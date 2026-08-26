using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

using System;
using DataTable = System.Data.DataTable;
using System.Data;
using System.Data.SqlClient;




namespace CAD001
{
    public class DBLoadUtil
    {
        //Load all th eLine Objects into the database
        public string ListDwgs()
        {
            string result = "";
            SqlConnection conn = DBUtil.GetConnection();
            Document doc = Application.DocumentManager.MdiActiveDocument;
            Editor ed = doc.Editor;
            try
            {
                // get the document and editror object
                string sql = "Select TOP 100 FileName from Dwgs";
                SqlDataAdapter adapter = new SqlDataAdapter(sql, conn);
                DataTable dt = new DataTable();
                adapter.Fill(dt);

                

                if (dt.Rows.Count > 0)
                {
                    

                    ed.WriteMessage("Writing out " + dt.Rows.Count + " dwgs to screen");
                    foreach(DataRow dr in dt.Rows)
                    {
                        ed.WriteMessage("Filename: " + dr["FileName"]);
                    }


                }
                else
                {
                    ed.WriteMessage("No Rows");
                }

            }
            catch (Exception ex)
            {
                result = ex.Message;
                ed.WriteMessage(result);
            }
            finally
            {
                if(conn.State == ConnectionState.Open)
                {
                    conn.Close();
                }
            }
            return result;
        }
       

    }
}
