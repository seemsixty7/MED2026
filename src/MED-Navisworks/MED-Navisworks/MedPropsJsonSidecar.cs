using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace MEDNavisworks
{
    /// <summary>
    /// Sibling JSON next to a DWG: {basename}.medprops.json
    /// Schema matches MED-DotNet MedPropertiesSidecar (version 1 object with items[]).
    /// </summary>
    internal static class MedPropsJsonSidecar
    {
        public const string FileSuffix = ".medprops.json";

        public sealed class FileModel
        {
            public int Version;
            public string SourceDwg;
            public string App;
            public List<ItemModel> Items = new List<ItemModel>();
        }

        public sealed class ItemModel
        {
            public string Handle;
            public string ObjectType;
            public string Size;
            public string Description;
            public string Tag;
            public string Length;
            public string Weight;

            public Dictionary<string, string> ToPropertyMap()
            {
                return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    { MedPropertyKeys.ObjectType, ObjectType ?? "" },
                    { MedPropertyKeys.Size, Size ?? "" },
                    { MedPropertyKeys.Description, Description ?? "" },
                    { MedPropertyKeys.Tag, Tag ?? "" },
                    { MedPropertyKeys.Length, Length ?? "" },
                    { MedPropertyKeys.Weight, Weight ?? "" }
                };
            }
        }

        public static string PathBeside(string dwgOrModelPath)
        {
            if (string.IsNullOrWhiteSpace(dwgOrModelPath))
                return null;
            try
            {
                string dir = Path.GetDirectoryName(dwgOrModelPath);
                string baseName = Path.GetFileNameWithoutExtension(dwgOrModelPath);
                if (string.IsNullOrEmpty(dir) || string.IsNullOrEmpty(baseName))
                    return null;
                return Path.Combine(dir, baseName + FileSuffix);
            }
            catch
            {
                return null;
            }
        }

        public static string NormalizeHandle(string handle)
        {
            if (string.IsNullOrWhiteSpace(handle))
                return "";
            string h = handle.Trim();
            if (h.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
                h = h.Substring(2);
            // Some readers pad or add quotes
            h = h.Trim('"', '\'', ' ');
            return h.ToUpperInvariant();
        }

        public static FileModel TryLoad(string jsonPath, out string error)
        {
            error = null;
            if (string.IsNullOrWhiteSpace(jsonPath) || !File.Exists(jsonPath))
            {
                error = "JSON not found: " + (jsonPath ?? "(null)");
                return null;
            }
            try
            {
                string json = File.ReadAllText(jsonPath, Encoding.UTF8);
                FileModel file = Parse(json);
                if (file == null)
                {
                    error = "Failed to parse JSON.";
                    return null;
                }
                return file;
            }
            catch (Exception ex)
            {
                error = ex.GetType().Name + ": " + ex.Message;
                return null;
            }
        }

        public static FileModel Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
                return null;
            FileModel file = new FileModel
            {
                Version = ReadIntProp(json, "version", 1),
                SourceDwg = ReadStringProp(json, "sourceDwg") ?? "",
                App = ReadStringProp(json, "app") ?? MedPropertyKeys.AppName,
                Items = new List<ItemModel>()
            };
            int itemsIdx = IndexOfKey(json, "items");
            if (itemsIdx < 0)
                return file;
            int arrStart = json.IndexOf('[', itemsIdx);
            if (arrStart < 0)
                return file;
            int arrEnd = FindMatching(json, arrStart, '[', ']');
            if (arrEnd < 0)
                return file;
            string arr = json.Substring(arrStart + 1, arrEnd - arrStart - 1);
            int pos = 0;
            while (pos < arr.Length)
            {
                int objStart = arr.IndexOf('{', pos);
                if (objStart < 0)
                    break;
                int objEnd = FindMatching(arr, objStart, '{', '}');
                if (objEnd < 0)
                    break;
                string obj = arr.Substring(objStart, objEnd - objStart + 1);
                ItemModel item = new ItemModel
                {
                    Handle = ReadStringProp(obj, "handle") ?? "",
                    ObjectType = ReadStringProp(obj, "objectType") ?? "",
                    Size = ReadStringProp(obj, "size") ?? "",
                    Description = ReadStringProp(obj, "description") ?? "",
                    Tag = ReadStringProp(obj, "tag") ?? "",
                    Length = ReadStringProp(obj, "length") ?? "",
                    Weight = ReadStringProp(obj, "weight") ?? ""
                };
                if (!string.IsNullOrEmpty(item.Handle))
                    file.Items.Add(item);
                pos = objEnd + 1;
            }
            return file;
        }

        static int IndexOfKey(string json, string key)
        {
            return json.IndexOf("\"" + key + "\"", StringComparison.OrdinalIgnoreCase);
        }

        static string ReadStringProp(string json, string key)
        {
            int k = IndexOfKey(json, key);
            if (k < 0)
                return null;
            int colon = json.IndexOf(':', k);
            if (colon < 0)
                return null;
            int i = colon + 1;
            while (i < json.Length && char.IsWhiteSpace(json[i]))
                i++;
            if (i >= json.Length || json[i] != '"')
                return null;
            i++;
            StringBuilder sb = new StringBuilder();
            while (i < json.Length)
            {
                char c = json[i++];
                if (c == '\\' && i < json.Length)
                {
                    char n = json[i++];
                    switch (n)
                    {
                        case '"': sb.Append('"'); break;
                        case '\\': sb.Append('\\'); break;
                        case '/': sb.Append('/'); break;
                        case 'n': sb.Append('\n'); break;
                        case 'r': sb.Append('\r'); break;
                        case 't': sb.Append('\t'); break;
                        case 'u':
                            if (i + 3 < json.Length)
                            {
                                int code;
                                if (int.TryParse(json.Substring(i, 4), NumberStyles.HexNumber,
                                    CultureInfo.InvariantCulture, out code))
                                    sb.Append((char)code);
                                i += 4;
                            }
                            break;
                        default: sb.Append(n); break;
                    }
                }
                else if (c == '"')
                    break;
                else
                    sb.Append(c);
            }
            return sb.ToString();
        }

        static int ReadIntProp(string json, string key, int fallback)
        {
            int k = IndexOfKey(json, key);
            if (k < 0)
                return fallback;
            int colon = json.IndexOf(':', k);
            if (colon < 0)
                return fallback;
            int i = colon + 1;
            while (i < json.Length && char.IsWhiteSpace(json[i]))
                i++;
            int start = i;
            while (i < json.Length && (char.IsDigit(json[i]) || json[i] == '-'))
                i++;
            int v;
            if (int.TryParse(json.Substring(start, i - start), NumberStyles.Integer,
                CultureInfo.InvariantCulture, out v))
                return v;
            return fallback;
        }

        static int FindMatching(string s, int openIdx, char open, char close)
        {
            int depth = 0;
            bool inStr = false;
            for (int i = openIdx; i < s.Length; i++)
            {
                char c = s[i];
                if (inStr)
                {
                    if (c == '\\' && i + 1 < s.Length) { i++; continue; }
                    if (c == '"') inStr = false;
                    continue;
                }
                if (c == '"') { inStr = true; continue; }
                if (c == open) depth++;
                else if (c == close)
                {
                    depth--;
                    if (depth == 0) return i;
                }
            }
            return -1;
        }
    }
}
