using System;
using System.Drawing;
using System.Windows.Forms;

namespace MEDDotNet
{
    internal class MedSettingsControl : UserControl
    {
        ComboBox _scale;
        TextBox _project;
        CheckBox _tagging;
        CheckBox _sizeOvr;
        CheckBox _userRot;
        CheckBox _conBends;
        TextBox _bendMul;
        ComboBox _conSize;
        ComboBox _traySize;
        ComboBox _trayDepth;
        ComboBox _trayRadius;
        TextBox _trayTan;
        TextBox _trayFlange;
        CheckBox _vertTray;
        bool _loading;

        public MedSettingsControl()
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

            GroupBox general = MakeGroup("General");
            TableLayoutPanel g = MakeGrid();
            _scale = MakeCombo();
            _scale.DropDownWidth = 260;
            _scale.DropDownHeight = 400;
            foreach (MedScaleChoice sc in MedScaleChoice.All())
                _scale.Items.Add(sc);
            _scale.SelectedIndexChanged += ScaleChanged;
            AddRow(g, "Scale", _scale);
            _project = MakeText();
            _project.Validated += ProjectValidated;
            _project.KeyDown += TextKeyDown;
            AddRow(g, "Project", _project);
            _tagging = MakeCheck();
            _tagging.CheckStateChanged += TaggingChanged;
            AddRow(g, "Tagging On", _tagging);
            _sizeOvr = MakeCheck();
            _sizeOvr.CheckStateChanged += SizeOvrChanged;
            AddRow(g, "Size Override", _sizeOvr);
            _userRot = MakeCheck();
            _userRot.CheckStateChanged += UserRotChanged;
            AddRow(g, "User Rotate", _userRot);
            general.Controls.Add(g);

            GroupBox conduit = MakeGroup("Conduit");
            TableLayoutPanel c = MakeGrid();
            _conBends = MakeCheck();
            _conBends.CheckStateChanged += ConBendsChanged;
            AddRow(c, "Conduit Bends", _conBends);
            _bendMul = MakeText();
            _bendMul.Validated += BendMulValidated;
            _bendMul.KeyDown += TextKeyDown;
            AddRow(c, "Bend Multiplier", _bendMul);
            _conSize = MakeCombo();
            _conSize.SelectedIndexChanged += ConSizeChanged;
            AddRow(c, "Size", _conSize);
            conduit.Controls.Add(c);

            GroupBox tray = MakeGroup("Tray");
            TableLayoutPanel t = MakeGrid();
            _traySize = MakeCombo();
            _traySize.SelectedIndexChanged += TraySizeChanged;
            AddRow(t, "Size", _traySize);
            _trayDepth = MakeCombo();
            _trayDepth.SelectedIndexChanged += TrayDepthChanged;
            AddRow(t, "Depth", _trayDepth);
            _trayRadius = MakeCombo();
            _trayRadius.SelectedIndexChanged += TrayRadiusChanged;
            AddRow(t, "Radius", _trayRadius);
            _trayTan = MakeText();
            _trayTan.Validated += TrayTanValidated;
            _trayTan.KeyDown += TextKeyDown;
            AddRow(t, "Tangent", _trayTan);
            _trayFlange = MakeText();
            _trayFlange.Validated += TrayFlangeValidated;
            _trayFlange.KeyDown += TextKeyDown;
            AddRow(t, "Flange", _trayFlange);
            _vertTray = MakeCheck();
            _vertTray.CheckStateChanged += VertTrayChanged;
            AddRow(t, "Vertical Tray", _vertTray);
            tray.Controls.Add(t);

            AddGroup(root, general);
            AddGroup(root, conduit);
            AddGroup(root, tray);

            Controls.Add(root);
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
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
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

        static TextBox MakeText()
        {
            TextBox tb = new TextBox();
            tb.Dock = DockStyle.Fill;
            tb.Margin = new Padding(0, 2, 0, 2);
            return tb;
        }

        static CheckBox MakeCheck()
        {
            CheckBox cb = new CheckBox();
            cb.AutoSize = true;
            cb.Text = "";
            cb.Margin = new Padding(0, 4, 0, 2);
            return cb;
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

        void TextKeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode != Keys.Enter)
                return;
            e.Handled = true;
            e.SuppressKeyPress = true;
            TextBox tb = sender as TextBox;
            if (tb != null)
                tb.Parent.SelectNextControl(tb, true, true, true, true);
        }

        public void LoadFromLisp()
        {
            _loading = true;
            try
            {
                SelectScale(MedLisp.GetReal("_SC"), MedLisp.GetReal("_PLOTSCALE"));
                _project.Text = MedLisp.GetString("_MEDPROJECT", "PROJECT1");
                _tagging.Checked = !MedLisp.GetLispTrue("_TAGOFF");
                _sizeOvr.Checked = MedLisp.GetInt("_SIZEOVR", 0) != 0;
                _userRot.Checked = MedLisp.GetInt("_USERROT", 0) != 0;
                _conBends.Checked = MedLisp.GetInt("_CONFILL", 1) != 0;

                double? rad = MedLisp.GetReal("_MEDRADFAC");
                _bendMul.Text = MedLisp.FormatNum(rad.HasValue ? rad.Value : 5.0);

                FillCombo(_conSize, MedLisp.GetRealList("_CONSIZE_LIST") ?? MedLisp.DefaultConduitSizes,
                    MedLisp.GetReal("_CSIZE"));

                FillCombo(_traySize, MedLisp.GetRealList("_TRAYSIZE_LIST") ?? MedLisp.DefaultTraySizes,
                    Coalesce(MedLisp.GetReal("_TRSIZE"), 24.0));
                FillCombo(_trayDepth, MedLisp.GetRealList("_TRAYDPTH_LIST") ?? MedLisp.DefaultTrayDepths,
                    Coalesce(MedLisp.GetReal("_TRDEPTH"), 6.0));
                FillCombo(_trayRadius, MedLisp.GetRealList("_TRAYRADIUS_LIST") ?? MedLisp.DefaultTrayRadii,
                    Coalesce(MedLisp.GetReal("_TRRAD"), 24.0));

                double? tan = MedLisp.GetReal("_TRTANFAC");
                _trayTan.Text = MedLisp.FormatNum(tan.HasValue ? tan.Value : 3.0);

                double? fl = MedLisp.GetReal("_TRAYFLANGE");
                _trayFlange.Text = MedLisp.FormatNum(fl.HasValue ? fl.Value : 1.5);

                _vertTray.Checked = MedLisp.GetLispTrue("_VERTICALTRAY");
            }
            catch (System.Exception)
            {
            }
            finally
            {
                _loading = false;
            }
        }

        static double Coalesce(double? v, double fallback)
        {
            return v.HasValue ? v.Value : fallback;
        }

        static void FillCombo(ComboBox cbo, double[] values, double? current)
        {
            cbo.Items.Clear();
            int sel = -1;
            for (int i = 0; i < values.Length; i++)
            {
                cbo.Items.Add(MedLisp.FormatNum(values[i]));
                if (current.HasValue && MedLisp.Near(values[i], current.Value))
                    sel = i;
            }
            if (current.HasValue && sel < 0)
            {
                cbo.Items.Add(MedLisp.FormatNum(current.Value));
                sel = cbo.Items.Count - 1;
            }
            cbo.SelectedIndex = sel;
        }

        static double? ComboValue(ComboBox cbo)
        {
            if (cbo.SelectedIndex < 0 || cbo.SelectedItem == null)
                return null;
            double d;
            if (!MedLisp.TryParseNum(cbo.SelectedItem.ToString(), out d))
                return null;
            return d;
        }

        void SelectScale(double? sc, double? plot)
        {
            double p = plot.HasValue ? plot.Value : 1.0;
            double s = sc.HasValue ? sc.Value : 1.0;
            _scale.Items.Clear();
            foreach (MedScaleChoice item in MedScaleChoice.All())
                _scale.Items.Add(item);
            int match = -1;
            for (int i = 0; i < _scale.Items.Count; i++)
            {
                MedScaleChoice c = _scale.Items[i] as MedScaleChoice;
                if (c == null)
                    continue;
                if (MedLisp.Near(c.Sc, s) && MedLisp.Near(c.PlotScale, p))
                {
                    match = i;
                    break;
                }
            }
            if (match < 0)
            {
                MedScaleChoice custom = new MedScaleChoice();
                custom.Label = "Custom  (" + MedLisp.FormatNum(s) + ")";
                custom.Sc = s;
                custom.PlotScale = p;
                _scale.Items.Insert(0, custom);
                match = 0;
            }
            _scale.SelectedIndex = match;
        }

        void ScaleChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            MedScaleChoice c = _scale.SelectedItem as MedScaleChoice;
            if (c == null)
                return;
            MedScaleChoice choice = c;
            MedLisp.Run(delegate { MedLisp.ApplyDrawingScale(choice.Sc, choice.PlotScale); });
        }

        void ProjectValidated(object sender, EventArgs e)
        {
            if (_loading)
                return;
            string v = (_project.Text ?? "").Trim();
            if (v.Length == 0)
                return;
            MedLisp.Run(delegate { MedLisp.SetString("_MEDPROJECT", v); });
        }

        void TaggingChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            bool taggingOn = _tagging.Checked;
            MedLisp.Run(delegate { MedLisp.SetBool("_TAGOFF", !taggingOn); });
        }

        void SizeOvrChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            int v = _sizeOvr.Checked ? 1 : 0;
            MedLisp.Run(delegate
            {
                MedLisp.SetInt("_SIZEOVR", v);
                MedLisp.SetInt("_SIZEOVER", v);
            });
        }

        void UserRotChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            int v = _userRot.Checked ? 1 : 0;
            MedLisp.Run(delegate { MedLisp.SetInt("_USERROT", v); });
        }

        void ConBendsChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            int v = _conBends.Checked ? 1 : 0;
            MedLisp.Run(delegate { MedLisp.SetInt("_CONFILL", v); });
        }

        void BendMulValidated(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double d;
            if (!MedLisp.TryParseNum(_bendMul.Text, out d))
            {
                double? cur = null;
                MedLisp.Run(delegate { cur = MedLisp.GetReal("_MEDRADFAC"); });
                _loading = true;
                _bendMul.Text = MedLisp.FormatNum(cur.HasValue ? cur.Value : 5.0);
                _loading = false;
                return;
            }
            _loading = true;
            _bendMul.Text = MedLisp.FormatNum(d);
            _loading = false;
            MedLisp.Run(delegate { MedLisp.SetReal("_MEDRADFAC", d); });
        }

        void ConSizeChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double? v = ComboValue(_conSize);
            if (!v.HasValue)
                return;
            double size = v.Value;
            MedLisp.Run(delegate { MedLisp.ApplyConduitSize(size); });
        }

        void TraySizeChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double? v = ComboValue(_traySize);
            if (!v.HasValue)
                return;
            double size = v.Value;
            MedLisp.Run(delegate { MedLisp.SetReal("_TRSIZE", size); });
        }

        void TrayDepthChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double? v = ComboValue(_trayDepth);
            if (!v.HasValue)
                return;
            double depth = v.Value;
            MedLisp.Run(delegate { MedLisp.SetReal("_TRDEPTH", depth); });
        }

        void TrayRadiusChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double? v = ComboValue(_trayRadius);
            if (!v.HasValue)
                return;
            double rad = v.Value;
            MedLisp.Run(delegate { MedLisp.ApplyTrayRadius(rad); });
        }

        void TrayTanValidated(object sender, EventArgs e)
        {
            if (_loading)
                return;
            string raw = (_trayTan.Text ?? "").Trim();
            if (raw.Length == 0)
            {
                _loading = true;
                _trayTan.Text = MedLisp.FormatNum(3.0);
                _loading = false;
                MedLisp.Run(delegate { MedLisp.SetReal("_TRTANFAC", 3.0); MedLisp.SetReal("_TRAYTANFAC", 3.0); });
                return;
            }
            double d;
            if (!MedLisp.TryParseNum(raw, out d))
            {
                double? cur = null;
                MedLisp.Run(delegate { cur = MedLisp.GetReal("_TRTANFAC"); });
                _loading = true;
                _trayTan.Text = MedLisp.FormatNum(cur.HasValue ? cur.Value : 3.0);
                _loading = false;
                return;
            }
            _loading = true;
            _trayTan.Text = MedLisp.FormatNum(d);
            _loading = false;
            MedLisp.Run(delegate { MedLisp.SetReal("_TRTANFAC", d); MedLisp.SetReal("_TRAYTANFAC", d); });
        }

        void TrayFlangeValidated(object sender, EventArgs e)
        {
            if (_loading)
                return;
            double d;
            if (!MedLisp.TryParseNum(_trayFlange.Text, out d))
            {
                double? cur = null;
                MedLisp.Run(delegate { cur = MedLisp.GetReal("_TRAYFLANGE"); });
                _loading = true;
                _trayFlange.Text = MedLisp.FormatNum(cur.HasValue ? cur.Value : 1.5);
                _loading = false;
                return;
            }
            _loading = true;
            _trayFlange.Text = MedLisp.FormatNum(d);
            _loading = false;
            MedLisp.Run(delegate { MedLisp.SetReal("_TRAYFLANGE", d); });
        }

        void VertTrayChanged(object sender, EventArgs e)
        {
            if (_loading)
                return;
            bool on = _vertTray.Checked;
            MedLisp.Run(delegate { MedLisp.SetBool("_VERTICALTRAY", on); });
        }
    }
}
