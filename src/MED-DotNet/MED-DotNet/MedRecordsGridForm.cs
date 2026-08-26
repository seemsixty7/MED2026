using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.GraphicsInterface;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    internal class MedRecordsGridForm : Form
    {
        readonly List<ObjectId> _ids;
        readonly ObjectId[] _originalPick;
        readonly ViewTableRecord _originalView;
        readonly IntegerCollection _haloVports = new IntegerCollection();
        DataGridView _grid;
        Label _status;
        ObjectId _highlighted = ObjectId.Null;
        Button _showBtn;
        Drawable _halo;

        public MedRecordsGridForm(List<ObjectId> ids, List<MedRecord> records)
        {
            _ids = ids ?? new List<ObjectId>();
            _originalView = CaptureView();
            _originalPick = CaptureImplied();
            Text = "MED Records";
            Width = 1180;
            Height = 460;
            StartPosition = FormStartPosition.CenterParent;
            MinimizeBox = false;
            ShowInTaskbar = false;
            Font = new System.Drawing.Font("Segoe UI", 9f);
            FormClosed += delegate
            {
                Unhighlight();
                ClearHalo();
                RestoreView();
                RestoreImplied();
            };

            _grid = new DataGridView();
            _grid.Dock = DockStyle.Fill;
            _grid.AllowUserToAddRows = _ids.Count == 1;
            _grid.AllowUserToDeleteRows = true;
            _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            _grid.RowHeadersVisible = true;
            _grid.SelectionMode = DataGridViewSelectionMode.CellSelect;
            _grid.MultiSelect = true;
            _grid.EditMode = DataGridViewEditMode.EditOnEnter;
            _grid.ClipboardCopyMode = DataGridViewClipboardCopyMode.EnableWithoutHeaderText;
            _grid.CellValueChanged += GridCellValueChanged;
            _grid.EditingControlShowing += GridEditingControlShowing;
            _grid.DefaultValuesNeeded += GridDefaultValuesNeeded;
            _grid.CellBeginEdit += GridCellBeginEdit;
            _grid.CurrentCellChanged += GridCurrentCellChanged;

            DataGridViewTextBoxColumn hCol = new DataGridViewTextBoxColumn();
            hCol.Name = "Handle";
            hCol.HeaderText = "Handle";
            hCol.ReadOnly = true;
            hCol.FillWeight = 80;
            _grid.Columns.Add(hCol);

            DataGridViewComboBoxColumn typeCol = new DataGridViewComboBoxColumn();
            typeCol.Name = "Type";
            typeCol.HeaderText = "Type";
            typeCol.Items.AddRange("Conduit", "Cable", "Tray", "Fitting", "Equipment");
            typeCol.FlatStyle = FlatStyle.Flat;
            typeCol.FillWeight = 90;
            _grid.Columns.Add(typeCol);

            AddTextCol("Tag", "Tag", 70);
            AddTextCol("RelatedTag", "Related Tag", 80);
            AddTextCol("Size", "Size", 55);
            AddTextCol("Alternate", "Alt", 50);
            AddTextCol("Depth", "Depth", 50);
            AddTextCol("Distance", "Dist", 50);

            DataGridViewComboBoxColumn codeCol = new DataGridViewComboBoxColumn();
            codeCol.Name = "Code";
            codeCol.HeaderText = "Code";
            codeCol.FlatStyle = FlatStyle.Flat;
            codeCol.FillWeight = 220;
            codeCol.DisplayStyle = DataGridViewComboBoxDisplayStyle.DropDownButton;
            _grid.Columns.Add(codeCol);

            DataGridViewCheckBoxColumn msrCol = new DataGridViewCheckBoxColumn();
            msrCol.Name = "Measure";
            msrCol.HeaderText = "Measure";
            msrCol.FillWeight = 55;
            _grid.Columns.Add(msrCol);

            AddTextCol("Flange", "Flange", 50);

            foreach (MedRecord rec in records)
                AddRecordRow(rec);
            foreach (DataGridViewRow row in _grid.Rows)
                ApplyFlangeState(row);

            Panel bottom = new Panel();
            bottom.Dock = DockStyle.Bottom;
            bottom.Height = 48;

            _showBtn = new Button();
            _showBtn.Text = "Show entity";
            _showBtn.Width = 100;
            _showBtn.Location = new Point(8, 10);
            _showBtn.Click += delegate { ShowCurrent(true); };

            Button ok = new Button();
            ok.Text = "OK";
            ok.DialogResult = DialogResult.OK;
            ok.Width = 88;
            Button cancel = new Button();
            cancel.Text = "Cancel";
            cancel.DialogResult = DialogResult.Cancel;
            cancel.Width = 88;

            _status = new Label();
            _status.AutoSize = true;
            _status.Location = new Point(116, 16);
            string addHint = _ids.Count == 1 ? " Click the blank row to add a record." : " Add record is off for multi-entity. Edit one entity to add.";
            _status.Text = records.Count + " record(s) / " + _ids.Count + " entit" + (_ids.Count == 1 ? "y" : "ies") + ". Ctrl+C/V, Ctrl+D fill down." + addHint;

            bottom.Controls.Add(_showBtn);
            bottom.Controls.Add(_status);
            bottom.Controls.Add(ok);
            bottom.Controls.Add(cancel);
            AcceptButton = ok;
            CancelButton = cancel;
            bottom.Resize += delegate
            {
                ok.Location = new Point(bottom.ClientSize.Width - 192, 10);
                cancel.Location = new Point(bottom.ClientSize.Width - 96, 10);
            };

            ContextMenuStrip menu = new ContextMenuStrip();
            menu.Items.Add("Copy", null, delegate { CopyCells(); });
            menu.Items.Add("Paste", null, delegate { PasteCells(); });
            menu.Items.Add("Fill down", null, delegate { FillDown(); });
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Show entity", null, delegate { ShowCurrent(true); });
            _grid.ContextMenuStrip = menu;

            Controls.Add(_grid);
            Controls.Add(bottom);
        }

        void AddTextCol(string name, string header, int fill)
        {
            DataGridViewTextBoxColumn col = new DataGridViewTextBoxColumn();
            col.Name = name;
            col.HeaderText = header;
            col.FillWeight = fill;
            _grid.Columns.Add(col);
        }

        void AddRecordRow(MedRecord rec)
        {
            int i = _grid.Rows.Add();
            FillRow(_grid.Rows[i], rec);
        }

        void FillRow(DataGridViewRow row, MedRecord rec)
        {
            row.Tag = rec.Id;
            row.Cells["Handle"].Value = rec.Id.Handle.ToString();
            row.Cells["Type"].Value = MedApps.DisplayName(rec.AppName);
            row.Cells["Tag"].Value = rec.Get(MedKeys.Tag);
            row.Cells["RelatedTag"].Value = rec.Get(MedKeys.RelatedTag);
            row.Cells["Size"].Value = rec.Get(MedKeys.Size);
            row.Cells["Alternate"].Value = rec.Get(MedKeys.Alternate);
            row.Cells["Depth"].Value = rec.Get(MedKeys.Depth);
            row.Cells["Distance"].Value = rec.Get(MedKeys.Distance);
            FillCodeCell(row, rec.AppName, rec.Get(MedKeys.Code));
            row.Cells["Measure"].Value = rec.Get(MedKeys.Measure) == "T";
            row.Cells["Flange"].Value = rec.Get(MedKeys.Flange);
        }

        void FillCodeCell(DataGridViewRow row, string app, string code)
        {
            DataGridViewComboBoxCell cell = row.Cells["Code"] as DataGridViewComboBoxCell;
            if (cell == null)
                return;
            cell.Items.Clear();
            string current = MedTypeLookup.Display(app, code);
            bool found = false;
            foreach (MedTypeRow t in MedTypeLookup.ForApp(app))
            {
                string s = t.ToString();
                cell.Items.Add(s);
                if (t.Code.ToString() == MedXdata.CodeFromDisplay(code))
                {
                    current = s;
                    found = true;
                }
            }
            if (!found && !string.IsNullOrEmpty(code))
                cell.Items.Insert(0, current);
            if (!string.IsNullOrEmpty(current) && !cell.Items.Contains(current))
                cell.Items.Insert(0, current);
            cell.Value = string.IsNullOrEmpty(current) ? null : current;
        }

        ObjectId IdFromRow(DataGridViewRow row)
        {
            if (row != null && row.Tag is ObjectId)
                return (ObjectId)row.Tag;
            if (_ids.Count > 0)
                return _ids[0];
            return ObjectId.Null;
        }

        void GridDefaultValuesNeeded(object sender, DataGridViewRowEventArgs e)
        {
            ObjectId id = ObjectId.Null;
            if (_grid.CurrentRow != null)
                id = IdFromRow(_grid.CurrentRow);
            if (id.IsNull)
                id = IdFromRow(e.Row);
            if (id.IsNull && _ids.Count > 0)
                id = _ids[0];
            e.Row.Tag = id;
            e.Row.Cells["Handle"].Value = id.IsNull ? "" : id.Handle.ToString();
            e.Row.Cells["Type"].Value = "Conduit";
            e.Row.Cells["Tag"].Value = "NONE";
            e.Row.Cells["Measure"].Value = false;
            FillCodeCell(e.Row, MedApps.Conduit, "");
            ApplyFlangeState(e.Row);
        }

        void GridEditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
        {
            if (_grid.CurrentCell == null || _grid.CurrentCell.OwningColumn.Name != "Code")
                return;
            ComboBox cb = e.Control as ComboBox;
            if (cb == null)
                return;
            cb.DropDownStyle = ComboBoxStyle.DropDown;
        }

        void GridCellValueChanged(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0)
                return;
            DataGridViewRow row = _grid.Rows[e.RowIndex];
            if (row.IsNewRow)
                return;
            if (_grid.Columns[e.ColumnIndex].Name == "Type")
            {
                string app = MedApps.FromDisplay(Convert.ToString(row.Cells["Type"].Value));
                FillCodeCell(row, app, "");
                ApplyFlangeState(row);
            }
        }

        static bool UsesFlange(string app)
        {
            return app == MedApps.Tray || app == MedApps.Fitting;
        }

        void ApplyFlangeState(DataGridViewRow row)
        {
            if (row == null || row.IsNewRow)
                return;
            string app = MedApps.FromDisplay(Convert.ToString(row.Cells["Type"].Value));
            bool on = UsesFlange(app);
            DataGridViewCell c = row.Cells["Flange"];
            c.ReadOnly = !on;
            c.Style.BackColor = on ? _grid.DefaultCellStyle.BackColor : SystemColors.Control;
            if (!on)
                c.Value = "";
        }

        void GridCellBeginEdit(object sender, DataGridViewCellCancelEventArgs e)
        {
            if (e.RowIndex < 0)
                return;
            string name = _grid.Columns[e.ColumnIndex].Name;
            if (name == "Handle")
            {
                e.Cancel = true;
                return;
            }
            if (name != "Flange")
                return;
            DataGridViewRow row = _grid.Rows[e.RowIndex];
            string app = MedApps.FromDisplay(Convert.ToString(row.Cells["Type"].Value));
            if (!UsesFlange(app))
                e.Cancel = true;
        }

        void GridCurrentCellChanged(object sender, EventArgs e)
        {
            ShowCurrent(false);
        }

        void ShowCurrent(bool zoom)
        {
            if (_grid.CurrentRow == null)
                return;
            ObjectId id = IdFromRow(_grid.CurrentRow);
            if (id.IsNull)
                return;
            Highlight(id, zoom);
        }

        void Highlight(ObjectId id, bool zoom)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            try
            {
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = doc.Database.TransactionManager.StartTransaction())
                {
                    if (!_highlighted.IsNull && _highlighted != id)
                    {
                        Entity old = tr.GetObject(_highlighted, OpenMode.ForRead, false) as Entity;
                        if (old != null)
                            old.Unhighlight();
                    }
                    Entity ent = tr.GetObject(id, OpenMode.ForRead, false) as Entity;
                    if (ent != null)
                    {
                        ent.Highlight();
                        _highlighted = id;
                        DrawHalo(ent);
                        if (zoom)
                            ZoomTo(doc.Editor, ent);
                    }
                    tr.Commit();
                }
                doc.Editor.SetImpliedSelection(new ObjectId[] { id });
                try { doc.Editor.UpdateScreen(); } catch (System.Exception) { }
            }
            catch (System.Exception)
            {
            }
        }

        static ViewTableRecord CaptureView()
        {
            try
            {
                Document doc = AcadApp.DocumentManager.MdiActiveDocument;
                if (doc == null)
                    return null;
                return doc.Editor.GetCurrentView();
            }
            catch (System.Exception)
            {
                return null;
            }
        }

        void RestoreView()
        {
            if (_originalView == null)
                return;
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            try
            {
                using (DocumentLock dl = doc.LockDocument())
                    doc.Editor.SetCurrentView(_originalView);
            }
            catch (System.Exception)
            {
            }
        }

        static ObjectId[] CaptureImplied()
        {
            try
            {
                Document doc = AcadApp.DocumentManager.MdiActiveDocument;
                if (doc == null)
                    return null;
                PromptSelectionResult r = doc.Editor.SelectImplied();
                if (r.Status != PromptStatus.OK || r.Value == null)
                    return null;
                List<ObjectId> o = new List<ObjectId>();
                foreach (SelectedObject so in r.Value)
                {
                    if (so != null && !so.ObjectId.IsNull)
                        o.Add(so.ObjectId);
                }
                return o.ToArray();
            }
            catch (System.Exception)
            {
                return null;
            }
        }

        void RestoreImplied()
        {
            if (_originalPick == null)
                return;
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            try
            {
                doc.Editor.SetImpliedSelection(_originalPick);
            }
            catch (System.Exception)
            {
            }
        }

        void Unhighlight()
        {
            if (_highlighted.IsNull)
                return;
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            try
            {
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = doc.Database.TransactionManager.StartTransaction())
                {
                    Entity old = tr.GetObject(_highlighted, OpenMode.ForRead, false) as Entity;
                    if (old != null)
                        old.Unhighlight();
                    tr.Commit();
                }
            }
            catch (System.Exception)
            {
            }
            _highlighted = ObjectId.Null;
        }

        void ClearHalo()
        {
            if (_halo == null)
                return;
            try
            {
                TransientManager.CurrentTransientManager.EraseTransient(_halo, _haloVports);
            }
            catch (System.Exception)
            {
            }
            try { _halo.Dispose(); } catch (System.Exception) { }
            _halo = null;
        }

        void DrawHalo(Entity ent)
        {
            ClearHalo();
            if (ent == null)
                return;
            Extents3d ext;
            try { ext = ent.GeometricExtents; }
            catch (System.Exception) { return; }
            double w = ext.MaxPoint.X - ext.MinPoint.X;
            double h = ext.MaxPoint.Y - ext.MinPoint.Y;
            double span = Math.Max(w, h);
            if (span < 1e-8)
                span = 1.0;
            double pad = span * 0.15;
            double thick = span * 0.04;
            if (thick < 0.01)
                thick = 0.01;
            double minx = ext.MinPoint.X - pad;
            double miny = ext.MinPoint.Y - pad;
            double maxx = ext.MaxPoint.X + pad;
            double maxy = ext.MaxPoint.Y + pad;
            Autodesk.AutoCAD.DatabaseServices.Polyline pl = new Autodesk.AutoCAD.DatabaseServices.Polyline();
            pl.AddVertexAt(0, new Point2d(minx, miny), 0, thick, thick);
            pl.AddVertexAt(1, new Point2d(maxx, miny), 0, thick, thick);
            pl.AddVertexAt(2, new Point2d(maxx, maxy), 0, thick, thick);
            pl.AddVertexAt(3, new Point2d(minx, maxy), 0, thick, thick);
            pl.Closed = true;
            pl.ColorIndex = 2;
            pl.Elevation = ext.MinPoint.Z;
            try
            {
                TransientManager.CurrentTransientManager.AddTransient(
                    pl, TransientDrawingMode.DirectTopmost, 128, _haloVports);
                _halo = pl;
            }
            catch (System.Exception)
            {
                pl.Dispose();
            }
        }

        static void ZoomTo(Editor ed, Entity ent)
        {
            try
            {
                Extents3d ext = ent.GeometricExtents;
                ext.TransformBy(ed.CurrentUserCoordinateSystem.Inverse());
                ViewTableRecord view = ed.GetCurrentView();
                double w = ext.MaxPoint.X - ext.MinPoint.X;
                double h = ext.MaxPoint.Y - ext.MinPoint.Y;
                if (w < 1e-8) w = 1;
                if (h < 1e-8) h = 1;
                // Previous pad was 1.4; 0.5x magnification is twice the view size (2.8).
                // Keep the current view aspect so a long conduit does not fill the screen on one axis.
                const double pad = 2.8;
                double needW = w * pad;
                double needH = h * pad;
                double aspect = view.Height > 1e-8 ? view.Width / view.Height : 1.0;
                if (needW / needH > aspect)
                    needH = needW / aspect;
                else
                    needW = needH * aspect;
                view.Width = needW;
                view.Height = needH;
                view.CenterPoint = new Point2d((ext.MinPoint.X + ext.MaxPoint.X) / 2.0, (ext.MinPoint.Y + ext.MaxPoint.Y) / 2.0);
                ed.SetCurrentView(view);
            }
            catch (System.Exception)
            {
            }
        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == (Keys.Control | Keys.V))
            {
                PasteCells();
                return true;
            }
            if (keyData == (Keys.Control | Keys.D))
            {
                FillDown();
                return true;
            }
            if (keyData == (Keys.Control | Keys.C))
            {
                CopyCells();
                return true;
            }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        void CopyCells()
        {
            try
            {
                if (_grid.GetCellCount(DataGridViewElementStates.Selected) > 0)
                    Clipboard.SetDataObject(_grid.GetClipboardContent());
            }
            catch (System.Exception)
            {
            }
        }

        bool CanEdit(DataGridViewCell cell)
        {
            if (cell == null || cell.ReadOnly || cell.OwningColumn.ReadOnly)
                return false;
            if (cell.OwningColumn.Name == "Handle")
                return false;
            if (cell.OwningRow != null && cell.OwningRow.IsNewRow)
                return false;
            if (cell.OwningColumn.Name == "Flange")
            {
                string app = MedApps.FromDisplay(Convert.ToString(cell.OwningRow.Cells["Type"].Value));
                if (!UsesFlange(app))
                    return false;
            }
            return true;
        }

        void TrySet(DataGridViewCell cell, string raw)
        {
            if (!CanEdit(cell))
                return;
            if (cell.OwningColumn is DataGridViewCheckBoxColumn)
            {
                string s = (raw ?? "").Trim();
                bool on = s == "T" || s == "True" || s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase);
                cell.Value = on;
                return;
            }
            cell.Value = raw;
        }

        void PasteCells()
        {
            string clip = null;
            try { clip = Clipboard.GetText(); } catch { return; }
            if (string.IsNullOrEmpty(clip))
                return;
            clip = clip.Replace("\r\n", "\n").TrimEnd('\n');
            string[] lines = clip.Split('\n');
            List<DataGridViewCell> selected = new List<DataGridViewCell>();
            foreach (DataGridViewCell c in _grid.SelectedCells)
                selected.Add(c);

            if (lines.Length == 1 && lines[0].IndexOf('\t') < 0 && selected.Count > 1)
            {
                foreach (DataGridViewCell c in selected)
                    TrySet(c, lines[0]);
                return;
            }

            int r0 = _grid.CurrentCell != null ? _grid.CurrentCell.RowIndex : 0;
            int c0 = _grid.CurrentCell != null ? _grid.CurrentCell.ColumnIndex : 0;
            for (int r = 0; r < lines.Length; r++)
            {
                string[] cols = lines[r].Split('\t');
                int ri = r0 + r;
                if (ri >= _grid.Rows.Count || _grid.Rows[ri].IsNewRow)
                    continue;
                for (int c = 0; c < cols.Length; c++)
                {
                    int ci = c0 + c;
                    if (ci >= _grid.Columns.Count)
                        continue;
                    TrySet(_grid.Rows[ri].Cells[ci], cols[c]);
                }
            }
        }

        void FillDown()
        {
            if (_grid.SelectedCells.Count == 0)
                return;
            int minR = int.MaxValue, maxR = -1;
            Dictionary<int, string> top = new Dictionary<int, string>();
            foreach (DataGridViewCell cell in _grid.SelectedCells)
            {
                if (cell.RowIndex < minR)
                    minR = cell.RowIndex;
                if (cell.RowIndex > maxR)
                    maxR = cell.RowIndex;
            }
            foreach (DataGridViewCell cell in _grid.SelectedCells)
            {
                if (cell.RowIndex != minR)
                    continue;
                top[cell.ColumnIndex] = cell.Value == null ? "" : Convert.ToString(cell.Value);
            }
            foreach (DataGridViewCell cell in _grid.SelectedCells)
            {
                if (cell.RowIndex == minR)
                    continue;
                string v;
                if (top.TryGetValue(cell.ColumnIndex, out v))
                    TrySet(cell, v);
            }
        }

        public List<MedRecord> ReadRows()
        {
            List<MedRecord> list = new List<MedRecord>();
            foreach (DataGridViewRow row in _grid.Rows)
            {
                if (row.IsNewRow)
                    continue;
                string type = Convert.ToString(row.Cells["Type"].Value);
                if (string.IsNullOrWhiteSpace(type))
                    continue;
                MedRecord rec = new MedRecord();
                rec.Id = IdFromRow(row);
                rec.AppName = MedApps.FromDisplay(type);
                rec.Set(MedKeys.Tag, Convert.ToString(row.Cells["Tag"].Value));
                rec.Set(MedKeys.RelatedTag, Convert.ToString(row.Cells["RelatedTag"].Value));
                rec.Set(MedKeys.Size, MedXdata.FormatValue(MedField.Size, Convert.ToString(row.Cells["Size"].Value)));
                rec.Set(MedKeys.Alternate, MedXdata.FormatValue(MedField.Alternate, Convert.ToString(row.Cells["Alternate"].Value)));
                rec.Set(MedKeys.Depth, MedXdata.FormatValue(MedField.Depth, Convert.ToString(row.Cells["Depth"].Value)));
                rec.Set(MedKeys.Distance, MedXdata.FormatValue(MedField.Distance, Convert.ToString(row.Cells["Distance"].Value)));
                rec.Set(MedKeys.Code, MedXdata.FormatValue(MedField.Code, Convert.ToString(row.Cells["Code"].Value)));
                bool msr = false;
                if (row.Cells["Measure"].Value is bool)
                    msr = (bool)row.Cells["Measure"].Value;
                rec.Set(MedKeys.Measure, msr ? "T" : "F");
                rec.Set(MedKeys.Flange, MedXdata.FormatValue(MedField.Flange, Convert.ToString(row.Cells["Flange"].Value)));
                list.Add(rec);
            }
            return list;
        }

        public static bool EditEntities(List<ObjectId> ids, List<MedRecord> records)
        {
            if (ids == null || ids.Count == 0)
                return false;
            using (MedRecordsGridForm form = new MedRecordsGridForm(ids, records))
            {
                DialogResult r = AcadApp.ShowModalDialog(form);
                if (r != DialogResult.OK)
                    return false;
                List<MedRecord> updated = form.ReadRows();
                WriteAll(ids, updated);
                return true;
            }
        }

        static void WriteAll(List<ObjectId> ids, List<MedRecord> records)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            using (DocumentLock dl = doc.LockDocument())
            using (Transaction tr = doc.Database.TransactionManager.StartTransaction())
            {
                foreach (ObjectId id in ids)
                {
                    Entity ent = tr.GetObject(id, OpenMode.ForWrite, false) as Entity;
                    if (ent == null)
                        continue;
                    List<MedRecord> mine = new List<MedRecord>();
                    foreach (MedRecord rec in records)
                    {
                        if (rec.Id == id)
                            mine.Add(rec);
                    }
                    MedXdata.WriteEntity(ent, mine, tr);
                }
                tr.Commit();
            }
            doc.Editor.WriteMessage("\nMED Records: wrote {0} record(s) on {1} entit{2}.", records.Count, ids.Count, ids.Count == 1 ? "y" : "ies");
        }
    }
}