using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace MEDDotNet
{
    /// <summary>
    /// Per-user settings for the 3D block library (%APPDATA%\MED\MED3DLib.settings, key=value lines).
    /// Folder resolution: saved folder -> Dwg3D next to MED's Support folder (relative to the loaded DLL) -> developer default.
    /// </summary>
    public static class Dwg3DLibSettings
    {
        public const string DeveloperDefault = @"C:\Users\moore\Dropbox\Development\Jane\MED2026-OpenSource\Dwg3D";

        public static string SettingsPath
        {
            get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "MED", "MED3DLib.settings"); }
        }

        static Dictionary<string, string> Load()
        {
            var d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            try
            {
                if (File.Exists(SettingsPath))
                    foreach (var line in File.ReadAllLines(SettingsPath))
                    {
                        int k = line.IndexOf('=');
                        if (k > 0) d[line.Substring(0, k).Trim()] = line.Substring(k + 1).Trim();
                    }
            }
            catch { }
            return d;
        }

        public static string Get(string key, string def)
        {
            string v;
            return Load().TryGetValue(key, out v) ? v : def;
        }

        public static void Set(string key, string value)
        {
            try
            {
                var d = Load();
                d[key] = value ?? "";
                Directory.CreateDirectory(Path.GetDirectoryName(SettingsPath));
                var lines = new List<string>();
                foreach (var kv in d) lines.Add(kv.Key + "=" + kv.Value);
                File.WriteAllLines(SettingsPath, lines.ToArray());
            }
            catch { }
        }

        /// <summary>Candidate library folders in priority order (excluding the saved one).</summary>
        public static List<string> Candidates()
        {
            var list = new List<string>();
            try
            {
                string dllDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? "";
                if (dllDir.Length > 0)
                {
                    // DLL in {app}\Support -> {app}\Dwg3D ; DLL elsewhere -> {dll}\Dwg3D, {dll}\..\Dwg3D
                    list.Add(Path.GetFullPath(Path.Combine(dllDir, "..", "Dwg3D")));
                    list.Add(Path.Combine(dllDir, "Dwg3D"));
                    list.Add(Path.GetFullPath(Path.Combine(dllDir, "..", "..", "Dwg3D")));
                }
            }
            catch { }
            list.Add(DeveloperDefault);
            return list;
        }

        /// <summary>The folder to use: saved (if it still exists), else first existing candidate, else developer default.</summary>
        public static string ResolveFolder()
        {
            string saved = Get("Folder", "");
            if (saved.Length > 0 && Directory.Exists(saved)) return saved;
            foreach (var c in Candidates())
                if (Directory.Exists(c) && (File.Exists(Path.Combine(c, Dwg3DLibDb.DbFileName)) || Directory.GetFiles(c, "*.dwg").Length > 0))
                    return c;
            return DeveloperDefault;
        }

        public static string DbPath(string folder) { return Path.Combine(folder, Dwg3DLibDb.DbFileName); }
    }
}
