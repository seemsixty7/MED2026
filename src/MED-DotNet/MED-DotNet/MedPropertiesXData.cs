using Autodesk.AutoCAD.DatabaseServices;
using System;
using System.Collections.Generic;
using System.Globalization;

namespace MEDDotNet
{
    /// <summary>
    /// Generic 3D-model identification XData (app MEDProperties).
    /// Not BOM: separate from MED_TRAY / MED_CABLE / etc. Do not feed into BOM export.
    /// Schema (all 1000 strings as key=value): ObjectType, Size, Description, Tag, Length, Weight.
    /// </summary>
    internal static class MedPropertiesXData
    {
        public const string AppName = "MEDProperties";

        public const string ObjectTypeTray = "TRAY";
        public const string ObjectTypeFitting = "FITTING";
        public const string ObjectTypeCable = "CABLE";
        public const string ObjectTypeConduit = "CONDUIT";
        public const string ObjectTypeEquipment = "EQUIPMENT";

        public const string KeyObjectType = "ObjectType";
        public const string KeySize = "Size";
        public const string KeyDescription = "Description";
        public const string KeyTag = "Tag";
        public const string KeyLength = "Length";
        public const string KeyWeight = "Weight";

        internal static readonly string[] WriteOrderPublic =
        {
            KeyObjectType, KeySize, KeyDescription, KeyTag, KeyLength, KeyWeight
        };

        public static void EnsureRegApp(Database db, Transaction tr)
        {
            if (db == null || tr == null)
                return;
            RegAppTable rat = (RegAppTable)tr.GetObject(db.RegAppTableId, OpenMode.ForRead);
            if (rat.Has(AppName))
                return;
            rat.UpgradeOpen();
            RegAppTableRecord rar = new RegAppTableRecord();
            rar.Name = AppName;
            rat.Add(rar);
            tr.AddNewlyCreatedDBObject(rar, true);
        }

        public static void Set(
            Entity ent,
            Transaction tr,
            string objectType,
            string size,
            string description,
            string tag,
            string length,
            string weight = null)
        {
            if (ent == null || tr == null)
                return;
            EnsureRegApp(ent.Database, tr);

            ResultBuffer rb = new ResultBuffer();
            rb.Add(new TypedValue(1001, AppName));
            rb.Add(new TypedValue(1002, "{"));
            rb.Add(new TypedValue(1000, KeyObjectType + "=" + (objectType ?? "")));
            rb.Add(new TypedValue(1000, KeySize + "=" + (size ?? "")));
            rb.Add(new TypedValue(1000, KeyDescription + "=" + (description ?? "")));
            rb.Add(new TypedValue(1000, KeyTag + "=" + (tag ?? "")));
            rb.Add(new TypedValue(1000, KeyLength + "=" + (length ?? "")));
            rb.Add(new TypedValue(1000, KeyWeight + "=" + (weight ?? "")));
            rb.Add(new TypedValue(1002, "}"));
            ent.XData = rb;
            rb.Dispose();

            try
            {
                string handle = ent.Handle.ToString();
                MedPropertiesSidecar.Upsert(
                    ent.Database,
                    handle,
                    objectType,
                    size,
                    description,
                    tag,
                    length,
                    weight);
            }
            catch
            {
                // Sidecar is best-effort; XData remains source of truth in DWG.
            }
        }

        public static Dictionary<string, string> Get(Entity ent)
        {
            Dictionary<string, string> values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (ent == null)
                return values;
            ResultBuffer rb = ent.GetXDataForApplication(AppName);
            if (rb == null)
                return values;
            try
            {
                foreach (TypedValue tv in rb)
                {
                    if (tv.TypeCode != 1000)
                        continue;
                    string s = tv.Value as string;
                    if (string.IsNullOrEmpty(s))
                        continue;
                    int eq = s.IndexOf('=');
                    if (eq <= 0)
                        continue;
                    string key = s.Substring(0, eq);
                    string val = s.Substring(eq + 1);
                    values[key] = val ?? "";
                }
            }
            finally
            {
                rb.Dispose();
            }
            return values;
        }

        public static string FormatLength(double length)
        {
            return length.ToString("0.####", CultureInfo.InvariantCulture);
        }

        public static string FormatSize(double size)
        {
            return size.ToString("0.####", CultureInfo.InvariantCulture);
        }
    }
}

