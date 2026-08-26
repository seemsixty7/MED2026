using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public class MedPropertiesCommands
    {
        [CommandMethod("MEDCHG", CommandFlags.UsePickSet | CommandFlags.Redraw)]
        public void ShowMedChg()
        {
            MedPropertiesPalette.Show();
        }

        [CommandMethod("MEDPROPERTIES", CommandFlags.UsePickSet | CommandFlags.Redraw)]
        public void ShowMedProperties()
        {
            MedPropertiesPalette.Show();
        }

        [CommandMethod("MEDPROPS", CommandFlags.UsePickSet | CommandFlags.Redraw)]
        public void ShowMedProps()
        {
            MedPropertiesPalette.Show();
        }

        [CommandMethod("MEDRECORDS", CommandFlags.UsePickSet)]
        public void EditRecords()
        {
            MedPropertiesPalette.EditSelectedEntity();
        }

        [CommandMethod("MEDXDEDIT", CommandFlags.UsePickSet)]
        public void EditXd()
        {
            MedPropertiesPalette.EditSelectedEntity();
        }
    }

    internal static class MedPropertiesPalette
    {
        static readonly Guid PaletteGuid = new Guid("A3F8B2C1-9D4E-4A71-8C22-5E6B1F0D3A88");
        static PaletteSet _ps;
        static MedPropertiesControl _ctl;
        static Document _hooked;
        static bool _busy;

        public static void Show()
        {
            Ensure();
            _ps.Visible = true;
            RefreshFromSelection();
        }

        public static void Ensure()
        {
            if (_ps != null)
                return;

            _ctl = new MedPropertiesControl();
            _ctl.ApplyRequested += OnApply;
            _ctl.RecordsRequested += OnRecordsRequested;

            _ps = new PaletteSet("MED Properties", "MEDPROPERTIES", PaletteGuid);
            _ps.Style = PaletteSetStyles.ShowAutoHideButton
                      | PaletteSetStyles.ShowCloseButton
                      | PaletteSetStyles.ShowPropertiesMenu
                      | PaletteSetStyles.Snappable;
            _ps.MinimumSize = new Size(240, 320);
            _ps.Size = new Size(280, 420);
            _ps.DockEnabled = DockSides.Left | DockSides.Right;
            _ps.Add("MED", _ctl);
            _ps.KeepFocus = false;
            _ps.StateChanged += PaletteStateChanged;

            AcadApp.DocumentManager.DocumentActivated += (s, e) => Hook(e.Document);
            Hook(AcadApp.DocumentManager.MdiActiveDocument);
        }

        static void PaletteStateChanged(object sender, PaletteSetStateEventArgs e)
        {
            if (e.NewState == StateEventIndex.Show)
                RefreshFromSelection();
        }

        static void Hook(Document doc)
        {
            if (_hooked != null)
            {
                try
                {
                    _hooked.ImpliedSelectionChanged -= OnImpliedSelectionChanged;
                    _hooked.CommandEnded -= OnCommandEnded;
                }
                catch { }
                _hooked = null;
            }
            if (doc == null)
                return;
            doc.ImpliedSelectionChanged += OnImpliedSelectionChanged;
            doc.CommandEnded += OnCommandEnded;
            _hooked = doc;
            RefreshFromSelection();
        }

        static void OnImpliedSelectionChanged(object sender, EventArgs e)
        {
            RefreshFromSelection();
        }

        static void OnCommandEnded(object sender, CommandEventArgs e)
        {
            RefreshFromSelection();
        }

        static void RefreshFromSelection()
        {
            if (_ctl == null || _ps == null || !_ps.Visible)
                return;
            if (_busy)
                return;

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                _ctl.ShowSelection(new List<MedRecord>(), null);
                return;
            }

            string keepApp = null;
            if (_ctl.SelectedFilter != null)
                keepApp = _ctl.SelectedFilter.AppName;

            List<MedRecord> records = new List<MedRecord>();
            try
            {
                PromptSelectionResult sel = doc.Editor.SelectImplied();
                if (sel.Status != PromptStatus.OK || sel.Value == null)
                {
                    _ctl.ShowSelection(records, keepApp);
                    return;
                }

                Database db = doc.Database;
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = db.TransactionManager.StartTransaction())
                {
                    foreach (SelectedObject so in sel.Value)
                    {
                        if (so == null)
                            continue;
                        Entity ent = tr.GetObject(so.ObjectId, OpenMode.ForRead, false) as Entity;
                        if (ent == null)
                            continue;
                        records.AddRange(MedXdata.ReadEntity(ent));
                    }
                    tr.Commit();
                }
            }
            catch (System.Exception)
            {
                // Selection can vanish mid-refresh during commands.
            }
            _ctl.ShowSelection(records, keepApp);
        }

        static void OnApply(object sender, EventArgs e)
        {
            if (_busy || _ctl == null)
                return;
            Control editor = sender as Control;
            MedField field;
            if (editor is System.Windows.Forms.CheckBox)
                field = MedField.Measure;
            else if (editor != null && editor.Tag is MedField)
                field = (MedField)editor.Tag;
            else
                return;

            string raw = _ctl.GetEditorValue(field);
            if (raw == MedXdata.Varies)
                return;

            string formatted = MedXdata.FormatValue(field, raw);
            string key = MedFieldMap.Key(field);
            List<MedRecord> targets = _ctl.FilteredRecords();
            if (targets.Count == 0)
                return;

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;

            _busy = true;
            try
            {
                int n = 0;
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = doc.Database.TransactionManager.StartTransaction())
                {
                    Dictionary<ObjectId, Entity> opened = new Dictionary<ObjectId, Entity>();
                    foreach (MedRecord rec in targets)
                    {
                        if (!MedFieldMap.UsedBy(rec.AppName, field))
                            continue;
                        Entity ent;
                        if (!opened.TryGetValue(rec.Id, out ent))
                        {
                            ent = tr.GetObject(rec.Id, OpenMode.ForWrite, false) as Entity;
                            if (ent == null)
                                continue;
                            opened[rec.Id] = ent;
                        }
                        rec.Values[key] = formatted;
                        n++;
                    }
                    HashSet<ObjectId> written = new HashSet<ObjectId>();
                    foreach (MedRecord rec in targets)
                    {
                        if (written.Contains(rec.Id))
                            continue;
                        written.Add(rec.Id);
                        Entity ent;
                        if (!opened.TryGetValue(rec.Id, out ent) || ent == null)
                            continue;
                        List<MedRecord> all = new List<MedRecord>();
                        foreach (MedRecord r in _ctl.CurrentRecords)
                        {
                            if (r.Id == rec.Id)
                                all.Add(r);
                        }
                        MedXdata.WriteEntity(ent, all, tr);
                    }
                    tr.Commit();
                }
                if (n > 0)
                    doc.Editor.WriteMessage("\nMED Properties: updated {0} on {1} item(s).", field, n);
            }
            catch (System.Exception ex)
            {
                doc.Editor.WriteMessage("\nMED Properties: " + ex.Message);
            }
            finally
            {
                _busy = false;
            }
            RefreshFromSelection();
        }

        static void OnRecordsRequested(object sender, EventArgs e)
        {
            if (_ctl == null)
                return;
            List<ObjectId> ids = _ctl.TargetEntityIds();
            if (ids.Count == 0)
                return;
            OpenRecords(ids);
        }

        public static void EditSelectedEntity()
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            List<ObjectId> ids = new List<ObjectId>();
            try
            {
                PromptSelectionResult implied = doc.Editor.SelectImplied();
                if (implied.Status == PromptStatus.OK && implied.Value != null)
                {
                    foreach (SelectedObject so in implied.Value)
                    {
                        if (so != null && !so.ObjectId.IsNull)
                            ids.Add(so.ObjectId);
                    }
                }
            }
            catch (System.Exception)
            {
            }
            if (ids.Count == 0)
            {
                PromptEntityOptions opt = new PromptEntityOptions("\nSelect MED entity: ");
                PromptEntityResult res = doc.Editor.GetEntity(opt);
                if (res.Status != PromptStatus.OK)
                    return;
                ids.Add(res.ObjectId);
            }
            OpenRecords(ids);
        }

        static void OpenRecords(IList<ObjectId> ids)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null || ids == null || ids.Count == 0)
                return;
            List<ObjectId> unique = new List<ObjectId>();
            HashSet<ObjectId> seen = new HashSet<ObjectId>();
            foreach (ObjectId id in ids)
            {
                if (id.IsNull || seen.Contains(id))
                    continue;
                seen.Add(id);
                unique.Add(id);
            }
            if (unique.Count == 0)
                return;
            List<MedRecord> recs = new List<MedRecord>();
            try
            {
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = doc.Database.TransactionManager.StartTransaction())
                {
                    foreach (ObjectId id in unique)
                    {
                        Entity ent = tr.GetObject(id, OpenMode.ForRead, false) as Entity;
                        if (ent == null)
                            continue;
                        recs.AddRange(MedXdata.ReadEntity(ent));
                    }
                    tr.Commit();
                }
            }
            catch (System.Exception ex)
            {
                doc.Editor.WriteMessage("\nMED Records: " + ex.Message);
                return;
            }
            if (recs.Count == 0)
                doc.Editor.WriteMessage("\nMED Records: no MED xdata on that selection. Grid will start empty.");
            MedTypeLookup.ClearCache();
            if (MedRecordsGridForm.EditEntities(unique, recs))
                RefreshFromSelection();
        }
    }
}

