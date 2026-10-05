;;; MED Parametric Motor (C:MOTOR)
;;; Draws a 2D plan motor from Support\MOTOR.DAT sizes.
;;; Replaces / wraps the legacy (motor msize vert) helper from QKEY.lsp.
;;; Copyright Moore Design / MED

(if (not *MED-MOTOR-HP*)   (setq *MED-MOTOR-HP* 5.0))
(if (not *MED-MOTOR-VERT*) (setq *MED-MOTOR-VERT* nil))

(defun med-motor-dat-path ( / p )
  (setq p (findfile "motor.dat"))
  (if (not p) (setq p (findfile "MOTOR.DAT")))
  p
)

(defun med-motor-read-dat ( / fn f line lst hp a b c d )
  (setq fn (med-motor-dat-path))
  (if (not fn)
    (progn (prompt "\nMOTOR.DAT not found on support path.") nil)
    (progn
      (setq f (open fn "r"))
      (repeat 10 (read-line f))
      (setq line (read-line f) lst nil)
      (while line
        (if (and (> (strlen line) 10)
                 (/= (substr line 1 1) "*")
                 (/= (strcase (substr line 1 5)) "HORSE")
                 (/= (strcase (substr line 1 5)) "POWER"))
          (progn
            (setq hp (atof (substr line 1 6))
                  a  (atof (substr line 7 8))
                  b  (atof (substr line 15 8))
                  c  (atof (substr line 23 8))
                  d  (atof (substr line 31 8)))
            (if (> hp 0.0)
              (setq lst (append lst (list (list hp a b c d))))
            )
          )
        )
        (setq line (read-line f))
      )
      (close f)
      lst
    )
  )
)

(defun med-motor-lookup (msize lst / itm found )
  (setq found nil)
  (foreach itm lst
    (if (equal (car itm) msize 0.001) (setq found itm))
  )
  found
)

(defun med-motor-pick-size ( / lst i itm defstr ans val picked )
  (setq lst (med-motor-read-dat))
  (if (not lst)
    nil
    (progn
      (prompt "\nMotor sizes (HP) from MOTOR.DAT:")
      (setq i 0)
      (foreach itm lst
        (setq i (1+ i))
        (prompt (strcat "\n  " (itoa i) ". " (rtos (car itm) 2 2) " HP"))
      )
      (setq defstr (rtos *MED-MOTOR-HP* 2 2)
            ans (getstring (strcat "\nEnter number or HP <" defstr ">: "))
            picked nil)
      (if (or (not ans) (= ans ""))
        (setq picked (med-motor-lookup *MED-MOTOR-HP* lst))
        (progn
          (setq val (distof ans 2))
          (if (and val (> val 0.0))
            (progn
              (setq picked (med-motor-lookup val lst))
              (if (and (not picked) (= val (fix val)) (>= val 1) (<= val (length lst)))
                (setq picked (nth (1- (fix val)) lst))
              )
            )
          )
        )
      )
      (if (not picked)
        (prompt "\nInvalid motor size.")
        (setq *MED-MOTOR-HP* (car picked))
      )
      picked
    )
  )
)

(defun med-motor-pick-orient ( / defkw ans )
  (if *MED-MOTOR-VERT* (setq defkw "Vertical") (setq defkw "Horizontal"))
  (initget "Horizontal Vertical")
  (setq ans (getkword (strcat "\nOrientation [Horizontal/Vertical] <" defkw ">: ")))
  (if (not ans) (setq ans defkw))
  (setq *MED-MOTOR-VERT* (= ans "Vertical"))
  *MED-MOTOR-VERT*
)

;; Layer per MED convention (same rule as pmake): CR_LAYER when set, else CLAYER.
(defun med-motor-layer ()
  (if CR_LAYER (list (cons 8 CR_LAYER)) nil)
)

;; Outward half-ellipse end cap.
;;   endMid  - midpoint of the motor body end line
;;   endPt   - one end of that end line (sets the major axis along the line)
;;   bodyCen - center of the motor body (used to decide which side is "out")
;;   depth   - how far the cap bulges past the end line
;; AutoCAD ellipse points are  cen + cos(t)*major + sin(t)*minor, with the
;; minor axis = (Z x major)*ratio, i.e. the major axis rotated +90 deg.  So
;; t in 0..PI lies on the +minor side and t in PI..2PI on the -minor side.
;; We pick whichever half points away from the body, so the cap is correct
;; regardless of generation angle or which end of the motor it is.
;; Returns the cap's arc midpoint (or nil if nothing was drawn).
(defun med-motor-cap (endMid endPt bodyCen depth / maj majLen minDir outDir
                        outLen outU dotp ratio sang eang mid ent z)
  (setq z      (if (caddr endMid) (caddr endMid) 0.0)
        maj    (mapcar '- (list (car endPt) (cadr endPt)) (list (car endMid) (cadr endMid)))
        majLen (distance (list (car endMid) (cadr endMid)) (list (car endPt) (cadr endPt)))
        outDir (mapcar '- (list (car endMid) (cadr endMid)) (list (car bodyCen) (cadr bodyCen)))
        outLen (distance (list (car endMid) (cadr endMid)) (list (car bodyCen) (cadr bodyCen))))
  (if (and (> majLen 1e-9) (> outLen 1e-9) (> depth 1e-9))
    (progn
      (setq outU (mapcar '(lambda (x) (/ x outLen)) outDir))
      (if (<= depth majLen)
        (progn
          ;; Normal case: major axis along the end line.
          (setq minDir (list (- (cadr maj)) (car maj))
                dotp   (+ (* (car minDir) (car outDir)) (* (cadr minDir) (cadr outDir)))
                ratio  (/ depth majLen))
          (if (> dotp 0.0)
            (setq sang 0.0 eang PI)
            (setq sang PI eang (* 2.0 PI))
          )
          (setq ent (list (cons 11 (list (car maj) (cadr maj) 0.0))
                          (cons 40 ratio) (cons 41 sang) (cons 42 eang)))
        )
        (progn
          ;; Very deep cap (depth > half width, ratio would exceed 1):
          ;; major axis points outward, arc runs -90..+90 deg around it.
          (setq ratio (/ majLen depth))
          (setq ent (list (cons 11 (list (* depth (car outU)) (* depth (cadr outU)) 0.0))
                          (cons 40 ratio) (cons 41 (* 1.5 PI)) (cons 42 (* 0.5 PI))))
        )
      )
      (setq mid (list (+ (car endMid) (* depth (car outU)))
                      (+ (cadr endMid) (* depth (cadr outU)))
                      z))
      (entmake (append
        (list '(0 . "ELLIPSE") '(100 . "AcDbEntity"))
        (med-motor-layer)
        (list '(100 . "AcDbEllipse")
              (cons 10 (list (car endMid) (cadr endMid) z)))
        ent
        (list '(210 0.0 0.0 1.0))
      ))
      mid
    )
  )
)

(defun med-motor-draw (msize vert mtpt mtang mtbxdir / lst row mtra mtrb mtrc mtrd
                        mperc mtrst mtpt1 mtpt2 mtpt3 mtpt4 mtend bxstpt bxpt
                        bxpt1 bxpt2 bxpt3 bxpt4 oldcmd oldosm bcen )
  (setq lst (med-motor-read-dat)
        row (med-motor-lookup msize lst))
  (if (not row)
    (progn
      (prompt (strcat "\nMotor size " (rtos msize 2 2) " HP not in MOTOR.DAT."))
      nil
    )
    (progn
      (setq mtra (nth 1 row)
            mtrb (nth 2 row)
            mtrc (- (nth 3 row) (* mtrb 0.5))
            mtrd (nth 4 row)
            oldcmd (getvar "CMDECHO")
            oldosm (getvar "OSMODE"))
      (setvar "CMDECHO" 0)
      (setvar "OSMODE" 0)
      (if (not mtpt) (setq mtpt (getpoint "\nStart Point: ")))
      (if mtpt
        (progn
          (if vert
            (progn
              (entmake (append (list '(0 . "CIRCLE") '(100 . "AcDbEntity"))
                               (med-motor-layer)
                               (list '(100 . "AcDbCircle")
                                     (cons 10 mtpt) (cons 40 (* mtrb 0.5)))))
              (setq bxstpt mtpt)
            )
            (progn
              (if (not mtang) (setq mtang (getangle mtpt "\nAngle of Generation: ")))
              (if mtang
                (progn
                  (setq mperc (* mtra 0.1875)
                        mtrst (polar mtpt mtang mperc)
                        mtpt1 (polar mtrst (+ mtang (* PI 1.5)) (* mtrb 0.5))
                        mtpt2 (polar mtpt1 mtang (- mtra (* mperc 2)))
                        mtpt3 (polar mtpt2 (+ mtang (* PI 0.5)) mtrb)
                        mtpt4 (polar mtpt3 (+ mtang PI) (- mtra (* mperc 2)))
                        bxstpt (polar mtpt mtang (* mtra 0.5)))
                  (pmake (list mtpt1 mtpt2 mtpt3 mtpt4) T)
                  ;; Body center = midpoint of the motor length (also bxstpt).
                  (setq bcen (polar mtpt mtang (* mtra 0.5)))
                  ;; Start end-cap: end line mtpt1-mtpt4, bulges back toward mtpt.
                  (med-motor-cap mtrst mtpt1 bcen mperc)
                  ;; Far end-cap: end line mtpt2-mtpt3, bulges out past mtpt2/mtpt3.
                  (setq mtrst (polar mtpt mtang (- mtra mperc))
                        mtend (polar mtpt mtang mtra))
                  (med-motor-cap mtrst mtpt2 bcen mperc)
                )
              )
            )
          )
          (if (and mtpt (or vert mtang))
            (progn
              (if (not mtbxdir)
                (setq mtbxdir (getangle bxstpt "\nSelect Direction of Motor Box: "))
              )
              (if mtbxdir
                (progn
                  (setq bxpt  (polar bxstpt mtbxdir (* mtrb 0.5))
                        bxpt1 (polar bxpt (+ mtbxdir (* PI 0.5)) (* mtrd 0.5))
                        bxpt2 (polar bxpt1 mtbxdir mtrc)
                        bxpt3 (polar bxpt2 (- mtbxdir (* PI 0.5)) mtrd)
                        bxpt4 (polar bxpt3 (+ mtbxdir PI) mtrc))
                  (pmake (list bxpt1 bxpt2 bxpt3 bxpt4) T)
                )
              )
            )
          )
        )
      )
      (setvar "CMDECHO" oldcmd)
      (setvar "OSMODE" oldosm)
      T
    )
  )
)

(defun motor (msize vert)
  (med-motor-draw msize vert nil nil nil)
)

(defun C:MOTOR ( / row vert )
  (med_cur_set "C:MOTOR")
  (command "_.UNDO" "_Begin")
  (setq row (med-motor-pick-size))
  (if row
    (progn
      (setq vert (med-motor-pick-orient))
      (med-motor-draw (car row) vert nil nil nil)
    )
  )
  (command "_.UNDO" "_End")
  (med_ret_ok)
  (princ)
)

(defun C:PLANMOTOR ()
  (C:MOTOR)
)

(princ "\nMED Motor loaded: MOTOR (Parametric Motor)")
(princ)