# MED3DFittings.lsp

`Support\MED3DFittings.lsp` - 3D rigid conduit bodies (Condulet) and inline fittings: data, geometry builders, blocks, MEDMAKE3D placement.

Loaded by MEDCore (order 26). 131 defun(s): 5 command(s), 126 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 135 | [`medcb-v+`](#medcb-v) | function |
| 136 | [`medcb-vx`](#medcb-vx) | function |
| 137 | [`medcb-get`](#medcb-get) | function |
| 138 | [`medcb-num`](#medcb-num) | function |
| 141 | [`medcb-pad2`](#medcb-pad2) | function |
| 145 | [`medcb-size-tag`](#medcb-size-tag) | function |
| 152 | [`medcb-sz1`](#medcb-sz1) | function |
| 153 | [`medcb-block-name`](#medcb-block-name) | function |
| 155 | [`medcb-ph-name`](#medcb-ph-name) | function |
| 158 | [`medcb-frac`](#medcb-frac) | function |
| 163 | [`medcb-parse-size`](#medcb-parse-size) | function |
| 172 | [`medcb-size-text`](#medcb-size-text) | function |
| 182 | [`medcb-size-down`](#medcb-size-down) | function |
| 189 | [`medcb-row`](#medcb-row) | function |
| 195 | [`medcb-row-key`](#medcb-row-key) | function |
| 197 | [`medcb-need`](#medcb-need) | function |
| 202 | [`medcb-row-ok`](#medcb-row-ok) | function |
| 208 | [`medcb-csv-split`](#medcb-csv-split) | function |
| 222 | [`medcb-index`](#medcb-index) | function |
| 228 | [`medcb-seed-path`](#medcb-seed-path) | function |
| 235 | [`medcb-csv-path`](#medcb-csv-path) | function |
| 237 | [`medcb-read-csv`](#medcb-read-csv) | function |
| 258 | [`medcb-sql`](#medcb-sql) | function |
| 268 | [`medcb-db-kind`](#medcb-db-kind) | function |
| 284 | [`medcb-db-has-table`](#medcb-db-has-table) | function |
| 289 | [`medcb-read-db`](#medcb-read-db) | function |
| 299 | [`medcb-load-data`](#medcb-load-data) | function |
| 307 | [`medcb-find`](#medcb-find) | function |
| 313 | [`medcb-conduit-od`](#medcb-conduit-od) | function |
| 322 | [`medcb-cod`](#medcb-cod) | function |
| 330 | [`medcb-hub`](#medcb-hub) | function |
| 338 | [`medcb-geom`](#medcb-geom) | function |
| 351 | [`medcb-geom-wh`](#medcb-geom-wh) | function |
| 395 | [`medcb-p`](#medcb-p) | function |
| 396 | [`medcb-h`](#medcb-h) | function |
| 397 | [`medcb-prims-geom`](#medcb-prims-geom) | function |
| 400 | [`medcb-hod2`](#medcb-hod2) | function |
| 410 | [`medcb-geom-lby`](#medcb-geom-lby) | function |
| 442 | [`medcb-gua-ref`](#medcb-gua-ref) | function |
| 444 | [`medcb-geom-gua`](#medcb-geom-gua) | function |
| 481 | [`medcb-geom-bub`](#medcb-geom-bub) | function |
| 498 | [`medcb-geom-uny`](#medcb-geom-uny) | function |
| 539 | [`medcb-rim-rmax`](#medcb-rim-rmax) | function |
| 544 | [`medcb-geom-seal`](#medcb-geom-seal) | function |
| 605 | [`medcb-mx`](#medcb-mx) | function |
| 606 | [`medcb-mirror-x`](#medcb-mirror-x) | function |
| 614 | [`medcb-geom-plug`](#medcb-geom-plug) | function |
| 627 | [`medcb-geom-hub`](#medcb-geom-hub) | function |
| 647 | [`medcb-geom-re`](#medcb-geom-re) | function |
| 660 | [`medcb-geom-ph`](#medcb-geom-ph) | function |
| 678 | [`medcb-real-geom`](#medcb-real-geom) | function |
| 704 | [`medcb-geom-for`](#medcb-geom-for) | function |
| 708 | [`medcb-hubs`](#medcb-hubs) | function |
| 711 | [`medcb-doc`](#medcb-doc) | function |
| 712 | [`medcb-ok`](#medcb-ok) | function |
| 713 | [`medcb-union`](#medcb-union) | function |
| 716 | [`medcb-subtract`](#medcb-subtract) | function |
| 721 | [`medcb-add-slot`](#medcb-add-slot) | function |
| 737 | [`medcb-add-cyl`](#medcb-add-cyl) | function |
| 745 | [`medcb-orient`](#medcb-orient) | function |
| 759 | [`medcb-add-prism`](#medcb-add-prism) | function |
| 779 | [`medcb-flag-layer`](#medcb-flag-layer) | function |
| 788 | [`medcb-body-layer`](#medcb-body-layer) | function |
| 801 | [`medcb-bylayer`](#medcb-bylayer) | function |
| 805 | [`medcb-bylayer-props`](#medcb-bylayer-props) | function |
| 812 | [`medcb-add-box`](#medcb-add-box) | function |
| 817 | [`medcb-name-shape`](#medcb-name-shape) | function |
| 825 | [`medcb-tag-for`](#medcb-tag-for) | function |
| 827 | [`medcb-suffix-for`](#medcb-suffix-for) | function |
| 831 | [`medcb-build-block`](#medcb-build-block) | function |
| 867 | [`medcb-stale-rename`](#medcb-stale-rename) | function |
| 881 | [`medcb-block-current`](#medcb-block-current) | function |
| 887 | [`medcb-ensure-block`](#medcb-ensure-block) | function |
| 899 | [`medcb-insert`](#medcb-insert) | function |
| 907 | [`medcb-tilt`](#medcb-tilt) | function |
| 908 | [`medcb-insert-block`](#medcb-insert-block) | function |
| 922 | [`medcb-join`](#medcb-join) | function |
| 926 | [`medcb-ask-shape`](#medcb-ask-shape) | function |
| 932 | [`medcb-shape-forms`](#medcb-shape-forms) | function |
| 939 | [`medcb-ask-form`](#medcb-ask-form) | function |
| 949 | [`medcb-ask-size`](#medcb-ask-size) | function |
| 955 | [`medcb-say`](#medcb-say) | function |
| 959 | [`medcb-begin`](#medcb-begin) | function |
| 963 | [`*error*`](#error) | function |
| 967 | [`medcb-end`](#medcb-end) | function |
| 971 | [`c:MEDCBINS`](#cmedcbins) | command |
| 988 | [`medcb-text`](#medcb-text) | function |
| 992 | [`c:MEDCBTEST`](#cmedcbtest) | command |
| 1020 | [`c:MEDCBALL`](#cmedcball) | command |
| 1048 | [`medcb-prims-ext`](#medcb-prims-ext) | function |
| 1061 | [`medcb-geom-xrange`](#medcb-geom-xrange) | function |
| 1071 | [`medcb-geom-width`](#medcb-geom-width) | function |
| 1081 | [`c:MEDCBDATA`](#cmedcbdata) | command |
| 1095 | [`c:MEDCBVER`](#cmedcbver) | command |
| 1164 | [`medcb-dot`](#medcb-dot) | function |
| 1165 | [`medcb-unit`](#medcb-unit) | function |
| 1168 | [`medcb-dxy`](#medcb-dxy) | function |
| 1169 | [`medcb-app`](#medcb-app) | function |
| 1172 | [`medcb-int`](#medcb-int) | function |
| 1175 | [`medcb-str`](#medcb-str) | function |
| 1176 | [`medcb-split`](#medcb-split) | function |
| 1181 | [`medcb-clean`](#medcb-clean) | function |
| 1190 | [`medcb-key-parse`](#medcb-key-parse) | function |
| 1196 | [`medcb-desc-key`](#medcb-desc-key) | function |
| 1209 | [`medcb-read-keys-csv`](#medcb-read-keys-csv) | function |
| 1224 | [`medcb-fitcat`](#medcb-fitcat) | function |
| 1238 | [`medcb-keys-csv`](#medcb-keys-csv) | function |
| 1245 | [`medcb-resolve-code`](#medcb-resolve-code) | function |
| 1262 | [`medcb-2d-offset`](#medcb-2d-offset) | function |
| 1272 | [`medcb-xdir`](#medcb-xdir) | function |
| 1278 | [`medcb-wcs-hubs`](#medcb-wcs-hubs) | function |
| 1281 | [`medcb-cos-tol`](#medcb-cos-tol) | function |
| 1282 | [`medcb-fit-tol`](#medcb-fit-tol) | function |
| 1284 | [`medcb-score`](#medcb-score) | function |
| 1295 | [`medcb-seg-param`](#medcb-seg-param) | function |
| 1303 | [`medcb-legs`](#medcb-legs) | function |
| 1328 | [`medcb-conduit-runs`](#medcb-conduit-runs) | function |
| 1339 | [`medcb-mirrored-p`](#medcb-mirrored-p) | function |
| 1346 | [`medcb-alt-tilts`](#medcb-alt-tilts) | function |
| 1355 | [`medcb-brk-max`](#medcb-brk-max) | function |
| 1367 | [`medcb-brk-list`](#medcb-brk-list) | function |
| 1376 | [`medcb-hub-tols`](#medcb-hub-tols) | function |
| 1387 | [`medcb-brk-tol`](#medcb-brk-tol) | function |
| 1391 | [`medcb-body-of`](#medcb-body-of) | function |
| 1480 | [`medcb-collect`](#medcb-collect) | function |
| 1506 | [`medcb-fit-rec`](#medcb-fit-rec) | function |
| 1511 | [`medcb-ensure-ph`](#medcb-ensure-ph) | function |
| 1516 | [`medcb-ensure-body`](#medcb-ensure-body) | function |
| 1527 | [`medcb-vert-data`](#medcb-vert-data) | function |
| 1535 | [`medcb-vert-leg`](#medcb-vert-leg) | function |
| 1560 | [`medcb-place-all`](#medcb-place-all) | function |

## medcb-v+

`(medcb-v+ a b)`  - line 135-135

------------------------------------------------------------- small helpers

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(mapcar '+ a b)`
- **Referenced**: 19

## medcb-vx

`(medcb-vx v s)`  - line 136-136

Scale a vector.

- **Arguments**: `v`, `s`
- **Returns**: value of the last expression: `(mapcar '(lambda (x) (* x s)) v)`
- **Referenced**: 25

## medcb-get

`(medcb-get key alist)`  - line 137-137

Alist lookup (cdr assoc).

- **Arguments**: `key`, `alist`
- **Returns**: value of the last expression: `(cdr (assoc key alist))`
- **Referenced**: 91

## medcb-num

`(medcb-num v / r)`  - line 138-140

Positive number or nil from a value/string.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(if (and r (> r 0.0)) r)`
- **Referenced**: 11

## medcb-pad2

`(medcb-pad2 n)`  - line 141-141

Two-character number string.

- **Arguments**: `n`
- **Returns**: value of the last expression: `(if (< n 10) (strcat "0" (itoa n)) (itoa n))`
- **Referenced**: 1

## medcb-size-tag

`(medcb-size-tag sz / n)`  - line 145-150

1.0 -> "1-00", 0.5 -> "0-50", 1.25 -> "1-25" (no RTOS: DIMZIN would strip zeros); a reducer's (large small) size list -> "1-00X0-75"

- **Arguments**: `sz`
- **Returns**: value of the last expression: `(if (listp sz) (strcat (medcb-size-tag (car sz)) "X" (medcb-size-tag (cadr sz))) (progn (setq n (fix (+ (* (fl...`
- **Referenced**: 5

## medcb-sz1

`(medcb-sz1 sz)`  - line 152-152

first (large) size of a size or (large small) list

- **Arguments**: `sz`
- **Returns**: value of the last expression: `(if (listp sz) (car sz) sz)`
- **Referenced**: 14

## medcb-block-name

`(medcb-block-name form shape sz)`  - line 153-154

Block name MED_CB_RGD_<form>_<shape>_<size>.

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(strcat "MED_CB_RGD_" (strcase form) "_" (strcase shape) "_" (medcb-size-tag sz))`
- **Side effects**: Xdata: `MED_CB_RGD_`
- **Referenced**: 3

## medcb-ph-name

`(medcb-ph-name form shape sz)`  - line 155-155

Placeholder block name (<name>_PH).

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(strcat (medcb-block-name form shape sz) "_PH")`
- **Referenced**: 2

## medcb-frac

`(medcb-frac s / k)`  - line 158-162

trade size text -> inches: "1/2" "3/4" "1" "1-1/4" "1 1/4" "1.25" (or a number)

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (setq k (vl-string-search "/" s)) (if (> (atof (substr s (+ k 2))) 0.0) (/ (atof (substr s 1 k)) (atof (su...`
- **Referenced**: 2

## medcb-parse-size

`(medcb-parse-size s / k r)`  - line 163-171

Parses a trade size string (1-1/4, 3/4) to a number.

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (and r (> r 0.0)) r)`
- **Referenced**: 2

## medcb-size-text

`(medcb-size-text sz / w f n)`  - line 172-179

Trade size (or reducer pair) to text.

- **Arguments**: `sz`
- **Returns**: value of the last expression: `(if (listp sz) (strcat (medcb-size-text (car sz)) " x " (medcb-size-text (cadr sz))) (progn (setq n (fix (+ (*...`
- **Referenced**: 10

## medcb-size-down

`(medcb-size-down sz / r)`  - line 182-184

Next smaller trade size.

- **Arguments**: `sz`
- **Returns**: value of the last expression: `r`
- **Referenced**: 4

## medcb-row

`(medcb-row form shape sz a b c d e hod hl cat from)`  - line 189-194

---------------------------------------------------------------------- data row: (("FORM" . "F7") ("SHAPE" . "LB") ("SIZE" . 1.0) ("A" . a) ("B" . b) ("C" . c) ("D" . d) ("E" . e) ("HUBOD" . x|nil) ("HUBLEN" . x|nil) ("CATNO" . s) ("FROM" . "DB"|"CSV"))

- **Arguments**: `form`, `shape`, `sz`, `a`, `b`, `c`, `d`, `e`, `hod`, `hl`, `cat`, `from`
- **Returns**: value of the last expression: `(list (cons "FORM" (strcase form)) (cons "SHAPE" (strcase shape)) (cons "SIZE" sz) (cons "A" (medcb-num a)) (c...`
- **Referenced**: 2

## medcb-row-key

`(medcb-row-key r)`  - line 195-195

Key (form shape size) of a data row.

- **Arguments**: `r`
- **Returns**: value of the last expression: `(list (medcb-get "FORM" r) (medcb-get "SHAPE" r) (medcb-size-tag (medcb-get "SIZE" r)))`
- **Referenced**: 3

## medcb-need

`(medcb-need shape)`  - line 197-201

letters a row needs to build its shape (the others are optional)

- **Arguments**: `shape`
- **Returns**: value of the last expression: `(cond ((member shape '("LBY" "UNY" "EYS" "EYD" "CPL")) '("A" "B")) ((member shape '("PLGR")) '("A" "B" "C")) (...`
- **Referenced**: 1

## medcb-row-ok

`(medcb-row-ok r / ok)`  - line 202-205

T when a data row has the dimensions a body needs.

- **Arguments**: `r`
- **Returns**: value of the last expression: `ok`
- **Referenced**: 3

## medcb-csv-split

`(medcb-csv-split line n / i len ch q cur out)`  - line 208-221

CSV line -> fields (quotes, doubled quotes); stops after n fields when n is given

- **Arguments**: `line`, `n`
- **Returns**: value of the last expression: `(reverse out)`
- **Referenced**: 4

## medcb-index

`(medcb-index name lst / i r)`  - line 222-225

Index of a name in a list.

- **Arguments**: `name`, `lst`
- **Returns**: value of the last expression: `r`
- **Referenced**: 2

## medcb-seed-path

`(medcb-seed-path name / here c r)`  - line 228-234

Data\seed\<name>: support path, else ..\Data\seed or Data\seed next to this file

- **Arguments**: `name`
- **Returns**: value of the last expression: `r`
- **Referenced**: 3

## medcb-csv-path

`(medcb-csv-path)`  - line 235-235

Path of conduit_body_dims.csv (Data\seed).

- **Arguments**: none
- **Returns**: value of the last expression: `(medcb-seed-path *MEDCB-CSV*)`
- **Referenced**: 5

## medcb-read-csv

`(medcb-read-csv path / f line hdr cols rows fl ix)`  - line 237-255

Reads conduit_body_dims.csv into rows.

- **Arguments**: `path`
- **Returns**: value of the last expression: `(if (and path (setq f (open path "r"))) (progn (if (setq line (read-line f)) (progn (setq hdr (medcb-csv-split...`
- **Referenced**: 1

## medcb-sql

`(medcb-sql sql / old res)`  - line 258-264

SELECT through MED-DotNet, quiet; nil when MED-DotNet / the table is not there

- **Arguments**: `sql`
- **Returns**: value of the last expression: `(if (and MED-DotNet-Ready (MED-DotNet-Ready) MEDProcessSQLStatement) (progn (setq old *MED-SQL-QUIET* *MED-SQL...`
- **Side effects**: Globals set (not declared local): `*MED-SQL-QUIET*`
- **Referenced**: 4

## medcb-db-kind

`(medcb-db-kind / p f line k v prov cs)`  - line 268-281

"SQLITE" / "SQLSERVER" / nil, from MEDDataBaseSettings.dat the way MED-DotNet reads it (Provider=..., else ConnectString with Data Source=... .db = SQLite)

- **Arguments**: none
- **Returns**: value of the last expression: `(if (and (setq p (findfile "MEDDataBaseSettings.dat")) (setq f (open p "r"))) (progn (while (setq line (read-l...`
- **Referenced**: 1

## medcb-db-has-table

`(medcb-db-has-table / kind)`  - line 284-288

T when MEDConduitBody exists (asked through the catalog, so a missing table never makes MED-DotNet print an SQL error)

- **Arguments**: none
- **Returns**: value of the last expression: `(cond ((= kind "SQLITE") (medcb-sql "SELECT name FROM sqlite_master WHERE type='table' AND name='MEDConduitBod...`
- **Side effects**: DB: `medcb-sql`
- **Referenced**: 1

## medcb-read-db

`(medcb-read-db / res rows)`  - line 289-296

Reads MEDConduitBody rows through SQL.

- **Arguments**: none
- **Returns**: value of the last expression: `(reverse rows)`
- **Side effects**: DB: `medcb-db-has-table`, `medcb-sql`
- **Referenced**: 1

## medcb-load-data

`(medcb-load-data force / db csv keys)`  - line 299-306

DB rows first (user edits win), CSV fills keys the DB does not have

- **Arguments**: `force`
- **Returns**: value of the last expression: `(vl-remove nil *MEDCB-DATA*)`
- **Side effects**: Globals set (not declared local): `*MEDCB-DATA*`; DB: `medcb-read-db`
- **Referenced**: 4

## medcb-find

`(medcb-find form shape sz / key r)`  - line 307-310

Data row for form, shape, size.

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `r`
- **Referenced**: 2

## medcb-conduit-od

`(medcb-conduit-od sz / r)`  - line 313-317

rigid steel conduit OD (MEDConduitOD code 1) when MEDFunctions is loaded

- **Arguments**: `sz`
- **Returns**: value of the last expression: `(if med_conduit_od (progn (setq r (vl-catch-all-apply 'med_conduit_od (list 1 sz))) (if (and (numberp r) (> r ...`
- **Referenced**: 7

## medcb-cod

`(medcb-cod sz / r)`  - line 322-326

Conduit OD for a trade size (DB, else ANSI C80.1 table).

- **Arguments**: `sz`
- **Returns**: value of the last expression: `(cond ((medcb-conduit-od sz)) (T (foreach x *MEDCB-C80* (if (and (not r) (equal (car x) sz 1e-6)) (setq r (cdr...`
- **Referenced**: 6

## medcb-hub

`(medcb-hub name face dir len)`  - line 330-332

------------------------------------------------------------ geometry (pure) adds one hub to medcb-geom's hubs / cyls (dynamic scope: hubs cyls ov hub)

- **Arguments**: `name`, `face`, `dir`, `len`
- **Returns**: value of the last expression: `(setq hubs (cons (list name face dir) hubs) cyls (cons (list (medcb-v+ face (medcb-vx dir (- (+ len ov)))) fac...`
- **Side effects**: Globals set (not declared local): `hubs`, `cyls`
- **Referenced**: 7

## medcb-geom

`(medcb-geom shape a b c d e hod hl cod / w h g k)`  - line 338-350

Returns alist: SHAPE W H M DOPEN LBODY HUBOD RUNLEN SIDELEN NOTE SHORT, ("BODY" cx len width z0 z1)  slot (round ends) along X centred at (cx,0) ("COVER" cx len width z0 z1) slot ("CYLS" (p0 p1 r) ...)       hub cylinders (axis-aligned, p1 = hub face) ("HUBS" (name face dir) ...)

- **Arguments**: `shape`, `a`, `b`, `c`, `d`, `e`, `hod`, `hl`, `cod`
- **Returns**: value of the last expression: `g`
- **Referenced**: 6

## medcb-geom-wh

`(medcb-geom-wh shape a b c d e hod hl cod w h note / dp m t0 hub minh n lb cx rl sl ov hubs cyls ell short)`  - line 351-381

Geometry alist from W/H body and hubs.

- **Arguments**: `shape`, `a`, `b`, `c`, `d`, `e`, `hod`, `hl`, `cod`, `w`, `h`, `note`
- **Returns**: value of the last expression: `(list (cons "SHAPE" shape) (cons "W" w) (cons "H" h) (cons "M" m) (cons "DOPEN" dp) (cons "LBODY" lb) (cons "H...`
- **Referenced**: 3

## medcb-p

`(medcb-p prim)`  - line 395-395

---------------------------------------------- phase 2 builders (r6, pure) Primitive geometry: ("PRIMS" prim ...) with prim ("CYL" role p0 p1 r)      cylinder p0 -> p1 (any direction) ("PRISM" role p0 p1 rc n) regular n-gon prism p0 -> p1, corner radius rc (r7: 4 = square drive recess, 6 = hex nut) ("BOX" role pmin ...

- **Arguments**: `prim`
- **Returns**: value of the last expression: `(setq prims (cons prim prims))`
- **Side effects**: Globals set (not declared local): `prims`
- **Referenced**: 46

## medcb-h

`(medcb-h name face dir)`  - line 396-396

Adds a hub (name face direction) inside a builder.

- **Arguments**: `name`, `face`, `dir`
- **Returns**: value of the last expression: `(setq hubs (cons (list name face dir) hubs))`
- **Side effects**: Globals set (not declared local): `hubs`
- **Referenced**: 13

## medcb-prims-geom

`(medcb-prims-geom shape note)`  - line 397-398

Geometry alist from primitives and hubs.

- **Arguments**: `shape`, `note`
- **Returns**: value of the last expression: `(list (cons "SHAPE" shape) (cons "NOTE" note) (cons "PRIMS" (reverse prims)) (cons "HUBS" (reverse hubs)))`
- **Referenced**: 9

## medcb-hod2

`(medcb-hod2 hod sz lim)`  - line 400-401

hub OD of the phase 2 builders: table value, else 1.15 x rigid conduit OD, at most lim

- **Arguments**: `hod`, `sz`, `lim`
- **Returns**: value of the last expression: `(cond (hod hod) (lim (min lim (* 1.15 (medcb-cod sz)))) (T (* 1.15 (medcb-cod sz))))`
- **Referenced**: 3

## medcb-geom-lby

`(medcb-geom-lby a b hod sz / prims hubs hub hc f n t0 note)`  - line 410-421

LBY (Crouse-Hinds, a b only): LB orientation (RUN +X, BACK -Z), legs symmetrical, round cover on the 45 deg outside corner (normal (-1,0,1)/sqrt2). Published a = overall (back of the body to a hub face, both legs), b = body / cover diameter. Derived: body = round can on the cover axis, cover face 0.55 x hub OD past ...

- **Arguments**: `a`, `b`, `hod`, `sz`
- **Returns**: value of the last expression: `(medcb-prims-geom "LBY" note)`
- **Referenced**: 2

## medcb-gua-ref

`(medcb-gua-ref a / r)`  - line 442-443

GUA reference dimensions (Clint DWG table) for a size.

- **Arguments**: `a`
- **Returns**: value of the last expression: `r`
- **Referenced**: 1

## medcb-geom-gua

`(medcb-geom-gua shape a b c d e hod hl sz / prims hubs hub z0 z1 t0 rc ov k dirs ref th rb)`  - line 444-474

GUAL/GUAT/GUAX geometry.

- **Arguments**: `shape`, `a`, `b`, `c`, `d`, `e`, `hod`, `hl`, `sz`
- **Returns**: value of the last expression: `(medcb-prims-geom shape nil)`
- **Referenced**: 1

## medcb-geom-bub

`(medcb-geom-bub a b c d e hod sz / prims hubs hub r w dp m xf zt hb sz0 sx ov lb t0 u)`  - line 481-495

Mogul BUB (a overall length, b overall height, c width, d x e cover opening): slot body with the cover up, two hubs 45 deg down and out at the ends. Origin = midpoint of the hub face centres (the conduit elevation), faces at +/-xf where the face rims reach A/2. The planner gets horizontal +/-X hub directions at the ...

- **Arguments**: `a`, `b`, `c`, `d`, `e`, `hod`, `sz`
- **Returns**: value of the last expression: `(medcb-prims-geom "BUB" "hubs 45 deg down; conduit joined horizontally at the hub faces")`
- **Referenced**: 1

## medcb-geom-uny

`(medcb-geom-uny a b / prims hubs l3)`  - line 498-505

UNY union (A length, B max dia): two ends 0.85 B, centre nut B; RUN faces +/-A/2

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(medcb-prims-geom "UNY" nil)`
- **Referenced**: 1

## medcb-rim-rmax

`(medcb-rim-rmax c w r / cz k den ts)`  - line 539-543

farthest distance from the X axis of a circle (centre c, unit normal w, radius r), for c and w in the XZ plane (every seal part): points c + r(t e1 + sqrt(1-t^2) Y)

- **Arguments**: `c`, `w`, `r`
- **Returns**: value of the last expression: `(if (<= den 1e-12) (+ cz k) (progn (setq ts (/ (* cz k) den)) (if (>= ts 1.0) (+ cz k) (sqrt (+ (* r r) (* cz ...`
- **Referenced**: 2

## medcb-geom-seal

`(medcb-geom-seal shape a b tr hod sz / prims hubs r rt rr lr xp rp hp zp th u rs ls xs ct zt pl s2 x0 x1 lo hi n ecd pf dd q0 q1 rn)`  - line 544-603

EYS/EYD seal geometry.

- **Arguments**: `shape`, `a`, `b`, `tr`, `hod`, `sz`
- **Returns**: value of the last expression: `(medcb-prims-geom shape nil)`
- **Referenced**: 1

## medcb-mx

`(medcb-mx q)`  - line 605-605

x -> -x of a CYL / PRISM primitive (end points)

- **Arguments**: `q`
- **Returns**: value of the last expression: `(list (- (car q)) (cadr q) (caddr q))`
- **Referenced**: 2

## medcb-mirror-x

`(medcb-mirror-x pr)`  - line 606-609

Mirrors a primitive along X (EYD r12).

- **Arguments**: `pr`
- **Returns**: value of the last expression: `(if (member (car pr) '("CYL" "PRISM")) (append (list (car pr) (cadr pr) (medcb-mx (caddr pr)) (medcb-mx (caddd...`
- **Referenced**: 1

## medcb-geom-plug

`(medcb-geom-plug shape a b c d / prims hubs)`  - line 614-620

plugged coupling (approx; A coupling length, B coupling OD, PLGR C recess, PLGS C square head, D head height): the conduit end is at the origin, half-way into the coupling (x -A/2 .. A/2); plug at the -X end (recessed face / square head, second solid)

- **Arguments**: `shape`, `a`, `b`, `c`, `d`
- **Returns**: value of the last expression: `(medcb-prims-geom shape (strcat "approx: plugged coupling, " (if (= shape "PLGS") "square-head" "recessed") " ...`
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 1

## medcb-geom-hub

`(medcb-geom-hub form a b c d e / prims hubs wl nk lk)`  - line 627-641

conduit hub on an enclosure wall; the wall's outer face is x = 0, conduit from +X. CH (MHUB): a body length, b body dia, c bushed-nipple flange dia, d flange thickness, x (E) max wall - nipple through the wall, flange inside. RUN face (a,0,0). MYR (Myers ST): A overall, B body dia, C body height, D max wall, K (E) ...

- **Arguments**: `form`, `a`, `b`, `c`, `d`, `e`
- **Returns**: value of the last expression: `(medcb-prims-geom "HUB" nil)`
- **Referenced**: 1

## medcb-geom-re

`(medcb-geom-re a b c d sz / prims hubs s2 col tc)`  - line 647-655

reducer RE (approx; row of the large size A: A coupling length, B coupling OD, C head thickness, D head dia): recessed in the large-size coupling / hub (x -A..0), the head sticks out C, collar for the small size (hub OD of size 2) - RUN face (small end) +X, RUN2 face (large end) -X.

- **Arguments**: `a`, `b`, `c`, `d`, `sz`
- **Returns**: value of the last expression: `(medcb-prims-geom "RE" "approx: reducer head / coupling proportions (no published dimensions)")`
- **Referenced**: 2

## medcb-geom-ph

`(medcb-geom-ph shape sz cod / d0 l w h ell x0 x1 hubs)`  - line 660-674

Placeholder box geometry.

- **Arguments**: `shape`, `sz`, `cod`
- **Returns**: value of the last expression: `(list (cons "SHAPE" shape) (cons "PLACEHOLDER" T) (list "BOX" (list x0 (/ w -2.0) (/ h -2.0)) (list x1 (/ w 2....`
- **Referenced**: 4

## medcb-real-geom

`(medcb-real-geom form shape sz / r a b c d e hod hl cod g s1)`  - line 678-701

real geometry for form / shape / size from the data, nil when there is no usable row. sz = trade size, or (large small) for a reducer.

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(if (and (member shape *MEDCB-SHAPES*) (numberp s1) (> s1 0.0) (setq r (medcb-find form shape s1)) (medcb-row-...`
- **Referenced**: 2

## medcb-geom-for

`(medcb-geom-for form shape sz / g)`  - line 704-707

geometry for form/shape/size from the data (placeholder geometry when no row)

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(if (setq g (medcb-real-geom form shape sz)) g (medcb-geom-ph shape sz (medcb-conduit-od sz)))`
- **Referenced**: 5

## medcb-hubs

`(medcb-hubs form shape sz)`  - line 708-708

Hubs of a body in block coordinates ((name face dir) ...).

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(medcb-get "HUBS" (medcb-geom-for form shape sz))`
- **Referenced**: 1

## medcb-doc

`(medcb-doc)`  - line 711-711

------------------------------------------------------------------ drawing

- **Arguments**: none
- **Returns**: value of the last expression: `(vla-get-ActiveDocument (vlax-get-acad-object))`
- **Referenced**: 6

## medcb-ok

`(medcb-ok x)`  - line 712-712

T when an ActiveX result is not an error.

- **Arguments**: `x`
- **Returns**: value of the last expression: `(and x (not (vl-catch-all-error-p x)))`
- **Referenced**: 12

## medcb-union

`(medcb-union a b / r)`  - line 713-714

Boolean union of two solids.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(if (and a b) (progn (setq r (vl-catch-all-apply 'vlax-invoke (list a 'Boolean 0 b))) a) (if a a b))`
- **Referenced**: 5

## medcb-subtract

`(medcb-subtract a b)`  - line 716-718

a minus b (acSubtraction); b is deleted either way (a cut that misses leaves a as is)

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `a`
- **Referenced**: 2

## medcb-add-slot

`(medcb-add-slot blk cx len w z0 z1 / h zc s c1 c2 st)`  - line 721-734

slot (stadium) along X: box + 2 vertical cylinders, unioned

- **Arguments**: `blk`, `cx`, `len`, `w`, `z0`, `z1`
- **Returns**: value of the last expression: `(if (> st 1e-6) (progn (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddBox (list cx 0.0 zc) st w h)) c1...`
- **Referenced**: 3

## medcb-add-cyl

`(medcb-add-cyl blk p0 p1 r / len s)`  - line 737-742

cylinder p0 -> p1 (axis parallel to X, Y or Z; r6: any other direction too)

- **Arguments**: `blk`, `p0`, `p1`, `r`
- **Returns**: value of the last expression: `(if (> len 1e-6) (progn (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder '(0.0 0.0 0.0) r len))...`
- **Referenced**: 2

## medcb-orient

`(medcb-orient s p0 p1 / d len mid q)`  - line 745-755

a solid made along +Z, centred on the origin, turned onto p0 -> p1 and moved to the midpoint (Rotate3D about the origin, then Move)

- **Arguments**: `s`, `p0`, `p1`
- **Returns**: value of the last expression: `s`
- **Side effects**: Entities: `vlax-invoke`
- **Referenced**: 2

## medcb-add-prism

`(medcb-add-prism blk p0 p1 rc n / len pts i a pl rg s)`  - line 759-777

regular n-gon prism p0 -> p1, corner radius rc (r7: square drive recess n = 4, hex nut n = 6): closed LWPOLYLINE -> region -> extruded solid along +Z, centred, then oriented like a cylinder. The temporary polyline and region are deleted.

- **Arguments**: `blk`, `p0`, `p1`, `rc`, `n`
- **Returns**: value of the last expression: `(if (> len 1e-6) (progn (repeat n (setq a (+ (/ pi n) (* i (/ (* 2.0 pi) n))) pts (append pts (list (* rc (cos...`
- **Side effects**: Entities: `vlax-invoke`
- **Referenced**: 1

## medcb-flag-layer

`(medcb-flag-layer / info)`  - line 779-787

Ensures and returns MED_3DFLAG / MED_3DCONDUIT layer.

- **Arguments**: none
- **Returns**: value of the last expression: `(if med3d-ensure-layer (med3d-ensure-layer info) (progn (if (not (tblsearch "LAYER" (car info))) (entmake (lis...`
- **Side effects**: Xdata: `MED_3DFLAG`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 1

## medcb-body-layer

`(medcb-body-layer / info)`  - line 788-796

Ensures and returns MED_3DFLAG / MED_3DCONDUIT layer.

- **Arguments**: none
- **Returns**: value of the last expression: `(if med3d-ensure-layer (med3d-ensure-layer info) (progn (if (not (tblsearch "LAYER" (car info))) (entmake (lis...`
- **Side effects**: Xdata: `MED_3DCONDUIT`; Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 2

## medcb-bylayer

`(medcb-bylayer o)`  - line 801-803

Clint's block rule (r6): every entity of a generated block on layer 0 with colour, linetype and lineweight ByLayer - nothing hard-coded. The INSERT carries the layer (MED_3DCONDUIT, placeholders MED_3DFLAG).

- **Arguments**: `o`
- **Returns**: value of the last expression: `(medcb-bylayer-props o)`
- **Referenced**: 2

## medcb-bylayer-props

`(medcb-bylayer-props o)`  - line 805-811

colour / linetype / lineweight ByLayer (the layer is left alone)

- **Arguments**: `o`
- **Returns**: value of the last expression: `o`
- **Referenced**: 2

## medcb-add-box

`(medcb-add-box blk p0 p1 / s)`  - line 812-815

Adds a box solid to a block.

- **Arguments**: `blk`, `p0`, `p1`
- **Returns**: value of the last expression: `(if (medcb-ok s) s)`
- **Referenced**: 2

## medcb-name-shape

`(medcb-name-shape name / t0 i j)`  - line 817-823

shape of a block name MED_CB_RGD_<form>_<shape>_<size>[...] ("" when not ours)

- **Arguments**: `name`
- **Returns**: value of the last expression: `(if (and (= (type name) 'STR) (> (strlen name) (strlen t0)) (= (strcase (substr name 1 (strlen t0))) t0) (setq...`
- **Side effects**: Xdata: `MED_CB_RGD_`
- **Referenced**: 2

## medcb-tag-for

`(medcb-tag-for name / x)`  - line 825-826

geometry tag / stale suffix for a block name (per-shape revision, else global)

- **Arguments**: `name`
- **Returns**: value of the last expression: `(if (setq x (assoc (medcb-name-shape name) *MEDCB-SHAPE-TAGS*)) (cadr x) *MEDCB-GEOM-TAG*)`
- **Referenced**: 2

## medcb-suffix-for

`(medcb-suffix-for name / x)`  - line 827-828

Version tag suffix for a block name (*MEDCB-SHAPE-TAGS*).

- **Arguments**: `name`
- **Returns**: value of the last expression: `(if (setq x (assoc (medcb-name-shape name) *MEDCB-SHAPE-TAGS*)) (caddr x) *MEDCB-STALE-SUFFIX*)`
- **Referenced**: 2

## medcb-build-block

`(medcb-build-block name geom / blks blk body cov s bx pr cut cutc)`  - line 831-862

new block definition from geometry; nil (and no block left behind) on failure. Solids: body (+ hubs) unioned, cover / plug head / pour hub a second solid.

- **Arguments**: `name`, `geom`
- **Returns**: value of the last expression: `(if (medcb-ok blk) (progn (cond ((setq pr (medcb-get "PRIMS" geom)) (foreach x pr (setq s (cond ((= (car x) "C...`
- **Referenced**: 3

## medcb-stale-rename

`(medcb-stale-rename name / blk c new i)`  - line 867-879

a block made before r6 (older tag, see *MEDCB-GEOM-TAG*; EYS / EYD before r7, see *MEDCB-SHAPE-TAGS*): rename it to <name>_PRE_R6[_n] / _PRE_R7[_n] (its inserts keep the old block) so the name is free for a new definition. T when renamed. To drop the old ones: PURGE the _PRE_R* blocks once nothing references them.

- **Arguments**: `name`
- **Returns**: value of the last expression: `(if (and (medcb-ok blk) (setq c (vl-catch-all-apply 'vlax-get (list blk 'Comments))) (not (vl-catch-all-error-...`
- **Referenced**: 1

## medcb-block-current

`(medcb-block-current name)`  - line 881-882

T when the block name exists and is current (older ones are renamed first)

- **Arguments**: `name`
- **Returns**: value of the last expression: `(and (tblsearch "BLOCK" name) (not (medcb-stale-rename name)))`
- **Referenced**: 3

## medcb-ensure-block

`(medcb-ensure-block form shape sz / name r geom)`  - line 887-896

Block for form/shape/size, generated on demand. Returns (name status): "EXISTS" (already defined, left alone) "CREATED" "PLACEHOLDER" (no data, _PH made) "PH-EXISTS"; nil when the shape is unknown or the block could not be built.

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(cond ((not (member shape *MEDCB-SHAPES*)) nil) ((not (and (numberp (medcb-sz1 sz)) (> (medcb-sz1 sz) 0.0))) n...`
- **Referenced**: 3

## medcb-insert

`(medcb-insert form shape sz pt rot / res ref)`  - line 899-902

insert in model space; pt WCS; rot radians about WCS Z. Returns (vla-ref name status)

- **Arguments**: `form`, `shape`, `sz`, `pt`, `rot`
- **Returns**: value of the last expression: `(if (and (setq res (medcb-ensure-block form shape sz)) (setq ref (medcb-insert-block res pt rot nil))) (list r...`
- **Referenced**: 3

## medcb-tilt

`(medcb-tilt flip)`  - line 907-907

res = (name status) from medcb-ensure-block; flip = tilt about the body's own (rotated) X axis after the Z rotation: nil = none, T = 180 deg (turned over), a number = that angle in radians (+/- pi/2: LB back hub turned into the plan). Right-hand rule about X, as Rotate3D. Returns the vla reference or nil.

- **Arguments**: `flip`
- **Returns**: value of the last expression: `(cond ((numberp flip) flip) (flip pi) (T 0.0))`
- **Referenced**: 4

## medcb-insert-block

`(medcb-insert-block res pt rot flip / ref)`  - line 908-918

Inserts a block reference with rotation and tilt/flip.

- **Arguments**: `res`, `pt`, `rot`, `flip`
- **Returns**: value of the last expression: `(if (medcb-ok ref) (progn (if (/= (medcb-tilt flip) 0.0) (vl-catch-all-apply 'vlax-invoke (list ref 'Rotate3D ...`
- **Referenced**: 5

## medcb-join

`(medcb-join lst sep / r)`  - line 922-925

----------------------------------------------------------------- commands "A B C" / "A/B/C" from a list of strings

- **Arguments**: `lst`, `sep`
- **Returns**: value of the last expression: `r`
- **Referenced**: 4

## medcb-ask-shape

`(medcb-ask-shape / k)`  - line 926-930

MEDCBINS prompts (remembered in *MEDCB-SHAPE*/*MEDCB-FORM*/*MEDCB-SIZE*).

- **Arguments**: none
- **Returns**: value of the last expression: `*MEDCB-SHAPE*`
- **Side effects**: Globals set (not declared local): `*MEDCB-SHAPE*`
- **Referenced**: 1

## medcb-shape-forms

`(medcb-shape-forms shape / r)`  - line 932-938

forms with dimension rows for a shape (F7 / F8 / M9 for the classic bodies)

- **Arguments**: `shape`
- **Returns**: value of the last expression: `(cond ((member shape '("LB" "LR" "LL" "T" "TB" "C")) '("F7" "F8" "M9")) (r (reverse r)) (T '("F7")))`
- **Referenced**: 2

## medcb-ask-form

`(medcb-ask-form shape / k fl)`  - line 939-948

MEDCBINS prompts (remembered in *MEDCB-SHAPE*/*MEDCB-FORM*/*MEDCB-SIZE*).

- **Arguments**: `shape`
- **Returns**: value of the last expression: `*MEDCB-FORM*`
- **Side effects**: Globals set (not declared local): `*MEDCB-FORM*`
- **Referenced**: 2

## medcb-ask-size

`(medcb-ask-size / s v)`  - line 949-954

MEDCBINS prompts (remembered in *MEDCB-SHAPE*/*MEDCB-FORM*/*MEDCB-SIZE*).

- **Arguments**: none
- **Returns**: value of the last expression: `(setq *MEDCB-SIZE* v)`
- **Side effects**: Globals set (not declared local): `*MEDCB-SIZE*`
- **Referenced**: 3

## medcb-say

`(medcb-say res)`  - line 955-957

Prints the result of a block ensure/insert.

- **Arguments**: `res`
- **Returns**: printed text (message); value not meant to be used
- **Referenced**: 3

## medcb-begin

`(medcb-begin / doc)`  - line 959-966

Command start/end: error handler and sysvars.

- **Arguments**: none
- **Returns**: value of the last expression: `(defun *error* (msg) (if (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*")) (princ (strcat "\nMED3DFittin...`
- **Side effects**: Globals set (not declared local): `*MEDCB-OLDERR*`
- **Referenced**: 3

## *error*

`(*error* msg)`  - line 963-966 (nested defun)

MED3DFittings command error handler.

- **Arguments**: `msg`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DCON.lsp:135, Support\MED3DPath.lsp:1080, Support\MED3DTrayFunctions.lsp:468, Support\MEDFunctions.lsp:921, Support\MEDFunctions.lsp:2816; this definition loads last and wins

## medcb-end

`(medcb-end)`  - line 967-969

Command start/end: error handler and sysvars.

- **Arguments**: none
- **Returns**: value of the last expression: `(if *MEDCB-OLDERR* (setq *error* *MEDCB-OLDERR* *MEDCB-OLDERR* nil))`
- **Side effects**: Globals set (not declared local): `*error*`, `*MEDCB-OLDERR*`
- **Referenced**: 4

## c:MEDCBINS

`(c:MEDCBINS / shape form sz pt ang res)`  - line 971-986

Inserts one 3D conduit body (type, form, trade size) at picked points. User entry: [MEDCBINS](../command-reference.md#medcbins).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## medcb-text

`(medcb-text pt h s lay)`  - line 988-990

Entmakes a label TEXT.

- **Arguments**: `pt`, `h`, `s`, `lay`
- **Returns**: value of the last expression: `(entmake (list '(0 . "TEXT") (cons 8 lay) (cons 10 pt) (cons 11 pt) (cons 40 h) (cons 1 s) '(72 . 1) '(73 . 3)...`
- **Side effects**: Entities: `entmake`
- **Referenced**: 3

## c:MEDCBTEST

`(c:MEDCBTEST / form sz base x res geom len wid h lay maxw gap)`  - line 992-1016

Row of LB LR LL T TB C X for one form and size, labelled. User entry: [MEDCBTEST](../command-reference.md#medcbtest).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:MEDCBALL

`(c:MEDCBALL / sz base y x res geom len h lay gap s2 fl row rowh)`  - line 1020-1045

Gallery of every body type of every form at one trade size. User entry: [MEDCBALL](../command-reference.md#medcball).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## medcb-prims-ext

`(medcb-prims-ext geom / lo hi w r)`  - line 1048-1060

(xmin xmax) of the geometry along X / max |y| extent, for spacing the test row

- **Arguments**: `geom`
- **Returns**: value of the last expression: `(list lo hi w)`
- **Referenced**: 2

## medcb-geom-xrange

`(medcb-geom-xrange geom / lo hi bx e)`  - line 1061-1070

Extent along X / half width of a geometry (gallery spacing).

- **Arguments**: `geom`
- **Returns**: value of the last expression: `(cond ((setq bx (medcb-get "BOX" geom)) (list (car (car bx)) (car (cadr bx)))) ((medcb-get "PRIMS" geom) (setq...`
- **Referenced**: 2

## medcb-geom-width

`(medcb-geom-width geom / w bx)`  - line 1071-1079

Extent along X / half width of a geometry (gallery spacing).

- **Arguments**: `geom`
- **Returns**: value of the last expression: `(cond ((setq bx (medcb-get "BOX" geom)) (cadr (cadr bx))) ((medcb-get "PRIMS" geom) (caddr (medcb-prims-ext ge...`
- **Referenced**: 3

## c:MEDCBDATA

`(c:MEDCBDATA / rows n from)`  - line 1081-1093

Reloads conduit-body dimension data and lists sizes per form/shape. User entry: [MEDCBDATA](../command-reference.md#medcbdata).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## c:MEDCBVER

`(c:MEDCBVER)`  - line 1095-1100

Prints MED3DFittings version, row count and CSV path. User entry: [MEDCBVER](../command-reference.md#medcbver).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## medcb-dot

`(medcb-dot a b)`  - line 1164-1164

Vector dot / unit / XY distance.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(+ (* (car a) (car b)) (* (cadr a) (cadr b)) (* (caddr a) (caddr b)))`
- **Referenced**: 2

## medcb-unit

`(medcb-unit v / l)`  - line 1165-1167

Vector dot / unit / XY distance.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(if (> l 1e-12) (medcb-vx v (/ 1.0 l)))`
- **Referenced**: 3

## medcb-dxy

`(medcb-dxy a b)`  - line 1168-1168

Vector dot / unit / XY distance.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(distance (list (car a) (cadr a)) (list (car b) (cadr b)))`
- **Referenced**: 4

## medcb-app

`(medcb-app kind / v)`  - line 1169-1171

Xdata app name for a kind (MED_CONDUIT ...).

- **Arguments**: `kind`
- **Returns**: value of the last expression: `(if (= (type v) 'STR) v (strcat "MED_" kind))`
- **Referenced**: 4

## medcb-int

`(medcb-int v)`  - line 1172-1174

Value to integer / trimmed string.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(cond ((numberp v) (fix v)) ((and (= (type v) 'STR) (/= (vl-string-trim " " v) "")) (atoi v)))`
- **Referenced**: 2

## medcb-str

`(medcb-str v)`  - line 1175-1175

Value to integer / trimmed string.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(if (= (type v) 'STR) (vl-string-trim " \t" v) "")`
- **Referenced**: 4

## medcb-split

`(medcb-split s ch / k out)`  - line 1176-1179

Splits a string on a character.

- **Arguments**: `s`, `ch`
- **Returns**: value of the last expression: `(reverse (cons s out))`
- **Referenced**: 2

## medcb-clean

`(medcb-clean s / i a r)`  - line 1181-1187

upper case, A-Z 0-9 only (safe in a block name)

- **Arguments**: `s`
- **Returns**: value of the last expression: `r`
- **Referenced**: 3

## medcb-key-parse

`(medcb-key-parse key / p)`  - line 1190-1194

"RGD|F7|LB" -> ("RGD" "F7" "LB"); nil unless material|form|shape with a shape

- **Arguments**: `key`
- **Returns**: value of the last expression: `(if (and (= (type key) 'STR) (setq p (medcb-split (vl-string-trim " \t" key) "|")) (= (length p) 3)) (progn (s...`
- **Referenced**: 3

## medcb-desc-key

`(medcb-desc-key desc / u k q e form shape)`  - line 1196-1207

catalog description -> "RGD|<form>|<shape>" or nil (not a condulet)

- **Arguments**: `desc`
- **Returns**: value of the last expression: `(if (and (= (type desc) 'STR) (setq k (vl-string-search "CONDULET" (setq u (strcase desc))))) (progn (setq for...`
- **Referenced**: 1

## medcb-read-keys-csv

`(medcb-read-keys-csv path / f line hdr ix fl rows code)`  - line 1209-1222

Reads / caches fitting_body_keys.csv.

- **Arguments**: `path`
- **Returns**: value of the last expression: `(if (and path (setq f (open path "r"))) (progn (if (setq line (read-line f)) (progn (setq hdr (medcb-csv-split...`
- **Referenced**: 2

## medcb-fitcat

`(medcb-fitcat / res code)`  - line 1224-1234

FITTING catalog, once per MEDMAKE3D: ((code desc itemkey2 "DB"|"CSV") ...)

- **Arguments**: none
- **Returns**: value of the last expression: `(vl-remove nil *MEDCB-FITCAT*)`
- **Side effects**: Globals set (not declared local): `*MEDCB-FITCAT*`; DB: `medcb-sql`
- **Referenced**: 1

## medcb-keys-csv

`(medcb-keys-csv)`  - line 1238-1241

Reads / caches fitting_body_keys.csv.

- **Arguments**: none
- **Returns**: value of the last expression: `(vl-remove nil *MEDCB-KEYCSV*)`
- **Side effects**: Globals set (not declared local): `*MEDCB-KEYCSV*`
- **Referenced**: 1

## medcb-resolve-code

`(medcb-resolve-code code / e k c)`  - line 1245-1258

fitting code -> (key source desc), source "ITEMKEY2" | "CSV" | "DESC"; nil = not a body. Order: ITEMKEY2, the description (condulets), then the seed keys CSV for the same code when its description is the same (union, seals, plugs, hubs, reducer).

- **Arguments**: `code`
- **Returns**: value of the last expression: `(cond ((null e) nil) ((medcb-key-parse (nth 2 e)) (list (vl-string-trim " \t" (nth 2 e)) (if (= (nth 3 e) "DB"...`
- **Referenced**: 1

## medcb-2d-offset

`(medcb-2d-offset blk shape)`  - line 1262-1265

Z rotation offset of the 3D body against the 2D symbol (see header): the tee symbols draw the run along Y and the branch +X

- **Arguments**: `blk`, `shape`
- **Returns**: value of the last expression: `(cond ((and (= blk "1TEE") (member shape '("T" "BT"))) (/ pi -2.0)) ((and (= blk "1GUAT") (= shape "GUAT")) (/...`
- **Referenced**: 1

## medcb-xdir

`(medcb-xdir v rot flip / x y z tl c sn y0)`  - line 1272-1277

block vector -> WCS vector: tilt about block X first (flip, see medcb-insert-block), then rot about Z

- **Arguments**: `v`, `rot`, `flip`
- **Returns**: value of the last expression: `(list (- (* x (cos rot)) (* y (sin rot))) (+ (* x (sin rot)) (* y (cos rot))) z)`
- **Referenced**: 2

## medcb-wcs-hubs

`(medcb-wcs-hubs hubs rot flip / r)`  - line 1278-1280

Hubs in WCS for a rotation and tilt.

- **Arguments**: `hubs`, `rot`, `flip`
- **Returns**: value of the last expression: `(reverse r)`
- **Referenced**: 2

## medcb-cos-tol

`(medcb-cos-tol)`  - line 1281-1281

Hub angle tolerance (cos *MED3D-FIT-ANG*) / distance tolerance *MED3D-FIT-TOL*.

- **Arguments**: none
- **Returns**: value of the last expression: `(cos (/ (* pi (if (numberp *MED3D-FIT-ANG*) *MED3D-FIT-ANG* 30.0)) 180.0))`
- **Referenced**: 2

## medcb-fit-tol

`(medcb-fit-tol)`  - line 1282-1282

Hub angle tolerance (cos *MED3D-FIT-ANG*) / distance tolerance *MED3D-FIT-TOL*.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (numberp *MED3D-FIT-TOL*) *MED3D-FIT-TOL* 0.25)`
- **Referenced**: 2

## medcb-score

`(medcb-score hubs legs / ct n used best bi i d)`  - line 1284-1292

legs matched by a hub pointing along them (each hub used once)

- **Arguments**: `hubs`, `legs`
- **Returns**: value of the last expression: `n`
- **Referenced**: 1

## medcb-seg-param

`(medcb-seg-param a b pt / dx dy l2 s)`  - line 1295-1301

XY foot of pt on segment a-b: (param xy-distance) for 0 < param < 1, else nil

- **Arguments**: `a`, `b`, `pt`
- **Returns**: value of the last expression: `(if (> l2 1e-12) (progn (setq s (/ (+ (* (- (car pt) (car a)) dx) (* (- (cadr pt) (cadr a)) dy)) l2)) (if (and...`
- **Referenced**: 1

## medcb-legs

`(medcb-legs pt runs tol / dirs z n i a b tt u)`  - line 1303-1325

conduit legs at pt: ((unit-dir ...) z-of-the-conduit-or-nil); runs = ((pts closed) ...) WCS

- **Arguments**: `pt`, `runs`, `tol`
- **Returns**: value of the last expression: `(list (vl-remove nil dirs) z)`
- **Referenced**: 1

## medcb-conduit-runs

`(medcb-conduit-runs / ss i pd r)`  - line 1328-1337

every MED_CONDUIT polyline as (pts closed) for the leg search (needs MED3DPath)

- **Arguments**: none
- **Returns**: value of the last expression: `(reverse r)`
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 1

## medcb-mirrored-p

`(medcb-mirrored-p ed / sx sy n)`  - line 1339-1344

T when an insert is mirrored (X*Y scale*extrusion Z < 0).

- **Arguments**: `ed`
- **Returns**: value of the last expression: `(< (* sx sy (caddr n)) 0.0)`
- **Referenced**: 3

## medcb-alt-tilts

`(medcb-alt-tilts shape flip / r)`  - line 1346-1351

tilts the snap tries after the symbol's own one (see medcb-insert-block)

- **Arguments**: `shape`, `flip`
- **Returns**: value of the last expression: `(cond ((or (member shape *MEDCB-LB-FAMILY*) (= shape "TB")) (foreach tl (list (/ pi 2.0) (/ pi -2.0)) (if (not...`
- **Referenced**: 1

## medcb-brk-max

`(medcb-brk-max blk / c d m x)`  - line 1355-1365

Largest medblck.dat break of a block / search tolerance with insert scale.

- **Arguments**: `blk`
- **Returns**: value of the last expression: `(if (setq c (assoc blk *MEDCB-BRK-CACHE*)) (cdr c) (progn (setq d (if get_bl_data (vl-catch-all-apply 'get_bl_...`
- **Side effects**: Globals set (not declared local): `*MEDCB-BRK-CACHE*`
- **Referenced**: 1

## medcb-brk-list

`(medcb-brk-list blk / d)`  - line 1367-1370

medblck.dat d1..d4 (block +X +Y -X -Y) of a 2D symbol, or nil

- **Arguments**: `blk`
- **Returns**: value of the last expression: `(if (and (listp d) (not (vl-catch-all-error-p d))) (mapcar '(lambda (x) (if (numberp x) (float x) 0.0)) (list ...`
- **Referenced**: 1

## medcb-hub-tols

`(medcb-hub-tols hubs blk ed a / bl sc x y r i)`  - line 1376-1386

r6: per hub search radius for the planner = the break on the symbol side the hub points to (hub direction back in the symbol's axes, a = symbol rotation) x scale + *MED3D-FIT-TOL*; vertical hubs *MED3D-FIT-TOL*. Hubs come back as (name face dir radius) - MED3DPath only accepts a far run end on the axis of a hub ...

- **Arguments**: `hubs`, `blk`, `ed`, `a`
- **Returns**: value of the last expression: `(mapcar '(lambda (h) (setq x (+ (* (car (caddr h)) (cos a)) (* (cadr (caddr h)) (sin a))) y (- (* (cadr (caddr...`
- **Referenced**: 1

## medcb-brk-tol

`(medcb-brk-tol blk ed / sc)`  - line 1387-1389

Largest medblck.dat break of a block / search tolerance with insert scale.

- **Arguments**: `blk`, `ed`
- **Returns**: value of the last expression: `(+ (medcb-fit-tol) (* sc (medcb-brk-max blk)))`
- **Referenced**: 1

## medcb-body-of

`(medcb-body-of e runs / ed xd code sz res kp mat form shape blk flip note reason r pt a rot geom hubs lg k best sc i h tl tbest tol sz2 gsz)`  - line 1391-1477

one MED_FITTING INSERT -> body alist; "NM" = not a conduit body; nil = no xdata

- **Arguments**: `e`, `runs`
- **Returns**: value of the last expression: `(cond ((not xd) nil) ((not res) "NM") ((progn (setq kp (medcb-key-parse (car res)) mat (car kp) form (cadr kp)...`
- **Side effects**: Xdata: reads xdata
- **Referenced**: 1

## medcb-collect

`(medcb-collect / ss i b bodies nm runs)`  - line 1480-1501

every MED_FITTING INSERT in the drawing -> (bodies not-modelled-count)

- **Arguments**: none
- **Returns**: value of the last expression: `(list (reverse bodies) nm)`
- **Side effects**: Globals set (not declared local): `*MEDCB-FITCAT*`, `*MEDCB-KEYCSV*`; Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 6

## medcb-fit-rec

`(medcb-fit-rec b)`  - line 1506-1508

record for the conduit planner (*MED3D-FITS*): (handle pt hubs search-radius); nil without a size mirrored fittings get none (the conduit is left as drawn)

- **Arguments**: `b`
- **Returns**: value of the last expression: `(if (and (> (medcb-get "SIZE" b) 0.0) (not (medcb-get "MIRROR" b))) (list (medcb-get "HANDLE" b) (medcb-get "P...`
- **Referenced**: 2

## medcb-ensure-ph

`(medcb-ensure-ph form shape sz / name)`  - line 1511-1515

placeholder for any form / shape (unknown ones: box with run hubs)

- **Arguments**: `form`, `shape`, `sz`
- **Returns**: value of the last expression: `(cond ((medcb-block-current name) (list name "PH-EXISTS")) ((medcb-build-block name (medcb-geom-ph shape sz (m...`
- **Referenced**: 1

## medcb-ensure-body

`(medcb-ensure-body form shape sz reason)`  - line 1516-1519

Ensures the 3D block (or placeholder) for a body key; returns name/status.

- **Arguments**: `form`, `shape`, `sz`, `reason`
- **Returns**: value of the last expression: `(cond ((not (and (numberp (medcb-sz1 sz)) (> (medcb-sz1 sz) 0.0))) nil) (reason (medcb-ensure-ph form shape sz...`
- **Referenced**: 1

## medcb-vert-data

`(medcb-vert-data e / vd cd dir len)`  - line 1527-1531

vertical conduit stored on the fitting insert by the menu's dcon_ins (up / down symbols): MED_CONDUIT (app tag size code dist msr) + VERT_DATA (app r1 r2 dir r4). Returns (dir length) or nil.

- **Arguments**: `e`
- **Returns**: value of the last expression: `(if (and vd cd (numberp (setq dir (nth 3 vd))) (/= dir 0) (numberp (setq len (nth 4 cd))) (> len 0.0)) (list (...`
- **Side effects**: Xdata: reads xdata, `VERT_DATA`
- **Referenced**: 1

## medcb-vert-leg

`(medcb-vert-leg b / e vd dir len pt hub best d od z0 z1 sol ms)`  - line 1535-1559

the vertical conduit of body b as a cylinder from the face of the hub pointing that way (else from the insertion point) to insertion Z + dir x length. Returns (ename-or-nil flagged-p)

- **Arguments**: `b`
- **Returns**: value of the last expression: `(if (and (setq vd (medcb-vert-data e)) pt) (progn (setq dir (car vd) len (cadr vd) best (medcb-cos-tol)) (fore...`
- **Referenced**: 1

## medcb-place-all

`(medcb-place-all bodies / h pt reason res ref e refs placed ph flagged skipped mir vl nv)`  - line 1560-1608

Inserts every collected body (MEDMAKE3D stage 4); returns counts.

- **Arguments**: `bodies`
- **Returns**: value of the last expression: `(list (cons "REFS" (reverse refs)) (cons "PLACED" placed) (cons "PH" ph) (cons "FLAGGED" flagged) (cons "MIRRO...`
- **Referenced**: 3

