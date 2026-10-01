using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.Drawing;

namespace MEDDotNet
{
    /// <summary>One row of Dwg3D\Dwg3DCatalog.db (same schema as tools\Dwg3DCatalog).</summary>
    public sealed class Dwg3DEntry
    {
        public long Id;
        public string File = "";
        public string Description = "", Note = "", Category = "", SourcePath = "", SourceModified = "";
        public string FileModified = "", DateAdded = "", DateUpdated = "";
        public long FileSize;
        public bool Missing;
        public byte[] Thumb;
        public string ThumbFormat = "";
        public string ThumbFileModified = "";
        // UI cache
        public Image Small;
    }

    /// <summary>
    /// SQLite catalog shared with the standalone tools\Dwg3DCatalog app. Uses System.Data.SQLite
    /// (already a MED-DotNet dependency, SQLite.Interop.dll beside the DLL).
    /// </summary>
    public sealed class Dwg3DLibDb : IDisposable
    {
        public const string DbFileName = "Dwg3DCatalog.db";
        public readonly string Path;
        readonly SQLiteConnection _c;

        public static string Now() { return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"); }
        public static string Stamp(DateTime d) { return d.ToString("yyyy-MM-dd HH:mm:ss"); }

        public Dwg3DLibDb(string path)
        {
            Path = path;
            var sb = new SQLiteConnectionStringBuilder { DataSource = path, Version = 3, Pooling = false, FailIfMissing = false };
            sb.DefaultTimeout = 10;
            _c = new SQLiteConnection(sb.ToString());
            _c.Open();
            Exec(@"
CREATE TABLE IF NOT EXISTS blocks(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file TEXT NOT NULL UNIQUE COLLATE NOCASE,
  description TEXT NOT NULL DEFAULT '',
  note TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  source_path TEXT NOT NULL DEFAULT '',
  source_modified TEXT NOT NULL DEFAULT '',
  file_modified TEXT NOT NULL DEFAULT '',
  file_size INTEGER NOT NULL DEFAULT 0,
  date_added TEXT NOT NULL,
  date_updated TEXT NOT NULL DEFAULT '',
  missing INTEGER NOT NULL DEFAULT 0,
  thumb BLOB,
  thumb_format TEXT NOT NULL DEFAULT '',
  thumb_file_modified TEXT NOT NULL DEFAULT '');
CREATE TABLE IF NOT EXISTS categories(name TEXT PRIMARY KEY COLLATE NOCASE);
CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);
INSERT OR IGNORE INTO meta(key,value) VALUES('schema_version','1');");
        }

        void Exec(string sql)
        {
            using (var cmd = _c.CreateCommand())
            {
                cmd.CommandText = sql;
                cmd.ExecuteNonQuery();
            }
        }

        SQLiteCommand Cmd(string sql, params object[] nameValuePairs)
        {
            var cmd = _c.CreateCommand();
            cmd.CommandText = sql;
            for (int i = 0; i + 1 < nameValuePairs.Length; i += 2)
                cmd.Parameters.AddWithValue((string)nameValuePairs[i], nameValuePairs[i + 1] ?? DBNull.Value);
            return cmd;
        }

        public SQLiteTransaction Begin() { return _c.BeginTransaction(); }

        static string S(SQLiteDataReader rd, int i) { return rd.IsDBNull(i) ? "" : Convert.ToString(rd.GetValue(i)); }
        static long L(SQLiteDataReader rd, int i) { return rd.IsDBNull(i) ? 0 : Convert.ToInt64(rd.GetValue(i)); }

        public List<Dwg3DEntry> LoadAll()
        {
            var list = new List<Dwg3DEntry>();
            using (var cmd = Cmd("SELECT id,file,description,note,category,source_path,source_modified,file_modified,file_size,date_added,date_updated,missing,thumb,thumb_format,thumb_file_modified FROM blocks ORDER BY file COLLATE NOCASE"))
            using (var rd = cmd.ExecuteReader())
            {
                while (rd.Read())
                {
                    list.Add(new Dwg3DEntry
                    {
                        Id = L(rd, 0), File = S(rd, 1), Description = S(rd, 2), Note = S(rd, 3),
                        Category = S(rd, 4), SourcePath = S(rd, 5), SourceModified = S(rd, 6),
                        FileModified = S(rd, 7), FileSize = L(rd, 8), DateAdded = S(rd, 9),
                        DateUpdated = S(rd, 10), Missing = L(rd, 11) != 0,
                        Thumb = rd.IsDBNull(12) ? null : rd.GetValue(12) as byte[],
                        ThumbFormat = S(rd, 13), ThumbFileModified = S(rd, 14)
                    });
                }
            }
            return list;
        }

        public void Insert(Dwg3DEntry e)
        {
            using (var cmd = Cmd(@"INSERT INTO blocks(file,description,note,category,source_path,source_modified,file_modified,file_size,date_added,date_updated,missing,thumb,thumb_format,thumb_file_modified)
VALUES(@f,@d,@n,@c,@s,@sm,@fm,@fs,@da,@du,@m,@t,@tf,@tfm); SELECT last_insert_rowid();",
                "@f", e.File, "@d", e.Description, "@n", e.Note, "@c", e.Category, "@s", e.SourcePath, "@sm", e.SourceModified,
                "@fm", e.FileModified, "@fs", e.FileSize, "@da", e.DateAdded, "@du", e.DateUpdated, "@m", e.Missing ? 1 : 0,
                "@t", e.Thumb, "@tf", e.ThumbFormat, "@tfm", e.ThumbFileModified))
                e.Id = Convert.ToInt64(cmd.ExecuteScalar());
        }

        public void UpdateFileInfo(Dwg3DEntry e)
        {
            using (var cmd = Cmd("UPDATE blocks SET file_modified=@fm,file_size=@fs,missing=@m,source_path=@s,source_modified=@sm WHERE id=@id",
                "@fm", e.FileModified, "@fs", e.FileSize, "@m", e.Missing ? 1 : 0, "@s", e.SourcePath, "@sm", e.SourceModified, "@id", e.Id))
                cmd.ExecuteNonQuery();
        }

        public void UpdateThumb(Dwg3DEntry e)
        {
            using (var cmd = Cmd("UPDATE blocks SET thumb=@t,thumb_format=@tf,thumb_file_modified=@tfm WHERE id=@id",
                "@t", e.Thumb, "@tf", e.ThumbFormat, "@tfm", e.ThumbFileModified, "@id", e.Id))
                cmd.ExecuteNonQuery();
        }

        public void SaveEdits(Dwg3DEntry e)
        {
            e.DateUpdated = Now();
            using (var cmd = Cmd("UPDATE blocks SET description=@d,note=@n,category=@c,date_updated=@du WHERE id=@id",
                "@d", e.Description, "@n", e.Note, "@c", e.Category, "@du", e.DateUpdated, "@id", e.Id))
                cmd.ExecuteNonQuery();
            AddCategory(e.Category);
        }

        public void AddCategory(string name)
        {
            if (string.IsNullOrWhiteSpace(name)) return;
            using (var cmd = Cmd("INSERT OR IGNORE INTO categories(name) VALUES(@n)", "@n", name.Trim()))
                cmd.ExecuteNonQuery();
        }

        public List<string> Categories()
        {
            var set = new SortedSet<string>(StringComparer.OrdinalIgnoreCase);
            using (var cmd = Cmd("SELECT name FROM categories UNION SELECT category FROM blocks WHERE category<>''"))
            using (var rd = cmd.ExecuteReader())
                while (rd.Read()) set.Add(S(rd, 0));
            return new List<string>(set);
        }

        public void Dispose()
        {
            try { _c.Close(); } catch { }
            _c.Dispose();
        }
    }
}
