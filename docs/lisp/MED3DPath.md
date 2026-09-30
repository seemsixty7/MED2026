# MED3DPath.lsp

`Support\MED3DPath.lsp` - 3D solids for conduit and cable runs (M3D, C3D, MAKE3DCONDUIT, MAKE3DCABLE, MEDMAKE3D, MED3DPLAN, MED3DVER).

Loaded by MEDCore (order 25). 108 defun(s): 7 command(s), 101 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 87 | [`med3d-v+`](#med3d-v) | function |
| 88 | [`med3d-v-`](#med3d-v-) | function |
| 89 | [`med3d-vx`](#med3d-vx) | function |
| 90 | [`med3d-dot`](#med3d-dot) | function |
| 91 | [`med3d-cross`](#med3d-cross) | function |
| 95 | [`med3d-len`](#med3d-len) | function |
| 96 | [`med3d-unit`](#med3d-unit) | function |
| 99 | [`med3d-pt3`](#med3d-pt3) | function |
| 101 | [`med3d-acos`](#med3d-acos) | function |
| 103 | [`med3d-tan`](#med3d-tan) | function |
| 104 | [`med3d-set-nth`](#med3d-set-nth) | function |
| 108 | [`med3d-get`](#med3d-get) | function |
| 115 | [`med3d-bend-radius`](#med3d-bend-radius) | function |
| 126 | [`med3d-seg-i1`](#med3d-seg-i1) | function |
| 127 | [`med3d-seg-len`](#med3d-seg-len) | function |
| 131 | [`med3d-seg-tin`](#med3d-seg-tin) | function |
| 135 | [`med3d-seg-tout`](#med3d-seg-tout) | function |
| 142 | [`med3d-bulge-arc`](#med3d-bulge-arc) | function |
| 154 | [`med3d-merge-collinear`](#med3d-merge-collinear) | function |
| 174 | [`med3d-build-segs`](#med3d-build-segs) | function |
| 210 | [`med3d-joints`](#med3d-joints) | function |
| 236 | [`med3d-vcover-run`](#med3d-vcover-run) | function |
| 261 | [`med3d-vcover`](#med3d-vcover) | function |
| 271 | [`med3d-trim-at`](#med3d-trim-at) | function |
| 282 | [`med3d-avail`](#med3d-avail) | function |
| 287 | [`med3d-conflict`](#med3d-conflict) | function |
| 296 | [`med3d-allocate`](#med3d-allocate) | function |
| 344 | [`med3d-fit-on-axis`](#med3d-fit-on-axis) | function |
| 355 | [`med3d-fit-at`](#med3d-fit-at) | function |
| 368 | [`med3d-fit-trim`](#med3d-fit-trim) | function |
| 376 | [`med3d-fit-joints`](#med3d-fit-joints) | function |
| 405 | [`med3d-fit-lens`](#med3d-fit-lens) | function |
| 417 | [`med3d-corner-by`](#med3d-corner-by) | function |
| 424 | [`med3d-plan`](#med3d-plan) | function |
| 504 | [`med3d-dxf`](#med3d-dxf) | function |
| 508 | [`med3d-read-path`](#med3d-read-path) | function |
| 545 | [`med3d-num`](#med3d-num) | function |
| 549 | [`med3d-sql`](#med3d-sql) | function |
| 559 | [`med3d-preload-od`](#med3d-preload-od) | function |
| 581 | [`med3d-cable-od`](#med3d-cable-od) | function |
| 602 | [`med3d-run-od`](#med3d-run-od) | function |
| 623 | [`med3d-skip`](#med3d-skip) | function |
| 629 | [`med3d-plan-ent`](#med3d-plan-ent) | function |
| 650 | [`med3d-layer-info`](#med3d-layer-info) | function |
| 655 | [`med3d-flag-layer`](#med3d-flag-layer) | function |
| 658 | [`med3d-ensure-layer`](#med3d-ensure-layer) | function |
| 669 | [`med3d-rtos`](#med3d-rtos) | function |
| 670 | [`med3d-deg`](#med3d-deg) | function |
| 673 | [`med3d-flag-at`](#med3d-flag-at) | function |
| 681 | [`med3d-flag-marker`](#med3d-flag-marker) | function |
| 684 | [`med3d-corner-reason`](#med3d-corner-reason) | function |
| 696 | [`med3d-report-flags`](#med3d-report-flags) | function |
| 727 | [`med3d-clear-flags`](#med3d-clear-flags) | function |
| 734 | [`med3d-ms`](#med3d-ms) | function |
| 737 | [`med3d-region`](#med3d-region) | function |
| 749 | [`med3d-debug-on`](#med3d-debug-on) | function |
| 757 | [`med3d-dbg`](#med3d-dbg) | function |
| 758 | [`med3d-ptstr`](#med3d-ptstr) | function |
| 760 | [`med3d-maxabs`](#med3d-maxabs) | function |
| 766 | [`med3d-bbox`](#med3d-bbox) | function |
| 770 | [`med3d-bbstr`](#med3d-bbstr) | function |
| 772 | [`med3d-bb-has`](#med3d-bb-has) | function |
| 780 | [`med3d-check-line`](#med3d-check-line) | function |
| 797 | [`med3d-arc-pt`](#med3d-arc-pt) | function |
| 805 | [`med3d-check-arc`](#med3d-check-arc) | function |
| 832 | [`med3d-solid-line`](#med3d-solid-line) | function |
| 856 | [`med3d-extrude-dir`](#med3d-extrude-dir) | function |
| 873 | [`med3d-solid-arc`](#med3d-solid-arc) | function |
| 909 | [`med3d-temp-arc`](#med3d-temp-arc) | function |
| 918 | [`med3d-solid-sphere`](#med3d-solid-sphere) | function |
| 923 | [`med3d-draw-pieces`](#med3d-draw-pieces) | function |
| 958 | [`med3d-planar-normal`](#med3d-planar-normal) | function |
| 981 | [`med3d-make-lw-path`](#med3d-make-lw-path) | function |
| 999 | [`med3d-has-spheres`](#med3d-has-spheres) | function |
| 1004 | [`med3d-draw-sweep`](#med3d-draw-sweep) | function |
| 1040 | [`med3d-run`](#med3d-run) | function |
| 1064 | [`med3d-run-ss`](#med3d-run-ss) | function |
| 1072 | [`med3d-begin`](#med3d-begin) | function |
| 1080 | [`*error*`](#error) | function |
| 1088 | [`med3d-end`](#med3d-end) | function |
| 1097 | [`med3d-filter`](#med3d-filter) | function |
| 1102 | [`med3d-kind-of`](#med3d-kind-of) | function |
| 1111 | [`med3d-pick`](#med3d-pick) | function |
| 1136 | [`med3d-cmd-m3d`](#med3d-cmd-m3d) | function |
| 1137 | [`med3d-cmd-c3d`](#med3d-cmd-c3d) | function |
| 1140 | [`med3d-live`](#med3d-live) | function |
| 1149 | [`med3d-path-build-all`](#med3d-path-build-all) | function |
| 1160 | [`med3d-export`](#med3d-export) | function |
| 1190 | [`med3d-cmd-make3dconduit`](#med3d-cmd-make3dconduit) | function |
| 1191 | [`med3d-cmd-make3dcable`](#med3d-cmd-make3dcable) | function |
| 1196 | [`med3d-stage`](#med3d-stage) | function |
| 1210 | [`med3d-sscat`](#med3d-sscat) | function |
| 1215 | [`med3d-summary-line`](#med3d-summary-line) | function |
| 1223 | [`med3d-make3d-all`](#med3d-make3d-all) | function |
| 1320 | [`med3d-make3d-all-cmd`](#med3d-make3d-all-cmd) | function |
| 1321 | [`c:MEDMake3D`](#cmedmake3d) | command |
| 1331 | [`med3d-claim-commands`](#med3d-claim-commands) | function |
| 1334 | [`c:M3D`](#cm3d) | command |
| 1337 | [`c:C3D`](#cc3d) | command |
| 1340 | [`c:Make3DConduit`](#cmake3dconduit) | command |
| 1343 | [`c:Make3DCable`](#cmake3dcable) | command |
| 1349 | [`med3d-join`](#med3d-join) | function |
| 1354 | [`med3d-lisp-will-start`](#med3d-lisp-will-start) | function |
| 1360 | [`med3d-install-reactor`](#med3d-install-reactor) | function |
| 1367 | [`med3d-owner`](#med3d-owner) | function |
| 1368 | [`c:MED3DVER`](#cmed3dver) | command |
| 1382 | [`med3d-print-plan`](#med3d-print-plan) | function |
| 1394 | [`c:MED3DPLAN`](#cmed3dplan) | command |

## med3d-v+

`(med3d-v+ a b)`  - line 87-87

------------------------------------------------------------ vector helpers

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(mapcar '+ a b)`
- **Referenced**: 10

## med3d-v-

`(med3d-v- a b)`  - line 88-88

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(mapcar '- a b)`
- **Referenced**: 22

## med3d-vx

`(med3d-vx v s)`  - line 89-89

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `v`, `s`
- **Returns**: value of the last expression: `(mapcar '(lambda (x) (* x s)) v)`
- **Referenced**: 20

## med3d-dot

`(med3d-dot a b)`  - line 90-90

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(apply '+ (mapcar '* a b))`
- **Referenced**: 13

## med3d-cross

`(med3d-cross a b)`  - line 91-94

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `a`, `b`
- **Returns**: value of the last expression: `(list (- (* (cadr a) (caddr b)) (* (caddr a) (cadr b))) (- (* (caddr a) (car b)) (* (car a) (caddr b))) (- (* ...`
- **Referenced**: 9

## med3d-len

`(med3d-len v)`  - line 95-95

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(sqrt (med3d-dot v v))`
- **Referenced**: 2

## med3d-unit

`(med3d-unit v / l)`  - line 96-98

Vector subtract / scale / dot / cross / length / unit.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(if (> l 1e-12) (med3d-vx v (/ 1.0 l)))`
- **Referenced**: 20

## med3d-pt3

`(med3d-pt3 p)`  - line 99-100

Point to 3D float list.

- **Arguments**: `p`
- **Returns**: value of the last expression: `(list (float (car p)) (float (cadr p)) (if (caddr p) (float (caddr p)) 0.0))`
- **Referenced**: 3

## med3d-acos

`(med3d-acos x)`  - line 101-102

Arc cosine / tangent.

- **Arguments**: `x`
- **Returns**: value of the last expression: `(cond ((>= x 1.0) 0.0) ((<= x -1.0) pi) (T (atan (sqrt (- 1.0 (* x x))) x)))`
- **Referenced**: 1

## med3d-tan

`(med3d-tan a)`  - line 103-103

Arc cosine / tangent.

- **Arguments**: `a`
- **Returns**: value of the last expression: `(/ (sin a) (cos a))`
- **Referenced**: 2

## med3d-set-nth

`(med3d-set-nth lst n val / i out)`  - line 104-107

Replaces the nth list item.

- **Arguments**: `lst`, `n`, `val`
- **Returns**: value of the last expression: `(reverse out)`
- **Referenced**: 6

## med3d-get

`(med3d-get key alist)`  - line 108-108

Alist lookup.

- **Arguments**: `key`, `alist`
- **Returns**: value of the last expression: `(cdr (assoc key alist))`
- **Referenced**: 97

## med3d-bend-radius

`(med3d-bend-radius kind od override)`  - line 115-121

--------------------------------------------------------------- bend radius Single place for bend radius rules. kind "CONDUIT" | "CABLE". override: nil -> *MED3D-BEND-FACTOR* (5) x OD for conduit, *MED3D-CABLE-BEND-FACTOR* (7) x OD for cable; number -> that radius; ("FACTOR" . n) -> n x OD. Later: per-bend lists, ...

- **Arguments**: `kind`, `od`, `override`
- **Returns**: value of the last expression: `(cond ((and (numberp override) (> override 0.0)) (float override)) ((and (listp override) (= (car override) "F...`
- **Referenced**: 3

## med3d-seg-i1

`(med3d-seg-i1 s)`  - line 126-126

------------------------------------------------------------------ segments seg: ("L" A B i0 i1) straight | ("A" A B C N th i0 i1) arc, N = unit axis (right hand, A->B), th = sweep > 0. i0/i1 = source vertex indices (0-based).

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (= (car s) "L") (nth 4 s) (nth 7 s))`
- **Referenced**: 1

## med3d-seg-len

`(med3d-seg-len s)`  - line 127-130

Length / start tangent / end tangent of a line or arc piece.

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (= (car s) "L") (distance (nth 1 s) (nth 2 s)) (* (distance (nth 1 s) (nth 3 s)) (nth 5 s)))`
- **Referenced**: 1

## med3d-seg-tin

`(med3d-seg-tin s)`  - line 131-134

Length / start tangent / end tangent of a line or arc piece.

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (= (car s) "L") (med3d-unit (med3d-v- (nth 2 s) (nth 1 s))) (med3d-unit (med3d-cross (nth 4 s) (med3d-v- (...`
- **Referenced**: 5

## med3d-seg-tout

`(med3d-seg-tout s)`  - line 135-138

Length / start tangent / end tangent of a line or arc piece.

- **Arguments**: `s`
- **Returns**: value of the last expression: `(if (= (car s) "L") (med3d-unit (med3d-v- (nth 2 s) (nth 1 s))) (med3d-unit (med3d-cross (nth 4 s) (med3d-v- (...`
- **Referenced**: 4

## med3d-bulge-arc

`(med3d-bulge-arc a b bul nrm / th ns chord d r mid cdir left)`  - line 142-151

Arc from bulge between WCS points a b; nrm = WCS unit normal of the polyline. Returns (center signed-axis sweep).

- **Arguments**: `a`, `b`, `bul`, `nrm`
- **Returns**: value of the last expression: `(list (med3d-v+ mid (med3d-vx left (* r (cos (/ th 2.0))))) ns th)`
- **Referenced**: 1

## med3d-merge-collinear

`(med3d-merge-collinear segs closed / out prev f l)`  - line 154-170

Straights in a row that are collinear become one straight.

- **Arguments**: `segs`, `closed`
- **Returns**: value of the last expression: `out`
- **Referenced**: 1

## med3d-build-segs

`(med3d-build-segs pts buls nrm closed / i np nb ni n segs p q b arc dt)`  - line 174-205

pts: WCS points, buls: bulge per vertex, nrm: WCS normal (2D) or nil (3D). Returns (segs closed) or nil when fewer than 2 distinct points.

- **Arguments**: `pts`, `buls`, `nrm`, `closed`
- **Returns**: value of the last expression: `(if (>= (length np) 2) (progn (setq n (length np) i 0 segs nil) (repeat (if closed n (1- n)) (setq p (nth i np...`
- **Side effects**: Globals set (not declared local): `*MED3D-DROPPED*`
- **Referenced**: 1

## med3d-joints

`(med3d-joints segs closed R / n k s1 s2 d1 d2 th typ tt res)`  - line 210-229

-------------------------------------------------------------------- joints joint: (V theta kin kout type T vidx d1 d2) type "C" straight/straight (fillet candidate), "R" reversal, "K" kink at an arc

- **Arguments**: `segs`, `closed`, `R`
- **Returns**: value of the last expression: `(reverse res)`
- **Side effects**: Globals set (not declared local): `1e99`, `0.0`
- **Referenced**: 1

## med3d-vcover-run

`(med3d-vcover-run costs edges first lastdrop / inf ck cd nk nd pk pd pks pds i e st c flags)`  - line 236-259

---------------------------------------------------------------- allocation Minimum-cost vertex cover on a chain (optionally closed) of candidates. costs: drop cost per item; edges: k-1 flags (T = items i and i+1 conflict). first: nil | "KEEP" | "DROP" forces item 0; lastdrop T forces last dropped. Returns (cost . ...

- **Arguments**: `costs`, `edges`, `first`, `lastdrop`
- **Returns**: value of the last expression: `(if (>= c inf) (cons inf nil) (progn (setq flags (list (= st "K"))) (while pks (setq st (if (= st "K") (car pk...`
- **Referenced**: 3

## med3d-vcover

`(med3d-vcover costs edges cyc / a b)`  - line 261-268

Minimum vertex cover used to choose which conflicting corners stay sharp.

- **Arguments**: `costs`, `edges`, `cyc`
- **Returns**: value of the last expression: `(cond ((null costs) nil) ((or (not cyc) (= (length costs) 1)) (cdr (med3d-vcover-run costs edges nil nil))) (T...`
- **Referenced**: 1

## med3d-trim-at

`(med3d-trim-at joints stats k which ex / i r jj)`  - line 271-279

tangent used by a FITTED joint at the START or END of segment k (skip joint ex)

- **Arguments**: `joints`, `stats`, `k`, `which`, `ex`
- **Returns**: value of the last expression: `r`
- **Referenced**: 2

## med3d-avail

`(med3d-avail joints stats lens i / j)`  - line 282-285

straight left for joint i on its two segments after the other ends' tangents

- **Arguments**: `joints`, `stats`, `lens`, `i`
- **Returns**: value of the last expression: `(min (- (nth (nth 2 j) lens) (med3d-trim-at joints stats (nth 2 j) "START" i)) (- (nth (nth 3 j) lens) (med3d-...`
- **Referenced**: 2

## med3d-conflict

`(med3d-conflict a b lens)`  - line 287-289

T when two corners overlap on the same straight.

- **Arguments**: `a`, `b`, `lens`
- **Returns**: value of the last expression: `(and (= (nth 3 a) (nth 2 b)) (> (+ (nth 5 a) (nth 5 b)) (+ (nth (nth 3 a) lens) 1e-9)))`
- **Referenced**: 2

## med3d-allocate

`(med3d-allocate segs joints closed / eps lens stats forced cands i f costs edges cyc flags changed avails a b)`  - line 296-334

Returns (stats avails), one entry per joint. A corner whose T exceeds either whole straight is dropped outright. The rest drop as few corners as possible (ties: drop the smaller bend) so that the two tangents on every straight sum to <= its length; then any dropped corner that now fits is put back.

- **Arguments**: `segs`, `joints`, `closed`
- **Returns**: value of the last expression: `(list stats (reverse avails))`
- **Referenced**: 1

## med3d-fit-on-axis

`(med3d-fit-on-axis f p od / dx dy ok hx hy hl al)`  - line 344-354

------------------------------------------------------------ conduit bodies body of *MED3D-FITS* at WCS point p: XY within the body's search radius (4th item: medblck.dat break x insert scale + *MED3D-FIT-TOL*, else *MED3D-FIT-TOL*), Z within max(*MED3D-FIT-TOL*, od). r12: farther than *MED3D-FIT-TOL* only on the ...

- **Arguments**: `f`, `p`, `od`
- **Returns**: value of the last expression: `ok`
- **Referenced**: 1

## med3d-fit-at

`(med3d-fit-at p od / tol r d)`  - line 355-363

Conduit-body fitting record at a point (from MEDMAKE3D bodies).

- **Arguments**: `p`, `od`
- **Returns**: value of the last expression: `r`
- **Referenced**: 3

## med3d-fit-trim

`(med3d-fit-trim f u p / best r d off)`  - line 368-373

cut-back along leg u (unit, pointing away from the body) for the run end / vertex p: (distance . T) from p to the face of the hub pointing along u (within *MED3D-FIT-ANG*); negative = the run stops short of the face (menu break) and is extended to it. (0.0 . nil) if no hub points along u.

- **Arguments**: `f`, `u`, `p`
- **Returns**: value of the last expression: `(if r (cons (- (max 0.0 (med3d-dot (cadr r) u)) off) T) (cons 0.0 nil))`
- **Referenced**: 4

## med3d-fit-joints

`(med3d-fit-joints segs joints closed od / out flags hits f s r ci co bad n p cs ce)`  - line 376-403

joints at a body become ("F" ...): (V th kin kout "F" 0.0 vidx d1 d2 cut-in cut-out handle). Returns (joints (cut-at-start cut-at-end) fitflags hits); fitflags = ((point handle vidx) ...)

- **Arguments**: `segs`, `joints`, `closed`, `od`
- **Returns**: value of the last expression: `(list (reverse out) (list cs ce) (reverse flags) (reverse hits))`
- **Referenced**: 1

## med3d-fit-lens

`(med3d-fit-lens lens joints closed / n)`  - line 405-414

segment lengths minus the body cut-backs (so bends next to a body still fit)

- **Arguments**: `lens`, `joints`, `closed`
- **Returns**: value of the last expression: `lens`
- **Referenced**: 1

## med3d-corner-by

`(med3d-corner-by corners key k / r cc)`  - line 417-419

---------------------------------------------------------------------- plan

- **Arguments**: `corners`, `key`, `k`
- **Returns**: value of the last expression: `r`
- **Referenced**: 2

## med3d-plan

`(med3d-plan pts buls nrm closed od kind override / *MED3D-DUP-TOL* *MED3D-ENDTRIM* bs segs R joints fj gaps al stats avails rs corners i st th d1 d2 tt pin pout n1 c nn pieces k cs ce d a b)`  - line 424-501

Pure geometry: WCS vertices -> plan alist ("SEGS" ...) ("CORNERS" ...) ("PIECES" ...) ("CLOSED" . flag) ("OD" . od) ("R" . R) pieces: ("L" A B) | ("A" A B C N th) | ("S" P radius), in path order.

- **Arguments**: `pts`, `buls`, `nrm`, `closed`, `od`, `kind`, `override`
- **Returns**: value of the last expression: `(if (and bs (car bs)) (progn (setq segs (car bs) closed (cadr bs) R (med3d-bend-radius kind od override) joint...`
- **Side effects**: Globals set (not declared local): `*MED3D-DROPPED*`
- **Referenced**: 2

## med3d-dxf

`(med3d-dxf code ed dflt / v)`  - line 504-505

================================================= AutoCAD side (not pure)

- **Arguments**: `code`, `ed`, `dflt`
- **Returns**: value of the last expression: `(if (setq v (cdr (assoc code ed))) v dflt)`
- **Referenced**: 9

## med3d-read-path

`(med3d-read-path ent / ed typ flg nrm elev pts buls v vd is3d p)`  - line 508-543

entity -> (pts buls nrm closed) in WCS, nil if unsupported

- **Arguments**: `ent`
- **Returns**: value of the last expression: `(cond ((= typ "LWPOLYLINE") (setq nrm (med3d-dxf 210 ed '(0.0 0.0 1.0)) elev (med3d-dxf 38 ed 0.0) flg (med3d-...`
- **Referenced**: 3

## med3d-num

`(med3d-num v)`  - line 545-545

Value to number.

- **Arguments**: `v`
- **Returns**: value of the last expression: `(cond ((numberp v) v) ((= (type v) 'STR) (atof v)) (T nil))`
- **Referenced**: 8

## med3d-sql

`(med3d-sql sql / old res)`  - line 549-555

SELECT through MED-DotNet with *MED-SQL-QUIET* = T (MED-DotNet then skips its "n row(s)" line). Returns the result list or nil (also on error).

- **Arguments**: `sql`
- **Returns**: value of the last expression: `(if (and MED-DotNet-Ready (MED-DotNet-Ready)) (progn (setq old *MED-SQL-QUIET* *MED-SQL-QUIET* T res (vl-catch...`
- **Side effects**: Globals set (not declared local): `*MED-SQL-QUIET*`
- **Referenced**: 3

## med3d-preload-od

`(med3d-preload-od kind / res k s v)`  - line 559-578

One SELECT per command for all conduit ODs / all cable ODs (instead of one per type+size), stored in the caches med_conduit_od / med3d-cable-od read.

- **Arguments**: `kind`
- **Returns**: value of the last expression: `(cond ((and (= kind "CONDUIT") (not *MED3D-OD-PRELOADED*)) (if (setq res (med3d-sql "SELECT ConduitCode, Trade...`
- **Side effects**: Globals set (not declared local): `_MEDCONDUITOD_CACHE`, `*MED3D-OD-PRELOADED*`, `*MED3D-CABLEOD-CACHE*`, `*MED3D-CABLEOD-PRELOADED*`
- **Referenced**: 1

## med3d-cable-od

`(med3d-cable-od code / key hit res val)`  - line 581-598

cable OD (inches) from MEDType.USER3, cached per run of a command

- **Arguments**: `code`
- **Returns**: value of the last expression: `(if (and (numberp code) (> code 0)) (progn (setq key (fix code)) (if (setq hit (assoc key *MED3D-CABLEOD-CACHE...`
- **Side effects**: Globals set (not declared local): `*MED3D-CABLEOD-CACHE*`
- **Referenced**: 2

## med3d-run-od

`(med3d-run-od ent kind / xd code size key old res)`  - line 602-620

xdata layouts (xdataget): conduit (app tag size code dist msr), cable (app tag size code rtag dist msr)

- **Arguments**: `ent`, `kind`
- **Returns**: value of the last expression: `(cond ((= kind "CONDUIT") (if (setq xd (xdataget ent _CONDUIT)) (progn (setq code (med3d-num (nth 3 xd)) size ...`
- **Side effects**: Globals set (not declared local): `_MEDCONDUITOD_CACHE`, `*MED-SQL-QUIET*`; Xdata: reads xdata
- **Referenced**: 3

## med3d-skip

`(med3d-skip h kind reason)`  - line 623-626

skipped run: print why, remember it for the MEDMAKE3D summary; returns nil

- **Arguments**: `h`, `kind`, `reason`
- **Returns**: value of the last expression: `nil`
- **Side effects**: Globals set (not declared local): `*MED3D-SKIPS*`
- **Referenced**: 5

## med3d-plan-ent

`(med3d-plan-ent ent kind / pd od h plan)`  - line 629-647

plan for one entity without drawing (for fittings); nil if skipped

- **Arguments**: `ent`, `kind`
- **Returns**: value of the last expression: `(cond ((not (setq pd (med3d-read-path ent))) (med3d-skip h kind "not a LWPOLYLINE / 2D / 3D POLYLINE")) ((prog...`
- **Referenced**: 3

## med3d-layer-info

`(med3d-layer-info kind)`  - line 650-654

-------------------------------------------------------------------- layers

- **Arguments**: `kind`
- **Returns**: value of the last expression: `(cond ((= kind "CABLE") (if _MED3DCABLE _MED3DCABLE '("MED_3DCABLE" "CYAN" "CONTINUOUS"))) (T (if _MED3DCONDUI...`
- **Side effects**: Xdata: `MED_3DCABLE`, `MED_3DCONDUIT`
- **Referenced**: 4

## med3d-flag-layer

`(med3d-flag-layer)`  - line 655-656

MED_3DFLAG layer spec (_MED3DFLAG).

- **Arguments**: none
- **Returns**: value of the last expression: `(if _MED3DFLAG _MED3DFLAG '("MED_3DFLAG" "RED" "CONTINUOUS"))`
- **Side effects**: Xdata: `MED_3DFLAG`
- **Referenced**: 5

## med3d-ensure-layer

`(med3d-ensure-layer info / nm col)`  - line 658-666

create the layer if missing (does not change CLAYER); returns its name

- **Arguments**: `info`
- **Returns**: value of the last expression: `nm`
- **Side effects**: Layers: creates/sets layers (LAYER command / CLAYER); Entities: `entmake`
- **Referenced**: 8

## med3d-rtos

`(med3d-rtos x)`  - line 669-669

--------------------------------------------------------------- flags / msg

- **Arguments**: `x`
- **Returns**: value of the last expression: `(if (> x 1e90) "n/a (reversal)" (rtos x 2 3))`
- **Referenced**: 2

## med3d-deg

`(med3d-deg a)`  - line 670-670

Radians to degree string.

- **Arguments**: `a`
- **Returns**: value of the last expression: `(rtos (* 180.0 (/ a pi)) 2 1)`
- **Referenced**: 5

## med3d-flag-at

`(med3d-flag-at v s txt / lay)`  - line 673-680

marker on MED_3DFLAG: 3 axis lines + circle of size s, text txt

- **Arguments**: `v`, `s`, `txt`
- **Returns**: value of the last expression: `(entmake (list '(0 . "TEXT") (cons 8 lay) (cons 10 (med3d-v+ v (list s s 0.0))) (cons 40 (* 0.5 s)) (cons 1 tx...`
- **Side effects**: Entities: `entmake`
- **Referenced**: 8

## med3d-flag-marker

`(med3d-flag-marker v od h idx)`  - line 681-682

Flag marker at a vertex.

- **Arguments**: `v`, `od`, `h`, `idx`
- **Returns**: value of the last expression: `(med3d-flag-at v (* 2.0 od) (strcat "3D FLAG " h " v" (itoa (1+ idx))))`
- **Referenced**: 1

## med3d-corner-reason

`(med3d-corner-reason c)`  - line 684-694

Text reason for a corner status.

- **Arguments**: `c`
- **Returns**: value of the last expression: `(cond ((= (med3d-get "STATUS" c) "FITTED") (strcat "fits: tangent " (rtos (med3d-get "NEED" c) 2 3) " <= avail...`
- **Referenced**: 1

## med3d-report-flags

`(med3d-report-flags plan / h od st)`  - line 696-725

Prints the FLAG lines of a plan.

- **Arguments**: `plan`
- **Returns**: value of the last expression: `(foreach ff (med3d-get "FITFLAGS" plan) (princ (strcat "\nMED3D FLAG: run " h " vertex " (itoa (1+ (nth 2 ff))...`
- **Referenced**: 1

## med3d-clear-flags

`(med3d-clear-flags / ss i)`  - line 727-731

Erases everything on MED_3DFLAG.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (setq ss (ssget "_X" (list (cons 8 (car (med3d-flag-layer)))))) (progn (setq i 0) (repeat (sslength ss) (e...`
- **Side effects**: Entities: `entdel`
- **Referenced**: 2

## med3d-ms

`(med3d-ms)`  - line 734-734

------------------------------------------------------------------- drawing

- **Arguments**: none
- **Returns**: value of the last expression: `(vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))`
- **Referenced**: 1

## med3d-region

`(med3d-region ms p tn r lay / c reg)`  - line 737-745

Profile circle region at a point normal to a tangent.

- **Arguments**: `ms`, `p`, `tn`, `r`, `lay`
- **Returns**: value of the last expression: `(if (and tn (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 (trans p 0 tn)) (cons 40 r) (cons 210 tn)))) ...`
- **Side effects**: Entities: `entmake`, `vla-delete`
- **Referenced**: 2

## med3d-debug-on

`(med3d-debug-on / r)`  - line 749-756

------------------------------------------------------------ debug / checks T when MED3DPath debug output is on (see *MED3D-DEBUG* above)

- **Arguments**: none
- **Returns**: value of the last expression: `(cond ((equal *MED3D-DEBUG* "OFF") nil) (*MED3D-DEBUG* T) (*MED-DEBUG* T) ((and med-debug-p (not (vl-catch-all...`
- **Referenced**: 2

## med3d-dbg

`(med3d-dbg msg)`  - line 757-757

Debug print when *MED3D-DEBUG* is on.

- **Arguments**: `msg`
- **Returns**: value of the last expression: `(if (med3d-debug-on) (princ (strcat "\nMED3D dbg: " msg)))`
- **Referenced**: 28

## med3d-ptstr

`(med3d-ptstr p)`  - line 758-759

Point / bounding box to string.

- **Arguments**: `p`
- **Returns**: value of the last expression: `(if p (strcat (rtos (car p) 2 3) "," (rtos (cadr p) 2 3) "," (rtos (caddr p) 2 3)) "nil")`
- **Referenced**: 10

## med3d-maxabs

`(med3d-maxabs pts / m)`  - line 760-763

Largest absolute coordinate.

- **Arguments**: `pts`
- **Returns**: value of the last expression: `m`
- **Referenced**: 3

## med3d-bbox

`(med3d-bbox obj / mn mx r)`  - line 766-769

bounding box of a vla object -> (min max) or nil

- **Arguments**: `obj`
- **Returns**: value of the last expression: `(if (not (vl-catch-all-error-p r)) (list (vlax-safearray->list mn) (vlax-safearray->list mx)))`
- **Referenced**: 8

## med3d-bbstr

`(med3d-bbstr bb)`  - line 770-771

Point / bounding box to string.

- **Arguments**: `bb`
- **Returns**: value of the last expression: `(if bb (strcat "(" (med3d-ptstr (car bb)) ")-(" (med3d-ptstr (cadr bb)) ")") "n/a")`
- **Referenced**: 6

## med3d-bb-has

`(med3d-bb-has bb p tol)`  - line 772-775

T when a bounding box contains a point.

- **Arguments**: `bb`, `p`, `tol`
- **Returns**: value of the last expression: `(and (<= (- (car (car bb)) tol) (car p) (+ (car (cadr bb)) tol)) (<= (- (cadr (car bb)) tol) (cadr p) (+ (cadr...`
- **Referenced**: 5

## med3d-check-line

`(med3d-check-line obj a b r / bb d tol ok i ext lo hi)`  - line 780-794

Does the solid's box match a cylinder a->b of radius r? (T when no box available) Box must hold both axis ends and be no bigger than the ideal box + r per side (AutoCAD boxes of sloped solids are not always tight).

- **Arguments**: `obj`, `a`, `b`, `r`
- **Returns**: value of the last expression: `(if (not bb) T (progn (setq ok (and (med3d-bb-has bb a tol) (med3d-bb-has bb b tol)) i 0) (repeat 3 (setq ext ...`
- **Referenced**: 2

## med3d-arc-pt

`(med3d-arc-pt a c nn ang / v)`  - line 797-799

point on the arc: a rotated about axis nn (through c) by angle ang

- **Arguments**: `a`, `c`, `nn`, `ang`
- **Returns**: value of the last expression: `(med3d-v+ c (med3d-v+ (med3d-vx v (cos ang)) (med3d-vx (med3d-cross nn v) (sin ang))))`
- **Referenced**: 3

## med3d-check-arc

`(med3d-check-arc obj a c nn th r / bb tol ok k q lo hi i)`  - line 805-824

Does the solid's box match a bend a -> (about nn through c, angle th), tube radius r? Box must hold the arc start, middle and end, and must not stick out more than r (+ r slack for loose boxes) past the ideal arc box. Rejects a bend revolved the wrong way, a ball, or a full torus. (T when no box available)

- **Arguments**: `obj`, `a`, `c`, `nn`, `th`, `r`
- **Returns**: value of the last expression: `(if (not bb) T (progn (setq ok (and (med3d-bb-has bb a tol) (med3d-bb-has bb (med3d-arc-pt a c nn (/ th 2.0)) ...`
- **Referenced**: 1

## med3d-solid-line

`(med3d-solid-line ms a b r lay / d reg ln sol)`  - line 832-853

------------------------------------------------------------------ straights Straight a->b. 1st: AddExtrudedSolidAlongPath with a temp LINE a->b (direction and length come from the path, nothing to guess). Checked against its box; if wrong or failed: circle + _.EXTRUDE _Direction a b. (c0c08c2 used AddExtrudedSolid ...

- **Arguments**: `ms`, `a`, `b`, `r`, `lay`
- **Returns**: value of the last expression: `(if d (progn (if (setq reg (med3d-region ms a d r lay)) (progn (setq ln (vl-catch-all-apply 'vlax-invoke (list...`
- **Side effects**: Entities: `vla-delete`
- **Referenced**: 1

## med3d-extrude-dir

`(med3d-extrude-dir a b r lay / d circ e obj)`  - line 856-871

fallback straight: entmake circle at a (normal a->b) + _.EXTRUDE _Direction a b

- **Arguments**: `a`, `b`, `r`, `lay`
- **Returns**: value of the last expression: `(if (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 (trans a 0 d)) (cons 40 r) (cons 210 d))) (progn (set...`
- **Side effects**: Entities: `entmake`, `entdel`; AutoCAD commands: `EXTRUDE`
- **Referenced**: 1

## med3d-solid-arc

`(med3d-solid-arc ms a c nn th r lay / tn reg arc sol res try note)`  - line 873-906

Bend solid (extrude along arc, revolve fallback).

- **Arguments**: `ms`, `a`, `c`, `nn`, `th`, `r`, `lay`
- **Returns**: value of the last expression: `(if (and tn (setq reg (med3d-region ms a tn r lay))) (progn ;; 1st: extrude the profile along a temp ARC in th...`
- **Side effects**: Entities: `vla-delete`
- **Referenced**: 1

## med3d-temp-arc

`(med3d-temp-arc ms a c nn th lay / oc oa sa)`  - line 909-916

temp ARC (vla object) centre c, axis nn, from a sweeping th (right hand about nn)

- **Arguments**: `ms`, `a`, `c`, `nn`, `th`, `lay`
- **Returns**: value of the last expression: `(if (entmake (list '(0 . "ARC") (cons 8 lay) (cons 10 oc) (cons 40 (distance a c)) (cons 50 sa) (cons 51 (+ sa...`
- **Side effects**: Entities: `entmake`
- **Referenced**: 1

## med3d-solid-sphere

`(med3d-solid-sphere ms p r / s)`  - line 918-920

Sphere solid at a corner.

- **Arguments**: `ms`, `p`, `r`
- **Returns**: value of the last expression: `(if (not (vl-catch-all-error-p s)) s)`
- **Referenced**: 1

## med3d-draw-pieces

`(med3d-draw-pieces plan lay / ms r sols s base res fails extras k)`  - line 923-955

ActiveX pieces unioned. Returns (main-ename extra-enames fails)

- **Arguments**: `plan`, `lay`
- **Returns**: value of the last expression: `(if sols (progn (setq base (car sols)) (foreach s (cdr sols) (setq res (vl-catch-all-apply 'vlax-invoke (list ...`
- **Referenced**: 1

## med3d-planar-normal

`(med3d-planar-normal plan / pcs n p0 ok d tol)`  - line 958-978

plane normal when every piece lies in one plane, else nil

- **Arguments**: `plan`
- **Returns**: value of the last expression: `(if n (progn (setq p0 (nth 1 (car pcs)) ok T tol (max 1e-6 (* 1e-9 (med3d-maxabs (mapcar 'cadr pcs))))) (forea...`
- **Referenced**: 1

## med3d-make-lw-path

`(med3d-make-lw-path plan n lay / pcs closed ed ocs b)`  - line 981-997

filleted centerline as one LWPOLYLINE in the run plane

- **Arguments**: `plan`, `n`, `lay`
- **Returns**: value of the last expression: `(if (entmake ed) (entlast))`
- **Side effects**: Entities: `entmake`
- **Referenced**: 1

## med3d-has-spheres

`(med3d-has-spheres plan / r)`  - line 999-1001

T when a plan has sphere corners.

- **Arguments**: `plan`
- **Returns**: value of the last expression: `r`
- **Referenced**: 1

## med3d-draw-sweep

`(med3d-draw-sweep plan lay / n path pc0 a tn circ sol typ)`  - line 1004-1037

SWEEP one circle along the filleted centerline (planar runs, no sharp corners)

- **Arguments**: `plan`, `lay`
- **Returns**: value of the last expression: `(cond ((med3d-get "GAPS" plan) (med3d-dbg "method PIECES: run is cut at a conduit body") nil) ((med3d-has-sphe...`
- **Side effects**: Entities: `entmake`, `entdel`; AutoCAD commands: `SWEEP`
- **Referenced**: 1

## med3d-run

`(med3d-run ent kind / plan lay sol res extras)`  - line 1040-1059

draw one entity: returns (solid plan) or nil

- **Arguments**: `ent`, `kind`
- **Returns**: value of the last expression: `(if (setq plan (med3d-plan-ent ent kind)) (progn (setq lay (med3d-ensure-layer (med3d-layer-info kind))) (med3...`
- **Side effects**: Globals set (not declared local): `*MED3D-BUILT*`, `*MED3D-FLAGGED*`, `*MED3D-LAST-PLANS*`; Xdata: writes xdata
- **Referenced**: 5

## med3d-run-ss

`(med3d-run-ss ss kind / i ok)`  - line 1064-1069

Converts every run in a selection set.

- **Arguments**: `ss`, `kind`
- **Returns**: value of the last expression: `ok`
- **Referenced**: 1

## med3d-begin

`(med3d-begin tag)`  - line 1072-1086

------------------------------------------------------ house rules / errors

- **Arguments**: `tag`
- **Returns**: value of the last expression: `(setvar "CMDECHO" 0)`
- **Side effects**: Globals set (not declared local): `*MED3D-OLD*`, `*MED3D-OLDERR*`, `*MED3D-TAG*`, `_MEDCONDUITOD_CACHE`, `*MED3D-CABLEOD-CACHE*`, `*MED3D-OD-PRELOADED*`, `*MED3D-CABLEOD-PRELOADED*`; Layers: creates/sets layers (LAYER command / CLAYER)
- **Referenced**: 6

## *error*

`(*error* msg)`  - line 1080-1084 (nested defun)

MED3DPath command error handler.

- **Arguments**: `msg`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 17
- **Duplicate**: also defined in Support\MED3DCON.lsp:135, Support\MED3DFittings.lsp:963, Support\MED3DTrayFunctions.lsp:468, Support\MEDFunctions.lsp:921, Support\MEDFunctions.lsp:2816; replaced at load time by Support\MED3DFittings.lsp:963

## med3d-end

`(med3d-end)`  - line 1088-1095

Restores sysvars and error handler.

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `*error*`, `*MED3D-OLD*`, `*MED3D-OLDERR*`, `*MED3D-FITS*`; Layers: creates/sets layers (LAYER command / CLAYER)
- **Referenced**: 8

## med3d-filter

`(med3d-filter app)`  - line 1097-1098

ssget filter for polylines with an xdata app.

- **Arguments**: `app`
- **Returns**: value of the last expression: `(list '(-4 . "<OR") '(0 . "LWPOLYLINE") '(0 . "POLYLINE") '(-4 . "OR>") (list -3 (list app)))`
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp)
- **Referenced**: 1

## med3d-kind-of

`(med3d-kind-of e pref / cn cb)`  - line 1102-1107

------------------------------------------------------------------ commands kind of a run from its xdata; pref wins when both are present

- **Arguments**: `e`, `pref`
- **Returns**: value of the last expression: `(cond ((and cn cb) pref) (cn "CONDUIT") (cb "CABLE"))`
- **Side effects**: Xdata: reads xdata
- **Referenced**: 1

## med3d-pick

`(med3d-pick kind tag / ss ok i e k n)`  - line 1111-1134

M3D / C3D: select polylines (no xdata filter, so nothing vanishes silently), convert each by its own xdata (conduit or cable), and say why any is skipped.

- **Arguments**: `kind`, `tag`
- **Returns**: nothing useful (restores sysvars / error handler)
- **Referenced**: 2

## med3d-cmd-m3d

`(med3d-cmd-m3d)`  - line 1136-1136

Worker behind M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D.

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-pick "CONDUIT" "M3D")`
- **Referenced**: 1

## med3d-cmd-c3d

`(med3d-cmd-c3d)`  - line 1137-1137

Worker behind M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D.

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-pick "CABLE" "C3D")`
- **Referenced**: 1

## med3d-live

`(med3d-live l / r)`  - line 1140-1142

live entities of a list (UNION / cleanup may have erased some)

- **Arguments**: `l`
- **Returns**: value of the last expression: `(reverse r)`
- **Referenced**: 4

## med3d-path-build-all

`(med3d-path-build-all kind / ss ok)`  - line 1149-1158

Worker shared by MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D: convert every MED run of kind in the drawing. No prompts and no sysvar handling (callers wrap it in med3d-begin / med3d-end). Returns (("KIND" . kind) ("RUNS" . n) ("OK" . n) ("SOLIDS" ename ...) ("FLAGGED" . n) ("SKIPPED" (handle kind reason) ...))

- **Arguments**: `kind`
- **Returns**: value of the last expression: `(list (cons "KIND" kind) (cons "RUNS" (if ss (sslength ss) 0)) (cons "OK" ok) (cons "SOLIDS" (med3d-live (reve...`
- **Side effects**: Globals set (not declared local): `*MED3D-BUILT*`, `*MED3D-SKIPS*`, `*MED3D-FLAGGED*`
- **Referenced**: 6

## med3d-export

`(med3d-export kind tag / lay res ok sols fmt fname)`  - line 1160-1188

Dwg/Layer export of the solids of one kind.

- **Arguments**: `kind`, `tag`
- **Returns**: nothing useful (restores sysvars / error handler)
- **Side effects**: Globals set (not declared local): `*MED3D-LAST-PLANS*`; AutoCAD commands: `-WBLOCK`, `PLAN`, `VPOINT`
- **Prompts**: `Use the PLAN command to return to plan view.`
- **Referenced**: 2

## med3d-cmd-make3dconduit

`(med3d-cmd-make3dconduit)`  - line 1190-1190

Worker behind M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D.

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-export "CONDUIT" "MAKE3DCONDUIT")`
- **Referenced**: 1

## med3d-cmd-make3dcable

`(med3d-cmd-make3dcable)`  - line 1191-1191

Worker behind M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D.

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-export "CABLE" "MAKE3DCABLE")`
- **Referenced**: 1

## med3d-stage

`(med3d-stage name fn args / r)`  - line 1196-1208

------------------------------------------------------------------ MEDMAKE3D run one stage worker without letting its error stop the other stages; returns the worker's result, or nil (and records why) on error

- **Arguments**: `name`, `fn`, `args`
- **Returns**: value of the last expression: `(if (vl-catch-all-error-p r) (progn (princ (strcat "\nMEDMAKE3D: " name " stage failed: " (vl-catch-all-error-...`
- **Side effects**: Globals set (not declared local): `*MED3D-STAGE-ERRORS*`
- **Referenced**: 5

## med3d-sscat

`(med3d-sscat l / ss)`  - line 1210-1213

Concatenates selection sets.

- **Arguments**: `l`
- **Returns**: value of the last expression: `(if (> (sslength ss) 0) ss)`
- **Referenced**: 1

## med3d-summary-line

`(med3d-summary-line label n what)`  - line 1215-1216

Prints one MEDMAKE3D summary line.

- **Arguments**: `label`, `n`, `what`
- **Returns**: printed text (message); value not meant to be used
- **Referenced**: 8

## med3d-make3d-all

`(med3d-make3d-all / fmt tray traysols fitsols bodies con cb cab skips flagged all ss fname n)`  - line 1223-1318

MEDMAKE3D: tray (+ fittings) via the MAKE3DTRAY worker, then the conduit bodies (MED3DFittings: every MED_FITTING INSERT resolved to a body + its hubs), then conduit (cut back at the bodies), then the body blocks, then cable via med3d-path-build-all; one [Dwg/Layer] prompt; one combined DWG + one .medprops.json ...

- **Arguments**: none
- **Returns**: nothing useful (restores sysvars / error handler)
- **Side effects**: Globals set (not declared local): `*MED3D-LAST-PLANS*`, `*MED3D-STAGE-ERRORS*`, `*MED3D-FITS*`; Layers: creates/sets layers (LAYER command / CLAYER); AutoCAD commands: `-WBLOCK`, `PLAN`, `VPOINT`
- **Prompts**: `MEDMAKE3D output to [Dwg/Layer] <Dwg>:`; `Use the PLAN command to return to plan view.`
- **Referenced**: 1

## med3d-make3d-all-cmd

`(med3d-make3d-all-cmd)`  - line 1320-1320

Worker behind M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D.

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-make3d-all)`
- **Referenced**: 1

## c:MEDMake3D

`(c:MEDMake3D)`  - line 1321-1321

Tray, tray fittings, conduit, conduit bodies and cable to 3D in one go (Dwg/Layer). See 3d.md. User entry: [MEDMAKE3D](../command-reference.md#medmake3d).

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-make3d-all-cmd)`
- **Referenced**: 1

## med3d-claim-commands

`(med3d-claim-commands quiet / bad)`  - line 1331-1348

------------------------------------------------------- command ownership M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE are bound to the med3d-cmd-* functions here, so a later (load "MED3DCON") with the 2012 defuns cannot keep them. Returns the list of names that had to be taken back (not counting first load). Commands ...

- **Arguments**: `quiet`
- **Returns**: value of the last expression: `bad`
- **Side effects**: Globals set (not declared local): `*MED3D-OWN-M3D*`, `*MED3D-OWN-C3D*`, `*MED3D-OWN-MKCON*`, `*MED3D-OWN-MKCAB*`
- **Referenced**: 5

## c:M3D

`(c:M3D)`  - line 1334-1334 (nested defun)

Selected conduit runs to 3D solids on MED_3DCONDUIT. User entry: [M3D](../command-reference.md#m3d).

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-cmd-m3d)`
- **Referenced**: 6

## c:C3D

`(c:C3D)`  - line 1337-1337 (nested defun)

Selected cable runs to 3D solids on MED_3DCABLE. User entry: [C3D](../command-reference.md#c3d).

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-cmd-c3d)`
- **Referenced**: 5

## c:Make3DConduit

`(c:Make3DConduit)`  - line 1340-1340 (nested defun)

Every conduit run to 3D; Dwg (WBLOCK + .medprops.json) or Layer. User entry: [MAKE3DCONDUIT](../command-reference.md#make3dconduit).

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-cmd-make3dconduit)`
- **Referenced**: 6

## c:Make3DCable

`(c:Make3DCable)`  - line 1343-1343 (nested defun)

Every cable run to 3D; Dwg or Layer. User entry: [MAKE3DCABLE](../command-reference.md#make3dcable).

- **Arguments**: none
- **Returns**: value of the last expression: `(med3d-cmd-make3dcable)`
- **Referenced**: 5

## med3d-join

`(med3d-join l sep / r)`  - line 1349-1351

Joins strings with a separator.

- **Arguments**: `l`, `sep`
- **Returns**: value of the last expression: `(if r r "")`
- **Referenced**: 1

## med3d-lisp-will-start

`(med3d-lisp-will-start rea args / s)`  - line 1354-1359

lisp reactor: re-claim just before one of our commands is evaluated

- **Arguments**: `rea`, `args`
- **Returns**: value of the last expression: `(if (and args (= (type (car args)) 'STR)) (progn (setq s (strcase (car args))) (if (wcmatch s "(C:M3D)*,(C:C3D...`
- **Referenced**: 1

## med3d-install-reactor

`(med3d-install-reactor)`  - line 1360-1365

Installs the lisp reactor that reclaims M3D/C3D/MAKE3D* names from old MED3DCON.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (and vlr-lisp-reactor (not (and *MED3D-LISP-REACTOR* (vlr-added-p *MED3D-LISP-REACTOR*)))) (setq *MED3D-LI...`
- **Side effects**: Globals set (not declared local): `*MED3D-LISP-REACTOR*`
- **Referenced**: 1

## med3d-owner

`(med3d-owner f g)`  - line 1367-1367

Which file owns a command (MED3DVER).

- **Arguments**: `f`, `g`
- **Returns**: value of the last expression: `(if (eq f g) "MED3DPath" (if f "OTHER FILE (old MED3DCON.lsp?)" "not defined"))`
- **Referenced**: 4

## c:MED3DVER

`(c:MED3DVER)`  - line 1368-1379

Prints the MED3DPath version, command ownership, tray worker, debug and file paths. User entry: [MED3DVER](../command-reference.md#med3dver).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

## med3d-print-plan

`(med3d-print-plan plan)`  - line 1382-1392

corner table of one run, no solids

- **Arguments**: `plan`
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 2

## c:MED3DPLAN

`(c:MED3DPLAN / e kind plan)`  - line 1394-1401

Prints the corner/bend table of one run; draws nothing. User entry: [MED3DPLAN](../command-reference.md#med3dplan).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Xdata: reads xdata
- **Referenced**: 0

