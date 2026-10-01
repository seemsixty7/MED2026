# MED-DotNet

AutoCAD .NET helper for MED. Database plus the MED Properties palette.

Future MED dialogs (replacing OpenDCL / AutoCAD DCL) stay in MED-DotNet.

## Build

Open MED-DotNet.sln in Visual Studio. Target x64. AutoCAD refs default to:

    C:\\Program Files\\Autodesk\\AutoCAD 2020

If yours differs, set AutoCADPath on the msbuild command or edit the csproj HintPath.

A successful build copies MED-DotNet.dll into ../../Support.

## Connect string

Support/MEDDataBaseSettings.dat  (copied here as the template)

    ConnectString=Server=DESKTOP-UGG2A0V\\MDDEVELOPMENT;Database=MED;Integrated Security=SSPI;

That is SqlClient syntax, not the OLEDB string in MEDVariables.lsp.

## Load

CSharpAdd.lsp NETLOADs MED-DotNet.dll. ProcessSQLStatementNET is the Lisp function MEDDatabase.lsp already calls.

## MED Properties palette

Command: MEDPROPERTIES (alias MEDPROPS)

Dockable palette. Pick one or many entities. Type dropdown at the top works like AutoCAD Properties:

- All (n) shows fields common to every selected MED type
- Conduit / Cable / Tray / Fitting / Equipment (n) shows that type only

Differing values show *VARIES*. Edit a field (Enter or leave the box) to write Xdata on every selected item of the filtered type. Measure is a checkbox; mixed selection is the third/indeterminate state.

Xdata keys match MEDBuildXData / MEDCHG: ITEM_TAG_, ITEM_RTAG, #ITEMSIZE, #ITEMCODE, #ITEMDIST, #ITEM_ALT, #ITEMDPTH, ITEM_MESR, #ITEMFLNG.

Fields by type:

- Conduit: Tag, Size, Code, Distance, Measure
- Cable: Tag, Related Tag, Alternate, Code, Distance, Measure
- Tray: Tag, Size, Code, Distance, Depth, Measure, Flange
- Fitting: Tag, Size, Alternate, Depth, Distance, Code, Flange
- Equipment: Tag, Code

SQL size/code dropdowns and Add Conduit/Cable/etc. stay out of the palette (commands/ribbon later).

## MED Records grid

Command: MEDRECORDS (alias MEDXDEDIT). Select one entity. Spreadsheet of every MED xdata record on it (multiple conduits/cables/fittings/equipment). Palette Records button does the same when exactly one entity is selected.

Code dropdowns list ITEMCODE + ITEMDESC from MEDType. Palette stays as the single-record editor; if the picked entity has more than one record the fields lock and you use the grid.

## MED 3D Library palette

Command: MED3DLIB (menu MED Main > MED 3D Library, ribbon/toolbar MED Data Tools > MED 3D Library). Dockable palette (fixed GUID, remembers position) over the 3D block DWGs in `Dwg3D\`
and their catalog `Dwg3D\Dwg3DCatalog.db` (same SQLite schema and DWG-header thumbnail extraction as the
standalone `tools\Dwg3DCatalog` app, so both can edit the same DB).

- Search box (file / description / note / category / source), category filter ((Uncategorized), (Missing files), (No preview)).
- View: List (thumbnails + file / category / description), Tiles (large thumbnails) or Grid (thumbnail, File, Category, Description, Note, Source; click a column header to sort, click an editable cell or press F2 to edit it in place, which saves to the DB right away). The choice is remembered.
- Large preview, editable Description / Category / Note, Save (Ctrl+S; also auto-saves when you move to another row).
- Excel button: Export to Excel writes a bulk-edit workbook (sheet Blocks with a thumbnail per row, File greyed and locked, Category dropdown from sheet Categories that still accepts free text). Import from Excel matches rows by File and applies only non-blank Category / Description / Note cells that differ (type (clear) to empty a field); it shows the counts first and backs up the DB to Dwg3DCatalog.db.bak-<timestamp>. Fallback scripts that do the same without AutoCAD: tools\Dwg3DExcel.
- Insert (or double-click / Enter; in Grid double-click the thumbnail or File cell): imports the DWG as a block named after the file (Database.ReadDwgFile + Database.Insert; an existing block of that name is reused), then jig for the insertion point, rotation prompt (Enter = 0), scale 1. You can also drag a row (or the preview) into the drawing; AutoCAD's own file-drop insert then runs.
- Open DWG opens the file read-only. Rescan adds new DWGs, flags missing ones and refreshes changed previews (Shift+click = re-extract all). Folder... picks another library folder.
- MED3DLIBINSERT inserts a library DWG from the command line (full path or file name in the library).
- MED3DLIBTEST is a non-UI self test (works in accoreconsole): reads the DB, rescans a temp copy of it, inserts one library DWG at 0,0,0.

Library folder: the per-user choice in `%APPDATA%\MED\MED3DLib.settings`, else `Dwg3D` next to the `Support` folder
the DLL was loaded from (`{dll}\..\Dwg3D`, `{dll}\Dwg3D`), else the developer path. SQLite uses the System.Data.SQLite
+ SQLite.Interop.dll already shipped beside MED-DotNet.dll.

Sources: `MED-DotNet\Dwg3DLib\`. `MED3DLib\MED3DLib.csproj` builds the same sources into a small standalone
`MED3DLib.dll` for testing; NETLOAD that only where the loaded MED-DotNet.dll does not already contain MED3DLIB
(both would register the same commands).
