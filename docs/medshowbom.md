# MEDSHOWBOM

Commands: `MEDSHOWBOM`, `MEDSHOW`. Alias `MEDSHOWSUM` opens with Summarize checked.

Current-drawing BOM from `MEDProject` for the active DWG name. Same idea as the 2012 `SHOW` browse: look at the extract; run `BOM` first if the grid is empty.

The 2012 dialog was a crude flat list (one row per reference, no summary). MED2026 adds filters, summarize, clipboard, and CSV. LISP `C:MEDSHOW` in `MEDMainDialogs-RedoWithCSharp.lsp` is not loaded.

![MEDSHOWBOM dialog](images/medshowbom.png)

MEDSHOWBOM dialog.

## Filters

Type: All, Conduit, Cable, Tray, Fitting, Equipment (assemblies). Equipment is `ITEM_TYPE=EQUIP`. Qty for equipment and fittings is each. Conduit / cable / tray qty in the table is inches; BOM qty is feet (`raw / 12`).

- **This project only** — limit to `_MEDPROJECT`.
- **Summarize (by type, code, size)** — rolls tags to `ALL TAGS`.
- Refresh, clipboard **Copy**, **Export CSV**.

## Extract

`BOM` walks the drawing and rewrites `MEDProject` for this file. Details in [database.md](database.md). Duplicate plan + section views of the same tray will double-count unless you `MEDSTRIP` the extra centerlines first ([tray.md](tray.md)).
