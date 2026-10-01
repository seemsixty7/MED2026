using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace MEDDotNet
{
    public sealed class Dwg3DScanResult
    {
        public int OnDisk, Added, NewlyMissing, Restored, ThumbsExtracted, TotalMissing;
        public int Png, Bmp, None;
        public List<Dwg3DEntry> Entries;
        public override string ToString()
        {
            return OnDisk + " DWGs on disk, " + Added + " added, " + NewlyMissing + " newly missing (" + TotalMissing + " missing total), "
                + Restored + " restored, " + ThumbsExtracted + " thumbnails (re)extracted. Previews: PNG " + Png + ", BMP " + Bmp + ", none " + None + ".";
        }
    }

    /// <summary>Folder scan; same rules as tools\Dwg3DCatalog\Scanner.cs so both tools keep the DB consistent.</summary>
    public static class Dwg3DScanner
    {
        public static Dwg3DScanResult Scan(Dwg3DLibDb db, string folder, bool forceThumbs)
        {
            var res = new Dwg3DScanResult();
            var manifest = LoadManifests(folder);
            var existing = new Dictionary<string, Dwg3DEntry>(StringComparer.OrdinalIgnoreCase);
            foreach (var x in db.LoadAll()) existing[x.File] = x;
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var files = Directory.EnumerateFiles(folder, "*.dwg", SearchOption.AllDirectories)
                .OrderBy(f => f, StringComparer.OrdinalIgnoreCase).ToList();
            using (var tx = db.Begin())
            {
                foreach (var full in files)
                {
                    var rel = RelativePath(folder, full);
                    seen.Add(rel);
                    var fi = new FileInfo(full);
                    var mod = Dwg3DLibDb.Stamp(fi.LastWriteTime);
                    string[] man;
                    manifest.TryGetValue(Path.GetFileName(rel), out man);
                    string manSource = man != null ? man[0] : "", manMod = man != null ? man[1] : "";
                    Dwg3DEntry e;
                    if (!existing.TryGetValue(rel, out e))
                    {
                        e = new Dwg3DEntry { File = rel, FileModified = mod, FileSize = fi.Length, DateAdded = Dwg3DLibDb.Now(), SourcePath = manSource, SourceModified = manMod };
                        ApplyThumb(e, full, mod);
                        db.Insert(e);
                        existing[rel] = e;
                        res.Added++; res.ThumbsExtracted++;
                        continue;
                    }
                    bool changed = e.FileModified != mod || e.FileSize != fi.Length || e.Missing;
                    if (e.Missing) res.Restored++;
                    e.FileModified = mod; e.FileSize = fi.Length; e.Missing = false;
                    if (string.IsNullOrEmpty(e.SourcePath) && !string.IsNullOrEmpty(manSource))
                    { e.SourcePath = manSource; e.SourceModified = manMod; changed = true; }
                    if (changed) db.UpdateFileInfo(e);
                    if (forceThumbs || e.ThumbFileModified != mod || e.ThumbFormat == "")
                    {
                        ApplyThumb(e, full, mod);
                        db.UpdateThumb(e);
                        if (e.Small != null) { e.Small.Dispose(); e.Small = null; }
                        res.ThumbsExtracted++;
                    }
                }
                foreach (var e in existing.Values)
                {
                    if (seen.Contains(e.File)) continue;
                    if (!e.Missing) { e.Missing = true; db.UpdateFileInfo(e); res.NewlyMissing++; }
                }
                tx.Commit();
            }
            res.OnDisk = files.Count;
            res.Entries = existing.Values.OrderBy(e => e.File, StringComparer.OrdinalIgnoreCase).ToList();
            foreach (var e in res.Entries)
            {
                if (e.Missing) { res.TotalMissing++; continue; }
                if (e.ThumbFormat == "PNG") res.Png++;
                else if (e.ThumbFormat == "BMP") res.Bmp++;
                else res.None++;
            }
            return res;
        }

        public static string RelativePath(string folder, string full)
        {
            string f = Path.GetFullPath(folder).TrimEnd('\\', '/') + "\\";
            string p = Path.GetFullPath(full);
            return p.StartsWith(f, StringComparison.OrdinalIgnoreCase) ? p.Substring(f.Length) : p;
        }

        static void ApplyThumb(Dwg3DEntry e, string full, string mod)
        {
            var t = Dwg3DThumbnail.Extract(full);
            e.Thumb = t.Png; e.ThumbFormat = t.Format; e.ThumbFileModified = mod;
        }

        /// <summary>manifest*.csv: columns file|output_file, source|source_drawing, source_modified. Value = {source, modified}.</summary>
        public static Dictionary<string, string[]> LoadManifests(string folder)
        {
            var map = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);
            if (!Directory.Exists(folder)) return map;
            foreach (var csv in Directory.GetFiles(folder, "manifest*.csv").OrderBy(f => f, StringComparer.OrdinalIgnoreCase))
            {
                try
                {
                    using (var sr = new StreamReader(new FileStream(csv, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
                    {
                        var header = ParseCsvLine(sr.ReadLine() ?? "");
                        Func<string[], int> col = names =>
                        {
                            foreach (var n in names)
                            {
                                int k = header.FindIndex(h => h.Trim().Equals(n, StringComparison.OrdinalIgnoreCase));
                                if (k >= 0) return k;
                            }
                            return -1;
                        };
                        int fc = col(new[] { "file", "output_file" }), sc = col(new[] { "source", "source_drawing" }), mc = col(new[] { "source_modified" });
                        if (fc < 0 || sc < 0) continue;
                        string line;
                        while ((line = sr.ReadLine()) != null)
                        {
                            var f = ParseCsvLine(line);
                            if (f.Count <= Math.Max(fc, sc)) continue;
                            var name = f[fc].Trim();
                            if (name.Length == 0 || map.ContainsKey(name)) continue;
                            map[name] = new[] { f[sc].Trim(), mc >= 0 && mc < f.Count ? f[mc].Trim() : "" };
                        }
                    }
                }
                catch { /* ignore unreadable manifest */ }
            }
            return map;
        }

        public static List<string> ParseCsvLine(string line)
        {
            var res = new List<string>();
            var sb = new StringBuilder();
            bool q = false;
            for (int i = 0; i < line.Length; i++)
            {
                char ch = line[i];
                if (q)
                {
                    if (ch == '"') { if (i + 1 < line.Length && line[i + 1] == '"') { sb.Append('"'); i++; } else q = false; }
                    else sb.Append(ch);
                }
                else if (ch == '"') q = true;
                else if (ch == ',') { res.Add(sb.ToString()); sb.Clear(); }
                else sb.Append(ch);
            }
            res.Add(sb.ToString());
            return res;
        }
    }
}
