# MEDCableTray.lsp

`Support\MEDCableTray.lsp` - Cable tray drawing: TRAY, elbows, tees, crosses, reducers, offsets, vertical tray, strut.

Loaded by MEDCore (order 14). 36 defun(s): 16 command(s), 20 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`MEDSetTrayValues`](#medsettrayvalues) | function |
| 10 | [`c:TRAY`](#ctray) | command |
| 29 | [`MEDGetTrayTag`](#medgettraytag) | function |
| 52 | [`MEDTray`](#medtray) | function |
| 60 | [`chg_tray_pl_wdth`](#chg_tray_pl_wdth) | function |
| 69 | [`MEDTrayOutline`](#medtrayoutline) | function |
| 137 | [`xdrtray`](#xdrtray) | function |
| 162 | [`MEDMTray90`](#medmtray90) | function |
| 275 | [`c:TRAY90`](#ctray90) | command |
| 283 | [`c:vtray90`](#cvtray90) | command |
| 296 | [`get_tray_data`](#get_tray_data) | function |
| 364 | [`maketray`](#maketray) | function |
| 408 | [`trayang`](#trayang) | function |
| 528 | [`MEDMakeTrayFitOutline`](#medmaketrayfitoutline) | function |
| 532 | [`c:traytee`](#ctraytee) | command |
| 652 | [`c:traycross`](#ctraycross) | command |
| 789 | [`c:trayre`](#ctrayre) | command |
| 912 | [`traylrre`](#traylrre) | function |
| 969 | [`mtray`](#mtray) | function |
| 1033 | [`c:trayfix`](#ctrayfix) | command |
| 1064 | [`c:trayoff`](#ctrayoff) | command |
| 1177 | [`trayoffitt`](#trayoffitt) | function |
| 1225 | [`c:trayv90`](#ctrayv90) | command |
| 1293 | [`DrawVerticalTray`](#drawverticaltray) | function |
| 1358 | [`DrawVerticalTrayFitting`](#drawverticaltrayfitting) | function |
| 1447 | [`c:strut`](#cstrut) | command |
| 1480 | [`DrawTrayVerticalX`](#drawtrayverticalx) | function |
| 1485 | [`c:ptrayoff`](#cptrayoff) | command |
| 1594 | [`c:trayteere`](#ctrayteere) | command |
| 1726 | [`MEDMakeTray`](#medmaketray) | function |
| 1796 | [`MEDPromptForVerticalTrayDistance`](#medpromptforverticaltraydistance) | function |
| 1813 | [`trayupdown`](#trayupdown) | function |
| 1899 | [`c:traydn`](#ctraydn) | command |
| 1905 | [`c:trayup`](#ctrayup) | command |
| 1911 | [`c:chandn`](#cchandn) | command |
| 1919 | [`c:chanup`](#cchanup) | command |

## MEDSetTrayValues

`(MEDSetTrayValues ValueList)`  - line 2-9

Sets the tray globals (_TRCODE _TRTYPE _TRSIZE _TRDEPTH _TRAYFLANGE ...) from a value list.

- **Arguments**: `ValueList`
- **Returns**: value of the last expression: `(setq _TRCODE (nth 0 ValueList) _TRTYPE (nth 1 ValueList) _TRSIZE (nth 2 ValueList) _TRDEPTH(nth 3 ValueList) ...`
- **Side effects**: Globals set (not declared local): `_TRCODE`, `_TRTYPE`, `_TRSIZE`, `_TRDEPTH`, `_TRAYFLANGE`
- **Referenced**: 4

## c:TRAY

`(c:TRAY)`  - line 10-27

Two-point cable tray (outline + centerline + MED_TRAY xdata). User entry: [TRAY](../command-reference.md#tray).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `TRAY_Point1`, `TRAY_Point2`, `TrayTag`, `xdlist`; Xdata: writes xdata
- **Referenced**: 6

## MEDGetTrayTag

`(MEDGetTrayTag mgtt-data)`  - line 29-50

Prompts for / returns the tray tag (default _MEDTAG or NONE).

- **Arguments**: `mgtt-data`
- **Returns**: value of the last expression: `mgtt-traytag`
- **Side effects**: Globals set (not declared local): `mgtt-traytag`, `mgtt-defaulttraytag`, `_MEDTAG`
- **Referenced**: 2

## MEDTray

`(MEDTray TrayData)`  - line 52-58

Draws a two-point tray from a tray-data list (used by TRAY).

- **Arguments**: `TrayData`
- **Returns**: value of the last expression: `(MEDPlineMake (car TrayData) nil nil nil)`
- **Side effects**: Globals set (not declared local): `MEDTray_Point1`, `MEDTray_Point2`
- **Referenced**: 9

## chg_tray_pl_wdth

`(chg_tray_pl_wdth trayent width_factor)`  - line 60-67

Sets the width of a tray/cable polyline by a factor (same as the MEDFunctions.lsp copy; this one loads later and wins).

- **Arguments**: `trayent`, `width_factor`
- **Returns**: value of the last expression: `(entmod trayentdata)`
- **Side effects**: Globals set (not declared local): `trayentdata`, `trayoldwdth`, `traynewwidth`; Entities: `entmod`
- **Referenced**: 26
- **Duplicate**: also defined in Support\MEDFunctions.lsp:1323; this definition loads last and wins

## MEDTrayOutline

`(MEDTrayOutline trent)`  - line 69-136

Rebuilds the outline of a tray centerline entity at its elevation/OCS.

- **Arguments**: `trent`
- **Returns**: value of the last expression: `(setvar "ELEVATION" mtrayelev)`
- **Side effects**: Globals set (not declared local): `trtype_ref`, `mtrayelev`, `trentdata`, `trentOCS`, `origtype`, `_VERTICALTRAY`, `_RESETVTRAY`, `ptlist`, `trpt1`, `trpt2`, `trd1`, `trd2`, `trang`, `trdist`, `trdata` ...; Xdata: writes xdata, reads xdata; Layers: `_MEDTRAY` (LAYER command / CLAYER)
- **Referenced**: 7

## xdrtray

`(xdrtray xdrelent1 xdmainent / handmdata handr1data)`  - line 137-160

Copies/relates tray xdata from one tray entity to another (fittings); handles vertical-tray flags. Overrides the medtray.lsp copy.

- **Arguments**: `xdrelent1`, `xdmainent`
- **Returns**: value of the last expression: `(entmod mentdata)`
- **Side effects**: Globals set (not declared local): `mentdata`, `mxdadd`, `_VERTICALTRAY`, `_RESETVTRAY`; Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmod`
- **Referenced**: 8
- **Duplicate**: also defined in Support\medtray.lsp:263; this definition loads last and wins

## MEDMTray90

`(MEDMTray90 tr_vert trfitcd / tr_data intpt tr_ss srtent bul tr_size tr_dpth tr_tag troff br_len br_tr_list genang tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8)`  - line 162-273

Builds a 90 degree tray fitting (horizontal or vertical) at a tray end.

- **Arguments**: `tr_vert`, `trfitcd`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trsize`, `trdpth`, `trflng`, `medprmpt`, `TR_MAIN`, `mtray90elev`, `pt_gen`, `prpt1`, `prpt2`, `prpt1a`, `prpt2a`, `mlist`, `xdlist`; Xdata: writes xdata
- **Prompts**: `Angle of generation:`
- **Referenced**: 3

## c:TRAY90

`(c:TRAY90 / trfitcd)`  - line 275-281

Horizontal tray elbow of that angle at a tray end. User entry: [TRAY90](../command-reference.md#tray90).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:vtray90

`(c:vtray90 / fittype trfitcd)`  - line 283-294

Side-view tray elbow of that angle (inside/outside). User entry: [VTRAY90](../command-reference.md#vtray90).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## get_tray_data

`(get_tray_data tray_ss / cnt num cmsize tray_size cmpent cmlent rtsize tray_code)`  - line 296-362

Reads tag, code, size, depth from a tray selection set (wins over the medtray.lsp copy).

- **Arguments**: `tray_ss`
- **Returns**: value of the last expression: `rt_size`
- **Side effects**: Globals set (not declared local): `cssize`, `tr_tag`, `tr_code`, `tr_size`, `tr_dpth`, `tr_flng`, `mxtag`, `mxcode`, `mxdpth`, `mxent`, `cslent`, `mntag`, `mncode`, `mdpth`, `mnent` ...; Xdata: reads xdata
- **Referenced**: 12
- **Duplicate**: also defined in Support\medtray.lsp:486; this definition loads last and wins

## maketray

`(maketray traylist closeflag layerset / clay vtxt sqend vtxt vert vertxt)`  - line 364-406

Entmakes a tray polyline from a point list on the tray layer (wins over medtray.lsp).

- **Arguments**: `traylist`, `closeflag`, `layerset`
- **Returns**: value of the last expression: `(entmake plin)`
- **Side effects**: Globals set (not declared local): `plin`, `bldlayer`, `ptlistlen`, `ver1`, `ver2`, `ver3`, `twoten`; Layers: `layerset` (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 20
- **Duplicate**: also defined in Support\medtray.lsp:288; this definition loads last and wins

## trayang

`(trayang inclang trfitcd tr_dat_lst / tr_data trsize trdpth tr_tag trflng medprmpt genang angpol intpt tr_size tr_dpth tr_tag troff br_len bul tpt1 tcen tpt2 pt1 pt2 tpt pt3 pt4 pt5 pt6 pt7 pt8 prpt1 prpt1a prpt2 prpt2a mlist tvar)`  - line 408-527

Builds a tray elbow of an included angle at a tray end (+/- direction prompt).

- **Arguments**: `inclang`, `trfitcd`, `tr_dat_lst`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `tang`, `_TRAYFITPTLIST`, `xdlist`; Xdata: writes xdata
- **Prompts**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`
- **Referenced**: 11

## MEDMakeTrayFitOutline

`(MEDMakeTrayFitOutline MEDTrayTeeEntity)`  - line 528-531

Makes the outline of a tray tee/cross fitting.

- **Arguments**: `MEDTrayTeeEntity`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:traytee

`(c:traytee / tr_data intpt tr_ss bul srtent trfitcd tr_size tr_dpth tr_tag troff br_len br_tr_list genang tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 mlist xdlist)`  - line 532-650

Horizontal tray tee. User entry: [TRAYTEE](../command-reference.md#traytee).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trprsz`, `trflng`, `medprmpt`, `trayteeelev`, `TR_MAIN`, `_CHANTEE`, `prpt1`, `prpt1a`, `prpt3`, `prpt3a`, `prpt2`, `prpt2a`; Xdata: writes xdata
- **Referenced**: 2

## c:traycross

`(c:traycross / tr_data intpt tr_ss srtent bul trfitcd tr_size tr_dpth tr_tag troff br_len br_tr_list genang tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 pt11 pt12 pt13 pt14 pt15 pt16 mlist xdlist)`  - line 652-787

Horizontal tray cross. User entry: [TRAYCROSS](../command-reference.md#traycross).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trprsz`, `trflng`, `medprmpt`, `traycrosselev`, `TR_MAIN`, `_CHANTEE`, `prpt1`, `prpt1a`, `prpt3`, `prpt3a`, `prpt2`, `prpt2a`, `prpt4`, `prpt4a`; Xdata: writes xdata
- **Referenced**: 2

## c:trayre

`(c:trayre / tr_data intpt tr_ss srtent bul tr_lsize tr_dpth tr_tag tr_loff tr_ssize tr_soff br_len1 br_len2 traydt testent testpt genang tang sizelst redlst tpt pt1 pt2 pt8 pt7 pt4 pt3 pt5 pt6 mlist xdlist)`  - line 789-910

Straight tray reducer (asks reduce-to size). User entry: [TRAYRE](../command-reference.md#trayre).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trayreelev`, `TR_MAIN`, `trflng`, `br_tr_list`, `_TANG`; Xdata: writes xdata, reads xdata
- **Referenced**: 1

## traylrre

`(traylrre reang fittcode / tr_data)`  - line 912-967

Builds a left/right tray reducer at a point.

- **Arguments**: `reang`, `fittcode`
- **Returns**: value of the last expression: `(setvar "ELEVATION" traylrreelev)`
- **Side effects**: Globals set (not declared local): `intpt`, `traylrreelev`, `genang`, `tr_lsize`, `tr_dpth`, `tr_tag`, `trflng`, `tr_loff`, `tr_ssize`, `br_len1`, `sizelst`, `redlst`, `tr_soff`, `pt1`, `pt2` ...; Xdata: writes xdata
- **Prompts**: `Select insertion point:`; `Angle of generation:`; `Size may not be larger than current size.`; `Size to Reduce to:`
- **Referenced**: 2

## mtray

`(mtray trent)`  - line 969-1031

Converts a tray entity into a 3D tray (legacy path).

- **Arguments**: `trent`
- **Returns**: value of the last expression: `(setvar "ELEVATION" mtrayelev)`
- **Side effects**: Globals set (not declared local): `trtype_ref`, `mtrayelev`, `trentdata`, `origtype`, `_VERTICALTRAY`, `_RESETVTRAY`, `ptlist`, `trpt1`, `trpt2`, `trd1`, `trd2`, `trang`, `trdist`, `trdata`, `trflng` ...; Xdata: writes xdata, reads xdata; Layers: `_MEDTRAY` (LAYER command / CLAYER)
- **Referenced**: 1

## c:trayfix

`(c:trayfix)`  - line 1033-1062

Rebuilds a tray outline from its centerline. User entry: [TRAYFIX](../command-reference.md#trayfix).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trayfixent`, `trayfixentdata`, `trayfixelev`, `trayentdata`; Xdata: reads xdata
- **Referenced**: 0

## c:trayoff

`(c:trayoff)`  - line 1064-1175

Plan horizontal tray offset at 30/45/60/90 degrees. User entry: [TRAYOFF](../command-reference.md#trayoff).

- **Arguments**: none
- **Returns**: value of the last expression: `(setq _ANGPOL nil)`
- **Side effects**: Globals set (not declared local): `en1`, `e1pt1`, `e1pt2`, `disty`, `angdir`, `troffss`, `tr_data`, `trayoffelev`, `offsize`, `offcode`, `offdpth`, `offtag`, `offflng`, `_ANGPOL`, `tangpol` ...
- **Referenced**: 2

## trayoffitt

`(trayoffitt angmult htrcode hchcode vitrcode votrcode vichcode vochcode / rtlist)`  - line 1177-1223

Builds the fittings of a tray offset (angle, up/down) for tray and channel codes.

- **Arguments**: `angmult`, `htrcode`, `hchcode`, `vitrcode`, `votrcode`, `vichcode`, `vochcode`
- **Returns**: value of the last expression: `(setq rtlist (list incang degfit1 degfit2 voffdiroption))`
- **Side effects**: Globals set (not declared local): `incang`, `voffdiroption`, `degfit1`, `degfit2`
- **Prompts**: `Direction Up/Down <Down>:`
- **Referenced**: 8

## c:trayv90

`(c:trayv90)`  - line 1225-1291

Plan vertical 90 degree tray elbow (inside/outside). User entry: [TRAYV90](../command-reference.md#trayv90).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `fitcd`, `trprsz`, `trflng`, `fittype`, `trfitcd`, `vtrdir1`, `medprmpt`, `intpt`, `TR_MAIN`, `tr_ss`, `srtent`, `genang`, `tr_lsize`, `tr_dpth`, `tr_tag` ...
- **Referenced**: 2

## DrawVerticalTray

`(DrawVerticalTray Tray_data StartPoint EndPoint TrayGenAngle VerticalDirection TrayAngle Traylength)`  - line 1293-1354

Draws a vertical (side-view) tray segment between two points.

- **Arguments**: `Tray_data`, `StartPoint`, `EndPoint`, `TrayGenAngle`, `VerticalDirection`, `TrayAngle`, `Traylength`
- **Returns**: value of the last expression: `(setvar "ELEVATION" CurrentElevation)`
- **Side effects**: Globals set (not declared local): `TraySize`, `TrayDepth`, `TrayCode`, `TrayFlange`, `TrayTag`, `StartingOCS`, `YAxispoint`, `TrayPoint1`, `TrayPoint2`, `xdlist`; Xdata: writes xdata; Layers: `_MEDCENLAY`; AutoCAD commands: `MOVE`, `ROTATE`, `UCS`
- **Referenced**: 1

## DrawVerticalTrayFitting

`(DrawVerticalTrayFitting Tray_data StartPoint TrayGenAngle VerticalDirection TrayFitIncAng / TraySize TrayDepth TrayFitCode TrayFlange TrayTag PointBuldge pt1 pt2 pt3 pt4 pt5)`  - line 1358-1446

Draws a vertical tray fitting at a start point.

- **Arguments**: `Tray_data`, `StartPoint`, `TrayGenAngle`, `VerticalDirection`, `TrayFitIncAng`
- **Returns**: value of the last expression: `returnPoint`
- **Side effects**: Globals set (not declared local): `TrayOffset`, `TStartPoint`, `TTrayGenAngle`, `TempPoint1`, `TempCenter`, `TempPoint2`, `TempPoint`, `TempAngle`, `_ZFLAG`, `mlist`, `CurrentElevation`, `FitEnt`, `FitEntPts`, `FitEntData`, `ReturnPoint` ...; Xdata: writes xdata; AutoCAD commands: `MOVE`, `ROTATE`
- **Referenced**: 3

## c:strut

`(c:strut / cltp clay trpt1 trpt2 trtag xdlist)`  - line 1447-1478

Framing channel (strut) run between two points. User entry: [STRUT](../command-reference.md#strut).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `CR_LAYER`, `strutelev`; Xdata: writes xdata; Layers: `_MEDCENLAY` (LAYER command / CLAYER)
- **Referenced**: 1

## DrawTrayVerticalX

`(DrawTrayVerticalX TrayData Startpoint Genangle TrayXDistance)`  - line 1480-1482

Draws the X symbol of a vertical tray in plan.

- **Arguments**: `TrayData`, `Startpoint`, `Genangle`, `TrayXDistance`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:ptrayoff

`(c:ptrayoff)`  - line 1485-1592

Plan vertical tray offset at 30/45/60/90 degrees (up/down). User entry: [PTRAYOFF](../command-reference.md#ptrayoff).

- **Arguments**: none
- **Returns**: value of the last expression: `(setq _ANGPOL nil)`
- **Side effects**: Globals set (not declared local): `en1`, `e1pt1`, `e1pt2`, `disty`, `troffss`, `tr_data`, `orgelev`, `workelev`, `ctrmode`, `_VERTICALTRAY`, `offsize`, `offcode`, `offdpth`, `offtag`, `offflng` ...; AutoCAD commands: `UCS`
- **Referenced**: 0

## c:trayteere

`(c:trayteere / tr_data intpt tr_ss bul srtent trfitcd tr_size tr_dpth tr_tag troff br_len br_tr_list genang tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 mlist xdlist)`  - line 1594-1724

Reducing tray tee. User entry: [TRAYTEERE](../command-reference.md#trayteere).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `trprsz`, `trflng`, `TrFlng`, `medprmpt`, `trayteeelev`, `TR_MAIN`, `tr_lsize`, `sizelst`, `redlst`, `tr_ssize`, `tr_alt_size`, `altoff`, `_CHANTEE`, `prpt1`, `prpt1a` ...; Xdata: writes xdata
- **Referenced**: 0

## MEDMakeTray

`(MEDMakeTray traylist closeflag layerset OCSData / clay vtxt sqend vtxt vert vertxt)`  - line 1726-1794

Entmakes a tray polyline with elevation and OCS data.

- **Arguments**: `traylist`, `closeflag`, `layerset`, `OCSData`
- **Returns**: value of the last expression: `(entmake plin)`
- **Side effects**: Globals set (not declared local): `plin`, `bldlayer`, `ptlistlen`, `elev`, `UseThisOCSData`, `UseThisOCSDAta`, `PtOnlyList`, `PTOnlyList`, `WCSPointList`, `PtCount`, `ver1`, `ver2`, `ver3`, `PTCount`, `twoten` ...; Layers: `layerset` (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 25

## MEDPromptForVerticalTrayDistance

`(MEDPromptForVerticalTrayDistance traydir trcode trsz trstpt)`  - line 1796-1811

Prompts for the vertical tray distance (default _MEDDIST).

- **Arguments**: `traydir`, `trcode`, `trsz`, `trstpt`
- **Returns**: value of the last expression: `trdist`
- **Side effects**: Globals set (not declared local): `mdprmpt`, `trdist`, `_MEDDIST`
- **Referenced**: 2

## trayupdown

`(trayupdown traydir trltype)`  - line 1813-1897

Tray up/down: vertical fitting at a picked tray item.

- **Arguments**: `traydir`, `trltype`
- **Returns**: value of the last expression: `(if (= (dxf 0 vtrayfitentdata) "LWPOLYLINE") (progn (setq cltp (getvar "celtype") clay (getvar "CLAYER") acttr...`
- **Side effects**: Globals set (not declared local): `trbasent`, `vtrayfitent`, `vtrayfitentdata`, `cltp`, `clay`, `acttraydir`, `tryptdatalist`, `tryptlist`, `traystpt`, `AlignPoint`, `genangle`, `trflng`, `trsize`, `trdpth`, `trcode` ...; Xdata: writes xdata, reads xdata; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `UCS`
- **Prompts**: `Select Tray item`
- **Referenced**: 4

## c:traydn

`(c:traydn)`  - line 1899-1904

Tray turning up / down in plan (vertical fitting symbol + elevation). User entry: [TRAYDN](../command-reference.md#traydn).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:trayup

`(c:trayup)`  - line 1905-1910

Tray turning up / down in plan (vertical fitting symbol + elevation). User entry: [TRAYUP](../command-reference.md#trayup).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:chandn

`(c:chandn)`  - line 1911-1918

Cable channel up / down / plan vertical 90. User entry: [CHANDN](../command-reference.md#chandn).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 1

## c:chanup

`(c:chanup)`  - line 1919-1926

Cable channel up / down / plan vertical 90. User entry: [CHANUP](../command-reference.md#chanup).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 1

