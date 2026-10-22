;;; MEDNode.lsp - MED routing nodes (MEDNODE). See docs\design\mednode.md.
;;;
;;; One standard block, MED_NODE, placed at route vertices. Everything about the node
;;; lives in XData under the MED_NODE app, written in the standard MED Data format
;;; (1002 "{", 1000 "KEY______=value" strings, 1002 "}") used by bld_app / bld_fitting:
;;; The node ID is NOT stored: it is the live AutoCAD handle of the INSERT. On extraction the
;;; unique key is drawing name + handle (med-node-key-of); a copied node gets a new handle.
;;;   NODE_KIND=  VERTEX | JUNCTION | ENDPOINT | INTERSECTION
;;;   NODE_SYS_=  CONDUIT | TRAY | CABLE
;;;   NODE_CONN=  one connected segment, "runhandle#segment" (one record per connection, N of them)
;;;   ITEM_TAG_=  #ITEMCODE= #ITEMSIZE=   the fitting assignment, same keys as bld_fitting.
;;;               Empty (the default) = no fitting: a 2-connection conduit node is a standard
;;;               field bend from MEDBendRadius, counted as conduit length.
;;; The node does NOT carry MED_FITTING xdata, so the BOM never counts a bare node.
;;; A later "set fitting" command only has to call med-node-set-fitting.
;;; The block is visible (circle + cross) with a POINT at its insertion, so STRETCH / MOVE that
;;; take the route vertex also take the node. No reactors. MEDNODEAUDIT finds nodes left behind.
(princ "\rLoading MEDNode...")

(setq *MED-NODE-APP* "MED_NODE" *MED-NODE-BLOCK* "MED_NODE" *MED-NODE-LAYER* "MED_NODE")
(if (not *MED-NODE-TOL*) (setq *MED-NODE-TOL* 0.5))   ; detection tolerance, drawing units

(defun med-node-size () (* 0.0625 (if (and _PLOTSCALE (numberp _PLOTSCALE) (> _PLOTSCALE 0)) _PLOTSCALE 48.0)))

;; the one standard block: unit circle + cross, scaled at insert
(defun med-node-ensure-block ()
  (if (not (tblsearch "LAYER" *MED-NODE-LAYER*))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                   (cons 2 *MED-NODE-LAYER*) '(70 . 0) '(62 . 6) '(6 . "Continuous"))))
  (if (not (tblsearch "APPID" *MED-NODE-APP*)) (regapp *MED-NODE-APP*))
  (if (not (tblsearch "BLOCK" *MED-NODE-BLOCK*))
    (progn
      (entmake (list '(0 . "BLOCK") (cons 2 *MED-NODE-BLOCK*) '(70 . 0) '(10 0.0 0.0 0.0)))
      (entmake '((0 . "CIRCLE") (8 . "0") (62 . 0) (10 0.0 0.0 0.0) (40 . 1.0)))
      (entmake '((0 . "LINE") (8 . "0") (62 . 0) (10 -1.0 0.0 0.0) (11 1.0 0.0 0.0)))
      (entmake '((0 . "LINE") (8 . "0") (62 . 0) (10 0.0 -1.0 0.0) (11 0.0 1.0 0.0)))
      (entmake '((0 . "POINT") (8 . "0") (62 . 0) (10 0.0 0.0 0.0)))
      (entmake '((0 . "ENDBLK"))))
    (med-node-block-point))
  *MED-NODE-BLOCK*)

;; older MED_NODE definitions (before the POINT): add the insertion POINT once
(defun med-node-block-point (/ e has)
  (setq e (cdr (assoc -2 (tblsearch "BLOCK" *MED-NODE-BLOCK*))))
  (while e (if (= (cdr (assoc 0 (entget e))) "POINT") (setq has T)) (setq e (entnext e)))
  (if (not has)
    (progn (vl-load-com)
      (vl-catch-all-apply 'vla-AddPoint
        (list (vla-item (vla-get-Blocks (vla-get-ActiveDocument (vlax-get-acad-object))) *MED-NODE-BLOCK*)
              (vlax-3d-point '(0.0 0.0 0.0)))))))

;; node id = live handle; extraction key = drawing name + handle
(defun med-node-id (e) (cdr (assoc 5 (entget e))))
(defun med-node-key-of (n) (strcat (getvar "DWGNAME") "|" (cdr (assoc "ID" n))))

(defun med-node-key (s k) (if (= (substr s 1 (strlen k)) k) (substr s (1+ (strlen k)))))

;; node alist -> MED Data xdata list
(defun med-node-build-xd (n / xd)
  (setq xd (list *MED-NODE-APP* (cons 1002 "{")
                 (cons 1000 (strcat "NODE_KIND=" (cdr (assoc "KIND" n))))
                 (cons 1000 (strcat "NODE_SYS_=" (cdr (assoc "SYS" n))))))
  (foreach h (cdr (assoc "CONN" n)) (setq xd (append xd (list (cons 1000 (strcat "NODE_CONN=" h))))))
  (append xd (list (cons 1000 (strcat "ITEM_TAG_=" (cond ((cdr (assoc "TAG" n))) (""))))
                   (cons 1000 (strcat "#ITEMCODE=" (cond ((cdr (assoc "CODE" n))) (""))))
                   (cons 1000 (strcat "#ITEMSIZE=" (cond ((cdr (assoc "SIZE" n))) (""))))
                   (cons 1002 "}"))))

;; MED_NODE INSERT -> ("ID"(=handle) "KIND" "SYS" ("CONN" h ...) "TAG" "CODE" "SIZE" "FITTING" "ENT"); nil if not a node
(defun med-node-read (e / ed xd n conn v)
  (setq ed (entget e (list *MED-NODE-APP*)))
  (if (and (= (cdr (assoc 0 ed)) "INSERT") (setq xd (assoc -3 ed)) (setq xd (cdr (assoc *MED-NODE-APP* (cdr xd)))))
    (progn
      (foreach r xd
        (if (= (car r) 1000)
          (cond ((setq v (med-node-key (cdr r) "NODE_KIND=")) (setq n (cons (cons "KIND" v) n)))
                ((setq v (med-node-key (cdr r) "NODE_SYS_=")) (setq n (cons (cons "SYS" v) n)))
                ((setq v (med-node-key (cdr r) "NODE_CONN=")) (setq conn (cons v conn)))
                ((setq v (med-node-key (cdr r) "ITEM_TAG_=")) (setq n (cons (cons "TAG" v) n)))
                ((setq v (med-node-key (cdr r) "#ITEMCODE=")) (setq n (cons (cons "CODE" v) n)))
                ((setq v (med-node-key (cdr r) "#ITEMSIZE=")) (setq n (cons (cons "SIZE" v) n))))))
      (append (list (cons "ENT" e) (cons "ID" (med-node-id e)) (cons "PT" (cdr (assoc 10 ed))) (cons "CONN" (reverse conn))
                    (cons "FITTING" (med-node-fitting-of n)))
              n))))

;; fitting assignment string, nil = none (standard field bend)
(defun med-node-fitting-of (n / c z tg)
  (setq c (cond ((cdr (assoc "CODE" n))) ("")) z (cond ((cdr (assoc "SIZE" n))) ("")) tg (cond ((cdr (assoc "TAG" n))) ("")))
  (if (/= c "") (strcat c (if (/= z "") (strcat "/" z) "") (if (/= tg "") (strcat " " tg) ""))))

(defun med-node-write (e n / ed)
  (setq ed (entget e) ed (vl-remove (assoc -3 ed) ed))
  (entmod (append ed (list (list -3 (med-node-build-xd n))))))

;; API for the later "tap a node, set fitting" command: updates XData only
(defun med-node-set-fitting (e code size tag / n)
  (if (setq n (med-node-read e))
    (progn
      (foreach k '("CODE" "SIZE" "TAG") (setq n (vl-remove (assoc k n) n)))
      (setq n (append n (list (cons "CODE" (if code (vl-princ-to-string code) ""))
                              (cons "SIZE" (if size (vl-princ-to-string size) ""))
                              (cons "TAG" (if tag tag "")))))
      (med-node-write e n) T)))

;; every node in the drawing (list of node alists)
(defun med-node-all (/ ss i r n)
  (if (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 2 *MED-NODE-BLOCK*))))
    (progn (setq i 0)
      (repeat (sslength ss)
        (if (setq n (med-node-read (ssname ss i))) (setq r (cons n r)))
        (setq i (1+ i)))))
  (reverse r))

;; nearest node within tol of pt (from a node list, or the drawing)
(defun med-node-at (pt tol nodes / best bd d)
  (foreach n (if nodes nodes (med-node-all))
    (if (and (<= (setq d (distance pt (cdr (assoc "PT" n)))) tol) (or (null bd) (< d bd)))
      (setq best n bd d)))
  best)

(defun med-node-sys (e)
  (cond ((and _CABLE (assoc -3 (entget e (list _CABLE)))) "CABLE")
        ((and _TRAY (assoc -3 (entget e (list _TRAY)))) "TRAY")
        (T "CONDUIT")))

(defun med-node-kind (nconn end) (cond ((> nconn 2) "JUNCTION") (end "ENDPOINT") (T "VERTEX")))

;; segment id: run handle + "#" + 1-based segment number
(defun med-node-seg-id (e k) (strcat (cdr (assoc 5 (entget e))) "#" (itoa k)))

;; tag one vertex of run e (WCS pt) with its connected segment ids; reuses a node already
;; there (within *MED-NODE-TOL*) and adds the new connections
(defun med-node-tag (e pt ids end / n ne s cn)
  (med-node-ensure-block)
  (if (setq n (med-node-at pt *MED-NODE-TOL* nil))
    (progn
      (setq cn (cdr (assoc "CONN" n)))
      (foreach id ids (if (not (member id cn)) (setq cn (append cn (list id)))))
      (if (/= (length cn) (length (cdr (assoc "CONN" n))))
        (progn
          (setq n (subst (cons "CONN" cn) (assoc "CONN" n) n)
                n (subst (cons "KIND" (med-node-kind (length cn) nil)) (assoc "KIND" n) n))
          (med-node-write (cdr (assoc "ENT" n)) n)))
      (cdr (assoc "ENT" n)))
    (progn
      (setq s (med-node-size))
      (entmake (list '(0 . "INSERT") (cons 2 *MED-NODE-BLOCK*) (cons 8 *MED-NODE-LAYER*) (cons 10 pt)
                     (cons 41 s) (cons 42 s) (cons 43 s)))
      (setq ne (entlast))
      (med-node-write ne (list (cons "KIND" (med-node-kind (length ids) end)) (cons "SYS" (med-node-sys e))
                               (cons "CONN" ids)))
      ne)))

(defun med-node-verts (e / pd) (if (setq pd (med3d-read-path e)) (car pd)))

;; ids of the segments meeting at vertex i of a run with n vertices (open runs)
(defun med-node-ids-at (e i n)
  (append (if (> i 0) (list (med-node-seg-id e i)))
          (if (< i (1- n)) (list (med-node-seg-id e (1+ i))))))

;; all vertices of a run: interior corners (and the ends when ends is T)
(defun med-node-tag-run (e ends / pts i n cnt)
  (setq pts (med-node-verts e) n (length pts) i 0 cnt 0)
  (foreach p pts
    (if (or ends (and (> i 0) (< i (1- n))))
      (progn (med-node-tag e p (med-node-ids-at e i n) (or (= i 0) (= i (1- n)))) (setq cnt (1+ cnt))))
    (setq i (1+ i)))
  cnt)

(defun c:MEDNODE (/ op ss i cnt es e p best bi pts)
  (initget "Pick Run")
  (setq op (cond ((getkword "\nMEDNODE [Pick vertices/Run (tag all corners)] <Run>: ")) ("Run")))
  (cond
    ((= op "Run")
      (princ "\nSelect routes: ")
      (setq cnt 0)
      (if (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE,LINE"))))
        (progn (setq i 0)
          (repeat (sslength ss) (setq cnt (+ cnt (med-node-tag-run (ssname ss i) nil)) i (1+ i)))))
      (princ (strcat "\nMEDNODE: " (itoa cnt) " corner node(s) tagged.")))
    (T
      (while (setq es (entsel "\nSelect route near the vertex (Enter to finish): "))
        (setq e (car es) p (trans (cadr es) 1 0) best nil bi nil i 0 pts (med-node-verts e))
        (foreach v pts
          (if (or (null best) (< (distance (list (car p) (cadr p)) (list (car v) (cadr v)))
                                 (distance (list (car p) (cadr p)) (list (car best) (cadr best)))))
            (setq best v bi i))
          (setq i (1+ i)))
        (if best
          (progn (med-node-tag e best (med-node-ids-at e bi (length pts)) (or (= bi 0) (= bi (1- (length pts)))))
                 (princ (strcat "\nNode at " (rtos (car best) 2 2) "," (rtos (cadr best) 2 2) "," (rtos (caddr best) 2 2))))
          (princ "\nNot a route.")))))
  (princ))

;;; ------------------------------------------------------------ MEDNODEAUDIT
;; live run entity for a "handle#seg" connection, nil when the handle is gone/erased
(defun med-node-conn-ent (c / h e)
  (setq h (substr c 1 (cond ((vl-string-search "#" c)) ((strlen c)))))
  (if (and (setq e (handent h)) (entget e)) e))

;; nearest vertex (WCS) of the node's live connected runs, nil if none
(defun med-node-nearest-vertex (n / pt best bd d e)
  (setq pt (cdr (assoc "PT" n)))
  (foreach c (cdr (assoc "CONN" n))
    (if (setq e (med-node-conn-ent c))
      (foreach v (med-node-verts e)
        (if (or (null bd) (< (setq d (distance pt v)) bd)) (setq best v bd (distance pt v))))))
  best)

;; orphans: ((node reason) ...). Reason: dead handle(s), or not on any connected run's vertex.
(defun med-node-audit (/ r dead v pt)
  (foreach n (med-node-all)
    (setq dead nil pt (cdr (assoc "PT" n)))
    (foreach c (cdr (assoc "CONN" n)) (if (not (med-node-conn-ent c)) (setq dead (cons c dead))))
    (setq v (med-node-nearest-vertex n))
    (cond
      ((null (cdr (assoc "CONN" n))) (setq r (cons (list n "no connections") r)))
      (dead (setq r (cons (list n (strcat "deleted route " (car dead))) r)))
      ((or (null v) (> (distance pt v) *MED-NODE-TOL*))
        (setq r (cons (list n (strcat "off vertex by " (if v (rtos (distance pt v) 2 3) "?"))) r)))))
  (reverse r))

;; move a node onto the nearest vertex of its live runs; drops dead connections. T if moved/fixed.
(defun med-node-snap (n / e v ed cn)
  (setq e (cdr (assoc "ENT" n)))
  (if (setq v (med-node-nearest-vertex n))
    (progn
      (setq ed (entget e) ed (subst (cons 10 v) (assoc 10 ed) ed))
      (entmod ed)
      (foreach c (cdr (assoc "CONN" n)) (if (med-node-conn-ent c) (setq cn (cons c cn))))
      (setq cn (reverse cn)
            n (subst (cons "CONN" cn) (assoc "CONN" n) n)
            n (subst (cons "KIND" (med-node-kind (length cn) (= (length cn) 1))) (assoc "KIND" n) n))
      (med-node-write e n)
      (entupd e) T)))

;; Yellow halo = the MED Records find/show highlight (MedHalo in MED-DotNet: transient yellow
;; box, pad 15% of the item's size, zoom 2.8x). Never added to the drawing. Without the DLL
;; (core console / old DLL) the same box is drawn with grvecs, cleared by REDRAW.
(defun med-node-halo-show (e / ed c s span pad mn mx k th v)
  (med-node-halo-clear)
  (if (and MED-HALO-SHOW (not (vl-catch-all-error-p (setq v (vl-catch-all-apply 'MED-HALO-SHOW (list e T))))) v)
    T
    (progn
      (setq ed (entget e) c (cdr (assoc 10 ed)) s (abs (cond ((cdr (assoc 41 ed))) (1.0)))
            span (* 2.0 s) pad (* span 0.15) th (max 0.01 (* span 0.04)))
      (command "_.ZOOM" "_C" (trans c 0 1) (* span 2.8))
      (setq k 0.0)
      (while (<= k th)
        (setq mn (list (- (car c) s pad k) (- (cadr c) s pad k)) mx (list (+ (car c) s pad k) (+ (cadr c) s pad k)))
        (grvecs (list 2 (trans mn 0 1) (trans (list (car mx) (cadr mn)) 0 1)
                      2 (trans (list (car mx) (cadr mn)) 0 1) (trans mx 0 1)
                      2 (trans mx 0 1) (trans (list (car mn) (cadr mx)) 0 1)
                      2 (trans (list (car mn) (cadr mx)) 0 1) (trans mn 0 1)))
        (setq k (+ k (/ th 4.0))))
      (setq *MED-NODE-HALO* T)
      nil)))

(defun med-node-halo-clear ()
  (if MED-HALO-CLEAR (vl-catch-all-apply 'MED-HALO-CLEAR nil))
  (if *MED-NODE-HALO* (progn (redraw) (setq *MED-NODE-HALO* nil)))
  (princ))

(defun c:MEDNODEAUDIT (/ all orph n tot i op nsnap ndel nskip done vc vs *error* med-node-audit-end)
  (defun med-node-audit-end ()
    (med-node-halo-clear)
    (if vc (command "_.ZOOM" "_C" vc vs))
    (if orph (princ (strcat "\nMEDNODEAUDIT done: snapped " (itoa nsnap) ", deleted " (itoa ndel)
                            ", skipped " (itoa (- tot nsnap ndel)) "."))))
  (defun *error* (msg)
    (med-node-audit-end)
    (if (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")) (princ (strcat "\nError: " msg)))
    (princ))
  (setq all (med-node-all) orph (med-node-audit) tot (length orph) nsnap 0 ndel 0 i 0)
  (if (null orph)
    (princ (strcat "\nMEDNODEAUDIT: No orphaned nodes found (" (itoa (length all)) " nodes checked)."))
    (progn
      (princ (strcat "\nMEDNODEAUDIT: " (itoa tot) " orphaned node(s) found (of " (itoa (length all)) " nodes)."))
      (setq vc (getvar "VIEWCTR") vs (getvar "VIEWSIZE"))
      (foreach o orph
        (if (not done)
          (progn
            (setq i (1+ i) n (car o))
            (med-node-halo-show (cdr (assoc "ENT" n)))
            (initget "Snap Delete Next eXit")
            (setq op (cond ((getkword (strcat "\nOrphan " (itoa i) " of " (itoa tot) ": " (cadr o)
                                              " (" (med-node-key-of n) ") [Snap/Delete/Next/eXit] <Next>: ")))
                           ("Next")))
            (cond
              ((= op "Snap")
                (if (med-node-snap n)
                  (progn (setq nsnap (1+ nsnap)) (princ "\n  Snapped to the nearest vertex."))
                  (princ "\n  No live route to snap to (use Delete) - skipped.")))
              ((= op "Delete")
                (initget "Yes No")
                (if (= (getkword "\n  Delete this node? [Yes/No] <No>: ") "Yes")
                  (progn (entdel (cdr (assoc "ENT" n))) (setq ndel (1+ ndel)) (princ "\n  Deleted."))
                  (princ "\n  Kept - skipped.")))
              ((= op "eXit") (setq done T)))
            (med-node-halo-clear))))
      (med-node-audit-end)))
  (princ))

;;; exporter side: annotate a M3D/C3D plan's corners with the nodes on them.
;;; Returns ((vertex-index node-id fitting-or-nil) ...). No fitting = standard bend (no change).
(defun med-node-plan-nodes (plan / nodes r n)
  (if (setq nodes (med-node-all))
    (foreach c (cdr (assoc "CORNERS" plan))
      (if (setq n (med-node-at (cdr (assoc "VERTEX" c)) *MED-NODE-TOL* nodes))
        (setq r (cons (list (cdr (assoc "INDEX" c)) (cdr (assoc "ID" n)) (cdr (assoc "FITTING" n))) r)))))
  (reverse r))

(princ "Done.")
(princ)
