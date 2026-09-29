# Database

Connection file: `Support\MEDDataBaseSettings.dat` (installer writes it; machine-local, not in git).

SQLite (default):

```
Provider=SQLite
ConnectString=Data Source=C:\MED2026\Data\MED.db
```

SQL Server (optional, shops that already have it):

```
Provider=SqlServer
ConnectString=Server=YOURSERVER\INSTANCE;Database=MED;Integrated Security=SSPI;
```

`ConnectString` is ADO.NET (`System.Data.SQLite` or SqlClient), not OLEDB. Template: `Support\MEDDataBaseSettings.example.dat`.

The 2012 guide used Access / FoxPro `.dbf` (`MEDTYPE.dbf`, `PROJECT.dbf`) and `MEDPACK` after catalog edits. MED2026 does not. Do not pack, reindex, or open the catalog in Access.

## Seed tables (`Data\MED.db`)

| Table | Role |
| --- | --- |
| MEDType | Catalog. Seeded. Primary key `ITEMTYPE` + `ITEMCODE`. |
| MEDProject | BOM extract. Empty at install. Written at runtime by `BOM`. |
| Layers1 | Layer standards. Seeded. `LOADLAYERS` reads this. |
| MEDUsers | Seed is empty. Installer inserts the current Windows login (`UserType=User`). |
| MEDConduitOD | Conduit outside diameter by conduit type + trade size. Seeded. Created at runtime if missing (see below). |

Same split as the 2012 guide: `MEDType` is the warehouse; `MEDProject` is what this drawing used. Entity xdata stores the code (and sizes/tags). The description is looked up in `MEDType` by type+code.

SQL Server is optional. Do not point a fresh install at someone else's live instance.

The public seed has no client-specific catalog rows.

## Catalog columns (`MEDType`)

Edit with [MEDTYPE](medtype.md), not a desktop database tool.

| Column | 2012 name | Used for |
| --- | --- | --- |
| ITEMTYPE | ITEM_TYPE | CONDUIT, CABLE, TRAY, FITTING, EQUIP |
| ITEMCODE | ITEM_CODE | Integer. Unique **per type**. |
| ITEMDESC | ITEM_DESC | Catalog text looked up at extract and in MEDLIST |
| ITEM_GRP | ITEM_GRP | Cable Type on the Cable palette (Building Wire, Tray Cable, Ground Cable, Instrument Cable, Residential Cable). Details: grouping (Lighting, Grounding, …). Empty group hides a detail from `DETAIL` / `LTG` / … |
| ITEMKEY1 | ITEMKEY1 | Details: detail number |
| ITEMKEY2 | ITEMKEY2 | Details: drawing number the detail lives on |
| ITEMKEY3 | ITEMKEY3 | Details: block (and slide) name to insert. Blank + `opt_eq_ins` in USER2 → pick an entity to attach |
| ITEMKEY4 | ITEMKEY4 | Details: layer-set name from `med.spc` |
| USER1 | USER1 | Details: value for a `DETNUM` attribute if the block has one. Tray: section length in feet (reporting; MED does not auto-cut tray to this) |
| USER2 | USER2 | Details: insert function name (usually `opt_eq_ins`) |
| USER3 | USER3 | EQUIP: original equipment code kept by the project remap (`MEDRemapEQCodeToProjectCode`). CABLE: cable outside diameter in inches, stored as numeric text (e.g. `0.624`). Blank = not sourced. Other types: unused |
| USER4 | USER4 | Detail sort order in the insert dialog |

Adding catalog rows is not a day-to-day drafting command. Set the project catalog up, then draw. Details are the usual exception — they get added through a job.

## Conduit / cable OD

`MEDConduitOD` (primary key `ConduitCode` + `TradeSize`):

| Column | Meaning |
| --- | --- |
| ConduitCode | CONDUIT `ITEMCODE` in `MEDType` (1 Rigid Steel, 2 PVC-coated rigid, 3 Rigid non-metallic, 4 EMT, 5 ENT, 6 IMC, 7 PVC-coated flexible) |
| ConduitDesc | Copy of the CONDUIT `ITEMDESC` for readability only (lookups use the code) |
| TradeSize | Trade size text: `1/2`, `3/4`, `1`, `1-1/4`, … |
| TradeSizeDec | Trade size as a number (0.5, 1.25, …). Matches the conduit xdata size (`#ITEMSIZE`) |
| OD_in | Outside diameter, inches. NULL = unknown (falls back) |
| Source | Data sheet / standard the value came from |

`MAKE3DCONDUIT` / `M3D` (and the vertical-conduit solids) size the solid with `med_conduit_od` (`MEDFunctions.lsp`): table value for the conduit's code + size, otherwise the old steel-pipe OD from `getsize`. Without the table, horizontal conduit output is unchanged.

Seed values ship in `Data\seed\conduit_od.csv` (conduit) and `Data\seed\cable_od_sources.csv` (CABLE `USER3`, with the source per row). At NETLOAD (and when MEDTYPE opens) MED-DotNet (`MedODSeed.cs`):

1. Creates `MEDConduitOD` if missing (SQLite or SQL Server syntax).
2. Inserts seed rows that are missing; fills `OD_in` only where it is NULL. Values you edited are never overwritten.
3. Sets CABLE `USER3` only where it is blank **and** `ITEMDESC` still matches the seed row.

The patch installer ships the two CSVs, not `MED.db`. Edit ODs in the table / MEDTYPE, not in the CSVs (CSV edits only reach blanks). `tools\build_od_seed.py` regenerates the CSVs and the seed `MED.db` from the transcribed data-sheet tables.

`MEDDBBACKUP` / `MEDDBRESTORE` write/read a CSV snapshot of `MEDType` under the MED directory (`MEDTYPE-DB-Backup.csv`). That is the 2026 stand-in for dumping the catalog. It is not `MEDPACK`.

## BOM extract (`MEDProject`)

`BOM` (`Support\MEDCommands.lsp`) is still the extract. It is not dynamic.

1. Reads the current `DWGNAME`.
2. `DELETE FROM MEDProject` for that drawing + `_MEDPROJECT` + `DWGPREFIX` + Windows login.
3. Selection set of every entity with `MED*` xdata.
4. One row per material record.

| Field | Meaning |
| --- | --- |
| ITEM_TYPE | CONDUIT, CABLE, TRAY, FITTING, EQUIP |
| ITEM_TAG_ | Tag you typed (or NONE) |
| ITEM_RTAG | Cable related tag; others N/A |
| ITEM_QTY_ | Measured length for conduit / cable / tray when Measure is on; Dist when Measure is off; 1 for fittings and equipment |
| ITEM_SIZE | Size for conduit / tray / fitting. Cable: count of conductors in the reference. Equipment: 0 |
| ITEM_ALT_ | Reducer alternate size; else 0 |
| ITEM_DPTH | Tray / tray-fitting depth; else 0 |
| ITEM_CODE | Catalog code; with type, looks up `MEDType` |
| ITEM_DESC | Copied from `MEDType` at extract time |
| ITEM_HAND | Entity handle (duplicates are normal — one entity, several records) |
| ENT_TYPE | AutoCAD entity type. Measurable raceway is POLYLINE / LWPOLYLINE |
| ITEM_DWG_ | Drawing file name |
| ITEM_MSR_ | T = measure at extract; F for fittings and details |

Browse with [MEDSHOWBOM](medshowbom.md). The 2012 `SHOW` dialog was a flat list with no summary. MED2026 adds type filters, project filter, summarize-by type/code/size, clipboard, and CSV. Qty for conduit / cable / tray in the table is inches; the dialog reports feet (`raw / 12`). Equipment and fittings are each.

Run `BOM` again after you change the drawing. Stale `MEDProject` rows are not your DWG.
