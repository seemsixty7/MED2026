using Autodesk.AutoCAD.ApplicationServices;
using System;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public static partial class MedRegistration
    {
        static string J(string v)
        {
            var sb = new StringBuilder("\"");
            foreach (char c in v ?? "")
            {
                if (c == '"' || c == '\\') sb.Append('\\').Append(c);
                else if (c < ' ') sb.Append("\\u").Append(((int)c).ToString("x4"));
                else sb.Append(c);
            }
            return sb.Append('"').ToString();
        }

        /// <summary>JSON body for the med-register function (same endpoint as Setup). test=true prefixes the name with "TEST - ".</summary>
        public static string BuildBody(string name, string email, string company, bool wantUpdates, bool test, string ver)
        {
            return "{\"name\":" + J(test ? "TEST - " + name : name)
                + ",\"email\":" + J(email)
                + ",\"company\":" + J(company)
                + ",\"want_updates\":" + (wantUpdates ? "true" : "false")
                + ",\"install_type\":\"appstore\""
                + ",\"channel\":\"appstore\""
                + ",\"version\":" + J(ver)
                + ",\"timestamp\":" + J(DateTime.UtcNow.ToString("o"))
                + "}";
        }

        /// <summary>Background POST; any failure (offline, timeout, HTTP error) is only logged.</summary>
        public static Task Submit(string name, string email, string company, bool wantUpdates, bool test)
        {
            string ver = Assembly.GetExecutingAssembly().GetName().Version.ToString();
            byte[] body = Encoding.UTF8.GetBytes(BuildBody(name, email, company, wantUpdates, test, ver));
            return Task.Run(() =>
            {
                try
                {
                    ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
                    var req = (HttpWebRequest)WebRequest.Create(FormUrl);
                    req.Method = "POST";
                    req.ContentType = "application/json";
                    req.Timeout = 15000;
                    req.AllowAutoRedirect = false;
                    req.UserAgent = "MED2026/" + ver + " (AutoCAD App Store bundle)";
                    using (var rs = req.GetRequestStream()) rs.Write(body, 0, body.Length);
                    using (var resp = (HttpWebResponse)req.GetResponse())
                        Log("posted: HTTP " + (int)resp.StatusCode);
                }
                catch (System.Exception ex) { Log("post failed (ignored): " + ex.Message); }
            });
        }

        static void WriteFlag(string path, string text)
        {
            try { Directory.CreateDirectory(MedAppStore.UserRoot); File.WriteAllText(path, DateTime.Now.ToString("s") + " " + text + Environment.NewLine); }
            catch (System.Exception ex) { MedAppStore.LogStartup("registration flag", ex); }
        }

        static void Log(string msg)
        {
            try
            {
                Directory.CreateDirectory(MedAppStore.UserRoot);
                File.AppendAllText(Path.Combine(MedAppStore.UserRoot, "MED-startup.log"),
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " [registration] " + msg + Environment.NewLine);
            }
            catch { }
        }

        static void Say(string msg)
        {
            try { Document d = AcApp.DocumentManager.MdiActiveDocument; if (d != null) d.Editor.WriteMessage("\n" + msg); }
            catch { }
        }
    }
}
