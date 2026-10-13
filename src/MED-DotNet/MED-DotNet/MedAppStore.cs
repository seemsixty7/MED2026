using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Data.SQLite;
using System.IO;
using System.Reflection;

namespace MEDDotNet
{
    /// <summary>
    /// Autodesk App Store bundle support. When MED-DotNet.dll is loaded from
    /// ...\MED2026.bundle\Contents\..., first-run setup seeds a writable per-user
    /// folder at %APPDATA%\MooreDesign\MED2026 (Program Files is read-only).
    /// No registry/profile edits here; support path + TRUSTEDPATHS are set by MEDFIRSTRUN (MED2026-Bundle.lsp); the
    /// Autoloader puts the bundle's own Support folder on the path and trusts it.
    /// </summary>
    public static class MedAppStore
    {
        public const string PrivacyUrl = "https://mooredesign.net/privacy/";
        public const string WebsiteUrl = "https://mooredesign.net/";

        public static string UserRoot
        {
            get
            {
                return Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    "MooreDesign", "MED2026");
            }
        }
        public static string UserSupport { get { return Path.Combine(UserRoot, "Support"); } }
        public static string UserData { get { return Path.Combine(UserRoot, "Data"); } }

        /// <summary>Contents folder of the bundle, or null when not running from a .bundle.</summary>
        public static string BundleContents
        {
            get
            {
                string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? "";
                // DLL lives in Contents\Win64 (or Contents\Support)
                DirectoryInfo d = new DirectoryInfo(dir);
                while (d != null)
                {
                    if (string.Equals(d.Name, "Contents", StringComparison.OrdinalIgnoreCase)
                        && d.Parent != null
                        && d.Parent.Name.EndsWith(".bundle", StringComparison.OrdinalIgnoreCase))
                        return d.FullName;
                    d = d.Parent;
                }
                return null;
            }
        }

        public static bool IsBundle { get { return BundleContents != null; } }

        // Per-user files that MED reads/writes. Copied only if missing so user edits survive updates.
        static readonly string[] SeedSupportFiles =
        {
            "med.spc", "MOTOR.DAT", "medblck.dat", "setup.add", "QKEY.lsp"
        };

        /// <summary>Run on Initialize. Safe to call repeatedly; never overwrites user files.</summary>
        public static void EnsureFirstRun()
        {
            string contents = BundleContents;
            if (contents == null)
                return; // classic Setup.exe install: leave everything as-is

            bool firstRun = !Directory.Exists(UserRoot);
            Directory.CreateDirectory(UserSupport);
            Directory.CreateDirectory(UserData);

            string bundleSupport = Path.Combine(contents, "Support");
            string bundleData = Path.Combine(contents, "Data");
            string bundleDwg = Path.Combine(contents, "Dwg");

            foreach (string f in SeedSupportFiles)
                CopyIfMissing(Path.Combine(bundleSupport, f), Path.Combine(UserSupport, f));

            string db = Path.Combine(UserData, "MED.db");
            CopyIfMissing(Path.Combine(bundleData, "MED.db"), db);

            // Project.dat: line0 db name, lines1-3 MED dirs (writable), line4 block library (read-only ok).
            string projectDat = Path.Combine(UserSupport, "Project.dat");
            if (!File.Exists(projectDat))
            {
                string dwgDir = Directory.Exists(bundleDwg) ? bundleDwg : Path.Combine(UserRoot, "Dwg");
                Directory.CreateDirectory(dwgDir);
                File.WriteAllLines(projectDat, new[] { "MED.db", UserSupport, UserSupport, UserSupport, dwgDir });
            }

            string settings = Path.Combine(UserSupport, "MEDDataBaseSettings.dat");
            if (!File.Exists(settings))
                File.WriteAllLines(settings, new[] { "Provider=SQLite", "ConnectString=Data Source=" + db });

            // MEDUsers row: idempotent, run every start (the bundle LISP may have seeded the folder first).
            {
                try
                {
                    using (var conn = new SQLiteConnection("Data Source=" + db))
                    {
                        conn.Open();
                        using (var cmd = conn.CreateCommand())
                        {
                            cmd.CommandText = "INSERT INTO MEDUsers (UserName, UserType, DefaultSpec) SELECT @u, @t, @s WHERE NOT EXISTS (SELECT 1 FROM MEDUsers WHERE UserName = @u)";
                            cmd.Parameters.AddWithValue("@u", Environment.UserName);
                            cmd.Parameters.AddWithValue("@t", "User");
                            cmd.Parameters.AddWithValue("@s", "");
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
                catch (System.Exception ex) { LogStartup("MEDUsers seed", ex); }
            }
            // Ductbank FITTING codes (DBSEED logic, no prompt): fixes APPDATA DBs seeded before 1013a r4.
            try
            {
                int added, filled;
                SeedMedType(db, Path.Combine(bundleData, "seed", "ductbank_medtype.csv"), out added, out filled);
            }
            catch (System.Exception ex) { LogStartup("MEDType ductbank seed", ex); }

            if (firstRun)
            {
                Document doc = Application.DocumentManager.MdiActiveDocument;
                if (doc != null)
                    doc.Editor.WriteMessage("\nMED2026 first-run setup: user files created in " + UserRoot);
            }
        }

        /// <summary>Idempotent DBSEED: inserts missing MEDType rows from the csv and fills blank ITEMDESC. Never prompts.</summary>
        public static void SeedMedType(string db, string csvPath, out int added, out int filled)
        {
            added = 0; filled = 0;
            if (!File.Exists(db) || !File.Exists(csvPath)) return;
            string[] lines = File.ReadAllLines(csvPath);
            using (var conn = new SQLiteConnection("Data Source=" + db))
            {
                conn.Open();
                using (var tx = conn.BeginTransaction())
                {
                    for (int i = 1; i < lines.Length; i++)
                    {
                        var f = SplitCsv(lines[i]);
                        int code;
                        if (f.Count < 3 || !int.TryParse(f[1].Trim(), out code)) continue;
                        string type = f[0].Trim(), desc = f[2].Trim();
                        using (var cmd = conn.CreateCommand())
                        {
                            cmd.Transaction = tx;
                            cmd.Parameters.AddWithValue("@t", type);
                            cmd.Parameters.AddWithValue("@c", code);
                            cmd.Parameters.AddWithValue("@d", desc);
                            cmd.CommandText = "INSERT INTO MEDType (ITEMTYPE, ITEMCODE, ITEMDESC) SELECT @t, @c, @d WHERE NOT EXISTS (SELECT 1 FROM MEDType WHERE ITEMTYPE=@t AND ITEMCODE=@c)";
                            added += cmd.ExecuteNonQuery();
                            cmd.CommandText = "UPDATE MEDType SET ITEMDESC=@d WHERE ITEMTYPE=@t AND ITEMCODE=@c AND TRIM(COALESCE(ITEMDESC,''))=''";
                            filled += cmd.ExecuteNonQuery();
                        }
                    }
                    tx.Commit();
                }
            }
        }

        static System.Collections.Generic.List<string> SplitCsv(string line)
        {
            var r = new System.Collections.Generic.List<string>();
            var sb = new System.Text.StringBuilder();
            bool q = false;
            for (int i = 0; i < line.Length; i++)
            {
                char ch = line[i];
                if (q)
                {
                    if (ch == '"' && i + 1 < line.Length && line[i + 1] == '"') { sb.Append('"'); i++; }
                    else if (ch == '"') q = false;
                    else sb.Append(ch);
                }
                else if (ch == '"') q = true;
                else if (ch == ',') { r.Add(sb.ToString()); sb.Clear(); }
                else sb.Append(ch);
            }
            r.Add(sb.ToString());
            return r;
        }

        /// <summary>(MED-SeedMedType) runs the ductbank MEDType seed on the APPDATA MED.db; returns (added filled) or nil.</summary>
        [LispFunction("MED-SeedMedType")]
        public static object LispSeedMedType(ResultBuffer args)
        {
            string contents = BundleContents;
            if (contents == null) return null;
            try
            {
                int a, f;
                SeedMedType(Path.Combine(UserData, "MED.db"), Path.Combine(contents, "Data", "seed", "ductbank_medtype.csv"), out a, out f);
                return new ResultBuffer(new TypedValue((int)LispDataType.Int32, a), new TypedValue((int)LispDataType.Int32, f));
            }
            catch (System.Exception ex) { LogStartup("MED-SeedMedType", ex); return null; }
        }

        /// <summary>Logs a startup/event exception to %APPDATA%\MooreDesign\MED2026\MED-startup.log and the command line. Never throws.</summary>
        public static void LogStartup(string where, System.Exception ex)
        {
            try
            {
                Directory.CreateDirectory(UserRoot);
                File.AppendAllText(Path.Combine(UserRoot, "MED-startup.log"),
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " [" + where + "] " + ex + Environment.NewLine);
            }
            catch { }
            try
            {
                Document doc = Application.DocumentManager.MdiActiveDocument;
                if (doc != null)
                    doc.Editor.WriteMessage("\nMED2026: " + where + " failed (" + ex.Message + "). Details: " + Path.Combine(UserRoot, "MED-startup.log"));
            }
            catch { }
        }

        static void CopyIfMissing(string src, string dst)
        {
            try
            {
                if (File.Exists(src) && !File.Exists(dst))
                    File.Copy(src, dst);
            }
            catch (System.Exception) { }
        }

        /// <summary>(MED-UserRoot) returns the per-user folder with trailing backslash, or nil when not a bundle install.</summary>
        [LispFunction("MED-UserRoot")]
        public static object LispUserRoot(ResultBuffer args)
        {
            if (!IsBundle) return null;
            return UserSupport + "\\";
        }

        [CommandMethod("MEDPRIVACY")]
        public static void Privacy()
        {
            OpenUrl(PrivacyUrl);
        }

        [CommandMethod("MEDABOUT")]
        public static void About()
        {
            string ver = Assembly.GetExecutingAssembly().GetName().Version.ToString();
            string where = IsBundle ? ("App Store bundle\nUser files: " + UserRoot) : "Classic install";
            var r = System.Windows.Forms.MessageBox.Show(
                "MED2026 (Moore Design)\nVersion " + ver + "\n" + where +
                "\n\n" + WebsiteUrl + "\nPrivacy policy: " + PrivacyUrl +
                "\n\nOpen the privacy policy now?",
                "About MED2026", System.Windows.Forms.MessageBoxButtons.YesNo,
                System.Windows.Forms.MessageBoxIcon.Information);
            if (r == System.Windows.Forms.DialogResult.Yes)
                OpenUrl(PrivacyUrl);
        }

        static void OpenUrl(string url)
        {
            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url) { UseShellExecute = true }); }
            catch (System.Exception ex)
            {
                Document doc = Application.DocumentManager.MdiActiveDocument;
                if (doc != null) doc.Editor.WriteMessage("\nOpen " + url + " (" + ex.Message + ")");
            }
        }
    }
}
