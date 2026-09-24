using System;
using System.Collections.Generic;
using Autodesk.Navisworks.Api;
using Autodesk.Navisworks.Api.ComApi;
using Autodesk.Navisworks.Api.Interop.ComApi;

namespace MEDNavisworks
{
    /// <summary>
    /// Practical bridge when AutoCAD XData is not visible on appended DWG ModelItems:
    /// attach a user-defined PropertyCategory "MEDProperties" via COM SetUserDefined.
    /// Values must be supplied by the caller (paste/side-channel / future RealDWG reader).
    /// After attach, native Properties and MedPropertyReader both see the category.
    /// </summary>
    internal static class UserPropertyBridge
    {
        public static bool AttachMedProperties(ModelItem item, IDictionary<string, string> values, out string error)
        {
            error = null;
            if (item == null)
            {
                error = "No ModelItem.";
                return false;
            }
            if (values == null || values.Count == 0)
            {
                error = "No values to attach.";
                return false;
            }

            try
            {
                InwOpState10 state = ComApiBridge.State;
                if (state == null)
                {
                    error = "ComApiBridge.State is null (not running inside Navisworks?).";
                    return false;
                }

                InwOaPath path = ComApiBridge.ToInwOaPath(item);
                InwGUIPropertyNode2 node =
                    state.GetGUIPropertyNode(path, true) as InwGUIPropertyNode2;
                if (node == null)
                {
                    error = "GetGUIPropertyNode returned null.";
                    return false;
                }

                InwOaPropertyVec vec =
                    (InwOaPropertyVec)state.ObjectFactory(
                        nwEObjectType.eObjectType_nwOaPropertyVec, null, null);

                foreach (string key in MedPropertyKeys.All)
                {
                    string val;
                    if (!values.TryGetValue(key, out val))
                        val = "";
                    InwOaProperty prop =
                        (InwOaProperty)state.ObjectFactory(
                            nwEObjectType.eObjectType_nwOaProperty, null, null);
                    prop.name = key;
                    prop.UserName = key;
                    prop.value = val ?? "";
                    vec.Properties().Add(prop);
                }

                int existingIndex = FindUserDefinedIndex(node);
                if (existingIndex >= 0)
                    node.RemoveUserDefined(existingIndex);

                node.SetUserDefined(
                    0,
                    MedPropertyKeys.CategoryDisplayName,
                    MedPropertyKeys.CategoryInternalName,
                    vec);

                return true;
            }
            catch (Exception ex)
            {
                error = ex.GetType().Name + ": " + ex.Message;
                return false;
            }
        }

        /// <summary>
        /// RemoveUserDefined index is among user-defined categories only (0-based).
        /// </summary>
        static int FindUserDefinedIndex(InwGUIPropertyNode2 node)
        {
            try
            {
                InwGUIAttributesColl attrs = node.GUIAttributes();
                if (attrs == null)
                    return -1;

                int userDefinedIndex = 0;
                foreach (InwGUIAttribute2 attr in attrs)
                {
                    if (attr == null)
                        continue;
                    if (!attr.UserDefined)
                        continue;

                    string classUser = attr.ClassUserName ?? "";
                    string className = attr.ClassName ?? "";
                    string name = attr.name ?? "";
                    if (string.Equals(classUser, MedPropertyKeys.CategoryDisplayName, StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(className, MedPropertyKeys.CategoryInternalName, StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(name, MedPropertyKeys.CategoryInternalName, StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(name, MedPropertyKeys.CategoryDisplayName, StringComparison.OrdinalIgnoreCase))
                    {
                        return userDefinedIndex;
                    }
                    userDefinedIndex++;
                }
            }
            catch
            {
                // ignore — caller will still SetUserDefined
            }
            return -1;
        }
    }
}
