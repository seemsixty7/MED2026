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
        readonly Button _viewBtn = new Button();
        readonly ListView _list = new ListView();
        readonly PictureBox _preview = new PictureBox();
        readonly Label _fileLbl = new Label();
        readonly TextBox _desc = new TextBox();
        readonly ComboBox _cat = new ComboBox();
        readonly TextBox _note = new TextBox();
        readonly Button _save = new Button(), _insert = new Button(), _open = new Button(), _rescan = new Button(), _folderBtn = new Button();
        readonly Label _status = new Label();
        readonly ToolTip _tip = new ToolTip();
        readonly SplitContainer _split = new SplitContainer();
        readonly ImageList _small = new ImageList(), _large = new ImageList();

        string _folder;
        List<Dwg3DEntry> _all = new List<Dwg3DEntry>();
        Dwg3DEntry _cur;
        bool _loading, _dirty, _loaded;
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
            _viewBtn.Text = "Tiles";
            _viewBtn.AutoSize = true;
            _viewBtn.Click += delegate { ToggleView(); };
            _tip.SetToolTip(_viewBtn, "Switch between list and large thumbnails");
            top.Controls.Add(_search, 0, 0); top.SetColumnSpan(_search, 2);
            top.Controls.Add(_catFilter, 0, 1);
            top.Controls.Add(_viewBtn, 1, 1);

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
            var bottom = new TableLayoutPanel { Dock = DockStyle.Bottom, ColumnCount = 3, AutoSize = true, Padding = new Padding(4, 0, 4, 4) };
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            bottom.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            Btn(_rescan, "Rescan", "Rescan the folder: add new DWGs, flag missing ones, refresh changed previews (Shift+click re-extracts all previews)", delegate { DoRescan(); });
            Btn(_folderBtn, "Folder...", "Choose the 3D library folder (remembered per user)", delegate { ChooseFolder(); });
            _status.AutoSize = true; _status.Dock = DockStyle.Fill; _status.TextAlign = ContentAlignment.MiddleLeft; _status.AutoEllipsis = true;
            bottom.Controls.Add(_rescan, 0, 0); bottom.Controls.Add(_folderBtn, 1, 0); bottom.Controls.Add(_status, 2, 0);

            Controls.Add(_split);
            Controls.Add(top);
            Controls.Add(bottom);
            ResumeLayout(true);

            SetEditorEnabled(false);
            Resize += delegate { FixSplitter(); };
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
            _list.BeginUpdate();
            _list.Items.Clear();
            _list.Items.AddRange(items.ToArray());
            _list.EndUpdate();
            ListViewItem sel = items.FirstOrDefault(i => ((Dwg3DEntry)i.Tag).Id == keep);
            if (sel != null) { sel.Selected = true; sel.EnsureVisible(); }
            else ShowEntry(null);
            Status(items.Count + " of " + _all.Count + " blocks");
        }

        void ToggleView()
        {
            if (_list.View == View.Details)
            {
                if (_large.Images.Count == 0) AddImages(_large, 110);
                _list.View = View.LargeIcon;
                _viewBtn.Text = "List";
            }
            else
            {
                _list.View = View.Details;
                _viewBtn.Text = "Tiles";
            }
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
                if (c.Length > 0 && !_catFilter.Items.Contains(c)) FillCategories(cats);
                Status("Saved " + e.File);
            }
            catch (Exception ex) { Status("Save failed: " + ex.Message); MessageBox.Show("Save failed:\n" + ex.Message, "MED 3D Library", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
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
            var data = new DataObject(DataFormats.FileDrop, new[] { p });
            DoDragDrop(data, DragDropEffects.Copy);
        }

        void OnPreviewMouseDown(object sender, MouseEventArgs ev)
        {
            if (ev.Button != MouseButtons.Left || _cur == null || _cur.Missing) return;
            string p = FullPath(_cur);
            if (File.Exists(p)) DoDragDrop(new DataObject(DataFormats.FileDrop, new[] { p }), DragDropEffects.Copy);
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
