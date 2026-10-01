using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(MEDDotNet.MED3DLibApp))]

namespace MEDDotNet
{
    /// <summary>Standalone MED3DLib.dll entry point (same Dwg3DLib sources as MED-DotNet). Do not NETLOAD together with a MED-DotNet.dll that already has MED3DLIB.</summary>
    public class MED3DLibApp : IExtensionApplication
    {
        public void Initialize()
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            if (doc != null)
                doc.Editor.WriteMessage("\nMED3DLib loaded. MED3DLIB opens the 3D block library palette, MED3DLIBINSERT inserts a library DWG, MED3DLIBTEST runs a self test.\n");
        }

        public void Terminate() { }
    }
}
