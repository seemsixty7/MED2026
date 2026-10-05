using System;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using Autodesk.Windows;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// MED ribbon mode switching (MEDRibbon.cuix tabs MED Main / MED Plan / MED Detail / MED Wiring).
    /// MED Main is always shown; only the current mode's tab is shown beside it.
    /// MEDPLAN / MEDDETAIL / MEDWIRING (med.mnl) call (MEDRIBBON-SETMODE "Plan"|"Detail"|"Wiring")
    /// after swapping the pulldowns. The mode is re-applied when the ribbon is created or rebuilt
    /// (startup, RIBBON, CUILOAD/MENULOAD/CUI, workspace switch).
    /// </summary>
    public class MedRibbonMode
    {
        // CUI tab element UIDs in MEDRibbon.cuix, and their titles (fallback match).
        private const string MainId = "MED_TAB_MAIN", PlanId = "MED_TAB_PLAN", DetailId = "MED_TAB_DETAIL", WiringId = "MED_TAB_WIRING";
        private const string MainTitle = "MED Main", PlanTitle = "MED Plan", DetailTitle = "MED Detail", WiringTitle = "MED Wiring";

        // Default matches the pulldown default (POP2CONDUIT = Plan).
        private static string _mode = "Plan";
        private static bool _idleQueued, _activateOnIdle, _hooked, _waitingForRibbon;

        public static string Mode { get { return _mode; } }

        // ------------------------------------------------------------ startup
        /// <summary>Called from Plugin.Initialize. Never throws.</summary>
        public static void Startup()
        {
            try
            {
                HookEvents();
                if (ComponentManager.Ribbon == null)
                    WaitForRibbon();
                else
                    QueueApply(false);
            }
            catch (System.Exception ex) { MedDebug.Warn("ribbon mode startup", ex); }
        }

        private static void WaitForRibbon()
        {
            if (_waitingForRibbon) return;
            _waitingForRibbon = true;
            ComponentManager.ItemInitialized += OnItemInitialized;
        }

        private static void OnItemInitialized(object sender, RibbonItemEventArgs e)
        {
            if (ComponentManager.Ribbon == null) return;
            ComponentManager.ItemInitialized -= OnItemInitialized;
            _waitingForRibbon = false;
            QueueApply(false);
        }

        private static void HookEvents()
        {
            if (_hooked) return;
            _hooked = true;
            AcApp.SystemVariableChanged += OnSysVarChanged;
            DocumentCollection dm = AcApp.DocumentManager;
            foreach (Document d in dm) HookDoc(d);
            dm.DocumentCreated += (s, e) => { if (e.Document != null) HookDoc(e.Document); };
        }

        private static void HookDoc(Document d)
        {
            try { d.CommandEnded += OnCommandEnded; } catch { }
        }

        private static void OnSysVarChanged(object sender, Autodesk.AutoCAD.ApplicationServices.SystemVariableChangedEventArgs e)
        {
            if (string.Equals(e.Name, "WSCURRENT", StringComparison.OrdinalIgnoreCase)
                || string.Equals(e.Name, "RIBBONSTATE", StringComparison.OrdinalIgnoreCase))
                QueueApply(false);
        }

        private static void OnCommandEnded(object sender, CommandEventArgs e)
        {
            string c = (e.GlobalCommandName ?? "").ToUpperInvariant();
            if (c == "CUILOAD" || c == "CUIUNLOAD" || c == "MENULOAD" || c == "MENUUNLOAD" || c == "CUI"
                || c == "MENU" || c == "RIBBON" || c == "WORKSPACE" || c == "WSCURRENT" || c == "CUIIMPORT")
                QueueApply(false);
        }

        // ------------------------------------------------------------ apply
        private static void QueueApply(bool activate)
        {
            if (activate) _activateOnIdle = true;
            if (_idleQueued) return;
            _idleQueued = true;
            AcApp.Idle += OnIdleOnce;
        }

        private static void OnIdleOnce(object sender, EventArgs e)
        {
            AcApp.Idle -= OnIdleOnce;
            _idleQueued = false;
            bool act = _activateOnIdle;
            _activateOnIdle = false;
            try
            {
                if (ComponentManager.Ribbon == null) { WaitForRibbon(); return; }
                Apply(act);
            }
            catch (System.Exception ex) { MedDebug.Warn("ribbon mode apply", ex); }
        }

        private static bool Matches(RibbonTab t, string uid, string title)
        {
            if (t == null) return false;
            string id = t.Id ?? "";
            if (string.Equals(id, uid, StringComparison.OrdinalIgnoreCase)) return true;
            if (id.EndsWith("." + uid, StringComparison.OrdinalIgnoreCase)) return true;
            if (id.EndsWith("_" + uid, StringComparison.OrdinalIgnoreCase)) return true;
            return string.Equals((t.Title ?? "").Trim(), title, StringComparison.OrdinalIgnoreCase)
                || string.Equals((t.Name ?? "").Trim(), title, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>Shows MED Main + the current mode tab, hides the other mode tabs.
        /// Returns the number of MED tabs found (0 = MEDRibbon.cuix tabs not on the ribbon).</summary>
        private static int Apply(bool activate)
        {
            RibbonControl rc = ComponentManager.Ribbon;
            if (rc == null) return 0;
            RibbonTab main = null, plan = null, detail = null, wiring = null;
            foreach (RibbonTab t in rc.Tabs)
            {
                if (main == null && Matches(t, MainId, MainTitle)) main = t;
                else if (plan == null && Matches(t, PlanId, PlanTitle)) plan = t;
                else if (detail == null && Matches(t, DetailId, DetailTitle)) detail = t;
                else if (wiring == null && Matches(t, WiringId, WiringTitle)) wiring = t;
            }
            RibbonTab cur = _mode == "Detail" ? detail : _mode == "Wiring" ? wiring : plan;
            int found = 0;
            if (main != null) { found++; if (!main.IsVisible) main.IsVisible = true; }
            foreach (RibbonTab t in new[] { plan, detail, wiring })
            {
                if (t == null) continue;
                found++;
                bool show = ReferenceEquals(t, cur);
                if (t.IsVisible != show) t.IsVisible = show;
            }
            if (activate && cur != null)
            {
                try { rc.ActiveTab = cur; } catch (System.Exception ex) { MedDebug.Warn("ribbon ActiveTab", ex); }
            }
            return found;
        }

        private static string Normalize(string s)
        {
            s = (s ?? "").Trim().ToUpperInvariant();
            if (s.StartsWith("P") || s == "1") return "Plan";
            if (s.StartsWith("D") || s == "2") return "Detail";
            if (s.StartsWith("W") || s == "3") return "Wiring";
            return null;
        }

        /// <summary>Set the mode and apply now (activating the mode tab). Returns MED tabs found.</summary>
        public static int SetMode(string mode, bool activate)
        {
            string m = Normalize(mode);
            if (m == null) return -1;
            _mode = m;
            HookEvents();
            if (ComponentManager.Ribbon == null) { WaitForRibbon(); _activateOnIdle |= activate; return 0; }
            int n = Apply(activate);
            // Workspace/menu loads during the same command can rebuild tabs; re-apply once at idle.
            QueueApply(false);
            return n;
        }

        // ------------------------------------------------------------ command + LISP
        [CommandMethod("MEDRIBBONMODE", CommandFlags.Modal)]
        public static void MedRibbonModeCmd()
        {
            Editor ed = AcApp.DocumentManager.MdiActiveDocument.Editor;
            PromptKeywordOptions pko = new PromptKeywordOptions("\nMED ribbon mode [Plan/Detail/Wiring]", "Plan Detail Wiring");
            pko.Keywords.Default = _mode;
            pko.AllowNone = true;
            PromptResult pr = ed.GetKeywords(pko);
            if (pr.Status != PromptStatus.OK && pr.Status != PromptStatus.None) return;
            string kw = pr.Status == PromptStatus.None || string.IsNullOrEmpty(pr.StringResult) ? _mode : pr.StringResult;
            int n = SetMode(kw, true);
            if (n == 0)
                ed.WriteMessage("\nMED ribbon tabs were not found. Make sure MEDRibbon.cuix is loaded (it is a partial of med.cuix; or CUILOAD MEDRibbon.cuix) and the ribbon is on (RIBBON).");
            else
                ed.WriteMessage("\nMED ribbon mode: " + _mode + ".");
        }

        /// <summary>(MEDRIBBON-SETMODE "Plan"|"Detail"|"Wiring") -> T when MED tabs were found, nil otherwise.
        /// (MEDRIBBON-SETMODE) with no argument returns the current mode string.</summary>
        [LispFunction("MEDRIBBON-SETMODE")]
        public static object MedRibbonSetModeLisp(ResultBuffer args)
        {
            try
            {
                string mode = null;
                if (args != null)
                    foreach (TypedValue tv in args)
                    {
                        if (tv.Value is string) { mode = (string)tv.Value; break; }
                        if (tv.Value is short || tv.Value is int) { mode = Convert.ToString(tv.Value); break; }
                    }
                if (mode == null) return _mode;
                int n = SetMode(mode, true);
                return n > 0 ? (object)new TypedValue((int)LispDataType.T_atom) : null;
            }
            catch (System.Exception ex)
            {
                MedDebug.Warn("MEDRIBBON-SETMODE", ex);
                return null;
            }
        }
    }
}
