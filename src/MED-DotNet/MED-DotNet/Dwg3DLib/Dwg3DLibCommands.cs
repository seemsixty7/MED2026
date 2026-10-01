using System;
using System.Drawing;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>MED 3D block library (Dwg3D folder + Dwg3DCatalog.db): MED3DLIB palette, MED3DLIBINSERT, MED3DLIBTEST.</summary>
    public class Dwg3DLibCommands
    {
        /// <summary>Set by the palette before it sends MED3DLIBINSERT, consumed by the command.</summary>
        internal static string PendingPath;

        [CommandMethod("MED3DLIB")]
        public void ShowLibrary()
        {
            try { Dwg3DLibPalette.Show(); }
            catch (System.Exception ex) { Msg("MED3DLIB: " + ex.Message); }
        }

        /// <summary>Insert a DWG as a block. Used by the palette (path handed over in PendingPath) or typed with a path / library-relative file name.</summary>
        [CommandMethod("MED3DLIBINSERT")]
        public void InsertCmd()
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return;
            try
            {
                string path = PendingPath;
                PendingPath = null;
                if (string.IsNullOrEmpty(path))
                {
                    var po = new PromptStringOptions("\nDWG file (full path or name in the 3D library): ");
                    po.AllowSpaces = true;
                    PromptResult r = doc.Editor.GetString(po);
                    if (r.Status != PromptStatus.OK || string.IsNullOrWhiteSpace(r.StringResult)) return;
                    path = ResolveLibraryFile(r.StringResult.Trim().Trim('"'));
                }
                Dwg3DLibInsert.InsertInteractive(doc, path);
            }
            catch (System.Exception ex) { doc.Editor.WriteMessage("\nMED3DLIBINSERT failed: " + ex.Message); }
        }

        internal static string ResolveLibraryFile(string s)
        {
            if (File.Exists(s)) return Path.GetFullPath(s);
            string folder = Dwg3DLibSettings.ResolveFolder();
            string p = Path.Combine(folder, s);
            if (File.Exists(p)) return p;
            if (!s.EndsWith(".dwg", StringComparison.OrdinalIgnoreCase) && File.Exists(p + ".dwg")) return p + ".dwg";
            return s;
        }

        /// <summary>
        /// Non-UI self test (works in accoreconsole): reads the catalog DB, rescans a temp COPY of it (real DB untouched),
        /// extracts one thumbnail, then inserts one library DWG at 0,0,0 into the current drawing.
        /// Prompt: file name (Enter = first available entry).
        /// </summary>
        [CommandMethod("MED3DLIBTEST")]
        public void SelfTest()
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return;
            Editor ed = doc.Editor;
            try
            {
                string folder = Dwg3DLibSettings.ResolveFolder();
                string dbPath = Dwg3DLibSettings.DbPath(folder);
                ed.WriteMessage("\nMED3DLIBTEST: DLL " + typeof(Dwg3DLibCommands).Assembly.Location);
                ed.WriteMessage("\nMED3DLIBTEST: folder " + folder + (Directory.Exists(folder) ? "" : " (MISSING)"));
                ed.WriteMessage("\nMED3DLIBTEST: db " + dbPath + (File.Exists(dbPath) ? "" : " (MISSING)"));
                if (!File.Exists(dbPath)) { ed.WriteMessage("\nMED3DLIBTEST: FAIL no database"); return; }

                System.Collections.Generic.List<Dwg3DEntry> rows;
                System.Collections.Generic.List<string> cats;
                using (var db = new Dwg3DLibDb(dbPath))
                {
                    rows = db.LoadAll();
                    cats = db.Categories();
                }
                int withThumb = rows.Count(r => r.Thumb != null);
                int decodable = 0;
                foreach (var r in rows)
                    using (var img = Dwg3DThumbnail.FromPng(r.Thumb)) if (img != null) decodable++;
                ed.WriteMessage(string.Format("\nMED3DLIBTEST: rows={0} thumbs={1} decodable={2} missing={3} categories={4} described={5}",
                    rows.Count, withThumb, decodable, rows.Count(r => r.Missing), cats.Count, rows.Count(r => r.Description.Length > 0)));

                // Rescan a temp copy (exercises the write path without touching the real DB).
                string tmpDir = Path.Combine(Path.GetTempPath(), "med3dlib_test");
                Directory.CreateDirectory(tmpDir);
                string tmpDb = Path.Combine(tmpDir, Dwg3DLibDb.DbFileName);
                File.Copy(dbPath, tmpDb, true);
                using (var db = new Dwg3DLibDb(tmpDb))
                {
                    var res = Dwg3DScanner.Scan(db, folder, true);
                    ed.WriteMessage("\nMED3DLIBTEST: rescan(copy, force thumbs) " + res);
                    var e0 = res.Entries.FirstOrDefault(x => !x.Missing);
                    if (e0 != null)
                    {
                        db.SaveEdits(e0);
                        ed.WriteMessage("\nMED3DLIBTEST: SaveEdits on copy OK (" + e0.File + ")");
                    }
                }
                try { File.Delete(tmpDb); } catch { }

                var po = new PromptStringOptions("\nLibrary file to insert <first available>: ");
                po.AllowSpaces = true;
                PromptResult pr = ed.GetString(po);
                string want = pr.Status == PromptStatus.OK ? pr.StringResult.Trim().Trim('"') : "";
                Dwg3DEntry pick = want.Length > 0
                    ? rows.FirstOrDefault(r => string.Equals(r.File, want, StringComparison.OrdinalIgnoreCase) || string.Equals(Path.GetFileNameWithoutExtension(r.File), want, StringComparison.OrdinalIgnoreCase))
                    : rows.FirstOrDefault(r => !r.Missing && File.Exists(Path.Combine(folder, r.File)));
                if (pick == null) { ed.WriteMessage("\nMED3DLIBTEST: FAIL entry not found: " + want); return; }
                string full = Path.Combine(folder, pick.File);
                var t = Dwg3DThumbnail.Extract(full);
                ed.WriteMessage("\nMED3DLIBTEST: thumbnail " + pick.File + " -> " + t.Format + " " + (t.Png != null ? t.Png.Length + " bytes" : t.Reason));

                string name; bool existed;
                ObjectId btrId = Dwg3DLibInsert.ImportBlock(doc.Database, full, out name, out existed);
                ObjectId refId = Dwg3DLibInsert.AddReference(doc.Database, btrId, Point3d.Origin, 0.0, ed.CurrentUserCoordinateSystem);
                int ents = 0;
                using (var tr = doc.Database.TransactionManager.StartTransaction())
                {
                    var btr = (BlockTableRecord)tr.GetObject(btrId, OpenMode.ForRead);
                    foreach (ObjectId id in btr) ents++;
                    tr.Commit();
                }
                ed.WriteMessage("\nMED3DLIBTEST: inserted block \"" + name + "\" (" + (existed ? "existing" : "imported") + ", " + ents + " entities in definition) handle " + refId.Handle);
                ed.WriteMessage("\nMED3DLIBTEST: PASS\n");
            }
            catch (System.Exception ex)
            {
                ed.WriteMessage("\nMED3DLIBTEST: FAIL " + ex.GetType().Name + ": " + ex.Message + "\n" + ex.StackTrace + "\n");
            }
        }

        static void Msg(string s)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc != null) doc.Editor.WriteMessage("\n" + s);
        }
    }

    internal static class Dwg3DLibPalette
    {
        static readonly Guid PaletteGuid = new Guid("6A1D3E58-2C47-4B9F-8E31-D5A70C94B2E6");
        static PaletteSet _ps;
        static Dwg3DLibControl _ctl;

        public static void Show()
        {
            if (_ps == null)
            {
                _ctl = new Dwg3DLibControl();
                _ps = new PaletteSet("MED 3D Library", "MED3DLIB", PaletteGuid);
                _ps.Style = PaletteSetStyles.ShowAutoHideButton
                          | PaletteSetStyles.ShowCloseButton
                          | PaletteSetStyles.ShowPropertiesMenu
                          | PaletteSetStyles.Snappable;
                _ps.MinimumSize = new Size(260, 420);
                _ps.Size = new Size(340, 760);
                _ps.DockEnabled = DockSides.Left | DockSides.Right;
                _ps.Add("3D Blocks", _ctl);
                _ps.KeepFocus = true;
            }
            _ps.Visible = true;
            _ctl.EnsureLoaded();
        }

        /// <summary>Hands the file to MED3DLIBINSERT in the active document (command context = lock + jig).</summary>
        public static void RequestInsert(string path)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null) { System.Windows.Forms.MessageBox.Show("Open a drawing first.", "MED 3D Library"); return; }
            Dwg3DLibCommands.PendingPath = path;
            string cancel = doc.CommandInProgress != null && doc.CommandInProgress.Length > 0 ? "\x03\x03" : "";
            doc.SendStringToExecute(cancel + "MED3DLIBINSERT\n", true, false, false);
        }

        public static void OpenDwg(string path)
        {
            if (!File.Exists(path)) { System.Windows.Forms.MessageBox.Show("File not found:\n" + path, "MED 3D Library"); return; }
            DocumentCollection dm = AcadApp.DocumentManager;
            foreach (Document d in dm)
                if (string.Equals(d.Name, path, StringComparison.OrdinalIgnoreCase)) { dm.MdiActiveDocument = d; return; }
            dm.Open(path, true);
        }
    }
}
