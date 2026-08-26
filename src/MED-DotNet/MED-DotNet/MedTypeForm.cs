using Autodesk.AutoCAD.ApplicationServices;

using Autodesk.AutoCAD.Runtime;

using System;

using System.Collections.Generic;

using System.Data;

using System.Data.Common;

using System.Drawing;

using System.Globalization;

using System.IO;

using System.Text;

using System.Windows.Forms;

using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

using DataTable = System.Data.DataTable;

using DataRow = System.Data.DataRow;

using DataView = System.Data.DataView;



namespace MEDDotNet

{

    public class MedTypeCommands

    {

        [CommandMethod("MEDTYPE")]

        public void ShowType()

        {

            MedTypeForm.Open();

        }



        [CommandMethod("MEDTYPES")]

        public void ShowTypes()

        {

            MedTypeForm.Open();

        }

    }



    internal class MedTypeForm : Form

    {

        static readonly string[] TypeValues = { "CONDUIT", "CABLE", "TRAY", "FITTING", "EQUIP" };

        static readonly string[] Cols =

        {

            "ITEMTYPE", "ITEMCODE", "ITEMDESC", "ITEM_GRP",

            "ITEMKEY1", "ITEMKEY2", "ITEMKEY3", "ITEMKEY4",

            "USER1", "USER2", "USER3", "USER4"

        };



        ComboBox _typeFilter;

        TextBox _search;

        DataGridView _grid;

        Label _status;

        DataTable _table;

        bool _loading;



        public static void Open()

        {

            using (MedTypeForm form = new MedTypeForm())

            {

                AcadApp.ShowModalDialog(form);

            }

        }



        public MedTypeForm()

        {

            Text = "MED Type";

            Width = 1100;

            Height = 620;

            StartPosition = FormStartPosition.CenterParent;

            MinimizeBox = false;

            ShowInTaskbar = false;

            Font = new System.Drawing.Font("Segoe UI", 9f);



            Panel top = new Panel();

            top.Dock = DockStyle.Top;

            top.Height = 40;



            Label typeLbl = new Label();

            typeLbl.Text = "Type";

            typeLbl.AutoSize = true;

            typeLbl.Location = new Point(8, 12);



            _typeFilter = new ComboBox();

            _typeFilter.DropDownStyle = ComboBoxStyle.DropDownList;

            _typeFilter.Location = new Point(44, 8);

            _typeFilter.Width = 110;

            _typeFilter.Items.AddRange(new object[] { "All", "Conduit", "Cable", "Tray", "Fitting", "Equipment" });

            _typeFilter.SelectedIndex = 0;

            _typeFilter.SelectedIndexChanged += delegate { if (!_loading) ApplyFilter(); };



            Label findLbl = new Label();

            findLbl.Text = "Find";

            findLbl.AutoSize = true;

            findLbl.Location = new Point(166, 12);



            _search = new TextBox();

            _search.Location = new Point(200, 8);

            _search.Width = 180;

            _search.TextChanged += delegate { if (!_loading) ApplyFilter(); };



            Button save = MakeBtn("Save", 400, delegate { Save(); });

            Button refresh = MakeBtn("Refresh", 484, delegate { LoadTable(); });

            Button exp = MakeBtn("Export CSV", 568, delegate { ExportCsv(); });

            Button imp = MakeBtn("Import CSV", 668, delegate { ImportCsv(); });



            top.Controls.Add(typeLbl);

            top.Controls.Add(_typeFilter);

            top.Controls.Add(findLbl);

            top.Controls.Add(_search);

            top.Controls.Add(save);

            top.Controls.Add(refresh);

            top.Controls.Add(exp);

            top.Controls.Add(imp);



            _grid = new DataGridView();

            _grid.Dock = DockStyle.Fill;

            _grid.AllowUserToAddRows = true;

            _grid.AllowUserToDeleteRows = true;

            _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;

            _grid.RowHeadersVisible = true;

            _grid.SelectionMode = DataGridViewSelectionMode.CellSelect;

            _grid.MultiSelect = true;

            _grid.EditMode = DataGridViewEditMode.EditOnEnter;

            _grid.ClipboardCopyMode = DataGridViewClipboardCopyMode.EnableWithoutHeaderText;

            _grid.DefaultValuesNeeded += GridDefaultValuesNeeded;

            _grid.DataError += delegate (object s, DataGridViewDataErrorEventArgs e) { e.ThrowException = false; };

            _grid.CellValueChanged += delegate { UpdateStatus(); };



            ContextMenuStrip menu = new ContextMenuStrip();

            menu.Items.Add("Copy", null, delegate { CopyCells(); });

            menu.Items.Add("Paste", null, delegate { PasteCells(); });

            menu.Items.Add("Fill down", null, delegate { FillDown(); });

            _grid.ContextMenuStrip = menu;



            _status = new Label();

            _status.Dock = DockStyle.Bottom;

            _status.Height = 22;

            _status.TextAlign = ContentAlignment.MiddleLeft;

            _status.Padding = new Padding(8, 0, 0, 0);



            Controls.Add(_grid);

            Controls.Add(_status);

            Controls.Add(top);



            FormClosing += FormClosingAsk;

            LoadTable();

        }



        static Button MakeBtn(string text, int x, EventHandler click)

        {

            Button b = new Button();

            b.Text = text;

            b.Width = text.Length > 8 ? 92 : 80;

            b.Location = new Point(x, 7);

            b.Click += click;

            return b;

        }



        void FormClosingAsk(object sender, FormClosingEventArgs e)

        {

            _grid.EndEdit();

            if (_table == null || _table.GetChanges() == null)

                return;

            DialogResult r = MessageBox.Show(this, "Save changes to MEDType?", "MED Type",

                MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);

            if (r == DialogResult.Cancel)

                e.Cancel = true;

            else if (r == DialogResult.Yes && !Save())

                e.Cancel = true;

        }



        void LoadTable()

        {

            _loading = true;

            try

            {

                DataTable dt = ProcessSQL.QueryTable("SELECT * FROM MEDType ORDER BY ITEMTYPE, ITEMCODE");

                dt.PrimaryKey = new DataColumn[] { dt.Columns["ITEMTYPE"], dt.Columns["ITEMCODE"] };

                dt.Columns["ITEMDESC"].DefaultValue = "";

                dt.Columns["ITEMTYPE"].DefaultValue = "CONDUIT";

                dt.Columns["ITEMCODE"].DefaultValue = 0L;

                _table = dt;

                _grid.DataSource = dt.DefaultView;

                StyleColumns();

                ApplyFilter();

            }

            catch (System.Exception ex)

            {

                MessageBox.Show(this, ex.Message, "MED Type");

            }

            finally

            {

                _loading = false;

                UpdateStatus();

            }

        }



        void StyleColumns()

        {

            SetHeader("ITEMTYPE", "Type", 70);

            SetHeader("ITEMCODE", "Code", 55);

            SetHeader("ITEMDESC", "Description", 280);

            SetHeader("ITEM_GRP", "Group", 70);

            SetHeader("ITEMKEY1", "Key1", 80);

            SetHeader("ITEMKEY2", "Key2", 80);

            SetHeader("ITEMKEY3", "Key3", 80);

            SetHeader("ITEMKEY4", "Key4", 80);

            SetHeader("USER1", "User1", 70);

            SetHeader("USER2", "User2", 70);

            SetHeader("USER3", "User3", 70);

            SetHeader("USER4", "User4", 70);

            if (_grid.Columns.Contains("ITEMTYPE"))

            {

                int idx = _grid.Columns["ITEMTYPE"].Index;

                DataGridViewComboBoxColumn combo = new DataGridViewComboBoxColumn();

                combo.Name = "ITEMTYPE";

                combo.DataPropertyName = "ITEMTYPE";

                combo.HeaderText = "Type";

                combo.Items.AddRange(TypeValues);

                combo.FlatStyle = FlatStyle.Flat;

                combo.DisplayStyle = DataGridViewComboBoxDisplayStyle.DropDownButton;

                combo.FillWeight = 70;

                _grid.Columns.RemoveAt(idx);

                _grid.Columns.Insert(idx, combo);

            }

        }



        void SetHeader(string name, string header, float weight)

        {

            if (!_grid.Columns.Contains(name))

                return;

            _grid.Columns[name].HeaderText = header;

            _grid.Columns[name].FillWeight = weight;

        }



        void ApplyFilter()

        {

            if (_table == null)

                return;

            List<string> parts = new List<string>();

            string type = SqlItemType(Convert.ToString(_typeFilter.SelectedItem));

            if (type != null)

                parts.Add("ITEMTYPE = '" + type.Replace("'", "''") + "'");

            string q = (_search.Text ?? "").Trim().Replace("'", "''");

            if (q.Length > 0)

            {

                parts.Add("(ITEMDESC LIKE '%" + q + "%' OR CONVERT(ITEMCODE, 'System.String') LIKE '%" + q

                    + "%' OR ITEMKEY1 LIKE '%" + q + "%' OR ITEM_GRP LIKE '%" + q + "%')");

            }

            try

            {

                _table.DefaultView.RowFilter = string.Join(" AND ", parts.ToArray());

            }

            catch (System.Exception)

            {

                _table.DefaultView.RowFilter = "";

            }

            UpdateStatus();

        }



        static string SqlItemType(string display)

        {

            if (display == "Conduit") return "CONDUIT";

            if (display == "Cable") return "CABLE";

            if (display == "Tray") return "TRAY";

            if (display == "Fitting") return "FITTING";

            if (display == "Equipment") return "EQUIP";

            return null;

        }



        void GridDefaultValuesNeeded(object sender, DataGridViewRowEventArgs e)

        {

            string type = SqlItemType(Convert.ToString(_typeFilter.SelectedItem));

            e.Row.Cells["ITEMTYPE"].Value = type ?? "CONDUIT";

            e.Row.Cells["ITEMCODE"].Value = 0L;

            e.Row.Cells["ITEMDESC"].Value = "";

        }



        bool Save()

        {

            try

            {

                _grid.EndEdit();

                _grid.BindingContext[_grid.DataSource].EndCurrentEdit();

            }

            catch (System.Exception)

            {

            }

            if (_table == null)

                return true;

            DataTable changes = _table.GetChanges();

            if (changes == null)

            {

                _status.Text = "No changes.";

                return true;

            }

            try

            {

                ProcessSQL.UpdateTable("SELECT * FROM MEDType", _table);

                _table.AcceptChanges();

                MedTypeLookup.ClearCache();

                UpdateStatus();

                _status.Text = VisibleCount() + " row(s). Saved.";

                return true;

            }

            catch (System.Exception ex)

            {

                MessageBox.Show(this, ex.Message, "MED Type save");

                return false;

            }

        }



        void ExportCsv()

        {

            SaveFileDialog dlg = new SaveFileDialog();

            dlg.Filter = "CSV (*.csv)|*.csv";

            dlg.FileName = "MEDType.csv";

            if (dlg.ShowDialog(this) != DialogResult.OK)

                return;

            try

            {

                DataView view = _table.DefaultView;

                StringBuilder sb = new StringBuilder();

                for (int i = 0; i < Cols.Length; i++)

                {

                    if (i > 0) sb.Append(',');

                    sb.Append(Cols[i]);

                }

                sb.AppendLine();

                foreach (DataRowView rv in view)

                {

                    DataRow row = rv.Row;

                    if (row.RowState == DataRowState.Deleted)

                        continue;

                    for (int i = 0; i < Cols.Length; i++)

                    {

                        if (i > 0) sb.Append(',');

                        sb.Append(Csv(Cell(row, Cols[i])));

                    }

                    sb.AppendLine();

                }

                File.WriteAllText(dlg.FileName, sb.ToString(), Encoding.UTF8);

                _status.Text = "Exported " + view.Count + " row(s).";

            }

            catch (System.Exception ex)

            {

                MessageBox.Show(this, ex.Message, "MED Type export");

            }

        }



        void ImportCsv()

        {

            OpenFileDialog dlg = new OpenFileDialog();

            dlg.Filter = "CSV (*.csv)|*.csv|All files (*.*)|*.*";

            if (dlg.ShowDialog(this) != DialogResult.OK)

                return;

            try

            {

                List<string[]> rows = ReadCsv(dlg.FileName);

                if (rows.Count < 2)

                {

                    MessageBox.Show(this, "CSV has no data rows.", "MED Type import");

                    return;

                }

                Dictionary<string, int> map = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

                string[] header = rows[0];

                for (int i = 0; i < header.Length; i++)

                    map[header[i].Trim()] = i;

                if (!map.ContainsKey("ITEMTYPE") || !map.ContainsKey("ITEMCODE"))

                {

                    MessageBox.Show(this, "CSV needs ITEMTYPE and ITEMCODE columns.", "MED Type import");

                    return;

                }

                int upsert = 0;

                using (DbConnection conn = ProcessSQL.OpenConnection())
                {
                    foreach (string[] cells in rows.GetRange(1, rows.Count - 1))
                    {
                        string itemType = Get(cells, map, "ITEMTYPE").Trim().ToUpperInvariant();
                        if (itemType == "EQUIPMENT") itemType = "EQUIP";
                        long code;
                        if (itemType.Length == 0 || !long.TryParse(Get(cells, map, "ITEMCODE").Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out code))
                            continue;
                        string desc = Get(cells, map, "ITEMDESC");
                        if (desc == null) desc = "";
                        bool exists;
                        using (DbCommand sel = conn.CreateCommand())
                        {
                            sel.CommandText = "SELECT 1 FROM MEDType WHERE ITEMTYPE=@t AND ITEMCODE=@c";
                            ProcessSQL.AddParam(sel, "@t", itemType);
                            ProcessSQL.AddParam(sel, "@c", code);
                            object found = sel.ExecuteScalar();
                            exists = found != null && found != DBNull.Value;
                        }
                        using (DbCommand cmd = conn.CreateCommand())
                        {
                            if (exists)
                            {
                                cmd.CommandText =
                                    "UPDATE MEDType SET ITEMDESC=@d, ITEM_GRP=@g, ITEMKEY1=@k1, ITEMKEY2=@k2, ITEMKEY3=@k3, ITEMKEY4=@k4, USER1=@u1, USER2=@u2, USER3=@u3, USER4=@u4 "
                                    + "WHERE ITEMTYPE=@t AND ITEMCODE=@c";
                            }
                            else
                            {
                                cmd.CommandText =
                                    "INSERT INTO MEDType (ITEMTYPE, ITEMCODE, ITEMDESC, ITEM_GRP, ITEMKEY1, ITEMKEY2, ITEMKEY3, ITEMKEY4, USER1, USER2, USER3, USER4) "
                                    + "VALUES (@t, @c, @d, @g, @k1, @k2, @k3, @k4, @u1, @u2, @u3, @u4)";
                            }
                            ProcessSQL.AddParam(cmd, "@t", itemType);
                            ProcessSQL.AddParam(cmd, "@c", code);
                            ProcessSQL.AddParam(cmd, "@d", Trunc(desc, 100));
                            ProcessSQL.AddParam(cmd, "@g", Db(Get(cells, map, "ITEM_GRP"), 12));
                            ProcessSQL.AddParam(cmd, "@k1", Db(Get(cells, map, "ITEMKEY1"), 20));
                            ProcessSQL.AddParam(cmd, "@k2", Db(Get(cells, map, "ITEMKEY2"), 20));
                            ProcessSQL.AddParam(cmd, "@k3", Db(Get(cells, map, "ITEMKEY3"), 20));
                            ProcessSQL.AddParam(cmd, "@k4", Db(Get(cells, map, "ITEMKEY4"), 20));
                            ProcessSQL.AddParam(cmd, "@u1", Db(Get(cells, map, "USER1"), 20));
                            ProcessSQL.AddParam(cmd, "@u2", Db(Get(cells, map, "USER2"), 20));
                            ProcessSQL.AddParam(cmd, "@u3", Db(Get(cells, map, "USER3"), 20));
                            ProcessSQL.AddParam(cmd, "@u4", Db(Get(cells, map, "USER4"), 20));
                            cmd.ExecuteNonQuery();
                            upsert++;
                        }
                    }
                }

                MedTypeLookup.ClearCache();

                LoadTable();

                _status.Text = "Imported " + upsert + " row(s).";

            }

            catch (System.Exception ex)

            {

                MessageBox.Show(this, ex.Message, "MED Type import");

            }

        }



        static string Get(string[] cells, Dictionary<string, int> map, string name)

        {

            int i;

            if (!map.TryGetValue(name, out i) || i < 0 || i >= cells.Length)

                return "";

            return cells[i] ?? "";

        }



        static object Db(string v, int max)

        {

            if (string.IsNullOrWhiteSpace(v))

                return DBNull.Value;

            return Trunc(v.Trim(), max);

        }



        static string Trunc(string v, int max)

        {

            if (v == null) return "";

            if (v.Length <= max) return v;

            return v.Substring(0, max);

        }



        static string Cell(DataRow row, string col)

        {

            if (!row.Table.Columns.Contains(col) || row[col] == null || row[col] == DBNull.Value)

                return "";

            return Convert.ToString(row[col]);

        }



        static string Csv(string v)

        {

            if (v == null) v = "";

            if (v.IndexOfAny(new char[] { ',', '"', '\n', '\r' }) >= 0)

                return "\"" + v.Replace("\"", "\"\"") + "\"";

            return v;

        }



        static List<string[]> ReadCsv(string path)

        {

            List<string[]> rows = new List<string[]>();

            using (StreamReader sr = new StreamReader(path, Encoding.UTF8))

            {

                string line;

                while ((line = sr.ReadLine()) != null)

                    rows.Add(SplitCsvLine(line));

            }

            return rows;

        }



        static string[] SplitCsvLine(string line)

        {

            List<string> cols = new List<string>();

            StringBuilder cur = new StringBuilder();

            bool quoted = false;

            for (int i = 0; i < line.Length; i++)

            {

                char ch = line[i];

                if (quoted)

                {

                    if (ch == '"')

                    {

                        if (i + 1 < line.Length && line[i + 1] == '"')

                        {

                            cur.Append('"');

                            i++;

                        }

                        else

                            quoted = false;

                    }

                    else

                        cur.Append(ch);

                }

                else if (ch == '"')

                    quoted = true;

                else if (ch == ',')

                {

                    cols.Add(cur.ToString());

                    cur.Length = 0;

                }

                else

                    cur.Append(ch);

            }

            cols.Add(cur.ToString());

            return cols.ToArray();

        }



        void UpdateStatus()

        {

            int dirty = 0;

            if (_table != null)

            {

                DataTable ch = _table.GetChanges();

                if (ch != null) dirty = ch.Rows.Count;

            }

            string extra = dirty > 0 ? "  " + dirty + " unsaved." : "";

            _status.Text = VisibleCount() + " row(s)." + extra + "  Ctrl+C/V, Ctrl+D fill down, Ctrl+S save.";

        }



        int VisibleCount()

        {

            int n = 0;

            foreach (DataGridViewRow row in _grid.Rows)

            {

                if (!row.IsNewRow) n++;

            }

            return n;

        }



        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)

        {

            if (keyData == (Keys.Control | Keys.S))

            {

                Save();

                return true;

            }

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

            if (cell.OwningRow != null && cell.OwningRow.IsNewRow)

                return false;

            return true;

        }



        void TrySet(DataGridViewCell cell, string raw)

        {

            if (!CanEdit(cell))

                return;

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

            int minR = int.MaxValue;

            foreach (DataGridViewCell cell in _grid.SelectedCells)

            {

                if (cell.RowIndex < minR)

                    minR = cell.RowIndex;

            }

            Dictionary<int, string> top = new Dictionary<int, string>();

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

    }

}

