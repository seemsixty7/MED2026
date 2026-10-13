using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// Optional registration (App Store bundle). Shown once, modeless; MEDREGISTER reopens it.
    /// Posts to the mooredesign.net Netlify form "med-leads". Never blocks MED: network errors are
    /// only logged to MED-startup.log. Flags: %APPDATA%\MooreDesign\MED2026\Registered.flag / RegisterSkipped.flag.
    /// </summary>
    public static partial class MedRegistration
    {
        // Same endpoint as Setup/Patch (installer/Register-MEDInstall.ps1); install_type tells them apart.
        const string FormUrl = "https://mooredesign.net/.netlify/functions/med-register";
        static string RegisteredFlag { get { return Path.Combine(MedAppStore.UserRoot, "Registered.flag"); } }
        static string SkippedFlag { get { return Path.Combine(MedAppStore.UserRoot, "RegisterSkipped.flag"); } }
        static Form _open;

        public static void StartupPrompt()
        {
            try
            {
                if (!MedAppStore.IsBundle) return;
                if (File.Exists(RegisteredFlag) || File.Exists(SkippedFlag)) return;
                AcApp.Idle += OnIdleOnce;
            }
            catch (System.Exception ex) { MedAppStore.LogStartup("registration startup", ex); }
        }

        static void OnIdleOnce(object sender, EventArgs e)
        {
            try { AcApp.Idle -= OnIdleOnce; Show(); }
            catch (System.Exception ex) { MedAppStore.LogStartup("registration dialog", ex); }
        }

        [CommandMethod("MEDREGISTER")]
        public static void Command()
        {
            try { Show(); }
            catch (System.Exception ex) { MedAppStore.LogStartup("MEDREGISTER", ex); }
        }
    }
}
