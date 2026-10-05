using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(MEDDotNet.Plugin))]

namespace MEDDotNet
{
    public class Plugin : IExtensionApplication
    {
        public void Initialize()
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            if (doc != null)
                doc.Editor.WriteMessage("\nMED-DotNet loaded. CABLE / CABLEPALETTE for cables, MEDCHG / MEDPROPERTIES for entity xdata, MEDSETTINGS for defaults, MED3DLIB for the 3D block library, MEDCHG-CLASSIC for the old DCL, ProcessSQLStatementNET for SQL, MEDDEBUG for debug mode"
                    + (MedDebug.Enabled ? " (debug is " + MedDebug.Level + ", log " + MedDebug.LogPath + ")." : "."));
            MedDebug.Startup();

            // Idempotent MEDUsers.LastProject migration + restore _MEDPROJECT from LastProject.
            try { MedUserProject.EnsureReady(true); }
            catch (System.Exception ex) { MedDebug.Warn("startup: MEDUsers.LastProject", ex); }

            // Idempotent OD data: MEDConduitOD table + CABLE USER3 (OD in) from Data\seed\*.csv.
            try { MedODSeed.EnsureReady(); }
            catch (System.Exception ex) { MedDebug.Warn("startup: OD seed", ex); }

            // MED ribbon: show MED Main + the current mode tab (default Plan); re-applied when the ribbon is (re)built.
            try { MedRibbonMode.Startup(); }
            catch (System.Exception ex) { MedDebug.Warn("startup: ribbon mode", ex); }
        }

        public void Terminate()
        {
        }

        [LispFunction("ProcessSQLStatementNET")]
        public static ResultBuffer ProcessSQLStatementNet(ResultBuffer resbufin)
        {
            return MedDebug.Lisp("ProcessSQLStatementNET", () => ProcessSQL.ProcessSQLStatementNet(resbufin));
        }
    }
}
