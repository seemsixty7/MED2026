# MED3DCON.lsp

`Support\MED3DCON.lsp` - 2012 3D conduit code kept as M3DOLD / MAKE3DCONDUITOLD. Not loaded by MEDCore.

**Not loaded by MEDCore.** APPLOAD it to use it. 20 defun(s): 4 command(s), 16 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 5 | [`gplen`](#gplen) | function |
| 23 | [`mk3dcon`](#mk3dcon) | function |
| 43 | [`m3d-pt3`](#m3d-pt3) | function |
| 48 | [`m3d-unitvec`](#m3d-unitvec) | function |
| 59 | [`m3d-heavy-pline`](#m3d-heavy-pline) | function |
| 131 | [`m3d-begin`](#m3d-begin) | function |
| 135 | [`*error*`](#error) | function |
| 145 | [`m3d-end`](#m3d-end) | function |
| 154 | [`VerticalConduitDriver`](#verticalconduitdriver) | function |
| 222 | [`mk3dconvertical`](#mk3dconvertical) | function |
| 231 | [`mk3dvconbend`](#mk3dvconbend) | function |
| 249 | [`mk3dconbend`](#mk3dconbend) | function |
| 284 | [`cirmake`](#cirmake) | function |
| 306 | [`ThreeDeeConduitDriver`](#threedeeconduitdriver) | function |
| 399 | [`getangleradius`](#getangleradius) | function |
| 411 | [`c:mytest`](#cmytest) | command |
| 429 | [`c:M3DOLD`](#cm3dold) | command |
| 443 | [`c:Make3DConduitOld`](#cmake3dconduitold) | command |
| 515 | [`m3dconduitfit`](#m3dconduitfit) | function |
| 562 | [`c:esolid`](#cesolid) | command |

## gplen

`(gplen gpt1 gpt2 gpbul)`  - line 5-14

Arc length from two points and a bulge (MED3DCON).

- **Arguments**: `gpt1`, `gpt2`, `gpbul`
- **Returns**: value of the last expression: `gprtlen`
- **Side effects**: Globals set (not declared local): `gpang`, `gpchord`, `gpanga`, `gprad`, `gpdeg`, `gprtlen`
- **Referenced**: 1

## mk3dcon

`(mk3dcon mkpt1 mkpt2 csize / mkn mklast)`  - line 23-40

Straight conduit segment mkpt1 -> mkpt2 (WCS points, 2D or 3D), csize = RADIUS. entmake the circle with its normal (210) along the segment, then EXTRUDE along that direction. Works for sloped 3D segments too. (height as 2 points, then a taper-angle prompt eaten by the trailing ""). Since 2007 there is no taper ...

- **Arguments**: `mkpt1`, `mkpt2`, `csize`
- **Returns**: value of the last expression: `(if (and (numberp csize) (> csize 0.0) (setq mkn (m3d-unitvec mkpt1 mkpt2))) (progn (setq mklast (entlast)) (e...`
- **Side effects**: Entities: `entmake`; AutoCAD commands: `EXTRUDE`
- **Referenced**: 2

## m3d-pt3

`(m3d-pt3 p)`  - line 43-45

3D point (adds Z 0.0 to 2D points)

- **Arguments**: `p`
- **Returns**: value of the last expression: `(if (caddr p) p (list (car p) (cadr p) 0.0))`
- **Referenced**: 3

## m3d-unitvec

`(m3d-unitvec p1 p2 / d)`  - line 48-53

unit vector p1 -> p2, nil for zero length

- **Arguments**: `p1`, `p2`
- **Returns**: value of the last expression: `(if (> d 1e-8) (mapcar '(lambda (a b) (/ (- b a) d)) p1 p2) )`
- **Referenced**: 1

## m3d-heavy-pline

`(m3d-heavy-pline hpent hpdata hprad / hflg his3d helev hv hvd hpts hbuls hi hp1 hp2 hbul har hcpt hlast hms)`  - line 59-128

Solids for a heavy POLYLINE (2D or 3D) with MED_CONDUIT xdata. 2D: straights + bulge arcs (arcs assume OCS = WCS, same as the LWPOLYLINE branch). 3D: straights, plus a sphere at each interior vertex so sharp corners have no gap (real bends for 3D paths are the CABTest-based rewrite, not this patch).

- **Arguments**: `hpent`, `hpdata`, `hprad`
- **Returns**: value of the last expression: `(if (= 0 (logand hflg 80)) ; skip polygon meshes (16) and polyface meshes (64) (progn (setq his3d (= 8 (logand...`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 1

## m3d-begin

`(m3d-begin)`  - line 131-144

OSMODE / CMDECHO off for the whole run, restored on exit or error.

- **Arguments**: none
- **Returns**: value of the last expression: `(setvar "CMDECHO" 0)`
- **Side effects**: Globals set (not declared local): `m3dOldOsmode`, `m3dOldCmdecho`, `m3dOldError`
- **Referenced**: 2

## *error*

`(*error* msg)`  - line 135-141 (nested defun)

MED3DCON error handler.

- **Arguments**: `msg`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DFittings.lsp:963, Support\MED3DPath.lsp:1080, Support\MED3DTrayFunctions.lsp:468, Support\MEDFunctions.lsp:921, Support\MEDFunctions.lsp:2816; replaced at load time by Support\MED3DFittings.lsp:963

## m3d-end

`(m3d-end)`  - line 145-152

MED3DCON: restores sysvars / error handler.

- **Arguments**: none
- **Returns**: value of the last expression: `(setq *error* m3dOldError m3dOldOsmode nil m3dOldCmdecho nil m3dOldError nil)`
- **Side effects**: Globals set (not declared local): `*error*`, `m3dOldOsmode`, `m3dOldCmdecho`, `m3dOldError`
- **Referenced**: 3

## VerticalConduitDriver

`(VerticalConduitDriver)`  - line 154-219

MED3DCON: builds vertical conduit solids.

- **Arguments**: none
- **Returns**: value of the last expression: `(if verticalconduitss (progn (setq sslen (sslength verticalconduitss) cnt 0 ) (princ "\nEntering the While loo...`
- **Side effects**: Globals set (not declared local): `verticalconduitss`, `sslen`, `cnt`, `conent`, `conentdata`, `conrot`, `condata`, `consize`, `conod`, `condist`, `vertdata`, `bend1m`, `bden2m`, `condir`, `bend2dir` ...; Xdata: writes xdata, reads xdata, `MED_CONDUIT`, `VERT_DATA`; DB: `med_conduit_od`
- **Referenced**: 0

## mk3dconvertical

`(mk3dconvertical mkvpt1 mkvdist mkvcsize)`  - line 222-228

MED3DCON: vertical conduit / vertical bend / bend solids (EXTRUDE).

- **Arguments**: `mkvpt1`, `mkvdist`, `mkvcsize`
- **Returns**: value of the last expression: `(command "_.EXTRUDE" mycir "" mkvdist)`
- **Side effects**: Globals set (not declared local): `mycir`, `mycirdata`; AutoCAD commands: `EXTRUDE`
- **Referenced**: 1

## mk3dvconbend

`(mk3dvconbend mkcbpt1 mkcbdir csize mkcbrad ConTopFlag)`  - line 231-244

MED3DCON: vertical conduit / vertical bend / bend solids (EXTRUDE).

- **Arguments**: `mkcbpt1`, `mkcbdir`, `csize`, `mkcbrad`, `ConTopFlag`
- **Returns**: value of the last expression: `(command "revolve" mycir "" mkcbcpt mkcbcpt2 (angtos (* PI 0.5) 0 8))`
- **Side effects**: Globals set (not declared local): `mycir`, `mycirdata`, `mkcbcpt`, `mkcbcpt2`; AutoCAD commands: `REVOLVE`
- **Referenced**: 2

## mk3dconbend

`(mk3dconbend mkcbpt1 mkcbpt2 mkcbcpt csize mkcbiang)`  - line 249-278

MED3DCON: vertical conduit / vertical bend / bend solids (EXTRUDE).

- **Arguments**: `mkcbpt1`, `mkcbpt2`, `mkcbcpt`, `csize`, `mkcbiang`
- **Returns**: value of the last expression: `(if (< mkcbiang 0) (command "revolve" mycir "" cmkcbpt1 mkcbcpt (angtos (abs mkcbiang) 0 8)) (command "revolve...`
- **Side effects**: Globals set (not declared local): `actgenang`, `mycir`, `mycirdata`, `3dold`, `3dnew`, `mycirpt`, `frompoint`, `movetopoint`, `mkcbzpoint`, `cmkcbpt1`, `bendang`; Entities: `entmod`; AutoCAD commands: `MOVE`, `REVOLVE`, `ROTATE`
- **Referenced**: 2

## cirmake

`(cirmake centerpoint radius)`  - line 284-297

Entmakes a circle.

- **Arguments**: `centerpoint`, `radius`
- **Returns**: value of the last expression: `(entmake ckent)`
- **Side effects**: Globals set (not declared local): `ckent`, `twoten`, `plin`, `_ZFLAG`; Entities: `entmake`
- **Referenced**: 4

## ThreeDeeConduitDriver

`(ThreeDeeConduitDriver plent)`  - line 306-398

((-1 . <Entity name: 7ef9b450>) (0 . "CIRCLE") (330 . <Entity name: 7ef7bcf8>) (5 . "132") (100 . "AcDbEntity") (67 . 0) (410 . "Model") (8 . "0") (100 . "AcDbCircle") (10 17.0084 -10.1694 0.0) (40 . 1.36514) (210 0.0 -1.0 2.22045e-016))

- **Arguments**: `plent`
- **Returns**: value of the last expression: `plen`
- **Side effects**: Globals set (not declared local): `plen`, `pentdata`, `curcondata`, `consize`, `actualsize`, `mode`, `mode1`, `spt`, `ept`, `mklwptbulist`, `mkcnt`, `mklwptlist`, `mklwbulist`, `mklwzpoint`, `angleandradiuslist` ...; Xdata: writes xdata, reads xdata; DB: `med_conduit_od`
- **Referenced**: 2

## getangleradius

`(getangleradius gpt1 gpt2 gpbul)`  - line 399-409

Arc data (angle, radius, chord) from two points and a bulge.

- **Arguments**: `gpt1`, `gpt2`, `gpbul`
- **Returns**: value of the last expression: `(list gpdeg gprad gpanga gpang gprtlen gpchord)`
- **Side effects**: Globals set (not declared local): `gpang`, `gpchord`, `gpanga`, `gprad`, `gpdeg`, `gprtlen`, `chordang`
- **Referenced**: 3

## c:mytest

`(c:mytest)`  - line 411-427

Developer test: picks a polyline arc (MED3DCON.lsp, not loaded). User entry: [MYTEST](../command-reference.md#mytest).

- **Arguments**: none
- **Returns**: value of the last expression: `(cirmake (polar pt1 angtocenter rad) 0.5)`
- **Side effects**: Globals set (not declared local): `pent`, `ptlist`, `pt1`, `pt2`, `bul1`, `mydata`, `anga`, `rad`, `chordang`, `angtocenter`
- **Referenced**: 0

## c:M3DOLD

`(c:M3DOLD / ent)`  - line 429-441

2012 single-run conduit to 3D (MED3DCON.lsp, not loaded). User entry: [M3DOLD](../command-reference.md#m3dold).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_MEDCONDUITOD_CACHE`; Xdata: reads xdata
- **Referenced**: 0

## c:Make3DConduitOld

`(c:Make3DConduitOld)`  - line 443-512

2012 all-conduit to 3D/3DS export (MED3DCON.lsp, not loaded). User entry: [MAKE3DCONDUITOLD](../command-reference.md#make3dconduitold).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_MEDCONDUITOD_CACHE`, `outputformat`, `3doutconduit`, `conduitoutnum`, `conduitoutcnt`, `conduitent`, `3dsoutfname`; Xdata: reads/writes xdata directly (-3 group / regapp), `MED_CONDUIT`, `MED_FITTING`; Layers: `_MED3DCONDUIT` (LAYER command / CLAYER); AutoCAD commands: `-LAYER`, `ERASE`, `PLAN`, `VPOINT`, `WBLOCK`
- **Referenced**: 0

## m3dconduitfit

`(m3dconduitfit conduitfitent conduitfitdata)`  - line 515-561

MED3DCON: 3D conduit fitting.

- **Arguments**: `conduitfitent`, `conduitfitdata`
- **Returns**: value of the last expression: `(setvar "ELEVATION" m3delev)`
- **Side effects**: Globals set (not declared local): `fitptbllist`, `fitptlist`, `fitbllist`, `fitwidth`, `fitdpth`, `fitalt`, `m3delev`, `conduitfitentdata`; Xdata: writes xdata; AutoCAD commands: `EXTRUDE`
- **Referenced**: 2

## c:esolid

`(c:esolid)`  - line 562-564

Erases all 3D solids (copy in unloaded MED3DCON.lsp). User entry: [ESOLID](../command-reference.md#esolid).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "erase" (SSGET "X" '((0 . "3DSOLID"))) "")`
- **Side effects**: AutoCAD commands: `ERASE`
- **Referenced**: 0
- **Duplicate**: also defined in Support\medtray.lsp:1322; replaced at load time by Support\medtray.lsp:1322

