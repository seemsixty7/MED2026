# medcon.lsp

`Support\medcon.lsp` - Conduit drawing: CONDUIT, DEFINE, FLEX, FC, CONSIZE, two-line conduit.

Loaded by MEDCore (order 6). 13 defun(s): 11 command(s), 2 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:conduit`](#cconduit) | command |
| 38 | [`c:define`](#cdefine) | command |
| 78 | [`c:fc`](#cfc) | command |
| 95 | [`c:flex`](#cflex) | command |
| 114 | [`c:consize`](#cconsize) | command |
| 158 | [`c:2break`](#c2break) | command |
| 164 | [`c:2lcon`](#c2lcon) | command |
| 170 | [`c:2lflex`](#c2lflex) | command |
| 192 | [`c:confix`](#cconfix) | command |
| 200 | [`mk2lcon`](#mk2lcon) | function |
| 260 | [`dblins`](#dblins) | function |
| 299 | [`c:2away`](#c2away) | command |
| 305 | [`c:2toward`](#c2toward) | command |

## c:conduit

`(c:conduit / conent conpt conqty xdlist contag cltp ptprompt)`  - line 2-37

Draws a conduit polyline run with MED_CONDUIT xdata; optional bend fillet; tag prompt. User entry: [CONDUIT](../command-reference.md#conduit).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Xdata: writes xdata; AutoCAD commands: `FILLET`, `PLINE`
- **Referenced**: 4

## c:define

`(c:define / conent conpt conqty xdlist contag)`  - line 38-77

Attaches the current conduit settings (xdata) to existing geometry of a run. User entry: [DEFINE](../command-reference.md#define).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `definent`, `definentdata`, `defineplm`, `definen`, `definent1`; Xdata: writes xdata; AutoCAD commands: `FILLET`, `PEDIT`
- **Referenced**: 1

## c:fc

`(c:fc / tem)`  - line 78-94

Fillet at the bend radius for a conduit size (asks the size). User entry: [FC](../command-reference.md#fc).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_FCSIZE`; AutoCAD commands: `FILLET`
- **Referenced**: 1

## c:flex

`(c:flex / ep pt1 pt2 pt3 pt4 pt5 sp)`  - line 95-113

Draws a flexible conduit (4-point spline-like run) with connectors. User entry: [FLEX](../command-reference.md#flex).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `INSERT`, `PLINE`
- **Referenced**: 1

## c:consize

`(c:consize)`  - line 114-156

DCL conduit size picker (sets _CSIZE/_ACSIZE/_CLETT). User entry: [CONSIZE](../command-reference.md#consize).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `index_val`, `result`
- **Referenced**: 1

## c:2break

`(c:2break / pt1 pt2 dist inspt)`  - line 158-163

Inserts a break symbol on a two-line conduit. User entry: [2BREAK](../command-reference.md#2break).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:2lcon

`(c:2lcon)`  - line 164-169

Two-line (detail) conduit run. User entry: [2LCON](../command-reference.md#2lcon).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:2lflex

`(c:2lflex / 2lent 2lpt 2lent1 2lent2 tcode)`  - line 170-190

Two-line flexible conduit run. User entry: [2LFLEX](../command-reference.md#2lflex).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CODE`; Layers: `_MEDDETCON`; AutoCAD commands: `OFFSET`, `PEDIT`
- **Referenced**: 0

## c:confix

`(c:confix)`  - line 192-195

Rebuilds a two-line conduit from its centerline. User entry: [CONFIX](../command-reference.md#confix).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## mk2lcon

`(mk2lcon mkent)`  - line 200-259

Builds a two-line conduit from a MED conduit polyline (CONFIX / 2LCON worker).

- **Arguments**: `mkent`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `mklwptlist`, `mkentpt`, `offang`, `mksel`, `mksz`, `conlett`, `2lent1`, `2lent2`; Xdata: writes xdata, reads xdata; Layers: `_MEDCENLAY`, `_MEDDETCON` (LAYER command / CLAYER); AutoCAD commands: `CHANGE`, `OFFSET`
- **Referenced**: 5

## dblins

`(dblins dblblname ins_code / pt1 pt2 dist inspt)`  - line 260-298

Inserts a block between two lines of a two-line conduit.

- **Arguments**: `dblblname`, `ins_code`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `currosmode`, `cmdechomode`, `pt1a`, `ent1`, `entdata`, `laynm`, `insang`, `origin-insunits`; Layers: `laynm`; AutoCAD commands: `-INSERT`
- **Prompts**: `Select lines of conduit:`; `First line:`; `Second line:`
- **Referenced**: 3

## c:2away

`(c:2away / pt1 pt2 dist inspt)`  - line 299-304

Inserts the conduit-away symbol on a two-line conduit. User entry: [2AWAY](../command-reference.md#2away).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## c:2toward

`(c:2toward / pt1 pt2 dist inspt)`  - line 305-310

Inserts the conduit-toward symbol on a two-line conduit. User entry: [2TOWARD](../command-reference.md#2toward).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

