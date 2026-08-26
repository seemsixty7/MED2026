using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
using System;
using System.Drawing;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public class MedCableCommands
    {
        [CommandMethod("CABLEPALETTE")]
        public void ShowCablePalette()
        {
            MedCablePalette.Show();
        }

        [CommandMethod("CABLESET")]
        public void ShowCableSet()
        {
            MedCablePalette.Show();
        }

        [CommandMethod("CABLE")]
        public void Cable()
        {
            MedCablePalette.RunCable();
        }

        [LispFunction("MED-CableApplyLayer")]
        public static ResultBuffer CableApplyLayer(ResultBuffer unused)
        {
            MedCablePalette.ApplyLayerFromCabCode();
            return null;
        }
    }

    internal static class MedCableLayers
    {
        public static string LayerName(string group)
        {
            if (string.IsNullOrEmpty(group))
                return null;
            return "MEDCable-" + group.Replace(" ", "");
        }

        public static void EnsureAndSetCurrent(string group)
        {
            string name = LayerName(group);
            if (string.IsNullOrEmpty(name))
                return;
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;
            Database db = doc.Database;
            DocumentLock dl = null;
            try
            {
                dl = doc.LockDocument();
                using (Transaction tr = db.TransactionManager.StartTransaction())
                {
                    LayerTable lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
                    ObjectId id;
                    if (!lt.Has(name))
                    {
                        lt.UpgradeOpen();
                        LayerTableRecord ltr = new LayerTableRecord();
                        ltr.Name = name;
                        id = lt.Add(ltr);
                        tr.AddNewlyCreatedDBObject(ltr, true);
                    }
                    else
                    {
                        id = lt[name];
                    }
                    db.Clayer = id;
                    tr.Commit();
                }
            }
            catch (System.Exception)
            {
            }
            finally
            {
                if (dl != null)
                    dl.Dispose();
            }
        }
    }

    internal static class MedCablePalette
    {
        static readonly Guid PaletteGuid = new Guid("E4A71B09-6C2D-4F8A-9B3E-1D5C7A8E4F20");
        static PaletteSet _ps;
        static MedCableControl _ctl;

        public static void Show()
        {
            Ensure();
            _ps.Visible = true;
            RefreshFromLisp(false);
        }

        public static void Ensure()
        {
            if (_ps != null)
                return;

            _ctl = new MedCableControl();
            _ps = new PaletteSet("MED Cable", "CABLEPALETTE", PaletteGuid);
            _ps.Style = PaletteSetStyles.ShowAutoHideButton
                      | PaletteSetStyles.ShowCloseButton
                      | PaletteSetStyles.ShowPropertiesMenu
                      | PaletteSetStyles.Snappable;
            _ps.MinimumSize = new Size(240, 200);
            _ps.Size = new Size(300, 260);
            _ps.DockEnabled = DockSides.Left | DockSides.Right;
            _ps.Add("Cable", _ctl);
            _ps.KeepFocus = false;
            _ps.StateChanged += PaletteStateChanged;

            AcadApp.DocumentManager.DocumentActivated += OnDocumentActivated;
        }

        static void PaletteStateChanged(object sender, PaletteSetStateEventArgs e)
        {
            if (e.NewState == StateEventIndex.Show)
                RefreshFromLisp(false);
        }

        static void OnDocumentActivated(object sender, DocumentCollectionEventArgs e)
        {
            RefreshFromLisp(false);
        }

        static void RefreshFromLisp(bool synchronous)
        {
            if (_ctl == null || _ps == null || !_ps.Visible)
                return;

            MedLisp.Run(delegate
            {
                try
                {
                    Action apply = delegate
                    {
                        try { _ctl.LoadFromLisp(); }
                        catch (System.Exception) { }
                    };
                    if (_ctl.IsHandleCreated && _ctl.InvokeRequired)
                    {
                        if (synchronous)
                            _ctl.Invoke(apply);
                        else
                            _ctl.BeginInvoke(apply);
                    }
                    else
                        apply();
                }
                catch (System.Exception)
                {
                }
            });
        }

        static void LoadSync()
        {
            if (_ctl == null)
                return;
            try
            {
                Action apply = delegate
                {
                    try { _ctl.LoadFromLisp(); }
                    catch (System.Exception) { }
                };
                if (_ctl.IsHandleCreated && _ctl.InvokeRequired)
                    _ctl.Invoke(apply);
                else
                    apply();
            }
            catch (System.Exception)
            {
            }
        }

        public static void ApplyLayerFromCabCode()
        {
            int code = MedLisp.GetInt("_CABCODE", 0);
            string group = MedTypeLookup.GroupForCableCode(code);
            if (!string.IsNullOrEmpty(group))
                MedCableLayers.EnsureAndSetCurrent(group);
        }

        public static void RunCable()
        {
            Ensure();
            _ps.Visible = true;
            LoadSync();

            int? code = null;
            string group = null;
            try
            {
                if (_ctl != null)
                {
                    if (_ctl.IsHandleCreated && _ctl.InvokeRequired)
                    {
                        _ctl.Invoke(new Action(delegate
                        {
                            code = _ctl.SelectedCode;
                            group = _ctl.SelectedGroup;
                        }));
                    }
                    else
                    {
                        code = _ctl.SelectedCode;
                        group = _ctl.SelectedGroup;
                    }
                }
            }
            catch (System.Exception)
            {
            }

            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (!code.HasValue || code.Value <= 0)
            {
                if (doc != null)
                    doc.Editor.WriteMessage("\nSelect a Cable Type and Cable on the Cable palette, then run CABLE again.");
                return;
            }

            MedLisp.SetInt("_CABCODE", code.Value);
            MedCableLayers.EnsureAndSetCurrent(group);
            if (doc != null)
                doc.SendStringToExecute("(med-cable-draw) ", true, false, false);
        }
    }
}
