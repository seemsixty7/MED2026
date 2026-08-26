using Autodesk.AutoCAD.DatabaseServices;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace MEDDotNet
{
    internal class TypeFilterItem
    {
        public string AppName; // null = All singles, "*" = multi-record entities
        public string Label;
        public int Count;
        public bool Multi;

        public override string ToString()
        {
            if (Count > 0)
                return string.Format("{0} ({1})", Label, Count);
            return Label;
        }
    }

    internal class MedPropertiesControl : UserControl
    {
        ComboBox _typeFilter;
        Label _status;
        readonly Dictionary<MedField, Control> _editors = new Dictionary<MedField, Control>();
        readonly Dictionary<MedField, Label> _labels = new Dictionary<MedField, Label>();
        CheckBox _measure;
        bool _refreshing;
        List<MedRecord> _current = new List<MedRecord>();
        ComboBox _codeCombo;
        Button _recordsBtn;
        Autodesk.AutoCAD.DatabaseServices.ObjectId _singleId;

        public event EventHandler ApplyRequested;
        public event EventHandler RecordsRequested;
        public Autodesk.AutoCAD.DatabaseServices.ObjectId SingleEntityId { get { return _singleId; } }

        public MedPropertiesControl()
        {
            Dock = DockStyle.Fill;
            BackColor = SystemColors.Window;
            Padding = new Padding(6);
            AutoScroll = true;

            TableLayoutPanel root = new TableLayoutPanel();
            root.Dock = DockStyle.Fill;
            root.ColumnCount = 2;
            root.AutoSize = true;
            root.AutoSizeMode = AutoSizeMode.GrowAndShrink;
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 96));
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

            Label typeLbl = MakeLabel("Type");
            _typeFilter = new ComboBox();
            _typeFilter.DropDownStyle = ComboBoxStyle.DropDownList;
            _typeFilter.Dock = DockStyle.Fill;
            _typeFilter.Margin = new Padding(0, 2, 0, 4);
            _typeFilter.SelectedIndexChanged += TypeFilterChanged;

            _status = new Label();
            _status.AutoSize = true;
            _status.ForeColor = SystemColors.GrayText;
            _status.Margin = new Padding(0, 0, 0, 8);
            _status.Text = "No selection";

            root.RowCount = 0;
            AddRow(root, typeLbl, _typeFilter);
            root.RowCount++;
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.Controls.Add(_status, 0, root.RowCount - 1);
            root.SetColumnSpan(_status, 2);

            AddEditor(root, MedField.Tag, "Tag");
            AddEditor(root, MedField.RelatedTag, "Related Tag");
            AddEditor(root, MedField.Size, "Size");
            AddEditor(root, MedField.Alternate, "Alternate");
            AddEditor(root, MedField.Depth, "Depth");
            AddEditor(root, MedField.Distance, "Distance");
            AddCodeEditor(root);

            _measure = new CheckBox();
            _measure.Text = "On";
            _measure.ThreeState = true;
            _measure.AutoSize = true;
            _measure.Margin = new Padding(0, 4, 0, 2);
            _measure.CheckStateChanged += MeasureChanged;
            Label msrLbl = MakeLabel("Measure");
            _labels[MedField.Measure] = msrLbl;
            _editors[MedField.Measure] = _measure;
            AddRow(root, msrLbl, _measure);

            AddEditor(root, MedField.Flange, "Flange");

            _recordsBtn = new Button();
            _recordsBtn.Text = "Edit records...";
            _recordsBtn.Height = 28;
            _recordsBtn.Dock = DockStyle.Bottom;
            _recordsBtn.Enabled = false;
            _recordsBtn.Click += RecordsClicked;

            Controls.Add(root);
            Controls.Add(_recordsBtn);
            SetEnabled(null);
        }

        void RecordsClicked(object sender, EventArgs e)
        {
            EventHandler h = RecordsRequested;
            if (h != null)
                h(this, EventArgs.Empty);
        }

        void AddCodeEditor(TableLayoutPanel root)
        {
            Label l = MakeLabel("Code");
            _codeCombo = new ComboBox();
            _codeCombo.Dock = DockStyle.Fill;
            _codeCombo.Margin = new Padding(0, 2, 0, 0);
            _codeCombo.DropDownStyle = ComboBoxStyle.DropDown;
            _codeCombo.Tag = MedField.Code;
            _codeCombo.Validated += EditorValidated;
            _codeCombo.KeyDown += EditorKeyDown;
            _labels[MedField.Code] = l;
            _editors[MedField.Code] = _codeCombo;
            AddRow(root, l, _codeCombo);
        }

        static Label MakeLabel(string text)
        {
            Label l = new Label();
            l.Text = text;
            l.AutoSize = true;
            l.Anchor = AnchorStyles.Left;
            l.Margin = new Padding(0, 6, 6, 0);
            return l;
        }

        void AddEditor(TableLayoutPanel root, MedField field, string caption)
        {
            Label l = MakeLabel(caption);
            TextBox tb = new TextBox();
            tb.Dock = DockStyle.Fill;
            tb.Margin = new Padding(0, 2, 0, 2);
            tb.Tag = field;
            tb.Validated += EditorValidated;
            tb.KeyDown += EditorKeyDown;
            _labels[field] = l;
            _editors[field] = tb;
            AddRow(root, l, tb);
        }

        static void AddRow(TableLayoutPanel root, Control left, Control right)
        {
            root.RowCount++;
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            int r = root.RowCount - 1;
            root.Controls.Add(left, 0, r);
            root.Controls.Add(right, 1, r);
        }

        void EditorKeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                e.Handled = true;
                e.SuppressKeyPress = true;
                RequestApply((Control)sender);
            }
        }

        void EditorValidated(object sender, EventArgs e)
        {
            RequestApply((Control)sender);
        }

        void MeasureChanged(object sender, EventArgs e)
        {
            if (_refreshing)
                return;
            RequestApply(_measure);
        }

        void RequestApply(Control editor)
        {
            if (_refreshing)
                return;
            EventHandler h = ApplyRequested;
            if (h != null)
                h(editor, EventArgs.Empty);
        }

        void TypeFilterChanged(object sender, EventArgs e)
        {
            if (_refreshing)
                return;
            BindFields();
            UpdateRecordsButton();
        }

        public TypeFilterItem SelectedFilter
        {
            get { return _typeFilter.SelectedItem as TypeFilterItem; }
        }

        public string GetEditorValue(MedField field)
        {
            if (field == MedField.Measure)
            {
                if (_measure.CheckState == CheckState.Indeterminate)
                    return MedXdata.Varies;
                return _measure.Checked ? "T" : "F";
            }
            ComboBox cb = _editors[field] as ComboBox;
            if (cb != null)
                return cb.Text ?? "";
            TextBox tb = _editors[field] as TextBox;
            return tb == null ? "" : tb.Text;
        }

        public List<MedRecord> CurrentRecords { get { return _current; } }

        public void ShowSelection(List<MedRecord> records, string previousApp)
        {
            _current = records ?? new List<MedRecord>();
            _refreshing = true;
            try
            {
                HashSet<ObjectIdBox> unique = new HashSet<ObjectIdBox>();
                Dictionary<ObjectIdBox, int> perEnt = new Dictionary<ObjectIdBox, int>();
                foreach (MedRecord rec in _current)
                {
                    ObjectIdBox b = new ObjectIdBox(rec.Id);
                    unique.Add(b);
                    int n;
                    perEnt[b] = perEnt.TryGetValue(b, out n) ? n + 1 : 1;
                }
                HashSet<ObjectIdBox> multi = new HashSet<ObjectIdBox>();
                HashSet<ObjectIdBox> singles = new HashSet<ObjectIdBox>();
                foreach (KeyValuePair<ObjectIdBox, int> kv in perEnt)
                {
                    if (kv.Value > 1) multi.Add(kv.Key);
                    else singles.Add(kv.Key);
                }

                Dictionary<string, int> counts = new Dictionary<string, int>();
                foreach (string app in MedApps.All)
                    counts[app] = 0;
                foreach (MedRecord rec in _current)
                {
                    ObjectIdBox b = new ObjectIdBox(rec.Id);
                    if (multi.Contains(b))
                        continue;
                    counts[rec.AppName] = counts[rec.AppName] + 1;
                }

                List<TypeFilterItem> items = new List<TypeFilterItem>();
                items.Add(new TypeFilterItem { AppName = null, Label = "All", Count = singles.Count });
                foreach (string app in MedApps.All)
                {
                    if (counts[app] > 0)
                        items.Add(new TypeFilterItem { AppName = app, Label = MedApps.DisplayName(app), Count = counts[app] });
                }
                if (multi.Count > 0)
                    items.Add(new TypeFilterItem { AppName = "*", Label = "Multiple records", Count = multi.Count, Multi = true });

                _typeFilter.Items.Clear();
                foreach (TypeFilterItem it in items)
                    _typeFilter.Items.Add(it);

                int select = 0;
                if (!string.IsNullOrEmpty(previousApp))
                {
                    for (int i = 0; i < items.Count; i++)
                    {
                        if (items[i].AppName == previousApp)
                        {
                            select = i;
                            break;
                        }
                    }
                }
                else if (singles.Count == 0 && multi.Count > 0)
                {
                    for (int i = 0; i < items.Count; i++)
                    {
                        if (items[i].Multi)
                        {
                            select = i;
                            break;
                        }
                    }
                }
                else if (items.Count == 2)
                    select = 1;
                if (_typeFilter.Items.Count > 0)
                    _typeFilter.SelectedIndex = select;

                BindFields();
                UpdateRecordsButton();
            }
            finally
            {
                _refreshing = false;
            }
        }

        void BindFields()
        {
            bool was = _refreshing;
            _refreshing = true;
            try
            {
                TypeFilterItem filter = SelectedFilter;
                List<MedRecord> subset = FilteredRecords();
                HashSet<MedField> enabled;
                if (subset.Count == 0)
                    enabled = new HashSet<MedField>();
                else if (filter != null && filter.AppName != null)
                    enabled = FieldsFor(filter.AppName);
                else
                {
                    HashSet<string> apps = new HashSet<string>();
                    foreach (MedRecord rec in subset)
                        apps.Add(rec.AppName);
                    enabled = MedFieldMap.Intersection(apps);
                }

                foreach (MedField field in Enum.GetValues(typeof(MedField)))
                {
                    bool on = enabled.Contains(field);
                    _labels[field].Enabled = on;
                    _editors[field].Enabled = on;
                    if (!on)
                    {
                        SetFieldValue(field, "");
                        continue;
                    }
                    List<string> vals = new List<string>();
                    string key = MedFieldMap.Key(field);
                    foreach (MedRecord rec in subset)
                    {
                        string v;
                        if (!rec.Values.TryGetValue(key, out v))
                            v = "";
                        vals.Add(v);
                    }
                    SetFieldValue(field, MedXdata.Common(vals));
                }

                if (filter != null && filter.Multi)
                {
                    foreach (MedField field in System.Enum.GetValues(typeof(MedField)))
                    {
                        _labels[field].Enabled = false;
                        _editors[field].Enabled = false;
                    }
                }
                FillCodeCombo(filter, subset);
            }
            finally
            {
                _refreshing = was;
            }
        }

        int UniqueCount()
        {
            HashSet<ObjectIdBox> unique = new HashSet<ObjectIdBox>();
            foreach (MedRecord rec in _current)
                unique.Add(new ObjectIdBox(rec.Id));
            return unique.Count;
        }

        void FillCodeCombo(TypeFilterItem filter, List<MedRecord> subset)
        {
            if (_codeCombo == null)
                return;
            string keep = _codeCombo.Text;
            _codeCombo.Items.Clear();
            string app = null;
            if (filter != null && filter.AppName != null)
                app = filter.AppName;
            else if (subset.Count > 0)
            {
                app = subset[0].AppName;
                foreach (MedRecord rec in subset)
                {
                    if (rec.AppName != app)
                    {
                        app = null;
                        break;
                    }
                }
            }
            if (app != null)
            {
                foreach (MedTypeRow row in MedTypeLookup.ForApp(app))
                    _codeCombo.Items.Add(row.ToString());
                string code = MedXdata.CodeFromDisplay(keep);
                string shown = MedTypeLookup.Display(app, code);
                if (!string.IsNullOrEmpty(shown) && !_codeCombo.Items.Contains(shown))
                    _codeCombo.Items.Insert(0, shown);
                if (!string.IsNullOrEmpty(shown))
                    _codeCombo.Text = shown;
            }
            else
            {
                _codeCombo.Text = keep;
            }
        }

        HashSet<ObjectIdBox> MultiEntityIds()
        {
            Dictionary<ObjectIdBox, int> perEnt = new Dictionary<ObjectIdBox, int>();
            foreach (MedRecord rec in _current)
            {
                ObjectIdBox b = new ObjectIdBox(rec.Id);
                int n;
                perEnt[b] = perEnt.TryGetValue(b, out n) ? n + 1 : 1;
            }
            HashSet<ObjectIdBox> multi = new HashSet<ObjectIdBox>();
            foreach (KeyValuePair<ObjectIdBox, int> kv in perEnt)
            {
                if (kv.Value > 1)
                    multi.Add(kv.Key);
            }
            return multi;
        }

        public List<MedRecord> FilteredRecords()
        {
            TypeFilterItem filter = SelectedFilter;
            HashSet<ObjectIdBox> multi = MultiEntityIds();
            List<MedRecord> list = new List<MedRecord>();
            foreach (MedRecord rec in _current)
            {
                ObjectIdBox b = new ObjectIdBox(rec.Id);
                bool isMulti = multi.Contains(b);
                if (filter != null && filter.Multi)
                {
                    if (isMulti)
                        list.Add(rec);
                    continue;
                }
                if (isMulti)
                    continue;
                if (filter != null && filter.AppName != null && rec.AppName != filter.AppName)
                    continue;
                list.Add(rec);
            }
            return list;
        }

        public List<Autodesk.AutoCAD.DatabaseServices.ObjectId> TargetEntityIds()
        {
            HashSet<ObjectIdBox> u = new HashSet<ObjectIdBox>();
            foreach (MedRecord rec in FilteredRecords())
                u.Add(new ObjectIdBox(rec.Id));
            List<Autodesk.AutoCAD.DatabaseServices.ObjectId> ids = new List<Autodesk.AutoCAD.DatabaseServices.ObjectId>();
            foreach (ObjectIdBox b in u)
                ids.Add(b.Id);
            return ids;
        }

        void UpdateRecordsButton()
        {
            List<Autodesk.AutoCAD.DatabaseServices.ObjectId> ids = TargetEntityIds();
            List<MedRecord> subset = FilteredRecords();
            TypeFilterItem filter = SelectedFilter;
            if (ids.Count == 0)
            {
                _recordsBtn.Enabled = false;
                _recordsBtn.Text = "Edit records...";
                int multiN = MultiEntityIds().Count;
                int singleN = UniqueCount() - multiN;
                if (_current.Count == 0)
                    _status.Text = "No MED entities selected";
                else
                    _status.Text = singleN + " single, " + multiN + " with multiple records";
                return;
            }
            _recordsBtn.Enabled = true;
            if (filter != null && filter.Multi)
            {
                _recordsBtn.Text = "Edit records (" + ids.Count + " ents)...";
                _status.Text = ids.Count + " entit" + (ids.Count == 1 ? "y" : "ies") + ", " + subset.Count + " records. Palette locked; use Edit records.";
            }
            else if (ids.Count == 1)
            {
                _recordsBtn.Text = "Edit records (" + subset.Count + ")...";
                _status.Text = "1 entity";
            }
            else
            {
                _recordsBtn.Text = "Edit records (" + ids.Count + " ents)...";
                _status.Text = ids.Count + " single-record entities";
            }
            if (ids.Count == 1)
                _singleId = ids[0];
            else
                _singleId = Autodesk.AutoCAD.DatabaseServices.ObjectId.Null;
        }

        static HashSet<MedField> FieldsFor(string app)
        {
            HashSet<MedField> set = new HashSet<MedField>();
            foreach (MedField f in Enum.GetValues(typeof(MedField)))
            {
                if (MedFieldMap.UsedBy(app, f))
                    set.Add(f);
            }
            return set;
        }

        void SetFieldValue(MedField field, string value)
        {
            if (field == MedField.Measure)
            {
                if (value == MedXdata.Varies)
                    _measure.CheckState = CheckState.Indeterminate;
                else if (value == "T")
                    _measure.CheckState = CheckState.Checked;
                else
                    _measure.CheckState = CheckState.Unchecked;
                return;
            }
            ComboBox cb = _editors[field] as ComboBox;
            if (cb != null)
            {
                cb.Text = value ?? "";
                return;
            }
            TextBox tb = _editors[field] as TextBox;
            if (tb != null)
                tb.Text = value ?? "";
        }

        void SetEnabled(HashSet<MedField> enabled)
        {
            foreach (MedField field in Enum.GetValues(typeof(MedField)))
            {
                bool on = enabled != null && enabled.Contains(field);
                _labels[field].Enabled = on;
                _editors[field].Enabled = on;
            }
        }

        struct ObjectIdBox : IEquatable<ObjectIdBox>
        {
            public readonly Autodesk.AutoCAD.DatabaseServices.ObjectId Id;
            public ObjectIdBox(Autodesk.AutoCAD.DatabaseServices.ObjectId id) { Id = id; }
            public bool Equals(ObjectIdBox other) { return Id == other.Id; }
            public override bool Equals(object obj) { return obj is ObjectIdBox && Equals((ObjectIdBox)obj); }
            public override int GetHashCode() { return Id.GetHashCode(); }
        }
    }
}
