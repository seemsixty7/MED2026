# MEDTYPE

Commands: `MEDTYPE`, `MEDTYPES`.

Excel-style grid on SQL table `MEDType`. Same idea as the 2012 guide: this is the catalog (warehouse). Codes stored on entities look up a description here. Primary key is `ITEMTYPE` + `ITEMCODE`. Code is unique per type.

![MEDTYPE grid](images/medtype.png)

MEDTYPE catalog grid.

## Columns

| Column | Header | Notes |
| --- | --- | --- |
| ITEMTYPE | Type | CONDUIT, CABLE, TRAY, FITTING, EQUIP |
| ITEMCODE | Code | Integer. Unique with type. |
| ITEMDESC | Description | Catalog text |
| ITEM_GRP | Group | Grouping (details historically) |
| ITEMKEY1–4 | Key1–4 | Extra keys |
| USER1–4 | User1–4 | Extra user fields |

Type filter: All / Conduit / Cable / Tray / Fitting / Equipment. Find box matches description, code, Key1, and group.

## Edit

- Add / delete rows on the grid.
- Ctrl+C / Ctrl+V copy and paste cells.
- Ctrl+D fill down.
- Ctrl+S save (also Save button). Closing with unsaved changes asks Yes / No / Cancel.
- Export CSV writes the **current filter**.
- Import CSV **upserts** on ITEMTYPE+ITEMCODE. CSV must have those two columns.
- `EQUIPMENT` in a CSV type cell normalizes to `EQUIP`.

Do not treat this as a day-to-day drafting command. Set the catalog up, then draw.
