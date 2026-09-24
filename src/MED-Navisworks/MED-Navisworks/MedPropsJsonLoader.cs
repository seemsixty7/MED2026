using System;
using System.Collections.Generic;
using System.IO;
using Autodesk.Navisworks.Api;

namespace MEDNavisworks
{
    /// <summary>
    /// Load sibling .medprops.json and attach MEDProperties user props by AutoCAD entity handle.
    /// </summary>
    internal static class MedPropsJsonLoader
    {
        public sealed class ApplyResult
        {
            public string JsonPath;
            public int JsonItems;
            public int Matched;
            public int Attached;
            public int Failed;
            public string Message;
        }

        public static List<string> CandidateJsonPaths(Document doc)
        {
            List<string> list = new List<string>();
            HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (doc == null)
                return list;

            foreach (Model model in doc.Models)
            {
                if (model == null)
                    continue;
                AddBeside(seen, list, SafeSourceFileName(model));
                AddBeside(seen, list, SafeFileName(model));
            }

            try { AddBeside(seen, list, doc.FileName); }
            catch { }

            return list;
        }

        static string SafeSourceFileName(Model model)
        {
            try { return model.SourceFileName; }
            catch { return null; }
        }

        static string SafeFileName(Model model)
        {
            try { return model.FileName; }
            catch { return null; }
        }

        static void AddBeside(HashSet<string> seen, List<string> list, string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return;
            string p = MedPropsJsonSidecar.PathBeside(path);
            if (!string.IsNullOrEmpty(p) && seen.Add(p))
                list.Add(p);
        }

        public static ApplyResult TryAutoLoad(Document doc)
        {
            foreach (string path in CandidateJsonPaths(doc))
            {
                if (File.Exists(path))
                    return ApplyFile(doc, path);
            }
            return new ApplyResult
            {
                Message = "No sibling .medprops.json found next to model source files."
            };
        }

        public static ApplyResult ApplyFile(Document doc, string jsonPath)
        {
            ApplyResult result = new ApplyResult { JsonPath = jsonPath };
            if (doc == null)
            {
                result.Message = "No document.";
                return result;
            }
            string err;
            MedPropsJsonSidecar.FileModel file = MedPropsJsonSidecar.TryLoad(jsonPath, out err);
            if (file == null)
            {
                result.Message = err ?? "Load failed.";
                return result;
            }
            result.JsonItems = file.Items != null ? file.Items.Count : 0;

            Dictionary<string, MedPropsJsonSidecar.ItemModel> byHandle =
                new Dictionary<string, MedPropsJsonSidecar.ItemModel>(StringComparer.OrdinalIgnoreCase);
            if (file.Items != null)
            {
                foreach (MedPropsJsonSidecar.ItemModel item in file.Items)
                {
                    string h = MedPropsJsonSidecar.NormalizeHandle(item.Handle);
                    if (!string.IsNullOrEmpty(h))
                        byHandle[h] = item;
                }
            }
            if (byHandle.Count == 0)
            {
                result.Message = "JSON has no items with handles.";
                return result;
            }

            int modelCount = 0;
            try { modelCount = doc.Models.Count; } catch { }
            if (modelCount == 0)
            {
                result.Message =
                    "JSON loaded (" + result.JsonItems + " item(s)) but the document has no models. " +
                    "Open/Append a DWG (or NWC) first — the MED add-in cannot match handles without ModelItems. " +
                    "If DWG open says 'no plug-in', that is the Autodesk DWG file reader, not this add-in.";
                return result;
            }

            foreach (Model model in doc.Models)
            {
                if (model == null || model.RootItem == null)
                    continue;
                foreach (ModelItem mi in model.RootItem.DescendantsAndSelf)
                {
                    string handle = FindEntityHandle(mi);
                    if (string.IsNullOrEmpty(handle))
                        continue;
                    string key = MedPropsJsonSidecar.NormalizeHandle(handle);
                    MedPropsJsonSidecar.ItemModel props;
                    if (!byHandle.TryGetValue(key, out props))
                        continue;
                    result.Matched++;
                    string attachErr;
                    if (UserPropertyBridge.AttachMedProperties(mi, props.ToPropertyMap(), out attachErr))
                        result.Attached++;
                    else
                        result.Failed++;
                }
            }

            result.Message = string.Format(
                "Loaded {0}: {1} JSON item(s), matched {2}, attached {3}, failed {4}.",
                Path.GetFileName(jsonPath),
                result.JsonItems,
                result.Matched,
                result.Attached,
                result.Failed);
            if (result.Matched == 0)
            {
                result.Message +=
                    " No ModelItems matched JSON handles. Select a solid and use Dump categories to confirm AutoCAD Entity Handle values (expect hex like 73/7A).";
            }
            return result;
        }

        public static string FindEntityHandle(ModelItem item)
        {
            if (item == null)
                return null;

            try
            {
                PropertyCategory cat =
                    item.PropertyCategories.FindCategoryByName(PropertyCategoryNames.AutoCadEntityHandle);
                if (cat != null)
                {
                    DataProperty p =
                        cat.Properties.FindPropertyByName(DataPropertyNames.AutoCadEntityHandleValue);
                    if (p != null)
                    {
                        string v = MedPropertyReader.FormatValue(p);
                        if (!string.IsNullOrWhiteSpace(v))
                            return v;
                    }
                    foreach (DataProperty dp in cat.Properties)
                    {
                        string v = MedPropertyReader.FormatValue(dp);
                        if (!string.IsNullOrWhiteSpace(v) && LooksLikeHandle(v))
                            return v;
                    }
                }
            }
            catch { }

            foreach (PropertyCategory cat in item.PropertyCategories)
            {
                string catDisplay = cat.DisplayName ?? "";
                string catName = cat.Name ?? "";
                bool catHandleish =
                    catDisplay.IndexOf("Handle", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    catName.IndexOf("Handle", StringComparison.OrdinalIgnoreCase) >= 0;

                foreach (DataProperty p in cat.Properties)
                {
                    string dn = p.DisplayName ?? "";
                    string pn = p.Name ?? "";
                    bool nameHandleish =
                        dn.IndexOf("Handle", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        pn.IndexOf("Handle", StringComparison.OrdinalIgnoreCase) >= 0;
                    if (!nameHandleish && !catHandleish)
                        continue;
                    if (!nameHandleish)
                        continue;
                    string v = MedPropertyReader.FormatValue(p);
                    if (!string.IsNullOrWhiteSpace(v) && LooksLikeHandle(v))
                        return v;
                }
            }
            return null;
        }

        static bool LooksLikeHandle(string v)
        {
            if (string.IsNullOrWhiteSpace(v))
                return false;
            string h = MedPropsJsonSidecar.NormalizeHandle(v);
            if (h.Length == 0 || h.Length > 16)
                return false;
            foreach (char c in h)
            {
                bool hex = (c >= '0' && c <= '9') ||
                           (c >= 'A' && c <= 'F') ||
                           (c >= 'a' && c <= 'f');
                if (!hex)
                    return false;
            }
            return true;
        }
    }
}

