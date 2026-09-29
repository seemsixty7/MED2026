;;; MED3DPathTest.lsp - sample runs for Support\MED3DPath.lsp (not shipped).
;;; Needs MED loaded (MEDCore: xdatadd, bld_conduit, bld_cable, MED3DPath).
;;; APPLOAD this file in a scratch drawing (inches), then run MED3DPATHTEST.
;;; Draws the source runs on layer MED3DTEST at X >= 1000, builds solids with
;;; the same code M3D / C3D use, and prints each run's corner table.
;;; Expected (EMT 1" OD 1.163 -> R 5.815; rigid 2" OD 2.375 -> R 11.875):
;;;   A LW, 2 x 90 deg          : v2 FITTED, v3 FITTED           one swept solid
;;;   B 2D heavy + bulges       : v4 FITTED, v5 KINK             pieces + sphere
;;;   C 3D sloped               : v2 FITTED, v3 FITTED           pieces (non-planar)
;;;   D 3D, 3" jog              : v2 FLAGGED, v3 FLAGGED         2 spheres + 2 markers
;;;   E 3D, 8" jog              : v2 FLAGGED, v3 FITTED          1 sphere + 1 marker
;;;   F LW closed 48" square    : v2 v3 v4 v1 FITTED             closed ring
;;;   G cable 3D (code 3)       : v2 FITTED, R = 7 x cable OD (needs MEDType USER3 for code 3)
;;;   H 3D lead-in + tilted loop: v2 v3 v4 v5 FITTED              4 bends, no spheres
;;;   I as H, 0.05" jogs        : jog vertices dropped (debug), same as H
;;; (setq *MED3D-DEBUG* T) first for the per-corner / per-piece trace.

(defun med3dt-lw (pts closed elev / ed)
  (setq ed (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") '(8 . "MED3DTEST") '(100 . "AcDbPolyline")
                 (cons 90 (length pts)) (cons 70 (if closed 1 0)) (cons 38 elev)))
  (foreach p pts
    (setq ed (append ed (list (list 10 (car p) (cadr p)) (cons 42 (if (caddr p) (caddr p) 0.0))))))
  (entmake ed)
  (entlast))

(defun med3dt-2d (pts elev)
  (entmake (list '(0 . "POLYLINE") '(100 . "AcDbEntity") '(8 . "MED3DTEST") '(100 . "AcDb2dPolyline")
                 '(66 . 1) (list 10 0.0 0.0 elev) '(70 . 0)))
  (foreach p pts
    (entmake (list '(0 . "VERTEX") '(100 . "AcDbEntity") '(8 . "MED3DTEST") '(100 . "AcDbVertex")
                   '(100 . "AcDb2dVertex") (list 10 (car p) (cadr p) elev)
                   (cons 42 (if (caddr p) (caddr p) 0.0)) '(70 . 0))))
  (entmake '((0 . "SEQEND") (8 . "MED3DTEST")))
  (entlast))

(defun med3dt-3d (pts)
  (entmake (list '(0 . "POLYLINE") '(100 . "AcDbEntity") '(8 . "MED3DTEST") '(100 . "AcDb3dPolyline")
                 '(66 . 1) '(10 0.0 0.0 0.0) '(70 . 8)))
  (foreach p pts
    (entmake (list '(0 . "VERTEX") '(100 . "AcDbEntity") '(8 . "MED3DTEST") '(100 . "AcDbVertex")
                   '(100 . "AcDb3dPolylineVertex") (cons 10 p) '(70 . 32))))
  (entmake '((0 . "SEQEND") (8 . "MED3DTEST")))
  (entlast))

(defun med3dt-conduit (e code size tag) (xdatadd e (bld_conduit code size tag nil nil)) e)
(defun med3dt-cable (e code tag) (xdatadd e (bld_cable code 1.0 tag "NONE" nil nil)) e)

(defun med3dt-go (label e kind / r)
  (princ (strcat "\n\n=== " label " ==="))
  (if (setq r (med3d-run e kind))
    (med3d-print-plan (cadr r))
    (princ "\n  (no solid)")))

(defun c:MED3DPATHTEST ( / b)
  (if (not med3d-run) (load "MED3DPath.lsp"))
  (med3d-begin "MED3DPATHTEST")
  (med3d-ensure-layer '("MED3DTEST" "WHITE" "CONTINUOUS"))
  (setq b (/ (sin (/ pi 8.0)) (cos (/ pi 8.0))))   ; bulge of a 90 deg arc
  (med3dt-go "A LW 2x90 (EMT 1in, elev 120)"
    (med3dt-conduit (med3dt-lw '((1000.0 0.0) (1120.0 0.0) (1120.0 96.0) (1240.0 96.0)) nil 120.0)
                    4 1.0 "T3D-A") "CONDUIT")
  (med3dt-go "B 2D heavy, bulges kept, fillet + kink (rigid 1in, elev 60)"
    (med3dt-conduit (med3dt-2d (list '(1000.0 150.0) (list 1050.0 150.0 b) '(1060.0 160.0) '(1060.0 200.0)
                                     (list 1100.0 200.0 (- b)) '(1120.0 220.0) '(1160.0 220.0)) 60.0)
                    1 1.0 "T3D-B") "CONDUIT")
  (med3dt-go "C 3D sloped (EMT 1in)"
    (med3dt-conduit (med3dt-3d '((1000.0 300.0 0.0) (1100.0 300.0 0.0) (1160.0 360.0 40.0) (1160.0 460.0 120.0)))
                    4 1.0 "T3D-C") "CONDUIT")
  (med3dt-go "D 3D 3in jog - both corners must FLAG"
    (med3dt-conduit (med3dt-3d '((1000.0 600.0 0.0) (1100.0 600.0 0.0) (1100.0 603.0 0.0) (1200.0 603.0 0.0)))
                    4 1.0 "T3D-D") "CONDUIT")
  (med3dt-go "E 3D 8in jog - one corner FLAGS"
    (med3dt-conduit (med3dt-3d '((1000.0 700.0 0.0) (1100.0 700.0 0.0) (1100.0 708.0 0.0) (1200.0 708.0 0.0)))
                    4 1.0 "T3D-E") "CONDUIT")
  (med3dt-go "F LW closed 48in square (rigid 2in)"
    (med3dt-conduit (med3dt-lw '((1300.0 0.0) (1348.0 0.0) (1348.0 48.0) (1300.0 48.0)) T 0.0)
                    1 2.0 "T3D-F") "CONDUIT")
  (med3dt-go "G cable 3D (cable code 3)"
    (med3dt-cable (med3dt-3d '((1000.0 800.0 0.0) (1100.0 800.0 0.0) (1100.0 900.0 50.0))) 3 "T3D-G") "CABLE")
  (med3dt-go "H 3D lead-in + tilted triangle loop (EMT 1in) - 4 bends, no spheres"
    (med3dt-conduit (med3dt-3d '((1400.0 0.0 120.0) (1500.0 0.0 120.0) (1700.0 40.0 150.0)
                                 (1560.0 200.0 90.0) (1500.0 0.0 120.0)))
                    4 1.0 "T3D-H") "CONDUIT")
  (med3dt-go "I as H with 0.05in jogs at the corners - jogs dropped, 4 bends"
    (med3dt-conduit (med3dt-3d '((1400.0 300.0 120.0) (1500.0 300.0 120.0) (1500.0 300.0 120.05)
                                 (1700.0 340.0 150.0) (1700.0 340.0 150.05) (1560.0 500.0 90.0)
                                 (1560.0 500.0 90.05) (1500.0 300.0 120.0)))
                    4 1.0 "T3D-I") "CONDUIT")
  (med3d-end)
  (command "_.ZOOM" "_E")
  (princ "\n\nMED3DPATHTEST done. Solids: MED_3DCONDUIT / MED_3DCABLE, flags: MED_3DFLAG.")
  (princ))
