using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;

namespace MEDDotNet
{
    /// <summary>
    /// Idempotent OD data migration for existing installs (patch ships Data\seed\*.csv, never MED.db):
    ///  - creates MEDConduitOD (SQLite or SQL Server) and inserts missing rows from conduit_od.csv
    ///    (existing rows are never overwritten; only a NULL OD_in is filled from the seed);
    ///  - fills MEDType.USER3 (cable OD, inches) for CABLE rows only where USER3 is blank and
    ///    ITEMDESC still matches the seed row (user-renumbered/edited codes are left alone);
    ///  - creates MEDConduitBody (rigid conduit body dimensions, MED3DFittings.lsp) and inserts
    ///    missing rows from conduit_body_dims.csv; only NULL dimension columns are filled;
    ///  - fills MEDType.ITEMKEY2 (conduit body key, e.g. RGD|F7|LB, used by MEDMAKE3D) for
    ///    FITTING rows from fitting_body_keys.csv, only where ITEMKEY2 is blank and ITEMDESC
    ///    still matches the seed row.
    /// Pattern follows MedUserProject (runtime schema change, no scripts).
    /// </summary>
    internal static class MedODSeed
    {
        static readonly object Gate = new object();
        static bool _done;

        public const string ConduitSeedFile = "conduit_od.csv";
        public const string CableSeedFile = "cable_od_sources.csv";
        public const string ConduitBodySeedFile = "conduit_body_dims.csv";
        public const string FittingBodyKeySeedFile = "fitting_body_keys.csv";

        public static void EnsureReady()
        {
            lock (Gate)
            {
                if (_done)
                    return;
                try
                {
                    EnsureConduitOdTable();
                    EnsureConduitBodyTable();
                    string dir = FindSeedDir();
                    if (dir != null)
                    {
                        SeedConduitOd(Path.Combine(dir, ConduitSeedFile));
                        SeedCableOd(Path.Combine(dir, CableSeedFile));
                        SeedConduitBody(Path.Combine(dir, ConduitBodySeedFile));
                        SeedFittingBodyKeys(Path.Combine(dir, FittingBodyKeySeedFile));
                    }
                    _done = true;
                }
                catch (System.Exception ex)
                {
                    // DB may be unavailable at early load; next call retries.
                    MedDebug.Warn("OD seed (MEDConduitOD / CABLE USER3)", ex);
                }
            }
        }

        public static void EnsureConduitOdTable()
        {
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbCommand cmd = conn.CreateCommand())
            {
                if (ProcessSQL.IsSqlite)
                {
                    cmd.CommandText =
                        "CREATE TABLE IF NOT EXISTS MEDConduitOD ("
                        + "ConduitCode INTEGER NOT NULL, "
                        + "ConduitDesc TEXT, "
                        + "TradeSize TEXT NOT NULL, "
                        + "TradeSizeDec REAL, "
                        + "OD_in REAL, "
                        + "Source TEXT, "
                        + "PRIMARY KEY (ConduitCode, TradeSize))";
                }
                else
                {
                    cmd.CommandText =
                        "IF OBJECT_ID(N'dbo.MEDConduitOD', N'U') IS NULL "
                        + "CREATE TABLE dbo.MEDConduitOD ("
                        + "ConduitCode int NOT NULL, "
                        + "ConduitDesc nvarchar(100) NULL, "
                        + "TradeSize nvarchar(10) NOT NULL, "
                        + "TradeSizeDec float NULL, "
                        + "OD_in float NULL, "
                        + "Source nvarchar(400) NULL, "
                        + "CONSTRAINT PK_MEDConduitOD PRIMARY KEY (ConduitCode, TradeSize))";
                }
                cmd.ExecuteNonQuery();
            }
        }

        /// <summary>Rigid conduit body dimensions (inches) per Form + Shape + trade size (MED3DFittings.lsp).</summary>
        public static void EnsureConduitBodyTable()
        {
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbCommand cmd = conn.CreateCommand())
            {
                if (ProcessSQL.IsSqlite)
                {
                    cmd.CommandText =
                        "CREATE TABLE IF NOT EXISTS MEDConduitBody ("
                        + "Mfr TEXT, Form TEXT NOT NULL, Shape TEXT NOT NULL, TradeSize TEXT NOT NULL, "
                        + "TradeSizeDec REAL, CatalogNo TEXT, "
                        + "A_in REAL, B_in REAL, C_in REAL, D_in REAL, E_in REAL, HubOD_in REAL, HubLen_in REAL, "
                        + "Source TEXT, PRIMARY KEY (Form, Shape, TradeSize))";
                }
                else
                {
                    cmd.CommandText =
                        "IF OBJECT_ID(N'dbo.MEDConduitBody', N'U') IS NULL "
                        + "CREATE TABLE dbo.MEDConduitBody ("
                        + "Mfr nvarchar(50) NULL, Form nvarchar(10) NOT NULL, Shape nvarchar(10) NOT NULL, "
                        + "TradeSize nvarchar(10) NOT NULL, TradeSizeDec float NULL, CatalogNo nvarchar(20) NULL, "
                        + "A_in float NULL, B_in float NULL, C_in float NULL, D_in float NULL, E_in float NULL, "
                        + "HubOD_in float NULL, HubLen_in float NULL, Source nvarchar(400) NULL, "
                        + "CONSTRAINT PK_MEDConduitBody PRIMARY KEY (Form, Shape, TradeSize))";
                }
                cmd.ExecuteNonQuery();
            }
        }

        static readonly string[] ConduitBodyDims = { "A_in", "B_in", "C_in", "D_in", "E_in", "HubOD_in", "HubLen_in" };

        static void SeedConduitBody(string path)
        {
            if (!File.Exists(path))
                return;
            List<string[]> rows = ReadCsv(path);
            if (rows.Count < 2)
                return;
            Dictionary<string, int> map = HeaderMap(rows[0]);
            bool sqlite = ProcessSQL.IsSqlite;
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbTransaction tx = conn.BeginTransaction())
            {
                for (int i = 1; i < rows.Count; i++)
                {
                    string[] r = rows[i];
                    string form = Get(r, map, "Form");
                    string shape = Get(r, map, "Shape");
                    string ts = Get(r, map, "TradeSize");
                    if (form.Length == 0 || shape.Length == 0 || ts.Length == 0)
                        continue;
                    using (DbCommand cmd = conn.CreateCommand())
                    {
                        cmd.Transaction = tx;
                        string cols = "Mfr, Form, Shape, TradeSize, TradeSizeDec, CatalogNo, A_in, B_in, C_in, D_in, E_in, HubOD_in, HubLen_in, Source";
                        string vals = "@m, @f, @s, @t, @td, @cat, @A_in, @B_in, @C_in, @D_in, @E_in, @HubOD_in, @HubLen_in, @src";
                        cmd.CommandText = sqlite
                            ? "INSERT OR IGNORE INTO MEDConduitBody (" + cols + ") VALUES (" + vals + ")"
                            : "IF NOT EXISTS (SELECT 1 FROM MEDConduitBody WHERE Form = @f AND Shape = @s AND TradeSize = @t) "
                              + "INSERT INTO MEDConduitBody (" + cols + ") VALUES (" + vals + ")";
                        string mfr = Get(r, map, "Mfr");
                        string cat = Get(r, map, "CatalogNo");
                        string src = Get(r, map, "Source");
                        ProcessSQL.AddParam(cmd, "@m", mfr.Length == 0 ? (object)DBNull.Value : Trunc(mfr, 50));
                        ProcessSQL.AddParam(cmd, "@f", Trunc(form, 10));
                        ProcessSQL.AddParam(cmd, "@s", Trunc(shape, 10));
                        ProcessSQL.AddParam(cmd, "@t", Trunc(ts, 10));
                        ProcessSQL.AddParam(cmd, "@td", Num(Get(r, map, "TradeSizeDec")));
                        ProcessSQL.AddParam(cmd, "@cat", cat.Length == 0 ? (object)DBNull.Value : Trunc(cat, 20));
                        foreach (string c in ConduitBodyDims)
                            ProcessSQL.AddParam(cmd, "@" + c, Num(Get(r, map, c)));
                        ProcessSQL.AddParam(cmd, "@src", src.Length == 0 ? (object)DBNull.Value : Trunc(src, 400));
                        cmd.ExecuteNonQuery();
                    }
                    // Fill only missing dimensions (never overwrite a user-entered value).
                    foreach (string c in ConduitBodyDims)
                    {
                        object v = Num(Get(r, map, c));
                        if (v == DBNull.Value)
                            continue;
                        using (DbCommand upd = conn.CreateCommand())
                        {
                            upd.Transaction = tx;
                            upd.CommandText = "UPDATE MEDConduitBody SET " + c + " = @v "
                                + "WHERE Form = @f AND Shape = @s AND TradeSize = @t AND " + c + " IS NULL";
                            ProcessSQL.AddParam(upd, "@v", v);
                            ProcessSQL.AddParam(upd, "@f", Trunc(form, 10));
                            ProcessSQL.AddParam(upd, "@s", Trunc(shape, 10));
                            ProcessSQL.AddParam(upd, "@t", Trunc(ts, 10));
                            upd.ExecuteNonQuery();
                        }
                    }
                }
                tx.Commit();
            }
        }

        /// <summary>Data\seed next to the SQLite DB, else {app}\Data\seed relative to Support\MED-DotNet.dll.</summary>
        static string FindSeedDir()
        {
            List<string> candidates = new List<string>();
            string dataDir = ProcessSQL.SqliteDataDirectory();
            if (!string.IsNullOrEmpty(dataDir))
                candidates.Add(Path.Combine(dataDir, "seed"));
            string dllDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? "";
            candidates.Add(Path.Combine(dllDir, "..", "Data", "seed"));
            candidates.Add(Path.Combine(dllDir, "Data", "seed"));
            foreach (string c in candidates)
            {
                try
                {
                    if (File.Exists(Path.Combine(c, ConduitSeedFile)) || File.Exists(Path.Combine(c, CableSeedFile))
                        || File.Exists(Path.Combine(c, ConduitBodySeedFile))
                        || File.Exists(Path.Combine(c, FittingBodyKeySeedFile)))
                        return Path.GetFullPath(c);
                }
                catch (System.Exception)
                {
                }
            }
            return null;
        }

        static void SeedConduitOd(string path)
        {
            if (!File.Exists(path))
                return;
            List<string[]> rows = ReadCsv(path);
            if (rows.Count < 2)
                return;
            Dictionary<string, int> map = HeaderMap(rows[0]);
            bool sqlite = ProcessSQL.IsSqlite;
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbTransaction tx = conn.BeginTransaction())
            {
                for (int i = 1; i < rows.Count; i++)
                {
                    string[] r = rows[i];
                    int code;
                    if (!int.TryParse(Get(r, map, "ConduitCode"), NumberStyles.Integer, CultureInfo.InvariantCulture, out code))
                        continue;
                    string ts = Get(r, map, "TradeSize");
                    if (ts.Length == 0)
                        continue;
                    object tsDec = Num(Get(r, map, "TradeSizeDec"));
                    object od = Num(Get(r, map, "OD_in"));
                    string desc = Get(r, map, "ConduitDesc");
                    string src = Get(r, map, "Source");

                    using (DbCommand cmd = conn.CreateCommand())
                    {
                        cmd.Transaction = tx;
                        if (sqlite)
                        {
                            cmd.CommandText =
                                "INSERT OR IGNORE INTO MEDConduitOD (ConduitCode, ConduitDesc, TradeSize, TradeSizeDec, OD_in, Source) "
                                + "VALUES (@c, @d, @t, @td, @od, @s)";
                        }
                        else
                        {
                            cmd.CommandText =
                                "IF NOT EXISTS (SELECT 1 FROM MEDConduitOD WHERE ConduitCode = @c AND TradeSize = @t) "
                                + "INSERT INTO MEDConduitOD (ConduitCode, ConduitDesc, TradeSize, TradeSizeDec, OD_in, Source) "
                                + "VALUES (@c, @d, @t, @td, @od, @s)";
                        }
                        AddRowParams(cmd, code, desc, ts, tsDec, od, src);
                        cmd.ExecuteNonQuery();
                    }

                    if (od != DBNull.Value)
                    {
                        // Fill only a missing OD (never overwrite a user-entered value).
                        using (DbCommand upd = conn.CreateCommand())
                        {
                            upd.Transaction = tx;
                            upd.CommandText =
                                "UPDATE MEDConduitOD SET OD_in = @od, Source = @s "
                                + "WHERE ConduitCode = @c AND TradeSize = @t AND OD_in IS NULL";
                            ProcessSQL.AddParam(upd, "@od", od);
                            ProcessSQL.AddParam(upd, "@s", Trunc(src, 400));
                            ProcessSQL.AddParam(upd, "@c", code);
                            ProcessSQL.AddParam(upd, "@t", ts);
                            upd.ExecuteNonQuery();
                        }
                    }
                }
                tx.Commit();
            }
        }

        static void AddRowParams(DbCommand cmd, int code, string desc, string ts, object tsDec, object od, string src)
        {
            ProcessSQL.AddParam(cmd, "@c", code);
            ProcessSQL.AddParam(cmd, "@d", desc.Length == 0 ? (object)DBNull.Value : Trunc(desc, 100));
            ProcessSQL.AddParam(cmd, "@t", Trunc(ts, 10));
            ProcessSQL.AddParam(cmd, "@td", tsDec);
            ProcessSQL.AddParam(cmd, "@od", od);
            ProcessSQL.AddParam(cmd, "@s", src.Length == 0 ? (object)DBNull.Value : Trunc(src, 400));
        }

        static void SeedCableOd(string path)
        {
            if (!File.Exists(path))
                return;
            List<string[]> rows = ReadCsv(path);
            if (rows.Count < 2)
                return;
            Dictionary<string, int> map = HeaderMap(rows[0]);
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbTransaction tx = conn.BeginTransaction())
            {
                for (int i = 1; i < rows.Count; i++)
                {
                    string[] r = rows[i];
                    long code;
                    if (!long.TryParse(Get(r, map, "ITEMCODE"), NumberStyles.Integer, CultureInfo.InvariantCulture, out code))
                        continue;
                    string od = Get(r, map, "OD_in");
                    double odVal;
                    if (od.Length == 0
                        || !double.TryParse(od, NumberStyles.Float, CultureInfo.InvariantCulture, out odVal)
                        || odVal <= 0)
                        continue;
                    string desc = Get(r, map, "ITEMDESC");
                    using (DbCommand cmd = conn.CreateCommand())
                    {
                        cmd.Transaction = tx;
                        cmd.CommandText =
                            "UPDATE MEDType SET USER3 = @od "
                            + "WHERE ITEMTYPE = 'CABLE' AND ITEMCODE = @c "
                            + "AND (USER3 IS NULL OR LTRIM(RTRIM(USER3)) = '') "
                            + "AND UPPER(LTRIM(RTRIM(ITEMDESC))) = @d";
                        ProcessSQL.AddParam(cmd, "@od", od);
                        ProcessSQL.AddParam(cmd, "@c", code);
                        ProcessSQL.AddParam(cmd, "@d", desc.Trim().ToUpperInvariant());
                        cmd.ExecuteNonQuery();
                    }
                }
                tx.Commit();
            }
            MedTypeLookup.ClearCache();
        }

        /// <summary>MEDType.ITEMKEY2 = conduit body key on FITTING rows (blank + same description only).</summary>
        static void SeedFittingBodyKeys(string path)
        {
            if (!File.Exists(path))
                return;
            List<string[]> rows = ReadCsv(path);
            if (rows.Count < 2)
                return;
            Dictionary<string, int> map = HeaderMap(rows[0]);
            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbTransaction tx = conn.BeginTransaction())
            {
                for (int i = 1; i < rows.Count; i++)
                {
                    string[] r = rows[i];
                    long code;
                    if (!long.TryParse(Get(r, map, "ITEMCODE"), NumberStyles.Integer, CultureInfo.InvariantCulture, out code))
                        continue;
                    string key = Get(r, map, "BodyKey");
                    if (key.Length == 0)
                        continue;
                    string desc = Get(r, map, "ITEMDESC");
                    using (DbCommand cmd = conn.CreateCommand())
                    {
                        cmd.Transaction = tx;
                        cmd.CommandText =
                            "UPDATE MEDType SET ITEMKEY2 = @k "
                            + "WHERE ITEMTYPE = 'FITTING' AND ITEMCODE = @c "
                            + "AND (ITEMKEY2 IS NULL OR LTRIM(RTRIM(ITEMKEY2)) = '') "
                            + "AND UPPER(LTRIM(RTRIM(ITEMDESC))) = @d";
                        ProcessSQL.AddParam(cmd, "@k", Trunc(key, 20));
                        ProcessSQL.AddParam(cmd, "@c", code);
                        ProcessSQL.AddParam(cmd, "@d", desc.Trim().ToUpperInvariant());
                        cmd.ExecuteNonQuery();
                    }
                }
                tx.Commit();
            }
            MedTypeLookup.ClearCache();
        }

        static object Num(string s)
        {
            double d;
            if (!string.IsNullOrWhiteSpace(s)
                && double.TryParse(s.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out d))
                return d;
            return DBNull.Value;
        }

        static string Trunc(string v, int max)
        {
            if (v == null) return "";
            return v.Length <= max ? v : v.Substring(0, max);
        }

        static Dictionary<string, int> HeaderMap(string[] header)
        {
            Dictionary<string, int> map = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < header.Length; i++)
            {
                string h = (header[i] ?? "").Trim().TrimStart('\uFEFF');
                if (h.Length > 0 && !map.ContainsKey(h))
                    map[h] = i;
            }
            return map;
        }

        static string Get(string[] cells, Dictionary<string, int> map, string name)
        {
            int i;
            if (!map.TryGetValue(name, out i) || i < 0 || i >= cells.Length)
                return "";
            return (cells[i] ?? "").Trim();
        }

        /// <summary>Minimal RFC 4180 reader (quoted fields, doubled quotes, CRLF/LF).</summary>
        internal static List<string[]> ReadCsv(string path)
        {
            List<string[]> rows = new List<string[]>();
            string text = File.ReadAllText(path, Encoding.UTF8);
            List<string> cur = new List<string>();
            StringBuilder field = new StringBuilder();
            bool inQuotes = false;
            for (int i = 0; i < text.Length; i++)
            {
                char ch = text[i];
                if (inQuotes)
                {
                    if (ch == '"')
                    {
                        if (i + 1 < text.Length && text[i + 1] == '"')
                        {
                            field.Append('"');
                            i++;
                        }
                        else
                            inQuotes = false;
                    }
                    else
                        field.Append(ch);
                    continue;
                }
                if (ch == '"')
                    inQuotes = true;
                else if (ch == ',')
                {
                    cur.Add(field.ToString());
                    field.Length = 0;
                }
                else if (ch == '\r' || ch == '\n')
                {
                    if (ch == '\r' && i + 1 < text.Length && text[i + 1] == '\n')
                        i++;
                    cur.Add(field.ToString());
                    field.Length = 0;
                    if (!(cur.Count == 1 && cur[0].Length == 0))
                        rows.Add(cur.ToArray());
                    cur.Clear();
                }
                else
                    field.Append(ch);
            }
            if (field.Length > 0 || cur.Count > 0)
            {
                cur.Add(field.ToString());
                rows.Add(cur.ToArray());
            }
            return rows;
        }
    }
}
