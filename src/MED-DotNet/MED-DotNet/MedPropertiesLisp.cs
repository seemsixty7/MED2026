using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using System;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// Lisp / command bridge for MEDProperties 3D identification XData + JSON sidecar.
    /// (MED-SetMedProperties ename objectType size description tag length [weight])
    /// (MED-UpsertMedPropertiesJson ename objectType size description tag length [weight])
    /// (MED-RebuildMedPropertiesJson)  — also command MEDREBUILDMEDPROPSJSON
    /// </summary>
    public class MedPropertiesLisp
    {
        [LispFunction("MED-SetMedProperties")]
        public static ResultBuffer SetMedProperties(ResultBuffer args)
        {
            if (args == null)
                return null;
            TypedValue[] arr = args.AsArray();
            if (arr == null || arr.Length < 6)
                return null;

            ObjectId id;
            if (!TryObjectId(arr[0], out id) || id.IsNull)
                return null;

            string objectType = AsText(arr, 1);
            string size = AsText(arr, 2);
            string description = AsText(arr, 3);
            string tag = AsText(arr, 4);
            string length = AsText(arr, 5);
            string weight = arr.Length > 6 ? AsText(arr, 6) : "";

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return null;

            Database db = doc.Database;
            using (DocumentLock dl = doc.LockDocument())
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                Entity ent = tr.GetObject(id, OpenMode.ForWrite, false) as Entity;
                if (ent == null)
                    return null;
                MedPropertiesXData.Set(ent, tr, objectType, size, description, tag, length, weight);
                tr.Commit();
            }
            return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
        }

        /// <summary>
        /// Upsert sidecar JSON only (entity already has XData, e.g. written by LISP).
        /// </summary>
        [LispFunction("MED-UpsertMedPropertiesJson")]
        public static ResultBuffer UpsertMedPropertiesJson(ResultBuffer args)
        {
            if (args == null)
                return null;
            TypedValue[] arr = args.AsArray();
            if (arr == null || arr.Length < 6)
                return null;

            ObjectId id;
            if (!TryObjectId(arr[0], out id) || id.IsNull)
                return null;

            string objectType = AsText(arr, 1);
            string size = AsText(arr, 2);
            string description = AsText(arr, 3);
            string tag = AsText(arr, 4);
            string length = AsText(arr, 5);
            string weight = arr.Length > 6 ? AsText(arr, 6) : "";

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return null;

            Database db = doc.Database;
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                Entity ent = tr.GetObject(id, OpenMode.ForRead, false) as Entity;
                if (ent == null)
                    return null;
                string handle = ent.Handle.ToString();
                MedPropertiesSidecar.Upsert(db, handle, objectType, size, description, tag, length, weight);
                tr.Commit();
            }
            return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
        }

        [LispFunction("MED-RebuildMedPropertiesJson")]
        public static ResultBuffer RebuildMedPropertiesJsonLisp(ResultBuffer args)
        {
            int n = RebuildCurrentDocument(true);
            return new ResultBuffer(new TypedValue((int)LispDataType.Int32, n));
        }

        [CommandMethod("MEDREBUILDMEDPROPSJSON")]
        public void RebuildMedPropertiesJsonCommand()
        {
            RebuildCurrentDocument(true);
        }

        /// <summary>Alias command name closer to the lisp symbol.</summary>
        [CommandMethod("MED-RebuildMedPropertiesJson")]
        public void RebuildMedPropertiesJsonCommandAlias()
        {
            RebuildCurrentDocument(true);
        }

        static int RebuildCurrentDocument(bool writeMessage)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return 0;
            Editor ed = doc.Editor;
            Database db = doc.Database;
            int count = 0;
            string path = null;
            try
            {
                using (DocumentLock dl = doc.LockDocument())
                using (Transaction tr = db.TransactionManager.StartTransaction())
                {
                    count = MedPropertiesSidecar.RebuildFromDatabase(db, tr);
                    path = MedPropertiesSidecar.PathFor(db);
                    tr.Commit();
                }
                if (writeMessage && ed != null)
                {
                    ed.WriteMessage(
                        "\nMEDProperties JSON rebuilt: {0} item(s) -> {1}",
                        count,
                        path ?? "(no DWG path — save drawing first)");
                }
            }
            catch (System.Exception ex)
            {
                if (writeMessage && ed != null)
                    ed.WriteMessage("\nMED-RebuildMedPropertiesJson failed: {0}", ex.Message);
            }
            return count;
        }

        [LispFunction("MED-GetMedProperties")]
        public static ResultBuffer GetMedProperties(ResultBuffer args)
        {
            if (args == null)
                return null;
            TypedValue[] arr = args.AsArray();
            if (arr == null || arr.Length < 1)
                return null;

            ObjectId id;
            if (!TryObjectId(arr[0], out id) || id.IsNull)
                return null;

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return null;

            Database db = doc.Database;
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                Entity ent = tr.GetObject(id, OpenMode.ForRead, false) as Entity;
                if (ent == null)
                    return null;
                var map = MedPropertiesXData.Get(ent);
                tr.Commit();

                ResultBuffer rb = new ResultBuffer();
                rb.Add(new TypedValue((int)LispDataType.ListBegin));
                foreach (string key in new[]
                {
                    MedPropertiesXData.KeyObjectType,
                    MedPropertiesXData.KeySize,
                    MedPropertiesXData.KeyDescription,
                    MedPropertiesXData.KeyTag,
                    MedPropertiesXData.KeyLength,
                    MedPropertiesXData.KeyWeight
                })
                {
                    string v;
                    if (!map.TryGetValue(key, out v))
                        v = "";
                    rb.Add(new TypedValue((int)LispDataType.Text, key + "=" + v));
                }
                rb.Add(new TypedValue((int)LispDataType.ListEnd));
                return rb;
            }
        }

        static bool TryObjectId(TypedValue tv, out ObjectId id)
        {
            id = ObjectId.Null;
            if (tv.Value is ObjectId)
            {
                id = (ObjectId)tv.Value;
                return true;
            }
            return false;
        }

        static string AsText(TypedValue[] arr, int index)
        {
            if (arr == null || index < 0 || index >= arr.Length || arr[index].Value == null)
                return "";
            if (arr[index].TypeCode == (int)LispDataType.Nil)
                return "";
            return Convert.ToString(arr[index].Value, System.Globalization.CultureInfo.InvariantCulture) ?? "";
        }
    }
}
