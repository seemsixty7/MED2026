# medtray.lsp

`Support\medtray.lsp` - Older tray code: tray elbows/size DCL, channel, side-view tray, legacy 3D tray, ESOLID.

Loaded by MEDCore (order 5). 42 defun(s): 22 command(s), 20 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:trayrel`](#ctrayrel) | command |
| 6 | [`c:trayrer`](#ctrayrer) | command |
| 10 | [`c:tray60`](#ctray60) | command |
| 14 | [`c:tray45`](#ctray45) | command |
| 18 | [`c:tray30`](#ctray30) | command |
| 22 | [`c:traysize`](#ctraysize) | command |
| 98 | [`c:vtray`](#cvtray) | command |
| 108 | [`c:channel`](#cchannel) | command |
| 130 | [`opposite_tray_endpt`](#opposite_tray_endpt) | function |
| 169 | [`c:vtray60`](#cvtray60) | command |
| 185 | [`c:vtray45`](#cvtray45) | command |
| 201 | [`c:vtray30`](#cvtray30) | command |
| 217 | [`c:chantee`](#cchantee) | command |
| 221 | [`c:chancross`](#cchancross) | command |
| 225 | [`c:chanv90`](#cchanv90) | command |
| 231 | [`c:chan60`](#cchan60) | command |
| 237 | [`c:chan45`](#cchan45) | command |
| 243 | [`c:chan30`](#cchan30) | command |
| 249 | [`c:chan90`](#cchan90) | command |
| 255 | [`c:chanoff`](#cchanoff) | command |
| 263 | [`xdrtray`](#xdrtray) | function |
| 288 | [`maketray`](#maketray) | function |
| 333 | [`tray_brk_rot`](#tray_brk_rot) | function |
| 458 | [`traychck`](#traychck) | function |
| 486 | [`get_tray_data`](#get_tray_data) | function |
| 555 | [`vtrayfitsel`](#vtrayfitsel) | function |
| 569 | [`tryupdn`](#tryupdn) | function |
| 712 | [`c:vtrayoff`](#cvtrayoff) | command |
| 721 | [`pmake`](#pmake) | function |
| 764 | [`m3dtray`](#m3dtray) | function |
| 870 | [`mtrayfit`](#mtrayfit) | function |
| 926 | [`m3dtrayfit`](#m3dtrayfit) | function |
| 972 | [`make_elbow`](#make_elbow) | function |
| 1006 | [`make_tee`](#make_tee) | function |
| 1048 | [`make_cross`](#make_cross) | function |
| 1105 | [`make_re`](#make_re) | function |
| 1133 | [`m3dvtrayfit`](#m3dvtrayfit) | function |
| 1180 | [`3dtrayang`](#3dtrayang) | function |
| 1230 | [`pl_arc_info_from_buldge`](#pl_arc_info_from_buldge) | function |
| 1240 | [`make_relr`](#make_relr) | function |
| 1279 | [`c:test`](#ctest) | command |
| 1322 | [`c:esolid`](#cesolid) | command |

## c:trayrel

`(c:trayrel)`  - line 2-5

Left-hand tray reducer. User entry: [TRAYREL](../command-reference.md#trayrel).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:trayrer

`(c:trayrer)`  - line 6-9

Right-hand tray reducer. User entry: [TRAYRER](../command-reference.md#trayrer).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:tray60

`(c:tray60)`  - line 10-13

Horizontal tray elbow of that angle at a tray end. User entry: [TRAY60](../command-reference.md#tray60).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:tray45

`(c:tray45)`  - line 14-17

Horizontal tray elbow of that angle at a tray end. User entry: [TRAY45](../command-reference.md#tray45).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:tray30

`(c:tray30)`  - line 18-21

Horizontal tray elbow of that angle at a tray end. User entry: [TRAY30](../command-reference.md#tray30).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:traysize

`(c:traysize / tsz_sizelist)`  - line 22-95

DCL for tray size, depth, type and radius. User entry: [TRAYSIZE](../command-reference.md#traysize).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (> (setq index_val (load_dialog "MED")) 0) (progn (if (new_dialog "Med_TraySize" index_val) (progn (set_ti...`
- **Side effects**: Globals set (not declared local): `tsz_depthlist`, `tsz_radiuslist`, `curwidth`, `curdepth`, `curradius`, `tsz_width`, `tsz_depth`, `tsz_radius`, `tsz_add`, `index_val`, `result`, `_TRSIZE`, `_TRDEPTH`, `_TRRAD`, `_TRFITTADD`
- **Referenced**: 0

## c:vtray

`(c:vtray / cltp clay trpt1 trpt2 trtag xdlist)`  - line 98-107

Side-view (vertical) tray run. User entry: [VTRAY](../command-reference.md#vtray).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `oldvert_tray`, `_VERTICALTRAY`
- **Referenced**: 0

## c:channel

`(c:channel / tmp_trcode tmp_trtype tmp_trdepth tmp_trsize)`  - line 108-129

Cable channel run (4" default). User entry: [CHANNEL](../command-reference.md#channel).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `tmp_flange`, `_TRCODE`, `_TRTYPE`, `_TRDEPTH`, `_TRSIZE`, `_TRAYFLANGE`
- **Referenced**: 1

## opposite_tray_endpt

`(opposite_tray_endpt pln_hdent pl_endpt / pl_data ptlist ret_pt ptlistlen)`  - line 130-167

Returns the opposite end point of a tray polyline.

- **Arguments**: `pln_hdent`, `pl_endpt`
- **Returns**: value of the last expression: `ret_pt`
- **Side effects**: Globals set (not declared local): `otept1`, `otept2`
- **Referenced**: 6

## c:vtray60

`(c:vtray60)`  - line 169-184

Side-view tray elbow of that angle (inside/outside). User entry: [VTRAY60](../command-reference.md#vtray60).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `olverttr`, `_VERTICALTRAY`, `fittype`, `trfitcd`
- **Referenced**: 0

## c:vtray45

`(c:vtray45)`  - line 185-200

Side-view tray elbow of that angle (inside/outside). User entry: [VTRAY45](../command-reference.md#vtray45).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `olverttr`, `_VERTICALTRAY`, `fittype`, `trfitcd`
- **Referenced**: 0

## c:vtray30

`(c:vtray30)`  - line 201-216

Side-view tray elbow of that angle (inside/outside). User entry: [VTRAY30](../command-reference.md#vtray30).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `olverttr`, `_VERTICALTRAY`, `fittype`, `trfitcd`
- **Referenced**: 0

## c:chantee

`(c:chantee)`  - line 217-220

Cable channel tee / cross. User entry: [CHANTEE](../command-reference.md#chantee).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:traytee)`
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chancross

`(c:chancross)`  - line 221-224

Cable channel tee / cross. User entry: [CHANCROSS](../command-reference.md#chancross).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:traycross)`
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chanv90

`(c:chanv90)`  - line 225-228

Cable channel up / down / plan vertical 90. User entry: [CHANV90](../command-reference.md#chanv90).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:trayv90)`
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chan60

`(c:chan60)`  - line 231-236

Cable channel elbow of that angle. User entry: [CHAN60](../command-reference.md#chan60).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chan45

`(c:chan45)`  - line 237-242

Cable channel elbow of that angle. User entry: [CHAN45](../command-reference.md#chan45).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chan30

`(c:chan30)`  - line 243-248

Cable channel elbow of that angle. User entry: [CHAN30](../command-reference.md#chan30).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chan90

`(c:chan90)`  - line 249-254

Cable channel elbow of that angle. User entry: [CHAN90](../command-reference.md#chan90).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## c:chanoff

`(c:chanoff)`  - line 255-259

Cable channel offset. User entry: [CHANOFF](../command-reference.md#chanoff).

- **Arguments**: none
- **Returns**: value of the last expression: `(setq _CHANTEE nil)`
- **Side effects**: Globals set (not declared local): `_CHANTEE`
- **Referenced**: 0

## xdrtray

`(xdrtray xdrelent1 xdmainent / handmdata handr1data)`  - line 263-286

Older copy of xdrtray (medtray.lsp loads first; the MEDCableTray.lsp version wins).

- **Arguments**: `xdrelent1`, `xdmainent`
- **Returns**: value of the last expression: `(entmod mentdata)`
- **Side effects**: Globals set (not declared local): `mentdata`, `mxdadd`, `_VERTICALTRAY`, `_RESETVTRAY`; Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmod`
- **Referenced**: 8
- **Duplicate**: also defined in Support\MEDCableTray.lsp:137; replaced at load time by Support\MEDCableTray.lsp:137

## maketray

`(maketray traylist closeflag layerset / clay vtxt sqend vtxt vert vertxt)`  - line 288-330

Older copy of maketray (overridden by MEDCableTray.lsp).

- **Arguments**: `traylist`, `closeflag`, `layerset`
- **Returns**: value of the last expression: `(entmake plin)`
- **Side effects**: Globals set (not declared local): `plin`, `bldlayer`, `ptlistlen`, `ver1`, `ver2`, `ver3`, `twoten`; Layers: `layerset` (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 20
- **Duplicate**: also defined in Support\MEDCableTray.lsp:364; replaced at load time by Support\MEDCableTray.lsp:364

## tray_brk_rot

`(tray_brk_rot br_pt br_bldata)`  - line 333-452

Tray fitting break and rotation at a point.

- **Arguments**: `br_pt`, `br_bldata`
- **Returns**: value of the last expression: `br_ang`
- **Side effects**: Globals set (not declared local): `br_data`, `br_d1`, `br_d2`, `br_d3`, `br_d4`, `rt_spec`, `br_list`, `bl_sz`, `pckbx`, `br_ang`, `br_pt2`, `tmp_ang`, `br_pt3`, `br_pt4`, `sub_ang`
- **Prompts**: `Select point on line for rotation:`; `PT4`; `PT3`; `Rotation:`
- **Referenced**: 5

## traychck

`(traychck ckpt)`  - line 458-484

Tray equivalent of dblchck: returns / erases the entities of a double-line tray depending on the check flag.

- **Arguments**: `ckpt`
- **Returns**: value of the last expression: `(while (< trcnt trsslen) (setq dblent (ssname trayss trcnt) dbldata (xdataget dblent _DOUBLE) trcnt (1+ trcnt)...`
- **Side effects**: Globals set (not declared local): `trayss`, `trsslen`, `trcnt`, `TR_MAIN`, `dblent`, `dbldata`, `dbl1ent`; Xdata: reads xdata; Entities: `entdel`
- **Referenced**: 6

## get_tray_data

`(get_tray_data tray_ss / cnt num cmsize tray_size cmpent cmlent rtsize tray_code)`  - line 486-552

Older copy of get_tray_data (overridden by MEDCableTray.lsp).

- **Arguments**: `tray_ss`
- **Returns**: value of the last expression: `rt_size`
- **Side effects**: Globals set (not declared local): `cssize`, `tr_tag`, `tr_code`, `tr_size`, `tr_dpth`, `tr_flng`, `mxtag`, `mxcode`, `mxdpth`, `mxent`, `cslent`, `mntag`, `mncode`, `mdpth`, `mnent` ...; Xdata: reads xdata
- **Referenced**: 12
- **Duplicate**: also defined in Support\MEDCableTray.lsp:296; replaced at load time by Support\MEDCableTray.lsp:296

## vtrayfitsel

`(vtrayfitsel outopt inopt / degfit1)`  - line 555-566

Inside/outside choice for vertical tray fittings.

- **Arguments**: `outopt`, `inopt`
- **Returns**: value of the last expression: `degfit1`
- **Side effects**: Globals set (not declared local): `olverttr`, `_VERTICALTRAY`, `fittype`
- **Prompts**: `Inside or <Outside>:`
- **Referenced**: 0

## tryupdn

`(tryupdn traydir trltype trptlist startingelev)`  - line 569-710

Tray up/down worker.

- **Arguments**: `traydir`, `trltype`, `trptlist`, `startingelev`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `cltp`, `clay`, `acttraydir`, `trbasent`, `pt1`, `opt1`, `pt3`, `pt2`, `pt4`, `trsizess`, `trsize`, `trdnverdata`, `trdncnt`, `trsizesslen`, `trdnentdata` ...; Xdata: writes xdata, reads xdata; Layers: creates/sets layers (LAYER command / CLAYER)
- **Prompts**: `Select Tray item`
- **Referenced**: 0

## c:vtrayoff

`(c:vtrayoff)`  - line 712-719

Side-view tray offset. User entry: [VTRAYOFF](../command-reference.md#vtrayoff).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_VERTICALTRAY`
- **Referenced**: 1

## pmake

`(pmake ptlist plclose)`  - line 721-761

Entmakes a polyline from a point list.

- **Arguments**: `ptlist`, `plclose`
- **Returns**: value of the last expression: `(setq CR_LAYER nil)`
- **Side effects**: Globals set (not declared local): `plin`, `ptlistlen`, `elev`, `_USEELEV`, `vert`, `ver1`, `ver2`, `ver3`, `twoten`, `_ZFLAG`, `CR_LAYER`; Entities: `entmake`
- **Referenced**: 18

## m3dtray

`(m3dtray trent)`  - line 764-869

Legacy 3D tray from a tray entity (EXTRUDE).

- **Arguments**: `trent`
- **Returns**: value of the last expression: `(if (and trentdata trentvdata) (progn (setq vtrydir (nth 3 trentvdata) vtryadd (nth 4 trentvdata) ) (if (= vtr...`
- **Side effects**: Globals set (not declared local): `trentdata`, `trentvdata`, `vtrydir`, `vtryadd`, `ptlist`, `trpt1`, `trpt2`, `trang`, `trdist`, `trsize`, `trpt3`, `trpt4`, `trpt5`, `trpt6`, `3dmkelev` ...; Xdata: reads xdata; Entities: `entmod`; AutoCAD commands: `EXTRUDE`, `MOVE`, `ROTATE`
- **Referenced**: 0

## mtrayfit

`(mtrayfit trayfitent trayfitdata NoFlangeFlag)`  - line 870-925

Tray fitting outline / legacy 3D tray fitting.

- **Arguments**: `trayfitent`, `trayfitdata`, `NoFlangeFlag`
- **Returns**: value of the last expression: `(setvar "ELEVATION" m3delev)`
- **Side effects**: Globals set (not declared local): `fitptbllist`, `fitptlist`, `fitbllist`, `fitwidth`, `fitdpth`, `fitalt`, `m3delev`, `fitflange`, `trayfitentdata`, `fitOCS`, `clay`, `CR_LAYER`; Xdata: writes xdata, reads xdata; Layers: `_MEDTRAY` (LAYER command / CLAYER)
- **Referenced**: 2

## m3dtrayfit

`(m3dtrayfit trayfitent trayfitdata)`  - line 926-970

Tray fitting outline / legacy 3D tray fitting.

- **Arguments**: `trayfitent`, `trayfitdata`
- **Returns**: value of the last expression: `(setvar "ELEVATION" m3delev)`
- **Side effects**: Globals set (not declared local): `fitptbllist`, `fitptlist`, `fitbllist`, `fitwidth`, `fitdpth`, `fitalt`, `m3delev`, `trayfitentdata`; Xdata: reads xdata; AutoCAD commands: `EXTRUDE`
- **Referenced**: 0

## make_elbow

`(make_elbow elbowdatalist trwidth)`  - line 972-1004

Point lists for tray elbow / tee / cross / reducer / left-right reducer outlines.

- **Arguments**: `elbowdatalist`, `trwidth`
- **Returns**: value of the last expression: `(MEDmaketray mlist T nil (MEDGetCurrentOCS))`
- **Side effects**: Globals set (not declared local): `pts`, `bls`, `pt1`, `pt2`, `pt3`, `pt4`, `bul1`, `ang1`, `ang2`, `tandist`, `arcdata`, `rad`, `apt1`, `apt2`, `apt3` ...
- **Referenced**: 3

## make_tee

`(make_tee teedatalist trwidth)`  - line 1006-1047

Point lists for tray elbow / tee / cross / reducer / left-right reducer outlines.

- **Arguments**: `teedatalist`, `trwidth`
- **Returns**: value of the last expression: `(MEDmaketray mlist T nil (MEDGetCurrentOCS))`
- **Side effects**: Globals set (not declared local): `pts`, `bls`, `pt1`, `pt2`, `pt3`, `pt4`, `pt5`, `pt6`, `bul1`, `bul2`, `ang1`, `ang2`, `ang3`, `tandist`, `arcdata1` ...
- **Referenced**: 3

## make_cross

`(make_cross crossdatalist trwidth)`  - line 1048-1103

Point lists for tray elbow / tee / cross / reducer / left-right reducer outlines.

- **Arguments**: `crossdatalist`, `trwidth`
- **Returns**: value of the last expression: `(MEDmaketray mlist T nil (MEDGETCurrentOCS))`
- **Side effects**: Globals set (not declared local): `pts`, `bls`, `pt1`, `pt2`, `pt3`, `pt4`, `pt5`, `pt6`, `pt7`, `pt8`, `bul1`, `ang1`, `ang2`, `ang3`, `ang4` ...
- **Referenced**: 3

## make_re

`(make_re redatalist trwidth1 trwidth2)`  - line 1105-1131

Point lists for tray elbow / tee / cross / reducer / left-right reducer outlines.

- **Arguments**: `redatalist`, `trwidth1`, `trwidth2`
- **Returns**: value of the last expression: `(MEDmaketray mlist T nil (MEDGetCurrentOCS))`
- **Side effects**: Globals set (not declared local): `pts`, `bls`, `pt1`, `pt2`, `ang1`, `tandist`, `apt1`, `apt2`, `apt3`, `apt4`, `bpt1`, `bpt2`, `bpt3`, `bpt4`, `mlist`
- **Referenced**: 3

## m3dvtrayfit

`(m3dvtrayfit trent)`  - line 1133-1179

Legacy 3D vertical tray fitting.

- **Arguments**: `trent`
- **Returns**: value of the last expression: `(if (and trentdata trvdata) (progn (setq trpt (nth 0 (bld_lw_ptlist trent)) trpt1 (cdr (nth 0 trpt)) trpt2 (cd...`
- **Side effects**: Globals set (not declared local): `trentdata`, `trvdata`, `trpt`, `trpt1`, `trpt2`, `actgenang`, `sendlist`, `sendgenang`, `rotateang`, `shiftfact`, `3dvent`, `3dventdata`, `3dold`, `3dnew`, `3dventpts` ...; Xdata: reads xdata; Entities: `entmod`; AutoCAD commands: `EXTRUDE`, `MOVE`, `ROTATE`
- **Referenced**: 2

## 3dtrayang

`(3dtrayang inclang intpt genang tr_dat_lst / tr_data)`  - line 1180-1225

3D tray elbow at an angle (up/down).

- **Arguments**: `inclang`, `intpt`, `genang`, `tr_dat_lst`
- **Returns**: value of the last expression: `(maketray mlist T nil)`
- **Side effects**: Globals set (not declared local): `trsize`, `trdpth`, `trrad`, `trtan`, `angpol`, `troff`, `br_len`, `bul`, `tpt1`, `tcen`, `tpt2`, `pt1`, `pt2`, `tpt`, `tang` ...
- **Referenced**: 1

## pl_arc_info_from_buldge

`(pl_arc_info_from_buldge gpt1 gpt2 gpbul)`  - line 1230-1239

Arc radius/angle/chord from two points and a bulge.

- **Arguments**: `gpt1`, `gpt2`, `gpbul`
- **Returns**: value of the last expression: `(list anga gpchord gpanga gprad gpdeg gprtlen)`
- **Side effects**: Globals set (not declared local): `gpang`, `gpchord`, `gpanga`, `gprad`, `gpdeg`, `gprtlen`
- **Referenced**: 4

## make_relr

`(make_relr redatalist trwidth1 trwidth2 trayfitent)`  - line 1240-1277

Point lists for tray elbow / tee / cross / reducer / left-right reducer outlines.

- **Arguments**: `redatalist`, `trwidth1`, `trwidth2`, `trayfitent`
- **Returns**: value of the last expression: `(MEDmaketray mlist T nil (MEDGetCurrentOCS))`
- **Side effects**: Globals set (not declared local): `fitdata`, `redata`, `dirfac`, `pts`, `pt1`, `pt2`, `linelen`, `redlen`, `entang`, `halfalt`, `halfsize2`, `sinofang`, `cosofang`, `ang`, `genang` ...; Xdata: reads xdata; DB: `med_getdesc`
- **Referenced**: 3

## c:test

`(c:test)`  - line 1279-1319

Developer test in medtray.lsp. Not a user command. User entry: [TEST](../command-reference.md#test).

- **Arguments**: none
- **Returns**: value of the last expression: `(if lwpent (progn (setq ptlist (bld_lw_ptlist lwpent) pt1 (cdr (nth 0 (nth 0 ptlist))) pt2 (cdr (nth 1 (nth 0 ...`
- **Side effects**: Globals set (not declared local): `lwpent`, `size`, `alt`, `ptlist`, `pt1`, `pt2`, `hyp`, `opp`, `adj`, `entang`, `sinang`, `cosang`, `oppfac`, `ang`, `genang` ...
- **Referenced**: 0

## c:esolid

`(c:esolid)`  - line 1322-1324

Erases ALL 3DSOLIDs in the drawing (loaded version). User entry: [ESOLID](../command-reference.md#esolid).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "erase" (ssget "X" '((0 . "3dsolid"))) "" )`
- **Side effects**: AutoCAD commands: `ERASE`
- **Referenced**: 0
- **Duplicate**: also defined in Support\MED3DCON.lsp:562; this definition loads last and wins

