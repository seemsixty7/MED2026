;;; MEDDuctbank.lsp - MED ductbank routing, first test build (MVP).
;;; Design: docs/design/ductbank-routing.md (Draft 2).
;;; Commands: DUCTBANK (build a bank from a routed reference: a MED conduit, or a plain
;;;           3D polyline / polyline / line route with elevation), DBEDIT (reopen a bank's
;;;           stored settings and rebuild it in place), DBLIST (list a bank), DBDELETE (erase a
;;;           bank, restore the reference), DBSEED (add the ductbank codes to MEDType).
;;;           -DUCTBANK / -DBEDIT are the command-line versions.
;;; DUCTBANK opens the MED-DotNet dialog (MED-DuctbankDialog); -DUCTBANK is the command-line
;;; flow (also the fallback when the DLL is not loaded). 2D plan + sections, flat trunk; the
;;; concrete envelope (with the stub-up encasement turn-up) and spacer stations are modelled as 3D solids on layer
;;; <_MED3DMODELPREFIX>Ductbank (3DMEDModel-Ductbank), which MEDMAKE3D pulls into the 3D export.
;;; Underground defaults: encased PVC (code 3), 1" minimum, stub-up risers and stub elbows
;;; PVC-coated RGS (option: plain RGS, tape wrap noted),
;;; stock elbows R24 under 4" / R36 at 4" and up (nested rule may raise), no spacers
;;; in bends, elbows as broken segments carrying 3 MED_FITTING records
;;; (PVC-coated RGS elbow + adapter + adapter), Carlon Snap-N-Stac 2" separation,
;;; spacer stations every 8 ft, cover 3" top/bottom and 2" sides from conduit OD.
;;; Bank data lives in regapp DBANK_DATA (not MED*, so BOM / MEDLIST never see it).
(princ "\nLoading MEDDuctbank...")
(vl-load-com)
(regapp "DBANK_DATA")
(setq *DBK-VERSION* "2026-10-06 MVP3")

;;; ------------------------------------------------------------------ defaults
;;; med.spc may set any of these; the patch never overwrites med.spc, so every
;;; variable has its default here.
(defun dbk-def (sym val) (if (null (eval sym)) (set sym val)) (eval sym))
(dbk-def '_DBKCOVERTOP 3.0)        ; concrete cover above the top conduit OD
(dbk-def '_DBKCOVERBOT 3.0)        ; minimum cover below the bottom conduit OD
(dbk-def '_DBKCOVERLEFT 2.0)       ; side cover, left looking from the section end
(dbk-def '_DBKCOVERRIGHT 2.0)      ; side cover, right
(dbk-def '_DBKCOVEREND 2.0)        ; cover beyond the outermost stub-up riser
(dbk-def '_DBKMINGAP 2.0)          ; minimum clear gap OD to OD (checked, flagged)
(dbk-def '_DBKSEP 2.0)             ; Snap-N-Stac separation (1.5, 2 or 3)
(dbk-def '_DBKSPINT 96.0)          ; spacer station interval (Carlon: 8-10 ft)
(dbk-def '_DBKSPEND 12.0)          ; first station from each trunk end
(dbk-def '_DBKTRANSL 60.0)         ; transition length stub spacing -> spacer spacing
(dbk-def '_DBKMAXTAPER 5.0)        ; flag tapers steeper than this (degrees)
(dbk-def '_DBKSTUBSTRAIGHT 12.0)   ; straight between the last stub elbow and the transition
(dbk-def '_DBKMINSIZE 1.0)         ; minimum underground conduit trade size
(dbk-def '_DBKCONCODE 3)           ; straights: Rigid non-metallic (PVC)
(dbk-def '_DBKRISERCODE 2)         ; stub-up risers + stub elbows: 2 PVC-coated RGS, 1 plain RGS
(dbk-def '_DBKSTUBWRAP 1)          ; plain RGS stub-ups: 1 = tape wrap noted (BOM code 174), 0 = no wrap
(dbk-def '_DBKMODEL3D 1)           ; 1 = model the envelope + spacer stations as 3D solids
(dbk-def '_DBKMODELSUFFIX "Ductbank") ; 3D model layer = _MED3DMODELPREFIX + this
(dbk-def '_DBKSPTHICK 2.0)         ; spacer thickness along the run (3D model only)
(dbk-def '_DBKUSEDIALOG 1)         ; DUCTBANK: 1 = grid dialog when MED-DotNet is loaded, 0 = always command line
(dbk-def '_DBKSECTPICK 0)          ; dialog: 1 = pick the section location after OK
(dbk-def '_DBKENCASE "Auto")       ; stub-up encasement turn-up top: "Auto" = top of the stub elbow sweep,
                                   ; "Top" = the stub-up top EL (grade), or an elevation (drawing units)
(dbk-def '_DBKREFSIZE 4.0)         ; plain route reference (no MED data): default trade size
(dbk-def '_MED3DMODELPREFIX "3DMEDModel-") ; shared with MEDMAKE3D (MED3DPath.lsp)
(dbk-def '_DBKADAPTER 170)         ; PVC female adapter (elbow records 2 and 3)
(dbk-def '_DBKREDUCERMODE "CENTER"); S287F / S287J: CENTER (assumed) or BOTTOM
(dbk-def '_DBKTAGPAT "{BANK}-{POS}")
(dbk-def '_DBKSECTSCALE 1.0)       ; section drawing scale factor (1 = full size)
(dbk-def '_DBKPLANTEXT 1.0)        ; plan text height
(dbk-def '_DBKSECTTEXT 0.5)        ; section text height (times the section scale)

;;; Carlon Snap-N-Stac combo spacers (catalog 7F78, 2006; VERIFY against current data)
;;; (part size od sep pitchV pitchH seatBottom catalogCL pieceLength MEDTypeCode)
(setq *DBK-SNAPNSTAC* '(
  ("SP2W20-2" 2.0 2.375 2.0 4.38 4.38 3.13 4.25  8.75 521)
  ("SP2W30-2" 2.0 2.375 3.0 5.38 5.38 4.13 5.25 10.75 522)
  ("SP3W20-2" 3.0 3.500 2.0 5.50 5.50 3.63 5.38 11.00 523)
  ("SP3W30-2" 3.0 3.500 3.0 6.50 6.50 4.63 6.38 13.00 524)
  ("SP4W15-2" 4.0 4.500 1.5 6.00 6.00 3.38 5.56 12.00 525)
  ("SP4W20-2" 4.0 4.500 2.0 6.50 6.50 3.88 6.06 13.00 526)
  ("SP4W30-2" 4.0 4.500 3.0 7.50 7.50 4.88 7.06 15.00 527)
  ("SP5W20-2" 5.0 5.500 2.0 7.56 7.56 4.38 7.25 15.12 528)
  ("SP5W30-2" 5.0 5.500 3.0 8.56 8.56 5.38 8.25 17.14 529)
  ("SP6W20-2" 6.0 6.625 2.0 8.62 8.62 4.13 7.38 17.25 530)
  ("SP6W30-2" 6.0 6.625 3.0 9.62 9.62 5.13 8.38 19.25 531)))
(setq *DBK-REDUCERS* '((1.0 "S287F" 568) (2.0 "S287J" 569)))   ; (conduit size part code)
(setq *DBK-STRAP* '("S28612" 570))                               ; beaded strap, top tier
;; PVC-coated RGS elbows by sweep and radius (MEDType FITTING, see DBSEED)
(setq *DBK-ELBOWS* '((90 (24.0 . 160) (36.0 . 161) (48.0 . 162))
                     (45 (24.0 . 163) (36.0 . 164) (48.0 . 165))))
(setq *DBK-STOCKR* '(24.0 36.0 48.0))
;; plain RGS elbows (stub-ups with _DBKRISERCODE 1): existing MEDType 89/90/91 + seeded 166-169
(setq *DBK-ELBOWS-RGS* '((90 (18.0 . 89) (24.0 . 90) (36.0 . 91) (48.0 . 166))
                         (45 (24.0 . 167) (36.0 . 168) (48.0 . 169))))
;; riser-side coupling of a stub elbow: PVC-coated RGS 173 (seeded), plain RGS 8 (existing)
(setq *DBK-COUPLING* '((2 . 173) (1 . 8)))
(setq *DBK-WRAPCODE* 174)               ; tape wrap, plain RGS stub-up (one record per stub-up)
;; PVC Sch 40 OD fallback when MEDConduitOD has no row
(setq *DBK-PVCOD* '((0.5 . 0.840) (0.75 . 1.050) (1.0 . 1.315) (1.25 . 1.660) (1.5 . 1.900)
                    (2.0 . 2.375) (2.5 . 2.875) (3.0 . 3.500) (3.5 . 4.000) (4.0 . 4.500)
                    (5.0 . 5.563) (6.0 . 6.625)))
;; every FITTING code in Data\seed\ductbank_medtype.csv except 89 (an old row, filled by DBSEED)
(setq *DBK-CODES* '(160 161 162 163 164 165 166 167 168 169 170 171 172 173 174) i 571)
(while (>= i 521) (setq *DBK-CODES* (append *DBK-CODES* (list i)) i (1- i)))
(setq *DBK-CODES* (vl-sort *DBK-CODES* '<) i nil)

;;; ------------------------------------------------------------------ helpers
(defun dbk-v+ (a b) (mapcar '+ a b))
(defun dbk-v- (a b) (mapcar '- a b))
(defun dbk-v* (a s) (mapcar '(lambda (x) (* x s)) a))
(defun dbk-dot (a b) (apply '+ (mapcar '* a b)))
(defun dbk-len (a) (sqrt (dbk-dot a a)))
(defun dbk-unit (a / l) (setq l (dbk-len a)) (if (> l 1e-12) (dbk-v* a (/ 1.0 l)) a))
(defun dbk-xy (p) (list (car p) (cadr p)))
(defun dbk-p3 (p z) (list (float (car p)) (float (cadr p)) (float z)))
(defun dbk-cross2 (a b) (- (* (car a) (cadr b)) (* (cadr a) (car b))))
(defun dbk-rnorm (d) (list (cadr d) (- (car d))))
(defun dbk-tan (a) (/ (sin a) (cos a)))
(defun dbk-acos (x) (cond ((>= x 1.0) 0.0) ((<= x -1.0) pi) (T (atan (sqrt (- 1.0 (* x x))) x))))
(defun dbk-deg (a) (* a (/ 180.0 pi)))
(defun dbk-r2 (x) (rtos x 2 2))
(defun dbk-r4 (x) (rtos x 2 4))
(defun dbk-ceil (x / f) (setq f (fix x)) (if (> (- x f) 1e-9) (1+ f) f))
(defun dbk-max (l) (apply 'max l))
(defun dbk-min (l) (apply 'min l))
(defun dbk-get (al k) (cdr (assoc k al)))
(defun dbk-put (al k v) (if (assoc k al) (subst (cons k v) (assoc k al) al) (cons (cons k v) al)))
(defun dbk-uniq (l / o) (foreach x l (if (not (member x o)) (setq o (cons x o)))) (reverse o))
(defun dbk-sz (s) (strcat (rtos s 5 2) "\""))
(defun dbk-subst-all (new old s / i j)
  (setq j 0)
  (while (setq i (vl-string-search old s j))
    (setq s (vl-string-subst new old s i) j (+ i (strlen new))))
  s)
(defun dbk-roundstock (r / s)
  (setq s (vl-some '(lambda (x) (if (>= x (- r 1e-6)) x)) *DBK-STOCKR*))
  (if s s r))
(defun dbk-rule (size) (if (< size 3.999) 24.0 36.0))
(defun dbk-typeabbr (code)
  (cond ((= code 3) "PVC") ((= code 2) "PVC-RGS") ((= code 1) "RGS") ((= code 4) "EMT")
        ((= code 6) "IMC") (T (strcat "C" (itoa code)))))
(defun dbk-od (code size / od)
  (setq od (if med_conduit_od (vl-catch-all-apply 'med_conduit_od (list code size))))
  (if (or (null od) (vl-catch-all-error-p od) (not (numberp od)) (<= od 0.0))
    (setq od (cdr (assoc size *DBK-PVCOD*))))
  (if (not od) (setq od (float size)))
  od)
(defun dbk-xd (items / l)
  (setq l (list "DBANK_DATA" '(1002 . "{")))
  (foreach p items (if p (setq l (append l (list (if (= (type p) 'STR) (cons 1000 p) p))))))
  (append l (list '(1002 . "}"))))
(defun dbk-xdval (ent key / xd r)
  (setq xd (cdr (assoc -3 (entget ent '("DBANK_DATA")))))
  (if xd
    (foreach it (cdar xd)
      (if (and (= (car it) 1000) (= (strcase (substr (cdr it) 1 (1+ (strlen key)))) (strcat (strcase key) "=")))
        (setq r (substr (cdr it) (+ 2 (strlen key)))))))
  r)
;; every value of a repeated key (e.g. P= position records on the envelope), in order
(defun dbk-xdvals (ent key / xd out)
  (setq xd (cdr (assoc -3 (entget ent '("DBANK_DATA")))))
  (if xd
    (foreach it (cdar xd)
      (if (and (= (car it) 1000) (= (strcase (substr (cdr it) 1 (1+ (strlen key)))) (strcat (strcase key) "=")))
        (setq out (cons (substr (cdr it) (+ 2 (strlen key))) out)))))
  (reverse out))
;; encasement setting: "Auto", "Top" or a real elevation (from a string, number or nil)
(defun dbk-encval (v / n)
  (cond ((numberp v) (float v))
        ((not (= (type v) 'STR)) "Auto")
        ((wcmatch (strcase (vl-string-trim " " v)) "T*") "Top")
        ((setq n (distof (vl-string-trim " " v) 2)) n)
        (T "Auto")))
(defun dbk-encstr (v / s)
  (if (numberp v)
    (progn (setq s (rtos v 2 4))
           (if (vl-string-search "." s) (vl-string-right-trim "." (vl-string-right-trim "0" s)) s))
    (if (= v "Top") "Top" "Auto")))
(defun dbk-enclabel (v)
  (setq v (dbk-encval v))
  (cond ((numberp v) (strcat "EL " (dbk-encstr v))) ((= v "Top") "Top = stub-up top EL") (T "Auto = top of the elbow sweep")))
(defun dbk-joinstr (l sep / s) (if l (progn (setq s (car l)) (foreach x (cdr l) (setq s (strcat s sep x))) s) ""))
(defun dbk-disclaimer ()
  (if (= (type med3d-disclaimer) 'USUBR) (med3d-disclaimer)
    (princ "\nNOTE: 3D models are approximations for layout and coordination only and are not reproductions of manufacturer specifications. Verify all dimensions against manufacturer data.")))
(defun dbk-model-layer () (strcat (if (= (type _MED3DMODELPREFIX) 'STR) _MED3DMODELPREFIX "3DMEDModel-") _DBKMODELSUFFIX))
(defun dbk-say (s) (princ (strcat "\n" s)))

;;; ------------------------------------------------------------------ prompts
(defun dbk-ask-int (msg def lo hi / v ok)
  (while (not ok)
    (initget 6)
    (setq v (getint (strcat "\n" msg " <" (itoa def) ">: ")))
    (if (null v) (setq v def))
    (if (and (>= v lo) (<= v hi)) (setq ok T) (dbk-say (strcat "  Enter " (itoa lo) " to " (itoa hi) "."))))
  v)
(defun dbk-ask-real (msg def / v)
  (initget 4)
  (setq v (getreal (strcat "\n" msg " <" (dbk-r2 def) ">: ")))
  (if v (float v) def))
(defun dbk-ask-kw (msg kws def / v)
  (initget kws)
  (setq v (getkword (strcat "\n" msg " [" (vl-string-translate " " "/" kws) "] <" def ">: ")))
  (if v v def))
(defun dbk-ask-str (msg def / v)
  (setq v (getstring T (strcat "\n" msg " <" def ">: ")))
  (if (= v "") def v))
(defun dbk-pick (msg / r h e)
  (while (not e)
    (initget "Handle")
    (setq r (entsel (strcat "\n" msg " [Handle]: ")))
    (cond ((= r "Handle")
            (setq h (getstring "\nEntity handle: "))
            (if (not (setq e (handent h))) (dbk-say "  No entity with that handle.")))
          ((null r) (setq e 'CANCEL))
          (T (setq e (car r)))))
  (if (= e 'CANCEL) nil e))

;;; ------------------------------------------------------------------ catalog
(defun dbk-spacer-part (maxsize sep / sizes sz rows)
  (setq sizes (vl-sort (dbk-uniq (mapcar 'cadr *DBK-SNAPNSTAC*)) '<))
  (setq sz (vl-some '(lambda (s) (if (>= s (- maxsize 1e-6)) s)) sizes))
  (if sz
    (progn
      (setq rows (vl-remove-if-not '(lambda (r) (equal (cadr r) sz 1e-6)) *DBK-SNAPNSTAC*))
      (cond ((vl-some '(lambda (r) (if (equal (nth 3 r) sep 1e-6) r)) rows))
            ((vl-some '(lambda (r) (if (equal (nth 3 r) 2.0 1e-6) r)) rows))
            (T (car rows))))))
(defun dbk-elbow-code (deg r / tb)
  (setq tb (cdr (assoc (if (< (abs (- deg 45.0)) 0.5) 45 90) *DBK-ELBOWS*)))
  (cond ((cdr (assoc r tb))) (T (cdr (last tb)))))
(defun dbk-stub-elbow-code (r mat / tb)
  (if (= mat 1)
    (progn (setq tb (cdr (assoc 90 *DBK-ELBOWS-RGS*))) (cond ((cdr (assoc r tb))) (T (cdr (last tb)))))
    (dbk-elbow-code 90.0 r)))
(defun dbk-sql-ok () (and MED-DotNet-Ready (MED-DotNet-Ready) MEDProcessSQLStatement))
(defun dbk-missing-codes ( / res have)
  (if (dbk-sql-ok)
    (progn
      (setq res (vl-catch-all-apply 'MEDProcessSQLStatement
                  (list (strcat "SELECT ITEMCODE FROM MEDType WHERE ITEMTYPE='FITTING' AND ITEMCODE IN ("
                                (substr (apply 'strcat (mapcar '(lambda (c) (strcat "," (itoa c))) *DBK-CODES*)) 2)
                                ")"))))
      ;; MEDProcessSQLStatement returns nil for an empty result (header only when rows exist)
      (if (and (not (vl-catch-all-error-p res)) (listp res))
        (progn
          (foreach row (cdr res)
            (if (and (listp row) (car row))
              (setq have (cons (if (= (type (car row)) 'STR) (atoi (car row)) (fix (car row))) have))))
          (vl-remove-if '(lambda (c) (member c have)) *DBK-CODES*))
        'UNKNOWN))
    'UNKNOWN))

;;; ------------------------------------------------------------------ reference path
;;; Returns (corners2D zTrunk topA topB (type nArcs)) or a string (error).
(defun dbk-ref-geom (ent / ed typ n i pts buls e2 v nar lines corners z topA topB ok a b c out)
  (setq ed (entget ent) typ (cdr (assoc 0 ed)) nar 0)
  (cond
    ((= typ "LINE")
      (setq pts (list (cdr (assoc 10 ed)) (cdr (assoc 11 ed))) buls '(0.0)))
    ((member typ '("LWPOLYLINE" "POLYLINE"))
      (if (vlax-curve-isClosed ent) (setq pts 'CLOSED)
        (progn
          (setq n (fix (+ 0.5 (vlax-curve-getEndParam ent))) i 0)
          (while (<= i n) (setq pts (cons (vlax-curve-getPointAtParam ent (float i)) pts) i (1+ i)))
          (setq pts (reverse pts))
          (cond
            ((= typ "LWPOLYLINE")
              (foreach it ed (if (= (car it) 42) (setq buls (cons (cdr it) buls))))
              (setq buls (reverse buls)))
            (T
              (setq e2 (entnext ent))
              (while (and e2 (= (cdr (assoc 0 (setq v (entget e2)))) "VERTEX"))
                (if (zerop (logand 16 (cdr (assoc 70 v))))
                  (setq buls (cons (if (assoc 42 v) (cdr (assoc 42 v)) 0.0) buls)))
                (setq e2 (entnext e2)))
              (setq buls (reverse buls))))
          (while (< (length buls) (length pts)) (setq buls (append buls '(0.0))))
          (setq buls (reverse (cdr (reverse buls)))))))
    (T (setq pts 'TYPE)))
  (cond
    ((= pts 'CLOSED) "the reference conduit is a closed polyline")
    ((= pts 'TYPE) (strcat "the reference must be a LINE or polyline (got " typ ")"))
    (T
      ;; vertical stub legs at either end
      (while (and (cdr pts) (< (distance (dbk-xy (car pts)) (dbk-xy (cadr pts))) 1e-4)
                  (> (abs (- (caddr (car pts)) (caddr (cadr pts)))) 1e-4))
        (if (not topA) (setq topA (caddr (car pts))))
        (setq pts (cdr pts) buls (cdr buls)))
      (setq pts (reverse pts) buls (reverse buls))
      (while (and (cdr pts) (< (distance (dbk-xy (car pts)) (dbk-xy (cadr pts))) 1e-4)
                  (> (abs (- (caddr (car pts)) (caddr (cadr pts)))) 1e-4))
        (if (not topB) (setq topB (caddr (car pts))))
        (setq pts (cdr pts) buls (cdr buls)))
      (setq pts (reverse pts) buls (reverse buls))
      (setq z (caddr (car pts)) ok T)
      (foreach p pts (if (> (abs (- (caddr p) z)) 0.01) (setq ok nil)))
      (cond
        ((< (length pts) 2) "no horizontal run found on the reference conduit")
        ((not ok) "the horizontal run is not flat (the MVP builds flat trunks only)")
        (T
          ;; straight segments only; fillet arcs are replaced by their tangent intersection
          (setq i 0)
          (while (cdr pts)
            (if (equal (nth i buls) 0.0 1e-9)
              (if (> (distance (dbk-xy (car pts)) (dbk-xy (cadr pts))) 1e-6)
                (setq lines (cons (list (dbk-xy (car pts)) (dbk-xy (cadr pts))) lines)))
              (setq nar (1+ nar)))
            (setq pts (cdr pts) i (1+ i)))
          (setq lines (reverse lines))
          (if (null lines) "the reference has no straight segments"
            (progn
              (setq corners (list (car (car lines))))
              (while (cdr lines)
                (setq a (car lines) b (cadr lines))
                (if (< (distance (cadr a) (car b)) 1e-6)
                  (setq c (cadr a))
                  (setq c (inters (car a) (cadr a) (car b) (cadr b) nil)))
                (if c (setq corners (cons c corners)))
                (setq lines (cdr lines)))
              (setq corners (cons (cadr (car lines)) corners) corners (reverse corners))
              ;; drop duplicates and collinear points
              (setq out (list (car corners)))
              (foreach p (cdr corners) (if (> (distance p (car out)) 1e-6) (setq out (cons p out))))
              (setq out (reverse out) corners (list (car out)))
              (setq i 1)
              (while (< i (1- (length out)))
                (setq a (dbk-unit (dbk-v- (nth i out) (car corners))) b (dbk-unit (dbk-v- (nth (1+ i) out) (nth i out))))
                (if (or (> (abs (dbk-cross2 a b)) 1e-7) (< (dbk-dot a b) 0.0))
                  (setq corners (cons (nth i out) corners)))
                (setq i (1+ i)))
              (setq corners (reverse (cons (last out) corners)))
              (list corners z topA topB (list typ nar)))))))))

;;; ------------------------------------------------------------------ path tables
(defun dbk-segs (pts / segs cum a b d l)
  (setq cum 0.0)
  (while (cdr pts)
    (setq a (car pts) b (cadr pts) d (dbk-v- b a) l (dbk-len d))
    (setq segs (cons (list a b (dbk-unit d) (dbk-rnorm (dbk-unit d)) l cum) segs) cum (+ cum l) pts (cdr pts)))
  (reverse segs))
;; corner: (point dirIn dirOut normIn normOut theta turnSign miterVector); turnSign +1 = left turn
(defun dbk-corners (segs / out sa sb ta tb ea eb th s m)
  (while (cdr segs)
    (setq sa (car segs) sb (cadr segs) ta (nth 2 sa) tb (nth 2 sb) ea (nth 3 sa) eb (nth 3 sb))
    (setq th (dbk-acos (dbk-dot ta tb)) s (if (> (dbk-cross2 ta tb) 0.0) 1.0 -1.0))
    (setq m (dbk-v* (dbk-v+ ea eb) (/ 1.0 (max 1e-9 (+ 1.0 (dbk-dot ea eb))))))
    (setq out (cons (list (nth 1 sa) ta tb ea eb th s m) out) segs (cdr segs)))
  (reverse out))
(defun dbk-pa (s lat / sg)   ; point at station s from end A along the first leg, lateral lat
  (setq sg (car *DBK-SEGS*))
  (dbk-v+ (dbk-v+ (nth 0 sg) (dbk-v* (nth 2 sg) s)) (dbk-v* (nth 3 sg) lat)))
(defun dbk-pb (s lat / sg)   ; point at station s back from end B along the last leg
  (setq sg (last *DBK-SEGS*))
  (dbk-v+ (dbk-v- (nth 1 sg) (dbk-v* (nth 2 sg) s)) (dbk-v* (nth 3 sg) lat)))
(defun dbk-pathpt (s / r)    ; (pt dir normal) at cumulative station s on the reference path
  (foreach g *DBK-SEGS* (if (and (not r) (<= s (+ (nth 5 g) (nth 4 g) 1e-6))) (setq r g)))
  (if (not r) (setq r (last *DBK-SEGS*)))
  (list (dbk-v+ (nth 0 r) (dbk-v* (nth 2 r) (- s (nth 5 r)))) (nth 2 r) (nth 3 r)))

;;; ------------------------------------------------------------------ positions
(defun dbk-posid (r c) (strcat (chr (+ 64 r)) (itoa c)))
(defun dbk-findpos (pl pos)
  (vl-some '(lambda (p) (if (= (strcase (dbk-get p "POS")) (strcase pos)) p)) pl))
(defun dbk-tag (p / tg)
  (if (setq tg (dbk-get p "TAG")) tg
    (dbk-subst-all (dbk-get p "POS") "{POS}" (dbk-subst-all (dbk-get *DBK* "BANK") "{BANK}" _DBKTAGPAT))))
(defun dbk-make-poslist (counts size / r c pl p pos)
  (setq r 1)
  (foreach cnt counts
    (setq c 1)
    (repeat cnt
      (setq pos (dbk-posid r c))
      (setq p (list (cons "POS" pos) (cons "ROW" r) (cons "COL" c) (cons "SIZE" (float size)) (cons "CODE" _DBKCONCODE) (cons "TAG" nil)))
      (setq pl (cons p pl) c (1+ c)))
    (setq r (1+ r)))
  (reverse pl))
(defun dbk-setpos (pos key val / pl)
  (setq pl (mapcar '(lambda (p) (if (or (= pos "*") (= (strcase (dbk-get p "POS")) (strcase pos))) (dbk-put p key val) p))
                   (dbk-get *DBK* "PL")))
  (setq *DBK* (dbk-put *DBK* "PL" pl)))
(defun dbk-replpos (pl p) (mapcar '(lambda (q) (if (= (dbk-get q "POS") (dbk-get p "POS")) p q)) pl))

;;; ------------------------------------------------------------------ solve
;;; Fills *DBKS* (results) and computed keys on each position. Pure geometry, nothing drawn.
;;; Lateral frame: + = right looking from end A along the run. Columns are numbered left to
;;; right looking from the section end (sgn = -1 when that is end B).
(defun dbk-solve ( / pl rows counts sgn sx sy refp tierref maxsize maxod part pitchh pitchv seatbot
                     partsz partod errs flags tier od h red zsref zs lt crn segs n corners k i s
                     col prev r rv rp lst ci th m coff tt tin tout s_in sout gstub griser stuba stubb sza szb
                     topa topb used gap lext rext lsa rsa top bot zone portions a b stations nst
                     sp len gl gr covl covr ang cnt prot pieces strap reds d ench sweep enca encb)
  (setq pl (dbk-get *DBK* "PL") rows (dbk-get *DBK* "ROWS") counts (dbk-get *DBK* "COUNTS")
        sgn (if (= (dbk-get *DBK* "SECTEND") "B") -1.0 1.0)
        sx (dbk-get *DBK* "SX") sy (dbk-get *DBK* "SY")
        stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        topa (dbk-get *DBK* "TOPA") topb (dbk-get *DBK* "TOPB")
        segs *DBK-SEGS* corners *DBK-CORNERS* lt _DBKTRANSL
        covl (if (> sgn 0) _DBKCOVERLEFT _DBKCOVERRIGHT)
        covr (if (> sgn 0) _DBKCOVERRIGHT _DBKCOVERLEFT))
  ;; sizes, ODs, spacer part
  (setq pl (mapcar '(lambda (p) (dbk-put p "OD" (dbk-od (dbk-get p "CODE") (dbk-get p "SIZE")))) pl))
  (setq maxsize (dbk-max (mapcar '(lambda (p) (dbk-get p "SIZE")) pl))
        maxod (dbk-max (mapcar '(lambda (p) (dbk-get p "OD")) pl)))
  (setq part (dbk-spacer-part maxsize _DBKSEP))
  ;; spacer part override (dialog Part / -DUCTBANK Options), else Auto
  (setq k (dbk-get *DBK* "PARTOVR"))
  (if (and (= (type k) 'STR) (/= k "") (/= (strcase k) "AUTO"))
    (cond
      ((null (setq s (assoc (strcase k) *DBK-SNAPNSTAC*)))
        (setq flags (cons (strcat "Spacer part " k " is not in the Snap-N-Stac table: Auto part used.") flags)))
      ((< (nth 1 s) (- maxsize 1e-6))
        (setq errs (cons (strcat "Spacer part " (car s) " (" (dbk-sz (nth 1 s)) ") is smaller than the largest conduit ("
                                 (dbk-sz maxsize) "): pick a larger part or Auto.") errs)))
      (T (if (and part (> (nth 1 s) (+ (nth 1 part) 1e-6)))
           (setq flags (cons (strcat "Spacer part " (car s) " chosen (Auto would be " (car part) ").") flags)))
         (setq part s))))
  (setq k nil s nil)
  (if part
    (setq pitchh (nth 5 part) pitchv (nth 4 part) seatbot (nth 6 part) partsz (nth 1 part) partod (nth 2 part))
    (setq pitchh (+ maxod _DBKMINGAP) pitchv (+ maxod _DBKMINGAP) seatbot _DBKCOVERBOT partsz nil partod nil
          flags (cons (strcat "No Snap-N-Stac spacer for " (dbk-sz maxsize) " conduit: spacing computed from OD + "
                              (dbk-r2 _DBKMINGAP) " gap, no spacer stations.") flags)))
  (setq refp (dbk-findpos pl (dbk-get *DBK* "REFPOS")) tierref (- rows (dbk-get refp "ROW") -1))
  ;; per position: tier, lateral, stagger, seat height
  (setq pl (mapcar
    '(lambda (p / size)
       (setq size (dbk-get p "SIZE") od (dbk-get p "OD") tier (- rows (dbk-get p "ROW") -1) red nil)
       (if (and part (< size (- partsz 1e-6)))
         (if (not (setq red (assoc size *DBK-REDUCERS*)))
           (setq flags (cons (strcat (dbk-get p "POS") " " (dbk-sz size) " sits loose in a " (dbk-sz partsz)
                                     " seat (no Snap-N-Stac reducer for that size).") flags))))
       (setq h (if (and red (= (strcase _DBKREDUCERMODE) "CENTER")) (/ partod 2.0) (/ od 2.0)))
       (setq p (dbk-put p "TIER" tier)
             p (dbk-put p "RELT" (* sgn (- (dbk-get p "COL") (dbk-get refp "COL")) pitchh))
             p (dbk-put p "RELS" (* sgn (- (dbk-get p "COL") (dbk-get refp "COL")) sx))
             p (dbk-put p "ALONG" (* (- tier tierref) sy))
             p (dbk-put p "H" h)
             p (dbk-put p "RED" red)))
    pl))
  (setq refp (dbk-findpos pl (dbk-get *DBK* "REFPOS")))
  ;; the reference conduit is drawn on the centerline of its own position
  (setq zsref (- (dbk-get *DBK* "ZREF") (dbk-get refp "H")))
  (setq pl (mapcar '(lambda (p) (setq zs (+ zsref (* (- (dbk-get p "TIER") tierref) pitchv)))
                      (dbk-put (dbk-put p "ZS" zs) "ZC" (+ zs (dbk-get p "H")))) pl))
  ;; stub-up vertical elbows, per column from the deepest tier up:
  ;; R_upper = max(rule, R_deeper - min(along offset, dz)), rounded up to stock
  (setq col 1)
  (repeat (dbk-max counts)
    (setq lst (vl-sort (vl-remove-if-not '(lambda (p) (= (dbk-get p "COL") col)) pl)
                       '(lambda (a b) (< (dbk-get a "TIER") (dbk-get b "TIER"))))
          prev nil)
    (foreach p lst
      (setq r (dbk-rule (dbk-get p "SIZE")))
      (if prev
        (setq r (max r (- (dbk-get prev "RV") (min (abs (- (dbk-get p "ALONG") (dbk-get prev "ALONG")))
                                                       (- (dbk-get p "ZC") (dbk-get prev "ZC")))))))
      (setq rv (dbk-roundstock r))
      (if (> rv (dbk-rule (dbk-get p "SIZE")))
        (setq flags (cons (strcat (dbk-get p "POS") " stub elbow raised to R" (rtos rv 2 0)
                                  " (nested over the conduit below).") flags)))
      (setq p (dbk-put p "RV" rv) prev p pl (dbk-replpos pl p)))
    (setq col (1+ col)))
  ;; plan bends, per corner and tier, from the outermost conduit inward:
  ;; R = max(rule, R_outer_neighbour - lateral distance), rounded up to stock
  (setq pl (mapcar '(lambda (p) (dbk-put p "RP" nil)) pl) ci 0)
  (foreach c corners
    (setq s (nth 6 c) tier 1)
    (repeat rows
      (setq lst (vl-sort (vl-remove-if-not '(lambda (p) (= (dbk-get p "TIER") tier)) pl)
                         '(lambda (a b) (> (* s (dbk-get a "RELT")) (* s (dbk-get b "RELT")))))
            prev nil)
      (foreach p lst
        (setq r (dbk-rule (dbk-get p "SIZE")))
        (if prev (setq r (max r (- (dbk-get prev "RTMP") (abs (- (dbk-get prev "RELT") (dbk-get p "RELT")))))))
        (setq rp (dbk-roundstock r))
        (if (> rp (dbk-rule (dbk-get p "SIZE")))
          (setq flags (cons (strcat (dbk-get p "POS") " bend " (itoa (1+ ci)) " raised to R" (rtos rp 2 0)
                                    " (nested rule: R outer - R inner <= spacing).") flags)))
        (setq p (dbk-put (dbk-put p "RTMP" rp) "RP" (append (dbk-get p "RP") (list rp))) prev p pl (dbk-replpos pl p)))
      (setq tier (1+ tier)))
    (if (and (> (abs (- (dbk-deg (nth 5 c)) 90.0)) 0.5) (> (abs (- (dbk-deg (nth 5 c)) 45.0)) 0.5))
      (setq flags (cons (strcat "Bend " (itoa (1+ ci)) " is " (dbk-r2 (dbk-deg (nth 5 c)))
                                " deg: no stock elbow code, the 90 deg code is used.") flags)))
    (setq ci (1+ ci)))
  ;; stub zones (station from the end where every stub elbow is done + straight)
  (setq sza (if stuba (+ (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "ALONG") (dbk-get p "RV"))) pl)) _DBKSTUBSTRAIGHT) 0.0)
        szb (if stubb (+ (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "ALONG") (dbk-get p "RV"))) pl)) _DBKSTUBSTRAIGHT) 0.0))
  ;; corner tangent points per position: (TPin TPout bulge stationIn stationOut R theta)
  (setq pl (mapcar
    '(lambda (p / lst2 ci2 lat)
       (setq lat (dbk-get p "RELT") ci2 0 lst2 nil)
       (foreach c corners
         (setq r (nth ci2 (dbk-get p "RP")) th (nth 5 c) m (nth 7 c))
         (setq coff (dbk-v+ (nth 0 c) (dbk-v* m lat)) tt (* r (dbk-tan (/ th 2.0))))
         (setq tin (dbk-v- coff (dbk-v* (nth 1 c) tt)) tout (dbk-v+ coff (dbk-v* (nth 2 c) tt)))
         (setq s_in (dbk-dot (dbk-v- tin (nth 0 (nth ci2 segs))) (nth 2 (nth ci2 segs)))
               sout (dbk-dot (dbk-v- tout (nth 0 (nth (1+ ci2) segs))) (nth 2 (nth (1+ ci2) segs))))
         (setq lst2 (append lst2 (list (list tin tout (* (nth 6 c) (dbk-tan (/ th 4.0))) s_in sout r th))) ci2 (1+ ci2)))
       (dbk-put p "CRN" lst2))
    pl))
  ;; does everything fit on the legs?
  (setq n (length segs))
  (foreach p pl
    (setq crn (dbk-get p "CRN") used (if stuba (+ sza lt) 0.0) k 0)
    (foreach cr crn
      (if (< (nth 3 cr) (- used 1e-6))
        (setq errs (cons (strcat "Leg " (itoa (1+ k)) " is too short (" (dbk-get p "POS") " short by "
                                 (dbk-r2 (- used (nth 3 cr))) "\": bends / transition / stub zone overlap).") errs)))
      (setq used (nth 4 cr) k (1+ k)))
    (if (> (+ used (if stubb (+ szb lt) 0.0)) (+ (nth 4 (last segs)) 1e-6))
      (setq errs (cons (strcat "Leg " (itoa n) " is too short (" (dbk-get p "POS") " short by "
                               (dbk-r2 (- (+ used (if stubb (+ szb lt) 0.0)) (nth 4 (last segs))))
                               "\": bend / transition / stub zone overlap).") errs)))
    (if (and stuba (> (+ (dbk-get p "ZC") (dbk-get p "RV")) (+ topa 1e-6)))
      (setq errs (cons (strcat (dbk-get p "POS") ": R" (rtos (dbk-get p "RV") 2 0)
                               " stub elbow does not fit below the end A stub-up top.") errs)))
    (if (and stubb (> (+ (dbk-get p "ZC") (dbk-get p "RV")) (+ topb 1e-6)))
      (setq errs (cons (strcat (dbk-get p "POS") ": R" (rtos (dbk-get p "RV") 2 0)
                               " stub elbow does not fit below the end B stub-up top.") errs))))
  ;; clear gaps
  (foreach p pl
    (foreach q pl
      (if (and (= (dbk-get p "TIER") (dbk-get q "TIER")) (= (dbk-get q "COL") (1+ (dbk-get p "COL"))))
        (progn
          (setq gap (- (abs (- (dbk-get q "RELT") (dbk-get p "RELT"))) (/ (+ (dbk-get p "OD") (dbk-get q "OD")) 2.0)))
          (if (< gap (- _DBKMINGAP 0.005))
            (setq flags (cons (strcat "Trunk clear gap " (dbk-get p "POS") "-" (dbk-get q "POS") " " (dbk-r2 gap) "\" < " (dbk-r2 _DBKMINGAP) "\".") flags)))
          (setq gap (- (abs (- (dbk-get q "RELS") (dbk-get p "RELS"))) (/ (+ (dbk-get p "OD") (dbk-get q "OD")) 2.0)))
          (if (and (or stuba stubb) (< gap (- _DBKMINGAP 0.005)))
            (setq gstub (cons (list (strcat (dbk-get p "POS") "-" (dbk-get q "POS")) gap) gstub)))))
      (if (and (= (dbk-get p "COL") (dbk-get q "COL")) (= (dbk-get q "TIER") (1+ (dbk-get p "TIER"))))
        (progn
          (setq gap (- (- (dbk-get q "ZC") (dbk-get p "ZC")) (/ (+ (dbk-get p "OD") (dbk-get q "OD")) 2.0)))
          (if (< gap (- _DBKMINGAP 0.005))
            (setq flags (cons (strcat "Vertical clear gap " (dbk-get p "POS") "-" (dbk-get q "POS") " " (dbk-r2 gap) "\".") flags)))
          (setq gap (- (abs (- (dbk-get q "ALONG") (dbk-get p "ALONG"))) (/ (+ (dbk-get p "OD") (dbk-get q "OD")) 2.0)))
          (if (and (or stuba stubb) (< gap (- _DBKMINGAP 0.005)))
            (setq griser (cons (list (strcat (dbk-get p "POS") "-" (dbk-get q "POS")) gap) griser)))))))
  (if gstub
    (setq flags (cons (strcat "Stub-up clear gap across " (dbk-r2 (apply 'min (mapcar 'cadr gstub))) "\" < " (dbk-r2 _DBKMINGAP)
                              "\" at stub pitch " (dbk-r2 sx) " (" (dbk-joinstr (reverse (mapcar 'car gstub)) " ") "). Kept as entered; check the stub-up layout.") flags)))
  (if griser
    (setq flags (cons (strcat "Stub-up clear gap along the run " (dbk-r2 (apply 'min (mapcar 'cadr griser))) "\" < " (dbk-r2 _DBKMINGAP)
                              "\" at row pitch " (dbk-r2 sy) " (" (dbk-joinstr (reverse (mapcar 'car griser)) " ") ").") flags)))
  ;; stub spacing vs trunk spacing, taper
  (setq ang (dbk-max (mapcar '(lambda (p) (dbk-deg (atan (abs (- (dbk-get p "RELS") (dbk-get p "RELT"))) lt))) pl)))
  (if (and (or stuba stubb) (> (abs (- sx pitchh)) 0.005))
    (setq flags (cons (strcat "Stub-up pitch " (dbk-r2 sx) "\" kept at the stub-ups; the trunk uses the spacer pitch "
                              (dbk-r2 pitchh) "\"" (if part (strcat " (" (car part) ")") "")
                              ", tapered over the " (dbk-r2 lt) "\" transition (max " (dbk-r2 ang) " deg).") flags)))
  (if (and (or stuba stubb) (> ang _DBKMAXTAPER))
    (setq flags (cons (strcat "Transition taper " (dbk-r2 ang) " deg exceeds " (dbk-r2 _DBKMAXTAPER) " deg: lengthen the transition.") flags)))
  (if (and part (< seatbot (- _DBKCOVERBOT 0.005)))
    (setq flags (cons (strcat "Spacer seat bottom " (dbk-r2 seatbot) "\" < bottom cover " (dbk-r2 _DBKCOVERBOT) "\": needs a mud slab or chair.") flags)))
  (if (and part (> (abs (- (nth 7 part) (+ seatbot (/ partod 2.0)))) 0.01))
    (setq flags (cons (strcat "Catalog center " (dbk-r2 (nth 7 part)) "\" vs seat bottom + OD/2 = "
                              (dbk-r2 (+ seatbot (/ partod 2.0))) "\": seat rule used (verify with Carlon).") flags)))
  (if (or stuba stubb)
    (if (= (dbk-get *DBK* "STUBCODE") 1)
      (setq flags (cons (if (= (dbk-get *DBK* "WRAP") 1)
                          "Stub-ups are plain RGS: tape wrap noted at each stub-up (BOM code 174)."
                          "Stub-ups are plain RGS, no wrap: verify corrosion protection where it enters the concrete / soil.") flags))))
  (if (/= (dbk-get *DBK* "REFCODE") _DBKCONCODE)
    (setq flags (cons (strcat "Reference conduit is " (dbk-typeabbr (dbk-get *DBK* "REFCODE")) " (code "
                              (itoa (dbk-get *DBK* "REFCODE")) "); bank positions default to encased PVC (code "
                              (itoa _DBKCONCODE) "). Change with Type.") flags)))
  ;; envelope from actual OD + cover (start-based lateral frame)
  (setq lext (- (dbk-min (mapcar '(lambda (p) (- (dbk-get p "RELT") (/ (dbk-get p "OD") 2.0))) pl)) covl)
        rext (+ (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "RELT") (/ (dbk-get p "OD") 2.0))) pl)) covr)
        lsa (- (dbk-min (mapcar '(lambda (p) (- (dbk-get p "RELS") (/ (dbk-get p "OD") 2.0))) pl)) covl)
        rsa (+ (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "RELS") (/ (dbk-get p "OD") 2.0))) pl)) covr)
        top (+ (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "ZC") (/ (dbk-get p "OD") 2.0))) pl)) _DBKCOVERTOP)
        bot (if part (- (+ zsref (* (- 1 tierref) pitchv)) seatbot)
                (- (dbk-min (mapcar '(lambda (p) (- (dbk-get p "ZC") (/ (dbk-get p "OD") 2.0))) pl)) _DBKCOVERBOT)))
  (setq bot (min bot (- (dbk-min (mapcar '(lambda (p) (- (dbk-get p "ZC") (/ (dbk-get p "OD") 2.0))) pl)) _DBKCOVERBOT)))
  (setq gl (car (vl-sort pl '(lambda (a b) (< (- (dbk-get a "RELT") (/ (dbk-get a "OD") 2.0)) (- (dbk-get b "RELT") (/ (dbk-get b "OD") 2.0))))))
        gr (car (vl-sort pl '(lambda (a b) (> (+ (dbk-get a "RELT") (/ (dbk-get a "OD") 2.0)) (+ (dbk-get b "RELT") (/ (dbk-get b "OD") 2.0)))))))
  ;; 2-way pieces per tier, odd column counts (flagged, not trimmed)
  (setq pieces 0 strap 0 reds 0)
  (if part
    (progn
      (setq tier 1)
      (repeat rows
        (setq cnt (length (vl-remove-if-not '(lambda (p) (= (dbk-get p "TIER") tier)) pl)))
        (setq pieces (+ pieces (dbk-ceil (/ cnt 2.0))))
        (if (= tier rows) (setq strap (dbk-ceil (/ cnt 2.0))))
        (if (= 1 (rem cnt 2))
          (progn
            (setq prot (- (+ (* (- (* 2 (dbk-ceil (/ cnt 2.0))) 1) pitchh) (/ pitchh 2.0))
                          (+ (* (1- cnt) pitchh) (/ partod 2.0) (if (> sgn 0) _DBKCOVERRIGHT _DBKCOVERLEFT))))
            (setq flags (cons (strcat "Row " (chr (+ 64 (- rows tier -1))) " has " (itoa cnt)
                                      " conduits on 2-way pieces: one empty seat"
                                      (if (> prot 0.005) (strcat ", piece end " (dbk-r2 prot) "\" past the envelope (flagged, not trimmed).") ".")) flags))))
        (setq tier (1+ tier)))
      (setq reds (length (vl-remove-if-not '(lambda (p) (dbk-get p "RED")) pl)))))
  ;; spacer stations: trunk portions between the transitions and the bend zones
  (setq a (if stuba (+ sza lt) 0.0) portions nil ci 0)
  (foreach c corners
    (setq zone (list (+ (nth 5 (nth ci segs)) (dbk-min (mapcar '(lambda (p) (nth 3 (nth ci (dbk-get p "CRN")))) pl)))
                     (+ (nth 5 (nth (1+ ci) segs)) (dbk-max (mapcar '(lambda (p) (nth 4 (nth ci (dbk-get p "CRN")))) pl)))))
    (setq portions (cons (list a (car zone)) portions) a (cadr zone) ci (1+ ci)))
  (setq len (+ (nth 5 (last segs)) (nth 4 (last segs))))
  (setq portions (reverse (cons (list a (- len (if stubb (+ szb lt) 0.0))) portions)))
  (setq stations nil)
  (if part
    (foreach pr portions
      (setq a (car pr) b (cadr pr) d (- b a))
      (cond
        ((<= d 0.0) nil)
        ((<= d (* 2.0 _DBKSPEND)) (setq stations (cons (/ (+ a b) 2.0) stations)))
        (T
          (setq nst (1+ (dbk-ceil (/ (- d (* 2.0 _DBKSPEND)) _DBKSPINT))) i 0)
          (setq sp (/ (- d (* 2.0 _DBKSPEND)) (1- nst)))
          (repeat nst (setq stations (cons (+ a _DBKSPEND (* i sp)) stations) i (1+ i)))))))
  (setq stations (reverse stations))
  ;; stub-up encasement turn-up: top of concrete at the stub-ups (default = top of the highest
  ;; stub elbow sweep; "Top" = stub-up top EL; or an elevation), never above the stub-up top
  (setq ench (dbk-encval (dbk-get *DBK* "ENCH"))
        sweep (dbk-max (mapcar '(lambda (p) (+ (dbk-get p "ZC") (dbk-get p "RV"))) pl)))
  (defun dbk-enc-end (lbl topx / e)
    (setq e (cond ((= ench "Top") topx) ((numberp ench) ench) (T sweep)))
    (if (> e (+ topx 1e-6))
      (setq flags (cons (strcat "Stub-up encasement EL " (dbk-r2 e) " is above the end " lbl " stub-up top EL " (dbk-r2 topx)
                                ": limited to the stub-up top.") flags)
            e topx))
    (cond
      ((<= e (+ top 0.01))
        (setq flags (cons (strcat "End " lbl ": stub-up encasement EL " (dbk-r2 e) " is not above the trunk top of concrete EL "
                                  (dbk-r2 top) ": no turn-up (stub elbows and risers not encased).") flags))
        nil)
      (T
        (if (< e (- sweep 0.005))
          (setq flags (cons (strcat "End " lbl ": stub-up encasement EL " (dbk-r2 e) " is below the top of the stub elbow sweep EL "
                                    (dbk-r2 sweep) ": the elbow tops are not encased.") flags)))
        e)))
  (setq enca (if stuba (dbk-enc-end "A" topa)) encb (if stubb (dbk-enc-end "B" topb)))
  ;; a new bank must not reuse an existing bank ID (DBEDIT keeps its own)
  (if (and (dbk-get *DBK* "BANK") (/= (strcase (dbk-get *DBK* "BANK")) (strcase (cond (*DBK-EDITING*) (""))))
           (member (strcase (dbk-get *DBK* "BANK")) (dbk-all-banks)))
    (setq errs (cons (strcat "Bank ID " (dbk-get *DBK* "BANK") " is already used in this drawing: enter another ID.") errs)))
  (setq *DBK* (dbk-put *DBK* "PL" pl))
  (setq *DBKS* (list (cons "PART" part) (cons "PITCHH" pitchh) (cons "PITCHV" pitchv) (cons "SEATBOT" seatbot)
                     (cons "PARTSZ" partsz) (cons "PARTOD" partod) (cons "SZA" sza) (cons "SZB" szb)
                     (cons "LEXT" lext) (cons "REXT" rext) (cons "LSA" lsa) (cons "RSA" rsa)
                     (cons "TOP" top) (cons "BOT" bot) (cons "GL" (dbk-get gl "POS")) (cons "GR" (dbk-get gr "POS"))
                     (cons "WT" (- rext lext)) (cons "WS" (- rsa lsa)) (cons "H" (- top bot))
                     (cons "PORTIONS" portions) (cons "STATIONS" stations) (cons "PIECES" pieces)
                     (cons "STRAPS" strap) (cons "REDS" reds) (cons "TAPER" ang) (cons "MAXOD" maxod)
                     (cons "SGN" sgn) (cons "ZSREF" zsref) (cons "TIERREF" tierref) (cons "LEN" len)
                     (cons "SWEEPTOP" sweep) (cons "ENCZA" enca) (cons "ENCZB" encb)
                     (cons "ERRS" (reverse (dbk-uniq errs))) (cons "FLAGS" (reverse (dbk-uniq flags)))))
  *DBKS*)

;;; ------------------------------------------------------------------ text grid ("cheat image")
(defun dbk-pad (s w) (while (< (strlen s) w) (setq s (strcat s " "))) s)
(defun dbk-joinnum (l / s) (setq s "") (foreach x l (setq s (strcat s (rtos x 2 0) " "))) s)
(defun dbk-print-grid ( / pl rows ncol r c p line part)
  (setq pl (dbk-get *DBK* "PL") rows (dbk-get *DBK* "ROWS") ncol (dbk-max (dbk-get *DBK* "COUNTS"))
        part (dbk-get *DBKS* "PART"))
  (dbk-say (strcat "Bank " (dbk-get *DBK* "BANK") ": " (itoa rows) " row(s), looking from end "
                   (dbk-get *DBK* "SECTEND") " along the run (row A = top, column 1 = left), * = reference"))
  (setq line "      " c 1)
  (repeat ncol (setq line (strcat line (dbk-pad (itoa c) 22)) c (1+ c)))
  (dbk-say line)
  (setq r 1)
  (repeat rows
    (setq line (strcat "  " (chr (+ 64 r)) "   ") c 1)
    (repeat ncol
      (setq p (dbk-findpos pl (dbk-posid r c)))
      (setq line (strcat line (dbk-pad (if p (strcat (if (= (dbk-get p "POS") (dbk-get *DBK* "REFPOS")) "*" " ")
                                                       (dbk-tag p) " " (dbk-sz (dbk-get p "SIZE")) " "
                                                       (dbk-typeabbr (dbk-get p "CODE"))
                                                       (if (dbk-get p "RED") (strcat "+" (cadr (dbk-get p "RED"))) ""))
                                             "  -") 22))
            c (1+ c)))
    (dbk-say line)
    (setq r (1+ r)))
  (if part
    (dbk-say (strcat "  Spacer: Carlon Snap-N-Stac " (car part) " (" (dbk-sz (nth 1 part)) ", " (dbk-sz (nth 3 part))
                     " sep, 2-way), trunk pitch " (dbk-r2 (nth 5 part)) " H x " (dbk-r2 (nth 4 part))
                     " V, seat bottom " (dbk-r2 (nth 6 part)) " (catalog CL " (dbk-r2 (nth 7 part)) ")"))
    (dbk-say "  Spacer: none (computed spacing)"))
  (dbk-say (strcat "  Ends: A " (dbk-get *DBK* "ENDA") ", B " (dbk-get *DBK* "ENDB")
                   "   stub-up pitch " (dbk-r2 (dbk-get *DBK* "SX")) " across x " (dbk-r2 (dbk-get *DBK* "SY"))
                   " along   transition " (dbk-r2 _DBKTRANSL) "\" (max taper " (dbk-r2 (dbk-get *DBKS* "TAPER")) " deg)"))
  (dbk-say (strcat "  Envelope: trunk W x H = " (dbk-r2 (dbk-get *DBKS* "WT")) " x " (dbk-r2 (dbk-get *DBKS* "H"))
                   "   stub zone " (dbk-r2 (dbk-get *DBKS* "WS")) " x " (dbk-r2 (dbk-get *DBKS* "H"))
                   "   cover T" (rtos _DBKCOVERTOP 2 1) " B" (rtos _DBKCOVERBOT 2 1) " L" (rtos _DBKCOVERLEFT 2 1)
                   " R" (rtos _DBKCOVERRIGHT 2 1) "   top of concrete EL " (dbk-r2 (dbk-get *DBKS* "TOP"))))
  (dbk-say (strcat "  Elbows: stub-up R" (dbk-joinnum (dbk-uniq (mapcar '(lambda (p) (dbk-get p "RV")) pl)))
                   (if *DBK-CORNERS* (strcat "  plan R" (dbk-joinnum (dbk-uniq (apply 'append (mapcar '(lambda (p) (dbk-get p "RP")) pl))))
                                             "(" (itoa (length *DBK-CORNERS*)) " plan bend(s))") "")))
  (if (or (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
    (dbk-say (strcat "  Stub-up encasement (" (dbk-enclabel (dbk-get *DBK* "ENCH")) "): concrete turn-up to EL"
                     (if (dbk-get *DBKS* "ENCZA") (strcat " " (dbk-r2 (dbk-get *DBKS* "ENCZA")) " at end A") "")
                     (if (dbk-get *DBKS* "ENCZB") (strcat " " (dbk-r2 (dbk-get *DBKS* "ENCZB")) " at end B") "")
                     ", elbow sweep top EL " (dbk-r2 (dbk-get *DBKS* "SWEEPTOP")))))
  (if part (dbk-say (strcat "  Spacer stations: " (itoa (length (dbk-get *DBKS* "STATIONS"))) " (max " (dbk-r2 _DBKSPINT)
                            "\" apart), per station " (itoa (dbk-get *DBKS* "PIECES")) " x " (car part) " + " (itoa (dbk-get *DBKS* "STRAPS"))
                            " x S28612 strap" (if (> (dbk-get *DBKS* "REDS") 0) (strcat " + " (itoa (dbk-get *DBKS* "REDS")) " reducer(s)") ""))))
  (foreach s (dbk-get *DBKS* "FLAGS") (dbk-say (strcat "  FLAG: " s)))
  (foreach s (dbk-get *DBKS* "ERRS") (dbk-say (strcat "  ERROR: " s)))
  (princ))

;;; ------------------------------------------------------------------ entity makers
(defun dbk-doc ( / a)   ; nil in accoreconsole (no ActiveX)
  (setq a (vl-catch-all-apply 'vlax-get-acad-object nil))
  (if (and a (not (vl-catch-all-error-p a))) (vla-get-activedocument a)))
(defun dbk-undo (on / d) (if (setq d (dbk-doc)) (if on (vla-startundomark d) (vla-endundomark d))))
(defun dbk-curvelen (e) (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)))
(defun dbk-layer (name color)
  (if (not (tblsearch "LAYER" name))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                   (cons 2 name) '(70 . 0) (cons 62 color) '(6 . "Continuous"))))
  name)
;; no-ActiveX fallback (accoreconsole): entmake a simple dash/gap linetype read from a .lin file
(defun dbk-ltype-fromfile (name lin / f fh l desc pat els tot)
  (if (setq f (findfile lin))
    (progn
      (setq fh (open f "r"))
      (while (and (setq l (read-line fh)) (not pat))
        (if (wcmatch (strcase l) (strcat "`*" (strcase name) ",*"))
          (setq desc (substr l (+ 3 (strlen name))) pat (read-line fh))))
      (close fh)
      (if (and pat (wcmatch pat "A,*") (not (wcmatch pat "*`[*")))
        (progn
          (setq els (mapcar 'atof (cdr (dbk-csv-split pat))) tot (apply '+ (mapcar 'abs els)))
          (entmake (append (list '(0 . "LTYPE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLinetypeTableRecord")
                                 (cons 2 (strcase name)) '(70 . 0) (cons 3 desc) '(72 . 65) (cons 73 (length els)) (cons 40 tot))
                           (apply 'append (mapcar '(lambda (x) (list (cons 49 x) '(74 . 0))) els)))))))))
(defun dbk-ltype (name)
  (if (and name (not (tblsearch "LTYPE" name)))
    (if (dbk-doc)
      (vl-catch-all-apply '(lambda () (vla-load (vla-get-linetypes (dbk-doc)) name "acad.lin")))
      (dbk-ltype-fromfile name "acad.lin")))
  (if (and name (tblsearch "LTYPE" name)) name))
(defun dbk-mk-lw (layer pts buls elev normal closed xds ltype / ed i)
  (setq ed (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 layer)))
  (if ltype (setq ed (append ed (list (cons 6 ltype)))))
  (setq ed (append ed (list '(100 . "AcDbPolyline") (cons 90 (length pts)) (cons 70 (if closed 1 0)) (cons 38 (float elev)))) i 0)
  (foreach p pts
    (setq ed (append ed (list (list 10 (float (car p)) (float (cadr p))) (cons 42 (float (nth i buls))))) i (1+ i)))
  (setq ed (append ed (list (cons 210 normal))))
  (if xds (setq ed (append ed (list (cons -3 xds)))))
  (if (entmake ed) (entlast)))
(defun dbk-mk-3dp (layer pts xds ltype)
  (entmake (append (list '(0 . "POLYLINE") '(100 . "AcDbEntity") (cons 8 layer))
                   (if ltype (list (cons 6 ltype)))
                   (list '(100 . "AcDb3dPolyline") '(66 . 1) '(10 0.0 0.0 0.0) '(70 . 8))
                   (if xds (list (cons -3 xds)))))
  (foreach p pts
    (entmake (list '(0 . "VERTEX") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbVertex")
                   '(100 . "AcDb3dPolylineVertex") (cons 10 p) '(70 . 32))))
  (entmake (list '(0 . "SEQEND") (cons 8 layer)))
  (entlast))
(defun dbk-mk-text (layer pt h str rot xds)
  (entmake (append (list '(0 . "TEXT") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbText") (cons 10 pt)
                         (cons 40 h) (cons 1 str) (cons 50 rot) '(72 . 1) (cons 11 pt) '(100 . "AcDbText") '(73 . 2))
                   (if xds (list (cons -3 xds)))))
  (entlast))
(defun dbk-mk-ltext (layer pt h str xds)
  (entmake (append (list '(0 . "TEXT") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbText") (cons 10 pt)
                         (cons 40 h) (cons 1 str) '(100 . "AcDbText"))
                   (if xds (list (cons -3 xds)))))
  (entlast))
(defun dbk-mk-circle (layer c r xds)
  (entmake (append (list '(0 . "CIRCLE") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbCircle") (cons 10 c) (cons 40 r))
                   (if xds (list (cons -3 xds)))))
  (entlast))
(defun dbk-mk-line (layer a b xds)
  (entmake (append (list '(0 . "LINE") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbLine") (cons 10 a) (cons 11 b))
                   (if xds (list (cons -3 xds)))))
  (entlast))
(defun dbk-mk-rect (layer x0 y0 x1 y1 z xds)
  (dbk-mk-lw layer (list (list x0 y0) (list x1 y0) (list x1 y1) (list x0 y1)) '(0.0 0.0 0.0 0.0) z '(0.0 0.0 1.0) T xds nil))
(defun dbk-spacer-block ()
  (if (not (tblsearch "BLOCK" "DBSPACER"))
    (progn
      (entmake '((0 . "BLOCK") (2 . "DBSPACER") (70 . 0) (10 0.0 0.0 0.0)))
      (entmake '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (62 . 0) (100 . "AcDbPolyline") (90 . 4) (70 . 1)
                 (10 -0.5 -0.75) (10 0.5 -0.75) (10 0.5 0.75) (10 -0.5 0.75)))
      (entmake '((0 . "LINE") (100 . "AcDbEntity") (8 . "0") (62 . 0) (10 -0.5 0.0 0.0) (11 0.5 0.0 0.0)))
      (entmake '((0 . "ENDBLK")))))
  "DBSPACER")
;; elbow segment in the vertical plane through H and V (true geometry; the plan shows a line of length R)
(defun dbk-mk-varc (layer h v ctr xds ltype / dir nrm ho vo co b)
  (setq dir (dbk-unit (list (- (car h) (car v)) (- (cadr h) (cadr v))))
        nrm (list (cadr dir) (- (car dir)) 0.0))
  (setq ho (trans h 0 nrm) vo (trans v 0 nrm) co (trans ctr 0 nrm))
  (setq b (if (> (dbk-cross2 (dbk-v- (dbk-xy ho) (dbk-xy co)) (dbk-v- (dbk-xy vo) (dbk-xy co))) 0.0)
            (dbk-tan (/ pi 8.0)) (- (dbk-tan (/ pi 8.0)))))
  (dbk-mk-lw layer (list (dbk-xy ho) (dbk-xy vo)) (list b 0.0) (caddr ho) nrm nil xds ltype))

;;; ------------------------------------------------------------------ generate
(defun dbk-add (e) (if e (setq *DBK-HANDLES* (cons (cdr (assoc 5 (entget e))) *DBK-HANDLES*))) e)
(defun dbk-xdpos (role bank p extra)
  (dbk-xd (append (list (strcat "ROLE=" role) (strcat "BANK=" bank) (strcat "POS=" (dbk-get p "POS"))) extra (list "GEN=1"))))
;; plan bend: PVC-coated RGS elbow + 2 PVC female adapters (encased PVC both sides)
(defun dbk-elbow-xd (code sz tag)
  (bld_fitting (list code _DBKADAPTER _DBKADAPTER) (list sz sz sz) (list tag tag tag) '(0.0 0.0 0.0) '(0.0 0.0 0.0) '(0.0 0.0 0.0)))
;; stub-up elbow: elbow (coated or plain RGS) + PVC female adapter (trunk side) + RGS coupling
;; (riser side, coated 173 / plain 8) + tape wrap 174 for a wrapped plain RGS stub-up
(defun dbk-stub-elbow-xd (code sz tag mat wrap / codes)
  (setq codes (list code _DBKADAPTER (cond ((cdr (assoc mat *DBK-COUPLING*))) (T 173))))
  (if (and (= mat 1) wrap) (setq codes (append codes (list *DBK-WRAPCODE*))))
  (bld_fitting codes (mapcar '(lambda (c) sz) codes) (mapcar '(lambda (c) tag) codes)
               (mapcar '(lambda (c) 0.0) codes) (mapcar '(lambda (c) 0.0) codes) (mapcar '(lambda (c) 0.0) codes)))
;; one side of the plan outline (start-based lateral ext), list of (pt2d bulge)
(defun dbk-side (ext exta extb g / out ci dl cr rr stuba stubb sza szb face)
  (setq stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        sza (dbk-get *DBKS* "SZA") szb (dbk-get *DBKS* "SZB")
        face (- (dbk-min (mapcar '(lambda (p) (dbk-get p "ALONG")) (dbk-get *DBK* "PL")))
                (+ (/ (dbk-get *DBKS* "MAXOD") 2.0) _DBKCOVEREND)))
  (if stuba
    (setq out (list (list (dbk-pa face exta) 0.0) (list (dbk-pa sza exta) 0.0) (list (dbk-pa (+ sza _DBKTRANSL) ext) 0.0)))
    (setq out (list (list (dbk-pa 0.0 ext) 0.0))))
  (setq ci 0)
  (foreach c *DBK-CORNERS*
    ;; follow the governing conduit's own elbow, offset by cover (concentric arc)
    (setq cr (nth ci (dbk-get g "CRN")) dl (- ext (dbk-get g "RELT")) rr (+ (nth 5 cr) (* (nth 6 c) dl)))
    (if (> rr 0.01)
      (setq out (append out (list (list (dbk-v+ (nth 0 cr) (dbk-v* (nth 3 c) dl)) (nth 2 cr))
                                  (list (dbk-v+ (nth 1 cr) (dbk-v* (nth 4 c) dl)) 0.0))))
      (setq out (append out (list (list (dbk-v+ (nth 0 c) (dbk-v* (nth 7 c) ext)) 0.0)))))
    (setq ci (1+ ci)))
  (if stubb
    (setq out (append out (list (list (dbk-pb (+ szb _DBKTRANSL) ext) 0.0) (list (dbk-pb szb extb) 0.0) (list (dbk-pb face extb) 0.0))))
    (setq out (append out (list (list (dbk-pb 0.0 ext) 0.0)))))
  out)

(defun dbk-generate (secpt / pl bank conlay lt sgn stuba stubb sza szb segs topa topb p tag sz code od zc rels relt
                       along rv crn cur v e xdc sa ha hv ctr k ent part stations st pp center wdt codes sizes tags a
                       nsta env lsd rsd gl gr q cut x0 y0 sc ins ws vtx bnd clines nconds nelb nfit mat wrap ecode m3d
                       plain encz tupl ntu)
  (setq pl (dbk-get *DBK* "PL") bank (dbk-get *DBK* "BANK") part (dbk-get *DBKS* "PART")
        sgn (dbk-get *DBKS* "SGN") stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        sza (dbk-get *DBKS* "SZA") szb (dbk-get *DBKS* "SZB") segs *DBK-SEGS*
        topa (dbk-get *DBK* "TOPA") topb (dbk-get *DBK* "TOPB")
        conlay (dbk-get *DBK* "REFLAYER") lt (if U_CON (dbk-ltype U_CON)) nconds 0 nelb 0 nfit 0
        *DBK-HANDLES* nil mat (if (= (dbk-get *DBK* "STUBCODE") 1) 1 2)
        wrap (and (= mat 1) (= (dbk-get *DBK* "WRAP") 1)) plain (dbk-get *DBK* "REFPLAIN") ntu 0)
  (foreach ly '(("MED_DBENVELOPE" 8) ("MED_DBSPACER" 4) ("MED_DBSECTION" 7) ("MED_DBSTUB" 6) ("MED_DBTEXT" 2) ("MED_DBREF" 8))
    (dbk-layer (car ly) (cadr ly)))
  (dbk-spacer-block)
  ;; reference -> non-BOM route guide on MED_DBREF (a MED conduit's MED_CONDUIT values move into
  ;; DBANK_DATA; DBDELETE restores them). A plain route keeps no MED data (REFPLAIN=1).
  (setq ent (dbk-get *DBK* "REFENT"))
  (entmod (append (subst (cons 8 "MED_DBREF") (assoc 8 (entget ent)) (entget ent))
                  (list (append (list -3) (if (and (not plain) (tblsearch "APPID" "MED_CONDUIT")) (list (list "MED_CONDUIT")))
                         (list
                              (dbk-xd (list "ROLE=REF" (strcat "BANK=" bank) (strcat "REFTAG=" (dbk-get *DBK* "REFTAG"))
                                            (if plain "REFPLAIN=1") (strcat "REFTYPE=" (cond ((dbk-get *DBK* "REFTYPE")) ("")))
                                            (strcat "REFSIZE=" (dbk-r4 (dbk-get *DBK* "REFSIZE")))
                                            (strcat "REFCODE=" (itoa (dbk-get *DBK* "REFCODE")))
                                            (strcat "REFDIST=" (dbk-r4 (dbk-get *DBK* "REFDIST")))
                                            (strcat "REFMESR=" (dbk-get *DBK* "REFMESR"))
                                            (strcat "REFLAYER=" conlay))))))))
  ;; conduits: straight runs (LWPOLYLINE at the conduit centerline elevation), plan elbows,
  ;; stub-up vertical elbows (true vertical arcs) and risers (3D polylines like the reference)
  (foreach p pl
    (setq tag (dbk-tag p) sz (dbk-get p "SIZE") code (dbk-get p "CODE") od (dbk-get p "OD") zc (dbk-get p "ZC")
          rels (dbk-get p "RELS") relt (dbk-get p "RELT") along (dbk-get p "ALONG") rv (dbk-get p "RV")
          crn (dbk-get p "CRN"))
    (setq xdc (list (strcat "ROW=" (itoa (dbk-get p "ROW"))) (strcat "COL=" (itoa (dbk-get p "COL")))
                    (strcat "TIER=" (itoa (dbk-get p "TIER"))) (strcat "LAT=" (dbk-r4 (* sgn relt)))
                    (strcat "SEATZ=" (dbk-r4 (- (dbk-get p "ZS") (dbk-get *DBKS* "ZSREF"))))))
    (setq v nil)
    (if stuba
      (setq v (list (list (dbk-pa (+ along rv) rels) 0.0 nil) (list (dbk-pa sza rels) 0.0 nil)
                    (list (dbk-pa (+ sza _DBKTRANSL) relt) 0.0 nil)))
      (setq v (list (list (dbk-pa 0.0 relt) 0.0 nil))))
    (foreach cr crn (setq v (append v (list (list (nth 0 cr) (nth 2 cr) cr) (list (nth 1 cr) 0.0 nil)))))
    (if stubb
      (setq v (append v (list (list (dbk-pb (+ szb _DBKTRANSL) relt) 0.0 nil) (list (dbk-pb szb rels) 0.0 nil)
                              (list (dbk-pb (+ along rv) rels) 0.0 nil))))
      (setq v (append v (list (list (dbk-pb 0.0 relt) 0.0 nil)))))
    (setq cur nil k 1)
    (foreach it v
      (if (not (and cur (< (distance (car it) (car (last cur))) 1e-6))) (setq cur (append cur (list it))))
      (if (caddr it)
        (progn
          (dbk-add (dbk-mk-lw conlay (mapcar 'car cur) (mapcar '(lambda (x) 0.0) cur) zc '(0.0 0.0 1.0) nil
                              (list (bld_conduit code sz tag nil "T") (dbk-xdpos "CONDUIT" bank p (append xdc (list (strcat "PART=RUN" (itoa k)))))) lt))
          (setq a (caddr it) nconds (1+ nconds))
          (dbk-add (dbk-mk-lw conlay (list (nth 0 a) (nth 1 a)) (list (nth 2 a) 0.0) zc '(0.0 0.0 1.0) nil
                              (list (dbk-elbow-xd (dbk-elbow-code (dbk-deg (nth 6 a)) (nth 5 a)) sz tag)
                                    (dbk-xdpos "ELBOW" bank p (list (strcat "PART=BEND" (itoa k)) (strcat "RAD=" (rtos (nth 5 a) 2 2))
                                                                    (strcat "ANG=" (rtos (dbk-deg (nth 6 a)) 2 2))
                                                                    (strcat "OD=" (dbk-r4 (dbk-od 2 sz))) "MAT=2"))) lt))
          (setq nelb (1+ nelb) nfit (+ nfit 3) cur (list (list (nth 1 a) 0.0 nil)) k (1+ k)))))
    (dbk-add (dbk-mk-lw conlay (mapcar 'car cur) (mapcar '(lambda (x) 0.0) cur) zc '(0.0 0.0 1.0) nil
                        (list (bld_conduit code sz tag nil "T") (dbk-xdpos "CONDUIT" bank p (append xdc (list (strcat "PART=RUN" (itoa k)))))) lt))
    (setq nconds (1+ nconds))
    (foreach end (list (if stuba "A") (if stubb "B"))
      (if end
        (progn
          (if (= end "A")
            (setq sa (dbk-pa along rels) ha (dbk-pa (+ along rv) rels) q topa)
            (setq sa (dbk-pb along rels) ha (dbk-pb (+ along rv) rels) q topb))
          (setq hv (dbk-p3 sa (+ zc rv)) ctr (dbk-p3 ha (+ zc rv)))
          (setq ecode (dbk-stub-elbow-code rv mat))
          (dbk-add (dbk-mk-varc conlay (dbk-p3 ha zc) hv ctr
                                (list (dbk-stub-elbow-xd ecode sz tag mat wrap)
                                      (dbk-xdpos "ELBOW" bank p (list (strcat "PART=STUB" end) (strcat "RAD=" (rtos rv 2 2)) "ANG=90.00"
                                                                      (strcat "OD=" (dbk-r4 (dbk-od mat sz))) (strcat "MAT=" (itoa mat))
                                                                      (strcat "WRAP=" (if wrap "1" "0"))))) lt))
          (setq nelb (1+ nelb) nfit (+ nfit (if wrap 4 3)))
          (if (> (- q (+ zc rv)) 0.01)
            (progn
              (dbk-add (dbk-mk-3dp conlay (list (dbk-p3 sa q) hv)
                                   (list (bld_conduit mat sz tag nil "T")
                                         (dbk-xdpos "RISER" bank p (list (strcat "PART=RISER" end) (strcat "MAT=" (itoa mat))
                                                                         (strcat "WRAP=" (if wrap "1" "0"))))) lt))
              (setq nconds (1+ nconds))))
          (dbk-add (dbk-mk-circle "MED_DBSTUB" (dbk-p3 sa q) (/ (dbk-od mat sz) 2.0) (list (dbk-xdpos "STUB" bank p (list (strcat "END=" end))))))
          (if wrap
            (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 (dbk-v+ sa (list (* 0.6 (dbk-od mat sz)) (* -0.6 (dbk-od mat sz)))) q)
                                  (min _DBKPLANTEXT (* 0.2 od)) "WRAP" 0.0
                                  (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank) "NOTE=WRAP"))))))
          (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 sa q) (min _DBKPLANTEXT (* 0.3 od)) (dbk-get p "POS") 0.0
                                (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank))))))))))
  ;; stub-up encasement turn-up: plan outline of its top (at the encasement elevation) + note
  (foreach end '("A" "B")
    (if (setq encz (dbk-get *DBKS* (strcat "ENCZ" end)))
      (progn
        (setq tupl (dbk-tu-plan end encz) ntu (1+ ntu))
        (dbk-add (dbk-mk-lw "MED_DBENVELOPE" tupl '(0.0 0.0 0.0 0.0) encz '(0.0 0.0 1.0) T
                            (list (dbk-xd (list "ROLE=TURNUP" (strcat "BANK=" bank) (strcat "END=" end) (strcat "ENCZ=" (dbk-r4 encz)) "GEN=1")))
                            nil))
        (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 (dbk-v* (dbk-v+ (nth 1 tupl) (nth 2 tupl)) 0.5) encz) _DBKPLANTEXT
                              (strcat "CONCRETE TURN-UP TO EL " (dbk-r2 encz))
                              (angle (nth 2 tupl) (nth 1 tupl))
                              (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank) "NOTE=TURNUP"))))))))
  ;; spacer stations: DBSPACER inserts across the trunk envelope carrying one MED_FITTING record per piece
  (setq stations (dbk-get *DBKS* "STATIONS") nsta 0)
  (if part
    (foreach st stations
      (setq pp (dbk-pathpt st) nsta (1+ nsta))
      (setq center (/ (+ (dbk-get *DBKS* "LEXT") (dbk-get *DBKS* "REXT")) 2.0) wdt (dbk-get *DBKS* "WT"))
      (setq codes nil sizes nil tags nil)
      (repeat (dbk-get *DBKS* "PIECES") (setq codes (cons (last part) codes) sizes (cons (nth 1 part) sizes) tags (cons bank tags)))
      (repeat (dbk-get *DBKS* "STRAPS") (setq codes (cons (cadr *DBK-STRAP*) codes) sizes (cons (nth 1 part) sizes) tags (cons bank tags)))
      (foreach p pl (if (dbk-get p "RED") (setq codes (cons (caddr (dbk-get p "RED")) codes) sizes (cons (dbk-get p "SIZE") sizes) tags (cons (dbk-tag p) tags))))
      (setq ins (dbk-v+ (car pp) (dbk-v* (caddr pp) center)))
      (if (entmake (list '(0 . "INSERT") '(100 . "AcDbEntity") '(8 . "MED_DBSPACER") '(100 . "AcDbBlockReference")
                         '(2 . "DBSPACER") (cons 10 (dbk-p3 ins (dbk-get *DBKS* "BOT"))) (cons 41 wdt) '(42 . 1.0) '(43 . 1.0)
                         (cons 50 (angle '(0.0 0.0) (caddr pp)))
                         (list -3 (bld_fitting (reverse codes) (reverse sizes) (reverse tags)
                                               (mapcar '(lambda (x) 0.0) codes) (mapcar '(lambda (x) 0.0) codes) (mapcar '(lambda (x) 0.0) codes))
                               (dbk-xd (list "ROLE=SPACER" (strcat "BANK=" bank) (strcat "STATION=" (itoa nsta))
                                             (strcat "STA=" (dbk-r2 st)) (strcat "PART=" (car part)) "GEN=1")))))
        (dbk-add (entlast)))))
  ;; plan outline: right side forward + left side reversed (bulges negated)
  (setq gl (dbk-findpos pl (dbk-get *DBKS* "GL")) gr (dbk-findpos pl (dbk-get *DBKS* "GR")))
  (setq rsd (dbk-side (dbk-get *DBKS* "REXT") (dbk-get *DBKS* "RSA") (dbk-get *DBKS* "RSA") gr)
        lsd (dbk-side (dbk-get *DBKS* "LEXT") (dbk-get *DBKS* "LSA") (dbk-get *DBKS* "LSA") gl))
  (setq vtx (mapcar 'car rsd) bnd (append (reverse (cdr (reverse (mapcar 'cadr rsd)))) '(0.0)))
  (setq k (1- (length lsd)))
  (while (>= k 0)
    (setq vtx (append vtx (list (car (nth k lsd))))
          bnd (append bnd (list (if (> k 0) (- (cadr (nth (1- k) lsd))) 0.0)))
          k (1- k)))
  ;; section cuts on plan + section drawings beside the plan
  (setq sc _DBKSECTSCALE)
  (if secpt (setq x0 (car secpt) y0 (cadr secpt))
    (setq x0 (+ (dbk-max (mapcar 'car vtx)) 48.0) y0 (dbk-min (mapcar 'cadr vtx))))
  (setq *DBK* (dbk-put *DBK* "SECTPT" (list x0 y0)))
  (setq clines nil)
  (if (or stuba stubb)
    (setq clines (list (list "1" (if (= (dbk-get *DBK* "SECTEND") "B")
                                   (list (dbk-pb (- szb (/ _DBKSTUBSTRAIGHT 2.0)) (- (dbk-get *DBKS* "LSA") 6.0))
                                         (dbk-pb (- szb (/ _DBKSTUBSTRAIGHT 2.0)) (+ (dbk-get *DBKS* "RSA") 6.0)))
                                   (list (dbk-pa (- sza (/ _DBKSTUBSTRAIGHT 2.0)) (- (dbk-get *DBKS* "LSA") 6.0))
                                         (dbk-pa (- sza (/ _DBKSTUBSTRAIGHT 2.0)) (+ (dbk-get *DBKS* "RSA") 6.0))))
                             "STUB"))))
  (setq a (if (= (dbk-get *DBK* "SECTEND") "B") (last (dbk-get *DBKS* "PORTIONS")) (car (dbk-get *DBKS* "PORTIONS"))))
  (setq pp (dbk-pathpt (/ (+ (car a) (cadr a)) 2.0)))
  (setq clines (append clines (list (list (if clines "2" "1")
                                          (list (dbk-v+ (car pp) (dbk-v* (caddr pp) (- (dbk-get *DBKS* "LEXT") 6.0)))
                                                (dbk-v+ (car pp) (dbk-v* (caddr pp) (+ (dbk-get *DBKS* "REXT") 6.0))))
                                          "TRUNK"))))
  (foreach cl clines
    (dbk-add (dbk-mk-line "MED_DBSECTION" (dbk-p3 (car (cadr cl)) (dbk-get *DBKS* "TOP")) (dbk-p3 (cadr (cadr cl)) (dbk-get *DBKS* "TOP"))
                          (list (dbk-xd (list "ROLE=SECTIONCUT" (strcat "BANK=" bank) (strcat "SECTION=" (car cl)))))))
    (foreach pt (cadr cl)
      (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 pt (dbk-get *DBKS* "TOP")) (* 2.0 _DBKPLANTEXT) (car cl) 0.0
                            (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank))))))))
  (foreach cl clines
    (setq ws (dbk-draw-section (list x0 y0) (caddr cl) (car cl) sc bank))
    (foreach e (car ws) (dbk-add e))
    (setq x0 (+ x0 (cadr ws) (* 36.0 sc))))
  ;; plan label beside the first trunk portion
  (setq a (car (dbk-get *DBKS* "PORTIONS")) pp (dbk-pathpt (/ (+ (car a) (cadr a)) 2.0)))
  (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 (dbk-v+ (car pp) (dbk-v* (caddr pp) (- (dbk-get *DBKS* "LEXT") (* 3.0 _DBKPLANTEXT)))) (dbk-get *DBKS* "TOP"))
                        (* 1.5 _DBKPLANTEXT)
                        (strcat "DUCTBANK " bank ": " (itoa (length pl)) " CONDUITS"
                                (if part (strcat ", " (car part) " @ " (rtos (/ _DBKSPINT 12.0) 2 1) "' O.C.") ""))
                        (+ (angle '(0.0 0.0) (cadr pp)) (if (> (cos (angle '(0.0 0.0) (cadr pp))) -0.01) 0.0 pi))
                        (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank))))))
  ;; 3D model (envelope + spacer stations) on <_MED3DMODELPREFIX>Ductbank, before the envelope record
  (setq m3d (if (= (dbk-get *DBK* "MODEL3D") 1) (dbk-model-3d vtx bnd bank)))
  ;; envelope outline last: carries the bank record and every member handle (1005)
  (setq env (dbk-mk-lw "MED_DBENVELOPE" vtx bnd (dbk-get *DBKS* "TOP") '(0.0 0.0 1.0) T
              (list (dbk-xd (append
                (list "ROLE=ENVELOPE" (strcat "BANK=" bank) "GEN=1" (strcat "VER=" *DBK-VERSION*)
                      (strcat "ROWS=" (itoa (dbk-get *DBK* "ROWS")))
                      (strcat "COUNTS=" (substr (apply 'strcat (mapcar '(lambda (c) (strcat "," (itoa c))) (dbk-get *DBK* "COUNTS"))) 2))
                      (strcat "REFPOS=" (dbk-get *DBK* "REFPOS")) (strcat "SECTEND=" (dbk-get *DBK* "SECTEND"))
                      (strcat "ENDA=" (dbk-get *DBK* "ENDA")) (strcat "ENDB=" (dbk-get *DBK* "ENDB"))
                      (strcat "SPACER=" (if part (car part) "NONE")) (strcat "SPINT=" (dbk-r2 _DBKSPINT))
                      "BENDSTYLE=STOCK" (strcat "COVT=" (dbk-r2 _DBKCOVERTOP)) (strcat "COVB=" (dbk-r2 _DBKCOVERBOT))
                      (strcat "COVL=" (dbk-r2 _DBKCOVERLEFT)) (strcat "COVR=" (dbk-r2 _DBKCOVERRIGHT))
                      (strcat "GAP=" (dbk-r2 _DBKMINGAP)) "ENCASE=CONCRETE"
                      (strcat "STUBSX=" (dbk-r2 (dbk-get *DBK* "SX"))) (strcat "STUBSY=" (dbk-r2 (dbk-get *DBK* "SY")))
                      (strcat "TRANSL=" (dbk-r2 _DBKTRANSL))
                      (strcat "WT=" (dbk-r4 (dbk-get *DBKS* "WT"))) (strcat "WS=" (dbk-r4 (dbk-get *DBKS* "WS")))
                      (strcat "HT=" (dbk-r4 (dbk-get *DBKS* "H"))) (strcat "TOPZ=" (dbk-r4 (dbk-get *DBKS* "TOP")))
                      (strcat "BOTZ=" (dbk-r4 (dbk-get *DBKS* "BOT"))) (strcat "STATIONS=" (itoa nsta))
                      (strcat "STUBMAT=" (itoa mat)) (strcat "WRAP=" (if wrap "1" "0"))
                      (strcat "PARTOVR=" (cond ((dbk-get *DBK* "PARTOVR")) ("Auto")))
                      (strcat "MODEL3D=" (if m3d (itoa (+ (car m3d) (cadr m3d))) "0"))
                      (strcat "REFH=" (cdr (assoc 5 (entget ent))))
                      ;; DBEDIT: every setting needed to reopen the dialog and rebuild in place
                      (strcat "COVE=" (dbk-r4 _DBKCOVEREND)) (strcat "SPEND=" (dbk-r4 _DBKSPEND))
                      (strcat "STUBSTR=" (dbk-r4 _DBKSTUBSTRAIGHT)) (strcat "SEP=" (dbk-r4 _DBKSEP))
                      (strcat "SECTSCALE=" (dbk-r4 _DBKSECTSCALE)) (strcat "TAGPAT=" _DBKTAGPAT)
                      (strcat "TOPA=" (dbk-r4 topa)) (strcat "TOPB=" (dbk-r4 topb))
                      (strcat "WRAPSET=" (itoa (dbk-get *DBK* "WRAP"))) (strcat "M3DON=" (itoa (dbk-get *DBK* "MODEL3D")))
                      (strcat "SECTX=" (dbk-r4 (car (dbk-get *DBK* "SECTPT")))) (strcat "SECTY=" (dbk-r4 (cadr (dbk-get *DBK* "SECTPT"))))
                      (strcat "ENCH=" (dbk-encstr (dbk-encval (dbk-get *DBK* "ENCH"))))
                      (strcat "ENCZA=" (if (dbk-get *DBKS* "ENCZA") (dbk-r4 (dbk-get *DBKS* "ENCZA")) ""))
                      (strcat "ENCZB=" (if (dbk-get *DBKS* "ENCZB") (dbk-r4 (dbk-get *DBKS* "ENCZB")) ""))
                      (strcat "SWEEPTOP=" (dbk-r4 (dbk-get *DBKS* "SWEEPTOP")))
                      (strcat "REFPLAIN=" (if plain "1" "0")))
                (mapcar '(lambda (p) (strcat "P=" (dbk-bar (list (dbk-get p "POS") (vl-string-translate "|" "/" (dbk-tag p))
                                                                 (dbk-get p "SIZE") (dbk-get p "CODE") (if (dbk-get p "TAG") "C" "D")))))
                        pl)
                (mapcar '(lambda (h) (cons 1005 h)) (reverse *DBK-HANDLES*)))))
              nil))
  (list env (length *DBK-HANDLES*) nconds nelb nfit nsta m3d ntu))

;;; section drawing at q (bottom-left of the envelope); returns (entities width)
(defun dbk-spx (xv) (+ (car *DBK-SQ*) (* (- xv *DBK-SVL*) *DBK-SSC*)))
(defun dbk-spy (z) (+ (cadr *DBK-SQ*) (* (- z (dbk-get *DBKS* "BOT")) *DBK-SSC*)))
(defun dbk-draw-section (q kind num sc bank / pl sgn lat lft rgt vl vr bot top ents x part ph tier cnt k xa xb zs y0 y1 ttl sub i xds refcol encz ttop)
  (setq pl (dbk-get *DBK* "PL") sgn (dbk-get *DBKS* "SGN") part (dbk-get *DBKS* "PART")
        bot (dbk-get *DBKS* "BOT") top (dbk-get *DBKS* "TOP")
        xds (list (dbk-xd (list "ROLE=SECTION" (strcat "BANK=" bank) (strcat "SECTION=" num)))))
  (if (= kind "STUB")
    (setq lft (dbk-get *DBKS* "LSA") rgt (dbk-get *DBKS* "RSA") lat "RELS")
    (setq lft (dbk-get *DBKS* "LEXT") rgt (dbk-get *DBKS* "REXT") lat "RELT"))
  (setq vl (min (* sgn lft) (* sgn rgt)) vr (max (* sgn lft) (* sgn rgt)))
  (setq *DBK-SQ* q *DBK-SVL* vl *DBK-SSC* sc)
  (setq ents (list (dbk-mk-rect "MED_DBENVELOPE" (dbk-spx vl) (dbk-spy bot) (dbk-spx vr) (dbk-spy top) 0.0 xds)))
  ;; stub section: the encasement turn-up beyond (hidden outline up to its top EL) + note
  (setq ttop top encz (if (= kind "STUB") (dbk-get *DBKS* (strcat "ENCZ" (dbk-get *DBK* "SECTEND")))))
  (if encz
    (progn
      (setq ttop encz)
      (setq ents (cons (dbk-mk-lw "MED_DBENVELOPE" (list (list (dbk-spx vl) (dbk-spy top)) (list (dbk-spx vl) (dbk-spy encz))
                                                         (list (dbk-spx vr) (dbk-spy encz)) (list (dbk-spx vr) (dbk-spy top)))
                                  '(0.0 0.0 0.0 0.0) 0.0 '(0.0 0.0 1.0) nil xds (dbk-ltype "HIDDEN")) ents))
      (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (+ (dbk-spx vl) (* sc 0.5 _DBKSECTTEXT)) (- (dbk-spy encz) (* sc 1.4 _DBKSECTTEXT)) 0.0)
                                     (* sc 0.8 _DBKSECTTEXT) (strcat "CONCRETE TURN-UP BEYOND, TOP EL " (dbk-r2 encz)) xds) ents))))
  ;; spacer pieces (trunk): piece k covers columns 2k+1 and 2k+2; view x = (col - refcol) * pitch
  (if (and part (= kind "TRUNK"))
    (foreach pc (dbk-trunk-pieces)
      (setq ents (cons (dbk-mk-rect "MED_DBSPACER" (dbk-spx (nth 0 pc)) (dbk-spy (nth 2 pc)) (dbk-spx (nth 1 pc)) (dbk-spy (nth 3 pc)) 0.0 xds) ents))))
  ;; conduits at actual OD, position IDs
  (foreach p pl
    (setq x (* sgn (dbk-get p lat)))
    (setq ents (cons (dbk-mk-circle "MED_DBSECTION" (list (dbk-spx x) (dbk-spy (dbk-get p "ZC")) 0.0) (* sc (/ (dbk-get p "OD") 2.0)) xds) ents))
    (setq ents (cons (dbk-mk-text "MED_DBTEXT" (list (dbk-spx x) (dbk-spy (dbk-get p "ZC")) 0.0) (* sc 0.28 (dbk-get p "OD"))
                                  (dbk-get p "POS") 0.0 xds) ents)))
  (setq ttl (strcat "SECTION " num "-" num "  " (if (= kind "STUB") (strcat "STUB-UP ZONE, END " (dbk-get *DBK* "SECTEND"))
                                                     (strcat "TRUNK" (if part (strcat " (" (car part) " @ " (rtos (/ _DBKSPINT 12.0) 2 1) "' O.C.)") "")))))
  (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (dbk-spx vl) (+ (dbk-spy ttop) (* sc 2.2 _DBKSECTTEXT)) 0.0) (* sc 1.4 _DBKSECTTEXT) ttl xds) ents))
  (setq sub (strcat "W x H = " (dbk-r2 (- vr vl)) "\" x " (dbk-r2 (- top bot)) "\"  COVER T" (rtos _DBKCOVERTOP 2 1)
                    " B" (rtos (if (and part (= kind "TRUNK")) (dbk-get *DBKS* "SEATBOT") _DBKCOVERBOT) 2 2)
                    " L" (rtos _DBKCOVERLEFT 2 1) " R" (rtos _DBKCOVERRIGHT 2 1)
                    "  TOP OF CONCRETE EL " (dbk-r2 top) (if encz (strcat " (TURN-UP EL " (dbk-r2 encz) ")") "") "  SCALE " (rtos sc 2 2) ":1"))
  (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (dbk-spx vl) (+ (dbk-spy ttop) (* sc 0.6 _DBKSECTTEXT)) 0.0) (* sc 0.8 _DBKSECTTEXT) sub xds) ents))
  (setq i 1)
  (foreach p (vl-sort pl '(lambda (a b) (< (dbk-get a "POS") (dbk-get b "POS"))))
    (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (dbk-spx vl) (- (dbk-spy bot) (* sc i 1.6 _DBKSECTTEXT)) 0.0) (* sc 0.8 _DBKSECTTEXT)
                                   (strcat (if (= (dbk-get p "POS") (dbk-get *DBK* "REFPOS")) "*" "") (dbk-get p "POS") "  " (dbk-tag p) "  "
                                           (dbk-sz (dbk-get p "SIZE")) " " (dbk-typeabbr (dbk-get p "CODE"))
                                           "  OD " (rtos (dbk-get p "OD") 2 3) "  CL EL " (dbk-r2 (dbk-get p "ZC"))
                                           (if (dbk-get p "RED") (strcat "  " (cadr (dbk-get p "RED")) " " _DBKREDUCERMODE) ""))
                                   xds) ents)
          i (1+ i)))
  (list ents (* sc (- vr vl))))

;;; ------------------------------------------------------------------ 3D model
;;; Spacer pieces in section-view coordinates: list of (xa xb y0 y1); view x = sgn * lateral.
;;; Piece k of a tier covers columns 2k+1, 2k+2 (view x = (col - refcol) * pitch).
(defun dbk-trunk-pieces ( / pl part ph tier cnt k refcol zs xa xb y0 y1 out bot)
  (setq pl (dbk-get *DBK* "PL") part (dbk-get *DBKS* "PART") bot (dbk-get *DBKS* "BOT"))
  (if part
    (progn
      (setq ph (nth 5 part) tier 1 refcol (dbk-get (dbk-findpos pl (dbk-get *DBK* "REFPOS")) "COL"))
      (repeat (dbk-get *DBK* "ROWS")
        (setq cnt (length (vl-remove-if-not '(lambda (p) (= (dbk-get p "TIER") tier)) pl)) k 0)
        (setq zs (dbk-get (car (vl-remove-if-not '(lambda (p) (= (dbk-get p "TIER") tier)) pl)) "ZS"))
        (repeat (dbk-ceil (/ cnt 2.0))
          (setq xa (- (* (- (+ (* 2 k) 1) refcol) ph) (/ ph 2.0)) xb (+ xa (nth 8 part)))
          (setq y0 (if (= tier 1) bot (- zs (nth 3 part))) y1 (+ zs (/ (nth 2 part) 2.0)))
          (setq out (cons (list xa xb y0 y1) out) k (1+ k)))
        (setq tier (1+ tier)))))
  (reverse out))
;; entities created after mark (entlast before the command), main entities only
(defun dbk-ents-after (mark / e out)
  (setq e (if mark (entnext mark) (entnext)))
  (while e
    (if (not (member (cdr (assoc 0 (entget e))) '("VERTEX" "SEQEND" "ATTRIB"))) (setq out (cons e out)))
    (setq e (entnext e)))
  (reverse out))
(defun dbk-ss (ents / ss) (setq ss (ssadd)) (foreach e ents (if (entget e) (ssadd e ss))) ss)
(defun dbk-tag3d (e layer xd / ed)
  (if (and e (setq ed (entget e)))
    (progn
      (setq ed (subst (cons 8 layer) (assoc 8 ed) ed))
      (entmod (append ed (list (list -3 xd))))))
  e)
;; profile in the plane through WCS point o with normal n (3D), from section points (lat z):
;; lateral axis m (2D), so WCS = o + m*lat + Z*z; returns OCS points + elevation
(defun dbk-ocs-pts (o m n pts / w)
  (mapcar '(lambda (q) (setq w (list (+ (car o) (* (car m) (car q))) (+ (cadr o) (* (cadr m) (car q))) (+ (caddr o) (cadr q))))
             (trans w 0 n)) pts))
(defun dbk-extrude (ent h / mark)
  (setq mark (entlast))
  (command "_.EXTRUDE" "_MO" "_SO" ent "" h)
  (car (dbk-ents-after mark)))
;; returns (nEnvelopeSolids nSpacerSolids nTurnups); every solid tagged DBANK_DATA and added to the bank.
;; The stub-up encasement turn-ups are unioned into the envelope solid (one ENV3D solid).
(defun dbk-model-3d (vtx bnd bank / lay oldce oldos olddel oldcmd e env n st pp dir m nrm o th sgn pls pts ocs
                                   pieces cyls sol ss mark ok p lat z r tus envs ntu)
  (setq lay (dbk-model-layer) n 0 th _DBKSPTHICK sgn (dbk-get *DBKS* "SGN"))
  (if (not (tblsearch "LAYER" lay))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                   (cons 2 lay) '(70 . 0) '(62 . 8) '(6 . "Continuous") '(290 . 0))))
  (setq oldce (getvar "CMDECHO") oldos (getvar "OSMODE") olddel (getvar "DELOBJ"))
  (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "DELOBJ" 3)
  ;; concrete envelope: the plan outline (stub zones, tapers and bends included) at the bottom
  ;; of the concrete, extruded up the full height
  (setq e (dbk-mk-lw lay vtx bnd (dbk-get *DBKS* "BOT") '(0.0 0.0 1.0) T nil nil))
  (if e (setq env (dbk-extrude e (dbk-get *DBKS* "H"))))
  (if (not (and env (entget env) (= (cdr (assoc 0 (entget env))) "3DSOLID")))
    (progn (setq env nil) (if (and e (entget e)) (entdel e))
           (dbk-say "  3D envelope could not be extruded (outline left in 2D only).")))
  ;; stub-up encasement turn-ups, unioned with the envelope
  (setq tus nil ntu 0)
  (foreach end '("A" "B")
    (if (setq z (dbk-get *DBKS* (strcat "ENCZ" end)))
      (if (setq sol (dbk-tu-solid end z lay)) (setq tus (cons sol tus) ntu (1+ ntu))
        (dbk-say (strcat "  3D stub-up encasement at end " end " could not be modelled.")))))
  (setq envs (vl-remove 'nil (cons env tus)))
  (if (cdr envs) (command "_.UNION" (dbk-ss envs) ""))
  (setq envs (vl-remove-if-not '(lambda (x) (and x (entget x))) envs))
  (foreach x envs
    (dbk-add (dbk-tag3d x lay (dbk-xd (list "ROLE=ENV3D" (strcat "BANK=" bank) "GEN=1"
                                            (strcat "HT=" (dbk-r4 (dbk-get *DBKS* "H")))
                                            (strcat "TURNUPS=" (itoa ntu))
                                            (if (dbk-get *DBKS* "ENCZA") (strcat "ENCZA=" (dbk-r4 (dbk-get *DBKS* "ENCZA"))))
                                            (if (dbk-get *DBKS* "ENCZB") (strcat "ENCZB=" (dbk-r4 (dbk-get *DBKS* "ENCZB")))))))))
  ;; spacer stations: pieces (rectangles in the section plane) extruded by the spacer thickness,
  ;; unioned, minus a cylinder per conduit seat
  (if (dbk-get *DBKS* "PART")
    (foreach st (dbk-get *DBKS* "STATIONS")
      (setq pp (dbk-pathpt st) dir (list (car (cadr pp)) (cadr (cadr pp)) 0.0) m (caddr pp)
            o (list (- (car (car pp)) (* (car dir) (/ th 2.0))) (- (cadr (car pp)) (* (cadr dir) (/ th 2.0))) 0.0)
            pieces nil cyls nil)
      (foreach pc (dbk-trunk-pieces)
        (setq pts (dbk-ocs-pts o m dir (list (list (* sgn (nth 0 pc)) (nth 2 pc)) (list (* sgn (nth 1 pc)) (nth 2 pc))
                                             (list (* sgn (nth 1 pc)) (nth 3 pc)) (list (* sgn (nth 0 pc)) (nth 3 pc)))))
        (if (setq e (dbk-mk-lw lay pts '(0.0 0.0 0.0 0.0) (caddr (car pts)) dir T nil nil))
          (if (and (setq sol (dbk-extrude e th)) (= (cdr (assoc 0 (entget sol))) "3DSOLID"))
            (setq pieces (cons sol pieces)))))
      (foreach p (dbk-get *DBK* "PL")
        ;; seat cylinder a little longer than the spacer so the subtraction has no coplanar faces
        (setq ocs (car (dbk-ocs-pts (mapcar '(lambda (a b) (- a (* 0.1 b))) o dir) m dir
                                    (list (list (dbk-get p "RELT") (dbk-get p "ZC"))))))
        (if (and (entmake (list '(0 . "CIRCLE") (cons 8 lay) (cons 10 ocs) (cons 40 (/ (dbk-get p "OD") 2.0)) (cons 210 dir)))
                 (setq sol (dbk-extrude (entlast) (+ th 0.2))) (= (cdr (assoc 0 (entget sol))) "3DSOLID"))
          (setq cyls (cons sol cyls))))
      (if pieces
        (progn
          (if (cdr pieces) (progn (setq mark (entlast)) (command "_.UNION" (dbk-ss pieces) "")
                                  (setq pieces (vl-remove-if-not 'entget pieces))))
          (if cyls (command "_.SUBTRACT" (dbk-ss pieces) "" (dbk-ss cyls) ""))
          (foreach c cyls (if (entget c) (entdel c)))
          (foreach sol (vl-remove-if-not 'entget pieces)
            (dbk-add (dbk-tag3d sol lay (dbk-xd (list "ROLE=SPACER3D" (strcat "BANK=" bank) "GEN=1"
                                                      (strcat "STA=" (dbk-r2 st)) (strcat "PART=" (car (dbk-get *DBKS* "PART")))))))
            (setq n (1+ n)))))))
  (setvar "DELOBJ" olddel) (setvar "OSMODE" oldos) (setvar "CMDECHO" oldce)
  (list (length envs) n ntu))

;;; ------------------------------------------------------------------ stub-up encasement turn-up
;;; The concrete turns up at each stub-up end and wraps the stub elbows and risers. Profile in
;;; the vertical plane along the first (end A) / last (end B) leg, stations s measured from that
;;; end: front face = the envelope end face (s = face), back edge = the inner side of the
;;; stub elbows (offset by OD/2 + end cover toward the elbow center) and the riser backs above
;;; the sweep. Width = the stub zone envelope (lateral LSA..RSA, side covers included).
(defun dbk-tu-face ()
  (- (dbk-min (mapcar '(lambda (p) (dbk-get p "ALONG")) (dbk-get *DBK* "PL")))
     (+ (/ (dbk-get *DBKS* "MAXOD") 2.0) _DBKCOVEREND)))
;; back edge station at elevation z (max over every position)
(defun dbk-tu-back (z / out cx cz rr s)
  (foreach p (dbk-get *DBK* "PL")
    (setq cx (+ (dbk-get p "ALONG") (dbk-get p "RV")) cz (+ (dbk-get p "ZC") (dbk-get p "RV"))
          rr (- (dbk-get p "RV") (/ (dbk-get p "OD") 2.0) _DBKCOVEREND))
    (setq s (cond ((>= z cz) (+ (dbk-get p "ALONG") (/ (dbk-get p "OD") 2.0) _DBKCOVEREND))
                  ((and (> rr 0.01) (>= z (- cz rr))) (- cx (sqrt (max 0.0 (- (* rr rr) (* (- cz z) (- cz z)))))))
                  (T cx)))
    (if (or (null out) (> s out)) (setq out s)))
  out)
;; closed profile ((s z) ...) from just below the trunk top of concrete up to encz
(defun dbk-tu-profile (encz / face zb zs z k pts n)
  (setq face (dbk-tu-face) zb (- (dbk-get *DBKS* "TOP") (min 1.0 (* 0.5 (dbk-get *DBKS* "H")))) n 24)
  (setq zs (list encz zb) k 1)
  (repeat (1- n) (setq zs (cons (+ zb (* (- encz zb) (/ (float k) n))) zs) k (1+ k)))
  (foreach p (dbk-get *DBK* "PL")
    (foreach z (list (+ (dbk-get p "ZC") (dbk-get p "RV"))
                     (+ (dbk-get p "ZC") (/ (dbk-get p "OD") 2.0) _DBKCOVEREND))
      (if (and (< z encz) (> z zb)) (setq zs (cons z zs)))))
  (setq zs (vl-sort (dbk-uniq (mapcar '(lambda (z) (atof (rtos z 2 6))) zs)) '>))
  (setq pts (list (list face zb) (list face encz)))
  (foreach z zs (setq pts (append pts (list (list (dbk-tu-back z) z)))))
  ;; drop repeated points
  (setq k nil)
  (foreach q pts (if (not (and k (< (distance q (car k)) 1e-6))) (setq k (cons q k))))
  (if (< (distance (car k) (last k)) 1e-6) (setq k (cdr k)))
  (reverse k))
;; end frame: (origin2D alongDir2D lateralNormal2D) so WCS = o + along*s + normal*lat
(defun dbk-tu-frame (end / sg)
  (if (= end "A")
    (progn (setq sg (car *DBK-SEGS*)) (list (nth 0 sg) (nth 2 sg) (nth 3 sg)))
    (progn (setq sg (last *DBK-SEGS*)) (list (nth 1 sg) (dbk-v* (nth 2 sg) -1.0) (nth 3 sg)))))
;; plan footprint of the turn-up top: 4 points (2D) at the given end
(defun dbk-tu-plan (end encz / fr face back lsa rsa)
  (setq fr (dbk-tu-frame end) face (dbk-tu-face) back (dbk-tu-back encz)
        lsa (dbk-get *DBKS* "LSA") rsa (dbk-get *DBKS* "RSA"))
  (mapcar '(lambda (sl) (dbk-v+ (dbk-v+ (car fr) (dbk-v* (cadr fr) (car sl))) (dbk-v* (caddr fr) (cadr sl))))
          (list (list face lsa) (list back lsa) (list back rsa) (list face rsa))))
;; 3D solid of the turn-up at one end (profile at lateral LSA extruded across to RSA)
(defun dbk-tu-solid (end encz lay / fr o m n pts ocs e sol)
  (setq fr (dbk-tu-frame end)
        o (dbk-v+ (car fr) (dbk-v* (caddr fr) (dbk-get *DBKS* "LSA")))
        o (list (car o) (cadr o) 0.0)
        m (cadr fr) n (list (car (caddr fr)) (cadr (caddr fr)) 0.0))
  (setq ocs (dbk-ocs-pts o m n (dbk-tu-profile encz)))
  (if (setq e (dbk-mk-lw lay ocs (mapcar '(lambda (q) 0.0) ocs) (caddr (car ocs)) n T nil nil))
    (if (and (setq sol (dbk-extrude e (- (dbk-get *DBKS* "RSA") (dbk-get *DBKS* "LSA"))))
             (= (cdr (assoc 0 (entget sol))) "3DSOLID"))
      sol
      (progn (if (entget e) (entdel e)) nil))))

;;; ------------------------------------------------------------------ dialog bridge
;;; DUCTBANK <-> MED-DuctbankDialog (MED-DotNet, MedDuctbankForm): one text block of KEY=VALUE
;;; lines each way. Lists use | between fields. The form never touches the drawing; LISP
;;; solves, the form shows inputs, lookups and the last solve, and returns the edited inputs
;;; with ACTION=OK / CHECK / CANCEL.
(defun dbk-kv (k v) (strcat k "=" (cond ((= (type v) 'STR) v) ((= (type v) 'INT) (itoa v)) ((numberp v) (dbk-r4 v)) ((null v) "") (T (vl-princ-to-string v)))))
(defun dbk-bar (l) (dbk-joinstr (mapcar '(lambda (x) (cond ((= (type x) 'STR) x) ((= (type x) 'INT) (itoa x)) ((numberp x) (dbk-r4 x)) (T ""))) l) "|"))
(defun dbk-split (s d / out i)
  (while (setq i (vl-string-search d s)) (setq out (cons (substr s 1 i) out) s (substr s (+ i 1 (strlen d)))))
  (reverse (cons s out)))
(defun dbk-dlg-codes ( / res out)
  (if (dbk-sql-ok)
    (progn
      (setq res (vl-catch-all-apply 'MEDProcessSQLStatement (list "SELECT ITEMCODE, ITEMDESC FROM MEDType WHERE ITEMTYPE='CONDUIT' ORDER BY ITEMCODE")))
      (if (and (listp res) (not (vl-catch-all-error-p res)))
        (foreach r (cdr res)
          (if (and (listp r) (car r))
            (setq out (cons (list (if (= (type (car r)) 'STR) (atoi (car r)) (fix (car r))) (vl-princ-to-string (cadr r))) out)))))))
  (if (not out)
    (setq out (reverse '((1 "Rigid Steel Conduit") (2 "Plastic Coated Rigid Steel Conduit") (3 "Rigid Non-Metalic Conduit")
                         (4 "Electrical Metalic Tubing") (6 "Intermediate Metal Conduit")))))
  (reverse out))
(defun dbk-dlg-sizes ( / l)
  (setq l (if _CONSIZE_LIST _CONSIZE_LIST '(0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0)))
  (vl-sort (vl-remove-if '(lambda (s) (< s (- _DBKMINSIZE 1e-6))) (mapcar 'float l)) '<))
(defun dbk-summary-lines ( / part out rvs)
  (setq part (dbk-get *DBKS* "PART") rvs (mapcar '(lambda (p) (dbk-get p "RV")) (dbk-get *DBK* "PL")))
  (setq out (list (strcat "Trunk W x H: " (dbk-r2 (dbk-get *DBKS* "WT")) " x " (dbk-r2 (dbk-get *DBKS* "H")) " in")
                  (strcat "Top of concrete EL " (dbk-r2 (dbk-get *DBKS* "TOP")) ", bottom EL " (dbk-r2 (dbk-get *DBKS* "BOT")))))
  (if (or (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup"))
    (setq out (append out (list (strcat "Stub zone W: " (dbk-r2 (dbk-get *DBKS* "WS")) " in, transition " (dbk-r2 _DBKTRANSL)
                                        " in (taper " (rtos (dbk-get *DBKS* "TAPER") 2 1) " deg)")
                                (strcat "Stub elbows R" (rtos (dbk-min rvs) 2 0) (if (> (dbk-max rvs) (dbk-min rvs)) (strcat "-R" (rtos (dbk-max rvs) 2 0)) "")
                                        ", " (if (= (dbk-get *DBK* "STUBCODE") 1)
                                               (strcat "plain RGS" (if (= (dbk-get *DBK* "WRAP") 1) " (wrapped)" "")) "PVC-coated RGS"))
                                (strcat "Turn-up (" (dbk-encstr (dbk-get *DBK* "ENCH")) "): "
                                        (if (or (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
                                          (strcat "EL " (dbk-joinstr (vl-remove 'nil (list (if (dbk-get *DBKS* "ENCZA") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZA")) " A"))
                                                                                              (if (dbk-get *DBKS* "ENCZB") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZB")) " B")))) ", ")
                                                  ", sweep top EL " (dbk-r2 (dbk-get *DBKS* "SWEEPTOP")))
                                          "none"))))))
  (setq out (append out (list (if part (strcat "Spacer " (car part) ": " (itoa (length (dbk-get *DBKS* "STATIONS"))) " stations x "
                                               (itoa (dbk-get *DBKS* "PIECES")) " pieces, pitch " (dbk-r2 (nth 5 part)) " x " (dbk-r2 (nth 4 part)))
                                "Spacer: none (no Snap-N-Stac part for this size)")
                              (strcat "Bank length along the route: " (rtos (/ (dbk-get *DBKS* "LEN") 12.0) 2 1) " ft"))))
  out)
(defun dbk-spec-out ( / out pl sgn bot sizes codes part ref)
  (setq pl (dbk-get *DBK* "PL") sgn (dbk-get *DBKS* "SGN") bot (dbk-get *DBKS* "BOT") part (dbk-get *DBKS* "PART")
        sizes (dbk-dlg-sizes) codes (dbk-dlg-codes) ref (dbk-get *DBK* "REFENT"))
  (setq out (list (dbk-kv "VER" *DBK-VERSION*)
                  (strcat "REF=" (dbk-bar (list (dbk-get *DBK* "REFTAG") (dbk-get *DBK* "REFSIZE") (dbk-get *DBK* "REFCODE")
                                                (cdr (assoc 5 (entget ref))) (dbk-get *DBK* "REFLAYER") (length *DBK-SEGS*) (length *DBK-CORNERS*)
                                                (dbk-get *DBK* "ZREF"))))
                  (dbk-kv "BANK" (dbk-get *DBK* "BANK")) (dbk-kv "ROWS" (dbk-get *DBK* "ROWS"))
                  (dbk-kv "COUNTS" (dbk-joinstr (mapcar 'itoa (dbk-get *DBK* "COUNTS")) ","))
                  (dbk-kv "REFPOS" (dbk-get *DBK* "REFPOS"))
                  (dbk-kv "ENDA" (dbk-get *DBK* "ENDA")) (dbk-kv "ENDB" (dbk-get *DBK* "ENDB"))
                  (dbk-kv "TOPA" (dbk-get *DBK* "TOPA")) (dbk-kv "TOPB" (dbk-get *DBK* "TOPB"))
                  (dbk-kv "SX" (dbk-get *DBK* "SX")) (dbk-kv "SY" (dbk-get *DBK* "SY")) (dbk-kv "SECTEND" (dbk-get *DBK* "SECTEND"))
                  (dbk-kv "FAMILY" "Carlon Snap-N-Stac") (dbk-kv "SEP" _DBKSEP) (dbk-kv "PART" (cond ((dbk-get *DBK* "PARTOVR")) ("Auto")))
                  (dbk-kv "COVT" _DBKCOVERTOP) (dbk-kv "COVB" _DBKCOVERBOT) (dbk-kv "COVL" _DBKCOVERLEFT) (dbk-kv "COVR" _DBKCOVERRIGHT)
                  (dbk-kv "COVE" _DBKCOVEREND) (dbk-kv "MINGAP" _DBKMINGAP) (dbk-kv "SPINT" _DBKSPINT) (dbk-kv "SPEND" _DBKSPEND)
                  (dbk-kv "TRANSL" _DBKTRANSL) (dbk-kv "STUBSTR" _DBKSTUBSTRAIGHT) (dbk-kv "SECTSCALE" _DBKSECTSCALE)
                  (dbk-kv "STUBCODE" (dbk-get *DBK* "STUBCODE")) (dbk-kv "WRAP" (dbk-get *DBK* "WRAP"))
                  (dbk-kv "MODEL3D" (dbk-get *DBK* "MODEL3D")) (dbk-kv "SECTPICK" (dbk-get *DBK* "SECTPICK"))
                  (dbk-kv "MODELLAYER" (dbk-model-layer)) (dbk-kv "TAGPAT" _DBKTAGPAT)
                  (dbk-kv "MINSIZE" _DBKMINSIZE) (dbk-kv "CONCODE" _DBKCONCODE)
                  (dbk-kv "SIZES" (dbk-joinstr (mapcar 'dbk-r4 sizes) ","))
                  (dbk-kv "MODE" (if *DBK-EDITING* "EDIT" "NEW"))
                  (dbk-kv "REFPLAIN" (if (dbk-get *DBK* "REFPLAIN") 1 0)) (dbk-kv "REFTYPE" (cond ((dbk-get *DBK* "REFTYPE")) ("")))
                  (dbk-kv "REFSIZE" (dbk-get *DBK* "REFSIZE")) (dbk-kv "REFCODE" (dbk-get *DBK* "REFCODE"))
                  (dbk-kv "ENCH" (dbk-encstr (dbk-get *DBK* "ENCH")))
                  (dbk-kv "BOTZ" bot) (dbk-kv "TOPZ" (dbk-get *DBKS* "TOP")) (dbk-kv "SWEEPTOPZ" (dbk-get *DBKS* "SWEEPTOP"))
                  (dbk-kv "ENCZA" (dbk-get *DBKS* "ENCZA")) (dbk-kv "ENCZB" (dbk-get *DBKS* "ENCZB"))))
  (foreach c codes (setq out (append out (list (strcat "CODE=" (dbk-bar (list (car c) (dbk-typeabbr (car c)) (cadr c))))))))
  (foreach r *DBK-SNAPNSTAC* (setq out (append out (list (strcat "CAT=" (dbk-bar r))))))
  ;; OD table for the preview (codes in use + 1/2/3)
  (foreach c (dbk-uniq (append '(3 2 1) (mapcar '(lambda (p) (dbk-get p "CODE")) pl)))
    (foreach s sizes (setq out (append out (list (strcat "OD=" (dbk-bar (list c s (dbk-od c s)))))))))
  (foreach p pl
    (setq out (append out (list (strcat "POS=" (dbk-bar (list (dbk-get p "POS") (dbk-tag p) (dbk-get p "SIZE") (dbk-get p "CODE")
                                                         (if (dbk-get p "TAG") "C" "D"))))))))
  ;; last solve
  (setq out (append out (list (dbk-kv "SOLVEDPART" (if part (car part) "NONE")) (dbk-kv "PITCHH" (dbk-get *DBKS* "PITCHH"))
                              (dbk-kv "PITCHV" (dbk-get *DBKS* "PITCHV")) (dbk-kv "SEATBOT" (dbk-get *DBKS* "SEATBOT"))
                              (strcat "ENVT=" (dbk-bar (list (min (* sgn (dbk-get *DBKS* "LEXT")) (* sgn (dbk-get *DBKS* "REXT")))
                                                             (max (* sgn (dbk-get *DBKS* "LEXT")) (* sgn (dbk-get *DBKS* "REXT")))
                                                             0.0 (dbk-get *DBKS* "H"))))
                              (strcat "ENVS=" (dbk-bar (list (min (* sgn (dbk-get *DBKS* "LSA")) (* sgn (dbk-get *DBKS* "RSA")))
                                                             (max (* sgn (dbk-get *DBKS* "LSA")) (* sgn (dbk-get *DBKS* "RSA")))))))))
  (foreach p pl
    (setq out (append out (list (strcat "PZ=" (dbk-bar (list (dbk-get p "POS") (* sgn (dbk-get p "RELT")) (* sgn (dbk-get p "RELS"))
                                                        (- (dbk-get p "ZC") bot) (dbk-get p "OD") (dbk-get p "RV"))))))))
  (foreach pc (dbk-trunk-pieces)
    (setq out (append out (list (strcat "PIECE=" (dbk-bar (list (nth 0 pc) (nth 1 pc) (- (nth 2 pc) bot) (- (nth 3 pc) bot))))))))
  (foreach s (dbk-summary-lines) (setq out (append out (list (strcat "SUM=" s)))))
  (foreach s (dbk-get *DBKS* "ERRS") (setq out (append out (list (strcat "ERR=" s)))))
  (foreach s (dbk-get *DBKS* "FLAGS") (setq out (append out (list (strcat "FLAG=" s)))))
  (dbk-joinstr out "\n"))

;; apply the dialog result; returns "OK", "CHECK" or "CANCEL"
(defun dbk-spec-in (txt / kv act k v rows counts poss f p)
  (foreach ln (dbk-split txt "\n")
    (setq ln (vl-string-trim "\r " ln))
    (if (setq k (vl-string-search "=" ln))
      (progn (setq v (substr ln (+ k 2)) k (strcase (substr ln 1 k)))
             (if (= k "POS") (setq poss (cons v poss)) (setq kv (cons (cons k v) kv))))))
  (setq act (strcase (cond ((cdr (assoc "ACTION" kv))) ("CANCEL"))))
  (if (/= act "CANCEL")
    (progn
      (defun dbk-kvn (k d / v) (if (and (setq v (cdr (assoc k kv))) (/= v "")) (atof v) d))
      (defun dbk-kvs (k d / v) (if (and (setq v (cdr (assoc k kv))) (/= v "")) v d))
      (if (not *DBK-EDITING*)   ; DBEDIT keeps the bank ID
        (setq *DBK* (dbk-put *DBK* "BANK" (strcase (dbk-kvs "BANK" (dbk-get *DBK* "BANK"))))))
      (if (dbk-get *DBK* "REFPLAIN")   ; plain route: the reference size / type come from the dialog
        (progn (setq v (dbk-kvn "REFSIZE" (dbk-get *DBK* "REFSIZE")) k (fix (dbk-kvn "REFCODE" (dbk-get *DBK* "REFCODE"))))
               (if (and (> v 0.0) (> k 0) (or (not (equal v (dbk-get *DBK* "REFSIZE") 1e-6)) (/= k (dbk-get *DBK* "REFCODE"))))
                 (dbk-set-refsize v k))))
      (setq *DBK* (dbk-put *DBK* "ENCH" (dbk-encval (dbk-kvs "ENCH" (dbk-encstr (dbk-get *DBK* "ENCH"))))))
      (setq rows (fix (dbk-kvn "ROWS" (dbk-get *DBK* "ROWS")))
            counts (mapcar 'atoi (dbk-split (dbk-kvs "COUNTS" (dbk-joinstr (mapcar 'itoa (dbk-get *DBK* "COUNTS")) ",")) ",")))
      (setq rows (max 1 (min 9 rows)) counts (mapcar '(lambda (c) (max 1 (min 12 c))) counts))
      (while (< (length counts) rows) (setq counts (append counts (list (last counts)))))
      (while (> (length counts) rows) (setq counts (reverse (cdr (reverse counts)))))
      (if (or (/= rows (dbk-get *DBK* "ROWS")) (not (equal counts (dbk-get *DBK* "COUNTS")))) (dbk-reshape rows counts))
      (foreach s (reverse poss)
        (setq f (dbk-split s "|"))
        (if (setq p (dbk-findpos (dbk-get *DBK* "PL") (car f)))
          (progn
            (if (and (nth 2 f) (> (atof (nth 2 f)) 0.0)) (dbk-setpos (car f) "SIZE" (atof (nth 2 f))))
            (if (and (nth 3 f) (> (atoi (nth 3 f)) 0)) (dbk-setpos (car f) "CODE" (atoi (nth 3 f))))
            (dbk-setpos (car f) "TAG" (if (and (= (nth 4 f) "C") (/= (nth 1 f) "")) (nth 1 f) nil)))))
      (setq v (strcase (dbk-kvs "REFPOS" (dbk-get *DBK* "REFPOS"))))
      (if (dbk-findpos (dbk-get *DBK* "PL") v) (setq *DBK* (dbk-put *DBK* "REFPOS" v)))
      (foreach k '("ENDA" "ENDB") (setq *DBK* (dbk-put *DBK* k (if (= (strcase (dbk-kvs k (dbk-get *DBK* k))) "STUBUP") "Stubup" "Open"))))
      (foreach k '("TOPA" "TOPB" "SX" "SY") (setq *DBK* (dbk-put *DBK* k (dbk-kvn k (dbk-get *DBK* k)))))
      (setq *DBK* (dbk-put *DBK* "SECTEND" (if (= (strcase (dbk-kvs "SECTEND" "A")) "B") "B" "A")))
      (if (and (= (dbk-get *DBK* "SECTEND") "A") (/= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup"))
        (setq *DBK* (dbk-put *DBK* "SECTEND" "B")))
      (if (and (= (dbk-get *DBK* "SECTEND") "B") (/= (dbk-get *DBK* "ENDB") "Stubup") (= (dbk-get *DBK* "ENDA") "Stubup"))
        (setq *DBK* (dbk-put *DBK* "SECTEND" "A")))
      (setq *DBK* (dbk-put *DBK* "PARTOVR" (dbk-kvs "PART" "Auto")))
      (foreach k '("STUBCODE" "WRAP" "MODEL3D" "SECTPICK") (setq *DBK* (dbk-put *DBK* k (fix (dbk-kvn k (dbk-get *DBK* k))))))
      (if (/= (dbk-get *DBK* "STUBCODE") 1) (setq *DBK* (dbk-put *DBK* "STUBCODE" 2)))
      (setq _DBKSEP (dbk-kvn "SEP" _DBKSEP) _DBKCOVERTOP (dbk-kvn "COVT" _DBKCOVERTOP) _DBKCOVERBOT (dbk-kvn "COVB" _DBKCOVERBOT)
            _DBKCOVERLEFT (dbk-kvn "COVL" _DBKCOVERLEFT) _DBKCOVERRIGHT (dbk-kvn "COVR" _DBKCOVERRIGHT) _DBKCOVEREND (dbk-kvn "COVE" _DBKCOVEREND)
            _DBKMINGAP (dbk-kvn "MINGAP" _DBKMINGAP) _DBKSPINT (dbk-kvn "SPINT" _DBKSPINT) _DBKSPEND (dbk-kvn "SPEND" _DBKSPEND)
            _DBKTRANSL (dbk-kvn "TRANSL" _DBKTRANSL) _DBKSTUBSTRAIGHT (dbk-kvn "STUBSTR" _DBKSTUBSTRAIGHT)
            _DBKSECTSCALE (dbk-kvn "SECTSCALE" _DBKSECTSCALE) _DBKTAGPAT (dbk-kvs "TAGPAT" _DBKTAGPAT))
      (setq *DBK-LASTSX* (dbk-get *DBK* "SX") *DBK-LASTSY* (dbk-get *DBK* "SY"))))
  act)

;;; ------------------------------------------------------------------ commands
(defun dbk-all-banks ( / ss i b out)
  (setq ss (ssget "_X" '((-3 ("DBANK_DATA")))) i 0)
  (if ss (repeat (sslength ss) (if (setq b (dbk-xdval (ssname ss i) "BANK")) (setq out (cons (strcase b) out))) (setq i (1+ i))))
  out)
(defun dbk-next-bank ( / names n)
  (setq names (dbk-all-banks) n 1)
  (while (member (strcat "DB" (itoa n)) names) (setq n (1+ n)))
  (strcat "DB" (itoa n)))
(defun dbk-bank-ents (bank / ss i e out)
  (setq ss (ssget "_X" '((-3 ("DBANK_DATA")))) i 0)
  (if ss (repeat (sslength ss) (setq e (ssname ss i))
           (if (= (strcase (cond ((dbk-xdval e "BANK")) (""))) (strcase bank)) (setq out (cons e out)))
           (setq i (1+ i))))
  out)

(defun dbk-edit-loop ( / done k pos v)
  (while (not done)
    (dbk-solve)
    (dbk-print-grid)
    (initget "Tag Size Type Options Generate Cancel")
    (setq k (getkword "\nPositions [Tag/Size/Type/Options/Generate/Cancel] <Generate>: "))
    (cond
      ((or (null k) (= k "Generate"))
        (if (dbk-get *DBKS* "ERRS") (dbk-say "Fix the errors above first (Options, sizes), or Cancel.") (setq done "GO")))
      ((= k "Cancel") (setq done "CANCEL"))
      ((= k "Tag")
        (setq pos (strcase (dbk-ask-str "Position, or * for all" "*")))
        (cond ((= pos "*") (setq _DBKTAGPAT (dbk-ask-str "Tag pattern ({BANK} {POS})" _DBKTAGPAT)) (dbk-setpos "*" "TAG" nil))
              ((setq v (dbk-findpos (dbk-get *DBK* "PL") pos)) (dbk-setpos pos "TAG" (dbk-ask-str (strcat "Tag for " pos) (dbk-tag v))))
              (T (dbk-say "  No such position."))))
      ((= k "Size")
        (setq pos (strcase (dbk-ask-str "Position, or * for all" "*")))
        (if (or (= pos "*") (dbk-findpos (dbk-get *DBK* "PL") pos))
          (progn
            (setq v (dbk-ask-real (strcat "Trade size for " pos)
                                  (dbk-get (if (= pos "*") (car (dbk-get *DBK* "PL")) (dbk-findpos (dbk-get *DBK* "PL") pos)) "SIZE")))
            (cond ((< v (- _DBKMINSIZE 1e-6)) (dbk-say (strcat "  Underground minimum is " (dbk-sz _DBKMINSIZE) ".")))
                  ((and _CONSIZE_LIST (not (vl-some '(lambda (s) (equal s v 1e-6)) _CONSIZE_LIST))) (dbk-say "  Not a size in _CONSIZE_LIST."))
                  (T (dbk-setpos pos "SIZE" v))))
          (dbk-say "  No such position.")))
      ((= k "Type")
        (setq pos (strcase (dbk-ask-str "Position, or * for all" "*")))
        (if (or (= pos "*") (dbk-findpos (dbk-get *DBK* "PL") pos))
          (dbk-setpos pos "CODE" (dbk-ask-int "Conduit type code (3 = PVC, 2 = PVC-coated RGS, 1 = RGS)" _DBKCONCODE 1 99))
          (dbk-say "  No such position.")))
      ((= k "Options") (dbk-options))))
  done)

(defun dbk-options ( / k)
  (initget "Cover Gap Interval Transition STRaight SEparation Part STUbmaterial ENcasement Model3d SCale Done")
  (setq k (getkword "\nOptions [Cover/Gap/Interval/Transition/STRaight/SEparation/Part/STUbmaterial/ENcasement/Model3d/SCale/Done] <Done>: "))
  (cond
    ((= k "Cover")
      (setq _DBKCOVERTOP (dbk-ask-real "Cover top" _DBKCOVERTOP) _DBKCOVERBOT (dbk-ask-real "Cover bottom (minimum)" _DBKCOVERBOT)
            _DBKCOVERLEFT (dbk-ask-real "Cover left" _DBKCOVERLEFT) _DBKCOVERRIGHT (dbk-ask-real "Cover right" _DBKCOVERRIGHT)))
    ((= k "Gap") (setq _DBKMINGAP (dbk-ask-real "Minimum clear gap OD to OD" _DBKMINGAP)))
    ((= k "Interval") (setq _DBKSPINT (dbk-ask-real "Spacer interval" _DBKSPINT) _DBKSPEND (dbk-ask-real "First station from a trunk end" _DBKSPEND)))
    ((= k "Transition") (setq _DBKTRANSL (dbk-ask-real "Transition length" _DBKTRANSL)))
    ((= k "STRaight") (setq _DBKSTUBSTRAIGHT (dbk-ask-real "Straight between the stub elbows and the transition" _DBKSTUBSTRAIGHT)))
    ((= k "SEparation") (setq _DBKSEP (atof (dbk-ask-kw "Snap-N-Stac separation" "1.5 2 3" (rtos _DBKSEP 2 1)))))
    ((= k "Part")
      (setq k (strcase (dbk-ask-str (strcat "Spacer part (Auto or " (dbk-joinstr (mapcar 'car *DBK-SNAPNSTAC*) " ") ")")
                                    (cond ((dbk-get *DBK* "PARTOVR")) ("Auto")))))
      (setq *DBK* (dbk-put *DBK* "PARTOVR" (if (= k "AUTO") "Auto" k))))
    ((= k "STUbmaterial")
      (setq k (dbk-ask-kw "Stub-up risers + elbows" "Coated Rgs" (if (= (dbk-get *DBK* "STUBCODE") 1) "Rgs" "Coated")))
      (setq *DBK* (dbk-put *DBK* "STUBCODE" (if (= k "Rgs") 1 2)))
      (if (= k "Rgs")
        (setq *DBK* (dbk-put *DBK* "WRAP" (if (= "Yes" (dbk-ask-kw "Tape wrap the plain RGS stub-ups" "Yes No"
                                                                  (if (= (dbk-get *DBK* "WRAP") 1) "Yes" "No"))) 1 0)))))
    ((= k "ENcasement")
      (dbk-solve)
      (initget "Auto Top")
      (setq k (getreal (strcat "\nStub-up encasement top: elevation, or [Auto/Top] (Auto = top of the elbow sweep EL "
                               (dbk-r2 (dbk-get *DBKS* "SWEEPTOP")) ", Top = stub-up top EL) <"
                               (dbk-encstr (dbk-encval (dbk-get *DBK* "ENCH"))) ">: ")))
      (if k (setq *DBK* (dbk-put *DBK* "ENCH" (dbk-encval k)))))
    ((= k "Model3d")
      (setq *DBK* (dbk-put *DBK* "MODEL3D" (if (= "Yes" (dbk-ask-kw (strcat "3D envelope + spacer solids on " (dbk-model-layer)) "Yes No"
                                                                  (if (= (dbk-get *DBK* "MODEL3D") 1) "Yes" "No"))) 1 0))))
    ((= k "SCale") (setq _DBKSECTSCALE (dbk-ask-real "Section scale factor" _DBKSECTSCALE))))
  (princ))

;;; ------------------------------------------------------------------ DUCTBANK / -DUCTBANK
;;; Reference info (tag size code dist mesr plain): from MED_CONDUIT, or for a plain route
;;; (3D polyline / polyline / line with elevation, no MED data) the last used or default
;;; size (_DBKREFSIZE, 4") and type (_DBKCONCODE); the dialog / -DUCTBANK ask for them.
(defun dbk-ref-info (ent / md)
  (if (setq md (xdataget ent "MED_CONDUIT"))
    (list (nth 1 md) (nth 2 md) (nth 3 md) (nth 4 md) (nth 5 md) nil)
    (list "" (if *DBK-LASTREFSIZE* *DBK-LASTREFSIZE* _DBKREFSIZE) (if *DBK-LASTREFCODE* *DBK-LASTREFCODE* _DBKCONCODE) 0.0 "T" T)))
(defun dbk-reflabel ()
  (if (dbk-get *DBK* "REFPLAIN") (strcat "plain " (cond ((dbk-get *DBK* "REFTYPE")) ("route")) " route") (dbk-get *DBK* "REFTAG")))
;;; Shared setup: validate the reference and fill *DBK* with defaults (no prompts), so the user
;;; mostly sets tags and sizes. Returns T when the reference is usable.
(defun dbk-setup-ref (ent)
  (cond
    ((null ent) (dbk-say "Cancelled.") nil)
    ((dbk-xdval ent "ROLE") (dbk-say (strcat "That entity already belongs to bank " (cond ((dbk-xdval ent "BANK")) ("?")) ". Use DBEDIT or DBDELETE.")) nil)
    ((not (member (cdr (assoc 0 (entget ent))) '("LWPOLYLINE" "POLYLINE" "LINE")))
      (dbk-say "Pick a MED conduit, or a plain 3D polyline / polyline / line route (with elevation).") nil)
    (T (dbk-setup-core ent (dbk-ref-info ent)))))
;; info = (tag size code dist mesr plain); geometry always read from the entity (DBEDIT: the
;; possibly edited route on MED_DBREF)
(defun dbk-setup-core (ent info / geo z topa topb gi rows cnt counts v plain size)
  (setq plain (nth 5 info))
  (cond
    ((= (type (setq geo (dbk-ref-geom ent))) 'STR) (dbk-say (strcat "Cannot use this reference: " geo ".")) nil)
    ((vl-some '(lambda (c) (> (dbk-deg (nth 5 c)) 135.0)) (dbk-corners (dbk-segs (car geo))))
      (dbk-say "Cannot use this reference: a plan bend is sharper than 135 deg.") nil)
    (T
      (setq *DBK-SEGS* (dbk-segs (car geo)) *DBK-CORNERS* (dbk-corners *DBK-SEGS*)
            z (cadr geo) topa (caddr geo) topb (cadddr geo) gi (nth 4 geo))
      (dbk-say (strcat "  Reference "
                       (if plain (strcat "(plain " (car gi) ", no MED data; size/type default " (dbk-sz (nth 1 info)) " "
                                         (dbk-typeabbr (nth 2 info)) ")")
                         (strcat (nth 0 info) ": " (dbk-sz (nth 1 info)) " " (dbk-typeabbr (nth 2 info)) " (code " (itoa (nth 2 info)) "), " (car gi)))
                       ", trunk centerline elevation " (dbk-r2 z) ", " (itoa (length *DBK-SEGS*)) " leg(s), "
                       (itoa (length *DBK-CORNERS*)) " plan bend(s)"
                       (apply 'strcat (mapcar '(lambda (c) (strcat " " (rtos (dbk-deg (nth 5 c)) 2 1) "deg" (if (> (nth 6 c) 0) "L" "R"))) *DBK-CORNERS*))
                       (if (> (cadr gi) 0) (strcat ", " (itoa (cadr gi)) " fillet arc(s) replaced by their corners") "")))
      (dbk-say (strcat "  End A (start) " (dbk-r2 (car (car (car geo)))) "," (dbk-r2 (cadr (car (car geo))))
                       (if topa (strcat ": vertical stub up to elevation " (dbk-r2 topa)) ": no vertical leg")
                       ".  End B " (dbk-r2 (car (last (car geo)))) "," (dbk-r2 (cadr (last (car geo))))
                       (if topb (strcat ": vertical stub up to elevation " (dbk-r2 topb)) ": no vertical leg") "."))
      (setq rows (if *DBK-LASTROWS* *DBK-LASTROWS* 2) cnt (if *DBK-LASTCNT* *DBK-LASTCNT* 4) counts nil)
      (repeat rows (setq counts (cons cnt counts)))
      (setq size (max _DBKMINSIZE (nth 1 info)) v (dbk-spacer-part size _DBKSEP))
      (setq *DBK* (list (cons "REFENT" ent) (cons "REFTAG" (nth 0 info)) (cons "REFSIZE" (nth 1 info)) (cons "REFCODE" (nth 2 info))
                        (cons "REFDIST" (nth 3 info)) (cons "REFMESR" (nth 4 info)) (cons "ZREF" z)
                        (cons "REFPLAIN" plain) (cons "REFTYPE" (car gi))
                        (cons "REFLAYER" (cdr (assoc 8 (entget ent))))
                        (cons "BANK" (dbk-next-bank)) (cons "ROWS" rows) (cons "COUNTS" counts)
                        (cons "PL" (dbk-make-poslist counts size))
                        (cons "REFPOS" (dbk-posid rows 1))
                        (cons "ENDA" (if topa "Stubup" "Open")) (cons "ENDB" (if topb "Stubup" "Open"))
                        (cons "TOPA" (if topa topa (+ z 48.0))) (cons "TOPB" (if topb topb (+ z 48.0)))
                        (cons "HASTOPA" (if topa T)) (cons "HASTOPB" (if topb T))
                        (cons "SX" (if *DBK-LASTSX* *DBK-LASTSX* (if v (nth 5 v) 6.0)))
                        (cons "SY" (if *DBK-LASTSY* *DBK-LASTSY* (if v (nth 5 v) 6.0)))
                        (cons "SECTEND" (if (and topb (not topa)) "B" "A"))
                        (cons "PARTOVR" "Auto") (cons "STUBCODE" (if (= _DBKRISERCODE 1) 1 2))
                        (cons "WRAP" (if (= _DBKSTUBWRAP 1) 1 0)) (cons "MODEL3D" (if (= _DBKMODEL3D 1) 1 0))
                        (cons "SECTPICK" (if (= _DBKSECTPICK 1) 1 0)) (cons "ENCH" (dbk-encval _DBKENCASE))))
      (if plain (dbk-setpos "*" "CODE" (nth 2 info)))
      T)))

;; plain route: the reference size / type are the defaults of every position still at the
;; old default (the REF position always follows)
(defun dbk-set-refsize (size code / osz ocd)
  (setq osz (max _DBKMINSIZE (dbk-get *DBK* "REFSIZE")) ocd (dbk-get *DBK* "REFCODE"))
  (setq *DBK* (dbk-put *DBK* "PL"
                (mapcar '(lambda (p)
                           (if (or (= (dbk-get p "POS") (dbk-get *DBK* "REFPOS"))
                                   (and (equal (dbk-get p "SIZE") osz 1e-6) (= (dbk-get p "CODE") ocd)))
                             (dbk-put (dbk-put p "SIZE" (max _DBKMINSIZE size)) "CODE" code) p))
                        (dbk-get *DBK* "PL"))))
  (setq *DBK* (dbk-put (dbk-put *DBK* "REFSIZE" size) "REFCODE" code)
        *DBK-LASTREFSIZE* size *DBK-LASTREFCODE* code))

;; rebuild the position list for new rows/counts, keeping what was set on surviving positions
(defun dbk-reshape (rows counts / old pl size)
  (setq old (dbk-get *DBK* "PL") size (max _DBKMINSIZE (dbk-get *DBK* "REFSIZE")))
  (setq pl (mapcar '(lambda (p / o) (if (setq o (dbk-findpos old (dbk-get p "POS"))) o p)) (dbk-make-poslist counts size)))
  (setq *DBK* (dbk-put (dbk-put (dbk-put *DBK* "ROWS" rows) "COUNTS" counts) "PL" pl))
  (if (not (dbk-findpos pl (dbk-get *DBK* "REFPOS"))) (setq *DBK* (dbk-put *DBK* "REFPOS" (dbk-posid rows 1))))
  (setq *DBK-LASTROWS* rows *DBK-LASTCNT* (car counts)))

;; command-line inputs (-DUCTBANK): every prompt defaults to the setup value
(defun dbk-text-inputs ( / rows k cnt counts v refpos topa topb sz cd)
  (if (dbk-get *DBK* "REFPLAIN")
    (progn
      (dbk-say "  The reference route has no MED data: enter the reference conduit size and type.")
      (setq sz (dbk-ask-real "Reference conduit trade size" (dbk-get *DBK* "REFSIZE"))
            cd (dbk-ask-int "Reference conduit type code (3 = PVC, 2 = PVC-coated RGS, 1 = RGS)" (dbk-get *DBK* "REFCODE") 1 99))
      (dbk-set-refsize sz cd)))
  (if *DBK-EDITING*
    (dbk-say (strcat "  Bank ID " (dbk-get *DBK* "BANK") " (kept by DBEDIT)."))
    (setq *DBK* (dbk-put *DBK* "BANK" (strcase (dbk-ask-str "Bank ID" (dbk-get *DBK* "BANK"))))))
  (setq rows (dbk-ask-int "Number of rows (deep)" (dbk-get *DBK* "ROWS") 1 9))
  (setq k 1 cnt (car (dbk-get *DBK* "COUNTS")) counts nil)
  (repeat rows
    (setq cnt (dbk-ask-int (strcat "Conduits in row " (chr (+ 64 k)) (cond ((= rows 1) "") ((= k 1) " (top)") ((= k rows) " (bottom)") (T "")))
                           cnt 1 12))
    (setq counts (append counts (list cnt)) k (1+ k)))
  (dbk-reshape rows counts)
  (setq refpos nil)
  (while (not refpos)
    (setq v (strcase (dbk-ask-str "Reference conduit position (row letter + column, e.g. B1)" (dbk-get *DBK* "REFPOS"))))
    (if (dbk-findpos (dbk-get *DBK* "PL") v) (setq refpos v) (dbk-say "  No such position in this bank.")))
  (setq *DBK* (dbk-put *DBK* "REFPOS" refpos))
  (setq *DBK* (dbk-put *DBK* "ENDA" (dbk-ask-kw "End A (reference start)" "Stubup Open" (dbk-get *DBK* "ENDA"))))
  (if (and (= (dbk-get *DBK* "ENDA") "Stubup") (not (dbk-get *DBK* "HASTOPA")))
    (setq *DBK* (dbk-put *DBK* "TOPA" (dbk-ask-real "End A stub-up top elevation" (dbk-get *DBK* "TOPA")))))
  (setq *DBK* (dbk-put *DBK* "ENDB" (dbk-ask-kw "End B (reference end)" "Stubup Open" (dbk-get *DBK* "ENDB"))))
  (if (and (= (dbk-get *DBK* "ENDB") "Stubup") (not (dbk-get *DBK* "HASTOPB")))
    (setq *DBK* (dbk-put *DBK* "TOPB" (dbk-ask-real "End B stub-up top elevation" (dbk-get *DBK* "TOPB")))))
  (if (or (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup"))
    (progn
      (setq *DBK* (dbk-put *DBK* "SX" (dbk-ask-real "Stub-up pitch across (center to center)" (dbk-get *DBK* "SX"))))
      (setq *DBK* (dbk-put *DBK* "SY" (dbk-ask-real "Stub-up pitch along the run (row to row)" (dbk-get *DBK* "SY"))))
      (setq *DBK-LASTSX* (dbk-get *DBK* "SX") *DBK-LASTSY* (dbk-get *DBK* "SY"))))
  (setq *DBK* (dbk-put *DBK* "SECTEND"
                (cond ((and (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup"))
                        (dbk-ask-kw "Section at stub-up end (columns are numbered looking from that end)" "A B" (dbk-get *DBK* "SECTEND")))
                      ((= (dbk-get *DBK* "ENDB") "Stubup") "B")
                      (T "A")))))

;; build + report (both flows)
(defun dbk-build (secpt / res m3d)
  (setq res (dbk-generate secpt) m3d (nth 6 res))
  (dbk-say (strcat "Stub-up encasement: "
                   (cond ((or (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
                           (strcat "concrete turns up to EL "
                                   (dbk-joinstr (vl-remove 'nil (list (if (dbk-get *DBKS* "ENCZA") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZA")) " (end A)"))
                                                                      (if (dbk-get *DBKS* "ENCZB") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZB")) " (end B)")))) ", ")
                                   " around the stub elbows and risers (" (dbk-enclabel (dbk-get *DBK* "ENCH")) ")."))
                         ((or (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup")) "none (see the flags).")
                         (T "no stub-up ends."))))
  (dbk-say (strcat "Bank " (dbk-get *DBK* "BANK") " built: " (itoa (length (dbk-get *DBK* "PL"))) " conduit positions ("
                   (itoa (nth 2 res)) " MED_CONDUIT segments, " (itoa (nth 3 res)) " elbow segments = " (itoa (nth 4 res))
                   " fitting records), " (itoa (nth 5 res)) " spacer stations, envelope and sections; "
                   (itoa (nth 1 res)) " member entities."))
  (dbk-say (strcat "  Stub-ups: " (if (= (dbk-get *DBK* "STUBCODE") 1)
                                     (strcat "plain RGS risers and stub elbows" (if (= (dbk-get *DBK* "WRAP") 1) ", tape wrap noted (WRAP text, BOM code 174)." ", no wrap."))
                                     "PVC-coated RGS risers and stub elbows.")))
  (if m3d
    (progn
      (dbk-say (strcat "  3D model on layer " (dbk-model-layer) ": " (itoa (car m3d)) " envelope solid"
                       (if (> (caddr m3d) 0) (strcat " (with " (itoa (caddr m3d)) " stub-up turn-up(s))") "") ", " (itoa (cadr m3d))
                       " spacer station solid(s); MEDMAKE3D includes every " (if (= (type _MED3DMODELPREFIX) 'STR) _MED3DMODELPREFIX "3DMEDModel-")
                       "* layer."))
      (dbk-disclaimer)))
  (dbk-say (strcat "  Reference " (dbk-reflabel) " is on layer MED_DBREF as the route guide (not in BOM); DBEDIT rebuilds from it, DBDELETE restores it."))
  (foreach s (dbk-get *DBKS* "FLAGS") (dbk-say (strcat "  FLAG: " s)))
  (dbk-say "  REMINDER: cables come later. MED does not calculate cable fill, ampacity derating (mutual heating),")
  (dbk-say "  voltage drop, pulling tension / sidewall pressure or burial depth. Check them for every circuit in the bank.")
  res)

(defun dbk-start-msg (cmd / miss)
  (dbk-say (strcat cmd " " *DBK-VERSION* ": underground ductbank from a routed reference conduit or 3D polyline (2D plan + sections"
                   (if (= _DBKMODEL3D 1) ", 3D envelope + spacers" "") ")."))
  (dbk-say "  Defaults: encased PVC, 1\" min, Carlon Snap-N-Stac 2\" sep, spacers every 8 ft, cover 3\" top/bottom 2\" sides, PVC-coated RGS stub-ups.")
  (setq miss (dbk-missing-codes))
  (if (and miss (listp miss))
    (dbk-say (strcat "  Note: " (itoa (length miss)) " ductbank fitting/spacer codes are not in MEDType yet (BOM rows show no"
                     " description). Run DBSEED once to add them."))))

(defun dbk-run-text ( / done secpt)
  (dbk-text-inputs)
  (setq done (dbk-edit-loop))
  (if (= done "GO")
    (progn
      (if *DBK-EDITING*
        (setq secpt (dbk-get *DBK* "SECTPT"))   ; DBEDIT: sections stay where they were
        (progn (setq secpt (getpoint "\nSection drawing location <auto, right of the bank>: "))
               (if secpt (setq secpt (trans secpt 1 0)))))
      (dbk-commit secpt))
    (dbk-say "Cancelled; nothing changed.")))

;; DBEDIT: erase the old members (not the reference route) just before the rebuild
(defun dbk-commit (secpt / n)
  (if *DBK-EDITING*
    (progn
      (setq n 0)
      (foreach x (dbk-bank-ents *DBK-EDITING*)
        (if (and (entget x) (/= (dbk-xdval x "ROLE") "REF")) (progn (entdel x) (setq n (1+ n)))))
      (dbk-say (strcat "DBEDIT: erased the " (itoa n) " old member entities of bank " *DBK-EDITING* "; rebuilding in place."))))
  (dbk-build secpt))

;;; -DUCTBANK: command-line version (standard AutoCAD dash convention), also DUCTBANK's fallback
(defun c:-DUCTBANK ( / *error*)
  (dbk-undo T)
  (setq *DBK-EDITING* nil)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg T) "*break*,*cancel*,*exit*"))) (dbk-say (strcat "DUCTBANK error: " msg)))
    (dbk-undo nil) (princ))
  (dbk-start-msg "-DUCTBANK")
  (if (dbk-setup-ref (dbk-pick "Select reference MED conduit or 3D polyline route")) (dbk-run-text))
  (dbk-undo nil)
  (princ))

(defun dbk-dialog-available ( / r)
  (and (/= _DBKUSEDIALOG 0) MED-DuctbankDialogAvailable
       (setq r (vl-catch-all-apply 'MED-DuctbankDialogAvailable nil))
       (not (vl-catch-all-error-p r)) (if (listp r) (car r) r) T))

;; dialog loop (DUCTBANK / DBEDIT): returns "OK", "CANCEL" or "TEXT" (dialog failed)
(defun dbk-dialog-loop ( / res act)
  (while (not act)
    (dbk-solve)
    (setq res (vl-catch-all-apply 'MED-DuctbankDialog (list (dbk-spec-out))))
    ;; a one-item ResultBuffer comes back as a list ("ACTION=...") in full AutoCAD
    (if (and (= (type res) 'LIST) (= (type (car res)) 'STR)) (setq res (car res)))
    (cond
      ((or (vl-catch-all-error-p res) (/= (type res) 'STR))
        (dbk-say (strcat "  Ductbank dialog failed" (if (vl-catch-all-error-p res) (strcat ": " (vl-catch-all-error-message res)) "")
                         "; command-line flow."))
        (setq act "TEXT"))
      (T
        (setq act (dbk-spec-in res))
        (cond ((= act "CHECK") (setq act nil))
              ((= act "OK") (dbk-solve) (if (dbk-get *DBKS* "ERRS") (setq act nil)))))))
  act)
(defun dbk-run-dialog ( / act secpt)
  (if (not (dbk-dialog-available))
    (progn (dbk-say "  (Ductbank dialog not available: MED-DotNet not loaded. Command-line flow.)")
           (dbk-run-text))
    (progn
      (setq act (dbk-dialog-loop))
      (cond
        ((= act "TEXT") (dbk-run-text))
        ((= act "OK")
          (dbk-print-grid)
          (cond
            ((= (dbk-get *DBK* "SECTPICK") 1)
              (setq secpt (getpoint "\nSection drawing location <auto, right of the bank>: "))
              (if secpt (setq secpt (trans secpt 1 0))))
            (*DBK-EDITING* (setq secpt (dbk-get *DBK* "SECTPT"))))
          (dbk-commit secpt))
        (T (dbk-say "Cancelled; nothing changed."))))))

;;; DUCTBANK: pick the reference, then the grid dialog (MED-DotNet); text flow if the DLL is not loaded
(defun c:DUCTBANK ( / *error*)
  (dbk-undo T)
  (setq *DBK-EDITING* nil)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg T) "*break*,*cancel*,*exit*"))) (dbk-say (strcat "DUCTBANK error: " msg)))
    (dbk-undo nil) (princ))
  (dbk-start-msg "DUCTBANK")
  (if (dbk-setup-ref (dbk-pick "Select reference MED conduit or 3D polyline route")) (dbk-run-dialog))
  (dbk-undo nil)
  (princ))

;;; ------------------------------------------------------------------ DBEDIT / -DBEDIT
;;; Reopen a bank: every setting comes from the bank record (envelope DBANK_DATA), the route
;;; from the reference on MED_DBREF (edited since? the edited route is used). OK erases the
;;; old members (and 3D solids) and regenerates in place with the same bank ID. The session
;;; settings (_DBK* covers, interval, ...) are restored afterwards.
(setq *DBK-EDIT-GLOBALS* '(_DBKCOVERTOP _DBKCOVERBOT _DBKCOVERLEFT _DBKCOVERRIGHT _DBKCOVEREND _DBKMINGAP _DBKSPINT
                          _DBKSPEND _DBKTRANSL _DBKSTUBSTRAIGHT _DBKSEP _DBKSECTSCALE _DBKTAGPAT))
(defun dbk-globals-save () (mapcar '(lambda (s) (cons s (eval s))) *DBK-EDIT-GLOBALS*))
(defun dbk-globals-restore (l) (foreach x l (set (car x) (cdr x))))
(defun dbk-edit-load (e / bank ents env ref info v n pl f p tgs conds)
  (setq bank (if e (dbk-xdval e "BANK")))
  (cond
    ((null e) (dbk-say "Cancelled.") nil)
    ((null bank) (dbk-say "That entity is not part of a ductbank.") nil)
    (T
      (setq ents (dbk-bank-ents bank))
      (foreach x ents
        (cond ((= (dbk-xdval x "ROLE") "ENVELOPE") (setq env x))
              ((= (dbk-xdval x "ROLE") "REF") (setq ref x))
              ((= (dbk-xdval x "ROLE") "CONDUIT") (setq conds (cons x conds)))))
      (cond
        ((null env) (dbk-say (strcat "Bank " bank ": no envelope / bank record found; cannot edit.")) nil)
        ((null ref) (dbk-say (strcat "Bank " bank ": the reference route (layer MED_DBREF) is missing; cannot rebuild.")) nil)
        (T
          ;; session settings from the bank record (code defaults when an older bank lacks one)
          (defun dbk-ev (k d / x) (if (and (setq x (dbk-xdval env k)) (/= x "")) (atof x) d))
          (defun dbk-es (k d / x) (if (and (setq x (dbk-xdval env k)) (/= x "")) x d))
          (setq _DBKCOVERTOP (dbk-ev "COVT" _DBKCOVERTOP) _DBKCOVERBOT (dbk-ev "COVB" _DBKCOVERBOT)
                _DBKCOVERLEFT (dbk-ev "COVL" _DBKCOVERLEFT) _DBKCOVERRIGHT (dbk-ev "COVR" _DBKCOVERRIGHT)
                _DBKCOVEREND (dbk-ev "COVE" _DBKCOVEREND) _DBKMINGAP (dbk-ev "GAP" _DBKMINGAP)
                _DBKSPINT (dbk-ev "SPINT" _DBKSPINT) _DBKSPEND (dbk-ev "SPEND" _DBKSPEND) _DBKTRANSL (dbk-ev "TRANSL" _DBKTRANSL)
                _DBKSTUBSTRAIGHT (dbk-ev "STUBSTR" _DBKSTUBSTRAIGHT) _DBKSEP (dbk-ev "SEP" _DBKSEP)
                _DBKSECTSCALE (dbk-ev "SECTSCALE" _DBKSECTSCALE) _DBKTAGPAT (dbk-es "TAGPAT" _DBKTAGPAT))
          (setq info (list (cond ((dbk-xdval ref "REFTAG")) ("")) (dbk-ev-ref ref "REFSIZE" _DBKREFSIZE)
                           (fix (dbk-ev-ref ref "REFCODE" _DBKCONCODE)) (dbk-ev-ref ref "REFDIST" 0.0)
                           (cond ((dbk-xdval ref "REFMESR")) ("T")) (= (dbk-xdval ref "REFPLAIN") "1")))
          (setq *DBK-EDITING* (strcase bank))
          (if (dbk-setup-core ref info)
            (progn
              (setq *DBK* (dbk-put *DBK* "BANK" (strcase bank))
                    *DBK* (dbk-put *DBK* "REFLAYER" (cond ((dbk-xdval ref "REFLAYER")) ("0"))))
              (setq v (mapcar 'atoi (dbk-split (dbk-es "COUNTS" "4,4") ",")))
              (dbk-reshape (length v) v)
              ;; positions: P= records, else (banks built before MVP3) the conduits' MED_CONDUIT data
              (setq pl (dbk-get *DBK* "PL"))
              (foreach r (dbk-xdvals env "P")
                (setq f (dbk-split r "|"))
                (if (dbk-findpos pl (car f))
                  (setq pl (dbk-replpos pl (dbk-put (dbk-put (dbk-put (dbk-findpos pl (car f)) "SIZE" (atof (nth 2 f))) "CODE" (atoi (nth 3 f)))
                                                    "TAG" (if (= (nth 4 f) "C") (nth 1 f)))))))
              (if (not (dbk-xdvals env "P"))
                (foreach c conds
                  (if (and (setq p (dbk-findpos pl (dbk-xdval c "POS"))) (setq v (xdataget c "MED_CONDUIT")))
                    (setq pl (dbk-replpos pl (dbk-put (dbk-put (dbk-put p "SIZE" (nth 2 v)) "CODE" (nth 3 v))
                                                      "TAG" (if (/= (nth 1 v) (dbk-tag (dbk-put p "TAG" nil))) (nth 1 v))))))))
              (setq *DBK* (dbk-put *DBK* "PL" pl))
              (if (dbk-findpos pl (dbk-es "REFPOS" "")) (setq *DBK* (dbk-put *DBK* "REFPOS" (strcase (dbk-es "REFPOS" "")))))
              (foreach k '("ENDA" "ENDB") (setq *DBK* (dbk-put *DBK* k (if (= (strcase (dbk-es k (dbk-get *DBK* k))) "STUBUP") "Stubup" "Open"))))
              (if (not (dbk-get *DBK* "HASTOPA")) (setq *DBK* (dbk-put *DBK* "TOPA" (dbk-ev "TOPA" (dbk-get *DBK* "TOPA")))))
              (if (not (dbk-get *DBK* "HASTOPB")) (setq *DBK* (dbk-put *DBK* "TOPB" (dbk-ev "TOPB" (dbk-get *DBK* "TOPB")))))
              (setq *DBK* (dbk-put *DBK* "SX" (dbk-ev "STUBSX" (dbk-get *DBK* "SX")))
                    *DBK* (dbk-put *DBK* "SY" (dbk-ev "STUBSY" (dbk-get *DBK* "SY")))
                    *DBK* (dbk-put *DBK* "SECTEND" (if (= (dbk-es "SECTEND" "A") "B") "B" "A"))
                    *DBK* (dbk-put *DBK* "PARTOVR" (dbk-es "PARTOVR" "Auto"))
                    *DBK* (dbk-put *DBK* "STUBCODE" (if (= (dbk-es "STUBMAT" "2") "1") 1 2))
                    *DBK* (dbk-put *DBK* "WRAP" (fix (dbk-ev "WRAPSET" (dbk-ev "WRAP" (dbk-get *DBK* "WRAP")))))
                    *DBK* (dbk-put *DBK* "MODEL3D" (cond ((dbk-xdval env "M3DON") (atoi (dbk-xdval env "M3DON")))
                                                         ((dbk-xdval env "MODEL3D") (if (> (atoi (dbk-xdval env "MODEL3D")) 0) 1 0))
                                                         (T (dbk-get *DBK* "MODEL3D"))))
                    *DBK* (dbk-put *DBK* "ENCH" (dbk-encval (dbk-es "ENCH" (dbk-get *DBK* "ENCH"))))
                    *DBK* (dbk-put *DBK* "SECTPICK" 0)
                    *DBK* (dbk-put *DBK* "SECTPT" (if (dbk-xdval env "SECTX") (list (dbk-ev "SECTX" 0.0) (dbk-ev "SECTY" 0.0)))))
              (dbk-say (strcat "  DBEDIT " bank ": " (itoa (length ents)) " member entities; settings read from the bank record"
                               (if (dbk-xdvals env "P") "" " (older bank: positions read from its conduits)")
                               ", route read from the reference on MED_DBREF."))
              T)
            (progn (setq *DBK-EDITING* nil) nil)))))))
(defun dbk-ev-ref (ref k d / x) (if (and (setq x (dbk-xdval ref k)) (/= x "")) (atof x) d))
(defun dbk-edit-cmd (dialog / *error* saved)
  (dbk-undo T)
  (setq saved (dbk-globals-save) *DBK-EDITING* nil)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg T) "*break*,*cancel*,*exit*"))) (dbk-say (strcat "DBEDIT error: " msg)))
    (dbk-globals-restore saved) (setq *DBK-EDITING* nil)
    (dbk-undo nil) (princ))
  (dbk-start-msg (if dialog "DBEDIT" "-DBEDIT"))
  (if (dbk-edit-load (dbk-pick "Select any part of the ductbank to edit"))
    (if dialog (dbk-run-dialog) (dbk-run-text)))
  (dbk-globals-restore saved)
  (setq *DBK-EDITING* nil)
  (dbk-undo nil)
  (princ))
(defun c:DBEDIT () (dbk-edit-cmd T))
(defun c:-DBEDIT () (dbk-edit-cmd nil))

(defun c:DBLIST ( / e bank ents env p pos role lens sta recs len n3d ref)
  (setq e (dbk-pick "Select any part of a ductbank"))
  (if (and e (setq bank (dbk-xdval e "BANK")))
    (progn
      (setq ents (dbk-bank-ents bank) n3d 0)
      (foreach x ents
        (setq role (dbk-xdval x "ROLE") pos (dbk-xdval x "POS"))
        (cond
          ((= role "ENVELOPE") (setq env x))
          ((member role '("CONDUIT" "RISER"))
            (setq len (dbk-curvelen x))
            (setq p (assoc pos lens) lens (if p (subst (list pos (+ (cadr p) len) (caddr p) (nth 3 p)) p lens)
                                              (cons (list pos len (xdataget x "MED_CONDUIT") 0) lens))))
          ((= role "ELBOW")
            (setq p (assoc pos lens) lens (if p (subst (list pos (cadr p) (caddr p) (1+ (nth 3 p))) p lens)
                                              (cons (list pos 0.0 nil 1) lens))))
          ((= role "SPACER") (setq sta (cons x sta)))
          ((member role '("ENV3D" "SPACER3D")) (setq n3d (1+ n3d)))
          ((= role "REF") (setq ref x))))
      (dbk-say (strcat "Ductbank " bank ": " (itoa (length ents)) " entities"))
      (if env (progn
        (dbk-say (strcat "  rows " (dbk-xdval env "ROWS") " (" (dbk-xdval env "COUNTS") "), reference " (dbk-xdval env "REFPOS")
                         ", spacer " (dbk-xdval env "SPACER") " every " (dbk-xdval env "SPINT") "\", trunk W x H "
                         (rtos (atof (dbk-xdval env "WT")) 2 2) " x " (rtos (atof (dbk-xdval env "HT")) 2 2)
                         ", stub zone W " (rtos (atof (dbk-xdval env "WS")) 2 2)
                         (if (= (dbk-xdval env "STUBMAT") "1") (strcat ", plain RGS stub-ups" (if (= (dbk-xdval env "WRAP") "1") " (wrapped)" ""))
                           ", PVC-coated RGS stub-ups")))
        (dbk-say (strcat "  stub-up encasement: "
                         (if (or (/= (cond ((dbk-xdval env "ENCZA")) ("")) "") (/= (cond ((dbk-xdval env "ENCZB")) ("")) ""))
                           (strcat "turn-up to EL" (if (/= (cond ((dbk-xdval env "ENCZA")) ("")) "") (strcat " " (rtos (atof (dbk-xdval env "ENCZA")) 2 2) " (end A)") "")
                                   (if (/= (cond ((dbk-xdval env "ENCZB")) ("")) "") (strcat " " (rtos (atof (dbk-xdval env "ENCZB")) 2 2) " (end B)") "")
                                   ", setting " (dbk-enclabel (cond ((dbk-xdval env "ENCH")) ("Auto"))))
                           (if (dbk-xdval env "ENCH") "none" "not stored (bank built before MVP3; DBEDIT adds it)"))))
        (dbk-say (strcat "  reference: " (cond ((null ref) "missing!")
                                                ((= (dbk-xdval ref "REFPLAIN") "1") (strcat "plain " (cond ((dbk-xdval ref "REFTYPE")) ("route"))
                                                                                            " (no MED data), handle " (cdr (assoc 5 (entget ref)))))
                                                (T (strcat "MED conduit " (cond ((dbk-xdval ref "REFTAG")) ("?")) ", handle " (cdr (assoc 5 (entget ref))))))
                         " on MED_DBREF; DBEDIT rebuilds from it" (if (dbk-xdvals env "P") "" " (older bank: positions come from its conduits)")))))
      (foreach x (vl-sort lens '(lambda (a b) (< (car a) (car b))))
        (dbk-say (strcat "  " (car x) "  " (if (caddr x) (nth 1 (caddr x)) "?") "  " (if (caddr x) (dbk-sz (nth 2 (caddr x))) "")
                         " code " (if (caddr x) (itoa (nth 3 (caddr x))) "?") "  conduit " (rtos (cadr x) 2 2) "\" ("
                         (rtos (/ (cadr x) 12.0) 2 2) "')  elbows " (itoa (nth 3 x)))))
      (setq recs 0)
      (foreach x sta (setq recs (+ recs (/ (length (cdr (xdataget x "MED_FITTING"))) 6))))
      (dbk-say (strcat "  Spacer stations: " (itoa (length sta)) " (" (itoa recs) " spacer / strap / reducer records)"))
      (dbk-say (strcat "  3D model solids (" (dbk-model-layer) "): " (itoa n3d))))
    (if e (dbk-say "That entity is not part of a ductbank.")))
  (princ))

(defun c:DBDELETE ( / e bank ents ref n lay doc plain)
  (setq e (dbk-pick "Select any part of the ductbank to erase"))
  (if (and e (setq bank (dbk-xdval e "BANK")))
    (progn
      (setq ents (dbk-bank-ents bank) n 0)
      (if (= "Yes" (dbk-ask-kw (strcat "Erase " (itoa (1- (length ents))) " entities of bank " bank " and restore the reference route?") "Yes No" "No"))
        (progn
          (dbk-undo T)
          (foreach x ents
            (if (= (dbk-xdval x "ROLE") "REF") (setq ref x) (progn (entdel x) (setq n (1+ n)))))
          (if ref
            (progn
              (setq lay (cond ((dbk-xdval ref "REFLAYER")) ("0")) plain (= (dbk-xdval ref "REFPLAIN") "1"))
              (entmod (append (subst (cons 8 lay) (assoc 8 (entget ref)) (entget ref))
                              (if plain
                                (list (list -3 (list "DBANK_DATA")))   ; plain route: back to its layer, no data
                              (list (list -3 (list "DBANK_DATA")
                                          (bld_app _CONDUIT (list (atoi (dbk-xdval ref "REFCODE"))) (list (atof (dbk-xdval ref "REFSIZE")))
                                                   (list (dbk-xdval ref "REFTAG")) nil (list (atof (dbk-xdval ref "REFDIST"))) nil nil
                                                   (list (dbk-xdval ref "REFMESR")) nil))))))))
          (dbk-undo nil)
          (dbk-say (strcat "Erased " (itoa n) " entities" (if ref (if plain "; reference route restored (plain, no MED data)." "; reference conduit restored.") "."))))))
    (if e (dbk-say "That entity is not part of a ductbank.")))
  (princ))

(defun dbk-csv-split (s / out i q c cur)
  (setq out nil cur "" q nil i 1)
  (while (<= i (strlen s))
    (setq c (substr s i 1))
    (cond ((= c "\"") (if (and q (= (substr s (1+ i) 1) "\"")) (setq cur (strcat cur "\"") i (1+ i)) (setq q (not q))))
          ((and (= c ",") (not q)) (setq out (cons cur out) cur ""))
          (T (setq cur (strcat cur c))))
    (setq i (1+ i)))
  (reverse (cons cur out)))

(defun c:DBSEED ( / f csv fh line rows res have blank add fill n r q)
  ;; Idempotent: inserts the CSV rows whose ITEMTYPE/ITEMCODE is missing from MEDType and fills
  ;; rows that exist with a blank ITEMDESC (e.g. the old FITTING 89 placeholder). Never overwrites text.
  (setq f (findfile "MEDDuctbank.lsp"))
  (setq csv (if f (strcat (vl-filename-directory f) "\\..\\Data\\seed\\ductbank_medtype.csv")))
  (cond
    ((not (dbk-sql-ok)) (dbk-say "DBSEED: MED-DotNet is not loaded (no database access)."))
    ((not (and csv (findfile csv))) (dbk-say (strcat "DBSEED: seed file not found: " (if csv csv "Data\\seed\\ductbank_medtype.csv"))))
    (T
      (setq fh (open (findfile csv) "r"))
      (read-line fh)
      (while (setq line (read-line fh))
        (if (> (strlen line) 3) (setq rows (cons (dbk-csv-split line) rows))))
      (close fh)
      (setq rows (reverse rows))
      (setq res (vl-catch-all-apply 'MEDProcessSQLStatement
                  (list (strcat "SELECT ITEMCODE, ITEMDESC FROM MEDType WHERE ITEMTYPE='FITTING' AND ITEMCODE IN ("
                                (dbk-joinstr (mapcar 'cadr rows) ",") ")"))))
      (if (or (vl-catch-all-error-p res) (not (listp res)))
        (dbk-say "DBSEED: could not read MEDType.")
        (progn
          (foreach row (cdr res)
            (if (and (listp row) (car row))
              (progn
                (setq n (if (= (type (car row)) 'STR) (atoi (car row)) (fix (car row))))
                (setq have (cons n have))
                (if (or (null (cadr row)) (= (vl-string-trim " " (vl-princ-to-string (cadr row))) "")) (setq blank (cons n blank))))))
          (setq add (vl-remove-if '(lambda (r) (member (atoi (cadr r)) have)) rows)
                fill (vl-remove-if-not '(lambda (r) (member (atoi (cadr r)) blank)) rows))
          (if (and (null add) (null fill))
            (dbk-say (strcat "DBSEED: all " (itoa (length rows)) " ductbank rows are already in MEDType."))
            (if (= "Yes" (dbk-ask-kw (strcat "Add " (itoa (length add)) " MEDType row(s) and fill " (itoa (length fill))
                                             " blank description(s)") "Yes No" "Yes"))
              (progn
                (setq n 0)
                (foreach row add
                  (setq q (dbk-subst-all "''" "'" (caddr row)))
                  (setq r (vl-catch-all-apply 'MEDProcessSQLStatement
                            (list (strcat "INSERT INTO MEDType (ITEMTYPE, ITEMCODE, ITEMDESC) SELECT '" (car row) "', " (cadr row) ", N'" q
                                          "' WHERE NOT EXISTS (SELECT 1 FROM MEDType WHERE ITEMTYPE='" (car row) "' AND ITEMCODE=" (cadr row) ")"))))
                  (if (not (vl-catch-all-error-p r)) (setq n (1+ n))))
                (foreach row fill
                  (setq q (dbk-subst-all "''" "'" (caddr row)))
                  (vl-catch-all-apply 'MEDProcessSQLStatement
                    (list (strcat "UPDATE MEDType SET ITEMDESC=N'" q "' WHERE ITEMTYPE='" (car row) "' AND ITEMCODE=" (cadr row)
                                  " AND LTRIM(RTRIM(ITEMDESC))=''"))))
                (setq r (dbk-missing-codes))
                (dbk-say (strcat "DBSEED: sent " (itoa n) " INSERT(s) and " (itoa (length fill)) " UPDATE(s); ductbank codes still missing: "
                                 (if (listp r) (itoa (length r)) "?"))))))))))
  (princ))

(princ "\rMEDDuctbank loaded: DUCTBANK / DBEDIT (dialog), -DUCTBANK / -DBEDIT (command line), DBLIST DBDELETE DBSEED.")
(princ)
