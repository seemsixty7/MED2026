# medutil.lsp

`Support\medutil.lsp` - Drafting utilities: breaks, layers, polylines, links/fields, BLDSTL.

Loaded by MEDCore (order 23). 29 defun(s): 24 command(s), 5 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 6 | [`c:lbreak`](#clbreak) | command |
| 64 | [`snut`](#snut) | function |
| 156 | [`c:lb`](#clb) | command |
| 213 | [`pbreak`](#pbreak) | function |
| 248 | [`entlist`](#entlist) | function |
| 253 | [`c:fl`](#cfl) | command |
| 288 | [`c:lisp`](#clisp) | command |
| 299 | [`c:bn`](#cbn) | command |
| 312 | [`c:cl`](#ccl) | command |
| 339 | [`c:em`](#cem) | command |
| 359 | [`c:lt`](#clt) | command |
| 385 | [`c:plmake`](#cplmake) | command |
| 402 | [`c:pw`](#cpw) | command |
| 405 | [`c:plwide`](#cplwide) | command |
| 481 | [`c:pbox`](#cpbox) | command |
| 525 | [`c:sl`](#csl) | command |
| 535 | [`c:tm`](#ctm) | command |
| 558 | [`c:bldstl`](#cbldstl) | command |
| 588 | [`getalias`](#getalias) | function |
| 639 | [`linemake`](#linemake) | function |
| 652 | [`c:il`](#cil) | command |
| 675 | [`c:uil`](#cuil) | command |
| 686 | [`c:blkreins`](#cblkreins) | command |
| 788 | [`c:linkprefix`](#clinkprefix) | command |
| 829 | [`c:linkprefixAtt`](#clinkprefixatt) | command |
| 860 | [`c:linkvalue`](#clinkvalue) | command |
| 894 | [`c:setlink`](#csetlink) | command |
| 931 | [`c:setlinksum`](#csetlinksum) | command |
| 967 | [`c:showfieldcode`](#cshowfieldcode) | command |

## c:lbreak

`(c:lbreak / lay ent selpt data pt1 pt2 ptlist stang endang nlen val40 val41 stpt vtxt1 vtxt2 vtxt3 sqend)`  - line 6-63

Line break symbol between two points. User entry: [LBREAK](../command-reference.md#lbreak).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `spt`, `ept`, `plin`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`; AutoCAD commands: `BREAK`, `LAYER`
- **Referenced**: 1

## snut

`(snut / pt1 pt pt2 pt3 pt4 pt5 pt6 pt7 pt8 en1 en2 en3 en4 en5 en6 apt ang ans size)`  - line 64-102

Draws a nut (top/side view). Nothing calls it (no c:SNUT) - unreachable. TODO: confirm with Clint.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (= ans "Side") (progn (setq pt (getpoint "\nStart point of nut: ")) (setq apt (getpoint pt "\nDirection an...`
- **Side effects**: AutoCAD commands: `CIRCLE`, `ERASE`, `FILLET`, `LINE`
- **Prompts**: `Size of nut:`; `Top view/Side view:`; `Start point of nut:`; `Direction angle of nut:`
- **Referenced**: 0

## c:lb

`(c:lb / ang1 ang2 count ent num old pt1 pt2 pt3 pt4 ss1 trl trl1 trl1data trldata)`  - line 156-211

Priority break: break entities around one that stays whole. User entry: [LB](../command-reference.md#lb).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `bkd`, `brent`, `brdata`, `brint`, `br1`, `br2`; AutoCAD commands: `BREAK`
- **Referenced**: 1

## pbreak

`(pbreak ent / ang1 ang2 cnt numb pt4 pt3 ptlist)`  - line 213-247

Breaks an entity at its intersections (LB worker).

- **Arguments**: `ent`
- **Returns**: value of the last expression: `(setq ptlist nil brint nil )`
- **Side effects**: Globals set (not declared local): `brent`, `brdata`, `brint`, `br1`, `br2`; AutoCAD commands: `BREAK`
- **Referenced**: 1

## entlist

`(entlist)`  - line 248-252

Prints the entity list of a pick.

- **Arguments**: none
- **Returns**: value of the last expression: `(setq ename (ssname ss1 count) edata (entget ename) )`
- **Side effects**: Globals set (not declared local): `ename`, `edata`
- **Referenced**: 0

## c:fl

`(c:fl / ss1 edata ename count num lname coff)`  - line 253-285

Freezes the layers of picked entities. User entry: [FL](../command-reference.md#fl).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `flss`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `F`, `LAYER`
- **Referenced**: 0

## c:lisp

`(c:lisp / rout)`  - line 288-294

Loads a lisp file by name. User entry: [LISP](../command-reference.md#lisp).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (findfile (strcat rout ".lsp")) (load rout) (progn (terpri) (prompt "File name not found.")) )`
- **Referenced**: 0

## c:bn

`(c:bn / bnent bndata bname)`  - line 299-311

Shows the block name of a picked insert. User entry: [BN](../command-reference.md#bn).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:cl

`(c:cl / clss cllen clcnt clnew clent cldata cllay nwlay)`  - line 312-337

Moves a selection to the layer of a picked entity. User entry: [CL](../command-reference.md#cl).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Entities: `entmod`
- **Referenced**: 1

## c:em

`(c:em / emss1 emss2 emlen emcnt empt)`  - line 339-358

Extend multiple to a boundary set. User entry: [EM](../command-reference.md#em).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ement`; AutoCAD commands: `EXTEND`
- **Referenced**: 0

## c:lt

`(c:lt / ltss ltnew ltnewlay ltlaydata ltewen)`  - line 359-383

Changes linetype of a selection to a picked entity's. User entry: [LT](../command-reference.md#lt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ltnewen`, `ltans`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `CHANGE`
- **Referenced**: 1

## c:plmake

`(c:plmake)`  - line 385-401

Converts lines to polylines. User entry: [PLMAKE](../command-reference.md#plmake).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ss1`, `count`, `num`, `en`, `endt`; AutoCAD commands: `PEDIT`
- **Referenced**: 0

## c:pw

`(c:pw)`  - line 402-404

Polyline width change (match or type). User entry: [PW](../command-reference.md#pw).

- **Arguments**: none
- **Returns**: value of the last expression: `(c:plwide)`
- **Referenced**: 0

## c:plwide

`(c:plwide / pwss nwth pwcnt pwlcnt pwnum pwent oldval swth ewth)`  - line 405-480

Polyline width change (match or type). User entry: [PLWIDE](../command-reference.md#plwide).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `pwdata`; AutoCAD commands: `PEDIT`
- **Referenced**: 2

## c:pbox

`(c:pbox / pt1 pt2 ptlist)`  - line 481-493

Closed polyline box from two corners. User entry: [PBOX](../command-reference.md#pbox).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:sl

`(c:sl)`  - line 525-533

Sets the current layer from a picked entity. User entry: [SL](../command-reference.md#sl).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `slen`, `sldata`, `sllay`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `LAYER`
- **Referenced**: 0

## c:tm

`(c:tm / tmss1 tmss2 tmlen tmcnt tmpt tment)`  - line 535-554

Trim multiple to a boundary set. User entry: [TM](../command-reference.md#tm).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `TRIM`
- **Referenced**: 0

## c:bldstl

`(c:bldstl / _stylenms stdata curcmdlst curalilst fname fn)`  - line 558-586

Builds temporary commands named after each text style (MEDlsp.tmp) to set that style. User entry: [BLDSTL](../command-reference.md#bldstl).

- **Arguments**: none
- **Returns**: value of the last expression: `(load (strcat (getvar "MYDOCUMENTSPREFIX") "\\MEDlsp.tmp"))`
- **Referenced**: 2

## getalias

`(getalias / al_err al_oe s al_oce aliasi lineno first line lfile)`  - line 588-637

Reads command aliases from ACAD.PGP.

- **Arguments**: none
- **Returns**: value of the last expression: `aliaslist`
- **Side effects**: Globals set (not declared local): `fname`, `aliaslist`, `j`, `al_str`, `c_str`, `tmpstr`
- **Referenced**: 1

## linemake

`(linemake linept1 linept2 linelay)`  - line 639-650

Entmakes a line on a layer.

- **Arguments**: `linept1`, `linept2`, `linelay`
- **Returns**: value of the last expression: `(entmake linedat)`
- **Side effects**: Globals set (not declared local): `linedat`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 1

## c:il

`(c:il)`  - line 652-674

Isolate layer: makes the picked entity's layer current and turns all other layers off (remembered in _LAYLIST). User entry: [IL](../command-reference.md#il).

- **Arguments**: none
- **Returns**: value of the last expression: `(if ent (progn (setq ent (car ent) data(entget ent) laynam (dxf 8 data) _LAYLIST nil ) (setq lay (tblnext "LAY...`
- **Side effects**: Globals set (not declared local): `ent`, `data`, `laynam`, `_LAYLIST`, `lay`, `lnm`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `LAYER`
- **Referenced**: 0

## c:uil

`(c:uil)`  - line 675-684

Turns back on layers switched off by IL (_LAYLIST). User entry: [UIL](../command-reference.md#uil).

- **Arguments**: none
- **Returns**: value of the last expression: `(setq _LAYLIST nil)`
- **Side effects**: Globals set (not declared local): `_LAYLIST`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `LAYER`
- **Referenced**: 0

## c:blkreins

`(c:blkreins)`  - line 686-786

Re-inserts blocks by name. User entry: [BLKREINS](../command-reference.md#blkreins).

- **Arguments**: none
- **Returns**: value of the last expression: `(setvar "cmdecho" cmdstat)`
- **Side effects**: Globals set (not declared local): `blknm`, `_BLKREINS`, `cmdstat`, `blkss`, `blklen`, `blkcnt`, `blkent`, `blkdata`, `blk_hd`, `blkins`, `blklay`, `blkrot`, `blksc`, `blkatts`, `blkxdata` ...; Xdata: reads/writes xdata directly (-3 group / regapp); Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmod`, `entdel`; AutoCAD commands: `INSERT`, `LAYER`
- **Referenced**: 0

## c:linkprefix

`(c:linkprefix)`  - line 788-827

Links a prefix text to other text / attributes (field-based). User entry: [LINKPREFIX](../command-reference.md#linkprefix).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `PrefixEnt`, `PrefixData`, `PrefixOID`, `prefixvalue`, `prefixtext`, `prefixlength`, `textss`, `cnt`, `textsslen`, `textdata`, `txtvalue`, `newvalue`, `newentdata`; Entities: `entmod`
- **Referenced**: 0

## c:linkprefixAtt

`(c:linkprefixAtt)`  - line 829-859

Links a prefix text to other text / attributes (field-based). User entry: [LINKPREFIXATT](../command-reference.md#linkprefixatt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `PrefixEnt`, `PrefixData`, `PrefixOID`, `prefixvalue`, `prefixtext`, `prefixlength`, `textent`, `textdata`, `txtvalue`, `newvalue`, `newentdata`; Entities: `entmod`
- **Referenced**: 0

## c:linkvalue

`(c:linkvalue)`  - line 860-891

Links target text/attributes to a source value (field). User entry: [LINKVALUE](../command-reference.md#linkvalue).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `PrefixEnt`, `PrefixData`, `PrefixOID`, `prefixvalue`, `prefixtext`, `prefixlength`, `textent`, `textdata`, `newvalue`, `newentdata`; Entities: `entmod`
- **Referenced**: 0

## c:setlink

`(c:setlink)`  - line 894-928

Builds a linked (field) string / sum from several sources into a target. User entry: [SETLINK](../command-reference.md#setlink).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `LinkEnt`, `LinkValue`, `textent`, `linkedentdata`, `linkedentOID`, `LinkEntData`, `newvalue`, `newentdata`; Entities: `entmod`; AutoCAD commands: `UNDO`
- **Referenced**: 0

## c:setlinksum

`(c:setlinksum)`  - line 931-965

Builds a linked (field) string / sum from several sources into a target. User entry: [SETLINKSUM](../command-reference.md#setlinksum).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `LinkEnt`, `LinkValue`, `textent`, `linkedentdata`, `linkedentOID`, `LinkEntData`, `newvalue`, `newentdata`; Entities: `entmod`; AutoCAD commands: `UNDO`
- **Referenced**: 0

## c:showfieldcode

`(c:showfieldcode)`  - line 967-983

Shows the field code of a picked entity. User entry: [SHOWFIELDCODE](../command-reference.md#showfieldcode).

- **Arguments**: none
- **Returns**: value of the last expression: `(if ent (progn (setq entdata (entget (car ent))) (if (or (= (dxf 0 entdata) "TEXT") (= (dxf 0 entdata) "MTEXT"...`
- **Side effects**: Globals set (not declared local): `ent`, `entdata`, `obj`, `fieldcode`
- **Referenced**: 0

