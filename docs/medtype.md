# MEDTYPE

Commands: `MEDTYPE`, `MEDTYPES`.

Excel-style grid on SQL table `MEDType`. Same idea as the 2012 guide: this is the catalog (warehouse). Codes stored on entities look up a description here. Primary key is `ITEMTYPE` + `ITEMCODE`. Code is unique per type.

The 2012 command opened a DCL browse/add dialog and wrote `MEDTYPE.dbf`. MED2026 is the C# grid against SQLite or SQL Server. There is no `MEDPACK` after edits.

![MEDTYPE grid](images/medtype.png)

MEDTYPE catalog grid. *Screenshot still needed — do not invent one. `docs/images/acad-ui.png` shows the grid in a wider AutoCAD shot.*

## Columns

| Column | Header | Notes |
| --- | --- | --- |
| ITEMTYPE | Type | CONDUIT, CABLE, TRAY, FITTING, EQUIP |
| ITEMCODE | Code | Integer. Unique with type. |
| ITEMDESC | Description | Catalog text |
| ITEM_GRP | Group | Cable Type for the Cable palette. Details: grouping. No group → detail does not appear in `DETAIL` / `LTG` / … |
| ITEMKEY1–4 | Key1–4 | Details: number, drawing, block/slide, layer set. See [database.md](database.md) |
| USER1–4 | User1–4 | Details: DETNUM fill, insert function, sort. Tray USER1 = section length (ft) for reporting |

Type filter: All / Conduit / Cable / Tray / Fitting / Equipment. Find box matches description, code, Key1, and group.

## Edit

- Add / delete rows on the grid.
- Ctrl+C / Ctrl+V copy and paste cells.
- Ctrl+D fill down.
- Ctrl+S save (also Save button). Closing with unsaved changes asks Yes / No / Cancel.
- Export CSV writes the **current filter**.
- Import CSV **upserts** on ITEMTYPE+ITEMCODE. CSV must have those two columns.
- `EQUIPMENT` in a CSV type cell normalizes to `EQUIP`.

Do not treat this as a day-to-day drafting command. Set the catalog up, then draw. Details are the usual mid-job add.

2012 walkthrough added a bogus EQUIP row then cancelled. Same rule: unique code per type (1–999 in that example; MED2026 does not cap you at 999), fill group / keys if it must show in the detail insert list.
