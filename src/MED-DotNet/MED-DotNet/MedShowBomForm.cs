using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Text;
using System.Windows.Forms;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;
using DataTable = System.Data.DataTable;
using DataRow = System.Data.DataRow;

namespace MEDDotNet
{
    public class MedShowBomCommands
    {
        [CommandMethod("MEDSHOWBOM")]
        public void ShowBomDetail()
        {
            MedShowBomForm.ShowBom(false);
        }

        [CommandMethod("MEDSHOW")]
        public void ShowBomAlias()
        {
            MedShowBomForm.ShowBom(false);
        }

        [CommandMethod("MEDSHOWSUM")]
        public void ShowBomSummary()
        {
            MedShowBomForm.ShowBom(true);
        }
    }

    internal class MedShowBomForm : Form
    {
        ComboBox _typeFilter;
        CheckBox _summary;
        CheckBox _thisProject;
        DataGridView _grid;
        Label _status;
        bool _loading;

        public MedShowBomForm(bool summary)
        {
            Text = "MED BOM";
            Width = 980;
            Height = 520;
            StartPosition = FormStartPosition.CenterParent;
            MinimizeBox = false;
            ShowInTaskbar = false;
            Font = new System.Drawing.Font("Segoe UI", 9f);

            Panel top = new Panel();
            top.Dock = DockStyle.Top;
            top.Height = 64;

            Label typeLbl = new Label();
            typeLbl.Text = "Type";
            typeLbl.AutoSize = true;
            typeLbl.Location = new Point(8, 12);

            _typeFilter = new ComboBox();
            _typeFilter.DropDownStyle = ComboBoxStyle.DropDownList;
            _typeFilter.Location = new Point(44, 8);
            _typeFilter.Width = 160;
            _typeFilter.Items.AddRange(new object[] { "All", "Conduit", "Cable", "Tray", "Fitting", "Equipment" });
            _typeFilter.SelectedIndex = 0;
            _typeFilter.SelectedIndexChanged += delegate { if (!_loading) Reload(); };

            _summary = new CheckBox();
            _summary.Text = "Summarize (by type, code, size)";
            _summary.AutoSize = true;
            _summary.Location = new Point(220, 10);
            _summary.Checked = summary;
            _summary.CheckedChanged += delegate { if (!_loading) Reload(); };

            _thisProject = new CheckBox();
            _thisProject.Text = "This project only";
            _thisProject.AutoSize = true;
            _thisProject.Location = new Point(220, 34);
            _thisProject.Checked = true;
            _thisProject.CheckedChanged += delegate { if (!_loading) Reload(); };

            Button refresh = new Button();
            refresh.Text = "Refresh";
            refresh.Width = 80;
            refresh.Location = new Point(460, 8);
            refresh.Click += delegate { Reload(); };

            Button copy = new Button();
            copy.Text = "Copy";
            copy.Width = 80;
            copy.Location = new Point(548, 8);
            copy.Click += delegate { CopyGrid(); };

            Button csv = new Button();
            csv.Text = "Export CSV";
            csv.Width = 88;
            csv.Location = new Point(636, 8);
            csv.Click += delegate { ExportCsv(); };

            top.Controls.Add(typeLbl);
            top.Controls.Add(_typeFilter);
            top.Controls.Add(_summary);
            top.Controls.Add(_thisProject);
            top.Controls.Add(refresh);
            top.Controls.Add(copy);
            top.Controls.Add(csv);

            _grid = new DataGridView();
            _grid.Dock = DockStyle.Fill;
            _grid.ReadOnly = true;
            _grid.AllowUserToAddRows = false;
            _grid.AllowUserToDeleteRows = false;
            _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            _grid.RowHeadersVisible = false;
            _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            _grid.MultiSelect = true;
            _grid.ClipboardCopyMode = DataGridViewClipboardCopyMode.EnableWithoutHeaderText;

            Panel bottom = new Panel();
            bottom.Dock = DockStyle.Bottom;
            bottom.Height = 48;

            _status = new Label();
            _status.AutoSize = true;
            _status.Location = new Point(8, 16);
            _status.Text = "Conduit/cable/tray qty is inches in the table. BOM qty is feet. Fittings and equipment are each.";

            Button close = new Button();
            close.Text = "Close";
            close.DialogResult = DialogResult.OK;
            close.Width = 88;
            bottom.Controls.Add(_status);
            bottom.Controls.Add(close);
            CancelButton = close;
            AcceptButton = close;
            bottom.Resize += delegate { close.Location = new Point(bottom.ClientSize.Width - 96, 10); };

            Controls.Add(_grid);
            Controls.Add(bottom);
            Controls.Add(top);
        }

        string GridText(bool csv)
        {
            StringBuilder sb = new StringBuilder();
            int cols = _grid.Columns.Count;
            for (int c = 0; c < cols; c++)
            {
                if (c > 0)
                    sb.Append(csv ? "," : "\t");
                sb.Append(Field(_grid.Columns[c].HeaderText, csv));
            }
            sb.AppendLine();
            foreach (DataGridViewRow row in _grid.Rows)
            {
                if (row.IsNewRow)
                    continue;
                for (int c = 0; c < cols; c++)
                {
                    if (c > 0)
                        sb.Append(csv ? "," : "\t");
                    object v = row.Cells[c].Value;
                    sb.Append(Field(v == null ? "" : Convert.ToString(v), csv));
                }
                sb.AppendLine();
            }
            return sb.ToString();
        }

        static string Field(string value, bool csv)
        {
            if (value == null)
                value = "";
            if (!csv)
                return value;
            if (value.IndexOfAny(new char[] { ',', '"', '\r', '\n' }) >= 0)
                return "\"" + value.Replace("\"", "\"\"") + "\"";
            return value;
        }

        void CopyGrid()
        {
            try
            {
                Clipboard.SetText(GridText(false));
                _status.Text = "Copied " + VisibleRowCount() + " row(s) with headers.";
            }
            catch (System.Exception ex)
            {
                _status.Text = "Copy failed: " + ex.Message;
            }
        }

        void ExportCsv()
        {
            string dwg = "MED-BOM";
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc != null)
                dwg = Path.GetFileNameWithoutExtension(doc.Name);
            using (SaveFileDialog dlg = new SaveFileDialog())
            {
                dlg.Title = "Export MED BOM";
                dlg.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*";
                dlg.FileName = dwg + "-BOM.csv";
                dlg.OverwritePrompt = true;
                if (dlg.ShowDialog(this) != DialogResult.OK)
                    return;
                try
                {
                    File.WriteAllText(dlg.FileName, GridText(true), Encoding.UTF8);
                    _status.Text = "Exported " + VisibleRowCount() + " row(s) to " + dlg.FileName;
                }
                catch (System.Exception ex)
                {
                    _status.Text = "Export failed: " + ex.Message;
                }
            }
        }

        int VisibleRowCount()
        {
            int n = 0;
            foreach (DataGridViewRow row in _grid.Rows)
            {
                if (!row.IsNewRow)
                    n++;
            }
            return n;
        }

        void SetFill(string name, float weight)
        {
            if (_grid.Columns.Contains(name))
                _grid.Columns[name].FillWeight = weight;
        }

        static string SqlText(string value)
        {
            if (value == null)
                return "";
            return value.Replace("'", "''");
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

        static bool IsLinear(string itemType)
        {
            if (string.IsNullOrEmpty(itemType))
                return false;
            string t = itemType.Trim().ToUpperInvariant();
            return t == "CONDUIT" || t == "CABLE" || t == "TRAY";
        }

        static string Cell(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col) || row[col] == null || row[col] == DBNull.Value)
                return "";
            return Convert.ToString(row[col]);
        }

        static double Qty(DataRow row)
        {
            if (!row.Table.Columns.Contains("ITEM_QTY_") || row["ITEM_QTY_"] == null || row["ITEM_QTY_"] == DBNull.Value)
                return 0;
            try { return Convert.ToDouble(row["ITEM_QTY_"], CultureInfo.InvariantCulture); }
            catch { return 0; }
        }

        void Reload()
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            string dwg = System.IO.Path.GetFileName(doc.Name);
            string project = "PROJECT1";
            try { project = MedLisp.GetString("_MEDPROJECT", "PROJECT1"); }
            catch (System.Exception) { }

            string type = SqlItemType(Convert.ToString(_typeFilter.SelectedItem));
            bool summary = _summary.Checked;
            bool byProject = _thisProject.Checked;

            string where = "WHERE p.ITEM_DWG_='" + SqlText(dwg) + "'";
            if (byProject && !string.IsNullOrEmpty(project))
                where += " AND p.PROJECTNO='" + SqlText(project) + "'";
            if (type != null)
                where += " AND p.ITEM_TYPE='" + type + "'";

            string sql;
            if (summary)
            {
                sql = "SELECT p.ITEM_TYPE, p.ITEM_CODE, CAST('ALL TAGS' AS varchar(20)) AS ITEM_TAG_, "
                    + "SUM(p.ITEM_QTY_) AS ITEM_QTY_, p.ITEM_SIZE, t.ITEMDESC "
                    + "FROM MEDProject p LEFT JOIN MEDType t ON p.ITEM_CODE=t.ITEMCODE AND p.ITEM_TYPE=t.ITEMTYPE "
                    + where
                    + " GROUP BY p.ITEM_TYPE, p.ITEM_CODE, p.ITEM_SIZE, t.ITEMDESC "
                    + "ORDER BY p.ITEM_TYPE, p.ITEM_CODE";
            }
            else
            {
                sql = "SELECT p.ITEM_TYPE, p.ITEM_CODE, p.ITEM_TAG_, p.ITEM_QTY_, p.ITEM_SIZE, t.ITEMDESC "
                    + "FROM MEDProject p LEFT JOIN MEDType t ON p.ITEM_CODE=t.ITEMCODE AND p.ITEM_TYPE=t.ITEMTYPE "
                    + where
                    + " ORDER BY p.ITEM_TYPE, p.ITEM_CODE";
            }

            DataTable src;
            try
            {
                src = ProcessSQL.QueryTable(sql);
            }
            catch (System.Exception ex)
            {
                _status.Text = "Query failed: " + ex.Message;
                _grid.DataSource = null;
                return;
            }

            DataTable view = new DataTable();
            view.Columns.Add("Type");
            view.Columns.Add("Code");
            view.Columns.Add("Tag");
            view.Columns.Add("Size");
            view.Columns.Add("Qty raw");
            view.Columns.Add("Unit");
            view.Columns.Add("BOM qty");
            view.Columns.Add("Description");

            int n = 0;
            foreach (DataRow row in src.Rows)
            {
                string itemType = Cell(row, "ITEM_TYPE");
                double raw = Qty(row);
                bool linear = IsLinear(itemType);
                DataRow nr = view.NewRow();
                nr["Type"] = itemType;
                nr["Code"] = Cell(row, "ITEM_CODE");
                nr["Tag"] = Cell(row, "ITEM_TAG_");
                nr["Size"] = Cell(row, "ITEM_SIZE");
                nr["Qty raw"] = raw.ToString("0.####", CultureInfo.InvariantCulture);
                nr["Unit"] = linear ? "in" : "ea";
                if (linear)
                    nr["BOM qty"] = (raw / 12.0).ToString("0.###", CultureInfo.InvariantCulture) + " ft";
                else
                    nr["BOM qty"] = raw.ToString("0.###", CultureInfo.InvariantCulture) + " ea";
                nr["Description"] = Cell(row, "ITEMDESC");
                view.Rows.Add(nr);
                n++;
            }

            _grid.DataSource = view;
            SetFill("Type", 50);
            SetFill("Code", 50);
            SetFill("Tag", 100);
            SetFill("Size", 50);
            SetFill("Qty raw", 50);
            SetFill("Unit", 25);
            SetFill("BOM qty", 100);
            SetFill("Description", 300);
            string mode = summary ? "summary" : "detail";
            string projBit = byProject ? " project " + project : " all projects";
            _status.Text = n + " " + mode + " row(s) for " + dwg + projBit
                + ". Linear qty is inches in the DB; BOM qty is feet. Fittings/equipment are each.";
            if (n == 0)
                _status.Text += " Run BOM to extract this drawing first.";
        }

        public static void ShowBom(bool summary)
        {
            using (MedShowBomForm form = new MedShowBomForm(summary))
            {
                form._loading = true;
                try { form.Reload(); }
                finally { form._loading = false; }
                AcadApp.ShowModalDialog(form);
            }
        }
    }
}