# MEDCBGrid.lsp

`tests\autocad\MEDCBGrid.lsp` - Test: MEDCBGRID fitting-matrix grid (tests\autocad, APPLOAD manually).

**Not loaded by MEDCore.** APPLOAD it to use it. 16 defun(s): 1 command(s), 15 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 32 | [`mcbg-mirrored-q`](#mcbg-mirrored-q) | function |
| 37 | [`mcbg-scale`](#mcbg-scale) | function |
| 48 | [`mcbg-split`](#mcbg-split) | function |
| 54 | [`mcbg-csv-line`](#mcbg-csv-line) | function |
| 65 | [`mcbg-csv`](#mcbg-csv) | function |
| 78 | [`mcbg-get`](#mcbg-get) | function |
| 81 | [`mcbg-dir`](#mcbg-dir) | function |
| 82 | [`mcbg-brk`](#mcbg-brk) | function |
| 83 | [`mcbg-pt`](#mcbg-pt) | function |
| 88 | [`mcbg-conduit`](#mcbg-conduit) | function |
| 99 | [`mcbg-legs`](#mcbg-legs) | function |
| 119 | [`mcbg-text`](#mcbg-text) | function |
| 126 | [`mcbg-fitting`](#mcbg-fitting) | function |
| 148 | [`mcbg-reduce-to`](#mcbg-reduce-to) | function |
| 155 | [`c:MEDCBGRID`](#cmedcbgrid) | command |
| 173 | [`get_con_dist`](#get_con_dist) | function |

## mcbg-mirrored-q

`(mcbg-mirrored-q e / ed)`  - line 32-36

MEDCBGRID: T if the insert's plan symbol is mirrored (same rule as MEDMAKE3D).

- **Arguments**: `e`
- **Returns**: value of the last expression: `(if medcb-mirrored-p (if (medcb-mirrored-p ed) T) (< (* (cdr (assoc 41 ed)) (cdr (assoc 42 ed)) (caddr (cond (...`
- **Referenced**: 1

## mcbg-scale

`(mcbg-scale / sc)`  - line 37-46

MEDCBGRID: drawing scale (USERR1/DIMSCALE, asks when 1).

- **Arguments**: none
- **Returns**: value of the last expression: `sc`
- **Side effects**: Globals set (not declared local): `_SC`
- **Referenced**: 1

## mcbg-split

`(mcbg-split s d / r i)`  - line 48-51

MEDCBGRID: split a string.

- **Arguments**: `s`, `d`
- **Returns**: value of the last expression: `(reverse (cons s r))`
- **Referenced**: 2

## mcbg-csv-line

`(mcbg-csv-line l / r cur i c q n)`  - line 54-64

one CSV line -> fields ("..." quoting with "" escapes, as Python's csv writes)

- **Arguments**: `l`
- **Returns**: value of the last expression: `(reverse (cons cur r))`
- **Referenced**: 1

## mcbg-csv

`(mcbg-csv / f p l hdr rows)`  - line 65-77

MEDCBGRID: reads fitting_matrix.csv.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (and p (setq f (open p "r"))) (progn (setq hdr (mapcar 'strcase (mcbg-split (vl-string-trim "\r\n" (read-l...`
- **Referenced**: 1

## mcbg-get

`(mcbg-get k row)`  - line 78-78

MEDCBGRID: alist lookup.

- **Arguments**: `k`, `row`
- **Returns**: value of the last expression: `(cdr (assoc k row))`
- **Referenced**: 24

## mcbg-dir

`(mcbg-dir tok)`  - line 81-81

MEDCBGRID: unit direction for a leg token (+X +Y -X -Y).

- **Arguments**: `tok`
- **Returns**: value of the last expression: `(cdr (assoc tok '(("+X" 1.0 0.0) ("+Y" 0.0 1.0) ("-X" -1.0 0.0) ("-Y" 0.0 -1.0))))`
- **Referenced**: 11

## mcbg-brk

`(mcbg-brk tok brk)`  - line 82-82

MEDCBGRID: break distance for a leg token.

- **Arguments**: `tok`, `brk`
- **Returns**: value of the last expression: `(nth (cdr (assoc tok '(("+X" . 0) ("+Y" . 1) ("-X" . 2) ("-Y" . 3)))) brk)`
- **Referenced**: 5

## mcbg-pt

`(mcbg-pt o d s rot / x y)`  - line 83-85

MEDCBGRID: rotated cell point.

- **Arguments**: `o`, `d`, `s`, `rot`
- **Returns**: value of the last expression: `(list (+ (car o) (- (* x (cos rot)) (* y (sin rot)))) (+ (cadr o) (+ (* x (sin rot)) (* y (cos rot)))) 0.0)`
- **Referenced**: 6

## mcbg-conduit

`(mcbg-conduit pts / ed e)`  - line 88-96

one MED conduit polyline through pts (WCS, Z 0), xdata as the CONDUIT command

- **Arguments**: `pts`
- **Returns**: value of the last expression: `(if (entmake ed) (progn (setq e (entlast)) (xdatadd e (bld_conduit 1 _CSIZE "NONE" nil "T")) e))`
- **Side effects**: Xdata: writes xdata; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 3

## mcbg-legs

`(mcbg-legs legs brk o rot len / ends tok ax a b out d1 d2)`  - line 99-117

conduit legs of one row around origin o; returns the conduit enames

- **Arguments**: `legs`, `brk`, `o`, `rot`, `len`
- **Returns**: value of the last expression: `(vl-remove nil out)`
- **Referenced**: 1

## mcbg-text

`(mcbg-text p h s)`  - line 119-120

MEDCBGRID: label text.

- **Arguments**: `p`, `h`, `s`
- **Returns**: value of the last expression: `(entmake (list '(0 . "TEXT") (cons 8 "MED_CBGRID") (cons 10 p) (cons 40 h) (cons 1 s) '(7 . "STANDARD")))`
- **Side effects**: Xdata: `MED_CBGRID`; Entities: `entmake`
- **Referenced**: 3

## mcbg-fitting

`(mcbg-fitting blk code instype o rotdeg cnds mir / path e ss ed g)`  - line 126-144

the 2D symbol + fitting xdata the way C:MEDBlockInsert / ifitt_ins / dcon_ins do always inserted at +_SC (as C:MEDBlockInsert: insert name pt _SC _SC rot); the Scale option works for uniform-scale blocks too. mir "X" / "Y" (M39 / M40 test cells only) then negates that one scale factor to fake a user MIRROR.

- **Arguments**: `blk`, `code`, `instype`, `o`, `rotdeg`, `cnds`, `mir`
- **Returns**: value of the last expression: `(if path (progn ;; file path only the first time (else AutoCAD asks to redefine the block) (command "_.-INSERT...`
- **Side effects**: Globals set (not declared local): `RL_SS`, `RL_SS_DATA`, `_FITTCODE`, `_TAGSUPRESS`; Entities: `entmod`; AutoCAD commands: `-INSERT`
- **Referenced**: 1

## mcbg-reduce-to

`(mcbg-reduce-to e code / xd sz alt)`  - line 148-153

reducer: reduce-to size = one trade size below the fitting size, written as the fitting's ALT value the way refitt_ins does (bld_fitting code size tag alt ...)

- **Arguments**: `e`, `code`
- **Returns**: value of the last expression: `(if (numberp sz) (progn (foreach x '(0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 5.0) (if (< x (- sz 1e-6)) (set...`
- **Side effects**: Xdata: writes xdata, reads xdata
- **Referenced**: 1

## c:MEDCBGRID

`(c:MEDCBGRID / sc f pos bad rows base rotall s len cols i row o brk cnds e h old oldtag oldcm oldos oldat oldcsz oldfc cnt miss err)`  - line 155-213

Draws every 2D fitting-symbol matrix row (fitting_matrix.csv) for a MEDMAKE3D check (tests\autocad\MEDCBGrid.lsp). User entry: [MEDCBGRID](../command-reference.md#medcbgrid).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `_CSIZE`, `_MEDDIST`, `_TAGOFF`, `get_con_dist`, `_FITTCODE`, `RL_SS`, `RL_SS_DATA`; Xdata: `MED_CBGRID`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 0

## get_con_dist

`(get_con_dist spt condir)`  - line 173-173 (nested defun)

MEDCBGRID stub that answers the menu's up/down length and tag prompts (overrides medinser.lsp get_con_dist while the grid runs).

- **Arguments**: `spt`, `condir`
- **Returns**: value of the last expression: `36.0`
- **Side effects**: Globals set (not declared local): `_MEDDIST`
- **Referenced**: 6
- **Duplicate**: also defined in Support\medinser.lsp:276; replaced at load time by Support\medinser.lsp:276

