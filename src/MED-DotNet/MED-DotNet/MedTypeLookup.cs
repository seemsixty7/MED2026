using System;
using System.Collections.Generic;
using System.Data;
using DataTable = System.Data.DataTable;

namespace MEDDotNet
{
    internal class MedTypeRow
    {
        public int Code;
        public string Description;

        public override string ToString()
        {
            if (string.IsNullOrEmpty(Description))
                return Code.ToString();
            return Code + "  " + Description;
        }
    }

    internal static class MedTypeLookup
    {
        static readonly Dictionary<string, List<MedTypeRow>> Cache =
            new Dictionary<string, List<MedTypeRow>>(StringComparer.OrdinalIgnoreCase);

        public static void ClearCache()
        {
            Cache.Clear();
        }

        public static List<MedTypeRow> ForApp(string app)
        {
            string itemType = MedApps.SqlItemType(app);
            List<MedTypeRow> list;
            if (Cache.TryGetValue(itemType, out list))
                return list;
            list = new List<MedTypeRow>();
            try
            {
                string sql = "SELECT ITEMCODE, ITEMDESC FROM MEDType WHERE ITEMTYPE='" + itemType + "' ORDER BY ITEMCODE";
                DataTable dt = ProcessSQL.QueryTable(sql);
                foreach (DataRow row in dt.Rows)
                {
                    if (row.IsNull(0))
                        continue;
                    MedTypeRow item = new MedTypeRow();
                    item.Code = Convert.ToInt32(row[0]);
                    item.Description = row.IsNull(1) ? "" : row[1].ToString();
                    list.Add(item);
                }
            }
            catch (System.Exception)
            {
            }
            Cache[itemType] = list;
            return list;
        }

        public static string Description(string app, string codeText)
        {
            string code = MedXdata.CodeFromDisplay(codeText);
            int n;
            if (!int.TryParse(code, out n))
                return "";
            foreach (MedTypeRow row in ForApp(app))
            {
                if (row.Code == n)
                    return row.Description ?? "";
            }
            return "";
        }

        public static string Display(string app, string codeText)
        {
            string code = MedXdata.CodeFromDisplay(codeText);
            string desc = Description(app, code);
            if (string.IsNullOrEmpty(code))
                return "";
            if (string.IsNullOrEmpty(desc))
                return code;
            return code + "  " + desc;
        }
    }
}