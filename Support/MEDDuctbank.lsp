;;; MEDDuctbank.lsp - MED ductbank routing, first test build (MVP).
;;; Design: docs/design/ductbank-routing.md (Draft 2).
;;; Commands: DUCTBANK (build a bank from a routed reference: a MED conduit, or a plain
;;;           3D polyline / polyline / line route with elevation), DBEDIT (reopen a bank's
;;;           stored settings and rebuild it in place), DBLIST (list a bank), DBDELETE (erase a
;;;           bank, restore the reference), DBSEED (add the ductbank codes to MEDType).
;;;           -DUCTBANK / -DBEDIT are the command-line versions.
;;; DUCTBANK opens the MED-DotNet dialog (MED-DuctbankDialog); -DUCTBANK is the command-line
;;; flow (also the fallback when the DLL is not loaded). 2D plan + sections; the trunk follows the
;;; reference route's elevations (MVP4: gentle grade changes flex, steeper ones get vertical bends); the
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
(setq *DBK-VERSION* "2026-10-07 MVP4d")

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
(dbk-def '_DBKENCASE "Auto")       ; stub-up encasement turn-up top: "Auto" = top of the stub elbow sweep at 90 deg
                                   ; ends, the Top limit (just below the riser ends) at 45 deg ends (MVP4d, Clint),
                                   ; "Top" = the stub-up top EL (grade) less the riser projection, or an elevation
                                   ; (drawing units). The turn-up top is always cut level (parallel to grade) and
                                   ; kept _DBKRISERPROJ below the lowest point of the riser ends (MVP4c)
(dbk-def '_DBKRISERPROJ 4.0)       ; minimum stub-up riser projection above the level top of the concrete turn-up:
                                   ; clears a threaded RGS coupling (about 2-3.4" long, 2"-4") so the next fitting can
                                   ; be made up without chipping concrete; at a 45 deg end measured from the low edge
                                   ; of the slanted riser end (top EL - OD/2 x sin 45)
(dbk-def '_DBKLAYERTRANS 75)       ; transparency (%, 0-90) of the 3D model layer (3DMEDModel-Ductbank): set when the
                                   ; layer is created, or on a layer an earlier build left without transparency;
                                   ; a value already set on the layer is kept. 0 = leave the layer alone
(dbk-def '_DBKREFSIZE 4.0)         ; plain route reference (no MED data): default trade size
(dbk-def '_DBKBENDCONC "Chamfer")  ; concrete at bends: "Chamfer" = straight chamfers (plan bends, outside tangent
                                   ; to the cover arc, inside on its chord; turn-up on the chord of the stub
                                   ; elbow sweep), "Sweep" = concentric arcs that follow the elbows
(dbk-def '_DBKSTUBANGLE 90)        ; new banks: stub-up angle at each stub-up end, 90 or 45 (45 = 45 deg stub elbow and
                                   ; 45 deg riser, open end at the stub-up top EL; no fitting at the stub-up)
(dbk-def '_DBKFLEXMAX 5.0)         ; route grade changes up to this deflection (deg) are taken up by conduit flex (no
                                   ; fitting); larger ones get vertical bends at the nearest stock elbow angle
(dbk-def '_DBKFLEXLEN 120.0)       ; straight conduit wanted over a flex point (one 10 ft stick: half each side)
(dbk-def '_DBKFLEXRMIN 160.0)      ; PVC conduit longitudinal bend radius minimum, x OD (PW Eagle TB-D4 2005 / Hultec TB-D4:
                                   ; electrical conduit and utility duct 160 x OD); flagged when a flex point is tighter
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
;; PVC-coated RGS elbows by sweep and radius (MEDType FITTING, see DBSEED). 30 / 22.5 / 11.25 (MVP4)
;; are for vertical bends at route grade changes (and odd plan bends)
(setq *DBK-ELBOWS* '((90 (24.0 . 160) (36.0 . 161) (48.0 . 162))
                     (45 (24.0 . 163) (36.0 . 164) (48.0 . 165))
                     (30.0 (24.0 . 175) (36.0 . 176) (48.0 . 177))
                     (22.5 (24.0 . 178) (36.0 . 179) (48.0 . 180))
                     (11.25 (24.0 . 181) (36.0 . 182) (48.0 . 183))))
(setq *DBK-STOCKANG* '(11.25 22.5 30.0 45.0 90.0))   ; stock elbow sweeps (deg)
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
(setq *DBK-CODES* '(160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183) i 571)
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
  (cond ((numberp v) (strcat "EL " (dbk-encstr v))) ((= v "Top") "Top = stub-up top EL less the riser projection") (T "Auto = elbow sweep top at 90 deg ends, just below the riser ends at 45 deg ends")))
(defun dbk-chamfer-p () (not (wcmatch (strcase (vl-princ-to-string _DBKBENDCONC)) "S*")))
(defun dbk-bendstr () (if (dbk-chamfer-p) "Chamfer" "Sweep"))
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
(defun dbk-stock-angle (deg / best)   ; nearest stock elbow sweep (deg)
  (foreach a *DBK-STOCKANG* (if (or (null best) (< (abs (- a deg)) (abs (- best deg)))) (setq best a)))
  best)
(defun dbk-elbow-code (deg r / tb)
  (setq tb (cdr (assoc (if (< (abs (- deg 45.0)) 0.5) 45 (if (< (abs (- deg 90.0)) 0.5) 90 (dbk-stock-angle deg))) *DBK-ELBOWS*)))
  (if (null tb) (setq tb (cdr (assoc 90 *DBK-ELBOWS*))))
  (cond ((cdr (assoc r tb))) (T (cdr (last tb)))))
;; stub elbow code by sweep (90 or 45), radius and stub material (1 plain RGS, else PVC-coated RGS)
(defun dbk-stub-elbow-code (r mat / tb ang)
  (setq ang (if (= *DBK-STUBANG* 45) 45 90))
  (if (= mat 1)
    (progn (setq tb (cdr (assoc ang *DBK-ELBOWS-RGS*))) (cond ((cdr (assoc r tb))) (T (cdr (last tb)))))
    (dbk-elbow-code (float ang) r)))
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
;;; Returns (corners2D zStart topA topB (type nArcs) profile) or a string (error). profile = ((s z) ...):
;;; the route's elevation by plan station s (every vertex kept, grade breaks on straight plan runs too).
(defun dbk-ref-geom (ent / ed typ n i pts buls e2 v nar lines corners z topA topB ok a b c out p3s prof)
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
      (setq z (caddr (car pts)) p3s pts)
      (cond
        ((< (length pts) 2) "no horizontal run found on the reference conduit")
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
              ;; profile: every 3D vertex projected on the plan path (station), in route order
              (setq prof nil)
              (foreach p p3s
                (setq a (dbk-proj-s (dbk-xy p) corners))
                (if (and prof (< a (car (car prof)))) (setq a (car (car prof))))
                (setq prof (cons (list a (caddr p)) prof)))
              (list corners z topA topB (list typ nar) (reverse prof)))))))))
;; plan station of the point on the polyline pts (2D) nearest to q
(defun dbk-proj-s (q pts / cum best bs a b d l t1 pp dd)
  (setq cum 0.0)
  (while (cdr pts)
    (setq a (car pts) b (cadr pts) d (dbk-v- b a) l (dbk-len d))
    (if (> l 1e-9)
      (progn
        (setq t1 (max 0.0 (min 1.0 (/ (dbk-dot (dbk-v- q a) d) (* l l)))) pp (dbk-v+ a (dbk-v* d t1)) dd (distance q pp))
        (if (or (null best) (< dd (- best 1e-9))) (setq best dd bs (+ cum (* t1 l))))))
    (setq cum (+ cum l) pts (cdr pts)))
  (if bs bs 0.0))

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

;;; ------------------------------------------------------------------ route profile (MVP4)
;;; The reference route's elevation by plan station: PV = ((s z) ...). Interior vertices are
;;; grade changes; each is classified by its deflection: up to _DBKFLEXMAX the conduits just flex
;;; (a sloped run, no fitting), above it vertical bends at the nearest stock elbow angle (nested
;;; rule per column). Plan bends are kept level: a grade change at or near a plan bend is moved to
;;; the ends of a level landing through the bend. Sections stay perpendicular to the run: on a
;;; slope a position sits at its offset d (its flat-trunk height above the reference) measured
;;; square to the run, so the vertical bends nest like plan bends in the (s, z) plane.
(defun dbk-pang (a b) (atan (- (cadr b) (cadr a)) (- (car b) (car a))))
(defun dbk-prof-z (prof s / a b r)
  (cond
    ((null (cdr prof)) (cadr (car prof)))
    (T
      (setq a (car prof) b (cadr prof))
      (while (and (cddr prof) (> s (car (cadr prof))))
        (setq prof (cdr prof) a (car prof) b (cadr prof)))
      (if (< (abs (- (car b) (car a))) 1e-9) (cadr b)
        (+ (cadr a) (* (- s (car a)) (/ (- (cadr b) (cadr a)) (- (car b) (car a)))))))))
;; slope angle (radians) of the profile segment containing s (the later one at a vertex)
(defun dbk-prof-alpha (prof s / r)
  (while (and (cddr prof) (>= s (- (car (cadr prof)) 1e-6))) (setq prof (cdr prof)))
  (if (cdr prof) (dbk-pang (car prof) (cadr prof)) 0.0))
(defun dbk-dz (s) (if *DBK-PV* (- (dbk-prof-z *DBK-PV* s) (dbk-get *DBK* "ZREF")) 0.0))
(defun dbk-level-p () (or (null *DBK-PV*) (vl-every '(lambda (q) (< (abs (- (cadr q) (cadr (car *DBK-PV*)))) 1e-6)) *DBK-PV*)))
;; drop repeats, clamp to [0 len], merge collinear points (< 0.01 deg)
(defun dbk-prof-clean (prof len / out a b c)
  (foreach q prof
    (if (not (and out (< (abs (- (car q) (car (car out)))) 1e-4) (< (abs (- (cadr q) (cadr (car out)))) 1e-4)))
      (setq out (cons (list (float (car q)) (float (cadr q))) out))))
  (setq out (reverse out))
  (if (null out) (setq out (list (list 0.0 0.0))))
  (setq out (cons (list 0.0 (cadr (car out))) (cdr out)))
  (if (cdr out) (setq out (append (reverse (cdr (reverse out))) (list (list len (cadr (last out))))))
                (setq out (list (car out) (list len (cadr (car out))))))
  (setq a nil c out out nil)
  (foreach q c
    (if (and (cdr out) (< (abs (- (dbk-pang (cadr out) (car out)) (dbk-pang (car out) q))) 1.75e-4))
      (setq out (cons q (cdr out)))
      (setq out (cons q out))))
  (reverse out))
;; level landing over [sa sb] at the elevation of station sc (plan bend zones); returns (prof moved?)
(defun dbk-prof-land (prof sa sb sc / zc lvl out)
  (setq zc (dbk-prof-z prof sc) lvl T)
  (foreach s (append (list sa sb) (mapcar 'car (vl-remove-if-not '(lambda (q) (and (> (car q) sa) (< (car q) sb))) prof)))
    (if (> (abs (- (dbk-prof-z prof s) zc)) 0.001) (setq lvl nil)))
  (if lvl (list prof nil)
    (progn
      (foreach q prof (if (< (car q) (- sa 1e-6)) (setq out (cons q out))))
      (setq out (cons (list sa zc) out) out (cons (list sb zc) out))
      (foreach q prof (if (> (car q) (+ sb 1e-6)) (setq out (cons q out))))
      (list (reverse out) T))))
;; interior vertices: (k s z dIn dOut delta) delta > 0 = the grade turns up (sag, bend centre above)
(defun dbk-prof-vertices (prof / k out a b c)
  (setq k 1)
  (while (cddr prof)
    (setq a (car prof) b (cadr prof) c (caddr prof))
    (setq out (cons (list k (car b) (cadr b) (dbk-pang a b) (dbk-pang b c) (- (dbk-pang b c) (dbk-pang a b))) out)
          prof (cdr prof) k (1+ k)))
  (reverse out))
(defun dbk-2u (a) (list (cos a) (sin a)))
(defun dbk-2n (a) (list (- (sin a)) (cos a)))
;; per position node list in (s z): ("P" pt) start / flex / end points, ("A" tin tout ctr R delta k stock)
(defun dbk-prof-nodes (p prof vx / d nodes v tin tout ni no m vv r tt ctr)
  (setq d (- (dbk-get p "ZC") (dbk-get *DBK* "ZREF")))
  (setq nodes (list (list "P" (dbk-v+ (car prof) (dbk-v* (dbk-2n (dbk-pang (car prof) (cadr prof))) d)))))
  (foreach v vx
    (setq ni (dbk-2n (nth 3 v)) no (dbk-2n (nth 4 v))
          m (dbk-v* (dbk-v+ ni no) (/ 1.0 (max 1e-9 (+ 1.0 (dbk-dot ni no)))))
          vv (dbk-v+ (list (nth 1 v) (nth 2 v)) (dbk-v* m d)))
    (if (= (nth 6 v) "BEND")
      (progn
        (setq r (nth (1- (nth 9 v)) (dbk-get p "VR")) tt (* r (dbk-tan (/ (abs (nth 5 v)) 2.0)))
              tin (dbk-v- vv (dbk-v* (dbk-2u (nth 3 v)) tt)) tout (dbk-v+ vv (dbk-v* (dbk-2u (nth 4 v)) tt))
              ctr (dbk-v+ tin (dbk-v* ni (* r (if (> (nth 5 v) 0.0) 1.0 -1.0)))))
        (setq nodes (cons (list "A" tin tout ctr r (nth 5 v) (nth 9 v) (nth 7 v)) nodes)))
      (setq nodes (cons (list "P" vv) nodes))))
  (setq nodes (cons (list "P" (dbk-v+ (last prof) (dbk-v* (dbk-2n (dbk-pang (cadr (reverse prof)) (last prof))) d))) nodes))
  (reverse nodes))
;; the node points as a polyline (arcs by their tangent points)
(defun dbk-node-pts (nodes / out)
  (foreach n nodes (if (= (car n) "P") (setq out (cons (cadr n) out)) (setq out (cons (caddr n) (cons (cadr n) out)))))
  (reverse out))
;; position p elevation at plan station s (outside its vertical bends)
(defun dbk-pz (p s) (if (dbk-get p "PN") (dbk-prof-z (dbk-node-pts (dbk-get p "PN")) s) (dbk-get p "ZC")))
;; solve step (dynamic scope: pl flags errs of dbk-solve): returns (PV VX); sets PN / VR on every position
(defun dbk-profile-solve (zones len lt sza szb stuba stubb / prof raw moved res vx k lst prev r ci col n v st a ang
                                                             maxod out rule lens zone ok s nb nf iv ivs x)
  (setq raw (dbk-get *DBK* "PROF") maxod (dbk-max (mapcar '(lambda (p) (dbk-get p "OD")) pl)))
  (setq prof (dbk-prof-clean (if raw raw (list (list 0.0 (dbk-get *DBK* "ZREF")))) len))
  ;; level landings through the plan bends
  (setq ci 1)
  (foreach z zones
    (setq res (dbk-prof-land prof (car z) (cadr z) (caddr z)))
    (if (cadr res)
      (setq flags (cons (strcat "Plan bend " (itoa ci) ": the route grade is held level through the bend (EL "
                                (dbk-r2 (dbk-prof-z prof (caddr z))) ", stations " (rtos (/ (car z) 12.0) 2 1) "' to "
                                (rtos (/ (cadr z) 12.0) 2 1) "'); the grade changes move to the landing ends.") flags)
            prof (car res)))
    (setq ci (1+ ci)))
  (setq prof (dbk-prof-clean prof len))
  (foreach q (dbk-prof-vertices prof)
    (if (> (abs (dbk-deg (nth 5 q))) 80.0) (setq errs (cons (strcat "Route grade change at " (rtos (/ (nth 1 q) 12.0) 2 1) "' is steeper than 80 deg: not supported.") errs))))
  (setq a (car prof))
  (foreach q (cdr prof)
    (if (> (abs (dbk-deg (dbk-pang a q))) 80.0) (setq errs (cons (strcat "Route segment at " (rtos (/ (car a) 12.0) 2 1) "' is steeper than 80 deg (vertical drops are not supported).") errs)))
    (setq a q))
  ;; classify: (k s z dIn dOut delta kind stock residual bendIndex)
  (setq nb 0 nf 0)
  (setq vx (mapcar '(lambda (q / dg st)
                      (setq dg (abs (dbk-deg (nth 5 q))))
                      (if (<= dg (+ _DBKFLEXMAX 1e-6))
                        (progn (setq nf (1+ nf)) (append q (list "FLEX" nil nil nil)))
                        (progn (setq nb (1+ nb) st (dbk-stock-angle dg)) (append q (list "BEND" st (- dg st) nb)))))
                   (dbk-prof-vertices prof)))
  ;; vertical bend radii, per bend and column from the outside of the bend inward (nested rule)
  (setq pl (mapcar '(lambda (p) (dbk-put p "VR" nil)) pl))
  (foreach v vx
    (if (= (nth 6 v) "BEND")
      (progn
        (setq col 1)
        (repeat (dbk-max (dbk-get *DBK* "COUNTS"))
          (setq lst (vl-sort (vl-remove-if-not '(lambda (p) (= (dbk-get p "COL") col)) pl)
                             (if (> (nth 5 v) 0.0) '(lambda (a b) (< (dbk-get a "ZC") (dbk-get b "ZC"))) '(lambda (a b) (> (dbk-get a "ZC") (dbk-get b "ZC")))))
                prev nil)
          (foreach p lst
            (setq rule (dbk-rule (dbk-get p "SIZE")) r rule)
            (if prev (setq r (max r (- (dbk-get prev "VRTMP") (abs (- (dbk-get prev "ZC") (dbk-get p "ZC")))))))
            (setq r (dbk-roundstock r))
            (if (> r rule) (setq flags (cons (strcat (dbk-get p "POS") " vertical bend " (itoa (nth 9 v)) " raised to R" (rtos r 2 0)
                                                     " (nested rule).") flags)))
            (setq p (dbk-put (dbk-put p "VRTMP" r) "VR" (append (dbk-get p "VR") (list r))) prev p pl (dbk-replpos pl p)))
          (setq col (1+ col)))
        (if (> (abs (nth 8 v)) 0.05)
          (setq flags (cons (strcat "Vertical bend " (itoa (nth 9 v)) " at " (rtos (/ (nth 1 v) 12.0) 2 1) "': drawn "
                                    (dbk-r2 (abs (dbk-deg (nth 5 v)))) " deg, stock " (dbk-r2 (nth 7 v)) " deg elbows in the BOM ("
                                    (dbk-r2 (abs (nth 8 v))) " deg "
                                    (if (<= (abs (nth 8 v)) _DBKFLEXMAX) "taken up by conduit flex)." "exceeds the flex limit: set the route grade to a stock angle).")) flags))))))
  ;; nodes per position
  (setq pl (mapcar '(lambda (p) (dbk-put p "PN" (dbk-prof-nodes p prof vx))) pl))
  ;; fit: vertical bends against each other, the plan bend zones and the stub zones + transitions
  (foreach p pl
    (setq ivs (list (list -1e6 0.0 "the end A of the route") (list len (+ len 1e6) "the end B of the route")))
    (if stuba (setq ivs (cons (list 0.0 (+ sza lt) "the end A stub zone + transition") ivs)))
    (if stubb (setq ivs (cons (list (- len szb lt) len "the end B stub zone + transition") ivs)))
    (setq ci 0)
    (foreach cr (dbk-get p "CRN")
      (setq ivs (cons (list (+ (nth 5 (nth ci *DBK-SEGS*)) (nth 3 cr)) (+ (nth 5 (nth (1+ ci) *DBK-SEGS*)) (nth 4 cr))
                            (strcat "plan bend " (itoa (1+ ci)))) ivs) ci (1+ ci)))
    (setq prev nil)
    (foreach nd (cdr (reverse (cdr (reverse (dbk-get p "PN")))))
      (if (= (car nd) "A")
        (progn
          (setq iv (list (car (cadr nd)) (car (caddr nd))) x (strcat "Vertical bend " (itoa (nth 6 nd))))
          (if (and prev (< (car iv) (- prev 1e-6)))
            (setq errs (cons (strcat x " overlaps the grade change before it (" (dbk-get p "POS") " short by " (dbk-r2 (- prev (car iv))) "\"): spread the grade changes out.") errs)))
          (foreach z ivs
            (if (and (< (car iv) (- (cadr z) 1e-6)) (> (cadr iv) (+ (car z) 1e-6)))
              (setq errs (cons (strcat x " (" (dbk-get p "POS") ", stations " (rtos (/ (car iv) 12.0) 2 1) "'-" (rtos (/ (cadr iv) 12.0) 2 1)
                                       "') runs into " (caddr z) ": move the grade change.") errs))))
          (setq prev (cadr iv)))
        (progn
          (setq s (car (cadr nd)))
          (foreach z ivs
            (if (and (wcmatch (caddr z) "*stub*") (> s (+ (car z) 1e-6)) (< s (- (cadr z) 1e-6)))
              (setq errs (cons (strcat "Grade change at " (rtos (/ s 12.0) 2 1) "' is inside " (caddr z) ": the stub-up ends must be level.") errs))))
          (if (and prev (< s (- prev 1e-6))) (setq errs (cons (strcat "Grade change at " (rtos (/ s 12.0) 2 1) "' overlaps a vertical bend.") errs)))
          (setq prev s)))))
  ;; flex points: straight conduit each side, implied radius vs the PVC minimum
  (setq k 0)
  (foreach v vx
    (if (= (nth 6 v) "FLEX")
      (progn
        (setq a (nth (1- (nth 0 v)) prof) st (nth (nth 0 v) prof) x (nth (1+ (nth 0 v)) prof))
        (if (< (min (distance a st) (distance st x)) (- (/ _DBKFLEXLEN 2.0) 1e-6))
          (setq flags (cons (strcat "Flex point at " (rtos (/ (nth 1 v) 12.0) 2 1) "' (" (dbk-r2 (abs (dbk-deg (nth 5 v))))
                                    " deg): less than " (dbk-r2 (/ _DBKFLEXLEN 2.0)) "\" of straight run on one side (wanted to spread the flex over "
                                    (dbk-r2 _DBKFLEXLEN) "\").") flags)))
        (if (> (abs (nth 5 v)) 1e-9)
          (if (< (/ _DBKFLEXLEN (abs (nth 5 v))) (- (* _DBKFLEXRMIN maxod) 1e-6))
            (setq flags (cons (strcat "Flex point at " (rtos (/ (nth 1 v) 12.0) 2 1) "': " (dbk-r2 (abs (dbk-deg (nth 5 v)))) " deg over "
                                      (dbk-r2 _DBKFLEXLEN) "\" is a " (rtos (/ (/ _DBKFLEXLEN (abs (nth 5 v))) 12.0) 2 1) "' radius, tighter than "
                                      (rtos _DBKFLEXRMIN 2 0) " x OD (" (rtos (/ (* _DBKFLEXRMIN maxod) 12.0) 2 1) "') for the largest conduit.") flags)))))))
  (list prof vx))
;; route profile summary lines (dialog Envelope panel, print grid, DBLIST)
(defun dbk-prof-summary ( / pv vx out a k v j dg)
  (setq pv (dbk-get *DBKS* "PV") vx (dbk-get *DBKS* "VX"))
  (cond
    ((null pv) nil)
    ((dbk-level-p) (list (strcat "Route profile: level (EL " (dbk-r2 (cadr (car pv))) ")")))
    (T
      (setq out (list (strcat "Route profile: " (itoa (1- (length pv))) " segment(s), "
                              (itoa (length (vl-remove-if-not '(lambda (v) (= (nth 6 v) "FLEX")) vx))) " flex, "
                              (itoa (length (vl-remove-if-not '(lambda (v) (= (nth 6 v) "BEND")) vx))) " vertical bend(s), end B "
                              (dbk-r2 (- (cadr (last pv)) (cadr (car pv)))) "\"")))
      (setq a (car pv) j 0)
      (foreach q (cdr pv)
        (setq dg (dbk-deg (dbk-pang a q)))
        (setq out (cons (strcat " " (rtos (/ (car a) 12.0) 2 1) "-" (rtos (/ (car q) 12.0) 2 1) "' "
                                (if (< (abs dg) 0.005) (strcat "flat EL " (dbk-r2 (cadr a)))
                                  (strcat "slope " (if (> dg 0) "+" "") (dbk-r2 dg) " deg (EL " (dbk-r2 (cadr a)) " to " (dbk-r2 (cadr q)) ")")))
                        out))
        (if (setq v (nth j vx))
          (setq out (cons (strcat "  @" (rtos (/ (nth 1 v) 12.0) 2 1) "' " (if (= (nth 6 v) "FLEX") "flex " "bend ")
                                  (dbk-r2 (abs (dbk-deg (nth 5 v)))) " deg " (if (> (nth 5 v) 0) "up" "down")
                                  (if (= (nth 6 v) "BEND")
                                    (strcat " -> " (dbk-r2 (nth 7 v)) " deg stock, R"
                                            (vl-string-right-trim " " (dbk-joinnum (dbk-uniq (mapcar '(lambda (p) (nth (1- (nth 9 v)) (dbk-get p "VR"))) (dbk-get *DBK* "PL"))))))
                                    " (no fitting)"))
                          out)))
        (setq a q j (1+ j)))
      (reverse out))))

;;; ------------------------------------------------------------------ generation helpers (MVP4)
;; insert a vertex at plan station s into the position's plan vertex list (pt2d bulge corner station tag),
;; on the straight piece around s (the point by station between its two vertices)
(defun dbk-vins (v s tag / out done a b f)
  (while v
    (setq a (car v) b (cadr v))
    (setq out (cons a out))
    (if (and (not done) b (>= s (- (nth 3 a) 1e-9)) (< s (- (nth 3 b) -1e-9)))
      (progn
        (setq f (if (> (- (nth 3 b) (nth 3 a)) 1e-9) (/ (- s (nth 3 a)) (- (nth 3 b) (nth 3 a))) 0.0))
        (setq out (cons (list (dbk-v+ (car a) (dbk-v* (dbk-v- (car b) (car a)) f)) 0.0 nil s tag) out) done T)))
    (setq v (cdr v)))
  (reverse out))
;; conduit run: LWPOLYLINE when level (as before), 3D polyline when it follows a grade
(defun dbk-mk-run (layer pts xds lt / z flat)
  (setq z (caddr (car pts)) flat T)
  (foreach q pts (if (> (abs (- (caddr q) z)) 1e-6) (setq flat nil)))
  (if flat
    (dbk-mk-lw layer (mapcar 'dbk-xy pts) (mapcar '(lambda (x) 0.0) pts) z '(0.0 0.0 1.0) nil xds lt)
    (dbk-mk-3dp layer pts xds lt)))
;; plan end face of the envelope at a stub-up end (station from that end)
(defun dbk-end-face (end)
  (setq *DBK-TUEND* end *DBK-TUDZ* (if (= end "B") (cond ((dbk-get *DBKS* "DZB")) (0.0)) 0.0)
        *DBK-TUZ* (cond ((dbk-get *DBKS* (strcat "ENCZ" end))) (T (+ (dbk-get *DBKS* "TOP") *DBK-TUDZ*))))
  (dbk-tu-face))

;;; ------------------------------------------------------------------ solve
;;; Fills *DBKS* (results) and computed keys on each position. Pure geometry, nothing drawn.
;;; Lateral frame: + = right looking from end A along the run. Columns are numbered left to
;;; right looking from the section end (sgn = -1 when that is end B).
(defun dbk-solve ( / pl rows counts sgn sx sy refp tierref maxsize maxod part pitchh pitchv seatbot
                     partsz partod errs flags tier od h red zsref zs lt crn segs n corners k i s
                     col prev r rv rp lst ci th m coff tt tin tout s_in sout gstub griser stuba stubb sza szb
                     topa topb used gap lext rext lsa rsa top bot zone portions a b stations nst
                     sp len gl gr covl covr ang cnt prot pieces strap reds d ench sweep enca encb
                     anga angb dzb sweepa sweepb zones res pv vx vbz hw)
  (setq pl (dbk-get *DBK* "PL") rows (dbk-get *DBK* "ROWS") counts (dbk-get *DBK* "COUNTS")
        sgn (if (= (dbk-get *DBK* "SECTEND") "B") -1.0 1.0)
        sx (dbk-get *DBK* "SX") sy (dbk-get *DBK* "SY")
        stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        topa (dbk-get *DBK* "TOPA") topb (dbk-get *DBK* "TOPB")
        anga (dbk-stubang (dbk-get *DBK* "ANGA")) angb (dbk-stubang (dbk-get *DBK* "ANGB"))
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
  ;; route profile: end B elevation offset first (stub zones), then the full classification
  (setq len (+ (nth 5 (last segs)) (nth 4 (last segs))))
  (setq dzb (- (dbk-prof-z (dbk-prof-clean (cond ((dbk-get *DBK* "PROF")) ((list (list 0.0 (dbk-get *DBK* "ZREF"))))) len) len)
               (dbk-get *DBK* "ZREF")))
  ;; stub zones (station from the end where every stub elbow is done + straight); a 45 deg stub
  ;; rises on a 45 deg riser from the elbow to the stub-up top at its along offset
  (setq pl (mapcar '(lambda (p) (dbk-put (dbk-put p "SEA" (dbk-stub-se p anga topa 0.0)) "SEB" (dbk-stub-se p angb topb dzb))) pl))
  (setq sza (if stuba (+ (dbk-max (mapcar '(lambda (p) (dbk-get p "SEA")) pl)) _DBKSTUBSTRAIGHT) 0.0)
        szb (if stubb (+ (dbk-max (mapcar '(lambda (p) (dbk-get p "SEB")) pl)) _DBKSTUBSTRAIGHT) 0.0))
  ;; plan bend zones held level: tangent extents and the envelope corner, + 6"
  (setq hw (+ (dbk-max (mapcar '(lambda (p) (+ (abs (dbk-get p "RELT")) (/ (dbk-get p "OD") 2.0))) pl)) (max covl covr) 2.0) ci 0 zones nil)
  (foreach c corners
    (setq a (* hw (+ 1.0 (dbk-tan (/ (nth 5 c) 2.0)))) b (nth 5 (nth (1+ ci) segs)))
    (setq zones (cons (list (- (min (- b a) (+ (nth 5 (nth ci segs)) (dbk-min (mapcar '(lambda (p) (nth 3 (nth ci (dbk-get p "CRN")))) pl)))) 6.0)
                            (+ (max (+ b a) (+ b (dbk-max (mapcar '(lambda (p) (nth 4 (nth ci (dbk-get p "CRN")))) pl)))) 6.0)
                            b) zones) ci (1+ ci)))
  (setq res (dbk-profile-solve (reverse zones) len lt sza szb stuba stubb) pv (car res) vx (cadr res))
  (setq *DBK-PV* pv dzb (- (dbk-prof-z pv len) (dbk-get *DBK* "ZREF")))
  ;; vertical bend zones (all positions), excluded from spacer stations
  (setq vbz nil)
  (foreach v vx
    (if (= (nth 6 v) "BEND")
      (setq vbz (cons (list (dbk-min (mapcar '(lambda (p) (car (cadr (car (vl-remove-if-not '(lambda (n) (and (= (car n) "A") (= (nth 6 n) (nth 9 v)))) (dbk-get p "PN")))))) pl))
                            (dbk-max (mapcar '(lambda (p) (car (caddr (car (vl-remove-if-not '(lambda (n) (and (= (car n) "A") (= (nth 6 n) (nth 9 v)))) (dbk-get p "PN")))))) pl)))
                      vbz))))
  (setq vbz (reverse vbz))
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
    (if (and stuba (> (dbk-stub-sweep p anga 0.0) (+ topa 1e-6)))
      (setq errs (cons (strcat (dbk-get p "POS") ": R" (rtos (dbk-get p "RV") 2 0)
                               " stub elbow does not fit below the end A stub-up top.") errs)))
    (if (and stubb (> (dbk-stub-sweep p angb dzb) (+ topb 1e-6)))
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
  ;; 45 deg stub-ups: clearance between the 45 deg risers of adjacent rows
  (foreach e (list (list "A" stuba anga) (list "B" stubb angb))
    (if (and (cadr e) (= (caddr e) 45))
      (progn
        (setq griser nil)
        (foreach p pl
          (foreach q pl
            (if (and (= (dbk-get p "COL") (dbk-get q "COL")) (= (dbk-get q "TIER") (1+ (dbk-get p "TIER"))))
              (progn
                (setq gap (- (/ (abs (- (dbk-get q "ALONG") (dbk-get p "ALONG"))) (sqrt 2.0)) (/ (+ (dbk-get p "OD") (dbk-get q "OD")) 2.0)))
                (if (< gap (- _DBKMINGAP 0.005)) (setq griser (cons (list (strcat (dbk-get p "POS") "-" (dbk-get q "POS")) gap) griser)))))))
        (if griser
          (setq flags (cons (strcat "End " (car e) " 45 deg risers: clear gap " (dbk-r2 (apply 'min (mapcar 'cadr griser))) "\" < " (dbk-r2 _DBKMINGAP)
                                    "\" between rows (" (dbk-joinstr (reverse (mapcar 'car griser)) " ") "): the rows collide, increase the row pitch.") flags)))
        (setq flags (cons (strcat "End " (car e) ": 45 deg stub-ups: the risers end open at the stub-up top EL (no fitting).") flags)))))
  ;; stub spacing vs trunk spacing, taper
  (setq ang (dbk-max (mapcar '(lambda (p) (dbk-deg (atan (abs (- (dbk-get p "RELS") (dbk-get p "RELT"))) lt))) pl)))
  (if (and (or stuba stubb) (> (abs (- sx pitchh)) 0.005))
    (setq flags (cons (strcat "Stub-up pitch (center to center across) " (dbk-r2 sx) "\" kept at the stub-ups; the trunk uses the spacer pitch "
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
  (setq portions (reverse (cons (list a (- len (if stubb (+ szb lt) 0.0))) portions)))
  (foreach z vbz
    (setq portions (apply 'append (mapcar '(lambda (pr)
                                             (if (and (< (car z) (cadr pr)) (> (cadr z) (car pr)))
                                               (vl-remove-if '(lambda (q) (<= (cadr q) (+ (car q) 1e-6))) (list (list (car pr) (car z)) (list (cadr z) (cadr pr))))
                                               (list pr)))
                                          portions))))
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
  ;; stub-up encasement turn-up: top of concrete at the stub-ups (Auto = top of the highest stub elbow
  ;; sweep at a 90 deg end, the Top limit at a 45 deg end (MVP4d, Clint: the concrete runs up the 45 deg
  ;; risers to just below their ends); "Top" = stub-up top EL less the riser projection; or an elevation). The top is
  ;; a level cut (parallel to grade) that stays at least _DBKRISERPROJ below the lowest point of the
  ;; riser ends (45 deg end: the slanted riser end's low edge, top EL - OD/2 x sin 45; primary OD).
  (setq ench (dbk-encval (dbk-get *DBK* "ENCH"))
        sweepa (dbk-max (mapcar '(lambda (p) (dbk-stub-sweep p anga 0.0)) pl))
        sweepb (dbk-max (mapcar '(lambda (p) (dbk-stub-sweep p angb dzb)) pl))
        sweep (if (or stuba (not stubb)) sweepa sweepb))
  (defun dbk-enc-end (lbl topx sweep top ang / e emax rlow)
    (setq rlow (- topx (if (= ang 45) (* 0.5 (dbk-max (mapcar '(lambda (p) (dbk-get p "OD")) pl)) (sqrt 0.5)) 0.0))
          emax (- rlow (max 0.0 _DBKRISERPROJ)))
    (setq e (cond ((= ench "Top") emax) ((numberp ench) ench) ((= ang 45) emax) (T sweep)))
    (if (> e (+ emax 1e-6))
      (setq flags (cons (strcat "End " lbl ": stub-up encasement EL " (dbk-r2 e) " would leave the risers less than "
                                (dbk-r2 _DBKRISERPROJ) "\" above the concrete (riser ends at EL " (dbk-r2 rlow)
                                (if (= ang 45) ", low edge of the 45 deg cut" "") "): concrete cut level at EL " (dbk-r2 emax) ".") flags)
            e emax))
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
  (setq enca (if stuba (dbk-enc-end "A" topa sweepa top anga)) encb (if stubb (dbk-enc-end "B" topb sweepb (+ top dzb) angb)))
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
                     (cons "ANGA" anga) (cons "ANGB" angb) (cons "DZB" dzb) (cons "PV" pv) (cons "VX" vx) (cons "VBZ" vbz)
                     (cons "SWEEPA" sweepa) (cons "SWEEPB" sweepb)
                     (cons "ERRS" (reverse (dbk-uniq errs))) (cons "FLAGS" (reverse (dbk-uniq flags)))))
  *DBKS*)
;; stub angle value (90 / 45 or "90" / "45", nil = the _DBKSTUBANGLE default)
(defun dbk-stubang (v)
  (if (= (type v) 'STR) (setq v (atof v)))
  (if (not (numberp v)) (setq v _DBKSTUBANGLE))
  (if (< (abs (- v 45.0)) 1.0) 45 90))
;; station from the end where position p's stub elbow leaves the trunk (dz = trunk offset at that end)
(defun dbk-stub-se (p ang top dz / r zc)
  (setq r (dbk-get p "RV") zc (+ (dbk-get p "ZC") dz))
  (if (= ang 45)
    (+ (dbk-get p "ALONG") (* r (sin (/ pi 4.0))) (- top zc (* r (- 1.0 (cos (/ pi 4.0))))))
    (+ (dbk-get p "ALONG") r)))
;; elevation where the stub elbow ends (top of the elbow sweep)
(defun dbk-stub-sweep (p ang dz)
  (+ (dbk-get p "ZC") dz (* (dbk-get p "RV") (if (= ang 45) (- 1.0 (cos (/ pi 4.0))) 1.0))))

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
  (dbk-say (strcat "  Ends: A " (dbk-get *DBK* "ENDA") (if (and (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBKS* "ANGA") 45)) " 45" "")
                   ", B " (dbk-get *DBK* "ENDB") (if (and (= (dbk-get *DBK* "ENDB") "Stubup") (= (dbk-get *DBKS* "ANGB") 45)) " 45" "")
                   "   stub-up pitch " (dbk-r2 (dbk-get *DBK* "SX")) " across x " (dbk-r2 (dbk-get *DBK* "SY"))
                   " along   transition " (dbk-r2 _DBKTRANSL) "\" (max taper " (dbk-r2 (dbk-get *DBKS* "TAPER")) " deg)"))
  (dbk-say (strcat "  Envelope: trunk W x H = " (dbk-r2 (dbk-get *DBKS* "WT")) " x " (dbk-r2 (dbk-get *DBKS* "H"))
                   "   stub zone " (dbk-r2 (dbk-get *DBKS* "WS")) " x " (dbk-r2 (dbk-get *DBKS* "H"))
                   "   cover T" (rtos _DBKCOVERTOP 2 1) " B" (rtos _DBKCOVERBOT 2 1) " L" (rtos _DBKCOVERLEFT 2 1)
                   " R" (rtos _DBKCOVERRIGHT 2 1) "   top of concrete EL " (dbk-r2 (dbk-get *DBKS* "TOP"))))
  (dbk-say (strcat "  Elbows: stub-up R" (dbk-joinnum (dbk-uniq (mapcar '(lambda (p) (dbk-get p "RV")) pl)))
                   (if *DBK-CORNERS* (strcat "  plan R" (dbk-joinnum (dbk-uniq (apply 'append (mapcar '(lambda (p) (dbk-get p "RP")) pl))))
                                             "(" (itoa (length *DBK-CORNERS*)) " plan bend(s))") "")
                   "   concrete at bends: " (if (dbk-chamfer-p) "chamfered" "swept")))
  (if (or (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
    (dbk-say (strcat "  Stub-up encasement (" (dbk-enclabel (dbk-get *DBK* "ENCH")) "): concrete turn-up to EL"
                     (if (dbk-get *DBKS* "ENCZA") (strcat " " (dbk-r2 (dbk-get *DBKS* "ENCZA")) " at end A") "")
                     (if (dbk-get *DBKS* "ENCZB") (strcat " " (dbk-r2 (dbk-get *DBKS* "ENCZB")) " at end B") "")
                     ", elbow sweep top EL " (dbk-r2 (dbk-get *DBKS* "SWEEPTOP"))
                     "; level top, risers project at least " (dbk-r2 _DBKRISERPROJ) "\"")))
  (if part (dbk-say (strcat "  Spacer stations: " (itoa (length (dbk-get *DBKS* "STATIONS"))) " (max " (dbk-r2 _DBKSPINT)
                            "\" apart), per station " (itoa (dbk-get *DBKS* "PIECES")) " x " (car part) " + " (itoa (dbk-get *DBKS* "STRAPS"))
                            " x S28612 strap" (if (> (dbk-get *DBKS* "REDS") 0) (strcat " + " (itoa (dbk-get *DBKS* "REDS")) " reducer(s)") ""))))
  (foreach s (dbk-prof-summary) (dbk-say (strcat "  " s)))
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
;; arc of sweep ang (radians) in the vertical plane along the horizontal direction hdir (2D),
;; from p0 to p1 about ctr (3D points): vertical bends at route grade changes and 45 deg stub elbows
(defun dbk-mk-varc2 (layer p0 p1 ctr ang hdir xds ltype / nrm ho vo co b)
  (setq hdir (dbk-unit (list (car hdir) (cadr hdir))) nrm (list (cadr hdir) (- (car hdir)) 0.0))
  (setq ho (trans p0 0 nrm) vo (trans p1 0 nrm) co (trans ctr 0 nrm))
  (setq b (if (> (dbk-cross2 (dbk-v- (dbk-xy ho) (dbk-xy co)) (dbk-v- (dbk-xy vo) (dbk-xy co))) 0.0)
            (dbk-tan (/ (abs ang) 4.0)) (- (dbk-tan (/ (abs ang) 4.0)))))
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
;; ---- concrete at plan bends (_DBKBENDCONC)
(defun dbk-2d (p) (list (car p) (cadr p)))
(defun dbk-rot (v a) (list (- (* (car v) (cos a)) (* (cadr v) (sin a))) (+ (* (car v) (sin a)) (* (cadr v) (cos a)))))
;; cover points of position p's elbow at corner ci on one side: side = 1 outside (away from its
;; center), -1 inside; od = OD used for the cover (elbow OD or position OD); n samples
(defun dbk-bend-covpts (c ci p side od cov n / cr r tin o v0 sg k a v out)
  (setq cr (nth ci (dbk-get p "CRN")) r (nth 5 cr) tin (dbk-2d (nth 0 cr))
        o (dbk-v- tin (dbk-v* (dbk-2d (nth 3 c)) (* (nth 6 c) r))) v0 (dbk-v- tin o)
        sg (if (< (- (* (car (nth 1 c)) (cadr (nth 2 c))) (* (cadr (nth 1 c)) (car (nth 2 c)))) 0.0) -1.0 1.0) k 0)
  (if (> r 0.01)
    (repeat (1+ n)
      (setq a (* sg (nth 6 cr) (/ (float k) n)) v (dbk-rot v0 a)
            out (cons (dbk-v+ (dbk-v+ o v) (dbk-v* (dbk-unit v) (* side (+ (/ od 2.0) cov)))) out) k (1+ k))))
  out)
(defun dbk-elbow-od (p) (dbk-get p "OD"))   ; cover is sized off the primary conduit OD only (Clint, Oct 7)
;; chamfer for one side of corner ci: face square to the bisector (m points from the bank toward
;; that side's void) at the max of m over every position's cover points; returns (P1 P2), or the
;; sharp corner when it is enough
(defun dbk-bend-cut (c ci ext g / dl side cov m q qm cm v u1 u2 pts)
  (setq dl (- ext (dbk-get g "RELT")) side (if (> (* (nth 6 c) dl) 0.0) 1.0 -1.0)
        cov (- (abs dl) (/ (dbk-get g "OD") 2.0))
        m (dbk-v* (dbk-unit (dbk-2d (nth 7 c))) (if (> dl 0.0) 1.0 -1.0))
        q (dbk-2d (dbk-v+ (nth 0 c) (dbk-v* (nth 7 c) ext))) qm (dbk-dot q m))
  (foreach p (dbk-get *DBK* "PL")
    (foreach x (dbk-bend-covpts c ci p side (dbk-elbow-od p) cov 32)
      (setq v (dbk-dot x m)) (if (or (null cm) (> v cm)) (setq cm v))))
  (setq u1 (dbk-dot (dbk-2d (nth 1 c)) m) u2 (dbk-dot (dbk-2d (nth 2 c)) m))
  ;; outside: cut the convex corner when a cover point is short of it; inside: fill the reflex
  ;; corner out to the cover points when they reach past it (else the sharp corner is enough)
  (if (or (null cm) (if (> side 0.0) (<= qm cm) (>= qm cm)) (< (abs u1) 1e-9) (< (abs u2) 1e-9))
    (list q)
    (list (dbk-v+ q (dbk-v* (dbk-2d (nth 1 c)) (/ (- cm qm) u1))) (dbk-v+ q (dbk-v* (dbk-2d (nth 2 c)) (/ (- cm qm) u2))))))
;; Sweep: T when another position's elbow (position OD + cover) pokes out of the governing arc
(defun dbk-bend-poke (c ci ext g rr / dl side cov cr o u hit d)
  (setq dl (- ext (dbk-get g "RELT")) side (if (> (* (nth 6 c) dl) 0.0) 1.0 -1.0)
        cov (- (abs dl) (/ (dbk-get g "OD") 2.0)) cr (nth ci (dbk-get g "CRN"))
        o (dbk-v- (dbk-2d (nth 0 cr)) (dbk-v* (dbk-2d (nth 3 c)) (* (nth 6 c) (nth 5 cr)))))
  (setq u (dbk-unit (dbk-v- (dbk-v* (dbk-v+ (dbk-2d (nth 0 cr)) (dbk-2d (nth 1 cr))) 0.5) o)))
  (foreach p (dbk-get *DBK* "PL")
    (foreach x (dbk-bend-covpts c ci p side (dbk-get p "OD") cov 32)
      (setq d (dbk-len (dbk-v- x o)))
      (if (and (> d 1e-6) (>= (dbk-dot (dbk-v- x o) u) (- (* d (cos (/ (nth 5 c) 2.0))) 1e-6))
               (if (> side 0.0) (> d (+ rr 0.005)) (< d (- rr 0.005))))
        (setq hit T))))
  hit)
;; one side of the plan outline (start-based lateral ext), list of (pt2d bulge)
(defun dbk-side (ext exta extb g / out ci dl cr rr stuba stubb sza szb face t1 t2)
  (setq stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        sza (dbk-get *DBKS* "SZA") szb (dbk-get *DBKS* "SZB"))
  (if stuba
    (setq out (list (list (dbk-pa (dbk-end-face "A") exta) 0.0) (list (dbk-pa sza exta) 0.0) (list (dbk-pa (+ sza _DBKTRANSL) ext) 0.0)))
    (setq out (list (list (dbk-pa 0.0 ext) 0.0))))
  (setq ci 0)
  (foreach c *DBK-CORNERS*
    ;; the governing conduit's own elbow offset by its OD/2 + cover is the cover arc (radius rr).
    ;; Sweep: the concrete follows that arc. Chamfer (default): one straight face per side,
    ;; square to the bend bisector, pushed out just far enough that EVERY position's elbow keeps
    ;; its cover (dbk-bend-cut: max over all elbows, both tiers, own radius, sized off the primary
    ;; conduit OD only - no allowance for the elbow coating, Clint Oct 7). Outside of the bend that face is tangent to the outermost cover arc at
    ;; mid-bend; inside it is the chord through the cover arc ends (a square inside corner would cut
    ;; into the inner elbows: R24 3" bank ~3" short). Mixed radii (e.g. one 4" R36 among 3" R24)
    ;; are covered too. Sweep falls back to the chamfer on a side where another position's elbow
    ;; would poke out of the governing arc (mixed radii), with a note.
    (setq cr (nth ci (dbk-get g "CRN")) dl (- ext (dbk-get g "RELT")) rr (+ (nth 5 cr) (* (nth 6 c) dl)))
    (setq t1 (dbk-v+ (nth 0 cr) (dbk-v* (nth 3 c) dl)) t2 (dbk-v+ (nth 1 cr) (dbk-v* (nth 4 c) dl)))
    (cond
      ((<= rr 0.01) (setq out (append out (list (list (dbk-2d (dbk-v+ (nth 0 c) (dbk-v* (nth 7 c) ext))) 0.0)))))
      ((and (not (dbk-chamfer-p)) (not (dbk-bend-poke c ci ext g rr)))
        (setq out (append out (list (list t1 (nth 2 cr)) (list t2 0.0)))))
      (T
        (if (not (dbk-chamfer-p))
          (setq *DBK-BENDNOTES* (cons (strcat "Bend " (itoa (1+ ci)) " " (if (> (* (nth 6 c) dl) 0.0) "outside" "inside")
                                              ": mixed elbow radii poke out of the swept arc, chamfered there to keep cover.") *DBK-BENDNOTES*)))
        (setq out (append out (mapcar '(lambda (q) (list q 0.0)) (dbk-bend-cut c ci ext g))))))
    (setq ci (1+ ci)))
  (if stubb
    (setq out (append out (list (list (dbk-pb (+ szb _DBKTRANSL) ext) 0.0) (list (dbk-pb szb extb) 0.0) (list (dbk-pb (dbk-end-face "B") extb) 0.0))))
    (setq out (append out (list (list (dbk-pb 0.0 ext) 0.0)))))
  out)

(defun dbk-generate (secpt / pl bank conlay lt sgn stuba stubb sza szb segs topa topb p tag sz code od zc rels relt
                       along rv crn cur v e xdc sa ha hv ctr k ent part stations st pp center wdt codes sizes tags a
                       nsta env lsd rsd gl gr q cut x0 y0 sc ins ws vtx bnd clines nconds nelb nfit mat wrap ecode m3d
                       plain encz tupl ntu len ci kv nvb hd hv ang ze uo xd)
  (setq pl (dbk-get *DBK* "PL") bank (dbk-get *DBK* "BANK") part (dbk-get *DBKS* "PART")
        sgn (dbk-get *DBKS* "SGN") stuba (= (dbk-get *DBK* "ENDA") "Stubup") stubb (= (dbk-get *DBK* "ENDB") "Stubup")
        sza (dbk-get *DBKS* "SZA") szb (dbk-get *DBKS* "SZB") segs *DBK-SEGS*
        topa (dbk-get *DBK* "TOPA") topb (dbk-get *DBK* "TOPB")
        conlay (dbk-get *DBK* "REFLAYER") lt (if U_CON (dbk-ltype U_CON)) nconds 0 nelb 0 nfit 0
        *DBK-HANDLES* nil mat (if (= (dbk-get *DBK* "STUBCODE") 1) 1 2)
        wrap (and (= mat 1) (= (dbk-get *DBK* "WRAP") 1)) plain (dbk-get *DBK* "REFPLAIN") ntu 0
        len (dbk-get *DBKS* "LEN") nvb 0)
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
  ;; conduits: straight runs (LWPOLYLINE at the conduit centerline elevation when level, else a
  ;; 3D polyline following the route profile), plan elbows, vertical bends at route grade changes,
  ;; stub-up elbows (true vertical arcs, 90 or 45 deg) and risers (3D polylines like the reference)
  (foreach p pl
    (setq tag (dbk-tag p) sz (dbk-get p "SIZE") code (dbk-get p "CODE") od (dbk-get p "OD") zc (dbk-get p "ZC")
          rels (dbk-get p "RELS") relt (dbk-get p "RELT") along (dbk-get p "ALONG") rv (dbk-get p "RV")
          crn (dbk-get p "CRN"))
    (setq xdc (list (strcat "ROW=" (itoa (dbk-get p "ROW"))) (strcat "COL=" (itoa (dbk-get p "COL")))
                    (strcat "TIER=" (itoa (dbk-get p "TIER"))) (strcat "LAT=" (dbk-r4 (* sgn relt)))
                    (strcat "SEATZ=" (dbk-r4 (- (dbk-get p "ZS") (dbk-get *DBKS* "ZSREF"))))))
    ;; plan vertices (pt2d bulge corner station tag)
    (setq v nil ci 0)
    (if stuba
      (setq v (list (list (dbk-pa (dbk-get p "SEA") rels) 0.0 nil (dbk-get p "SEA")) (list (dbk-pa sza rels) 0.0 nil sza)
                    (list (dbk-pa (+ sza _DBKTRANSL) relt) 0.0 nil (+ sza _DBKTRANSL))))
      (setq v (list (list (dbk-pa 0.0 relt) 0.0 nil 0.0))))
    (foreach cr crn
      (setq v (append v (list (list (nth 0 cr) (nth 2 cr) cr (+ (nth 5 (nth ci segs)) (nth 3 cr)))
                              (list (nth 1 cr) 0.0 nil (+ (nth 5 (nth (1+ ci) segs)) (nth 4 cr)))))
            ci (1+ ci)))
    (if stubb
      (setq v (append v (list (list (dbk-pb (+ szb _DBKTRANSL) relt) 0.0 nil (- len szb _DBKTRANSL)) (list (dbk-pb szb rels) 0.0 nil (- len szb))
                              (list (dbk-pb (dbk-get p "SEB") rels) 0.0 nil (- len (dbk-get p "SEB"))))))
      (setq v (append v (list (list (dbk-pb 0.0 relt) 0.0 nil len)))))
    ;; route profile nodes between the plan vertices: flex points, vertical bend tangent points
    (foreach nd (cdr (reverse (cdr (reverse (dbk-get p "PN")))))
      (if (= (car nd) "P")
        (setq v (dbk-vins v (car (cadr nd)) nil))
        (setq v (dbk-vins (dbk-vins v (car (cadr nd)) (list "VIN" nd)) (car (caddr nd)) (list "VOUT" nd)))))
    (setq cur nil k 1 kv 0)
    (foreach it v
      (setq q (dbk-p3 (car it) (cond ((and (nth 4 it) (= (car (nth 4 it)) "VIN")) (cadr (cadr (cadr (nth 4 it)))))
                                     ((and (nth 4 it) (= (car (nth 4 it)) "VOUT")) (cadr (caddr (cadr (nth 4 it)))))
                                     (T (dbk-pz p (nth 3 it))))))
      (if (not (and cur (< (distance (dbk-xy q) (dbk-xy (last cur))) 1e-6))) (setq cur (append cur (list q))))
      (cond
        ((caddr it)
          (dbk-add (dbk-mk-run conlay cur (list (bld_conduit code sz tag nil "T") (dbk-xdpos "CONDUIT" bank p (append xdc (list (strcat "PART=RUN" (itoa k)))))) lt))
          (setq a (caddr it) nconds (1+ nconds))
          (dbk-add (dbk-mk-lw conlay (list (nth 0 a) (nth 1 a)) (list (nth 2 a) 0.0) (caddr q) '(0.0 0.0 1.0) nil
                              (list (dbk-elbow-xd (dbk-elbow-code (dbk-deg (nth 6 a)) (nth 5 a)) sz tag)
                                    (dbk-xdpos "ELBOW" bank p (list (strcat "PART=BEND" (itoa k)) (strcat "RAD=" (rtos (nth 5 a) 2 2))
                                                                    (strcat "ANG=" (rtos (dbk-deg (nth 6 a)) 2 2))
                                                                    (strcat "OD=" (dbk-r4 (dbk-od 2 sz))) "MAT=2"))) lt))
          (setq nelb (1+ nelb) nfit (+ nfit 3) cur (list (dbk-p3 (nth 1 a) (caddr q))) k (1+ k)))
        ((and (nth 4 it) (= (car (nth 4 it)) "VIN"))
          (dbk-add (dbk-mk-run conlay cur (list (bld_conduit code sz tag nil "T") (dbk-xdpos "CONDUIT" bank p (append xdc (list (strcat "PART=RUN" (itoa k)))))) lt))
          (setq a (cadr (nth 4 it)) nconds (1+ nconds) kv (1+ kv))
          ;; the tangent-out point: the next vertex (its plan point), the centre on the same straight piece
          (setq x (car (vl-member-if '(lambda (w) (and (nth 4 w) (= (car (nth 4 w)) "VOUT") (eq (cadr (nth 4 w)) a))) v)))
          (setq hd (dbk-unit (dbk-v- (car x) (car it))))
          (setq e (dbk-p3 (car x) (cadr (caddr a)))
                ctr (dbk-p3 (dbk-v+ (car it) (dbk-v* hd (- (car (nth 3 a)) (car (cadr a))))) (cadr (nth 3 a))))
          (dbk-add (dbk-mk-varc2 conlay q e ctr (nth 5 a) hd
                                 (list (dbk-elbow-xd (dbk-elbow-code (nth 7 a) (nth 4 a)) sz tag)
                                       (dbk-xdpos "ELBOW" bank p (list (strcat "PART=VBEND" (itoa (nth 6 a))) (strcat "RAD=" (rtos (nth 4 a) 2 2))
                                                                       (strcat "ANG=" (rtos (abs (dbk-deg (nth 5 a))) 2 2))
                                                                       (strcat "STOCK=" (rtos (nth 7 a) 2 2))
                                                                       (strcat "DIR=" (if (> (nth 5 a) 0.0) "UP" "DOWN"))
                                                                       (strcat "OD=" (dbk-r4 (dbk-od 2 sz))) "MAT=2"))) lt))
          (setq nelb (1+ nelb) nfit (+ nfit 3) nvb (1+ nvb) cur (list e) k (1+ k)))))
    (dbk-add (dbk-mk-run conlay cur (list (bld_conduit code sz tag nil "T") (dbk-xdpos "CONDUIT" bank p (append xdc (list (strcat "PART=RUN" (itoa k)))))) lt))
    (setq nconds (1+ nconds))
    (foreach end (list (if stuba "A") (if stubb "B"))
      (if end
        (progn
          (if (= end "A")
            (setq sa (dbk-pa along rels) ha (dbk-pa (dbk-get p "SEA") rels) q topa ang (dbk-get *DBKS* "ANGA") ze zc
                  uo (dbk-v* (nth 2 (car segs)) -1.0) x (dbk-pa (- (dbk-get p "SEA") (* rv (sin (/ pi 4.0)))) rels))
            (setq sa (dbk-pb along rels) ha (dbk-pb (dbk-get p "SEB") rels) q topb ang (dbk-get *DBKS* "ANGB") ze (+ zc (dbk-get *DBKS* "DZB"))
                  uo (nth 2 (last segs)) x (dbk-pb (- (dbk-get p "SEB") (* rv (sin (/ pi 4.0)))) rels)))
          (setq *DBK-STUBANG* ang ecode (dbk-stub-elbow-code rv mat) ctr (dbk-p3 ha (+ ze rv)))
          (setq xd (list (dbk-stub-elbow-xd ecode sz tag mat wrap)
                         (dbk-xdpos "ELBOW" bank p (list (strcat "PART=STUB" end) (strcat "RAD=" (rtos rv 2 2)) (if (= ang 45) "ANG=45.00" "ANG=90.00")
                                                         (strcat "OD=" (dbk-r4 (dbk-od mat sz))) (strcat "MAT=" (itoa mat))
                                                         (strcat "WRAP=" (if wrap "1" "0"))))))
          (if (= ang 45)
            (progn
              (setq hv (dbk-p3 x (+ ze (* rv (- 1.0 (cos (/ pi 4.0)))))))
              (dbk-add (dbk-mk-varc2 conlay (dbk-p3 ha ze) hv ctr (/ pi 4.0) uo xd lt)))
            (progn
              (setq hv (dbk-p3 sa (+ ze rv)))
              (dbk-add (dbk-mk-varc conlay (dbk-p3 ha ze) hv ctr xd lt))))
          (setq nelb (1+ nelb) nfit (+ nfit (if wrap 4 3)))
          (if (> (- q (caddr hv)) 0.01)
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
                              (strcat "CONCRETE TURN-UP, LEVEL TOP EL " (dbk-r2 encz))
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
                         '(2 . "DBSPACER") (cons 10 (dbk-p3 ins (+ (dbk-get *DBKS* "BOT") (dbk-dz st)))) (cons 41 wdt) '(42 . 1.0) '(43 . 1.0)
                         (cons 50 (angle '(0.0 0.0) (caddr pp)))
                         (list -3 (bld_fitting (reverse codes) (reverse sizes) (reverse tags)
                                               (mapcar '(lambda (x) 0.0) codes) (mapcar '(lambda (x) 0.0) codes) (mapcar '(lambda (x) 0.0) codes))
                               (dbk-xd (list "ROLE=SPACER" (strcat "BANK=" bank) (strcat "STATION=" (itoa nsta))
                                             (strcat "STA=" (dbk-r2 st)) (strcat "PART=" (car part)) "GEN=1")))))
        (dbk-add (entlast)))))
  ;; plan outline: right side forward + left side reversed (bulges negated)
  (setq gl (dbk-findpos pl (dbk-get *DBKS* "GL")) gr (dbk-findpos pl (dbk-get *DBKS* "GR")))
  (setq *DBK-BENDNOTES* nil)
  (setq rsd (dbk-side (dbk-get *DBKS* "REXT") (dbk-get *DBKS* "RSA") (dbk-get *DBKS* "RSA") gr)
        lsd (dbk-side (dbk-get *DBKS* "LEXT") (dbk-get *DBKS* "LSA") (dbk-get *DBKS* "LSA") gl))
  (foreach x (reverse *DBK-BENDNOTES*) (princ (strcat "\n  Note: " x)))
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
    (setq *DBK-SDZ* (if (= (caddr cl) "STUB") (if (= (dbk-get *DBK* "SECTEND") "B") (dbk-get *DBKS* "DZB") 0.0)
                      (dbk-dz (/ (+ (car a) (cadr a)) 2.0))))
    (setq cl (append cl (list *DBK-SDZ*)))
    (dbk-add (dbk-mk-line "MED_DBSECTION" (dbk-p3 (car (cadr cl)) (+ (dbk-get *DBKS* "TOP") *DBK-SDZ*)) (dbk-p3 (cadr (cadr cl)) (+ (dbk-get *DBKS* "TOP") *DBK-SDZ*))
                          (list (dbk-xd (list "ROLE=SECTIONCUT" (strcat "BANK=" bank) (strcat "SECTION=" (car cl)))))))
    (foreach pt (cadr cl)
      (dbk-add (dbk-mk-text "MED_DBTEXT" (dbk-p3 pt (+ (dbk-get *DBKS* "TOP") (nth 3 cl))) (* 2.0 _DBKPLANTEXT) (car cl) 0.0
                            (list (dbk-xd (list "ROLE=TEXT" (strcat "BANK=" bank))))))))
  (setq clines (mapcar '(lambda (cl) (if (= (caddr cl) "STUB") (append cl (list (if (= (dbk-get *DBK* "SECTEND") "B") (dbk-get *DBKS* "DZB") 0.0)))
                                         (append cl (list (dbk-dz (/ (+ (car a) (cadr a)) 2.0)))))) clines))
  (foreach cl clines
    (setq *DBK-SDZ* (nth 3 cl))
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
                      (strcat "REFPLAIN=" (if plain "1" "0")) (strcat "BENDCONC=" (dbk-bendstr))
                      (strcat "ANGA=" (itoa (dbk-get *DBKS* "ANGA"))) (strcat "ANGB=" (itoa (dbk-get *DBKS* "ANGB")))
                      (strcat "FLEXMAX=" (dbk-r4 _DBKFLEXMAX)) (strcat "FLEXLEN=" (dbk-r4 _DBKFLEXLEN))
                      (strcat "RISERPROJ=" (dbk-r4 _DBKRISERPROJ))
                      (strcat "PROFILE=" (if (dbk-level-p) "LEVEL" "GRADE")) (strcat "DZB=" (dbk-r4 (dbk-get *DBKS* "DZB")))
                      (strcat "VBENDS=" (itoa (length (vl-remove-if-not '(lambda (v) (= (nth 6 v) "BEND")) (dbk-get *DBKS* "VX")))))
                      (strcat "FLEXPTS=" (itoa (length (vl-remove-if-not '(lambda (v) (= (nth 6 v) "FLEX")) (dbk-get *DBKS* "VX"))))))
                (mapcar '(lambda (p) (strcat "P=" (dbk-bar (list (dbk-get p "POS") (vl-string-translate "|" "/" (dbk-tag p))
                                                                 (dbk-get p "SIZE") (dbk-get p "CODE") (if (dbk-get p "TAG") "C" "D")))))
                        pl)
                (mapcar '(lambda (h) (cons 1005 h)) (reverse *DBK-HANDLES*)))))
              nil))
  (list env (length *DBK-HANDLES*) nconds nelb nfit nsta m3d ntu nvb))

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
                                     (* sc 0.8 _DBKSECTTEXT) (strcat "CONCRETE TURN-UP BEYOND, LEVEL TOP EL " (dbk-r2 encz) " (RISERS PROJECT " (dbk-r2 _DBKRISERPROJ) "\" MIN)") xds) ents))))
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
                    "  TOP OF CONCRETE EL " (dbk-r2 (+ top (cond (*DBK-SDZ*) (0.0)))) (if encz (strcat " (TURN-UP EL " (dbk-r2 encz) ")") "") "  SCALE " (rtos sc 2 2) ":1"))
  (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (dbk-spx vl) (+ (dbk-spy ttop) (* sc 0.6 _DBKSECTTEXT)) 0.0) (* sc 0.8 _DBKSECTTEXT) sub xds) ents))
  (setq i 1)
  (foreach p (vl-sort pl '(lambda (a b) (< (dbk-get a "POS") (dbk-get b "POS"))))
    (setq ents (cons (dbk-mk-ltext "MED_DBTEXT" (list (dbk-spx vl) (- (dbk-spy bot) (* sc i 1.6 _DBKSECTTEXT)) 0.0) (* sc 0.8 _DBKSECTTEXT)
                                   (strcat (if (= (dbk-get p "POS") (dbk-get *DBK* "REFPOS")) "*" "") (dbk-get p "POS") "  " (dbk-tag p) "  "
                                           (dbk-sz (dbk-get p "SIZE")) " " (dbk-typeabbr (dbk-get p "CODE"))
                                           "  OD " (rtos (dbk-get p "OD") 2 3) "  CL EL " (dbk-r2 (+ (dbk-get p "ZC") (cond (*DBK-SDZ*) (0.0))))
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
;; profile plane points: WCS = o + m*lat + up*(z - zref), in the OCS of normal n (sloped spacer sections)
(defun dbk-ocs-pts2 (o m up n zref pts / w)
  (mapcar '(lambda (q / dz) (setq dz (- (cadr q) zref))
             (setq w (list (+ (car o) (* (car m) (car q)) (* (car up) dz)) (+ (cadr o) (* (cadr m) (car q)) (* (cadr up) dz))
                           (+ (caddr o) (* (caddr up) dz))))
             (trans w 0 n)) pts))
;; ---- sloped / stepped trunk envelope: (s z) offset of the route profile, chamfered at the vertical bends
;; cover points of every position's vertical bend k on one side (+1 top, -1 bottom), primary OD
(defun dbk-vbend-cut (k q ti to mv side cov / m qm cm nd c v0 v1 r sg n i a v u sig x u1 u2)
  (setq m (dbk-v* (dbk-unit mv) (float side)) qm (dbk-dot q m))
  (foreach p (dbk-get *DBK* "PL")
    (if (setq nd (car (vl-remove-if-not '(lambda (n) (and (= (car n) "A") (= (nth 6 n) k))) (dbk-get p "PN"))))
      (progn
        (setq c (nth 3 nd) r (nth 4 nd) v0 (dbk-v- (cadr nd) c) v1 (dbk-v- (caddr nd) c)
              sg (if (> (dbk-cross2 v0 v1) 0.0) 1.0 -1.0) n 24 i 0
              sig (if (> (* side (nth 5 nd)) 0.0) -1.0 1.0))
        (repeat (1+ n)
          (setq a (* sg (abs (nth 5 nd)) (/ (float i) n)) v (dbk-rot v0 a) u (dbk-unit v)
                x (dbk-v+ (dbk-v+ c v) (dbk-v* u (* sig (+ (/ (dbk-get p "OD") 2.0) cov)))))
          (setq x (dbk-dot x m))
          (if (or (null cm) (> x cm)) (setq cm x))
          (setq i (1+ i))))))
  (setq u1 (dbk-dot ti m) u2 (dbk-dot to m))
  ;; outside of the bend: cut when the corner is past the cover points; inside: fill when they reach past it
  (if (or (null cm) (< (abs u1) 1e-9) (< (abs u2) 1e-9) (< (abs (- cm qm)) 1e-6))
    (list q)
    (if (or (and (> qm cm) (dbk-vb-outside k side)) (and (< qm cm) (not (dbk-vb-outside k side))))
      (list (dbk-v+ q (dbk-v* ti (/ (- cm qm) u1))) (dbk-v+ q (dbk-v* to (/ (- cm qm) u2))))
      (list q))))
;; T when side (+1 top / -1 bottom) is the outside of vertical bend k (away from its centre)
(defun dbk-vb-outside (k side / v)
  (setq v (car (vl-remove-if-not '(lambda (x) (equal (nth 9 x) k)) (dbk-get *DBKS* "VX"))))
  (and v (< (* side (nth 5 v)) 0.0)))
;; offset chain of the profile at ext (top / bottom of concrete relative to the reference), extended e past the ends
(defun dbk-prof-chain (ext side cov e / pv vx out a b c ti to ni no mv q j v)
  (setq pv (dbk-get *DBKS* "PV") vx (dbk-get *DBKS* "VX"))
  (setq ti (dbk-2u (dbk-pang (car pv) (cadr pv))) a (dbk-v+ (car pv) (dbk-v* (dbk-2n (dbk-pang (car pv) (cadr pv))) ext)))
  (setq out (list a (dbk-v- a (dbk-v* ti e))) j 0)
  (setq c pv)
  (while (cddr c)
    (setq a (car c) b (cadr c) v (nth j vx)
          ti (dbk-2u (dbk-pang a b)) to (dbk-2u (dbk-pang b (caddr c))) ni (dbk-2n (dbk-pang a b)) no (dbk-2n (dbk-pang b (caddr c)))
          mv (dbk-v* (dbk-v+ ni no) (/ 1.0 (max 1e-9 (+ 1.0 (dbk-dot ni no))))) q (dbk-v+ b (dbk-v* mv ext)))
    (foreach x (if (= (nth 6 v) "BEND") (dbk-vbend-cut (nth 9 v) q ti to mv side cov) (list q)) (setq out (cons x out)))
    (setq c (cdr c) j (1+ j)))
  (setq to (dbk-2u (dbk-pang (cadr (reverse pv)) (last pv))) a (dbk-v+ (last pv) (dbk-v* (dbk-2n (dbk-pang (cadr (reverse pv)) (last pv))) ext)))
  (setq out (cons (dbk-v+ a (dbk-v* to e)) (cons a out)))
  (reverse out))
;; Sutherland-Hodgman clip of a polygon ((s z) ...) to s >= lo (keep = 1) or s <= hi (keep = -1)
(defun dbk-clip-s (poly x keep / out n i a b ina inb f)
  (setq n (length poly) i 0)
  (repeat n
    (setq a (nth i poly) b (nth (rem (1+ i) n) poly)
          ina (>= (* keep (- (car a) x)) 0.0) inb (>= (* keep (- (car b) x)) 0.0))
    (if ina (setq out (cons a out)))
    (if (not (eq ina inb))
      (progn (setq f (/ (- x (car a)) (- (car b) (car a))))
             (setq out (cons (list x (+ (cadr a) (* f (- (cadr b) (cadr a))))) out))))
    (setq i (1+ i)))
  (reverse out))
;; the trunk envelope solid for a sloped / stepped route; nil when it fails
(defun dbk-env-profile (vtx bnd lay / zr dT dB e poly hw segs i sg lo hi pl2 o n slabs zmin zmax prism slab th c ok mark res)
  (setq zr (dbk-get *DBK* "ZREF") dT (- (dbk-get *DBKS* "TOP") zr) dB (- (dbk-get *DBKS* "BOT") zr) e 1000.0
        segs *DBK-SEGS* hw (+ (/ (dbk-get *DBKS* "WT") 2.0) 2.0)
        th (+ (max (abs (dbk-get *DBKS* "LEXT")) (abs (dbk-get *DBKS* "REXT")) (abs (dbk-get *DBKS* "LSA")) (abs (dbk-get *DBKS* "RSA"))) 12.0))
  (setq poly (append (dbk-prof-chain dT 1 _DBKCOVERTOP e) (reverse (dbk-prof-chain dB -1 _DBKCOVERBOT e))))
  (setq *DBKS* (dbk-put *DBKS* "SLAB" poly))
  (setq zmin (dbk-min (mapcar 'cadr poly)) zmax (dbk-max (mapcar 'cadr poly)) i 0)
  (foreach sg segs
    (setq lo (if (> i 0) (- (nth 5 sg) (+ (* hw (+ 1.0 (dbk-tan (/ (nth 5 (nth (1- i) *DBK-CORNERS*)) 2.0)))) 6.0)))
          hi (if (< i (1- (length segs))) (+ (nth 5 sg) (nth 4 sg) (* hw (+ 1.0 (dbk-tan (/ (nth 5 (nth i *DBK-CORNERS*)) 2.0)))) 6.0)))
    (setq pl2 poly)
    (if lo (setq pl2 (dbk-clip-s pl2 lo 1)))
    (if hi (setq pl2 (dbk-clip-s pl2 hi -1)))
    (setq o (dbk-v- (dbk-v+ (nth 0 sg) (dbk-v* (nth 3 sg) (- th))) (dbk-v* (nth 2 sg) (nth 5 sg)))
          o (list (car o) (cadr o) 0.0) n (list (car (nth 3 sg)) (cadr (nth 3 sg)) 0.0))
    (setq pl2 (dbk-ocs-pts o (nth 2 sg) n pl2))
    (if (and (setq c (dbk-mk-lw lay pl2 (mapcar '(lambda (q) 0.0) pl2) (caddr (car pl2)) n T nil nil))
             (setq slab (dbk-extrude c (* 2.0 th))) (= (cdr (assoc 0 (entget slab))) "3DSOLID"))
      (setq slabs (cons slab slabs))
      (progn (if (and c (entget c)) (entdel c)) (setq ok 'FAIL)))
    (setq i (1+ i)))
  (setq c (dbk-mk-lw lay vtx bnd (- zmin 1.0) '(0.0 0.0 1.0) T nil nil))
  (if c (setq prism (dbk-extrude c (+ (- zmax zmin) 2.0))))
  (if (or (= ok 'FAIL) (not (and prism (entget prism) (= (cdr (assoc 0 (entget prism))) "3DSOLID"))))
    (progn (foreach x (cons prism slabs) (if (and x (entget x)) (entdel x))) (if (and c (entget c)) (entdel c)) nil)
    (progn
      (if (cdr slabs) (command "_.UNION" (dbk-ss slabs) ""))
      (setq slabs (vl-remove-if-not 'entget slabs))
      (command "_.INTERSECT" (dbk-ss (cons prism slabs)) "")
      (setq res (vl-remove-if-not '(lambda (x) (and (entget x) (= (cdr (assoc 0 (entget x))) "3DSOLID"))) (cons prism slabs)))
      (car res))))
;; layer transparency (MVP4c, Clint: the ductbank 3D layer 75 % transparent by default). Stored as layer xdata
;; AcCmTransparency 1071 = 0x02000000 + alpha, alpha = 255 x (100 - %) / 100 (truncated, as AutoCAD does).
;; Set on a new layer or one without a transparency value (earlier builds made it at 0); a value already
;; on the layer (the user's) is left alone. _DBKLAYERTRANS 0 = never touch it.
(defun dbk-trans-pct (lay / e xd v)
  (if (and (setq e (tblobjname "LAYER" lay))
           (setq xd (cdr (assoc -3 (entget e '("AcCmTransparency")))))
           (setq v (cdr (assoc 1071 (cdar xd)))))
    (if (= (logand v 33554432) 33554432) (fix (+ 0.5 (- 100.0 (/ (* 100.0 (logand v 255)) 255.0)))) 0)
    0))
(defun dbk-layer-trans (lay / pct e ed)
  (setq pct (if (numberp _DBKLAYERTRANS) (max 0 (min 90 (fix _DBKLAYERTRANS))) 0))
  (if (and (> pct 0) (setq e (tblobjname "LAYER" lay)))
    (progn
      (regapp "AcCmTransparency")
      (setq ed (entget e '("AcCmTransparency")))
      (if (not (assoc -3 ed))
        (entmod (append ed (list (list -3 (list "AcCmTransparency" (cons 1071 (+ 33554432 (fix (/ (* 255.0 (- 100 pct)) 100.0))))))))))))
  lay)
;; returns (nEnvelopeSolids nSpacerSolids nTurnups); every solid tagged DBANK_DATA and added to the bank.
;; The stub-up encasement turn-ups are unioned into the envelope solid (one ENV3D solid).
(defun dbk-model-3d (vtx bnd bank / lay oldce oldos olddel oldcmd e env n st pp dir m nrm o th sgn pls pts ocs
                                   pieces cyls sol ss mark ok p lat z r tus envs ntu al up zr)
  (setq lay (dbk-model-layer) n 0 th _DBKSPTHICK sgn (dbk-get *DBKS* "SGN"))
  (if (not (tblsearch "LAYER" lay))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                   (cons 2 lay) '(70 . 0) '(62 . 8) '(6 . "Continuous") '(290 . 0))))
  (dbk-layer-trans lay)
  (setq oldce (getvar "CMDECHO") oldos (getvar "OSMODE") olddel (getvar "DELOBJ"))
  (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "DELOBJ" 3)
  ;; concrete envelope: the plan outline (stub zones, tapers and bends included) at the bottom
  ;; of the concrete, extruded up the full height
  ;; (a sloped / stepped trunk: that prism, taller, intersected with the route profile slabs)
  (if (dbk-level-p)
    (progn
      (setq e (dbk-mk-lw lay vtx bnd (dbk-get *DBKS* "BOT") '(0.0 0.0 1.0) T nil nil))
      (if e (setq env (dbk-extrude e (dbk-get *DBKS* "H")))))
    (setq env (dbk-env-profile vtx bnd lay) e nil))
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
      ;; on a grade the section stays square to the run: normal = the 3D run direction, up tilted
      (setq pp (dbk-pathpt st) al (if *DBK-PV* (dbk-prof-alpha *DBK-PV* st) 0.0) m (caddr pp)
            dir (list (* (cos al) (car (cadr pp))) (* (cos al) (cadr (cadr pp))) (sin al))
            up (list (* (- (sin al)) (car (cadr pp))) (* (- (sin al)) (cadr (cadr pp))) (cos al))
            zr (dbk-get *DBK* "ZREF")
            o (list (- (car (car pp)) (* (car dir) (/ th 2.0))) (- (cadr (car pp)) (* (cadr dir) (/ th 2.0)))
                    (- (+ zr (dbk-dz st)) (* (caddr dir) (/ th 2.0))))
            pieces nil cyls nil)
      (foreach pc (dbk-trunk-pieces)
        (setq pts (dbk-ocs-pts2 o m up dir zr (list (list (* sgn (nth 0 pc)) (nth 2 pc)) (list (* sgn (nth 1 pc)) (nth 2 pc))
                                             (list (* sgn (nth 1 pc)) (nth 3 pc)) (list (* sgn (nth 0 pc)) (nth 3 pc)))))
        (if (setq e (dbk-mk-lw lay pts '(0.0 0.0 0.0 0.0) (caddr (car pts)) dir T nil nil))
          (if (and (setq sol (dbk-extrude e th)) (= (cdr (assoc 0 (entget sol))) "3DSOLID"))
            (setq pieces (cons sol pieces)))))
      (foreach p (dbk-get *DBK* "PL")
        ;; seat cylinder a little longer than the spacer so the subtraction has no coplanar faces
        (setq ocs (car (dbk-ocs-pts2 (mapcar '(lambda (a b) (- a (* 0.1 b))) o dir) m up dir zr
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
;;; stub elbows (offset by OD/2 + end cover toward the elbow center; with _DBKBENDCONC Chamfer
;;; the chord of that arc instead of the arc) and the riser backs above the sweep. Width = the stub zone envelope (lateral LSA..RSA, side covers included).
;; stub-up riser / stub elbow OD (the stub material: PVC-coated or plain RGS), never under the position OD
(defun dbk-tu-od (p) (dbk-get p "OD"))
;;; MVP4: the turn-up functions work on the end in *DBK-TUEND* ("A" / "B", trunk offset *DBK-TUDZ* at
;;; that end). MVP4c (Clint, Oct 7): a 45 deg stub-up end is a band that follows the 45 deg elbows and
;;; risers with the end cover on both sides (front = the outer cover of the elbows / risers, back = the
;;; inner cover, chord with Chamfer), cut by a level plane (parallel to grade) at the encasement top,
;;; which dbk-solve keeps _DBKRISERPROJ below the riser ends: no vertical / angled cap past the conduit
;;; ends. Below the trunk top the front is the vertical trunk end face (dbk-tu-face). Primary OD.
(setq *DBK-TUEND* "A" *DBK-TUDZ* 0.0 *DBK-TUZ* nil)
(defun dbk-tu-ang () (cond ((dbk-get *DBKS* (strcat "ANG" *DBK-TUEND*))) (90)))
(defun dbk-tu-se (p) (cond ((dbk-get p (strcat "SE" *DBK-TUEND*))) (T (+ (dbk-get p "ALONG") (dbk-get p "RV")))))
(defun dbk-tu-zc (p) (+ (dbk-get p "ZC") *DBK-TUDZ*))
;; trunk end face (station from the end): 90 deg = beyond the outermost riser by the end cover; 45 deg =
;; the outer cover of the 45 deg elbows / risers at the trunk top of concrete (the band above leans out)
(defun dbk-tu-face ( / out x)
  (if (= (dbk-tu-ang) 45)
    (progn
      (foreach p (dbk-get *DBK* "PL")
        (setq x (dbk-tu-outer45 p (+ (dbk-get *DBKS* "TOP") *DBK-TUDZ*)))
        (if (or (null out) (< x out)) (setq out x)))
      out)
    (- (dbk-min (mapcar '(lambda (p) (dbk-get p "ALONG")) (dbk-get *DBK* "PL")))
       (+ (/ (dbk-get *DBKS* "MAXOD") 2.0) _DBKCOVEREND))))
;; 45 deg stub: outer cover station at elevation z (riser outer line, else the elbow's outer cover arc)
(defun dbk-tu-outer45 (p z / se r zc w s2 ex ez ox oz cz)
  (setq se (dbk-tu-se p) r (dbk-get p "RV") zc (dbk-tu-zc p) w (+ (/ (dbk-get p "OD") 2.0) _DBKCOVEREND) s2 (sqrt 0.5)
        ex (- se (* r s2)) ez (+ zc (* r (- 1.0 s2))) ox (- ex (* w s2)) oz (- ez (* w s2)) cz (+ zc r))
  (cond ((>= z oz) (- ox (- z oz)))
        ((>= z (- cz r w)) (- se (sqrt (max 0.0 (- (* (+ r w) (+ r w)) (* (- cz z) (- cz z)))))))
        (T se)))
;; 45 deg stub: inner cover (back edge) station at elevation z
(defun dbk-tu-inner45 (p z / se r zc w s2 ri cz a0z a1x a1z)
  (setq se (dbk-tu-se p) r (dbk-get p "RV") zc (dbk-tu-zc p) w (+ (/ (dbk-get p "OD") 2.0) _DBKCOVEREND) s2 (sqrt 0.5)
        ri (- r w) cz (+ zc r))
  (if (<= ri 0.01)
    (- (+ se (* w s2)) (max 0.0 (- z (+ zc (* r (- 1.0 s2))) (* w s2))))
    (progn
      (setq a0z (+ zc w) a1x (- se (* ri s2)) a1z (- cz (* ri s2)))
      (cond ((>= z a1z) (- a1x (- z a1z)))
            ((>= z a0z) (if (dbk-chamfer-p)
                          (+ se (* (- a1x se) (/ (- z a0z) (- a1z a0z))))
                          (- se (sqrt (max 0.0 (- (* ri ri) (* (- cz z) (- cz z))))))))
            (T se)))))
;; back edge station at elevation z (max over every position)
(defun dbk-tu-back (z / out cx cz rr s od)
  (foreach p (dbk-get *DBK* "PL")
    (if (= (dbk-tu-ang) 45)
      (setq s (dbk-tu-inner45 p z))
      (progn
        (setq od (dbk-tu-od p) cx (dbk-tu-se p) cz (+ (dbk-tu-zc p) (dbk-get p "RV"))
              rr (- (dbk-get p "RV") (/ od 2.0) _DBKCOVEREND))
        (setq s (cond ((>= z cz) (+ (dbk-get p "ALONG") (/ od 2.0) _DBKCOVEREND))
                      ((and (> rr 0.01) (>= z (- cz rr)))
                        (if (dbk-chamfer-p)
                          (+ (- cx rr) (- cz z))   ; chamfer: chord of the inner cover arc (45 deg), cover kept
                          (- cx (sqrt (max 0.0 (- (* rr rr) (* (- cz z) (- cz z))))))))
                      (T cx)))))
    (if (or (null out) (> s out)) (setq out s)))
  out)
;; front (end side) station at elevation z: the trunk end face up to the trunk top; at a 45 deg end the
;; outer cover of the elbows / risers above it (never past the trunk end face)
(defun dbk-tu-front (z / out x)
  (setq out (dbk-tu-face))
  (if (= (dbk-tu-ang) 45)
    (foreach p (dbk-get *DBK* "PL")
      (setq x (dbk-tu-outer45 p z))
      (if (< x out) (setq out x))))
  out)
;; closed profile ((s z) ...) from just below the trunk top of concrete up to the level cut at encz
(defun dbk-tu-profile (encz / face zb zt zs z k pts n w r zc a out)
  (setq *DBK-TUZ* encz)
  (setq face (dbk-tu-face) zt (+ (dbk-get *DBKS* "TOP") *DBK-TUDZ*) zb (- zt (min 1.0 (* 0.5 (dbk-get *DBKS* "H")))) n 24)
  (setq zs (list encz zb) k 1)
  (repeat (1- n) (setq zs (cons (+ zb (* (- encz zb) (/ (float k) n))) zs) k (1+ k)))
  (foreach p (dbk-get *DBK* "PL")
    (setq r (dbk-get p "RV") zc (dbk-tu-zc p) w (+ (/ (dbk-get p "OD") 2.0) _DBKCOVEREND))
    (foreach z (if (= (dbk-tu-ang) 45)
                 (append (list zt (+ zc w) (- (+ zc r) (* (- r w) (sqrt 0.5))) (+ zc (* r (- 1.0 (sqrt 0.5))))
                               (- (+ zc (* r (- 1.0 (sqrt 0.5)))) (* w (sqrt 0.5))))
                         ;; the outer cover arc every degree (a chord of it would cut into the cover)
                         (progn (setq a 0 out nil)
                                (repeat 46 (setq out (cons (- (+ zc r) (* (+ r w) (cos (* a (/ pi 180.0))))) out) a (1+ a)))
                                out))
                 (list (+ zc r) (+ zc (/ (dbk-tu-od p) 2.0) _DBKCOVEREND)))
      (if (and (< z encz) (> z zb)) (setq zs (cons z zs)))))
  (setq zs (vl-sort (dbk-uniq (mapcar '(lambda (z) (atof (rtos z 2 6))) zs)) '>))
  ;; front edge bottom -> level cut (90 deg: the vertical end face), then the back edge down
  (setq pts (if (= (dbk-tu-ang) 45)
              (mapcar '(lambda (z) (list (dbk-tu-front z) z)) (reverse zs))
              (list (list face zb) (list face encz))))
  (foreach z zs (setq pts (append pts (list (list (dbk-tu-back z) z)))))
  ;; drop repeated points
  (setq k nil)
  (foreach q pts (if (not (and k (< (distance q (car k)) 1e-6))) (setq k (cons q k))))
  (if (< (distance (car k) (last k)) 1e-6) (setq k (cdr k)))
  (reverse k))
(defun dbk-tu-set (end encz)
  (setq *DBK-TUEND* end *DBK-TUDZ* (if (= end "B") (cond ((dbk-get *DBKS* "DZB")) (0.0)) 0.0) *DBK-TUZ* encz))
;; end frame: (origin2D alongDir2D lateralNormal2D) so WCS = o + along*s + normal*lat
(defun dbk-tu-frame (end / sg)
  (if (= end "A")
    (progn (setq sg (car *DBK-SEGS*)) (list (nth 0 sg) (nth 2 sg) (nth 3 sg)))
    (progn (setq sg (last *DBK-SEGS*)) (list (nth 1 sg) (dbk-v* (nth 2 sg) -1.0) (nth 3 sg)))))
;; plan footprint of the turn-up top: 4 points (2D) at the given end
(defun dbk-tu-plan (end encz / fr face back lsa rsa)
  (dbk-tu-set end encz)
  (setq fr (dbk-tu-frame end) face (dbk-tu-front encz) back (dbk-tu-back encz)
        lsa (dbk-get *DBKS* "LSA") rsa (dbk-get *DBKS* "RSA"))
  (mapcar '(lambda (sl) (dbk-v+ (dbk-v+ (car fr) (dbk-v* (cadr fr) (car sl))) (dbk-v* (caddr fr) (cadr sl))))
          (list (list face lsa) (list back lsa) (list back rsa) (list face rsa))))
;; 3D solid of the turn-up at one end (profile at lateral LSA extruded across to RSA)
(defun dbk-tu-solid (end encz lay / fr o m n pts ocs e sol)
  (dbk-tu-set end encz)
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
                                (strcat "Stub-ups: end A " (if (= (dbk-get *DBK* "ENDA") "Stubup") (if (= (dbk-get *DBKS* "ANGA") 45) "45 deg (open riser top)" "90 deg") "open")
                                        ", end B " (if (= (dbk-get *DBK* "ENDB") "Stubup") (if (= (dbk-get *DBKS* "ANGB") 45) "45 deg (open riser top)" "90 deg") "open"))
                                (strcat "Stub elbows R" (rtos (dbk-min rvs) 2 0) (if (> (dbk-max rvs) (dbk-min rvs)) (strcat "-R" (rtos (dbk-max rvs) 2 0)) "")
                                        ", " (if (= (dbk-get *DBK* "STUBCODE") 1)
                                               (strcat "plain RGS" (if (= (dbk-get *DBK* "WRAP") 1) " (wrapped)" "")) "PVC-coated RGS"))
                                (strcat "Turn-up (" (dbk-encstr (dbk-get *DBK* "ENCH")) "): "
                                        (if (or (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
                                          (strcat "EL " (dbk-joinstr (vl-remove 'nil (list (if (dbk-get *DBKS* "ENCZA") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZA")) " A"))
                                                                                              (if (dbk-get *DBKS* "ENCZB") (strcat (dbk-r2 (dbk-get *DBKS* "ENCZB")) " B")))) ", ")
                                                  ", sweep top EL " (dbk-r2 (dbk-get *DBKS* "SWEEPTOP"))
                                                  ", level top, risers project >= " (dbk-r2 _DBKRISERPROJ) "\"")
                                          "none"))))))
  (if (or *DBK-CORNERS* (dbk-get *DBKS* "ENCZA") (dbk-get *DBKS* "ENCZB"))
    (setq out (append out (list (strcat "Concrete at bends: " (if (dbk-chamfer-p) "chamfered" "swept")
                                        (if *DBK-CORNERS* (strcat " (" (itoa (length *DBK-CORNERS*)) " plan bend(s)"
                                                                  (if (dbk-get *DBKS* "ENCZA") " + turn-ups)" (if (dbk-get *DBKS* "ENCZB") " + turn-ups)" ")"))) " (turn-ups)"))))))
  (setq out (append out (list (if part (strcat "Spacer " (car part) ": " (itoa (length (dbk-get *DBKS* "STATIONS"))) " stations x "
                                               (itoa (dbk-get *DBKS* "PIECES")) " pieces, pitch " (dbk-r2 (nth 5 part)) " x " (dbk-r2 (nth 4 part)))
                                "Spacer: none (no Snap-N-Stac part for this size)")
                              (strcat "Bank length along the route: " (rtos (/ (dbk-get *DBKS* "LEN") 12.0) 2 1) " ft"))))
  (if (dbk-get *DBKS* "PV") (setq out (append out (list (car (dbk-prof-summary))))))
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
                  (dbk-kv "ENCH" (dbk-encstr (dbk-get *DBK* "ENCH"))) (dbk-kv "BENDCONC" (dbk-bendstr))
                  (dbk-kv "BOTZ" bot) (dbk-kv "TOPZ" (dbk-get *DBKS* "TOP")) (dbk-kv "SWEEPTOPZ" (dbk-get *DBKS* "SWEEPTOP"))
                  (dbk-kv "ENCZA" (dbk-get *DBKS* "ENCZA")) (dbk-kv "ENCZB" (dbk-get *DBKS* "ENCZB"))
                  (dbk-kv "ANGA" (dbk-stubang (dbk-get *DBK* "ANGA"))) (dbk-kv "ANGB" (dbk-stubang (dbk-get *DBK* "ANGB")))
                  (dbk-kv "FLEXMAX" _DBKFLEXMAX) (dbk-kv "FLEXLEN" _DBKFLEXLEN) (dbk-kv "FLEXRMIN" _DBKFLEXRMIN)
                  (dbk-kv "RISERPROJ" _DBKRISERPROJ)
                  (dbk-kv "DZB" (dbk-get *DBKS* "DZB"))))
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
  (foreach s (dbk-prof-summary) (setq out (append out (list (strcat "PROF=" s)))))
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
      (setq _DBKBENDCONC (if (wcmatch (strcase (dbk-kvs "BENDCONC" (dbk-bendstr))) "S*") "Sweep" "Chamfer"))
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
      (foreach k '("ANGA" "ANGB") (setq *DBK* (dbk-put *DBK* k (dbk-stubang (dbk-kvs k (itoa (dbk-stubang (dbk-get *DBK* k))))))))
      (setq _DBKFLEXMAX (max 0.0 (min 10.0 (dbk-kvn "FLEXMAX" _DBKFLEXMAX))) _DBKFLEXLEN (max 1.0 (dbk-kvn "FLEXLEN" _DBKFLEXLEN)))
      (setq _DBKRISERPROJ (max 0.0 (dbk-kvn "RISERPROJ" _DBKRISERPROJ)))
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
  (initget "Cover Gap Interval Transition STRaight SEparation Part STUbmaterial ENcasement Bends ANgle FLex Model3d SCale Done")
  (setq k (getkword "\nOptions [Cover/Gap/Interval/Transition/STRaight/SEparation/Part/STUbmaterial/ENcasement/Bends/ANgle/FLex/Model3d/SCale/Done] <Done>: "))
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
      (setq k (getreal (strcat "\nStub-up encasement top: elevation, or [Auto/Top] (Auto = 90 deg ends: top of the elbow sweep EL "
                               (dbk-r2 (dbk-get *DBKS* "SWEEPTOP")) "; 45 deg ends: up the risers to just below their ends; Top = stub-up top EL less the riser projection) <"
                               (dbk-encstr (dbk-encval (dbk-get *DBK* "ENCH"))) ">: ")))
      (if k (setq *DBK* (dbk-put *DBK* "ENCH" (dbk-encval k))))
      (setq _DBKRISERPROJ (max 0.0 (dbk-ask-real "Minimum riser projection above the level top of the concrete (in)" _DBKRISERPROJ))))
    ((= k "ANgle")
      (foreach e '("A" "B")
        (if (= (dbk-get *DBK* (strcat "END" e)) "Stubup")
          (setq *DBK* (dbk-put *DBK* (strcat "ANG" e)
                        (dbk-stubang (dbk-ask-int (strcat "End " e " stub-up angle, 90 or 45 (45 = 45 deg stub elbow + 45 deg riser, open end)")
                                                  (dbk-stubang (dbk-get *DBK* (strcat "ANG" e))) 45 90)))))))
    ((= k "FLex")
      (setq _DBKFLEXMAX (max 0.0 (min 10.0 (dbk-ask-real "Route grade change taken up by conduit flex, max deflection (deg)" _DBKFLEXMAX)))
            _DBKFLEXLEN (max 1.0 (dbk-ask-real "Run length the flex is spread over (in)" _DBKFLEXLEN))))
    ((= k "Bends")
      (setq _DBKBENDCONC (dbk-ask-kw "Concrete at bends (plan bends and the stub-up turn-up)" "Chamfer Sweep" (dbk-bendstr))))
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
      (if (vl-some '(lambda (q) (> (abs (- (cadr q) z)) 1e-4)) (nth 5 geo))
        (dbk-say (strcat "  Route profile: the trunk follows the reference elevations (EL " (dbk-r2 z) " at end A, "
                         (dbk-r2 (cadr (last (nth 5 geo)))) " at end B, " (itoa (max 0 (- (length (nth 5 geo)) 2))) " intermediate vertices).")))
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
                        (cons "SECTPICK" (if (= _DBKSECTPICK 1) 1 0)) (cons "ENCH" (dbk-encval _DBKENCASE))
                        (cons "PROF" (nth 5 geo)) (cons "ANGA" (dbk-stubang nil)) (cons "ANGB" (dbk-stubang nil))))
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
      (setq *DBK* (dbk-put *DBK* "SX" (dbk-ask-real "Stub-up pitch center to center across (column to column)" (dbk-get *DBK* "SX"))))
      (setq *DBK* (dbk-put *DBK* "SY" (dbk-ask-real "Stub-up pitch center to center along (row to row)" (dbk-get *DBK* "SY"))))
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
                                   " around the stub elbows and risers (" (dbk-enclabel (dbk-get *DBK* "ENCH"))
                                   "), level top at least " (dbk-r2 _DBKRISERPROJ) "\" below the riser ends."))
                         ((or (= (dbk-get *DBK* "ENDA") "Stubup") (= (dbk-get *DBK* "ENDB") "Stubup")) "none (see the flags).")
                         (T "no stub-up ends."))))
  (dbk-say (strcat "Bank " (dbk-get *DBK* "BANK") " built: " (itoa (length (dbk-get *DBK* "PL"))) " conduit positions ("
                   (itoa (nth 2 res)) " MED_CONDUIT segments, " (itoa (nth 3 res)) " elbow segments = " (itoa (nth 4 res))
                   " fitting records), " (itoa (nth 5 res)) " spacer stations, envelope and sections; "
                   (itoa (nth 1 res)) " member entities."))
  (if (> (nth 8 res) 0) (dbk-say (strcat "  " (itoa (nth 8 res)) " vertical bend elbow(s) at route grade changes.")))
  (if (not (dbk-level-p)) (foreach s (dbk-prof-summary) (dbk-say (strcat "  " s))))
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
;; the DBK_BUB stand-in block an earlier build (e91df9d) defined: purge it once nothing references it
(defun dbk-purge-bub ( / b)
  (if (and (setq b (tblsearch "BLOCK" "DBK_BUB")) (not (ssget "_X" '((0 . "INSERT") (2 . "DBK_BUB")))))
    (command "_.-PURGE" "_B" "DBK_BUB" "_N"))
  (princ))
(defun dbk-commit (secpt / n nb)
  (if *DBK-EDITING*
    (progn
      (setq n 0)
      (setq nb 0)
      (foreach x (dbk-bank-ents *DBK-EDITING*)
        (if (and (entget x) (/= (dbk-xdval x "ROLE") "REF"))
          (progn (if (= (dbk-xdval x "ROLE") "BUB") (setq nb (1+ nb))) (entdel x) (setq n (1+ n)))))
      (dbk-say (strcat "DBEDIT: erased the " (itoa n) " old member entities of bank " *DBK-EDITING* "; rebuilding in place."))
      (if (> nb 0) (dbk-say (strcat "DBEDIT: " (itoa nb) " BUB fitting(s) from an earlier build removed; 45 deg stub-ups now end open at the riser top (no fitting).")))
      (dbk-purge-bub)))
  (dbk-build secpt))

;;; -DUCTBANK: command-line version (standard AutoCAD dash convention), also DUCTBANK's fallback
(defun c:-DUCTBANK ( / *error*)
  (dbk-undo T)
  (setq *DBK-EDITING* nil)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg T) "*break*,*cancel*,*exit*"))) (dbk-say (strcat "DUCTBANK error: " msg)))
    (if med-snap-restore (med-snap-restore)) (dbk-undo nil) (princ))
  (if med-snap-off (med-snap-off))
  (dbk-start-msg "-DUCTBANK")
  (if (dbk-setup-ref (dbk-pick "Select reference MED conduit or 3D polyline route")) (dbk-run-text))
  (if med-snap-restore (med-snap-restore))
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
    (if med-snap-restore (med-snap-restore)) (dbk-undo nil) (princ))
  (if med-snap-off (med-snap-off))
  (dbk-start-msg "DUCTBANK")
  (if (dbk-setup-ref (dbk-pick "Select reference MED conduit or 3D polyline route")) (dbk-run-dialog))
  (if med-snap-restore (med-snap-restore))
  (dbk-undo nil)
  (princ))

;;; ------------------------------------------------------------------ DBEDIT / -DBEDIT
;;; Reopen a bank: every setting comes from the bank record (envelope DBANK_DATA), the route
;;; from the reference on MED_DBREF (edited since? the edited route is used). OK erases the
;;; old members (and 3D solids) and regenerates in place with the same bank ID. The session
;;; settings (_DBK* covers, interval, ...) are restored afterwards.
(setq *DBK-EDIT-GLOBALS* '(_DBKCOVERTOP _DBKCOVERBOT _DBKCOVERLEFT _DBKCOVERRIGHT _DBKCOVEREND _DBKMINGAP _DBKSPINT
                          _DBKSPEND _DBKTRANSL _DBKSTUBSTRAIGHT _DBKSEP _DBKSECTSCALE _DBKTAGPAT _DBKBENDCONC
                          _DBKFLEXMAX _DBKFLEXLEN _DBKRISERPROJ))
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
                _DBKSECTSCALE (dbk-ev "SECTSCALE" _DBKSECTSCALE) _DBKTAGPAT (dbk-es "TAGPAT" _DBKTAGPAT)
                _DBKBENDCONC (dbk-es "BENDCONC" _DBKBENDCONC)
                _DBKFLEXMAX (dbk-ev "FLEXMAX" _DBKFLEXMAX) _DBKFLEXLEN (dbk-ev "FLEXLEN" _DBKFLEXLEN)
                _DBKRISERPROJ (dbk-ev "RISERPROJ" _DBKRISERPROJ))
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
                    *DBK* (dbk-put *DBK* "ANGA" (dbk-stubang (dbk-es "ANGA" "90")))
                    *DBK* (dbk-put *DBK* "ANGB" (dbk-stubang (dbk-es "ANGB" "90")))
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
    (if med-snap-restore (med-snap-restore)) (dbk-undo nil) (princ))
  (if med-snap-off (med-snap-off))
  (dbk-start-msg (if dialog "DBEDIT" "-DBEDIT"))
  (if (dbk-edit-load (dbk-pick "Select any part of the ductbank to edit"))
    (if dialog (dbk-run-dialog) (dbk-run-text)))
  (dbk-globals-restore saved)
  (setq *DBK-EDITING* nil)
  (if med-snap-restore (med-snap-restore))
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
                                   ", setting " (dbk-enclabel (cond ((dbk-xdval env "ENCH")) ("Auto")))
                                   (if (dbk-xdval env "RISERPROJ") (strcat ", level top, risers project >= " (rtos (atof (dbk-xdval env "RISERPROJ")) 2 2) "\"")
                                     " (built before the level cut: DBEDIT cuts it level below the riser ends)"))
                           (if (dbk-xdval env "ENCH") "none" "not stored (bank built before MVP3; DBEDIT adds it)"))
                         ", concrete at bends: " (cond ((= (dbk-xdval env "BENDCONC") "Sweep") "swept") ((dbk-xdval env "BENDCONC") "chamfered") (T "swept (built before the chamfer option)"))))
        (dbk-say (strcat "  stub-up angle: end A " (cond ((dbk-xdval env "ANGA")) ("90")) ", end B " (cond ((dbk-xdval env "ANGB")) ("90"))
                         (if (/= (cond ((dbk-xdval env "BUBS")) ("0")) "0") (strcat " (" (dbk-xdval env "BUBS") " BUB fittings from an earlier build: DBEDIT rebuild removes them)") "")
                         "; route profile: " (cond ((= (dbk-xdval env "PROFILE") "GRADE")
                                                     (strcat (cond ((dbk-xdval env "VBENDS")) ("0")) " vertical bend(s), " (cond ((dbk-xdval env "FLEXPTS")) ("0"))
                                                             " flex point(s), end B " (rtos (atof (cond ((dbk-xdval env "DZB")) ("0"))) 2 2) "\" from end A"))
                                                    (T "level"))
                         ", flex limit " (cond ((dbk-xdval env "FLEXMAX")) ("5")) " deg over " (cond ((dbk-xdval env "FLEXLEN")) ("120")) "\""))
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
          (dbk-purge-bub)
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
