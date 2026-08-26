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
                doc.Editor.WriteMessage("\nMED-DotNet loaded. CABLE / CABLEPALETTE for cables, MEDCHG / MEDPROPERTIES for entity xdata, MEDSETTINGS for defaults, MEDCHG-CLASSIC for the old DCL, ProcessSQLStatementNET for SQL.");
        }

        public void Terminate()
        {
        }

        [LispFunction("ProcessSQLStatementNET")]
        public static ResultBuffer ProcessSQLStatementNet(ResultBuffer resbufin)
        {
            return ProcessSQL.ProcessSQLStatementNet(resbufin);
        }
    }
}
