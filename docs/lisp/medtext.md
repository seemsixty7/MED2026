# medtext.lsp

`Support\medtext.lsp` - Text and attribute tools (FD, XT, CT, CTEDIT, TJ, ...), LOADTXT.

Loaded by MEDCore (order 21). 23 defun(s): 15 command(s), 8 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:fd`](#cfd) | command |
| 159 | [`c:xt`](#cxt) | command |
| 231 | [`c:upcase`](#cupcase) | command |
| 255 | [`c:rt`](#crt) | command |
| 299 | [`c:ct`](#cct) | command |
| 331 | [`c:acx`](#cacx) | command |
| 362 | [`c:ac`](#cac) | command |
| 375 | [`c:ctedit`](#cctedit) | command |
| 426 | [`update`](#update) | function |
| 436 | [`ntext`](#ntext) | function |
| 468 | [`edadd`](#edadd) | function |
| 477 | [`sets`](#sets) | function |
| 528 | [`c:tj`](#ctj) | command |
| 614 | [`tjupd`](#tjupd) | function |
| 635 | [`c:ut`](#cut) | command |
| 658 | [`c:cx`](#ccx) | command |
| 751 | [`c:atadd`](#catadd) | command |
| 965 | [`c:mt`](#cmt) | command |
| 1025 | [`matchtxtprops`](#matchtxtprops) | function |
| 1049 | [`grldr`](#grldr) | function |
| 1113 | [`c:attcopy`](#cattcopy) | command |
| 1129 | [`getmainent`](#getmainent) | function |
| 1136 | [`c:LOADTXT`](#cloadtxt) | command |

## c:fd

`(c:fd / dwgcnt dwgnm dwg_info fileinfo currdate year month day mnth_list jmonth hour minute dwgchar dwg ampm dateinfo timinfo userinfo viewinfo all_info fileinfodata oldinfo newinfo)`  - line 2-157

Inserts/updates the FILEINFO block (name, scale, date, user). User entry: [FD](../command-reference.md#fd).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `fdupd`, `dwgprefix`, `dwglen`, `timeinfo`, `dwg_scl`, `fdss`, `cnt`, `num`, `hdent`, `atent`, `hddata`, `oldlay`, `newlay`, `atdata`, `plac` ...; Layers: `_FDTEXT`; Entities: `entmod`; AutoCAD commands: `INSERT`
- **Referenced**: 0

## c:xt

`(c:xt / ans sbpt num count ss1 hgt new wdth styl nhgt cur ent old old1 old3)`  - line 159-229

Converts selected text to another style (spacing adjust if heights differ). User entry: [XT](../command-reference.md#xt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Entities: `entmod`; AutoCAD commands: `SCALE`, `SELECT`, `STYLE`
- **Referenced**: 1

## c:upcase

`(c:upcase / count ent new old old1 ss1 txt)`  - line 231-254

Converts selected text to upper case. User entry: [UPCASE](../command-reference.md#upcase).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `len`; Entities: `entmod`
- **Referenced**: 0

## c:rt

`(c:rt)`  - line 255-297

Replaces several text entities with one value (pick or type). User entry: [RT](../command-reference.md#rt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ss1`, `num`, `count`, `edata`, `ename`, `nt`, `newvalue`, `entdata`, `txtdata`, `newtext`, `oldtext`; Entities: `entmod`
- **Referenced**: 0

## c:ct

`(c:ct / num count ss1 item inp ent new old)`  - line 299-329

Changes text strings; pick several in the order to change. User entry: [CT](../command-reference.md#ct).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Entities: `entmod`; AutoCAD commands: `SELECT`
- **Referenced**: 1

## c:acx

`(c:acx / pt ptlist old hlmode new)`  - line 331-360

Replaces part of attribute values (old string -> new string). User entry: [ACX](../command-reference.md#acx).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `ATTEDIT`
- **Referenced**: 1

## c:ac

`(c:ac / old)`  - line 362-374

Changes a selected attribute to a new value. User entry: [AC](../command-reference.md#ac).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `AC_VAL`; AutoCAD commands: `ATTEDIT`
- **Referenced**: 0

## c:ctedit

`(c:ctedit)`  - line 375-425

Edits a text set: change / prefix / suffix, autostep or typical. User entry: [CTEDIT](../command-reference.md#ctedit).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ss1`, `numb`, `count`, `item`, `ent`, `inp`, `new`, `old`, `preval`, `sufval`, `pre`, `suf`, `prenum`, `sufnum`, `num` ...; Entities: `entmod`; AutoCAD commands: `SELECT`
- **Referenced**: 3

## update

`(update var cntr)`  - line 426-435

CTEDIT: steps a counter value.

- **Arguments**: `var`, `cntr`
- **Returns**: value of the last expression: `num`
- **Side effects**: Globals set (not declared local): `num`
- **Referenced**: 13

## ntext

`(ntext)`  - line 436-467

CTEDIT: prefix/suffix prompt.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (and (not preval) (not sufval)) (progn (if pre (setq inp (strcat (getstring T "\nPrefix: ") (substr inp (1...`
- **Side effects**: Globals set (not declared local): `inp`, `preval`, `sufval`
- **Prompts**: `Prefix:`; `Suffix:`
- **Referenced**: 5

## edadd

`(edadd typedata / edans ret)`  - line 468-476

CTEDIT: number of characters to edit.

- **Arguments**: `typedata`
- **Returns**: value of the last expression: `ret`
- **Prompts**: `Number of Characters to edit:`
- **Referenced**: 2

## sets

`(sets)`  - line 477-525

CTEDIT: change/prefix/suffix, single/multiple, autostep/typical prompts.

- **Arguments**: none
- **Returns**: value of the last expression: `(while (/= ans "Change") (initget "Change Prefix Suffix") (setq ans (getkword "\nChange/Prefix/Suffix <Change>...`
- **Side effects**: Globals set (not declared local): `ans`, `prenum`, `pre`, `prean`, `prest`, `precnt`, `preval`, `sufnum`, `suf`, `sufan`, `sufst`, `sufcnt`, `sufval`
- **Prompts**: `Change/Prefix/Suffix <Change>:`; `Single or Multiple edit:`; `Autostep Or Typical:`; `Start point:`
- **Referenced**: 7

## c:tj

`(c:tj)`  - line 528-613

Sets text justification and aligns text to a picked point. User entry: [TJ](../command-reference.md#tj).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ss1`, `count`, `num`, `just`, `align`, `new`, `new1`, `cur`, `ent`, `old`, `old1`, `gettj`, `y10`, `pt10`, `y11` ...; Entities: `entmod`
- **Referenced**: 1

## tjupd

`(tjupd pt1 pt2)`  - line 614-633

TJ: aligns text to a point.

- **Arguments**: `pt1`, `pt2`
- **Returns**: value of the last expression: `(entmod ent)`
- **Side effects**: Globals set (not declared local): `tjw`, `tjw1`, `tjd`, `tjd1`, `ent`; Entities: `entmod`
- **Referenced**: 2

## c:ut

`(c:ut / ulss ulsslen ulcnt uldata)`  - line 635-657

Underlines selected text. User entry: [UT](../command-reference.md#ut).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ulent`, `ulval`; Entities: `entmod`
- **Referenced**: 0

## c:cx

`(c:cx / cxss cxlen cxcnt cxfirst cxoldst cxoldln cxnewst cxnewln cxdata oldval newval chngd)`  - line 658-750

Find and replace a substring across selected text. User entry: [CX](../command-reference.md#cx).

- **Arguments**: none
- **Returns**: nothing useful (restores sysvars / error handler)
- **Side effects**: Globals set (not declared local): `oldlen`, `oldcnt`, `cmpval`; Entities: `entmod`
- **Referenced**: 1

## c:atadd

`(c:atadd)`  - line 751-843

Adds an attribute to a block insert. User entry: [ATADD](../command-reference.md#atadd).

- **Arguments**: none
- **Returns**: value of the last expression: `(entmake (list (cons 0 "SEQEND")))`
- **Side effects**: Globals set (not declared local): `blkent`, `tagnm`, `atval`, `inspt`, `blkdata`, `just`, `align`, `new`, `new1`, `suben`, `subdata`, `newblk`, `addent`; Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmake`, `entdel`
- **Referenced**: 0

## c:mt

`(c:mt)`  - line 965-1023

Matches text properties from a master text entity. User entry: [MT](../command-reference.md#mt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `chgss`, `mstent`, `MT_MATCHLIST`, `tmplist`, `index_val`, `result`
- **Referenced**: 0

## matchtxtprops

`(matchtxtprops mtchss chglist mstrdata)`  - line 1025-1047

Applies text properties from a master to a selection (this copy wins).

- **Arguments**: `mtchss`, `chglist`, `mstrdata`
- **Returns**: value of the last expression: `(while (< cnt num) (setq ent (ssname mtchss cnt) data(entget ent) cnt (1+ cnt) ) (foreach itm chgdata (setq ol...`
- **Side effects**: Globals set (not declared local): `chgdata`, `num`, `cnt`, `ent`, `data`, `oldvals`; Entities: `entmod`
- **Referenced**: 1
- **Duplicate**: also defined in Support\MEDFunctions.lsp:1557; this definition loads last and wins

## grldr

`(grldr pt numpk blnm scadj)`  - line 1049-1110

Hook leader worker (GR/GRAB).

- **Arguments**: `pt`, `numpk`, `blnm`, `scadj`
- **Returns**: value of the last expression: `(entlast)`
- **Side effects**: Globals set (not declared local): `genang`, `lentmrk`, `lentbk`, `pt1`, `cnt`, `entblk`, `allss`, `entdata`, `oldy`, `newy`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmod`; AutoCAD commands: `DIM`, `DIMASZ`, `DIMBLK`, `INSERT`, `LAYER`
- **Prompts**: `Leader start:`; `to:`
- **Referenced**: 0

## c:attcopy

`(c:attcopy)`  - line 1113-1128

Copies one attribute value to another attribute. User entry: [ATTCOPY](../command-reference.md#attcopy).

- **Arguments**: none
- **Returns**: value of the last expression: `(if patt (progn (setq pdata (entget (car patt)) satt (nentsel "\nSelect Attribute to copy to: ") sdata (entget...`
- **Side effects**: Globals set (not declared local): `patt`, `pdata`, `satt`, `sdata`, `ment`, `pval`; Entities: `entmod`
- **Referenced**: 1

## getmainent

`(getmainent subent)`  - line 1129-1134

Returns the parent insert of a sub-entity.

- **Arguments**: `subent`
- **Returns**: value of the last expression: `(setq retent (dxf -2 (entget subent)))`
- **Side effects**: Globals set (not declared local): `retent`
- **Referenced**: 1

## c:LOADTXT

`(c:LOADTXT)`  - line 1136-1153

Creates the MED text styles from MED_TXT_STYLE_MAP (TXT0625 ... TXT1875), then runs BLDSTL. Replaced at load time by the med.spc version (med.spc loads after medtext.lsp). User entry: [LOADTXT](../command-reference.md#loadtxt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `STYLE`
- **Referenced**: 15
- **Duplicate**: also defined in Support\med.spc:167; replaced at load time by the med.spc version

