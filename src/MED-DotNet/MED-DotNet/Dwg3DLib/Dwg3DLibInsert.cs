using System;
using System.IO;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

namespace MEDDotNet
{
    /// <summary>Inserts a library DWG as a block (Database.ReadDwgFile + Database.Insert) and places a reference.</summary>
    public static class Dwg3DLibInsert
    {
        public static string BlockNameFor(string dwgPath)
        {
            string n = Path.GetFileNameWithoutExtension(dwgPath) ?? "Block";
            try { n = SymbolUtilityServices.RepairSymbolName(n, false); } catch { }
            return n;
        }

        /// <summary>Returns the block definition id in db; imports the DWG if the block name does not exist yet (existing definitions are reused, like INSERT).</summary>
        public static ObjectId ImportBlock(Database db, string dwgPath, out string blockName, out bool existed)
        {
            blockName = BlockNameFor(dwgPath);
            existed = false;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (bt.Has(blockName))
                {
                    existed = true;
                    ObjectId id = bt[blockName];
                    tr.Commit();
                    return id;
                }
                tr.Commit();
            }
            using (var side = new Database(false, true))
            {
                side.ReadDwgFile(dwgPath, FileShare.Read, true, "");
                side.CloseInput(true);
                return db.Insert(blockName, side, true);
            }
        }

        /// <summary>Adds a BlockReference (scale 1) at posWcs, rotated about the UCS Z axis, into the current space. Adds attributes.</summary>
        public static ObjectId AddReference(Database db, ObjectId btrId, Point3d posWcs, double rotation, Matrix3d ucs)
        {
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var space = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
                var br = CreateReference(db, btrId, ucs, rotation);
                br.Position = posWcs;
                ObjectId id = space.AppendEntity(br);
                tr.AddNewlyCreatedDBObject(br, true);
                AddAttributes(tr, br, btrId);
                tr.Commit();
                return id;
            }
        }

        internal static BlockReference CreateReference(Database db, ObjectId btrId, Matrix3d ucs, double rotation)
        {
            var br = new BlockReference(Point3d.Origin, btrId);
            br.SetDatabaseDefaults(db);
            br.TransformBy(Matrix3d.Rotation(rotation, Vector3d.ZAxis, Point3d.Origin));
            br.TransformBy(ucs);
            return br;
        }

        static void AddAttributes(Transaction tr, BlockReference br, ObjectId btrId)
        {
            var btr = (BlockTableRecord)tr.GetObject(btrId, OpenMode.ForRead);
            if (!btr.HasAttributeDefinitions) return;
            foreach (ObjectId id in btr)
            {
                var ad = tr.GetObject(id, OpenMode.ForRead) as AttributeDefinition;
                if (ad == null || ad.Constant) continue;
                var ar = new AttributeReference();
                ar.SetAttributeFromBlock(ad, br.BlockTransform);
                ar.TextString = ad.TextString;
                br.AttributeCollection.AppendAttribute(ar);
                tr.AddNewlyCreatedDBObject(ar, true);
            }
        }

        /// <summary>Interactive insert: import, jig for the insertion point, optional rotation prompt. Call from a command (document is locked).</summary>
        public static bool InsertInteractive(Document doc, string dwgPath)
        {
            Editor ed = doc.Editor;
            Database db = doc.Database;
            if (!File.Exists(dwgPath)) { ed.WriteMessage("\nMED3DLIB: file not found: " + dwgPath); return false; }
            if (string.Equals(Path.GetFullPath(dwgPath), Path.GetFullPath(db.Filename ?? "x:\\none"), StringComparison.OrdinalIgnoreCase))
            { ed.WriteMessage("\nMED3DLIB: cannot insert a drawing into itself."); return false; }

            string name; bool existed;
            ObjectId btrId = ImportBlock(db, dwgPath, out name, out existed);
            ed.WriteMessage("\nMED3DLIB: block \"" + name + "\"" + (existed ? " (existing definition reused)" : " imported") + ".");

            Matrix3d ucs = ed.CurrentUserCoordinateSystem;
            using (var br = CreateReference(db, btrId, ucs, 0.0))
            {
                var jig = new InsertJig(br, name);
                PromptResult pr = ed.Drag(jig);
                if (pr.Status != PromptStatus.OK) { ed.WriteMessage("\nMED3DLIB: cancelled."); return false; }
                Point3d pos = jig.Position;

                double rot = 0.0;
                var po = new PromptAngleOptions("\nRotation angle <0>: ");
                po.AllowNone = true;
                po.UseBasePoint = true;
                po.BasePoint = pos.TransformBy(ucs.Inverse());
                po.UseDashedLine = true;
                PromptDoubleResult ar = ed.GetAngle(po);
                if (ar.Status == PromptStatus.Cancel) { ed.WriteMessage("\nMED3DLIB: cancelled."); return false; }
                if (ar.Status == PromptStatus.OK) rot = ar.Value;

                AddReference(db, btrId, pos, rot, ucs);
            }
            ed.WriteMessage("\nMED3DLIB: inserted " + name + ".");
            return true;
        }

        sealed class InsertJig : EntityJig
        {
            Point3d _pos;
            readonly string _name;
            public Point3d Position { get { return _pos; } }

            public InsertJig(BlockReference br, string name) : base(br) { _name = name; _pos = br.Position; }

            protected override SamplerStatus Sampler(JigPrompts prompts)
            {
                var o = new JigPromptPointOptions("\nInsertion point for " + _name + ": ");
                o.UserInputControls = UserInputControls.Accept3dCoordinates | UserInputControls.NoZeroResponseAccepted | UserInputControls.NoNegativeResponseAccepted;
                PromptPointResult r = prompts.AcquirePoint(o);
                if (r.Status != PromptStatus.OK) return SamplerStatus.Cancel;
                if (r.Value.DistanceTo(_pos) < 1e-9) return SamplerStatus.NoChange;
                _pos = r.Value;
                return SamplerStatus.OK;
            }

            protected override bool Update()
            {
                ((BlockReference)Entity).Position = _pos;
                return true;
            }
        }
    }
}
