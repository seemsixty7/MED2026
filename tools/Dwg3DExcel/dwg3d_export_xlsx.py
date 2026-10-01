"""Export Dwg3D\\Dwg3DCatalog.db to an Excel bulk-edit workbook (same layout as the MED3DLIB palette export).

    py -3.12 dwg3d_export_xlsx.py [--db PATH] [--out PATH] [--no-images]

Needs openpyxl (+ Pillow for thumbnails): py -3.12 -m pip install --user openpyxl pillow
Category cells are left empty; the Categories sheet holds the dropdown list and per-file suggestions.
"""
import argparse, io, os, sqlite3, sys
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Protection
from openpyxl.worksheet.datavalidation import DataValidation

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dwg3d_categories import CATEGORIES, suggest

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.normpath(os.path.join(HERE, "..", "..", "Dwg3D", "Dwg3DCatalog.db"))
HEADERS = ["Preview", "File", "Category", "Description", "Note", "Source", "Modified"]
WIDTHS = [9, 42, 24, 50, 40, 60, 19]
THUMB_PX = 48


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=DEFAULT_DB)
    ap.add_argument("--out", default=None)
    ap.add_argument("--no-images", action="store_true")
    a = ap.parse_args()
    out = a.out or os.path.join(os.path.dirname(a.db), "Dwg3DCatalog_BulkEdit.xlsx")
    # read-only open: never writes the DB
    con = sqlite3.connect("file:" + a.db.replace("\\", "/") + "?mode=ro", uri=True)
    rows = con.execute("SELECT file,category,description,note,source_path,file_modified,thumb FROM blocks ORDER BY file COLLATE NOCASE").fetchall()
    db_cats = [r[0] for r in con.execute("SELECT name FROM categories UNION SELECT category FROM blocks WHERE category<>''")]
    con.close()

    images = not a.no_images
    if images:
        try:
            from PIL import Image as PILImage
            from openpyxl.drawing.image import Image as XLImage
        except ImportError:
            print("Pillow not installed: exporting without thumbnails")
            images = False

    wb = Workbook()
    ws = wb.active
    ws.title = "Blocks"
    hdr_font = Font(bold=True, color="FFFFFF")
    hdr_fill = PatternFill("solid", fgColor="44546A")
    key_fill = PatternFill("solid", fgColor="E7E6E6")
    key_font = Font(color="595959")
    ro_font = Font(color="7F7F7F")
    top = Alignment(vertical="top", wrap_text=True)
    unlocked = Protection(locked=False)
    for c, (h, w) in enumerate(zip(HEADERS, WIDTHS), start=1):
        cell = ws.cell(row=1, column=c, value=h)
        cell.font = hdr_font; cell.fill = hdr_fill
        ws.column_dimensions[cell.column_letter].width = w
    for i, (f, cat, desc, note, src, mod, thumb) in enumerate(rows, start=2):
        vals = [None, f, cat or None, desc or None, note or None, src or None, mod or None]
        for c, v in enumerate(vals, start=1):
            cell = ws.cell(row=i, column=c, value=v)
            cell.alignment = top
        ws.cell(row=i, column=2).fill = key_fill
        ws.cell(row=i, column=2).font = key_font
        for c in (3, 4, 5):
            ws.cell(row=i, column=c).protection = unlocked
        for c in (6, 7):
            ws.cell(row=i, column=c).font = ro_font
        ws.row_dimensions[i].height = 40 if images else 18
        if images and thumb:
            try:
                im = PILImage.open(io.BytesIO(thumb)).convert("RGBA")
                im.thumbnail((THUMB_PX, THUMB_PX))
                bg = PILImage.new("RGBA", (THUMB_PX, THUMB_PX), (33, 40, 48, 255))
                bg.paste(im, ((THUMB_PX - im.width) // 2, (THUMB_PX - im.height) // 2), im)
                buf = io.BytesIO(); bg.convert("RGB").save(buf, "PNG"); buf.seek(0)
                xi = XLImage(buf); xi.width = THUMB_PX; xi.height = THUMB_PX
                ws.add_image(xi, f"A{i}")
            except Exception as ex:
                print("thumb failed", f, ex)
    last = len(rows) + 1
    ws.freeze_panes = "C2"
    ws.auto_filter.ref = f"A1:G{last}"

    # Categories sheet
    cs = wb.create_sheet("Categories")
    cats = list(CATEGORIES) + sorted({c for c in db_cats if c and c not in CATEGORIES}, key=str.lower)
    cs["A1"] = "Category (dropdown list)"; cs["A1"].font = Font(bold=True)
    for k, c in enumerate(cats, start=2):
        cs.cell(row=k, column=1, value=c)
    cs["C1"] = "File"; cs["D1"] = "Suggested category (from file name; NOT imported, copy what you like)"
    cs["C1"].font = cs["D1"].font = Font(bold=True)
    for k, r in enumerate(rows, start=2):
        cs.cell(row=k, column=3, value=r[0]); cs.cell(row=k, column=4, value=suggest(r[0]) or None)
    cs.column_dimensions["A"].width = 28; cs.column_dimensions["C"].width = 42; cs.column_dimensions["D"].width = 30
    cs.freeze_panes = "A2"
    cs.auto_filter.ref = f"C1:D{len(rows) + 1}"

    dv = DataValidation(type="list", formula1=f"=Categories!$A$2:$A${len(cats) + 1}", allow_blank=True,
                        showErrorMessage=True, errorStyle="information",
                        errorTitle="Category", error="Not in the suggested list. Click OK to keep your own category.",
                        showInputMessage=True, promptTitle="Category", prompt="Pick a suggestion or type your own.")
    ws.add_data_validation(dv)
    dv.add(f"C2:C{max(last, 2000)}")

    # Light protection (no password): File column locked; Category/Description/Note editable; filter allowed.
    ws.protection.sheet = True
    ws.protection.autoFilter = False
    ws.protection.formatColumns = False
    ws.protection.formatRows = False
    ws.protection.selectLockedCells = False
    ws.protection.selectUnlockedCells = False

    wb.active = 0
    wb.save(out)
    print(f"Wrote {out}: {len(rows)} rows, {len(cats)} categories, images={'yes' if images else 'no'}")


if __name__ == "__main__":
    main()
