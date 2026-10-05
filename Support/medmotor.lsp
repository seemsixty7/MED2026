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

;; Half ellipse: cen, major-axis endpoint (absolute), minor axis length, start/end params
(defun med-motor-ellipse-half (cen majEnd minLen sang eang / majLen ratio)
  (setq majLen (distance cen majEnd))
  (if (> majLen 1e-9)
    (progn
      (setq ratio (/ minLen majLen))
      (entmake (list
        '(0 . "ELLIPSE")
        '(100 . "AcDbEntity")
        '(100 . "AcDbEllipse")
        (cons 10 cen)
        (cons 11 (mapcar '- majEnd cen))
        (cons 40 ratio)
        (cons 41 sang)
        (cons 42 eang)
      ))
    )
  )
)

(defun med-motor-draw (msize vert mtpt mtang mtbxdir / lst row mtra mtrb mtrc mtrd
                        mperc mtrst mtpt1 mtpt2 mtpt3 mtpt4 mtend bxstpt bxpt
                        bxpt1 bxpt2 bxpt3 bxpt4 oldcmd oldosm )
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
              (entmake (list '(0 . "CIRCLE") '(100 . "AcDbEntity") '(100 . "AcDbCircle")
                             (cons 10 mtpt) (cons 40 (* mtrb 0.5))))
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
                  ;; Start end-cap (outer half toward mtpt). Major along to mtpt1.
                  (med-motor-ellipse-half mtrst mtpt1 mperc PI (* 2.0 PI))
                  ;; Far end-cap
                  (setq mtrst (polar mtpt mtang (- mtra mperc))
                        mtpt1 (polar mtrst (+ mtang (* PI 0.5)) (* mtrb 0.5))
                        mtend (polar mtpt mtang mtra))
                  (med-motor-ellipse-half mtrst mtpt1 mperc 0.0 PI)
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