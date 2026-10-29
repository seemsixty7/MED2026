;;; MED3DLadderTray.lsp
;;; teeelev 2026-10-29: tee/cross rails built flat then moved to fitting elev.
;;; 2026-10-28 restore slope+layer0: entity-UCS slope fix (t776u/t777u, archive-q) +
;;;   swivel 390 dispatch + block definitions built on layer "0" (t847u).
;;; !! DO NOT replace this file from a pre-UCS / pre-layer0 snapshot when shipping
;;; !! MEDTraySwivel or MED3DTrayFunctions. Ship only the live Support file or MERGE.
;;; !! Expected MD5s: Jane/Bean/MED3D-CHECK.txt
;;; Separate maintainable file; auto-loaded by MED3DTrayFunctions.lsp when on the Support path (not in MEDCore).
;;; Builds ladder-style (open-bottom) 3D tray from MED 2D tray data:
;;;   side rails + rung BLOCK inserts, no solid floor, no UNION.
;;; Does not replace Make3DTray (solid-bottom collision solids).
;;;
;;; Command: Make3DLadderTray
;;;   Pick one entity  -> that MED_TRAY run or MED_FITTING outline only.
;;;   Enter at pick    -> every MED_TRAY run + every MED_FITTING outline in the
;;;                       drawing (same walk as Make3DTray / med3d-tray-build).
;;;   Block-INSERT fittings (conduit bodies, couplings) are skipped and listed.
;;;
;;; STRAIGHT RUNS
;;;   Stock pieces, default 20 ft (240 in) - MED_TRAY_SEGLEN.
;;;   Full pieces share one assembly block, e.g.
;;;     MED_TRAY-W24-R9-D6-L240-F1-T0-125
;;;   Shorter remnants get their own block named for that length (-L87).
;;;
;;; FITTINGS (one piece each, never segmented) - same outline tests as
;;; MEDConvertTrayFittingsTo3D:
;;;   4-pt outline   ELBOW  (30/45/60/90 from bulge; vertical = rails + width rungs)
;;;   7-pt outline   TEE
;;;   10-pt outline  CROSS
;;;   2-pt, 18" long RED    (straight reducer)
;;;   2-pt, other    LRRED  (left/right reducer)
;;;   Rails reuse MED's MEDBuild3DTrayFitFlange / MEDBuild3DTrayFlange(FromEntity)
;;;   when loaded (MED3DTrayFunctions.lsp), else a local C/Z rail sweep.
;;;   Each fitting is rotated to a canonical orientation, wrapped in one block
;;;   and INSERTed back in place, so identical fittings share a definition:
;;;     MED_TRAYFIT-ELBOW-W24-D6-A90-L-F1-T0-125
;;;     MED_TRAYFIT-TEE-W24-D6-F1-T0-125
;;;     MED_TRAYFIT-CROSS-W24-D6-F1-T0-125
;;;     MED_TRAYFIT-RED-W24-X12-D6-F1-T0-125
;;;     MED_TRAYFIT-LRRED-W24-X12-L-D6-F1-T0-125
;;;     MED_TRAYFIT-VELBOW-W24-D6-A90-U-F1-T0-125
;;;   Name tokens: A = angle deg, L/R = turn hand, U/D = vertical up/down,
;;;   X = reduced width, F = flange size (N prefix = negative / flange OUT),
;;;   T = material thickness.  If the name already exists the existing
;;;   definition is reused.  -2, -3 suffixes only if MED3DL_UNIQUEFITS is T
;;;   (forces a fresh definition per fitting, e.g. after editing geometry).
;;;
;;; RUNGS
;;;   One block per width: MEDRUNG-W24 (box, X across tray). INSERT only.
;;;   Straights / elbows: along centerline at MED_TRAY_RUNGSPACING.
;;;   Vertical elbows (t774u): MEDRUNG-W{w} arrayed along the bend arc
;;;   (side view) at MED_TRAY_FITRUNGSPACING, spanning the two rails
;;;   (MED3DL-velbowRungs).  1,1 inserts only.
;;;   Tee (Clint 2026-10-26): through-axis rungs (closed legs, tan rungs at
;;;   p1/p5, middle at foot, fills at FITRUNGSPACING from each tan, no
;;;   double at middle); NO tan-tan open-side rail (t751u; closed p6-p0 kept);
;;;   sweep-to-sweep cross rung inside tan line; rung at branch tangent;
;;;   one more sp toward straight; 45-deg rungs in the remaining pockets.
;;;   Cross (t752u): primary 1-3 = tee steps 1-4 (m1/m5 tans, foot, fills);
;;;   arm 2 = tee steps 5-8 from arcs m1-m2/m4-m5; arm 4 = geometric mirror
;;;   of arm 2 across the primary (10-pt CL has only 3 bulges).  No rails.
;;;   Variable lengths = real MEDRUNG-W{w}-L{len} blocks.  NEVER XYZ-scale
;;;   an INSERT (breaks explode/plot/render/calcs) - all inserts 1,1.
;;;   projOnSeg uses local u (never t — AutoLISP reserved; bind:T crash).
;;;   Cross (t749u): tee-mirror.  Primary 1<->3 (p0<->p6) = tee steps
;;;   1-4 (closed legs, tan rungs at the primary sweep tangents, middle at
;;;   cen, sp fills no double, open-side rail tan->tan on BOTH sides,
;;;   soft-fail).  Arms 2 (p3) and 4 (p9) = tee steps 5-8 mirrored: mouth
;;;   span (teeSpanRung), rung at arm tangent, optional sp fill, two 45s
;;;   (tee45).  Sweeps taken from every bulged segment.  Reducing tee later.
;;;   Reducers: large-width rungs over the 7" tangent, reduced width after.
;;;
;;; FLANGE IN / OUT
;;;   Sign of MED xdata flange is honored exactly as MED does:
;;;     positive = standard (C-channel, lips IN)  - Enduro std, B-Line
;;;     negative = reverse  (Z-channel, lips OUT) - Enduro alt 6" profile
;;;   |flange| < 2 x material -> plain web (no lip).
;;;
;;; MATERIAL THICKNESS (MED_TRAY_MATERIALWIDTH used by all rail builders)
;;;   MED3DL_MATWIDTH   number -> forced for every piece (user override).
;;;   else tray type detected from MED description / layer / MED_TRAYTYPE:
;;;     *FIBERGLASS* *FIBREGLASS* *FRP* *GRP* *ENDURO*  -> 0.25  (1/4")
;;;     *ALUM* *B-LINE* *BLINE*                        -> 0.125 (1/8")
;;;   else MED_TRAY_MATERIALWIDTH as loaded (MED default 0.125).
;;;   Original MED_TRAY_MATERIALWIDTH is restored after the command.
;;;
;;; REFERENCE MANUFACTURERS (defaults calibrated to catalogs)
;;;   Eaton B-Line aluminum ladder: I-beam rails, rungs sit on inside bottom
;;;     flange; outside flanges for hold-downs / covers. 20 ft stock; rung
;;;     spacing 6/9/12 (default 9). Model material 0.125.
;;;   Enduro fiberglass ladder: C-channel flanges IN (std), Z-channel upper
;;;     flanges OUT (alt). Channel 5/32-5/16 by series, 1/4 on EHL4/EHL6 ->
;;;     default 0.25. Fitting rung spacing nominal 9.25. Lengths 10/20 ft.
;;;   Rail profile here is MED's (web + top flange), not a full I-beam.
;;;
;;; Load after MED (xdataget, _TRAY, _FITTING, bld_lw_ptlist, dxf).
;;;
;;; Defaults (setq before running to override):
;;;   MED_TRAY_SEGLEN          240.0  stock piece length (20 ft)
;;;   MED_TRAY_RUNGSPACING     9.0    straights
;;;   MED_TRAY_FITRUNGSPACING  9.0    fittings (set 9.25 for Enduro)
;;;   MED_TRAY_RUNGTHICK       1.0    along-tray thickness of a rung
;;;   MED_TRAY_RUNGHEIGHT      0.75   rung solid height
;;;   MED3DL_MATWIDTH          nil    force material thickness
;;;   MED3DL_UNIQUEFITS        nil    T = never reuse fitting definitions

(vl-load-com)
(princ "\nLoading MED3DLadderTray.lsp...")

(if (not MED_TRAY_SEGLEN)        (setq MED_TRAY_SEGLEN 240.0))
(if (not MED_TRAY_RUNGSPACING)   (setq MED_TRAY_RUNGSPACING 9.0))
(if (not MED_TRAY_RUNGTHICK)     (setq MED_TRAY_RUNGTHICK 1.0))
(if (not MED_TRAY_RUNGHEIGHT)    (setq MED_TRAY_RUNGHEIGHT 0.75))
(if (not MED_TRAY_MATERIALWIDTH) (setq MED_TRAY_MATERIALWIDTH 0.125))

(defun MED3DL-dxf (code elist)
  (cdr (assoc code elist))
)

(defun MED3DL-inchTok (x)
  (if (equal x (float (atoi (rtos x 2 0))) 1e-4)
    (itoa (atoi (rtos x 2 0)))
    (vl-string-translate "." "-" (rtos x 2 2))
  )
)

(defun MED3DL-rungBlockName (w)
  (strcat "MEDRUNG-W" (MED3DL-inchTok w))
)

;; Assembly name includes length so stock and remnant pieces diverge.
(defun MED3DL-assemblyName (width depth len)
  (strcat "MED_TRAY-W" (MED3DL-inchTok width)
          "-R"         (MED3DL-inchTok MED_TRAY_RUNGSPACING)
          "-D"         (MED3DL-inchTok depth)
          "-L"         (MED3DL-inchTok len)
          (MED3DL-flangeTok MED3DL_FLANGE)
          (MED3DL-matTok)
  )
)

(defun MED3DL-ssAfter (emark / ss e)
  (setq ss (ssadd))
  (if emark
    (progn
      (setq e emark)
      (while (setq e (entnext e))
        (ssadd e ss)
      )
    )
    (setq ss (ssget "_X"))
  )
  ss
)

;; Box at block origin: X = across tray, Y = along tray, Z = up.
;; Does not recreate if tblsearch hits.
;; t847u: every entity going into a block definition lives on layer "0"
;; (inserts keep the 3D tray layer).  Accepts ename or selection set.
(defun MED3DL-toLayer0 (x / i e ed)
  (if (= (type x) (quote ENAME)) (setq x (list x))
    (if (= (type x) (quote PICKSET))
      (progn (setq i 0 e nil)
        (repeat (sslength x) (setq e (cons (ssname x i) e) i (1+ i)))
        (setq x e))))
  (foreach e x
    (if (and e (setq ed (entget e)))
      (entmod (subst (cons 8 "0") (assoc 8 ed) ed))))
  x
)

(defun MED3DL-ensureRungBlock (width / bname hw thick ht p1 p2 oldos oldecho oldatt oldexp)
  (setq bname (MED3DL-rungBlockName width)
        thick MED_TRAY_RUNGTHICK
        ht    MED_TRAY_RUNGHEIGHT
        hw    (* 0.5 width)
  )
  (if (tblsearch "BLOCK" bname)
    (princ (strcat "\nUsing existing rung " bname))
    (progn
      (setq oldos    (getvar "OSMODE")
            oldecho  (getvar "CMDECHO")
            oldatt   (getvar "ATTREQ")
            oldexp   (getvar "EXPERT")
      )
      (setvar "CMDECHO" 0)
      (setvar "OSMODE" 0)
      (setvar "ATTREQ" 0)
      (setvar "EXPERT" 5)
      (command "._ucs" "_World")
      (setq p1 (list (- hw) (* -0.5 thick) 0.0)
            p2 (list hw     (*  0.5 thick) ht)
      )
      (command "._box" "_non" p1 "_non" p2)
      (MED3DL-toLayer0 (entlast))
      (command "._-block" bname "_non" (list 0.0 0.0 0.0) (entlast) "")
      ;; restore caller's entity UCS (Clint t777u: alternate-UCS routing)
      (command "._ucs" "_Previous")
      (setvar "OSMODE" oldos)
      (setvar "CMDECHO" oldecho)
      (setvar "ATTREQ" oldatt)
      (setvar "EXPERT" oldexp)
      (princ (strcat "\nCreated rung block " bname))
    )
  )
  bname
)

;; Side rail fallback when MED 3D helpers are not loaded.
;; Web = material x depth.  If |flange| >= 2 x material a top lip is added:
;;   flange > 0  -> lip turns IN  (C-channel, Enduro standard / B-Line style)
;;   flange < 0  -> lip turns OUT (Z-channel upper flange, Enduro alt)
;; Same sign convention as MED (negative = reverse flange / FlangeFLIP).
(defun MED3DL-railProfile (p1 ang width depth flange flip / mt out in base lip o1 o2 o3 o4 o5 o6)
  (setq mt   MED_TRAY_MATERIALWIDTH
        out  (+ ang (* flip (* pi 0.5)))
        in   (+ ang (* flip (* pi -0.5)))
        base (polar p1 out (* width 0.5))
        lip  (* 0.5 (abs flange))
  )
  (if (< (abs flange) (* 2.0 mt))
    (progn
      (setq o1 base
            o2 (polar o1 out mt)
            o3 (list (nth 0 o2) (nth 1 o2) (+ (nth 2 o2) depth))
            o4 (list (nth 0 o1) (nth 1 o1) (+ (nth 2 o1) depth)))
      (command "._3DPOLY" "_non" o1 "_non" o2 "_non" o3 "_non" o4 "_C")
    )
    (if (> flange 0.0)
      (progn ; lip in
        (setq o1 base
              o2 (polar o1 out mt)
              o3 (list (nth 0 o2) (nth 1 o2) (+ (nth 2 o2) depth))
              o4 (polar o3 in (+ mt lip))
              o5 (list (nth 0 o4) (nth 1 o4) (- (nth 2 o4) mt))
              o6 (list (nth 0 o1) (nth 1 o1) (- (nth 2 o3) mt)))
        (command "._3DPOLY" "_non" o1 "_non" o2 "_non" o3 "_non" o4 "_non" o5 "_non" o6 "_C")
      )
      (progn ; lip out
        (setq o1 base
              o2 (polar o1 out mt)
              o6 (list (nth 0 o2) (nth 1 o2) (- (+ (nth 2 o2) depth) mt))
              o5 (polar o6 out lip)
              o4 (list (nth 0 o5) (nth 1 o5) (+ (nth 2 o5) mt))
              o3 (list (nth 0 o1) (nth 1 o1) (+ (nth 2 o1) depth)))
        (command "._3DPOLY" "_non" o1 "_non" o2 "_non" o6 "_non" o5 "_non" o4 "_non" o3 "_C")
      )
    )
  )
  (entlast)
)

(defun MED3DL-buildRectRail (p1 p2 width depth flip / ang oldos)
  (setq ang (angle p1 p2) oldos (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  (MED3DL-railProfile p1 ang width depth MED3DL_FLANGE flip)
  (command "._Extrude" (entlast) "" "_Dir" "_non" (polar p1 ang 0.0) "_non" (polar p1 ang (distance p1 p2)))
  (setvar "OSMODE" oldos)
  (entlast)
)

;; Fallback rail along any curve (fitting arcs): profile at start, sweep along an
;; offset copy of the path.  Used only when MEDBuild3DTrayFitFlange is not bound.
(defun MED3DL-buildPathRail (path p1 p2 width depth flange flip / ang prof off oldos)
  (setq ang (angle p1 p2) oldos (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  (setq prof (MED3DL-railProfile p1 ang width depth flange flip))
  (command "._offset" (* 0.5 width) path "_non" (polar p1 (+ ang (* flip (* pi 0.5))) (* width 0.5)) "")
  (setq off (entlast))
  (command "._Extrude" prof "" "_Path" off)
  (if (entget off) (entdel off))
  (setvar "OSMODE" oldos)
  (entlast)
)

(defun MED3DL-buildRails (p1 p2 width depth flange ucs)
  (setq MED3DL_FLANGE (if flange flange 0.0))
  (if (boundp (quote MEDBuild3DTrayFlange))
    (progn
      (MEDBuild3DTrayFlange (list p1 p2 width depth MED3DL_FLANGE) 1.0 ucs)
      (MEDBuild3DTrayFlange (list p1 p2 width depth MED3DL_FLANGE) -1.0 ucs)
    )
    (progn
      (MED3DL-buildRectRail p1 p2 width depth 1.0)
      (MED3DL-buildRectRail p1 p2 width depth -1.0)
    )
  )
)

(defun MED3DL-insertRungs (p1 p2 bname / ang len sp dist pt rotdeg oldos n)
  (setq ang    (angle p1 p2)
        len    (distance p1 p2)
        sp     MED_TRAY_RUNGSPACING
        oldos  (getvar "OSMODE")
        n      0
        ;; block X is across tray; rotate so local X is perpendicular
        rotdeg (* (/ 180.0 pi) (+ ang (* pi 0.5)))
  )
  (setvar "OSMODE" 0)
  (cond
    ((<= len (* 0.5 sp))
      (setq pt (polar p1 ang (* 0.5 len)))
      (command "._insert" bname "_non" pt 1 1 rotdeg)
      (setq n 1)
    )
    (T
      (setq dist (* 0.5 sp))
      (while (<= dist (- len (* 0.5 sp)))
        (setq pt (polar p1 ang dist))
        (command "._insert" bname "_non" pt 1 1 rotdeg)
        (setq n    (1+ n)
              dist (+ dist sp)
        )
      )
    )
  )
  (setvar "OSMODE" oldos)
  n
)

;; Build one ladder piece along +X from origin (len long) and -BLOCK it.
;; Call only when tblsearch miss. Returns block name.
(defun MED3DL-defineSegmentBlock (width depth flange ucs rungName len
                                  / asm p0 p1 emark oldos oldexp olddel n ss)
  (setq asm (MED3DL-assemblyName width depth len)
        p0  (list 0.0 0.0 0.0)
        p1  (list len 0.0 0.0)
  )
  (if (tblsearch "BLOCK" asm)
    (princ (strcat "\nUsing existing piece " asm))
    (progn
      (setq oldos  (getvar "OSMODE")
            oldexp (getvar "EXPERT")
            olddel (getvar "DELOBJ")
      )
      (setvar "OSMODE" 0)
      (setvar "EXPERT" 5)
      (setvar "DELOBJ" 1)
      (command "._ucs" "_World")
      (setq emark (entlast))
      (MED3DL-buildRails p0 p1 width depth flange ucs)
      (setq n (MED3DL-insertRungs p0 p1 rungName))
      (setq ss (MED3DL-ssAfter emark))
      (if (and ss (> (sslength ss) 0))
        (progn
          (MED3DL-toLayer0 ss)
          (command "._-block" asm "_non" p0 ss "")
          (princ (strcat "\nCreated piece block " asm
                         "  L=" (rtos len 2 2)
                         "  rungs " (itoa n)))
        )
        (princ (strcat "\nNo geometry for " asm))
      )
      ;; restore caller's entity UCS for placeSegment (cache hit: no UCS change)
      (command "._ucs" "_Previous")
      (setvar "OSMODE" oldos)
      (setvar "EXPERT" oldexp)
      (setvar "DELOBJ" olddel)
    )
  )
  asm
)

;; Place one piece INSERT at start point, rotation = run angle (deg).
(defun MED3DL-placeSegment (asm startpt ang / rotdeg oldos)
  (setq rotdeg (* (/ 180.0 pi) ang)
        oldos  (getvar "OSMODE")
  )
  (setvar "OSMODE" 0)
  (command "._insert" asm "_non" startpt 1 1 rotdeg)
  (setvar "OSMODE" oldos)
  (entlast)
)

(defun MED3DL-trayPoints (ent / ed pts z p1 p2)
  (setq ed (entget ent)
        z  (if (assoc 38 ed) (cdr (assoc 38 ed)) 0.0)
  )
  (cond
    ((= (MED3DL-dxf 0 ed) "LWPOLYLINE")
      (if (boundp (quote bld_lw_ptlist))
        (setq pts (car (bld_lw_ptlist ent)))
        (progn
          (setq pts nil)
          (foreach d ed
            (if (= (car d) 10) (setq pts (append pts (list d))))
          )
        )
      )
      (setq p1 (append (cdr (nth 0 pts)) (list z))
            p2 (append (cdr (nth 1 pts)) (list z))
      )
    )
    ((= (MED3DL-dxf 0 ed) "LINE")
      (setq p1 (MED3DL-dxf 10 ed)
            p2 (MED3DL-dxf 11 ed)
      )
    )
    (T
      (setq p1 nil p2 nil)
    )
  )
  (if (and p1 p2 (MED3DL-dxf 210 ed))
    (setq p1 (trans p1 (MED3DL-dxf 210 ed) 1)
          p2 (trans p2 (MED3DL-dxf 210 ed) 1)
    )
  )
  (list p1 p2 (MED3DL-dxf 210 ed))
)

;; UCS restore must use command-s: (command) from *error* re-enters and
;; hides the real failure ("Cannot invoke (command) from *error*...").
(defun MED3DL-restore (oldc oldos oldexp olddel)
  (if oldc    (setvar "CMDECHO" oldc))
  (if oldos   (setvar "OSMODE" oldos))
  (if oldexp  (setvar "EXPERT" oldexp))
  (if olddel  (setvar "DELOBJ" olddel))
  (vl-catch-all-apply (quote command-s) (list "._ucs" "_World"))
)

;; Walk the run in seglen chunks; define each distinct length once; INSERT all.
(defun MED3DL-buildRun (p1 p2 width depth flange ucs rungName seglen
                        / ang total remaining dist thisLen asm nStock nRem start)
  (setq ang       (angle p1 p2)
        total     (distance p1 p2)
        remaining total
        dist      0.0
        nStock    0
        nRem      0
  )
  (while (> remaining 1e-4)
    (setq thisLen (if (> remaining (+ seglen 1e-4))
                    seglen
                    remaining
                  )
          start   (polar p1 ang dist)
          asm     (MED3DL-defineSegmentBlock width depth flange ucs rungName thisLen)
    )
    (MED3DL-placeSegment asm start ang)
    (if (equal thisLen seglen 1e-4)
      (setq nStock (1+ nStock))
      (setq nRem (1+ nRem))
    )
    (setq dist      (+ dist thisLen)
          remaining (- remaining thisLen)
    )
  )
  (list nStock nRem total)
)
(if (not MED_TRAY_FITRUNGSPACING) (setq MED_TRAY_FITRUNGSPACING MED_TRAY_RUNGSPACING))
(if (not MED3DL_FLANGE) (setq MED3DL_FLANGE 0.0))

(defun MED3DL-flangeTok (f)
  (if (null f) (setq f 0.0))
  (strcat "-F" (if (< f 0.0) "N" "") (MED3DL-inchTok (abs f)))
)

(defun MED3DL-matTok ()
  (strcat "-T" (MED3DL-inchTok MED_TRAY_MATERIALWIDTH))
)

;; Number token for block names: 24 -> "24", 0.125 -> "0-125", 9.25 -> "9-25".
(defun MED3DL-inchTok (x / s)
  (if (equal x (float (atoi (rtos x 2 0))) 1e-4)
    (itoa (atoi (rtos x 2 0)))
    (progn
      (setq s (rtos x 2 3))
      (while (= (substr s (strlen s)) "0") (setq s (substr s 1 (1- (strlen s)))))
      (vl-string-translate "." "-" s)
    )
  )
)

;;; ------------------------------------------------------------------
;;; Material thickness by tray type
;;; ------------------------------------------------------------------
(defun MED3DL-typeText (ent kind code / s ed)
  (setq s "" ed (entget ent))
  (if (and code (boundp (quote med_getdesc)))
    (setq s (vl-catch-all-apply (quote med_getdesc) (list kind code))))
  (if (not (= (type s) 'STR)) (setq s ""))
  (strcase (strcat s " " (if (MED3DL-dxf 8 ed) (MED3DL-dxf 8 ed) "")
                   " " (if (= (type MED_TRAYTYPE) 'STR) MED_TRAYTYPE "")))
)

;; Returns thickness for this entity (does not set anything).
(defun MED3DL-materialFor (ent kind code / txt)
  (cond
    ((numberp MED3DL_MATWIDTH) (float MED3DL_MATWIDTH))
    ((wcmatch (setq txt (MED3DL-typeText ent kind code))
              "*FIBERGLASS*,*FIBREGLASS*,*FRP*,*GRP*,*ENDURO*") 0.25)
    ((wcmatch txt "*ALUM*,*B-LINE*,*BLINE*") 0.125)
    (T MED3DL_BASEMAT)
  )
)

;;; ------------------------------------------------------------------
;;; Generic helpers for fittings
;;; ------------------------------------------------------------------
(defun MED3DL-ptsUCS (ent / bl pts z out)
  (setq bl  (bld_lw_ptlist ent)
        z   (MED3DL-dxf 38 (entget ent))
        out nil)
  (if (not z) (setq z 0.0))
  (foreach p (car bl)
    (setq out (append out (list (trans (append (cdr p) (list z)) ent 1)))))
  out
)

(defun MED3DL-bulges (ent / out)
  (foreach b (cadr (bld_lw_ptlist ent))
    (setq out (append out (list (if (numberp (cdr b)) (cdr b) 0.0)))))
  out
)

(defun MED3DL-rtd (a) (* a (/ 180.0 pi)))

;; ALWAYS 1,1 insert.  NEVER X/Y/Z-scale a block (breaks explode, plot,
;; render, takeoff calcs).  Variable-length rungs get their own real-size
;; block via MED3DL-ensureRungLen.
(defun MED3DL-ins (bname pt rotdeg)
  (command "._insert" bname "_non" pt 1 1 rotdeg)
  (entlast)
)

;; Real-geometry rung of exact length len (rounded to 1/16 in), same profile
;; (MED_TRAY_RUNGTHICK x MED_TRAY_RUNGHEIGHT).  Block MEDRUNG-W{w}-L{len},
;; box X = length, centered on insert point.  Safe mid-build: restores UCS.
(defun MED3DL-ensureRungLen (w len / bname hl thick ht oldos oldecho oldexp)
  (setq len   (/ (fix (+ (* len 16.0) 0.5)) 16.0)
        bname (strcat "MEDRUNG-W" (MED3DL-inchTok w) "-L" (MED3DL-inchTok len))
        thick MED_TRAY_RUNGTHICK ht MED_TRAY_RUNGHEIGHT hl (* 0.5 len))
  (if (not (tblsearch "BLOCK" bname))
    (progn
      (setq oldos (getvar "OSMODE") oldecho (getvar "CMDECHO") oldexp (getvar "EXPERT"))
      (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "EXPERT" 5)
      (command "._ucs" "_World")
      (command "._box" "_non" (list (- hl) (* -0.5 thick) 0.0)
                       "_non" (list hl (* 0.5 thick) ht))
      (MED3DL-toLayer0 (entlast))
      (command "._-block" bname "_non" (list 0.0 0.0 0.0) (entlast) "")
      (command "._ucs" "_Previous")
      (setvar "OSMODE" oldos) (setvar "CMDECHO" oldecho) (setvar "EXPERT" oldexp)
      (princ (strcat "\nCreated rung block " bname))))
  bname
)
;; Insert a real-length rung centered at pt, length along ang (radians).
(defun MED3DL-insLen (w len pt ang)
  (if (> len (* 2.0 MED_TRAY_RUNGTHICK))
    (progn (MED3DL-ins (MED3DL-ensureRungLen w len) pt (MED3DL-rtd ang)) 1)
    0)
)

;; Rungs along any planar curve (centerline). Returns count.
;; Rungs along any planar curve (centerline). Returns count.
(defun MED3DL-rungsAlongCurve (curve bname sp / obj len d dl pt der n)
  (setq obj (vlax-ename->vla-object curve)
        len (vlax-curve-getDistAtParam obj (vlax-curve-getEndParam obj))
        n   0)
  (if (< len sp)
    (setq d (* 0.5 len) dl d)
    (setq d (* 0.5 sp) dl (+ (- len (* 0.5 sp)) 1e-6)))
  (while (<= d dl)
    (setq pt  (vlax-curve-getPointAtDist obj d)
          der (vlax-curve-getFirstDeriv obj (vlax-curve-getParamAtPoint obj pt))
          pt  (trans pt 0 1)
          der (trans der 0 1 T))
    (MED3DL-ins bname pt (MED3DL-rtd (+ (angle '(0.0 0.0 0.0) der) (* pi 0.5))))
    (setq n (1+ n) d (+ d sp)))
  n
)

;; VERTICAL ELBOW rungs (Clint t774u): rails exist per side for each
;; angle (30/45/60/90) and radius; rungs = plain tray-width MEDRUNG-W{w}
;; (length w, 1,1 insert) arrayed along the bend centerline in side view
;; at MED_TRAY_FITRUNGSPACING.  Must run in the UCS left by
;; MED3DL-fitRailsElbow (vert=T, 3P UCS).  MEDBuild3DTrayFitFlange makes
;; vertical rails as COPIES of the centerline displaced +/- w/2 along
;; (ang + 90) in that UCS, so every rung uses that same fixed direction
;; (not the tangent): rung X spans rail-to-rail at every station, rung Z =
;; UCS Z = rail depth direction.  ang = angle p1->p2 in that UCS.
(defun MED3DL-velbowRungs (curve ang bname sp / obj len d dl pt n rot)
  (setq obj (vlax-ename->vla-object curve)
        len (vlax-curve-getDistAtParam obj (vlax-curve-getEndParam obj))
        rot (MED3DL-rtd (+ ang (* pi 0.5)))
        n   0)
  (if (< len sp)
    (setq d (* 0.5 len) dl d)
    (setq d (* 0.5 sp) dl (+ (- len (* 0.5 sp)) 1e-6)))
  (while (<= d dl)
    (setq pt (trans (vlax-curve-getPointAtDist obj d) 0 1))
    (MED3DL-ins bname pt rot)
    (setq n (1+ n) d (+ d sp)))
  n
)

;; Rungs on a straight line p1->p2 (rung X across the line), from d0 to d1.
(defun MED3DL-rungsOnLine (p1 ang d0 d1 bname sp / d n)
  (setq d (+ d0 (* 0.5 sp)) n 0)
  (while (<= d (+ (- d1 (* 0.5 sp)) 1e-6))
    (MED3DL-ins bname (polar p1 ang d) (MED3DL-rtd (+ ang (* pi 0.5))))
    (setq n (1+ n) d (+ d sp)))
  n
)

;; Tee / cross (concept).  Centerline: p0=+90, p3=genang, p6=-90 [,p9].
;; TEE rungs (Clint 2026-10-26).  Local frame: X along through axis
;; (m0->m6) from foot, Y = station toward branch.  All 1,1 inserts.
;;  1 through axis m0->m6 (line between the straight-section midpoints)
;;  2 tan rungs at m1 and m5          3 middle rung at foot
;;  4 fills from each tan rung toward foot at sp; no double at middle
;;    (last gap may be short); closed legs m0->m1, m5->m6 at sp
;;  5 cross rung sweep-to-sweep just inside the tan line (cyan rail),
;;    exact-length real block, never past the branch sweeps
;;  6 rung at branch tangent station (mid of the two sweeps)
;;  7 rung sp in toward straight from 6 (exact local span)
;;  8 45-deg rungs from each sweep's 45-deg point into the pocket,
;;    stopping at the step-5 rung / branch axis
(defun MED3DL-projOnSeg (p a b / ax ay dx dy u)
  ;; NOTE: never localize/setq symbol T — AutoLISP reserved (bind error).
  (setq ax (car a) ay (cadr a)
        dx (- (car b) ax) dy (- (cadr b) ay)
        u  (if (< (+ (* dx dx) (* dy dy)) 1e-12) 0.0
             (/ (+ (* (- (car p) ax) dx) (* (- (cadr p) ay) dy))
                (+ (* dx dx) (* dy dy)))))
  (list (+ ax (* u dx)) (+ ay (* u dy)) (if (caddr p) (caddr p) 0.0))
)
(defun MED3DL-sideToward (origin dir target / vx vy sx sy)
  (setq vx (- (car target) (car origin)) vy (- (cadr target) (cadr origin))
        sx (- (sin dir)) sy (cos dir))
  (if (>= (+ (* vx sx) (* vy sy)) 0.0) 1.0 -1.0)
)
;; Arc center from p1->p2 + bulge (nil if straight).
(defun MED3DL-arcCtr (p1 p2 b / th c R)
  (if (and (numberp b) (> (abs b) 1e-6))
    (progn
      (setq th (* 4.0 (atan (abs b))) c (distance p1 p2)
            R  (/ c (* 2.0 (sin (* 0.5 th)))))
      (polar p1 (+ (angle p1 p2) (* (if (> b 0) 1.0 -1.0) (- (* 0.5 pi) (* 0.5 th)))) R))
  )
)
;; Soft-fail wrapper: Extrude/(command) failures invoke *error*, not vl-catch.
(defun MED3DL-tryOpenSideRail (data flip ucs / *error* ok)
  (defun *error* (msg)
    (setq ok nil)
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*")))
      (princ (strcat "\n  open-side rail skipped: " msg)))
    (princ)
  )
  (setq ok T)
  (MEDBuild3DTrayFlange data flip ucs)
  ok
)
;; Tee helpers (locals of MED3DL-teeCrossRungs: _tF _tA _tY _tS).
(defun MED3DL-tL2W (x y) (polar (polar _tF _tA x) _tY y))
(defun MED3DL-tX (p) (+ (* (- (car p) (car _tF)) (cos _tA)) (* (- (cadr p) (cadr _tF)) (sin _tA))))
(defun MED3DL-tYof (p) (+ (* (- (car p) (car _tF)) (cos _tY)) (* (- (cadr p) (cadr _tF)) (sin _tY))))
;; Sweep x at station y for circle (cx cy r); mouth-side root, clamp y<=cy.
(defun MED3DL-sweepX (cx cy r y / dy q)
  (setq dy (- cy (min y cy)) q (- (* r r) (* dy dy)))
  (if (< q 0.0) nil
    (if (< cx 0.0) (+ cx (sqrt q)) (- cx (sqrt q))))
)
;; Exact-length rung across at station y (parallel to through axis).
(defun MED3DL-teeSpanRung (w y cL cR / xl xr)
  (setq xl (MED3DL-sweepX (car cL) (cadr cL) (caddr cL) y)
        xr (MED3DL-sweepX (car cR) (cadr cR) (caddr cR) y))
  (if (and xl xr (> xr xl))
    (MED3DL-insLen w (- xr xl) (MED3DL-tL2W (* 0.5 (+ xl xr)) y) _tA)
    0)
)
;; 45-deg rung from sweep circle c (local cx cy r) toward foot side,
;; ends at station y5 or the branch axis (x=0), whichever first.
(defun MED3DL-tee45 (w c y5 / cx cy r sx dx dy px py L1 L2 L)
  (setq cx (car c) cy (cadr c) r (caddr c)
        sx (if (< cx 0.0) 1.0 -1.0)
        dx (* sx (sqrt 0.5)) dy (- (sqrt 0.5))
        px (+ cx (* r dx)) py (+ cy (* r dy)))
  (if (> py y5)
    (progn
      (setq L1 (/ (- py y5) (sqrt 0.5)) L2 (/ (abs px) (sqrt 0.5))
            L  (- (min L1 L2) (* 0.5 MED_TRAY_RUNGTHICK)))
      (MED3DL-insLen w L (MED3DL-tL2W (+ px (* dx L 0.5)) (+ py (* dy L 0.5)))
                     (+ _tA (* _tS (atan dy dx)))))
    0)
)
;; Cross helpers (use _tF _tA _tY _cq/hw from MED3DL-teeCrossRungs).
(defun MED3DL-cxQ (x y) (strcat (if (< x 0.0) "-" "+") (if (< y 0.0) "-" "+")))
;; Inner rail |y| at primary station x on side ys (+1/-1): primary rail hw
;; outside the tan, sweep circle in the flare, secondary tangent inside.
(defun MED3DL-crossBound (x ys / c ax ay r ux)
  (setq c (cdr (assoc (MED3DL-cxQ x ys) _cq))
        ax (abs (car c)) ay (abs (cadr c)) r (caddr c) ux (abs x))
  (cond ((>= ux ax) hw)
        ((<= ux (- ax r)) ay)
        (T (- ay (sqrt (max 0.0 (- (* r r) (* (- ux ax) (- ux ax)))))))))
;; Exact-length span rung across primary at station x, sweep-inner to sweep-inner.
(defun MED3DL-crossSpan (w x / yu yl)
  (setq yu (MED3DL-crossBound x 1.0) yl (MED3DL-crossBound x -1.0))
  (MED3DL-insLen w (+ yu yl) (MED3DL-tL2W x (* 0.5 (- yu yl))) _tY)
)
;; 45-deg rung from the corner sweep's 45 point toward cen; stops at the
;; nearest rung station beyond it (sts) or the primary axis, minus half thick.
(defun MED3DL-cross45 (w c sts / cx cy r sx sy dx dy px py Lx L)
  (setq cx (car c) cy (cadr c) r (caddr c)
        sx (if (< cx 0.0) 1.0 -1.0) sy (if (< cy 0.0) 1.0 -1.0)
        dx (* sx (sqrt 0.5)) dy (* sy (sqrt 0.5))
        px (+ cx (* r dx)) py (+ cy (* r dy))
        Lx (abs px))
  (foreach s sts
    (if (> (* (- s px) sx) 1e-6) (setq Lx (min Lx (abs (- s px))))))
  (setq L (- (/ (min Lx (abs py)) (sqrt 0.5)) (* 0.5 MED_TRAY_RUNGTHICK)))
  (MED3DL-insLen w L (MED3DL-tL2W (+ px (* dx L 0.5)) (+ py (* dy L 0.5)))
                 (+ _tA (* _tS (atan dy dx))))
)
(defun MED3DL-teeCrossRungs (ent width flange bname sp / pts np m0 m1 m2 m3 m4 m5 m6 m9
                             L n hw angT foot flip data ucs dpth fl bl rot d dd x
                             c1 c2 cL cR yT y5 y7 tol cen dl pm m7 m8 xA xB sts
                             _cq _tF _tA _tY _tS sg)
  (setq pts (MED3DL-ptsUCS ent) np (length pts) n 0
        hw  (* 0.5 (if (numberp _PLOTSCALE) _PLOTSCALE 1.0) width)
        ucs (MED3DL-dxf 210 (entget ent))
        dpth (if (and (boundp (quote MED3DL_FITDEPTH)) (numberp MED3DL_FITDEPTH))
               MED3DL_FITDEPTH 4.0)
        fl   (if (numberp MED3DL_FLANGE) MED3DL_FLANGE flange)
        fl   (if (boundp (quote MED3D-effFlange)) (MED3D-effFlange fl) fl))
  (cond
    ((= np 7)
      (setq m0 (nth 0 pts) m1 (nth 1 pts) m2 (nth 2 pts) m3 (nth 3 pts)
            m4 (nth 4 pts) m5 (nth 5 pts) m6 (nth 6 pts) bl (MED3DL-bulges ent)
            angT (angle m0 m6) L (distance m0 m6)
            foot (MED3DL-projOnSeg m3 m0 m6)
            rot  (MED3DL-rtd (+ angT (* pi 0.5)))
            tol  (* 0.5 sp)
            _tF foot _tA angT
            _tS (MED3DL-sideToward m0 angT m3)
            _tY (+ angT (* _tS pi 0.5)))
      ;; steps 1-4: through axis rungs (standard width block, 1,1)
      (princ "\n  tee: through rungs")
      (setq n (+ n (MED3DL-rungsOnLine m0 angT 0.0 (distance m0 m1) bname sp)))
      (setq n (+ n (MED3DL-rungsOnLine m5 angT 0.0 (distance m5 m6) bname sp)))
      (MED3DL-ins bname m1 rot) (MED3DL-ins bname m5 rot) (MED3DL-ins bname foot rot)
      (setq n (+ n 3))
      (foreach pr (list (list m1 (angle m1 foot)) (list m5 (angle m5 foot)))
        (setq d sp dd (distance (car pr) foot))
        (while (< d (- dd tol))
          (MED3DL-ins bname (polar (car pr) (cadr pr) d) rot)
          (setq n (1+ n) d (+ d sp))))
      ;; steps 5-8: branch flare (sweep circles in local frame, r = R - hw)
      (setq c1 (MED3DL-arcCtr m1 m2 (nth 1 bl)) c2 (MED3DL-arcCtr m4 m5 (nth 4 bl)))
      (if (and c1 c2 (> (distance c1 m1) hw) (> (distance c2 m5) hw))
        (progn
          (setq c1 (list (MED3DL-tX c1) (MED3DL-tYof c1) (- (distance c1 m1) hw))
                c2 (list (MED3DL-tX c2) (MED3DL-tYof c2) (- (distance c2 m5) hw))
                cL (if (< (car c1) (car c2)) c1 c2)
                cR (if (< (car c1) (car c2)) c2 c1)
                yT (* 0.5 (+ (MED3DL-tYof m2) (MED3DL-tYof m4)))
                y5 (+ hw (* 0.5 MED_TRAY_RUNGTHICK))
                y7 (- yT sp))
          (princ "\n  tee: branch cross / tangent / 45 rungs")
          (setq n (+ n (MED3DL-teeSpanRung width y5 cL cR)))          ; 5
          (MED3DL-ins bname (MED3DL-tL2W 0.0 yT) (MED3DL-rtd angT))    ; 6
          (setq n (1+ n))
          (if (> y7 (+ y5 tol))
            (setq n (+ n (MED3DL-teeSpanRung width y7 cL cR))))        ; 7
          (setq n (+ n (MED3DL-tee45 width cL y5) (MED3DL-tee45 width cR y5)))) ; 8
        (princ "\n  tee: no fillet arcs found; branch flare rungs skipped")))
    ((= np 10)
      ;; CROSS (Clint t752u): primary 1<->3 = tee steps 1-4 via m1/m5;
      ;; arm 2 (m3) = tee steps 5-8 from the two real fillet arcs
      ;; (m1-m2, m4-m5); arm 4 (m9) = geometric mirror of arm 2 across the
      ;; primary axis.  The 10-pt centerline has only three bulges, so arm 4
      ;; has no own arc pair - never scan bulges for it.
      (setq m0 (nth 0 pts) m1 (nth 1 pts) m2 (nth 2 pts) m3 (nth 3 pts)
            m4 (nth 4 pts) m5 (nth 5 pts) m6 (nth 6 pts) m9 (nth 9 pts)
            bl (MED3DL-bulges ent) angT (angle m0 m6)
            cen (MED3DL-projOnSeg m3 m0 m6)
            rot (MED3DL-rtd (+ angT (* pi 0.5)))
            tol (* 0.5 sp)
            _tF cen _tA angT
            _tS (MED3DL-sideToward m0 angT m3)
            _tY (+ angT (* _tS pi 0.5)))
      ;; steps 1-4 (identical to tee)
      (princ "\n  cross: primary 1-3 through rungs (tee steps 1-4)")
      (setq n (+ n (MED3DL-rungsOnLine m0 angT 0.0 (distance m0 m1) bname sp)))
      (setq n (+ n (MED3DL-rungsOnLine m5 angT 0.0 (distance m5 m6) bname sp)))
      (MED3DL-ins bname m1 rot) (MED3DL-ins bname m5 rot) (MED3DL-ins bname cen rot)
      (setq n (+ n 3))
      (foreach pr (list (list m1 (angle m1 cen)) (list m5 (angle m5 cen)))
        (setq d sp dd (distance (car pr) cen))
        (while (< d (- dd tol))
          (MED3DL-ins bname (polar (car pr) (cadr pr) d) rot)
          (setq n (1+ n) d (+ d sp))))
      ;; arm 2 sweeps (local to arm-2 frame)
      (setq c1 (MED3DL-arcCtr m1 m2 (nth 1 bl)) c2 (MED3DL-arcCtr m4 m5 (nth 4 bl)))
      (if (and c1 c2 (> (distance c1 m1) hw) (> (distance c2 m5) hw))
        (progn
          (setq c1 (list (MED3DL-tX c1) (MED3DL-tYof c1) (- (distance c1 m1) hw))
                c2 (list (MED3DL-tX c2) (MED3DL-tYof c2) (- (distance c2 m5) hw))
                cL (if (< (car c1) (car c2)) c1 c2)
                cR (if (< (car c1) (car c2)) c2 c1)
                yT (* 0.5 (+ (MED3DL-tYof m2) (MED3DL-tYof m4)))
                y5 (+ hw (* 0.5 MED_TRAY_RUNGTHICK))
                y7 (- yT sp))
          ;; arm 2 then arm 4.  Mirror across primary: (x,y)->(x,-y) in the
          ;; arm-2 frame == same (x,y) in the arm-4 frame (_tY/_tS flipped),
          ;; so cL/cR/yT carry over unchanged; only the frame flips.
          (foreach pm (list m3 m9)
            (setq _tS (if (equal pm m3) (MED3DL-sideToward m0 angT m3)
                        (- (MED3DL-sideToward m0 angT m3)))
                  _tY (+ angT (* _tS pi 0.5))
                  dl (- (MED3DL-tYof pm) yT))
            (princ (strcat "\n  cross: arm " (if (equal pm m3) "2" "4 (mirror of 2)")
                           " mouth / tangent / 45 rungs (tee steps 5-8)"))
            (if (> dl sp)                                                ; arm leg
              (setq n (+ n (MED3DL-rungsOnLine pm (angle pm cen) 0.0 dl bname sp))))
            (setq n (+ n (MED3DL-teeSpanRung width y5 cL cR)))          ; 5
            (MED3DL-ins bname (MED3DL-tL2W 0.0 yT) (MED3DL-rtd angT))    ; 6
            (setq n (1+ n))
            (if (> y7 (+ y5 tol))
              (setq n (+ n (MED3DL-teeSpanRung width y7 cL cR))))        ; 7
            (setq n (+ n (MED3DL-tee45 width cL y5) (MED3DL-tee45 width cR y5))))) ; 8
        (princ "\n  cross: arm-2 fillet arcs not found; arm 2/4 flare rungs skipped")))
    (T (princ "\n  (tee/cross rungs: unexpected centerline point count)")))
  n
)



;;; ------------------------------------------------------------------
;;; Fitting classification (mirrors MEDConvertTrayFittingsTo3D tests)
;;; ------------------------------------------------------------------
(defun MED3DL-fitKind (ent / ed pl np xd code)
  (setq ed (entget ent)
        xd (xdataget ent (if (boundp (quote _FITTING)) _FITTING "MED_FITTING"))
        code (if xd (nth 3 xd) nil))
  (cond
    ((= (MED3DL-dxf 0 ed) "INSERT") "BLOCK")
    ((/= (MED3DL-dxf 0 ed) "LWPOLYLINE") nil)
    ;; ITEMCODE 390 = swivel — before elbow/tee/reducer geometry tests
    ((and code (= code (if (boundp (quote *MEDSW-FITCODE*)) *MEDSW-FITCODE* 390))) "SWIVEL")
    (T
      (setq pl (car (bld_lw_ptlist ent)) np (length pl))
      (cond
        ((= np 4) (if (and (boundp (quote vtrayxdataget)) (vtrayxdataget ent)) "VELBOW" "ELBOW"))
        ((= np 7) "TEE")
        ((= np 10) "CROSS")
        ((and (= np 2) (equal (MED3DL-redLen) (distance (cdr (nth 0 pl)) (cdr (nth 1 pl))) 1e-4)) "RED")
        ((and (= np 2) (> (rem (distance (cdr (nth 0 pl)) (cdr (nth 1 pl))) 1.0) 0.0)) "LRRED")
        (T nil)))
  )
)

(defun MED3DL-fitName (kind ent xd / w d f ang bl hand alt s desc)
  (setq w (nth 2 xd) d (nth 5 xd) f (nth 6 xd) alt (nth 4 xd)
        s (strcat "MED_TRAYFIT-" kind "-W" (MED3DL-inchTok w)))
  (cond
    ((member kind '("ELBOW" "VELBOW"))
      (setq bl  (nth 1 (MED3DL-bulges ent))
            ang (* 4.0 (atan (abs bl)))
            s   (strcat s "-D" (MED3DL-inchTok d) "-A" (itoa (fix (+ 0.5 (MED3DL-rtd ang))))
                        (if (= kind "VELBOW")
                          (if (< bl 0.0) "-D" "-U")
                          (if (< bl 0.0) "-R" "-L")))))
    ((= kind "RED")
      (setq s (strcat s "-X" (MED3DL-inchTok alt) "-D" (MED3DL-inchTok d))))
    ((= kind "LRRED")
      (setq desc (if (boundp (quote med_getdesc)) (med_getdesc "FITTING" (nth 3 xd)) "L"))
      (setq s (strcat s "-X" (MED3DL-inchTok alt)
                      (if (= (strcase (substr desc 1 1)) "L") "-L" "-R")
                      "-D" (MED3DL-inchTok d))))
    (T (setq s (strcat s "-D" (MED3DL-inchTok d))))
  )
  (strcat s (MED3DL-flangeTok f) (MED3DL-matTok))
)

(defun MED3DL-uniqueName (base / i nm)
  (setq nm base i 2)
  (while (tblsearch "BLOCK" nm) (setq nm (strcat base "-" (itoa i)) i (1+ i)))
  nm
)

(defun MED3DL-delTemp (e) (if (and e (entget e)) (entdel e)))

;;; ------------------------------------------------------------------
;;; Rails per fitting type (MED helpers minus base solid and UNION)
;;; ------------------------------------------------------------------
(defun MED3DL-fitRailsElbow (ent w d f vert / pts p1 p2 data)
  (setq pts (MED3DL-ptsUCS ent) p1 (nth 0 pts) p2 (nth 1 pts))
  (if vert
    (progn
      (command "._UCS" "_New" "_3P" "_non" p1 "_non" p2 "_non"
               (list (car p1) (cadr p1) (- (caddr p1) 10.0)))
      (setq pts (MED3DL-ptsUCS ent) p1 (nth 0 pts) p2 (nth 1 pts))))
  (setq data (list p1 p2 w d f))
  (if (boundp (quote MEDBuild3DTrayFitFlange))
    (progn
      (MEDBuild3DTrayFitFlange data 1.0 ent (not vert))
      (MED3DL-delTemp (MED3DL-lastPath))
      (MEDBuild3DTrayFitFlange data -1.0 ent (not vert))
      (MED3DL-delTemp (MED3DL-lastPath)))
    (progn
      (MED3DL-buildPathRail ent p1 p2 w d f 1.0)
      (MED3DL-buildPathRail ent p1 p2 w d f -1.0)))
  (list p1 (angle p1 p2))
)

;; MED's FitFlange leaves its offset/copy path entity in the drawing
;; (global PathEntity); remove it so only solids go into the block.
(defun MED3DL-lastPath ()
  (if (and (boundp (quote PathEntity)) PathEntity (entget PathEntity)
           (/= (MED3DL-dxf 0 (entget PathEntity)) "3DSOLID"))
    PathEntity)
)

(defun MED3DL-tempTray (mlist / e)
  (if (boundp (quote MEDmaketray))
    (MEDmaketray mlist nil nil (MEDGetCurrentOCS))
    (maketray mlist nil nil))
  (entlast)
)

;; teeelev 2026-10-29: tee/cross rails are built FLAT (UCS Z=0, ELEVATION 0)
;; exactly like the elev-0 case, then the new solids are MOVEd up by the
;; fitting's UCS Z.  At elev<>0 the temp-tray/OFFSET path and the 3DPOLY
;; profile disagreed on Z, so Extrude Path skewed the curved rails.
(defun MED3DL-fitRailsTeeCross (ent w d f / tp tp0 bl z zu p tmp data mark ss e)
  (setq tp0 (MED3DL-ptsUCS ent)
        bl  (MED3DL-bulges ent)
        z   (MED3DL-dxf 38 (entget ent))
        zu  (caddr (car tp0))
        tp  (mapcar (function (lambda (q) (list (car q) (cadr q) 0.0))) tp0)
        mark (entlast))
  (setvar "ELEVATION" 0.0)
  (defun p (i) (nth i tp))
  (if (not (boundp (quote MEDBuild3DTrayFitFlange)))
    (progn (princ "\n  Tee/cross rails need MED3DTrayFunctions.lsp loaded.") nil)
    (progn
      (setq data (list (p 0) (p 1) w d f)
            tmp  (MED3DL-tempTray (list (list (p 0) nil) (list (p 1) (nth 1 bl)) (list (p 2) nil) (list (p 3) nil))))
      (MEDBuild3DTrayFitFlange data 1.0 tmp T)
      (MED3DL-delTemp (MED3DL-lastPath)) (MED3DL-delTemp tmp)
      (setq data (list (p 3) (p 4) w d f)
            tmp  (MED3DL-tempTray (list (list (p 3) nil) (list (p 4) (nth 4 bl)) (list (p 5) nil) (list (p 6) nil))))
      (MEDBuild3DTrayFitFlange data 1.0 tmp T)
      (MED3DL-delTemp (MED3DL-lastPath)) (MED3DL-delTemp tmp)
      (if (= (length tp) 7)
        (MEDBuild3DTrayFlange (list (p 6) (p 0) w d f) 1.0 (MED3DL-dxf 210 (entget ent)))
        (progn
          (setq data (list (p 6) (p 7) w d f)
                tmp  (MED3DL-tempTray (list (list (p 6) nil) (list (p 7) (nth 4 bl)) (list (p 8) nil) (list (p 9) nil))))
          (MEDBuild3DTrayFitFlange data 1.0 tmp T)
          (MED3DL-delTemp (MED3DL-lastPath)) (MED3DL-delTemp tmp)
          (setq data (list (p 9) (p 8) w d f)
                tmp  (MED3DL-tempTray (list (list (p 9) nil) (list (p 8) (nth 1 bl)) (list (p 1) nil) (list (p 0) nil))))
          (MEDBuild3DTrayFitFlange data 1.0 tmp T)
          (MED3DL-delTemp (MED3DL-lastPath)) (MED3DL-delTemp tmp)))
      T))
  ;; lift the flat-built rails to the fitting elevation
  (if (and zu (not (equal zu 0.0 1e-9)))
    (progn
      (setq ss (ssadd) e (if mark (entnext mark) (entnext)))
      (while e
        (if (and (entget e) (= (MED3DL-dxf 0 (entget e)) "3DSOLID")) (ssadd e ss))
        (setq e (entnext e)))
      (if (> (sslength ss) 0)
        (command "._move" ss "" "_non" (list 0.0 0.0 0.0) "_non" (list 0.0 0.0 zu)))))
  (setvar "ELEVATION" (if z z 0.0))
  (list (car tp0) (angle (car tp0) (cadr tp0)))
)

;; Straight reducer rungs: always >= 2.  One inset from each opening
;; (inset = min(sp/2, L/4)), extra rungs at ~sp between.  Large-width rung
;; on the big half, reduced-width rung on the small half.
(defun MED3DL-redRungs (p1 p2 bname bname2 sp / L ang ins k i dd step n)
  (setq L (distance p1 p2) ang (angle p1 p2)
        ins (min (* 0.5 sp) (* 0.25 L))
        k   (max 1 (fix (+ 0.999 (/ (- L ins ins) sp))))
        step (/ (- L ins ins) k) i 0 n 0)
  (while (<= i k)
    (setq dd (+ ins (* i step)))
    (MED3DL-ins (if (<= dd (* 0.5 L)) bname bname2) (polar p1 ang dd)
                (MED3DL-rtd (+ ang (* pi 0.5))))
    (setq i (1+ i) n (1+ n)))
  n
)

;; Straight reducer 2D footprint length (MED house standard 18").
;; Set MED_TRAY_REDUCER_LEN to override detection (future: per material /
;; manufacturer).  NOTE Eaton B-Line Series 1-5 (Al & steel) straight
;; reducer "A" is SHORTER and varies with width change, e.g.
;;   12>9 8-7/8   12>6 9-3/4   18>12 9-3/4   24>18 9-3/4
;;   18>6 11-1/2  24>6 13-3/16   (LR/RR reducers are longer)
;; Recommend later: Al = B-Line A table keyed on (W - alt); FG (Enduro etc.)
;; use that maker's table; keep 18 as fallback.
(defun MED3DL-redLen ()
  (if (numberp MED_TRAY_REDUCER_LEN) MED_TRAY_REDUCER_LEN 18.0))

;; Straight reducer - same apt/bpt path as MEDDraw3DTrayStraightReducer.
;; One Extrude Path per rail along the full dog-leg (no per-segment Dir):
;; continuous flanges, no miter gaps at the taper corners.  Requires a real
;; flange size (MED3D-effFlange / DEFAULTFLANGE); Path with flange 0 was the
;; old flat-web failure mode.
(defun MED3DL-fitRailsRed (ent w d f alt / tp p1 p2 ang ps td apt1 apt2 apt3 apt4
                           bpt1 bpt2 bpt3 bpt4 data tmp)
  (setq tp (MED3DL-ptsUCS ent) p1 (nth 0 tp) p2 (nth 1 tp)
        ang (angle p1 p2) ps (if (numberp _PLOTSCALE) _PLOTSCALE 1.0) td 7.0
        apt1 (polar p1 (- ang (* pi 0.5)) (* 0.5 ps w))
        apt2 (polar p1 (+ ang (* pi 0.5)) (* 0.5 ps w)) ; was p2 (path doubled back)
        apt3 (polar apt1 ang (* ps td))
        apt4 (polar apt2 ang (* ps td))
        bpt1 (polar p2 (+ ang (* pi 0.5)) (* 0.5 ps alt))
        bpt2 (polar p2 (- ang (* pi 0.5)) (* 0.5 ps alt))
        bpt3 (polar bpt1 (+ pi ang) (* ps td))
        bpt4 (polar bpt2 (+ pi ang) (* ps td))
        f    (if (boundp (quote MED3D-effFlange)) (MED3D-effFlange f) f)
        data (list p1 p2 w d f))
  (if (boundp (quote MEDBuild3DTrayFlangeFromEntity))
    (progn
      (setq tmp (MED3DL-tempTray (list (list apt2 nil) (list apt4 nil)
                                       (list bpt3 nil) (list bpt1 nil))))
      (MEDBuild3DTrayFlangeFromEntity data 1.0 tmp)
      (MED3DL-delTemp tmp)
      (setq tmp (MED3DL-tempTray (list (list apt1 nil) (list apt3 nil)
                                       (list bpt4 nil) (list bpt2 nil))))
      (MEDBuild3DTrayFlangeFromEntity data -1.0 tmp)
      (MED3DL-delTemp tmp))
    (princ "\n  Reducer rails need MED3DTrayFunctions.lsp loaded."))
  (list p1 ang)
)

;; Left/right reducer - same construction as MEDDraw3DTrayLeftOrRightReducer.
(defun MED3DL-fitRailsLRRed (ent w d f alt xd / tp p1 p2 ps df tru rl srl halfalt half2
                             sina cosa fa ang op2 apt1 apt2 apt3 apt4 apt5 apt6 data tmp)
  (setq tp (MED3DL-ptsUCS ent) p1 (nth 0 tp) p2 (nth 1 tp)
        ps (if (numberp _PLOTSCALE) _PLOTSCALE 1.0)
        df (if (= (strcase (substr (med_getdesc "FITTING" (nth 3 xd)) 1 1)) "L") 1 -1)
        tru (angle p2 p1) rl (distance p1 p2) srl 18.0
        halfalt (* (- w alt 0.5)) half2 (* alt 0.5)
        sina (/ rl srl) cosa (/ halfalt srl)
        fa (* df (atan (/ sina cosa)))
        ang (+ tru fa)
        op2 (polar p2 ang halfalt)
        ang (angle p1 op2)
        apt1 (polar p2 (+ ang (* df (* pi 0.5))) (* ps half2))
        apt2 (polar apt1 (+ ang pi) (* srl ps))
        apt3 (polar apt2 (- ang (* df (* pi 0.5))) (* w ps))
        apt4 (polar apt3 ang (* 7.0 ps))
        apt6 (polar p2 (+ ang (* df (* pi 1.5))) (* ps half2))
        apt5 (polar apt6 (+ ang pi) (* 7.0 ps))
        op2  (polar p1 (angle apt3 apt4) srl)
        data (list p1 op2 w d f))
  (if (boundp (quote MEDBuild3DTrayFlangeFromEntity))
    (progn
      (setq tmp (MED3DL-tempTray (list (list apt2 nil) (list apt1 nil))))
      (MEDBuild3DTrayFlangeFromEntity data (* 1.0 df) tmp) (MED3DL-delTemp tmp)
      (setq tmp (MED3DL-tempTray (list (list apt3 nil) (list apt4 nil) (list apt5 nil) (list apt6 nil))))
      (MEDBuild3DTrayFlangeFromEntity data (* -1.0 df) tmp) (MED3DL-delTemp tmp))
    (princ "\n  LR reducer rails need MED3DTrayFunctions.lsp loaded."))
  (list p1 (angle p1 p2))
)

;;; ------------------------------------------------------------------
;;; One fitting -> one assembly block INSERT.  Returns block name or nil.
;;; ------------------------------------------------------------------
;; Transform every object in ss by WCS->current-UCS matrix, so a point
;; that sat at UCS coords q ends up at WCS coords q (canonical for -BLOCK).
;; No-op when current UCS is World.
(defun MED3DL-ssUcsToCanon (ss / o x y z m i dot)
  (setq o (getvar "UCSORG") x (getvar "UCSXDIR") y (getvar "UCSYDIR")
        z (list (- (* (cadr x) (caddr y)) (* (caddr x) (cadr y)))
                (- (* (caddr x) (car y)) (* (car x) (caddr y)))
                (- (* (car x) (cadr y)) (* (cadr x) (car y)))))
  (defun dot (a b) (apply (quote +) (mapcar (quote *) a b)))
  (if (not (and (equal o '(0.0 0.0 0.0) 1e-9) (equal x '(1.0 0.0 0.0) 1e-9)
                (equal y '(0.0 1.0 0.0) 1e-9)))
    (progn
      (setq m (vlax-tmatrix
                (list (append x (list (- (dot x o))))
                      (append y (list (- (dot y o))))
                      (append z (list (- (dot z o))))
                      (list 0.0 0.0 0.0 1.0)))
            i 0)
      (repeat (sslength ss)
        (vla-TransformBy (vlax-ename->vla-object (ssname ss i)) m)
        (setq i (1+ i)))))
  ss
)

(defun MED3DL-doFitting (ent / xd kind w d f alt code bname bname2 sp emark base ss
                         ang n tp p1 p2 ps rot oldelev nm ret)
  (setq xd   (xdataget ent (if (boundp (quote _FITTING)) _FITTING "MED_FITTING"))
        kind (MED3DL-fitKind ent))
  (cond
    ((null xd) (princ "\n  No MED_FITTING xdata.") nil)
    ((= kind "BLOCK")
      (princ (strcat "\n  Skipped " (MED3DL-dxf 5 (entget ent))
                     ": block fitting (not a tray outline) - handled by MEDMAKE3D conduit-body stage."))
      nil)
    ((null kind)
      (princ (strcat "\n  Skipped " (MED3DL-dxf 5 (entget ent))
                     ": not an elbow / tee / cross / reducer / swivel outline."))
      nil)
    ((= kind "SWIVEL")
      (if (not (boundp (quote MEDConvertTraySwivelTo3D)))
        (vl-catch-all-apply (function load) (list "MEDTraySwivel")))
      (if (boundp (quote MEDConvertTraySwivelTo3D))
        (progn (MEDConvertTraySwivelTo3D ent) "SWIVEL")
        (progn (princ "\n  Swivel 3D: MEDTraySwivel.lsp not loaded.") nil)))
    (T
      (setq w   (nth 2 xd) alt (nth 4 xd) d (nth 5 xd) f (nth 6 xd) code (nth 3 xd)
            sp  MED_TRAY_FITRUNGSPACING
            ps  (if (numberp _PLOTSCALE) _PLOTSCALE 1.0)
            oldelev (getvar "ELEVATION"))
      (if (null f) (setq f 0.0))
      (setq MED_TRAY_MATERIALWIDTH (MED3DL-materialFor ent "FITTING" code)
            MED3DL_FLANGE f
            MED3DL_FITDEPTH d)
      (if (boundp (quote MEDSet3DTrayLayer)) (MEDSet3DTrayLayer ent))
      (setq bname (MED3DL-ensureRungBlock w))
      (if (member kind '("RED" "LRRED")) (setq bname2 (MED3DL-ensureRungBlock alt)))
      (if (equal (MED3DL-dxf 210 (entget ent)) '(0.0 0.0 1.0) 1e-6)
        (command "._ucs" "_World")
        (command "._ucs" "_OB" ent))
      (setvar "ELEVATION" (MED3DL-dxf 38 (entget ent)))
      (setq emark (entlast) n 0)
      (cond
        ((= kind "ELBOW")
          (setq base (MED3DL-fitRailsElbow ent w d f nil)
                n    (MED3DL-rungsAlongCurve ent bname sp)))
        ((= kind "VELBOW")
          (setq base (MED3DL-fitRailsElbow ent w d f T)
                n    (MED3DL-velbowRungs ent (cadr base) bname sp)))
        ((member kind '("TEE" "CROSS"))
          (setq base (MED3DL-fitRailsTeeCross ent w d f)
                n    (MED3DL-teeCrossRungs ent w f bname sp)))
        ((member kind '("RED" "LRRED"))
          (setq base (if (= kind "RED")
                       (MED3DL-fitRailsRed ent w d f alt)
                       (MED3DL-fitRailsLRRed ent w d f alt xd))
                tp   (MED3DL-ptsUCS ent) p1 (nth 0 tp) p2 (nth 1 tp)
                n    (MED3DL-redRungs p1 p2 bname bname2 sp)))
      )
      (setvar "ELEVATION" oldelev)
      (setq ss (MED3DL-ssAfter emark))
      (if (or (null ss) (= (sslength ss) 0) (null base))
        (progn (princ "\n  No geometry created.") nil)
        (progn
          (setq nm  (MED3DL-fitName kind ent xd)
                rot (MED3DL-rtd (cadr base)))
          (if (and MED3DL_UNIQUEFITS (tblsearch "BLOCK" nm)) (setq nm (MED3DL-uniqueName nm)))
          (if (tblsearch "BLOCK" nm)
            (progn
              ;; same type/size/angle/hand/flange/material: reuse definition
              (command "._erase" ss "")
              (princ (strcat "\n  Using existing " nm)))
            (progn
              ;; canonical orientation: first leg along +X from base point
              (command "._rotate" ss "" "_non" (car base) (- rot))
              ;; UCS fix (t777u): geometry was built in the entity UCS; the
              ;; INSERT below (also in entity UCS) applies the UCS again, so
              ;; map the pieces UCS->WCS-canonical before defining the block.
              (MED3DL-ssUcsToCanon ss)
              (command "._ucs" "_World")
              (MED3DL-toLayer0 ss)
              (command "._-block" nm "_non" (car base) ss "")
              (command "._ucs" "_Previous")
              (princ (strcat "\n  Created " nm "  rungs " (itoa n)))))
          (MED3DL-ins nm (car base) rot)
          (setq ret nm)))
      (command "._ucs" "_World")
      ret)
  )
)

;;; ------------------------------------------------------------------
;;; One straight tray run (20 ft segmentation)
;;; ------------------------------------------------------------------
(defun MED3DL-doTray (ent seglen / xd width depth flange pts p1 p2 ucs rungName stats)
  (setq xd (xdataget ent (if (boundp (quote _TRAY)) _TRAY "MED_TRAY")))
  (if (not xd)
    (progn (princ "\n  No MED tray xdata.") nil)
    (progn
      (setq width  (nth 2 xd)
            depth  (nth 5 xd)
            flange (nth 7 xd)
            ucs    (MED3DL-dxf 210 (entget ent)))
      ;; UCS fix (Clint t776u): set entity UCS BEFORE trayPoints so the
      ;; (trans p 210 1) lands in the entity UCS (same as MEDConvertTrayTo3D).
      (if (equal ucs (list 0.0 0.0 1.0) 1e-6)
        (command "._ucs" "_World")
        (command "._ucs" "_OB" ent))
      (setq pts    (MED3DL-trayPoints ent)
            p1 (nth 0 pts) p2 (nth 1 pts) ucs (nth 2 pts))
      (if (or (not p1) (not p2) (not width) (not depth))
        (progn (princ "\n  Could not read tray points or size xdata.") nil)
        (progn
          (setq MED_TRAY_MATERIALWIDTH (MED3DL-materialFor ent "TRAY" (nth 3 xd))
                MED3DL_FLANGE (if flange flange 0.0)
                rungName (MED3DL-ensureRungBlock width))
          ;; buildRun/placeSegment expect p1/p2/ang in the CURRENT (entity) UCS.
          (if (boundp (quote MEDSet3DTrayLayer))
            (MEDSet3DTrayLayer ent)
            (if (and (boundp (quote smlayer)) (boundp (quote _MED3DTRAY))) (smlayer _MED3DTRAY)))
          (setq stats (MED3DL-buildRun p1 p2 width depth MED3DL_FLANGE ucs rungName seglen))
          (command "._ucs" "_World")
          (princ (strcat "\n  Run W" (rtos width 2 2) " D" (rtos depth 2 2)
                         " L" (rtos (nth 2 stats) 2 2)
                         "  stock " (itoa (nth 0 stats)) "  remnant " (itoa (nth 1 stats))
                         "  t=" (rtos MED_TRAY_MATERIALWIDTH 2 3)
                         (if (< MED3DL_FLANGE 0.0) "  flange OUT" "  flange IN")))
          stats)))
  )
)

(defun MED3DL-hasXd (ent app) (and ent app (xdataget ent app)))

(defun c:Make3DLadderTray ( / *error* ent seglen oldc oldos oldexp olddel oldatt oldelev
                              ss i nT nF nS app tApp fApp)
  (defun *error* (msg)
    (if MED3DL_BASEMAT (setq MED_TRAY_MATERIALWIDTH MED3DL_BASEMAT))
    (if oldelev (setvar "ELEVATION" oldelev))
    (if oldatt (setvar "ATTREQ" oldatt))
    (MED3DL-restore oldc oldos oldexp olddel)
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*")))
      (princ (strcat "\nMake3DLadderTray: " msg)))
    (princ)
  )
  (if (not (boundp (quote xdataget)))
    (princ "\nLoad MED first (xdataget / _TRAY / _FITTING), then load MED3DTrayFunctions (it loads this file).")
    (progn
      (setq tApp (if (boundp (quote _TRAY)) _TRAY "MED_TRAY")
            fApp (if (boundp (quote _FITTING)) _FITTING "MED_FITTING")
            MED3DL_BASEMAT MED_TRAY_MATERIALWIDTH
            oldc (getvar "CMDECHO") oldos (getvar "OSMODE") oldexp (getvar "EXPERT")
            olddel (getvar "DELOBJ") oldatt (getvar "ATTREQ") oldelev (getvar "ELEVATION")
            nT 0 nF 0 nS 0)
      (setq ent (car (entsel "\nSelect MED tray run or tray fitting <Enter = all in drawing>: ")))
      (initget 6)
      (setq seglen (getdist (strcat "\nStock tray piece length <" (rtos MED_TRAY_SEGLEN 2 0) "\">: ")))
      (if (not seglen) (setq seglen MED_TRAY_SEGLEN))
      (setq MED_TRAY_SEGLEN seglen)
      (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "DELOBJ" 1)
      (setvar "EXPERT" 5) (setvar "ATTREQ" 0)
      (command "._undo" "_BE")
      (if ent
        (cond
          ((MED3DL-hasXd ent fApp)
            (if (MED3DL-doFitting ent) (setq nF 1) (setq nS 1)))
          ((MED3DL-hasXd ent tApp)
            (if (MED3DL-doTray ent seglen) (setq nT 1) (setq nS 1)))
          (T (princ "\nNo MED tray or fitting xdata on that entity.")))
        (progn
          (if (setq ss (ssget "_X" (list (list -3 (list "MED_TRAY")))))
            (progn
              (setq i 0)
              (while (< i (sslength ss))
                (if (MED3DL-doTray (ssname ss i) seglen) (setq nT (1+ nT)) (setq nS (1+ nS)))
                (setq i (1+ i)))))
          (if (setq ss (ssget "_X" (list (list -3 (list "MED_FITTING")))))
            (progn
              (setq i 0)
              (while (< i (sslength ss))
                (if (MED3DL-doFitting (ssname ss i)) (setq nF (1+ nF)) (setq nS (1+ nS)))
                (setq i (1+ i)))))))
      (command "._undo" "_E")
      (setq MED_TRAY_MATERIALWIDTH MED3DL_BASEMAT)
      (setvar "ELEVATION" oldelev) (setvar "ATTREQ" oldatt)
      (MED3DL-restore oldc oldos oldexp olddel)
      (command "._ucs" "_World")
      (princ (strcat "\nLadder tray (open bottom): runs " (itoa nT)
                     "  fittings " (itoa nF) "  skipped " (itoa nS)))
    )
  )
  (princ)
)

(if (not MED3DL_BASEMAT) (setq MED3DL_BASEMAT MED_TRAY_MATERIALWIDTH))
(princ "\nMake3DLadderTray loaded (separate file). Pick a tray run / fitting, or Enter for all.")
(princ)
