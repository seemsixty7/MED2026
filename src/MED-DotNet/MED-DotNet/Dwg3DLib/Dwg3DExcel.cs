using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security;
using System.Text;
using System.Xml;

namespace MEDDotNet
{
    public sealed class Dwg3DImportResult
    {
        public int RowsRead, Matched, BlocksUpdated, Fields, CategoryChanges, DescriptionChanges, NoteChanges;
        public List<string> NotFound = new List<string>();
        public string BackupPath = "";
        public bool DryRun;
        public override string ToString()
        {
            return RowsRead + " rows read, " + Matched + " matched, " + NotFound.Count + " not found, " + BlocksUpdated + " blocks "
                + (DryRun ? "to update" : "updated") + ", " + Fields + " fields (category " + CategoryChanges + ", description "
                + DescriptionChanges + ", note " + NoteChanges + ")";
        }
    }

    /// <summary>
    /// Minimal xlsx export/import for the 3D library (no extra dependency: System.IO.Compression + XML).
    /// Layout matches tools\Dwg3DExcel\dwg3d_export_xlsx.py: sheet "Blocks" (Preview, File, Category, Description, Note, Source, Modified)
    /// and sheet "Categories" (dropdown list for Category, information-style validation so free text is allowed).
    /// Import: match by File, apply non-blank cells that differ ("(clear)" empties a field), back up the DB first.
    /// </summary>
    public static class Dwg3DExcel
    {
        public const string SheetName = "Blocks";
        public const string ClearToken = "(clear)";
        public static readonly string[] SuggestedCategories =
        {
            "Transformers", "Lighting", "Junction Boxes/Enclosures", "Cable Tray", "Unistrut/Supports",
            "Conduit Fittings", "Detectors/Gas/Flame", "Cameras", "Stations/Push Buttons", "Horns/PA/Antennas",
            "Receptacles/Switches", "Panels/Racks", "Power Equipment", "Hardware/Fasteners", "Grounding/Lightning",
            "Structural", "Letters/Text", "People/Misc",
        };

        // ------------------------------------------------------------------ export

        public static void Export(IList<Dwg3DEntry> rows, IEnumerable<string> dbCategories, string path, bool images)
        {
            var cats = new List<string>(SuggestedCategories);
            foreach (var c in dbCategories.Where(c => !string.IsNullOrWhiteSpace(c)).OrderBy(c => c, StringComparer.OrdinalIgnoreCase))
                if (!cats.Contains(c, StringComparer.OrdinalIgnoreCase)) cats.Add(c);

            string tmp = path + ".tmp";
            if (File.Exists(tmp)) File.Delete(tmp);
            var pics = new List<int>(); // row numbers with an image
            using (var fs = new FileStream(tmp, FileMode.CreateNew))
            using (var zip = new ZipArchive(fs, ZipArchiveMode.Create))
            {
                int imgNo = 0;
                if (images)
                {
                    for (int i = 0; i < rows.Count; i++)
                    {
                        byte[] png = ThumbPng(rows[i].Thumb, 48);
                        if (png == null) continue;
                        imgNo++;
                        pics.Add(i + 2);
                        var e = zip.CreateEntry("xl/media/image" + imgNo + ".png", CompressionLevel.NoCompression);
                        using (var s = e.Open()) s.Write(png, 0, png.Length);
                    }
                }
                bool hasDrawing = pics.Count > 0;
                Put(zip, "[Content_Types].xml", ContentTypes(hasDrawing));
                Put(zip, "_rels/.rels", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/></Relationships>");
                Put(zip, "xl/workbook.xml", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\"><bookViews><workbookView activeTab=\"0\"/></bookViews><sheets><sheet name=\"" + SheetName + "\" sheetId=\"1\" r:id=\"rId1\"/><sheet name=\"Categories\" sheetId=\"2\" r:id=\"rId2\"/></sheets><definedNames><definedName name=\"_xlnm._FilterDatabase\" localSheetId=\"0\" hidden=\"1\">" + SheetName + "!$A$1:$G$" + (rows.Count + 1) + "</definedName></definedNames></workbook>");
                Put(zip, "xl/_rels/workbook.xml.rels", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/><Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet2.xml\"/><Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/></Relationships>");
                Put(zip, "xl/styles.xml", Styles());
                Put(zip, "xl/worksheets/sheet1.xml", BlocksSheet(rows, cats.Count, hasDrawing, images));
                Put(zip, "xl/worksheets/sheet2.xml", CategoriesSheet(cats));
                if (hasDrawing)
                {
                    Put(zip, "xl/worksheets/_rels/sheet1.xml.rels", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing\" Target=\"../drawings/drawing1.xml\"/></Relationships>");
                    Put(zip, "xl/drawings/drawing1.xml", Drawing(pics));
                    var rels = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">");
                    for (int n = 1; n <= pics.Count; n++)
                        rels.Append("<Relationship Id=\"rId" + n + "\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/image" + n + ".png\"/>");
                    rels.Append("</Relationships>");
                    Put(zip, "xl/drawings/_rels/drawing1.xml.rels", rels.ToString());
                }
            }
            if (File.Exists(path)) File.Delete(path);
            File.Move(tmp, path);
        }

        static void Put(ZipArchive zip, string name, string xml)
        {
            var e = zip.CreateEntry(name, CompressionLevel.Optimal);
            using (var s = e.Open())
            {
                var b = new UTF8Encoding(false).GetBytes(xml);
                s.Write(b, 0, b.Length);
            }
        }

        static string ContentTypes(bool drawing)
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
                + "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
                + "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
                + "<Default Extension=\"png\" ContentType=\"image/png\"/>"
                + "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
                + "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
                + "<Override PartName=\"/xl/worksheets/sheet2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
                + "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>"
                + (drawing ? "<Override PartName=\"/xl/drawings/drawing1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.drawing+xml\"/>" : "")
                + "</Types>";
        }

        // style ids: 0 default, 1 header, 2 key (File, grey, locked), 3 editable (unlocked, wrap), 4 read-only info (grey text), 5 bold
        static string Styles()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
                + "<fonts count=\"4\"><font><sz val=\"11\"/><name val=\"Calibri\"/><family val=\"2\"/></font>"
                + "<font><b/><sz val=\"11\"/><color rgb=\"FFFFFFFF\"/><name val=\"Calibri\"/><family val=\"2\"/></font>"
                + "<font><sz val=\"11\"/><color rgb=\"FF595959\"/><name val=\"Calibri\"/><family val=\"2\"/></font>"
                + "<font><b/><sz val=\"11\"/><name val=\"Calibri\"/><family val=\"2\"/></font></fonts>"
                + "<fills count=\"4\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill>"
                + "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FF44546A\"/><bgColor indexed=\"64\"/></patternFill></fill>"
                + "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FFE7E6E6\"/><bgColor indexed=\"64\"/></patternFill></fill></fills>"
                + "<borders count=\"1\"><border><left/><right/><top/><bottom/><diagonal/></border></borders>"
                + "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>"
                + "<cellXfs count=\"6\">"
                + "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/>"
                + "<xf numFmtId=\"0\" fontId=\"1\" fillId=\"2\" borderId=\"0\" xfId=\"0\" applyFont=\"1\" applyFill=\"1\"/>"
                + "<xf numFmtId=\"0\" fontId=\"2\" fillId=\"3\" borderId=\"0\" xfId=\"0\" applyFont=\"1\" applyFill=\"1\" applyAlignment=\"1\"><alignment vertical=\"top\" wrapText=\"1\"/></xf>"
                + "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyAlignment=\"1\" applyProtection=\"1\"><alignment vertical=\"top\" wrapText=\"1\"/><protection locked=\"0\"/></xf>"
                + "<xf numFmtId=\"0\" fontId=\"2\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyFont=\"1\" applyAlignment=\"1\"><alignment vertical=\"top\" wrapText=\"1\"/></xf>"
                + "<xf numFmtId=\"0\" fontId=\"3\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyFont=\"1\"/>"
                + "</cellXfs><cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles></styleSheet>";
        }

        static readonly string[] Headers = { "Preview", "File", "Category", "Description", "Note", "Source", "Modified" };
        static readonly double[] Widths = { 9, 42, 24, 50, 40, 60, 19 };

        static string BlocksSheet(IList<Dwg3DEntry> rows, int catCount, bool drawing, bool images)
        {
            int last = rows.Count + 1;
            var sb = new StringBuilder(rows.Count * 400);
            sb.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">");
            sb.Append("<dimension ref=\"A1:G" + last + "\"/>");
            sb.Append("<sheetViews><sheetView tabSelected=\"1\" workbookViewId=\"0\"><pane xSplit=\"2\" ySplit=\"1\" topLeftCell=\"C2\" activePane=\"bottomRight\" state=\"frozen\"/><selection pane=\"topRight\"/><selection pane=\"bottomLeft\"/><selection pane=\"bottomRight\" activeCell=\"C2\" sqref=\"C2\"/></sheetView></sheetViews>");
            sb.Append("<sheetFormatPr defaultRowHeight=\"15\"/><cols>");
            for (int c = 0; c < Widths.Length; c++)
                sb.Append("<col min=\"" + (c + 1) + "\" max=\"" + (c + 1) + "\" width=\"" + Widths[c].ToString(CultureInfo.InvariantCulture) + "\" customWidth=\"1\"/>");
            sb.Append("</cols><sheetData><row r=\"1\">");
            for (int c = 0; c < Headers.Length; c++) Cell(sb, c, 1, Headers[c], 1);
            sb.Append("</row>");
            string ht = images ? "40" : "18";
            for (int i = 0; i < rows.Count; i++)
            {
                var e = rows[i];
                int r = i + 2;
                sb.Append("<row r=\"" + r + "\" ht=\"" + ht + "\" customHeight=\"1\">");
                Cell(sb, 1, r, e.File, 2);
                Cell(sb, 2, r, e.Category, 3);
                Cell(sb, 3, r, e.Description, 3);
                Cell(sb, 4, r, e.Note, 3);
                Cell(sb, 5, r, e.SourcePath, 4);
                Cell(sb, 6, r, e.FileModified, 4);
                sb.Append("</row>");
            }
            sb.Append("</sheetData>");
            sb.Append("<sheetProtection sheet=\"1\" objects=\"1\" scenarios=\"1\" formatColumns=\"0\" formatRows=\"0\" autoFilter=\"0\"/>");
            sb.Append("<autoFilter ref=\"A1:G" + last + "\"/>");
            sb.Append("<dataValidations count=\"1\"><dataValidation type=\"list\" errorStyle=\"information\" allowBlank=\"1\" showInputMessage=\"1\" showErrorMessage=\"1\" errorTitle=\"Category\" error=\"Not in the suggested list. Click OK to keep your own category.\" promptTitle=\"Category\" prompt=\"Pick a suggestion or type your own.\" sqref=\"C2:C" + Math.Max(last, 2000) + "\"><formula1>Categories!$A$2:$A$" + (catCount + 1) + "</formula1></dataValidation></dataValidations>");
            sb.Append("<pageMargins left=\"0.7\" right=\"0.7\" top=\"0.75\" bottom=\"0.75\" header=\"0.3\" footer=\"0.3\"/>");
            if (drawing) sb.Append("<drawing r:id=\"rId1\"/>");
            sb.Append("</worksheet>");
            return sb.ToString();
        }

        static string CategoriesSheet(List<string> cats)
        {
            var sb = new StringBuilder();
            sb.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">");
            sb.Append("<cols><col min=\"1\" max=\"1\" width=\"30\" customWidth=\"1\"/></cols><sheetData><row r=\"1\">");
            Cell(sb, 0, 1, "Category (dropdown list)", 5);
            sb.Append("</row>");
            for (int i = 0; i < cats.Count; i++)
            {
                sb.Append("<row r=\"" + (i + 2) + "\">");
                Cell(sb, 0, i + 2, cats[i], 0);
                sb.Append("</row>");
            }
            sb.Append("</sheetData></worksheet>");
            return sb.ToString();
        }

        static void Cell(StringBuilder sb, int col, int row, string text, int style)
        {
            string r = ColName(col) + row;
            if (string.IsNullOrEmpty(text)) { sb.Append("<c r=\"" + r + "\" s=\"" + style + "\"/>"); return; }
            sb.Append("<c r=\"" + r + "\" s=\"" + style + "\" t=\"inlineStr\"><is><t xml:space=\"preserve\">" + Esc(text) + "</t></is></c>");
        }

        static string Esc(string s)
        {
            var sb = new StringBuilder(s.Length);
            foreach (char ch in s)
                if (ch == '\t' || ch == '\n' || ch == '\r' || ch >= 0x20) sb.Append(ch);
            return SecurityElement.Escape(sb.ToString());
        }

        static string ColName(int col)
        {
            string s = "";
            col++;
            while (col > 0) { int m = (col - 1) % 26; s = (char)('A' + m) + s; col = (col - 1) / 26; }
            return s;
        }

        static string Drawing(List<int> rows)
        {
            const long px = 9525, size = 48 * px, off = 3 * px;
            var sb = new StringBuilder();
            sb.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><xdr:wsDr xmlns:xdr=\"http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing\" xmlns:a=\"http://schemas.openxmlformats.org/drawingml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">");
            for (int n = 0; n < rows.Count; n++)
            {
                int row0 = rows[n] - 1; // zero-based
                sb.Append("<xdr:oneCellAnchor><xdr:from><xdr:col>0</xdr:col><xdr:colOff>" + off + "</xdr:colOff><xdr:row>" + row0 + "</xdr:row><xdr:rowOff>" + off + "</xdr:rowOff></xdr:from>");
                sb.Append("<xdr:ext cx=\"" + size + "\" cy=\"" + size + "\"/><xdr:pic><xdr:nvPicPr><xdr:cNvPr id=\"" + (n + 2) + "\" name=\"Preview " + (n + 1) + "\"/><xdr:cNvPicPr><a:picLocks noChangeAspect=\"1\"/></xdr:cNvPicPr></xdr:nvPicPr>");
                sb.Append("<xdr:blipFill><a:blip r:embed=\"rId" + (n + 1) + "\"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill>");
                sb.Append("<xdr:spPr><a:xfrm><a:off x=\"0\" y=\"0\"/><a:ext cx=\"" + size + "\" cy=\"" + size + "\"/></a:xfrm><a:prstGeom prst=\"rect\"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/></xdr:oneCellAnchor>");
            }
            sb.Append("</xdr:wsDr>");
            return sb.ToString();
        }

        static byte[] ThumbPng(byte[] png, int size)
        {
            using (var img = Dwg3DThumbnail.FromPng(png))
            {
                if (img == null) return null;
                using (var sc = Dwg3DThumbnail.Scaled(img, size, size, Color.FromArgb(33, 40, 48)))
                using (var ms = new MemoryStream())
                {
                    sc.Save(ms, ImageFormat.Png);
                    return ms.ToArray();
                }
            }
        }

        // ------------------------------------------------------------------ read

        /// <summary>Reads the "Blocks" sheet (or the first sheet) into rows of header-name -> text.</summary>
        public static List<Dictionary<string, string>> ReadSheet(string path)
        {
            var result = new List<Dictionary<string, string>>();
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var zip = new ZipArchive(fs, ZipArchiveMode.Read))
            {
                var shared = new List<string>();
                var sst = Entry(zip, "xl/sharedStrings.xml");
                if (sst != null)
                {
                    var d = LoadXml(sst);
                    foreach (XmlNode si in d.DocumentElement.ChildNodes)
                        if (si.LocalName == "si") shared.Add(InnerT(si));
                }
                string sheetPath = FindSheet(zip);
                var sheet = Entry(zip, sheetPath);
                if (sheet == null) throw new InvalidDataException("Worksheet not found in " + path);
                var doc = LoadXml(sheet);
                var ns = new XmlNamespaceManager(doc.NameTable);
                ns.AddNamespace("m", doc.DocumentElement.NamespaceURI);
                var header = new Dictionary<int, string>();
                bool first = true;
                foreach (XmlNode row in doc.SelectNodes("/m:worksheet/m:sheetData/m:row", ns))
                {
                    var vals = new Dictionary<int, string>();
                    int next = 0;
                    foreach (XmlNode c in row.ChildNodes)
                    {
                        if (c.LocalName != "c") continue;
                        var rAttr = c.Attributes["r"];
                        int col = rAttr != null ? ColIndex(rAttr.Value) : next;
                        next = col + 1;
                        vals[col] = CellText(c, shared);
                    }
                    if (first)
                    {
                        foreach (var kv in vals) if (!string.IsNullOrWhiteSpace(kv.Value)) header[kv.Key] = kv.Value.Trim();
                        first = false;
                        continue;
                    }
                    var d = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    foreach (var kv in header)
                    {
                        string v;
                        d[kv.Value] = vals.TryGetValue(kv.Key, out v) ? v : "";
                    }
                    result.Add(d);
                }
            }
            return result;
        }

        static ZipArchiveEntry Entry(ZipArchive zip, string name)
        {
            return zip.Entries.FirstOrDefault(e => string.Equals(e.FullName.TrimStart('/'), name, StringComparison.OrdinalIgnoreCase));
        }

        static XmlDocument LoadXml(ZipArchiveEntry e)
        {
            var d = new XmlDocument { XmlResolver = null };
            using (var s = e.Open()) d.Load(s);
            return d;
        }

        static string FindSheet(ZipArchive zip)
        {
            var wbE = Entry(zip, "xl/workbook.xml");
            var relE = Entry(zip, "xl/_rels/workbook.xml.rels");
            if (wbE == null || relE == null) return "xl/worksheets/sheet1.xml";
            var wb = LoadXml(wbE);
            var rels = LoadXml(relE);
            const string rNs = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
            string rid = null, firstRid = null;
            foreach (XmlNode n in wb.GetElementsByTagName("sheet", wb.DocumentElement.NamespaceURI))
            {
                var id = n.Attributes["id", rNs];
                if (id == null) continue;
                if (firstRid == null) firstRid = id.Value;
                var nm = n.Attributes["name"];
                if (nm != null && string.Equals(nm.Value, SheetName, StringComparison.OrdinalIgnoreCase)) { rid = id.Value; break; }
            }
            rid = rid ?? firstRid;
            foreach (XmlNode r in rels.DocumentElement.ChildNodes)
            {
                if (r.Attributes == null || r.Attributes["Id"] == null || r.Attributes["Id"].Value != rid) continue;
                string target = r.Attributes["Target"].Value;
                return target.StartsWith("/") ? target.TrimStart('/') : "xl/" + target;
            }
            return "xl/worksheets/sheet1.xml";
        }

        static string InnerT(XmlNode n)
        {
            // concatenates <t> of plain and rich-text runs, skipping phonetic runs (rPh)
            var sb = new StringBuilder();
            foreach (XmlNode ch in n.ChildNodes)
            {
                if (ch.LocalName == "t") sb.Append(ch.InnerText);
                else if (ch.LocalName == "r") foreach (XmlNode t in ch.ChildNodes) if (t.LocalName == "t") sb.Append(t.InnerText);
            }
            return sb.ToString();
        }

        static string CellText(XmlNode c, List<string> shared)
        {
            var tA = c.Attributes["t"];
            string t = tA != null ? tA.Value : "n";
            XmlNode v = null, isN = null;
            foreach (XmlNode ch in c.ChildNodes) { if (ch.LocalName == "v") v = ch; else if (ch.LocalName == "is") isN = ch; }
            switch (t)
            {
                case "s":
                    int k;
                    return v != null && int.TryParse(v.InnerText, NumberStyles.Integer, CultureInfo.InvariantCulture, out k) && k >= 0 && k < shared.Count ? shared[k] : "";
                case "inlineStr": return isN != null ? InnerT(isN) : "";
                case "b": return v != null && v.InnerText == "1" ? "TRUE" : (v != null ? "FALSE" : "");
                default:
                    if (v == null) return "";
                    double dv;
                    if (t == "n" && double.TryParse(v.InnerText, NumberStyles.Float, CultureInfo.InvariantCulture, out dv))
                        return dv.ToString("0.###############", CultureInfo.InvariantCulture);
                    return v.InnerText;
            }
        }

        static int ColIndex(string cellRef)
        {
            int n = 0;
            foreach (char ch in cellRef)
            {
                if (ch >= 'A' && ch <= 'Z') n = n * 26 + (ch - 'A' + 1);
                else if (ch >= 'a' && ch <= 'z') n = n * 26 + (ch - 'a' + 1);
                else break;
            }
            return n - 1;
        }

        // ------------------------------------------------------------------ import

        /// <summary>Imports Category/Description/Note from the workbook into dbPath. Backs up the DB first (unless dry run or nothing changes).</summary>
        public static Dwg3DImportResult Import(string dbPath, string xlsxPath, bool dryRun)
        {
            var res = new Dwg3DImportResult { DryRun = dryRun };
            var sheet = ReadSheet(xlsxPath);
            if (sheet.Count > 0 && !sheet[0].ContainsKey("File")) throw new InvalidDataException("No 'File' column in the first row of the sheet.");
            List<Dwg3DEntry> all;
            using (var db = new Dwg3DLibDb(dbPath)) all = db.LoadAll();
            var byFile = new Dictionary<string, Dwg3DEntry>(StringComparer.OrdinalIgnoreCase);
            var byName = new Dictionary<string, List<Dwg3DEntry>>(StringComparer.OrdinalIgnoreCase);
            foreach (var e in all)
            {
                byFile[e.File] = e;
                string n = Path.GetFileName(e.File);
                List<Dwg3DEntry> l;
                if (!byName.TryGetValue(n, out l)) byName[n] = l = new List<Dwg3DEntry>();
                l.Add(e);
            }

            var changed = new List<Dwg3DEntry>();
            foreach (var row in sheet)
            {
                string f;
                if (!row.TryGetValue("File", out f) || string.IsNullOrWhiteSpace(f)) continue;
                f = f.Trim();
                res.RowsRead++;
                Dwg3DEntry e;
                if (!byFile.TryGetValue(f, out e))
                {
                    List<Dwg3DEntry> l;
                    e = byName.TryGetValue(Path.GetFileName(f), out l) && l.Count == 1 ? l[0] : null;
                }
                if (e == null) { res.NotFound.Add(f); continue; }
                res.Matched++;
                bool any = false;
                string nv;
                if (Pick(row, "Category", false, e.Category, out nv)) { e.Category = nv; res.CategoryChanges++; any = true; }
                if (Pick(row, "Description", false, e.Description, out nv)) { e.Description = nv; res.DescriptionChanges++; any = true; }
                if (Pick(row, "Note", true, e.Note, out nv)) { e.Note = nv; res.NoteChanges++; any = true; }
                if (any && !changed.Contains(e)) changed.Add(e);
            }
            res.BlocksUpdated = changed.Count;
            res.Fields = res.CategoryChanges + res.DescriptionChanges + res.NoteChanges;
            if (dryRun || changed.Count == 0) return res;

            res.BackupPath = dbPath + ".bak-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");
            File.Copy(dbPath, res.BackupPath, false);
            using (var db = new Dwg3DLibDb(dbPath))
            using (var tx = db.Begin())
            {
                foreach (var e in changed) db.SaveEdits(e);
                tx.Commit();
            }
            return res;
        }

        static bool Pick(Dictionary<string, string> row, string col, bool note, string current, out string value)
        {
            value = null;
            string v;
            if (!row.TryGetValue(col, out v) || v == null) return false;
            v = note ? v.TrimEnd() : v.Trim();
            if (v.Length == 0) return false;
            if (string.Equals(v, ClearToken, StringComparison.OrdinalIgnoreCase)) v = "";
            if (v == (current ?? "")) return false;
            value = v;
            return true;
        }
    }
}
