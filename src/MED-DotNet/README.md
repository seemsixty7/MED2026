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
