using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Linq;
using System.Windows.Forms;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// DUCTBANK dialog bridge (MEDDuctbank.lsp):
    /// (MED-DuctbankDialogAvailable) -> T when the WinForms dialog can be shown (full AutoCAD UI).
    /// (MED-DuctbankDialog spec) -> edited spec text (ACTION=OK / CHECK / CANCEL), nil on failure.
    /// The spec is KEY=VALUE lines; see MedDuctbankForm.
    /// </summary>
    public class MedDuctbankLisp
    {
        [LispFunction("MED-DuctbankDialogAvailable")]
        public static ResultBuffer Available(ResultBuffer args)
        {
            return MedDebug.Lisp("MED-DuctbankDialogAvailable", () =>
            {
                bool ui = AppDomain.CurrentDomain.GetAssemblies().Any(a => string.Equals(a.GetName().Name, "acmgd", StringComparison.OrdinalIgnoreCase))
                          && Environment.UserInteractive;
                return ui ? new ResultBuffer(new TypedValue((int)LispDataType.T_atom)) : null;
            });
        }

        [LispFunction("MED-DuctbankDialog")]
        public static ResultBuffer Dialog(ResultBuffer args)
        {
            return MedDebug.Lisp("MED-DuctbankDialog", () =>
            {
                string spec = "";
                if (args != null)
                    foreach (TypedValue tv in args)
                        if (tv.TypeCode == (int)LispDataType.Text) { spec = (string)tv.Value; break; }
                using (var f = new MedDuctbankForm(spec))
                {
                    AcadApp.ShowModalDialog(f);
                    return new ResultBuffer(new TypedValue((int)LispDataType.Text, f.ResultSpec ?? "ACTION=CANCEL"));
                }
            });
        }
    }
}
