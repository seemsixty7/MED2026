using Autodesk.AutoCAD.DatabaseServices;
using System;
using System.Collections.Generic;
using System.Globalization;

namespace MEDDotNet
{
    internal static class MedApps
    {
        public const string Conduit = "MED_CONDUIT";
        public const string Cable = "MED_CABLE";
        public const string Tray = "MED_TRAY";
        public const string Fitting = "MED_FITTING";
        public const string Equip = "MED_EQUIP";

        public static readonly string[] All =
        {
            Conduit, Cable, Tray, Fitting, Equip
        };

        public static string DisplayName(string app)
        {
            if (app == Conduit) return "Conduit";
            if (app == Cable) return "Cable";
            if (app == Tray) return "Tray";
            if (app == Fitting) return "Fitting";
            if (app == Equip) return "Equipment";
            return app;
        }

        public static string FromDisplay(string display)
        {
            if (string.IsNullOrEmpty(display)) return Conduit;
            string d = display.Trim();
            if (d.Equals("Conduit", StringComparison.OrdinalIgnoreCase) || d.Equals(Conduit, StringComparison.OrdinalIgnoreCase)) return Conduit;
            if (d.Equals("Cable", StringComparison.OrdinalIgnoreCase) || d.Equals(Cable, StringComparison.OrdinalIgnoreCase)) return Cable;
            if (d.Equals("Tray", StringComparison.OrdinalIgnoreCase) || d.Equals(Tray, StringComparison.OrdinalIgnoreCase)) return Tray;
            if (d.Equals("Fitting", StringComparison.OrdinalIgnoreCase) || d.Equals(Fitting, StringComparison.OrdinalIgnoreCase)) return Fitting;
            if (d.Equals("Equipment", StringComparison.OrdinalIgnoreCase) || d.Equals("Equip", StringComparison.OrdinalIgnoreCase) || d.Equals(Equip, StringComparison.OrdinalIgnoreCase)) return Equip;
            return Conduit;
        }

        public static string SqlItemType(string app)
        {
            if (app == Conduit) return "CONDUIT";
            if (app == Cable) return "CABLE";
            if (app == Tray) return "TRAY";
            if (app == Fitting) return "FITTING";
            if (app == Equip) return "EQUIP";
            return "CONDUIT";
        }
    }

    internal static class MedKeys
    {
        public const string Tag = "ITEM_TAG_";
        public const string RelatedTag = "ITEM_RTAG";
        public const string Size = "#ITEMSIZE";
        public const string Code = "#ITEMCODE";
        public const string Distance = "#ITEMDIST";
        public const string Alternate = "#ITEM_ALT";
        public const string Depth = "#ITEMDPTH";
        public const string Measure = "ITEM_MESR";
        public const string Flange = "#ITEMFLNG";

        public static readonly string[] WriteOrder =
        {
            Tag, Size, Code, RelatedTag, Distance, Alternate, Depth, Measure, Flange
        };
    }

    internal enum MedField
    {
        Tag,
        RelatedTag,
        Size,
        Alternate,
        Depth,
        Distance,
        Code,
        Measure,
        Flange
    }

    internal static class MedFieldMap
    {
        public static string Key(MedField field)
        {
            switch (field)
            {
                case MedField.Tag: return MedKeys.Tag;
                case MedField.RelatedTag: return MedKeys.RelatedTag;
                case MedField.Size: return MedKeys.Size;
                case MedField.Alternate: return MedKeys.Alternate;
                case MedField.Depth: return MedKeys.Depth;
                case MedField.Distance: return MedKeys.Distance;
                case MedField.Code: return MedKeys.Code;
                case MedField.Measure: return MedKeys.Measure;
                case MedField.Flange: return MedKeys.Flange;
                default: return null;
            }
        }

        public static bool UsedBy(string app, MedField field)
        {
            if (app == MedApps.Conduit)
                return field == MedField.Tag || field == MedField.Size || field == MedField.Code
                    || field == MedField.Distance || field == MedField.Measure;
            if (app == MedApps.Cable)
                return field == MedField.Tag || field == MedField.RelatedTag || field == MedField.Size
                    || field == MedField.Code || field == MedField.Distance || field == MedField.Measure;
            if (app == MedApps.Tray)
                return field == MedField.Tag || field == MedField.Size || field == MedField.Code
                    || field == MedField.Distance || field == MedField.Depth || field == MedField.Measure
                    || field == MedField.Flange;
            if (app == MedApps.Fitting)
                return field == MedField.Tag || field == MedField.Size || field == MedField.Code
                    || field == MedField.Alternate || field == MedField.Depth || field == MedField.Distance
                    || field == MedField.Flange;
            if (app == MedApps.Equip)
                return field == MedField.Tag || field == MedField.Code;
            return false;
        }

        public static HashSet<MedField> Intersection(IEnumerable<string> apps)
        {
            HashSet<MedField> result = null;
            foreach (string app in apps)
            {
                HashSet<MedField> one = new HashSet<MedField>();
                foreach (MedField f in Enum.GetValues(typeof(MedField)))
                {
                    if (UsedBy(app, f))
                        one.Add(f);
                }
                if (result == null)
                    result = one;
                else
                    result.IntersectWith(one);
            }
            return result ?? new HashSet<MedField>();
        }
    }

    internal class MedRecord
    {
        public ObjectId Id;
        public string AppName;
        public Dictionary<string, string> Values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        public List<string> KeyOrder = new List<string>();

        public string Get(string key)
        {
            string v;
            return Values.TryGetValue(key, out v) ? v : "";
        }

        public void Set(string key, string value)
        {
            Values[key] = value ?? "";
            if (!KeyOrder.Contains(key))
                KeyOrder.Add(key);
        }
    }

    internal static class MedXdata
    {
        public const string Varies = "*VARIES*";

        public static List<MedRecord> ReadEntity(Entity ent)
        {
            List<MedRecord> list = new List<MedRecord>();
            if (ent == null)
                return list;
            foreach (string app in MedApps.All)
            {
                ResultBuffer rb = ent.GetXDataForApplication(app);
                if (rb == null)
                    continue;
                list.AddRange(ParseApp(ent.ObjectId, app, rb));
                rb.Dispose();
            }
            return list;
        }

        public static List<MedRecord> ParseApp(ObjectId id, string app, ResultBuffer rb)
        {
            List<MedRecord> recs = new List<MedRecord>();
            MedRecord cur = null;
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
                if (cur != null && cur.Values.ContainsKey(key))
                {
                    recs.Add(cur);
                    cur = null;
                }
                if (cur == null)
                    cur = new MedRecord { Id = id, AppName = app };
                cur.Set(key, val);
            }
            if (cur != null)
                recs.Add(cur);
            return recs;
        }

        public static void WriteEntity(Entity ent, List<MedRecord> records, Transaction tr)
        {
            foreach (string app in MedApps.All)
            {
                List<MedRecord> items = new List<MedRecord>();
                foreach (MedRecord rec in records)
                {
                    if (rec.AppName == app)
                        items.Add(rec);
                }
                WriteApp(ent, app, items, tr);
            }
        }

        public static void WriteApp(Entity ent, string app, List<MedRecord> items, Transaction tr)
        {
            Database db = ent.Database;
            RegAppTable rat = (RegAppTable)tr.GetObject(db.RegAppTableId, OpenMode.ForRead);
            if (!rat.Has(app))
            {
                rat.UpgradeOpen();
                RegAppTableRecord rar = new RegAppTableRecord();
                rar.Name = app;
                rat.Add(rar);
                tr.AddNewlyCreatedDBObject(rar, true);
            }

            if (items == null || items.Count == 0)
            {
                ent.XData = new ResultBuffer(new TypedValue(1001, app));
                return;
            }

            ResultBuffer rb = new ResultBuffer();
            rb.Add(new TypedValue(1001, app));
            rb.Add(new TypedValue(1002, "{"));
            foreach (MedRecord rec in items)
            {
                List<string> order = new List<string>();
                foreach (string k in rec.KeyOrder)
                {
                    if (rec.Values.ContainsKey(k) && !order.Contains(k))
                        order.Add(k);
                }
                foreach (string k in MedKeys.WriteOrder)
                {
                    if (rec.Values.ContainsKey(k) && !order.Contains(k))
                        order.Add(k);
                }
                foreach (string k in rec.Values.Keys)
                {
                    if (!order.Contains(k))
                        order.Add(k);
                }
                foreach (string k in order)
                {
                    string v = rec.Values[k];
                    if (v == null)
                        v = "";
                    rb.Add(new TypedValue(1000, k + "=" + v));
                }
            }
            rb.Add(new TypedValue(1002, "}"));
            ent.XData = rb;
            rb.Dispose();
        }

        public static string FormatValue(MedField field, string raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return "";
            raw = raw.Trim();
            if (field == MedField.Tag || field == MedField.RelatedTag)
                return raw;
            if (field == MedField.Measure)
            {
                if (raw == "T" || raw.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || raw == "1" || raw.Equals("on", StringComparison.OrdinalIgnoreCase))
                    return "T";
                return "F";
            }
            if (field == MedField.Code)
            {
                raw = CodeFromDisplay(raw);
                int n;
                if (int.TryParse(raw, NumberStyles.Integer, CultureInfo.InvariantCulture, out n))
                    return n.ToString(CultureInfo.InvariantCulture);
                if (int.TryParse(raw, NumberStyles.Integer, CultureInfo.CurrentCulture, out n))
                    return n.ToString(CultureInfo.InvariantCulture);
                return raw;
            }
            double d;
            if (!double.TryParse(raw, NumberStyles.Float, CultureInfo.InvariantCulture, out d)
                && !double.TryParse(raw, NumberStyles.Float, CultureInfo.CurrentCulture, out d))
                return raw;
            if (field == MedField.Distance)
                return d.ToString("0.####", CultureInfo.InvariantCulture);
            return d.ToString("0.0000", CultureInfo.InvariantCulture);
        }

        public static string CodeFromDisplay(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return "";
            raw = raw.Trim();
            int sp = raw.IndexOf(' ');
            int dash = raw.IndexOf(" - ");
            int cut = -1;
            if (dash > 0) cut = dash;
            else if (sp > 0) cut = sp;
            string head = cut > 0 ? raw.Substring(0, cut).Trim() : raw;
            return head;
        }

        public static string Common(IList<string> values)
        {
            if (values == null || values.Count == 0)
                return "";
            string first = values[0] ?? "";
            for (int i = 1; i < values.Count; i++)
            {
                if (!string.Equals(first, values[i] ?? "", StringComparison.Ordinal))
                    return Varies;
            }
            return first;
        }
    }
}