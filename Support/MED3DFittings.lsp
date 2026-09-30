;;; MED3DFittings.lsp - rigid conduit body (Condulet) and inline fitting 3D blocks for
;;; MED (AutoCAD 2024+).
;;;
;;; Commands
;;;   MEDCBINS   insert one fitting (type, form, trade size) at picked points
;;;   MEDCBTEST  insert LB LR LL T TB C X of one form + size in a row, with labels
;;;   MEDCBALL   every fitting type of every form at one size (gallery, one row per form)
;;;   MEDCBDATA  reload the dimension data and print what is covered
;;;   MEDCBVER   print version / data source
;;; MEDMAKE3D (MED3DPath.lsp) uses medcb-collect / medcb-place-all to replace the 2D
;;; MED_FITTING blocks of a plan with these bodies - see "plan fittings" below.
;;;
;;; Data: MEDConduitBody (MED-DotNet MedODSeed creates + seeds it from
;;;   Data\seed\conduit_body_dims.csv, blanks-only). When the table is not reachable
;;;   (MED-DotNet not loaded, old DLL) the same CSV is read directly. Rows come from the
;;;   Eaton Crouse-Hinds Condulet catalog (Form 7 = F7, Form 8 = F8, Mark 9 = M9); see
;;;   Data\seed\conduit_body_sources.csv. Published letters, inches:
;;;     A overall length along the run   B overall depth (LB/TB: incl. back hub)
;;;     C overall width (LL/LR/T: incl. side hub)   D cover opening width   E opening length
;;;   Hub OD / hub length are not published; they are derived below (HubOD_in /
;;;   HubLen_in override when filled in the table).
;;;
;;; r6 (phase 2) adds, all from the same table (Data\seed\conduit_body_sources.csv
;;;   lists every publication; APPROX rows are derived and say so):
;;;     X (F7 F8 M9)  LBD LBY (CH)  BLB BT BC BUB (MOG Mogul)  GUAL GUAT GUAX (XP)
;;;     inline: UNY union, EYS / EYD seals, PLGR / PLGS plugged couplings (approx),
;;;     HUB (CH conduit hub, MYR Myers ST), RE reducer (approx); CPL (WH) = Wheatland
;;;     rigid coupling data behind the approx rows.
;;;   Letters per family: see the builders below (medcb-geom-lby ... medcb-geom-re).
;;;
;;; Block: MED_CB_RGD_<form>_<shape>_<size>, size = trade size to 2 decimals with "-"
;;;   for the point: MED_CB_RGD_F7_LB_1-00, MED_CB_RGD_F8_T_1-25, MED_CB_RGD_F7_C_0-50;
;;;   reducer <large>X<small>: MED_CB_RGD_CH_RE_1-00X0-75.
;;;   Block contents (r6, Clint's rule): every entity on layer 0, colour / linetype /
;;;   lineweight ByLayer; the INSERT carries the layer (MED_3DCONDUIT, placeholders
;;;   MED_3DFLAG). Definitions made by r5 or older (gray cover, red placeholder, old
;;;   LL / LR) are renamed <name>_PRE_R6 on first use and rebuilt; PURGE them later.
;;;   r7: EYS / EYD were reworked, so only their blocks carry "MEDCB geom r7"
;;;   (*MEDCB-SHAPE-TAGS*); an older EYS / EYD block is renamed <name>_PRE_R7.
;;;   Created only when not already in the drawing (an existing definition is never
;;;   redefined). No data -> placeholder box on layer MED_3DFLAG in a block named
;;;   <name>_PH (the real name stays free for when data is added).
;;;   Units: drawing units = inches (same as MED3DPath conduit ODs).
;;;
;;; Block axes (block coordinates, insertion point 0,0,0):
;;;   Cover (removable cover / opening) faces +Z.  Conduit centerlines lie in Z = 0
;;;   (mid-depth of the body), except the back hub of LB / TB which points -Z.
;;;   Origin = intersection of the conduit centerlines entering the body; C = body
;;;   centre on the conduit axis.  Hub directions (outward, i.e. toward the conduit):
;;;     C   RUN +X, RUN2 -X            T   RUN +X, RUN2 -X, BRANCH +Y
;;;     LB  RUN +X, BACK -Z            TB  RUN +X, RUN2 -X, BACK -Z
;;;     LL  RUN +X, BRANCH +Y          LR  RUN +X, BRANCH -Y
;;;   r6: X / GUAX  RUN +X, RUN2 -X, BRANCH +Y, BRANCH2 -Y;  GUAL RUN +X, BRANCH +Y;
;;;     GUAT = T;  LBD / BLB / LBY = LB (LBY: round cover on the 45 deg corner toward
;;;     -X +Z);  BT = T;  BC = C;  BUB RUN +X, RUN2 -X (hub faces; the hubs slope 45 deg
;;;     down to them);  UNY / EYS / EYD RUN +X, RUN2 -X (EYS / EYD r7: bulge and pour
;;;     hub +Z, leaning boss toward +X; EYD drain down toward +X);  PLGR / PLGS RUN +X (plug at -X);  HUB RUN +X, wall face at X = 0;
;;;     RE RUN +X (small size), RUN2 -X (large size).
;;;   LL / LR (r5, per Clint - r4 had them swapped): with the cover up (+Z) and the RUN
;;;   (end) hub east (+X), an LL's side hub points north (+Y) and an LR's south (-Y).
;;;   Trade rule: side hub pointing up, looking into the end hub: cover on the left =
;;;   LL, on the right = LR.
;;;   (medcb-hubs form shape size) returns ((name face-point outward-dir) ...) in these
;;;   block coordinates for placement code; face-point = where the conduit enters.
;;;
;;; Derived (not published) geometry, see medcb-geom:
;;;   body section W x H: C, LB, TB  W = C;  LL, LR, T  H = B;  the other one = min(B, C)
;;;   (square section assumed where the catalog gives only the overall size).
;;;   opening D' = min(D, 0.9 W); wall m = max((W - D')/2, 0.05 W); body length
;;;   E + 2m (the plan shape is a slot W wide with round ends).  Cover plate = slot
;;;   (E + m) x (D' + m), thickness max(1/16, 0.06 H), top at Z = H/2.  Hub OD =
;;;   min(W, H, max(1.2 D', 1.15 x rigid conduit OD)).  Run hubs take the rest of A;
;;;   side / back hubs take C - W / B - H.  Every hub is at least 0.25 x hub OD long:
;;;   when C - W (B - H) is shorter, the body width (depth) is reduced instead, so the
;;;   overall A, B and C of the block always equal the published values.
;;;   Back / side hub axis = centre of the round end of LB / LL / LR (W/2 from the
;;;   closed end); T / TB branch at the middle of A.

(princ "\rLoading MED3DFittings...")
(vl-load-com)
(setq *MEDCB-VERSION* "2026-09-30 r7 (feature/3dpath)")
;; Block definitions carry this tag in their Comments; one made by an older revision
;; (no / another tag) is renamed <name>_PRE_R6 out of the way and rebuilt (existing
;; definitions are otherwise never redefined). r5: LL / LR hub convention (Clint);
;; r6: every entity on layer 0 with colour / linetype / lineweight ByLayer (Clint's
;; block rule - r5 and older blocks had a gray colour-8 cover and a red placeholder).
(setq *MEDCB-GEOM-TAG* "MEDCB geom r6")
(setq *MEDCB-STALE-SUFFIX* "_PRE_R6")
;; r7: per-shape geometry revisions. Only the shapes listed here were rebuilt, so only
;; their blocks (and placeholders) get the newer tag; an EYS / EYD block tagged r6 is
;; renamed <name>_PRE_R7 and rebuilt, every other r6 block stays as it is.
;;   (shape tag stale-suffix)
(setq *MEDCB-SHAPE-TAGS* '(("EYS" "MEDCB geom r7" "_PRE_R7")    ; r7 seal rework (Clint)
                           ("EYD" "MEDCB geom r7" "_PRE_R7")))
;; r6: every modelled shape. Classic Condulet bodies (Form 7 / 8, Mark 9) first - the
;; MEDCBTEST row - then the phase 2 bodies and the inline fittings.
(setq *MEDCB-CLASSIC* '("LB" "LR" "LL" "T" "TB" "C" "X"))
(setq *MEDCB-SHAPES* (append *MEDCB-CLASSIC*
                             '("LBD" "BLB" "LBY" "BT" "BC" "BUB" "GUAL" "GUAT" "GUAX"
                               "UNY" "EYS" "EYD" "PLGR" "PLGS" "HUB" "RE")))
;; inline fittings (not conduit bodies): union, seals, plugged couplings, hubs, reducer
(setq *MEDCB-INLINE* '("UNY" "EYS" "EYD" "PLGR" "PLGS" "HUB" "RE"))
;; LB-like bodies (same hubs / orientation as an LB: RUN +X, BACK -Z; Clint: LBD is an
;; LB with a bigger body, LBY an LB with symmetrical legs, Mogul BLB a larger LB)
(setq *MEDCB-LB-FAMILY* '("LB" "LBD" "LBY" "BLB"))
;; forms: F7 / F8 / M9 Condulet, CH = Crouse-Hinds without a form number (LBD, LBY,
;; seals, union, plugs, hub, reducer), MOG Mogul, XP GUA explosionproof, MYR Myers hub
(setq *MEDCB-FORMS* '("F7" "F8" "M9" "CH" "MOG" "XP" "MYR"))
(if (not *MEDCB-FORM*) (setq *MEDCB-FORM* "F7"))
(if (not *MEDCB-SHAPE*) (setq *MEDCB-SHAPE* "LB"))
(if (not *MEDCB-SIZE*) (setq *MEDCB-SIZE* 1.0))
(if (not (boundp '*MEDCB-DATA*)) (setq *MEDCB-DATA* nil))   ; nil = load on first use
(setq *MEDCB-CSV* "conduit_body_dims.csv")

;;; ------------------------------------------------------------- small helpers
(defun medcb-v+ (a b) (mapcar '+ a b))
(defun medcb-vx (v s) (mapcar '(lambda (x) (* x s)) v))
(defun medcb-get (key alist) (cdr (assoc key alist)))
(defun medcb-num (v / r)
  (setq r (cond ((numberp v) (float v)) ((= (type v) 'STR) (if (/= v "") (atof v))) (T nil)))
  (if (and r (> r 0.0)) r))
(defun medcb-pad2 (n) (if (< n 10) (strcat "0" (itoa n)) (itoa n)))

;; 1.0 -> "1-00", 0.5 -> "0-50", 1.25 -> "1-25" (no RTOS: DIMZIN would strip zeros);
;; a reducer's (large small) size list -> "1-00X0-75"
(defun medcb-size-tag (sz / n)
  (if (listp sz)
    (strcat (medcb-size-tag (car sz)) "X" (medcb-size-tag (cadr sz)))
    (progn
      (setq n (fix (+ (* (float sz) 100.0) 0.5)))
      (strcat (itoa (/ n 100)) "-" (medcb-pad2 (rem n 100))))))
;; first (large) size of a size or (large small) list
(defun medcb-sz1 (sz) (if (listp sz) (car sz) sz))
(defun medcb-block-name (form shape sz)
  (strcat "MED_CB_RGD_" (strcase form) "_" (strcase shape) "_" (medcb-size-tag sz)))
(defun medcb-ph-name (form shape sz) (strcat (medcb-block-name form shape sz) "_PH"))

;; trade size text -> inches: "1/2" "3/4" "1" "1-1/4" "1 1/4" "1.25" (or a number)
(defun medcb-frac (s / k)
  (if (setq k (vl-string-search "/" s))
    (if (> (atof (substr s (+ k 2))) 0.0)
      (/ (atof (substr s 1 k)) (atof (substr s (+ k 2)))))
    (atof s)))
(defun medcb-parse-size (s / k r)
  (cond
    ((numberp s) (setq r (float s)))
    ((= (type s) 'STR)
      (setq s (vl-string-translate " " "-" (vl-string-trim " \t\"" s)))
      (setq r (if (and (setq k (vl-string-search "-" s)) (> k 0))
                (+ (atof (substr s 1 k)) (medcb-frac (substr s (+ k 2))))
                (medcb-frac s)))))
  (if (and r (> r 0.0)) r))
(defun medcb-size-text (sz / w f n)
  (if (listp sz)
    (strcat (medcb-size-text (car sz)) " x " (medcb-size-text (cadr sz)))
    (progn
      (setq n (fix (+ (* sz 16.0) 0.5)) w (/ n 16) f (rem n 16))
      (cond ((= f 0) (itoa w))
            (T (setq f (cond ((= f 8) "1/2") ((= f 4) "1/4") ((= f 12) "3/4") (T (strcat (itoa f) "/16"))))
               (if (> w 0) (strcat (itoa w) "-" f) f))))))
;; trade sizes (rigid conduit) and the next smaller one (reducer without a reduce-to size)
(setq *MEDCB-TRADE* '(0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0))
(defun medcb-size-down (sz / r)
  (foreach x *MEDCB-TRADE* (if (< x (- sz 1e-6)) (setq r x)))
  r)

;;; ---------------------------------------------------------------------- data
;; row: (("FORM" . "F7") ("SHAPE" . "LB") ("SIZE" . 1.0) ("A" . a) ("B" . b) ("C" . c)
;;       ("D" . d) ("E" . e) ("HUBOD" . x|nil) ("HUBLEN" . x|nil) ("CATNO" . s) ("FROM" . "DB"|"CSV"))
(defun medcb-row (form shape sz a b c d e hod hl cat from)
  (list (cons "FORM" (strcase form)) (cons "SHAPE" (strcase shape)) (cons "SIZE" sz)
        (cons "A" (medcb-num a)) (cons "B" (medcb-num b)) (cons "C" (medcb-num c))
        (cons "D" (medcb-num d)) (cons "E" (medcb-num e))
        (cons "HUBOD" (medcb-num hod)) (cons "HUBLEN" (medcb-num hl))
        (cons "CATNO" (if (= (type cat) 'STR) cat "")) (cons "FROM" from)))
(defun medcb-row-key (r) (list (medcb-get "FORM" r) (medcb-get "SHAPE" r) (medcb-size-tag (medcb-get "SIZE" r))))
;; letters a row needs to build its shape (the others are optional)
(defun medcb-need (shape)
  (cond ((member shape '("LBY" "UNY" "EYS" "EYD" "CPL")) '("A" "B"))
        ((member shape '("PLGR")) '("A" "B" "C"))
        ((member shape '("GUAL" "GUAT" "GUAX" "PLGS" "RE")) '("A" "B" "C" "D"))
        (T '("A" "B" "C" "D" "E"))))
(defun medcb-row-ok (r / ok)
  (setq ok T)
  (foreach k (medcb-need (medcb-get "SHAPE" r)) (if (not (medcb-get k r)) (setq ok nil)))
  ok)

;; CSV line -> fields (quotes, doubled quotes); stops after n fields when n is given
(defun medcb-csv-split (line n / i len ch q cur out)
  (setq i 1 len (strlen line) cur "" q nil out nil)
  (while (and (<= i len) (or (null n) (< (length out) n)))
    (setq ch (substr line i 1))
    (cond
      (q (if (= ch "\"")
           (if (= (substr line (1+ i) 1) "\"") (setq cur (strcat cur "\"") i (1+ i)) (setq q nil))
           (setq cur (strcat cur ch))))
      ((= ch "\"") (setq q T))
      ((= ch ",") (setq out (cons cur out) cur ""))
      (T (setq cur (strcat cur ch))))
    (setq i (1+ i)))
  (if (or (null n) (< (length out) n)) (setq out (cons cur out)))
  (reverse out))
(defun medcb-index (name lst / i r)
  (setq i 0)
  (foreach x lst (if (and (not r) (= (strcase x) (strcase name))) (setq r i)) (setq i (1+ i)))
  r)

;; Data\seed\<name>: support path, else ..\Data\seed or Data\seed next to this file
(defun medcb-seed-path (name / here c r)
  (setq here (findfile "MED3DFittings.lsp"))
  (foreach c (list (findfile name)
                   (if here (strcat (vl-filename-directory here) "\\..\\Data\\seed\\" name))
                   (if here (strcat (vl-filename-directory here) "\\Data\\seed\\" name)))
    (if (and (not r) c (findfile c)) (setq r (findfile c))))
  r)
(defun medcb-csv-path () (medcb-seed-path *MEDCB-CSV*))

(defun medcb-read-csv (path / f line hdr cols rows fl ix)
  (if (and path (setq f (open path "r")))
    (progn
      (if (setq line (read-line f))
        (progn
          (setq hdr (medcb-csv-split line nil)
                cols '("Form" "Shape" "TradeSizeDec" "A_in" "B_in" "C_in" "D_in" "E_in" "HubOD_in" "HubLen_in" "CatalogNo")
                ix (mapcar '(lambda (x) (medcb-index x hdr)) cols))
          (if (member nil ix) (setq ix nil))))
      (while (and ix (setq line (read-line f)))
        (setq fl (medcb-csv-split line (1+ (apply 'max ix))))
        (if (and (> (length fl) (apply 'max ix)) (medcb-num (nth (nth 2 ix) fl)))
          (setq rows (cons (medcb-row (nth (nth 0 ix) fl) (nth (nth 1 ix) fl) (medcb-num (nth (nth 2 ix) fl))
                                      (nth (nth 3 ix) fl) (nth (nth 4 ix) fl) (nth (nth 5 ix) fl)
                                      (nth (nth 6 ix) fl) (nth (nth 7 ix) fl) (nth (nth 8 ix) fl)
                                      (nth (nth 9 ix) fl) (nth (nth 10 ix) fl) "CSV")
                           rows))))
      (close f)
      (reverse rows))))

;; SELECT through MED-DotNet, quiet; nil when MED-DotNet / the table is not there
(defun medcb-sql (sql / old res)
  (if (and MED-DotNet-Ready (MED-DotNet-Ready) MEDProcessSQLStatement)
    (progn
      (setq old *MED-SQL-QUIET* *MED-SQL-QUIET* T
            res (vl-catch-all-apply 'MEDProcessSQLStatement (list sql))
            *MED-SQL-QUIET* old)
      (if (and res (not (vl-catch-all-error-p res)) (listp res)) res))))

;; "SQLITE" / "SQLSERVER" / nil, from MEDDataBaseSettings.dat the way MED-DotNet reads it
;; (Provider=..., else ConnectString with Data Source=... .db = SQLite)
(defun medcb-db-kind ( / p f line k v prov cs)
  (if (and (setq p (findfile "MEDDataBaseSettings.dat")) (setq f (open p "r")))
    (progn
      (while (setq line (read-line f))
        (setq line (vl-string-trim " \t" line))
        (if (and (/= line "") (/= (substr line 1 1) ";") (setq k (vl-string-search "=" line)))
          (progn
            (setq v (vl-string-trim " \t" (substr line (+ k 2))) k (strcase (vl-string-trim " \t" (substr line 1 k))))
            (cond ((= k "PROVIDER") (setq prov v)) ((= k "CONNECTSTRING") (setq cs v))))))
      (close f)
      (cond
        ((and prov (/= prov "")) (if (= (strcase prov) "SQLITE") "SQLITE" "SQLSERVER"))
        ((and cs (vl-string-search "DATA SOURCE=" (strcase cs)) (wcmatch (strcase cs) "*.DB")) "SQLITE")
        ((and cs (/= cs "")) "SQLSERVER")))))
;; T when MEDConduitBody exists (asked through the catalog, so a missing table
;; never makes MED-DotNet print an SQL error)
(defun medcb-db-has-table ( / kind)
  (setq kind (medcb-db-kind))
  (cond
    ((= kind "SQLITE") (medcb-sql "SELECT name FROM sqlite_master WHERE type='table' AND name='MEDConduitBody'"))
    ((= kind "SQLSERVER") (medcb-sql "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='MEDConduitBody'"))))
(defun medcb-read-db ( / res rows)
  (if (and (medcb-db-has-table) (setq res (medcb-sql "SELECT Form, Shape, TradeSizeDec, A_in, B_in, C_in, D_in, E_in, HubOD_in, HubLen_in, CatalogNo FROM MEDConduitBody")))
    (foreach r (cdr res)
      (if (and (listp r) (>= (length r) 11) (= (type (nth 0 r)) 'STR) (= (type (nth 1 r)) 'STR) (medcb-num (nth 2 r)))
        (setq rows (cons (medcb-row (nth 0 r) (nth 1 r) (medcb-num (nth 2 r)) (nth 3 r) (nth 4 r) (nth 5 r)
                                    (nth 6 r) (nth 7 r) (nth 8 r) (nth 9 r) (nth 10 r) "DB")
                         rows)))))
  (reverse rows))

;; DB rows first (user edits win), CSV fills keys the DB does not have
(defun medcb-load-data (force / db csv keys)
  (if (or force (null *MEDCB-DATA*))
    (progn
      (setq db (medcb-read-db) csv (medcb-read-csv (medcb-csv-path)))
      (setq keys (mapcar 'medcb-row-key db))
      (foreach r csv (if (not (member (medcb-row-key r) keys)) (setq db (append db (list r)))))
      (setq *MEDCB-DATA* (if db db '(nil)))))
  (vl-remove nil *MEDCB-DATA*))
(defun medcb-find (form shape sz / key r)
  (setq key (list (strcase form) (strcase shape) (medcb-size-tag (medcb-sz1 sz))))
  (foreach x (medcb-load-data nil) (if (and (not r) (equal (medcb-row-key x) key)) (setq r x)))
  r)

;; rigid steel conduit OD (MEDConduitOD code 1) when MEDFunctions is loaded
(defun medcb-conduit-od (sz / r)
  (setq sz (medcb-sz1 sz))
  (if med_conduit_od
    (progn (setq r (vl-catch-all-apply 'med_conduit_od (list 1 sz)))
           (if (and (numberp r) (> r 0.0)) (float r)))))
;; ANSI C80.1 rigid conduit OD by trade size (phase 2 builders when MEDFunctions is
;; not loaded); other sizes: trade size + 0.35
(setq *MEDCB-C80* '((0.5 . 0.84) (0.75 . 1.05) (1.0 . 1.315) (1.25 . 1.66) (1.5 . 1.9) (2.0 . 2.375)
                    (2.5 . 2.875) (3.0 . 3.5) (3.5 . 4.0) (4.0 . 4.5) (5.0 . 5.563) (6.0 . 6.625)))
(defun medcb-cod (sz / r)
  (setq sz (medcb-sz1 sz))
  (cond ((medcb-conduit-od sz))
        (T (foreach x *MEDCB-C80* (if (and (not r) (equal (car x) sz 1e-6)) (setq r (cdr x))))
           (if r r (+ sz 0.35)))))

;;; ------------------------------------------------------------ geometry (pure)
;; adds one hub to medcb-geom's hubs / cyls (dynamic scope: hubs cyls ov hub)
(defun medcb-hub (name face dir len)
  (setq hubs (cons (list name face dir) hubs)
        cyls (cons (list (medcb-v+ face (medcb-vx dir (- (+ len ov)))) face (/ hub 2.0)) cyls)))
;; Returns alist: SHAPE W H M DOPEN LBODY HUBOD RUNLEN SIDELEN NOTE SHORT,
;;   ("BODY" cx len width z0 z1)  slot (round ends) along X centred at (cx,0)
;;   ("COVER" cx len width z0 z1) slot
;;   ("CYLS" (p0 p1 r) ...)       hub cylinders (axis-aligned, p1 = hub face)
;;   ("HUBS" (name face dir) ...)
(defun medcb-geom (shape a b c d e hod hl cod / w h g k)
  (setq shape (strcase shape))
  (cond ((member shape '("C" "LB" "TB")) (setq w c h (if (= shape "C") b (min b c))))
        (T (setq h b w (min b c))))
  (setq g (medcb-geom-wh shape a b c d e hod hl cod w h nil))
  ;; side / back hub shorter than 0.25 x hub OD: shrink the body section instead of
  ;; the hub, so the overall B (LB, TB) / C (LL, LR, T) stays as published
  (if (setq k (medcb-get "SHORT" g))
    (setq g (if (member shape '("LB" "TB"))
              (medcb-geom-wh shape a b c d e hod hl cod w (- b k) "body depth reduced so the back hub fits B")
              (medcb-geom-wh shape a b c d e hod hl cod (- c (if (= shape "X") (* 2.0 k) k)) h
                             "body width reduced so the side hub fits C"))))
  g)
(defun medcb-geom-wh (shape a b c d e hod hl cod w h note / dp m t0 hub minh n lb cx rl sl ov hubs cyls ell short)
  (setq ell (member shape '("LB" "LL" "LR"))
        n (if ell 1 2))
  (setq dp (min d (* 0.9 w))
        m (max (/ (- w dp) 2.0) (* 0.05 w))
        t0 (max 0.0625 (* 0.06 h))
        hub (if hod hod (min w h (max (* 1.2 dp) (if cod (* 1.15 cod) 0.0))))
        minh (* 0.25 hub)
        lb (max w (+ e m m)))
  (if hl (setq lb (- a (* n hl))) (if (> lb (- a (* n minh))) (setq lb (- a (* n minh)) note "body shortened to fit A")))
  (if (< lb w) (setq lb w note "A shorter than body width"))
  (setq rl (if ell (- a lb) (/ (- a lb) 2.0))
        cx (if ell (- (/ lb 2.0) (/ w 2.0)) 0.0)
        sl (cond ((member shape '("LB" "TB")) (- b h)) ((= shape "X") (/ (- c w) 2.0)) (T (- c w))))
  (if (and (not (= shape "C")) (< sl (- minh 1e-9))) (setq short minh sl minh note "side/back hub lengthened to 0.25 x hub OD"))
  (setq ov (* 0.25 (min w h)))
  (cond
    (ell (medcb-hub "RUN" (list (- a (/ w 2.0)) 0.0 0.0) '(1.0 0.0 0.0) rl))
    (T (medcb-hub "RUN" (list (/ a 2.0) 0.0 0.0) '(1.0 0.0 0.0) rl)
       (medcb-hub "RUN2" (list (/ a -2.0) 0.0 0.0) '(-1.0 0.0 0.0) rl)))
  (cond
    ((member shape '("LB" "TB")) (medcb-hub "BACK" (list 0.0 0.0 (- (+ (/ h 2.0) sl))) '(0.0 0.0 -1.0) sl))
    ((member shape '("LL" "T" "X")) (medcb-hub "BRANCH" (list 0.0 (+ (/ w 2.0) sl) 0.0) '(0.0 1.0 0.0) sl)
      (if (= shape "X") (medcb-hub "BRANCH2" (list 0.0 (- (+ (/ w 2.0) sl)) 0.0) '(0.0 -1.0 0.0) sl)))
    ((= shape "LR") (medcb-hub "BRANCH" (list 0.0 (- (+ (/ w 2.0) sl)) 0.0) '(0.0 -1.0 0.0) sl)))
  (list (cons "SHAPE" shape) (cons "W" w) (cons "H" h) (cons "M" m) (cons "DOPEN" dp) (cons "LBODY" lb)
        (cons "HUBOD" hub) (cons "RUNLEN" rl) (cons "SIDELEN" (if (= shape "C") nil sl)) (cons "NOTE" note) (cons "SHORT" short)
        (list "BODY" cx lb w (/ h -2.0) (- (/ h 2.0) t0))
        (list "COVER" cx (min lb (+ e m)) (min w (+ dp m)) (- (/ h 2.0) t0) (/ h 2.0))
        (cons "CYLS" (reverse cyls))
        (cons "HUBS" (reverse hubs))))

;;; ---------------------------------------------- phase 2 builders (r6, pure)
;;; Primitive geometry: ("PRIMS" prim ...) with prim
;;;   ("CYL" role p0 p1 r)      cylinder p0 -> p1 (any direction)
;;;   ("PRISM" role p0 p1 rc n) regular n-gon prism p0 -> p1, corner radius rc (r7:
;;;                             4 = square drive recess, 6 = hex nut)
;;;   ("BOX" role pmin pmax)    axis-aligned box
;;;   ("SLOT" role cx len w z0 z1)  stadium along X (as BODY / COVER above)
;;; role "BODY" (unioned into one solid) or "COVER" (a second solid: cover, pour hub,
;;; plug head, locknut); both on layer 0, ByLayer (no colour in the block, r6).
;;; r7: role "CUT" is subtracted from the body, "CUTC" from the cover solid (plug
;;; seats, square drive recesses), after all the unions.
;;; Builders collect into prims / hubs (dynamic scope of medcb-prims-geom callers).
(defun medcb-p (prim) (setq prims (cons prim prims)))
(defun medcb-h (name face dir) (setq hubs (cons (list name face dir) hubs)))
(defun medcb-prims-geom (shape note)
  (list (cons "SHAPE" shape) (cons "NOTE" note) (cons "PRIMS" (reverse prims)) (cons "HUBS" (reverse hubs))))
;; hub OD of the phase 2 builders: table value, else 1.15 x rigid conduit OD, at most lim
(defun medcb-hod2 (hod sz lim)
  (cond (hod hod) (lim (min lim (* 1.15 (medcb-cod sz)))) (T (* 1.15 (medcb-cod sz)))))
(setq *MEDCB-R2* (sqrt 0.5))

;; LBY (Crouse-Hinds, a b only): LB orientation (RUN +X, BACK -Z), legs symmetrical,
;; round cover on the 45 deg outside corner (normal (-1,0,1)/sqrt2). Published a =
;; overall (back of the body to a hub face, both legs), b = body / cover diameter.
;; Derived: body = round can on the cover axis, cover face 0.55 x hub OD past the
;; centreline crossing, hubs from the crossing to the faces at a minus the body's reach
;; behind the crossing (rim of the can / cover), so both legs measure a overall.
(defun medcb-geom-lby (a b hod sz / prims hubs hub hc f n t0 note)
  (setq hub (medcb-hod2 hod sz b) hc (* 0.55 hub) n (list (- *MEDCB-R2*) 0.0 *MEDCB-R2*)
        t0 (max 0.0625 (* 0.06 b))
        f (- a (* *MEDCB-R2* (max (+ (- hc t0) (/ b 2.0)) (+ hc (* 0.45 b))))))
  (if (< f (* 0.75 hub)) (setq f (* 0.75 hub) note "A too short for the derived body - hubs lengthened"))
  (medcb-p (list "CYL" "BODY" (medcb-vx n (* -0.35 b)) (medcb-vx n (- hc t0)) (/ b 2.0)))
  (medcb-p (list "CYL" "COVER" (medcb-vx n (- hc t0)) (medcb-vx n hc) (* 0.45 b)))
  (medcb-p (list "CYL" "BODY" '(0.0 0.0 0.0) (list f 0.0 0.0) (/ hub 2.0)))
  (medcb-p (list "CYL" "BODY" '(0.0 0.0 0.0) (list 0.0 0.0 (- f)) (/ hub 2.0)))
  (medcb-h "RUN" (list f 0.0 0.0) '(1.0 0.0 0.0))
  (medcb-h "BACK" (list 0.0 0.0 (- f)) '(0.0 0.0 -1.0))
  (medcb-prims-geom "LBY" note))

;; GUA explosionproof outlet box (a body dia, b height, c centre to hub face, d bottom
;; to hub centreline, E cover opening dia, HubLen e): round body, axis Z, threaded
;; cover on top (face up), horizontal hubs: GUAL RUN +X, BRANCH +Y; GUAT RUN +X,
;; RUN2 -X, BRANCH +Y; GUAX + BRANCH2 -Y. Origin = hub centreline crossing.
(defun medcb-geom-gua (shape a b c d e hod hl sz / prims hubs hub z0 z1 t0 rc ov k dirs)
  (setq hub (medcb-hod2 hod sz (* 0.8 b)) z0 (- d) z1 (- b d) t0 (* 0.12 b)
        rc (min (* 0.48 a) (/ (+ (if e e (* 0.6 a)) 0.25) 2.0)) ov (* 0.25 a))
  (if (not hl) (setq hl (max (* 0.25 hub) (- c (/ a 2.0)))))
  (medcb-p (list "CYL" "BODY" (list 0.0 0.0 z0) (list 0.0 0.0 (- z1 t0)) (/ a 2.0)))
  (medcb-p (list "CYL" "COVER" (list 0.0 0.0 (- z1 t0)) (list 0.0 0.0 z1) rc))
  (setq dirs (cond ((= shape "GUAL") '(("RUN" 1.0 0.0) ("BRANCH" 0.0 1.0)))
                   ((= shape "GUAT") '(("RUN" 1.0 0.0) ("RUN2" -1.0 0.0) ("BRANCH" 0.0 1.0)))
                   (T '(("RUN" 1.0 0.0) ("RUN2" -1.0 0.0) ("BRANCH" 0.0 1.0) ("BRANCH2" 0.0 -1.0)))))
  (foreach dd dirs
    (setq k (list (cadr dd) (caddr dd) 0.0))
    (medcb-p (list "CYL" "BODY" (medcb-vx k (min (- c hl) (- (/ a 2.0) ov))) (medcb-vx k c) (/ hub 2.0)))
    (medcb-h (car dd) (medcb-vx k c) k))
  (medcb-prims-geom shape nil))

;; Mogul BUB (a overall length, b overall height, c width, d x e cover opening):
;; slot body with the cover up, two hubs 45 deg down and out at the ends. Origin =
;; midpoint of the hub face centres (the conduit elevation), faces at +/-xf where the
;; face rims reach A/2. The planner gets horizontal +/-X hub directions at the faces
;; (plan runs are horizontal - the 45 deg entry is not drawn in the conduit).
(defun medcb-geom-bub (a b c d e hod sz / prims hubs hub r w dp m xf zt hb sz0 sx ov lb t0 u)
  (setq w c hub (medcb-hod2 hod sz (* 0.9 w)) r (/ hub 2.0)
        dp (min d (* 0.9 w)) m (max (/ (- w dp) 2.0) (* 0.05 w))
        xf (- (/ a 2.0) (* r *MEDCB-R2*)) zt (- b (* r *MEDCB-R2*))
        hb (min (* 0.8 w) zt) t0 (max 0.0625 (* 0.06 hb)) ov (* 0.25 hb)
        ;; hub start on the 45 deg axis inside the body, its rim below the cover
        sz0 (min (- zt (/ hb 2.0)) (- zt t0 (* r *MEDCB-R2*))) sx (- xf sz0)
        lb (* 2.0 (+ sx (* 0.5 r))))
  (medcb-p (list "SLOT" "BODY" 0.0 lb w (- zt hb) (- zt t0)))
  (medcb-p (list "SLOT" "COVER" 0.0 (min lb (+ e m)) (min w (+ dp m)) (- zt t0) zt))
  (foreach sg '(1.0 -1.0)
    (setq u (list (* sg *MEDCB-R2*) 0.0 (- *MEDCB-R2*)))
    (medcb-p (list "CYL" "BODY" (list (* sg sx) 0.0 sz0) (list (* sg xf) 0.0 0.0) r))
    (medcb-h (if (> sg 0.0) "RUN" "RUN2") (list (* sg xf) 0.0 0.0) (list sg 0.0 0.0)))
  (medcb-prims-geom "BUB" "hubs 45 deg down; conduit joined horizontally at the hub faces"))

;; UNY union (A length, B max dia): two ends 0.85 B, centre nut B; RUN faces +/-A/2
(defun medcb-geom-uny (a b / prims hubs l3)
  (setq l3 (* 0.3 a))
  (medcb-p (list "CYL" "BODY" (list (/ a -2.0) 0.0 0.0) (list (+ (/ a -2.0) l3) 0.0 0.0) (* 0.425 b)))
  (medcb-p (list "CYL" "BODY" (list (+ (/ a -2.0) l3) 0.0 0.0) (list (- (/ a 2.0) l3) 0.0 0.0) (/ b 2.0)))
  (medcb-p (list "CYL" "BODY" (list (- (/ a 2.0) l3) 0.0 0.0) (list (/ a 2.0) 0.0 0.0) (* 0.425 b)))
  (medcb-h "RUN" (list (/ a 2.0) 0.0 0.0) '(1.0 0.0 0.0))
  (medcb-h "RUN2" (list (/ a -2.0) 0.0 0.0) '(-1.0 0.0 0.0))
  (medcb-prims-geom "UNY" nil))

;; EYS / EYD sealing fitting (r7, after Clint's reference model of the real fitting).
;; Published: a overall length, b body width, D turning radius (conduit axis to the
;; farthest face; Eaton EYS p.114 / EYD table). The rest is estimated from the catalog
;; drawings and Clint's reference (approx):
;;   - the conduit runs straight through a tube (hub OD max(1.06 x conduit OD, 0.62 b)
;;     <= b), bored to the conduit OD, with plain hub rings at both ends;
;;   - the body swells out on the +Z side into an eccentric bulge b wide (a cylinder of
;;     dia b, bottom flush with the tube);
;;   - on top of the bulge a large, short pour hub (dia 0.84 b) with a recessed plug
;;     with a square drive; beside it, toward +X, a smaller boss leaning 40 deg with
;;     its own square-drive plug (the face square to its axis, so slanted);
;;   - 1-1/4 and up: pour hub face at D; 1/2 - 1 (the catalog's angled body): the
;;     leaning boss reaches D, the pour hub stays short (0.3 b above the bulge);
;;   - EYD adds the drain: a boss 45 deg down toward +X, hex nut and cartridge.
;; Body solid: tube, rings, bulge, hubs minus the plug seats; second solid: plugs minus
;; the square drives (+ EYD nut / cartridge). RUN faces +/-a/2, axis = X (as r6).
(defun medcb-geom-seal (shape a b tr hod sz / prims hubs r rt rr lr zc xp rp hp zp th u rs ls xs ct zt xt
                                             rd dn ld xd pl s2 bt x0 x1)
  (setq r (/ b 2.0) s2 *MEDCB-R2*
        rt (/ (min b (if hod hod (max (* 1.06 (medcb-cod sz)) (* 0.62 b)))) 2.0)
        rr (min r (* 1.06 rt)) lr (* 0.07 a)
        zc (- r rt)                           ; bulge axis (bottom flush with the tube)
        bt (+ zc r)                           ; bulge top
        rp (* 0.42 b) hp (* 0.14 b)           ; pour hub radius, plug thickness
        xp (* -0.14 a)
        rs (* 0.25 b) th (/ (* 40.0 pi) 180.0) u (list (sin th) 0.0 (cos th)))
  (if (not (and tr (> tr (+ bt (* 0.1 b))))) (setq tr (+ bt (* 0.35 b))))
  (setq zp (if (> (medcb-sz1 sz) 1.0) tr (min tr (+ bt (* 0.3 b))))    ; pour hub face
        zt (if (> (medcb-sz1 sz) 1.0) (- zp (* 0.03 b)) tr))              ; boss rim top
  ;; leaning boss: base on the axis beside the pour hub, top face centre ct
  (setq ls (/ (- zt (* rs (sin th))) (cos th))
        xs (+ xp (* 0.95 rp)))
  (if (> (+ xs (* ls (sin th)) (* rs (cos th))) (- (/ a 2.0) lr))
    (setq xs (- (/ a 2.0) lr (* ls (sin th)) (* rs (cos th)))))
  (setq ct (medcb-v+ (list xs 0.0 0.0) (medcb-vx u ls))
        x0 (max (+ (/ a -2.0) lr) (- xp (* 1.15 rp)))
        x1 (min (- (/ a 2.0) lr) (max (+ xp rp) (+ (car ct) rs))))
  ;; tube, hub rings, bulge
  (medcb-p (list "CYL" "BODY" (list (/ a -2.0) 0.0 0.0) (list (/ a 2.0) 0.0 0.0) rt))
  (medcb-p (list "CYL" "BODY" (list (/ a -2.0) 0.0 0.0) (list (+ (/ a -2.0) lr) 0.0 0.0) rr))
  (medcb-p (list "CYL" "BODY" (list (- (/ a 2.0) lr) 0.0 0.0) (list (/ a 2.0) 0.0 0.0) rr))
  (medcb-p (list "CYL" "BODY" (list x0 0.0 zc) (list x1 0.0 zc) r))
  ;; bore: the conduit runs straight through (threads not drawn)
  (medcb-p (list "CYL" "CUT" (list (- (/ a -2.0) 0.01) 0.0 0.0) (list (+ (/ a 2.0) 0.01) 0.0 0.0) (min (* 0.95 rt) (/ (medcb-cod sz) 2.0))))
  ;; pour hub + recessed plug with a square drive
  (medcb-p (list "CYL" "BODY" (list xp 0.0 zc) (list xp 0.0 zp) rp))
  (medcb-p (list "CYL" "CUT" (list xp 0.0 (- zp hp)) (list xp 0.0 (+ zp 0.01)) (* 0.8 rp)))
  (medcb-p (list "CYL" "COVER" (list xp 0.0 (- zp hp)) (list xp 0.0 (- zp (* 0.03 b))) (* 0.79 rp)))
  (medcb-p (list "PRISM" "CUTC" (list xp 0.0 (- zp (* 0.6 hp))) (list xp 0.0 zp) (* 0.4 rp) 4))
  ;; leaning boss + its plug (face square to the boss axis)
  (setq pl (* 0.3 rs))
  (medcb-p (list "CYL" "BODY" (list xs 0.0 0.0) ct rs))
  (medcb-p (list "CYL" "CUT" (medcb-v+ ct (medcb-vx u (- (* 1.2 pl)))) (medcb-v+ ct (medcb-vx u 0.01)) (* 0.72 rs)))
  (medcb-p (list "CYL" "COVER" (medcb-v+ ct (medcb-vx u (- (* 1.2 pl)))) (medcb-v+ ct (medcb-vx u (* -0.03 b))) (* 0.71 rs)))
  (medcb-p (list "PRISM" "CUTC" (medcb-v+ ct (medcb-vx u (- (* 0.8 pl)))) ct (* 0.42 rs) 4))
  ;; EYD drain: boss 45 deg down toward +X, hex nut, cartridge
  (if (= shape "EYD")
    (progn
      (setq rd (* 0.15 b) dn (list s2 0.0 (- s2)) ld (/ (+ rt (* 0.1 b)) s2) xd (* -0.05 a))
      (if (> (+ xd (* (+ ld (* 0.42 b)) s2) (* 0.7 rd)) (- (/ a 2.0) lr))
        (setq xd (- (/ a 2.0) lr (* (+ ld (* 0.42 b)) s2) (* 0.7 rd))))
      (medcb-p (list "CYL" "BODY" (list xd 0.0 0.0) (medcb-v+ (list xd 0.0 0.0) (medcb-vx dn ld)) rd))
      (medcb-p (list "PRISM" "COVER" (medcb-v+ (list xd 0.0 0.0) (medcb-vx dn ld)) (medcb-v+ (list xd 0.0 0.0) (medcb-vx dn (+ ld (* 0.1 b)))) (* 1.25 rd) 6))
      (medcb-p (list "CYL" "COVER" (medcb-v+ (list xd 0.0 0.0) (medcb-vx dn (+ ld (* 0.1 b)))) (medcb-v+ (list xd 0.0 0.0) (medcb-vx dn (+ ld (* 0.42 b)))) (* 0.7 rd)))))
  (medcb-h "RUN" (list (/ a 2.0) 0.0 0.0) '(1.0 0.0 0.0))
  (medcb-h "RUN2" (list (/ a -2.0) 0.0 0.0) '(-1.0 0.0 0.0))
  (medcb-prims-geom shape nil))

;; plugged coupling (approx; A coupling length, B coupling OD, PLGR C recess, PLGS
;; C square head, D head height): the conduit end is at the origin, half-way into the
;; coupling (x -A/2 .. A/2); plug at the -X end (recessed face / square head, second solid)
(defun medcb-geom-plug (shape a b c d / prims hubs)
  (medcb-p (list "CYL" "BODY" (list (/ a -2.0) 0.0 0.0) (list (/ a 2.0) 0.0 0.0) (/ b 2.0)))
  (if (= shape "PLGS")
    (medcb-p (list "BOX" "COVER" (list (- (+ (/ a 2.0) d)) (/ c -2.0) (/ c -2.0)) (list (+ (/ a -2.0) 1e-3) (/ c 2.0) (/ c 2.0))))
    (medcb-p (list "CYL" "COVER" (list (- (+ (/ a 2.0) 0.03)) 0.0 0.0) (list (+ (/ a -2.0) 0.01) 0.0 0.0) (* 0.4 b))))
  (medcb-h "RUN" '(0.0 0.0 0.0) '(1.0 0.0 0.0))
  (medcb-prims-geom shape (strcat "approx: plugged coupling, " (if (= shape "PLGS") "square-head" "recessed") " plug")))

;; conduit hub on an enclosure wall; the wall's outer face is x = 0, conduit from +X.
;; CH (MHUB): a body length, b body dia, c bushed-nipple flange dia, d flange thickness,
;;   x (E) max wall - nipple through the wall, flange inside. RUN face (a,0,0).
;; MYR (Myers ST): A overall, B body dia, C body height, D max wall, K (E) neck dia -
;;   neck through the wall, locknut inside. RUN face (C,0,0).
(defun medcb-geom-hub (form a b c d e / prims hubs wl nk lk)
  (if (= form "MYR")
    (progn
      (setq nk (max (- a c) (+ d 0.125)) lk (max 0.0625 (* 0.3 (- nk d))))
      (medcb-p (list "CYL" "BODY" '(0.0 0.0 0.0) (list c 0.0 0.0) (/ b 2.0)))
      (medcb-p (list "CYL" "BODY" (list (- nk) 0.0 0.0) '(0.001 0.0 0.0) (/ e 2.0)))
      (medcb-p (list "CYL" "COVER" (list (- (+ d lk)) 0.0 0.0) (list (- d) 0.0 0.0) (* 0.475 b)))
      (medcb-h "RUN" (list c 0.0 0.0) '(1.0 0.0 0.0)))
    (progn
      (setq wl e)
      (medcb-p (list "CYL" "BODY" '(0.0 0.0 0.0) (list a 0.0 0.0) (/ b 2.0)))
      (medcb-p (list "CYL" "BODY" (list (- (+ wl d)) 0.0 0.0) '(0.001 0.0 0.0) (* 0.4 c)))
      (medcb-p (list "CYL" "COVER" (list (- (+ wl d)) 0.0 0.0) (list (- wl) 0.0 0.0) (/ c 2.0)))
      (medcb-h "RUN" (list a 0.0 0.0) '(1.0 0.0 0.0))))
  (medcb-prims-geom "HUB" nil))

;; reducer RE (approx; row of the large size A: A coupling length, B coupling OD,
;; C head thickness, D head dia): recessed in the large-size coupling / hub (x -A..0),
;; the head sticks out C, collar for the small size (hub OD of size 2) - RUN face
;; (small end) +X, RUN2 face (large end) -X.
(defun medcb-geom-re (a b c d sz / prims hubs s2 col tc)
  (setq s2 (if (listp sz) (cadr sz)) col (min (* 0.95 d) (* 1.15 (medcb-cod (if s2 s2 (* 0.75 (medcb-sz1 sz))))))
        tc (* 0.5 c))
  (medcb-p (list "CYL" "BODY" (list (- a) 0.0 0.0) '(0.0 0.0 0.0) (/ b 2.0)))
  (medcb-p (list "CYL" "COVER" '(-0.001 0.0 0.0) (list c 0.0 0.0) (/ d 2.0)))
  (medcb-p (list "CYL" "COVER" (list (- c 0.001) 0.0 0.0) (list (+ c tc) 0.0 0.0) (/ col 2.0)))
  (medcb-h "RUN" (list (+ c tc) 0.0 0.0) '(1.0 0.0 0.0))
  (medcb-h "RUN2" (list (- a) 0.0 0.0) '(-1.0 0.0 0.0))
  (medcb-prims-geom "RE" "approx: reducer head / coupling proportions (no published dimensions)"))

;; placeholder (no data): box, same hub directions as the real shape; size only from
;; trade size / OD
(setq *MEDCB-PH-ELL* (append *MEDCB-LB-FAMILY* '("LL" "LR" "GUAL" "PLGR" "PLGS" "HUB")))
(defun medcb-geom-ph (shape sz cod / d0 l w h ell x0 x1 hubs)
  (setq sz (medcb-sz1 sz) shape (strcase shape) ell (member shape *MEDCB-PH-ELL*)
        d0 (if cod cod (+ sz 0.35)) l (* 4.5 d0) w (* 1.6 d0) h w
        x0 (if ell (/ w -2.0) (/ l -2.0)) x1 (+ x0 l))
  (setq hubs (list (list "RUN" (list x1 0.0 0.0) '(1.0 0.0 0.0))))
  (if (not ell) (setq hubs (append hubs (list (list "RUN2" (list x0 0.0 0.0) '(-1.0 0.0 0.0))))))
  (cond
    ((member shape (cons "TB" *MEDCB-LB-FAMILY*)) (setq hubs (append hubs (list (list "BACK" (list 0.0 0.0 (/ h -2.0)) '(0.0 0.0 -1.0))))))
    ((member shape '("LL" "T" "BT" "GUAL" "GUAT")) (setq hubs (append hubs (list (list "BRANCH" (list 0.0 (/ w 2.0) 0.0) '(0.0 1.0 0.0))))))
    ((= shape "LR") (setq hubs (append hubs (list (list "BRANCH" (list 0.0 (/ w -2.0) 0.0) '(0.0 -1.0 0.0))))))
    ((member shape '("X" "GUAX")) (setq hubs (append hubs (list (list "BRANCH" (list 0.0 (/ w 2.0) 0.0) '(0.0 1.0 0.0))
                                                               (list "BRANCH2" (list 0.0 (/ w -2.0) 0.0) '(0.0 -1.0 0.0)))))))
  (list (cons "SHAPE" shape) (cons "PLACEHOLDER" T)
        (list "BOX" (list x0 (/ w -2.0) (/ h -2.0)) (list x1 (/ w 2.0) (/ h 2.0)))
        (cons "HUBS" hubs)))

;; real geometry for form / shape / size from the data, nil when there is no usable
;; row. sz = trade size, or (large small) for a reducer.
(defun medcb-real-geom (form shape sz / r a b c d e hod hl cod g s1)
  (setq form (strcase form) shape (strcase shape) s1 (medcb-sz1 sz))
  (if (and (member shape *MEDCB-SHAPES*) (numberp s1) (> s1 0.0)
           (setq r (medcb-find form shape s1)) (medcb-row-ok r))
    (progn
      (setq a (medcb-get "A" r) b (medcb-get "B" r) c (medcb-get "C" r) d (medcb-get "D" r) e (medcb-get "E" r)
            hod (medcb-get "HUBOD" r) hl (medcb-get "HUBLEN" r) cod (medcb-conduit-od s1))
      (setq g
        (cond
          ((member shape '("C" "LB" "LL" "LR" "T" "TB")) (medcb-geom shape a b c d e hod hl cod))
          ;; X: published b = width across both side hubs, c = depth
          ((= shape "X") (medcb-geom "X" a c b d e hod hl cod))
          ((member shape '("LBD" "BLB")) (cons (cons "SHAPE" shape) (medcb-geom "LB" a b c d e hod hl cod)))
          ((= shape "BT") (cons (cons "SHAPE" shape) (medcb-geom "T" a b c d e hod hl cod)))
          ((= shape "BC") (cons (cons "SHAPE" shape) (medcb-geom "C" a b c d e hod hl cod)))
          ((= shape "LBY") (medcb-geom-lby a b hod s1))
          ((member shape '("GUAL" "GUAT" "GUAX")) (medcb-geom-gua shape a b c d e hod hl s1))
          ((= shape "BUB") (medcb-geom-bub a b c d e hod s1))
          ((= shape "UNY") (medcb-geom-uny a b))
          ((member shape '("EYS" "EYD")) (medcb-geom-seal shape a b d hod s1))
          ((member shape '("PLGR" "PLGS")) (medcb-geom-plug shape a b c d))
          ((= shape "HUB") (medcb-geom-hub form a b c d e))
          ((= shape "RE") (medcb-geom-re a b c d sz))))
      g)))

;; geometry for form/shape/size from the data (placeholder geometry when no row)
(defun medcb-geom-for (form shape sz / g)
  (if (setq g (medcb-real-geom form shape sz))
    g
    (medcb-geom-ph shape sz (medcb-conduit-od sz))))
(defun medcb-hubs (form shape sz) (medcb-get "HUBS" (medcb-geom-for form shape sz)))

;;; ------------------------------------------------------------------ drawing
(defun medcb-doc () (vla-get-ActiveDocument (vlax-get-acad-object)))
(defun medcb-ok (x) (and x (not (vl-catch-all-error-p x))))
(defun medcb-union (a b / r)
  (if (and a b) (progn (setq r (vl-catch-all-apply 'vlax-invoke (list a 'Boolean 0 b))) a) (if a a b)))
;; a minus b (acSubtraction); b is deleted either way (a cut that misses leaves a as is)
(defun medcb-subtract (a b)
  (if b (if a (vl-catch-all-apply 'vlax-invoke (list a 'Boolean 2 b)) (vl-catch-all-apply 'vla-delete (list b))))
  a)

;; slot (stadium) along X: box + 2 vertical cylinders, unioned
(defun medcb-add-slot (blk cx len w z0 z1 / h zc s c1 c2 st)
  (setq h (- z1 z0) zc (/ (+ z0 z1) 2.0) st (- len w))
  (if (> st 1e-6)
    (progn
      (setq s  (vl-catch-all-apply 'vlax-invoke (list blk 'AddBox (list cx 0.0 zc) st w h))
            c1 (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder (list (- cx (/ st 2.0)) 0.0 zc) (/ w 2.0) h))
            c2 (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder (list (+ cx (/ st 2.0)) 0.0 zc) (/ w 2.0) h)))
      (if (not (medcb-ok s)) (setq s nil))
      (if (not (medcb-ok c1)) (setq c1 nil))
      (if (not (medcb-ok c2)) (setq c2 nil))
      (medcb-union (medcb-union s c1) c2))
    (progn
      (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder (list cx 0.0 zc) (/ w 2.0) h)))
      (if (medcb-ok s) s))))

;; cylinder p0 -> p1 (axis parallel to X, Y or Z; r6: any other direction too)
(defun medcb-add-cyl (blk p0 p1 r / len s)
  (setq len (distance p0 p1))
  (if (> len 1e-6)
    (progn
      (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder '(0.0 0.0 0.0) r len)))
      (if (medcb-ok s) (medcb-orient s p0 p1)))))
;; a solid made along +Z, centred on the origin, turned onto p0 -> p1 and moved to
;; the midpoint (Rotate3D about the origin, then Move)
(defun medcb-orient (s p0 p1 / d len mid q)
  (setq d (mapcar '- p1 p0) len (distance p0 p1) mid (medcb-vx (medcb-v+ p0 p1) 0.5)
        q (sqrt (+ (* (car d) (car d)) (* (cadr d) (cadr d)))))
  (cond ((> (abs (car d)) (* 0.999 len)) (vlax-invoke s 'Rotate3D '(0.0 0.0 0.0) '(0.0 1.0 0.0) (/ pi 2.0)))
        ((> (abs (cadr d)) (* 0.999 len)) (vlax-invoke s 'Rotate3D '(0.0 0.0 0.0) '(1.0 0.0 0.0) (/ pi 2.0)))
        ((> (abs (caddr d)) (* 0.999 len)))
        ;; oblique: turn +Z onto d about (-dy, dx, 0)
        (T (vlax-invoke s 'Rotate3D '(0.0 0.0 0.0) (list (- (/ (cadr d) q)) (/ (car d) q) 0.0)
                        (atan q (caddr d)))))
  (vlax-invoke s 'Move '(0.0 0.0 0.0) mid)
  s)
;; regular n-gon prism p0 -> p1, corner radius rc (r7: square drive recess n = 4,
;; hex nut n = 6): closed LWPOLYLINE -> region -> extruded solid along +Z, centred,
;; then oriented like a cylinder. The temporary polyline and region are deleted.
(defun medcb-add-prism (blk p0 p1 rc n / len pts i a pl rg s)
  (setq len (distance p0 p1) i 0)
  (if (> len 1e-6)
    (progn
      (repeat n (setq a (+ (/ pi n) (* i (/ (* 2.0 pi) n))) pts (append pts (list (* rc (cos a)) (* rc (sin a)))) i (1+ i)))
      (setq pl (vl-catch-all-apply 'vlax-invoke (list blk 'AddLightWeightPolyline pts)))
      (if (medcb-ok pl)
        (progn
          (vl-catch-all-apply 'vlax-put (list pl 'Closed :vlax-true))
          (setq rg (vl-catch-all-apply 'vlax-invoke (list blk 'AddRegion (list pl))))
          (vl-catch-all-apply 'vla-delete (list pl))
          (if (and (not (vl-catch-all-error-p rg)) (setq rg (car rg)))
            (progn
              (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddExtrudedSolid rg len 0.0)))
              (vl-catch-all-apply 'vla-delete (list rg))
              (if (medcb-ok s)
                (progn
                  (vlax-invoke s 'Move '(0.0 0.0 0.0) (list 0.0 0.0 (/ len -2.0)))
                  (medcb-orient s p0 p1))))))))))

(defun medcb-flag-layer ( / info)
  (setq info (if med3d-flag-layer (med3d-flag-layer) '("MED_3DFLAG" "RED" "CONTINUOUS")))
  (if med3d-ensure-layer
    (med3d-ensure-layer info)
    (progn
      (if (not (tblsearch "LAYER" (car info)))
        (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                       (cons 2 (car info)) '(70 . 0) '(62 . 1) '(6 . "Continuous"))))
      (car info))))
(defun medcb-body-layer ( / info)
  (setq info (if med3d-layer-info (med3d-layer-info "CONDUIT") '("MED_3DCONDUIT" "GREEN" "CONTINUOUS")))
  (if med3d-ensure-layer
    (med3d-ensure-layer info)
    (progn
      (if (not (tblsearch "LAYER" (car info)))
        (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                       (cons 2 (car info)) '(70 . 0) '(62 . 3) '(6 . "Continuous"))))
      (car info))))

;; Clint's block rule (r6): every entity of a generated block on layer 0 with colour,
;; linetype and lineweight ByLayer - nothing hard-coded. The INSERT carries the layer
;; (MED_3DCONDUIT, placeholders MED_3DFLAG).
(defun medcb-bylayer (o)
  (if o (vl-catch-all-apply 'vlax-put (list o 'Layer "0")))
  (medcb-bylayer-props o))
;; colour / linetype / lineweight ByLayer (the layer is left alone)
(defun medcb-bylayer-props (o)
  (if o
    (progn
      (vl-catch-all-apply 'vlax-put (list o 'Color 256))            ; acByLayer
      (vl-catch-all-apply 'vlax-put (list o 'Linetype "ByLayer"))
      (vl-catch-all-apply 'vlax-put (list o 'Lineweight -1))))     ; acLnWtByLayer
  o)
(defun medcb-add-box (blk p0 p1 / s)
  (setq s (vl-catch-all-apply 'vlax-invoke
            (list blk 'AddBox (medcb-vx (medcb-v+ p0 p1) 0.5) (- (car p1) (car p0)) (- (cadr p1) (cadr p0)) (- (caddr p1) (caddr p0)))))
  (if (medcb-ok s) s))
;; shape of a block name MED_CB_RGD_<form>_<shape>_<size>[...] ("" when not ours)
(defun medcb-name-shape (name / t0 i j)
  (setq t0 "MED_CB_RGD_")
  (if (and (= (type name) 'STR) (> (strlen name) (strlen t0)) (= (strcase (substr name 1 (strlen t0))) t0)
           (setq i (vl-string-search "_" name (strlen t0)))
           (setq j (vl-string-search "_" name (1+ i))))
    (strcase (substr name (+ i 2) (- j i 1)))
    ""))
;; geometry tag / stale suffix for a block name (per-shape revision, else global)
(defun medcb-tag-for (name / x)
  (if (setq x (assoc (medcb-name-shape name) *MEDCB-SHAPE-TAGS*)) (cadr x) *MEDCB-GEOM-TAG*))
(defun medcb-suffix-for (name / x)
  (if (setq x (assoc (medcb-name-shape name) *MEDCB-SHAPE-TAGS*)) (caddr x) *MEDCB-STALE-SUFFIX*))
;; new block definition from geometry; nil (and no block left behind) on failure.
;; Solids: body (+ hubs) unioned, cover / plug head / pour hub a second solid.
(defun medcb-build-block (name geom / blks blk body cov s bx pr cut cutc)
  (setq blks (vla-get-Blocks (medcb-doc))
        blk (vl-catch-all-apply 'vlax-invoke (list blks 'Add '(0.0 0.0 0.0) name)))
  (if (medcb-ok blk)
    (progn
      (cond
       ((setq pr (medcb-get "PRIMS" geom))
          (foreach x pr
            (setq s (cond ((= (car x) "CYL") (medcb-add-cyl blk (nth 2 x) (nth 3 x) (nth 4 x)))
                          ((= (car x) "PRISM") (medcb-add-prism blk (nth 2 x) (nth 3 x) (nth 4 x) (nth 5 x)))
                          ((= (car x) "BOX") (medcb-add-box blk (nth 2 x) (nth 3 x)))
                          ((= (car x) "SLOT") (medcb-add-slot blk (nth 2 x) (nth 3 x) (nth 4 x) (nth 5 x) (nth 6 x)))))
            (cond ((= (cadr x) "COVER") (setq cov (medcb-union cov s)))
                  ((= (cadr x) "CUT") (setq cut (cons s cut)))
                  ((= (cadr x) "CUTC") (setq cutc (cons s cutc)))
                  (T (setq body (medcb-union body s)))))
          (foreach c cut (medcb-subtract body c))
          (foreach c cutc (medcb-subtract cov c)))
       ((setq bx (medcb-get "BOX" geom))
          (setq body (medcb-add-box blk (car bx) (cadr bx))))
       (T
          (setq s (medcb-get "BODY" geom)
                body (medcb-add-slot blk (nth 0 s) (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s)))
          (foreach cy (medcb-get "CYLS" geom)
            (setq body (medcb-union body (medcb-add-cyl blk (nth 0 cy) (nth 1 cy) (nth 2 cy)))))
          (setq s (medcb-get "COVER" geom)
                cov (medcb-add-slot blk (nth 0 s) (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s)))))
      (medcb-bylayer body)
      (medcb-bylayer cov)
      (if body
        (progn (vl-catch-all-apply 'vlax-put (list blk 'Comments (medcb-tag-for name))) name)
        (progn (vl-catch-all-apply 'vla-delete (list blk)) nil)))))
;; a block made before r6 (older tag, see *MEDCB-GEOM-TAG*; EYS / EYD before r7, see
;; *MEDCB-SHAPE-TAGS*): rename it to <name>_PRE_R6[_n] / _PRE_R7[_n] (its inserts keep the old block) so the name is free for a new
;; definition. T when renamed. To drop the old ones: PURGE the _PRE_R* blocks once
;; nothing references them.
(defun medcb-stale-rename (name / blk c new i)
  (setq blk (vl-catch-all-apply 'vla-item (list (vla-get-Blocks (medcb-doc)) name)))
  (if (and (medcb-ok blk)
           (setq c (vl-catch-all-apply 'vlax-get (list blk 'Comments)))
           (not (vl-catch-all-error-p c))
           (/= c (medcb-tag-for name)))
    (progn
      (setq new (strcat name (medcb-suffix-for name)) i 1)
      (while (tblsearch "BLOCK" new) (setq i (1+ i) new (strcat name (medcb-suffix-for name) "_" (itoa i))))
      (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vlax-put (list blk 'Name new))))
        (progn (princ (strcat "\nMED3D: block " name " was made by an older MED3DFittings (" (if (= c "") "no tag" c)
                              ") - renamed " new " and rebuilt."))
               T)))))
;; T when the block name exists and is current (older ones are renamed first)
(defun medcb-block-current (name)
  (and (tblsearch "BLOCK" name) (not (medcb-stale-rename name))))

;; Block for form/shape/size, generated on demand. Returns (name status):
;;   "EXISTS" (already defined, left alone) "CREATED" "PLACEHOLDER" (no data, _PH made)
;;   "PH-EXISTS"; nil when the shape is unknown or the block could not be built.
(defun medcb-ensure-block (form shape sz / name r geom)
  (setq form (strcase form) shape (strcase shape))
  (cond
    ((not (member shape *MEDCB-SHAPES*)) nil)
    ((not (and (numberp (medcb-sz1 sz)) (> (medcb-sz1 sz) 0.0))) nil)
    ((medcb-block-current (setq name (medcb-block-name form shape sz))) (list name "EXISTS"))
    ((setq geom (medcb-real-geom form shape sz))
      (if (medcb-build-block name geom) (list name "CREATED")))
    ((medcb-block-current (setq name (medcb-ph-name form shape sz))) (list name "PH-EXISTS"))
    (T (if (medcb-build-block name (medcb-geom-ph shape sz (medcb-conduit-od sz))) (list name "PLACEHOLDER")))))

;; insert in model space; pt WCS; rot radians about WCS Z. Returns (vla-ref name status)
(defun medcb-insert (form shape sz pt rot / res ref)
  (if (and (setq res (medcb-ensure-block form shape sz))
           (setq ref (medcb-insert-block res pt rot nil)))
    (list ref (car res) (cadr res))))
;; res = (name status) from medcb-ensure-block; flip = tilt about the body's own
;; (rotated) X axis after the Z rotation: nil = none, T = 180 deg (turned over),
;; a number = that angle in radians (+/- pi/2: LB back hub turned into the plan).
;; Right-hand rule about X, as Rotate3D. Returns the vla reference or nil.
(defun medcb-tilt (flip) (cond ((numberp flip) flip) (flip pi) (T 0.0)))
(defun medcb-insert-block (res pt rot flip / ref)
  (setq ref (vl-catch-all-apply 'vlax-invoke
              (list (vla-get-ModelSpace (medcb-doc)) 'InsertBlock pt (car res) 1.0 1.0 1.0 rot)))
  (if (medcb-ok ref)
    (progn
      (if (/= (medcb-tilt flip) 0.0)
        (vl-catch-all-apply 'vlax-invoke
          (list ref 'Rotate3D pt (medcb-v+ pt (list (cos rot) (sin rot) 0.0)) (medcb-tilt flip))))
      (vlax-put ref 'Layer (if (wcmatch (cadr res) "PLACEHOLDER,PH-EXISTS") (medcb-flag-layer) (medcb-body-layer)))
      (medcb-bylayer-props ref)
      ref)))

;;; ----------------------------------------------------------------- commands
;; "A B C" / "A/B/C" from a list of strings
(defun medcb-join (lst sep / r)
  (setq r "")
  (foreach x lst (setq r (if (= r "") x (strcat r sep x))))
  r)
(defun medcb-ask-shape ( / k)
  (initget (medcb-join *MEDCB-SHAPES* " "))
  (setq k (getkword (strcat "\nFitting type [" (medcb-join *MEDCB-SHAPES* "/") "] <" *MEDCB-SHAPE* ">: ")))
  (if k (setq *MEDCB-SHAPE* k))
  *MEDCB-SHAPE*)
;; forms with dimension rows for a shape (F7 / F8 / M9 for the classic bodies)
(defun medcb-shape-forms (shape / r)
  (foreach x (medcb-load-data nil)
    (if (and (= (medcb-get "SHAPE" x) shape) (not (member (medcb-get "FORM" x) r)) (member (medcb-get "FORM" x) *MEDCB-FORMS*))
      (setq r (cons (medcb-get "FORM" x) r))))
  (cond ((member shape '("LB" "LR" "LL" "T" "TB" "C")) '("F7" "F8" "M9"))
        (r (reverse r))
        (T '("F7"))))
(defun medcb-ask-form (shape / k fl)
  (setq fl (medcb-shape-forms (if shape shape "LB")))
  (if (not (member *MEDCB-FORM* fl)) (setq *MEDCB-FORM* (car fl)))
  (if (cdr fl)
    (progn
      (initget (medcb-join fl " "))
      (setq k (getkword (strcat "\nForm (F7 = Form 7, F8 = Form 8, M9 = Mark 9 aluminum, CH = Crouse-Hinds, MOG = Mogul, "
                                "XP = GUA, MYR = Myers) [" (medcb-join fl "/") "] <" *MEDCB-FORM* ">: ")))
      (if k (setq *MEDCB-FORM* k))))
  *MEDCB-FORM*)
(defun medcb-ask-size ( / s v)
  (while (not v)
    (setq s (getstring (strcat "\nTrade size (1/2, 3/4, 1, 1-1/4, 1-1/2, 2 ... 4) <" (medcb-size-text *MEDCB-SIZE*) ">: ")))
    (setq v (if (= s "") *MEDCB-SIZE* (medcb-parse-size s)))
    (if (not v) (princ "\nNot a trade size.")))
  (setq *MEDCB-SIZE* v))
(defun medcb-say (res)
  (princ (strcat "\n  " (cadr res) " (" (caddr res) ")"
                 (if (wcmatch (caddr res) "PLACEHOLDER,PH-EXISTS") " - no dimension data, placeholder on MED_3DFLAG" ""))))

(defun medcb-begin ( / doc)
  (setq doc (medcb-doc))
  (vla-StartUndoMark doc)
  (setq *MEDCB-OLDERR* *error*)
  (defun *error* (msg)
    (if (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*")) (princ (strcat "\nMED3DFittings error: " msg)))
    (medcb-end)
    (princ)))
(defun medcb-end ()
  (vl-catch-all-apply 'vla-EndUndoMark (list (medcb-doc)))
  (if *MEDCB-OLDERR* (setq *error* *MEDCB-OLDERR* *MEDCB-OLDERR* nil)))

(defun c:MEDCBINS ( / shape form sz pt ang res)
  (medcb-begin)
  (setq shape (medcb-ask-shape) form (medcb-ask-form shape) sz (medcb-ask-size))
  ;; reducer: size to reduce to (default one trade size down)
  (if (= shape "RE")
    (setq sz (list sz (cond ((medcb-parse-size (getstring (strcat "\nReduce to size <" (medcb-size-text (cond ((medcb-size-down sz)) (sz))) ">: "))))
                            ((medcb-size-down sz)) (sz)))))
  (while (setq pt (getpoint (strcat "\nInsertion point (conduit centerline intersection) for "
                                    (medcb-block-name form shape sz) " <done>: ")))
    (setq ang (getangle pt "\nRotation about Z <0>: "))
    (if (not ang) (setq ang 0.0))
    (if (setq res (medcb-insert form shape sz (trans pt 1 0) (+ ang (angle '(0.0 0.0 0.0) (getvar "UCSXDIR")))))
      (medcb-say res)
      (princ "\n  Could not create / insert the block.")))
  (medcb-end)
  (princ))

(defun medcb-text (pt h s lay)
  (entmake (list '(0 . "TEXT") (cons 8 lay) (cons 10 pt) (cons 11 pt) (cons 40 h) (cons 1 s)
                 '(72 . 1) '(73 . 3))))

(defun c:MEDCBTEST ( / form sz base x res geom len wid h lay maxw gap)
  (medcb-begin)
  (setq form (medcb-ask-form "LB") sz (medcb-ask-size))
  (if (setq base (getpoint "\nBase point for the row <0,0,0>: ")) (setq base (trans base 1 0)) (setq base '(0.0 0.0 0.0)))
  (setq x 0.0 maxw 0.0 gap (max 2.0 (* 2.0 sz)) h (max 0.25 (* 0.2 sz)))
  (foreach shape *MEDCB-CLASSIC*
    (setq geom (medcb-geom-for form shape sz))
    (setq wid (medcb-geom-width geom))
    (if (> wid maxw) (setq maxw wid)))
  (foreach shape *MEDCB-CLASSIC*
    (setq geom (medcb-geom-for form shape sz)
          len (medcb-geom-xrange geom))
    (setq x (- x (car len)))                                  ; left end of this body at x
    (if (setq res (medcb-insert form shape sz (medcb-v+ base (list x 0.0 0.0)) 0.0))
      (progn
        (medcb-say res)
        (setq lay (vla-get-Layer (car res)))
        (medcb-text (medcb-v+ base (list x (- (+ maxw h)) 0.0)) h (strcat shape " " (cadr res)) lay)
        (if (wcmatch (caddr res) "PLACEHOLDER,PH-EXISTS")
          (medcb-text (medcb-v+ base (list x (- (+ maxw (* 2.6 h))) 0.0)) (* 0.8 h) "NO DATA - placeholder" lay)))
      (princ (strcat "\n  " shape ": could not create / insert.")))
    (setq x (+ x (cadr len) gap)))
  (princ (strcat "\nMEDCBTEST: " form " " (medcb-size-text sz) "\" in a row along +X, covers facing +Z (view TOP / use a 3D view)."))
  (medcb-end)
  (princ))
;; MEDCBALL: every shape x every form with data at one trade size, one row per form
;; group (classic F7 / F8 / M9 rows, then CH / MOG / XP / MYR), labelled; a reducer at
;; size x one size down. Shapes without a row at that size come in as placeholders.
(defun c:MEDCBALL ( / sz base y x res geom len h lay gap s2 fl row rowh)
  (medcb-begin)
  (setq sz (medcb-ask-size))
  (if (setq base (getpoint "\nBase point <0,0,0>: ")) (setq base (trans base 1 0)) (setq base '(0.0 0.0 0.0)))
  (setq y 0.0 gap (max 2.0 (* 2.0 sz)) h (max 0.25 (* 0.2 sz)))
  (foreach form *MEDCB-FORMS*
    (setq x 0.0 rowh 0.0 row nil)
    (foreach shape *MEDCB-SHAPES*
      (if (member form (medcb-shape-forms shape)) (setq row (cons shape row))))
    (foreach shape (reverse row)
      (setq s2 (if (= shape "RE") (list sz (cond ((medcb-size-down sz)) (sz))) sz)
            geom (medcb-geom-for form shape s2)
            len (medcb-geom-xrange geom)
            rowh (max rowh (* 2.0 (medcb-geom-width geom))))
      (setq x (- x (car len)))
      (if (setq res (medcb-insert form shape s2 (medcb-v+ base (list x y 0.0)) 0.0))
        (progn
          (medcb-say res)
          (setq lay (vla-get-Layer (car res)))
          (medcb-text (medcb-v+ base (list x (- y (+ (medcb-geom-width geom) h)) 0.0)) h (strcat form " " shape) lay))
        (princ (strcat "\n  " form " " shape ": could not create / insert.")))
      (setq x (+ x (cadr len) gap)))
    (if row (setq y (- y (+ rowh gap (* 3.0 h))))))
  (princ (strcat "\nMEDCBALL: every fitting at " (medcb-size-text sz) "\" (one row per form), covers facing +Z."))
  (medcb-end)
  (princ))

;; (xmin xmax) of the geometry along X / max |y| extent, for spacing the test row
(defun medcb-prims-ext (geom / lo hi w r)
  (setq lo 0.0 hi 0.0 w 0.0)
  (foreach x (medcb-get "PRIMS" geom)
    (cond ((and (member (car x) '("CYL" "PRISM")) (not (member (cadr x) '("CUT" "CUTC"))))
            (setq r (nth 4 x))
            (foreach p (list (nth 2 x) (nth 3 x))
              (setq lo (min lo (- (car p) r)) hi (max hi (+ (car p) r)) w (max w (+ (abs (cadr p)) r)))))
          ((= (car x) "BOX")
            (setq lo (min lo (car (nth 2 x))) hi (max hi (car (nth 3 x))) w (max w (abs (cadr (nth 2 x))) (abs (cadr (nth 3 x))))))
          ((= (car x) "SLOT")
            (setq lo (min lo (- (nth 2 x) (/ (nth 3 x) 2.0))) hi (max hi (+ (nth 2 x) (/ (nth 3 x) 2.0)))
                  w (max w (/ (nth 4 x) 2.0))))))
  (list lo hi w))
(defun medcb-geom-xrange (geom / lo hi bx e)
  (cond
   ((setq bx (medcb-get "BOX" geom))
    (list (car (car bx)) (car (cadr bx))))
   ((medcb-get "PRIMS" geom) (setq e (medcb-prims-ext geom)) (list (car e) (cadr e)))
   (T
      (setq lo 0.0 hi 0.0)
      (foreach hb (medcb-get "HUBS" geom)
        (setq lo (min lo (car (cadr hb))) hi (max hi (car (cadr hb)))))
      (list (min lo (- (nth 0 (medcb-get "BODY" geom)) (/ (nth 1 (medcb-get "BODY" geom)) 2.0))) hi))))
(defun medcb-geom-width (geom / w bx)
  (cond
   ((setq bx (medcb-get "BOX" geom))
    (cadr (cadr bx)))
   ((medcb-get "PRIMS" geom) (caddr (medcb-prims-ext geom)))
   (T
      (setq w (/ (medcb-get "W" geom) 2.0))
      (foreach hb (medcb-get "HUBS" geom) (setq w (max w (abs (cadr (cadr hb))))))
      w)))

(defun c:MEDCBDATA ( / rows n from)
  (setq rows (medcb-load-data T) n 0)
  (princ (strcat "\nMED3DFittings: " (itoa (length rows)) " fitting dimension row(s)"
                 (if rows (strcat " (first from " (medcb-get "FROM" (car rows)) ")") "")
                 "; CSV: " (if (medcb-csv-path) (medcb-csv-path) "not found")))
  (foreach f (append *MEDCB-FORMS* '("WH"))
    (foreach s (append *MEDCB-SHAPES* '("CPL"))
      (setq n nil)
      (foreach r rows
        (if (and (= (medcb-get "FORM" r) f) (= (medcb-get "SHAPE" r) s) (medcb-row-ok r))
          (setq n (cons (medcb-size-text (medcb-get "SIZE" r)) n))))
      (if n (princ (strcat "\n  " f " " s ": " (apply 'strcat (mapcar '(lambda (x) (strcat x " ")) (reverse n))))))))
  (princ))

(defun c:MEDCBVER ()
  (princ (strcat "\nMED3DFittings " *MEDCB-VERSION*
                 "\n  data rows : " (itoa (length (medcb-load-data nil)))
                 "\n  CSV       : " (if (medcb-csv-path) (medcb-csv-path) "not found")
                 "\n  file      : " (if (findfile "MED3DFittings.lsp") (findfile "MED3DFittings.lsp") "not on support path")))
  (princ))

;;; ============================================ plan fittings (for MEDMAKE3D)
;;; 2D MED_FITTING blocks on a plan -> 3D conduit bodies. MED3DPath MEDMAKE3D calls
;;; (medcb-collect) before the conduit stage, hands (medcb-fit-rec body) to the
;;; conduit planner (runs are cut back to the hubs) and calls (medcb-place-all bodies)
;;; after it.
;;; Body key: MEDType.ITEMKEY2 = "RGD|F7|LB" (material|form|shape; forms F7 F8 M9,
;;;   MOG for Mogul). ITEMKEY2 blank -> the catalog description is parsed:
;;;   'Form 7 "LB" condulet fitting' -> RGD|F7|LB ("Form 8" F8, "Mark 9" M9, "Mogul"
;;;   MOG, no form -> ""; shape = the quoted word, else the word before "condulet").
;;;   A description without "condulet" and a blank ITEMKEY2: the seed keys CSV by code
;;;   when the description is the same (union, seals, plugs, hubs, reducer), else not
;;;   modelled (couplings, connectors ...). "Explosion Proof" -> XP; LBD / LBY without a
;;;   form -> CH. No MED-DotNet / DB ->
;;;   Data\seed\fitting_body_keys.csv (ITEMCODE, ITEMDESC, BodyKey) is used instead.
;;;   Size = #ITEMSIZE of the fitting.
;;; Placement: the 2D insertion point (WCS) is the body insertion point (centerline
;;;   intersection); where a conduit vertex / pass-through is found at that XY its Z
;;;   wins over the block Z. Legs are searched within the medblck.dat break distance x
;;;   the insert scale + *MED3D-FIT-TOL* (Q5: the menu cuts the conduit back from some
;;;   symbols); the planner trims or extends those runs to the hub faces.
;;;   Rotation = the 2D rotation about Z (1tee T: -90 deg, +X is the branch), then a
;;;   tilt about the body X axis (medcb-insert-block, Rotate3D):
;;;   - 1lbl / 1lbr / 1lbdl / 1lbdr / 1lby: the body lies along the symbol's long leg
;;;     (+X, the conduit picked). LB / LBD / LBY / BLB lie on their side (back hub
;;;     +/-90 deg toward the short leg, +Y on 1lbl, -Y on 1lbr; cover sideways away from
;;;     it), even with only one leg drawn. LL / LR: cover up when the side hub already
;;;     points at the short leg, else turned over (cover down) - e.g. LR on 1lbl.
;;;   - T on 1teed / 2teed -> TB (back hub down, cover up); T on 1teeu / 1teeuo -> TB
;;;     turned over (back hub up, cover down). LB on 1lbu / 1lbuo turned over.
;;;   - TA (code 17) is modelled as a T.
;;;   With *MEDCB-SNAP* (default T) the quarter turns about Z and the alternative tilts
;;;   (LB family / TB: back hub into the plan; LL / LR: over) are scored against the
;;;   conduit legs; the first best wins, drawn rotation and symbol tilt first. A TB code
;;;   on a flat tee so gets its back hub on the branch, opening opposite it.
;;;   Vertical conduit stored on the insert (MED_CONDUIT distance + VERT_DATA
;;;   direction, written by the menu's dcon_ins) is built as a cylinder from the face
;;;   of the hub pointing that way to insertion Z +/- distance (flagged when no hub).
;;; Mirrored 2D symbols (X scale x Y scale x extrusion Z < 0: MIRROR, negative scale)
;;;   are not accommodated: no body, the conduit is left as drawn (no trim, no leg
;;;   flag), one marker "MIRRORED FITTING - re-insert, do not mirror" on MED_3DFLAG,
;;;   a Skipped line and the "Mirrored fittings" summary line.
;;; r6 phase 2 on plan symbols: X / GUAX / BUB / seals / union face up; GUA side views
;;;   (1gualsid / 1guatsid) tilted -90 deg about X: branch down, cover toward +Y (the
;;;   same for both); 1guat -90 deg like 1tee; reducer: reduce-to size = #ITEM_ALT
;;;   (xdata ALT, refitt_ins "Size to"), else one trade size down (noted); large end
;;;   (RUN2) toward the symbol's -X. Each hub carries its own search radius (the break
;;;   on that side of the symbol) so the planner only extends a run on a hub's axis.
;;; Code -> builder (fitting_body_keys.csv / ITEMKEY2): 80-82 X, 39 LBD, 41 LBY,
;;;   18 / 40 / 53 / 94 Mogul BT / BLB / BC / BUB, 141-143 GUAL / GUAT / GUAX,
;;;   72 UNY, 61 EYS, 64 EYD, 100 PLGR, 101 PLGS, 120 HUB (CH), 121 HUB (MYR), 103 RE.
;;; Unresolved (key without data, no form, no row for the size, other material):
;;;   placeholder block on MED_3DFLAG + flag marker + Skipped line (handle and reason).
;;;   No size -> marker only.
(setq *MEDCB-KEYS-CSV* "fitting_body_keys.csv")
(if (not (boundp '*MEDCB-SNAP*)) (setq *MEDCB-SNAP* T))
(setq *MEDCB-FITCAT* nil)
(setq *MEDCB-2D-TEEDOWN* '("1TEED" "2TEED")
      *MEDCB-2D-TEEUP*   '("1TEEU" "1TEEUO")
      *MEDCB-2D-LBUP*    '("1LBU" "1LBUO")
      *MEDCB-2D-TURN*    '("1LBL" "1LBR" "1LBDL" "1LBDR" "1LBY")
      *MEDCB-2D-TURN-R*  '("1LBR" "1LBDR"))     ; short leg at -Y (the others +Y)

(defun medcb-dot (a b) (+ (* (car a) (car b)) (* (cadr a) (cadr b)) (* (caddr a) (caddr b))))
(defun medcb-unit (v / l)
  (setq l (sqrt (medcb-dot v v)))
  (if (> l 1e-12) (medcb-vx v (/ 1.0 l))))
(defun medcb-dxy (a b) (distance (list (car a) (cadr a)) (list (car b) (cadr b))))
(defun medcb-app (kind / v)
  (setq v (if (= kind "FITTING") _FITTING _CONDUIT))
  (if (= (type v) 'STR) v (strcat "MED_" kind)))
(defun medcb-int (v)
  (cond ((numberp v) (fix v))
        ((and (= (type v) 'STR) (/= (vl-string-trim " " v) "")) (atoi v))))
(defun medcb-str (v) (if (= (type v) 'STR) (vl-string-trim " \t" v) ""))
(defun medcb-split (s ch / k out)
  (while (setq k (vl-string-search ch s))
    (setq out (cons (substr s 1 k) out) s (substr s (+ k 2))))
  (reverse (cons s out)))
;; upper case, A-Z 0-9 only (safe in a block name)
(defun medcb-clean (s / i a r)
  (setq r "" i 1 s (strcase s))
  (while (<= i (strlen s))
    (setq a (ascii (substr s i 1)))
    (if (or (and (>= a 48) (<= a 57)) (and (>= a 65) (<= a 90))) (setq r (strcat r (chr a))))
    (setq i (1+ i)))
  r)

;; "RGD|F7|LB" -> ("RGD" "F7" "LB"); nil unless material|form|shape with a shape
(defun medcb-key-parse (key / p)
  (if (and (= (type key) 'STR) (setq p (medcb-split (vl-string-trim " \t" key) "|")) (= (length p) 3))
    (progn
      (setq p (mapcar 'medcb-clean p))
      (if (and (/= (car p) "") (/= (nth 2 p) "")) p))))
;; catalog description -> "RGD|<form>|<shape>" or nil (not a condulet)
(defun medcb-desc-key (desc / u k q e form shape)
  (if (and (= (type desc) 'STR) (setq k (vl-string-search "CONDULET" (setq u (strcase desc)))))
    (progn
      (setq form (cond ((vl-string-search "FORM 7" u) "F7") ((vl-string-search "FORM 8" u) "F8")
                       ((vl-string-search "MARK 9" u) "M9") ((vl-string-search "MOGUL" u) "MOG")
                       ((vl-string-search "EXPLOSION PROOF" u) "XP") (T "")))
      (if (and (setq q (vl-string-search "\"" u)) (setq e (vl-string-search "\"" u (1+ q))))
        (setq shape (medcb-clean (substr u (+ q 2) (- e q 1))))
        (setq shape (medcb-clean (last (medcb-split (vl-string-trim " " (substr u 1 k)) " ")))))
      ;; LBD / LBY are sold without a form number: Crouse-Hinds (CH) dimensions
      (if (and (= form "") (member shape '("LBD" "LBY"))) (setq form "CH"))
      (if (/= shape "") (strcat "RGD|" form "|" shape)))))

(defun medcb-read-keys-csv (path / f line hdr ix fl rows code)
  (if (and path (setq f (open path "r")))
    (progn
      (if (setq line (read-line f))
        (progn
          (setq hdr (medcb-csv-split line nil)
                ix (mapcar '(lambda (x) (medcb-index x hdr)) '("ITEMCODE" "ITEMDESC" "BodyKey")))
          (if (member nil ix) (setq ix nil))))
      (while (and ix (setq line (read-line f)))
        (setq fl (medcb-csv-split line nil))
        (if (and (> (length fl) (apply 'max ix)) (setq code (medcb-int (nth (car ix) fl))))
          (setq rows (cons (list code (nth (cadr ix) fl) (nth (caddr ix) fl) "CSV") rows))))
      (close f)
      (reverse rows))))
;; FITTING catalog, once per MEDMAKE3D: ((code desc itemkey2 "DB"|"CSV") ...)
(defun medcb-fitcat ( / res code)
  (if (null *MEDCB-FITCAT*)
    (progn
      (setq res (medcb-sql "SELECT ITEMCODE, ITEMDESC, ITEMKEY2 FROM MEDType WHERE ITEMTYPE='FITTING'"))
      (foreach r (cdr res)
        (if (and (listp r) (>= (length r) 2) (setq code (medcb-int (car r))))
          (setq *MEDCB-FITCAT* (cons (list code (medcb-str (nth 1 r)) (medcb-str (nth 2 r)) "DB") *MEDCB-FITCAT*))))
      (if (null *MEDCB-FITCAT*)
        (setq *MEDCB-FITCAT* (medcb-read-keys-csv (medcb-seed-path *MEDCB-KEYS-CSV*))))
      (if (null *MEDCB-FITCAT*) (setq *MEDCB-FITCAT* '(nil)))))
  (vl-remove nil *MEDCB-FITCAT*))
;; Data\seed\fitting_body_keys.csv rows, once per MEDMAKE3D (fallback for a DB whose
;; ITEMKEY2 is still blank: MED-DotNet not re-seeded yet)
(setq *MEDCB-KEYCSV* nil)
(defun medcb-keys-csv ()
  (if (null *MEDCB-KEYCSV*)
    (setq *MEDCB-KEYCSV* (cond ((medcb-read-keys-csv (medcb-seed-path *MEDCB-KEYS-CSV*))) ('(nil)))))
  (vl-remove nil *MEDCB-KEYCSV*))
;; fitting code -> (key source desc), source "ITEMKEY2" | "CSV" | "DESC"; nil = not a body.
;; Order: ITEMKEY2, the description (condulets), then the seed keys CSV for the same
;; code when its description is the same (union, seals, plugs, hubs, reducer).
(defun medcb-resolve-code (code / e k c)
  (foreach x (medcb-fitcat) (if (and (not e) (= (car x) code)) (setq e x)))
  (cond
    ((null e) nil)
    ((medcb-key-parse (nth 2 e)) (list (vl-string-trim " \t" (nth 2 e)) (if (= (nth 3 e) "DB") "ITEMKEY2" "CSV") (nth 1 e)))
    ((setq k (medcb-desc-key (nth 1 e))) (list k "DESC" (nth 1 e)))
    ((and (= (nth 3 e) "DB")
          (progn (foreach x (medcb-keys-csv)
                   (if (and (not c) (= (car x) code)
                            (= (strcase (medcb-str (nth 1 x))) (strcase (medcb-str (nth 1 e))))
                            (medcb-key-parse (nth 2 x)))
                     (setq c x)))
                 c))
      (list (vl-string-trim " \t" (nth 2 c)) "CSV" (nth 1 e)))))

;; Z rotation offset of the 3D body against the 2D symbol (see header): the tee
;; symbols draw the run along Y and the branch +X
(defun medcb-2d-offset (blk shape)
  (cond ((and (= blk "1TEE") (member shape '("T" "BT"))) (/ pi -2.0))
        ((and (= blk "1GUAT") (= shape "GUAT")) (/ pi -2.0))
        (T 0.0)))
;; GUA side-view symbols: body tilted -90 deg about X - branch down (-Z), cover
;; toward +Y (away from the viewer of the plan), the same for GUAL and GUAT (Clint:
;; face either way, be consistent; branch down / away)
(setq *MEDCB-2D-GUASIDE* '("1GUALSID" "1GUATSID"))
;; block vector -> WCS vector: tilt about block X first (flip, see medcb-insert-block),
;; then rot about Z
(defun medcb-xdir (v rot flip / x y z tl c sn y0)
  (setq x (car v) y (cadr v) z (caddr v) tl (medcb-tilt flip))
  (cond ((= tl 0.0))
        ((equal tl pi 1e-12) (setq y (- y) z (- z)))
        (T (setq c (cos tl) sn (sin tl) y0 y y (- (* y0 c) (* z sn)) z (+ (* y0 sn) (* z c)))))
  (list (- (* x (cos rot)) (* y (sin rot))) (+ (* x (sin rot)) (* y (cos rot))) z))
(defun medcb-wcs-hubs (hubs rot flip / r)
  (foreach h hubs (setq r (cons (list (car h) (medcb-xdir (cadr h) rot flip) (medcb-xdir (caddr h) rot flip)) r)))
  (reverse r))
(defun medcb-cos-tol () (cos (/ (* pi (if (numberp *MED3D-FIT-ANG*) *MED3D-FIT-ANG* 30.0)) 180.0)))
(defun medcb-fit-tol () (if (numberp *MED3D-FIT-TOL*) *MED3D-FIT-TOL* 0.25))
;; legs matched by a hub pointing along them (each hub used once)
(defun medcb-score (hubs legs / ct n used best bi i d)
  (setq ct (medcb-cos-tol) n 0 used nil)
  (foreach lg legs
    (setq best ct bi nil i 0)
    (foreach h hubs
      (if (and (not (member i used)) (>= (setq d (medcb-dot (caddr h) lg)) best)) (setq best d bi i))
      (setq i (1+ i)))
    (if bi (setq used (cons bi used) n (1+ n))))
  n)

;; XY foot of pt on segment a-b: (param xy-distance) for 0 < param < 1, else nil
(defun medcb-seg-param (a b pt / dx dy l2 s)
  (setq dx (- (car b) (car a)) dy (- (cadr b) (cadr a)) l2 (+ (* dx dx) (* dy dy)))
  (if (> l2 1e-12)
    (progn
      (setq s (/ (+ (* (- (car pt) (car a)) dx) (* (- (cadr pt) (cadr a)) dy)) l2))
      (if (and (> s 0.0) (< s 1.0))
        (list s (medcb-dxy pt (list (+ (car a) (* s dx)) (+ (cadr a) (* s dy)))))))))
;; conduit legs at pt: ((unit-dir ...) z-of-the-conduit-or-nil); runs = ((pts closed) ...) WCS
(defun medcb-legs (pt runs tol / dirs z n i a b tt u)
  (foreach r runs
    (setq n (length (car r)) i 0)
    (foreach p (car r)
      (if (<= (medcb-dxy p pt) tol)
        (progn
          (if (not z) (setq z (caddr p)))
          (if (or (> i 0) (cadr r))
            (setq dirs (cons (medcb-unit (mapcar '- (nth (if (> i 0) (1- i) (1- n)) (car r)) p)) dirs)))
          (if (or (< i (1- n)) (cadr r))
            (setq dirs (cons (medcb-unit (mapcar '- (nth (if (< i (1- n)) (1+ i) 0) (car r)) p)) dirs)))))
      (setq i (1+ i)))
    (setq i 0)                                          ; passes straight through pt
    (repeat (if (cadr r) n (max 0 (1- n)))
      (setq a (nth i (car r)) b (nth (rem (1+ i) n) (car r)))
      (if (and (> (medcb-dxy a pt) tol) (> (medcb-dxy b pt) tol)
               (setq tt (medcb-seg-param a b pt)) (<= (cadr tt) tol))
        (progn
          (if (not z) (setq z (+ (caddr a) (* (car tt) (- (caddr b) (caddr a))))))
          (setq u (medcb-unit (mapcar '- b a)))
          (if u (setq dirs (cons u (cons (medcb-vx u -1.0) dirs))))))
      (setq i (1+ i))))
  (list (vl-remove nil dirs) z))

;; every MED_CONDUIT polyline as (pts closed) for the leg search (needs MED3DPath)
(defun medcb-conduit-runs ( / ss i pd r)
  (if (and med3d-read-path
           (setq ss (ssget "_X" (list '(-4 . "<OR") '(0 . "LWPOLYLINE") '(0 . "POLYLINE") '(-4 . "OR>")
                                      (list -3 (list (medcb-app "CONDUIT")))))))
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (if (setq pd (med3d-read-path (ssname ss i))) (setq r (cons (list (car pd) (nth 3 pd)) r)))
        (setq i (1+ i)))))
  (reverse r))

(defun medcb-mirrored-p (ed / sx sy n)
  ;; plan mirror: X scale x Y scale x extrusion Z < 0 (MIRROR, negative scale, or an
  ;; insert seen from below). A negative Z scale alone does not change the plan symbol.
  (setq sx (cond ((cdr (assoc 41 ed))) (1.0)) sy (cond ((cdr (assoc 42 ed))) (1.0))
        n (cond ((cdr (assoc 210 ed))) ('(0.0 0.0 1.0))))
  (< (* sx sy (caddr n)) 0.0))
;; tilts the snap tries after the symbol's own one (see medcb-insert-block)
(defun medcb-alt-tilts (shape flip / r)
  (cond
    ((or (member shape *MEDCB-LB-FAMILY*) (= shape "TB"))
      (foreach tl (list (/ pi 2.0) (/ pi -2.0)) (if (not (equal (medcb-tilt flip) tl 1e-9)) (setq r (cons tl r))))
      (reverse r))
    ((member shape '("LL" "LR")) (list (if flip nil T)))))
;; leg search radius (Q5): the menu breaks the conduit back from some symbols by the
;; medblck.dat distances x the insert scale; search that far + *MED3D-FIT-TOL*
(setq *MEDCB-BRK-CACHE* nil)
(defun medcb-brk-max (blk / c d m x)
  (if (setq c (assoc blk *MEDCB-BRK-CACHE*))
    (cdr c)
    (progn
      (setq d (if get_bl_data (vl-catch-all-apply 'get_bl_data (list blk))))
      (setq m 0.0)
      (if (and (listp d) (not (vl-catch-all-error-p d)))
        (foreach x (list (nth 0 d) (nth 1 d) (nth 2 d) (nth 3 d)) (if (and (numberp x) (> x m)) (setq m x))))
      (setq d m)
      (setq *MEDCB-BRK-CACHE* (cons (cons blk d) *MEDCB-BRK-CACHE*))
      d)))
;; medblck.dat d1..d4 (block +X +Y -X -Y) of a 2D symbol, or nil
(defun medcb-brk-list (blk / d)
  (setq d (if get_bl_data (vl-catch-all-apply 'get_bl_data (list blk))))
  (if (and (listp d) (not (vl-catch-all-error-p d)))
    (mapcar '(lambda (x) (if (numberp x) (float x) 0.0)) (list (nth 0 d) (nth 1 d) (nth 2 d) (nth 3 d)))))
;; r6: per hub search radius for the planner = the break on the symbol side the hub
;; points to (hub direction back in the symbol's axes, a = symbol rotation) x scale +
;; *MED3D-FIT-TOL*; vertical hubs *MED3D-FIT-TOL*. Hubs come back as
;; (name face dir radius) - MED3DPath only accepts a far run end on the axis of a hub
;; within that hub's radius (1re breaks 0.09125 x DIMSCALE on +X only, medblck.dat 1c73970).
(defun medcb-hub-tols (hubs blk ed a / bl sc x y r i)
  (setq bl (medcb-brk-list blk) sc (abs (cond ((cdr (assoc 41 ed))) (1.0))))
  (mapcar '(lambda (h)
             (setq x (+ (* (car (caddr h)) (cos a)) (* (cadr (caddr h)) (sin a)))
                   y (- (* (cadr (caddr h)) (cos a)) (* (car (caddr h)) (sin a))))
             (setq i (cond ((< (+ (* x x) (* y y)) 0.25) nil)
                           ((>= (abs x) (abs y)) (if (> x 0.0) 0 2))
                           (T (if (> y 0.0) 1 3))))
             (list (car h) (cadr h) (caddr h)
                   (+ (medcb-fit-tol) (if (and bl i) (* sc (nth i bl)) 0.0))))
          hubs))
(defun medcb-brk-tol (blk ed / sc)
  (setq sc (abs (cond ((cdr (assoc 41 ed))) (1.0))))
  (+ (medcb-fit-tol) (* sc (medcb-brk-max blk))))
;; one MED_FITTING INSERT -> body alist; "NM" = not a conduit body; nil = no xdata
(defun medcb-body-of (e runs / ed xd code sz res kp mat form shape blk flip note reason r
                            pt a rot geom hubs lg k best sc i h tl tbest tol sz2 gsz)
  (setq ed (entget e) xd (xdataget e (medcb-app "FITTING")))
  (if (and xd (numberp (setq code (nth 3 xd)))) (setq res (medcb-resolve-code (fix code))))
  (cond
    ((not xd) nil)
    ((not res) "NM")
    ((progn
       (setq kp (medcb-key-parse (car res)) mat (car kp) form (cadr kp) shape (caddr kp)
             blk (strcase (cdr (assoc 2 ed)))
             sz (if (numberp (nth 2 xd)) (float (nth 2 xd)) 0.0)
             h (cdr (assoc 5 ed)))
       (medcb-mirrored-p ed))
      ;; mirrored 2D symbol: not accommodated - no body, no conduit trim; one flag + Skipped
      (list (cons "HANDLE" h) (cons "ENT" e) (cons "CODE" (fix code)) (cons "KEY" (car res)) (cons "SRC" (cadr res))
            (cons "FORM" form) (cons "SHAPE" shape) (cons "SIZE" sz) (cons "BLK2D" blk)
            (cons "PT" (trans (cdr (assoc 10 ed)) e 0)) (cons "ROT" 0.0) (cons "FLIP" nil) (cons "TURN" 0) (cons "LEGS" 0)
            (cons "HUBS" nil) (cons "MIRROR" T)
            (cons "REASON" "mirrored 2D fitting block - re-insert it without mirroring") (cons "NOTE" nil)))
    (T
      ;; TA (Form 7, MEDCHG only): modelled as a T (Clint: "simply a Tee fitting")
      (if (= shape "TA") (setq shape "T" note "TA modelled as a T (T dimensions)"))
      (if (and (= shape "T") (member blk (append *MEDCB-2D-TEEDOWN* *MEDCB-2D-TEEUP*)))
        (setq shape "TB" flip (if (member blk *MEDCB-2D-TEEUP*) T)))
      ;; LB up: turned over (back hub up, cover down)
      (if (and (member shape *MEDCB-LB-FAMILY*) (member blk *MEDCB-2D-LBUP*)) (setq flip T))
      ;; 1lbl / 1lbr (and 1lbdl / 1lbdr / 1lby): the body lies along the symbol's long leg (+X) and the symbol's
      ;; short leg (+Y on 1lbl, -Y on 1lbr) is the other hub: LB family on its side
      ;; (back hub tilted +/-90 deg into the plan, cover away from that leg), LL / LR
      ;; cover up or turned over (cover down) as the code needs (Clint, r5)
      (if (member blk *MEDCB-2D-TURN*)
        (cond
          ((member shape *MEDCB-LB-FAMILY*) (setq flip (if (member blk *MEDCB-2D-TURN-R*) (/ pi -2.0) (/ pi 2.0))))
          ((if (member blk *MEDCB-2D-TURN-R*) (= shape "LL") (= shape "LR")) (setq flip T))))
      (if (and (member blk *MEDCB-2D-GUASIDE*) (member shape '("GUAL" "GUAT" "GUAX"))) (setq flip (/ pi -2.0)))
      ;; reducer: reduce-to size = the fitting's ALT size (1re / refitt_ins "Size to"),
      ;; else one trade size down (noted)
      (if (and (= shape "RE") (> sz 0.0))
        (progn
          (setq sz2 (if (numberp (nth 4 xd)) (float (nth 4 xd))))
          (if (not (and sz2 (> sz2 0.0) (< sz2 (- sz 1e-6))))
            (setq sz2 (medcb-size-down sz)
                  note (strcat "no reduce-to size on the reducer - " (if sz2 (medcb-size-text sz2) "?") "\" (one size down) assumed")))))
      (setq gsz (if sz2 (list sz sz2) sz))
      (setq reason
        (cond
          ((<= sz 0.0) "no trade size on the fitting")
          ((/= mat "RGD") (strcat "material " mat " not modelled"))
          ((= form "") (strcat shape " - no form in the body key / description"))
          ((not (member shape *MEDCB-SHAPES*)) (strcat "no 3D data for " shape " bodies"))
          ((not (member form *MEDCB-FORMS*)) (strcat "no 3D data for form " form))
          ((not (and (setq r (medcb-find form shape sz)) (medcb-row-ok r)))
            (strcat "no " form " " shape " " (medcb-size-text sz) "\" row in the conduit body data"))))
      (setq pt  (trans (cdr (assoc 10 ed)) e 0)
            a   (if (assoc 50 ed) (cdr (assoc 50 ed)) 0.0)
            rot (angle '(0.0 0.0 0.0) (trans (list (cos a) (sin a) 0.0) e 0 T))
            geom (if reason
                   (medcb-geom-ph shape (if (> sz 0.0) sz 1.0) (medcb-conduit-od (if (> sz 0.0) sz 1.0)))
                   (medcb-geom-for form shape gsz))
            hubs (medcb-get "HUBS" geom)
            tol (medcb-brk-tol blk ed)
            lg  (medcb-legs pt runs tol))
      (if (cadr lg) (setq pt (list (car pt) (cadr pt) (cadr lg))))   ; conduit elevation wins
      (setq rot (+ rot (medcb-2d-offset blk shape)) k 0)
      ;; snap: quarter turns about Z from the drawn rotation; per turn the symbol's own
      ;; tilt first, then the alternatives (LB family / TB: back hub tilted +/-90 deg
      ;; into the plan; LL / LR: cover up or turned over). The first candidate with the
      ;; most hubs on conduit legs wins, so ties keep the drawn rotation and the tilt
      ;; the symbol implies (the body stays on the drawn +X leg when it can).
      (if (and *MEDCB-SNAP* (car lg))
        (progn
          (setq best -1 tbest flip i 0)
          (repeat 4
            (foreach tl (cons flip (medcb-alt-tilts shape flip))
              (setq sc (medcb-score (medcb-wcs-hubs hubs (+ rot (* i (/ pi 2.0))) tl) (car lg)))
              (if (> sc best) (setq best sc k i tbest tl)))
            (setq i (1+ i)))
          (setq rot (+ rot (* k (/ pi 2.0))) flip tbest)))
      (while (< rot 0.0) (setq rot (+ rot (* 2.0 pi))))
      (while (>= rot (* 2.0 pi)) (setq rot (- rot (* 2.0 pi))))
      (list (cons "HANDLE" h) (cons "ENT" e) (cons "CODE" (fix code)) (cons "KEY" (car res)) (cons "SRC" (cadr res))
            (cons "FORM" form) (cons "SHAPE" shape) (cons "SIZE" sz) (cons "BLK2D" blk) (cons "PT" pt)
            (cons "ROT" rot) (cons "FLIP" flip) (cons "TURN" k) (cons "LEGS" (length (car lg)))
            (cons "HUBS" (medcb-hub-tols (medcb-wcs-hubs hubs rot flip) blk ed
                                         (angle '(0.0 0.0 0.0) (trans (list (cos a) (sin a) 0.0) e 0 T))))
            (cons "REASON" reason) (cons "NOTE" note)
            (cons "TOL" tol) (cons "SIZE2" sz2)))))

;; every MED_FITTING INSERT in the drawing -> (bodies not-modelled-count)
(defun medcb-collect ( / ss i b bodies nm runs)
  (setq *MEDCB-FITCAT* nil *MEDCB-KEYCSV* nil nm 0 runs (medcb-conduit-runs))
  (if (setq ss (ssget "_X" (list '(0 . "INSERT") (list -3 (list (medcb-app "FITTING"))))))
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq b (medcb-body-of (ssname ss i) runs))
        (cond ((= (type b) 'STR) (setq nm (1+ nm)))
              (b (setq bodies (cons b bodies))
                 (if med3d-dbg
                   (med3d-dbg (strcat "body " (medcb-get "HANDLE" b) " code " (itoa (medcb-get "CODE" b)) " "
                                      (medcb-get "KEY" b) " (" (medcb-get "SRC" b) ") -> " (medcb-get "SHAPE" b) " "
                                      (medcb-size-text (max 0.0625 (medcb-get "SIZE" b))) "\" on " (medcb-get "BLK2D" b)
                                      ", rot " (rtos (* 180.0 (/ (medcb-get "ROT" b) pi)) 2 1) " deg"
                                      (cond ((numberp (medcb-get "FLIP" b))
                                              (strcat " tilted " (rtos (* 180.0 (/ (medcb-get "FLIP" b) pi)) 2 0) " deg about X"))
                                            ((medcb-get "FLIP" b) " flipped") (T ""))
                                      ", " (itoa (medcb-get "LEGS" b)) " conduit leg(s), quarter turns "
                                      (itoa (medcb-get "TURN" b))
                                      (if (medcb-get "REASON" b) (strcat " - " (medcb-get "REASON" b)) ""))))))
        (setq i (1+ i)))))
  (list (reverse bodies) nm))

;; record for the conduit planner (*MED3D-FITS*): (handle pt hubs search-radius); nil
;; without a size
;; mirrored fittings get none (the conduit is left as drawn)
(defun medcb-fit-rec (b)
  (if (and (> (medcb-get "SIZE" b) 0.0) (not (medcb-get "MIRROR" b)))
    (list (medcb-get "HANDLE" b) (medcb-get "PT" b) (medcb-get "HUBS" b) (medcb-get "TOL" b))))

;; placeholder for any form / shape (unknown ones: box with run hubs)
(defun medcb-ensure-ph (form shape sz / name)
  (setq sz (medcb-sz1 sz))
  (setq name (medcb-ph-name (if (= form "") "NA" form) shape sz))
  (cond ((medcb-block-current name) (list name "PH-EXISTS"))
        ((medcb-build-block name (medcb-geom-ph shape sz (medcb-conduit-od sz))) (list name "PLACEHOLDER"))))
(defun medcb-ensure-body (form shape sz reason)
  (cond ((not (and (numberp (medcb-sz1 sz)) (> (medcb-sz1 sz) 0.0))) nil)
        (reason (medcb-ensure-ph form shape sz))
        (T (medcb-ensure-block form shape sz))))

;; insert the bodies; returns (("REFS" ename ...) ("PLACED" . n) ("PH" . n) ("FLAGGED" . n)
;;   ("MIRRORED" . n) ("VERT" . vertical-conduit-solids) ("SKIPPED" (handle "FITTING" reason) ...))
(setq *MEDCB-MIRROR-FLAG* "MIRRORED FITTING - re-insert, do not mirror")
;; vertical conduit stored on the fitting insert by the menu's dcon_ins (up / down
;; symbols): MED_CONDUIT (app tag size code dist msr) + VERT_DATA (app r1 r2 dir r4).
;; Returns (dir length) or nil.
(defun medcb-vert-data (e / vd cd dir len)
  (setq vd (xdataget e "VERT_DATA") cd (xdataget e (medcb-app "CONDUIT")))
  (if (and vd cd (numberp (setq dir (nth 3 vd))) (/= dir 0)
           (numberp (setq len (nth 4 cd))) (> len 0.0))
    (list (if (> dir 0) 1.0 -1.0) (float len))))
;; the vertical conduit of body b as a cylinder from the face of the hub pointing
;; that way (else from the insertion point) to insertion Z + dir x length.
;; Returns (ename-or-nil flagged-p)
(defun medcb-vert-leg (b / e vd dir len pt hub best d od z0 z1 sol ms)
  (setq e (medcb-get "ENT" b) pt (medcb-get "PT" b))
  (if (and (setq vd (medcb-vert-data e)) pt)
    (progn
      (setq dir (car vd) len (cadr vd) best (medcb-cos-tol))
      (foreach h (medcb-get "HUBS" b)
        (if (>= (setq d (* dir (caddr (caddr h)))) best) (setq best d hub h)))
      (setq od (cond ((and med3d-run-od (numberp (setq d (vl-catch-all-apply 'med3d-run-od (list e "CONDUIT")))) (> d 0.0)) d)
                     ((medcb-conduit-od (medcb-get "SIZE" b)))
                     (T (+ (max 0.5 (medcb-get "SIZE" b)) 0.35)))
            z0 (+ (caddr pt) (if hub (caddr (cadr hub)) 0.0))
            z1 (+ (caddr pt) (* dir len)))
      (if (> (* dir (- z1 z0)) 1e-6)
        (progn
          (setq ms (vla-get-ModelSpace (medcb-doc))
                sol (vl-catch-all-apply 'vlax-invoke
                      (list ms 'AddCylinder (list (car pt) (cadr pt) (/ (+ z0 z1) 2.0)) (/ od 2.0) (abs (- z1 z0)))))
          (if (medcb-ok sol)
            (progn
              (vlax-put sol 'Layer (medcb-body-layer))
              (setq sol (vlax-vla-object->ename sol))
              (if MEDStamp3DFromBom (vl-catch-all-apply 'MEDStamp3DFromBom (list sol e "CONDUIT" nil)))
              (list sol (not hub)))
            (list nil T)))
        (list nil nil)))))
(defun medcb-place-all (bodies / h pt reason res ref e refs placed ph flagged skipped mir vl nv)
  (setq placed 0 ph 0 flagged 0 mir 0 nv 0)
  (foreach b bodies
    (setq h (medcb-get "HANDLE" b) pt (medcb-get "PT" b) reason (medcb-get "REASON" b)
          res (if (not (medcb-get "MIRROR" b))
                (medcb-ensure-body (medcb-get "FORM" b) (medcb-get "SHAPE" b)
                                   (if (medcb-get "SIZE2" b) (list (medcb-get "SIZE" b) (medcb-get "SIZE2" b)) (medcb-get "SIZE" b))
                                   reason))
          ref (if res (medcb-insert-block res pt (medcb-get "ROT" b) (medcb-get "FLIP" b))))
    (if (medcb-get "NOTE" b)
      (princ (strcat "\nMED3D note: fitting " h " (" (medcb-get "KEY" b) "): " (medcb-get "NOTE" b) ".")))
    (if ref
      (progn
        (setq e (vlax-vla-object->ename ref) refs (cons e refs))
        (if MEDStamp3DFromBom (vl-catch-all-apply 'MEDStamp3DFromBom (list e (medcb-get "ENT" b) "FITTING" nil)))))
    ;; vertical conduit leg from the fitting's own conduit xdata (not for mirrored)
    (if (and (not (medcb-get "MIRROR" b)) (setq vl (medcb-vert-leg b)))
      (progn
        (if (car vl) (setq refs (cons (car vl) refs) nv (1+ nv)))
        (if (cadr vl)
          (progn
            (setq flagged (1+ flagged)
                  skipped (cons (list h "CONDUIT" (strcat "vertical conduit on fitting " h ": no hub points that way"
                                                          (if (car vl) " - built from the insertion point" "")))
                                skipped))
            (if med3d-flag-at
              (med3d-flag-at pt (max 1.0 (* 2.0 (medcb-get "SIZE" b))) (strcat "3D FLAG " h " vertical conduit")))))))
    (cond
     ((medcb-get "MIRROR" b)
      (setq mir (1+ mir) flagged (1+ flagged)
            skipped (cons (list h "FITTING" (strcat (medcb-get "KEY" b) " on " (medcb-get "BLK2D" b) ": " reason)) skipped))
      (princ (strcat "\nMED3D FLAG: fitting " h " (" (medcb-get "BLK2D" b) ") is mirrored - no 3D body; re-insert it without mirroring."))
      (if med3d-flag-at
        (med3d-flag-at pt (max 1.0 (* 2.0 (medcb-get "SIZE" b))) (strcat *MEDCB-MIRROR-FLAG* " (" h ")"))))
     ((and ref (not reason))
      (setq placed (1+ placed)))
     (T
      (progn
        (if ref (setq ph (1+ ph)))
        (if (not reason) (setq reason "block could not be created / inserted"))
        (setq flagged (1+ flagged)
              skipped (cons (list h "FITTING" (strcat (medcb-get "KEY" b) ": " reason
                                                      (if ref " - placeholder on MED_3DFLAG" "")))
                            skipped))
        (princ (strcat "\nMED3D FLAG: fitting " h " " (medcb-get "KEY" b) ": " reason "."))
        (if med3d-flag-at
          (med3d-flag-at pt (max 1.0 (* 2.0 (medcb-get "SIZE" b))) (strcat "3D FLAG " h " " (medcb-get "KEY" b))))))))
  (list (cons "REFS" (reverse refs)) (cons "PLACED" placed) (cons "PH" ph) (cons "FLAGGED" flagged)
        (cons "MIRRORED" mir) (cons "VERT" nv) (cons "SKIPPED" (reverse skipped))))

(princ (strcat "Done.\nMED3DFittings " *MEDCB-VERSION* " loaded: MEDCBINS MEDCBTEST MEDCBALL MEDCBDATA MEDCBVER"))
(princ)
