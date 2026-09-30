;;; MED3DPath.lsp - unified 3D solids for MED conduit and cable runs (AutoCAD 2024+).
;;;
;;; Commands
;;;   M3D            conduit runs you select   -> one 3DSOLID per run on MED_3DCONDUIT
;;;   C3D            cable runs you select     -> one 3DSOLID per run on MED_3DCABLE
;;;   MAKE3DCONDUIT  every MED_CONDUIT run     -> Dwg / Layer output like MAKE3DTRAY
;;;   MAKE3DCABLE    every MED_CABLE run       -> Dwg / Layer output like MAKE3DTRAY
;;;   MEDMAKE3D      tray + tray fittings (MED3DTrayFunctions, med3d-tray-build),
;;;                  then conduit bodies are resolved (MED3DFittings medcb-collect),
;;;                  then every conduit run (cut back to the body hubs), then the
;;;                  body blocks, then every cable run -> one prompt
;;;                  [Dwg/Layer]: one combined DWG + one .medprops.json sidecar,
;;;                  or all solids left on their layers; prints a summary
;;;   MED3DPLAN      print the corner table of one run (no solids)
;;;   MED3DVER       print this file's version and who owns the commands
;;; The 2012 code stays in MED3DCON.lsp as M3DOLD / MAKE3DCONDUITOLD.
;;; Load order: MEDCore loads this file last among the MED files. If an old,
;;; unrenamed MED3DCON.lsp (2012 c:M3D / c:MAKE3DCONDUIT) is loaded later, the
;;; command names are taken back: med3d-claim-commands runs at the end of this
;;; file, from the new MED3DCON.lsp, and (lisp reactor) just before M3D, C3D,
;;; MAKE3DCONDUIT or MAKE3DCABLE starts.
;;;
;;; Paths: LWPOLYLINE, 2D heavy POLYLINE (bulges kept as drawn), 3D POLYLINE.
;;;   Vertices go to WCS with trans (OCS + elevation). Meshes are skipped.
;;; OD: conduit = med_conduit_od (MED_CONDUIT code + trade size);
;;;     cable   = MEDType.USER3 for the MED_CABLE code. No OD = run skipped.
;;; Bends: every corner between two straights gets a fillet of radius
;;;   (med3d-bend-radius kind od override) = 5 x OD conduit, 7 x OD cable. Tangent
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
;;; Conduit bodies (MEDMAKE3D only): *MED3D-FITS* = ((handle pt hubs) ...), hubs =
;;;   ((name face-offset outward-dir) ...) in WCS, face offset relative to pt. A run
;;;   vertex / open end within *MED3D-FIT-TOL* (XY) of pt is a body joint: no fillet,
;;;   no sphere, not flagged (STATUS "FITTING"); each straight leg is cut back to the
;;;   hub face whose outward direction is within *MED3D-FIT-ANG* degrees of the leg.
;;;   No such hub -> leg left uncut and FLAGGED ("FITFLAGS"). A run that passes
;;;   straight through a body (C, T run) stays continuous. Runs cut at an inner
;;;   body joint have "GAPS" and are drawn as PIECES.
;;; Workers (no prompts; wrap in med3d-begin / med3d-end):
;;;   (med3d-path-build-all kind) -> converts every MED run of kind, returns
;;;     (("KIND" . k) ("RUNS" . n) ("OK" . n) ("SOLIDS" enames...) ("FLAGGED" . n)
;;;      ("SKIPPED" (handle kind reason) ...))
;;;   (med3d-tray-build) in MED3DTrayFunctions.lsp -> (tray-solids fitting-solids skipped)

(princ "\rLoading MED3DPath...")
(vl-load-com)
(setq *MED3D-VERSION* "2026-09-30 r11 (feature/3dpath)")

;;; ------------------------------------------------------------------ settings
(if (not *MED3D-BEND-FACTOR*) (setq *MED3D-BEND-FACTOR* 5.0))  ; conduit R = factor x OD
(if (not *MED3D-CABLE-BEND-FACTOR*) (setq *MED3D-CABLE-BEND-FACTOR* 7.0))  ; cable R = factor x OD
(if (not *MED3D-METHOD*) (setq *MED3D-METHOD* "SWEEP"))       ; "SWEEP" or "PIECES"
;; per-run bend override: list of (handle . override), see med3d-bend-radius
(if (not (boundp '*MED3D-BEND-OVERRIDES*)) (setq *MED3D-BEND-OVERRIDES* nil))
;; Debug output: each run's path, method choice, every piece's planned
;; start/end and the bounding box of the solid actually created.
;;   *MED3D-DEBUG* nil (default) -> follow the global MED debug flag
;;                                  (MEDDEBUG command / *MED-DEBUG* / (med-debug-p))
;;   (setq *MED3D-DEBUG* T)      -> always on for MED3DPath
;;   (setq *MED3D-DEBUG* "OFF")  -> always off for MED3DPath, even if MEDDEBUG is on
(if (not (boundp '*MED3D-DEBUG*)) (setq *MED3D-DEBUG* nil))
;; vertices closer than factor x OD to the previous kept vertex are dropped
;; (tiny jogs / near-duplicate vertices in 3D polylines would otherwise leave a
;; segment too short for any bend and force spheres at both its corners)
(if (not *MED3D-DUP-FACTOR*) (setq *MED3D-DUP-FACTOR* 0.1))
;; conduit bodies (MEDMAKE3D): XY distance body point <-> run vertex (drawing units)
;; and the largest angle between a conduit leg and the hub it is cut back to
(if (not *MED3D-FIT-TOL*) (setq *MED3D-FIT-TOL* 0.25))
(if (not *MED3D-FIT-ANG*) (setq *MED3D-FIT-ANG* 30.0))
(setq *MED3D-FITS* nil *MED3D-ENDTRIM* nil)   ; set by MEDMAKE3D / med3d-plan only
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
;; Single place for bend radius rules. kind "CONDUIT" | "CABLE".
;; override: nil -> *MED3D-BEND-FACTOR* (5) x OD for conduit,
;;           *MED3D-CABLE-BEND-FACTOR* (7) x OD for cable; number -> that radius;
;;           ("FACTOR" . n) -> n x OD. Later: per-bend lists, long-radius tables.
(defun med3d-bend-radius (kind od override)
  (cond
    ((and (numberp override) (> override 0.0)) (float override))
    ((and (listp override) (= (car override) "FACTOR") (numberp (cdr override)))
      (* (cdr override) od))
    ((= kind "CABLE") (* *MED3D-CABLE-BEND-FACTOR* od))
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
(defun med3d-build-segs (pts buls nrm closed / i np nb ni n segs p q b arc dt)
  (setq i 0 np nil nb nil ni nil
        dt (if (and (numberp *MED3D-DUP-TOL*) (> *MED3D-DUP-TOL* *MED3D-TOL*)) *MED3D-DUP-TOL* *MED3D-TOL*))
  (foreach p pts
    (if (and np (< (distance p (car np)) dt))
      (progn                                          ; (near) zero-length segment dropped
        (if (> (distance p (car np)) *MED3D-TOL*)
          (setq *MED3D-DROPPED* (cons (list i (distance p (car np))) *MED3D-DROPPED*)))
        (setq nb (cons (nth i buls) (cdr nb))))
      (setq np (cons p np) nb (cons (nth i buls) nb) ni (cons i ni)))
    (setq i (1+ i)))
  (setq np (reverse np) nb (reverse nb) ni (reverse ni))
  (if (and (> (length np) 2) (< (distance (car np) (car (reverse np))) dt))
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
  (setq eps 1e-9 lens (med3d-fit-lens (mapcar 'med3d-seg-len segs) joints closed) i 0 stats nil forced nil cands nil)
  (foreach j joints
    (setq f (or (= (nth 4 j) "R") (= (nth 4 j) "F")
                (and (= (nth 4 j) "C")
                     (or (> (nth 5 j) (+ (nth (nth 2 j) lens) eps))
                         (> (nth 5 j) (+ (nth (nth 3 j) lens) eps))))))
    (setq forced (cons f forced)
          stats  (cons (cond ((= (nth 4 j) "K") "KINK") ((= (nth 4 j) "F") "FITTING") (T "FLAGGED")) stats))
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

;;; ------------------------------------------------------------ conduit bodies
;; body of *MED3D-FITS* at WCS point p: XY within the body's search radius (4th item:
;; medblck.dat break x insert scale + *MED3D-FIT-TOL*, else *MED3D-FIT-TOL*), Z within
;; max(*MED3D-FIT-TOL*, od)
(defun med3d-fit-at (p od / tol r)
  (foreach f *MED3D-FITS*
    (setq tol (max (if (numberp (nth 3 f)) (nth 3 f) *MED3D-FIT-TOL*) 1e-6))
    (if (and (not r)
             (<= (distance (list (car p) (cadr p)) (list (car (cadr f)) (cadr (cadr f)))) tol)
             (<= (abs (- (caddr p) (caddr (cadr f)))) (max *MED3D-FIT-TOL* od)))
      (setq r f)))
  r)
;; cut-back along leg u (unit, pointing away from the body) for the run end / vertex p:
;; (distance . T) from p to the face of the hub pointing along u (within
;; *MED3D-FIT-ANG*); negative = the run stops short of the face (menu break) and is
;; extended to it. (0.0 . nil) if no hub points along u.
(defun med3d-fit-trim (f u p / best r d off)
  (setq best (cos (/ (* pi *MED3D-FIT-ANG*) 180.0)))
  (foreach h (caddr f)
    (if (>= (setq d (med3d-dot (caddr h) u)) best) (setq best d r h)))
  (setq off (if p (med3d-dot (list (- (car p) (car (cadr f))) (- (cadr p) (cadr (cadr f))) 0.0) u) 0.0))
  (if r (cons (- (max 0.0 (med3d-dot (cadr r) u)) off) T) (cons 0.0 nil)))
;; joints at a body become ("F" ...): (V th kin kout "F" 0.0 vidx d1 d2 cut-in cut-out handle).
;; Returns (joints (cut-at-start cut-at-end) fitflags hits); fitflags = ((point handle vidx) ...)
(defun med3d-fit-joints (segs joints closed od / out flags hits f s r ci co bad n p cs ce)
  (setq cs 0.0 ce 0.0)
  (foreach j joints
    (if (setq f (med3d-fit-at (nth 0 j) od))
      (progn
        (setq ci 0.0 co 0.0 bad nil hits (cons (car f) hits))
        (if (= (car (nth (nth 2 j) segs)) "L")
          (setq r (med3d-fit-trim f (med3d-vx (nth 7 j) -1.0) (nth 0 j)) ci (car r) bad (not (cdr r))))
        (if (= (car (nth (nth 3 j) segs)) "L")
          (setq r (med3d-fit-trim f (nth 8 j) (nth 0 j)) co (car r) bad (or bad (not (cdr r)))))
        (if bad (setq flags (cons (list (nth 0 j) (car f) (nth 6 j)) flags)))
        (setq out (cons (list (nth 0 j) (nth 1 j) (nth 2 j) (nth 3 j) "F" 0.0 (nth 6 j) (nth 7 j) (nth 8 j)
                              ci co (car f))
                        out)))
      (setq out (cons j out))))
  (if (not closed)
    (progn
      (setq n (length segs) s (car segs) p (nth 1 s))
      (if (and (= (car s) "L") (setq f (med3d-fit-at p od)))
        (progn
          (setq r (med3d-fit-trim f (med3d-seg-tin s) p) cs (car r) hits (cons (car f) hits))
          (if (not (cdr r)) (setq flags (cons (list p (car f) (nth 3 s)) flags)))))
      (setq s (nth (1- n) segs) p (nth 2 s))
      (if (and (= (car s) "L") (setq f (med3d-fit-at p od)))
        (progn
          (setq r (med3d-fit-trim f (med3d-vx (med3d-seg-tout s) -1.0) p) ce (car r) hits (cons (car f) hits))
          (if (not (cdr r)) (setq flags (cons (list p (car f) (nth 4 s)) flags)))))))
  (list (reverse out) (list cs ce) (reverse flags) (reverse hits)))
;; segment lengths minus the body cut-backs (so bends next to a body still fit)
(defun med3d-fit-lens (lens joints closed / n)
  (foreach j joints
    (if (= (nth 4 j) "F")
      (setq lens (med3d-set-nth lens (nth 2 j) (- (nth (nth 2 j) lens) (nth 9 j)))
            lens (med3d-set-nth lens (nth 3 j) (- (nth (nth 3 j) lens) (nth 10 j))))))
  (if (and (not closed) *MED3D-ENDTRIM* lens)
    (setq n (length lens)
          lens (med3d-set-nth lens 0 (- (car lens) (car *MED3D-ENDTRIM*)))
          lens (med3d-set-nth lens (1- n) (- (nth (1- n) lens) (cadr *MED3D-ENDTRIM*)))))
  lens)

;;; ---------------------------------------------------------------------- plan
(defun med3d-corner-by (corners key k / r cc)
  (foreach cc corners (if (= (med3d-get key cc) k) (setq r cc)))
  r)

;; Pure geometry: WCS vertices -> plan alist
;;   ("SEGS" ...) ("CORNERS" ...) ("PIECES" ...) ("CLOSED" . flag) ("OD" . od) ("R" . R)
;; pieces: ("L" A B) | ("A" A B C N th) | ("S" P radius), in path order.
(defun med3d-plan (pts buls nrm closed od kind override / *MED3D-DUP-TOL* *MED3D-ENDTRIM* bs segs R joints fj gaps al stats avails rs corners i st th d1 d2 tt pin pout n1 c nn pieces k cs ce d a b)
  (setq *MED3D-DUP-TOL* (* *MED3D-DUP-FACTOR* od)
        *MED3D-DROPPED* nil
        bs (med3d-build-segs pts buls nrm closed))
  (if (and bs (car bs))
    (progn
      (setq segs   (car bs)
            closed (cadr bs)
            R      (med3d-bend-radius kind od override)
            joints (med3d-joints segs closed R)
            fj     (if (and *MED3D-FITS* (= kind "CONDUIT"))
                     (med3d-fit-joints segs joints closed od)
                     (list joints nil nil nil))
            joints (car fj)
            *MED3D-ENDTRIM* (cadr fj)
            al     (med3d-allocate segs joints closed)
            stats  (car al)
            avails (cadr al)
            rs     (* 0.5 od)
            corners nil
            i 0)
      (foreach j joints
        (setq th (nth 1 j) d1 (nth 7 j) d2 (nth 8 j) st (nth i stats))
        (cond
          ((= st "FITTED")
            (setq tt   (nth 5 j)
                  pin  (med3d-v- (nth 0 j) (med3d-vx d1 tt))
                  pout (med3d-v+ (nth 0 j) (med3d-vx d2 tt))
                  n1   (med3d-unit (med3d-v- d2 (med3d-vx d1 (med3d-dot d1 d2))))
                  c    (med3d-v+ pin (med3d-vx n1 R))
                  nn   (med3d-unit (med3d-cross d1 d2))))
          ((= st "FITTING")            ; conduit body: straights cut back to the hub faces
            (setq tt 0.0 c nil nn nil
                  pin  (med3d-v- (nth 0 j) (med3d-vx d1 (nth 9 j)))
                  pout (med3d-v+ (nth 0 j) (med3d-vx d2 (nth 10 j)))))
          (T (setq tt 0.0 pin (nth 0 j) pout (nth 0 j) c nil nn nil)))
        (setq corners
               (cons (list (cons "INDEX" (nth 6 j)) (cons "VERTEX" (nth 0 j)) (cons "ANGLE" th)
                           (cons "RADIUS" (if (= st "FITTED") R nil))
                           (cons "TANGENT" tt) (cons "PTIN" pin) (cons "PTOUT" pout)
                           (cons "CENTER" c) (cons "NORMAL" nn) (cons "TIN" d1) (cons "TOUT" d2)
                           (cons "STATUS" st) (cons "NEED" (nth 5 j)) (cons "AVAIL" (nth i avails))
                           (cons "SEGIN" (nth 2 j)) (cons "SEGOUT" (nth 3 j))
                           (cons "FITTING" (if (= st "FITTING") (nth 11 j))))
                     corners)
              i (1+ i)))
      (setq corners (reverse corners) pieces nil k 0)
      (foreach s segs
        (setq cs (med3d-corner-by corners "SEGOUT" k)
              ce (med3d-corner-by corners "SEGIN" k))
        (if (= (car s) "L")
          (progn
            (setq d (med3d-seg-tin s)
                  a (cond ((and cs (member (med3d-get "STATUS" cs) '("FITTED" "FITTING"))) (med3d-get "PTOUT" cs))
                          ((and (= k 0) (not closed) *MED3D-ENDTRIM*)
                            (med3d-v+ (nth 1 s) (med3d-vx d (car *MED3D-ENDTRIM*))))
                          (T (nth 1 s)))
                  b (cond ((and ce (member (med3d-get "STATUS" ce) '("FITTED" "FITTING"))) (med3d-get "PTIN" ce))
                          ((and (= k (1- (length segs))) (not closed) *MED3D-ENDTRIM*)
                            (med3d-v- (nth 2 s) (med3d-vx d (cadr *MED3D-ENDTRIM*))))
                          (T (nth 2 s))))
            (if (> (med3d-dot (med3d-v- b a) d) *MED3D-TOL*)
              (setq pieces (cons (list "L" a b) pieces))))
          (setq pieces (cons (list "A" (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s) (nth 5 s)) pieces)))
        (if ce
          (cond
            ((= (med3d-get "STATUS" ce) "FITTED")
              (setq pieces (cons (list "A" (med3d-get "PTIN" ce) (med3d-get "PTOUT" ce)
                                       (med3d-get "CENTER" ce) (med3d-get "NORMAL" ce)
                                       (med3d-get "ANGLE" ce))
                                 pieces)))
            ((= (med3d-get "STATUS" ce) "FITTING") (setq gaps T))   ; the body fills the gap
            (T (setq pieces (cons (list "S" (med3d-get "VERTEX" ce) rs) pieces)))))
        (setq k (1+ k)))
      (list (cons "SEGS" segs) (cons "CORNERS" corners) (cons "PIECES" (reverse pieces))
            (cons "CLOSED" closed) (cons "OD" od) (cons "R" R)
            (cons "GAPS" gaps) (cons "ENDTRIM" *MED3D-ENDTRIM*)
            (cons "FITFLAGS" (nth 2 fj)) (cons "FITHITS" (nth 3 fj))))))

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

;; SELECT through MED-DotNet with *MED-SQL-QUIET* = T (MED-DotNet then skips its
;; "n row(s)" line). Returns the result list or nil (also on error).
(defun med3d-sql (sql / old res)
  (if (and MED-DotNet-Ready (MED-DotNet-Ready))
    (progn
      (setq old *MED-SQL-QUIET* *MED-SQL-QUIET* T
            res (vl-catch-all-apply 'MEDProcessSQLStatement (list sql))
            *MED-SQL-QUIET* old)
      (if (and res (not (vl-catch-all-error-p res)) (listp res)) res))))

;; One SELECT per command for all conduit ODs / all cable ODs (instead of one per
;; type+size), stored in the caches med_conduit_od / med3d-cable-od read.
(defun med3d-preload-od (kind / res k s v)
  (cond
    ((and (= kind "CONDUIT") (not *MED3D-OD-PRELOADED*))
      (if (setq res (med3d-sql "SELECT ConduitCode, TradeSizeDec, OD_in FROM MEDConduitOD WHERE OD_in IS NOT NULL"))
        (progn
          (foreach row (cdr res)
            (setq k (med3d-num (nth 0 row)) s (med3d-num (nth 1 row)) v (med3d-num (nth 2 row)))
            (if (and k s v (> v 0.0))
              (setq _MEDCONDUITOD_CACHE
                     (cons (cons (list (fix k) (rtos s 2 4)) (float v)) _MEDCONDUITOD_CACHE))))
          (setq *MED3D-OD-PRELOADED* T))))
    ((and (= kind "CABLE") (not *MED3D-CABLEOD-PRELOADED*))
      (if (setq res (med3d-sql "SELECT ITEMCODE, USER3 FROM MEDType WHERE ITEMTYPE='CABLE'"))
        (progn
          (foreach row (cdr res)
            (setq k (med3d-num (nth 0 row)) v (med3d-num (nth 1 row)))
            (if k
              (setq *MED3D-CABLEOD-CACHE*
                     (cons (cons (fix k) (if (and v (> v 0.0)) (float v))) *MED3D-CABLEOD-CACHE*))))
          (setq *MED3D-CABLEOD-PRELOADED* T))))))

;; cable OD (inches) from MEDType.USER3, cached per run of a command
(defun med3d-cable-od (code / key hit res val)
  (if (and (numberp code) (> code 0))
    (progn
      (setq key (fix code))
      (if (setq hit (assoc key *MED3D-CABLEOD-CACHE*))
        (cdr hit)
        (if (and MED-DotNet-Ready (MED-DotNet-Ready))
          (progn
            (setq res (if *MED3D-CABLEOD-PRELOADED*
                        nil          ; not in the preloaded table = no row
                        (med3d-sql (strcat "SELECT USER3 FROM MEDType WHERE ITEMTYPE='CABLE' AND ITEMCODE="
                                           (itoa key)))))
            (if (and res (>= (length res) 2) (listp (cadr res)))
              (setq val (car (cadr res))))
            (if (= (type val) 'STR) (setq val (atof val)))
            (if (not (and (numberp val) (> val 0.0))) (setq val nil))
            (setq *MED3D-CABLEOD-CACHE* (cons (cons key val) *MED3D-CABLEOD-CACHE*))
            val))))))

;; xdata layouts (xdataget): conduit (app tag size code dist msr),
;; cable (app tag size code rtag dist msr)
(defun med3d-run-od (ent kind / xd code size key old res)
  (med3d-preload-od kind)
  (cond
    ((= kind "CONDUIT")
      (if (setq xd (xdataget ent _CONDUIT))
        (progn
          (setq code (med3d-num (nth 3 xd)) size (med3d-num (nth 2 xd)))
          ;; preloaded and not in the table: cache the miss so med_conduit_od falls
          ;; back to getsize without its own query (same result, no extra SELECT)
          (if (and *MED3D-OD-PRELOADED* code size (> code 0) (> size 0.0)
                   (not (assoc (setq key (list (fix code) (rtos size 2 4))) _MEDCONDUITOD_CACHE)))
            (setq _MEDCONDUITOD_CACHE (cons (cons key nil) _MEDCONDUITOD_CACHE)))
          (setq old *MED-SQL-QUIET* *MED-SQL-QUIET* T
                res (vl-catch-all-apply 'med_conduit_od (list code size))
                *MED-SQL-QUIET* old)
          (if (not (vl-catch-all-error-p res)) res))))
    ((= kind "CABLE")
      (if (setq xd (xdataget ent _CABLE))
        (med3d-cable-od (med3d-num (nth 3 xd)))))))

;; skipped run: print why, remember it for the MEDMAKE3D summary; returns nil
(defun med3d-skip (h kind reason)
  (princ (strcat "\nMED3D: " h " skipped - " reason "."))
  (setq *MED3D-SKIPS* (cons (list h kind reason) *MED3D-SKIPS*))
  nil)

;; plan for one entity without drawing (for fittings); nil if skipped
(defun med3d-plan-ent (ent kind / pd od h plan)
  (setq h (cdr (assoc 5 (entget ent))))
  (cond
    ((not (setq pd (med3d-read-path ent)))
      (med3d-skip h kind "not a LWPOLYLINE / 2D / 3D POLYLINE"))
    ((progn
       (med3d-dbg (strcat "run " h " " (cdr (assoc 0 (entget ent)))
                          " flags " (itoa (med3d-dxf 70 (entget ent) 0))
                          " " (itoa (length (car pd))) " vertices"
                          (if (nth 2 pd) (strcat " normal " (med3d-ptstr (nth 2 pd))) " (3D)")
                          (if (nth 3 pd) " closed" "")
                          " first " (med3d-ptstr (car (car pd)))))
       nil))
    ((not (setq od (med3d-run-od ent kind)))
      (med3d-skip h kind (strcat "no OD for this " (strcase kind T) " type/size")))
    ((not (setq plan (med3d-plan (nth 0 pd) (nth 1 pd) (nth 2 pd) (nth 3 pd) od kind
                                 (cdr (assoc h *MED3D-BEND-OVERRIDES*)))))
      (med3d-skip h kind "fewer than 2 distinct points"))
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

;; marker on MED_3DFLAG: 3 axis lines + circle of size s, text txt
(defun med3d-flag-at (v s txt / lay)
  (setq lay (med3d-ensure-layer (med3d-flag-layer)))
  (foreach d '((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
    (entmake (list '(0 . "LINE") (cons 8 lay)
                   (cons 10 (med3d-v- v (med3d-vx d s))) (cons 11 (med3d-v+ v (med3d-vx d s))))))
  (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 v) (cons 40 s)))
  (entmake (list '(0 . "TEXT") (cons 8 lay) (cons 10 (med3d-v+ v (list s s 0.0))) (cons 40 (* 0.5 s))
                 (cons 1 txt))))
(defun med3d-flag-marker (v od h idx)
  (med3d-flag-at v (* 2.0 od) (strcat "3D FLAG " h " v" (itoa (1+ idx)))))

(defun med3d-corner-reason (c)
  (cond
    ((= (med3d-get "STATUS" c) "FITTED")
      (strcat "fits: tangent " (rtos (med3d-get "NEED" c) 2 3) " <= available " (rtos (med3d-get "AVAIL" c) 2 3)))
    ((= (med3d-get "STATUS" c) "KINK") "non-tangent joint at a drawn arc")
    ((= (med3d-get "STATUS" c) "FITTING")
      (strcat "conduit body " (med3d-get "FITTING" c) ": sharp, legs cut back to the hub faces"))
    ((> (med3d-get "NEED" c) 1e90) "reversal (run doubles back)")
    (T (strcat "tangent " (rtos (med3d-get "NEED" c) 2 3) " > available "
               (rtos (max 0.0 (med3d-get "AVAIL" c)) 2 3)
               " (segment too short or shared with a neighbouring bend)"))))

(defun med3d-report-flags (plan / h od st)
  (setq h (med3d-get "HANDLE" plan) od (med3d-get "OD" plan))
  (foreach d (reverse *MED3D-DROPPED*)
    (med3d-dbg (strcat "vertex " (itoa (1+ (car d))) " dropped: only " (rtos (cadr d) 2 4)
                       " from the previous vertex (< " (rtos *MED3D-DUP-FACTOR* 2 2) " x OD)")))
  (med3d-dbg (strcat (itoa (length (med3d-get "CORNERS" plan))) " corner(s), R " (rtos (med3d-get "R" plan) 2 3)
                     ", OD " (rtos od 2 3)))
  (foreach c (med3d-get "CORNERS" plan)
    (med3d-dbg (strcat "corner at vertex " (itoa (1+ (med3d-get "INDEX" c))) " "
                       (med3d-ptstr (med3d-get "VERTEX" c)) " bend " (med3d-deg (med3d-get "ANGLE" c))
                       " deg: " (med3d-get "STATUS" c) " - " (med3d-corner-reason c))))
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
                       " deg) - closed with sphere.")))))
  (foreach ff (med3d-get "FITFLAGS" plan)
    (princ (strcat "\nMED3D FLAG: run " h " vertex " (itoa (1+ (nth 2 ff))) " at conduit body " (nth 1 ff)
                   ": no hub within " (rtos *MED3D-FIT-ANG* 2 0) " deg of the conduit - leg not cut back."))
    (med3d-flag-at (nth 0 ff) (* 2.0 od) (strcat "3D FLAG " h " body " (nth 1 ff)))))

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
;; T when MED3DPath debug output is on (see *MED3D-DEBUG* above)
(defun med3d-debug-on (/ r)
  (cond ((equal *MED3D-DEBUG* "OFF") nil)
        (*MED3D-DEBUG* T)
        (*MED-DEBUG* T)
        ((and med-debug-p
              (not (vl-catch-all-error-p
                     (setq r (vl-catch-all-apply 'med-debug-p nil)))))
         r)))
(defun med3d-dbg (msg) (if (med3d-debug-on) (princ (strcat "\nMED3D dbg: " msg))))
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

;; point on the arc: a rotated about axis nn (through c) by angle ang
(defun med3d-arc-pt (a c nn ang / v)
  (setq v (med3d-v- a c))
  (med3d-v+ c (med3d-v+ (med3d-vx v (cos ang)) (med3d-vx (med3d-cross nn v) (sin ang)))))

;; Does the solid's box match a bend a -> (about nn through c, angle th), tube radius r?
;; Box must hold the arc start, middle and end, and must not stick out more than
;; r (+ r slack for loose boxes) past the ideal arc box. Rejects a bend revolved the
;; wrong way, a ball, or a full torus. (T when no box available)
(defun med3d-check-arc (obj a c nn th r / bb tol ok k q lo hi i)
  (setq bb  (med3d-bbox obj)
        tol (+ (* 0.02 r) (* 1e-9 (med3d-maxabs (list a c))) 1e-6))
  (if (not bb)
    T
    (progn
      (setq ok (and (med3d-bb-has bb a tol)
                    (med3d-bb-has bb (med3d-arc-pt a c nn (/ th 2.0)) tol)
                    (med3d-bb-has bb (med3d-arc-pt a c nn th) tol))
            lo (med3d-pt3 a) hi (med3d-pt3 a) k 1)
      (repeat 16
        (setq q  (med3d-arc-pt a c nn (* th (/ k 16.0)))
              lo (mapcar 'min lo q) hi (mapcar 'max hi q) k (1+ k)))
      (setq i 0)
      (repeat 3
        (if (or (< (nth i (car bb)) (- (nth i lo) r r tol))
                (> (nth i (cadr bb)) (+ (nth i hi) r r tol)))
          (setq ok nil))
        (setq i (1+ i)))
      ok)))

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

(defun med3d-solid-arc (ms a c nn th r lay / tn reg arc sol res try note)
  (setq tn (med3d-unit (med3d-cross nn (med3d-v- a c))))
  (if (and tn (setq reg (med3d-region ms a tn r lay)))
    (progn
      ;; 1st: extrude the profile along a temp ARC in the bend plane (same call that
      ;;      makes the straights; the arc carries plane, centre and sweep)
      ;; 2nd/3rd: AddRevolvedSolid about +nn, then -nn.
      ;; Each result must pass the box check; first one that passes is kept.
      (foreach try '("PATH" "REV+" "REV-")
        (if (not res)
          (progn
            (setq sol (cond
                        ((= try "PATH")
                          (if (setq arc (med3d-temp-arc ms a c nn th lay))
                            (progn
                              (setq sol (vl-catch-all-apply 'vlax-invoke (list ms 'AddExtrudedSolidAlongPath reg arc)))
                              (vla-delete arc)
                              sol)
                            (progn (setq note "temp ARC failed") nil)))
                        ((= try "REV+") (vl-catch-all-apply 'vlax-invoke (list ms 'AddRevolvedSolid reg c nn th)))
                        (T (vl-catch-all-apply 'vlax-invoke (list ms 'AddRevolvedSolid reg c (med3d-vx nn -1.0) th)))))
            (cond
              ((null sol))
              ((vl-catch-all-error-p sol)
                (med3d-dbg (strcat "  bend " try " failed: " (vl-catch-all-error-message sol))))
              ((med3d-check-arc sol a c nn th r)
                (setq res sol)
                (if (/= try "PATH") (med3d-dbg (strcat "  bend made by " try))))
              (T
                (med3d-dbg (strcat "  bend " try " box wrong " (med3d-bbstr (med3d-bbox sol))))
                (vla-delete sol))))))
      (vla-delete reg)
      (if (not res) (med3d-dbg "  bend: no method gave a correct solid - piece left out"))
      res)))

;; temp ARC (vla object) centre c, axis nn, from a sweeping th (right hand about nn)
(defun med3d-temp-arc (ms a c nn th lay / oc oa sa)
  (setq nn (med3d-unit nn)
        oc (trans c 0 nn)
        oa (trans a 0 nn)
        sa (atan (- (cadr oa) (cadr oc)) (- (car oa) (car oc))))
  (if (entmake (list '(0 . "ARC") (cons 8 lay) (cons 10 oc) (cons 40 (distance a c))
                     (cons 50 sa) (cons 51 (+ sa th)) (cons 210 nn)))
    (vlax-ename->vla-object (entlast))))

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
    ((med3d-get "GAPS" plan) (med3d-dbg "method PIECES: run is cut at a conduit body") nil)
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
        (MEDStamp3DFromBom s ent kind nil)
        (setq *MED3D-BUILT* (cons s *MED3D-BUILT*)))
      (foreach c (med3d-get "CORNERS" plan)
        (if (= (med3d-get "STATUS" c) "FLAGGED") (setq *MED3D-FLAGGED* (1+ *MED3D-FLAGGED*))))
      (setq *MED3D-FLAGGED* (+ *MED3D-FLAGGED* (length (med3d-get "FITFLAGS" plan))))
      (setq *MED3D-LAST-PLANS* (cons (append plan (list (cons "SOLID" sol))) *MED3D-LAST-PLANS*))
      (if (not sol) (med3d-skip (med3d-get "HANDLE" plan) kind "no solid created (every piece failed)"))
      (if sol (list sol plan)))))

;; counters filled by med3d-run / med3d-skip (reset by med3d-path-build-all)
(if (not (numberp *MED3D-FLAGGED*)) (setq *MED3D-FLAGGED* 0))

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
        *MED3D-CABLEOD-CACHE* nil
        *MED3D-OD-PRELOADED* nil
        *MED3D-CABLEOD-PRELOADED* nil)
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
  (setq *error* *MED3D-OLDERR* *MED3D-OLD* nil *MED3D-OLDERR* nil *MED3D-FITS* nil)
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

(defun med3d-cmd-m3d () (med3d-pick "CONDUIT" "M3D"))
(defun med3d-cmd-c3d () (med3d-pick "CABLE" "C3D"))

;; live entities of a list (UNION / cleanup may have erased some)
(defun med3d-live (l / r)
  (foreach e l (if (and e (entget e)) (setq r (cons e r))))
  (reverse r))

;; Worker shared by MAKE3DCONDUIT / MAKE3DCABLE / MEDMAKE3D: convert every MED
;; run of kind in the drawing. No prompts and no sysvar handling (callers wrap it
;; in med3d-begin / med3d-end). Returns
;;   (("KIND" . kind) ("RUNS" . n) ("OK" . n) ("SOLIDS" ename ...) ("FLAGGED" . n)
;;    ("SKIPPED" (handle kind reason) ...))
(defun med3d-path-build-all (kind / ss ok)
  (setq *MED3D-BUILT* nil *MED3D-SKIPS* nil *MED3D-FLAGGED* 0
        ss (ssget "_X" (med3d-filter (if (= kind "CABLE") _CABLE _CONDUIT)))
        ok (if ss (med3d-run-ss ss kind) 0))
  (med3d-dbg (strcat "build-all " kind ": " (itoa ok) " of " (itoa (if ss (sslength ss) 0))
                     " run(s), " (itoa (length *MED3D-BUILT*)) " solid(s), "
                     (itoa *MED3D-FLAGGED*) " flagged corner(s)"))
  (list (cons "KIND" kind) (cons "RUNS" (if ss (sslength ss) 0)) (cons "OK" ok)
        (cons "SOLIDS" (med3d-live (reverse *MED3D-BUILT*))) (cons "FLAGGED" *MED3D-FLAGGED*)
        (cons "SKIPPED" (reverse *MED3D-SKIPS*))))

(defun med3d-export (kind tag / lay res ok sols fmt fname)
  (med3d-begin tag)
  (setq *MED3D-LAST-PLANS* nil
        lay (med3d-ensure-layer (med3d-layer-info kind)))
  (med3d-clear-flags)
  (command "_.VPOINT" "1,1,1")
  (initget "Dwg Layer")
  (setq fmt (getkword (strcat "\n" tag " output to [Dwg/Layer] <Dwg>: ")))
  (if (not fmt) (setq fmt "Dwg"))
  (setq res (med3d-path-build-all kind)
        ok  (med3d-get "OK" res))
  (princ (strcat "\n" tag ": " (itoa ok) " of " (itoa (med3d-get "RUNS" res)) " run(s) converted."))
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

(defun med3d-cmd-make3dconduit () (med3d-export "CONDUIT" "MAKE3DCONDUIT"))
(defun med3d-cmd-make3dcable () (med3d-export "CABLE" "MAKE3DCABLE"))

;;; ------------------------------------------------------------------ MEDMAKE3D
;; run one stage worker without letting its error stop the other stages;
;; returns the worker's result, or nil (and records why) on error
(defun med3d-stage (name fn args / r)
  (setq r (vl-catch-all-apply fn args))
  ;; Esc / cancel stops the whole command (-> *error* -> med3d-end)
  (if (and (vl-catch-all-error-p r)
           (wcmatch (strcase (vl-catch-all-error-message r) T) "*cancel*,*break*,*quit*"))
    (exit))
  (if (vl-catch-all-error-p r)
    (progn
      (princ (strcat "\nMEDMAKE3D: " name " stage failed: " (vl-catch-all-error-message r)))
      (setq *MED3D-STAGE-ERRORS* (cons (list "-" name (strcat "stage failed: " (vl-catch-all-error-message r)))
                                       *MED3D-STAGE-ERRORS*))
      nil)
    r))

(defun med3d-sscat (l / ss)
  (setq ss (ssadd))
  (foreach e l (ssadd e ss))
  (if (> (sslength ss) 0) ss))

(defun med3d-summary-line (label n what)
  (princ (strcat "\n  " label (itoa n) " " what)))

;; MEDMAKE3D: tray (+ fittings) via the MAKE3DTRAY worker, then the conduit bodies
;; (MED3DFittings: every MED_FITTING INSERT resolved to a body + its hubs), then
;; conduit (cut back at the bodies), then the body blocks, then cable via
;; med3d-path-build-all; one [Dwg/Layer] prompt; one combined DWG +
;; one .medprops.json sidecar (Dwg) or solids left in place (Layer).
(defun med3d-make3d-all ( / fmt tray traysols fitsols bodies con cb cab skips flagged all ss fname n)
  (med3d-begin "MEDMAKE3D")
  (setq *MED3D-LAST-PLANS* nil *MED3D-STAGE-ERRORS* nil)
  (med3d-clear-flags)
  (if _MED3DTRAY (vl-catch-all-apply 'smlayer (list _MED3DTRAY)))   ; as MAKE3DTRAY
  (command "_.VPOINT" "1,1,1")
  (initget "Dwg Layer")
  (setq fmt (getkword "\nMEDMAKE3D output to [Dwg/Layer] <Dwg>: "))
  (if (not fmt) (setq fmt "Dwg"))
  ;; 1. tray + tray fittings (MED3DTrayFunctions.lsp, auto-loaded by MEDCore)
  (if (not med3d-tray-build)
    (vl-catch-all-apply 'load (list "MED3DTrayFunctions.lsp")))
  (cond
    ((not med3d-tray-build)
      (setq *MED3D-STAGE-ERRORS*
             (cons (list "-" "TRAY" "MED3DTrayFunctions.lsp not loaded - tray stage skipped") *MED3D-STAGE-ERRORS*)))
    ((setq tray (med3d-stage "TRAY" 'med3d-tray-build nil)))
    (T (vl-catch-all-apply 'command (list "_.UCS" "_W"))))   ; tray failed part-way: back to World
  (setq traysols (med3d-live (nth 0 tray)) fitsols (med3d-live (nth 1 tray)))
  (med3d-dbg (strcat "MEDMAKE3D tray stage: " (itoa (length traysols)) " tray, "
                     (itoa (length fitsols)) " fitting solid(s)"))
  ;; 2. conduit bodies: resolve every MED_FITTING INSERT (MED3DFittings.lsp) and
  ;;    its hub faces, so the conduit stage can cut the runs back to them
  (if (not medcb-collect)
    (vl-catch-all-apply 'load (list "MED3DFittings.lsp")))
  (if medcb-collect
    (setq bodies (med3d-stage "BODIES" 'medcb-collect nil))
    (setq *MED3D-STAGE-ERRORS*
           (cons (list "-" "FITTING" "MED3DFittings.lsp not loaded - conduit bodies skipped") *MED3D-STAGE-ERRORS*)))
  (setq *MED3D-FITS* (if (car bodies) (vl-remove nil (mapcar 'medcb-fit-rec (car bodies)))))
  ;; 3. conduit (cut back at the bodies)
  (setq con (med3d-stage "CONDUIT" 'med3d-path-build-all (list "CONDUIT")))
  (setq *MED3D-FITS* nil)
  ;; 4. conduit body blocks on the 3D conduit layer (placeholders on MED_3DFLAG)
  (if (car bodies) (setq cb (med3d-stage "BODIES" 'medcb-place-all (list (car bodies)))))
  ;; 5. cable
  (setq cab (med3d-stage "CABLE" 'med3d-path-build-all (list "CABLE")))
  (setq skips   (append (nth 2 tray) (med3d-get "SKIPPED" con) (med3d-get "SKIPPED" cb)
                        (med3d-get "SKIPPED" cab) (reverse *MED3D-STAGE-ERRORS*))
        flagged (+ (if con (med3d-get "FLAGGED" con) 0) (if cb (med3d-get "FLAGGED" cb) 0)
                   (if cab (med3d-get "FLAGGED" cab) 0))
        all     (med3d-live (append traysols fitsols (med3d-get "SOLIDS" con) (med3d-get "REFS" cb)
                                    (med3d-get "SOLIDS" cab)))
        ss      (med3d-sscat all))
  ;; output
  (cond
    ((not ss) (princ "\nMEDMAKE3D: no solids created - nothing to export."))
    ((= fmt "Dwg")
      (setq fname (getfiled "Select file name for MEDMAKE3D output" (getvar "DWGPREFIX") "dwg" 1))
      (if fname
        (progn
          (if (findfile fname)
            (command "_.-WBLOCK" fname "_Y" "")
            (command "_.-WBLOCK" fname ""))
          (command "0,0,0" ss "")
          (command "_.PLAN" "")
          ;; one sidecar beside the combined DWG (handles are in that file)
          (if (findfile fname) (MEDRebuildMedPropsJsonBeside fname)))
        (princ "\nMEDMAKE3D: no file chosen - solids left in the drawing.")))
    (T
      (prompt "\nUse the PLAN command to return to plan view.")
      (MEDRebuildMedPropsJsonBeside nil)))
  ;; summary
  (princ "\nMEDMAKE3D summary:")
  (med3d-summary-line "Tray          : " (length traysols) "solid(s)")
  (med3d-summary-line "Tray fittings : " (length fitsols) "solid(s)")
  (med3d-summary-line "Conduit       : " (length (med3d-get "SOLIDS" con))
    (strcat "solid(s) from " (itoa (if con (med3d-get "OK" con) 0)) " of "
            (itoa (if con (med3d-get "RUNS" con) 0)) " run(s)"))
  (med3d-summary-line "Conduit bodies: " (if cb (med3d-get "PLACED" cb) 0)
    (strcat "block(s), " (itoa (if cb (med3d-get "PH" cb) 0)) " placeholder(s), "
            (itoa (if (cadr bodies) (cadr bodies) 0)) " fitting(s) not modelled"
            (if (and cb (numberp (med3d-get "VERT" cb)) (> (med3d-get "VERT" cb) 0))
              (strcat ", " (itoa (med3d-get "VERT" cb)) " vertical conduit leg(s)") "")))
  (if (and cb (numberp (med3d-get "MIRRORED" cb)) (> (med3d-get "MIRRORED" cb) 0))
    (med3d-summary-line "Mirrored fittings: " (med3d-get "MIRRORED" cb) "(bad practice - re-insert without mirroring)"))
  (med3d-summary-line "Cable         : " (length (med3d-get "SOLIDS" cab))
    (strcat "solid(s) from " (itoa (if cab (med3d-get "OK" cab) 0)) " of "
            (itoa (if cab (med3d-get "RUNS" cab) 0)) " run(s)"))
  (med3d-summary-line "Flagged       : " flagged
    (if (> flagged 0) (strcat "(markers on " (car (med3d-flag-layer)) ")") ""))
  (med3d-summary-line "Skipped       : " (length skips) "")
  (foreach k skips
    (princ (strcat "\n    " (nth 0 k) " " (strcase (nth 1 k) T) ": " (nth 2 k))))
  (princ (strcat "\n  Output        : "
                 (cond ((not ss) "none")
                       ((= fmt "Layer") "left on their layers in this drawing")
                       (fname (strcat fname " (+ .medprops.json)"))
                       (T "none (no file chosen)"))))
  (if med-debug-log
    (vl-catch-all-apply 'med-debug-log
      (list (strcat "MEDMAKE3D " fmt ": tray " (itoa (length traysols)) ", fittings " (itoa (length fitsols))
                    ", conduit " (itoa (length (med3d-get "SOLIDS" con)))
                    ", bodies " (itoa (if cb (med3d-get "PLACED" cb) 0)) ", cable " (itoa (length (med3d-get "SOLIDS" cab)))
                    ", flagged " (itoa flagged) ", skipped " (itoa (length skips))))))
  (med3d-end))

(defun med3d-make3d-all-cmd () (med3d-make3d-all))
(defun c:MEDMake3D () (med3d-make3d-all-cmd))

;;; ------------------------------------------------------- command ownership
;; M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE are bound to the med3d-cmd-* functions
;; here, so a later (load "MED3DCON") with the 2012 defuns cannot keep them.
;; Returns the list of names that had to be taken back (not counting first load).
;; Commands must be created with DEFUN for AutoCAD to register them as command
;; names (a SETQ'd c: symbol is callable from LISP but is not a command).
;; Each wrapper's defun result is kept in *MED3D-OWN-<name>* so ownership can be
;; tested with EQ; if another file redefined the name it is re-defun'd here.
(defun med3d-claim-commands (quiet / bad)
  (if (or (null c:M3D) (not (eq c:M3D *MED3D-OWN-M3D*)))
    (setq bad (if c:M3D (cons "M3D" bad) bad)
          *MED3D-OWN-M3D* (defun c:M3D () (med3d-cmd-m3d))))
  (if (or (null c:C3D) (not (eq c:C3D *MED3D-OWN-C3D*)))
    (setq bad (if c:C3D (cons "C3D" bad) bad)
          *MED3D-OWN-C3D* (defun c:C3D () (med3d-cmd-c3d))))
  (if (or (null c:Make3DConduit) (not (eq c:Make3DConduit *MED3D-OWN-MKCON*)))
    (setq bad (if c:Make3DConduit (cons "MAKE3DCONDUIT" bad) bad)
          *MED3D-OWN-MKCON* (defun c:Make3DConduit () (med3d-cmd-make3dconduit))))
  (if (or (null c:Make3DCable) (not (eq c:Make3DCable *MED3D-OWN-MKCAB*)))
    (setq bad (if c:Make3DCable (cons "MAKE3DCABLE" bad) bad)
          *MED3D-OWN-MKCAB* (defun c:Make3DCable () (med3d-cmd-make3dcable))))
  (if (and bad (not quiet))
    (princ (strcat "\nMED3DPath: " (med3d-join (reverse bad) ", ")
                   " had been redefined by another file (old MED3DCON.lsp?) - MED3DPath "
                   *MED3D-VERSION* " version restored.")))
  bad)
(defun med3d-join (l sep / r)
  (foreach x l (setq r (if r (strcat r sep x) x)))
  (if r r ""))

;; lisp reactor: re-claim just before one of our commands is evaluated
(defun med3d-lisp-will-start (rea args / s)
  (if (and args (= (type (car args)) 'STR))
    (progn
      (setq s (strcase (car args)))
      (if (wcmatch s "(C:M3D)*,(C:C3D)*,(C:MAKE3DCONDUIT)*,(C:MAKE3DCABLE)*")
        (med3d-claim-commands nil)))))
(defun med3d-install-reactor ()
  (if (and vlr-lisp-reactor
           (not (and *MED3D-LISP-REACTOR* (vlr-added-p *MED3D-LISP-REACTOR*))))
    (setq *MED3D-LISP-REACTOR*
           (vl-catch-all-apply 'vlr-lisp-reactor
             (list nil '((:vlr-lispWillStart . med3d-lisp-will-start)))))))

(defun med3d-owner (f g) (if (eq f g) "MED3DPath" (if f "OTHER FILE (old MED3DCON.lsp?)" "not defined")))
(defun c:MED3DVER ()
  (princ (strcat "\nMED3DPath " *MED3D-VERSION*
                 "\n  M3D           : " (med3d-owner c:M3D *MED3D-OWN-M3D*)
                 "\n  C3D           : " (med3d-owner c:C3D *MED3D-OWN-C3D*)
                 "\n  MAKE3DCONDUIT : " (med3d-owner c:Make3DConduit *MED3D-OWN-MKCON*)
                 "\n  MAKE3DCABLE   : " (med3d-owner c:Make3DCable *MED3D-OWN-MKCAB*)
                 "\n  MEDMAKE3D     : " (if c:MEDMake3D "MED3DPath" "not defined")
                 "\n  tray worker   : " (if med3d-tray-build "med3d-tray-build (MED3DTrayFunctions.lsp)" "not loaded - MEDMAKE3D would skip tray")
                 "\n  debug         : " (if (med3d-debug-on) "on" "off")
                 "\n  support path MED3DPath.lsp: " (if (findfile "MED3DPath.lsp") (findfile "MED3DPath.lsp") "not found")
                 "\n  support path MED3DCON.lsp : " (if (findfile "MED3DCON.lsp") (findfile "MED3DCON.lsp") "not found")))
  (princ))

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

(med3d-claim-commands T)
(med3d-install-reactor)
(princ (strcat "Done.\nMED3DPath " *MED3D-VERSION*
               " loaded: M3D C3D MAKE3DCONDUIT MAKE3DCABLE MEDMAKE3D MED3DPLAN MED3DVER"))
(princ)
