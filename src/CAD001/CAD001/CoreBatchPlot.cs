using System;
using System.Collections;
using System.Windows.Forms;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

namespace CAD001
{
    public partial class CoreBatchPlot : Form
    {
        //string[] fileList = new string[] { "", "" };
        //ArrayList fileList = new ArrayList();
        string PDfOutPutFolder = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments).ToString();
        int BatchRun = 0;
        public CoreBatchPlot()
        {
            InitializeComponent();
            Document doc = Autodesk.AutoCAD.ApplicationServices.Application.DocumentManager.MdiActiveDocument;
            if (doc.GetLispSymbol("CORE_PDFOUTPUTFOLDER") != null)
            {
                PDfOutPutFolder = doc.GetLispSymbol("CORE_PDFOUTPUTFOLDER").ToString();
            }
            comboPrinter.Items.Add("LDIS PDF.pc3");
            comboPrinter.Items.Add("LDIS PDF-NoShow.pc3");


            textBox1.Text = PDfOutPutFolder;
            openFileDialog1.Filter = "Drawings(*.dwg)|*.dwg";
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if(openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                int i = 0;
                foreach (string filename in openFileDialog1.FileNames)
                {
                    listBox1.Items.Add(filename);
                    //fileList.Add(filename.ToString());
                    i++;
                }
            }
        }

        private void plotFilesBtn_Click(object sender, EventArgs e)
        {
            //Here we set the autolisp variable of the results and close the dialog box. Lisp will launch the Script file
            Document doc = Autodesk.AutoCAD.ApplicationServices.Application.DocumentManager.MdiActiveDocument;
            ResultBuffer rb = new ResultBuffer();
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.ListBegin)));
            foreach (var filename in listBox1.Items)
            {
                rb.Add(new TypedValue(Convert.ToInt32(LispDataType.Text),filename));
            }
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.ListEnd)));
            doc.SetLispSymbol("CORE_BATCHFILELIST", rb.AsArray());

            CoreBatchPlot.ActiveForm.Close();
            BatchRun = 1;
        }

        private void cancelBtn_Click(object sender, EventArgs e)
        {
            Document doc = Autodesk.AutoCAD.ApplicationServices.Application.DocumentManager.MdiActiveDocument;
            doc.SetLispSymbol("CORE_BATCHFILELIST", new TypedValue(Convert.ToInt32(LispDataType.Nil)));
            CoreBatchPlot.ActiveForm.Close();
            //here we nil out the autolisp variable just close the dialog.
        }

        private void button1_Click_1(object sender, EventArgs e)
        {
            if (folderBrowserDialog1.ShowDialog() == DialogResult.OK)
            {
                PDfOutPutFolder = folderBrowserDialog1.SelectedPath.ToString();
                textBox1.Text = PDfOutPutFolder;


            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            //ListBox.SelectedObjectCollection selectedItems = new ListBox.SelectedObjectCollection.(listBox1);
            //selectedItems = listBox1.SelectedItems;
            if(listBox1.SelectedIndex != -1)
            {
                for( int i = listBox1.SelectedIndices.Count -1; i >= 0; i--)
                    //listBox1.Items.RemoveAt(selectedItems[i]);
                    listBox1.Items.RemoveAt(listBox1.SelectedIndices[i]);
                    //listBox1.Items.re

            }
            
            listBox1.Refresh();

        }

        private void comboPrinter_SelectedIndexChanged(object sender, EventArgs e)
        {
            //Do nothing
        }
    }
}
