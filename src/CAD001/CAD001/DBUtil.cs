using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

using System;
using System.Data.SqlClient;


namespace CAD001
{
    public static class DBUtil
    {
        [CommandMethod("DwgList")]
        public static void ShowDwgs()
        {
            DBLoadUtil listDwgs = new DBLoadUtil();
            string result = listDwgs.ListDwgs();

        }
        [CommandMethod("CoreBatchPlot")]
        public static void CoreBatchPlot()
        {
            CoreBatchPlot batchForm = new CoreBatchPlot();
            batchForm.ShowDialog();



        }
        public static SqlConnection GetConnection()
        {
            string connStr = Settings1.Default.connstr;
            SqlConnection conn = new SqlConnection(connStr);
            return conn;
        }
        [LispFunction ("MYTEST")]
        public static ResultBuffer QuickTest(ResultBuffer resbufin) // dont foreget that when usinga lisp routine you have to have a RB coming in
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            Editor ed = doc.Editor;

            doc.SetLispSymbol("T1Sting", "This is a test");
            doc.SetLispSymbol("T2Real", 3.0);
            doc.SetLispSymbol("T3Int", 1);
            ed.WriteMessage("\nAbout to start REsbuff");
            ResultBuffer rb = new ResultBuffer();
            ed.WriteMessage("\n.REsbuff CReated");
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.ListBegin)));
            ed.WriteMessage("\nListBegin");
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.Text), "Start of List"));
            ed.WriteMessage("\nAdded text");
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.Int32), 2));
            ed.WriteMessage("\nAddded Int");
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.Double), 2.0));
            ed.WriteMessage("\nAdded Double");
            rb.Add(new TypedValue(Convert.ToInt32(LispDataType.ListEnd)));
            ed.WriteMessage("\nAdded list End");
            // doc.SetLispSymbol("T4List",rb);


            return rb ;

        }
        [LispFunction("ProcessSQLStatementNET")]
        public static ResultBuffer ProcessSQLStatementNet(ResultBuffer resbufin)
        {
            ResultBuffer result = new ResultBuffer();
            if (resbufin != null)
            {

                string QueryToRun = resbufin.AsArray()[0].Value.ToString(); //resbufin.Value.ToString();// "Select top 10 * from DWGS";
                SqlConnection conn = GetConnection();
                Document doc = Application.DocumentManager.MdiActiveDocument;
                Editor ed = doc.Editor;
                try
                {
                    // get the document and editror object
                    SqlDataAdapter adapter = new SqlDataAdapter(QueryToRun, conn);
                    System.Data.DataTable dt = new System.Data.DataTable();
                    adapter.Fill(dt);

                    if (dt.Rows.Count > 0)
                    {
                        ed.WriteMessage("Query Resulted ins " + dt.Rows.Count + " Rows");
                        //Start the overall List
                        result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListBegin)));

                        //Start the List for the column names
                        result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListBegin)));
                        //Step through the column names and ad to resbuf
                        foreach (System.Data.DataColumn dc in dt.Columns)
                        {
                            result.Add(new TypedValue(Convert.ToInt32(LispDataType.Text), dc.ToString()));
                        }
                        //Close the Column Name list
                        result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListEnd)));


                        foreach (System.Data.DataRow dr in dt.Rows)
                        {
                            result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListBegin)));
                            //ed.WriteMessage("Filename: " + dr["FileName"]);
                            for (int i = 0; i < dt.Columns.Count; i++)
                            {
                                //ed.WriteMessage("\nDataTpe is:" + dr[i].GetType());
                                if (dr.IsNull(i)) // intersting way to check for null value using row and then column number rather than the actual item
                                {
                                    result.Add(new TypedValue(Convert.ToInt32(LispDataType.Nil)));
                                }
                                else if (dr[i] is Double)
                                {
                                    result.Add(new TypedValue(Convert.ToInt32(LispDataType.Double), dr[i]));
                                }
                                else if (dr[i] is Int32 || dr[i] is Int64)
                                {
                                    result.Add(new TypedValue(Convert.ToInt32(LispDataType.Int32), dr[i]));
                                }
                                else
                                {
                                    result.Add(new TypedValue(Convert.ToInt32(LispDataType.Text), dr[i].ToString()));
                                }
                            }
                            result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListEnd)));
                        }
                        result.Add(new TypedValue(Convert.ToInt32(LispDataType.ListEnd)));

                    }
                    else
                    {
                        ed.WriteMessage("No Rows");
                        result = null;
                    }

                }
                catch (System.Exception ex)
                {
                    ed.WriteMessage(ex.Message);
                    result = null;
                }
                finally
                {
                    if (conn.State == System.Data.ConnectionState.Open)
                    {
                        conn.Close();
                    }
                }
            }
            return result;
        }



    }
}
