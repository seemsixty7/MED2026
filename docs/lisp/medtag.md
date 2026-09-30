# medtag.lsp

`Support\medtag.lsp` - Tagging: section/cut marks, clouds, bubbles, hot dog tag, bracket.

Loaded by MEDCore (order 22). 12 defun(s): 12 command(s), 0 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:sect`](#csect) | command |
| 19 | [`c:cut`](#ccut) | command |
| 38 | [`c:cloud`](#ccloud) | command |
| 83 | [`c:abl`](#cabl) | command |
| 96 | [`c:bracket`](#cbracket) | command |
| 125 | [`c:gr`](#cgr) | command |
| 142 | [`c:mbl`](#cmbl) | command |
| 190 | [`c:HDTAG`](#chdtag) | command |
| 305 | [`c:hdtagold`](#chdtagold) | command |
| 330 | [`c:mb`](#cmb) | command |
| 374 | [`c:mb1`](#cmb1) | command |
| 413 | [`c:boxcloud`](#cboxcloud) | command |

## c:sect

`(c:sect / pt1 pt2 val)`  - line 2-18

Section marks in plan (two points + letter). This definition wins (loads after MEDCommands.lsp). User entry: [SECT](../command-reference.md#sect).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `curatdia`; Layers: `_MEDTEXT`; AutoCAD commands: `COPY`, `INSERT`
- **Referenced**: 2
- **Duplicate**: also defined in Support\MEDCommands.lsp:303; this definition loads last and wins

## c:cut

`(c:cut / lay pt1 pt2 val)`  - line 19-34

Cut marks plus a section letter. User entry: [CUT](../command-reference.md#cut).

- **Arguments**: none
- **Returns**: nothing useful (restores sysvars / error handler)
- **Side effects**: Globals set (not declared local): `curatdia`; Layers: `_MEDTEXT`; AutoCAD commands: `COPY`, `INSERT`
- **Referenced**: 1

## c:cloud

`(c:cloud / clpt clpt1 head hdata bulge en ed)`  - line 38-81

Revision cloud: pick-and-drag closed polyline cloud. User entry: [CLOUD](../command-reference.md#cloud).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `ptprompt`, `newhdata`, `itmcd`; Layers: creates/sets layers; Entities: `entmod`; AutoCAD commands: `PLINE`
- **Referenced**: 1

## c:abl

`(c:abl / pt pt1 pt2 pt3 pt4 dist lay)`  - line 83-95

Adds a leader to a selected bubble. User entry: [ABL](../command-reference.md#abl).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:bracket

`(c:bracket)`  - line 96-124

Bracket mark from two points and a direction. User entry: [BRACKET](../command-reference.md#bracket).

- **Arguments**: none
- **Returns**: value of the last expression: `(progn (setvar "cmdecho" 0) (setvar "menuecho" 1) (setq curosmode (getvar "osmode")) (setq pt1(getpoint "\nFir...`
- **Side effects**: Globals set (not declared local): `curosmode`, `pt1`, `pt5`, `ang`, `pt2`, `pt3`, `pt4`, `en`; AutoCAD commands: `FILLET`, `MIRROR`, `PEDIT`, `PLINE`
- **Referenced**: 1

## c:gr

`(c:gr / pt1 ept rot nep data)`  - line 125-140

Hook ("grab") leader / add a hoop at a line end. User entry: [GR](../command-reference.md#gr).

- **Arguments**: none
- **Returns**: value of the last expression: `(command "insert" "grabit" ept(* (* 1.0 (getvar "dimscale")) (getvar "dimasz") 0.5) "" rot)`
- **Side effects**: Entities: `entmod`; AutoCAD commands: `INSERT`
- **Referenced**: 0

## c:mbl

`(c:mbl / ans cenpt dist lay npt1 pt pt1 pt3 pt4 s1 s2 ss1)`  - line 142-189

Moves a bubble or its leader point. User entry: [MBL](../command-reference.md#mbl).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `ERASE`, `LAYER`, `LINE`, `SELECT`
- **Referenced**: 1

## c:HDTAG

`(c:HDTAG)`  - line 190-303

"Hot dog" conduit tag sized to the text. User entry: [HDTAG](../command-reference.md#hdtag).

- **Arguments**: none
- **Returns**: value of the last expression: `(ltback ctlt)`
- **Side effects**: Globals set (not declared local): `ctlt`, `ctlay`, `cattdia`, `ConduitEntity`, `ConduitPoint`, `ConduitData`, `ConduitSize`, `ConduitTag`, `hdtagblockname`, `1.0`, `1.375`, `1.7375`, `2.1375`, `2.575`, `2.9375` ...; Xdata: reads xdata; Layers: `_ECTAG` (LAYER command / CLAYER); AutoCAD commands: `INSERT`
- **Referenced**: 1

## c:hdtagold

`(c:hdtagold / info blk)`  - line 305-327

Previous hot dog tag version. User entry: [HDTAGOLD](../command-reference.md#hdtagold).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `curatdia`; Layers: `_MEDTEXT`; AutoCAD commands: `INSERT`
- **Referenced**: 0

## c:mb

`(c:mb / bsize id qty pt1 pt2 pt3 ang)`  - line 330-372

Material bubble(s) with leader. User entry: [MB](../command-reference.md#mb).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (/= "" (setq id (getstring "\nMaterial I.D.#: "))) (progn (setq ang (getangle pt2 "\nDirection of bubbles:...`
- **Side effects**: Globals set (not declared local): `etp`; Layers: `_EMATBUB`; AutoCAD commands: `INSERT`, `LINE`
- **Referenced**: 0

## c:mb1

`(c:mb1 / bsize id qty pt1 pt2 pt3 ang)`  - line 374-411

Material bubble(s) with leader. User entry: [MB1](../command-reference.md#mb1).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (/= "" (setq id (getstring "\nMaterial I.D.#: "))) (progn (setq ang (getangle pt2 "\nDirection of bubbles:...`
- **Side effects**: Layers: `_EMATBUB`; AutoCAD commands: `DIM1`, `INSERT`
- **Referenced**: 0

## c:boxcloud

`(c:boxcloud)`  - line 413-496

Rectangular revision cloud from two corners with X/Y arc spacing. User entry: [BOXCLOUD](../command-reference.md#boxcloud).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `xseglen`, `xlen`, `yseglen`, `ylen`, `pt1`, `pt3`, `pt2`, `pt4`, `d1`, `d2`, `npt`, `head`, `hdata`, `newhdata`, `bulge` ...; Layers: creates/sets layers; Entities: `entmod`; AutoCAD commands: `C`, `PLINE`
- **Referenced**: 1

