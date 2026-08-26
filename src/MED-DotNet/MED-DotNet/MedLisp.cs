using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.Globalization;
using AcadApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace MEDDotNet
{
    /// <summary>
    /// Live read/write of AutoLISP globals via MED-GetSym / MED-SetSym.
    /// Never throws to callers; unbound symbols and missing helpers yield defaults.
    /// </summary>
    internal static class MedLisp
    {
        public static readonly double[] DefaultConduitSizes =
            { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0 };
        public static readonly double[] DefaultTraySizes =
            { 6.0, 9.0, 12.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0 };
        public static readonly double[] DefaultTrayDepths = { 3.0, 4.0, 6.0 };
        public static readonly double[] DefaultTrayRadii = { 12.0, 24.0, 36.0, 48.0 };

        public static void Run(Action action)
        {
            if (action == null)
                return;
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null)
                return;

            // Palette events are application-context. Application.Invoke only works
            // in command context, so never Invoke from the UI thread.
            if (AcadApp.DocumentManager.IsApplicationContext)
            {
                try
                {
                    AcadApp.DocumentManager.ExecuteInCommandContextAsync(
                        delegate (object unused)
                        {
                            try { action(); }
                            catch (System.Exception) { }
                            return System.Threading.Tasks.Task.CompletedTask;
                        },
                        null);
                }
                catch (System.Exception)
                {
                    try { action(); }
                    catch (System.Exception) { }
                }
                return;
            }

            try { action(); }
            catch (System.Exception) { }
        }

        static string LispLiteral(TypedValue v)
        {
            int tc = v.TypeCode;
            if (tc == (int)LispDataType.Nil)
                return "nil";
            if (tc == (int)LispDataType.T_atom)
                return "T";
            if (tc == (int)LispDataType.Text)
            {
                string s = v.Value == null ? "" : v.Value.ToString();
                s = s.Replace("\\", "\\\\").Replace("\"", "\\\"");
                return "\"" + s + "\"";
            }
            if (v.Value is double)
                return ((double)v.Value).ToString("G", CultureInfo.InvariantCulture);
            if (v.Value is float)
                return ((float)v.Value).ToString("G", CultureInfo.InvariantCulture);
            if (v.Value is short)
                return ((short)v.Value).ToString(CultureInfo.InvariantCulture);
            if (v.Value is int)
                return ((int)v.Value).ToString(CultureInfo.InvariantCulture);
            if (v.Value is long)
                return ((long)v.Value).ToString(CultureInfo.InvariantCulture);
            return v.Value == null ? "nil" : v.Value.ToString();
        }

        static void EvalSetq(string expr)
        {
            Document doc = AcadApp.DocumentManager.MdiActiveDocument;
            if (doc == null || string.IsNullOrEmpty(expr))
                return;
            string line = expr.Trim();
            if (!line.StartsWith("("))
                line = "(" + line + ")";

            if (!AcadApp.DocumentManager.IsApplicationContext)
            {
                ResultBuffer rb = InvokeFunc("MEDDO", new TypedValue((int)LispDataType.Text, line));
                if (rb != null)
                {
                    rb.Dispose();
                    try { doc.Editor.WriteMessage("\nMED Settings: " + line); } catch (System.Exception) { }
                    return;
                }
            }

            try
            {
                doc.SendStringToExecute(line + "\n", true, false, false);
            }
            catch (System.Exception)
            {
            }
        }

        public static ResultBuffer InvokeFunc(string func, params TypedValue[] args)
        {
            ResultBuffer rb = new ResultBuffer();
            rb.Add(new TypedValue((int)LispDataType.Text, func));
            if (args != null)
            {
                for (int i = 0; i < args.Length; i++)
                    rb.Add(args[i]);
            }

            try
            {
                return AcadApp.Invoke(rb);
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                if (ex.ErrorStatus == ErrorStatus.InvalidContext)
                    throw;
                return null;
            }
            catch (System.Exception)
            {
                return null;
            }
            finally
            {
                rb.Dispose();
            }
        }

        public static TypedValue[] GetRaw(string symbol)
        {
            try
            {
                ResultBuffer result = InvokeFunc("MED-GetSym",
                    new TypedValue((int)LispDataType.Text, symbol));
                if (result == null)
                    return null;
                TypedValue[] arr = result.AsArray();
                result.Dispose();
                return arr;
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                if (ex.ErrorStatus == ErrorStatus.InvalidContext)
                    throw;
                return null;
            }
            catch (System.Exception)
            {
                return null;
            }
        }

        public static void Set(string symbol, TypedValue value)
        {
            EvalSetq("(setq " + symbol + " " + LispLiteral(value) + ")");
        }

        public static string GetString(string symbol, string defaultValue)
        {
            TypedValue[] tvs = GetRaw(symbol);
            if (tvs == null || tvs.Length == 0)
                return defaultValue;
            if (tvs[0].TypeCode == (int)LispDataType.Nil || tvs[0].Value == null)
                return defaultValue;
            string s = tvs[0].Value.ToString();
            return s;
        }

        public static double? GetReal(string symbol)
        {
            TypedValue[] tvs = GetRaw(symbol);
            if (tvs == null || tvs.Length == 0)
                return null;
            return AsDouble(tvs[0]);
        }

        public static int GetInt(string symbol, int defaultValue)
        {
            TypedValue[] tvs = GetRaw(symbol);
            if (tvs == null || tvs.Length == 0)
                return defaultValue;
            int? n = AsInt(tvs[0]);
            return n.HasValue ? n.Value : defaultValue;
        }

        public static bool GetLispTrue(string symbol)
        {
            TypedValue[] tvs = GetRaw(symbol);
            if (tvs == null || tvs.Length == 0)
                return false;
            return IsTrue(tvs[0]);
        }

        public static double[] GetRealList(string symbol)
        {
            TypedValue[] tvs = GetRaw(symbol);
            if (tvs == null || tvs.Length == 0)
                return null;
            List<double> nums = new List<double>();
            for (int i = 0; i < tvs.Length; i++)
            {
                double? d = AsDouble(tvs[i]);
                if (d.HasValue)
                    nums.Add(d.Value);
            }
            if (nums.Count == 0)
                return null;
            return nums.ToArray();
        }

        public static void SetString(string symbol, string value)
        {
            Set(symbol, new TypedValue((int)LispDataType.Text, value ?? ""));
        }

        public static void SetReal(string symbol, double value)
        {
            Set(symbol, new TypedValue((int)LispDataType.Double, value));
        }

        public static void SetInt(string symbol, int value)
        {
            Set(symbol, new TypedValue((int)LispDataType.Int16, (short)value));
        }

        public static void SetBool(string symbol, bool value)
        {
            if (value)
                EvalSetq("(setq " + symbol + " T)");
            else
                EvalSetq("(setq " + symbol + " nil)");
        }

        public static void ApplyConduitSize(double csize)
        {
            string n = csize.ToString("G", CultureInfo.InvariantCulture);
            EvalSetq("(progn (setq _CSIZE " + n + ") (vl-catch-all-apply (function (lambda ( / d) (setq d (getsize \"\" (rtos _CSIZE 4)) _ACSIZE (nth 1 d) _CLETT (nth 3 d))))))");
        }

        public static void ApplyTrayRadius(double radius)
        {
            int fitt = 1;
            if (Near(radius, 12.0))
                fitt = 0;
            else if (Near(radius, 24.0))
                fitt = 1;
            else if (Near(radius, 36.0))
                fitt = 3;
            else if (Near(radius, 48.0))
                fitt = 120;
            string n = radius.ToString("G", CultureInfo.InvariantCulture);
            EvalSetq("(setq _TRRAD " + n + " _TRFITTADD " + fitt.ToString(CultureInfo.InvariantCulture) + ")");
        }


        public static void ApplyDrawingScale(double sc, double plotScale)
        {
            string n = sc.ToString("G", CultureInfo.InvariantCulture);
            string p = plotScale.ToString("G", CultureInfo.InvariantCulture);
            EvalSetq("(progn (setq _SC " + n + " _PLOTSCALE " + p + ") (setvar \"DIMSCALE\" _SC) (setvar \"USERR1\" _SC))");
        }

        public static string FormatNum(double d)
        {
            return d.ToString("0.##", CultureInfo.InvariantCulture);
        }

        public static bool TryParseNum(string text, out double value)
        {
            value = 0;
            if (string.IsNullOrWhiteSpace(text))
                return false;
            if (double.TryParse(text.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out value))
                return true;
            return double.TryParse(text.Trim(), NumberStyles.Float, CultureInfo.CurrentCulture, out value);
        }

        public static bool Near(double a, double b)
        {
            return Math.Abs(a - b) < 1e-6;
        }

        static List<TypedValue> FlattenList(ResultBuffer rb)
        {
            List<TypedValue> items = new List<TypedValue>();
            if (rb == null)
                return items;
            foreach (TypedValue tv in rb)
            {
                int tc = tv.TypeCode;
                if (tc == (int)LispDataType.ListBegin || tc == (int)LispDataType.ListEnd)
                    continue;
                items.Add(tv);
            }
            return items;
        }

        static bool IsTrue(TypedValue tv)
        {
            int tc = tv.TypeCode;
            if (tc == (int)LispDataType.Nil)
                return false;
            if (tc == (int)LispDataType.T_atom)
                return true;
            if (tv.Value is short)
                return (short)tv.Value != 0;
            if (tv.Value is int)
                return (int)tv.Value != 0;
            if (tv.Value is double)
                return Math.Abs((double)tv.Value) > 1e-9;
            return tv.Value != null;
        }

        static double? AsDouble(TypedValue tv)
        {
            int tc = tv.TypeCode;
            if (tc == (int)LispDataType.Nil || tv.Value == null)
                return null;
            if (tv.Value is double)
                return (double)tv.Value;
            if (tv.Value is float)
                return (float)tv.Value;
            if (tv.Value is short)
                return (short)tv.Value;
            if (tv.Value is int)
                return (int)tv.Value;
            if (tv.Value is long)
                return (long)tv.Value;
            double d;
            if (TryParseNum(tv.Value.ToString(), out d))
                return d;
            return null;
        }

        static int? AsInt(TypedValue tv)
        {
            double? d = AsDouble(tv);
            if (!d.HasValue)
                return null;
            return (int)Math.Round(d.Value);
        }
    }
}
