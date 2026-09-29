;;This is the right version
;; 2012 conduit 3D code, kept for comparison. M3D / MAKE3DCONDUIT now live in
;; MED3DPath.lsp (loaded by MEDCore); the old commands are M3DOLD / MAKE3DCONDUITOLD.
(vl-load-com)
(defun gplen (gpt1 gpt2 gpbul)
  (setq	gpang	(* 4 (atan gpbul))
	gpchord	(distance gpt1 gpt2)
	gpanga	(- (/ 3.141592654 2.00000000) (/ gpang 2.00000000))
	gprad	(/ (/ gpchord 2.00000000) (cos gpanga))
	gpdeg	(* gpang (/ 180.000000000 3.141592654))
	gprtlen	(* gpdeg gprad 0.017453293)
  )
  gprtlen
)

;; Straight conduit segment mkpt1 -> mkpt2 (WCS points, 2D or 3D), csize = RADIUS.
;; entmake the circle with its normal (210) along the segment, then EXTRUDE along
;; that direction. Works for sloped 3D segments too.
;; Old stream (command "extrude" c "" p1 p2 "") was written for AutoCAD <= 2006
;; (height as 2 points, then a taper-angle prompt eaten by the trailing "").
;; Since 2007 there is no taper prompt, so the extra "" re-issued EXTRUDE and
;; every later (command ...) was fed into the wrong prompt.
(defun mk3dcon (mkpt1 mkpt2 csize / mkn mklast)
  (setq mkpt1 (m3d-pt3 mkpt1)
        mkpt2 (m3d-pt3 mkpt2)
  )
  (if (and (numberp csize) (> csize 0.0) (setq mkn (m3d-unitvec mkpt1 mkpt2)))
    (progn
      (setq mklast (entlast))
      (entmake (list '(0 . "CIRCLE")
                     (cons 10 (trans mkpt1 0 mkn))
                     (cons 40 csize)
                     (cons 210 mkn)))
      (if (not (eq mklast (entlast)))
        (command "_.EXTRUDE" (entlast) ""
                 "_Direction" (trans mkpt1 0 1) (trans mkpt2 0 1))
      )
    )
  )
)

;; 3D point (adds Z 0.0 to 2D points)
(defun m3d-pt3 (p)
  (if (caddr p) p (list (car p) (cadr p) 0.0))
)

;; unit vector p1 -> p2, nil for zero length
(defun m3d-unitvec (p1 p2 / d)
  (setq d (distance p1 p2))
  (if (> d 1e-8)
    (mapcar '(lambda (a b) (/ (- b a) d)) p1 p2)
  )
)

;; Solids for a heavy POLYLINE (2D or 3D) with MED_CONDUIT xdata.
;; 2D: straights + bulge arcs (arcs assume OCS = WCS, same as the LWPOLYLINE branch).
;; 3D: straights, plus a sphere at each interior vertex so sharp corners have no gap
;;     (real bends for 3D paths are the CABTest-based rewrite, not this patch).
(defun m3d-heavy-pline (hpent hpdata hprad / hflg his3d helev hv hvd hpts hbuls
                                              hi hp1 hp2 hbul har hcpt hlast hms)
  (setq hflg (dxf 70 hpdata))
  (if (= 0 (logand hflg 80)) ; skip polygon meshes (16) and polyface meshes (64)
    (progn
      (setq his3d (= 8 (logand hflg 8))
            helev (caddr (dxf 10 hpdata))
            hv    (entnext hpent)
      )
      (if (not helev) (setq helev 0.0))
      (while (and hv (/= (dxf 0 (setq hvd (entget hv))) "SEQEND"))
        (if (= 0 (logand (dxf 70 hvd) 16)) ; skip spline frame control points
          (setq hpts  (cons (dxf 10 hvd) hpts)
                hbuls (cons (if (dxf 42 hvd) (dxf 42 hvd) 0.0) hbuls)
          )
        )
        (setq hv (entnext hv))
      )
      (setq hpts  (reverse hpts)
            hbuls (reverse hbuls)
      )
      (if (and hpts (= 1 (logand hflg 1))) ; closed
        (setq hpts (append hpts (list (car hpts))))
      )
      ;; 3D polyline vertices are WCS; 2D vertices are OCS at the polyline elevation
      (setq hpts (mapcar '(lambda (p)
                            (if his3d
                              (m3d-pt3 p)
                              (trans (list (car p) (cadr p) helev) hpent 0)))
                         hpts))
      (setq hi 0)
      (while (< (1+ hi) (length hpts))
        (setq hp1   (nth hi hpts)
              hp2   (nth (1+ hi) hpts)
              hbul  (nth hi hbuls)
              hlast (entlast)
        )
        (if (> (distance hp1 hp2) 1e-8)
          (if (and (not his3d) hbul (/= hbul 0.0))
            (progn
              (setq har  (getangleradius hp1 hp2 hbul)
                    hcpt (polar hp1 (+ (angle hp1 hp2) (nth 2 har)) (nth 1 har))
                    hcpt (list (car hcpt) (cadr hcpt) (caddr hp1))
              )
              (mk3dconbend hp1 hp2 hcpt hprad (nth 3 har))
            )
            (progn
              (mk3dcon hp1 hp2 hprad)
              (if (and his3d (> hi 0))
                (progn
                  (if (not (eq hlast (entlast)))
                    (MEDStamp3DFromBom (entlast) hpent "CONDUIT" nil)
                  )
                  (setq hlast (entlast)
                        hms   (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
                  (vl-catch-all-apply 'vla-AddSphere (list hms (vlax-3d-point hp1) hprad))
                )
              )
            )
          )
        )
        (if (not (eq hlast (entlast)))
          (MEDStamp3DFromBom (entlast) hpent "CONDUIT" nil)
        )
        (setq hi (1+ hi))
      )
    )
    (princ "\nM3D: polygon/polyface mesh skipped.")
  )
)

;; OSMODE / CMDECHO off for the whole run, restored on exit or error.
(defun m3d-begin ()
  (setq m3dOldOsmode  (getvar "OSMODE")
        m3dOldCmdecho (getvar "CMDECHO")
        m3dOldError   *error*)
  (defun *error* (msg)
    (m3d-end)
    (if (and msg (/= msg "") (not (wcmatch (strcase msg t) "*break*,*cancel*,*exit*")))
      (princ (strcat "\nMake3DConduit: " msg))
    )
    (princ)
  )
  (setvar "OSMODE" 0)
  (setvar "CMDECHO" 0)
)
(defun m3d-end ()
  (if m3dOldOsmode  (setvar "OSMODE" m3dOldOsmode))
  (if m3dOldCmdecho (setvar "CMDECHO" m3dOldCmdecho))
  (setq *error* m3dOldError
        m3dOldOsmode nil
        m3dOldCmdecho nil
        m3dOldError nil)
)

(defun VerticalConduitDriver ()
  (setq verticalconduitss (ssget "X" '((0 . "INSERT") (-3 ("MED_CONDUIT")("VERT_DATA")))))
  (princ "\nGot the Selection Set")
  (if verticalconduitss
     (progn
       (setq sslen (sslength verticalconduitss)
	     cnt 0
       )
       (princ "\nEntering the While loop")
       (while (< cnt sslen)
	 (setq conent (ssname verticalconduitss cnt)
	       conentdata (entget conent)
	       conrot (dxf 50 conentdata)
	       condata (xdataget conent _CONDUIT)
	       consize (nth 2 condata)
	       ;; OD for the solid diameter (bend radius stays based on nominal consize)
	       conod   (med_conduit_od (nth 3 condata) consize)
	       condist (nth 4 condata)
	       vertdata(vtrayxdataget conent)
	       bend1m  (nth 1 vertdata)
	       bden2m  (nth 2 vertdata)
	       condir  (nth 3 vertdata)
	       bend2dir(nth 4 vertdata)
	 )
	 (princ "\nGot entity Data")
	 (if (= bend1m 0.0)
	   (progn
	     (setq conpt1 (dxf 10 conentdata))
	   )
	   (progn
	      (setq benrad (* bend1m consize))
	      (setq conpt1 (dxf 10 conentdata)
		    conpt1 (list (car conpt1) (cadr conpt1) (+ (caddr conpt1) (* benrad condir)))
		    condist (- condist benrad)
		    benddir conrot
	      )
	      (princ "\nAbout to run the 3d process")
	      (if (= condir -1)
	        (progn
	          (mk3dvconbend conpt1 benddir (if conod conod consize) benrad nil)
	          (MEDStamp3DFromBom (entlast) conent "CONDUIT" nil)
	        )
	        (progn
	          (mk3dvconbend conpt1 benddir (if conod conod consize) benrad T)
	          (MEDStamp3DFromBom (entlast) conent "CONDUIT" nil)
	        )
	      )
	   )
	 )
	 (if (> bend2m 0.0)
	   (progn
		(princ "Handle second Bend Here")
	   )
	 )
	 (princ "\nAbout to run 3d conduit segment")
        (setq mk3dcondist (* condist condir))
        (mk3dconvertical conpt1 mk3dcondist (if conod conod consize))
	 ;; MEDProperties CONDUIT on vertical segment solid
	 (MEDStamp3DFromBom (entlast) conent "CONDUIT" nil)
	 (setq cnt (1+ cnt))
	)
       
    )
   )
 
)


(defun mk3dconvertical (mkvpt1 mkvdist mkvcsize)
  (cirmake mkvpt1 (* mkvcsize 0.5))
  (setq mycir (entlast)
	mycirdata (entget mycir)
  )
  (command "_.EXTRUDE" mycir "" mkvdist)
 )

  
(defun mk3dvconbend(mkcbpt1 mkcbdir csize mkcbrad ConTopFlag) ;; Set to True if drawing from Top of Conduit
  (cirmake mkcbpt1 (* csize 0.5))
  
  (setq mycir (entlast)
	mycirdata (entget mycir)
  )
  (setq mkcbcpt (polar mkcbpt1 mkcbdir mkcbrad))
  (if ConTopFlag
    	(setq mkcbcpt2 (polar mkcbcpt (+ mkcbdir (* PI 0.5 )) -1.0))
    	(setq mkcbcpt2 (polar mkcbcpt (+ mkcbdir (* PI 0.5)) 1.0))
    
  )
  (command "revolve" mycir "" mkcbcpt mkcbcpt2 (angtos (* PI 0.5) 0 8))
)




(defun mk3dconbend(mkcbpt1 mkcbpt2 mkcbcpt csize mkcbiang)
  (setq	actgenang (angle mkcbpt1 mkcbpt2))
  
  (cirmake mkcbpt1 csize)
  
  (setq mycir (entlast)
	mycirdata (entget mycir)
	3dold (assoc 210 mycirdata)
	3dnew (cons 210 (list 0.0 -1.0 -1.8369e-016))
 	mycirdata (subst 3dnew 3dold mycirdata)
	mycirdata (entmod mycirdata)
	)
  
  (setq	mycirpt (assoc 10 mycirdata)
	frompoint (trans (append (list (cadr mycirpt) (caddr mycirpt))   (list (cadddr mycirpt))) mycir 0)
	movetopoint (dxf 10 (entget mycir))
  )
  (command "move" mycir "" frompoint movetopoint)
  
  (command "rotate" mycir "" movetopoint mkcbcpt)
  (setq mkcbzpoint (caddr mkcbcpt))
  (setq cmkcbpt1 (list (car mkcbcpt) (cadr mkcbcpt) (+ mkcbzpoint 1.0)))
  (setq bendang (angle mkcbpt1 mkcbcpt))
  (if (< mkcbiang 0)
    (command "revolve" mycir "" cmkcbpt1  mkcbcpt (angtos (abs mkcbiang) 0 8))
    (command "revolve" mycir "" mkcbcpt  cmkcbpt1 (angtos (abs mkcbiang) 0 8))
  )
 
  
)





(defun cirmake ( centerpoint radius ) ;zflag / );plin vtxt sqend)
  (setq ckent '((0 . "CIRCLE") (100 . "AcDbEntity") (67 . 0)))
  (setq ckent (append ckent (list (cons 100 "AcDbCircle") (cons 67 0))))
  (setq ckent (append ckent (list (cons 10 centerpoint))))
  (setq ckent (append ckent (list (cons 40 radius))))
  
  (if _ZFLAG 
    (setq twoten (cons 210 (list 0.0 -1.0 0.0))
          plin (append plin (list twoten))
          _ZFLAG nil
    )
  )
  (entmake ckent)
)   


;;
;((-1 . <Entity name: 7ef9b450>) (0 . "CIRCLE") (330 . <Entity 
;name: 7ef7bcf8>) (5 . "132") (100 . "AcDbEntity") (67 . 0) (410 . "Model") (8 . 
;"0") (100 . "AcDbCircle") (10 17.0084 -10.1694 0.0) (40 . 1.36514) (210 0.0 -1.0 2.22045e-016))


(defun ThreeDeeConduitDriver (plent)
  (setq	plen	 0
	pentdata (entget plent)
  )
  (setq curcondata (xdataget plent _CONDUIT)
	consize    (nth 2 curcondata)
	;; OD by conduit type (ITEMCODE) + trade size from MEDConduitOD;
	;; falls back to getsize steel-pipe OD when no table/row.
	actualsize (med_conduit_od (nth 3 curcondata) consize)
  )
  
  (if (= (dxf 0 pentdata) "POLYLINE")
    (progn
      (setq mode  (entget (entnext plent))
	    mode1 (entget (entnext (dxf -1 mode)))
      )
      (while (/= (dxf 0 mode1) "SEQEND")
	(setq spt (dxf 10 mode)
	      ept (dxf 10 mode1)
	)
	(if (/= (dxf 42 mode) 0.0)
	  (setq plen (+ plen (gplen spt ept (dxf 42 mode))))
	  (setq plen (+ plen (distance spt ept)))
	)
	(setq mode  mode1
	      mode1 (entget (entnext (dxf -1 mode)))
	)
      )
      ;; 2D heavy and 3D POLYLINE were only measured, never drawn (since 2012).
      (if (numberp actualsize)
        (m3d-heavy-pline plent pentdata (* actualsize 0.5))
        (princ "\nM3D: no OD for this conduit type/size, skipped.")
      )
    )
    (progn
      (if (and (= (dxf 0 pentdata) "LWPOLYLINE") (numberp actualsize))
	(progn

	  (setq	mklwptbulist
		 (bld_lw_ptlist plent)
		mkcnt 0
		mklwptlist
		 (nth 0 mklwptbulist)
		mklwbulist
		 (nth 1 mklwptbulist)
		mklwzpoint (dxf 38 pentdata)
	  )

	  (foreach ptitm mklwptlist

	    (if	(> mkcnt 0)
	      (progn

		(setq ept (cdr ptitm))
		(if (/= (cdr (nth (- mkcnt 1) mklwbulist)) 0.0)
		  (progn
		    (setq angleandradiuslist (getangleradius spt ept (cdr (nth (- mkcnt 1) mklwbulist))))
		    (princ (cdr (nth (- mkcnt 1) mklwbulist)))
		    (setq anga (nth 2 angleandradiuslist))
  		    (setq rad (nth 1 angleandradiuslist))
		    (setq iang(nth 3 angleandradiuslist))
  		    (setq chordang (angle spt ept))
  	            (setq angtocenter (+ chordang anga))
		    (setq cpt (polar spt angtocenter rad))
		    (setq spt (append spt (list mklwzpoint)))
		    (setq ept (append ept (list mklwzpoint)))
		    (setq cpt (append cpt (list mklwzpoint)))
			  
		    (mk3dconbend spt ept cpt (* actualsize 0.5) iang)
		    ;; MEDProperties CONDUIT on each segment solid
		    (MEDStamp3DFromBom (entlast) plent "CONDUIT" nil)
		  )
		  (progn
		    (setq spt (append spt (list mklwzpoint)))
		    (setq ept (append ept (list mklwzpoint)))
		    (mk3dcon spt ept (* actualsize 0.5))
		    (MEDStamp3DFromBom (entlast) plent "CONDUIT" nil)
		  )
		)
	      )
	    )

	    (setq mkcnt	(1+ mkcnt)
		  spt	(cdr ptitm)
	    )
	  )				;foreach

	)				;progn
      )					;if
    )					;progn
  )					;if
  plen
)
(defun getangleradius (gpt1 gpt2 gpbul)
  (setq	gpang	(* 4 (atan gpbul))
	gpchord	(distance gpt1 gpt2)
	gpanga	(- (/ 3.141592654 2.00000000) (/ gpang 2.00000000))
	gprad	(/ (/ gpchord 2.00000000) (cos gpanga))
	gpdeg	(* gpang (/ 180.000000000 3.141592654))
	gprtlen	(* gpdeg gprad 0.017453293)
	chordang (angle gpt1 gpt2)
  )
  (list gpdeg gprad gpanga gpang gprtlen gpchord)
)

(defun c:mytest()
  (setq pent (car (entsel "\nSelect Pline Arc")))
  (setq ptlist (bld_lw_ptlist pent))
  (setq pt1 (cdr (nth 0 (nth 0 ptlist))))
  (setq pt2 (cdr (nth 1 (nth 0 ptlist))))
  (setq bul1 (cdr (nth 0 (nth 1 ptlist))))
  (setq mydata (getangleradius pt1 pt2 bul1))
  (setq anga (nth 2 mydata))
  (setq rad (nth 1 mydata))
  (setq chordang (angle pt1 pt2))
  (if (< bul1 0)
    (setq angtocenter (+ chordang anga))
    (setq angtocenter (+ chordang anga))
  )
  
  (cirmake (polar pt1 angtocenter rad) 0.5)
)

(defun c:M3DOLD( / ent)
  (setq _MEDCONDUITOD_CACHE nil)
  (if (and (setq ent (car (entsel "\nSelect MED conduit polyline: ")))
           (xdataget ent _CONDUIT))
    (progn
      (m3d-begin)
      (ThreeDeeConduitDriver ent)
      (m3d-end)
    )
    (princ "\nNot a MED conduit.")
  )
  (princ)
)

(defun c:Make3DConduitOld()
  (setq _MEDCONDUITOD_CACHE nil) ; re-read MEDConduitOD each run
  (m3d-begin)
  (smlayer _MED3DCONDUIT)
  (command "vpoint" "1,1,1")
  (initget "3DS Dwg Layer")
  (setq outputformat (getkword "\n Output to 3DS Layer <Dwg>: "))
  (if (not outputformat)
    (setq outputformat "Dwg")
  )
  (setq 3doutconduit (ssget "x" (list (list -3 (list "MED_CONDUIT")))))
  (if 3doutconduit
    (progn
      (setq conduitoutnum (sslength 3doutconduit)
	    conduitoutcnt 0
      )
      (while (< conduitoutcnt conduitoutnum)
	(setq conduitent (ssname 3doutconduit conduitoutcnt))
	(threedeeconduitdriver conduitent)
	(setq conduitoutcnt (1+ conduitoutcnt))
      )
    )
  )
  ;; TODO(MEDProperties): enable conduit-fitting walk below when MAKE3DCONDUIT
  ;; exports MED_FITTING solids; m3dconduitfit already stamps FITTING via MEDStamp3DFromBom.
  ;(setq 3doutconduit (ssget "x" (list (list -3 (list "MED_FITTING")))))
  ;(if 3doutconduit
  ;  (progn
  ;    (setq conduitoutnum (sslength 3doutconduit)
;	    conduitoutcnt 0
 ;     )
  ;    (while (< conduitoutcnt conduitoutnum)
;	(setq conduitent (ssname 3doutconduit conduitoutcnt)
;	      conduitentdata (xdataget conduitent _FITTING)
;	)
;	(if (> (nth 5 conduitentdata) 0.00)
;	  (m3dconduitfit conduitent conduitentdata)
;	)
 ;       (setq conduitoutcnt (1+ conduitoutcnt))
  ;    )
  ;  )
 ; )
  (cond
    ((= outputformat "3DS")
      (Prompt "\nMake3dconduit will export to 3ds file:")
      (if (not c:3dsout)
	(arxload "render")
      )
      (setq 3dsoutfname (getfiled "Select file name for 3Dconduit output" (substr (getvar "dwgname") 1 (- (strlen (getvar "dwgname")) 4)) "3ds" 1))
      (c:3dsout (ssget "X" (list (cons 0 "3dsolid") (cons 8 (nth 0 _MED3Dconduit)))) 0 0 30 0.1 3dsoutfname)
      (command "erase" (ssget "X" (list (cons 0 "3dsolid") (cons 8 (nth 0 _MED3Dconduit)))) "")
      (command "plan" "")
    )
    ((= outputformat "Dwg")
      (setq 3dsoutfname (getfiled "Select file name for 3Dconduit output" (substr (getvar "dwgname") 1 (- (strlen (getvar "dwgname")) 4)) "dwg" 1))
      (if (findfile 3dsoutfname)
	(command "wblock" 3dsoutfname "y" "")
	(command "wblock" 3dsoutfname "")
      )
      (command (list 0.0 0.0 0.0) (ssget "X" (list (cons 0 "3dsolid") (cons 8 (nth 0 _MED3Dconduit)))) "")
      (command "plan" "")
    )
    ((= outputformat "Layer")
      ;(command "-layer" "off" "*" "" "On" (nth 0 _MED3Dconduit) "")
      (prompt "\nUse the PLAN command to return to plan view:")
    )
  )
  (m3d-end)
  (princ)
)


(defun m3dconduitfit (conduitfitent conduitfitdata)
  (setq fitptbllist (bld_lw_ptlist conduitfitent)
	fitptlist   (nth 0 fitptbllist)
	fitbllist   (nth 1 fitptbllist)
	fitwidth    (nth 2 conduitfitdata)
	fitdpth     (nth 5 conduitfitdata)
	fitalt      (nth 4 conduitfitdata)
	m3delev     (getvar "ELEVATION")
	conduitfitentdata (entget conduitfitent)
  )
  (setvar "ELEVATION" (dxf 38 conduitfitentdata))
  
  (cond
    ((= (length fitptlist) 4)
       (make_elbow fitptbllist fitwidth)
       (command "extrude" (entlast) "" (* _PLOTSCALE fitdpth) "")
    )
    ((= (length fitptlist) 7)
       (make_tee fitptbllist fitwidth)
       (command "extrude" (entlast) "" (* _PLOTSCALE fitdpth) "")
    )
    ((= (length fitptlist) 10)
       (make_cross fitptbllist fitwidth)
       (command "extrude" (entlast) "" (* _PLOTSCALE fitdpth) "")
    )
    ((and (= (length fitptlist) 2)
	  (= 18.0 (distance (cdr (nth 0 fitptlist)) (cdr (nth 1 fitptlist)))))
       (make_re fitptbllist fitwidth fitalt)
       (command "extrude" (entlast) "" (* _PLOTSCALE fitdpth) "")
    )
    ;((= (nth 3 conduitfitdata) 341)
    ;   (make_relr fitptbllist fitwidth fitalt)
    ;   (command "extrude" (entlast) "" fitdpth "")
    ;)
    ((vconduitxdataget conduitfitent)
     (m3dvconduitfit conduitfitent)
    )
    (T nil)
    
  )
  ;; MEDProperties: conduit fittings use FITTING ObjectType (Length empty)
  (if (entlast)
    (MEDStamp3DFromBom (entlast) conduitfitent "FITTING" nil)
  )
  (setvar "ELEVATION" m3delev)
  
)
(defun c:esolid()
  (command "erase" (SSGET "X" '((0 . "3DSOLID"))) "")
)
  

		  
  
	
(princ "Version 1.02")

;; Loaded after MED3DPath.lsp (e.g. APPLOAD)? This file defines only M3DOLD /
;; MAKE3DCONDUITOLD, but make sure M3D / MAKE3DCONDUIT stay MED3DPath's.
(if med3d-claim-commands (med3d-claim-commands T))
(princ)
