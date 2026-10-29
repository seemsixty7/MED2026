;;; swxdata2 2026-10-29: swivel center = complete MED_FITTING 367 only (6 fields, Alt 0.0); MED_TRAY stamp dropped; 3D f pinned nil.
;;; 27ak (2026-10-28ak): 2D swivel boxes entmade at parent tray elevation (DXF 38 per end);
;;;   was MEDPlineMake w/ 2D pts -> Z=0.  3D/27aj path untouched.
;;; 27aj (2026-10-28aj): restores 27z WCS pivot (flat along*PARENT-OFF, Z+V_OFF, cross=along x Z);
;;;   alongShift removed; non-World up keeps fal/fup pivot; UCS 2D place + 27ad/ae/af/ag kept.
;;; 27ai (2026-10-28ai): flips 27ah alongShift sign - pivot moves back into parent (opposite fal)
;;;   by V_OFF*sin(phi) so 3D plates meet 27p-shifted 2D bridge (Clint 'back' nudge). Status prints signed value.
;;; MEDTraySwivel.lsp  -  TRAYSWIVEL (2026-10-28ah)
;;; 27ah (2026-10-28ah): 3D pivot += V_OFF*sin(phi) along parent fal to meet 27p-shifted
;;;   2D bridge; pivot/cross use unflattened fal/fup (fixes WCS ~sin(phi) gap and Front creep).
;;; 27ag (2026-10-28ag): 3D swivels on MED_3DTRAY-{desc} from nearest MEDTRAY* parent.
;;; 27af (2026-10-28af): 3D swivels put on parent tray layer; SW tag TEXT only when *MEDSW-DEBUG* is T.
;;; 27ae (2026-10-28ae): Angle1 phi + rise/drop sense relative to parent tray up (not World Z).
;;; 27ad (2026-10-28ad): 3D frame from flat parent tray (210 + in-plane along), single TransformBy.
;;; 27ac (2026-10-28ac): TRAYFIX-style named UCS MEDSwTmp + Object UCS + origin
;;;   shift to WCS 0 (World only when extrusion=Z); ELEVATION from tray A DXF 38;
;;;   boxes written in tray A OCS (210); 3D up = fitting extrusion (not World Z).
;;; 27z (2026-10-28z): along off open end (no p1->p2 flip); dyn diagonal mapping inverted vs 27y.
;;; 27y (2026-10-28y): dyn diagonal by rise/drop sense from relative bridge points (was SW tag parity); 27x R180along kept.
;;;   after existing +180 about up.
;;; 27w (2026-10-28w): dyn Angle phi from sloped BRIDGE tray center at p2 (not the
;;;   steeper fitting centerline). Fallback to fitting p1->p2 with WARNING. phiSrc in status.
;;; 27v (2026-10-28v): dyn Angle put in RADIANS first (ActiveX), degrees fallback.
;;; 27t (2026-10-28t): place both plates first, dyn Angle last; hardened dyn setter (never throws).
;;; 27u (2026-10-28u): dyn setter matches ANGLE or ANGLE1 (block prop is Angle1).
;;; 27s (2026-10-28s): swap L/R, R-type +180 about up, dyn Angle 360-phi / phi by diagonal (bolt head inside).
;;; 27r (2026-10-28r): tag TEXT uses WCS insert pt (not DXF 10 OCS).
;;; 27q (2026-10-28q): TAG DIAGNOSTIC ONLY - each 3D swivel insert gets a red TEXT
;;;   label SW{n}-L (flip +1) / SW{n}-R (flip -1), n = pair counter across the
;;;   session (*MEDSW-TAG-N*, reset on load).  Text at insert pt + 1.0 Z, h=1.0,
;;;   same layer as insert.  Place/orient/flip math unchanged from 27p.
;;; Straight tray + swivel plates instead of offset fittings (2D).
;;; Pick tray A near open end, pick tray B near open end.
;;;  - Each pick snaps to the NEARER end of that MED_TRAY lwpolyline.
;;;  - 2D: one closed box per end (rail to rail) = swivel-plate pair symbol.
;;;  - MED Center + MED_FITTING xdata per end: Main tray end -> Drop/bridge face.
;;;  - Bridge straight tray between computed faces (NOT the raw tray ends).
;;;
;;; Working plate constants (from 3DTraySwivelWork markup; not true catalog specs):
;;;  *MEDSW-PARENT-OFF*  insert (swivel center) -> parent tray face   = 5.0451
;;;  *MEDSW-BRIDGE-OFF*  insert -> bridge/angled tray face (perp)     = 5.0357
;;; Field cuts will vary; keep geometry consistent with these.
;;;
;;; 3D RULE (Clint 2026-10-27l): block INSERT = swivel point (diamond CEN).
;;; No offset-insert compensation / crazy rotations for a displaced insert.
;;; PARENT-OFF / BRIDGE-OFF only locate that swivel point in space from the trays.
;;; 27p (2026-10-28p): bridge faces shifted by V_OFF*(up - n) so the 2D bridge
;;;   matches plates whose pivots are raised V_OFF (along-path V_OFF*sin(slope)).
;;; 27o (2026-10-28): V_OFF depth read from parent MED Center tray xdata
;;;   (was fitting nth 5 = flange -> 0.8125). Now (6+0.125)/2 = 3.0625.
;;; 27n (2026-10-28): Clint rule - pivot = p1 + along*PARENT-OFF (along = non-fitting
;;;  MED Center dir at p1, toward p2, plan), Z = p1.Z + (depth+mat)/2.
;;; 27m (2026-10-28): parent frame = LEVEL parent MED_TRAY only (ssget "_X", UCS-safe;
;;;   skips MED_FITTING centers; rejects sloping trays |along.Z|>0.15 = bridge).
;;;   Main end = center end nearest a level parent. Never orient from bridge diagonal.
;;;   INSERT = swivel point unchanged.
;;;
;;; Swivel point (one per rail):
;;;  XY = baseTrayEnd + along*PARENT-OFF +/- cross*half
;;;  Z  = baseTrayEnd.Z + (depth+mat)/2     [never mid of sloping center]
;;; Orient: plan bearing of parent + 90 deg stand about along (+ 180 deg flip for R).
;;; Dyn Angle parked; set later from center tilt.
;;;
;;; Bridge face A = swivelA + unit(swivelB-swivelA)*BRIDGE-OFF
;;; Bridge face B = swivelB + unit(swivelA-swivelB)*BRIDGE-OFF
;;;
;;; Fitting code *MEDSW-FITCODE* (390) = tray swivel (NOT a reducer - no #ITEM_ALT size).
;;; 3D export: L/R PAIR of 3DTrayVerticalAdjSplice per end (four inserts / bridge).
;;; ActiveX InsertBlock + TransformBy (no (command) under MEDMAKE3D).
;;; Parent-tray plan UCS - not the center diagonal.
;;; Size/code/tag/depth/flange from that end's tray (same size both ends of center).
;;; 27aa (2026-10-28): TRAYSWIVEL sets UCS _OB to tray A for whole place
;;;   (boxes used current UCS, bridge/center used World-Z up) - restored on exit/*error*.
;;; 27ab (2026-10-28): UCS Object via (command) not vl-cmdf (ladder pattern);
;;;   World if tray A extrusion = Z; status line + 'did not stick' warning.
;;;   3D export (MEDMAKE3D) unchanged from 27z.
;;; Load: (load "MEDTraySwivel") or APPLOAD. Command: TRAYSWIVEL.
(vl-load-com)

(if (not *MEDSW-PARENT-OFF*) (setq *MEDSW-PARENT-OFF* 5.0451))
(if (not *MEDSW-BRIDGE-OFF*) (setq *MEDSW-BRIDGE-OFF* 5.0357))
(if (not *MEDSW-UCSD*)      (setq *MEDSW-UCSD* 0))
(setq *MEDSW-FITCODE* 367) ; swxdata 2026-10-29: MEDType FITTING 367 'Vertical Swivel Splice Plate Pair' (was 390 = VINELBOW)
(if (not (boundp (quote *MEDSW-DEBUG*))) (setq *MEDSW-DEBUG* nil))
;; *MEDSW-DEBUG*: set to T, e.g. (setq *MEDSW-DEBUG* T), to place SW#-L/R diagnostic TEXT.
(if (not *MEDSW-3DBLOCK*)    (setq *MEDSW-3DBLOCK* "3DTrayVerticalAdjSplice"))

(defun medsw_wpts (ent / ed el nv)
  (setq ed (entget ent) el (cdr (assoc 38 ed)) nv (cdr (assoc 210 ed)))
  (mapcar
    (function (lambda (p) (trans (list (car p) (cadr p) el) nv 0)))
    (mapcar (function cdr)
            (vl-remove-if-not (function (lambda (x) (= (car x) 10))) ed)))
)

(defun medsw_unit (a b / d)
  (setq d (distance a b))
  (if (< d 1e-9)
    (list 0.0 0.0 0.0)
    (list (/ (- (car b) (car a)) d)
          (/ (- (cadr b) (cadr a)) d)
          (/ (- (caddr b) (caddr a)) d)))
)

(defun medsw_add (p v s)
  (list (+ (car p) (* s (car v)))
        (+ (cadr p) (* s (cadr v)))
        (+ (caddr p) (* s (caddr v))))
)

(defun medsw_cross (a b)
  (list (- (* (cadr a) (caddr b)) (* (caddr a) (cadr b)))
        (- (* (caddr a) (car b)) (* (car a) (caddr b)))
        (- (* (car a) (cadr b)) (* (cadr a) (car b))))
)

(defun medsw_len (v)
  (sqrt (+ (* (car v) (car v)) (* (cadr v) (cadr v)) (* (caddr v) (caddr v))))
)

(defun medsw_norm (v / L)
  (setq L (medsw_len v))
  (if (< L 1e-9) (list 0.0 0.0 0.0)
    (list (/ (car v) L) (/ (cadr v) L) (/ (caddr v) L)))
)

;; Degrees between two unit vectors (atan |u x v|, u.v).
(defun medsw_ang_deg (u v / dot c L)
  (setq dot (+ (* (car u) (car v)) (* (cadr u) (cadr v)) (* (caddr u) (caddr v)))
        c   (medsw_cross u v)
        L   (medsw_len c)
        dot (max -1.0 (min 1.0 dot)))
  (* (/ 180.0 pi) (atan L dot))
)

;; plan-perpendicular to horizontal part of v (for UCS 3P side point)
(defun medsw_plan_perp (v / x y n)
  (setq x (car v) y (cadr v) n (sqrt (+ (* x x) (* y y))))
  (if (< n 1e-9)
    (list 0.0 1.0 0.0)
    (list (/ (- y) n) (/ x n) 0.0))
)

(defun medsw_pick (msg / sel ent info pts pk a b)
  (setq info nil)
  (while (not info)
    (setq sel (entsel msg))
    (if sel
      (progn
        (setq ent (car sel) info (xdataget ent _TRAY))
        (if (or (not info) (/= (cdr (assoc 0 (entget ent))) "LWPOLYLINE"))
          (progn (setq info nil) (princ "\nNot a MED tray centerline.")))
      )
    )
  )
  (setq pts (medsw_wpts ent)
        pk  (trans (cadr sel) 1 0)
        a   (car pts)
        b   (last pts))
  (if (<= (distance (list (car pk) (cadr pk)) (list (car a) (cadr a)))
          (distance (list (car pk) (cadr pk)) (list (car b) (cadr b))))
    (list ent info a (cadr pts))
    (list ent info b (cadr (reverse pts))))
)

(defun medsw_out (e)
  (medsw_unit (cadddr e) (caddr e))
)

(defun medsw_insert (e)
  (medsw_add (caddr e) (medsw_out e) *MEDSW-PARENT-OFF*)
)

;; 2D box rail-to-rail spanning parent face -> insert (swivel zone).
(defun medsw_box (e / info end mid dir crs half len nv pts)
  (setq info (cadr e)
        end  (trans (caddr e) 0 1)
        half (* 0.5 (+ (nth 2 info) (nth 7 info)))
        dir  (angle (trans (cadddr e) 0 1) end)
        crs  (+ dir (* PI 0.5))
        mid  (polar end dir (* 0.5 *MEDSW-PARENT-OFF*))
        len  (* 0.5 *MEDSW-PARENT-OFF*))
  ;; 27ac: build in current (tray Object) UCS, write in tray A OCS (210).
  (setq nv (if *MEDSW-PLACE-NV* *MEDSW-PLACE-NV*
             (cdr (assoc 210 (entget (car e))))))
  (if (null nv) (setq nv '(0.0 0.0 1.0)))
  (setq pts (mapcar (function (lambda (p) (trans p 1 nv)))
              (list
                (polar (polar mid crs half) dir len)
                (polar (polar mid crs half) (+ dir PI) len)
                (polar (polar mid crs (- half)) (+ dir PI) len)
                (polar (polar mid crs (- half)) dir len))))
  ;; 27ak: direct entmake - MEDPlineMake got 2D pts and re-trans'd them at Z=0
  ;; (MEDTransPointListToUCS), dropping boxes to elev 0.  DXF 38 = this end's
  ;; parent tray OCS Z (pts built from the parent end, which carries its elev).
  (entmake
    (append
      (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity")
            (cons 8 (if CR_LAYER CR_LAYER (getvar "CLAYER")))
            '(100 . "AcDbPolyline") (cons 90 (length pts)) '(70 . 1)
            '(43 . 0.0) (cons 38 (caddr (car pts))) '(39 . 0.0))
      (apply (function append)
        (mapcar (function (lambda (p) (list (cons 10 (list (car p) (cadr p)))
                                            '(40 . 0.0) '(41 . 0.0) '(42 . 0.0))))
                pts))
      (list (cons 210 nv))))
  (setq CR_LAYER nil)
  (princ (strcat "\n  Swivel box 27ak elev=" (rtos (caddr (car pts)) 2 4)))
  (entlast)
)

;; MED Center main tray end -> drop/bridge face + MED_FITTING swivel xdata.
;; Fitting is same-size (alt nil) - angle is NOT #ITEM_ALT; 3D reads center ends.
;; 27aa: along/side computed in CURRENT UCS (= picked tray Object UCS under
;; TRAYSWIVEL) so the 3P plane is "up" relative to the tray, not World Z.
(defun medsw_fit_center (e face / info end out along side mlist xd ent eu fu)
  (setq info  (cadr e)
        end   (caddr e)
        out   (medsw_out e)
        eu    (trans end 0 1)
        fu    (trans face 0 1)
        along (medsw_unit eu fu)
        side  (trans (medsw_add eu (medsw_plan_perp along) 1.0) 1 0))
  (vl-cmdf "._UCS" "_3P"
           "_non" (trans end 0 1)
           "_non" (trans face 0 1)
           "_non" (trans side 0 1))
  (setq *MEDSW-UCSD* (1+ *MEDSW-UCSD*))
  (setvar "CLAYER" (car _MEDCENLAY))
  (setq mlist (list (list (trans end 0 1) nil)
                    (list (trans face 0 1) nil)))
  (MEDMakeTray mlist nil _MEDCENLAY nil)
  ;; swxdata2 2026-10-29: complete 6-field MED_FITTING only (code 367, Alt 0.0). No MED_TRAY.
  (setq ent (entlast)
        xd  (bld_fitting *MEDSW-FITCODE* (nth 2 info) (nth 1 info) 0.0 (nth 5 info) (nth 7 info)))
  (xdatadd ent xd)
  (vl-cmdf "._UCS" "_P")
  (setq *MEDSW-UCSD* (1- *MEDSW-UCSD*))
  ent
)

;;; ------------------------------------------------------------------
;;; 3D export: L/R pair of 3DTrayVerticalAdjSplice per swivel end.
;;; ActiveX only (InsertBlock + TransformBy + dyn Angle) - no (command).
;;; ------------------------------------------------------------------
(defun medsw_find_splice ( / f support)
  (cond
    ((setq f (findfile (strcat *MEDSW-3DBLOCK* ".dwg"))) f)
    ((setq f (findfile (strcat "Dwg3D/" *MEDSW-3DBLOCK* ".dwg"))) f)
    ((setq f (findfile (strcat "../Dwg3D/" *MEDSW-3DBLOCK* ".dwg"))) f)
    ((and (setq support (findfile "MEDTraySwivel.lsp"))
          (setq f (findfile
                    (strcat (vl-filename-directory support)
                            "/../Dwg3D/" *MEDSW-3DBLOCK* ".dwg"))))
      f)
    (T nil))
)

(defun medsw_ensure_splice ( / path doc ms obj)
  (cond
    ((tblsearch "BLOCK" *MEDSW-3DBLOCK*) T)
    ((setq path (medsw_find_splice))
      ;; ActiveX path insert loads the DWG as a block def - no (command).
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
            ms  (vla-get-ModelSpace doc)
            obj (vl-catch-all-apply
                  (function vla-InsertBlock)
                  (list ms (vlax-3d-point 0.0 0.0 0.0) path 1.0 1.0 1.0 0.0)))
      (cond
        ((vl-catch-all-error-p obj)
          (princ (strcat "\n  Could not load " *MEDSW-3DBLOCK* ": "
                         (vl-catch-all-error-message obj)))
          nil)
        (T
          (vl-catch-all-apply (function vla-Delete) (list obj))
          (not (null (tblsearch "BLOCK" *MEDSW-3DBLOCK*))))))
    (T
      (princ (strcat "\n" *MEDSW-3DBLOCK* ".dwg not on Support path / Dwg3D."))
      nil))
)

;; Set dynamic Angle property (deg). 27t: hardened - never throws, ANGLE or ANGLE1.
(defun medsw_dyn_angle_work (ename deg / obj props lst p name val hit names)
  (setq hit nil names "")
  (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
  (if (and obj (not (vl-catch-all-error-p obj))
           (eq (vl-catch-all-apply 'vla-get-IsDynamicBlock (list obj)) :vlax-true))
    (progn
      (setq props (vl-catch-all-apply 'vlax-invoke (list obj 'GetDynamicBlockProperties)))
      (cond
        ((or (null props) (vl-catch-all-error-p props)) (setq lst nil))
        ((= (type props) 'LIST) (setq lst props))
        (T (setq lst (vl-catch-all-apply
                       (function (lambda (v) (vlax-safearray->list (vlax-variant-value v))))
                       (list props)))
           (if (vl-catch-all-error-p lst) (setq lst nil))))
      (foreach p lst
        (setq name (vl-catch-all-apply 'vla-get-PropertyName (list p)))
        (if (and name (= (type name) 'STR))
          (progn
            (setq name (strcase name) names (strcat names " " name))
            (if (and (not hit) (or (= name "ANGLE") (= name "ANGLE1"))
                     (not (eq (vl-catch-all-apply 'vla-get-ReadOnly (list p)) :vlax-true)))
              (progn
                ;; ActiveX Angle params = radians; palette shows degrees; try rad then deg.
                (setq val (vl-catch-all-apply 'vla-put-Value
                            (list p (* pi (/ deg 180.0)))))
                (if (vl-catch-all-error-p val)
                  (setq val (vl-catch-all-apply 'vla-put-Value (list p deg))))
                (if (not (vl-catch-all-error-p val)) (setq hit T)))))))))
  (if (not hit)
    (princ (strcat "\n  Swivel WARNING dynAngle not set (" (rtos deg 2 2)
                   " deg). Props:" names)))
  hit
)
(defun medsw_set_dyn_angle (ename deg / r)
  (if (and ename (numberp deg))
    (progn
      (setq r (vl-catch-all-apply (function medsw_dyn_angle_work) (list ename deg)))
      (if (vl-catch-all-error-p r)
        (princ (strcat "\n  Swivel WARNING dynAngle error: "
                       (vl-catch-all-error-message r))))))
  ename
)

;; Bend angle (deg): tilt of MED Center main->drop off horizontal.
(defun medsw_angle_from_center (p1 p2 / along horiz)
  (setq along (medsw_unit p1 p2)
        horiz (list (car along) (cadr along) 0.0)
        horiz (medsw_norm horiz))
  (if (< (medsw_len horiz) 1e-9)
    90.0
    (medsw_ang_deg horiz along))
)

;; 27ae: tilt (deg) of p1->p2 off the plane perpendicular to UP.  up=(0,0,1) == medsw_angle_from_center.
(defun medsw_dot3 (a b) (+ (* (car a) (car b)) (* (cadr a) (cadr b)) (* (caddr a) (caddr b))))
(defun medsw_perp_up (v up / d)
  (setq d (medsw_dot3 v up))
  (mapcar (function (lambda (x u) (- x (* d u)))) v up))
(defun medsw_angle_from_up (p1 p2 up / dir proj)
  (setq dir (medsw_unit p1 p2)
        proj (medsw_perp_up dir up))
  (if (< (medsw_len proj) 1e-9)
    90.0
    (medsw_ang_deg (medsw_norm proj) dir))
)
(defun medsw_up_dist (a b up)
  (medsw_len (medsw_perp_up (mapcar (function -) a b) up))
)

;; ActiveX helpers - never (command) under MEDMAKE3D (bad order function: COMMAND).
(defun medsw_acad ( / )
  (vlax-get-acad-object)
)
(defun medsw_doc ( / )
  (vla-get-ActiveDocument (medsw_acad))
)
(defun medsw_ms ( / )
  (vla-get-ModelSpace (medsw_doc))
)

;; Rodrigues rotation about AXIS (unit) through ORIGIN by ANG radians -> TransformBy matrix.
(defun medsw_xform_rot (origin axis ang / ux uy uz c s omc
                                        r00 r01 r02 r10 r11 r12 r20 r21 r22
                                        ox oy oz tx ty tz)
  (setq axis (medsw_norm axis)
        ux (car axis) uy (cadr axis) uz (caddr axis)
        c  (cos ang) s (sin ang) omc (- 1.0 c)
        ox (car origin) oy (cadr origin) oz (caddr origin)
        r00 (+ c (* ux ux omc))
        r01 (- (* ux uy omc) (* uz s))
        r02 (+ (* ux uz omc) (* uy s))
        r10 (+ (* uy ux omc) (* uz s))
        r11 (+ c (* uy uy omc))
        r12 (- (* uy uz omc) (* ux s))
        r20 (- (* uz ux omc) (* uy s))
        r21 (+ (* uz uy omc) (* ux s))
        r22 (+ c (* uz uz omc))
        ;; t = O - R*O  (rotate about O, not WCS origin)
        tx (- ox (+ (* r00 ox) (* r01 oy) (* r02 oz)))
        ty (- oy (+ (* r10 ox) (* r11 oy) (* r12 oz)))
        tz (- oz (+ (* r20 ox) (* r21 oy) (* r22 oz))))
  (list (list r00 r01 r02 tx)
        (list r10 r11 r12 ty)
        (list r20 r21 r22 tz)
        (list 0.0 0.0 0.0 1.0))
)

(defun medsw_xform_apply (obj origin axis deg / mat)
  (setq mat (medsw_xform_rot origin axis (* pi (/ deg 180.0))))
  (vl-catch-all-apply
    (function vla-TransformBy)
    (list obj (vlax-tmatrix mat)))
)

;; Place block with INSERT = swivel point PT (no insert-offset math).
;; Orient only: plan bearing of parent along, 90 deg stand about along, optional
;; 180 deg about up for opposite rail. Dyn Angle only if DYNANG is a number.
;; 27ad: frame-mapped placement.  Insert at WCS origin rot 0, apply the 27z
;; sequence in a canonical local frame (along=X, up=Z), then ONE TransformBy
;; M = [along | up x along | up | pt].  On WCS trays this equals 27z exactly.
(defun medsw_frame_mat (pt along up / y)
  (setq y (medsw_norm (medsw_cross up along)))
  (list (list (car along) (car y) (car up) (car pt))
        (list (cadr along) (cadr y) (cadr up) (cadr pt))
        (list (caddr along) (caddr y) (caddr up) (caddr pt))
        (list 0.0 0.0 0.0 1.0))
)
(defun medsw_ins_one (pt along up dynang flip / obj e res o)
  (setq o (list 0.0 0.0 0.0)
        res (vl-catch-all-apply
              (function vla-InsertBlock)
              (list (medsw_ms) (vlax-3d-point o) *MEDSW-3DBLOCK* 1.0 1.0 1.0 0.0)))
  (if (vl-catch-all-error-p res)
    (progn
      (princ (strcat "\n  Swivel InsertBlock failed: "
                     (vl-catch-all-error-message res)))
      nil)
    (progn
      (setq obj res
            e   (vlax-vla-object->ename obj))
      ;; local: stand 90 about along(X); flip 180 about up(Z)
      (medsw_xform_apply obj o (list 1.0 0.0 0.0) 90.0)
      (if (minusp flip)
        (progn
          (medsw_xform_apply obj o (list 0.0 0.0 1.0) 180.0)
          ;; 27s/27x R-type: R180up then R180along (was done after insert)
          (medsw_xform_apply obj o (list 0.0 0.0 1.0) 180.0)
          (medsw_xform_apply obj o (list 1.0 0.0 0.0) 180.0)))
      (vl-catch-all-apply (function vla-TransformBy)
        (list obj (vlax-tmatrix (medsw_frame_mat pt along up))))
      (if (numberp dynang)
        (vl-catch-all-apply (function medsw_set_dyn_angle) (list e dynang)))
      e))
)

;; XY-only distance (center Z can disagree with tray elev).
(defun medsw_xy_dist (a b)
  (distance (list (car a) (cadr a)) (list (car b) (cadr b)))
)

;; Non-fitting MED Center direction at P (27n).  DIRECTION ONLY - not a position base.
;; ssget "_X" (UCS-safe): LWPOLYLINE with _TRAY xdata and no _FITTING xdata,
;; nearest end within tol of P (XY dist + 0.25*|dZ|).  Direction is taken from
;; that end toward its next vertex, flattened to plan (MED Center plane), and
;; flipped to point toward TOWARD (p1->p2).  Returns unit along or nil.
(defun medsw_center_dir (p toward / ss i ent pts a b da db end nxt dir best sbest sc tol)
  (setq tol 8.0 sbest 1e99 best nil *MEDSW-CENTER-ENT* nil
        ss (ssget "_X" (list (cons 0 "LWPOLYLINE"))))
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i) i (1+ i))
        (if (and (xdataget ent _TRAY) (not (xdataget ent _FITTING)))
          (progn
            (setq pts (medsw_wpts ent)
                  a (car pts) b (last pts)
                  da (medsw_xy_dist a p) db (medsw_xy_dist b p))
            (if (<= da db)
              (setq end a nxt (cadr pts))
              (setq end b nxt (cadr (reverse pts)) da db))
            ;; 27z: off the OPEN end (parent body -> end -> bridge), not fitting order.
            (setq dir (medsw_unit nxt end))
            (if (and dir (< da tol))
              (progn
                (setq dir (list (car dir) (cadr dir) 0.0))
                (if (> (medsw_len dir) 1e-9)
                  (progn
                    (setq sc (+ da (* 0.25 (abs (- (caddr end) (caddr p))))))
                    (if (< sc sbest)
                      (setq sbest sc best (medsw_norm dir) *MEDSW-CENTER-ENT* ent)))))))))))
  ;; 27z: no flip toward p1->p2 (that put the pivot into the parent when the
  ;; fitting vertex order ran backward).  Just record disagreement.
  (setq *MEDSW-ALONG-FLIP* (and best toward
           (< (+ (* (car best) (car toward)) (* (cadr best) (cadr toward))) 0.0)))
  best
)

;; 27ad: unflattened parent dir off the open end nearest P (nxt->end).
(defun medsw_center_dir3 (cent p / pts a b)
  (if (and cent (setq pts (medsw_wpts cent)))
    (progn
      (setq a (car pts) b (last pts))
      (if (<= (distance a p) (distance b p))
        (medsw_unit (cadr pts) a)
        (medsw_unit (cadr (reverse pts)) b))))
)

;; L/R pair at swivel pivot (27n) - Clint's rule:
;;   pivot_xy = p1 + along * PARENT-OFF  (along = non-fitting MED Center dir at p1,
;;              toward p2, on the center plane)
;;   pivot.Z  = p1.Z + V_OFF,  V_OFF = (TrayDepth + TrayMaterial)/2
;; Dyn Angle parked; orientation polish is the next step.  Returns (eL eR).
;; 27q: tag diagnostic.  TEXT at insert pt + 1.0 Z on the insert's layer, red.
(setq *MEDSW-TAG-N* 0)
(defun medsw_tag (e tag flip wpt / obj pt lay txt)
  (if e
    (progn
      (setq pt (if wpt wpt (trans (cdr (assoc 10 (entget e))) e 0))
            lay (cdr (assoc 8 (entget e))))
      (setq txt (vl-catch-all-apply (function vla-AddText)
                  (list (medsw_ms) tag
                        (vlax-3d-point (list (car pt) (cadr pt) (+ (caddr pt) 1.0))) 1.0)))
      (if (not (vl-catch-all-error-p txt))
        (progn
          (vl-catch-all-apply (function vla-put-Layer) (list txt lay))
          (vl-catch-all-apply (function vla-put-Color) (list txt 1))))
      (princ (strcat "\n  Swivel tag " tag
                     " handle=" (cdr (assoc 5 (entget e)))
                     " flip=" (if (minusp flip) "-1" "+1")
                     " WCS pt=(" (rtos (car pt) 2 4) "," (rtos (cadr pt) 2 4) ","
                     (rtos (caddr pt) 2 4) ")"))
      tag))
)

;; 27w: tilt (deg off horizontal) of the sloped non-fitting MED Center (bridge tray)
;; whose nearest end is near PDROP (fitting p2).  Score XY dist + 0.25*|dZ|, tol 24.
;; Must slope: |along Z| > 0.15 (level parents never win).  Returns deg or nil.
(setq *MEDSW-BRIDGE-ENT* nil)
(defun medsw_bridge_phi (pDrop up / ss i ent pts a b da db end nxt dir best sbest sc tol)
  (setq tol 24.0 sbest 1e99 best nil *MEDSW-BRIDGE-ENT* nil
        ss (ssget "_X" (list (cons 0 "LWPOLYLINE"))))
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i) i (1+ i))
        (if (and (xdataget ent _TRAY) (not (xdataget ent _FITTING)))
          (progn
            (setq pts (medsw_wpts ent)
                  a (car pts) b (last pts)
                  da (medsw_up_dist a pDrop up) db (medsw_up_dist b pDrop up))
            (if (<= da db)
              (setq end a nxt (cadr pts))
              (setq end b nxt (cadr (reverse pts)) da db))
            (if (and end nxt (< da tol))
              (progn
                (setq dir (medsw_unit end nxt))
                (if (and dir (> (abs (medsw_dot3 dir up)) 0.15))
                  (progn
                    (setq sc (+ da (* 0.25 (abs (medsw_dot3 (mapcar (function -) end pDrop) up)))))
                    (if (< sc sbest)
                      (setq sbest sc best (list end nxt) *MEDSW-BRIDGE-ENT* ent)))))))))))
  (if best
    (medsw_angle_from_up (car best) (cadr best) up)
    nil)
)

;; 27y: rise/drop sense of the transition relative to THIS fitting end.
;; Uses *MEDSW-BRIDGE-ENT* (set by medsw_bridge_phi): Z of the bridge far end
;; minus Z of its end nearest P2.  Fallback: p2.Z - p1.Z.  Returns +1 or -1.
(defun medsw_bridge_sense (p1 p2 up / pts a b dz)
  (setq dz nil)
  (if (and *MEDSW-BRIDGE-ENT* (setq pts (medsw_wpts *MEDSW-BRIDGE-ENT*)))
    (progn
      (setq a (car pts) b (last pts))
      (if (<= (medsw_up_dist a p2 up) (medsw_up_dist b p2 up))
        (setq dz (medsw_dot3 (mapcar (function -) b a) up))
        (setq dz (medsw_dot3 (mapcar (function -) a b) up)))))
  (if (or (null dz) (< (abs dz) 1e-6))
    (setq dz (medsw_dot3 (mapcar (function -) p2 p1) up)))
  (if (minusp dz) -1 1)
)

;; 27ag: 2D MEDTRAY{desc} -> 3D MED_3DTRAY-{desc} (same substr-10 rule as MEDSet3DTrayLayer).
(defun medsw_3dlay_name (lay2d)
  (if (and lay2d (wcmatch (strcase lay2d) "MED_TRAY*,MEDTRAY*"))
    (strcat "MED_3DTRAY-" (substr lay2d 10))
    nil))

;; 27ag: layer of nearest non-fitting _TRAY LWPOLYLINE end on MEDTRAY* (not MEDCENTER*).
(defun medsw_parent_tray_layer (p / ss i ent lay pts a b da sc best sbest tol)
  (setq tol 24.0 sbest 1e99 best nil
        ss (ssget "_X" (list (cons 0 "LWPOLYLINE"))))
  (if (and ss p)
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i) i (1+ i)
              lay (cdr (assoc 8 (entget ent))))
        (if (and (wcmatch (strcase lay) "MED_TRAY*,MEDTRAY*")
                 (xdataget ent _TRAY) (not (xdataget ent _FITTING)))
          (progn
            (setq pts (medsw_wpts ent) a (car pts) b (last pts))
            (foreach e (list a b)
              (setq da (medsw_xy_dist e p)
                    sc (+ da (* 0.25 (abs (- (caddr e) (caddr p))))))
              (if (and (< da tol) (< sc sbest))
                (setq sbest sc best lay))))))))
  best
)

;; 27ag: make sure 3D layer exists (color from MEDTRAY{desc}; fallback 2).
(defun medsw_ensure_3dlay (lay / desc col)
  (if (and lay (not (tblsearch "layer" lay)))
    (progn
      (setq desc (substr lay 12)
            col (if (boundp (quote MEDGetLayerColor))
                  (vl-catch-all-apply (function MEDGetLayerColor) (list (strcat "MEDTRAY" desc)))
                  nil))
      (if (or (null col) (vl-catch-all-error-p col) (not (numberp col))) (setq col 2))
      (if (boundp (quote medsmlayer))
        (vl-catch-all-apply (function medsmlayer) (list (list lay col "Continuous" nil)))
        (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                       (cons 2 lay) '(70 . 0) (cons 62 col) '(6 . "Continuous"))))))
  lay)

(defun medsw_3d_pair (ent / swlay cent xd w f dpth mat voff pts p1 p2 tow along up
                            cross half pivot ptL ptR eL eR oldos oldlay tgs
                            phi phiSrc angA angB dynL dynR objR sense fup fal alongShift)
  (if (not (medsw_ensure_splice))
    nil
    (progn
      (setq xd  (xdataget ent _FITTING)
            w   (nth 2 xd)
            f   nil ; swxdata: pinned to pre-Alt value (nth 6 was nil) so 27aj/27ak inserts stay put
            mat (if (and (boundp (quote MED_TRAY_MATERIALWIDTH))
                         (numberp MED_TRAY_MATERIALWIDTH))
                  MED_TRAY_MATERIALWIDTH 0.125)
            pts (medsw_wpts ent)
            p1  (car pts)
            p2  (last pts)
            tow (mapcar (function -) p2 p1)
            along (medsw_center_dir p1 tow)
            cent *MEDSW-CENTER-ENT*)
      ;; 27o: depth from parent non-fitting MED Center tray xdata (cdr idx 4).
      ;; Fitting xdata omits ALT so its nth 5 was FLANGE (gave V_OFF 0.8125).
      (setq dpth (if cent (nth 4 (cdr (xdataget cent _TRAY))) nil))
      (if (not along)
        (progn
          (princ "\n  Swivel WARNING: no non-fitting MED Center at p1 - using p1->p2 in plan.")
          (setq along (if (> (medsw_len tow) 1e-9) (medsw_norm tow) (list 1.0 0.0 0.0)))))
      ;; 27ac: up = fitting extrusion (fallback parent center, World Z).
      (setq up (cdr (assoc 210 (entget ent))))
      (if (and (null up) cent) (setq up (cdr (assoc 210 (entget cent)))))
      (if (or (null up) (< (medsw_len up) 1e-9)) (setq up (list 0.0 0.0 1.0)))
      (setq up    (medsw_norm up)
            cross (medsw_norm (medsw_cross along up)))
      ;; 27ad: orientation frame from FLAT PARENT TRAY (positions stay 27ac).
      (setq fup (if cent (cdr (assoc 210 (entget cent)))))
      (if (null fup) (setq fup (cdr (assoc 210 (entget ent)))))
      (if (or (null fup) (< (medsw_len fup) 1e-9)) (setq fup (list 0.0 0.0 1.0)))
      (setq fup (medsw_norm fup)
            fal (medsw_center_dir3 cent p1))
      (if (null fal) (setq fal along))
      (setq fal (mapcar (function -) fal
                  (mapcar (function (lambda (u) (* u (apply (function +) (mapcar (function *) fal fup))))) fup)))
      (setq fal (if (> (medsw_len fal) 1e-9) (medsw_norm fal) along))
      (if (null f) (setq f 0.0))
      (if (or (null dpth) (not (numberp dpth)) (<= dpth 0.0)) (setq dpth 6.0))
      (setq voff  (* 0.5 (+ dpth mat))
            half  (* 0.5 (+ w (if (< f 0.0) 0.0 f)))
            ;; 27ah: pivot/cross from unflattened parent frame fal/fup (fixes Front creep).
            ;; 27aj: WCS (fup=World Z) -> 27z pivot (flat along, Z+V_OFF); else fal/fup.
            cross nil pivot nil
            oldos (getvar "OSMODE")
            oldlay (getvar "CLAYER"))
      (if (> (abs (caddr fup)) 0.999)
        (setq along (medsw_norm (list (car along) (cadr along) 0.0))
              cross (medsw_norm (medsw_cross along (list 0.0 0.0 1.0)))
              pivot (list (+ (car p1) (* (car along) *MEDSW-PARENT-OFF*))
                          (+ (cadr p1) (* (cadr along) *MEDSW-PARENT-OFF*))
                          (+ (caddr p1) voff)))
        (setq cross (medsw_norm (medsw_cross fal fup))
              pivot (medsw_add (medsw_add p1 fal *MEDSW-PARENT-OFF*) fup voff)))
      (setvar "OSMODE" 0)
      (if (and (boundp (quote MEDSet3DTrayLayer)) (boundp (quote _MED3DTRAY)))
        (MEDSet3DTrayLayer ent)
        (if (boundp (quote _MED3DTRAY)) (setvar "CLAYER" (car _MED3DTRAY))))
      ;; 27s: bolt-head-inside. Swap L/R positions, extra 180 on R-type,
      ;; dyn Angle from transition slope; diagonals match (SW1-L=SW2-R=360-phi).
      ;; 27w: phi from bridge tray slope at p2; fallback fitting p1->p2.
      (setq phi (vl-catch-all-apply (function medsw_bridge_phi) (list p2 fup))
            phiSrc "bridge")
      (if (or (vl-catch-all-error-p phi) (not (numberp phi)))
        (progn
          (princ "\n  Swivel WARNING: bridge tray not found at p2 - phi from fitting centerline.")
          (setq phi (vl-catch-all-apply (function medsw_angle_from_up) (list p1 p2 fup))
                phiSrc "fitting")))
      (if (or (vl-catch-all-error-p phi) (not (numberp phi)))
        (setq phi nil angA nil angB nil)
        (setq angA (- 360.0 phi)
              angA (if (>= angA 359.999) 0.0 angA)
              angB phi))
      ;; 27aj: alongShift removed (27ah/ai reverted).
      (setq alongShift 0.0
            ptL   (medsw_add pivot cross half)
            ptR   (medsw_add pivot cross (- half)))
      (setq *MEDSW-TAG-N* (1+ *MEDSW-TAG-N*)
            tgs (strcat "SW" (itoa *MEDSW-TAG-N*)))
      ;; 27y: diagonal from RELATIVE tray points, not tag parity.  sense = +1 when
      ;; the bridge rises leaving this fitting (p2 -> bridge far end), -1 when it
      ;; drops.  Up right->left (old SW1 parity) = rising -> dynL=360-phi.
      (setq sense (medsw_bridge_sense p1 p2 fup))
      ;; 27z: 27y mapping was inverted (every 27y joint, incl. up R->L, bent away
      ;; from the bridge).  Rising -> dynL=phi, dynR=360-phi.
      (if (> sense 0)
        (setq dynL angB dynR angA)
        (setq dynL angA dynR angB))
      ;; 27t: place both plates first (no dyn), R180, THEN dyn Angle.
      (setq eL (medsw_ins_one ptR fal fup nil 1.0)
            eR (medsw_ins_one ptL fal fup nil -1.0))
      (if eR
        (progn
          (setq objR (vl-catch-all-apply (function vlax-ename->vla-object) (list eR)))
          (if (not (vl-catch-all-error-p objR))
            (progn
              ;; 27ad: R180up+R180along now applied in local frame (medsw_ins_one).
              (princ)))))
      (if (and eL (numberp dynL))
        (vl-catch-all-apply (function medsw_set_dyn_angle) (list eL dynL)))
      (if (and eR (numberp dynR))
        (vl-catch-all-apply (function medsw_set_dyn_angle) (list eR dynR)))
      ;; 27ag: swivels on the run's 3D tray layer MED_3DTRAY-{desc}.
      (setq swlay (cond ((medsw_3dlay_name (medsw_parent_tray_layer p1)))
                        ((and cent (medsw_3dlay_name (cdr (assoc 8 (entget cent))))))
                        ((medsw_3dlay_name (cdr (assoc 8 (entget ent)))))
                        (T (getvar "CLAYER"))))
      (medsw_ensure_3dlay swlay)
      (foreach e (list eL eR)
        (if e
          (vl-catch-all-apply
            (function (lambda (x) (vla-put-Layer (vlax-ename->vla-object x) swlay)))
            (list e))))
      ;; 27af: tags only in debug.
      (if *MEDSW-DEBUG*
        (progn
          (vl-catch-all-apply (function medsw_tag) (list eL (strcat tgs "-L") 1.0 ptR))
          (vl-catch-all-apply (function medsw_tag) (list eR (strcat tgs "-R") -1.0 ptL))))
      (setvar "OSMODE" oldos)
      (setvar "CLAYER" oldlay)
      (princ (strcat "\n  Swivel 27aj alongShift=" (rtos alongShift 2 4) " layer=" (if swlay swlay "?") " debug=" (if *MEDSW-DEBUG* "on" "off") " up=(" (rtos (car fup) 2 4) "," (rtos (cadr fup) 2 4) "," (rtos (caddr fup) 2 4) ")"
                     " along=(" (rtos (car fal) 2 4) "," (rtos (cadr fal) 2 4) "," (rtos (caddr fal) 2 4) ") frame=parentTray"
                     "  center=" (if cent "matched" "NONE")
                     "  depth=" (rtos dpth 2 4)
                     "  p1Z=" (rtos (caddr p1) 2 4)
                     "  V_OFF=" (rtos voff 2 4)
                     "  Z=" (rtos (caddr pivot) 2 4)
                     "  along=(" (rtos (car along) 2 4) "," (rtos (cadr along) 2 4) ")"
                     "  tags=" tgs "-L," tgs "-R"
                     "  phi=" (if phi (rtos phi 2 2) "nil")
                     "  phiSrc=" phiSrc
                     "  dynL=" (if dynL (rtos dynL 2 2) "nil")
                     "  dynR=" (if dynR (rtos dynR 2 2) "nil")
                     "  swapped+R180up+R180along"
                     "  upSense=" (if (> sense 0) "+ rise" "- down")
                     "  standDeg=+90  alongFlip=" (if *MEDSW-ALONG-FLIP* "Y(vs p1p2)" "N")
                     "  alongZ=" (rtos (caddr along) 2 3)))
      (if (and eL eR)
        (list eL eR)
        (progn (princ "\n  Swivel pair incomplete.") nil))))
)

(defun MEDConvertTraySwivelTo3D (trayfitent / pair)
  (setq pair (medsw_3d_pair trayfitent))
  (if (not pair)
    (princ (strcat "\n  Swivel 3D: skipped (need " *MEDSW-3DBLOCK* " + valid center).")))
  pair
)

;; 27ac: TRAYFIX pattern - named save, World or Object+origin shift, ELEVATION.
(if (not (boundp (quote *MEDSW-UCSSET*))) (setq *MEDSW-UCSSET* nil))
(defun medsw_ucs_begin (ent / nv umode ed el)
  (setq ed (entget ent)
        nv (cdr (assoc 210 ed))
        nv (if nv nv '(0.0 0.0 1.0))
        el (cdr (assoc 38 ed))
        *MEDSW-OLDELEV* (getvar "ELEVATION"))
  (if (tblsearch "UCS" "MEDSwTmp") (command "_.UCS" "_NA" "_D" "MEDSwTmp"))
  (command "_.UCS" "_NA" "_S" "MEDSwTmp")
  (setq *MEDSW-UCSSET* T)
  (if (equal nv '(0.0 0.0 1.0) 1e-6)
    (progn (command "_.UCS" "_W") (setq umode "World"))
    (progn
      (command "_.UCS" "_OB" ent)
      (command "_.UCS" "_O" (trans '(0.0 0.0 0.0) 0 1))
      (setq umode "Object")))
  (setq *MEDSW-PLACE-NV* nv
        *MEDSW-PLACE-ELEV* (if el el 0.0))
  (setvar "ELEVATION" *MEDSW-PLACE-ELEV*)
  umode
)
(defun medsw_ucs_end (errp / )
  (if *MEDSW-UCSSET*
    (progn
      (if errp
        (progn (command-s "_.UCS" "_NA" "_R" "MEDSwTmp")
               (command-s "_.UCS" "_NA" "_D" "MEDSwTmp"))
        (progn (command "_.UCS" "_NA" "_R" "MEDSwTmp")
               (command "_.UCS" "_NA" "_D" "MEDSwTmp")))
      (setq *MEDSW-UCSSET* nil)))
  (if *MEDSW-OLDELEV* (setvar "ELEVATION" *MEDSW-OLDELEV*))
  (setq *MEDSW-OLDELEV* nil *MEDSW-PLACE-NV* nil *MEDSW-PLACE-ELEV* nil)
)

(defun medsw_ucs_unwind ( / )
  (while (and *MEDSW-UCSD* (> *MEDSW-UCSD* 0))
    (command-s "._UCS" "_P")
    (setq *MEDSW-UCSD* (1- *MEDSW-UCSD*)))
  (setq *MEDSW-UCSD* 0)
)

;; 27aa: whole place (boxes, centers, bridge) runs in tray A's Object UCS;
;; restored on exit and from *error*.  Math below is in that UCS (Z = tray up).
(defun c:trayswivel ( / ea eb info ia ib ua ub ba bb side xd oce oly
                         dpth mat voff nrm sh olderr iau ibu nv ox0 oy0 umode)
  (med_force_2d_wireframe)
  (setq oce (getvar "CMDECHO")
        oly (getvar "CLAYER")
        olderr *error*
        *MEDSW-UCSD* 0)
  (defun *error* (msg)
    (medsw_ucs_unwind)
    (medsw_ucs_end T)
    (setvar "CLAYER" oly)
    (setvar "CMDECHO" oce)
    (setq *error* olderr)
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (princ (strcat "\nTRAYSWIVEL error: " msg)))
    (princ))
  (setvar "CMDECHO" 0)
  (setq ea   (medsw_pick "\nSelect tray A near its open end: "))
    ;; 27ac: TRAYFIX-style (named MEDSwTmp, Object + origin shift; World only if Z)
  (setq nv  (cdr (assoc 210 (entget (car ea))))
        nv  (if nv nv '(0.0 0.0 1.0))
        ox0 (getvar "UCSXDIR")
        oy0 (getvar "UCSYDIR"))
  (setq umode (medsw_ucs_begin (car ea)))
  (princ (strcat "\n  TRAYSWIVEL 27ac: extrusion=(" (rtos (car nv) 2 4) " "
                 (rtos (cadr nv) 2 4) " " (rtos (caddr nv) 2 4)
                 ") place UCS=" umode " of tray A"
                 (if (= umode "Object") " (origin shifted to WCS 0)" "")
                 "  ELEV=" (rtos *MEDSW-PLACE-ELEV* 2 4)))
  (if (and (= umode "Object")
           (equal ox0 (getvar "UCSXDIR") 1e-9)
           (equal oy0 (getvar "UCSYDIR") 1e-9))
    (princ "\n  TRAYSWIVEL: UCS Object did not stick (UCSXDIR/UCSYDIR unchanged) - ignore if that UCS was already current."))
  (setq eb   (medsw_pick "\nSelect tray B near its open end: ")
        info (cadr ea)
        iau  (trans (medsw_insert ea) 0 1)
        ibu  (trans (medsw_insert eb) 0 1)
        ua   (medsw_unit iau ibu)
        ub   (medsw_unit ibu iau)
        ia   iau
        ib   ibu
        ba   (medsw_add iau ua *MEDSW-BRIDGE-OFF*)
        bb   (medsw_add ibu ub *MEDSW-BRIDGE-OFF*))
  ;; 27p: 3D pivots sit V_OFF straight UP from ia/ib, but the bridge hangs off
  ;; them PERPENDICULAR to its own slope.  Shift = V_OFF*(up - n), n = bridge
  ;; normal in its vertical plane.  Along-path part = V_OFF*sin(slope) uphill
  ;; (3.0625*sin 38 deg = 1.88); across part = -V_OFF*(1-cos(slope)).
  (setq dpth (nth 5 info)
        mat  (if (and (boundp (quote MED_TRAY_MATERIALWIDTH))
                      (numberp MED_TRAY_MATERIALWIDTH))
               MED_TRAY_MATERIALWIDTH 0.125))
  (if (or (not (numberp dpth)) (<= dpth 0.0)) (setq dpth 6.0))
  (setq voff (* 0.5 (+ dpth mat))
        nrm  (list (- (* (car ua) (caddr ua)))
                   (- (* (cadr ua) (caddr ua)))
                   (- 1.0 (* (caddr ua) (caddr ua)))))
  (if (> (medsw_len nrm) 1e-9)
    (progn
      (setq nrm (medsw_norm nrm)
            sh  (list (- (* voff 0.0) (* voff (car nrm)))
                      (- (* voff 0.0) (* voff (cadr nrm)))
                      (- voff (* voff (caddr nrm))))
            ba  (mapcar (function +) ba sh)
            bb  (mapcar (function +) bb sh))
      (princ (strcat "\n  Swivel 27p  V_OFF=" (rtos voff 2 4)
                     "  bridge along-shift=" (rtos (* voff (caddr ua)) 2 4)
                     "  across=" (rtos (- (* voff (caddr nrm)) voff) 2 4)))))
  ;; back to world coords for the draw helpers (they trans 0 1 themselves)
  (setq side (trans (medsw_add ba (medsw_plan_perp ua) 1.0) 1 0)
        ia   (trans ia 1 0)
        ib   (trans ib 1 0)
        ba   (trans ba 1 0)
        bb   (trans bb 1 0))
  (if (< (distance ia ib) (+ *MEDSW-BRIDGE-OFF* *MEDSW-BRIDGE-OFF* 1e-3))
    (princ "\nSwivel inserts too close for bridge faces - check gap / elevations.")
    (progn
      (setvar "CLAYER" (car _MEDTRAY))
      (medsw_box ea)
      (medsw_box eb)
      ;; MED Center + swivel MED_FITTING each end (main -> drop face)
      (medsw_fit_center ea ba)
      (medsw_fit_center eb bb)
      (vl-cmdf "._UCS" "_3P"
               "_non" (trans ba 0 1)
               "_non" (trans bb 0 1)
               "_non" (trans side 0 1))
      (setq *MEDSW-UCSD* (1+ *MEDSW-UCSD*))
      (setvar "CLAYER" (car _MEDCENLAY))
      (MEDTray
        (list (list (trans ba 0 1) (trans bb 0 1))
              (nth 3 info)
              (nth 2 info)))
      (setq xd (bld_tray (nth 3 info) (nth 2 info) (nth 1 info)
                         nil (nth 5 info) "T" (nth 7 info)))
      (xdatadd (entlast) xd)
      (MEDTrayOutline (entlast))
      (vl-cmdf "._UCS" "_P")
      (setq *MEDSW-UCSD* (1- *MEDSW-UCSD*))
      (princ
        (strcat "\nTRAYSWIVEL: boxes + centers(xdata "
                (itoa *MEDSW-FITCODE*)
                ") + bridge (parent-off "
                (rtos *MEDSW-PARENT-OFF* 2 4)
                " bridge-off "
                (rtos *MEDSW-BRIDGE-OFF* 2 4)
                ")."))
    )
  )
  (medsw_ucs_unwind)
  (medsw_ucs_end nil)
  (setvar "CLAYER" oly)
  (setvar "CMDECHO" oce)
  (setq *error* olderr)
  (princ)
)

(princ "\nMEDTraySwivel loaded - TRAYSWIVEL (2026-10-28ak) 27ak boxes at tray elev; 27aj restores 27z WCS pivot (no alongShift); Front fal/fup; UCS 2D + 27ad/ae kept")
(princ)
