# MEDFunctions.lsp

`Support\MEDFunctions.lsp` - Core library: layers, xdata read/write, breaks, BOM write, leaders, geometry and string helpers, error handling, MEDProperties stamping.

Loaded by MEDCore (order 9). 88 defun(s): 0 command(s), 88 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`getColorNumber`](#getcolornumber) | function |
| 35 | [`verifyLinetypeLoaded`](#verifylinetypeloaded) | function |
| 57 | [`SetLayerLineweight`](#setlayerlineweight) | function |
| 74 | [`medMakeLayer`](#medmakelayer) | function |
| 108 | [`medsmlayer`](#medsmlayer) | function |
| 128 | [`MEDGetLayerColor`](#medgetlayercolor) | function |
| 139 | [`MEDverifyLayerColor`](#medverifylayercolor) | function |
| 151 | [`MEDverifyLayerLinetype`](#medverifylayerlinetype) | function |
| 166 | [`smlayer`](#smlayer) | function |
| 170 | [`dxf`](#dxf) | function |
| 176 | [`clookup`](#clookup) | function |
| 220 | [`med_tan`](#med_tan) | function |
| 224 | [`polylen`](#polylen) | function |
| 232 | [`MEDSettings`](#medsettings) | function |
| 243 | [`MEDGetCurrentUCS`](#medgetcurrentucs) | function |
| 246 | [`MEDGetCurrentOCS`](#medgetcurrentocs) | function |
| 261 | [`MEDTransPointListToUCS`](#medtranspointlisttoucs) | function |
| 292 | [`MEDPlineMake`](#medplinemake) | function |
| 356 | [`MEDSendEntityDataToBOM`](#medsendentitydatatobom) | function |
| 524 | [`MEDSendEntityDataToBOM`](#medsendentitydatatobom) | function |
| 708 | [`xdataget`](#xdataget) | function |
| 778 | [`FixDetailResultList`](#fixdetailresultlist) | function |
| 800 | [`FixMEDDetailResultList`](#fixmeddetailresultlist) | function |
| 816 | [`bld_dtl_list`](#bld_dtl_list) | function |
| 826 | [`med_detail`](#med_detail) | function |
| 845 | [`getblockentityhandle`](#getblockentityhandle) | function |
| 854 | [`makeleader`](#makeleader) | function |
| 907 | [`medleader`](#medleader) | function |
| 921 | [`*error*`](#error) | function |
| 983 | [`PlaceTextFromLeader`](#placetextfromleader) | function |
| 1019 | [`vtrayxdataget`](#vtrayxdataget) | function |
| 1043 | [`addvtraydata`](#addvtraydata) | function |
| 1058 | [`break_out`](#break_out) | function |
| 1180 | [`bld_lw_ptlist`](#bld_lw_ptlist) | function |
| 1196 | [`bld_3dpline_ptlist`](#bld_3dpline_ptlist) | function |
| 1216 | [`chopspace`](#chopspace) | function |
| 1235 | [`mparse`](#mparse) | function |
| 1323 | [`chg_tray_pl_wdth`](#chg_tray_pl_wdth) | function |
| 1332 | [`chg_ent_ltype`](#chg_ent_ltype) | function |
| 1350 | [`get_con_tag`](#get_con_tag) | function |
| 1367 | [`prc_detlist`](#prc_detlist) | function |
| 1386 | [`upd_detaglst`](#upd_detaglst) | function |
| 1411 | [`mk_str_len`](#mk_str_len) | function |
| 1422 | [`typstrins`](#typstrins) | function |
| 1433 | [`opt_eq_ins`](#opt_eq_ins) | function |
| 1489 | [`verify_list`](#verify_list) | function |
| 1512 | [`subst_txt`](#subst_txt) | function |
| 1546 | [`listtoggle`](#listtoggle) | function |
| 1557 | [`matchtxtprops`](#matchtxtprops) | function |
| 1581 | [`attachfitting`](#attachfitting) | function |
| 1594 | [`move_attrib`](#move_attrib) | function |
| 1616 | [`getdettags`](#getdettags) | function |
| 1704 | [`getatvals`](#getatvals) | function |
| 1725 | [`xdatappend`](#xdatappend) | function |
| 1736 | [`medcount`](#medcount) | function |
| 1852 | [`dblchck`](#dblchck) | function |
| 1914 | [`med_brk_out`](#med_brk_out) | function |
| 1964 | [`xdr2line`](#xdr2line) | function |
| 1999 | [`xdstrip`](#xdstrip) | function |
| 2032 | [`attmod`](#attmod) | function |
| 2079 | [`be`](#be) | function |
| 2097 | [`between`](#between) | function |
| 2104 | [`xdataget`](#xdataget) | function |
| 2174 | [`xd_apps`](#xd_apps) | function |
| 2199 | [`xdatadd`](#xdatadd) | function |
| 2210 | [`MEDSetMedProperties`](#medsetmedproperties) | function |
| 2241 | [`MEDRebuildMedPropsJsonBeside`](#medrebuildmedpropsjsonbeside) | function |
| 2272 | [`MEDStamp3DFromBom`](#medstamp3dfrombom) | function |
| 2349 | [`clookup`](#clookup) | function |
| 2395 | [`getsize`](#getsize) | function |
| 2453 | [`med_conduit_od`](#med_conduit_od) | function |
| 2500 | [`ltback`](#ltback) | function |
| 2519 | [`insblk`](#insblk) | function |
| 2528 | [`toggle`](#toggle) | function |
| 2550 | [`retr_size_tag`](#retr_size_tag) | function |
| 2622 | [`feedset`](#feedset) | function |
| 2633 | [`brk_rot`](#brk_rot) | function |
| 2788 | [`med_cur_set`](#med_cur_set) | function |
| 2816 | [`*error*`](#error) | function |
| 2832 | [`med_reset`](#med_reset) | function |
| 2845 | [`med_ret_ok`](#med_ret_ok) | function |
| 2857 | [`med_verify`](#med_verify) | function |
| 2876 | [`addatrib`](#addatrib) | function |
| 2930 | [`newsz`](#newsz) | function |
| 2946 | [`settog`](#settog) | function |
| 3032 | [`setmedval`](#setmedval) | function |
| 3052 | [`MEDremoveitemfromlist`](#medremoveitemfromlist) | function |
| 3065 | [`MEDRemapEQCodeToProjectCode`](#medremapeqcodetoprojectcode) | function |

## getColorNumber

`(getColorNumber gcn-color)`  - line 2-32

Maps a colour name/number to an ACI number.

- **Arguments**: `gcn-color`
- **Returns**: value of the last expression: `gcn-color`
- **Referenced**: 4

## verifyLinetypeLoaded

`(verifyLinetypeLoaded vltl-ltype)`  - line 35-54

Loads a linetype from acad.lin if missing; falls back to Continuous.

- **Arguments**: `vltl-ltype`
- **Returns**: value of the last expression: `vltl-ltype`
- **Side effects**: AutoCAD commands: `LINETYPE`
- **Referenced**: 2

## SetLayerLineweight

`(SetLayerLineweight Layername lineweighttouse)`  - line 57-72

Sets a layer's lineweight (validated against AutoCAD values).

- **Arguments**: `Layername`, `lineweighttouse`
- **Returns**: value of the last expression: `(if (= (vl-catch-all-error-p LayerToUpdate) nil) (if (member lineweighttouse valid-lwght-list) (vla-put-linewe...`
- **Side effects**: Globals set (not declared local): `AcadMainObj`, `AcadActiveDoc`, `ActiveLayers`, `LayerToUpdate`, `valid-lwght-list`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 1

## medMakeLayer

`(medMakeLayer ml-layinfo)`  - line 74-106

Creates a layer from (name color ltype lweight).

- **Arguments**: `ml-layinfo`
- **Returns**: value of the last expression: `(setLayerLineWeight ml-name ml-lwght)`
- **Side effects**: Globals set (not declared local): `ml-name`, `ml-color`, `ml-ltype`, `ml-lwght`, `ml-newlayer`, `ml-newlayerdata`; Xdata: reads/writes xdata directly (-3 group / regapp); Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 2

## medsmlayer

`(medsmlayer layinfo / name color ltype regen)`  - line 108-126

Creates (if needed) and sets current a layer from a MED layer spec.

- **Arguments**: `layinfo`
- **Returns**: value of the last expression: `(setvar "CLAYER" name)`
- **Side effects**: Globals set (not declared local): `lwght`; Layers: creates/sets layers (LAYER command / CLAYER)
- **Referenced**: 4

## MEDGetLayerColor

`(MEDGetLayerColor LayerName)`  - line 128-136

Returns a layer's colour.

- **Arguments**: `LayerName`
- **Returns**: value of the last expression: `(setq LayerColor (getColorNumber MVLC-VerifyLayerColor))`
- **Side effects**: Globals set (not declared local): `AcadMainObj`, `AcadActiveDoc`, `MVLC-ActiveLayers`, `MVLC-VerifyLayerObj`, `MVLC-VerifyLayerColor`, `LayerColor`
- **Referenced**: 1

## MEDverifyLayerColor

`(MEDverifyLayerColor layername layercolor)`  - line 139-150

Makes a layer's colour / linetype match the MED spec.

- **Arguments**: `layername`, `layercolor`
- **Returns**: value of the last expression: `(if (/= MVLC-VerifyLayerColor LayerColor) (vla-put-color MVLC-VerifyLayerObj layercolor) )`
- **Side effects**: Globals set (not declared local): `AcadMainObj`, `AcadActiveDoc`, `MVLC-ActiveLayers`, `MVLC-VerifyLayerObj`, `MVLC-VerifyLayerColor`
- **Referenced**: 1

## MEDverifyLayerLinetype

`(MEDverifyLayerLinetype layername linetypename)`  - line 151-164

Makes a layer's colour / linetype match the MED spec.

- **Arguments**: `layername`, `linetypename`
- **Returns**: value of the last expression: `(if (/= VerifyLayerLtype linetypename) (progn (verifyLinetypeLoaded linetypename) (vla-put-linetype VerifyLaye...`
- **Side effects**: Globals set (not declared local): `AcadMainObj`, `AcadActiveDoc`, `ActiveLayers`, `VerifyLayerObj`, `VerifyLayerLtype`
- **Referenced**: 1

## smlayer

`(smlayer layinfo)`  - line 166-168

Set-MED-layer: make the MED layer spec current (creates it). Used by most menu macros.

- **Arguments**: `layinfo`
- **Returns**: value of the last expression: `(medsmlayer layinfo)`
- **Side effects**: Layers: creates/sets layers
- **Called from menu macros**: 106 item(s), e.g. MEDRibbon.cuix Ribbon: Cables > #2 Gnd Cable
- **Referenced**: 128

## dxf

`(dxf code elist)`  - line 170-172

Returns the value of DXF group code from an entity list.

- **Arguments**: `code`, `elist`
- **Returns**: value of the last expression: `(cdr (assoc code elist))`
- **Referenced**: 415

## clookup

`(clookup lookcode size apptype)`  - line 176-218

Builds the size + description string for a code/size/app type from the catalog (first copy; overridden by line 2349).

- **Arguments**: `lookcode`, `size`, `apptype`
- **Returns**: value of the last expression: `rstr`
- **Side effects**: Globals set (not declared local): `rstr`, `aplk`, `rval`; DB: `med_getdesc`
- **Referenced**: 32
- **Duplicate**: also defined in Support\MEDFunctions.lsp:2349; replaced at load time by Support\MEDFunctions.lsp:2349

## med_tan

`(med_tan mt_ang)`  - line 220-222

Tangent of an angle.

- **Arguments**: `mt_ang`
- **Returns**: value of the last expression: `(setq mt_returnvalue (/ (sin mt_ang) (cos mt_ang)))`
- **Side effects**: Globals set (not declared local): `mt_returnvalue`
- **Referenced**: 9

## polylen

`(polylen plineent)`  - line 224-230

Length of a polyline (ActiveX).

- **Arguments**: `plineent`
- **Returns**: value of the last expression: `(if (and pl-object (vlax-property-available-p pl-object 'length)) (setq pl-returnlength (vla-get-length pl-obj...`
- **Side effects**: Globals set (not declared local): `pl-object`, `pl-returnlength`
- **Referenced**: 10

## MEDSettings

`(MEDSettings CommandName)`  - line 232-242

Sets layer and linetype for a MED command name.

- **Arguments**: `CommandName`
- **Returns**: value of the last expression: `(cond ((= CommandName "C:TRAY") (smlayer _MEDCENLAY) ) )`
- **Side effects**: Globals set (not declared local): `CurrLinetype`, `CurrLayer`; Layers: `_MEDCENLAY` (LAYER command / CLAYER)
- **Referenced**: 6

## MEDGetCurrentUCS

`(MEDGetCurrentUCS)`  - line 243-245

Returns the current UCS data.

- **Arguments**: none
- **Returns**: value of the last expression: `(trans (list 0.0 0.0 1.0) 1 0)`
- **Referenced**: 0

## MEDGetCurrentOCS

`(MEDGetCurrentOCS)`  - line 246-260

Returns the OCS vectors of the current UCS.

- **Arguments**: none
- **Returns**: value of the last expression: `(list OCSXValue OCSYValue OCSZValue)`
- **Side effects**: Globals set (not declared local): `ucsxdirA`, `ucsydirB`, `OCSAx`, `OCSAy`, `OCSAz`, `OCSBx`, `OCSBy`, `OCSBz`, `OCSXValue`, `OCSYValue`, `OCSZValue`
- **Referenced**: 40

## MEDTransPointListToUCS

`(MEDTransPointListToUCS mtpltw-Pointlist mtpltw-ElevationData mtpltw-UCSData)`  - line 261-289

Transforms a point list (with elevation) to the current UCS.

- **Arguments**: `mtpltw-Pointlist`, `mtpltw-ElevationData`, `mtpltw-UCSData`
- **Returns**: value of the last expression: `ReturnPtList`
- **Side effects**: Globals set (not declared local): `WCSComparePoint`, `ReturnPtList`, `pt`, `ActualWCSPoint`, `ActualElevationToUse`
- **Referenced**: 2

## MEDPlineMake

`(MEDPlineMake PointList CloseFlag PlineElevation OCSData)`  - line 292-353

Entmakes a polyline from a point list, closed flag, elevation and OCS.

- **Arguments**: `PointList`, `CloseFlag`, `PlineElevation`, `OCSData`
- **Returns**: value of the last expression: `(setq CR_LAYER nil)`
- **Side effects**: Globals set (not declared local): `plin`, `ptlistlen`, `elev`, `_USEELEV`, `UseThisOCSData`, `UseThisOCSDAta`, `WCSPointList`, `vert`, `ver1`, `ver2`, `ver3`, `twoten`, `_ZFLAG`, `OCSTrue`, `OCSFalse` ...; Entities: `entmake`
- **Referenced**: 6

## MEDSendEntityDataToBOM

`(MEDSendEntityDataToBOM medent)`  - line 356-522

Writes an entity's MED xdata records to MEDProject (first copy; overridden by the definition at line 524).

- **Arguments**: `medent`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `applist`, `medentdata`, `medentityhandle`, `medentitytype`, `meddwgname`, `meddwgpath`, `medusername`, `numapps`, `appcnt`, `appnm`, `appdata`, `datalen`, `applen`, `numtags`, `tagcnt` ...; Xdata: reads xdata; DB: `medprocesssqlstatement`
- **Referenced**: 1
- **Duplicate**: also defined in Support\MEDFunctions.lsp:524; replaced at load time by Support\MEDFunctions.lsp:524

## MEDSendEntityDataToBOM

`(MEDSendEntityDataToBOM medent)`  - line 524-703

Writes an entity's MED xdata records to MEDProject; saves the SQL statement to a variable (this copy wins).

- **Arguments**: `medent`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `applist`, `medentdata`, `medentityhandle`, `medentitytype`, `meddwgname`, `meddwgpath`, `medusername`, `numapps`, `appcnt`, `appnm`, `appdata`, `datalen`, `applen`, `numtags`, `tagcnt` ...; Xdata: reads xdata; DB: `medprocesssqlstatement`
- **Referenced**: 1
- **Duplicate**: also defined in Support\MEDFunctions.lsp:356; this definition loads last and wins

## xdataget

`(xdataget ent app_name / xdlist)`  - line 708-776

Returns an application's xdata from an entity (first copy; overridden by line 2104).

- **Arguments**: `ent`, `app_name`
- **Returns**: value of the last expression: `xdlist`
- **Side effects**: Globals set (not declared local): `entdata`, `xdatalist`, `xdlen`, `xdcnt`, `xdval`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 73
- **Duplicate**: also defined in Support\MEDFunctions.lsp:2104; replaced at load time by Support\MEDFunctions.lsp:2104

## FixDetailResultList

`(FixDetailResultList ResultList)`  - line 778-798

Normalises a detail query result list (nil -> defaults).

- **Arguments**: `ResultList`
- **Returns**: value of the last expression: `ReturnResultList`
- **Side effects**: Globals set (not declared local): `ReturnResultList`, `UpdateRecord`, `REturnResultList`
- **Referenced**: 1

## FixMEDDetailResultList

`(FixMEDDetailResultList ResultList)`  - line 800-814

Normalises a detail query result list (nil -> defaults).

- **Arguments**: `ResultList`
- **Returns**: value of the last expression: `ReturnResultList`
- **Side effects**: Globals set (not declared local): `ReturnResultList`, `UpdateRecord`, `REturnResultList`
- **Referenced**: 1

## bld_dtl_list

`(bld_dtl_list DetailGroup)`  - line 816-825

Returns the detail rows of a MEDType group (DETAIL dialog).

- **Arguments**: `DetailGroup`
- **Returns**: value of the last expression: `MEDReturnData`
- **Side effects**: Globals set (not declared local): `MEDSQLStatement`, `MEDReturnData`; DB: `medprocesssqlstatement`
- **Referenced**: 1

## med_detail

`(med_detail DetailMaterialCodeOrnum)`  - line 826-841

Returns detail data by material code or number.

- **Arguments**: `DetailMaterialCodeOrnum`
- **Returns**: value of the last expression: `MEDReturnData`
- **Side effects**: Globals set (not declared local): `AddWhereCond`, `MEDSQLStatement`, `MEDReturnData`; DB: `medprocesssqlstatement`
- **Referenced**: 5

## getblockentityhandle

`(getblockentityhandle blockname)`  - line 845-852

Returns the handle of the block-record owner of a block definition (nil if the block is not defined).

- **Arguments**: `blockname`
- **Returns**: value of the last expression: `returnvalue`
- **Side effects**: Globals set (not declared local): `gbeh-tableentity`, `returnvalue`
- **Referenced**: 1

## makeleader

`(makeleader leaderpointlist leaderstylename leaderdata)`  - line 854-905

Makes a leader with a style and arrow block.

- **Arguments**: `leaderpointlist`, `leaderstylename`, `leaderdata`
- **Returns**: value of the last expression: `(entmake Leaderent)`
- **Side effects**: Globals set (not declared local): `usedimstylename`, `Leaderent`, `leaderent`, `leaderblkname`, `leaderarrowsize`, `leaderblkhandle`, `xdataforleader`; Xdata: reads/writes xdata directly (-3 group / regapp); Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 4

## medleader

`(medleader leadblname txtflag scalesz LayerSpec / lay txt genang lentmrk lentbk pt pt1 entblk allss entdata txt_spec oldy newy txt)`  - line 907-982

Leader with optional text at the MED scale on a layer spec.

- **Arguments**: `leadblname`, `txtflag`, `scalesz`, `LayerSpec`
- **Returns**: value of the last expression: `(entlast)`
- **Side effects**: Globals set (not declared local): `leaddimstyle`, `leaderbuildinfo`, `layerdata`, `olderr`, `*error*`, `DimDataStyle`, `DimDataLeaderBlock`, `DimDataLeaderArrowSize`, `cmdone`, `OrthoModeVariable`, `addpoint`, `LeaderPtlist`; Layers: `layerdata` (LAYER command / CLAYER); Entities: `entdel`; AutoCAD commands: `INSERT`, `LEADER`
- **Prompts**: `Leader Start Point:`
- **Referenced**: 7

## *error*

`(*error* errmsg)`  - line 921-925 (nested defun)

Local error handler inside medleader.

- **Arguments**: `errmsg`
- **Returns**: value of the last expression: `(setq *error* olderr)`
- **Side effects**: Globals set (not declared local): `*error*`
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DCON.lsp:135, Support\MED3DFittings.lsp:963, Support\MED3DPath.lsp:1080, Support\MED3DTrayFunctions.lsp:468, Support\MEDFunctions.lsp:2816; replaced at load time by Support\MED3DFittings.lsp:963

## PlaceTextFromLeader

`(PlaceTextFromLeader LeaderPoint1 LeaderPoint2)`  - line 983-1017

Places text at the end of a two-point leader with the right justification.

- **Arguments**: `LeaderPoint1`, `LeaderPoint2`
- **Returns**: value of the last expression: `(med_text "T1" txt_spec)`
- **Side effects**: Globals set (not declared local): `genang`, `txtang`, `txtjust`
- **Referenced**: 1

## vtrayxdataget

`(vtrayxdataget xdgent / xdlist xdatalist xdlen xdcnt xdgentdata)`  - line 1019-1041

Reads VERT_DATA xdata from an entity.

- **Arguments**: `xdgent`
- **Returns**: value of the last expression: `xdlist`
- **Side effects**: Globals set (not declared local): `xdval`; Xdata: reads/writes xdata directly (-3 group / regapp), `VERT_DATA`
- **Referenced**: 13

## addvtraydata

`(addvtraydata entnm vtraydata)`  - line 1043-1056

Adds VERT_DATA xdata (vertical direction/distance) to an entity.

- **Arguments**: `entnm`, `vtraydata`
- **Returns**: value of the last expression: `(entmod endata)`
- **Side effects**: Globals set (not declared local): `endata`, `xdlist`; Xdata: reads/writes xdata directly (-3 group / regapp), `VERT_DATA`; Entities: `entmod`
- **Referenced**: 3

## break_out

`(break_out bo_bk_ang bo_bk_pt bo_bk_dist bo_tray_flag)`  - line 1058-1177

Breaks a raceway at a point by a distance (fitting insert break).

- **Arguments**: `bo_bk_ang`, `bo_bk_pt`, `bo_bk_dist`, `bo_tray_flag`
- **Returns**: value of the last expression: `(if (setq tmp_ent (nentselp "\n" b_pt)) (progn (if bo_tray_flag (traychck b_pt) (dblchck b_pt) ) (setq lentmrk...`
- **Side effects**: Globals set (not declared local): `b_pt`, `tmp_ent`, `lentmrk`, `lentbk`, `islastent`, `tdet`, `lastent`, `lastdata`, `en1`, `en2`, `s_ents`, `enset`, `PRIM_ENT`; AutoCAD commands: `BREAK`
- **Referenced**: 4

## bld_lw_ptlist

`(bld_lw_ptlist lwent)`  - line 1180-1194

Returns points and bulges of an LWPOLYLINE.

- **Arguments**: `lwent`
- **Returns**: value of the last expression: `(list lwptlist lwbulist)`
- **Side effects**: Globals set (not declared local): `lwptlist`, `lwbulist`, `lwdata`
- **Referenced**: 27

## bld_3dpline_ptlist

`(bld_3dpline_ptlist plent)`  - line 1196-1211

Returns the vertex list of a heavy / 3D polyline.

- **Arguments**: `plent`
- **Returns**: value of the last expression: `plptlist`
- **Side effects**: Globals set (not declared local): `plptlist`, `pldata`, `mode`
- **Referenced**: 0

## chopspace

`(chopspace txtstr)`  - line 1216-1233

Trims trailing spaces from a string.

- **Arguments**: `txtstr`
- **Returns**: value of the last expression: `txtstr`
- **Side effects**: Globals set (not declared local): `dlen`, `lchar`
- **Referenced**: 12

## mparse

`(mparse strng delchar txtid coldata)`  - line 1235-1321

Splits a string on a delimiter.

- **Arguments**: `strng`, `delchar`, `txtid`, `coldata`
- **Returns**: value of the last expression: `fieldlist`
- **Side effects**: Globals set (not declared local): `stlen`, `modstr`, `strcnt`, `fieldlist`, `cmpchar`, `txtstr`, `fielditm`, `txtstrip`, `rmtxtid`
- **Referenced**: 4

## chg_tray_pl_wdth

`(chg_tray_pl_wdth trayent width_factor)`  - line 1323-1330

Sets the width of a polyline (tray / cable) by a factor (replaced by the MEDCableTray.lsp copy).

- **Arguments**: `trayent`, `width_factor`
- **Returns**: value of the last expression: `(entmod trayentdata)`
- **Side effects**: Globals set (not declared local): `trayentdata`, `trayoldwdth`, `traynewwidth`; Entities: `entmod`
- **Referenced**: 26
- **Duplicate**: also defined in Support\MEDCableTray.lsp:60; replaced at load time by Support\MEDCableTray.lsp:60

## chg_ent_ltype

`(chg_ent_ltype chgent chgltype)`  - line 1332-1348

Changes an entity's linetype.

- **Arguments**: `chgent`, `chgltype`
- **Returns**: value of the last expression: `(entmod chgentdata)`
- **Side effects**: Globals set (not declared local): `chgentdata`, `chgoldltype`, `chgnewltype`; Entities: `entmod`
- **Referenced**: 2

## get_con_tag

`(get_con_tag / r_tag)`  - line 1350-1365

Prompts for a conduit tag (default NONE).

- **Arguments**: none
- **Returns**: value of the last expression: `r_tag`
- **Prompts**: `Tag <NONE>:`
- **Referenced**: 16

## prc_detlist

`(prc_detlist l_index / trim cnt item fnd_desc)`  - line 1367-1385

DETAIL dialog: processes the picked list item.

- **Arguments**: `l_index`
- **Returns**: value of the last expression: `(while (setq item (read l_index)) (setq cmd_data_list (append cmd_data_list (list (nth item taglstng)))) (whil...`
- **Side effects**: Globals set (not declared local): `cmd_data_list`
- **Referenced**: 1

## upd_detaglst

`(upd_detaglst / moditem modent moddata modold modnew)`  - line 1386-1406

Updates the detail tag list (DETAGUPD).

- **Arguments**: none
- **Returns**: value of the last expression: `(if cmd_data_list (progn (foreach detail_item cmd_data_list (setq moditem (nth 3 detail_item) moditem (assoc (...`
- **Side effects**: Entities: `entmod`
- **Referenced**: 1

## mk_str_len

`(mk_str_len mkstr mklen / mkstrlen)`  - line 1411-1419

Pads a string to a length.

- **Arguments**: `mkstr`, `mklen`
- **Returns**: value of the last expression: `mkstr`
- **Referenced**: 2

## typstrins

`(typstrins typstrnm / inspt)`  - line 1422-1431

Inserts a typical-circuit block (menu macro helper).

- **Arguments**: `typstrnm`
- **Returns**: value of the last expression: `(if (findfile (strcat typstrnm ".dwg")) (progn (command "insert" typstrnm "pscale" _SC pause nil) (setq inspt ...`
- **Side effects**: AutoCAD commands: `INSERT`
- **Prompts**: `Bock not Found!`
- **Called from menu macros**: 31 item(s), e.g. med.cuix Image menu: Typical Elementary Circuits
- **Referenced**: 21

## opt_eq_ins

`(opt_eq_ins opeqlst eqscflg blname inlaylst / instr eqsc tvar oldatdia lblent ldrval)`  - line 1433-1484

Optional-equipment insert: inserts a detail block and adds MED_EQUIP xdata (menu macro helper).

- **Arguments**: `opeqlst`, `eqscflg`, `blname`, `inlaylst`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `TAT_VAL`, `eqdef`, `eqsel`, `_EQCODE`, `ADDTOENT`, `xdlist`; Xdata: writes xdata; DB: `medremapeqcodetoprojectcode`
- **Prompts**: `Select Entity to Add Detail to:`
- **Called from menu macros**: 55 item(s), e.g. MEDRibbon.cuix Ribbon: Detectors and Alarms > Flame Detector
- **Referenced**: 54

## verify_list

`(verify_list main_list test_list)`  - line 1489-1508

T when every item of a test list is in a main list.

- **Arguments**: `main_list`, `test_list`
- **Returns**: value of the last expression: `verify_ret`
- **Side effects**: Globals set (not declared local): `verify_ret`, `lst_cnt`, `lst_num`, `cmp_itm`
- **Referenced**: 1

## subst_txt

`(subst_txt txtstrng cxoldst cxnewst)`  - line 1512-1542

Replaces a substring in a string.

- **Arguments**: `txtstrng`, `cxoldst`, `cxnewst`
- **Returns**: value of the last expression: `newval`
- **Side effects**: Globals set (not declared local): `cxoldln`, `cxnewln`, `oldlen`, `oldcnt`, `newval`, `chngd`, `cmpval`
- **Referenced**: 1

## listtoggle

`(listtoggle listvar listitm)`  - line 1546-1555

Toggles an item in a global list.

- **Arguments**: `listvar`, `listitm`
- **Returns**: value of the last expression: `listvar`
- **Side effects**: Globals set (not declared local): `newval`, `oldval`
- **Referenced**: 5

## matchtxtprops

`(matchtxtprops mtchss chglist mstrdata)`  - line 1557-1579

Applies text properties from a master to a selection (overridden by medtext.lsp copy).

- **Arguments**: `mtchss`, `chglist`, `mstrdata`
- **Returns**: value of the last expression: `(while (< cnt num) (setq ent (ssname mtchss cnt) data(entget ent) cnt (1+ cnt) ) (foreach itm chgdata (setq ol...`
- **Side effects**: Globals set (not declared local): `chgdata`, `num`, `cnt`, `ent`, `data`, `oldvals`; Entities: `entmod`
- **Referenced**: 1
- **Duplicate**: also defined in Support\medtext.lsp:1025; replaced at load time by Support\medtext.lsp:1025

## attachfitting

`(attachfitting fitcd)`  - line 1581-1592

Adds a MED_FITTING record with a given code to a picked entity (menu macro helper).

- **Arguments**: `fitcd`
- **Returns**: value of the last expression: `(if atent (progn (setq atent (car atent) xdlist (bld_fitting fitcd _CSIZE "NONE" 0.0 0.0) ) (xdatadd atent xdl...`
- **Side effects**: Globals set (not declared local): `atent`, `xdlist`; Xdata: writes xdata
- **Called from menu macros**: 4 item(s), e.g. med.cuix Menu: Long Radius Elbows
- **Referenced**: 3

## move_attrib

`(move_attrib mventhead mvang mvdist mvtagname)`  - line 1594-1613

Moves an attribute of an insert by angle and distance.

- **Arguments**: `mventhead`, `mvang`, `mvdist`, `mvtagname`
- **Returns**: value of the last expression: `(entupd mventhead)`
- **Side effects**: Globals set (not declared local): `mvattag`, `mvattagdata`, `oldpos`, `newpos`, `old11pos`, `new11pos`; Entities: `entmod`
- **Referenced**: 2

## getdettags

`(getdettags / det_ss detlnum det_cnt det_ent att_vals det_typ det_num det_code det_actl tagitem)`  - line 1616-1702

Collects detail tags in the drawing.

- **Arguments**: none
- **Returns**: value of the last expression: `(if det_ss (progn (setq detlnum (sslength det_ss) det_cnt 0 dispcnt 1 ) (while (< det_cnt detlnum) (setq det_e...`
- **Side effects**: Globals set (not declared local): `taglstng`, `tagdisplay`, `tmp_ss`, `tmp_len`, `tmp_cnt`, `tmp_ent`, `dispcnt`, `det_num1`, `det_num1a`, `dsp_det_num`, `det_code1`, `det_tags`; DB: `med_detail`
- **Referenced**: 1

## getatvals

`(getatvals attent / attdata attretlst)`  - line 1704-1723

Returns the attribute tag/value pairs of an insert.

- **Arguments**: `attent`
- **Returns**: value of the last expression: `attretlst`
- **Referenced**: 1

## xdatappend

`(xdatappend xdlist1 xdlist2)`  - line 1725-1734

Merges two xdata lists.

- **Arguments**: `xdlist1`, `xdlist2`
- **Returns**: value of the last expression: `xdlist`
- **Side effects**: Globals set (not declared local): `data1list`, `xdlist`, `data2list`
- **Referenced**: 4

## medcount

`(medcount appname matcode appsize apptag apprtag appalt appdpth appmsr / cnt_data)`  - line 1736-1846

Counts entities with matching MED xdata fields.

- **Arguments**: `appname`, `matcode`, `appsize`, `apptag`, `apprtag`, `appalt`, `appdpth`, `appmsr`
- **Returns**: value of the last expression: `cntr`
- **Side effects**: Globals set (not declared local): `appss`, `num`, `cnt`, `cntr`, `_COUNTSS`, `ttllen`, `numapps`, `numcnt`, `worklist`, `workcnt`, `tmp_list`, `workdata`, `tmp_cnt`, `mcmp`; Xdata: reads xdata
- **Referenced**: 3

## dblchck

`(dblchck ckpt / dblnum dblcnt dblent dbldata dblinfo condata dblsz dbllett)`  - line 1852-1909

this function will return one of two items pending on a value of ckpt if ckpt is true then dblchk will erase entities assosiated with a double line conduit found at the point specified by ckpt

- **Arguments**: `ckpt`
- **Returns**: value of the last expression: `dbllett`
- **Side effects**: Globals set (not declared local): `_MEDR14_BRKENT`, `dbl1ent`, `dbl2ent`, `chklist`, `lgsz`; Xdata: reads xdata; Entities: `entdel`
- **Referenced**: 2

## med_brk_out

`(med_brk_out bk_ang bk_pt bk_dlst tray_flag / s_ents enset)`  - line 1914-1958

This function is responsible for breaking out distances supplied if any

- **Arguments**: `bk_ang`, `bk_pt`, `bk_dlst`, `tray_flag`
- **Returns**: value of the last expression: `(if PRIM_ENT (progn (setq RL_SS (ssadd PRIM_ENT) PRIM_ENT nil ) ) (progn (setq nlstent (entlast)) (if (not (eq...`
- **Side effects**: Globals set (not declared local): `lastchk`, `bk_d1`, `bk_d2`, `bk_d3`, `bk_d4`, `RL_SS`, `PRIM_ENT`, `nlstent`
- **Referenced**: 17

## xdr2line

`(xdr2line xdrelent1 xdrelent2 xdmainent / handmdata handr1data handr2data rent1data rent2data rxdadd mentdata mxdadd)`  - line 1964-1995

Function adds the handles of first two entities to last entity and then adds handle of last entity to first two entities, but will remove all xdata from first two entities before doing so

- **Arguments**: `xdrelent1`, `xdrelent2`, `xdmainent`
- **Returns**: value of the last expression: `(entmod mentdata)`
- **Side effects**: Xdata: writes xdata; Entities: `entmod`
- **Referenced**: 2

## xdstrip

`(xdstrip stent strp_appcode / stentdata stxdata xdata newxdata cnt num)`  - line 1999-2027

routine to remove all xdata existing in passed entity

- **Arguments**: `stent`, `strp_appcode`
- **Returns**: value of the last expression: `(if xdata (progn (setq newxdata (list (list (car (nth 0 xdata)))) cnt 1 num (length xdata) ) (while (< cnt num...`
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmod`
- **Referenced**: 9

## attmod

`(attmod attmodent / attmoddat stepent stepdata stepval)`  - line 2032-2075

function for modifying entities inserted with attributes after a complete insertion has been made with ATTREQ off

- **Arguments**: `attmodent`
- **Returns**: value of the last expression: `(if (and (= (dxf 0 attmoddat) "INSERT") (dxf 66 attmoddat)) (progn (setq stepent (entnext attmodent) stepdata(...`
- **Side effects**: Entities: `entmod`; AutoCAD commands: `DDATTE`
- **Prompts**: `No Attributes`
- **Referenced**: 2

## be

`(be pta ptb / pt)`  - line 2079-2095

function returns a point between two points provided

- **Arguments**: `pta`, `ptb`
- **Returns**: value of the last expression: `pt`
- **Prompts**: `Select first point:`; `Select second point:`
- **Referenced**: 103

## between

`(between)`  - line 2097-2099

Calls (be nil nil) - be (line 2079) returns the point between two points, so nil arguments would error. Nothing calls between - looks like a leftover test. TODO: confirm with Clint.

- **Arguments**: none
- **Returns**: value of the last expression: `(be nil nil)`
- **Referenced**: 7

## xdataget

`(xdataget ent app_name / xdlist)`  - line 2104-2172

Returns an application's xdata from an entity (this copy wins).

- **Arguments**: `ent`, `app_name`
- **Returns**: value of the last expression: `xdlist`
- **Side effects**: Globals set (not declared local): `entdata`, `xdatalist`, `xdlen`, `xdcnt`, `xdval`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 73
- **Duplicate**: also defined in Support\MEDFunctions.lsp:708; this definition loads last and wins

## xd_apps

`(xd_apps ent)`  - line 2174-2195

Returns the MED xdata app lists of an entity.

- **Arguments**: `ent`
- **Returns**: value of the last expression: `applist`
- **Side effects**: Globals set (not declared local): `finallist`, `entdata`, `xdatalist`, `numapps`, `xdcnta`, `applist`, `xdatalista`, `appnm`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 7

## xdatadd

`(xdatadd ent xdata)`  - line 2199-2206

function to add xdata provided to provided entity

- **Arguments**: `ent`, `xdata`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `xentdata`, `xdadd`; Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmod`
- **Referenced**: 67

## MEDSetMedProperties

`(MEDSetMedProperties ent objectType size description tag length weight / xd r w)`  - line 2210-2236

MEDProperties: 3D model identification only (NOT BOM). Excluded from xd_apps. Prefers .NET MED-SetMedProperties (XData + {dwg}.medprops.json upsert). Falls back to LISP XData plus MED-UpsertMedPropertiesJson when the DLL is loaded; pure LISP XData if not.

- **Arguments**: `ent`, `objectType`, `size`, `description`, `tag`, `length`, `weight`
- **Returns**: value of the last expression: `ent`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 1

## MEDRebuildMedPropsJsonBeside

`(MEDRebuildMedPropsJsonBeside dwgPath / r titled)`  - line 2241-2266

After 3D tray/conduit export: write/update {dwg}.medprops.json beside a saved DWG. dwgPath nil = active document; otherwise rebuild from that on-disk file (WBLOCK target). Unsaved active drawing: skip with a clear message (do not fail the export).

- **Arguments**: `dwgPath`
- **Returns**: nothing useful (quiet exit)
- **Prompts**: `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).`
- **Referenced**: 7

## MEDStamp3DFromBom

`(MEDStamp3DFromBom solidEnt sourceEnt objectType lengthOverride / bomApp xd tag size code dist desc sizeStr lenStr ot)`  - line 2272-2343

Stamp MEDProperties on a 3D entity from source BOM XData (same fields as tray). objectType: TRAY|FITTING|CABLE|CONDUIT|EQUIPMENT (schema kept even if exporters incomplete). lengthOverride: optional string; when nil, TRAY/CABLE/CONDUIT use BOM dist; FITTING/EQUIPMENT Length="". Call after each 3D solid is created: ...

- **Arguments**: `solidEnt`, `sourceEnt`, `objectType`, `lengthOverride`
- **Returns**: value of the last expression: `(if (not (and solidEnt sourceEnt objectType)) solidEnt (progn (setq ot (strcase (vl-princ-to-string objectType...`
- **Side effects**: Xdata: writes xdata, reads xdata
- **Referenced**: 22

## clookup

`(clookup lookcode size apptype)`  - line 2349-2391

Builds the size + description string for a code/size/app type from the catalog (this copy wins).

- **Arguments**: `lookcode`, `size`, `apptype`
- **Returns**: value of the last expression: `rstr`
- **Side effects**: Globals set (not declared local): `rstr`, `aplk`, `rval`; DB: `med_getdesc`
- **Referenced**: 32
- **Duplicate**: also defined in Support\MEDFunctions.lsp:176; this definition loads last and wins

## getsize

`(getsize gtlett gtsize)`  - line 2395-2446

function returns a listing of size info about arguments passed

- **Arguments**: `gtlett`, `gtsize`
- **Returns**: value of the last expression: `GT_INFO`
- **Side effects**: Globals set (not declared local): `GT_INFO`
- **Referenced**: 14

## med_conduit_od

`(med_conduit_od mco_code mco_size / mco_key mco_hit mco_od mco_res mco_val mco_gs)`  - line 2453-2495

Conduit outside diameter (inches) by conduit type + trade size. Looks up MEDConduitOD (ConduitCode = CONDUIT ITEMCODE, TradeSizeDec = xdata size). Falls back to the steel-pipe OD in getsize when the table, the row, or OD_in is missing, so results are identical to the old behavior without the table. Results are ...

- **Arguments**: `mco_code`, `mco_size`
- **Returns**: value of the last expression: `(if mco_od mco_od (nth 1 mco_gs) )`
- **Side effects**: Globals set (not declared local): `_MEDCONDUITOD_CACHE`
- **Referenced**: 8

## ltback

`(ltback sltp)`  - line 2500-2512

function sets the linetype to specified argument passed if nil sets linetype to bylayer

- **Arguments**: `sltp`
- **Returns**: value of the last expression: `(if (not sltp) (progn (command "linetype" "s" "bylayer" "") (setq _LTP "bylayer") ) (progn (command "linetype"...`
- **Side effects**: Globals set (not declared local): `_LTP`; AutoCAD commands: `LINETYPE`
- **Referenced**: 33

## insblk

`(insblk blname ipt blsc insrot)`  - line 2519-2521

simple function for inserting a block at a specified point rotation and scale

- **Arguments**: `blname`, `ipt`, `blsc`, `insrot`
- **Returns**: value of the last expression: `(command "insert" blname ipt blsc blsc insrot)`
- **Side effects**: AutoCAD commands: `INSERT`
- **Referenced**: 6

## toggle

`(toggle medvar togprmpt)`  - line 2528-2548

function toggles MED variables off or on and prompts the user of the current status of that variable

- **Arguments**: `medvar`, `togprmpt`
- **Returns**: nothing useful (quiet exit)
- **Called from menu macros**: 7 item(s), e.g. med.cuix Image menu: Plan Conduit
- **Referenced**: 3

## retr_size_tag

`(retr_size_tag con_ss / cnt num cmsize consize cmpent cmlent rtsize concode)`  - line 2550-2616

Returns size and tag from a conduit selection set.

- **Arguments**: `con_ss`
- **Returns**: value of the last expression: `rt_size`
- **Side effects**: Globals set (not declared local): `cssize`, `contag`, `mxtag`, `mxcode`, `cslent`, `mntag`, `mncode`, `rt_size`, `testdata`; Xdata: reads xdata
- **Referenced**: 3

## feedset

`(feedset dbl_name)`  - line 2622-2627

this function simply returns a string concatenation of a block prefix name for feed through devices

- **Arguments**: `dbl_name`
- **Returns**: value of the last expression: `dbl_name`
- **Called from menu macros**: 12 item(s), e.g. med.cuix Image menu: Detail Outlet Devices
- **Referenced**: 5

## brk_rot

`(brk_rot br_pt br_blname br_sc)`  - line 2633-2785

This function will simply break out an object and return a rotation for a block to be inserted.

- **Arguments**: `br_pt`, `br_blname`, `br_sc`
- **Returns**: value of the last expression: `br_ang`
- **Side effects**: Globals set (not declared local): `DETDATA`, `brblnm`, `NEW_BLNAME`, `bl_sz`, `br_data`, `br_bldata`, `br_d1`, `br_d2`, `br_d3`, `br_d4`, `rt_spec`, `br_list`, `oldaperture`, `br_ang`, `br_pt2` ...; Entities: `entdel`; AutoCAD commands: `INSERT`
- **Prompts**: `Select point on line for rotation:`; `PT4`; `PT3`; `Rotation:`
- **Referenced**: 2

## med_cur_set

`(med_cur_set func_name)`  - line 2788-2831

Full command-start hook: saves sysvars, installs the MED *error* handler, records _FUNCNAME. Replaced at load time by the stub MEDCore.lsp defines later, so it never runs.

- **Arguments**: `func_name`
- **Returns**: value of the last expression: `(if (not MED_ERROR) (progn (setq MED_ERROR T MED_ERR_CNT 0 ) (setq MED_SYSVARS (list (getvar "CELTYPE") (getva...`
- **Side effects**: Globals set (not declared local): `MED_ERROR`, `MED_ERR_CNT`, `MED_SYSVARS`, `olderr`, `_FUNCNAME`, `trap_trcode`, `trap_trtype`, `trap_trdepth`, `trap_trsize`, `*error*`; Layers: creates/sets layers (LAYER command / CLAYER)
- **Referenced**: 62
- **Duplicate**: also defined in Support\MEDCore.lsp:87; replaced by that stub (MEDCore defines it after loading this file)

## *error*

`(*error* errmsg)`  - line 2816-2821 (nested defun)

MED error handler installed by med_cur_set: restores sysvars and reports.

- **Arguments**: `errmsg`
- **Returns**: value of the last expression: `(setq *error* olderr)`
- **Side effects**: Globals set (not declared local): `*error*`
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DCON.lsp:135, Support\MED3DFittings.lsp:963, Support\MED3DPath.lsp:1080, Support\MED3DTrayFunctions.lsp:468, Support\MEDFunctions.lsp:921; replaced at load time by Support\MED3DFittings.lsp:963

## med_reset

`(med_reset)`  - line 2832-2844

Resets tray globals and error handler after a command.

- **Arguments**: none
- **Returns**: value of the last expression: `(setq *error* olderr)`
- **Side effects**: Globals set (not declared local): `_TRCODE`, `_TRTYPE`, `_TRDEPTH`, `_TRSIZE`, `*error*`
- **Referenced**: 1

## med_ret_ok

`(med_ret_ok)`  - line 2845-2855

Command-end hook: restores sysvars and the previous *error*.

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `*error*`, `MED_ERR_CNT`
- **Referenced**: 56

## med_verify

`(med_verify / rkval expdate)`  - line 2857-2873

Legacy licence check with a hard-coded 2001-03-15 expiry (alerts and exits after that date). Not called anywhere - dead code. TODO: confirm with Clint it can go.

- **Arguments**: none
- **Returns**: value of the last expression: `rkval`
- **Side effects**: Globals set (not declared local): `dtnum`, `dtstr`
- **Referenced**: 0

## addatrib

`(addatrib at_tag at_val at_ent at_pt)`  - line 2876-2929

Adds an attribute to a block (ATADD worker).

- **Arguments**: `at_tag`, `at_val`, `at_ent`, `at_pt`
- **Returns**: value of the last expression: `(entmake (list (cons 0 "SEQEND")))`
- **Side effects**: Globals set (not declared local): `tagnm`, `atval`, `inspt`, `blkdata`, `suben`, `subdata`, `newblk`, `addent`; Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmake`, `entdel`
- **Prompts**: `Select Block to Add Attribute to:`; `TAG:`; `Value:`; `Select Point for Insertion of Attribute:`
- **Referenced**: 0

## newsz

`(newsz act let sz)`  - line 2930-2945

Sets the current conduit size globals (_ACSIZE _CLETT _CSIZE).

- **Arguments**: `act`, `let`, `sz`
- **Returns**: value of the last expression: `(if act (setq _NEWSIZELST (list act let sz)) )`
- **Side effects**: Globals set (not declared local): `_ACSIZE`, `_CLETT`, `_CSIZE`, `_NEWSIZELST`
- **Referenced**: 22

## settog

`(settog option togval)`  - line 2946-3031

Sets a toggle global from MEDSETTINGS/menus.

- **Arguments**: `option`, `togval`
- **Returns**: value of the last expression: `(if option (progn (cond ((= option 1) (if (equal togval "1") (progn (setq _NTOGGLES (append _NTOGGLES (list (l...`
- **Side effects**: Globals set (not declared local): `_NTOGGLES`
- **Referenced**: 0

## setmedval

`(setmedval option $value)`  - line 3032-3050

Sets a value global from MEDSETTINGS/menus.

- **Arguments**: `option`, `$value`
- **Returns**: value of the last expression: `(if option (progn (cond ((= option 5) (setq _NVALS (append _NVALS (list (list "_MEDRADFAC" (atof $value))))) )...`
- **Side effects**: Globals set (not declared local): `_NVALS`
- **Referenced**: 0

## MEDremoveitemfromlist

`(MEDremoveitemfromlist originallist removelist)`  - line 3052-3063

Removes items from a list.

- **Arguments**: `originallist`, `removelist`
- **Returns**: value of the last expression: `returnlist`
- **Side effects**: Globals set (not declared local): `returnlist`, `ReturnList`
- **Referenced**: 0

## MEDRemapEQCodeToProjectCode

`(MEDRemapEQCodeToProjectCode equipmentcode)`  - line 3065-3075

Maps an equipment code to the project code via SQL.

- **Arguments**: `equipmentcode`
- **Returns**: value of the last expression: `CodeToUse`
- **Side effects**: Globals set (not declared local): `SQLLookupStatement`, `Lookupresults`, `CodeToUse`; DB: `medprocesssqlstatement`
- **Referenced**: 2

