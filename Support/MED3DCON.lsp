;;This is the right version
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

(defun mk3dcon(mkpt1 mkpt2 csize)
  (setq	actgenang (angle mkpt1 mkpt2))
  (cirmake mkpt1 csize)
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
  (command "rotate" mycir "" movetopoint (angtos (+ actgenang  (* PI 0.5)) 0 8))
	   
  (command "extrude" mycir "" mkpt1 mkpt2 "" )
 
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
	        (mk3dvconbend conpt1 benddir consize benrad nil)
	        (mk3dvconbend conpt1 benddir consize benrad T)
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
        (mk3dconvertical conpt1 mk3dcondist consize)
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
  (command "extrude" mycir "" mkvdist "" )
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
	actualsize (nth 1 (getsize nil (rtos consize 4)))
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
    )
    (progn
      (if (= (dxf 0 pentdata) "LWPOLYLINE")
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
		  )
		  (progn
		    (setq spt (append spt (list mklwzpoint)))
		    (setq ept (append ept (list mklwzpoint)))
		    (mk3dcon spt ept (* actualsize 0.5))
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

(defun c:m3d()
  (setq ent (car (entsel)))
  (ThreeDeeConduitDriver ent)
)

(defun c:make3dConduit()
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
  (setvar "ELEVATION" m3delev)
  
)
(defun c:esolid()
  (command "erase" (SSGET "X" '((0 . "3DSOLID"))) "")
)
  

		  
  
	
(princ "Version 1.02")