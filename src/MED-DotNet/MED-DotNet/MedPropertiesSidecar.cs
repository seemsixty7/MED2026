using Autodesk.AutoCAD.DatabaseServices;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace MEDDotNet
{
    /// <summary>
    /// Sibling JSON sidecar for MEDProperties so Navisworks can attach user props by entity handle.
    /// File: {dwgBasename}.medprops.json next to the DWG.
    /// Schema (object):
    /// {
    ///   "version": 1,
    ///   "sourceDwg": "3DTrayPlanSample.dwg",
    ///   "app": "MEDProperties",
    ///   "items": [ { "handle":"1A2", "objectType":"TRAY", "size":"24",
    ///                "description":"...", "tag":"", "length":"10.0", "weight":"" } ]
    /// }
    /// Handle = AutoCAD entity Handle as hex string (no leading 0x).
    /// </summary>
    internal static class MedPropertiesSidecar
    {
        public const int SchemaVersion = 1;
        public const string AppLabel = "MEDProperties";
        public const string FileSuffix = ".medprops.json";

        static readonly object FileLock = new object();

        public static string PathFor(Database db)
        {
            if (db == null)
                return null;
            string fn = null;
            try { fn = db.Filename; }
            catch { }
            return PathForDwgPath(fn);
        }

        public static string PathForDwgPath(string dwgPath)
        {
            if (string.IsNullOrWhiteSpace(dwgPath))
                return null;
            try
            {
                string dir = Path.GetDirectoryName(dwgPath);
                string baseName = Path.GetFileNameWithoutExtension(dwgPath);
                if (string.IsNullOrEmpty(dir) || string.IsNullOrEmpty(baseName))
                    return null;
                return Path.Combine(dir, baseName + FileSuffix);
            }
            catch
            {
                return null;
            }
        }

        public static void Upsert(
            Database db,
            string handle,
            string objectType,
            string size,
            string description,
            string tag,
            string length,
            string weight)
        {
            if (db == null || string.IsNullOrWhiteSpace(handle))
                return;
            string path = PathFor(db);
            if (string.IsNullOrEmpty(path))
                return;

            string sourceDwg = "";
            try { sourceDwg = Path.GetFileName(db.Filename) ?? ""; }
            catch { }

            lock (FileLock)
            {
                SidecarFile file = ReadOrCreate(path, sourceDwg);
                string key = NormalizeHandle(handle);
                SidecarItem existing = null;
                for (int i = 0; i < file.Items.Count; i++)
                {
                    if (string.Equals(NormalizeHandle(file.Items[i].Handle), key, StringComparison.OrdinalIgnoreCase))
                    {
                        existing = file.Items[i];
                        break;
                    }
                }
                if (existing == null)
                {
                    existing = new SidecarItem { Handle = key };
                    file.Items.Add(existing);
                }
                else
                {
                    existing.Handle = key;
                }
                existing.ObjectType = objectType ?? "";
                existing.Size = size ?? "";
                existing.Description = description ?? "";
                existing.Tag = tag ?? "";
                existing.Length = length ?? "";
                existing.Weight = weight ?? "";
                if (!string.IsNullOrEmpty(sourceDwg))
                    file.SourceDwg = sourceDwg;
                WriteAtomic(path, file);
            }
        }

        /// <summary>
        /// Scan all entities with MEDProperties XData and rewrite the sidecar.
        /// Returns number of items written.
        /// </summary>
        public static int RebuildFromDatabase(Database db, Transaction tr)
        {
            if (db == null || tr == null)
                return 0;
            string path = PathFor(db);
            if (string.IsNullOrEmpty(path))
                return 0;

            string sourceDwg = "";
            try { sourceDwg = Path.GetFileName(db.Filename) ?? ""; }
            catch { }

            List<SidecarItem> items = new List<SidecarItem>();
            BlockTable bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            foreach (ObjectId btrId in bt)
            {
                BlockTableRecord btr = (BlockTableRecord)tr.GetObject(btrId, OpenMode.ForRead);
                if (btr == null)
                    continue;
                // Model space + paper space + all block defs (3D solids may live in MS only, but scan all)
                foreach (ObjectId entId in btr)
                {
                    Entity ent = tr.GetObject(entId, OpenMode.ForRead, false) as Entity;
                    if (ent == null)
                        continue;
                    Dictionary<string, string> map = MedPropertiesXData.Get(ent);
                    if (map == null || map.Count == 0)
                        continue;
                    bool any = false;
                    foreach (string k in MedPropertiesXData.WriteOrderPublic)
                    {
                        string v;
                        if (map.TryGetValue(k, out v) && !string.IsNullOrEmpty(v))
                        {
                            any = true;
                            break;
                        }
                    }
                    // Still record if XData app present even with empty values
                    ResultBuffer rb = ent.GetXDataForApplication(MedPropertiesXData.AppName);
                    if (rb == null && !any)
                        continue;
                    if (rb != null)
                        rb.Dispose();

                    string handle = NormalizeHandle(ent.Handle.ToString());
                    SidecarItem item = new SidecarItem
                    {
                        Handle = handle,
                        ObjectType = GetMap(map, MedPropertiesXData.KeyObjectType),
                        Size = GetMap(map, MedPropertiesXData.KeySize),
                        Description = GetMap(map, MedPropertiesXData.KeyDescription),
                        Tag = GetMap(map, MedPropertiesXData.KeyTag),
                        Length = GetMap(map, MedPropertiesXData.KeyLength),
                        Weight = GetMap(map, MedPropertiesXData.KeyWeight)
                    };
                    items.Add(item);
                }
            }

            SidecarFile file = new SidecarFile
            {
                Version = SchemaVersion,
                SourceDwg = sourceDwg,
                App = AppLabel,
                Items = items
            };
            lock (FileLock)
            {
                WriteAtomic(path, file);
            }
            return items.Count;
        }

        static string GetMap(Dictionary<string, string> map, string key)
        {
            string v;
            if (map != null && map.TryGetValue(key, out v) && v != null)
                return v;
            return "";
        }

        public static string NormalizeHandle(string handle)
        {
            if (string.IsNullOrWhiteSpace(handle))
                return "";
            string h = handle.Trim();
            if (h.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
                h = h.Substring(2);
            return h.ToUpperInvariant();
        }

        static SidecarFile ReadOrCreate(string path, string sourceDwg)
        {
            if (File.Exists(path))
            {
                try
                {
                    string json = File.ReadAllText(path, Encoding.UTF8);
                    SidecarFile parsed = SidecarJson.Parse(json);
                    if (parsed != null)
                    {
                        if (parsed.Items == null)
                            parsed.Items = new List<SidecarItem>();
                        if (parsed.Version <= 0)
                            parsed.Version = SchemaVersion;
                        if (string.IsNullOrEmpty(parsed.App))
                            parsed.App = AppLabel;
                        if (string.IsNullOrEmpty(parsed.SourceDwg) && !string.IsNullOrEmpty(sourceDwg))
                            parsed.SourceDwg = sourceDwg;
                        return parsed;
                    }
                }
                catch
                {
                    // fall through to new file
                }
            }
            return new SidecarFile
            {
                Version = SchemaVersion,
                SourceDwg = sourceDwg ?? "",
                App = AppLabel,
                Items = new List<SidecarItem>()
            };
        }

        static void WriteAtomic(string path, SidecarFile file)
        {
            string dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);
            string tmp = path + ".tmp";
            string json = SidecarJson.Serialize(file);
            File.WriteAllText(tmp, json, new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
            if (File.Exists(path))
            {
                try { File.Replace(tmp, path, null); }
                catch
                {
                    File.Copy(tmp, path, true);
                    try { File.Delete(tmp); } catch { }
                }
            }
            else
            {
                File.Move(tmp, path);
            }
        }

        internal sealed class SidecarFile
        {
            public int Version;
            public string SourceDwg;
            public string App;
            public List<SidecarItem> Items = new List<SidecarItem>();
        }

        internal sealed class SidecarItem
        {
            public string Handle;
            public string ObjectType;
            public string Size;
            public string Description;
            public string Tag;
            public string Length;
            public string Weight;
        }

        /// <summary>Minimal JSON for the fixed MEDProperties sidecar schema (no third-party deps).</summary>
        internal static class SidecarJson
        {
            public static string Serialize(SidecarFile file)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("{\r\n");
                sb.Append("  \"version\": ").Append(file.Version).Append(",\r\n");
                sb.Append("  \"sourceDwg\": ").Append(Q(file.SourceDwg)).Append(",\r\n");
                sb.Append("  \"app\": ").Append(Q(file.App)).Append(",\r\n");
                sb.Append("  \"items\": [\r\n");
                List<SidecarItem> items = file.Items ?? new List<SidecarItem>();
                for (int i = 0; i < items.Count; i++)
                {
                    SidecarItem it = items[i];
                    sb.Append("    {\r\n");
                    sb.Append("      \"handle\": ").Append(Q(it.Handle)).Append(",\r\n");
                    sb.Append("      \"objectType\": ").Append(Q(it.ObjectType)).Append(",\r\n");
                    sb.Append("      \"size\": ").Append(Q(it.Size)).Append(",\r\n");
                    sb.Append("      \"description\": ").Append(Q(it.Description)).Append(",\r\n");
                    sb.Append("      \"tag\": ").Append(Q(it.Tag)).Append(",\r\n");
                    sb.Append("      \"length\": ").Append(Q(it.Length)).Append(",\r\n");
                    sb.Append("      \"weight\": ").Append(Q(it.Weight)).Append("\r\n");
                    sb.Append("    }");
                    if (i < items.Count - 1)
                        sb.Append(",");
                    sb.Append("\r\n");
                }
                sb.Append("  ]\r\n");
                sb.Append("}\r\n");
                return sb.ToString();
            }

            public static SidecarFile Parse(string json)
            {
                if (string.IsNullOrWhiteSpace(json))
                    return null;
                SidecarFile file = new SidecarFile
                {
                    Version = SchemaVersion,
                    App = AppLabel,
                    Items = new List<SidecarItem>()
                };
                // Very small extractor for our known keys (tolerant of whitespace).
                file.Version = ReadIntProp(json, "version", SchemaVersion);
                file.SourceDwg = ReadStringProp(json, "sourceDwg") ?? "";
                file.App = ReadStringProp(json, "app") ?? AppLabel;

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
                    SidecarItem item = new SidecarItem
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

            static string Q(string s)
            {
                if (s == null)
                    s = "";
                StringBuilder sb = new StringBuilder();
                sb.Append('"');
                foreach (char c in s)
                {
                    switch (c)
                    {
                        case '\\': sb.Append("\\\\"); break;
                        case '"': sb.Append("\\\""); break;
                        case '\r': sb.Append("\\r"); break;
                        case '\n': sb.Append("\\n"); break;
                        case '\t': sb.Append("\\t"); break;
                        default:
                            if (c < 0x20)
                                sb.AppendFormat(CultureInfo.InvariantCulture, "\\u{0:x4}", (int)c);
                            else
                                sb.Append(c);
                            break;
                    }
                }
                sb.Append('"');
                return sb.ToString();
            }

            static int IndexOfKey(string json, string key)
            {
                // Find "key"
                string needle = "\"" + key + "\"";
                return json.IndexOf(needle, StringComparison.OrdinalIgnoreCase);
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
                        if (c == '\\' && i + 1 < s.Length)
                        {
                            i++;
                            continue;
                        }
                        if (c == '"')
                            inStr = false;
                        continue;
                    }
                    if (c == '"')
                    {
                        inStr = true;
                        continue;
                    }
                    if (c == open)
                        depth++;
                    else if (c == close)
                    {
                        depth--;
                        if (depth == 0)
                            return i;
                    }
                }
                return -1;
            }
        }
    }
}
