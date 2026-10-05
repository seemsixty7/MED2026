using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace MEDDotNet
{
    /// <summary>Palette UI for the 3D block library: search, category filter, thumbnail list, preview, edit, insert/open/rescan.</summary>
    public class Dwg3DLibControl : UserControl
    {
        const string AllCats = "(All categories)", Uncat = "(Uncategorized)", MissingCat = "(Missing files)", NoPreview = "(No preview)";

        readonly TextBox _search = new TextBox();
        readonly ComboBox _catFilter = new ComboBox();
        readonly ComboBox _viewMode = new ComboBox();
        readonly ListView _list = new ListView();
        readonly DataGridView _grid = new DataGridView();
        readonly ContextMenuStrip _excelMenu = new ContextMenuStrip();
        readonly PictureBox _preview = new PictureBox();
        readonly Label _fileLbl = new Label();
        readonly TextBox _desc = new TextBox();
        readonly ComboBox _cat = new ComboBox();
        readonly TextBox _note = new TextBox();
        readonly Button _save = new Button(), _insert = new Button(), _open = new Button(), _rescan = new Button(), _folderBtn = new Button(), _excelBtn = new Button();
        readonly Label _status = new Label();
        readonly ToolTip _tip = new ToolTip();
        readonly SplitContainer _split = new SplitContainer();
        readonly ImageList _small = new ImageList(), _large = new ImageList();

        string _folder;
        List<Dwg3DEntry> _all = new List<Dwg3DEntry>();
        Dwg3DEntry _cur;
        bool _loading, _dirty, _loaded, _gridFilling;
        const string ViewList = "List", ViewTiles = "Tiles", ViewGrid = "Grid";
        const int ColThumb = 0, ColFile = 1, ColCat = 2, ColDesc = 3, ColNote = 4, ColSource = 5;
        readonly Timer _searchTimer = new Timer { Interval = 250 };

        public Dwg3DLibControl()
        {
            Dock = DockStyle.Fill;
            Font = new Font("Segoe UI", 8.25f);
            BuildUi();
        }

        void BuildUi()
        {
            SuspendLayout();
            // --- top: search + category filter + view toggle
            var top = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, RowCount = 2, AutoSize = true, Padding = new Padding(4, 4, 4, 0) };
            top.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            _search.Dock = DockStyle.Fill;
            SetCue(_search, "Search file, description, note, category...");
            _search.TextChanged += delegate { _searchTimer.Stop(); _searchTimer.Start(); };
            _searchTimer.Tick += delegate { _searchTimer.Stop(); ApplyFilter(); };
            _catFilter.DropDownStyle = ComboBoxStyle.DropDownList;
            _catFilter.Dock = DockStyle.Fill;
            _catFilter.SelectedIndexChanged += delegate { if (!_loading) ApplyFilter(); };
            _viewMode.DropDownStyle = ComboBoxStyle.DropDownList;
            _viewMode.Items.AddRange(new object[] { ViewList, ViewTiles, ViewGrid });
            _viewMode.Width = 64;
            _viewMode.Margin = new Padding(3, 3, 0, 3);
            _viewMode.SelectedIndexChanged += delegate { if (!_loading) SetView(_viewMode.SelectedItem as string, true); };
            _tip.SetToolTip(_viewMode, "List / large thumbnail Tiles / editable Grid");
            top.Controls.Add(_search, 0, 0); top.SetColumnSpan(_search, 2);
            top.Controls.Add(_catFilter, 0, 1);
            top.Controls.Add(_viewMode, 1, 1);

            // --- list
            _small.ImageSize = new Size(48, 48); _small.ColorDepth = ColorDepth.Depth32Bit;
            _large.ImageSize = new Size(110, 110); _large.ColorDepth = ColorDepth.Depth32Bit;
            _list.Dock = DockStyle.Fill;
            _list.View = View.Details;
            _list.FullRowSelect = true;
            _list.HideSelection = false;
            _list.MultiSelect = false;
            _list.SmallImageList = _small;
            _list.LargeImageList = _large;
            _list.Columns.Add("File", 150);
            _list.Columns.Add("Category", 80);
            _list.Columns.Add("Description", 180);
            _list.ShowItemToolTips = true;
            _list.SelectedIndexChanged += delegate { OnSelect(); };
            _list.ItemActivate += delegate { DoInsert(); };
            _list.ItemDrag += OnItemDrag;
            _list.ColumnClick += OnColumnClick;
            _split.Panel1.Controls.Add(_list);
            BuildGrid();
            _split.Panel1.Controls.Add(_grid);

            // --- details
            var det = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, Padding = new Padding(4), AutoScroll = true };
            det.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            det.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            int row = 0;
            _preview.SizeMode = PictureBoxSizeMode.Zoom;
            _preview.BackColor = Color.FromArgb(33, 40, 48);
            _preview.Dock = DockStyle.Fill;
            _preview.MinimumSize = new Size(100, 160);
            _preview.MouseDown += OnPreviewMouseDown;
            det.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            det.Controls.Add(_preview, 0, row); det.SetColumnSpan(_preview, 2); row++;

            _fileLbl.AutoSize = true; _fileLbl.Dock = DockStyle.Fill; _fileLbl.ForeColor = SystemColors.GrayText; _fileLbl.Padding = new Padding(0, 2, 0, 2);
            det.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            det.Controls.Add(_fileLbl, 0, row); det.SetColumnSpan(_fileLbl, 2); row++;

            det.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            det.Controls.Add(Lbl("Description"), 0, row);
            _desc.Dock = DockStyle.Fill; _desc.TextChanged += delegate { MarkDirty(); };
            det.Controls.Add(_desc, 1, row); row++;

            det.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            det.Controls.Add(Lbl("Category"), 0, row);
            _cat.Dock = DockStyle.Fill; _cat.DropDownStyle = ComboBoxStyle.DropDown;
            _cat.AutoCompleteMode = AutoCompleteMode.SuggestAppend; _cat.AutoCompleteSource = AutoCompleteSource.ListItems;
            _cat.TextChanged += delegate { MarkDirty(); };
            det.Controls.Add(_cat, 1, row); row++;

            det.RowStyles.Add(new RowStyle(SizeType.Absolute, 58));
            det.Controls.Add(Lbl("Note"), 0, row);
            _note.Dock = DockStyle.Fill; _note.Multiline = true; _note.ScrollBars = ScrollBars.Vertical; _note.AcceptsReturn = true;
            _note.TextChanged += delegate { MarkDirty(); };
            det.Controls.Add(_note, 1, row); row++;

            var btns = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoSize = true, WrapContents = true, Margin = new Padding(0) };
            Btn(_insert, "Insert", "Insert the selected DWG as a block (or double-click / drag it into the drawing)", delegate { DoInsert(); });
            Btn(_save, "Save", "Save description / category / note (Ctrl+S)", delegate { SaveCurrent(true); });
            Btn(_open, "Open DWG", "Open the DWG read-only in AutoCAD", delegate { DoOpen(); });
            _insert.Font = new Font(Font, FontStyle.Bold);
            btns.Controls.AddRange(new Control[] { _insert, _save, _open });
            det.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            det.Controls.Add(btns, 0, row); det.SetColumnSpan(btns, 2); row++;
            _split.Panel2.Controls.Add(det);

            _split.Dock = DockStyle.Fill;
            _split.Orientation = Orientation.Horizontal;
            _split.SplitterWidth = 5;

            // --- bottom: rescan / folder / status
            var bottom = new TableLayoutPanel { Dock = DockStyle.Bottom, ColumnCount = 4, RowCount = 2, AutoSize = true, Padding = new Padding(4, 0, 4, 4) };
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            Btn(_rescan, "Rescan", "Rescan the folder: add new DWGs, flag missing ones, refresh changed previews (Shift+click re-extracts all previews)", delegate { DoRescan(); });
            Btn(_folderBtn, "Folder...", "Choose the 3D library folder (remembered per user)", delegate { ChooseFolder(); });
            _status.AutoSize = true; _status.Dock = DockStyle.Fill; _status.TextAlign = ContentAlignment.MiddleLeft; _status.AutoEllipsis = true;
            Btn(_excelBtn, "Excel \u25BE", "Export the catalog to an Excel bulk-edit workbook, or import Category / Description / Note from one", delegate { _excelMenu.Show(_excelBtn, new Point(0, _excelBtn.Height)); });
            _excelMenu.Items.Add("Export to Excel...", null, delegate { DoExport(); });
            _excelMenu.Items.Add("Import from Excel...", null, delegate { DoImport(); });
            bottom.Controls.Add(_rescan, 0, 0); bottom.Controls.Add(_folderBtn, 1, 0); bottom.Controls.Add(_excelBtn, 2, 0);
            bottom.Controls.Add(_status, 0, 1); bottom.SetColumnSpan(_status, 4);

            Controls.Add(_split);
            Controls.Add(top);
            Controls.Add(bottom);
            ResumeLayout(true);

            SetEditorEnabled(false);
            Resize += delegate { FixSplitter(); };
            string v = Dwg3DLibSettings.Get("View", ViewList);
            if (v != ViewTiles && v != ViewGrid) v = ViewList;
            _loading = true; _viewMode.SelectedItem = v; _loading = false;
            SetView(v, false);
        }

        bool _splitInit;
        void FixSplitter()
        {
            if (_splitInit || _split.Height < 300) return;
            _splitInit = true;
            try { _split.SplitterDistance = Math.Max(120, (int)(_split.Height * 0.45)); } catch { }
        }

        static Label Lbl(string t) { return new Label { Text = t, AutoSize = true, Anchor = AnchorStyles.Left | AnchorStyles.Top, Padding = new Padding(0, 5, 2, 0) }; }

        void Btn(Button b, string text, string tip, EventHandler click)
        {
            b.Text = text; b.AutoSize = true; b.AutoSizeMode = AutoSizeMode.GrowAndShrink; b.MinimumSize = new Size(64, 24);
            b.Click += click; _tip.SetToolTip(b, tip);
        }

        static void SetCue(TextBox tb, string cue)
        {
            tb.HandleCreated += delegate { try { SendMessage(tb.Handle, 0x1501, (IntPtr)1, cue); } catch { } };
        }
        [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
        static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, string lParam);

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == (Keys.Control | Keys.S)) { SaveCurrent(true); return true; }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        // ------------------------------------------------------------------ data

        public void EnsureLoaded()
        {
            if (_loaded) return;
            _loaded = true;
            _folder = Dwg3DLibSettings.ResolveFolder();
            Reload(true);
        }

        void Reload(bool scanIfEmpty)
        {
            Cursor old = Cursor.Current;
            Cursor.Current = Cursors.WaitCursor;
            try
            {
                if (!Directory.Exists(_folder)) { _all = new List<Dwg3DEntry>(); FillCategories(new List<string>()); ApplyFilter(); Status("Folder not found: " + _folder + ". Use Folder..."); return; }
                string dbPath = Dwg3DLibSettings.DbPath(_folder);
                List<string> cats;
                using (var db = new Dwg3DLibDb(dbPath))
                {
                    _all = db.LoadAll();
                    if (_all.Count == 0 && scanIfEmpty)
                        _all = Dwg3DScanner.Scan(db, _folder, false).Entries;
                    cats = db.Categories();
                }
                BuildImages();
                FillCategories(cats);
                ApplyFilter();
                Status(_all.Count + " blocks in " + _folder);
            }
            catch (Exception ex) { Status("Load failed: " + ex.Message); MessageBox.Show("Could not load the 3D library:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
            finally { Cursor.Current = old; }
        }

        void BuildImages()
        {
            _gridFilling = true;
            try { _grid.Rows.Clear(); } finally { _gridFilling = false; }
            _list.BeginUpdate();
            _list.Items.Clear();
            _small.Images.Clear();
            _large.Images.Clear();
            _list.EndUpdate();
            foreach (var e in _all) { if (e.Small != null) { e.Small.Dispose(); e.Small = null; } }
            AddImages(_small, 48);
            if (_list.View == View.LargeIcon) AddImages(_large, 110);
        }

        void AddImages(ImageList il, int size)
        {
            var back = Color.FromArgb(33, 40, 48);
            using (var ph = Dwg3DThumbnail.Placeholder(size, size, "No preview"))
                il.Images.Add("none", Dwg3DThumbnail.Scaled(ph, size, size, back));
            foreach (var e in _all)
            {
                using (var img = Dwg3DThumbnail.FromPng(e.Thumb))
                    if (img != null) il.Images.Add(e.Id.ToString(), Dwg3DThumbnail.Scaled(img, size, size, back));
            }
        }

        void FillCategories(List<string> cats)
        {
            _loading = true;
            try
            {
                string sel = _catFilter.SelectedItem as string;
                _catFilter.Items.Clear();
                _catFilter.Items.AddRange(new object[] { AllCats, Uncat, MissingCat, NoPreview });
                foreach (var c in cats) _catFilter.Items.Add(c);
                int k = sel != null ? _catFilter.Items.IndexOf(sel) : -1;
                _catFilter.SelectedIndex = k >= 0 ? k : 0;

                string curText = _cat.Text;
                bool wasDirty = _dirty;
                _cat.Items.Clear();
                foreach (var c in cats) _cat.Items.Add(c);
                _cat.Text = curText;
                _dirty = wasDirty;
            }
            finally { _loading = false; }
        }

        IEnumerable<Dwg3DEntry> Filtered()
        {
            string cat = _catFilter.SelectedItem as string ?? AllCats;
            string[] words = (_search.Text ?? "").Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var e in _all)
            {
                if (cat == Uncat) { if (e.Category.Length > 0) continue; }
                else if (cat == MissingCat) { if (!e.Missing) continue; }
                else if (cat == NoPreview) { if (e.Thumb != null) continue; }
                else if (cat != AllCats && !string.Equals(e.Category, cat, StringComparison.OrdinalIgnoreCase)) continue;
                if (words.Length > 0)
                {
                    string hay = (e.File + " " + e.Description + " " + e.Note + " " + e.Category + " " + e.SourcePath).ToLowerInvariant();
                    bool ok = true;
                    foreach (var w in words) if (hay.IndexOf(w.ToLowerInvariant(), StringComparison.Ordinal) < 0) { ok = false; break; }
                    if (!ok) continue;
                }
                yield return e;
            }
        }

        void ApplyFilter()
        {
            if (_dirty) SaveCurrent(false);
            long keep = _cur != null ? _cur.Id : -1;
            var items = new List<ListViewItem>();
            foreach (var e in Filtered())
            {
                var it = new ListViewItem(Path.GetFileNameWithoutExtension(e.File));
                it.SubItems.Add(e.Category);
                it.SubItems.Add(e.Description);
                it.ImageKey = e.Thumb != null && _small.Images.ContainsKey(e.Id.ToString()) ? e.Id.ToString() : "none";
                it.Tag = e;
                it.ToolTipText = e.File + (e.Description.Length > 0 ? "\n" + e.Description : "") + (e.Missing ? "\n(missing file)" : "");
                if (e.Missing) it.ForeColor = Color.Firebrick;
                items.Add(it);
            }
            if (IsGrid)
            {
                FillGrid(items.Select(i => (Dwg3DEntry)i.Tag).ToList(), keep);
                Status(items.Count + " of " + _all.Count + " blocks");
                return;
            }
            _list.BeginUpdate();
            _list.Items.Clear();
            _list.Items.AddRange(items.ToArray());
            _list.EndUpdate();
            ListViewItem sel = items.FirstOrDefault(i => ((Dwg3DEntry)i.Tag).Id == keep);
            if (sel != null) { sel.Selected = true; sel.EnsureVisible(); }
            else ShowEntry(null);
            Status(items.Count + " of " + _all.Count + " blocks");
        }

        string _view = ViewList;
        bool IsGrid { get { return _view == ViewGrid; } }

        void SetView(string v, bool refill)
        {
            if (_dirty) SaveCurrent(false);
            if (_grid.IsCurrentCellInEditMode) _grid.EndEdit();
            bool grid = v == ViewGrid;
            _view = v;
            if (v == ViewTiles)
            {
                if (_large.Images.Count == 0 && _all.Count > 0) AddImages(_large, 110);
                _list.View = View.LargeIcon;
            }
            else _list.View = View.Details;
            _grid.Visible = grid;
            _list.Visible = !grid;
            Dwg3DLibSettings.Set("View", v);
            if (refill && _loaded) ApplyFilter();
        }

        int _sortCol = -1; bool _sortDesc;
        void OnColumnClick(object sender, ColumnClickEventArgs e)
        {
            _sortDesc = _sortCol == e.Column && !_sortDesc;
            _sortCol = e.Column;
            Func<Dwg3DEntry, string> key = x => e.Column == 1 ? x.Category : e.Column == 2 ? x.Description : x.File;
            _all = (_sortDesc ? _all.OrderByDescending(key, StringComparer.OrdinalIgnoreCase) : _all.OrderBy(key, StringComparer.OrdinalIgnoreCase)).ToList();
            ApplyFilter();
        }

        // ------------------------------------------------------------------ selection / edit

        Dwg3DEntry Selected()
        {
            if (IsGrid) return _grid.CurrentRow != null ? _grid.CurrentRow.Tag as Dwg3DEntry : null;
            return _list.SelectedItems.Count > 0 ? _list.SelectedItems[0].Tag as Dwg3DEntry : null;
        }

        void OnSelect()
        {
            var e = Selected();
            if (e == _cur) return;
            if (_dirty) SaveCurrent(false);
            ShowEntry(e);
        }

        void ShowEntry(Dwg3DEntry e)
        {
            _loading = true;
            try
            {
                _cur = e;
                var old = _preview.Image;
                _preview.Image = null;
                if (old != null) old.Dispose();
                if (e == null)
                {
                    _fileLbl.Text = "";
                    _desc.Text = ""; _cat.Text = ""; _note.Text = "";
                    SetEditorEnabled(false);
                    return;
                }
                _preview.Image = Dwg3DThumbnail.FromPng(e.Thumb) ?? Dwg3DThumbnail.Placeholder(220, 160, e.Missing ? "File missing" : "No preview");
                _fileLbl.Text = e.File + (e.Missing ? "  (MISSING)" : "") + (e.FileSize > 0 ? "  " + (e.FileSize / 1024) + " KB" : "")
                    + (e.FileModified.Length > 0 ? "  " + e.FileModified : "") + (e.SourcePath.Length > 0 ? "\nSource: " + e.SourcePath : "");
                _desc.Text = e.Description; _cat.Text = e.Category; _note.Text = e.Note;
                SetEditorEnabled(true);
                _insert.Enabled = _open.Enabled = !e.Missing;
            }
            finally { _loading = false; _dirty = false; _save.Enabled = false; }
        }

        void SetEditorEnabled(bool on)
        {
            _desc.Enabled = _cat.Enabled = _note.Enabled = on;
            _insert.Enabled = _open.Enabled = on;
            _save.Enabled = false;
        }

        void MarkDirty()
        {
            if (_loading || _cur == null) return;
            _dirty = true;
            _save.Enabled = true;
        }

        void SaveCurrent(bool explicitSave)
        {
            var e = _cur;
            if (e == null || (!_dirty && !explicitSave)) return;
            string d = _desc.Text.Trim(), c = _cat.Text.Trim(), n = _note.Text.TrimEnd();
            if (d == e.Description && c == e.Category && n == e.Note) { _dirty = false; _save.Enabled = false; return; }
            try
            {
                List<string> cats;
                using (var db = new Dwg3DLibDb(Dwg3DLibSettings.DbPath(_folder)))
                {
                    e.Description = d; e.Category = c; e.Note = n;
                    db.SaveEdits(e);
                    cats = db.Categories();
                }
                _dirty = false; _save.Enabled = false;
                foreach (ListViewItem it in _list.Items)
                    if (it.Tag == e) { it.SubItems[1].Text = e.Category; it.SubItems[2].Text = e.Description; break; }
                SyncGridRow(e);
                if (c.Length > 0 && !_catFilter.Items.Contains(c)) FillCategories(cats);
                Status("Saved " + e.File);
            }
            catch (Exception ex) { Status("Save failed: " + ex.Message); MessageBox.Show("Save failed:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
        }

        // ------------------------------------------------------------------ grid view

        void BuildGrid()
        {
            _grid.Dock = DockStyle.Fill;
            _grid.Visible = false;
            _grid.AllowUserToAddRows = false;
            _grid.AllowUserToDeleteRows = false;
            _grid.AllowUserToResizeRows = false;
            _grid.RowHeadersVisible = false;
            _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            _grid.MultiSelect = false;
            _grid.EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2;
            _grid.BackgroundColor = SystemColors.Window;
            _grid.BorderStyle = BorderStyle.None;
            _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.None;
            _grid.RowTemplate.Height = 40;
            _grid.DefaultCellStyle.WrapMode = DataGridViewTriState.False;
            _grid.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            _grid.ShowCellToolTips = true;

            var thumb = new DataGridViewImageColumn { Name = "Thumb", HeaderText = "", Width = 44, ImageLayout = DataGridViewImageCellLayout.Zoom, ReadOnly = true, SortMode = DataGridViewColumnSortMode.NotSortable, Resizable = DataGridViewTriState.False };
            thumb.DefaultCellStyle.NullValue = null;
            thumb.DefaultCellStyle.BackColor = Color.FromArgb(33, 40, 48);
            _grid.Columns.Add(thumb);
            _grid.Columns.Add(TextCol("File", "File", 140, true));
            _grid.Columns.Add(TextCol("Category", "Category", 110, false));
            _grid.Columns.Add(TextCol("Description", "Description", 180, false));
            _grid.Columns.Add(TextCol("Note", "Note", 150, false));
            _grid.Columns.Add(TextCol("Source", "Source", 200, true));
            foreach (int c in new[] { ColFile, ColSource }) _grid.Columns[c].DefaultCellStyle.ForeColor = SystemColors.GrayText;

            _grid.SelectionChanged += delegate { if (!_gridFilling && IsGrid) OnSelect(); };
            _grid.CellDoubleClick += OnGridDoubleClick;
            _grid.CellClick += delegate (object s, DataGridViewCellEventArgs ev)
            {
                if (ev.RowIndex >= 0 && Editable(ev.ColumnIndex) && !_grid.IsCurrentCellInEditMode) _grid.BeginEdit(false);
            };
            _grid.CellEndEdit += OnGridCellEndEdit;
            _grid.EditingControlShowing += OnGridEditingControlShowing;
            _grid.KeyDown += delegate (object s, KeyEventArgs ev)
            {
                if (ev.KeyCode == Keys.Enter && !_grid.IsCurrentCellInEditMode && _grid.CurrentCell != null && !Editable(_grid.CurrentCell.ColumnIndex))
                { ev.Handled = true; DoInsert(); }
            };
            _grid.MouseDown += OnGridMouseDown;
            _grid.MouseMove += OnGridMouseMove;
            _grid.Sorted += delegate { Dwg3DEntry e = Selected(); if (e != null && _grid.CurrentRow != null) _grid.FirstDisplayedScrollingRowIndex = Math.Max(0, _grid.CurrentRow.Index - 2); };
        }

        static DataGridViewTextBoxColumn TextCol(string name, string header, int width, bool ro)
        {
            return new DataGridViewTextBoxColumn { Name = name, HeaderText = header, Width = width, ReadOnly = ro, SortMode = DataGridViewColumnSortMode.Automatic };
        }

        static bool Editable(int col) { return col == ColCat || col == ColDesc || col == ColNote; }

        Image GridThumb(Dwg3DEntry e)
        {
            if (e.Small != null) return e.Small;
            using (var img = Dwg3DThumbnail.FromPng(e.Thumb))
                e.Small = img != null ? Dwg3DThumbnail.Scaled(img, 40, 40, Color.FromArgb(33, 40, 48)) : Dwg3DThumbnail.Placeholder(40, 40, "-");
            return e.Small;
        }

        void FillGrid(List<Dwg3DEntry> rows, long keepId)
        {
            DataGridViewColumn sortCol = _grid.SortedColumn;
            SortOrder order = _grid.SortOrder;
            _gridFilling = true;
            try
            {
                _grid.Rows.Clear();
                var arr = new DataGridViewRow[rows.Count];
                for (int i = 0; i < rows.Count; i++)
                {
                    var e = rows[i];
                    var r = new DataGridViewRow();
                    r.CreateCells(_grid, GridThumb(e), e.File, e.Category, e.Description, e.Note, e.SourcePath);
                    r.Tag = e;
                    if (e.Missing) r.DefaultCellStyle.ForeColor = Color.Firebrick;
                    r.Cells[ColFile].ToolTipText = e.File + (e.Missing ? "\n(missing file)" : "") + "\nDouble-click to insert, drag into the drawing";
                    arr[i] = r;
                }
                _grid.Rows.AddRange(arr);
                if (sortCol != null && order != SortOrder.None)
                    _grid.Sort(sortCol, order == SortOrder.Ascending ? System.ComponentModel.ListSortDirection.Ascending : System.ComponentModel.ListSortDirection.Descending);
                _grid.ClearSelection();
                _grid.CurrentCell = null;
            }
            finally { _gridFilling = false; }
            foreach (DataGridViewRow r in _grid.Rows)
                if (((Dwg3DEntry)r.Tag).Id == keepId)
                {
                    _grid.CurrentCell = r.Cells[ColFile];
                    r.Selected = true;
                    try { _grid.FirstDisplayedScrollingRowIndex = Math.Max(0, r.Index - 2); } catch { }
                    return;
                }
            ShowEntry(null);
        }

        void SyncGridRow(Dwg3DEntry e)
        {
            foreach (DataGridViewRow r in _grid.Rows)
                if (r.Tag == e)
                {
                    r.Cells[ColCat].Value = e.Category; r.Cells[ColDesc].Value = e.Description; r.Cells[ColNote].Value = e.Note;
                    break;
                }
        }

        void OnGridDoubleClick(object sender, DataGridViewCellEventArgs ev)
        {
            if (ev.RowIndex < 0) return;
            if (Editable(ev.ColumnIndex)) { if (!_grid.IsCurrentCellInEditMode) _grid.BeginEdit(true); return; }
            DoInsert();
        }

        void OnGridEditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs ev)
        {
            var tb = ev.Control as TextBox;
            if (tb == null) return;
            if (_grid.CurrentCell != null && _grid.CurrentCell.ColumnIndex == ColCat)
            {
                var src = new AutoCompleteStringCollection();
                foreach (var c in _cat.Items) src.Add(c.ToString());
                foreach (var c in Dwg3DExcel.SuggestedCategories) src.Add(c);
                tb.AutoCompleteCustomSource = src;
                tb.AutoCompleteSource = AutoCompleteSource.CustomSource;
                tb.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
            }
            else tb.AutoCompleteMode = AutoCompleteMode.None;
        }

        void OnGridCellEndEdit(object sender, DataGridViewCellEventArgs ev)
        {
            if (ev.RowIndex < 0 || !Editable(ev.ColumnIndex)) return;
            var row = _grid.Rows[ev.RowIndex];
            var e = row.Tag as Dwg3DEntry;
            if (e == null) return;
            string v = Convert.ToString(row.Cells[ev.ColumnIndex].Value) ?? "";
            v = ev.ColumnIndex == ColNote ? v.TrimEnd() : v.Trim();
            string cur = ev.ColumnIndex == ColCat ? e.Category : ev.ColumnIndex == ColDesc ? e.Description : e.Note;
            if (v == cur) return;
            if (_dirty && _cur == e) SaveCurrent(false);   // keep the details panel and the cell edit from fighting
            string oc = e.Category, od = e.Description, on = e.Note;
            if (ev.ColumnIndex == ColCat) e.Category = v; else if (ev.ColumnIndex == ColDesc) e.Description = v; else e.Note = v;
            try
            {
                List<string> cats;
                using (var db = new Dwg3DLibDb(Dwg3DLibSettings.DbPath(_folder)))
                {
                    db.SaveEdits(e);
                    cats = db.Categories();
                }
                if (ev.ColumnIndex == ColCat && v.Length > 0 && !_catFilter.Items.Contains(v)) FillCategories(cats);
                if (_cur == e) ShowEntry(e);
                Status("Saved " + e.File);
            }
            catch (Exception ex)
            {
                e.Category = oc; e.Description = od; e.Note = on;
                SyncGridRow(e);
                Status("Save failed: " + ex.Message);
            }
        }

        Rectangle _dragBox = Rectangle.Empty;
        Dwg3DEntry _dragEntry;
        void OnGridMouseDown(object sender, MouseEventArgs ev)
        {
            _dragBox = Rectangle.Empty; _dragEntry = null;
            if (ev.Button != MouseButtons.Left) return;
            var hit = _grid.HitTest(ev.X, ev.Y);
            if (hit.Type != DataGridViewHitTestType.Cell || hit.RowIndex < 0 || Editable(hit.ColumnIndex)) return;
            _dragEntry = _grid.Rows[hit.RowIndex].Tag as Dwg3DEntry;
            Size ds = SystemInformation.DragSize;
            _dragBox = new Rectangle(new Point(ev.X - ds.Width / 2, ev.Y - ds.Height / 2), ds);
        }

        void OnGridMouseMove(object sender, MouseEventArgs ev)
        {
            if ((ev.Button & MouseButtons.Left) == 0 || _dragEntry == null || _dragBox == Rectangle.Empty || _dragBox.Contains(ev.X, ev.Y)) return;
            var e = _dragEntry;
            _dragBox = Rectangle.Empty; _dragEntry = null;
            if (e.Missing) return;
            string p = FullPath(e);
            if (File.Exists(p)) Dwg3DLibPalette.StartDrag(_grid, p);
        }

        // ------------------------------------------------------------------ Excel round trip

        void DoExport()
        {
            if (_dirty) SaveCurrent(false);
            if (_all.Count == 0) { Status("Nothing to export."); return; }
            using (var dlg = new SaveFileDialog { Filter = "Excel workbook (*.xlsx)|*.xlsx", FileName = "Dwg3DCatalog_BulkEdit.xlsx", InitialDirectory = _folder, OverwritePrompt = true })
            {
                if (dlg.ShowDialog(this) != DialogResult.OK) return;
                Cursor old = Cursor.Current;
                Cursor.Current = Cursors.WaitCursor;
                try
                {
                    List<string> cats;
                    using (var db = new Dwg3DLibDb(Dwg3DLibSettings.DbPath(_folder))) cats = db.Categories();
                    var rows = _all.OrderBy(x => x.File, StringComparer.OrdinalIgnoreCase).ToList();
                    Dwg3DExcel.Export(rows, cats, dlg.FileName, true);
                    Status("Exported " + rows.Count + " rows to " + dlg.FileName);
                    if (MessageBox.Show("Exported " + rows.Count + " rows to\n" + dlg.FileName + "\n\nEdit Category / Description / Note, save, then use Excel > Import.\n\nOpen it now?",
                        "MED 3D Library", MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes)
                        System.Diagnostics.Process.Start(dlg.FileName);
                }
                catch (Exception ex) { Status("Export failed: " + ex.Message); MessageBox.Show("Export failed:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
                finally { Cursor.Current = old; }
            }
        }

        void DoImport()
        {
            if (_dirty) SaveCurrent(false);
            string dbPath = Dwg3DLibSettings.DbPath(_folder);
            using (var dlg = new OpenFileDialog { Filter = "Excel workbook (*.xlsx)|*.xlsx", InitialDirectory = _folder, FileName = "Dwg3DCatalog_BulkEdit.xlsx" })
            {
                if (dlg.ShowDialog(this) != DialogResult.OK) return;
                try
                {
                    var dry = Dwg3DExcel.Import(dbPath, dlg.FileName, true);
                    string nf = dry.NotFound.Count > 0 ? "\n\nNot found (first 10):\n" + string.Join("\n", dry.NotFound.Take(10)) : "";
                    if (dry.Fields == 0) { MessageBox.Show(dry + "\n\nNothing to update." + nf, "MED 3D Library"); return; }
                    if (MessageBox.Show(dry + nf + "\n\nOnly non-blank cells that differ are applied; (clear) empties a field.\nThe database is backed up first. Import now?",
                        "MED 3D Library - Import from Excel", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK) return;
                    var res = Dwg3DExcel.Import(dbPath, dlg.FileName, false);
                    _cur = null;
                    Reload(false);
                    Status(res.ToString());
                    MessageBox.Show(res + "\n\nBackup: " + res.BackupPath, "MED 3D Library");
                }
                catch (IOException ex) { MessageBox.Show("Import failed (close the workbook in Excel first?):\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
                catch (Exception ex) { MessageBox.Show("Import failed:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
            }
        }

        // ------------------------------------------------------------------ actions

        string FullPath(Dwg3DEntry e) { return Path.Combine(_folder, e.File); }

        void DoInsert()
        {
            var e = Selected();
            if (e == null) return;
            if (_dirty) SaveCurrent(false);
            string p = FullPath(e);
            if (!File.Exists(p)) { Status("File missing: " + e.File); return; }
            try { Dwg3DLibPalette.RequestInsert(p); }
            catch (Exception ex) { Status("Insert failed: " + ex.Message); }
        }

        void DoOpen()
        {
            var e = Selected();
            if (e == null) return;
            try { Dwg3DLibPalette.OpenDwg(FullPath(e)); }
            catch (Exception ex) { Status("Open failed: " + ex.Message); }
        }

        void OnItemDrag(object sender, ItemDragEventArgs ev)
        {
            var it = ev.Item as ListViewItem;
            var e = it != null ? it.Tag as Dwg3DEntry : null;
            if (e == null || e.Missing) return;
            string p = FullPath(e);
            if (!File.Exists(p)) return;
            Dwg3DLibPalette.StartDrag(_list, p);
        }

        void OnPreviewMouseDown(object sender, MouseEventArgs ev)
        {
            if (ev.Button != MouseButtons.Left || _cur == null || _cur.Missing) return;
            string p = FullPath(_cur);
            if (File.Exists(p)) Dwg3DLibPalette.StartDrag(_preview, p);
        }

        void DoRescan()
        {
            if (_dirty) SaveCurrent(false);
            if (!Directory.Exists(_folder)) { Status("Folder not found: " + _folder); return; }
            bool force = (ModifierKeys & Keys.Shift) == Keys.Shift;
            Cursor old = Cursor.Current;
            Cursor.Current = Cursors.WaitCursor;
            try
            {
                Dwg3DScanResult res;
                using (var db = new Dwg3DLibDb(Dwg3DLibSettings.DbPath(_folder)))
                    res = Dwg3DScanner.Scan(db, _folder, force);
                Reload(false);
                Status(res.ToString());
            }
            catch (Exception ex) { Status("Rescan failed: " + ex.Message); MessageBox.Show("Rescan failed:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
            finally { Cursor.Current = old; }
        }

        void ChooseFolder()
        {
            if (_dirty) SaveCurrent(false);
            using (var dlg = new FolderBrowserDialog { Description = "3D block library folder (DWGs + Dwg3DCatalog.db)", SelectedPath = _folder ?? "" })
            {
                if (dlg.ShowDialog(this) != DialogResult.OK) return;
                _folder = dlg.SelectedPath;
                Dwg3DLibSettings.Set("Folder", _folder);
                _cur = null;
                Reload(true);
            }
        }

        void Status(string s) { _status.Text = s; _tip.SetToolTip(_status, s); }
    }
}
