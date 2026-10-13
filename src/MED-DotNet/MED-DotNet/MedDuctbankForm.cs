using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace MEDDotNet
{
    /// <summary>
    /// DUCTBANK grid dialog (Draft 2 mockup). Pure WinForms: no AutoCAD types, so it can be
    /// rendered outside AutoCAD (RenderToPng) for docs/tests. Input and output are KEY=VALUE
    /// lines (MEDDuctbank.lsp dbk-spec-out / dbk-spec-in). LISP does the authoritative solve;
    /// the cheat image is a live preview from the same rules, and the checks / envelope boxes
    /// show the last LISP solve (Check re-solves).
    /// </summary>
    public class MedDuctbankForm : Form
    {
        class Pos { public string Id; public int Row, Col; public string Tag; public double Size; public int Code; public bool Custom; }
        class Part { public string Name; public double Size, Od, Sep, PV, PH, Seat, CatCL, Len; public int Code; }

        static readonly CultureInfo IC = CultureInfo.InvariantCulture;
        readonly Dictionary<string, string> _kv = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        readonly Dictionary<string, List<string>> _multi = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        readonly List<Pos> _pos = new List<Pos>();
        readonly List<Part> _cat = new List<Part>();
        readonly Dictionary<string, double> _od = new Dictionary<string, double>();
        readonly List<KeyValuePair<int, string>> _codes = new List<KeyValuePair<int, string>>();
        readonly Dictionary<int, string> _abbr = new Dictionary<int, string>();
        readonly List<double> _sizes = new List<double>(), _refSizes = new List<double>();
        string _refPos = "B1", _sel = null;
        bool _dirty, _loading;
        double _refSize = 1.0, _minSize = 1.0; int _conCode = 3, _refCode = 3;
        bool _plain, _edit;

        public string ResultSpec { get; private set; }

        // controls
        TextBox _bank, _counts, _interval, _first, _covT, _covB, _covL, _covR, _covE, _gap, _topA, _topB, _sx, _sy, _transl, _straight, _scale, _tag, _tagPat, _flexMax, _flexLen;
        NumericUpDown _rows;
        ComboBox _family, _sep, _part, _endA, _endB, _sectEnd, _mat, _size, _type, _refSizeCb, _refTypeCb, _enc, _bends, _angA, _angB;
        readonly ToolTip _tips = new ToolTip { AutoPopDelay = 15000, InitialDelay = 400 };
        CheckBox _wrap, _model3d, _sectPick;
        Label _refInfo, _pitch, _selLabel, _status, _layerInfo, _encHint;
        TextBox _envelope;
        Button _okBtn;
        Panel _grid, _cheat;
        RadioButton _viewTrunk, _viewStub;
        ListBox _checks;

        public MedDuctbankForm(string spec)
        {
            Parse(spec ?? "");
            _edit = Get("MODE", "NEW").ToUpperInvariant() == "EDIT";
            Text = "MED Ductbank - " + Get("BANK", "DB1") + (_edit ? "  (DBEDIT: rebuild in place)" : "");
            Font = new Font("Segoe UI", 9f);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false; MinimizeBox = false; ShowInTaskbar = false;
            StartPosition = FormStartPosition.CenterParent;
            ClientSize = new Size(1240, 890);
            FormClosed += (s, e) => _tips.Dispose();
            BackColor = SystemColors.Control;
            _loading = true;
            BuildLeft();
            BuildMiddle();
            BuildRight();
            BuildBottom();
            LoadValues();
            _loading = false;
            if (_sel == null) _sel = _refPos;
            ShowSelected();
            RefreshAll();
        }

        // ------------------------------------------------------------------ spec in
        void Parse(string spec)
        {
            foreach (string raw in spec.Replace("\r", "").Split('\n'))
            {
                int i = raw.IndexOf('=');
                if (i <= 0) continue;
                string k = raw.Substring(0, i).Trim(), v = raw.Substring(i + 1);
                switch (k.ToUpperInvariant())
                {
                    case "POS": case "CODE": case "CAT": case "OD": case "PZ": case "PIECE": case "SUM": case "PROF": case "ERR": case "FLAG":
                        List<string> l;
                        if (!_multi.TryGetValue(k, out l)) { l = new List<string>(); _multi[k] = l; }
                        l.Add(v); break;
                    default: _kv[k] = v; break;
                }
            }
            foreach (string c in Multi("CODE"))
            {
                string[] f = c.Split('|');
                int code; if (f.Length < 3 || !int.TryParse(f[0], out code)) continue;
                _codes.Add(new KeyValuePair<int, string>(code, f[2])); _abbr[code] = f[1];
            }
            if (_codes.Count == 0)
                foreach (var c in new[] { new KeyValuePair<int, string>(3, "Rigid Non-Metalic Conduit"), new KeyValuePair<int, string>(2, "Plastic Coated Rigid Steel Conduit"), new KeyValuePair<int, string>(1, "Rigid Steel Conduit") })
                { _codes.Add(c); _abbr[c.Key] = c.Key == 3 ? "PVC" : c.Key == 2 ? "PVC-RGS" : "RGS"; }
            foreach (string c in Multi("CAT"))
            {
                string[] f = c.Split('|');
                if (f.Length < 10) continue;
                _cat.Add(new Part { Name = f[0], Size = D(f[1]), Od = D(f[2]), Sep = D(f[3]), PV = D(f[4]), PH = D(f[5]), Seat = D(f[6]), CatCL = D(f[7]), Len = D(f[8]), Code = (int)D(f[9]) });
            }
            foreach (string c in Multi("OD"))
            {
                string[] f = c.Split('|');
                if (f.Length >= 3) _od[OdKey((int)D(f[0]), D(f[1]))] = D(f[2]);
            }
            foreach (string s in Get("SIZES", "1,1.25,1.5,2,2.5,3,3.5,4,5,6").Split(','))
                if (s.Trim() != "") _sizes.Add(D(s));
            string[] rf = Get("REF", "").Split('|');
            if (rf.Length > 1) _refSize = D(rf[1]);
            if (rf.Length > 2) _refCode = (int)D(rf[2]);
            _plain = Get("REFPLAIN", "0") == "1";
            if (_plain) { _refSize = D(Get("REFSIZE", N(_refSize))); _refCode = (int)D(Get("REFCODE", _refCode.ToString())); }
            _minSize = D(Get("MINSIZE", "1"));
            _conCode = (int)D(Get("CONCODE", "3"));
            _refPos = Get("REFPOS", "B1").ToUpperInvariant();
            foreach (string c in Multi("POS"))
            {
                string[] f = c.Split('|');
                if (f.Length < 4) continue;
                var p = new Pos { Id = f[0].ToUpperInvariant(), Tag = f[1], Size = D(f[2]), Code = (int)D(f[3]), Custom = f.Length > 4 && f[4] == "C" };
                p.Row = p.Id[0] - 'A' + 1; int col; int.TryParse(p.Id.Substring(1), out col); p.Col = col;
                _pos.Add(p);
            }
        }
        List<string> Multi(string k) { List<string> l; return _multi.TryGetValue(k, out l) ? l : new List<string>(); }
        string Get(string k, string d) { string v; return _kv.TryGetValue(k, out v) && v != "" ? v : d; }
        static double D(string s) { double v; return double.TryParse((s ?? "").Trim(), NumberStyles.Float, IC, out v) ? v : 0.0; }
        static string N(double v) { return v.ToString("0.####", IC); }
        static string OdKey(int code, double size) { return code + "|" + size.ToString("0.####", IC); }
        double Od(int code, double size)
        {
            double v;
            if (_od.TryGetValue(OdKey(code, size), out v) && v > 0) return v;
            if (_od.TryGetValue(OdKey(3, size), out v) && v > 0) return v;
            return size + 0.4;
        }
        string Abbr(int code) { string a; return _abbr.TryGetValue(code, out a) ? a : "C" + code; }
        static string SizeText(double s)
        {
            int whole = (int)Math.Floor(s + 1e-9); double fr = s - whole;
            string[] names = { "", "1/4", "1/2", "3/4" };
            int q = (int)Math.Round(fr * 4);
            if (Math.Abs(fr * 4 - q) > 0.01) return N(s) + "\"";
            if (q == 4) { whole++; q = 0; }
            if (whole == 0) return names[q] + "\"";
            return whole + (q > 0 ? "-" + names[q] : "") + "\"";
        }
        string DefaultTag(Pos p) { return (_tagPat != null ? _tagPat.Text : Get("TAGPAT", "{BANK}-{POS}")).Replace("{BANK}", _bank != null ? _bank.Text.Trim().ToUpperInvariant() : Get("BANK", "DB1")).Replace("{POS}", p.Id); }
        string TagOf(Pos p) { return p.Custom ? p.Tag : DefaultTag(p); }

        // ------------------------------------------------------------------ layout helpers
        GroupBox Group(Control parent, string text, int x, int y, int w, int h)
        {
            var g = new GroupBox { Text = text, Left = x, Top = y, Width = w, Height = h };
            parent.Controls.Add(g); return g;
        }
        Label Lbl(Control p, string t, int x, int y, int w = 0)
        {
            var l = new Label { Text = t, Left = x, Top = y + 3, AutoSize = w == 0 };
            if (w > 0) { l.Width = w; l.Height = 18; }
            p.Controls.Add(l); return l;
        }
        TextBox Txt(Control p, int x, int y, int w, string v)
        {
            var t = new TextBox { Left = x, Top = y, Width = w, Text = v };
            t.TextChanged += (s, e) => Changed();
            p.Controls.Add(t); return t;
        }
        ComboBox Cmb(Control p, int x, int y, int w, IEnumerable<string> items)
        {
            var c = new ComboBox { Left = x, Top = y, Width = w, DropDownStyle = ComboBoxStyle.DropDownList };
            foreach (string s in items) c.Items.Add(s);
            c.SelectedIndexChanged += (s, e) => Changed();
            p.Controls.Add(c); return c;
        }
        static void Pick(ComboBox c, string v) { for (int i = 0; i < c.Items.Count; i++) if (string.Equals(c.Items[i].ToString(), v, StringComparison.OrdinalIgnoreCase)) { c.SelectedIndex = i; return; } if (c.Items.Count > 0 && c.SelectedIndex < 0) c.SelectedIndex = 0; }

        // ------------------------------------------------------------------ left column
        void BuildLeft()
        {
            int x = 8, w = 300, y = 6;
            var g = Group(this, "Bank", x, y, w, 160);
            Lbl(g, "Bank ID", 10, 20); _bank = Txt(g, 130, 20, 80, "");
            Lbl(g, "Rows (deep)", 10, 46); _rows = new NumericUpDown { Left = 130, Top = 46, Width = 50, Minimum = 1, Maximum = 9 };
            _rows.ValueChanged += (s, e) => { if (!_loading) RowsChanged(); }; g.Controls.Add(_rows);
            Lbl(g, "Conduits per row", 10, 72); _counts = Txt(g, 130, 72, 80, "");
            _counts.Leave += (s, e) => { if (!_loading) CountsChanged(); };
            Lbl(g, "(top row first)", 214, 72).ForeColor = SystemColors.GrayText;
            Lbl(g, "Ref size / type", 10, 98);
            _refSizeCb = new ComboBox { Left = 130, Top = 98, Width = 62, DropDownStyle = ComboBoxStyle.DropDownList }; g.Controls.Add(_refSizeCb);
            _refSizes.AddRange(_sizes);
            if (!_refSizes.Any(s => Math.Abs(s - _refSize) < 1e-6)) { _refSizes.Add(_refSize); _refSizes.Sort(); }
            foreach (double s in _refSizes) _refSizeCb.Items.Add(SizeText(s));
            _refTypeCb = new ComboBox { Left = 198, Top = 98, Width = 92, DropDownStyle = ComboBoxStyle.DropDownList, DropDownWidth = 260 }; g.Controls.Add(_refTypeCb);
            foreach (var c in _codes) _refTypeCb.Items.Add(c.Key + " " + Abbr(c.Key) + " - " + c.Value);
            _refSizeCb.SelectedIndexChanged += (s, e) => RefSizeChanged();
            _refTypeCb.SelectedIndexChanged += (s, e) => RefSizeChanged();
            _refInfo = Lbl(g, "", 10, 124, 285); _refInfo.Height = 32; _refInfo.ForeColor = Color.FromArgb(0, 70, 140);
            y += 164;
            g = Group(this, "Main trunk spacers", x, y, w, 158);
            Lbl(g, "Family", 10, 20); _family = Cmb(g, 130, 20, 160, new[] { Get("FAMILY", "Carlon Snap-N-Stac") }); _family.SelectedIndex = 0;
            Lbl(g, "Separation", 10, 46); _sep = Cmb(g, 130, 46, 60, new[] { "1.5", "2", "3" });
            _sep.SelectedIndexChanged += (s, e) => { if (!_loading) FillParts(); };
            Lbl(g, "Part", 10, 72); _part = Cmb(g, 130, 72, 120, new string[0]);
            Lbl(g, "Interval / first (in)", 10, 98); _interval = Txt(g, 130, 98, 50, ""); _first = Txt(g, 186, 98, 50, "");
            _pitch = Lbl(g, "", 10, 126, 285); _pitch.ForeColor = SystemColors.GrayText;
            y += 162;
            g = Group(this, "Cover from conduit OD (in)", x, y, w, 104);
            Lbl(g, "Top", 10, 22); _covT = Txt(g, 52, 20, 44, "");
            Lbl(g, "Bottom", 104, 22); _covB = Txt(g, 158, 20, 44, "");
            Lbl(g, "End", 210, 22); _covE = Txt(g, 244, 20, 44, "");
            Lbl(g, "Left", 10, 48); _covL = Txt(g, 52, 46, 44, "");
            Lbl(g, "Right", 104, 48); _covR = Txt(g, 158, 46, 44, "");
            var gl = Lbl(g, "Min gap", 10, 74); _gap = Txt(g, 58, 72, 38, "");
            _tips.SetToolTip(gl, "Minimum clear gap OD to OD (checks only)"); _tips.SetToolTip(_gap, "Minimum clear gap OD to OD (checks only)");
            var bl = Lbl(g, "Bends", 104, 74); _bends = Cmb(g, 158, 72, 90, new[] { "Chamfer", "Sweep" });
            const string bt = "Concrete at bends (plan bends and the stub-up turn-up):\nChamfer = straight chamfer on the outside, sized so the cover over the outermost elbow is never less than the side/top cover (inside on the chord of the cover arc).\nSweep = concrete follows the elbow arcs.";
            _tips.SetToolTip(bl, bt); _tips.SetToolTip(_bends, bt);
            y += 108;
            g = Group(this, "Stub-up zone", x, y, w, 298);
            Lbl(g, "End A", 10, 20); _endA = Cmb(g, 52, 20, 76, new[] { "Stubup", "Open" });
            _angA = Cmb(g, 132, 20, 70, new[] { "90", "45" });
            Lbl(g, "top EL", 206, 20); _topA = Txt(g, 248, 20, 44, "");
            Lbl(g, "End B", 10, 46); _endB = Cmb(g, 52, 46, 76, new[] { "Stubup", "Open" });
            _angB = Cmb(g, 132, 46, 70, new[] { "90", "45" });
            Lbl(g, "top EL", 206, 46); _topB = Txt(g, 248, 46, 44, "");
            const string at = "Stub-up angle at this end:\n90 = vertical stub-up elbows and risers (default).\n45 = 45 deg stub elbows and 45 deg risers; each riser ends open at the stub-up point (top EL), no fitting.\nThe concrete turn-up follows the 45.";
            foreach (Control c in new Control[] { _angA, _angB }) _tips.SetToolTip(c, at);
            _endA.SelectedIndexChanged += (s, e) => _angA.Enabled = (_endA.SelectedItem as string) == "Stubup";
            _endB.SelectedIndexChanged += (s, e) => _angB.Enabled = (_endB.SelectedItem as string) == "Stubup";
            Lbl(g, "Stub pitch center to center (in)", 10, 72);
            var la = Lbl(g, "across", 24, 98); _sx = Txt(g, 72, 98, 50, "");
            var lb = Lbl(g, "along", 150, 98); _sy = Txt(g, 196, 98, 50, "");
            foreach (Control c in new Control[] { la, _sx }) _tips.SetToolTip(c, "Stub-up pitch center to center across = column to column");
            foreach (Control c in new Control[] { lb, _sy }) _tips.SetToolTip(c, "Stub-up pitch center to center along = row to row");
            Lbl(g, "Transition / stub straight", 10, 124); _transl = Txt(g, 170, 124, 50, ""); _straight = Txt(g, 226, 124, 50, "");
            Lbl(g, "Section at stub-up end", 10, 150); _sectEnd = Cmb(g, 170, 150, 50, new[] { "A", "B" });
            Lbl(g, "Risers + stub elbows", 10, 178); _mat = Cmb(g, 140, 178, 150, new[] { "PVC-coated RGS", "Plain RGS" });
            _mat.SelectedIndexChanged += (s, e) => { if (_wrap != null) _wrap.Enabled = _mat.SelectedIndex == 1; };
            _wrap = new CheckBox { Text = "Tape wrap plain RGS (note + BOM 174)", Left = 10, Top = 206, Width = 280 };
            _wrap.CheckedChanged += (s, e) => Changed(); g.Controls.Add(_wrap);
            Lbl(g, "Encasement top EL", 10, 232);
            _enc = new ComboBox { Left = 140, Top = 232, Width = 90, DropDownStyle = ComboBoxStyle.DropDown };
            _enc.Items.Add("Auto"); _enc.Items.Add("Top");
            _enc.TextChanged += (s, e) => Changed(); g.Controls.Add(_enc);
            Lbl(g, "(turn-up)", 236, 232).ForeColor = SystemColors.GrayText;
            _encHint = Lbl(g, "", 10, 258, 285); _encHint.Height = 32; _encHint.ForeColor = SystemColors.GrayText;
            y += 302;
            g = Group(this, "Output", x, y, w, 96);
            _model3d = new CheckBox { Text = "3D envelope + spacer solids", Left = 10, Top = 18, Width = 280 };
            _model3d.CheckedChanged += (s, e) => Changed(); g.Controls.Add(_model3d);
            _layerInfo = Lbl(g, "", 28, 38, 265); _layerInfo.ForeColor = SystemColors.GrayText;
            Lbl(g, "Section scale", 10, 66); _scale = Txt(g, 100, 64, 44, "");
            _sectPick = new CheckBox { Text = "Pick section location", Left = 152, Top = 64, Width = 145 };
            g.Controls.Add(_sectPick);
        }

        // ------------------------------------------------------------------ middle column
        void BuildMiddle()
        {
            int x = 316, w = 470;
            var g = Group(this, "Conduit positions (section looking from the stub-up end; columns left to right)", x, 6, w, 330);
            _grid = new DoubleBufferedPanel { Left = 10, Top = 22, Width = w - 20, Height = 298, BackColor = Color.White, BorderStyle = BorderStyle.FixedSingle };
            _grid.Paint += PaintGrid;
            _grid.MouseClick += GridClick;
            g.Controls.Add(_grid);
            g = Group(this, "Selected position", x, 340, w, 200);
            _selLabel = Lbl(g, "", 10, 20, 450); _selLabel.Font = new Font(Font, FontStyle.Bold);
            Lbl(g, "Tag", 10, 46); _tag = new TextBox { Left = 60, Top = 46, Width = 150 }; g.Controls.Add(_tag);
            _tag.TextChanged += (s, e) => { if (_loading) return; var p = SelPos(); if (p == null) return; p.Custom = _tag.Text != DefaultTag(p); p.Tag = _tag.Text; Changed(); _grid.Invalidate(); };
            Lbl(g, "Size", 220, 46); _size = new ComboBox { Left = 256, Top = 46, Width = 70, DropDownStyle = ComboBoxStyle.DropDownList }; g.Controls.Add(_size);
            foreach (double s in _sizes) _size.Items.Add(SizeText(s));
            _size.SelectedIndexChanged += (s, e) => { if (_loading) return; var p = SelPos(); if (p == null || _size.SelectedIndex < 0) return; p.Size = _sizes[_size.SelectedIndex]; Changed(); };
            Lbl(g, "Type", 334, 46); _type = new ComboBox { Left = 370, Top = 46, Width = 88, DropDownStyle = ComboBoxStyle.DropDownList, DropDownWidth = 260 }; g.Controls.Add(_type);
            foreach (var c in _codes) _type.Items.Add(c.Key + " " + Abbr(c.Key) + " - " + c.Value);
            _type.SelectedIndexChanged += (s, e) => { if (_loading) return; var p = SelPos(); if (p == null || _type.SelectedIndex < 0) return; p.Code = _codes[_type.SelectedIndex].Key; Changed(); };
            int bx = 10, by = 80;
            Btn(g, "Set as REF", bx, by, 100, (s, e) => { if (_sel != null) { _refPos = _sel; Changed(); } });
            Btn(g, "Size to all", bx + 106, by, 100, (s, e) => { var p = SelPos(); if (p == null) return; foreach (var q in _pos) q.Size = p.Size; Changed(); });
            Btn(g, "Type to all", bx + 212, by, 100, (s, e) => { var p = SelPos(); if (p == null) return; foreach (var q in _pos) q.Code = p.Code; Changed(); });
            Btn(g, "Auto tags", bx + 318, by, 100, (s, e) => { foreach (var q in _pos) q.Custom = false; ShowSelected(); Changed(); });
            Lbl(g, "Tag pattern", 10, 118); _tagPat = Txt(g, 90, 116, 150, "");
            _tagPat.TextChanged += (s, e) => { if (!_loading) { ShowSelected(); _grid.Invalidate(); } };
            var hint = Lbl(g, "{BANK} {POS}. Click a card to edit it.", 248, 118, 215); hint.ForeColor = SystemColors.GrayText;
            var rem = new Label { Left = 10, Top = 152, Width = 450, Height = 38, BackColor = Color.FromArgb(255, 248, 205), BorderStyle = BorderStyle.FixedSingle,
                Text = "REMINDER: MED does not calculate cable fill, ampacity derating (mutual heating), voltage drop, pulling tension or burial depth." };
            g.Controls.Add(rem);
            g = Group(this, "Envelope (last check)", x, 544, w, 292);
            var fl = Lbl(g, "Route rises: flex up to (deg)", 10, 20); _flexMax = Txt(g, 190, 18, 44, "");
            var fo = Lbl(g, "over at least (in)", 244, 20); _flexLen = Txt(g, 352, 18, 50, "");
            const string ft = "Elevation changes along the route (from the reference route Z):\na grade change up to this many degrees, spread over at least this run length, is taken in the flex of the PVC\n(continuous sloped run, no fitting). Steeper or shorter changes get stock vertical bends (11.25 / 22.5 / 30 / 45 / 90).\nDefault 5 deg over 120 in (radius about 1375 in, well above the 160 x OD minimum for PVC electrical conduit).";
            foreach (Control c in new Control[] { fl, _flexMax, fo, _flexLen }) _tips.SetToolTip(c, ft);
            _envelope = new TextBox { Left = 10, Top = 46, Width = w - 20, Height = 238, Font = new Font("Consolas", 8.25f), Multiline = true, ReadOnly = true,
                                      ScrollBars = ScrollBars.Vertical, BorderStyle = BorderStyle.None, BackColor = SystemColors.Control, TabStop = false, WordWrap = true };
            g.Controls.Add(_envelope);
        }
        Button Btn(Control p, string t, int x, int y, int w, EventHandler h)
        {
            var b = new Button { Text = t, Left = x, Top = y, Width = w, Height = 26 };
            b.Click += h; p.Controls.Add(b); return b;
        }

        // ------------------------------------------------------------------ right column
        void BuildRight()
        {
            int x = 794, w = 438;
            var g = Group(this, "Cheat image (current position highlighted)", x, 6, w, 420);
            _viewTrunk = new RadioButton { Text = "Trunk section", Left = 10, Top = 20, Width = 110, Checked = true };
            _viewStub = new RadioButton { Text = "Stub-up section", Left = 124, Top = 20, Width = 130 };
            _viewTrunk.CheckedChanged += (s, e) => _cheat.Invalidate();
            g.Controls.Add(_viewTrunk); g.Controls.Add(_viewStub);
            _cheat = new DoubleBufferedPanel { Left = 10, Top = 44, Width = w - 20, Height = 366, BackColor = Color.White, BorderStyle = BorderStyle.FixedSingle };
            _cheat.Paint += PaintCheat;
            g.Controls.Add(_cheat);
            g = Group(this, "Checks", x, 430, w, 406);
            _checks = new ListBox { Left = 10, Top = 20, Width = w - 20, Height = 378, DrawMode = DrawMode.OwnerDrawVariable, IntegralHeight = false, HorizontalScrollbar = false };
            _checks.MeasureItem += (s, e) => { var t = _checks.Items[e.Index].ToString(); var sz = e.Graphics.MeasureString(t, _checks.Font, _checks.Width - 24); e.ItemHeight = (int)Math.Ceiling(sz.Height) + 4; };
            _checks.DrawItem += DrawCheck;
            g.Controls.Add(_checks);
        }

        // ------------------------------------------------------------------ bottom
        void BuildBottom()
        {
            _status = new Label { Left = 10, Top = 850, Width = 820, Height = 30, ForeColor = Color.FromArgb(0, 90, 0) };
            Controls.Add(_status);
            var help = Btn(this, "Help", 836, 848, 90, (s, e) => ShowHelp());
            var check = Btn(this, "Check", 932, 848, 90, (s, e) => Finish("CHECK"));
            var ok = Btn(this, "OK", 1028, 848, 96, (s, e) => Finish("OK"));
            var cancel = Btn(this, "Cancel", 1130, 848, 100, (s, e) => Finish("CANCEL"));
            AcceptButton = ok; CancelButton = cancel;
            ok.Font = new Font(Font, FontStyle.Bold);
            if (_edit) ok.Text = "Rebuild";
            _okBtn = ok;
        }

        void LoadValues()
        {
            _bank.Text = Get("BANK", "DB1");
            int rows = Math.Max(1, Math.Min(9, (int)D(Get("ROWS", "2"))));
            _rows.Value = rows;
            _counts.Text = Get("COUNTS", "4,4");
            Pick(_sep, N(D(Get("SEP", "2"))));
            FillParts();
            Pick(_part, Get("PART", "Auto"));
            _interval.Text = N(D(Get("SPINT", "96"))); _first.Text = N(D(Get("SPEND", "12")));
            _covT.Text = N(D(Get("COVT", "3"))); _covB.Text = N(D(Get("COVB", "3"))); _covL.Text = N(D(Get("COVL", "2")));
            _covR.Text = N(D(Get("COVR", "2"))); _covE.Text = N(D(Get("COVE", "2"))); _gap.Text = N(D(Get("MINGAP", "2")));
            Pick(_endA, Get("ENDA", "Stubup")); Pick(_endB, Get("ENDB", "Open"));
            Pick(_angA, Math.Abs(D(Get("ANGA", "90")) - 45) < 0.01 ? "45" : "90"); Pick(_angB, Math.Abs(D(Get("ANGB", "90")) - 45) < 0.01 ? "45" : "90");
            _angA.Enabled = (_endA.SelectedItem as string) == "Stubup"; _angB.Enabled = (_endB.SelectedItem as string) == "Stubup";
            _flexMax.Text = N(D(Get("FLEXMAX", "5"))); _flexLen.Text = N(D(Get("FLEXLEN", "120")));
            _topA.Text = N(D(Get("TOPA", "0"))); _topB.Text = N(D(Get("TOPB", "0")));
            _sx.Text = N(D(Get("SX", "6"))); _sy.Text = N(D(Get("SY", "6")));
            _transl.Text = N(D(Get("TRANSL", "60"))); _straight.Text = N(D(Get("STUBSTR", "12")));
            Pick(_sectEnd, Get("SECTEND", "A"));
            _mat.SelectedIndex = Get("STUBCODE", "2") == "1" ? 1 : 0;
            _wrap.Checked = Get("WRAP", "1") == "1"; _wrap.Enabled = _mat.SelectedIndex == 1;
            _model3d.Checked = Get("MODEL3D", "1") == "1";
            _layerInfo.Text = Get("MODELLAYER", "3DMEDModel-Ductbank") + " (in MEDMAKE3D)";
            _sectPick.Checked = Get("SECTPICK", "0") == "1";
            _scale.Text = N(D(Get("SECTSCALE", "1")));
            _tagPat.Text = Get("TAGPAT", "{BANK}-{POS}");
            _enc.Text = Get("ENCH", "Auto");
            Pick(_bends, Get("BENDCONC", "Chamfer").StartsWith("S", StringComparison.OrdinalIgnoreCase) ? "Sweep" : "Chamfer");
            if (Get("VIEW", "").ToUpperInvariant() == "STUB") _viewStub.Checked = true;
            if (_edit) { _bank.ReadOnly = true; _bank.BackColor = SystemColors.Control; }
            _refSizeCb.SelectedIndex = _refSizes.FindIndex(s => Math.Abs(s - _refSize) < 1e-6);
            int rti = _codes.FindIndex(c => c.Key == _refCode);
            if (rti >= 0) _refTypeCb.SelectedIndex = rti;
            _refSizeCb.Enabled = _refTypeCb.Enabled = _plain;
            string[] rf = Get("REF", "").Split('|');
            if (_plain)
                _refInfo.Text = "Ref: plain " + Get("REFTYPE", "polyline") + " route (no MED data), handle " + (rf.Length >= 4 ? rf[3] : "?")
                                + (rf.Length >= 7 ? ", " + rf[5] + " legs, " + rf[6] + " bends" : "") + ". Set its size / type above.";
            else if (rf.Length >= 4)
                _refInfo.Text = "Ref " + rf[0] + ": " + SizeText(D(rf[1])) + " " + Abbr((int)D(rf[2])) + ", handle " + rf[3]
                                + (rf.Length >= 7 ? ", " + rf[5] + " legs, " + rf[6] + " bends" : "");
            if (_pos.Count == 0) RebuildPositions();
        }

        void FillParts()
        {
            string cur = _part.SelectedItem as string;
            _part.Items.Clear(); _part.Items.Add("Auto");
            double sep = D(_sep.SelectedItem as string);
            foreach (var p in _cat) if (Math.Abs(p.Sep - sep) < 0.01) _part.Items.Add(p.Name);
            Pick(_part, cur ?? "Auto");
            Changed();
        }

        // ------------------------------------------------------------------ positions
        List<int> Counts()
        {
            var l = new List<int>();
            foreach (string s in _counts.Text.Split(new[] { ',', ' ', ';' }, StringSplitOptions.RemoveEmptyEntries))
            { int n; if (int.TryParse(s, out n)) l.Add(Math.Max(1, Math.Min(12, n))); }
            if (l.Count == 0) l.Add(4);
            int rows = (int)_rows.Value;
            while (l.Count < rows) l.Add(l[l.Count - 1]);
            while (l.Count > rows) l.RemoveAt(l.Count - 1);
            return l;
        }
        void RowsChanged() { var c = Counts(); _counts.Text = string.Join(",", c.Select(i => i.ToString())); RebuildPositions(); }
        void CountsChanged() { var c = Counts(); _counts.Text = string.Join(",", c.Select(i => i.ToString())); RebuildPositions(); }
        void RebuildPositions()
        {
            var old = _pos.ToDictionary(p => p.Id);
            var counts = Counts();
            _pos.Clear();
            double defSize = Math.Max(_minSize, _refSize);
            if (_sizes.Count > 0 && !_sizes.Any(s => Math.Abs(s - defSize) < 1e-6)) defSize = _sizes.FirstOrDefault(s => s >= defSize - 1e-6);
            for (int r = 1; r <= counts.Count; r++)
                for (int c = 1; c <= counts[r - 1]; c++)
                {
                    string id = ((char)('A' + r - 1)).ToString() + c;
                    Pos p;
                    if (!old.TryGetValue(id, out p)) p = new Pos { Id = id, Size = defSize, Code = _conCode };
                    p.Row = r; p.Col = c; _pos.Add(p);
                }
            if (!_pos.Any(p => p.Id == _refPos)) _refPos = ((char)('A' + counts.Count - 1)).ToString() + "1";
            if (_sel == null || !_pos.Any(p => p.Id == _sel)) _sel = _refPos;
            ShowSelected();
            Changed();
        }
        Pos SelPos() { return _pos.FirstOrDefault(p => p.Id == _sel); }
        void ShowSelected()
        {
            var p = SelPos();
            if (p == null || _tag == null) return;
            bool was = _loading; _loading = true;
            _selLabel.Text = "Position " + p.Id + (p.Id == _refPos ? "  (REF - the picked reference conduit runs here)" : "");
            _tag.Text = TagOf(p);
            int si = _sizes.FindIndex(s => Math.Abs(s - p.Size) < 1e-6);
            if (si < 0) { _sizes.Add(p.Size); _sizes.Sort(); _size.Items.Clear(); foreach (double s in _sizes) _size.Items.Add(SizeText(s)); si = _sizes.FindIndex(s => Math.Abs(s - p.Size) < 1e-6); }
            _size.SelectedIndex = si;
            int ti = _codes.FindIndex(c => c.Key == p.Code);
            if (ti < 0) { _codes.Add(new KeyValuePair<int, string>(p.Code, "code " + p.Code)); _type.Items.Add(p.Code + " " + Abbr(p.Code)); ti = _codes.Count - 1; }
            _type.SelectedIndex = ti;
            _loading = was;
        }

        // plain route reference: its size / type are the default of every position still at the old default
        void RefSizeChanged()
        {
            if (_loading || !_plain || _refSizeCb.SelectedIndex < 0 || _refTypeCb.SelectedIndex < 0) return;
            double ns = _refSizes[_refSizeCb.SelectedIndex];
            int nc = _codes[_refTypeCb.SelectedIndex].Key;
            double osz = Math.Max(_minSize, _refSize);
            foreach (var p in _pos)
                if (p.Id == _refPos || (Math.Abs(p.Size - osz) < 1e-6 && p.Code == _refCode)) { p.Size = Math.Max(_minSize, ns); p.Code = nc; }
            _refSize = ns; _refCode = nc; _conCode = nc;
            ShowSelected(); _grid.Invalidate();
            Changed();
        }
        // stub-up encasement (turn-up) top, relative to the preview bottom; NaN = no turn-up at the section end
        double EncRel(Geo g, out string why)
        {
            why = "";
            bool endA = (_sectEnd.SelectedItem as string ?? "A") != "B";
            string end = endA ? (_endA.SelectedItem as string) : (_endB.SelectedItem as string);
            double botz; string bz = Get("BOTZ", "");
            if (end != "Stubup" || bz == "" || g.P.Count == 0) { why = end != "Stubup" ? "no stub-up at this end" : ""; return double.NaN; }
            botz = D(bz) + SectDz();
            double topRel = D((endA ? _topA : _topB).Text) - botz;
            double sweep = SweepRel(g);
            string t = (_enc.Text ?? "").Trim();
            if (Is45(endA)) why = "45 deg end: the turn-up follows the 45 deg risers, cut level";
            // level cut at least the riser projection below the riser ends (45 deg: the slanted end's low edge, primary OD)
            double proj = Math.Max(0.0, D(Get("RISERPROJ", "4")));
            double maxod = _pos.Count > 0 ? _pos.Max(p => Od(p.Code, p.Size)) : 0.0;
            double lim = topRel - proj - (Is45(endA) ? maxod / 2.0 * Math.Sqrt(0.5) : 0.0);
            double v;
            if (t.StartsWith("T", StringComparison.OrdinalIgnoreCase)) v = lim;
            else if (double.TryParse(t, NumberStyles.Float, IC, out v)) v -= botz;
            else v = Is45(endA) ? lim : sweep;
            if (v > lim + 1e-6) { v = lim; why = "cut level " + N(proj) + "\" below the riser ends"; }
            if (v <= g.Top + 0.01) { why = "at or below the trunk top: no turn-up"; return double.NaN; }
            return v;
        }
        // end B of a sloped / stepped route sits DZB above end A (spec DZB from the last solve)
        double SectDz() { return (_sectEnd.SelectedItem as string ?? "A") == "B" ? D(Get("DZB", "0")) : 0.0; }
        bool Is45(bool endA) { var c = endA ? _angA : _angB; return c != null && (c.SelectedItem as string ?? "").StartsWith("45"); }
        // top of the stub elbow sweep at the section end, relative to the preview bottom (45 deg elbow: R (1 - cos 45))
        double SweepRel(Geo g)
        {
            double fk = Is45((_sectEnd.SelectedItem as string ?? "A") != "B") ? 1.0 - Math.Sqrt(0.5) : 1.0;
            var rv = new Dictionary<string, double>(StringComparer.OrdinalIgnoreCase);
            foreach (string z in Multi("PZ")) { var f = z.Split('|'); if (f.Length >= 6) rv[f[0]] = D(f[5]); }
            double m = double.MinValue;
            foreach (var p in _pos)
            {
                double r; if (!rv.TryGetValue(p.Id, out r) || r <= 0) r = p.Size < 3.999 ? 24.0 : 36.0;
                m = Math.Max(m, g.P[p.Id][2] + fk * r);
            }
            return m;
        }

        void Changed()
        {
            if (_loading) return;
            _dirty = true;
            RefreshAll();
        }

        // ------------------------------------------------------------------ preview geometry (same rules as dbk-solve)
        class Geo { public Part Part; public double PH, PV, Seat, Bot, Top, VL, VR, SVL, SVR; public Dictionary<string, double[]> P = new Dictionary<string, double[]>(); public List<double[]> Pieces = new List<double[]>(); public List<string> Notes = new List<string>(); }
        Geo Preview()
        {
            var g = new Geo();
            if (_pos.Count == 0) return g;
            double sep = D(_sep.SelectedItem as string), maxsize = _pos.Max(p => p.Size), gap = D(_gap.Text);
            double maxod = _pos.Max(p => Od(p.Code, p.Size));
            string pick = _part.SelectedItem as string;
            Part auto = _cat.Where(c => Math.Abs(c.Sep - sep) < 0.01 && c.Size >= maxsize - 1e-6).OrderBy(c => c.Size).FirstOrDefault();
            g.Part = auto;
            if (pick != null && pick != "Auto")
            {
                var ov = _cat.FirstOrDefault(c => c.Name == pick);
                if (ov != null && ov.Size >= maxsize - 1e-6) g.Part = ov;
                else if (ov != null) g.Notes.Add("ERR:Spacer part " + ov.Name + " is smaller than the largest conduit (" + SizeText(maxsize) + ").");
            }
            if (g.Part != null) { g.PH = g.Part.PH; g.PV = g.Part.PV; g.Seat = g.Part.Seat; }
            else { g.PH = g.PV = maxod + gap; g.Seat = D(_covB.Text); g.Notes.Add("No Snap-N-Stac part for " + SizeText(maxsize) + ": spacing from OD + gap."); }
            var refp = _pos.FirstOrDefault(p => p.Id == _refPos) ?? _pos[0];
            int rows = _pos.Max(p => p.Row);
            double sx = D(_sx.Text);
            foreach (var p in _pos)
            {
                int tier = rows - p.Row + 1;
                double od = Od(p.Code, p.Size);
                double zs = g.Seat + (tier - 1) * g.PV;
                g.P[p.Id] = new double[] { (p.Col - refp.Col) * g.PH, (p.Col - refp.Col) * sx, zs + od / 2.0, od, tier, zs };
            }
            g.Bot = Math.Min(0.0, g.P.Values.Min(v => v[2] - v[3] / 2) - D(_covB.Text));
            g.Top = g.P.Values.Max(v => v[2] + v[3] / 2) + D(_covT.Text);
            g.VL = g.P.Values.Min(v => v[0] - v[3] / 2) - D(_covL.Text);
            g.VR = g.P.Values.Max(v => v[0] + v[3] / 2) + D(_covR.Text);
            g.SVL = g.P.Values.Min(v => v[1] - v[3] / 2) - D(_covL.Text);
            g.SVR = g.P.Values.Max(v => v[1] + v[3] / 2) + D(_covR.Text);
            if (g.Part != null)
                for (int tier = 1; tier <= rows; tier++)
                {
                    var inTier = _pos.Where(p => rows - p.Row + 1 == tier).ToList();
                    if (inTier.Count == 0) continue;
                    double zs = g.P[inTier[0].Id][5];
                    for (int k = 0; k < (inTier.Count + 1) / 2; k++)
                    {
                        double xa = ((2 * k + 1) - refp.Col) * g.PH - g.PH / 2.0;
                        g.Pieces.Add(new double[] { xa, xa + g.Part.Len, tier == 1 ? g.Bot : zs - g.Part.Sep, zs + g.Part.Od / 2.0 });
                    }
                    if (inTier.Count % 2 == 1) g.Notes.Add("Row " + inTier[0].Id.Substring(0, 1) + " has " + inTier.Count + " conduits on 2-way pieces: one empty seat.");
                }
            foreach (var p in _pos)
                if (p.Size < _minSize - 1e-6) g.Notes.Add("ERR:" + p.Id + " is below the " + SizeText(_minSize) + " underground minimum.");
            return g;
        }

        void RefreshAll()
        {
            if (_grid == null || _checks == null) return;
            var g = Preview();
            _pitch.Text = g.Part != null ? ("Part " + g.Part.Name + ((_part.SelectedItem as string) == "Auto" ? " (auto)" : "") + ", pitch " + N(g.PH) + " x " + N(g.PV) + ", seat " + N(g.Seat))
                                         : "No spacer part: pitch from OD + gap";
            _grid.Invalidate(); _cheat.Invalidate();
            _checks.BeginUpdate();
            _checks.Items.Clear();
            if (_dirty) _checks.Items.Add("i  Inputs changed since the last check: click Check to re-solve (OK also re-solves).");
            foreach (string s in g.Notes) _checks.Items.Add(s.StartsWith("ERR:") ? "X  " + s.Substring(4) : "!  " + s);
            foreach (string s in Multi("ERR")) _checks.Items.Add("X  " + s);
            foreach (string s in Multi("FLAG")) _checks.Items.Add("!  " + s);
            if (_checks.Items.Count == 0) _checks.Items.Add("OK  No flags.");
            _checks.EndUpdate();
            var sb = new StringBuilder();
            foreach (string s in Multi("SUM")) sb.AppendLine(s);
            var sums = Multi("SUM");
            foreach (string s in Multi("PROF")) if (!sums.Contains(s)) sb.AppendLine(s);
            sb.AppendLine();
            sb.AppendLine("Preview: W x H " + N(Math.Round(g.VR - g.VL, 2)) + " x " + N(Math.Round(g.Top - g.Bot, 2)) + " in, " + _pos.Count + " conduits");
            _envelope.Text = sb.ToString();
            if (_encHint != null)
            {
                string bz = Get("BOTZ", ""), why;
                double er = EncRel(g, out why);
                _encHint.Text = (Is45((_sectEnd.SelectedItem as string ?? "A") != "B") ? "Auto (45 deg end) = Top limit; 90 deg ends: top of the elbow sweep" : "Auto = top of the elbow sweep") + (bz != "" && g.P.Count > 0 ? " (EL " + N(Math.Round(D(bz) + SectDz() + SweepRel(g), 2)) + ")" : "")
                                + ", Top = stub-up top EL less the " + N(Math.Max(0.0, D(Get("RISERPROJ", "4")))) + "\" riser projection, or an elevation. Level top." + (!double.IsNaN(er) ? " Turn-up to EL " + N(Math.Round(D(bz) + SectDz() + er, 2)) : "") + (why != "" ? " (" + why + ")" : "");
            }
            int nerr = Multi("ERR").Count + g.Notes.Count(n => n.StartsWith("ERR:"));
            _status.ForeColor = nerr > 0 ? Color.Firebrick : Color.FromArgb(0, 90, 0);
            _status.Text = (nerr > 0 ? nerr + " error(s): OK is blocked until they are fixed. " : "Ready. ")
                           + _pos.Count + " conduits, " + (g.Part != null ? g.Part.Name : "no spacer") + (_dirty ? " (preview)" : " (checked)")
                           + (_edit ? ". Edit, then Rebuild: the bank is regenerated in place (same ID)." : ". Set tags and sizes, then OK to generate.");
        }

        // ------------------------------------------------------------------ painting
        Rectangle CardRect(Pos p, int ncol, int rows)
        {
            int cw = Math.Min(112, (_grid.Width - 20) / Math.Max(1, ncol)) - 6, ch = Math.Min(72, (_grid.Height - 30) / Math.Max(1, rows)) - 6;
            return new Rectangle(10 + (p.Col - 1) * (cw + 6), 24 + (p.Row - 1) * (ch + 6), cw, ch);
        }
        void PaintGrid(object sender, PaintEventArgs e)
        {
            var gr = e.Graphics; gr.SmoothingMode = SmoothingMode.AntiAlias;
            if (_pos.Count == 0) return;
            int ncol = _pos.Max(p => p.Col), rows = _pos.Max(p => p.Row);
            using (var f = new Font("Segoe UI", 8f)) gr.DrawString("Top row A ... bottom row " + (char)('A' + rows - 1) + ";  REF = reference conduit position", f, Brushes.Gray, 8, 4);
            using (var fb = new Font("Segoe UI", 9f, FontStyle.Bold))
            using (var fs = new Font("Segoe UI", 8f))
                foreach (var p in _pos)
                {
                    var r = CardRect(p, ncol, rows);
                    bool sel = p.Id == _sel, isref = p.Id == _refPos;
                    using (var b = new SolidBrush(sel ? Color.FromArgb(255, 236, 150) : Color.FromArgb(236, 243, 252))) gr.FillRectangle(b, r);
                    using (var pen = new Pen(sel ? Color.DarkOrange : Color.SteelBlue, sel ? 2f : 1f)) gr.DrawRectangle(pen, r);
                    gr.DrawString(p.Id, fb, Brushes.Black, r.Left + 4, r.Top + 2);
                    gr.DrawString(TagOf(p), fs, p.Custom ? Brushes.DarkBlue : Brushes.DimGray, new RectangleF(r.Left + 4, r.Top + 19, r.Width - 6, 16));
                    gr.DrawString(SizeText(p.Size) + " " + Abbr(p.Code), fs, Brushes.Black, r.Left + 4, r.Top + 35);
                    if (isref)
                    {
                        var br = new Rectangle(r.Right - 34, r.Top + 3, 30, 15);
                        gr.FillRectangle(Brushes.SteelBlue, br);
                        gr.DrawString("REF", fs, Brushes.White, br.Left + 3, br.Top);
                    }
                }
        }
        void GridClick(object sender, MouseEventArgs e)
        {
            if (_pos.Count == 0) return;
            int ncol = _pos.Max(p => p.Col), rows = _pos.Max(p => p.Row);
            foreach (var p in _pos)
                if (CardRect(p, ncol, rows).Contains(e.Location)) { _sel = p.Id; ShowSelected(); _grid.Invalidate(); _cheat.Invalidate(); return; }
        }
        void PaintCheat(object sender, PaintEventArgs e)
        {
            var gr = e.Graphics; gr.SmoothingMode = SmoothingMode.AntiAlias;
            var g = Preview();
            if (g.P.Count == 0) return;
            bool stub = _viewStub.Checked;
            double vl = stub ? g.SVL : g.VL, vr = stub ? g.SVR : g.VR, bot = g.Bot, top = g.Top;
            string encWhy; double enc = stub ? EncRel(g, out encWhy) : double.NaN;
            double vtop = double.IsNaN(enc) ? top : Math.Max(top, enc);
            float W = _cheat.Width - 2, H = _cheat.Height - 2;
            double sc = Math.Min((W - 60) / Math.Max(1, vr - vl), (H - 90) / Math.Max(1, vtop - bot));
            float ox = (float)(W / 2 - (vl + vr) / 2 * sc), oy = (float)(H - 50);
            Func<double, float> X = v => (float)(ox + v * sc);
            Func<double, float> Y = z => (float)(oy - (z - bot) * sc);
            using (var hatch = new HatchBrush(HatchStyle.DottedGrid, Color.FromArgb(200, 200, 200), Color.FromArgb(245, 245, 245)))
                gr.FillRectangle(hatch, X(vl), Y(top), (float)((vr - vl) * sc), (float)((top - bot) * sc));
            gr.DrawRectangle(Pens.DimGray, X(vl), Y(top), (float)((vr - vl) * sc), (float)((top - bot) * sc));
            if (!double.IsNaN(enc))
            {
                // concrete turn-up beyond the section: envelope continues up around the elbows / risers
                using (var hatch = new HatchBrush(HatchStyle.DottedGrid, Color.FromArgb(215, 225, 235), Color.FromArgb(250, 251, 253)))
                    gr.FillRectangle(hatch, X(vl), Y(enc), (float)((vr - vl) * sc), (float)((enc - top) * sc));
                using (var pen = new Pen(Color.SlateGray, 1.2f) { DashStyle = DashStyle.Dash })
                {
                    gr.DrawRectangle(pen, X(vl), Y(enc), (float)((vr - vl) * sc), (float)((enc - top) * sc));
                    foreach (var p in _pos)
                    {
                        double[] v = g.P[p.Id];
                        gr.DrawLine(pen, X(v[1] - v[3] / 2), Y(v[2]), X(v[1] - v[3] / 2), Y(enc));
                        gr.DrawLine(pen, X(v[1] + v[3] / 2), Y(v[2]), X(v[1] + v[3] / 2), Y(enc));
                    }
                }
                using (var fe = new Font("Segoe UI", 8f, FontStyle.Bold))
                {
                    string lt = "Concrete turn-up to EL " + N(Math.Round(D(Get("BOTZ", "0")) + enc, 2)) + " (beyond)";
                    var ls = gr.MeasureString(lt, fe);
                    float lx = Math.Max(2f, (X(vl) + X(vr)) / 2 - ls.Width / 2), ly = Y(enc) - ls.Height - 2;
                    if (ly < 18) ly = Y(enc) + 2;
                    gr.FillRectangle(Brushes.White, lx, ly, ls.Width, ls.Height);
                    gr.DrawString(lt, fe, Brushes.SlateGray, lx, ly);
                }
            }
            if (!stub)
                using (var pb = new SolidBrush(Color.FromArgb(150, 120, 170, 120)))
                    foreach (var pc in g.Pieces)
                        gr.FillRectangle(pb, X(pc[0]), Y(pc[3]), (float)((pc[1] - pc[0]) * sc), (float)((pc[3] - pc[2]) * sc));
            using (var f = new Font("Segoe UI", 8f))
            using (var fb = new Font("Segoe UI", 8f, FontStyle.Bold))
            {
                foreach (var p in _pos)
                {
                    double[] v = g.P[p.Id];
                    float r = (float)(v[3] / 2 * sc), cx = X(stub ? v[1] : v[0]), cy = Y(v[2]);
                    bool cur = p.Id == _sel;
                    using (var b = new SolidBrush(cur ? Color.Gold : Color.White)) gr.FillEllipse(b, cx - r, cy - r, 2 * r, 2 * r);
                    using (var pen = new Pen(cur ? Color.DarkOrange : Color.Black, cur ? 2.5f : 1.2f)) gr.DrawEllipse(pen, cx - r, cy - r, 2 * r, 2 * r);
                    var s = p.Id; var sz = gr.MeasureString(s, cur ? fb : f);
                    gr.DrawString(s, cur ? fb : f, Brushes.Black, cx - sz.Width / 2, cy - sz.Height / 2);
                    if (p.Id == _refPos) gr.DrawString("REF", f, Brushes.SteelBlue, cx - r, cy + r);
                }
                gr.DrawString((stub ? "Stub-up zone" : "Trunk") + " section, looking from end " + (_sectEnd.SelectedItem ?? "A") + "  (preview, not to scale of the drawing)", f, Brushes.Gray, 6, 4);
                gr.DrawString("W " + N(Math.Round(vr - vl, 2)) + "\"  x  H " + N(Math.Round(top - bot, 2)) + "\"", fb, Brushes.Black, X(vl), Y(bot) + 6);
                var sp = SelPos();
                if (sp != null)
                {
                    double[] v = g.P[sp.Id];
                    gr.DrawString("Current: " + sp.Id + "  " + TagOf(sp) + "  " + SizeText(sp.Size) + " " + Abbr(sp.Code) + "  OD " + N(Math.Round(v[3], 3)) + "\"", fb, Brushes.DarkOrange, 6, H - 22);
                }
                if (!stub && g.Part != null) gr.DrawString("green = " + g.Part.Name + " pieces", f, Brushes.SeaGreen, W - 150, 22);
            }
        }
        void DrawCheck(object sender, DrawItemEventArgs e)
        {
            if (e.Index < 0) return;
            string t = _checks.Items[e.Index].ToString();
            e.DrawBackground();
            Brush b = t.StartsWith("X") ? Brushes.Firebrick : t.StartsWith("!") ? Brushes.DarkGoldenrod : t.StartsWith("i") ? Brushes.SteelBlue : Brushes.DarkGreen;
            e.Graphics.DrawString(t, _checks.Font, b, new RectangleF(e.Bounds.Left + 2, e.Bounds.Top + 2, e.Bounds.Width - 4, e.Bounds.Height));
        }

        // ------------------------------------------------------------------ out
        void Finish(string action)
        {
            if (action == "OK")
            {
                var bad = new List<string>();
                foreach (var t in new[] { _interval, _first, _covT, _covB, _covL, _covR, _covE, _gap, _topA, _topB, _sx, _sy, _transl, _straight, _scale, _flexMax, _flexLen })
                { double v; if (!double.TryParse(t.Text.Trim(), NumberStyles.Float, IC, out v)) bad.Add(t.Text); }
                if (bad.Count > 0) { MessageBox.Show(this, "Not a number: " + string.Join(", ", bad), "MED Ductbank", MessageBoxButtons.OK, MessageBoxIcon.Warning); return; }
                if (_bank.Text.Trim() == "") { MessageBox.Show(this, "Enter a bank ID.", "MED Ductbank"); return; }
                double fm = D(_flexMax.Text), fln = D(_flexLen.Text);
                if (fm < 0 || fm > 10 || fln < 1)
                { MessageBox.Show(this, "Route rises: flex 0 to 10 deg, over at least 1 in.", "MED Ductbank", MessageBoxButtons.OK, MessageBoxIcon.Warning); return; }
                string et = (_enc.Text ?? "").Trim(); double ev;
                if (!(et == "" || et.StartsWith("A", StringComparison.OrdinalIgnoreCase) || et.StartsWith("T", StringComparison.OrdinalIgnoreCase)
                      || double.TryParse(et, NumberStyles.Float, IC, out ev)))
                { MessageBox.Show(this, "Encasement top EL: enter Auto, Top or an elevation.", "MED Ductbank", MessageBoxButtons.OK, MessageBoxIcon.Warning); return; }
            }
            ResultSpec = BuildSpec(action);
            DialogResult = action == "CANCEL" ? DialogResult.Cancel : DialogResult.OK;
            Close();
        }
        public string BuildSpec(string action)
        {
            var sb = new StringBuilder();
            Action<string, string> kv = (k, v) => sb.Append(k).Append('=').Append(v ?? "").Append('\n');
            kv("ACTION", action);
            if (action == "CANCEL") return sb.ToString();
            kv("BANK", _bank.Text.Trim().ToUpperInvariant()); kv("ROWS", ((int)_rows.Value).ToString());
            kv("COUNTS", string.Join(",", Counts().Select(i => i.ToString()))); kv("REFPOS", _refPos);
            kv("ENDA", _endA.SelectedItem as string); kv("ENDB", _endB.SelectedItem as string);
            kv("ANGA", Is45(true) ? "45" : "90"); kv("ANGB", Is45(false) ? "45" : "90");
            kv("FLEXMAX", _flexMax.Text.Trim()); kv("FLEXLEN", _flexLen.Text.Trim());
            kv("TOPA", _topA.Text.Trim()); kv("TOPB", _topB.Text.Trim()); kv("SX", _sx.Text.Trim()); kv("SY", _sy.Text.Trim());
            kv("SECTEND", _sectEnd.SelectedItem as string); kv("SEP", _sep.SelectedItem as string); kv("PART", _part.SelectedItem as string ?? "Auto");
            kv("COVT", _covT.Text.Trim()); kv("COVB", _covB.Text.Trim()); kv("COVL", _covL.Text.Trim()); kv("COVR", _covR.Text.Trim());
            kv("COVE", _covE.Text.Trim()); kv("MINGAP", _gap.Text.Trim()); kv("SPINT", _interval.Text.Trim()); kv("SPEND", _first.Text.Trim());
            kv("TRANSL", _transl.Text.Trim()); kv("STUBSTR", _straight.Text.Trim()); kv("SECTSCALE", _scale.Text.Trim());
            kv("STUBCODE", _mat.SelectedIndex == 1 ? "1" : "2"); kv("WRAP", _wrap.Checked ? "1" : "0");
            kv("MODEL3D", _model3d.Checked ? "1" : "0"); kv("SECTPICK", _sectPick.Checked ? "1" : "0"); kv("TAGPAT", _tagPat.Text.Trim());
            string ench = (_enc.Text ?? "").Trim();
            kv("BENDCONC", (_bends.SelectedItem as string) ?? "Chamfer");
            kv("ENCH", ench == "" || ench.StartsWith("A", StringComparison.OrdinalIgnoreCase) ? "Auto" : ench.StartsWith("T", StringComparison.OrdinalIgnoreCase) ? "Top" : ench);
            if (_plain) { kv("REFSIZE", N(_refSize)); kv("REFCODE", _refCode.ToString()); }
            foreach (var p in _pos)
                kv("POS", p.Id + "|" + (TagOf(p) ?? "").Replace("|", "/") + "|" + N(p.Size) + "|" + p.Code + "|" + (p.Custom ? "C" : "D"));
            return sb.ToString();
        }

        void ShowHelp()
        {
            MessageBox.Show(this,
                "DUCTBANK builds an underground bank around the reference conduit you picked.\n\n" +
                "1. Set rows and conduits per row (top row first). The REF card is where the picked conduit runs.\n" +
                "2. Click a card to set its tag, size and type; 'Size to all' / 'Type to all' copy the selected card.\n" +
                "3. Spacers default to Carlon Snap-N-Stac (Auto part from the largest conduit and the separation).\n" +
                "4. Stub-up risers and elbows default to PVC-coated RGS; plain RGS can be tape wrapped (WRAP note, BOM 174).\n" +
                "5. Stub pitch center to center: across = column to column, along = row to row (at the stub-ups; the trunk uses the spacer pitch).\n" +
                "6. Encasement top EL: the concrete turns up around the stub elbows and risers (at 45 deg ends it follows the risers) and is cut level, parallel to grade, at least the riser projection (_DBKRISERPROJ, default 4\") below the riser ends. Auto = top of the elbow sweep at 90 deg ends and the Top limit at 45 deg ends, Top = the stub-up top EL less the projection, or type an elevation (higher values are cut at that limit).\n" +
                "7. Bends (Cover box): Chamfer (default) = straight concrete chamfer on the outside of each plan bend and of the stub-up turn-up, sized so every elbow keeps at least the side/top/end cover; Sweep = concrete follows the elbow arcs.\n" +
                "8. A plain 3D polyline / polyline / line can be the reference route: set its size and type in the Bank box.\n" +
                "   Elevation changes in the route are followed: gentle grades (up to the flex angle over the flex length, Envelope box) are sloped runs with no fitting; steeper changes get stock vertical bends (11.25 / 22.5 / 30 / 45 / 90). The route profile is listed in the Envelope box.\n" +
                "   Stub-up angle per end (next to End A / End B): 90 or 45 (45 deg stub elbows and risers ending open at the stub-up point; no fitting).\n" +
                "9. Check re-solves and refreshes the checks and envelope; OK solves and generates (blocked while there are errors).\n\n" +
                "DBEDIT reopens this dialog for an existing bank and rebuilds it in place (same ID) from the reference route on MED_DBREF.\n" +
                "The envelope and spacer stations are also modelled as 3D solids on the 3DMEDModel- layer, which MEDMAKE3D pulls into the 3D export.\n" +
                Med3DNotice.Text + "\n\nCommand-line versions: -DUCTBANK, -DBEDIT.",
                "MED Ductbank help", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        /// <summary>Docs/tests: render the dialog for a spec (no AutoCAD needed) with a position selected.</summary>
        public static void RenderToPng(string spec, string selectPos, string pngPath)
        {
            using (var f = new MedDuctbankForm(spec))
            {
                f.StartPosition = FormStartPosition.Manual;
                f.Location = new Point(-4000, -4000);
                f.ShowInTaskbar = false;
                if (!string.IsNullOrEmpty(selectPos) && f._pos.Any(p => p.Id == selectPos.ToUpperInvariant())) { f._sel = selectPos.ToUpperInvariant(); f.ShowSelected(); f.RefreshAll(); }
                f.Show();
                Application.DoEvents();
                using (var bmp = new Bitmap(f.Width, f.Height))
                {
                    f.DrawToBitmap(bmp, new Rectangle(0, 0, f.Width, f.Height));
                    bmp.Save(pngPath, System.Drawing.Imaging.ImageFormat.Png);
                }
                f.Close();
            }
        }

        class DoubleBufferedPanel : Panel { public DoubleBufferedPanel() { DoubleBuffered = true; ResizeRedraw = true; } }
    }
}
