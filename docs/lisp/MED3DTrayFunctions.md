# MED3DTrayFunctions.lsp

`Support\MED3DTrayFunctions.lsp` - 3D cable tray and tray fittings (MAKE3DTRAY, med3d-tray-build).

Loaded by MEDCore (order 17). 31 defun(s): 7 command(s), 24 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 7 | [`MEDDraw3DTray`](#meddraw3dtray) | function |
| 21 | [`c:traytest`](#ctraytest) | command |
| 24 | [`MEDConvertTrayTo3D`](#medconverttrayto3d) | function |
| 67 | [`MEDBuild3DTrayBase`](#medbuild3dtraybase) | function |
| 92 | [`MEDBuild3DTrayFlange`](#medbuild3dtrayflange) | function |
| 140 | [`MEDBuild3DTrayFlange`](#medbuild3dtrayflange) | function |
| 195 | [`MEDBuild3DTrayFitFlange`](#medbuild3dtrayfitflange) | function |
| 240 | [`MEDBuild3DTrayFitFlange`](#medbuild3dtrayfitflange) | function |
| 295 | [`c:QVTest`](#cqvtest) | command |
| 310 | [`c:trayfittest`](#ctrayfittest) | command |
| 313 | [`MEDConvertTrayElbowTo3D`](#medconverttrayelbowto3d) | function |
| 335 | [`MEDDraw3DTrayFit`](#meddraw3dtrayfit) | function |
| 368 | [`MEDBuild3DTrayFitBase`](#medbuild3dtrayfitbase) | function |
| 386 | [`MEDSet3DTrayLayer`](#medset3dtraylayer) | function |
| 406 | [`MEDNew3DSolidsAfter`](#mednew3dsolidsafter) | function |
| 418 | [`med3d-tray-build`](#med3d-tray-build) | function |
| 464 | [`c:Make3DTray`](#cmake3dtray) | command |
| 468 | [`*error*`](#error) | function |
| 528 | [`MEDConvertTrayFittingsTo3D`](#medconverttrayfittingsto3d) | function |
| 566 | [`MEDCopyEntity`](#medcopyentity) | function |
| 579 | [`MEDDraw3DTrayTeeCrossFit`](#meddraw3dtrayteecrossfit) | function |
| 639 | [`MEDBuild3DTrayBaseFromOutline`](#medbuild3dtraybasefromoutline) | function |
| 647 | [`c:trayteetest`](#ctrayteetest) | command |
| 650 | [`MEDConvertTrayTeeTo3D`](#medconverttrayteeto3d) | function |
| 672 | [`MEDBuild3DTrayFlangeFromEntity`](#medbuild3dtrayflangefromentity) | function |
| 723 | [`MEDDraw3DTrayStraightReducer`](#meddraw3dtraystraightreducer) | function |
| 761 | [`MEDDraw3DTrayLeftOrRightReducer`](#meddraw3dtrayleftorrightreducer) | function |
| 820 | [`c:trayretest`](#ctrayretest) | command |
| 823 | [`MEDConvertTrayReducerTo3D`](#medconverttrayreducerto3d) | function |
| 846 | [`c:traylrretest`](#ctraylrretest) | command |
| 849 | [`MEDConvertTrayLRReducerTo3D`](#medconverttraylrreducerto3d) | function |

## MEDDraw3DTray

`(MEDDraw3DTray TrayDataList UCSData / TrayPoint1 TrayPoint2 TrayWidth TrayDepth TrayFlange TrayBaseEnt TrayFlangeEnt1 TrayFlangeEnt2)`  - line 7-20

3D tray straight: base + two flanges, unioned.

- **Arguments**: `TrayDataList`, `UCSData`
- **Returns**: value of the last expression: `TrayBaseEnt`
- **Side effects**: AutoCAD commands: `UNION`
- **Referenced**: 1

## c:traytest

`(c:traytest)`  - line 21-23

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [TRAYTEST](../command-reference.md#traytest).

- **Arguments**: none
- **Returns**: value of the last expression: `(MEDConvertTrayto3d (car (entsel)))`
- **Referenced**: 0

## MEDConvertTrayTo3D

`(MEDConvertTrayTo3D TrayEntity / TrayPoint1 TrayPoint2 Tray3DEnt TrayTag TraySize TrayCode TrayDist TrayLen TrayDesc TraySizeStr)`  - line 24-65

Tray entity to 3D solid.

- **Arguments**: `TrayEntity`
- **Returns**: value of the last expression: `Tray3DEnt`
- **Side effects**: Globals set (not declared local): `TrayEntityData`, `TrayEntityUCSData`, `TrayPointlist`, `TrayPointList`, `TrayEntityPoint1`, `TrayEntityPoint2`, `TrayMEDData`, `TrayUCSData`; Xdata: writes xdata, reads xdata; AutoCAD commands: `UCS`
- **Referenced**: 2

## MEDBuild3DTrayBase

`(MEDBuild3DTrayBase MB3DTB_TrayData TrayUCSData / TrayPoint1 TrayPoint2 TrayAngle)`  - line 67-91

3D tray base plate.

- **Arguments**: `MB3DTB_TrayData`, `TrayUCSData`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `CheckAngle`, `ExtrudeDir`, `t1`, `t2`, `TrayWidth`, `TrayBasePoint1`, `TrayBasePoint2`, `TrayBasePoint3`, `TrayBasePoint4`, `TrayReturnEntity`; AutoCAD commands: `3DPOLY`, `EXTRUDE`, `UCS`
- **Referenced**: 1

## MEDBuild3DTrayFlange

`(MEDBuild3DTrayFlange MB3DTF_TrayData MB3DTF_FlipValue UCSData / TrayPoint1 TrayPoint2)`  - line 92-137

3D tray flange (first copy; overridden by line 140).

- **Arguments**: `MB3DTF_TrayData`, `MB3DTF_FlipValue`, `UCSData`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayWidth`, `TrayDepth`, `TrayFlange`, `TrayLength`, `TrayAngle`, `TrayBasePoint1`, `TrayFlangePoint1`, `TrayFlangePoint2`, `TrayFlangePoint3`, `TrayFlangePoint4`, `TrayFlangePoint5`, `TrayFlangePoint6`, `TrayFlangePoint7`, `TrayReturnEntity`; AutoCAD commands: `3DPOLY`, `EXTRUDE`, `UCS`
- **Referenced**: 3
- **Duplicate**: also defined in Support\MED3DTrayFunctions.lsp:140; replaced at load time by Support\MED3DTrayFunctions.lsp:140

## MEDBuild3DTrayFlange

`(MEDBuild3DTrayFlange MB3DTF_TrayData MB3DTF_FlipValue UCSData / TrayPoint1 TrayPoint2)`  - line 140-191

Work on Reverse Flange

- **Arguments**: `MB3DTF_TrayData`, `MB3DTF_FlipValue`, `UCSData`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayWidth`, `TrayDepth`, `TrayFlange`, `TrayLength`, `TrayAngle`, `TrayBasePoint1`, `TrayFlangePoint1`, `TrayFlangePoint2`, `TrayFlangePoint3`, `FlangeFLIP`, `TrayFlangePoint4`, `TrayFlangePoint5`, `TrayFlangePoint6`, `TrayFlangePoint7`, `TrayReturnEntity`; AutoCAD commands: `3DPOLY`, `EXTRUDE`, `UCS`
- **Referenced**: 3
- **Duplicate**: also defined in Support\MED3DTrayFunctions.lsp:92; this definition loads last and wins

## MEDBuild3DTrayFitFlange

`(MEDBuild3DTrayFitFlange MB3DTF_TrayData MB3DTF_FlipValue MB3DTF_Entity NotVerticalTrayFlag / TrayPoint1 TrayPoint2 TrayAngle)`  - line 195-236

This function simply needs same info as tray, but then pass it the offset entity form the MED Centerline Copy and it will create it nice and smooth

- **Arguments**: `MB3DTF_TrayData`, `MB3DTF_FlipValue`, `MB3DTF_Entity`, `NotVerticalTrayFlag`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayWidth`, `TrayDepth`, `TrayFlange`, `TrayLength`, `TrayBasePoint1`, `TrayFlangePoint1`, `TrayFlangePoint2`, `TrayFlangePoint3`, `ExtrudeEntity`, `TrayFlangePoint4`, `TrayFlangePoint5`, `TrayFlangePoint6`, `TrayFlangePoint7`, `t1`, `PathEntity` ...; AutoCAD commands: `3DPOLY`, `COPY`, `EXTRUDE`, `OFFSET`
- **Referenced**: 8
- **Duplicate**: also defined in Support\MED3DTrayFunctions.lsp:240; replaced at load time by Support\MED3DTrayFunctions.lsp:240

## MEDBuild3DTrayFitFlange

`(MEDBuild3DTrayFitFlange MB3DTF_TrayData MB3DTF_FlipValue MB3DTF_Entity NotVerticalTrayFlag / TrayPoint1 TrayPoint2 TrayAngle)`  - line 240-286

Work on negative flange

- **Arguments**: `MB3DTF_TrayData`, `MB3DTF_FlipValue`, `MB3DTF_Entity`, `NotVerticalTrayFlag`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayWidth`, `TrayDepth`, `TrayFlange`, `TrayLength`, `TrayBasePoint1`, `TrayFlangePoint1`, `TrayFlangePoint2`, `TrayFlangePoint3`, `ExtrudeEntity`, `FlangeFLIP`, `TrayFlangePoint4`, `TrayFlangePoint5`, `TrayFlangePoint6`, `TrayFlangePoint7`, `t1` ...; AutoCAD commands: `3DPOLY`, `COPY`, `EXTRUDE`, `OFFSET`
- **Referenced**: 8
- **Duplicate**: also defined in Support\MED3DTrayFunctions.lsp:195; this definition loads last and wins

## c:QVTest

`(c:QVTest)`  - line 295-308

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [QVTEST](../command-reference.md#qvtest).

- **Arguments**: none
- **Returns**: value of the last expression: `(maketray t-list nil nil)`
- **Side effects**: Globals set (not declared local): `_ZFLAG`, `t-pt1`, `t-pt2`, `t-pt3`, `t-pt4`, `t-list`
- **Referenced**: 0

## c:trayfittest

`(c:trayfittest)`  - line 310-312

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [TRAYFITTEST](../command-reference.md#trayfittest).

- **Arguments**: none
- **Returns**: value of the last expression: `(MEDConvertTrayElbowto3d (car (entsel)))`
- **Referenced**: 0

## MEDConvertTrayElbowTo3D

`(MEDConvertTrayElbowTo3D TrayEntity / TrayEntityData TrayMEDData Tray3DEnt)`  - line 313-333

Tray elbow to 3D.

- **Arguments**: `TrayEntity`
- **Returns**: value of the last expression: `Tray3DEnt`
- **Side effects**: Xdata: writes xdata, reads xdata; AutoCAD commands: `UCS`
- **Referenced**: 2

## MEDDraw3DTrayFit

`(MEDDraw3DTrayFit TrayDataList TrayCenterLine / TrayPoint1 TrayPoint2 TrayWidth TrayDepth TrayFlange)`  - line 335-367

3D tray fitting from its centerline.

- **Arguments**: `TrayDataList`, `TrayCenterLine`
- **Returns**: value of the last expression: `(command "union" TrayBaseEnt TrayFlangeEnt1 TrayFlangeEnt2 "")`
- **Side effects**: Globals set (not declared local): `t1e`, `t1d`, `Traypoints`, `TrayCenterLineData`, `TrayPoint38`, `TrayfitVData`, `TrayBaseEnt`, `TrayFlangeEnt1`, `TrayFlangeEnt2`; Xdata: reads xdata; AutoCAD commands: `UCS`, `UNION`
- **Referenced**: 1

## MEDBuild3DTrayFitBase

`(MEDBuild3DTrayFitBase MB3DTB_TrayData MB3DTF_Entity / TrayPoint1 TrayPoint2 TrayAngle)`  - line 368-384

3D tray fitting base.

- **Arguments**: `MB3DTB_TrayData`, `MB3DTF_Entity`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `t1`, `TrayWidth`, `TrayBasePoint1`, `TrayBasePoint2`, `TrayBasePoint3`, `TrayBasePoint4`, `PathEntity`, `TrayReturnEntity`; AutoCAD commands: `3DPOLY`, `COPY`, `EXTRUDE`
- **Referenced**: 1

## MEDSet3DTrayLayer

`(MEDSet3DTrayLayer trayentity)`  - line 386-401

Ensures and sets the 3D tray layer for a tray.

- **Arguments**: `trayentity`
- **Returns**: value of the last expression: `(if (not (tblsearch "layer" 3DTrayLayerName)) (progn (setq NewLayColor (MEDGetLayerColor TrayLayer) NewLayData...`
- **Side effects**: Globals set (not declared local): `trayentityLayer`, `traydesc`, `trayLayer`, `3dtraylayername`, `NewLayColor`, `NewLayData`; Layers: creates/sets layers (LAYER command / CLAYER)
- **Referenced**: 2

## MEDNew3DSolidsAfter

`(MEDNew3DSolidsAfter mark / e out)`  - line 406-411

3DSOLIDs created after entity mark (all entities when mark is nil), still alive

- **Arguments**: `mark`
- **Returns**: value of the last expression: `(reverse out)`
- **Referenced**: 2

## med3d-tray-build

`(med3d-tray-build / mark new traysols fitsols skipped)`  - line 418-462

Non-interactive tray worker shared by MAKE3DTRAY and MEDMAKE3D (MED3DPath.lsp). Converts every MED_TRAY run and every MED_FITTING outline in the drawing with the same per-entity code MAKE3DTRAY always used (layer, geometry unchanged), then resets the UCS to World. No prompts, no sysvar handling (callers do that). ...

- **Arguments**: none
- **Returns**: value of the last expression: `(list traysols fitsols (reverse skipped))`
- **Side effects**: Globals set (not declared local): `3douttray`, `trayoutnum`, `trayoutcnt`, `trayent`; Xdata: reads/writes xdata directly (-3 group / regapp), `MED_FITTING`, `MED_TRAY`; AutoCAD commands: `UCS`
- **Referenced**: 8

## c:Make3DTray

`(c:Make3DTray / m3dOldOsmode m3dOldError)`  - line 464-526

3D solids from all tray and tray fittings (Dwg/Layer/3DS). See 3d.md. User entry: [MAKE3DTRAY](../command-reference.md#make3dtray).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `*error*`, `outputformat`, `3dsoutfname`; Layers: `_MED3DTRAY` (LAYER command / CLAYER); AutoCAD commands: `-LAYER`, `ERASE`, `PLAN`, `VPOINT`, `WBLOCK`
- **Referenced**: 0

## *error*

`(*error* msg)`  - line 468-475 (nested defun)

MAKE3DTRAY error handler (restores OSMODE).

- **Arguments**: `msg`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `*error*`
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DCON.lsp:135, Support\MED3DFittings.lsp:963, Support\MED3DPath.lsp:1080, Support\MEDFunctions.lsp:921, Support\MEDFunctions.lsp:2816; replaced at load time by Support\MED3DFittings.lsp:963

## MEDConvertTrayFittingsTo3D

`(MEDConvertTrayFittingsTo3D trayfitent)`  - line 528-564

Tray fitting entity to 3D.

- **Arguments**: `trayfitent`
- **Returns**: value of the last expression: `(setvar "ELEVATION" m3delev)`
- **Side effects**: Globals set (not declared local): `fitptbllist`, `fitptlist`, `fitbllist`, `Trayfitdata`, `fitwidth`, `fitdpth`, `fitalt`, `m3delev`, `trayfitentdata`; Xdata: reads xdata
- **Referenced**: 1

## MEDCopyEntity

`(MEDCopyEntity EntityToCopy / CopyEntityData)`  - line 566-576

Copies an entity; returns the copy.

- **Arguments**: `EntityToCopy`
- **Returns**: value of the last expression: `ReturnEntity`
- **Side effects**: Globals set (not declared local): `ReturnEntity`; Entities: `entmake`
- **Referenced**: 0

## MEDDraw3DTrayTeeCrossFit

`(MEDDraw3DTrayTeeCrossFit TrayDataList TrayCenterLine / TrayPoint1 TrayPoint2 TrayPoint3 TrayPoint4 TrayPoint5 TrayPoint6 TrayPoint7 TrayWidth TrayDepth TrayFlange)`  - line 579-637

3D tray tee/cross.

- **Arguments**: `TrayDataList`, `TrayCenterLine`
- **Returns**: value of the last expression: `(if (= (length (car TrayPoints)) 7) (progn (setq TrayDataList (list TrayPoint7 TrayPoint1 TrayWidth TrayDepth ...`
- **Side effects**: Globals set (not declared local): `Traypoints`, `TrayCenterLineData`, `TrayPoint38`, `TrayBaseEnt`, `TrayElevation`, `TempTrayCenter`, `TrayFlangeEnt1`, `TrayFlangeEnt2`, `TrayFlangeEnt3`, `TrayPoint8`, `TrayPoint9`, `TrayPoint10`, `TrayFlangeEnt4`; Xdata: reads xdata; Entities: `entdel`; AutoCAD commands: `UNION`
- **Referenced**: 1

## MEDBuild3DTrayBaseFromOutline

`(MEDBuild3DTrayBaseFromOutline TrayCenterline)`  - line 639-645

3D tray base from an outline.

- **Arguments**: `TrayCenterline`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayFittingData`, `TrayFittingOutlineEnt`, `TrayReturnEntity`; Xdata: reads xdata; AutoCAD commands: `EXTRUDE`
- **Referenced**: 3

## c:trayteetest

`(c:trayteetest)`  - line 647-649

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [TRAYTEETEST](../command-reference.md#trayteetest).

- **Arguments**: none
- **Returns**: value of the last expression: `(MEDConvertTrayTeeTo3d (car (entsel)))`
- **Referenced**: 0

## MEDConvertTrayTeeTo3D

`(MEDConvertTrayTeeTo3D TrayEntity / TrayEntityData TrayMEDData Tray3DEnt)`  - line 650-670

Tray tee to 3D.

- **Arguments**: `TrayEntity`
- **Returns**: value of the last expression: `Tray3DEnt`
- **Side effects**: Xdata: writes xdata, reads xdata; AutoCAD commands: `UCS`
- **Referenced**: 3

## MEDBuild3DTrayFlangeFromEntity

`(MEDBuild3DTrayFlangeFromEntity MB3DTF_TrayData MB3DTF_FlipValue MB3DTF_Entity / TrayPoint1 TrayPoint2 TrayAngle)`  - line 672-721

3D tray flange from an entity.

- **Arguments**: `MB3DTF_TrayData`, `MB3DTF_FlipValue`, `MB3DTF_Entity`
- **Returns**: value of the last expression: `(setq TrayReturnEntity (entlast))`
- **Side effects**: Globals set (not declared local): `TrayWidth`, `TrayDepth`, `TrayFlange`, `TrayLength`, `TrayBasePoint1`, `TrayFlangePoint1`, `TrayFlangePoint2`, `TrayFlangePoint3`, `FlangeFLIP`, `t1`, `t2`, `t3`, `TrayFlangePoint4`, `TrayFlangePoint5`, `TrayFlangePoint6` ...; AutoCAD commands: `3DPOLY`, `EXTRUDE`
- **Referenced**: 4

## MEDDraw3DTrayStraightReducer

`(MEDDraw3DTrayStraightReducer TrayDataList TrayCenterLine / TrayPoint1 TrayPoint2 TrayPoint3 TrayPoint4 TrayWidth TrayDepth TrayFlange TrayAngle)`  - line 723-759

3D straight / left-right tray reducer.

- **Arguments**: `TrayDataList`, `TrayCenterLine`
- **Returns**: value of the last expression: `(command "union" TrayBaseEnt TrayFlangeEnt1 TrayFlangeEnt2 "")`
- **Side effects**: Globals set (not declared local): `Traypoints`, `TrayReducerData`, `TrayPoint38`, `t1`, `t2`, `t3`, `TrayAltWidth`, `tandist`, `apt1`, `apt2`, `apt3`, `apt4`, `bpt1`, `bpt2`, `bpt3` ...; Xdata: reads xdata; AutoCAD commands: `UNION`
- **Referenced**: 1

## MEDDraw3DTrayLeftOrRightReducer

`(MEDDraw3DTrayLeftOrRightReducer TrayDataList TrayCenterLine / TrayPoint1 TrayPoint2 TrayPoint3 TrayPoint4 TrayWidth TrayDepth TrayFlange TrayAngle)`  - line 761-817

3D straight / left-right tray reducer.

- **Arguments**: `TrayDataList`, `TrayCenterLine`
- **Returns**: value of the last expression: `(command "union" TrayBaseEnt TrayFlangeEnt1 TrayFlangeEnt2 "")`
- **Side effects**: Globals set (not declared local): `Traypoints`, `TrayReducerData`, `TrayPoint38`, `t1`, `t2`, `TrayAltWidth`, `ReducerData`, `DirectionFactor`, `TrueAngle`, `tandist`, `ReducerLength`, `StockReducerLength`, `HalfAlt`, `HalfSize2`, `SinOfAngle` ...; Xdata: reads xdata; DB: `med_getdesc`; AutoCAD commands: `UNION`
- **Referenced**: 1

## c:trayretest

`(c:trayretest)`  - line 820-822

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [TRAYRETEST](../command-reference.md#trayretest).

- **Arguments**: none
- **Returns**: value of the last expression: `(MEDConvertTrayReducerTo3d (car (entsel)))`
- **Referenced**: 0

## MEDConvertTrayReducerTo3D

`(MEDConvertTrayReducerTo3D TrayEntity / TrayEntityData TrayMEDData Tray3DEnt)`  - line 823-843

Tray reducer / LR reducer to 3D.

- **Arguments**: `TrayEntity`
- **Returns**: value of the last expression: `Tray3DEnt`
- **Side effects**: Xdata: writes xdata, reads xdata; AutoCAD commands: `UCS`
- **Referenced**: 2

## c:traylrretest

`(c:traylrretest)`  - line 846-848

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command. User entry: [TRAYLRRETEST](../command-reference.md#traylrretest).

- **Arguments**: none
- **Returns**: value of the last expression: `(MEDConvertTrayLRReducerTo3d (car (entsel)))`
- **Referenced**: 0

## MEDConvertTrayLRReducerTo3D

`(MEDConvertTrayLRReducerTo3D TrayEntity / TrayEntityData TrayMEDData Tray3DEnt)`  - line 849-869

Tray reducer / LR reducer to 3D.

- **Arguments**: `TrayEntity`
- **Returns**: value of the last expression: `Tray3DEnt`
- **Side effects**: Xdata: writes xdata, reads xdata; AutoCAD commands: `UCS`
- **Referenced**: 2

