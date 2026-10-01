# Dwg3DExcel

Excel bulk edit for the 3D block catalog `Dwg3D\Dwg3DCatalog.db` (the same workbook layout as the
MED3DLIB palette's Excel > Export / Import). Python 3.12 + openpyxl (+ Pillow for thumbnails):

    py -3.12 -m pip install --user openpyxl pillow

Export (reads the DB read-only, writes `Dwg3D\Dwg3DCatalog_BulkEdit.xlsx` by default):

    py -3.12 tools\Dwg3DExcel\dwg3d_export_xlsx.py [--db PATH] [--out PATH] [--no-images]

Import (default workbook `Dwg3D\Dwg3DCatalog_BulkEdit.xlsx`; try `--dry-run` first):

    py -3.12 tools\Dwg3DExcel\dwg3d_import_xlsx.py [XLSX] [--db PATH] [--dry-run]

Import rules: match by File; only non-blank Category / Description / Note cells that differ are written;
`(clear)` empties a field; the DB is copied to `Dwg3DCatalog.db.bak-YYYYMMDD-HHMMSS` first.
Close the workbook in Excel before importing.

The sheet is protected without a password (Review > Unprotect Sheet) so the File key column is not
edited by accident; filtering works while protected, sorting needs Unprotect.
Category suggestions per file (sheet Categories, columns C:D) come from `dwg3d_categories.py` and are
not imported.
