# medwire.lsp

`Support\medwire.lsp` - Wiring diagram helpers: TSTRIP, MEDLINE, 2LINE, 3LINE.

Loaded by MEDCore (order 7). 4 defun(s): 4 command(s), 0 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:tstrip`](#ctstrip) | command |
| 61 | [`c:medline`](#cmedline) | command |
| 80 | [`c:2line`](#c2line) | command |
| 104 | [`c:3line`](#c3line) | command |

## c:tstrip

`(c:tstrip / drawit pt1 apt ang num pt2 pt3 pt4 ptlist txtpt ans)`  - line 2-60

Terminal strip generator; can chain into CTEDIT for numbering. User entry: [TSTRIP](../command-reference.md#tstrip).

- **Arguments**: none
- **Returns**: value of the last expression: `(if (or (not ans) (= ans "Yes")) (progn (setq CTEDITSS txtss txtss nil ) (C:CTEDIT) ) )`
- **Side effects**: Globals set (not declared local): `clay`, `txtss`, `CTEDITSS`; Layers: `_MEDSYM`, `_MEDTEXT` (LAYER command / CLAYER); AutoCAD commands: `CHANGE`, `LAYER`, `TEXT`
- **Referenced**: 1

## c:medline

`(c:medline / conent conpt conqty xdlist contag cltp ptprompt)`  - line 61-79

Plain polyline on the current MED linetype/layer (wiring diagrams). User entry: [MEDLINE](../command-reference.md#medline).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `PLINE`
- **Referenced**: 1

## c:2line

`(c:2line)`  - line 80-102

Double / triple line: offsets a polyline by _2LINOFF / _3LINOFF. User entry: [2LINE](../command-reference.md#2line).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `cltp`, `ptprompt`, `offpt`; AutoCAD commands: `OFFSET`, `PLINE`
- **Referenced**: 1

## c:3line

`(c:3line)`  - line 104-129

Double / triple line: offsets a polyline by _2LINOFF / _3LINOFF. User entry: [3LINE](../command-reference.md#3line).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `cltp`, `ptprompt`, `offpt`; AutoCAD commands: `OFFSET`, `PLINE`
- **Referenced**: 1

