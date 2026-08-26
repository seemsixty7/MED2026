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
        public string Group;

        public override string ToString()
        {
            if (string.IsNullOrEmpty(Description))
                return Code.ToString();
            return Code + "  " + Description;
        }
    }

    internal static class MedTypeLookup
    {
        public static readonly string[] PreferredCableGroups =
        {
            "Building Wire",
            "Tray Cable",
            "Ground Cable",
            "Instrument Cable",
            "Residential Cable"
        };

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
                string sql = "SELECT ITEMCODE, ITEMDESC, ITEM_GRP FROM MEDType WHERE ITEMTYPE='" + itemType + "' ORDER BY ITEMCODE";
                DataTable dt = ProcessSQL.QueryTable(sql);
                foreach (DataRow row in dt.Rows)
                {
                    if (row.IsNull(0))
                        continue;
                    MedTypeRow item = new MedTypeRow();
                    item.Code = Convert.ToInt32(row[0]);
                    item.Description = row.IsNull(1) ? "" : row[1].ToString();
                    item.Group = (dt.Columns.Count > 2 && !row.IsNull(2)) ? row[2].ToString() : "";
                    list.Add(item);
                }
            }
            catch (System.Exception)
            {
            }
            Cache[itemType] = list;
            return list;
        }

        public static List<string> CableGroups()
        {
            List<string> list = new List<string>();
            Dictionary<string, bool> seen = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < PreferredCableGroups.Length; i++)
            {
                string name = PreferredCableGroups[i];
                if (seen.ContainsKey(name))
                    continue;
                seen[name] = true;
                list.Add(name);
            }
            foreach (MedTypeRow row in ForApp(MedApps.Cable))
            {
                if (string.IsNullOrEmpty(row.Group) || seen.ContainsKey(row.Group))
                    continue;
                seen[row.Group] = true;
                list.Add(row.Group);
            }
            return list;
        }

        public static List<MedTypeRow> CablesByGroup(string group)
        {
            List<MedTypeRow> list = new List<MedTypeRow>();
            if (string.IsNullOrEmpty(group))
                return list;
            foreach (MedTypeRow row in ForApp(MedApps.Cable))
            {
                if (string.Equals(row.Group, group, StringComparison.OrdinalIgnoreCase))
                    list.Add(row);
            }
            return list;
        }

        public static MedTypeRow CableByCode(int code)
        {
            foreach (MedTypeRow row in ForApp(MedApps.Cable))
            {
                if (row.Code == code)
                    return row;
            }
            return null;
        }

        public static string GroupForCableCode(int code)
        {
            MedTypeRow row = CableByCode(code);
            if (row == null || string.IsNullOrEmpty(row.Group))
                return "";
            return row.Group;
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
