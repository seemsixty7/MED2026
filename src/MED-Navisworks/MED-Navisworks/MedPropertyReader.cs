using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using Autodesk.Navisworks.Api;

namespace MEDNavisworks
{
    /// <summary>
    /// Reads MED identification fields from a ModelItem.
    /// Prefer a PropertyCategory named MEDProperties; otherwise search all
    /// categories for the known keys (and XData-derived / User names).
    /// </summary>
    internal static class MedPropertyReader
    {
        public sealed class Result
        {
            public ModelItem Item { get; set; }
            public string SourceCategory { get; set; }
            public string SourceNote { get; set; }
            public Dictionary<string, string> Values { get; set; }
                = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            public bool HasAnyMedField
            {
                get
                {
                    foreach (string key in MedPropertyKeys.All)
                    {
                        string v;
                        if (Values.TryGetValue(key, out v) && !string.IsNullOrWhiteSpace(v))
                            return true;
                    }
                    return false;
                }
            }
        }

        public static Result Read(ModelItem item)
        {
            Result r = new Result { Item = item };
            if (item == null)
            {
                r.SourceNote = "No item.";
                return r;
            }

            // 1) Prefer explicit MEDProperties category (display or internal name).
            PropertyCategory preferred = FindPreferredCategory(item);
            if (preferred != null)
            {
                FillFromCategory(preferred, r.Values);
                r.SourceCategory = DisplayOf(preferred);
                r.SourceNote = "Read from PropertyCategory '" + r.SourceCategory + "'.";
                if (r.HasAnyMedField)
                    return r;
            }

            // 2) Search every category for known keys / key=value style names.
            foreach (PropertyCategory cat in item.PropertyCategories)
            {
                if (preferred != null && object.ReferenceEquals(cat, preferred))
                    continue;
                int before = r.Values.Count;
                FillFromCategory(cat, r.Values);
                if (r.Values.Count > before && string.IsNullOrEmpty(r.SourceCategory))
                    r.SourceCategory = DisplayOf(cat);
            }

            if (r.HasAnyMedField)
            {
                if (string.IsNullOrEmpty(r.SourceNote))
                    r.SourceNote = "Matched MED field names across categories (source: " +
                                   (r.SourceCategory ?? "?") + ").";
                return r;
            }

            r.SourceNote =
                "No MEDProperties fields found on this ModelItem. " +
                "AutoCAD XData app 'MEDProperties' is typically NOT imported by the " +
                "Navisworks DWG reader. Use Attach User Properties bridge, or ensure " +
                "properties were converted/exported into the model.";
            return r;
        }

        public static string DumpCategories(ModelItem item)
        {
            if (item == null)
                return "(no item)";
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("Item: " + (item.DisplayName ?? "(unnamed)"));
            foreach (PropertyCategory cat in item.PropertyCategories)
            {
                sb.AppendLine("[" + DisplayOf(cat) + " | name=" + (cat.Name ?? "") + "]");
                foreach (DataProperty p in cat.Properties)
                {
                    sb.Append("  ")
                      .Append(p.DisplayName ?? "")
                      .Append(" / ")
                      .Append(p.Name ?? "")
                      .Append(" = ")
                      .AppendLine(FormatValue(p));
                }
            }
            return sb.ToString();
        }

        static PropertyCategory FindPreferredCategory(ModelItem item)
        {
            foreach (PropertyCategory cat in item.PropertyCategories)
            {
                string display = cat.DisplayName ?? "";
                string name = cat.Name ?? "";
                foreach (string alt in MedPropertyKeys.AlternateCategoryNames)
                {
                    if (string.Equals(display, alt, StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(name, alt, StringComparison.OrdinalIgnoreCase))
                    {
                        // "User" / "Element" alone are too broad unless they contain MED keys.
                        if (string.Equals(alt, "User", StringComparison.OrdinalIgnoreCase) ||
                            string.Equals(alt, "Element", StringComparison.OrdinalIgnoreCase))
                        {
                            Dictionary<string, string> tmp =
                                new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                            FillFromCategory(cat, tmp);
                            bool any = false;
                            foreach (string key in MedPropertyKeys.All)
                            {
                                string v;
                                if (tmp.TryGetValue(key, out v) && !string.IsNullOrWhiteSpace(v))
                                {
                                    any = true;
                                    break;
                                }
                            }
                            if (!any)
                                continue;
                        }
                        return cat;
                    }
                }
            }
            return null;
        }

        static void FillFromCategory(PropertyCategory cat, Dictionary<string, string> into)
        {
            if (cat == null)
                return;
            foreach (DataProperty p in cat.Properties)
            {
                TryCapture(p.DisplayName, FormatValue(p), into);
                TryCapture(p.Name, FormatValue(p), into);
            }
        }

        static void TryCapture(string rawName, string value, Dictionary<string, string> into)
        {
            if (string.IsNullOrWhiteSpace(rawName) || value == null)
                return;
            string name = rawName.Trim();

            // key=value packed into a single property name or value (XData-style remnants)
            int eq = name.IndexOf('=');
            if (eq > 0)
            {
                string k = name.Substring(0, eq).Trim();
                string v = name.Substring(eq + 1).Trim();
                if (IsMedKey(k) && !into.ContainsKey(k))
                    into[k] = v;
            }

            if (IsMedKey(name))
            {
                if (!into.ContainsKey(name) || string.IsNullOrWhiteSpace(into[name]))
                    into[name] = value;
                return;
            }

            // Strip common prefixes: MEDProperties_ObjectType, LcOaMEDProperties.ObjectType
            foreach (string key in MedPropertyKeys.All)
            {
                if (name.EndsWith(key, StringComparison.OrdinalIgnoreCase))
                {
                    char sep = name.Length > key.Length
                        ? name[name.Length - key.Length - 1]
                        : '\0';
                    if (name.Length == key.Length || sep == '_' || sep == '.' || sep == ':' || sep == ' ')
                    {
                        if (!into.ContainsKey(key) || string.IsNullOrWhiteSpace(into[key]))
                            into[key] = value;
                    }
                }
            }
        }

        static bool IsMedKey(string name)
        {
            foreach (string key in MedPropertyKeys.All)
            {
                if (string.Equals(name, key, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }

        static string DisplayOf(PropertyCategory cat)
        {
            if (!string.IsNullOrEmpty(cat.DisplayName))
                return cat.DisplayName;
            return cat.Name ?? "(category)";
        }

        public static string FormatValue(DataProperty p)
        {
            if (p == null || p.Value == null)
                return "";
            try
            {
                VariantData v = p.Value;
                if (v.IsDisplayString)
                    return v.ToDisplayString() ?? "";
                // Prefer typed accessors when available.
                if (v.IsDouble)
                    return v.ToDouble().ToString("0.####", CultureInfo.InvariantCulture);
                if (v.IsInt32)
                    return v.ToInt32().ToString(CultureInfo.InvariantCulture);
                if (v.IsBoolean)
                    return v.ToBoolean() ? "True" : "False";
                if (v.IsDateTime)
                    return v.ToDateTime().ToString("o", CultureInfo.InvariantCulture);
                string s = v.ToString();
                return s ?? "";
            }
            catch
            {
                try { return p.Value.ToString() ?? ""; }
                catch { return ""; }
            }
        }
    }
}
