;;; MEDCBGrid.lsp - conduit body orientation test grid (feature/3dpath).
;;;
;;; MEDCBGRID lays out every row of tests\med3dpath\fitting_matrix.csv (see
;;; docs\3d-fitting-matrix.md) in the CURRENT drawing: real MED conduit runs
;;; (LWPOLYLINE + MED_CONDUIT xdata from bld_conduit, rigid steel, current size)
;;; and the real 2D fitting block from Dwg\ with MED_FITTING xdata written by the
;;; menu's own ifitt_ins (and dcon_ins + VERT_DATA for the up / down symbols).
;;; The conduit is cut back around each symbol by the medblck.dat break distances
;;; x DIMSCALE (_SC), as the menu's med_brk_out does. Each cell is labelled with the
;;; row id, block, code, expected orientation and the current result. Then run MEDMAKE3D.
;;;
;;; Load:  (load "<repo>/tests/autocad/MEDCBGrid.lsp")   then  MEDCBGRID
;;; Needs MED loaded (acad.lsp / MEDCore). Scale: USERR1 / DIMSCALE as MED SETUP sets
;;; them; if that is 1 (or 0) it asks (default 48) and sets _SC, DIMSCALE and USERR1.
;;; Every symbol goes in at +_SC, as the menu inserts it; only the M39 / M40 test cells
;;; get one negative scale factor (a faked MIRROR). The final line checks this.
;;; Not generated faithfully (the label says so):
;;;   - blocks whose DWG is missing (2teed): no symbol, conduit + label only;
;;;   - up / down length: the menu asks "Length of conduit traveling ..."; the grid
;;;     answers 36" (MED_CONDUIT distance + VERT_DATA written as the menu does).
;;;   - conduit breaks are made by shortening the drawn runs, not by BREAK.

(setq *MEDCBGRID-VERSION* "2026-09-30 r4")

;; drawing scale the way MED SETUP / MEDVariables keep it: USERR1 if set, else
;; DIMSCALE. 1 (or 0) = not set up: ask, default 48, and set _SC / DIMSCALE /
;; USERR1 like SETUP does, so the grid and MEDMAKE3D see the same scale.
;; T if the insert's plan symbol is mirrored (same rule as MEDMAKE3D)
(defun mcbg-mirrored-q (e / ed)
  (setq ed (entget e))
  (if medcb-mirrored-p
    (if (medcb-mirrored-p ed) T)
    (< (* (cdr (assoc 41 ed)) (cdr (assoc 42 ed)) (caddr (cond ((cdr (assoc 210 ed))) ('(0.0 0.0 1.0))))) 0.0)))
(defun mcbg-scale ( / sc)
  (setq sc (if (/= 0.0 (getvar "USERR1")) (getvar "USERR1") (getvar "DIMSCALE")))
  (if (<= sc 1.0)
    (progn
      (setq sc (getreal (strcat "\nDrawing scale (DIMSCALE) is " (rtos sc 2 2) " - scale to use <48>: ")))
      (if (not (and sc (> sc 0.0))) (setq sc 48.0))))
  (setq _SC sc)
  (setvar "DIMSCALE" sc)
  (setvar "USERR1" sc)
  sc)

(defun mcbg-split (s d / r i)
  (while (setq i (vl-string-search d s))
    (setq r (cons (substr s 1 i) r) s (substr s (+ i 1 (strlen d)))))
  (reverse (cons s r)))

;; one CSV line -> fields ("..." quoting with "" escapes, as Python's csv writes)
(defun mcbg-csv-line (l / r cur i c q n)
  (setq r nil cur "" i 1 q nil n (strlen l))
  (while (<= i n)
    (setq c (substr l i 1))
    (cond
      ((and q (= c "\"") (= (substr l (1+ i) 1) "\"")) (setq cur (strcat cur "\"") i (1+ i)))
      ((= c "\"") (setq q (not q)))
      ((and (not q) (= c ",")) (setq r (cons cur r) cur ""))
      (T (setq cur (strcat cur c))))
    (setq i (1+ i)))
  (reverse (cons cur r)))
(defun mcbg-csv ( / f p l hdr rows)
  (setq p (findfile "fitting_matrix.csv"))
  (if (and (not p) (= (type _MEDDIR) 'STR))
    (setq p (findfile (strcat _MEDDIR "../tests/med3dpath/fitting_matrix.csv"))))
  (if (not p) (setq p (getfiled "fitting_matrix.csv" "" "csv" 0)))
  (if (and p (setq f (open p "r")))
    (progn
      (setq hdr (mapcar 'strcase (mcbg-split (vl-string-trim "\r\n" (read-line f)) ",")))
      (while (setq l (read-line f))
        (setq l (vl-string-trim "\r\n" l))
        (if (/= l "") (setq rows (cons (mapcar 'cons hdr (mcbg-csv-line l)) rows))))
      (close f)
      (reverse rows))))
(defun mcbg-get (k row) (cdr (assoc k row)))

;; local 2D helpers
(defun mcbg-dir (tok) (cdr (assoc tok '(("+X" 1.0 0.0) ("+Y" 0.0 1.0) ("-X" -1.0 0.0) ("-Y" 0.0 -1.0)))))
(defun mcbg-brk (tok brk) (nth (cdr (assoc tok '(("+X" . 0) ("+Y" . 1) ("-X" . 2) ("-Y" . 3)))) brk))
(defun mcbg-pt (o d s rot / x y)
  (setq x (* (car d) s) y (* (cadr d) s))
  (list (+ (car o) (- (* x (cos rot)) (* y (sin rot)))) (+ (cadr o) (+ (* x (sin rot)) (* y (cos rot)))) 0.0))

;; one MED conduit polyline through pts (WCS, Z 0), xdata as the CONDUIT command
(defun mcbg-conduit (pts / ed e)
  (setq ed (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 (getvar "CLAYER"))
                 '(100 . "AcDbPolyline") (cons 90 (length pts)) '(70 . 0) '(38 . 0.0)))
  (foreach p pts (setq ed (append ed (list (list 10 (car p) (cadr p))))))
  (if (entmake ed)
    (progn
      (setq e (entlast))
      (xdatadd e (bld_conduit 1 _CSIZE "NONE" nil "T"))
      e)))

;; conduit legs of one row around origin o; returns the conduit enames
(defun mcbg-legs (legs brk o rot len / ends tok ax a b out d1 d2)
  (foreach tok (mcbg-split legs " ")
    (cond
      ((mcbg-dir tok) (setq ends (append ends (list tok))))
      ((wcmatch tok "PASS*")
        (setq ax (substr tok 5 1) a (strcat "+" ax) b (strcat "-" ax))
        (if (and (= (mcbg-brk a brk) 0.0) (= (mcbg-brk b brk) 0.0))
          (setq out (cons (mcbg-conduit (list (mcbg-pt o (mcbg-dir b) len rot) (mcbg-pt o (mcbg-dir a) len rot))) out))
          (setq ends (append ends (list a b)))))))
  (if (and (= (length ends) 2)
           (= (mcbg-brk (car ends) brk) 0.0) (= (mcbg-brk (cadr ends) brk) 0.0)
           (equal 0.0 (+ (* (car (mcbg-dir (car ends))) (car (mcbg-dir (cadr ends))))
                         (* (cadr (mcbg-dir (car ends))) (cadr (mcbg-dir (cadr ends))))) 1e-9))
    (setq out (cons (mcbg-conduit (list (mcbg-pt o (mcbg-dir (car ends)) len rot) o
                                        (mcbg-pt o (mcbg-dir (cadr ends)) len rot))) out))
    (foreach tok ends
      (setq out (cons (mcbg-conduit (list (mcbg-pt o (mcbg-dir tok) (mcbg-brk tok brk) rot)
                                          (mcbg-pt o (mcbg-dir tok) len rot))) out))))
  (vl-remove nil out))

(defun mcbg-text (p h s)
  (entmake (list '(0 . "TEXT") (cons 8 "MED_CBGRID") (cons 10 p) (cons 40 h) (cons 1 s) '(7 . "STANDARD"))))

;; the 2D symbol + fitting xdata the way C:MEDBlockInsert / ifitt_ins / dcon_ins do
;; always inserted at +_SC (as C:MEDBlockInsert: insert name pt _SC _SC rot); the Scale
;; option works for uniform-scale blocks too. mir "X" / "Y" (M39 / M40 test cells
;; only) then negates that one scale factor to fake a user MIRROR.
(defun mcbg-fitting (blk code instype o rotdeg cnds mir / path e ss ed g)
  (setq path (if (= (type _MEDDWG) 'STR) (findfile (strcat _MEDDWG blk ".dwg"))))
  (if (not path) (setq path (findfile (strcat blk ".dwg"))))
  (if path
    (progn
      ;; file path only the first time (else AutoCAD asks to redefine the block)
      (command "_.-INSERT" (if (tblsearch "BLOCK" blk) blk path) "_S" _SC "_non" o rotdeg)
      (setq e (entlast))
      (if (member mir '("X" "Y"))
        (progn
          (setq ed (entget e) g (if (= mir "X") 41 42))
          (entmod (subst (cons g (- (abs (cdr (assoc g ed))))) (assoc g ed) ed))
          (entupd e)))
      (if cnds (progn (setq ss (ssadd)) (foreach c cnds (ssadd c ss))))
      (setq RL_SS ss RL_SS_DATA (if ss (retr_size_tag ss)) _FITTCODE code _TAGSUPRESS nil)
      (ifitt_ins e ss)
      (if (member instype '(3 6)) (dcon_ins e o instype ss))
      e)))

(defun c:MEDCBGRID ( / sc f pos bad rows base rotall s len cols i row o brk cnds e h old oldtag oldcm oldos oldat oldcsz oldfc cnt miss err)
  (if (not (and bld_conduit bld_fitting ifitt_ins dcon_ins get_bl_data retr_size_tag xdatadd))
    (progn (princ "\nMEDCBGRID: MED is not loaded (bld_conduit / ifitt_ins missing) - (load \"acad\") first.") (exit)))
  (if (not (setq rows (mcbg-csv))) (progn (princ "\nMEDCBGRID: fitting_matrix.csv not found.") (exit)))
  (setq base (getpoint "\nMEDCBGRID base point (top-left cell) <0,0>: "))
  (if (not base) (setq base '(0.0 0.0 0.0)))
  (setq rotall (getreal "\nRotation of every cell (degrees) <0>: "))
  (if (not rotall) (setq rotall 0.0))
  (setq sc (mcbg-scale) f (/ sc 48.0))
  (setq s (* f 120.0) len (* f 40.0) cols 6 h (* f 2.5) i 0 cnt 0 miss 0
        old get_con_dist oldtag _TAGOFF oldcsz _CSIZE oldfc _FITTCODE
        oldcm (getvar "CMDECHO") oldos (getvar "OSMODE") oldat (getvar "ATTREQ"))
  (if (not (and (numberp _CSIZE) (> _CSIZE 0.0))) (setq _CSIZE 1.0))
  (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "ATTREQ" 0)
  (if (not (tblsearch "LAYER" "MED_CBGRID"))
    (entmake '((0 . "LAYER") (100 . "AcDbSymbolTableRecord") (100 . "AcDbLayerTableRecord") (2 . "MED_CBGRID") (70 . 0) (62 . 3) (6 . "CONTINUOUS"))))
  (if _MCON (vl-catch-all-apply 'smlayer (list _MCON)))
  ;; the menu asks for the up / down length and the tag: answer for it
  (defun get_con_dist (spt condir) (setq _MEDDIST 36.0) 36.0)
  (setq _TAGOFF T)
  (setq err
    (vl-catch-all-apply
      '(lambda ()
        (foreach row rows
          (setq o (list (+ (car base) (* (rem i cols) s)) (- (cadr base) (* (/ i cols) s)) 0.0)
                brk (mapcar '(lambda (d) (* d _SC)) (reverse (cdr (reverse (get_bl_data (mcbg-get "BLOCK" row)))))))
          (setq cnds (mcbg-legs (mcbg-get "LEGS" row) brk o (* pi (/ rotall 180.0)) len))
          (setq e (mcbg-fitting (mcbg-get "BLOCK" row) (atoi (mcbg-get "CODE" row)) (atoi (mcbg-get "INSTYPE" row))
                                o rotall cnds (strcase (cond ((mcbg-get "MIRROR" row)) ("")))))
          (if e (setq cnt (1+ cnt)) (setq miss (1+ miss)))
          (if e
            (if (and (eq (not (mcbg-mirrored-q e)) (not (member (strcase (cond ((mcbg-get "MIRROR" row)) (""))) '("X" "Y"))))
                     (equal (abs (cdr (assoc 41 (entget e)))) _SC 1e-6) (equal (abs (cdr (assoc 42 (entget e)))) _SC 1e-6))
              (setq pos (1+ (if pos pos 0)))
              (setq bad (cons (mcbg-get "ID" row) bad))))
          (mcbg-text (list (- (car o) (* 0.45 s)) (+ (cadr o) (* 0.45 s)) 0.0) (* 1.6 h)
                     (strcat (mcbg-get "ID" row) "  " (mcbg-get "BLOCK" row) "  code " (mcbg-get "CODE" row)
                             "  " (mcbg-get "BODY" row) "  legs " (mcbg-get "LEGS" row)
                             (if (member (mcbg-get "MIRROR" row) '("X" "Y")) (strcat "  MIRRORED (" (mcbg-get "MIRROR" row) " scale -1)") "")
                             (if e "" "  - NOT PLACEABLE: block DWG missing")))
          (mcbg-text (list (- (car o) (* 0.45 s)) (- (cadr o) (* 0.40 s)) 0.0) h
                     (strcat "expected: " (mcbg-get "EXPECTED" row) " | cuts " (mcbg-get "EXP_CUTS" row)
                             " | flags " (mcbg-get "EXP_FLAGS" row)))
          (mcbg-text (list (- (car o) (* 0.45 s)) (- (cadr o) (* 0.45 s)) 0.0) h
                     (strcat (cond ((equal sc 48.0 1e-9) (strcat "current at DIMSCALE 48: " (mcbg-get "MATCH_SC48" row)))
                                   ((equal sc 1.0 1e-9) (strcat "current at DIMSCALE 1: " (mcbg-get "MATCH_SC1" row)))
                                   (T (strcat "current (DIMSCALE 1 / 48): " (mcbg-get "MATCH_SC1" row) " / " (mcbg-get "MATCH_SC48" row))))
                             (if (/= (mcbg-get "CLINT_Q" row) "") (strcat "   ask: " (mcbg-get "CLINT_Q" row)) "")))
          (setq i (1+ i))))))
  (setq get_con_dist old _TAGOFF oldtag _CSIZE oldcsz _FITTCODE oldfc RL_SS nil RL_SS_DATA nil)
  (setvar "CMDECHO" oldcm) (setvar "OSMODE" oldos) (setvar "ATTREQ" oldat)
  (if (vl-catch-all-error-p err)
    (princ (strcat "\nMEDCBGRID stopped: " (vl-catch-all-error-message err))))
  (princ (strcat "\nMEDCBGRID " *MEDCBGRID-VERSION* ": " (itoa i) " row(s), " (itoa cnt) " symbol(s) inserted, "
                 (itoa miss) " not placeable; scale check " (itoa (if pos pos 0)) " ok"
                 (if bad (strcat ", WRONG scale / mirror: " (apply 'strcat (mapcar '(lambda (x) (strcat x " ")) (reverse bad)))) "")
                 "; DIMSCALE (_SC) " (rtos _SC 2 2) ", conduit size " (rtos _CSIZE 2 3)
                 "\". Now ZOOM E and run MEDMAKE3D (Layer)."))
  (princ))

(princ "\nMEDCBGrid loaded: MEDCBGRID")
(princ)
