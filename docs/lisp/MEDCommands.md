# MEDCommands.lsp

`Support\MEDCommands.lsp` - Catalog/BOM commands (BOM, MEDLIST, MEDSTRIP, CHGSIZE, CHGTAG, MEDDBBACKUP/RESTORE), leaders, text style shortcuts, section marks, isolate.

Loaded by MEDCore (order 12). 31 defun(s): 27 command(s), 4 function(s). (`c:ddMEDlist` / DDMEDLIST and its dialog helpers were removed 2026-10.)

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:LoadLayers`](#cloadlayers) | command |
| 19 | [`c:MEDlist`](#cmedlist) | command |
| 51 | [`ShowMEDListData`](#showmedlistdata) | function |
| 113 | [`med_text`](#med_text) | function |
| 159 | [`c:alead`](#calead) | command |
| 163 | [`c:glead`](#cglead) | command |
| 166 | [`c:grab`](#cgrab) | command |
| 170 | [`c:al`](#cal) | command |
| 174 | [`c:gl`](#cgl) | command |
| 178 | [`c:T1`](#ct1) | command |
| 181 | [`c:T2`](#ct2) | command |
| 184 | [`c:T3`](#ct3) | command |
| 187 | [`c:B1`](#cb1) | command |
| 190 | [`c:B2`](#cb2) | command |
| 193 | [`c:B3`](#cb3) | command |
| 197 | [`c:cd`](#ccd) | command |
| 303 | [`c:sect`](#csect) | command |
| 321 | [`c:sectd`](#csectd) | command |
| 326 | [`c:isolate`](#cisolate) | command |
| 373 | [`c:unisolate`](#cunisolate) | command |
| 388 | [`c:MEDstrip`](#cmedstrip) | command |
| 406 | [`c:chgsize`](#cchgsize) | command |
| 523 | [`c:unj`](#cunj) | command |
| 553 | [`c:hubs`](#chubs) | command |
| 617 | [`c:detagupd`](#cdetagupd) | command |
| 647 | [`c:BOM`](#cbom) | command |
| 670 | [`MEDFixForExcelParse`](#medfixforexcelparse) | function |
| 692 | [`c:MEDDBBackup`](#cmeddbbackup) | command |
| 720 | [`c:MEDDBRestore`](#cmeddbrestore) | command |
| 730 | [`MEDDatabaseRestore`](#meddatabaserestore) | function |
| 758 | [`c:chgtag`](#cchgtag) | command |

## c:LoadLayers

`(c:LoadLayers / Laylist)`  - line 2-8

Creates the MED layers from the Layers1 table (colour, linetype, lineweight). User entry: [LOADLAYERS](../command-reference.md#loadlayers).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: DB: `processsqlstatement`
- **Referenced**: 0

## c:MEDlist

`(c:MEDlist / medent)`  - line 19-50

Command-line listing of an entity's MED xdata with catalog descriptions. User entry: [MEDLIST](../command-reference.md#medlist).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `applist`, `numapps`, `appcnt`, `appnm`, `appdata`, `datalen`, `applen`, `numtags`, `tagcnt`, `printdata`; Xdata: reads xdata
- **Referenced**: 1

## ShowMEDListData

`(ShowMEDListData MEDAppName TagCount MEDAppData MEDEntity / smld-count smld-printlist smld-applen smld-datacnt smld-code smld-mesr smld-length)`  - line 51-111

Prints one MED xdata record for MEDLIST.

- **Arguments**: `MEDAppName`, `TagCount`, `MEDAppData`, `MEDEntity`
- **Returns**: value of the last expression: `smld-printlist`
- **Side effects**: Globals set (not declared local): `smld-item`, `smld-itemstring`, `smld-size`
- **Referenced**: 1

## med_text

`(med_text txt_specifier txt_startpoint)`  - line 113-157

Sets the text style/layer for a MED text spec ("T1", "B2", ...) and starts DTEXT.

- **Arguments**: `txt_specifier`, `txt_startpoint`
- **Returns**: value of the last expression: `(if txt_startpoint (command "dtext" "s" txtstylnm "j" (nth 2 txt_startpoint) (nth 0 txt_startpoint) (nth 1 txt...`
- **Side effects**: Globals set (not declared local): `layerdata`, `txtstydata`, `txtstylnm`, `txtstyleheight`, `newlayname`, `oldlayname`, `newlaycol`, `oldlaycol`; Layers: `layerdata`; AutoCAD commands: `DTEXT`
- **Prompts**: `*********Layer Info Not Found Using Current Layer`
- **Referenced**: 11

## c:alead

`(c:alead)`  - line 159-161

Arrow leader. User entry: [ALEAD](../command-reference.md#alead).

- **Arguments**: none
- **Returns**: value of the last expression: `(medleader nil T 1.0 nil)`
- **Referenced**: 0

## c:glead

`(c:glead)`  - line 163-165

Hook ("grab") leader / add a hoop at a line end. User entry: [GLEAD](../command-reference.md#glead).

- **Arguments**: none
- **Returns**: value of the last expression: `(medleader "grabit" T 0.5 nil)`
- **Referenced**: 0

## c:grab

`(c:grab)`  - line 166-168

Hook ("grab") leader / add a hoop at a line end. User entry: [GRAB](../command-reference.md#grab).

- **Arguments**: none
- **Returns**: value of the last expression: `(medleader "grabit" T 0.5 nil)`
- **Referenced**: 0

## c:al

`(c:al)`  - line 170-172

Arrow leader. User entry: [AL](../command-reference.md#al).

- **Arguments**: none
- **Returns**: value of the last expression: `(medleader nil nil 1.0 nil)`
- **Referenced**: 0

## c:gl

`(c:gl)`  - line 174-176

Hook ("grab") leader / add a hoop at a line end. User entry: [GL](../command-reference.md#gl).

- **Arguments**: none
- **Returns**: value of the last expression: `(medleader "grabit" nil 0.5 nil)`
- **Referenced**: 0

## c:T1

`(c:T1)`  - line 178-180

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [T1](../command-reference.md#t1).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "T1" nil)`
- **Referenced**: 2

## c:T2

`(c:T2)`  - line 181-183

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [T2](../command-reference.md#t2).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "T2" nil)`
- **Referenced**: 2

## c:T3

`(c:T3)`  - line 184-186

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [T3](../command-reference.md#t3).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "T3" nil)`
- **Referenced**: 2

## c:B1

`(c:B1)`  - line 187-189

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [B1](../command-reference.md#b1).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "B1" nil)`
- **Referenced**: 2

## c:B2

`(c:B2)`  - line 190-192

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [B2](../command-reference.md#b2).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "B2" nil)`
- **Referenced**: 2

## c:B3

`(c:B3)`  - line 193-195

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted). User entry: [B3](../command-reference.md#b3).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "B3" nil)`
- **Referenced**: 2

## c:cd

`(c:cd / ex len y1 y2 x1 x2 dirxy coor cord coord inspt rot part1 part2 sub trl usepoint1 usepoint2)`  - line 197-301

Coordinate text from a grid line or two points. User entry: [CD](../command-reference.md#cd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `orgosmode`, `orgorthomode`, `test1`, `test2`, `txtstyle`; Layers: `_COORDS`; AutoCAD commands: `TEXT`
- **Referenced**: 0

## c:sect

`(c:sect / pt1 pt2 val)`  - line 303-319

Section marks in plan (defined in MEDCommands.lsp; overridden by medtag.lsp, which loads later). User entry: [SECT](../command-reference.md#sect).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `curatdia`; Layers: `_MEDTEXT`; AutoCAD commands: `COPY`, `INSERT`
- **Referenced**: 2
- **Duplicate**: also defined in Support\medtag.lsp:2; replaced at load time by Support\medtag.lsp:2

## c:sectd

`(c:sectd)`  - line 321-324

Inserts the dynamic section-mark block sect-dyn on the MED text layer. User entry: [SECTD](../command-reference.md#sectd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:isolate

`(c:isolate)`  - line 326-372

Hides everything except entities whose detail/equipment code matches a picked entity or typed code. User entry: [ISOLATE](../command-reference.md#isolate).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "layer" "F" "*" "")`
- **Side effects**: Globals set (not declared local): `dent`, `dentss`, `sslen`, `cnt`, `data`, `dcode`, `isolayer`, `cntval`, `num`, `ISO_LIST`, `_CURRLAY`, `ent`, `entlay`; Xdata: reads xdata, `MED_TEMP_ISOLATE`; Layers: `isolayer` (LAYER command / CLAYER); AutoCAD commands: `CHANGE`, `LAYER`
- **Referenced**: 0

## c:unisolate

`(c:unisolate)`  - line 373-386

Restores entities hidden by ISOLATE. User entry: [UNISOLATE](../command-reference.md#unisolate).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "REGEN")`
- **Side effects**: Globals set (not declared local): `ent`, `entlay`, `data`, `new`, `old`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmod`; AutoCAD commands: `LAYER`, `REGEN`
- **Referenced**: 0

## c:MEDstrip

`(c:MEDstrip)`  - line 388-404

Removes all MED xdata from the selected entities. User entry: [MEDSTRIP](../command-reference.md#medstrip).

- **Arguments**: none
- **Returns**: printed text (message); value not meant to be used
- **Side effects**: Globals set (not declared local): `stripset`, `stripnum`, `stripcnt`, `stripent`, `strip_apps`; Xdata: writes xdata, reads xdata
- **Referenced**: 0

## c:chgsize

`(c:chgsize / newsz chgapp chgss chglen allsiz taglst codlst sizlst dislst msrlst altlst dptlst rtglst medtag medsiz medcod medmsr meddis medalt meddpt xdlist)`  - line 406-521

Changes the size in the MED xdata of a selection of conduits or fittings. User entry: [CHGSIZE](../command-reference.md#chgsize).

- **Arguments**: none
- **Returns**: value of the last expression: `(while (< chgcnt chglen) (setq chgent (ssname chgss chgcnt) appdata(xdataget chgent chgapp) ) (if appdata (pro...`
- **Side effects**: Globals set (not declared local): `chgcnt`, `chgent`, `appdata`, `applen`, `numtag`, `tagcnt`, `medrtg`; Xdata: writes xdata, reads xdata
- **Referenced**: 0

## c:unj

`(c:unj / ans pt1 pt2 ang blk)`  - line 523-547

Inserts a UNJ / UNJC fitting at a point, aligned to a reference entity. User entry: [UNJ](../command-reference.md#unj).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (or (= _CLETT "A") (= _CLETT "B")) (progn (initget 1 "UNJ UNJC") (setq ans (getkword "\nType of fitting UN...`
- **Side effects**: AutoCAD commands: `INSERT`
- **Referenced**: 0

## c:hubs

`(c:hubs / hubpt hinspt bxent bxins refang)`  - line 553-615

Adds hubs to an RS junction box at picked locations. User entry: [HUBS](../command-reference.md#hubs).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 2

## c:detagupd

`(c:detagupd / index_val max_y max_x result tlist1 tlist2 fname fn)`  - line 617-645

Refreshes typical counts on existing detail bubbles. User entry: [DETAGUPD](../command-reference.md#detagupd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `detail_lst`
- **Referenced**: 1

## c:BOM

`(c:BOM)`  - line 647-663

Extracts all MED xdata in the drawing to MEDProject (deletes this drawing's old rows first). Not live. User entry: [BOM](../command-reference.md#bom).

- **Arguments**: none
- **Returns**: value of the last expression: `(if MEDallss (progn (princ "\nDeleting Old Records") (MEDProcessSQLStatement (strcat "DELETE FROM MEDProject W...`
- **Side effects**: Globals set (not declared local): `MEDallss`, `allsslen`, `allcnt`, `boment`; Xdata: reads/writes xdata directly (-3 group / regapp); DB: `medprocesssqlstatement`, `medsendentitydatatobom`
- **Referenced**: 1

## MEDFixForExcelParse

`(MEDFixForExcelParse StringToFix)`  - line 670-689

Doubles/escapes double quotes in a string so the BOM CSV parses in Excel.

- **Arguments**: `StringToFix`
- **Returns**: value of the last expression: `ReturnString`
- **Side effects**: Globals set (not declared local): `Quotefound`, `ReturnString`, `StartPos`, `QuoteFound`, `CommaFound`
- **Referenced**: 1

## c:MEDDBBackup

`(c:MEDDBBackup)`  - line 692-719

Writes a CSV snapshot of MEDType (MEDTYPE-DB-Backup.csv) under the MED directory. User entry: [MEDDBBACKUP](../command-reference.md#meddbbackup).

- **Arguments**: none
- **Returns**: value of the last expression: `(close BackupFileHandle)`
- **Side effects**: Globals set (not declared local): `MEDTYPEDataBaseRecords`, `BackupPathLocation`, `BackupFileHandle`, `RecordLine`, `usethis`; DB: `medprocesssqlstatement`
- **Referenced**: 0

## c:MEDDBRestore

`(c:MEDDBRestore)`  - line 720-729

Restores MEDType rows from the CSV snapshot; asks project name (ALL) and whether to delete first. User entry: [MEDDBRESTORE](../command-reference.md#meddbrestore).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (/= DataSetToRestore "") (MEDDatabaseRestore (nth 0 SelectFile) DataSetToRestore) )`
- **Side effects**: Globals set (not declared local): `EquipCodeStart`, `selectfile`, `DataSetToRestore`; DB: `meddatabaserestore`, `medprocesssqlstatement`
- **Referenced**: 0

## MEDDatabaseRestore

`(MEDDatabaseRestore FileImportName ProjectToRestore)`  - line 730-756

Worker for MEDDBRESTORE: reads the CSV and inserts rows (optionally deleting first).

- **Arguments**: `FileImportName`, `ProjectToRestore`
- **Returns**: value of the last expression: `(if (/= ProjectToRestore "ALL") (progn (setq DatatoRestore (list)) (foreach RecordItem (cdr FileImportData) (i...`
- **Side effects**: Globals set (not declared local): `fileimporthandle`, `fileimportdata`, `linedata`, `DatatoRestore`
- **Prompts**: `MED Database Restore utility`; `DeleteRecords prior to restore [Yes/No]:`
- **Referenced**: 1

## c:chgtag

`(c:chgtag / newsz chgapp chgss chglen allsiz taglst codlst sizlst dislst msrlst altlst dptlst rtglst medtag medsiz medcod medmsr meddis medalt meddpt xdlist)`  - line 758-871

Changes the tag in the MED xdata of a selection. (Prompt text still says "New Size".) User entry: [CHGTAG](../command-reference.md#chgtag).

- **Arguments**: none
- **Returns**: value of the last expression: `(while (< chgcnt chglen) (setq chgent (ssname chgss chgcnt) appdata(xdataget chgent chgapp) ) (if appdata (pro...`
- **Side effects**: Globals set (not declared local): `chgcnt`, `chgent`, `appdata`, `applen`, `numtag`, `tagcnt`, `medrtg`; Xdata: writes xdata, reads xdata
- **Referenced**: 0

