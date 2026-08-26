using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
using System;
using System.Drawing;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public class MedSettingsCommands
    {
        [CommandMethod("MEDSETTINGS")]
        public void ShowMedSettings()
        {
            MedSettingsPalette.Show();
        }

        [CommandMethod("MEDSET")]
        public void ShowMedSet()
        {
            MedSettingsPalette.Show();
        }
    }

    internal static class MedSettingsPalette
    {
        static readonly Guid PaletteGuid = new Guid("B8E1C4D2-7A53-4F19-9E80-3C5D2A1B6F44");
        static PaletteSet _ps;
        static MedSettingsControl _ctl;

        public static void Show()
        {
            Ensure();
            _ps.Visible = true;
            RefreshFromLisp();
        }

        public static void Ensure()
        {
            if (_ps != null)
                return;

            _ctl = new MedSettingsControl();
            _ps = new PaletteSet("MED Settings", "MEDSETTINGS", PaletteGuid);
            _ps.Style = PaletteSetStyles.ShowAutoHideButton
                      | PaletteSetStyles.ShowCloseButton
                      | PaletteSetStyles.ShowPropertiesMenu
                      | PaletteSetStyles.Snappable;
            _ps.MinimumSize = new Size(240, 360);
            _ps.Size = new Size(280, 520);
            _ps.DockEnabled = DockSides.Left | DockSides.Right;
            _ps.Add("Settings", _ctl);
            _ps.KeepFocus = false;
            _ps.StateChanged += PaletteStateChanged;

            AcadApp.DocumentManager.DocumentActivated += OnDocumentActivated;
        }

        static void PaletteStateChanged(object sender, PaletteSetStateEventArgs e)
        {
            if (e.NewState == StateEventIndex.Show)
                RefreshFromLisp();
        }

        static void OnDocumentActivated(object sender, DocumentCollectionEventArgs e)
        {
            RefreshFromLisp();
        }

        static void RefreshFromLisp()
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
                        _ctl.BeginInvoke(apply);
                    else
                        apply();
                }
                catch (System.Exception)
                {
                }
            });
        }
    }
}
