# QKEY.lsp

`Support\QKEY.lsp` - User quick keys (zoom/erase/copy macros) plus many legacy commands (CTAG, TTAG, MEDFIND, MEDCOPY, tray hardware, instrument tags).

Loaded by MEDCore (order 2). 92 defun(s): 75 command(s), 17 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 25 | [`c:zw`](#czw) | command |
| 27 | [`c:zd`](#czd) | command |
| 29 | [`c:zp`](#czp) | command |
| 31 | [`c:zv`](#czv) | command |
| 33 | [`c:ze`](#cze) | command |
| 35 | [`c:va`](#cva) | command |
| 37 | [`c:vr`](#cvr) | command |
| 39 | [`c:ew`](#cew) | command |
| 41 | [`c:ec`](#cec) | command |
| 43 | [`c:cw`](#ccw) | command |
| 45 | [`c:cc`](#ccc) | command |
| 47 | [`c:mw`](#cmw) | command |
| 49 | [`c:mc`](#cmc) | command |
| 51 | [`c:rw`](#crw) | command |
| 53 | [`c:rc`](#crc) | command |
| 55 | [`c:st`](#cst) | command |
| 57 | [`c:bf`](#cbf) | command |
| 65 | [`c:dd`](#cdd) | command |
| 75 | [`c:mcon`](#cmcon) | command |
| 91 | [`c:medcopy`](#cmedcopy) | command |
| 144 | [`c:mtray`](#cmtray) | command |
| 160 | [`c:mcable`](#cmcable) | command |
| 176 | [`c:mequip`](#cmequip) | command |
| 183 | [`c:mfit`](#cmfit) | command |
| 191 | [`c:qc`](#cqc) | command |
| 204 | [`c:ctag`](#cctag) | command |
| 253 | [`c:traycon`](#ctraycon) | command |
| 286 | [`c:trayep`](#ctrayep) | command |
| 290 | [`c:trayeg`](#ctrayeg) | command |
| 295 | [`c:trayhd`](#ctrayhd) | command |
| 300 | [`trayepg_hd`](#trayepg_hd) | function |
| 404 | [`getinst`](#getinst) | function |
| 416 | [`geninst`](#geninst) | function |
| 451 | [`getlit`](#getlit) | function |
| 470 | [`c:attlay`](#cattlay) | command |
| 503 | [`c:wbl`](#cwbl) | command |
| 518 | [`c:attrot`](#cattrot) | command |
| 568 | [`grndins`](#grndins) | function |
| 616 | [`grtag`](#grtag) | function |
| 658 | [`grnd_ins`](#grnd_ins) | function |
| 706 | [`c:mc`](#cmc) | command |
| 712 | [`c:addre`](#caddre) | command |
| 757 | [`c:cf`](#ccf) | command |
| 763 | [`c:cn`](#ccn) | command |
| 767 | [`motor`](#motor) | function |
| 824 | [`c:wires`](#cwires) | command |
| 914 | [`c:refdwg`](#crefdwg) | command |
| 1001 | [`getdwgnm`](#getdwgnm) | function |
| 1024 | [`c:planmotor`](#cplanmotor) | command |
| 1038 | [`cntrlsta`](#cntrlsta) | function |
| 1055 | [`c:trayhang`](#ctrayhang) | command |
| 1062 | [`c:traydrop`](#ctraydrop) | command |
| 1066 | [`c:trayblind`](#ctrayblind) | command |
| 1069 | [`trayfit`](#trayfit) | function |
| 1118 | [`c:strut1`](#cstrut1) | command |
| 1145 | [`c:takeoff`](#ctakeoff) | command |
| 1151 | [`detailtag`](#detailtag) | function |
| 1242 | [`c:detag`](#cdetag) | command |
| 1246 | [`c:detag2`](#cdetag2) | command |
| 1251 | [`c:atlsc`](#catlsc) | command |
| 1254 | [`c:atrsc`](#catrsc) | command |
| 1258 | [`atsched`](#atsched) | function |
| 1280 | [`sel_att_ent`](#sel_att_ent) | function |
| 1314 | [`c:trayhinge`](#ctrayhinge) | command |
| 1319 | [`c:pb`](#cpb) | command |
| 1331 | [`c:loopit`](#cloopit) | command |
| 1345 | [`c:sort`](#csort) | command |
| 1418 | [`c:qe`](#cqe) | command |
| 1425 | [`qt`](#qt) | function |
| 1447 | [`itag`](#itag) | function |
| 1467 | [`c:qte`](#cqte) | command |
| 1470 | [`c:qta`](#cqta) | command |
| 1473 | [`c:qtr`](#cqtr) | command |
| 1476 | [`c:itage`](#citage) | command |
| 1479 | [`c:itaga`](#citaga) | command |
| 1482 | [`c:itagT`](#citagt) | command |
| 1486 | [`c:qtT`](#cqtt) | command |
| 1489 | [`c:par`](#cpar) | command |
| 1510 | [`c:app`](#capp) | command |
| 1533 | [`c:MEDfind`](#cmedfind) | command |
| 1565 | [`c:ttag`](#cttag) | command |
| 1673 | [`c:it`](#cit) | command |
| 1691 | [`c:f0`](#cf0) | command |
| 1702 | [`c:off2con`](#coff2con) | command |
| 1747 | [`c:bc`](#cbc) | command |
| 1750 | [`c:atc`](#catc) | command |
| 1754 | [`c:hand`](#chand) | command |
| 1762 | [`getschedule`](#getschedule) | function |
| 1779 | [`c:blk2byl`](#cblk2byl) | command |
| 1784 | [`c:T1Thin`](#ct1thin) | command |
| 1789 | [`c:ttags`](#cttags) | command |
| 1833 | [`c:telev`](#ctelev) | command |

## c:zw

`(c:zw)`  - line 25-26

Zoom window / dynamic / previous / vmax / extents. User entry: [ZW](../command-reference.md#zw).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "zoom" "w")`
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 0

## c:zd

`(c:zd)`  - line 27-28

Zoom window / dynamic / previous / vmax / extents. User entry: [ZD](../command-reference.md#zd).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "zoom" "d")`
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 0

## c:zp

`(c:zp)`  - line 29-30

Zoom window / dynamic / previous / vmax / extents. User entry: [ZP](../command-reference.md#zp).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 0

## c:zv

`(c:zv)`  - line 31-32

Zoom window / dynamic / previous / vmax / extents. User entry: [ZV](../command-reference.md#zv).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 0

## c:ze

`(c:ze)`  - line 33-34

Zoom window / dynamic / previous / vmax / extents. User entry: [ZE](../command-reference.md#ze).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 0

## c:va

`(c:va)`  - line 35-36

Restore view ALL / named view. User entry: [VA](../command-reference.md#va).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:vr

`(c:vr)`  - line 37-38

Restore view ALL / named view. User entry: [VR](../command-reference.md#vr).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "'view" "r")`
- **Referenced**: 0

## c:ew

`(c:ew)`  - line 39-40

Erase / copy / move / rotate with window or crossing preselected. User entry: [EW](../command-reference.md#ew).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "erase" "w")`
- **Side effects**: AutoCAD commands: `ERASE`
- **Referenced**: 0

## c:ec

`(c:ec)`  - line 41-42

Erase / copy / move / rotate with window or crossing preselected. User entry: [EC](../command-reference.md#ec).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "erase" "c")`
- **Side effects**: AutoCAD commands: `ERASE`
- **Referenced**: 0

## c:cw

`(c:cw)`  - line 43-44

Erase / copy / move / rotate with window or crossing preselected. User entry: [CW](../command-reference.md#cw).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "copy" "w")`
- **Side effects**: AutoCAD commands: `COPY`
- **Referenced**: 0

## c:cc

`(c:cc)`  - line 45-46

Erase / copy / move / rotate with window or crossing preselected. User entry: [CC](../command-reference.md#cc).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "copy" "c")`
- **Side effects**: AutoCAD commands: `COPY`
- **Referenced**: 0

## c:mw

`(c:mw)`  - line 47-48

Erase / copy / move / rotate with window or crossing preselected. User entry: [MW](../command-reference.md#mw).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "move" "w")`
- **Side effects**: AutoCAD commands: `MOVE`
- **Referenced**: 0

## c:mc

`(c:mc)`  - line 49-50

Move with crossing window. Overridden by the later MC defun (line 706) - never reachable. User entry: [MC](../command-reference.md#mc).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "move" "c")`
- **Side effects**: AutoCAD commands: `MOVE`
- **Referenced**: 0
- **Duplicate**: also defined in Support\QKEY.lsp:706; replaced at load time by Support\QKEY.lsp:706

## c:rw

`(c:rw)`  - line 51-52

Erase / copy / move / rotate with window or crossing preselected. User entry: [RW](../command-reference.md#rw).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "rotate" "w")`
- **Side effects**: AutoCAD commands: `ROTATE`
- **Referenced**: 0

## c:rc

`(c:rc)`  - line 53-54

Erase / copy / move / rotate with window or crossing preselected. User entry: [RC](../command-reference.md#rc).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "rotate" "c")`
- **Side effects**: AutoCAD commands: `ROTATE`
- **Referenced**: 0

## c:st

`(c:st)`  - line 55-56

STRETCH with crossing already chosen. User entry: [ST](../command-reference.md#st).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "stretch" "crossing")`
- **Side effects**: AutoCAD commands: `STRETCH`
- **Referenced**: 0

## c:bf

`(c:bf)`  - line 57-64

BREAK at two points. User entry: [BF](../command-reference.md#bf).

- **Arguments**: none
- **Returns**: value of the last expression: `(command pause)`
- **Side effects**: AutoCAD commands: `BREAK`, `FIRST`
- **Referenced**: 0

## c:dd

`(c:dd / ent)`  - line 65-74

DDEDIT for TEXT/ATTDEF/MTEXT, DDATTE for INSERT. User entry: [DD](../command-reference.md#dd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `DDATTE`, `DDEDIT`
- **Referenced**: 0

## c:mcon

`(c:mcon / ment mdata xdlist)`  - line 75-90

Adds a MED_CONDUIT record (current _CODE/_CSIZE, tag NONE) to a picked polyline. User entry: [MCON](../command-reference.md#mcon).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (or (= (dxf 0 mdata) "POLYLINE") (= (dxf 0 mdata) "LWPOLYLINE") ) (progn (setq xdlist (bld_conduit _CODE _...`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 0

## c:medcopy

`(c:medcopy)`  - line 91-143

Copies the MED xdata of one entity onto other selected entities. User entry: [MEDCOPY](../command-reference.md#medcopy).

- **Arguments**: none
- **Returns**: value of the last expression: `(if copyss (progn (setq num (sslength copyss)) (while (< cnt num) (setq ment (ssname copyss cnt) mdata (entget...`
- **Side effects**: Globals set (not declared local): `ment`, `mdata`, `xdlist`, `cnt`, `copyss`, `num`, `itmtype`, `xditmnew`, `typlist`, `typlistcnt`, `firstpart`, `field`, `itmdata`, `xditm`; Xdata: writes xdata
- **Referenced**: 0

## c:mtray

`(c:mtray / ment mdata xdlist)`  - line 144-159

Adds a MED_TRAY record (current tray code/size/depth, tag NONE) to a picked polyline. User entry: [MTRAY](../command-reference.md#mtray).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (or (= (dxf 0 mdata) "POLYLINE") (= (dxf 0 mdata) "LWPOLYLINE") ) (progn (setq xdlist (bld_tray _TRCODE _T...`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 0

## c:mcable

`(c:mcable / ment mdata xdlist)`  - line 160-175

Adds a MED_CABLE record (current _CABCODE, tag NONE) to a picked polyline. User entry: [MCABLE](../command-reference.md#mcable).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (or (= (dxf 0 mdata) "POLYLINE") (= (dxf 0 mdata) "LWPOLYLINE") ) (progn (setq xdlist (bld_cable _CABCODE ...`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 0

## c:mequip

`(c:mequip / ment mdata xdlist)`  - line 176-182

Adds a MED_EQUIP record (current _EQCODE) to a picked entity. User entry: [MEQUIP](../command-reference.md#mequip).

- **Arguments**: none
- **Returns**: value of the last expression: `(xdatadd ment xdlist)`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 0

## c:mfit

`(c:mfit / ment mdata xdlist)`  - line 183-189

Adds a MED_FITTING record (current _FITTCODE and _CSIZE) to a picked entity. User entry: [MFIT](../command-reference.md#mfit).

- **Arguments**: none
- **Returns**: value of the last expression: `(xdatadd ment xdlist)`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 0

## c:qc

`(c:qc / pt rad)`  - line 191-197

Circles of several radii from one center. User entry: [QC](../command-reference.md#qc).

- **Arguments**: none
- **Returns**: value of the last expression: `(while (setq rad (getdist pt "\nRadius of circle: ")) (command "circle" pt rad) )`
- **Side effects**: AutoCAD commands: `CIRCLE`
- **Referenced**: 0

## c:ctag

`(c:ctag / ctlt ctlay cctid ccten cctszl ctpt1 ctpt2 ctpt3 ctan ctlen ctinfo)`  - line 204-252

Conduit tag (block contag) from xdata size/tag. User entry: [CTAG](../command-reference.md#ctag).

- **Arguments**: none
- **Returns**: value of the last expression: `(ltback ctlt)`
- **Side effects**: Globals set (not declared local): `curattdia`, `cten`, `ctendata`, `ctszl`, `ctid`; Xdata: reads xdata; Layers: `_ECTAG` (LAYER command / CLAYER); AutoCAD commands: `INSERT`, `LAYER`, `LINE`
- **Referenced**: 2

## c:traycon

`(c:traycon)`  - line 253-285

Tray-to-conduit connector (side or end entry) by conduit size. User entry: [TRAYCON](../command-reference.md#traycon).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `etype`, `_EQCODE`, `conlist`, `con`, `data`, `consz`, `contg`, `endlist`, `addmt`, `lalet`, `ent`, `xdlist`; Xdata: writes xdata, reads xdata; Layers: creates/sets layers
- **Referenced**: 0

## c:trayep

`(c:trayep)`  - line 286-289

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge. User entry: [TRAYEP](../command-reference.md#trayep).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:trayeg

`(c:trayeg)`  - line 290-294

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge. User entry: [TRAYEG](../command-reference.md#trayeg).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:trayhd

`(c:trayhd / instr opeqlst eqdef)`  - line 295-298

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge. User entry: [TRAYHD](../command-reference.md#trayhd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## trayepg_hd

`(trayepg_hd blname1 blname2 mainlay angpt mwidth hd_list)`  - line 300-403

Inserts tray hardware blocks (expansion plate/guide, hold-down, hanger) with xdata.

- **Arguments**: `blname1`, `blname2`, `mainlay`, `angpt`, `mwidth`, `hd_list`
- **Returns**: value of the last expression: `(xdatadd ent xdlist)`
- **Side effects**: Globals set (not declared local): `atmd`, `info`, `cnt`, `num`, `opeqlst`, `instr`, `desc`, `eqdef`, `eqsel`, `TAT_VAL`, `_EQCODE`, `eppt`, `epss`, `ent`, `size` ...; Xdata: writes xdata, reads xdata; Layers: `_ZEROLAY`, `mainlay`; DB: `med_detail`, `medremapeqcodetoprojectcode`; AutoCAD commands: `PLINE`
- **Prompts**: `Select Point for insertion:`; `Rotation:`
- **Referenced**: 5

## getinst

`(getinst addone ecode)`  - line 404-415

Asks detail A/B for an instrument insert.

- **Arguments**: `addone`, `ecode`
- **Returns**: value of the last expression: `(if addone (progn (setq addlet (getstring "\nDetail <A> or B:")) (if (or (not addlet) (= addlet "")) (setq _EQ...`
- **Side effects**: Globals set (not declared local): `_EQCODE`, `addlet`
- **Prompts**: `Detail <A> or B:`
- **Referenced**: 0

## geninst

`(geninst inprt1 inprt2 inprt3)`  - line 416-450

Inserts additional instruments.

- **Arguments**: `inprt1`, `inprt2`, `inprt3`
- **Returns**: value of the last expression: `(if ang (progn (cond ((= ang 0.0) (setq cnt 0) ) ((= ang (* PI 0.5)) (setq cnt 1) ) ((= ang PI) (setq cnt 2) )...`
- **Side effects**: Globals set (not declared local): `stpt`, `ang`, `data1`, `data2`, `data3`, `cnt`, `dist1`, `dist2`, `inspt1`, `inspt2`
- **Prompts**: `Select loaction of additonal inst:`
- **Referenced**: 0

## getlit

`(getlit letlist ecode)`  - line 451-469

Returns the key letter for a detail.

- **Arguments**: `letlist`, `ecode`
- **Returns**: value of the last expression: `(if letlist (progn (setq klet "") (foreach let letlist (setq klet (strcat klet " " let )) ) (initget 1 klet) (...`
- **Side effects**: Globals set (not declared local): `_EQCODE`, `klet`, `let`, `len`, `sublst`, `sublen`, `letnum`
- **Referenced**: 0

## c:attlay

`(c:attlay)`  - line 470-502

Moves the attributes of selected blocks to the MED text layer. User entry: [ATTLAY](../command-reference.md#attlay).

- **Arguments**: none
- **Returns**: value of the last expression: `(if attss (progn (setq sslen (sslength attss) cnt 0 ) (while (< cnt sslen) (setq attent (ssname attss cnt) mat...`
- **Side effects**: Globals set (not declared local): `txtlay`, `attss`, `sslen`, `cnt`, `attent`, `mattent`, `attdata`, `old`, `new`; Entities: `entmod`
- **Referenced**: 0

## c:wbl

`(c:wbl)`  - line 503-517

Defines a block from a selection (BLOCK with redefine). User entry: [WBL](../command-reference.md#wbl).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (findfile (strcat fullfile ".dwg")) (command "wblock" fullfile "y" blname) (command "wblock" fullfile blna...`
- **Side effects**: Globals set (not declared local): `blname`, `inspt`, `ss`, `fullfile`; AutoCAD commands: `BLOCK`, `WBLOCK`
- **Referenced**: 0

## c:attrot

`(c:attrot)`  - line 518-566

Rotates the attributes of selected blocks to 0 degrees. User entry: [ATTROT](../command-reference.md#attrot).

- **Arguments**: none
- **Returns**: value of the last expression: `(if attss (progn (setq sslen (sslength attss) cnt 0 ) (while (< cnt sslen) (setq attent (ssname attss cnt) mat...`
- **Side effects**: Globals set (not declared local): `attss`, `sslen`, `cnt`, `attent`, `mattent`, `attdata`, `blinpt`, `blinptx`, `blinpty`, `blinptz`, `attins`, `attinsx`, `attinsy`, `attrot`, `attdist` ...; Entities: `entmod`
- **Referenced**: 0

## grndins

`(grndins det1num det1klet det2num det2klet)`  - line 568-615

Inserts a grounding detail pair.

- **Arguments**: `det1num`, `det1klet`, `det2num`, `det2klet`
- **Returns**: value of the last expression: `(if det2num (progn (if det2klet (progn (setq klet "") (foreach let det2klet (setq klet (strcat klet " " let ))...`
- **Side effects**: Globals set (not declared local): `grndent`, `klet`, `let`, `len`, `sublst`, `sublen`, `letnum`, `xdlist`; Xdata: writes xdata; Layers: `_MEDGRND`
- **Referenced**: 0

## grtag

`(grtag cabtag / lay txt)`  - line 616-656

Ground tag with leader.

- **Arguments**: `cabtag`
- **Returns**: value of the last expression: `(command "layer" "s" lay "")`
- **Side effects**: Globals set (not declared local): `genang`, `lentmrk`, `pt`, `pt1`, `entblk`, `entdata`, `oldy`, `newy`; Layers: `_MEDTEXT` (LAYER command / CLAYER); Entities: `entmod`; AutoCAD commands: `DIM`, `DIMBLK`, `INSERT`, `LAYER`, `STYLE`
- **Prompts**: `Leader start:`; `to:`
- **Referenced**: 0

## grnd_ins

`(grnd_ins det1num det1klet det2num det2klet blname)`  - line 658-705

Inserts a grounding detail pair.

- **Arguments**: `det1num`, `det1klet`, `det2num`, `det2klet`, `blname`
- **Returns**: value of the last expression: `(if det2num (progn (if det2klet (progn (setq klet "") (foreach let det2klet (setq klet (strcat klet " " let ))...`
- **Side effects**: Globals set (not declared local): `grndent`, `klet`, `let`, `len`, `sublst`, `sublen`, `letnum`, `xdlist`; Xdata: writes xdata; Layers: `_MEDGRND`
- **Referenced**: 0

## c:mc

`(c:mc)`  - line 706-709

Alias: runs the .NET MEDCHG properties palette (replaces the earlier move-crossing MC). User entry: [MC](../command-reference.md#mc).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0
- **Duplicate**: also defined in Support\QKEY.lsp:49; this definition loads last and wins

## c:addre

`(c:addre)`  - line 712-756

Adds a given number of reducing fittings (RE) to an entity's MED_FITTING xdata. User entry: [ADDRE](../command-reference.md#addre).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `addent`, `sizedata`, `tagdata`, `addata`, `xadata`, `rsizelist`, `redlst`, `recode`, `resize`, `retag`, `realt`, `redpth`, `re_ssize`, `re_qty`, `xbdata` ...; Xdata: writes xdata, reads xdata
- **Referenced**: 0

## c:cf

`(c:cf)`  - line 757-762

Centerline layer off / on. User entry: [CF](../command-reference.md#cf).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "layer" "off" (nth 0 _MEDCENLAY) "")`
- **Side effects**: Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `LAYER`
- **Referenced**: 0

## c:cn

`(c:cn)`  - line 763-765

Centerline layer off / on. User entry: [CN](../command-reference.md#cn).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "layer" "on" (nth 0 _MEDCENLAY) "")`
- **Side effects**: Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `LAYER`
- **Referenced**: 0

## motor

`(motor msize vert)`  - line 767-822

Draws a parametric motor from MOTOR.DAT (size, vertical flag).

- **Arguments**: `msize`, `vert`
- **Returns**: value of the last expression: `(pmake (list bxpt1 bxpt2 bxpt3 bxpt4) T)`
- **Side effects**: Globals set (not declared local): `mtrfname`, `mtrfn`, `mtrdata`, `mtrsz`, `mtr_data`, `mtra`, `mtrb`, `mtrc`, `mtrd`, `mtpt`, `bxstpt`, `mtang`, `mperc`, `mtrst`, `mtpt1` ...; AutoCAD commands: `CIRCLE`, `ELLIPSE`, `MIRROR`, `TRIM`
- **Prompts**: `Start Point:`; `Angle of Genration:`; `Select Direction of Motor Box:`
- **Referenced**: 10

## c:wires

`(c:wires)`  - line 824-912

Wire markers (hot/neutral/ground dashes) on conduit. User entry: [WIRES](../command-reference.md#wires).

- **Arguments**: none
- **Returns**: value of the last expression: `(entmake)`
- **Side effects**: Globals set (not declared local): `stylnm`, `oldvallist`, `stpt`, `rot`, `genang`, `wirestr`, `stang`, `endang`, `wlen`, `nlen`, `glen`, `slen`, `sleg`, `spcr`, `cnt` ...; Layers: `_MEDTEXT`; Entities: `entmake`
- **Referenced**: 0

## c:refdwg

`(c:refdwg)`  - line 914-1000

Reference drawing list next to the title block (from the drawing list). User entry: [REFDWG](../command-reference.md#refdwg).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `dwglist`, `currlist`, `lay`, `intpt`, `ans`, `txtss`, `num`, `cnt`, `ent`, `entdata`, `ipt`, `itm`, `ipt2`, `ipt3`, `dat1` ...; Layers: `_MEDTEXT` (LAYER command / CLAYER); Entities: `entdel`; AutoCAD commands: `TEXT`
- **Referenced**: 1

## getdwgnm

`(getdwgnm dwgnum)`  - line 1001-1022

Reads a drawing name/description from the drawing list file.

- **Arguments**: `dwgnum`
- **Returns**: value of the last expression: `dwgdesc`
- **Side effects**: Globals set (not declared local): `fn`, `dline`, `dlcd`, `dwgdesc`
- **Referenced**: 2

## c:planmotor

`(c:planmotor)`  - line 1024-1037

Plan motor symbol sized from MOTOR.DAT (horizontal/vertical). User entry: [PLANMOTOR](../command-reference.md#planmotor).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ans`, `vmotor`
- **Referenced**: 0

## cntrlsta

`(cntrlsta blname fcode)`  - line 1038-1054

Inserts a control station block with size data.

- **Arguments**: `blname`, `fcode`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `oldacs`, `oldlet`, `oldsz`, `_ACSIZE`, `_CLETT`, `1.0`, `_CSIZE`, `ADDTOENT`
- **Referenced**: 0

## c:trayhang

`(c:trayhang / instr opeqlst eqdef)`  - line 1055-1060

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge. User entry: [TRAYHANG](../command-reference.md#trayhang).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `cltp`; AutoCAD commands: `CHANGE`
- **Referenced**: 1

## c:traydrop

`(c:traydrop)`  - line 1062-1064

Adds a drop-out / blind-end fitting record to a picked tray. User entry: [TRAYDROP](../command-reference.md#traydrop).

- **Arguments**: none
- **Returns**: value of the last expression: `(trayfit (nth 0 _TRAYDROP) "Drop")`
- **Referenced**: 0

## c:trayblind

`(c:trayblind)`  - line 1066-1068

Adds a drop-out / blind-end fitting record to a picked tray. User entry: [TRAYBLIND](../command-reference.md#trayblind).

- **Arguments**: none
- **Returns**: value of the last expression: `(trayfit (nth 0 _TRAYBLIND) "Blind")`
- **Referenced**: 0

## trayfit

`(trayfit tryfitcode tryprompt)`  - line 1069-1117

Adds a tray fitting record (drop / blind) to a picked tray.

- **Arguments**: `tryfitcode`, `tryprompt`
- **Returns**: value of the last expression: `(if trybas (progn (setq trybas (car trybas) trydat (xdataget trybas _TRAY) ) (if trydat (progn (setq trysiz (n...`
- **Side effects**: Globals set (not declared local): `trybas`, `trydat`, `trysiz`, `trydpt`, `xdlist`, `drpent`, `drpdat`, `c-code`, `c-size`, `c-tag`, `c-alt`, `c-dpt`, `xdclist`; Xdata: writes xdata, reads xdata
- **Prompts**: `Xdata has been added!`; `Xdata Add has Failed!!!`
- **Referenced**: 2

## c:strut1

`(c:strut1 / cltp clay trpt1 trpt2 trtag xdlist)`  - line 1118-1144

Strut on the centerline layer with MED xdata (QKEY variant). User entry: [STRUT1](../command-reference.md#strut1).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `CR_LAYER`; Xdata: writes xdata; Layers: `_MEDCENLAY` (LAYER command / CLAYER)
- **Referenced**: 1

## c:takeoff

`(c:takeoff)`  - line 1145-1149

Turns HANDLES on and runs BOM (legacy take-off wrapper). User entry: [TAKEOFF](../command-reference.md#takeoff).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:BOM)`
- **Side effects**: AutoCAD commands: `ATTEXT`, `HANDLES`
- **Referenced**: 0

## detailtag

`(detailtag DetailBlockName Distance0 Distance180)`  - line 1151-1241

Detail bubble insert worker for DETAG / DETAG2.

- **Arguments**: `DetailBlockName`, `Distance0`, `Distance180`
- **Returns**: value of the last expression: `(setvar "OSMODE" currosmode)`
- **Side effects**: Globals set (not declared local): `currosmode`, `dt`, `ne`, `attdi`, `p1`, `p2`, `a`, `LeaderAngle`, `p3`, `p4`, `dent`, `dentss`, `sslen`, `cnt`, `data` ...; Xdata: reads xdata; Layers: `_MEDTEXT`; DB: `med_detail`; AutoCAD commands: `INSERT`
- **Prompts**: `From point:`; `To point:`; `Select Entity with Detail info:`; `Detail Number:`
- **Referenced**: 2

## c:detag

`(c:detag)`  - line 1242-1244

Detail bubble detbub2 from catalog keys. User entry: [DETAG](../command-reference.md#detag).

- **Arguments**: none
- **Returns**: value of the last expression: `(detailtag "detbub2" 0.0 0.0)`
- **Referenced**: 1

## c:detag2

`(c:detag2)`  - line 1246-1248

Alternate detail bubble dtlhd1. User entry: [DETAG2](../command-reference.md#detag2).

- **Arguments**: none
- **Returns**: value of the last expression: `(detailtag "dtlhd1" 0.0 -1.25)`
- **Referenced**: 0

## c:atlsc

`(c:atlsc)`  - line 1251-1253

Adds schedule data (material 67 / 68) to a picked entity's xdata (legacy lighting/receptacle schedule). User entry: [ATLSC](../command-reference.md#atlsc).

- **Arguments**: none
- **Returns**: value of the last expression: `(atsched 67)`
- **Referenced**: 0

## c:atrsc

`(c:atrsc)`  - line 1254-1256

Adds schedule data (material 67 / 68) to a picked entity's xdata (legacy lighting/receptacle schedule). User entry: [ATRSC](../command-reference.md#atrsc).

- **Arguments**: none
- **Returns**: value of the last expression: `(atsched 68)`
- **Referenced**: 0

## atsched

`(atsched mat_id / ment mdata xdlist schedlet)`  - line 1258-1278

Adds schedule data to an entity (ATLSC / ATRSC).

- **Arguments**: `mat_id`
- **Returns**: value of the last expression: `(xdatadd ment xdlist)`
- **Side effects**: Globals set (not declared local): `addata`, `xadata`, `oldsched`; Xdata: writes xdata
- **Prompts**: `Select Entity to add Schedule data:`
- **Referenced**: 2

## sel_att_ent

`(sel_att_ent hd_ent at_tag new_val / sent sdata oldval newval)`  - line 1280-1312

Sets an attribute value on an insert; nil if not found.

- **Arguments**: `hd_ent`, `at_tag`, `new_val`
- **Returns**: value of the last expression: `sent`
- **Side effects**: Globals set (not declared local): `smdata`; Entities: `entmod`
- **Referenced**: 10

## c:trayhinge

`(c:trayhinge / instr opeqlst eqdef)`  - line 1314-1317

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge. User entry: [TRAYHINGE](../command-reference.md#trayhinge).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:pb

`(c:pb / bpt bent)`  - line 1319-1329

Break an entity at one point. User entry: [PB](../command-reference.md#pb).

- **Arguments**: none
- **Returns**: value of the last expression: `(if bpt (progn (command "break" (list bent bpt) "f" bpt bpt) ) )`
- **Side effects**: AutoCAD commands: `BREAK`
- **Referenced**: 0

## c:loopit

`(c:loopit)`  - line 1331-1343

Loop leader: draws a loop mark between two points on the text layer. User entry: [LOOPIT](../command-reference.md#loopit).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "line" (be pt2 pt3))`
- **Side effects**: Globals set (not declared local): `pt1`, `pt2`, `ang`, `pt3`, `pt4`; Layers: `_MEDTEXT`; AutoCAD commands: `FILLET`, `LINE`
- **Referenced**: 0

## c:sort

`(c:sort)`  - line 1345-1417

Sorts and rewrites the existing reference drawing list text. User entry: [SORT](../command-reference.md#sort).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `dwglist`, `currlist`, `lay`, `intpt`, `txtss`, `num`, `cnt`, `ent`, `entdata`, `ipt`, `itm`, `ipt2`, `dat1`, `datlen`, `dwgdesc` ...; Layers: `_MEDTEXT` (LAYER command / CLAYER); Entities: `entdel`; AutoCAD commands: `TEXT`
- **Referenced**: 0

## c:qe

`(c:qe)`  - line 1418-1424

Erases a fixed-size crossing window from a picked point (legacy sheet helper). User entry: [QE](../command-reference.md#qe).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "erase" "c" stpt npt)`
- **Side effects**: Globals set (not declared local): `stpt`, `npt`; AutoCAD commands: `ERASE`
- **Referenced**: 0

## qt

`(qt prefix)`  - line 1425-1446

Quick cable-tag text with a prefix.

- **Arguments**: `prefix`
- **Returns**: value of the last expression: `(if txtss (progn (setq catag (getstring "\nCable Tag: ") catag (strcat "PART OF " prefix "-" catag) num (sslen...`
- **Side effects**: Globals set (not declared local): `txtss`, `catag`, `num`, `cnt`, `txtent`, `txtdata`, `old`, `new`; Entities: `entmod`
- **Prompts**: `Cable Tag:`
- **Referenced**: 4

## itag

`(itag prefix)`  - line 1447-1466

Instrument tags with a prefix along a line.

- **Arguments**: `prefix`
- **Returns**: value of the last expression: `(foreach tag tags (setq brkdn (mparse tag "-" nil nil)) (setq itm1 prefix itm2 (strcat (nth 0 brkdn) "-" (nth ...`
- **Side effects**: Globals set (not declared local): `stpt`, `tags`, `tagstr`, `brkdn`, `itm1`, `itm2`, `itm3`; AutoCAD commands: `INSERT`
- **Prompts**: `Startpoint for tags:`; `Tag string:`
- **Referenced**: 4

## c:qte

`(c:qte)`  - line 1467-1469

Quick cable-tag text with prefix A / E / R / T on selected text. User entry: [QTE](../command-reference.md#qte).

- **Arguments**: none
- **Returns**: value of the last expression: `(qt "E")`
- **Referenced**: 0

## c:qta

`(c:qta)`  - line 1470-1472

Quick cable-tag text with prefix A / E / R / T on selected text. User entry: [QTA](../command-reference.md#qta).

- **Arguments**: none
- **Returns**: value of the last expression: `(qt "A")`
- **Referenced**: 0

## c:qtr

`(c:qtr)`  - line 1473-1475

Quick cable-tag text with prefix A / E / R / T on selected text. User entry: [QTR](../command-reference.md#qtr).

- **Arguments**: none
- **Returns**: value of the last expression: `(qt "R")`
- **Referenced**: 0

## c:itage

`(c:itage)`  - line 1476-1478

Instrument tag series with prefix A / E / T along a line. User entry: [ITAGE](../command-reference.md#itage).

- **Arguments**: none
- **Returns**: value of the last expression: `(itag "E")`
- **Referenced**: 0

## c:itaga

`(c:itaga)`  - line 1479-1481

Instrument tag series with prefix A / E / T along a line. User entry: [ITAGA](../command-reference.md#itaga).

- **Arguments**: none
- **Returns**: value of the last expression: `(itag "A")`
- **Referenced**: 0

## c:itagT

`(c:itagT)`  - line 1482-1484

Instrument tag series with prefix A / E / T along a line. User entry: [ITAGT](../command-reference.md#itagt).

- **Arguments**: none
- **Returns**: value of the last expression: `(itag "T")`
- **Referenced**: 0

## c:qtT

`(c:qtT)`  - line 1486-1488

Quick cable-tag text with prefix A / E / R / T on selected text. User entry: [QTT](../command-reference.md#qtt).

- **Arguments**: none
- **Returns**: value of the last expression: `(qt "T")`
- **Referenced**: 0

## c:par

`(c:par)`  - line 1489-1509

Wraps each selected TEXT string in parentheses. User entry: [PAR](../command-reference.md#par).

- **Arguments**: none
- **Returns**: value of the last expression: `(if ss (progn (setq num (sslength ss) cnt 0 ) (while (< cnt num) (setq ent (ssname ss cnt) data(entget ent) va...`
- **Side effects**: Globals set (not declared local): `ss`, `num`, `cnt`, `ent`, `data`, `val`, `old`, `new`; Entities: `entmod`
- **Referenced**: 0

## c:app

`(c:app)`  - line 1510-1531

Appends a string to selected text. User entry: [APP](../command-reference.md#app).

- **Arguments**: none
- **Returns**: value of the last expression: `(if ss (progn (setq tapp (getstring "\nText to append: ")) (setq num (sslength ss) cnt 0 ) (while (< cnt num) ...`
- **Side effects**: Globals set (not declared local): `ss`, `tapp`, `num`, `cnt`, `ent`, `data`, `val`, `old`, `new`; Entities: `entmod`
- **Referenced**: 0

## c:MEDfind

`(c:MEDfind)`  - line 1533-1558

Selects/highlights MED entities of a type (Conduit/Cable/Tray/Fitting/Equipment) and optional code. User entry: [MEDFIND](../command-reference.md#medfind).

- **Arguments**: none
- **Returns**: value of the last expression: `ss1`
- **Side effects**: Globals set (not declared local): `ans`, `mdcd`, `ss1`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 0

## c:ttag

`(c:ttag / ctlt ctlay cctid ccten cctszl ctpt1 ctpt2 ctpt3 ctan ctlen ctinfo keyent keydata blk)`  - line 1565-1661

Tray tag on the centerline with leader. User entry: [TTAG](../command-reference.md#ttag).

- **Arguments**: none
- **Returns**: value of the last expression: `(ltback ctlt)`
- **Side effects**: Globals set (not declared local): `cten`, `ctelev`, `ctendata`, `ctszl`, `ctid`, `mvdata`, `keyrot`, `keypt2`, `elev`, `esystem`, `hdent`, `atent`, `atdata`, `txtbx`, `addon` ...; Xdata: reads xdata; Layers: `_ECTAG` (LAYER command / CLAYER); AutoCAD commands: `INSERT`
- **Referenced**: 3

## c:it

`(c:it / info info2 itang bsize pt1 pt2)`  - line 1673-1689

Instrument bubble (tag + number). User entry: [IT](../command-reference.md#it).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "break" pt2 pt3)`
- **Side effects**: Globals set (not declared local): `pt3`; Layers: `_MEDINST`; AutoCAD commands: `BREAK`, `INSERT`, `LINE`
- **Referenced**: 2

## c:f0

`(c:f0)`  - line 1691-1700

FILLET with radius 0 (restores FILLETRAD after). User entry: [F0](../command-reference.md#f0).

- **Arguments**: none
- **Returns**: value of the last expression: `(setvar "FILLETRAD" oldfrad)`
- **Side effects**: Globals set (not declared local): `oldfrad`; AutoCAD commands: `FILLET`
- **Referenced**: 0

## c:off2con

`(c:off2con / mdata xdlist offent offpt)`  - line 1702-1743

Offsets a picked entity by a distance and turns the copy into a conduit run. User entry: [OFF2CON](../command-reference.md#off2con).

- **Arguments**: none
- **Returns**: value of the last expression: `(if offent (progn (setq offdist (getdist (strcat "\nDistance of offset<" (rtos oldoffdist 2 4) ">: "))) (if (n...`
- **Side effects**: Globals set (not declared local): `oldoffdist`, `offdist`, `ment`, `mpt`, `currlay`; Xdata: writes xdata; Layers: `_MCON` (LAYER command / CLAYER); AutoCAD commands: `CHANGE`, `OFFSET`, `PEDIT`
- **Referenced**: 0

## c:bc

`(c:bc)`  - line 1747-1749

Alias for BOXCLOUD. User entry: [BC](../command-reference.md#bc).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:boxcloud)`
- **Referenced**: 0

## c:atc

`(c:atc)`  - line 1750-1752

Alias for ATTCOPY. User entry: [ATC](../command-reference.md#atc).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:attcopy)`
- **Referenced**: 0

## c:hand

`(c:hand)`  - line 1754-1760

Copies the entity with a typed handle. User entry: [HAND](../command-reference.md#hand).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (handent handval) (command "copy" (handent handval) "") (prompt "Handle not found!") )`
- **Side effects**: Globals set (not declared local): `handval`; AutoCAD commands: `COPY`
- **Referenced**: 0

## getschedule

`(getschedule getschent / detnument detnuminfo detailinfo xdlist curxdata)`  - line 1762-1777

Reads schedule data from a detail entity.

- **Arguments**: `getschent`
- **Returns**: value of the last expression: `(if detnument (progn (setq detnumdata (entget detnument) detnuminfo (dxf 1 detnumdata) detailinfo (med_detail ...`
- **Side effects**: Globals set (not declared local): `detnumdata`; Xdata: writes xdata; DB: `med_detail`
- **Referenced**: 2

## c:blk2byl

`(c:blk2byl)`  - line 1779-1782

Loads blk2byl.lsp and runs its BLK2BYL (block layers to 0/ByLayer). blk2byl.lsp is not in Support. User entry: [BLK2BYL](../command-reference.md#blk2byl).

- **Arguments**: none
- **Returns**: value of the last expression: `(C:BLK2BYL)`
- **Referenced**: 1

## c:T1Thin

`(c:T1Thin)`  - line 1784-1786

Sets the T1Thin MED text style. User entry: [T1THIN](../command-reference.md#t1thin).

- **Arguments**: none
- **Returns**: value of the last expression: `(med_text "T1Thin" nil)`
- **Referenced**: 0

## c:ttags

`(c:ttags / ctlt ctlay cctid ccten cctszl ctpt1 ctpt2 ctpt3 ctan ctlen ctinfo keyent keydata blk)`  - line 1789-1832

Tray tag variant (T1 style). User entry: [TTAGS](../command-reference.md#ttags).

- **Arguments**: none
- **Returns**: value of the last expression: `(ltback ctlt)`
- **Side effects**: Globals set (not declared local): `txtstylname`, `ctss`, `ctsslen`, `ctcnt`, `cten`, `ctelev`, `ctptlist`, `ctendata`, `cttextpt`, `cttextro`, `ctszl`, `ctid`; Xdata: reads xdata; Layers: `_ECTAG` (LAYER command / CLAYER); AutoCAD commands: `LAYER`, `TEXT`
- **Referenced**: 0

## c:telev

`(c:telev / ctlt ctlay cctid ccten cctszl ctpt1 ctpt2 ctpt3 ctan ctlen ctinfo keyent keydata blk)`  - line 1833-1872

Labels tray elevations with a leader tag. User entry: [TELEV](../command-reference.md#telev).

- **Arguments**: none
- **Returns**: value of the last expression: `(ltback ctlt)`
- **Side effects**: Globals set (not declared local): `txtstydata`, `txtstylname`, `currenttab`, `cten`, `ctelev`, `ctendata`, `cttextpt`, `ctszl`, `ctid`, `cttextro`; Xdata: reads xdata; Layers: `_ECTAG` (LAYER command / CLAYER); AutoCAD commands: `LAYER`, `MSPACE`, `PSPACE`, `TEXT`
- **Referenced**: 1

