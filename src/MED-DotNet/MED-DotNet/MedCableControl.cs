using System;
using System.Drawing;
using System.Windows.Forms;

namespace MEDDotNet
{
    internal class MedCableControl : UserControl
    {
        ComboBox _group;
        ComboBox _cable;
        Label _desc;
        bool _loading;

        public MedCableControl()
        {
            Dock = DockStyle.Fill;
            BackColor = SystemColors.Window;
            Padding = new Padding(6);
            AutoScroll = true;

            TableLayoutPanel root = new TableLayoutPanel();
            root.Dock = DockStyle.Top;
            root.AutoSize = true;
            root.AutoSizeMode = AutoSizeMode.GrowAndShrink;
            root.ColumnCount = 1;
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            root.Padding = new Padding(0);

            GroupBox box = MakeGroup("Cable");
            TableLayoutPanel g = MakeGrid();

            _group = MakeCombo();
            _group.DropDownWidth = 280;
            _group.SelectedIndexChanged += GroupChanged;
            AddRow(g, "Cable Type", _group);

            _cable = MakeCombo();
            _cable.DropDownWidth = 420;
            _cable.DropDownHeight = 400;
            _cable.SelectedIndexChanged += CableChanged;
            AddRow(g, "Cable", _cable);

            _desc = new Label();
            _desc.AutoSize = true;
            _desc.MaximumSize = new Size(260, 0);
            _desc.ForeColor = SystemColors.GrayText;
            _desc.Margin = new Padding(0, 4, 0, 2);
            _desc.Text = "";
            g.RowCount++;
            g.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            g.Controls.Add(_desc, 0, g.RowCount - 1);
            g.SetColumnSpan(_desc, 2);

            Button route = new Button();
            route.Text = "Route Cable";
            route.AutoSize = true;
            route.Anchor = AnchorStyles.Left;
            route.Margin = new Padding(0, 8, 0, 2);
            route.Click += RouteClicked;
            g.RowCount++;
            g.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            g.Controls.Add(route, 0, g.RowCount - 1);
            g.SetColumnSpan(route, 2);

            box.Controls.Add(g);
            AddGroup(root, box);
            Controls.Add(root);
        }

        public int? SelectedCode
        {
            get
            {
                MedTypeRow row = _cable.SelectedItem as MedTypeRow;
                if (row == null)
                    return null;
                return row.Code;
            }
        }

        public string SelectedGroup
        {
            get
            {
                if (_group.SelectedIndex < 0 || _group.SelectedItem == null)
                    return "";
                return _group.SelectedItem.ToString();
            }
        }

        public string SelectedDescription
        {
            get
            {
                MedTypeRow row = _cable.SelectedItem as MedTypeRow;
                if (row == null)
                    return "";
                return row.Description ?? "";
            }
        }

        static GroupBox MakeGroup(string title)
        {
            GroupBox gb = new GroupBox();
            gb.Text = title;
            gb.AutoSize = true;
            gb.AutoSizeMode = AutoSizeMode.GrowAndShrink;
            gb.Dock = DockStyle.Top;
            gb.Padding = new Padding(8, 8, 8, 10);
            gb.Margin = new Padding(0, 0, 0, 8);
            return gb;
        }

        static TableLayoutPanel MakeGrid()
        {
            TableLayoutPanel grid = new TableLayoutPanel();
            grid.Dock = DockStyle.Fill;
            grid.AutoSize = true;
            grid.AutoSizeMode = AutoSizeMode.GrowAndShrink;
            grid.ColumnCount = 2;
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 90));
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            return grid;
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

        static ComboBox MakeCombo()
        {
            ComboBox cbo = new ComboBox();
            cbo.DropDownStyle = ComboBoxStyle.DropDownList;
            cbo.Dock = DockStyle.Fill;
            cbo.Margin = new Padding(0, 2, 0, 2);
            return cbo;
        }

        static void AddRow(TableLayoutPanel grid, string caption, Control editor)
        {
            grid.RowCount++;
            grid.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            int r = grid.RowCount - 1;
            grid.Controls.Add(MakeLabel(caption), 0, r);
            grid.Controls.Add(editor, 1, r);
        }

        static void AddGroup(TableLayoutPanel root, GroupBox gb)
        {
            root.RowCount++;
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            root.Controls.Add(gb, 0, root.RowCount - 1);
        }

        public void LoadFromLisp()
        {
            _loading = true;
            try
            {
                FillGroups();
                int code = MedLisp.GetInt("_CABCODE", 0);
                MedTypeRow row = code > 0 ? MedTypeLookup.CableByCode(code) : null;
                if (row != null && !string.IsNullOrEmpty(row.Group))
                {
                    SelectGroupName(row.Group);
                    FillCables();
                    SelectCableCode(row.Code);
                }
                else
                {
                    _group.SelectedIndex = -1;
                    _cable.Items.Clear();
                    _cable.SelectedIndex = -1;
                }
                UpdateDesc();
            }
            catch (System.Exception)
            {
            }
            finally
            {
                _loading = false;
            }
        }

        void FillGroups()
        {
            string keep = SelectedGroup;
            _group.Items.Clear();
            foreach (string g in MedTypeLookup.CableGroups())
                _group.Items.Add(g);
            if (!string.IsNullOrEmpty(keep))
                SelectGroupName(keep);
        }

        void FillCables()
        {
            int? keep = SelectedCode;
            _cable.Items.Clear();
            string g = SelectedGroup;
            if (string.IsNullOrEmpty(g))
                return;
            foreach (MedTypeRow row in MedTypeLookup.CablesByGroup(g))
                _cable.Items.Add(row);
            if (keep.HasValue)
                SelectCableCode(keep.Value);
        }

        void SelectGroupName(string group)
        {
            for (int i = 0; i < _group.Items.Count; i++)
            {
                if (string.Equals(_group.Items[i].ToString(), group, StringComparison.OrdinalIgnoreCase))
                {
                    _group.SelectedIndex = i;
                    return;
                }
            }
            _group.SelectedIndex = -1;
        }

        void SelectCableCode(int code)
        {
            for (int i = 0; i < _cable.Items.Count; i++)
            {
                MedTypeRow row = _cable.Items[i] as MedTypeRow;
                if (row != null && row.Code == code)
                {
                    _cable.SelectedIndex = i;
                    return;
                }
            }
            _cable.SelectedIndex = -1;
        }

        void UpdateDesc()
        {
            string d = SelectedDescription;
            _desc.Text = string.IsNullOrEmpty(d) ? "" : d;
        }

        void GroupChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            _loading = true;
            try
            {
                FillCables();
                if (_cable.Items.Count > 0 && _cable.SelectedIndex < 0)
                    _cable.SelectedIndex = 0;
                UpdateDesc();
            }
            finally
            {
                _loading = false;
            }
            ApplySelection();
        }

        void CableChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            UpdateDesc();
            ApplySelection();
        }

        void RouteClicked(object sender, EventArgs e)
        {
            MedCablePalette.RouteCurrent();
        }

        void ApplySelection()
        {
            string group = SelectedGroup;
            int? code = SelectedCode;
            MedLisp.Run(delegate
            {
                if (code.HasValue)
                    MedLisp.SetInt("_CABCODE", code.Value);
                MedCableLayers.EnsureAndSetCurrent(group);
            });
        }
    }
}
