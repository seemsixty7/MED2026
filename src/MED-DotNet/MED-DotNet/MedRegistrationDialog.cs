using System;
using System.Windows.Forms;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public static partial class MedRegistration
    {
        static void Show()
        {
            if (_open != null && !_open.IsDisposed) { _open.Activate(); return; }
            var f = new Form
            {
                Text = "Register MED2026 (optional)", FormBorderStyle = FormBorderStyle.FixedDialog,
                MaximizeBox = false, MinimizeBox = false, StartPosition = FormStartPosition.CenterScreen,
                ClientSize = new System.Drawing.Size(420, 260), ShowInTaskbar = false
            };
            var intro = new Label { Left = 12, Top = 10, Width = 396, Height = 44,
                Text = "Registering is optional; MED works the same either way. Details go to Moore Design only. Privacy: " + MedAppStore.PrivacyUrl };
            var lName = new Label { Text = "Name", Left = 12, Top = 64, Width = 80 };
            var tName = new TextBox { Left = 100, Top = 60, Width = 306 };
            var lMail = new Label { Text = "Email", Left = 12, Top = 96, Width = 80 };
            var tMail = new TextBox { Left = 100, Top = 92, Width = 306 };
            var lCo = new Label { Text = "Company", Left = 12, Top = 128, Width = 80 };
            var tCo = new TextBox { Left = 100, Top = 124, Width = 306 };
            var cUpd = new CheckBox { Left = 100, Top = 158, Width = 306, Checked = false,
                Text = "Email me when MED updates are released" };
            var bReg = new Button { Text = "Register", Left = 226, Top = 216, Width = 86 };
            var bSkip = new Button { Text = "Skip", Left = 320, Top = 216, Width = 86 };
            f.Controls.AddRange(new Control[] { intro, lName, tName, lMail, tMail, lCo, tCo, cUpd, bReg, bSkip });
            f.AcceptButton = bReg; f.CancelButton = bSkip;
            bool decided = false;

            bReg.Click += (s, e) =>
            {
                try
                {
                    string mail = tMail.Text.Trim();
                    if (mail.Length < 3 || mail.IndexOf('@') < 1)
                    {
                        MessageBox.Show(f, "Please enter an email address, or click Skip.", "Register MED2026");
                        return;
                    }
                    decided = true;
                    WriteFlag(RegisteredFlag, mail);
                    Submit(tName.Text.Trim(), mail, tCo.Text.Trim(), cUpd.Checked, false);
                    Say("Thanks for registering MED2026.");
                    f.Close();
                }
                catch (System.Exception ex) { MedAppStore.LogStartup("registration submit", ex); }
            };
            bSkip.Click += (s, e) => f.Close();
            f.FormClosed += (s, e) =>
            {
                // Skip or the window X: don't ask again (MEDREGISTER still opens it)
                if (!decided) { WriteFlag(SkippedFlag, "skipped"); Say("Registration skipped. Run MEDREGISTER any time."); }
                _open = null;
            };
            _open = f;
            AcApp.ShowModelessDialog(f);
        }
    }
}
