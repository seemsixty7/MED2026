using Autodesk.AutoCAD.ApplicationServices;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Windows.Forms;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// MEDUsers LastProject migration + helpers shared by MEDSETTINGS and MEDSHOW.
    /// LOGINNAME matches AutoCAD (getvar "LOGINNAME") / installer $env:USERNAME.
    /// </summary>
    internal static class MedUserProject
    {
        static readonly object Gate = new object();
        static bool _schemaReady;
        static bool _seedApplied;

        public static string LoginName()
        {
            try
            {
                object v = AcadApp.GetSystemVariable("LOGINNAME");
                if (v != null)
                {
                    string s = Convert.ToString(v);
                    if (!string.IsNullOrWhiteSpace(s))
                        return s.Trim();
                }
            }
            catch (System.Exception)
            {
            }
            string env = Environment.UserName;
            return string.IsNullOrWhiteSpace(env) ? "" : env.Trim();
        }

        /// <summary>
        /// Idempotent: add LastProject if missing, upsert current user row, optionally seed _MEDPROJECT once.
        /// </summary>
        public static void EnsureReady(bool applySeed)
        {
            lock (Gate)
            {
                try
                {
                    if (!_schemaReady)
                    {
                        EnsureLastProjectColumn();
                        EnsureCurrentUserRow();
                        _schemaReady = true;
                    }
                    else
                    {
                        EnsureCurrentUserRow();
                    }

                    if (applySeed && !_seedApplied)
                    {
                        ApplyLastProjectSeedCore();
                        _seedApplied = true;
                    }
                }
                catch (System.Exception)
                {
                    // DB may be unavailable at early load; callers retry on UI open.
                }
            }
        }

        public static void EnsureLastProjectColumn()
        {
            using (DbConnection conn = ProcessSQL.OpenConnection())
            {
                if (ProcessSQL.IsSqlite)
                    EnsureLastProjectSqlite(conn);
                else
                    EnsureLastProjectSqlServer(conn);
            }
        }

        static void EnsureLastProjectSqlite(DbConnection conn)
        {
            bool has = false;
            using (DbCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = "PRAGMA table_info(MEDUsers)";
                using (DbDataReader r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        string name = Convert.ToString(r["name"]);
                        if (string.Equals(name, "LastProject", StringComparison.OrdinalIgnoreCase))
                        {
                            has = true;
                            break;
                        }
                    }
                }
            }
            if (has)
                return;
            using (DbCommand alter = conn.CreateCommand())
            {
                alter.CommandText = "ALTER TABLE MEDUsers ADD COLUMN LastProject TEXT NULL";
                alter.ExecuteNonQuery();
            }
        }

        static void EnsureLastProjectSqlServer(DbConnection conn)
        {
            using (DbCommand check = conn.CreateCommand())
            {
                check.CommandText =
                    "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.MEDUsers') AND name = N'LastProject'";
                object n = check.ExecuteScalar();
                int count = 0;
                try { count = Convert.ToInt32(n); }
                catch (System.Exception) { count = 0; }
                if (count > 0)
                    return;
            }
            using (DbCommand alter = conn.CreateCommand())
            {
                alter.CommandText = "ALTER TABLE MEDUsers ADD LastProject nvarchar(50) NULL";
                alter.ExecuteNonQuery();
            }
        }

        public static void EnsureCurrentUserRow()
        {
            string user = LoginName();
            if (string.IsNullOrEmpty(user))
                return;

            using (DbConnection conn = ProcessSQL.OpenConnection())
            using (DbCommand cmd = conn.CreateCommand())
            {
                if (ProcessSQL.IsSqlite)
                {
                    cmd.CommandText =
                        "INSERT OR IGNORE INTO MEDUsers (UserName, UserType, DefaultSpec) VALUES (@u, @t, @s)";
                }
                else
                {
                    cmd.CommandText =
                        "IF NOT EXISTS (SELECT 1 FROM MEDUsers WHERE UserName = @u) "
                        + "INSERT INTO MEDUsers (UserName, UserType, DefaultSpec) VALUES (@u, @t, @s)";
                }
                ProcessSQL.AddParam(cmd, "@u", user);
                ProcessSQL.AddParam(cmd, "@t", "User");
                ProcessSQL.AddParam(cmd, "@s", "");
                cmd.ExecuteNonQuery();
            }
        }

        static void EnsureCurrentUserRow(DbConnection conn)
        {
            string user = LoginName();
            if (string.IsNullOrEmpty(user))
                return;
            using (DbCommand cmd = conn.CreateCommand())
            {
                if (ProcessSQL.IsSqlite)
                {
                    cmd.CommandText =
                        "INSERT OR IGNORE INTO MEDUsers (UserName, UserType, DefaultSpec) VALUES (@u, @t, @s)";
                }
                else
                {
                    cmd.CommandText =
                        "IF NOT EXISTS (SELECT 1 FROM MEDUsers WHERE UserName = @u) "
                        + "INSERT INTO MEDUsers (UserName, UserType, DefaultSpec) VALUES (@u, @t, @s)";
                }
                ProcessSQL.AddParam(cmd, "@u", user);
                ProcessSQL.AddParam(cmd, "@t", "User");
                ProcessSQL.AddParam(cmd, "@s", "");
                cmd.ExecuteNonQuery();
            }
        }

        public static string GetLastProject()
        {
            try
            {
                EnsureReady(false);
                return ReadLastProject();
            }
            catch (System.Exception)
            {
                return "";
            }
        }

        static string ReadLastProject()
        {
            string user = LoginName();
            if (string.IsNullOrEmpty(user))
                return "";
            DataTable dt = ProcessSQL.QueryTable(
                "SELECT LastProject FROM MEDUsers WHERE UserName='" + SqlText(user) + "'");
            if (dt.Rows.Count == 0)
                return "";
            object v = dt.Rows[0]["LastProject"];
            if (v == null || v == DBNull.Value)
                return "";
            return Convert.ToString(v).Trim();
        }

        public static void SetLastProject(string project)
        {
            string user = LoginName();
            if (string.IsNullOrEmpty(user))
                return;
            string p = (project ?? "").Trim();
            if (p.Length == 0)
                return;
            if (p.Length > 50)
                p = p.Substring(0, 50);

            EnsureReady(false);
            using (DbConnection conn = ProcessSQL.OpenConnection())
            {
                using (DbCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "UPDATE MEDUsers SET LastProject = @p WHERE UserName = @u";
                    ProcessSQL.AddParam(cmd, "@p", p);
                    ProcessSQL.AddParam(cmd, "@u", user);
                    int n = cmd.ExecuteNonQuery();
                    if (n != 0)
                        return;
                }
                EnsureCurrentUserRow(conn);
                using (DbCommand cmd2 = conn.CreateCommand())
                {
                    cmd2.CommandText = "UPDATE MEDUsers SET LastProject = @p WHERE UserName = @u";
                    ProcessSQL.AddParam(cmd2, "@p", p);
                    ProcessSQL.AddParam(cmd2, "@u", user);
                    cmd2.ExecuteNonQuery();
                }
            }
        }

        static void ApplyLastProjectSeedCore()
        {
            string last = ReadLastProject();
            if (string.IsNullOrWhiteSpace(last))
                return;
            try
            {
                MedLisp.SetString("_MEDPROJECT", last.Trim());
            }
            catch (System.Exception)
            {
            }
        }

        /// <summary>
        /// Persist project to Lisp + MEDUsers.LastProject.
        /// </summary>
        public static void SetCurrentProject(string project)
        {
            string p = (project ?? "").Trim();
            if (p.Length == 0)
                return;
            MedLisp.Run(delegate { MedLisp.SetString("_MEDPROJECT", p); });
            try { SetLastProject(p); }
            catch (System.Exception) { }
        }

        public static List<string> ListDistinctProjects(string ensureInclude)
        {
            List<string> list = new List<string>();
            HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            try
            {
                DataTable dt = ProcessSQL.QueryTable(
                    "SELECT DISTINCT PROJECTNO FROM MEDProject "
                    + "WHERE PROJECTNO IS NOT NULL AND PROJECTNO <> '' ORDER BY 1");
                foreach (DataRow row in dt.Rows)
                {
                    string p = Convert.ToString(row["PROJECTNO"]);
                    if (string.IsNullOrWhiteSpace(p))
                        continue;
                    p = p.Trim();
                    if (seen.Add(p))
                        list.Add(p);
                }
            }
            catch (System.Exception)
            {
            }

            if (!string.IsNullOrWhiteSpace(ensureInclude))
            {
                string cur = ensureInclude.Trim();
                if (seen.Add(cur))
                    list.Add(cur);
            }
            return list;
        }

        public static void FillProjectCombo(ComboBox cbo, string current)
        {
            if (cbo == null)
                return;
            string cur = string.IsNullOrWhiteSpace(current) ? "PROJECT1" : current.Trim();
            List<string> projects = ListDistinctProjects(cur);
            cbo.BeginUpdate();
            try
            {
                cbo.Items.Clear();
                int sel = -1;
                for (int i = 0; i < projects.Count; i++)
                {
                    cbo.Items.Add(projects[i]);
                    if (string.Equals(projects[i], cur, StringComparison.OrdinalIgnoreCase))
                        sel = i;
                }
                if (sel < 0)
                {
                    cbo.Items.Add(cur);
                    sel = cbo.Items.Count - 1;
                }
                cbo.SelectedIndex = sel;
                cbo.Text = cur;
            }
            finally
            {
                cbo.EndUpdate();
            }
        }

        public static string ComboProjectText(ComboBox cbo)
        {
            if (cbo == null)
                return "";
            string t = (cbo.Text ?? "").Trim();
            if (t.Length > 0)
                return t;
            if (cbo.SelectedItem != null)
                return Convert.ToString(cbo.SelectedItem).Trim();
            return "";
        }

        static string SqlText(string value)
        {
            if (value == null)
                return "";
            return value.Replace("'", "''");
        }
    }
}
