;;; MED3DFittings.lsp - rigid conduit body (Condulet) 3D blocks for MED (AutoCAD 2024+).
;;;
;;; Commands
;;;   MEDCBINS   insert one conduit body (type, form, trade size) at picked points
;;;   MEDCBTEST  insert LB LR LL T TB C of one form + size in a row, with labels
;;;   MEDCBDATA  reload the dimension data and print what is covered
;;;   MEDCBVER   print version / data source
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
;;; Block: MED_CB_RGD_<form>_<shape>_<size>, size = trade size to 2 decimals with "-"
;;;   for the point: MED_CB_RGD_F7_LB_1-00, MED_CB_RGD_F8_T_1-25, MED_CB_RGD_F7_C_0-50.
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
;;;     LL  RUN +X, BRANCH -Y          LR  RUN +X, BRANCH +Y
;;;   LL / LR: looking at the cover with the RUN hub pointing east (+X), LL opens to the
;;;   south (-Y) and LR to the north (+Y) - the same as the trade rule "cover toward you,
;;;   end hub down: side opening on the left = LL, right = LR".
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
(setq *MEDCB-VERSION* "2026-09-30 r1 (feature/3dpath)")
(setq *MEDCB-SHAPES* '("LB" "LR" "LL" "T" "TB" "C"))
(setq *MEDCB-FORMS* '("F7" "F8" "M9"))
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

;; 1.0 -> "1-00", 0.5 -> "0-50", 1.25 -> "1-25" (no RTOS: DIMZIN would strip zeros)
(defun medcb-size-tag (sz / n)
  (setq n (fix (+ (* (float sz) 100.0) 0.5)))
  (strcat (itoa (/ n 100)) "-" (medcb-pad2 (rem n 100))))
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
  (setq n (fix (+ (* sz 16.0) 0.5)) w (/ n 16) f (rem n 16))
  (cond ((= f 0) (itoa w))
        (T (setq f (cond ((= f 8) "1/2") ((= f 4) "1/4") ((= f 12) "3/4") (T (strcat (itoa f) "/16"))))
           (if (> w 0) (strcat (itoa w) "-" f) f))))

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
(defun medcb-row-ok (r)
  (and (medcb-get "A" r) (medcb-get "B" r) (medcb-get "C" r) (medcb-get "D" r) (medcb-get "E" r)))

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

(defun medcb-csv-path ( / here c r)
  (setq here (findfile "MED3DFittings.lsp"))
  (foreach c (list (findfile *MEDCB-CSV*)
                   (if here (strcat (vl-filename-directory here) "\\..\\Data\\seed\\" *MEDCB-CSV*))
                   (if here (strcat (vl-filename-directory here) "\\Data\\seed\\" *MEDCB-CSV*)))
    (if (and (not r) c (findfile c)) (setq r (findfile c))))
  r)

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
  (setq key (list (strcase form) (strcase shape) (medcb-size-tag sz)))
  (foreach x (medcb-load-data nil) (if (and (not r) (equal (medcb-row-key x) key)) (setq r x)))
  r)

;; rigid steel conduit OD (MEDConduitOD code 1) when MEDFunctions is loaded
(defun medcb-conduit-od (sz / r)
  (if med_conduit_od
    (progn (setq r (vl-catch-all-apply 'med_conduit_od (list 1 sz)))
           (if (and (numberp r) (> r 0.0)) (float r)))))

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
              (medcb-geom-wh shape a b c d e hod hl cod (- c k) h "body width reduced so the side hub fits C"))))
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
        sl (if (member shape '("LB" "TB")) (- b h) (- c w)))
  (if (and (not (= shape "C")) (< sl (- minh 1e-9))) (setq short minh sl minh note "side/back hub lengthened to 0.25 x hub OD"))
  (setq ov (* 0.25 (min w h)))
  (cond
    (ell (medcb-hub "RUN" (list (- a (/ w 2.0)) 0.0 0.0) '(1.0 0.0 0.0) rl))
    (T (medcb-hub "RUN" (list (/ a 2.0) 0.0 0.0) '(1.0 0.0 0.0) rl)
       (medcb-hub "RUN2" (list (/ a -2.0) 0.0 0.0) '(-1.0 0.0 0.0) rl)))
  (cond
    ((member shape '("LB" "TB")) (medcb-hub "BACK" (list 0.0 0.0 (- (+ (/ h 2.0) sl))) '(0.0 0.0 -1.0) sl))
    ((member shape '("LR" "T")) (medcb-hub "BRANCH" (list 0.0 (+ (/ w 2.0) sl) 0.0) '(0.0 1.0 0.0) sl))
    ((= shape "LL") (medcb-hub "BRANCH" (list 0.0 (- (+ (/ w 2.0) sl)) 0.0) '(0.0 -1.0 0.0) sl)))
  (list (cons "SHAPE" shape) (cons "W" w) (cons "H" h) (cons "M" m) (cons "DOPEN" dp) (cons "LBODY" lb)
        (cons "HUBOD" hub) (cons "RUNLEN" rl) (cons "SIDELEN" (if (= shape "C") nil sl)) (cons "NOTE" note) (cons "SHORT" short)
        (list "BODY" cx lb w (/ h -2.0) (- (/ h 2.0) t0))
        (list "COVER" cx (min lb (+ e m)) (min w (+ dp m)) (- (/ h 2.0) t0) (/ h 2.0))
        (cons "CYLS" (reverse cyls))
        (cons "HUBS" (reverse hubs))))

;; placeholder (no data): box, same hub directions; size only from trade size / OD
(defun medcb-geom-ph (shape sz cod / d0 l w h ell x0 x1 hubs)
  (setq shape (strcase shape) ell (member shape '("LB" "LL" "LR"))
        d0 (if cod cod (+ sz 0.35)) l (* 4.5 d0) w (* 1.6 d0) h w
        x0 (if ell (/ w -2.0) (/ l -2.0)) x1 (+ x0 l))
  (setq hubs (list (list "RUN" (list x1 0.0 0.0) '(1.0 0.0 0.0))))
  (if (not ell) (setq hubs (append hubs (list (list "RUN2" (list x0 0.0 0.0) '(-1.0 0.0 0.0))))))
  (cond
    ((member shape '("LB" "TB")) (setq hubs (append hubs (list (list "BACK" (list 0.0 0.0 (/ h -2.0)) '(0.0 0.0 -1.0))))))
    ((member shape '("LR" "T")) (setq hubs (append hubs (list (list "BRANCH" (list 0.0 (/ w 2.0) 0.0) '(0.0 1.0 0.0))))))
    ((= shape "LL") (setq hubs (append hubs (list (list "BRANCH" (list 0.0 (/ w -2.0) 0.0) '(0.0 -1.0 0.0)))))))
  (list (cons "SHAPE" shape) (cons "PLACEHOLDER" T)
        (list "BOX" (list x0 (/ w -2.0) (/ h -2.0)) (list x1 (/ w 2.0) (/ h 2.0)))
        (cons "HUBS" hubs)))

;; geometry for form/shape/size from the data (placeholder geometry when no row)
(defun medcb-geom-for (form shape sz / r cod)
  (setq cod (medcb-conduit-od sz))
  (if (and (setq r (medcb-find form shape sz)) (medcb-row-ok r))
    (medcb-geom shape (medcb-get "A" r) (medcb-get "B" r) (medcb-get "C" r) (medcb-get "D" r) (medcb-get "E" r)
                (medcb-get "HUBOD" r) (medcb-get "HUBLEN" r) cod)
    (medcb-geom-ph shape sz cod)))
(defun medcb-hubs (form shape sz) (medcb-get "HUBS" (medcb-geom-for form shape sz)))

;;; ------------------------------------------------------------------ drawing
(defun medcb-doc () (vla-get-ActiveDocument (vlax-get-acad-object)))
(defun medcb-ok (x) (and x (not (vl-catch-all-error-p x))))
(defun medcb-union (a b / r)
  (if (and a b) (progn (setq r (vl-catch-all-apply 'vlax-invoke (list a 'Boolean 0 b))) a) (if a a b)))

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

;; cylinder p0 -> p1 (axis parallel to X, Y or Z)
(defun medcb-add-cyl (blk p0 p1 r / d len mid s)
  (setq d (mapcar '- p1 p0) len (distance p0 p1) mid (medcb-vx (medcb-v+ p0 p1) 0.5))
  (if (> len 1e-6)
    (progn
      (setq s (vl-catch-all-apply 'vlax-invoke (list blk 'AddCylinder '(0.0 0.0 0.0) r len)))
      (if (medcb-ok s)
        (progn
          (cond ((> (abs (car d)) (* 0.5 len)) (vlax-invoke s 'Rotate3D '(0.0 0.0 0.0) '(0.0 1.0 0.0) (/ pi 2.0)))
                ((> (abs (cadr d)) (* 0.5 len)) (vlax-invoke s 'Rotate3D '(0.0 0.0 0.0) '(1.0 0.0 0.0) (/ pi 2.0))))
          (vlax-invoke s 'Move '(0.0 0.0 0.0) mid)
          s)))))

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

;; new block definition from geometry; nil (and no block left behind) on failure
(defun medcb-build-block (name geom / blks blk body cov s ok bx lay)
  (setq blks (vla-get-Blocks (medcb-doc))
        blk (vl-catch-all-apply 'vlax-invoke (list blks 'Add '(0.0 0.0 0.0) name)))
  (if (medcb-ok blk)
    (progn
      (if (setq bx (medcb-get "BOX" geom))
        (progn
          (setq lay (medcb-flag-layer)
                body (vl-catch-all-apply 'vlax-invoke
                       (list blk 'AddBox (medcb-vx (medcb-v+ (car bx) (cadr bx)) 0.5)
                             (- (car (cadr bx)) (car (car bx))) (- (cadr (cadr bx)) (cadr (car bx)))
                             (- (caddr (cadr bx)) (caddr (car bx))))))
          (if (medcb-ok body) (progn (vlax-put body 'Layer lay) (vlax-put body 'Color 1)) (setq body nil)))
        (progn
          (setq s (medcb-get "BODY" geom)
                body (medcb-add-slot blk (nth 0 s) (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s)))
          (foreach cy (medcb-get "CYLS" geom)
            (setq body (medcb-union body (medcb-add-cyl blk (nth 0 cy) (nth 1 cy) (nth 2 cy)))))
          (if body (progn (vlax-put body 'Layer "0") (vlax-put body 'Color 0)))   ; ByBlock
          (setq s (medcb-get "COVER" geom)
                cov (medcb-add-slot blk (nth 0 s) (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s)))
          (if cov (progn (vlax-put cov 'Layer "0") (vlax-put cov 'Color 8)))))
      (if body
        name
        (progn (vl-catch-all-apply 'vla-delete (list blk)) nil)))))

;; Block for form/shape/size, generated on demand. Returns (name status):
;;   "EXISTS" (already defined, left alone) "CREATED" "PLACEHOLDER" (no data, _PH made)
;;   "PH-EXISTS"; nil when the shape is unknown or the block could not be built.
(defun medcb-ensure-block (form shape sz / name r geom)
  (setq form (strcase form) shape (strcase shape))
  (cond
    ((not (member shape *MEDCB-SHAPES*)) nil)
    ((not (and (numberp sz) (> sz 0.0))) nil)
    ((tblsearch "BLOCK" (setq name (medcb-block-name form shape sz))) (list name "EXISTS"))
    ((and (setq r (medcb-find form shape sz)) (medcb-row-ok r))
      (setq geom (medcb-geom-for form shape sz))
      (if (medcb-build-block name geom) (list name "CREATED")))
    ((tblsearch "BLOCK" (setq name (medcb-ph-name form shape sz))) (list name "PH-EXISTS"))
    (T (if (medcb-build-block name (medcb-geom-ph shape sz (medcb-conduit-od sz))) (list name "PLACEHOLDER")))))

;; insert in model space; pt WCS; rot radians about WCS Z. Returns (vla-ref name status)
(defun medcb-insert (form shape sz pt rot / res ref)
  (if (setq res (medcb-ensure-block form shape sz))
    (progn
      (setq ref (vl-catch-all-apply 'vlax-invoke
                  (list (vla-get-ModelSpace (medcb-doc)) 'InsertBlock pt (car res) 1.0 1.0 1.0 rot)))
      (if (medcb-ok ref)
        (progn
          (vlax-put ref 'Layer (if (wcmatch (cadr res) "PLACEHOLDER,PH-EXISTS") (medcb-flag-layer) (medcb-body-layer)))
          (list ref (car res) (cadr res)))))))

;;; ----------------------------------------------------------------- commands
(defun medcb-ask-shape ( / k)
  (initget "LB LR LL T TB C")
  (setq k (getkword (strcat "\nConduit body type [LB/LR/LL/T/TB/C] <" *MEDCB-SHAPE* ">: ")))
  (if k (setq *MEDCB-SHAPE* k))
  *MEDCB-SHAPE*)
(defun medcb-ask-form ( / k)
  (initget "F7 F8 M9")
  (setq k (getkword (strcat "\nCondulet form (F7 = Form 7, F8 = Form 8, M9 = Mark 9 aluminum) [F7/F8/M9] <" *MEDCB-FORM* ">: ")))
  (if k (setq *MEDCB-FORM* k))
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
  (setq shape (medcb-ask-shape) form (medcb-ask-form) sz (medcb-ask-size))
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
  (setq form (medcb-ask-form) sz (medcb-ask-size))
  (if (setq base (getpoint "\nBase point for the row <0,0,0>: ")) (setq base (trans base 1 0)) (setq base '(0.0 0.0 0.0)))
  (setq x 0.0 maxw 0.0 gap (max 2.0 (* 2.0 sz)) h (max 0.25 (* 0.2 sz)))
  (foreach shape *MEDCB-SHAPES*
    (setq geom (medcb-geom-for form shape sz))
    (setq wid (medcb-geom-width geom))
    (if (> wid maxw) (setq maxw wid)))
  (foreach shape *MEDCB-SHAPES*
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
;; (xmin xmax) of the geometry along X / max |y| extent, for spacing the test row
(defun medcb-geom-xrange (geom / lo hi bx)
  (if (setq bx (medcb-get "BOX" geom))
    (list (car (car bx)) (car (cadr bx)))
    (progn
      (setq lo 0.0 hi 0.0)
      (foreach hb (medcb-get "HUBS" geom)
        (setq lo (min lo (car (cadr hb))) hi (max hi (car (cadr hb)))))
      (list (min lo (- (nth 0 (medcb-get "BODY" geom)) (/ (nth 1 (medcb-get "BODY" geom)) 2.0))) hi))))
(defun medcb-geom-width (geom / w bx)
  (if (setq bx (medcb-get "BOX" geom))
    (cadr (cadr bx))
    (progn
      (setq w (/ (medcb-get "W" geom) 2.0))
      (foreach hb (medcb-get "HUBS" geom) (setq w (max w (abs (cadr (cadr hb))))))
      w)))

(defun c:MEDCBDATA ( / rows n from)
  (setq rows (medcb-load-data T) n 0)
  (princ (strcat "\nMED3DFittings: " (itoa (length rows)) " conduit body row(s)"
                 (if rows (strcat " (first from " (medcb-get "FROM" (car rows)) ")") "")
                 "; CSV: " (if (medcb-csv-path) (medcb-csv-path) "not found")))
  (foreach f *MEDCB-FORMS*
    (foreach s *MEDCB-SHAPES*
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

(princ (strcat "Done.\nMED3DFittings " *MEDCB-VERSION* " loaded: MEDCBINS MEDCBTEST MEDCBDATA MEDCBVER"))
(princ)
