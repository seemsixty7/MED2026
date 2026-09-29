;;; MED3DPath.lsp - unified 3D solids for MED conduit and cable runs (AutoCAD 2024+).
;;;
;;; Commands
;;;   M3D            conduit runs you select   -> one 3DSOLID per run on MED_3DCONDUIT
;;;   C3D            cable runs you select     -> one 3DSOLID per run on MED_3DCABLE
;;;   MAKE3DCONDUIT  every MED_CONDUIT run     -> Dwg / Layer output like MAKE3DTRAY
;;;   MAKE3DCABLE    every MED_CABLE run       -> Dwg / Layer output like MAKE3DTRAY
;;;   MED3DPLAN      print the corner table of one run (no solids)
;;; The 2012 code stays in MED3DCON.lsp as M3DOLD / MAKE3DCONDUITOLD.
;;;
;;; Paths: LWPOLYLINE, 2D heavy POLYLINE (bulges kept as drawn), 3D POLYLINE.
;;;   Vertices go to WCS with trans (OCS + elevation). Meshes are skipped.
;;; OD: conduit = med_conduit_od (MED_CONDUIT code + trade size);
;;;     cable   = MEDType.USER3 for the MED_CABLE code. No OD = run skipped.
;;; Bends: every corner between two straights gets a fillet of radius
;;;   (med3d-bend-radius kind od override) = 5 x OD by default. Tangent
;;;   T = R*tan(theta/2) is pulled back from both straights. Tangents at the two
;;;   ends of a straight may use the whole straight between them (sum <= length).
;;;   A corner that cannot fit is left sharp, closed with a sphere of the OD, and
;;;   FLAGGED (command line + marker on MED_3DFLAG). Drawn bulge arcs are kept;
;;;   a non-tangent joint next to an arc is a KINK (sphere, no marker).
;;; Solid: planar run with no sharp corners -> one filleted LWPOLYLINE centerline
;;;   + entmake profile circle + _.SWEEP, temp path deleted. Anything else (3D
;;;   non-planar, sphere corners, or SWEEP failure) -> ActiveX pieces (extruded
;;;   straights, revolved bends, spheres) unioned into one solid.
;;; Data for fittings: (med3d-plan-ent ent kind) returns the plan without drawing;
;;;   ("CORNERS" ...) is a list of corner alists:
;;;   INDEX (0-based source vertex) VERTEX ANGLE RADIUS TANGENT PTIN PTOUT CENTER
;;;   NORMAL TIN TOUT STATUS ("FITTED" "FLAGGED" "KINK") NEED AVAIL SEGIN SEGOUT.
;;;   Each run drawn by a command is also kept in *MED3D-LAST-PLANS*.

(princ "\rLoading MED3DPath...")
(vl-load-com)

;;; ------------------------------------------------------------------ settings
(if (not *MED3D-BEND-FACTOR*) (setq *MED3D-BEND-FACTOR* 5.0))  ; R = factor x OD
(if (not *MED3D-METHOD*) (setq *MED3D-METHOD* "SWEEP"))       ; "SWEEP" or "PIECES"
;; per-run bend override: list of (handle . override), see med3d-bend-radius
(if (not (boundp '*MED3D-BEND-OVERRIDES*)) (setq *MED3D-BEND-OVERRIDES* nil))
;; (setq *MED3D-DEBUG* T) prints each run's path, method choice, every piece's
;; planned start/end and the bounding box of the solid actually created.
(if (not (boundp '*MED3D-DEBUG*)) (setq *MED3D-DEBUG* nil))
(setq *MED3D-TOL* 1e-6       ; length tolerance (drawing units)
      *MED3D-ANGTOL* 1e-4)   ; radians; smaller deflection = straight through

;;; ------------------------------------------------------------ vector helpers
(defun med3d-v+ (a b) (mapcar '+ a b))
(defun med3d-v- (a b) (mapcar '- a b))
(defun med3d-vx (v s) (mapcar '(lambda (x) (* x s)) v))
(defun med3d-dot (a b) (apply '+ (mapcar '* a b)))
(defun med3d-cross (a b)
  (list (- (* (cadr a) (caddr b)) (* (caddr a) (cadr b)))
        (- (* (caddr a) (car b)) (* (car a) (caddr b)))
        (- (* (car a) (cadr b)) (* (cadr a) (car b)))))
(defun med3d-len (v) (sqrt (med3d-dot v v)))
(defun med3d-unit (v / l)
  (setq l (med3d-len v))
  (if (> l 1e-12) (med3d-vx v (/ 1.0 l))))
(defun med3d-pt3 (p)
  (list (float (car p)) (float (cadr p)) (if (caddr p) (float (caddr p)) 0.0)))
(defun med3d-acos (x)
  (cond ((>= x 1.0) 0.0) ((<= x -1.0) pi) (T (atan (sqrt (- 1.0 (* x x))) x))))
(defun med3d-tan (a) (/ (sin a) (cos a)))
(defun med3d-set-nth (lst n val / i out)
  (setq i 0 out nil)
  (foreach x lst (setq out (cons (if (= i n) val x) out) i (1+ i)))
  (reverse out))
(defun med3d-get (key alist) (cdr (assoc key alist)))

;;; --------------------------------------------------------------- bend radius
;; Single place for bend radius rules. kind "CONDUIT" | "CABLE" (same rule today).
;; override: nil -> *MED3D-BEND-FACTOR* x OD; number -> that radius;
;;           ("FACTOR" . n) -> n x OD. Later: per-bend lists, long-radius tables.
(defun med3d-bend-radius (kind od override)
  (cond
    ((and (numberp override) (> override 0.0)) (float override))
    ((and (listp override) (= (car override) "FACTOR") (numberp (cdr override)))
      (* (cdr override) od))
    (T (* *MED3D-BEND-FACTOR* od))))

;;; ------------------------------------------------------------------ segments
;; seg: ("L" A B i0 i1) straight | ("A" A B C N th i0 i1) arc, N = unit axis
;; (right hand, A->B), th = sweep > 0. i0/i1 = source vertex indices (0-based).
(defun med3d-seg-i1 (s) (if (= (car s) "L") (nth 4 s) (nth 7 s)))
(defun med3d-seg-len (s)
  (if (= (car s) "L")
    (distance (nth 1 s) (nth 2 s))
    (* (distance (nth 1 s) (nth 3 s)) (nth 5 s))))
(defun med3d-seg-tin (s)
  (if (= (car s) "L")
    (med3d-unit (med3d-v- (nth 2 s) (nth 1 s)))
    (med3d-unit (med3d-cross (nth 4 s) (med3d-v- (nth 1 s) (nth 3 s))))))
(defun med3d-seg-tout (s)
  (if (= (car s) "L")
    (med3d-unit (med3d-v- (nth 2 s) (nth 1 s)))
    (med3d-unit (med3d-cross (nth 4 s) (med3d-v- (nth 2 s) (nth 3 s))))))

;; Arc from bulge between WCS points a b; nrm = WCS unit normal of the polyline.
;; Returns (center signed-axis sweep).
(defun med3d-bulge-arc (a b bul nrm / th ns chord d r mid cdir left)
  (setq th    (* 4.0 (atan (abs bul)))
        ns    (if (minusp bul) (med3d-vx nrm -1.0) nrm)
        chord (med3d-v- b a)
        d     (med3d-len chord)
        r     (/ d (* 2.0 (sin (/ th 2.0))))
        mid   (med3d-vx (med3d-v+ a b) 0.5)
        cdir  (med3d-vx chord (/ 1.0 d))
        left  (med3d-cross ns cdir))
  (list (med3d-v+ mid (med3d-vx left (* r (cos (/ th 2.0))))) ns th))

;; Straights in a row that are collinear become one straight.
(defun med3d-merge-collinear (segs closed / out prev f l)
  (setq out nil)
  (foreach s segs
    (setq prev (car out))
    (if (and prev (= (car prev) "L") (= (car s) "L")
             (> (med3d-dot (med3d-seg-tout prev) (med3d-seg-tin s)) (- 1.0 1e-10)))
      (setq out (cons (list "L" (nth 1 prev) (nth 2 s) (nth 3 prev) (nth 4 s)) (cdr out)))
      (setq out (cons s out))))
  (setq out (reverse out))
  (if (and closed (> (length out) 2))
    (progn
      (setq f (car out) l (car (reverse out)))
      (if (and (= (car f) "L") (= (car l) "L")
               (> (med3d-dot (med3d-seg-tout l) (med3d-seg-tin f)) (- 1.0 1e-10)))
        (setq out (cons (list "L" (nth 1 l) (nth 2 f) (nth 3 l) (nth 4 f))
                        (cdr (reverse (cdr (reverse out)))))))))
  out)

;; pts: WCS points, buls: bulge per vertex, nrm: WCS normal (2D) or nil (3D).
;; Returns (segs closed) or nil when fewer than 2 distinct points.
(defun med3d-build-segs (pts buls nrm closed / i np nb ni n segs p q b arc)
  (setq i 0 np nil nb nil ni nil)
  (foreach p pts
    (if (and np (< (distance p (car np)) *MED3D-TOL*))
      (setq nb (cons (nth i buls) (cdr nb)))          ; zero-length segment dropped
      (setq np (cons p np) nb (cons (nth i buls) nb) ni (cons i ni)))
    (setq i (1+ i)))
  (setq np (reverse np) nb (reverse nb) ni (reverse ni))
  (if (and (> (length np) 2) (< (distance (car np) (car (reverse np))) *MED3D-TOL*))
    (setq np (reverse (cdr (reverse np)))
          nb (reverse (cdr (reverse nb)))
          ni (reverse (cdr (reverse ni)))
          closed T))
  (if (< (length np) 3) (setq closed nil))
  (if (>= (length np) 2)
    (progn
      (setq n (length np) i 0 segs nil)
      (repeat (if closed n (1- n))
        (setq p (nth i np)
              q (nth (rem (1+ i) n) np)
              b (nth i nb))
        (if (and nrm b (> (abs b) 1e-9))
          (setq arc  (med3d-bulge-arc p q b nrm)
                segs (cons (list "A" p q (car arc) (cadr arc) (caddr arc)
                                 (nth i ni) (nth (rem (1+ i) n) ni)) segs))
          (setq segs (cons (list "L" p q (nth i ni) (nth (rem (1+ i) n) ni)) segs)))
        (setq i (1+ i)))
      (list (med3d-merge-collinear (reverse segs) closed) closed))))

;;; -------------------------------------------------------------------- joints
;; joint: (V theta kin kout type T vidx d1 d2)
;;   type "C" straight/straight (fillet candidate), "R" reversal, "K" kink at an arc
(defun med3d-joints (segs closed R / n k s1 s2 d1 d2 th typ tt res)
  (setq n (length segs) k 0 res nil)
  (repeat (if closed n (1- n))
    (setq s1 (nth k segs)
          s2 (nth (rem (1+ k) n) segs)
          d1 (med3d-seg-tout s1)
          d2 (med3d-seg-tin s2)
          th (med3d-acos (med3d-dot d1 d2)))
    (if (> th *MED3D-ANGTOL*)
      (progn
        (cond
          ((and (= (car s1) "L") (= (car s2) "L"))
            (if (< th (- pi 1e-6))
              (setq typ "C" tt (* R (med3d-tan (/ th 2.0))))
              (setq typ "R" tt 1e99)))
          (T (setq typ "K" tt 0.0)))
        (setq res (cons (list (nth 2 s1) th k (rem (1+ k) n) typ tt (med3d-seg-i1 s1) d1 d2)
                        res))))
    (setq k (1+ k)))
  (reverse res))

;;; ---------------------------------------------------------------- allocation
;; Minimum-cost vertex cover on a chain (optionally closed) of candidates.
;; costs: drop cost per item; edges: k-1 flags (T = items i and i+1 conflict).
;; first: nil | "KEEP" | "DROP" forces item 0; lastdrop T forces last dropped.
;; Returns (cost . keep-flags).
(defun med3d-vcover-run (costs edges first lastdrop / inf ck cd nk nd pk pd pks pds i e st c flags)
  (setq inf 1e300
        ck  (if (= first "DROP") inf 0.0)
        cd  (if (= first "KEEP") inf (car costs))
        pks nil pds nil i 1)
  (foreach c (cdr costs)
    (setq e (nth (1- i) edges))
    (if e
      (setq nk cd pk "D")
      (if (<= ck cd) (setq nk ck pk "K") (setq nk cd pk "D")))
    (if (<= ck cd) (setq nd (+ ck c) pd "K") (setq nd (+ cd c) pd "D"))
    (setq pks (cons pk pks) pds (cons pd pds) ck nk cd nd i (1+ i)))
  (setq st (cond (lastdrop "D") ((<= ck cd) "K") (T "D"))
        c  (if (= st "K") ck cd))
  (if (>= c inf)
    (cons inf nil)
    (progn
      (setq flags (list (= st "K")))
      (while pks
        (setq st    (if (= st "K") (car pks) (car pds))
              flags (cons (= st "K") flags)
              pks   (cdr pks)
              pds   (cdr pds)))
      (cons c flags))))

(defun med3d-vcover (costs edges cyc / a b)
  (cond
    ((null costs) nil)
    ((or (not cyc) (= (length costs) 1)) (cdr (med3d-vcover-run costs edges nil nil)))
    (T
      (setq a (med3d-vcover-run costs edges "DROP" nil)
            b (med3d-vcover-run costs edges "KEEP" T))
      (if (<= (car a) (car b)) (cdr a) (cdr b)))))

;; tangent used by a FITTED joint at the START or END of segment k (skip joint ex)
(defun med3d-trim-at (joints stats k which ex / i r jj)
  (setq i 0 r 0.0)
  (foreach jj joints
    (if (and (/= i ex)
             (= (nth i stats) "FITTED")
             (= (if (= which "START") (nth 3 jj) (nth 2 jj)) k))
      (setq r (nth 5 jj)))
    (setq i (1+ i)))
  r)

;; straight left for joint i on its two segments after the other ends' tangents
(defun med3d-avail (joints stats lens i / j)
  (setq j (nth i joints))
  (min (- (nth (nth 2 j) lens) (med3d-trim-at joints stats (nth 2 j) "START" i))
       (- (nth (nth 3 j) lens) (med3d-trim-at joints stats (nth 3 j) "END" i))))

(defun med3d-conflict (a b lens)
  (and (= (nth 3 a) (nth 2 b))
       (> (+ (nth 5 a) (nth 5 b)) (+ (nth (nth 3 a) lens) 1e-9))))

;; Returns (stats avails), one entry per joint.
;; A corner whose T exceeds either whole straight is dropped outright. The rest
;; drop as few corners as possible (ties: drop the smaller bend) so that the two
;; tangents on every straight sum to <= its length; then any dropped corner that
;; now fits is put back.
(defun med3d-allocate (segs joints closed / eps lens stats forced cands i f costs edges cyc flags changed avails a b)
  (setq eps 1e-9 lens (mapcar 'med3d-seg-len segs) i 0 stats nil forced nil cands nil)
  (foreach j joints
    (setq f (or (= (nth 4 j) "R")
                (and (= (nth 4 j) "C")
                     (or (> (nth 5 j) (+ (nth (nth 2 j) lens) eps))
                         (> (nth 5 j) (+ (nth (nth 3 j) lens) eps))))))
    (setq forced (cons f forced)
          stats  (cons (if (= (nth 4 j) "K") "KINK" "FLAGGED") stats))
    (if (and (= (nth 4 j) "C") (not f)) (setq cands (cons i cands)))
    (setq i (1+ i)))
  (setq forced (reverse forced) stats (reverse stats) cands (reverse cands))
  (setq costs nil edges nil)
  (foreach ci cands (setq costs (cons (+ 1e9 (nth 5 (nth ci joints))) costs)))
  (setq costs (reverse costs) i 0)
  (repeat (max 0 (1- (length cands)))
    (setq a (nth (nth i cands) joints)
          b (nth (nth (1+ i) cands) joints)
          edges (cons (med3d-conflict a b lens) edges)
          i (1+ i)))
  (setq edges (reverse edges))
  (setq cyc (and closed (> (length cands) 1)
                 (med3d-conflict (nth (car (reverse cands)) joints) (nth (car cands) joints) lens)))
  (setq flags (med3d-vcover costs edges cyc) i 0)
  (foreach ci cands
    (if (nth i flags) (setq stats (med3d-set-nth stats ci "FITTED")))
    (setq i (1+ i)))
  (setq changed T)
  (while changed
    (setq changed nil i 0)
    (foreach j joints
      (if (and (= (nth 4 j) "C") (not (nth i forced)) (= (nth i stats) "FLAGGED")
               (<= (nth 5 j) (+ (med3d-avail joints stats lens i) eps)))
        (setq stats (med3d-set-nth stats i "FITTED") changed T))
      (setq i (1+ i))))
  (setq avails nil i 0)
  (foreach j joints
    (setq avails (cons (med3d-avail joints stats lens i) avails) i (1+ i)))
  (list stats (reverse avails)))

;;; ---------------------------------------------------------------------- plan
(defun med3d-corner-by (corners key k / r cc)
  (foreach cc corners (if (= (med3d-get key cc) k) (setq r cc)))
  r)

;; Pure geometry: WCS vertices -> plan alist
;;   ("SEGS" ...) ("CORNERS" ...) ("PIECES" ...) ("CLOSED" . flag) ("OD" . od) ("R" . R)
;; pieces: ("L" A B) | ("A" A B C N th) | ("S" P radius), in path order.
(defun med3d-plan (pts buls nrm closed od kind override / bs segs R joints al stats avails rs corners i st th d1 d2 tt pin pout n1 c nn pieces k cs ce d a b)
  (setq bs (med3d-build-segs pts buls nrm closed))
  (if (and bs (car bs))
    (progn
      (setq segs   (car bs)
            closed (cadr bs)
            R      (med3d-bend-radius kind od override)
            joints (med3d-joints segs closed R)
            al     (med3d-allocate segs joints closed)
            stats  (car al)
            avails (cadr al)
            rs     (* 0.5 od)
            corners nil
            i 0)
      (foreach j joints
        (setq th (nth 1 j) d1 (nth 7 j) d2 (nth 8 j) st (nth i stats))
        (if (= st "FITTED")
          (setq tt   (nth 5 j)
                pin  (med3d-v- (nth 0 j) (med3d-vx d1 tt))
                pout (med3d-v+ (nth 0 j) (med3d-vx d2 tt))
                n1   (med3d-unit (med3d-v- d2 (med3d-vx d1 (med3d-dot d1 d2))))
                c    (med3d-v+ pin (med3d-vx n1 R))
                nn   (med3d-unit (med3d-cross d1 d2)))
          (setq tt 0.0 pin (nth 0 j) pout (nth 0 j) c nil nn nil))
        (setq corners
               (cons (list (cons "INDEX" (nth 6 j)) (cons "VERTEX" (nth 0 j)) (cons "ANGLE" th)
                           (cons "RADIUS" (if (= st "FITTED") R nil))
                           (cons "TANGENT" tt) (cons "PTIN" pin) (cons "PTOUT" pout)
                           (cons "CENTER" c) (cons "NORMAL" nn) (cons "TIN" d1) (cons "TOUT" d2)
                           (cons "STATUS" st) (cons "NEED" (nth 5 j)) (cons "AVAIL" (nth i avails))
                           (cons "SEGIN" (nth 2 j)) (cons "SEGOUT" (nth 3 j)))
                     corners)
              i (1+ i)))
      (setq corners (reverse corners) pieces nil k 0)
      (foreach s segs
        (setq cs (med3d-corner-by corners "SEGOUT" k)
              ce (med3d-corner-by corners "SEGIN" k))
        (if (= (car s) "L")
          (progn
            (setq d (med3d-seg-tin s)
                  a (if (and cs (= (med3d-get "STATUS" cs) "FITTED")) (med3d-get "PTOUT" cs) (nth 1 s))
                  b (if (and ce (= (med3d-get "STATUS" ce) "FITTED")) (med3d-get "PTIN" ce) (nth 2 s)))
            (if (> (med3d-dot (med3d-v- b a) d) *MED3D-TOL*)
              (setq pieces (cons (list "L" a b) pieces))))
          (setq pieces (cons (list "A" (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s) (nth 5 s)) pieces)))
        (if ce
          (if (= (med3d-get "STATUS" ce) "FITTED")
            (setq pieces (cons (list "A" (med3d-get "PTIN" ce) (med3d-get "PTOUT" ce)
                                     (med3d-get "CENTER" ce) (med3d-get "NORMAL" ce)
                                     (med3d-get "ANGLE" ce))
                               pieces))
            (setq pieces (cons (list "S" (med3d-get "VERTEX" ce) rs) pieces))))
        (setq k (1+ k)))
      (list (cons "SEGS" segs) (cons "CORNERS" corners) (cons "PIECES" (reverse pieces))
            (cons "CLOSED" closed) (cons "OD" od) (cons "R" R)))))

;;; ================================================= AutoCAD side (not pure)
(defun med3d-dxf (code ed dflt / v)
  (if (setq v (cdr (assoc code ed))) v dflt))

;; entity -> (pts buls nrm closed) in WCS, nil if unsupported
(defun med3d-read-path (ent / ed typ flg nrm elev pts buls v vd is3d p)
  (setq ed (entget ent) typ (cdr (assoc 0 ed)))
  (cond
    ((= typ "LWPOLYLINE")
      (setq nrm  (med3d-dxf 210 ed '(0.0 0.0 1.0))
            elev (med3d-dxf 38 ed 0.0)
            flg  (med3d-dxf 70 ed 0))
      (foreach g ed
        (cond
          ((= (car g) 10)
            (setq pts  (cons (trans (list (cadr g) (caddr g) elev) ent 0) pts)
                  buls (cons 0.0 buls)))
          ((= (car g) 42)
            (setq buls (cons (cdr g) (cdr buls))))))
      (list (reverse pts) (reverse buls) (med3d-unit nrm) (= 1 (logand flg 1))))
    ((= typ "POLYLINE")
      (setq flg (med3d-dxf 70 ed 0))
      (if (= 0 (logand flg 80))               ; not a polygon / polyface mesh
        (progn
          (setq is3d (= 8 (logand flg 8))
                nrm  (med3d-dxf 210 ed '(0.0 0.0 1.0))
                elev (caddr (med3d-dxf 10 ed '(0.0 0.0 0.0)))
                v    (entnext ent))
          (if (not elev) (setq elev 0.0))
          (while (and v (setq vd (entget v)) (= (cdr (assoc 0 vd)) "VERTEX"))
            (if (= 0 (logand (med3d-dxf 70 vd 0) 16))   ; skip spline frame points
              (setq p    (cdr (assoc 10 vd))
                    pts  (cons (if is3d
                                 (med3d-pt3 p)
                                 (trans (list (car p) (cadr p) elev) ent 0))
                               pts)
                    buls (cons (if is3d 0.0 (med3d-dxf 42 vd 0.0)) buls)))
            (setq v (entnext v)))
          (list (reverse pts) (reverse buls) (if is3d nil (med3d-unit nrm))
                (= 1 (logand flg 1))))))
    (T nil)))

(defun med3d-num (v) (cond ((numberp v) v) ((= (type v) 'STR) (atof v)) (T nil)))

;; cable OD (inches) from MEDType.USER3, cached per run of a command
(defun med3d-cable-od (code / key hit res val)
  (if (and (numberp code) (> code 0))
    (progn
      (setq key (fix code))
      (if (setq hit (assoc key *MED3D-CABLEOD-CACHE*))
        (cdr hit)
        (if (and MED-DotNet-Ready (MED-DotNet-Ready))
          (progn
            (setq res (vl-catch-all-apply 'MEDProcessSQLStatement
                        (list (strcat "SELECT USER3 FROM MEDType WHERE ITEMTYPE='CABLE' AND ITEMCODE="
                                      (itoa key)))))
            (if (and res (not (vl-catch-all-error-p res)) (listp res)
                     (>= (length res) 2) (listp (cadr res)))
              (setq val (car (cadr res))))
            (if (= (type val) 'STR) (setq val (atof val)))
            (if (not (and (numberp val) (> val 0.0))) (setq val nil))
            (setq *MED3D-CABLEOD-CACHE* (cons (cons key val) *MED3D-CABLEOD-CACHE*))
            val))))))

;; xdata layouts (xdataget): conduit (app tag size code dist msr),
;; cable (app tag size code rtag dist msr)
(defun med3d-run-od (ent kind / xd)
  (cond
    ((= kind "CONDUIT")
      (if (setq xd (xdataget ent _CONDUIT))
        (med_conduit_od (med3d-num (nth 3 xd)) (med3d-num (nth 2 xd)))))
    ((= kind "CABLE")
      (if (setq xd (xdataget ent _CABLE))
        (med3d-cable-od (med3d-num (nth 3 xd)))))))

;; plan for one entity without drawing (for fittings); nil if skipped
(defun med3d-plan-ent (ent kind / pd od h plan)
  (setq h (cdr (assoc 5 (entget ent))))
  (cond
    ((not (setq pd (med3d-read-path ent)))
      (princ (strcat "\nMED3D: " h " skipped - not a LWPOLYLINE / 2D / 3D POLYLINE.")) nil)
    ((progn
       (med3d-dbg (strcat "run " h " " (cdr (assoc 0 (entget ent)))
                          " flags " (itoa (med3d-dxf 70 (entget ent) 0))
                          " " (itoa (length (car pd))) " vertices"
                          (if (nth 2 pd) (strcat " normal " (med3d-ptstr (nth 2 pd))) " (3D)")
                          (if (nth 3 pd) " closed" "")
                          " first " (med3d-ptstr (car (car pd)))))
       nil))
    ((not (setq od (med3d-run-od ent kind)))
      (princ (strcat "\nMED3D: " h " skipped - no OD for this " (strcase kind T) " type/size."))
      nil)
    ((not (setq plan (med3d-plan (nth 0 pd) (nth 1 pd) (nth 2 pd) (nth 3 pd) od kind
                                 (cdr (assoc h *MED3D-BEND-OVERRIDES*)))))
      (princ (strcat "\nMED3D: " h " skipped - fewer than 2 distinct points.")) nil)
    (T (append (list (cons "HANDLE" h) (cons "KIND" kind) (cons "ENT" ent)) plan))))

;;; -------------------------------------------------------------------- layers
(defun med3d-layer-info (kind)
  (cond
    ((= kind "CABLE")
      (if _MED3DCABLE _MED3DCABLE '("MED_3DCABLE" "CYAN" "CONTINUOUS")))
    (T (if _MED3DCONDUIT _MED3DCONDUIT '("MED_3DCONDUIT" "GREEN" "CONTINUOUS")))))
(defun med3d-flag-layer ()
  (if _MED3DFLAG _MED3DFLAG '("MED_3DFLAG" "RED" "CONTINUOUS")))
;; create the layer if missing (does not change CLAYER); returns its name
(defun med3d-ensure-layer (info / nm col)
  (setq nm (car info))
  (if (not (tblsearch "LAYER" nm))
    (progn
      (setq col (vl-catch-all-apply 'getColorNumber (list (cadr info))))
      (if (or (vl-catch-all-error-p col) (not (numberp col))) (setq col 7))
      (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                     (cons 2 nm) '(70 . 0) (cons 62 col) '(6 . "Continuous")))))
  nm)

;;; --------------------------------------------------------------- flags / msg
(defun med3d-rtos (x) (if (> x 1e90) "n/a (reversal)" (rtos x 2 3)))
(defun med3d-deg (a) (rtos (* 180.0 (/ a pi)) 2 1))

(defun med3d-flag-marker (v od h idx / lay s)
  (setq lay (med3d-ensure-layer (med3d-flag-layer)) s (* 2.0 od))
  (foreach d '((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
    (entmake (list '(0 . "LINE") (cons 8 lay)
                   (cons 10 (med3d-v- v (med3d-vx d s))) (cons 11 (med3d-v+ v (med3d-vx d s))))))
  (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 v) (cons 40 s)))
  (entmake (list '(0 . "TEXT") (cons 8 lay) (cons 10 (med3d-v+ v (list s s 0.0))) (cons 40 od)
                 (cons 1 (strcat "3D FLAG " h " v" (itoa (1+ idx)))))))

(defun med3d-report-flags (plan / h od st)
  (setq h (med3d-get "HANDLE" plan) od (med3d-get "OD" plan))
  (foreach c (med3d-get "CORNERS" plan)
    (setq st (med3d-get "STATUS" c))
    (cond
      ((= st "FLAGGED")
        (princ (strcat "\nMED3D FLAG: run " h " vertex " (itoa (1+ (med3d-get "INDEX" c)))
                       " bend " (med3d-deg (med3d-get "ANGLE" c))
                       " deg, R " (rtos (med3d-get "R" plan) 2 3)
                       ": needs tangent " (med3d-rtos (med3d-get "NEED" c))
                       ", available " (rtos (max 0.0 (med3d-get "AVAIL" c)) 2 3)
                       " - sharp corner, closed with sphere."))
        (med3d-flag-marker (med3d-get "VERTEX" c) od h (med3d-get "INDEX" c)))
      ((= st "KINK")
        (princ (strcat "\nMED3D: run " h " vertex " (itoa (1+ (med3d-get "INDEX" c)))
                       " non-tangent joint at a drawn arc (" (med3d-deg (med3d-get "ANGLE" c))
                       " deg) - closed with sphere."))))))

(defun med3d-clear-flags ( / ss i)
  (if (setq ss (ssget "_X" (list (cons 8 (car (med3d-flag-layer))))))
    (progn
      (setq i 0)
      (repeat (sslength ss) (entdel (ssname ss i)) (setq i (1+ i))))))

;;; ------------------------------------------------------------------- drawing
(defun med3d-ms () (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))

;; profile circle (entmake, normal = tangent) -> region object (circle removed)
(defun med3d-region (ms p tn r lay / c reg)
  (setq tn (med3d-unit tn))
  (if (and tn (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 (trans p 0 tn))
                             (cons 40 r) (cons 210 tn))))
    (progn
      (setq c   (vlax-ename->vla-object (entlast))
            reg (vl-catch-all-apply 'vlax-invoke (list ms 'AddRegion (list c))))
      (vla-delete c)
      (if (and reg (not (vl-catch-all-error-p reg))) (car reg)))))

;;; ------------------------------------------------------------ debug / checks
(defun med3d-dbg (msg) (if *MED3D-DEBUG* (princ (strcat "\nMED3D dbg: " msg))))
(defun med3d-ptstr (p)
  (if p (strcat (rtos (car p) 2 3) "," (rtos (cadr p) 2 3) "," (rtos (caddr p) 2 3)) "nil"))
(defun med3d-maxabs (pts / m)
  (setq m 1.0)
  (foreach p pts (foreach c p (if (> (abs c) m) (setq m (abs c)))))
  m)

;; bounding box of a vla object -> (min max) or nil
(defun med3d-bbox (obj / mn mx r)
  (setq r (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'mn 'mx)))
  (if (not (vl-catch-all-error-p r))
    (list (vlax-safearray->list mn) (vlax-safearray->list mx))))
(defun med3d-bbstr (bb)
  (if bb (strcat "(" (med3d-ptstr (car bb)) ")-(" (med3d-ptstr (cadr bb)) ")") "n/a"))
(defun med3d-bb-has (bb p tol)
  (and (<= (- (car (car bb)) tol) (car p) (+ (car (cadr bb)) tol))
       (<= (- (cadr (car bb)) tol) (cadr p) (+ (cadr (cadr bb)) tol))
       (<= (- (caddr (car bb)) tol) (caddr p) (+ (caddr (cadr bb)) tol))))

;; Does the solid's box match a cylinder a->b of radius r? (T when no box available)
;; Box must hold both axis ends and be no bigger than the ideal box + r per side
;; (AutoCAD boxes of sloped solids are not always tight).
(defun med3d-check-line (obj a b r / bb d tol ok i ext lo hi)
  (setq bb (med3d-bbox obj)
        d  (med3d-unit (med3d-v- b a))
        tol (+ (* 0.02 r) (* 1e-9 (med3d-maxabs (list a b))) 1e-6))
  (if (not bb)
    T
    (progn
      (setq ok (and (med3d-bb-has bb a tol) (med3d-bb-has bb b tol)) i 0)
      (repeat 3
        (setq ext (* r (sqrt (max 0.0 (- 1.0 (* (nth i d) (nth i d))))))
              lo  (- (min (nth i a) (nth i b)) ext r tol)
              hi  (+ (max (nth i a) (nth i b)) ext r tol))
        (if (or (< (nth i (car bb)) lo) (> (nth i (cadr bb)) hi)) (setq ok nil))
        (setq i (1+ i)))
      ok)))

;; arc solid box must hold the arc start, end and mid point
(defun med3d-check-arc (obj a c nn th r / bb v m tol)
  (setq bb  (med3d-bbox obj)
        v   (med3d-v- a c)
        m   (med3d-v+ c (med3d-v+ (med3d-vx v (cos (/ th 2.0)))
                                  (med3d-vx (med3d-cross nn v) (sin (/ th 2.0)))))
        tol (+ (* 0.02 r) (* 1e-9 (med3d-maxabs (list a c))) 1e-6))
  (or (not bb)
      (and (med3d-bb-has bb a tol) (med3d-bb-has bb m tol)
           (med3d-bb-has bb (med3d-v+ c (med3d-v+ (med3d-vx v (cos th)) (med3d-vx (med3d-cross nn v) (sin th)))) tol))))

;;; ------------------------------------------------------------------ straights
;; Straight a->b. 1st: AddExtrudedSolidAlongPath with a temp LINE a->b (direction
;; and length come from the path, nothing to guess). Checked against its box;
;; if wrong or failed: circle + _.EXTRUDE _Direction a b. (c0c08c2 used
;; AddExtrudedSolid + a centroid flip, which cannot repair an extrusion that went
;; sideways/vertical - the flip only handles +/- the segment direction.)
(defun med3d-solid-line (ms a b r lay / d reg ln sol)
  (setq d (med3d-unit (med3d-v- b a)))
  (if d
    (progn
      (if (setq reg (med3d-region ms a d r lay))
        (progn
          (setq ln  (vl-catch-all-apply 'vlax-invoke (list ms 'AddLine a b))
                sol (if (vl-catch-all-error-p ln)
                      ln
                      (vl-catch-all-apply 'vlax-invoke (list ms 'AddExtrudedSolidAlongPath reg ln))))
          (if (not (vl-catch-all-error-p ln)) (vla-delete ln))
          (vla-delete reg)
          (cond
            ((vl-catch-all-error-p sol)
              (med3d-dbg (strcat "  AlongPath failed: " (vl-catch-all-error-message sol)))
              (setq sol nil))
            ((not (med3d-check-line sol a b r))
              (med3d-dbg (strcat "  AlongPath box wrong " (med3d-bbstr (med3d-bbox sol)) " - retry EXTRUDE"))
              (vla-delete sol)
              (setq sol nil)))))
      (if (not sol) (setq sol (med3d-extrude-dir a b r lay)))
      sol)))

;; fallback straight: entmake circle at a (normal a->b) + _.EXTRUDE _Direction a b
(defun med3d-extrude-dir (a b r lay / d circ e obj)
  (setq d (med3d-unit (med3d-v- b a)))
  (if (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 (trans a 0 d)) (cons 40 r) (cons 210 d)))
    (progn
      (setq circ (entlast))
      (command "_.EXTRUDE" circ "" "_Direction" (trans a 0 1) (trans b 0 1))
      (if (> (getvar "CMDACTIVE") 0) (command))   ; cancel if left waiting
      (setq e (entlast))
      (if (entget circ) (entdel circ))
      (if (and e (not (eq e circ)) (entget e) (= (cdr (assoc 0 (entget e))) "3DSOLID"))
        (progn
          (setq obj (vlax-ename->vla-object e))
          (if (not (med3d-check-line obj a b r))
            (med3d-dbg (strcat "  EXTRUDE box still wrong " (med3d-bbstr (med3d-bbox obj)))))
          obj)
        (progn (med3d-dbg "  EXTRUDE _Direction made no solid") nil)))))

(defun med3d-solid-arc (ms a c nn th r lay / tn reg sol)
  (setq tn (med3d-unit (med3d-cross nn (med3d-v- a c))))
  (if (and tn (setq reg (med3d-region ms a tn r lay)))
    (progn
      (setq sol (vl-catch-all-apply 'vlax-invoke (list ms 'AddRevolvedSolid reg c nn th)))
      ;; wrong way round? revolve about the opposite axis
      (if (and (not (vl-catch-all-error-p sol)) (not (med3d-check-arc sol a c nn th r)))
        (progn
          (med3d-dbg (strcat "  revolve box wrong " (med3d-bbstr (med3d-bbox sol)) " - reversing axis"))
          (vla-delete sol)
          (setq sol (vl-catch-all-apply 'vlax-invoke
                      (list ms 'AddRevolvedSolid reg c (med3d-vx nn -1.0) th)))))
      (vla-delete reg)
      (cond
        ((vl-catch-all-error-p sol)
          (med3d-dbg (strcat "  revolve failed: " (vl-catch-all-error-message sol))) nil)
        (T sol)))))

(defun med3d-solid-sphere (ms p r / s)
  (setq s (vl-catch-all-apply 'vlax-invoke (list ms 'AddSphere p r)))
  (if (not (vl-catch-all-error-p s)) s))

;; ActiveX pieces unioned. Returns (main-ename extra-enames fails)
(defun med3d-draw-pieces (plan lay / ms r sols s base res fails extras k)
  (setq ms (med3d-ms) r (* 0.5 (med3d-get "OD" plan)) sols nil fails 0 extras nil k 0)
  (foreach p (med3d-get "PIECES" plan)
    (setq k (1+ k))
    (med3d-dbg (strcat "piece " (itoa k) " " (car p) " "
                       (if (= (car p) "S")
                         (strcat "at " (med3d-ptstr (nth 1 p)) " r " (rtos (nth 2 p) 2 3))
                         (strcat (med3d-ptstr (nth 1 p)) " -> " (med3d-ptstr (nth 2 p))
                                 (if (= (car p) "L")
                                   (strcat " len " (rtos (distance (nth 1 p) (nth 2 p)) 2 3))
                                   (strcat " ctr " (med3d-ptstr (nth 3 p)) " "
                                           (med3d-deg (nth 5 p)) " deg"))))))
    (setq s (cond
              ((= (car p) "L") (med3d-solid-line ms (nth 1 p) (nth 2 p) r lay))
              ((= (car p) "A") (med3d-solid-arc ms (nth 1 p) (nth 3 p) (nth 4 p) (nth 5 p) r lay))
              ((= (car p) "S") (med3d-solid-sphere ms (nth 1 p) (nth 2 p)))))
    (med3d-dbg (strcat "  solid box " (if s (med3d-bbstr (med3d-bbox s)) "NONE")))
    (if s (setq sols (cons s sols)) (setq fails (1+ fails))))
  (setq sols (reverse sols))
  (if sols
    (progn
      (setq base (car sols))
      (foreach s (cdr sols)
        (setq res (vl-catch-all-apply 'vlax-invoke (list base 'Boolean 0 s))) ; 0 = acUnion
        (if (vl-catch-all-error-p res)
          (progn
            (med3d-dbg (strcat "  union failed: " (vl-catch-all-error-message res)))
            (vla-put-Layer s lay)
            (setq extras (cons (vlax-vla-object->ename s) extras) fails (1+ fails)))))
      (vla-put-Layer base lay)
      (med3d-dbg (strcat "run solid box " (med3d-bbstr (med3d-bbox base))))
      (list (vlax-vla-object->ename base) extras fails))
    (list nil nil fails)))

;; plane normal when every piece lies in one plane, else nil
(defun med3d-planar-normal (plan / pcs n p0 ok d tol)
  (setq pcs (med3d-get "PIECES" plan) n nil d nil)
  (foreach p pcs
    (if (and (not n) (= (car p) "A")) (setq n (med3d-unit (nth 4 p)))))
  (if (not n)
    (foreach p pcs
      (if (and (not n) (= (car p) "L"))
        (if (not d)
          (setq d (med3d-unit (med3d-v- (nth 2 p) (nth 1 p))))
          (setq n (med3d-unit (med3d-cross d (med3d-v- (nth 2 p) (nth 1 p)))))))))
  (if (and (not n) d)   ; one straight line: any plane holding it
    (setq n (med3d-unit (med3d-cross d (if (< (abs (caddr d)) 0.9) '(0.0 0.0 1.0) '(1.0 0.0 0.0))))))
  (if n
    (progn
      (setq p0  (nth 1 (car pcs)) ok T
            tol (max 1e-6 (* 1e-9 (med3d-maxabs (mapcar 'cadr pcs)))))
      (foreach p pcs
        (if (> (abs (med3d-dot (med3d-v- (nth 1 p) p0) n)) tol) (setq ok nil))
        (if (and (/= (car p) "S") (> (abs (med3d-dot (med3d-v- (nth 2 p) p0) n)) tol)) (setq ok nil))
        (if (and (= (car p) "A") (< (abs (med3d-dot (nth 4 p) n)) (- 1.0 1e-9))) (setq ok nil)))
      (if ok n))))

;; filleted centerline as one LWPOLYLINE in the run plane
(defun med3d-make-lw-path (plan n lay / pcs closed ed ocs b)
  (setq pcs (med3d-get "PIECES" plan) closed (med3d-get "CLOSED" plan))
  (setq ed (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lay) '(100 . "AcDbPolyline")
                 (cons 90 (if closed (length pcs) (1+ (length pcs))))
                 (cons 70 (if closed 1 0))
                 (cons 38 (caddr (trans (nth 1 (car pcs)) 0 n)))))
  (foreach p pcs
    (setq ocs (trans (nth 1 p) 0 n)
          b   (if (= (car p) "A")
                (* (if (< (med3d-dot (nth 4 p) n) 0.0) -1.0 1.0) (med3d-tan (/ (nth 5 p) 4.0)))
                0.0)
          ed  (append ed (list (list 10 (car ocs) (cadr ocs)) (cons 42 b)))))
  (if (not closed)
    (setq ocs (trans (nth 2 (car (reverse pcs))) 0 n)
          ed  (append ed (list (list 10 (car ocs) (cadr ocs)) (cons 42 0.0)))))
  (setq ed (append ed (list (cons 210 n))))
  (if (entmake ed) (entlast)))

(defun med3d-has-spheres (plan / r)
  (foreach p (med3d-get "PIECES" plan) (if (= (car p) "S") (setq r T)))
  r)

;; SWEEP one circle along the filleted centerline (planar runs, no sharp corners)
(defun med3d-draw-sweep (plan lay / n path pc0 a tn circ sol typ)
  (cond
    ((med3d-has-spheres plan) (med3d-dbg "method PIECES: run has sphere corners (flag/kink)") nil)
    ((not (setq n (med3d-planar-normal plan))) (med3d-dbg "method PIECES: run is not planar") nil)
    ((not (setq path (med3d-make-lw-path plan n lay)))
      (med3d-dbg "method PIECES: could not entmake the LWPOLYLINE centerline") nil)
    (T
      (med3d-dbg (strcat "method SWEEP: plane normal " (med3d-ptstr n)))
      (setq pc0 (car (med3d-get "PIECES" plan))
            a   (nth 1 pc0)
            tn  (if (= (car pc0) "L")
                  (med3d-unit (med3d-v- (nth 2 pc0) a))
                  (med3d-unit (med3d-cross (nth 4 pc0) (med3d-v- a (nth 3 pc0))))))
      (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 (trans a 0 tn))
                     (cons 40 (* 0.5 (med3d-get "OD" plan))) (cons 210 tn)))
      (setq circ (entlast))
      ;; MOde SOlid so a surface is never made (SWEEP remembers the mode)
      (command "_.SWEEP" "_MO" "_SO" circ "" path)
      (if (> (getvar "CMDACTIVE") 0) (command))   ; cancel if left waiting
      (setq sol (entlast))
      (if (entget path) (entdel path))
      (if (entget circ) (entdel circ))
      (setq typ (if (and sol (entget sol)) (cdr (assoc 0 (entget sol)))))
      (cond
        ((or (null typ) (eq sol circ) (eq sol path))
          (med3d-dbg "SWEEP made nothing - falling back to PIECES") nil)
        ((/= typ "3DSOLID")
          (med3d-dbg (strcat "SWEEP made a " typ " - deleted, falling back to PIECES"))
          (entdel sol) nil)
        (T
          (vla-put-Layer (vlax-ename->vla-object sol) lay)
          (med3d-dbg (strcat "SWEEP solid box " (med3d-bbstr (med3d-bbox (vlax-ename->vla-object sol)))))
          sol)))))

;; draw one entity: returns (solid plan) or nil
(defun med3d-run (ent kind / plan lay sol res extras)
  (if (setq plan (med3d-plan-ent ent kind))
    (progn
      (setq lay (med3d-ensure-layer (med3d-layer-info kind)))
      (med3d-report-flags plan)
      (if (= (strcase *MED3D-METHOD*) "SWEEP") (setq sol (med3d-draw-sweep plan lay)))
      (if (not sol)
        (setq res (med3d-draw-pieces plan lay) sol (car res) extras (cadr res)))
      (if (and res (> (caddr res) 0))
        (princ (strcat "\nMED3D: run " (med3d-get "HANDLE" plan) " - "
                       (itoa (caddr res)) " piece(s) failed or would not union.")))
      (foreach s (if sol (cons sol extras) extras)
        (MEDStamp3DFromBom s ent kind nil))
      (setq *MED3D-LAST-PLANS* (cons (append plan (list (cons "SOLID" sol))) *MED3D-LAST-PLANS*))
      (if sol (list sol plan)))))

(defun med3d-run-ss (ss kind / i ok)
  (setq i 0 ok 0)
  (repeat (sslength ss)
    (if (med3d-run (ssname ss i) kind) (setq ok (1+ ok)))
    (setq i (1+ i)))
  ok)

;;; ------------------------------------------------------ house rules / errors
(defun med3d-begin (tag)
  (setq *MED3D-OLD*    (list (getvar "OSMODE") (getvar "CMDECHO") (getvar "CLAYER"))
        *MED3D-OLDERR* *error*
        *MED3D-TAG*    tag
        _MEDCONDUITOD_CACHE nil
        *MED3D-CABLEOD-CACHE* nil)
  (defun *error* (msg)
    (med3d-end)
    (if (and msg (/= msg "") (not (wcmatch (strcase msg T) "*break*,*cancel*,*exit*")))
      (princ (strcat "\n" *MED3D-TAG* ": " msg)))
    (princ))
  (setvar "OSMODE" 0)
  (setvar "CMDECHO" 0))

(defun med3d-end ()
  (if *MED3D-OLD*
    (progn
      (setvar "OSMODE" (nth 0 *MED3D-OLD*))
      (setvar "CMDECHO" (nth 1 *MED3D-OLD*))
      (if (tblsearch "LAYER" (nth 2 *MED3D-OLD*)) (setvar "CLAYER" (nth 2 *MED3D-OLD*)))))
  (setq *error* *MED3D-OLDERR* *MED3D-OLD* nil *MED3D-OLDERR* nil)
  (princ))

(defun med3d-filter (app)
  (list '(-4 . "<OR") '(0 . "LWPOLYLINE") '(0 . "POLYLINE") '(-4 . "OR>") (list -3 (list app))))

;;; ------------------------------------------------------------------ commands
;; kind of a run from its xdata; pref wins when both are present
(defun med3d-kind-of (e pref / cn cb)
  (setq cn (xdataget e _CONDUIT) cb (xdataget e _CABLE))
  (cond
    ((and cn cb) pref)
    (cn "CONDUIT")
    (cb "CABLE")))

;; M3D / C3D: select polylines (no xdata filter, so nothing vanishes silently),
;; convert each by its own xdata (conduit or cable), and say why any is skipped.
(defun med3d-pick (kind tag / ss ok i e k n)
  (med3d-begin tag)
  (princ (strcat "\nSelect MED " (strcase kind T) " runs: "))
  (if (setq ss (ssget '((-4 . "<OR") (0 . "LWPOLYLINE") (0 . "POLYLINE") (-4 . "OR>"))))
    (progn
      (setq ok 0 n 0 i 0)
      (repeat (sslength ss)
        (setq e (ssname ss i) k (med3d-kind-of e kind))
        (cond
          ((not k)
            (princ (strcat "\n" tag ": " (cdr (assoc 5 (entget e))) " ("
                           (cdr (assoc 0 (entget e))) ") has no MED_CONDUIT / MED_CABLE xdata - skipped.")))
          (T
            (setq n (1+ n))
            (if (/= k kind)
              (princ (strcat "\n" tag ": " (cdr (assoc 5 (entget e))) " is a " (strcase k T)
                             " run - converted as " (strcase k T) ".")))
            (if (med3d-run e k) (setq ok (1+ ok)))))
        (setq i (1+ i)))
      (princ (strcat "\n" tag ": " (itoa ok) " of " (itoa n) " MED run(s) converted"
                     (if (< n (sslength ss)) (strcat ", " (itoa (- (sslength ss) n)) " polyline(s) without MED data") "")
                     "."))
      (if (> ok 0) (MEDRebuildMedPropsJsonBeside nil))))
  (med3d-end))

(defun c:M3D () (med3d-pick "CONDUIT" "M3D"))
(defun c:C3D () (med3d-pick "CABLE" "C3D"))

(defun med3d-export (kind tag / lay ss ok sols fmt fname)
  (med3d-begin tag)
  (setq *MED3D-LAST-PLANS* nil
        lay (med3d-ensure-layer (med3d-layer-info kind)))
  (med3d-clear-flags)
  (command "_.VPOINT" "1,1,1")
  (initget "Dwg Layer")
  (setq fmt (getkword (strcat "\n" tag " output to [Dwg/Layer] <Dwg>: ")))
  (if (not fmt) (setq fmt "Dwg"))
  (setq ss (ssget "_X" (med3d-filter (if (= kind "CABLE") _CABLE _CONDUIT)))
        ok (if ss (med3d-run-ss ss kind) 0))
  (princ (strcat "\n" tag ": " (itoa ok) " of " (itoa (if ss (sslength ss) 0)) " run(s) converted."))
  (setq sols (ssget "_X" (list '(0 . "3DSOLID") (cons 8 lay))))
  (cond
    ((not sols) (princ "\nNo solids to export."))
    ((= fmt "Dwg")
      (setq fname (getfiled (strcat "Select file name for " tag " output") (getvar "DWGPREFIX") "dwg" 1))
      (if fname
        (progn
          (if (findfile fname)
            (command "_.-WBLOCK" fname "_Y" "")
            (command "_.-WBLOCK" fname ""))
          (command "0,0,0" sols "")
          (command "_.PLAN" "")
          (if (findfile fname) (MEDRebuildMedPropsJsonBeside fname)))))
    (T
      (prompt "\nUse the PLAN command to return to plan view.")
      (MEDRebuildMedPropsJsonBeside nil)))
  (med3d-end))

(defun c:Make3DConduit () (med3d-export "CONDUIT" "MAKE3DCONDUIT"))
(defun c:Make3DCable () (med3d-export "CABLE" "MAKE3DCABLE"))

;; corner table of one run, no solids
(defun med3d-print-plan (plan)
  (princ (strcat "\nRun " (med3d-get "HANDLE" plan) " " (med3d-get "KIND" plan)
                 " OD " (rtos (med3d-get "OD" plan) 2 3) " R " (rtos (med3d-get "R" plan) 2 3)
                 (if (med3d-get "CLOSED" plan) " closed" "")
                 ", " (itoa (length (med3d-get "PIECES" plan))) " piece(s)"))
  (foreach c (med3d-get "CORNERS" plan)
    (princ (strcat "\n  v" (itoa (1+ (med3d-get "INDEX" c)))
                   "  " (med3d-deg (med3d-get "ANGLE" c)) " deg  " (med3d-get "STATUS" c)
                   "  T " (med3d-rtos (med3d-get "NEED" c))
                   "  avail " (rtos (med3d-get "AVAIL" c) 2 3))))
  (princ))

(defun c:MED3DPLAN ( / e kind plan)
  (if (setq e (car (entsel "\nSelect MED conduit or cable run: ")))
    (progn
      (setq kind (cond ((xdataget e _CONDUIT) "CONDUIT") ((xdataget e _CABLE) "CABLE")))
      (if (and kind (setq plan (med3d-plan-ent e kind)))
        (med3d-print-plan plan)
        (princ "\nNot a MED conduit/cable run with an OD."))))
  (princ))

(princ "Done.")
(princ)
