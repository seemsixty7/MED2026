using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using Autodesk.Navisworks.Api;
using Autodesk.Navisworks.Api.DocumentParts;

namespace MEDNavisworks
{
    /// <summary>
    /// Dockable pane content: shows MEDProperties fields for the current selection.
    /// </summary>
    public class MEDPropertiesControl : UserControl
    {
        readonly Label _status;
        readonly TextBox _objectType;
        readonly TextBox _size;
        readonly TextBox _description;
        readonly TextBox _tag;
        readonly TextBox _length;
        readonly TextBox _weight;
        readonly TextBox _source;
        readonly TextBox _dump;
        readonly Button _btnRefresh;
        readonly Button _btnDump;
        readonly Button _btnAttachDemo;
        readonly Button _btnLoadJson;
        Document _subscribedDoc;
        bool _busy;

        public MEDPropertiesControl()
        {
            SuspendLayout();
            AutoScroll = true;
            BackColor = SystemColors.Window;
            Padding = new Padding(8);
            Font = new Font("Segoe UI", 9F);

            _status = new Label
            {
                AutoSize = false,
                Height = 36,
                Dock = DockStyle.Top,
                Text = "Select a model itemâ€¦",
                Padding = new Padding(0, 4, 0, 4)
            };

            TableLayoutPanel grid = new TableLayoutPanel
            {
                ColumnCount = 2,
                RowCount = 7,
                Dock = DockStyle.Top,
                AutoSize = true,
                Padding = new Padding(0, 4, 0, 4)
            };
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100));
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));

            _objectType = AddRow(grid, 0, "ObjectType");
            _size = AddRow(grid, 1, "Size");
            _description = AddRow(grid, 2, "Description");
            _tag = AddRow(grid, 3, "Tag");
            _length = AddRow(grid, 4, "Length");
            _weight = AddRow(grid, 5, "Weight");

            _source = new TextBox
            {
                Dock = DockStyle.Fill,
                Multiline = true,
                ReadOnly = true,
                Height = 48,
                ScrollBars = ScrollBars.Vertical,
                BorderStyle = BorderStyle.FixedSingle
            };
            grid.Controls.Add(new Label { Text = "Source", AutoSize = true, Anchor = AnchorStyles.Left }, 0, 6);
            grid.Controls.Add(_source, 1, 6);

            FlowLayoutPanel buttons = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                WrapContents = true,
                Padding = new Padding(0, 4, 0, 4)
            };
            _btnRefresh = new Button { Text = "Refresh", AutoSize = true };
            _btnDump = new Button { Text = "Dump categories", AutoSize = true };
            _btnAttachDemo = new Button { Text = "Attach demo User props", AutoSize = true };
            _btnLoadJson = new Button { Text = "Load MEDProperties JSON", AutoSize = true };
            _btnRefresh.Click += (s, e) => RefreshFromSelection();
            _btnDump.Click += (s, e) => DumpSelection();
            _btnAttachDemo.Click += (s, e) => AttachDemo();
            _btnLoadJson.Click += (s, e) => LoadMedPropsJson();
            buttons.Controls.Add(_btnRefresh);
            buttons.Controls.Add(_btnDump);
            buttons.Controls.Add(_btnAttachDemo);
            buttons.Controls.Add(_btnLoadJson);

            _dump = new TextBox
            {
                Dock = DockStyle.Fill,
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Both,
                Font = new Font("Consolas", 8.25F),
                WordWrap = false
            };

            Controls.Add(_dump);
            Controls.Add(buttons);
            Controls.Add(grid);
            Controls.Add(_status);
            ResumeLayout(false);
        }

        static TextBox AddRow(TableLayoutPanel grid, int row, string label)
        {
            Label lab = new Label
            {
                Text = label,
                AutoSize = true,
                Anchor = AnchorStyles.Left
            };
            TextBox box = new TextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BorderStyle = BorderStyle.FixedSingle
            };
            grid.Controls.Add(lab, 0, row);
            grid.Controls.Add(box, 1, row);
            return box;
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            HookDocument(Autodesk.Navisworks.Api.Application.ActiveDocument);
            Autodesk.Navisworks.Api.Application.ActiveDocumentChanged += OnActiveDocumentChanged;
            RefreshFromSelection();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                Autodesk.Navisworks.Api.Application.ActiveDocumentChanged -= OnActiveDocumentChanged;
                UnhookDocument();
            }
            base.Dispose(disposing);
        }

        void OnActiveDocumentChanged(object sender, EventArgs e)
        {
            HookDocument(Autodesk.Navisworks.Api.Application.ActiveDocument);
            RefreshFromSelection();
        }

        void HookDocument(Document doc)
        {
            UnhookDocument();
            _subscribedDoc = doc;
            if (_subscribedDoc != null)
                _subscribedDoc.CurrentSelection.Changed += OnSelectionChanged;
        }

        void UnhookDocument()
        {
            if (_subscribedDoc != null)
            {
                try { _subscribedDoc.CurrentSelection.Changed -= OnSelectionChanged; }
                catch { }
                _subscribedDoc = null;
            }
        }

        void OnSelectionChanged(object sender, EventArgs e)
        {
            RefreshFromSelection();
        }

        void RefreshFromSelection()
        {
            if (_busy || IsDisposed)
                return;
            _busy = true;
            try
            {
                Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
                if (doc == null)
                {
                    ClearFields("No active document.");
                    return;
                }

                ModelItemCollection sel = doc.CurrentSelection.SelectedItems;
                if (sel == null || sel.Count == 0)
                {
                    ClearFields("Nothing selected.");
                    return;
                }

                ModelItem item = FirstGeometryOrSelf(sel[0]);
                MedPropertyReader.Result r = MedPropertyReader.Read(item);
                _objectType.Text = Get(r, MedPropertyKeys.ObjectType);
                _size.Text = Get(r, MedPropertyKeys.Size);
                _description.Text = Get(r, MedPropertyKeys.Description);
                _tag.Text = Get(r, MedPropertyKeys.Tag);
                _length.Text = Get(r, MedPropertyKeys.Length);
                _weight.Text = Get(r, MedPropertyKeys.Weight);
                _source.Text = r.SourceNote ?? "";
                _status.Text = r.HasAnyMedField
                    ? "MEDProperties found (" + sel.Count + " selected; showing first)."
                    : "No MED fields on selection (" + sel.Count + " selected).";
            }
            catch (Exception ex)
            {
                _status.Text = "Error: " + ex.Message;
            }
            finally
            {
                _busy = false;
            }
        }

        void DumpSelection()
        {
            try
            {
                Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
                if (doc == null || doc.CurrentSelection.SelectedItems.Count == 0)
                {
                    _dump.Text = "(nothing selected)";
                    return;
                }
                ModelItem item = FirstGeometryOrSelf(doc.CurrentSelection.SelectedItems[0]);
                _dump.Text = MedPropertyReader.DumpCategories(item);
            }
            catch (Exception ex)
            {
                _dump.Text = ex.ToString();
            }
        }

        void AttachDemo()
        {
            try
            {
                Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
                if (doc == null || doc.CurrentSelection.SelectedItems.Count == 0)
                {
                    MessageBox.Show(this, "Select a ModelItem first.", "MED Properties");
                    return;
                }
                ModelItem item = FirstGeometryOrSelf(doc.CurrentSelection.SelectedItems[0]);
                Dictionary<string, string> demo = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    { MedPropertyKeys.ObjectType, "TRAY" },
                    { MedPropertyKeys.Size, "24" },
                    { MedPropertyKeys.Description, "Demo MEDProperties (User bridge)" },
                    { MedPropertyKeys.Tag, "DEMO-001" },
                    { MedPropertyKeys.Length, "10" },
                    { MedPropertyKeys.Weight, "100" }
                };
                string err;
                if (!UserPropertyBridge.AttachMedProperties(item, demo, out err))
                {
                    MessageBox.Show(this, "Attach failed: " + err, "MED Properties");
                    return;
                }
                _status.Text = "Attached demo MEDProperties via COM UserDefined.";
                RefreshFromSelection();
                DumpSelection();
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, ex.ToString(), "MED Properties");
            }
        }

        void LoadMedPropsJson()
        {
            try
            {
                Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
                if (doc == null)
                {
                    MessageBox.Show(this, "No active document.", "MED Properties");
                    return;
                }

                string chosen = null;
                foreach (string path in MedPropsJsonLoader.CandidateJsonPaths(doc))
                {
                    if (System.IO.File.Exists(path))
                    {
                        chosen = path;
                        break;
                    }
                }

                if (chosen == null)
                {
                    using (OpenFileDialog ofd = new OpenFileDialog())
                    {
                        ofd.Filter = "MEDProperties JSON (*.medprops.json)|*.medprops.json|JSON (*.json)|*.json|All files (*.*)|*.*";
                        ofd.Title = "Select MEDProperties JSON sidecar";
                        if (ofd.ShowDialog(this) != DialogResult.OK)
                            return;
                        chosen = ofd.FileName;
                    }
                }

                MedPropsJsonLoader.ApplyResult r = MedPropsJsonLoader.ApplyFile(doc, chosen);
                _status.Text = r.Message ?? "";
                _dump.Text = r.Message + Environment.NewLine + "Path: " + (r.JsonPath ?? "");
                MessageBox.Show(
                    this,
                    (r.Message ?? "(no message)") + Environment.NewLine + Environment.NewLine +
                    "Path: " + (r.JsonPath ?? "(none)"),
                    "MED Properties — Load JSON",
                    MessageBoxButtons.OK,
                    (r.Matched > 0 && r.Failed == 0) ? MessageBoxIcon.Information : MessageBoxIcon.Warning);
                RefreshFromSelection();
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, ex.ToString(), "MED Properties");
            }
        }
        static ModelItem FirstGeometryOrSelf(ModelItem item)
        {
            if (item == null)
                return null;
            // Prefer a leaf with geometry if the selection is a group.
            if (item.HasGeometry)
                return item;
            foreach (ModelItem d in item.DescendantsAndSelf)
            {
                if (d.HasGeometry)
                    return d;
            }
            return item;
        }

        static string Get(MedPropertyReader.Result r, string key)
        {
            string v;
            if (r != null && r.Values != null && r.Values.TryGetValue(key, out v))
                return v ?? "";
            return "";
        }

        void ClearFields(string status)
        {
            _status.Text = status;
            _objectType.Text = "";
            _size.Text = "";
            _description.Text = "";
            _tag.Text = "";
            _length.Text = "";
            _weight.Text = "";
            _source.Text = "";
        }
    }
}



