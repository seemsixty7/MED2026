using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.Data.Common;
using System.IO;
using System.Reflection;

namespace MEDDotNet
{
    /// <summary>
    /// DB update path for existing installs (Patch never ships MED.db; Setup renames an existing one).
    /// Runs before the other startup migrations (MedUserProject, MedODSeed):
    ///  1. Backup: the first time a new MED-DotNet version opens a SQLite MED.db, it is copied to
    ///     MED.db.bak-YYYYMMDD-HHMMSS before anything changes (marker file MED.db.medver).
    ///  2. Schema check: adds missing nullable MEDType columns. Missing core tables are only logged.
    ///  3. Ductbank seed: inserts missing MEDType rows from Data\seed\ductbank_medtype.csv and fills a blank
    ///     ITEMDESC (DBSEED logic, no prompt).
    /// MEDDBUPDATE runs the same steps on demand (and the OD/LastProject migrations) and reports.
    /// </summary>
    internal static class MedDbUpdate
    {
        public const string DuctbankSeedFile = "ductbank_medtype.csv";
        static readonly string[] MedTypeOptionalColumns =
            { "ITEM_GRP", "ITEMKEY1", "ITEMKEY2", "ITEMKEY3", "ITEMKEY4", "USER1", "USER2", "USER3", "USER4" };
        static readonly string[] CoreTables = { "MEDType", "MEDUsers", "MEDProject" };

        static string Version { get { return Assembly.GetExecutingAssembly().GetName().Version.ToString(); } }

        /// <summary>Startup entry. Never throws.</summary>
        public static void EnsureReady()
        {
            try { Run(false); }
            catch (System.Exception ex) { MedDebug.Warn("DB update", ex); }
        }

        [CommandMethod("MEDDBUPDATE")]
        public static void Command()
        {
            try
            {
                string msg = Run(true);
                try { MedUserProject.EnsureReady(true); } catch (System.Exception ex) { msg += "\n LastProject: " + ex.Message; }
                try { MedODSeed.EnsureReady(); } catch (System.Exception ex) { msg += "\n OD seed: " + ex.Message; }
                Say("MEDDBUPDATE:" + msg);
            }
            catch (System.Exception ex) { Say("MEDDBUPDATE failed: " + ex.Message); }
        }

        /// <returns>Report text.</returns>
        static string Run(bool forceBackup)
        {
            string report = "";
            string db = ProcessSQL.SqliteDatabasePath();
            if (db != null && File.Exists(db))
            {
                string marker = db + ".medver";
                string seen = File.Exists(marker) ? File.ReadAllText(marker).Trim() : "";
                if (forceBackup || seen != Version)
                {
                    string bak = db + ".bak-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");
                    File.Copy(db, bak, false);
                    File.WriteAllText(marker, Version);
                    report += "\n Backup: " + bak;
                }
            }
            else if (db == null)
                report += "\n SQL Server database: no file backup (back it up in SQL Server first).";

            using (DbConnection conn = ProcessSQL.OpenConnection())
            {
                foreach (string t in CoreTables)
                    if (!TableExists(conn, t))
                        report += "\n Missing table " + t + " (not created automatically; restore MED.db or contact Moore Design).";

                if (TableExists(conn, "MEDType"))
                {
                    var have = Columns(conn, "MEDType");
                    foreach (string c in MedTypeOptionalColumns)
                    {
                        if (have.Contains(c.ToUpperInvariant())) continue;
                        using (DbCommand cmd = conn.CreateCommand())
                        {
                            cmd.CommandText = ProcessSQL.IsSqlite
                                ? "ALTER TABLE MEDType ADD COLUMN " + c + " TEXT NULL"
                                : "ALTER TABLE MEDType ADD " + c + " nvarchar(255) NULL";
                            cmd.ExecuteNonQuery();
                        }
                        report += "\n Added column MEDType." + c;
                    }

                    string dir = MedODSeed.FindSeedDir();
                    if (dir != null)
                    {
                        int added, filled;
                        SeedMedType(conn, Path.Combine(dir, DuctbankSeedFile), out added, out filled);
                        if (added + filled > 0 || forceBackup)
                            report += "\n Ductbank MEDType rows: " + added + " added, " + filled + " descriptions filled.";
                    }
                }
            }
            if (report.Length > 0) MedDebug.Note("DB update:" + report.Replace("\n", " |"));
            return report.Length > 0 ? report : "\n Nothing to do.";
        }

        static bool TableExists(DbConnection conn, string table)
        {
            using (DbCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = ProcessSQL.IsSqlite
                    ? "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=@t COLLATE NOCASE"
                    : "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME=@t";
                ProcessSQL.AddParam(cmd, "@t", table);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        static HashSet<string> Columns(DbConnection conn, string table)
        {
            var r = new HashSet<string>();
            using (DbCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = ProcessSQL.IsSqlite
                    ? "PRAGMA table_info(" + table + ")"
                    : "SELECT COLUMN_NAME AS name FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='" + table + "'";
                using (DbDataReader rd = cmd.ExecuteReader())
                    while (rd.Read()) r.Add(Convert.ToString(rd["name"]).ToUpperInvariant());
            }
            return r;
        }

        /// <summary>Idempotent DBSEED: missing (ITEMTYPE, ITEMCODE) rows inserted, blank ITEMDESC filled.</summary>
        internal static void SeedMedType(DbConnection conn, string csvPath, out int added, out int filled)
        {
            added = 0; filled = 0;
            if (!File.Exists(csvPath)) return;
            string[] lines = File.ReadAllLines(csvPath);
            using (DbTransaction tx = conn.BeginTransaction())
            {
                for (int i = 1; i < lines.Length; i++)
                {
                    List<string> f = SplitCsv(lines[i]);
                    int code;
                    if (f.Count < 3 || !int.TryParse(f[1].Trim(), out code)) continue;
                    foreach (string sql in new[] {
                        "INSERT INTO MEDType (ITEMTYPE, ITEMCODE, ITEMDESC) SELECT @t, @c, @d WHERE NOT EXISTS (SELECT 1 FROM MEDType WHERE ITEMTYPE=@t AND ITEMCODE=@c)",
                        "UPDATE MEDType SET ITEMDESC=@d WHERE ITEMTYPE=@t AND ITEMCODE=@c AND LTRIM(RTRIM(COALESCE(ITEMDESC,'')))=''" })
                    {
                        using (DbCommand cmd = conn.CreateCommand())
                        {
                            cmd.Transaction = tx;
                            cmd.CommandText = sql;
                            ProcessSQL.AddParam(cmd, "@t", f[0].Trim());
                            ProcessSQL.AddParam(cmd, "@c", code);
                            ProcessSQL.AddParam(cmd, "@d", f[2].Trim());
                            int n = cmd.ExecuteNonQuery();
                            if (sql.StartsWith("INSERT")) added += n; else filled += n;
                        }
                    }
                }
                tx.Commit();
            }
        }

        static List<string> SplitCsv(string line)
        {
            var r = new List<string>();
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

        static void Say(string msg)
        {
            try
            {
                Document d = Application.DocumentManager.MdiActiveDocument;
                if (d != null) d.Editor.WriteMessage("\n" + msg + "\n");
            }
            catch { }
        }
    }
}
