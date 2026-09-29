using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using Microsoft.Win32;
using System;
using System.Data.Common;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    public enum MedDebugLevel
    {
        Off = 0,      // normal: one-line errors, errors logged
        Errors = 1,   // debug on: full error details on screen, debug notes logged
        Verbose = 2   // also SQL / row-count chatter on screen and in the log
    }

    /// <summary>
    /// Central debug switch + log for MED-DotNet (command MEDDEBUG, LISP (med-debug-p)).
    /// Level persists in HKCU\Software\MooreDesign\MED2026\DebugLevel (no admin).
    /// Log: %LOCALAPPDATA%\MED2026\logs\med-YYYYMMDD.log (errors always, notes when on), 7 days kept.
    /// </summary>
    public static class MedDebug
    {
        public const string RegistryPath = @"Software\MooreDesign\MED2026";
        public const string RegistryValue = "DebugLevel";
        const int KeepDays = 7;

        static readonly object Gate = new object();
        static MedDebugLevel _level = MedDebugLevel.Off;
        static bool _loaded;
        static bool _pruned;
        static bool _hinted;

        public static MedDebugLevel Level
        {
            get { EnsureLoaded(); return _level; }
        }

        public static bool Enabled { get { return Level >= MedDebugLevel.Errors; } }
        public static bool IsVerbose { get { return Level >= MedDebugLevel.Verbose; } }

        public static string LogDirectory
        {
            get
            {
                string root = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                return Path.Combine(root, "MED2026", "logs");
            }
        }

        public static string LogPath
        {
            get { return Path.Combine(LogDirectory, "med-" + DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture) + ".log"); }
        }

        static void EnsureLoaded()
        {
            if (_loaded)
                return;
            _loaded = true;
            try
            {
                using (Microsoft.Win32.RegistryKey k = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(RegistryPath))
                {
                    object v = k != null ? k.GetValue(RegistryValue) : null;
                    MedDebugLevel parsed;
                    if (v != null && Enum.TryParse(v.ToString(), true, out parsed))
                        _level = parsed;
                }
            }
            catch (System.Exception)
            {
                _level = MedDebugLevel.Off;
            }
        }

        public static void SetLevel(MedDebugLevel level)
        {
            EnsureLoaded();
            _level = level;
            try
            {
                using (Microsoft.Win32.RegistryKey k = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(RegistryPath))
                {
                    if (k != null)
                        k.SetValue(RegistryValue, level.ToString(), Microsoft.Win32.RegistryValueKind.String);
                }
            }
            catch (System.Exception ex)
            {
                Log("WARN", "could not save debug level to HKCU\\" + RegistryPath + ": " + ex.Message);
            }
            Log("INFO", "debug level set to " + level);
        }

        // ------------------------------------------------------------------ output
        static Editor Ed()
        {
            try
            {
                Document doc = AcadApp.DocumentManager.MdiActiveDocument;
                return doc != null ? doc.Editor : null;
            }
            catch (System.Exception)
            {
                return null;
            }
        }

        public static void Write(string text)
        {
            try
            {
                Editor ed = Ed();
                if (ed != null)
                    ed.WriteMessage(text);
            }
            catch (System.Exception)
            {
            }
        }

        /// <summary>Verbose-only chatter (screen + log).</summary>
        public static void Verbose(string text)
        {
            if (!IsVerbose)
                return;
            Write("\nMED-DotNet: " + text);
            Log("VERBOSE", text);
        }

        /// <summary>Debug note: logged when debug is on, shown on screen only in Verbose.</summary>
        public static void Note(string text)
        {
            if (!Enabled)
                return;
            Log("DEBUG", text);
            if (IsVerbose)
                Write("\nMED-DotNet: " + text);
        }

        /// <summary>
        /// Report an error: always a one-liner on screen (full details when debug is on),
        /// always the full details in the log. Returns the one-line text.
        /// </summary>
        public static string Error(string context, System.Exception ex, string sql = null)
        {
            string detail = Describe(context, ex, sql);
            Log("ERROR", detail);
            string oneLine = "MED-DotNet: " + context + ": " + Root(ex).Message;
            if (Enabled)
            {
                Write("\n" + detail.Replace("\r\n", "\n").Replace("\n", "\n  ") + "\n  log: " + LogPath);
            }
            else
            {
                string hint = "";
                if (!_hinted)
                {
                    hint = "  (MEDDEBUG On for details)";
                    _hinted = true;
                }
                Write("\n" + oneLine + hint);
            }
            return oneLine;
        }

        /// <summary>Background / startup problem: logged always, on screen only when debug is on.</summary>
        public static void Warn(string context, System.Exception ex, string sql = null)
        {
            string detail = Describe(context, ex, sql);
            Log("WARN", detail);
            if (Enabled)
                Write("\n" + detail.Replace("\r\n", "\n").Replace("\n", "\n  "));
        }

        /// <summary>Text for a dialog / status line: logs the error, returns the message (full details in debug).</summary>
        public static string UiText(string context, System.Exception ex)
        {
            string detail = Describe(context, ex, null);
            Log("ERROR", detail);
            return Enabled ? detail + "\r\n\r\nlog: " + LogPath : Root(ex).Message;
        }

        /// <summary>For status lines: logs the error (details on the command line when debug is on), returns the plain message.</summary>
        public static string Status(string context, System.Exception ex)
        {
            string detail = Describe(context, ex, null);
            Log("ERROR", detail);
            if (Enabled)
                Write("\n" + detail.Replace("\r\n", "\n").Replace("\n", "\n  "));
            return Root(ex).Message;
        }

        static System.Exception Root(System.Exception ex)
        {
            // TargetInvocationException etc. carry the useful message inside
            while (ex is System.Reflection.TargetInvocationException && ex.InnerException != null)
                ex = ex.InnerException;
            return ex;
        }

        public static string Describe(string context, System.Exception ex, string sql)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("MED-DotNet ERROR in ").Append(context).Append(": ");
            if (ex == null)
            {
                sb.Append("(no exception)");
            }
            else
            {
                sb.Append(ex.GetType().FullName).Append(": ").Append(ex.Message);
                System.Exception inner = ex.InnerException;
                int depth = 0;
                while (inner != null && depth < 10)
                {
                    sb.AppendLine().Append("inner: ").Append(inner.GetType().FullName).Append(": ").Append(inner.Message);
                    inner = inner.InnerException;
                    depth++;
                }
            }
            if (!string.IsNullOrEmpty(sql))
                sb.AppendLine().Append("SQL: ").Append(sql);
            if (ex != null && !string.IsNullOrEmpty(ex.StackTrace))
                sb.AppendLine().Append("stack:").AppendLine().Append(ex.StackTrace.TrimEnd());
            return sb.ToString();
        }

        /// <summary>SQL text of a command with its parameters, for error reports.</summary>
        public static string SqlText(DbCommand cmd)
        {
            if (cmd == null)
                return null;
            StringBuilder sb = new StringBuilder(cmd.CommandText ?? "");
            foreach (DbParameter p in cmd.Parameters)
                sb.Append(" [").Append(p.ParameterName).Append("=").Append(p.Value == null || p.Value == DBNull.Value ? "NULL" : p.Value.ToString()).Append("]");
            return sb.ToString();
        }

        // --------------------------------------------------------------------- log
        public static void Log(string kind, string text)
        {
            if (kind != "ERROR" && kind != "WARN" && !Enabled)
                return;
            try
            {
                lock (Gate)
                {
                    Directory.CreateDirectory(LogDirectory);
                    if (!_pruned)
                    {
                        _pruned = true;
                        Prune();
                    }
                    string stamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff", CultureInfo.InvariantCulture);
                    string body = (text ?? "").Replace("\r\n", "\n").Replace("\n", Environment.NewLine + "    ");
                    File.AppendAllText(LogPath, stamp + " [" + kind + "] " + body + Environment.NewLine, Encoding.UTF8);
                }
            }
            catch (System.Exception)
            {
                // logging must never break a command
            }
        }

        static void Prune()
        {
            try
            {
                DateTime cutoff = DateTime.Now.Date.AddDays(-KeepDays);
                foreach (string f in Directory.GetFiles(LogDirectory, "med-*.log"))
                {
                    if (File.GetLastWriteTime(f) < cutoff)
                        File.Delete(f);
                }
            }
            catch (System.Exception)
            {
            }
        }

        // ----------------------------------------------------------------- guards
        /// <summary>Run a command body; any exception is reported instead of reaching AutoCAD.</summary>
        public static void Run(string name, Action body)
        {
            Stopwatch sw = Enabled ? Stopwatch.StartNew() : null;
            Note(name + ": start");
            try
            {
                body();
            }
            catch (System.Exception ex)
            {
                Error(name, ex);
            }
            finally
            {
                if (sw != null)
                    Note(name + ": end (" + sw.ElapsedMilliseconds + " ms)");
            }
        }

        /// <summary>Run a LispFunction body; on exception report it and return nil.</summary>
        public static ResultBuffer Lisp(string name, Func<ResultBuffer> body)
        {
            try
            {
                return body();
            }
            catch (System.Exception ex)
            {
                Error("(" + name + ")", ex);
                return null;
            }
        }

        // ------------------------------------------------------------------- LISP
        /// <summary>Set *MED-DEBUG-LEVEL* (0/1/2) in a document's LISP namespace.</summary>
        public static void SyncLisp(Document doc)
        {
            if (doc == null)
                return;
            try
            {
                doc.SetLispSymbol("*MED-DEBUG-LEVEL*", (int)Level);
            }
            catch (System.Exception ex)
            {
                Log("WARN", "SetLispSymbol *MED-DEBUG-LEVEL*: " + ex.Message);
            }
        }

        internal static void Startup()
        {
            EnsureLoaded();
            Log("INFO", "MED-DotNet loaded, debug level " + Level + ", AutoCAD " + SafeVersion());
            try
            {
                AcadApp.DocumentManager.DocumentActivated += (s, e) => { if (e != null) SyncLisp(e.Document); };
                SyncLisp(AcadApp.DocumentManager.MdiActiveDocument);
            }
            catch (System.Exception ex)
            {
                Log("WARN", "debug sync hook: " + ex.Message);
            }
        }

        static string SafeVersion()
        {
            try { return AcadApp.Version.ToString(); }
            catch (System.Exception) { return "?"; }
        }
    }

    public class MedDebugCommands
    {
        [CommandMethod("MEDDEBUG")]
        public void MedDebugCommand()
        {
            MedDebug.Run("MEDDEBUG", () =>
            {
                Document doc = AcadApp.DocumentManager.MdiActiveDocument;
                if (doc == null)
                    return;
                Editor ed = doc.Editor;
                PromptKeywordOptions opt = new PromptKeywordOptions(
                    "\nMED debug is " + MedDebug.Level + ". [On/Off/Verbose/Status] <Status>: ");
                opt.Keywords.Add("On");
                opt.Keywords.Add("Off");
                opt.Keywords.Add("Verbose");
                opt.Keywords.Add("Status");
                opt.Keywords.Default = "Status";
                opt.AllowNone = true;
                PromptResult pr = ed.GetKeywords(opt);
                if (pr.Status != PromptStatus.OK && pr.Status != PromptStatus.None)
                    return;
                string kw = pr.Status == PromptStatus.None || string.IsNullOrEmpty(pr.StringResult) ? "Status" : pr.StringResult;
                if (kw == "On") MedDebug.SetLevel(MedDebugLevel.Errors);
                else if (kw == "Off") MedDebug.SetLevel(MedDebugLevel.Off);
                else if (kw == "Verbose") MedDebug.SetLevel(MedDebugLevel.Verbose);
                MedDebug.SyncLisp(doc);
                if (kw != "Status")
                {
                    // *MED-DEBUG* T/nil for LISP modules (MED3DPath follows it); queued after this command
                    try
                    {
                        doc.SendStringToExecute(MedDebug.Enabled ? "(setq *MED-DEBUG* T) " : "(setq *MED-DEBUG* nil) ", true, false, false);
                    }
                    catch (System.Exception) { }
                }
                ed.WriteMessage("\nMED debug: {0}{1}\n  log: {2}\n  setting: HKCU\\{3}\\{4}",
                    MedDebug.Level,
                    MedDebug.Level == MedDebugLevel.Off ? " (errors: one line on screen, full details in the log)"
                        : MedDebug.Level == MedDebugLevel.Errors ? " (full error details, debug notes in the log)"
                        : " (full error details, SQL and row counts on screen and in the log)",
                    MedDebug.LogPath, MedDebug.RegistryPath, MedDebug.RegistryValue);
            });
        }

        /// <summary>(med-debug-p) -> T when MED debug is On or Verbose, else nil.</summary>
        [LispFunction("MED-DEBUG-P")]
        public static ResultBuffer MedDebugP(ResultBuffer unused)
        {
            return MedDebug.Enabled ? new ResultBuffer(new TypedValue((int)LispDataType.T_atom)) : null;
        }

        /// <summary>(med-debug-level) -> 0 Off, 1 On (errors), 2 Verbose.</summary>
        [LispFunction("MED-DEBUG-LEVEL")]
        public static ResultBuffer MedDebugLevelLisp(ResultBuffer unused)
        {
            return new ResultBuffer(new TypedValue((int)LispDataType.Int16, (short)MedDebug.Level));
        }

        /// <summary>(med-debug-log "text") -> writes a DEBUG line to the MED log when debug is on; returns T.</summary>
        [LispFunction("MED-DEBUG-LOG")]
        public static ResultBuffer MedDebugLog(ResultBuffer args)
        {
            try
            {
                if (args != null)
                {
                    StringBuilder sb = new StringBuilder();
                    foreach (TypedValue tv in args)
                        sb.Append(tv.Value == null ? "nil" : tv.Value.ToString()).Append(' ');
                    MedDebug.Log("LISP", sb.ToString().TrimEnd());
                }
            }
            catch (System.Exception) { }
            return new ResultBuffer(new TypedValue((int)LispDataType.T_atom));
        }
    }
}
