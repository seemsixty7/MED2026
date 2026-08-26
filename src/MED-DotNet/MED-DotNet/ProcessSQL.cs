using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Data.SQLite;
using System.IO;
using System.Reflection;
using DataTable = System.Data.DataTable;
using DataColumn = System.Data.DataColumn;
using DataRow = System.Data.DataRow;

namespace MEDDotNet
{
    public static class ProcessSQL
    {
        const string SettingsFileName = "MEDDataBaseSettings.dat";

        static void ReadSettings(out string provider, out string connectString)
        {
            provider = null;
            connectString = null;
            foreach (string candidate in SettingsCandidates())
            {
                if (!File.Exists(candidate))
                    continue;
                foreach (string raw in File.ReadAllLines(candidate))
                {
                    string line = raw.Trim();
                    if (line.Length == 0 || line.StartsWith(";") || line.StartsWith("#"))
                        continue;
                    if (line.StartsWith("Provider=", StringComparison.OrdinalIgnoreCase))
                        provider = line.Substring("Provider=".Length).Trim();
                    else if (line.StartsWith("ConnectString=", StringComparison.OrdinalIgnoreCase))
                        connectString = line.Substring("ConnectString=".Length).Trim();
                    else if (connectString == null)
                        connectString = line;
                }
                if (!string.IsNullOrEmpty(connectString))
                    return;
            }
            throw new FileNotFoundException(
                "MEDDataBaseSettings.dat not found next to MED-DotNet.dll or in Support. Create it with Provider= and ConnectString= lines.");
        }

        static string ReadConnectString()
        {
            string provider;
            string cs;
            ReadSettings(out provider, out cs);
            return cs;
        }

        static string[] SettingsCandidates()
        {
            string dllDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? "";
            return new[]
            {
                Path.Combine(dllDir, SettingsFileName),
                Path.Combine(dllDir, "Support", SettingsFileName),
                Path.Combine(dllDir, "..", SettingsFileName)
            };
        }

        internal static bool IsSqlite
        {
            get
            {
                string provider;
                string cs;
                ReadSettings(out provider, out cs);
                if (!string.IsNullOrEmpty(provider))
                    return string.Equals(provider, "SQLite", StringComparison.OrdinalIgnoreCase);
                string t = (cs ?? "").Trim();
                return t.IndexOf("Data Source=", StringComparison.OrdinalIgnoreCase) >= 0
                    && t.EndsWith(".db", StringComparison.OrdinalIgnoreCase);
            }
        }

        static DbConnection GetConnection()
        {
            string cs = ReadConnectString();
            if (IsSqlite)
                return new SQLiteConnection(cs);
            return new SqlConnection(cs);
        }

        internal static DbConnection OpenConnection()
        {
            DbConnection conn = GetConnection();
            conn.Open();
            return conn;
        }

        internal static DataTable QueryTable(string sql)
        {
            using (DbConnection conn = OpenConnection())
            {
                using (DbDataAdapter adapter = CreateAdapter(sql, conn))
                {
                    DataTable dt = new DataTable();
                    adapter.Fill(dt);
                    return dt;
                }
            }
        }

        internal static DbDataAdapter CreateAdapter(string selectSql, DbConnection conn)
        {
            if (conn is SQLiteConnection)
                return new SQLiteDataAdapter(selectSql, (SQLiteConnection)conn);
            return new SqlDataAdapter(selectSql, (SqlConnection)conn);
        }

        internal static void AttachCommandBuilder(DbDataAdapter da)
        {
            if (da is SQLiteDataAdapter)
                new SQLiteCommandBuilder((SQLiteDataAdapter)da);
            else
                new SqlCommandBuilder((SqlDataAdapter)da);
        }

        internal static void UpdateTable(string selectSql, DataTable table)
        {
            using (DbConnection conn = OpenConnection())
            {
                using (DbDataAdapter da = CreateAdapter(selectSql, conn))
                {
                    da.MissingSchemaAction = MissingSchemaAction.AddWithKey;
                    AttachCommandBuilder(da);
                    da.Update(table);
                }
            }
        }

        internal static void AddParam(DbCommand cmd, string name, object value)
        {
            DbParameter p = cmd.CreateParameter();
            p.ParameterName = name;
            p.Value = value ?? DBNull.Value;
            cmd.Parameters.Add(p);
        }

        [LispFunction("ProcessSQLStatementNET")]
        public static ResultBuffer ProcessSQLStatementNet(ResultBuffer resbufin)
        {
            ResultBuffer result = new ResultBuffer();
            if (resbufin == null)
                return null;

            string query = resbufin.AsArray()[0].Value.ToString();
            Document doc = Application.DocumentManager.MdiActiveDocument;
            Editor ed = doc.Editor;
            DbConnection conn = null;
            try
            {
                conn = OpenConnection();
                string trimmed = query.TrimStart();
                bool isSelect = trimmed.StartsWith("SELECT", StringComparison.OrdinalIgnoreCase)
                             || trimmed.StartsWith("WITH", StringComparison.OrdinalIgnoreCase);

                if (isSelect)
                {
                    using (DbDataAdapter adapter = CreateAdapter(query, conn))
                    {
                        DataTable dt = new DataTable();
                        adapter.Fill(dt);
                        if (dt.Rows.Count == 0)
                        {
                            ed.WriteMessage("\nMED-DotNet: No Rows");
                            return null;
                        }
                        ed.WriteMessage("\nMED-DotNet: " + dt.Rows.Count + " row(s)");
                        result.Add(new TypedValue((int)LispDataType.ListBegin));
                        result.Add(new TypedValue((int)LispDataType.ListBegin));
                        foreach (DataColumn dc in dt.Columns)
                            result.Add(new TypedValue((int)LispDataType.Text, dc.ColumnName));
                        result.Add(new TypedValue((int)LispDataType.ListEnd));
                        foreach (DataRow dr in dt.Rows)
                        {
                            result.Add(new TypedValue((int)LispDataType.ListBegin));
                            for (int i = 0; i < dt.Columns.Count; i++)
                                result.Add(TypedFromCell(dr, i));
                            result.Add(new TypedValue((int)LispDataType.ListEnd));
                        }
                        result.Add(new TypedValue((int)LispDataType.ListEnd));
                        return result;
                    }
                }

                using (DbCommand cmd = conn.CreateCommand())
                {
                    cmd.CommandText = query;
                    int n = cmd.ExecuteNonQuery();
                    ed.WriteMessage("\nMED-DotNet: " + n + " row(s) affected");
                    result.Add(new TypedValue((int)LispDataType.Int32, n));
                    return result;
                }
            }
            catch (System.Exception ex)
            {
                ed.WriteMessage("\nMED-DotNet: " + ex.Message);
                return null;
            }
            finally
            {
                if (conn != null)
                {
                    if (conn.State == ConnectionState.Open)
                        conn.Close();
                    conn.Dispose();
                }
            }
        }

        static TypedValue TypedFromCell(DataRow dr, int i)
        {
            if (dr.IsNull(i))
                return new TypedValue((int)LispDataType.Nil);
            object v = dr[i];
            if (v is double || v is float || v is decimal)
                return new TypedValue((int)LispDataType.Double, Convert.ToDouble(v));
            if (v is int || v is long || v is short || v is byte)
                return new TypedValue((int)LispDataType.Int32, Convert.ToInt32(v));
            return new TypedValue((int)LispDataType.Text, v.ToString());
        }
    }
}
