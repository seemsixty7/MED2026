;;; MEDNode.lsp - MED routing nodes (MEDNODE). See docs\design\mednode.md.
;;;
;;; One standard block, MED_NODE, placed at route vertices. Everything about the node
;;; lives in XData under the MED_NODE app, written in the standard MED Data format
;;; (1002 "{", 1000 "KEY______=value" strings, 1002 "}") used by bld_app / bld_fitting:
;;;   NODE_ID__=  stable node id (N + handle of the INSERT when it was first tagged)
;;;   NODE_KIND=  VERTEX | JUNCTION | ENDPOINT | INTERSECTION
;;;   NODE_SYS_=  CONDUIT | TRAY | CABLE
;;;   NODE_CONN=  one connected segment, "runhandle#segment" (one record per connection, N of them)
;;;   ITEM_TAG_=  #ITEMCODE= #ITEMSIZE=   the fitting assignment, same keys as bld_fitting.
;;;               Empty (the default) = no fitting: a 2-connection conduit node is a standard
;;;               field bend from MEDBendRadius, counted as conduit length.
;;; The node does NOT carry MED_FITTING xdata, so the BOM never counts a bare node.
;;; A later "set fitting" command only has to call med-node-set-fitting.
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
      (entmake '((0 . "ENDBLK")))))
  *MED-NODE-BLOCK*)

(defun med-node-key (s k) (if (= (substr s 1 (strlen k)) k) (substr s (1+ (strlen k)))))

;; node alist -> MED Data xdata list
(defun med-node-build-xd (n / xd)
  (setq xd (list *MED-NODE-APP* (cons 1002 "{")
                 (cons 1000 (strcat "NODE_ID__=" (cdr (assoc "ID" n))))
                 (cons 1000 (strcat "NODE_KIND=" (cdr (assoc "KIND" n))))
                 (cons 1000 (strcat "NODE_SYS_=" (cdr (assoc "SYS" n))))))
  (foreach h (cdr (assoc "CONN" n)) (setq xd (append xd (list (cons 1000 (strcat "NODE_CONN=" h))))))
  (append xd (list (cons 1000 (strcat "ITEM_TAG_=" (cond ((cdr (assoc "TAG" n))) (""))))
                   (cons 1000 (strcat "#ITEMCODE=" (cond ((cdr (assoc "CODE" n))) (""))))
                   (cons 1000 (strcat "#ITEMSIZE=" (cond ((cdr (assoc "SIZE" n))) (""))))
                   (cons 1002 "}"))))

;; MED_NODE INSERT -> ("ID" "KIND" "SYS" ("CONN" h ...) "TAG" "CODE" "SIZE" "FITTING" "ENT"); nil if not a node
(defun med-node-read (e / ed xd n conn v)
  (setq ed (entget e (list *MED-NODE-APP*)))
  (if (and (= (cdr (assoc 0 ed)) "INSERT") (setq xd (assoc -3 ed)) (setq xd (cdr (assoc *MED-NODE-APP* (cdr xd)))))
    (progn
      (foreach r xd
        (if (= (car r) 1000)
          (cond ((setq v (med-node-key (cdr r) "NODE_ID__=")) (setq n (cons (cons "ID" v) n)))
                ((setq v (med-node-key (cdr r) "NODE_KIND=")) (setq n (cons (cons "KIND" v) n)))
                ((setq v (med-node-key (cdr r) "NODE_SYS_=")) (setq n (cons (cons "SYS" v) n)))
                ((setq v (med-node-key (cdr r) "NODE_CONN=")) (setq conn (cons v conn)))
                ((setq v (med-node-key (cdr r) "ITEM_TAG_=")) (setq n (cons (cons "TAG" v) n)))
                ((setq v (med-node-key (cdr r) "#ITEMCODE=")) (setq n (cons (cons "CODE" v) n)))
                ((setq v (med-node-key (cdr r) "#ITEMSIZE=")) (setq n (cons (cons "SIZE" v) n))))))
      (append (list (cons "ENT" e) (cons "PT" (cdr (assoc 10 ed))) (cons "CONN" (reverse conn))
                    (cons "FITTING" (med-node-fitting-of n)))
              n))))

;; fitting assignment string, nil = none (standard field bend)
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
      (med-node-write ne (list (cons "ID" (strcat "N" (cdr (assoc 5 (entget ne)))))
                               (cons "KIND" (med-node-kind (length ids) end)) (cons "SYS" (med-node-sys e))
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
