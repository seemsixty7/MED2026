# medsetup.lsp

`Support\medsetup.lsp` - SETUP, SETLIM, SETPLOT, BLDIST; title block and scale.

Loaded by MEDCore (order 8). 12 defun(s): 4 command(s), 8 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 11 | [`scale_for`](#scale_for) | function |
| 39 | [`settmpsc`](#settmpsc) | function |
| 62 | [`select_title`](#select_title) | function |
| 70 | [`ins_border`](#ins_border) | function |
| 75 | [`c:setup`](#csetup) | command |
| 184 | [`mod_paperspace`](#mod_paperspace) | function |
| 191 | [`c:bldist`](#cbldist) | command |
| 254 | [`c:setplot`](#csetplot) | command |
| 279 | [`setblk`](#setblk) | function |
| 287 | [`MEDtitle`](#medtitle) | function |
| 324 | [`setlim`](#setlim) | function |
| 338 | [`c:setlim`](#csetlim) | command |

## scale_for

`(scale_for tilename)`  - line 11-38

SETUP dialog: enables the scale tiles and temp scale for the chosen scale family (Full/Arch/Eng/Met).

- **Arguments**: `tilename`
- **Returns**: value of the last expression: `(cond ((= tilename "Full") (mode_tile "Arch" 1) (mode_tile "Eng" 1) (mode_tile "Met" 1) (setq tmp_sc 1.0) ) ((...`
- **Side effects**: Globals set (not declared local): `tmp_sc`
- **Referenced**: 4

## settmpsc

`(settmpsc radnm scflag)`  - line 39-61

SETUP dialog: temporary scale values for a radio button.

- **Arguments**: `radnm`, `scflag`
- **Returns**: value of the last expression: `(setq tmpvar radnm)`
- **Side effects**: Globals set (not declared local): `tmp_sc`, `tmp_asc`, `tmp_pltsc`, `tmp_esc`, `tmp_msc`, `tmpvar`
- **Referenced**: 3

## select_title

`(select_title fname)`  - line 62-69

SETUP: picks the title block file.

- **Arguments**: `fname`
- **Returns**: value of the last expression: `titblktouse`
- **Side effects**: Globals set (not declared local): `newfname`, `titblktouse`
- **Referenced**: 1

## ins_border

`(ins_border)`  - line 70-73

SETUP: inserts the border/title block.

- **Arguments**: none
- **Returns**: value of the last expression: `(load "setup.add")`
- **Referenced**: 1

## c:setup

`(c:setup)`  - line 75-182

Drawing setup: DCL for scale set, title block (model or paper space), text styles; sets _SC, DIMSCALE, USERR1. User entry: [SETUP](../command-reference.md#setup).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `archlist`, `englist`, `metlist`, `titblktouse`, `_SC`, `index_val`, `radbut`, `tmp_sc`, `tmp_asc`, `tmp_pltsc`, `tmp_esc`, `tmp_msc`, `result`, `MED_TBLK`, `_PLOTSCALE`
- **Referenced**: 2

## mod_paperspace

`(mod_paperspace n_value)`  - line 184-189

SETUP dialog: paper space toggle.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if (= n_value "0") (setq MEDSETUPUSEPAPERSPACE nil) (setq MEDSETUPUSEPAPERSPACE T) )`
- **Side effects**: Globals set (not declared local): `MEDSETUPUSEPAPERSPACE`
- **Referenced**: 1

## c:bldist

`(c:bldist / fn fnh inspt d1 d2 d3 d4 rtsc dwgpr dwgnm prelen nmlen wrstr)`  - line 191-253

Builds break/rotation distances for a block (0/90/180/270 points) for medblck.dat. User entry: [BLDIST](../command-reference.md#bldist).

- **Arguments**: none
- **Returns**: value of the last expression: `(if blexprt (progn (setq blexprt (entget (car blexprt)) inspt (dxf 10 blexprt) d1 (getdist inspt "\nFirst dist...`
- **Side effects**: Globals set (not declared local): `blexprt`, `rtspc`
- **Referenced**: 0

## c:setplot

`(c:setplot / oldval pltval)`  - line 254-276

Sets or turns off the plot correction factor used by MED text/symbol scaling. User entry: [SETPLOT](../command-reference.md#setplot).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_PLOTSCALE`
- **Referenced**: 0

## setblk

`(setblk)`  - line 279-283

function for setting up a title block definition file

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `MED_TBLK`
- **Prompts**: `Title block name(Path if needed):`; `The MED.SPC file has not been modified.`
- **Referenced**: 0

## MEDtitle

`(MEDtitle / old ss1 str tdwg su cnt tit)`  - line 287-321

function for changing existing title block in current drawing

- **Arguments**: none
- **Returns**: value of the last expression: `(setvar "ATTREQ" 1)`
- **Side effects**: Globals set (not declared local): `atmode`, `s3`, `titleinscale`, `_INSPT`; AutoCAD commands: `-INSERT`, `-LAYOUT`
- **Prompts**: `Insertion point for Title block:`; `Rotation Angle <0>:`
- **Referenced**: 1

## setlim

`(setlim / pt)`  - line 324-337

functions sets the limits to the extents of the drawing

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `ZOOM`
- **Referenced**: 1

## c:setlim

`(c:setlim)`  - line 338-340

Sets drawing limits from the title block size and current MED scale. User entry: [SETLIM](../command-reference.md#setlim).

- **Arguments**: none
- **Returns**: value of the last expression: `(setlim)`
- **Referenced**: 0

