(princ "\rLoading MEDFunctions...")
(defun getColorNumber (gcn-color)
   (if (/= (type gcn-color) 'INT)
      (progn
         (cond
            ((= (strcase gcn-color) "RED")
             (setq gcn-color 1)
            )
            ((= (strcase gcn-color) "YELLOW")
             (setq gcn-color 2)
            )
            ((= (strcase gcn-color) "GREEN")
             (setq gcn-color 3)
            )
            ((= (strcase gcn-color) "CYAN")
             (setq gcn-color 4)
            )
            ((= (strcase gcn-color) "BLUE")
             (setq gcn-color 5)
            )
            ((= (strcase gcn-color) "MAGENTA")
             (setq gcn-color 6)
            )
            ((= (strcase gcn-color) "WHITE")
             (setq gcn-color 7)
            )
            (T (setq gcn-color (read gcn-color)))
         )
      )
   )
   gcn-color
)

;Need to add ability to use metric line file vs empirical Add this to the spec somewhere.
(defun verifyLinetypeLoaded (vltl-ltype)
   (if (not (tblsearch "LTYPE" vltl-ltype nil))
      (progn
         (command "linetype" "load" vltl-ltype "acad.lin" "" nil)
         (if (not (tblsearch "LTYPE" vltl-ltype nil))
            (progn
               (setq vltl-ltype "Continuous")
               (prompt
                  (strcat
                     "\n****["
                     vltl-ltype
                     "] Linetype was not found. Using Continous as a substitute."
                  )
               )
            )
         )
      )
   )
   vltl-ltype
)


(defun SetLayerLineweight(Layername lineweighttouse)
	(setq AcadMainObj   (vlax-get-acad-object)
         AcadActiveDoc (vla-get-ActiveDocument AcadMainObj)
         ActiveLayers  (vla-get-layers AcadActiveDoc)
         LayerToUpdate (vl-catch-all-apply 'vla-item (list ActiveLayers layername))
         valid-lwght-list (list -3 -2 -1 0 5 9 13 15 18 20 25 30 35 40 50 53 60 70 80 90 100 106 120 140 158 200 211)
         	                 ;-3 defualt , -2 byblock, -1 bylayer
   )
   (if (= (vl-catch-all-error-p LayerToUpdate) nil)
   	   (if (member lineweighttouse  valid-lwght-list)
   	   		(vla-put-lineweight LayerToUpdate lineweighttouse)
   	   		(princ (strcat "\n Lineweight Specified is not a valid lineweight for Layer " layername))
   	   )
   	   (princ (strcat "\nFailed to Set Lineweight for Layer " layername)) 
   )
)

(defun medMakeLayer (ml-layinfo)
   (setq ml-name     (car ml-layinfo)
         ml-color    (cadr ml-layinfo)
         ml-ltype    (caddr ml-layinfo) ;need to add code to verify the linetype is loaded
         ml-lwght    (cadddr ml-layinfo)
   )
   (if (or (not ml-lwght) (and (= (type ml-lwght) 'STR) (= (strcase ml-lwght) "DEFAULT")) )
   	   (setq ml-lwght -3)
   	   (progn
   	   	   (if (= (type ml-lwght) 'STR)
   	   	   	   (setq ml-lwght (atof ml-lwght)
   	   	   	   	     ml-lwght (fix (* ml-lwght 100))
   	   	   	   )
   	   	   	   (setq ml-lwght (fix (* ml-lwght 100))
   	   	   	   )
   	   	   )
   	   )
   )
   (setq ml-newlayer (list (cons 0 "LAYER")
                           (cons 100 "AcDbSymbolTableRecord")
                           (cons 100 "AcDbLayerTableRecord")
                           (cons 2 ml-name)
                           (cons 6 (verifyLinetypeLoaded ml-ltype))
                           (cons 62 (getColorNumber ml-color))
                           (cons 70 0)
                           (cons 290 1)
                           ;(cons 370 ml-lwght) ;;Apparently you can't set hte lwght here
                     )
   )
   (setq ml-newlayerdata (entmake ml-newlayer))
   (setLayerLineWeight ml-name ml-lwght)
   
)

(defun medsmlayer (layinfo / name color ltype regen)
   (setq name  (car layinfo)
         color (cadr layinfo)
         ltype (caddr layinfo)
         lwght (cadddr layinfo)
   )
   (if (not (tblsearch "layer" name))
      (MEDMakeLayer layinfo)
      (progn
      	  (if color
      	  	  (MEDVerifyLayerColor name color)
      	  )
      	  (if ltype
      	  	  (MEDVerifyLayerLinetype name ltype)
      	  )
      )
   )
   (setvar "CLAYER" name) 
)

(defun MEDGetLayerColor(LayerName)
	   (setq AcadMainObj   (vlax-get-acad-object)
			 AcadActiveDoc (vla-get-ActiveDocument AcadMainObj)
			 MVLC-ActiveLayers  (vla-get-layers AcadActiveDoc)
			 MVLC-VerifyLayerObj (vla-Item MVLC-ActiveLayers layername)
			 MVLC-VerifyLayerColor (vla-get-color MVLC-VerifyLayerObj) 
   )
   (setq LayerColor (getColorNumber MVLC-VerifyLayerColor))
)
	

(defun MEDverifyLayerColor (layername layercolor)
   (setq AcadMainObj   (vlax-get-acad-object)
         AcadActiveDoc (vla-get-ActiveDocument AcadMainObj)
         MVLC-ActiveLayers  (vla-get-layers AcadActiveDoc)
         MVLC-VerifyLayerObj (vla-Item MVLC-ActiveLayers layername)
         MVLC-VerifyLayerColor (vla-get-color MVLC-VerifyLayerObj) 
   )
   (setq LayerColor (getColorNumber LayerColor))
   (if (/= MVLC-VerifyLayerColor LayerColor)
   	   (vla-put-color MVLC-VerifyLayerObj layercolor)
   )
)
(defun MEDverifyLayerLinetype (layername linetypename)
   (setq AcadMainObj   (vlax-get-acad-object)
         AcadActiveDoc (vla-get-ActiveDocument AcadMainObj)
         ActiveLayers  (vla-get-layers AcadActiveDoc)
         VerifyLayerObj (vla-Item ActiveLayers layername)
         VerifyLayerLtype (vla-get-linetype VerifyLayerObj) 
   )
   (if (/= VerifyLayerLtype linetypename)
   	   (progn
   	   	   (verifyLinetypeLoaded linetypename)
   	   	   (vla-put-linetype VerifyLayerObj linetypename)
   	   )
   )
)

(defun smlayer ( layinfo )
	(medsmlayer layinfo)
)

(defun dxf(code elist)
    (cdr (assoc code elist))
)



(defun clookup (lookcode size apptype)
  (cond
     ((= apptype _CONDUIT)
        (setq rstr (strcat (rtos size 4 2) " ")
              aplk "CONDUIT"
        )

     )
     ((= apptype _CABLE)
        (setq aplk "CABLE")
        (if size
           (setq rstr (strcat (itoa (fix size)) " "))
           (setq rstr "1 ")
        )
     )
     ((= apptype _EQUIP)
        (setq rstr ""
              aplk "EQUIP"
        )
     )
     ((= apptype _TRAY)
        (setq rstr (strcat (rtos size 5 4) "\" ")
              aplk "TRAY"
        )
     )
     ((= apptype _FITTING)
        (setq aplk "FITTING"
        )
        (if (or _ZERO (= size 0.0))
          (setq rstr "")
          (setq rstr (strcat (rtos size 4 2) " "))
        )
     )
  )
  (if (= lookcode 0)
    (setq rval "MED BOM void Entity")
    (setq rval (med_getdesc aplk lookcode))
  )

  (setq rstr (strcat rstr rval))
  
  rstr
)

(defun med_tan (mt_ang)
	(setq mt_returnvalue (/ (sin mt_ang) (cos mt_ang)))
)

(defun polylen (plineent)
	(setq pl-object (vlax-ename->vla-object plineent))
	(if (and pl-object (vlax-property-available-p pl-object 'length))
		(setq pl-returnlength (vla-get-length pl-object))
		(setq pl-returnlength 0.0)
	)
)

(defun MEDSettings (CommandName)
	(setq CurrLinetype (getvar "CELTYPE")
		  CurrLayer    (getvar "CLAYER")
	)
	(setvar "CELTYPE" "ByLayer")
	(cond 
		((= CommandName "C:TRAY")
			(smlayer _MEDCENLAY)
		)
	)
)
(defun MEDGetCurrentUCS()
	(trans (list 0.0 0.0 1.0) 1 0)
)
(defun MEDGetCurrentOCS()
	(setq ucsxdirA (getvar "UCSXDIR")
		  ucsydirB (getvar "UCSYDIR")
		  OCSAx        (car ucsxdirA)
		  OCSAy        (cadr ucsxdirA)
		  OCSAz        (caddr ucsxdirA)
		  OCSBx        (car ucsydirB)
		  OCSBy        (cadr ucsydirB)
		  OCSBz        (caddr ucsydirB)
		  OCSXValue (- (* OCSAy OCSBz) (* OCSAz OCSBy))
		  OCSYValue (- (* OCSAz OCSBx) (* OCSAx OCSBz))
		  OCSZValue (- (* OCSAx OCSBy) (* OCSAy OCSBx))
	)
	(list OCSXValue OCSYValue OCSZValue)
)
(defun MEDTransPointListToUCS (mtpltw-Pointlist mtpltw-ElevationData mtpltw-UCSData)
;	(if (not (= mtpltw-ElevationData (caddr (nth 0 mtpltw-PointList))))
;		(setq UseZCoordinate mtpltw-ElevationData
;			  WCSComparePoint (list (car (nth 0 mtpltw-pointlist)) (cadr (nth 0 mtpltw-pointlist)) UseZCoordinate)
;		)
;		(setq UseZCoordinate nil
;			  WCSComparePoint (nth 0 mtpltw-pointlist)
;		)
;	)
	(setq WCSComparePoint (nth 0 mtpltw-pointlist))
	(setq ReturnPtList (list))
	(if (not (equal WCSComparePoint (trans WCSComparePoint 1 mtpltw-UCSData)))
		(progn
			(foreach pt mtpltw-PointList
				(if UseZCoordinate
					(setq pt (list (car pt) (cadr pt) UseZCoordinate))
				)
				(setq ActualWCSPoint (trans pt 1 mtpltw-UCSData)
					  ReturnPtList (append ReturnPtList (list ActualWCSPoint))
				)
			)
			(setq ActualElevationToUse (caddr (nth 0 ReturnPtList))
				  ReturnPtList (list ReturnPtList ActualElevationToUse)
			)
		)
		(setq ReturnPtList (list mtpltw-PointList mtpltw-ElevationData))
	)
	ReturnPtList
)
	

(defun MEDPlineMake (PointList CloseFlag PlineElevation OCSData)
  (setq plin '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (67 . 0)))
  (if CR_LAYER
   (progn
     (setq plin (append plin (list (cons 8 CR_LAYER)))
     )
   )
  )
  (setq plin (append plin (list (cons 100 "AcDbPolyline") (cons 67 0))))
  (setq ptlistlen (length PointList)
        plin (append plin (list (cons 90 ptlistlen)))
  )
  (if CloseFlag
     (setq plin  (append plin (list (cons 70 1))))
  )
  (if _USEELEV
     (setq elev _USEELEV
           _USEELEV nil
     )
     (if PlineElevation
     	 (setq elev PlineElevation)
     	 (setq elev (getvar "ELEVATION"))
     )
  )
  (if OCSData
  	  (setq UseThisOCSData OCSData)
  	  (setq UseThisOCSDAta (MedGetCurrentOCS))
  )
  (setq WCSPointList (MEDTransPointListToUCS PointList elev UseThisOCSData)
  	    elev (nth 1 WCSPointlist)
  	    PointList (nth 0 WCSPointList)
  )

  (setq plin (append plin (list (cons 43 0.0) (cons 38 elev) (cons 39 0.0))))

  (foreach pt PointList
     (setq vert (cons 10 pt)
           ver1 (cons 40 0.0)
           ver2 (cons 41 0.0)
           ver3 (cons 42 0.0)
           plin (append plin (list vert ver1 ver2 ver3))
     )
  )
  (if _ZFLAG
    (setq twoten (cons 210 (list 0.0 -1.0 0.0))
          plin (append plin (list twoten))
          _ZFLAG nil
    )
    (if OCSData
    	(setq OCSTrue (princ "\nOCSTrue")
    		  twoten (cons 210 OCSData)
    		  plin (append plin (list twoten))
    	)
    	(setq OCSFalse (princ "\nOCSFalse")
    		  twoten (cons 210 (MEDGetCurrentOCS))
    	      plin (append plin (list twoten))
    	)
    )
  )
  (entmake plin)
  (setq CR_LAYER nil)
)


(defun MEDSendEntityDataToBOM( medent )
  (setq applist (xd_apps medent)
  	    medentdata (entget medent)
  	    medentityhandle (dxf 5 medentdata)
  	    medentitytype (dxf 0 medentdata)
  	    meddwgname (getvar "dwgname")
  	    meddwgpath (getvar "dwgprefix")
  	    medusername (getvar "loginname")
  	    numapps (length applist)
  	    appcnt  0
 )
 (while (< appcnt numapps)
   (setq appnm (nth appcnt applist)
         appdata (cdr (xdataget medent appnm))
         datalen (length appdata)
         applen  (eval (read (strcat "len" (substr appnm 4))))
         numtags (/ datalen applen)
         tagcnt 0
   )
   (while (< tagcnt numtags)
     (cond
       ((= appnm _CABLE)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 medrtag(nth (+ 3 (* applen tagcnt)) appdata)
                 meddist(nth (+ 4 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 5 (* applen tagcnt)) appdata)
           )
           (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len meddist)
           )
           (MEDProcessSQLStatement (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'CABLE',"
           		                           "'" medtag "',"
           		                           "'" medrtag "',"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2) ","
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')"))
           		                           
           
       )
       ((= appnm _CONDUIT)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 meddist(nth (+ 3 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 4 (* applen tagcnt)) appdata)
           )
           (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len  meddist)
           )
           (MEDProcessSQLStatement (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'CONDUIT',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2)","
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')"))
       )
       ((= appnm _TRAY)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 meddist(nth (+ 3 (* applen tagcnt)) appdata)
                 meddpth(nth (+ 4 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 5 (* applen tagcnt)) appdata)
                 medflng(nth (+ 6 (* applen tagcnt)) appdata)
                 
           )
    	   (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len meddist)
           )
           (MEDProcessSQLStatement (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'TRAY',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2)","
           		                           "NULL,"
           		                           (rtos meddpth 2 2)","
           		                           (rtos medcode 2 0)","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')"))
       )
       ((= appnm _FITTING)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 medalt (nth (+ 3 (* applen tagcnt)) appdata)
                 meddpth(nth (+ 4 (* applen tagcnt)) appdata)
           )
           (MEDProcessSQLStatement (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'FITTING',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                            "1.0,"
           		                           (rtos medsize 2 2) ","
           		                           "NULL,"
           		                           (rtos meddpth 2 2)","
           		                           (rtos medcode 2 0)","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "NULL,"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')"))
           
       )
       ((= appnm _EQUIP)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medcode(nth (+ 1 (* applen tagcnt)) appdata)
           )
           (MEDProcessSQLStatement (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'EQUIP',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                            "1.0,"
           		                           "NULL,"
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "NULL,"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')"))
           
           
       )

     )
     (setq tagcnt (1+ tagcnt))
   )
   (setq appcnt (1+ appcnt))
 )
 (princ)
)
;;Updated lower override function to save statement to variable
(defun MEDSendEntityDataToBOM( medent )
  (setq applist (xd_apps medent)
  	    medentdata (entget medent)
  	    medentityhandle (dxf 5 medentdata)
  	    medentitytype (dxf 0 medentdata)
  	    meddwgname (getvar "dwgname")
  	    meddwgpath (getvar "dwgprefix")
  	    medusername (getvar "loginname")
  	    numapps (length applist)
  	    appcnt  0
 )
 (while (< appcnt numapps)
   (setq appnm (nth appcnt applist)
         appdata (cdr (xdataget medent appnm))
         datalen (length appdata)
         applen  (eval (read (strcat "len" (substr appnm 4))))
         numtags (/ datalen applen)
         tagcnt 0
   )
   (while (< tagcnt numtags)
     (cond
       ((= appnm _CABLE)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 medrtag(nth (+ 3 (* applen tagcnt)) appdata)
                 meddist(nth (+ 4 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 5 (* applen tagcnt)) appdata)
           )
           (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len meddist)
           )
           (setq MEDSQLStatementToProcess (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'CABLE',"
           		                           "'" medtag "',"
           		                           "'" medrtag "',"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2) ","
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')")
           	 ) 
           	   
           (MEDProcessSQLStatement MEDSQLStatementToProcess)
           		                           
           
       )
       ((= appnm _CONDUIT)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 meddist(nth (+ 3 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 4 (* applen tagcnt)) appdata)
           )
           (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len  meddist)
           )
           (setq MEDSQLStatementToProcess (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'CONDUIT',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2)","
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')")
           	   )
           
           (MEDProcessSQLStatement MEDSQLStatementToProcess)
       )
       ((= appnm _TRAY)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 meddist(nth (+ 3 (* applen tagcnt)) appdata)
                 meddpth(nth (+ 4 (* applen tagcnt)) appdata)
                 medmesr(nth (+ 5 (* applen tagcnt)) appdata)
                 medflng(nth (+ 6 (* applen tagcnt)) appdata)
                 
           )
    	   (if (= medmesr "T")
                (setq m_len (polylen medent))
                (setq m_len meddist)
           )
           (setq MEDSQLStatementToProcess (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'TRAY',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                           (rtos m_len 2 4) ","
           		                           (rtos medsize 2 2)","
           		                           "NULL,"
           		                           (rtos meddpth 2 2)","
           		                           (rtos medcode 2 0)","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "'" medmesr "',"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')")
           	   )
           (MEDProcessSQLStatement MEDSQLStatementToProcess)
       )
       ((= appnm _FITTING)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medsize(nth (+ 1 (* applen tagcnt)) appdata)
                 medcode(nth (+ 2 (* applen tagcnt)) appdata)
                 medalt (nth (+ 3 (* applen tagcnt)) appdata)
                 meddpth(nth (+ 4 (* applen tagcnt)) appdata)
           )
           (setq MEDSQLStatementToProcess (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'FITTING',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                            "1.0,"
           		                           (rtos medsize 2 2) ","
           		                           "NULL,"
           		                           (rtos meddpth 2 2)","
           		                           (rtos medcode 2 0)","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "NULL,"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')")
           	   )
           (MEDProcessSQLStatement MEDSQLStatementToProcess)
           
       )
       ((= appnm _EQUIP)
           (setq medtag (nth (+ 0 (* applen tagcnt)) appdata)
                 medcode(nth (+ 1 (* applen tagcnt)) appdata)
           )
           (setq MEDSQLStatementToProcess (strcat "INSERT INTO MEDProject VALUES ("
           		                           "'EQUIP',"
           		                           "'" medtag "',"
           		                           "NULL,"
           		                            "1.0,"
           		                           "NULL,"
           		                           "NULL,"
           		                           "NULL,"
           		                           (rtos medcode 2 0) ","
           		                           "'" medentityhandle "',"
           		                           "'" medentitytype "',"
           		                           "'" meddwgname "',"
           		                           "NULL,"
           		                           "'" _MEDPROJECT "',"
           		                           "'" meddwgpath "'," 
           		                           "'" medusername "')")
           	   )
           
           (MEDProcessSQLStatement MEDSQLStatementToProcess)
           
           
       )

     )
     (setq tagcnt (1+ tagcnt))
   )
   (setq appcnt (1+ appcnt))
 )
 (princ)
)

;; function returns an applications xdata from a provided
;; entity.

(defun xdataget (ent app_name / xdlist)
  (setq entdata (entget ent (list app_name)))
  (if (setq xdatalist (assoc -3 entdata))
    (progn
      (setq xdatalist (cdr xdatalist)
            xdatalist (cdr (car xdatalist))
            xdlen     (length xdatalist)
            xdcnt     1
            xdlist    (list app_name )
      )
      
      (while (< xdcnt xdlen)
          (setq xdval (cdr (nth xdcnt xdatalist)))
          (cond
              ((= (substr xdval 1 9) "ITEM_DESC")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "ITEM_TAG_")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "ITEM_RTAG")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "#ITEMSIZE")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMCODE")
                 (setq xdval (substr xdval 11)
                       xdval (atoi xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMDIST")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMDPTH")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEM_ALT")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "ITEM_MESR")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "#ITEMFLNG")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
          )
          (setq xdlist (cons xdval xdlist)
	              xdcnt (1+ xdcnt)
	        
	        )
      )
      (setq xdlist (cdr xdlist)
            xdlist (reverse xdlist)
      )
    )
  )
  xdlist
)

(defun FixDetailResultList (ResultList)
	(setq ReturnResultList (list))
	(if ResultList
		(foreach DetailRecord ResultList

			(setq UpdateRecord (list (fix (nth 0 DetailRecord))
					                   (chopspace (nth 1 DetailRecord))
					                   (chopspace (nth 2 DetailRecord))
					                   (if (nth 3 DetailRecord) (chopspace (nth 3 DetailRecord)) "")
					                   (chopspace (nth 4 DetailRecord))
					                   (if (nth 5 DetailRecord) (chopspace (nth 5 DetailRecord)) "")
					                   (chopspace (nth 6 DetailRecord))
					            )
				ReturnResultList (append ReturnResultList (list UpdateRecord))
			)
			
		)
		(setq REturnResultList nil)
	)
	ReturnResultList
)

(defun FixMEDDetailResultList (ResultList)
	(setq ReturnResultList (list))
	(if ResultList
		(foreach DetailRecord ResultList
			(setq UpdateRecord (list (fix (nth 0 DetailRecord))
					                   (chopspace (nth 1 DetailRecord))
					                   (chopspace (nth 2 DetailRecord))
					            )
				ReturnResultList (append ReturnResultList (list UpdateRecord))
			)
		)
		(setq REturnResultList nil)
	)
	ReturnResultList
)

(defun bld_dtl_list (DetailGroup)
	(setq MEDSQLStatement (strcat "Select ITEMCODE, ITEMDESC, ITEMKEY1, ItemKey3, ItemKey4, User1, User2 from MEDTYPE where ITEM_GRP='" DetailGroup "'")
		  MEDReturnData (MEDProcessSQLStatement MEDSQLStatement)
	)
	(if (> (length MEDReturnData) 1)
		(setq MEDReturnData (cdr MEDReturnData))
		(setq MEDReturnData nil)
	)
	MEDReturnData
)
(defun med_detail (DetailMaterialCodeOrnum)
	(princ "Start")
	(if (= (type DetailMaterialCodeOrnum) 'INT)
		(setq AddWhereCond (strcat " WHERE ITEMTYPE='EQUIP' AND ITEMCODE=" (itoa DetailMaterialCodeOrnum)))
		(setq AddWhereCond (strcat " WHERE ITEMTYPE='EQUIP' AND ITEMKEY1='" DetailMaterialCodeOrnum "'"))
	)
	(princ "Here")
	(setq MEDSQLStatement (strcat "Select ITEMCODE, ITEMKEY1, ITEMKEY2 from MEDTYPE" AddWhereCond)
		  MEDReturnData (MEDProcessSQLStatement MEDSQLStatement)
	)
	(if (> (length MEDReturnData) 1)
		(setq MEDReturnData (car (FixMEDDetailResultList (cdr MEDReturnData))))
		(setq MEDReturnData nil)
	)
	MEDReturnData
)

;Moved Text Functions to MEDTextStyles.lsp

(defun getblockentityhandle (blockname)
	(setq gbeh-tableentity (tblobjname "BLOCK" blockname))
	(if gbeh-tableentity
		(setq returnvalue (dxf 5 (entget (dxf 330 (entget gbeh-tableentity)))))
		(setq returnvalue nil)
	)
	returnvalue
)

(defun makeleader (leaderpointlist leaderstylename leaderdata)
	;leaderdata is blkname, arrowheadsize
	(if leaderstylename
		(setq usedimstylename leaderstylename)
		(setq usedimstylename "Standard")
	)
	(setq Leaderent (list 	(cons 0 "LEADER")
							(cons 100 "AcDbEntity")
							(cons 67 0)
							(cons 410 (getvar "CTAB"))
							(cons 8 (getvar "CLAYER"))
							(cons 100 "AcDbLeader")
							(cons 3 usedimstylename)
							(cons 71 1)
							(cons 72 0)
							(cons 73 3)
							(cons 74 1)
							(cons 40 0.0)
							(cons 41 0.0)
							(cons 76 2)
                    )
    )
    (foreach leadpt leaderpointlist 
    	(setq leaderent (append Leaderent (list (cons 10 leadpt))))
    )
    (if leaderdata
    	(progn
    		(setq leaderblkname (nth 0 leaderdata)
    			  leaderarrowsize (nth 1 leaderdata)
    			  leaderblkhandle (getblockentityhandle leaderblkname)
    		)
    		(setq xdataforleader (cons -3 (list (list "ACAD" (cons 1000 "DSTYLE")
    					                               (cons 1002 "{")
    					                               (cons 1070 41)
    					                               (cons 1040 leaderarrowsize)
    					                               (cons 1070 40);new for scale size
    					                               (cons 1040 _SC);new for scale size
    					                               (cons 1070 341)
    					                               (if leaderblkhandle
    					                               	   (cons 1005 leaderblkhandle)
    					                               	   (cons 1005 "")
    					                               )
    					                               (cons 1002 "}")
    					                   )     )
    				              )
    			  Leaderent (append Leaderent (list xdataforleader))
    		)
    	)
    )

    (entmake Leaderent)
)

(defun medleader (leadblname txtflag scalesz LayerSpec /
                  lay txt genang lentmrk lentbk pt pt1 entblk allss entdata txt_spec oldy newy txt
                 )
   (setq genang nil
         leaddimstyle nil
         leaderbuildinfo nil
   )
   (setq lay (getvar "clayer"))
   (if (not layerspec)
   	   (setq layerdata _MEDTEXT)
   	   (setq layerdata layerspec)
   )
   (smlayer layerdata)
   (setq olderr *error*)
   (defun *error*(errmsg)
   	   (SetDimStyleVariable DimDataStyle "DIMLDRBLK" ".")
       (SetDimStyleVariable DimDataStyle "DIMASZ" _LEADSYMSIZE)
       (setq *error* olderr)
   )
   (if leadblname
      (progn
         (if (not (tblsearch "BLOCK" leadblname))
            (command "insert" leadblname nil)
         )
         (setq lentmrk (entlast))
         (setq DimDataStyle (getvar "DIMSTYLE")
         	   DimDataLeaderBlock	(getvar "DIMLDRBLK")
         	   DimDataLeaderArrowSize (getvar "DIMASZ")
         )
         (SetDimStyleVariable DimDataStyle "DIMLDRBLK" leadblname)
         (SetDimStyleVariable DimDataStyle "DIMASZ" (* _LEADSYMSIZE scalesz))
         (setq leaddimstyle "Standard"
         	   leaderbuildinfo (list leadblname (* _LEADSYMSIZE scalesz))
         )
      )
      (progn
      	  (setq DimDataStyle (getvar "DIMSTYLE")
         	   DimDataLeaderBlock	(getvar "DIMLDRBLK")
         	   DimDataLeaderArrowSize (getvar "DIMASZ")
         )
         (SetDimStyleVariable DimDataStyle "DIMLDRBLK" ".")
         (SetDimStyleVariable DimDataStyle "DIMASZ" (* _LEADSYMSIZE scalesz))
      )
   )
   ;(setvar "ORTHOMODE" 0)
   (prompt "\nLeader Start Point: ")
   (command "LEADER" pause)
   (setq pt (list (getvar "LASTPOINT"))
   	     cmdone nil
   )
   (command pause)
   (setq OrthoModeVariable (getvar "ORTHOMODE"))
   (setq pt (append pt (list (getvar "LASTPOINT"))))
   (command nil)
   (makeLeader pt leaddimstyle leaderbuildinfo)
   (setvar "ORTHOMODE" OrthoModeVariable)
   (while (setq addpoint (getpoint (nth 0 (reverse pt))))
   	   (setq pt (append pt (list addpoint)))
   	   (entdel (entlast))
   	   (makeleader pt leaddimstyle leaderbuildinfo)
   )
   (if (= DimDataLeaderBlock "")
   	   (SetDimStyleVariable DimDataStyle "DIMLDRBLK" ".")
   	   (SetDimStyleVariable DimDataStyle "DIMLDRBLK" DimDataLeaderBlock)
   )
   (SetDimStyleVariable DimDataStyle "DIMASZ" DimDataLeaderArrowSize)
   (if txtflag
   	   (progn
   	   	   (setq LeaderPtlist (reverse pt))
   	   	   (PlaceTextFromLeader (nth 1 leaderPtList) (nth 0 leaderptlist))
   	   )
       (setvar "CLAYER" lay)
   )
   (setq *error* olderr)
   (entlast)
)
(defun PlaceTextFromLeader (LeaderPoint1 LeaderPoint2)
	(princ "\nInside TextLeader")
	(setq genang (angle LeaderPoint1 LeaderPoint2))
    (cond
       ((= genang 0.0)
			(setq txtang   0.0
				  txtjust  "ML"
				  txtpt    (polar LeaderPoint2 genang (* 0.0625 _SC _PLOTSCALE))
				  txt_spec (list txtpt txtang txtjust)
			)
       )
       ((= genang PI)
			(setq txtang   0.0
				  txtjust  "MR"
				  txtpt    (polar LeaderPoint2 genang (* 0.0625 _SC _PLOTSCALE))
				  txt_spec (list txtpt txtang txtjust)
			)
       )
       ((= genang (* PI 0.5))
			(setq txtang   90.0
				  txtjust  "ML"
				  txtpt    (polar LeaderPoint2 genang (* 0.0625 _SC _PLOTSCALE))
				  txt_spec (list txtpt txtang txtjust)
			)
       )
       ((= genang (* PI 1.5))
			(setq txtang   90.0
				  txtjust  "MR"
				  txtpt    (polar LeaderPoint2 genang (* 0.0625 _SC _PLOTSCALE))
				  txt_spec (list txtpt txtang txtjust)
			)
       )
    )
    (med_text "T1" txt_spec)
)

(defun vtrayxdataget (xdgent / xdlist xdatalist xdlen xdcnt xdgentdata)
  (setq xdgentdata (entget xdgent (list "VERT_DATA")))
  (if (setq xdatalist (assoc -3 xdgentdata))
    (progn
      (setq xdatalist (cdr xdatalist)
            xdatalist (cdr (car xdatalist))
            xdlen     (length xdatalist)
            xdcnt     0
            xdlist    (list "VERT_DATA" )
      )
      
      (while (< xdcnt xdlen)
          (setq xdval (cdr (nth xdcnt xdatalist)))
          (setq xdlist (cons xdval xdlist)
	            xdcnt (1+ xdcnt)
	        
	      )
      )
      (setq xdlist (reverse xdlist))
    )
  )
  xdlist
)

(defun addvtraydata(entnm vtraydata)
  (setq endata (entget entnm)
        xdlist (list "VERT_DATA")
	xdlist (append xdlist (list (cons 1040 (nth 0 vtraydata))
				    (cons 1040 (nth 1 vtraydata))
				    (cons 1070 (nth 2 vtraydata))
				    (cons 1040 (nth 3 vtraydata))
			      )
	       )
	xdlist (list (list -3 xdlist))
        endata (append endata xdlist)
  )
  (entmod endata)
)

(defun break_out (bo_bk_ang bo_bk_pt bo_bk_dist bo_tray_flag)
  (setq b_pt (polar bo_bk_pt bo_bk_ang bo_bk_dist))
  (if (setq tmp_ent (nentselp "\n" b_pt))
     (progn
        (if bo_tray_flag
          (traychck b_pt)
          (dblchck b_pt)
        )
        (setq lentmrk(entlast))
        (while lentmrk
            (setq lentbk lentmrk
                  lentmrk (entnext lentmrk)
            )
        )
        (setq lentmrk lentbk)
        (setq tmp_ent (car tmp_ent))
        (if (eq lentmrk tmp_ent)
	  (setq islastent T)
	  (setq islastent nil)
	)
        (command "break" b_pt bo_bk_pt)
       (setq tdet DETDATA)
        (if DETDATA
          (progn
            (setq lastent (entlast)
		  lastdata(entget lastent)
             )
	     (if (= (dxf 0 lastdata) "LWPOLYLINE")
	       (progn
		 (if (entget tmp_ent)
		   (progn
		     (setq en1 tmp_ent)
		     (if (eq lentmrk (entlast))
		       (setq en2 nil)
		       (setq en2 (entlast))
		     )
		   )
		   (progn
		     (setq en1 (entnext lentmrk))
		     (if (eq en1 (entlast))
		       (setq en2 nil)
		       (setq en2 (entnext en1))
	             )
		   )
		 )
	       )
	       (progn
		 (setq s_ents (getvar "SORTENTS"))
                 (setvar "SORTENTS" 0)
                 (setq enset (ssget "X")
                       en1   (ssname enset 0)
                       en2   (ssname enset 1)
                 )
	       )
	     )
             (mk2lcon en1)
	     (if en2
	       (mk2lcon en2)
	     )
	     (if (and (not (= tmp_ent en1)) (entget tmp_ent))
	       (mk2lcon tmp_ent)
	     )
	    
             (setq PRIM_ENT en1)
             (if s_ents
	       (setvar "SORTENTS" s_ents)
	     )
         )
        )
        (if TR_MAIN
          (progn
	     (setq lastent (entlast)
		   lastdata(entget lastent)
             )
	     (if (= (dxf 0 lastdata) "LWPOLYLINE")
	       (progn
			 (if (entget tmp_ent)
			   (progn
				 (setq en1 tmp_ent)
				 (if (eq lentmrk (entlast))
				   (setq en2 nil)
				   (setq en2 (entlast))
				 )
			   )
			   (progn
				 (setq en1 (entnext lentmrk))
				 (if (eq en1 (entlast))
				   (setq en2 nil)
				   (setq en2 (entnext en1))
					 )
			   )
			 )
	       )
	       (progn
				 (setq s_ents (getvar "SORTENTS"))
				 (setvar "SORTENTS" 0)
				 (setq enset (ssget "X")
					   en1   (ssname enset 0)
					   en2   (ssname enset 1)
				)
	       )
	     )
         (medtrayOutline en1)
	     (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
	     (if en2
	       (progn
		 (medtrayoutline en2)
		 (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
	       )
	     )
             (setq PRIM_ENT en1)
	     (if s_ents
	       (setvar "SORTENTS" s_ents)
	     )
          )
        )
     )
   )
 
)

         
(defun bld_lw_ptlist(lwent)
  (setq lwptlist nil
        lwbulist nil
        lwdata (entget lwent)
  )
  (foreach dcode lwdata
     (if (= (car dcode) 10)
        (setq lwptlist (append lwptlist (list dcode)))
     )
     (if (= (car dcode) 42)
        (setq lwbulist (append lwbulist (list dcode)))
     )
  )
  (list lwptlist lwbulist)
)

(defun bld_3dpline_ptlist(plent)
  (setq plptlist nil
        pldata (entget plent)
  )
  (if (= (dxf 0 pldata) "POLYLINE")
    (progn
      (setq mode  (entget (entnext plent)))
      (while (/= (dxf 0 mode) "SEQEND")
      	  (setq plptlist (append plptlist (list (dxf 10 mode)))
      	  	    mode (entget (entnext (dxf -1 mode)))
      	  )
      )
	)
  )
  plptlist
)




(defun chopspace(txtstr)
  (if txtstr
     (progn
		  (setq dlen (strlen txtstr))
		  (if (> dlen 0)
			(progn
			  (setq lchar(substr txtstr dlen))
			  (while (and (> (setq dlen (1- dlen)) 0) (= lchar " "))
				 (setq lchar(substr txtstr dlen 1))
			  )
			  (setq txtstr (substr txtstr 1 (1+ dlen)))
			)
	     )
	  )
	 (setq txtstr "")
  )
  txtstr
)

(defun mparse(strng delchar txtid coldata)
   (setq stlen (strlen strng)
         modstr strng
         strcnt stlen
         fieldlist nil
         cmpchar nil
         txtstr nil
   )
   (if coldata
     (progn
	(foreach col coldata
	   (setq fielditm (chopspace (substr strng (car col) (cadr col)))
		 fieldlist(append fieldlist (list fielditm))
	   )
	)
     )
     (progn
       (while (> strcnt 0)
	  (setq cmpchar (substr strng strcnt 1)
		txtstr nil
	  )
	  (while (and (> strcnt 0) (or (/= cmpchar delchar) txtstr))
	     (setq cmpchar (substr strng strcnt 1)
		   strcnt  (1- strcnt)
	     )
	     (if (= cmpchar txtid)
	       (progn
		 (if txtstr
		   (progn
		     (if (> strcnt 1)
		       (progn
			 (if (= delchar (substr strng strcnt 1))
			    (setq txtstr nil)
			    (progn 
			      (if (= txtid (substr strng strcnt 1))
				(setq txtstrip (append txtstrip (list strcnt)))
			      )
			    )
			 )
		       )
		       (progn
			 (setq txtstr nil)
		       )
		     )
		   )
		   (progn
		     (setq txtstr T
			   rmtxtid T
		     )
		   )
		 )
	       )
	     )

	  )
	  (if (and (= strcnt 0) (/= cmpchar delchar))
	    (setq fielditm modstr)
	    (progn
	      (setq fielditm  (substr modstr (+ 2 strcnt)))
	      (if (< (strlen fielditm) 1)
		 (setq strcnt (1- strcnt))
	      )
	      (setq modstr (substr modstr 1 (- (strlen modstr) (1+ (strlen fielditm)))))
	    )
	  )
	  (if txtstrip
	    (progn
	      (setq fielditm (subst_txt fielditm (strcat txtid txtid) txtid))
	      (setq txtstrip nil)
	    )
	  )
	  (if rmtxtid
	     (setq fielditm (substr fielditm 2)
		   fielditm (substr fielditm 1 (1- (strlen fielditm)))
		   rmtxtid nil
	     )
	  )
	  (setq fieldlist (append (list fielditm) fieldlist))
	  (if (and (= strcnt 0) (= cmpchar delchar))
	     (setq fieldlist (append (list "") fieldlist))
	  )
	     
       )
     )
   )
   fieldlist
)

(defun chg_tray_pl_wdth(trayent width_factor)
  (setq trayentdata (entget trayent)
	trayoldwdth (assoc 43 trayentdata)
	traynewwidth(cons 43 (* _SC width_factor _PLOTSCALE))
	trayentdata (subst traynewwidth trayoldwdth trayentdata)
  )
  (entmod trayentdata)
)

(defun chg_ent_ltype(chgent chgltype)
  (setq chgentdata (entget chgent)
	chgoldltype(assoc 6 chgentdata)
	chgnewltype(cons 6 chgltype)
  )
  (if (not (tblsearch "LTYPE" chgltype))
    (progn
      (ltback chgltype)
      (ltback nil)
    )
  )
  (if (not chgoldltype)
    (setq chgentdata (append chgentdata (list chgnewltype)))
    (setq chgentdata (subst chgnewltype chgoldltype chgentdata))
  )
  (entmod chgentdata)
)

(defun get_con_tag( / r_tag)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     r_tag          ||    String value to be returned to  the calling
;;;                    ||    function. Default value is "NONE".

  (if _TAGOFF
    (setq r_tag "NONE")
    (setq r_tag (getstring T "\nTag <NONE>: "))
  )
  (if (= r_tag "")
    (setq r_tag "NONE")
  )
  r_tag
)

(defun prc_detlist(l_index / trim cnt item fnd_desc)
   (setq trim 1
         cnt  1
         cmd_data_list nil
   )
   (while (= " " (substr l_index trim))
      (setq trim (1+ trim))
   )
   (setq l_index (substr l_index trim))
   (while (setq item (read l_index))
      (setq cmd_data_list  (append cmd_data_list (list (nth item taglstng))))
      (while (and (/= " " (substr l_index cnt 1))
                  (/= ""  (substr l_index cnt 1))
             )
             (setq cnt (1+ cnt))
      )
      (setq l_index (substr l_index cnt))
   )
)
(defun upd_detaglst( / moditem modent moddata modold modnew)
   (if cmd_data_list
      (progn
        (foreach detail_item cmd_data_list
            (setq moditem (nth 3 detail_item)
                  moditem (assoc (nth 0 _DETTYP) moditem)
                  modent  (nth 2 moditem)
                  moddata (entget modent)
                  modold  (assoc 1 moddata)
            )
            (if (= (nth 2 detail_item) 1)
                (setq modnew (cons 1 ""))
                (setq modnew (cons 1 (strcat "(TYP. " (itoa (nth 2 detail_item)) ")")))
            )
            (setq moddata (subst modnew modold moddata))
            (entmod moddata)
            (entupd (dxf -1 moddata))
        )
      )
   )
)




(defun mk_str_len (mkstr mklen / mkstrlen )
   (setq mkstrlen (strlen mkstr))
   (while (< mkstrlen mklen)
       (setq mkstr (strcat mkstr " ")
             mkstrlen (strlen mkstr)
       )
   )
   mkstr
)


(defun typstrins( typstrnm / inspt)
  (if (findfile (strcat typstrnm ".dwg"))
     (progn
       (command "insert" typstrnm "pscale" _SC pause nil)
       (setq inspt (getvar "LASTPOINT"))
       (command "insert" (strcat "*" typstrnm) inspt _SC 0.0000)
     )
     (prompt "\nBock not Found!")
  )
)

(defun opt_eq_ins(opeqlst eqscflg blname inlaylst / instr eqsc tvar oldatdia
                                                    lblent ldrval)

; send eqscfalg as 0 to use 1 for the scale factor
; otherwise send 1 to use scale factor of drawing
  (if (= eqscflg 0)
    (setq eqsc 1.0)
    (setq eqsc _SC)
  )
  (if TAT_VAL
     (setq tvar TAT_VAL
           TAT_VAL nil
     )
  )
  (setq instr ""
        eqdef (car (nth 0 opeqlst))
  )
  (foreach eqlet opeqlst
      (setq instr (strcat instr (car eqlet) " "))
  )
  (if (> (length opeqlst) 1)
    (progn
      (initget instr)
      (setq eqsel (getkword (strcat "\nEnter Detail Letter " instr "<" eqdef ">: ")))
      (if (or (not eqsel) (= eqsel eqdef))
        (setq eqsel eqdef)
      )
      (setq _EQCODE (cadr (assoc eqsel opeqlst)))
    )
    (setq _EQCODE (cadr (nth 0 opeqlst)))
  )
  (setq _EQCODE (MEDRemapEQCodeToProjectCode _EQCODE))
  (if blname
    (progn
      (setq oldatdia (getvar "attdia"))
      (setvar "attdia" 0)
      (medblkins inlaylst blname nil nil eqsc 9)
      (setvar "attdia" oldatdia)
      (setq lblent (entlast)
            ldrval (sel_att_ent lblent "DETNUM" tvar)
      )
    )
    (progn
      (while (not ADDTOENT)
           (setq ADDTOENT (car (entsel "\nSelect Entity to Add Detail to: "))))
      (setq xdlist (bld_equip _EQCODE "NONE"))
      (xdatadd ADDTOENT xdlist)
    )
  )
  (setq ADDTOENT nil)
  (princ)
)




(defun verify_list (main_list test_list)
  (setq verify_ret T)
  (if (not (= (length main_list) (length test_list)))
    (setq verify_ret nil)
    (progn
     (setq lst_cnt 0
           lst_num (length main_list)
     )
     (while (and verify_ret (< lst_cnt lst_num))
         (setq cmp_itm (nth lst_cnt main_list))
         (if (member cmp_itm test_list)
            (setq verify_ret T)
            (setq verify_ret nil)
         )
         (setq lst_cnt (1+ lst_cnt))
     )
    )
  )
  verify_ret
)



(defun subst_txt (txtstrng cxoldst cxnewst)
  (setq cxoldln (strlen cxoldst)
	cxnewln (strlen cxnewst)
  )
  (cond
     ((> cxoldln 0)
	(setq oldlen (strlen txtstrng)
	      oldcnt 0
	      newval ""
	      chngd nil
	)
	(while (< oldcnt oldlen)
	  (setq cmpval (substr txtstrng (1+ oldcnt) cxoldln))
	  (if (= cmpval cxoldst)
	     (progn
	       (setq newval (strcat newval cxnewst)
		     oldcnt (1- (+ oldcnt cxoldln))
		     chngd T
	       )

	     )
	     (progn
	       (setq newval (strcat newval (substr txtstrng (1+ oldcnt) 1)))
	     )
	  )
	  (setq oldcnt (1+ oldcnt))
	)
     )
  )
  newval
)



(defun listtoggle (listvar listitm)
  (if (= (dxf listitm listvar) 0)
    (setq newval (cons listitm 1))
    (setq newval (cons listitm 0))
  )
  (setq oldval (assoc listitm listvar)
        listvar (subst newval oldval listvar)
  )
  listvar
)

(defun matchtxtprops (mtchss chglist mstrdata)
  (setq chgdata nil)
  (foreach itm chglist
    (if (= (cdr itm) 1)
      (setq chgdata (append chgdata (list (assoc (car itm) mstrdata))))
    )
  )
  (setq num (sslength mtchss)
        cnt 0
  )
  (while (< cnt num)
    (setq ent (ssname mtchss cnt)
          data(entget ent)
	  cnt (1+ cnt)
    )
    (foreach itm chgdata
      (setq oldvals (assoc (car itm) data)
	    data    (subst itm oldvals data)
      )
    )
    (entmod data)
  )
)

(defun attachfitting (fitcd)
  (setq atent (entsel (strcat "\nSelect Entity to add " (clookup fitcd _CSIZE _FITTING) " to: ")))
  (if atent
   (progn
     (setq atent (car atent)
           xdlist (bld_fitting fitcd _CSIZE "NONE" 0.0 0.0)
     )
     (xdatadd atent xdlist)
     (princ)
   )
  )
)

(defun move_attrib(mventhead mvang mvdist mvtagname)
    (setq mvattag (sel_att_ent mventhead mvtagname nil)
	  mvattagdata (entget mvattag)
	  oldpos   (assoc 10 mvattagdata)
	  newpos   (polar (dxf 10 mvattagdata) mvang mvdist)
	  newpos   (cons 10 newpos)
	  mvattagdata (subst newpos oldpos mvattagdata)
     )
     (if (assoc 11 mvattagdata)
       (progn
	 (setq old11pos (assoc 11 mvattagdata)
	       new11pos (polar (dxf 11 mvattagdata) mvdata mvdist)
	       new11pos (cons 11 new11pos)
	       mvattagdata (subst new11pos old11pos mvattagdata)
         )
       )
     )
     (entmod mvattagdata)
     (entupd mventhead)
)


(defun getdettags ( / det_ss  detlnum det_cnt det_ent
                      att_vals det_typ det_num det_code det_actl tagitem
                  )
   (setq det_ss (ssadd)
         taglstng   nil
         tagdisplay nil
   )
   (foreach detblk _DETBLK
      (setq tmp_ss (ssget "X" (list (cons 2 detblk))))
      (if tmp_ss
        (progn
         (setq tmp_len (sslength tmp_ss)
               tmp_cnt 0
         )
         (while (< tmp_cnt tmp_len)
            (setq tmp_ent (ssname tmp_ss tmp_cnt)
                  det_ss (ssadd tmp_ent det_ss) 
                  tmp_cnt (1+ tmp_cnt)
            )
         )
        )
      )
   )
   (if det_ss
     (progn
       (setq detlnum (sslength det_ss)
             det_cnt 0
             dispcnt 1
       )
       (while (< det_cnt detlnum)
         (setq det_ent (ssname det_ss det_cnt)
               att_vals(getatvals det_ent)
               det_typ (assoc (nth 0 _DETTYP) att_vals)
               det_typ (atoi (substr (nth 1 det_typ) (nth 1 _DETTYP)))
         )
         (if (= det_typ 0)
            (setq det_typ 1)
         )
         (setq det_num (nth 1 (assoc _DETNUM att_vals))
               det_num1(assoc _DETNUM1 att_vals)
               det_num1a(assoc _DETNUM1A att_vals)
         )
         (setq det_code(nth 0 (med_detail det_num))
               dsp_det_num det_num
         )
         (if det_num1
          (progn
            (setq det_num1(nth 1 det_num1)
                  det_code1 (nth 0 (med_detail det_num1))
                  dsp_det_num (strcat dsp_det_num "; " det_num1)
            )
            (if det_code
               (setq det_code(list det_code det_code1))
            )
          )
         )
         (if det_num1a
            (setq det_num1a(nth 1 det_num1a)
                  det_tags (list "NONE" det_num1a)
                  dsp_det_num (strcat dsp_det_num "-" det_num1a)

            )
         )
         (if det_code
           (progn
             (setq det_actl(medcount _EQUIP det_code nil det_tags nil nil nil nil)

                   tagitem (strcat (mk_str_len dsp_det_num 30) "| "
                                   (mk_str_len (itoa det_typ) 8) "| "
                                   (itoa det_actl)
                           )
                   tagdisplay (append tagdisplay (list tagitem))
                   taglstng   (append taglstng (list (list dispcnt
                                                           det_code
                                                           det_actl
                                                           att_vals
                                               )     )
                              )
                    dispcnt (1+ dispcnt)
             )
           )
         )
         (setq det_cnt (1+ det_cnt))
       )
     )
  )
)

(defun getatvals(attent / attdata attretlst )
  (setq attent (entnext attent)
        attdata (entget attent)
        attretlst nil
  )

  (while (/= (dxf 0 attdata) "SEQEND")
    (setq attretlst (append attretlst (list (list (dxf 2  attdata)
                                                  (dxf 1  attdata)
                                                  (dxf -1 attdata)
                                            )
                                      )
                    )
          attent (entnext attent)
          attdata (entget attent)
    )

  )
  attretlst
)

(defun xdatappend (xdlist1 xdlist2)
   (setq data1list(reverse xdlist1)
         xdlist   (cdr data1list)
         xdlist   (reverse xdlist)
         data2list(cdr xdlist2)
         data2list(cdr data2list)
         xdlist   (append xdlist data2list)
   )
   xdlist
)

(defun medcount (appname matcode appsize apptag apprtag appalt appdpth appmsr / cnt_data)
   (setq appss (ssget "x" (list (list -3 (list appname))))
         num   (sslength appss)
         cnt   0
         cntr  0
         _COUNTSS (ssadd)
   )
   (while (< cnt num)
     (setq cnt_data (xdataget (ssname appss cnt) appname))
     (cond 
        ((= appname _EQUIP)
            (if (> (length cnt_data) 3)
              (progn
                (setq ttllen  (1- (length cnt_data))
                      numapps (/ ttllen len_equip)
                      numcnt  0
                )
                (if (= (type matcode) (read "LIST"))
                   (progn
                      (setq worklist nil
                            workcnt  0
                      )
                      (foreach m_cd matcode
                       (if apptag
                         (setq worklist (append worklist (list (list
                                                         m_cd 
                                                         (nth workcnt apptag)
                                                         )     )
                                        )
                         )
                         (setq worklist (append worklist (list (list m_cd))))
                       )
                       (setq workcnt (1+ workcnt))
                      )
                      (setq tmp_list (cdr cnt_data)
                            workdata nil
                            tmp_cnt 0
                      )
                      (repeat numapps
                         (setq workdata (append workdata (list (list 
                                            (nth (1+ tmp_cnt) tmp_list)
                                            (nth tmp_cnt tmp_list)
                                        )                )     )
                               tmp_cnt (+ 2 tmp_cnt)
                         )
                      )
                      (if (verify_list worklist workdata)
                        (setq cntr (1+ cntr)
                              _COUNTSS (ssadd (ssname appss cnt) _COUNTSS)
                        )
                      )
                   )
                   (progn
                     (while (< numcnt numapps)
                        (setq mcmp (nth (+ 2 (* numcnt len_equip)) cnt_data))
                        (if (= mcmp matcode)
                           (setq cntr (1+ cntr)
                                 _COUNTSS (ssadd (ssname appss cnt) _COUNTSS)
                           )
                     
                        )
                        (setq numcnt (1+ numcnt))

                     )
                   )
                )

              )
              (progn
                (if (= (nth 2 cnt_data) matcode)
                   (setq cntr (1+ cntr)
                         _COUNTSS (ssadd (ssname appss cnt) _COUNTSS)
                   )
                )
              )
            )
        )
        ((= appname _CONDUIT)
            (if (> (length cnt_data) (1+ len_conduit))
              (progn
                (setq ttllen  (1- (length cnt_data))
                      numapps (/ ttllen len_conduit)
                      numcnt  0
                )
                (while (< numcnt numapps)
                   (setq mcmp (nth (+ 2 (* numcnt len_equip)) cnt_data))
                   (if (= mcmp matcode)
                      (setq cntr (1+ cntr)
                            _COUNTSS (ssadd (ssname appss cnt) _COUNTSS)
                      )

                   )
                   (setq numcnt (1+ numcnt))
                )

              )
              (progn
                (if (= (nth 2 cnt_data) matcode)
                   (setq cntr (1+ cntr)
                         _COUNTSS (ssadd (ssname appss cnt) _COUNTSS)
                   )
                )
              )
            )
        )

     )
     (setq cnt (1+ cnt))
   )
   cntr
)

; this function will return one of two items pending on a value of ckpt
; if ckpt is true then dblchk will erase entities assosiated with
; a double line conduit found at the point specified by ckpt

(defun dblchck ( ckpt / dblnum dblcnt dblent dbldata dblinfo condata dblsz dbllett)
  (if ckpt
    (progn
       (setq dblent  (ssname (ssget ckpt) 0)
             _MEDR14_BRKENT dblent
             dbldata (xdataget dblent _DOUBLE)
       )
       (if dbldata
         (progn
           (setq dbl1ent (handent (nth 1 dbldata))
                 dbl2ent (handent (nth 2 dbldata))
           )
           (if dbl1ent
             (progn
               (if (entget dbl1ent)
                 (entdel dbl1ent)
               )
             )
           )
           (if dbl2ent
             (progn
               (if (entget dbl2ent)
                 (entdel dbl2ent)
               )
             )
           )
         )
       )
    )
    (progn
      (setq dblnum (sslength RL_SS)
            dblcnt 0
      )
      (while (< dblcnt dblnum)
        (setq dblent  (ssname RL_SS dblcnt)
              dbldata (entget dblent (list _DOUBLE))
        )
        (if (dxf -3 dbldata)
          (progn
            (setq condata (xdataget dblent _CONDUIT)
                  dblsz (append (list (nth 2 condata)) dblsz)
            )
          )        
        )
        (setq dblcnt (1+ dblcnt))
      )
      (setq chklist dblsz)
      (if dblsz
        (progn
           (setq lgsz    (nth 0 RL_SS_DATA)
                 dbllett (nth 3 (getsize nil (rtos lgsz 4)))
           )
        )
      )
    )
  )
  dbllett
)

;
; This function is responsible for breaking out distances supplied if any
;
(defun med_brk_out(bk_ang bk_pt bk_dlst tray_flag / s_ents enset)
  (setq lastchk (entlast))
  
  (setq bk_d1     (nth 0 bk_dlst)
        bk_d2     (nth 1 bk_dlst)
        bk_d3     (nth 2 bk_dlst)
        bk_d4     (nth 3 bk_dlst)
  )

  (if (> bk_d1 0.0)
    (progn
      (break_out bk_ang bk_pt bk_d1 tray_flag)
    )
  )
  (if (> bk_d2 0.0)
    (progn
      (break_out (+ bk_ang (* 0.5 PI)) bk_pt bk_d2 tray_flag)
    )
  )
  (if (> bk_d3 0.0)
    (progn
      (break_out (+ bk_ang PI) bk_pt bk_d3 tray_flag)
    )
  )
  (if (> bk_d4 0.0)
    (progn
      (break_out (+ bk_ang (* 1.5 PI)) bk_pt bk_d4 tray_flag)
    )
  )
  (if PRIM_ENT
    (progn
      (setq RL_SS (ssadd PRIM_ENT)
            PRIM_ENT nil
      )
    )
    (progn
      (setq nlstent (entlast))
      (if (not (equal nlstent lastchk))
         (setq RL_SS (ssget "L"))
      )
    )
  )
;  (setvar "PICKBOX" pksz)
          
)

;; Function adds the handles of first two entities to last entity
;; and then adds handle of last entity to first two entities, but
;; will remove all xdata from first two entities before doing so

(defun xdr2line (xdrelent1 xdrelent2 xdmainent / handmdata handr1data
                 handr2data rent1data rent2data rxdadd mentdata mxdadd
                )
   (setq handmdata  (dxf 5 (entget xdmainent))
         handr1data (dxf 5 (entget xdrelent1))
         handr2data (dxf 5 (entget xdrelent2))
   )
   (setq xdrelent1 (xdstrip xdrelent1 nil))
   (setq xdrelent2 (xdstrip xdrelent2 nil))
   (setq rent1data (entget xdrelent1 (list "MED_*"))
         rent2data (entget xdrelent2 (list "MED_*"))
         rxdadd    (list '(1002 . "}"))
	       rxdadd   (cons (cons 1000 handmdata) rxdadd)
         rxdadd   (cons '(1002 . "{")         rxdadd)
	       rxdadd   (cons _DOUBLE               rxdadd)
	       rxdadd   (list -3 rxdadd)
	       rent1data (cons rxdadd rent1data)
	       rent2data (cons rxdadd rent2data)
   )
   (entmod rent1data)
   (entmod rent2data)
   (setq mentdata (entget xdmainent (list "MED_*"))
         mxdadd   (list '(1002 . "}"))
         mxdadd   (cons (cons 1000 handr1data) mxdadd)
         mxdadd   (cons (cons 1000 handr2data) mxdadd)
         mxdadd   (cons '(1002 . "{") mxdadd)
         mxdadd   (cons _DOUBLE  mxdadd)
         mxdadd   (cons -3 (cons mxdadd (cdr (assoc -3 mentdata))))
         mentdata (subst mxdadd (assoc -3 mentdata) mentdata)
   )
   (entmod mentdata) 
)

;; routine to remove all xdata existing in passed entity

(defun xdstrip (stent strp_appcode / stentdata stxdata xdata newxdata cnt num)
  (if (not strp_appcode)
      (setq strp_appcode (list "*"))
      (setq strp_appcode (list strp_appcode))
  )
  (setq stentdata (entget stent strp_appcode)
        stxdata   (assoc -3 stentdata)
	xdata     (cdr stxdata)
  )
  (if xdata
    (progn
     (setq newxdata  (list (list (car (nth 0 xdata))))
           cnt       1
           num       (length xdata)
     )
     (while (< cnt num)
    	  (setq newxdata (append newxdata (list (list (car (nth cnt xdata)))))
                cnt      (1+ cnt)
	  )
     )
     (setq newxdata (cons -3 newxdata)
           stentdata(subst newxdata stxdata stentdata)
     )
     (entmod stentdata)
     (setq stentdata (entget stent))
     (dxf -1 stentdata)
    )
  )
)

;; function for modifying entities inserted with attributes
;; after a complete insertion has been made with ATTREQ off

(defun attmod(attmodent / attmoddat stepent stepdata stepval)
  (setq attmoddat (entget attmodent))
  (if (and (= (dxf 0 attmoddat) "INSERT") (dxf 66 attmoddat))
     (progn
       (setq stepent (entnext attmodent)
             stepdata(entget stepent)
       )
       (terpri)
       (if (= (getvar "ATTDIA") 1)
         (progn
           (command "ddatte" (entlast))
         )
         (progn
           (while (/= (dxf 0 stepdata) "SEQEND")
             (if (/= (dxf 70 stepdata) 8)
              (progn
               (setq stepval(getstring T (strcat(dxf 2 stepdata)" <"
                              (dxf 1 stepdata) ">: "))
	           )
	           (if (not (= stepval ""))
	            (progn
	              (if (= stepval " ")
	                (setq stepdata (subst (cons 1 "")(assoc 1 stepdata) stepdata))
		              (setq stepdata (subst (cons 1 stepval)(assoc 1 stepdata) stepdata))
	              )
	              (entmod stepdata)
	            )
	           )
              )
             )
             (setq stepent (entnext stepent)
                   stepdata(entget stepent)
             )
           )   
	       ;(entupd attmodent)   
         )
       )
     )
     (progn
       (prompt "\nNo Attributes")
       (terpri)
     )
  )
)

;; function returns a point between two points provided

(defun be ( pta ptb / pt)
  (setq pt nil)
  (if (not pta)
   (progn (setq pta (getpoint "\nSelect first point: "))
          (setq ptb (getpoint "\nSelect second point: "))
   )
  )
  (setq pt (list (* (+ (car pta) (car ptb)) 0.5)
                 (* (+ (cadr pta) (cadr ptb)) 0.5))
  )
  (if (caddr pta) 
    (setq pt (append pt (list
                           (* (+ (caddr pta) (caddr ptb)) 0.5)))
    )
  )
  pt
)

(defun between()
(be nil nil)
)

;; function returns an applications xdata from a provided
;; entity.

(defun xdataget (ent app_name / xdlist)
  (setq entdata (entget ent (list app_name)))
  (if (setq xdatalist (assoc -3 entdata))
    (progn
      (setq xdatalist (cdr xdatalist)
            xdatalist (cdr (car xdatalist))
            xdlen     (length xdatalist)
            xdcnt     1
            xdlist    (list app_name )
      )
      
      (while (< xdcnt xdlen)
          (setq xdval (cdr (nth xdcnt xdatalist)))
          (cond
              ((= (substr xdval 1 9) "ITEM_DESC")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "ITEM_TAG_")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "ITEM_RTAG")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "#ITEMSIZE")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMCODE")
                 (setq xdval (substr xdval 11)
                       xdval (atoi xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMDIST")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEMDPTH")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "#ITEM_ALT")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
              ((= (substr xdval 1 9) "ITEM_MESR")
                 (setq xdval (substr xdval 11))
              )
              ((= (substr xdval 1 9) "#ITEMFLNG")
                 (setq xdval (substr xdval 11)
                       xdval (atof xdval)
                 )
              )
          )
          (setq xdlist (cons xdval xdlist)
	              xdcnt (1+ xdcnt)
	        
	        )
      )
      (setq xdlist (cdr xdlist)
            xdlist (reverse xdlist)
      )
    )
  )
  xdlist
)

(defun xd_apps (ent)
  (setq finallist nil)
  (setq entdata (entget ent (list "MED*")))
  (if (setq xdatalist (dxf -3 entdata))
    (progn
      (setq numapps   (length xdatalist)
            xdcnta    0
            applist nil
      )
      (while (< xdcnta numapps)
           (setq xdatalista (nth xdcnta xdatalist)
                 appnm      (nth 0 xdatalista)
           )
           (if (and (/= appnm _DOUBLE) (/= appnm _ELEC))
             (setq applist  (append applist (list appnm)))
           )
           (setq xdcnta (1+ xdcnta))
      )
    )
  )
  applist
)

;; function to add xdata provided to provided entity

(defun xdatadd (ent xdata)
  (setq xentdata (entget ent)
        xdadd    (list -3 xdata)
	xentdata (cons xdadd xentdata)
  )
  (entmod xentdata)
  (princ)
)

;; function to read appropriate string from medtype.dat file
;; then build string with size and description

(defun clookup (lookcode size apptype)
  (cond
     ((= apptype _CONDUIT)
        (setq rstr (strcat (rtos size 4 2) " ")
              aplk "CONDUIT"
        )

     )
     ((= apptype _CABLE)
        (setq aplk "CABLE")
        (if size
           (setq rstr (strcat (itoa (fix size)) " "))
           (setq rstr "1 ")
        )
     )
     ((= apptype _EQUIP)
        (setq rstr ""
              aplk "EQUIP"
        )
     )
     ((= apptype _TRAY)
        (setq rstr (strcat (rtos size 5 4) "\" ")
              aplk "TRAY"
        )
     )
     ((= apptype _FITTING)
        (setq aplk "FITTING"
        )
        (if (or _ZERO (= size 0.0))
          (setq rstr "")
          (setq rstr (strcat (rtos size 4 2) " "))
        )
     )
  )
  (if (= lookcode 0)
    (setq rval "MED BOM void Entity")
    (setq rval (med_getdesc aplk lookcode))
  )

  (setq rstr (strcat rstr rval))
  
  rstr
)

;; function returns a listing of size info about arguments passed

(defun getsize (gtlett gtsize)
  (setq GT_INFO nil)
  (cond ((or (= gtlett "A")(= gtsize (rtos 0.5 4)))
          (setq GT_INFO (list 0.5 0.84 "[1\\2]\042" "A" "1")))
        ((or (= gtlett "B")(= gtsize (rtos 0.75 4)))
          (setq GT_INFO (list 0.75 1.050 "[3\\4]\042" "B" "2")))
        ((or (= gtlett "C")(= gtsize (rtos 1.0 4)))
          (setq GT_INFO (list 1.0 1.315 "1\042" "C" "3")))
        ((or (= gtlett "D")(= gtsize (rtos 1.25 4)))
          (setq GT_INFO (list 1.25 1.66 "1[1\\4]\042" "D" "4")))
        ((or (= gtlett "E")(= gtsize (rtos 1.5 4)))
          (setq GT_INFO (list 1.5 1.9 "1[1\\2]\042" "E" "5")))
        ((or (= gtlett "F")(= gtsize (rtos 2.0 4)))
          (setq GT_INFO (list 2.0 2.375 "2\042" "F" "6")))
        ((or (= gtlett "G")(= gtsize (rtos 2.5 4)))
          (setq GT_INFO (list 2.5 2.875 "2[1\\2]\042" "G" "7")))
        ((or (= gtlett "H")(= gtsize (rtos 3.0 4)))
          (setq GT_INFO (list 3.0 3.5 "3\042" "H" "8")))
        ((or (= gtlett "I")(= gtsize (rtos 3.5 4)))
          (setq GT_INFO (list 3.5 4.0 "3[1\\2]\042" "I" "9")))
        ((or (= gtlett "J")(= gtsize (rtos 4.0 4)))
          (setq GT_INFO (list 4.0 4.5 "4\042" "J" "10")))
        ((or (= gtlett "K")(= gtsize (rtos 5.0 4)))
          (setq GT_INFO (list 5.0 5.563 "5\042" "K" "11")))
        ((or (= gtlett "L")(= gtsize (rtos 6.0 4)))
          (setq GT_INFO (list 6.0 6.625 "6\042" "L" "12")))
        ((= gtsize 1.625)
          (setq GT_INFO (list 1.625 nil "1-5/8\042" "" "1")))
        ((= gtsize 4.0)
          (setq GT_INFO (list 4.0   nil "4\042"     "" "2")))
        ((= gtsize 6.0)                          
          (setq GT_INFO (list 6.0   nil "6\042"     "" "3")))
        ((= gtsize 9.0)           
          (setq GT_INFO (list 9.0   nil "9\042"     "" "4")))
        ((= gtsize 12.0)
          (setq GT_INFO (list 12.0  nil "12\042"    "" "5")))
        ((= gtsize 18.0)
          (setq GT_INFO (list 18.0  nil "18\042"    "" "6")))
        ((= gtsize 24.0)
          (setq GT_INFO (list 24.0  nil "24\042"    "" "7")))
        ((= gtsize 30.0)
          (setq GT_INFO (list 30.0  nil "30\042"    "" "8")))
        ((= gtsize 36.0)
          (setq GT_INFO (list 36.0  nil "36\042"    "" "9")))
        ((= gtsize 42.0)
          (setq GT_INFO (list 42.0  nil "42\042"    "" "10")))
        ((= gtsize 48.0)
          (setq GT_INFO (list 48.0  nil "48\042"    "" "11")))

  )
  GT_INFO
)	  

;; function sets the linetype to specified argument passed
;; if nil sets linetype to bylayer

(defun ltback(sltp)
  (if (not sltp)
    (progn
       (command "linetype" "s" "bylayer" "") 
       (setq _LTP "bylayer")
    )
    (progn
       (command "linetype" "s" sltp "")
       (setq _LTP sltp)
    )
  )
  
)



;; simple function for inserting a block at a specified point
;; rotation and scale

(defun insblk(blname ipt blsc insrot)
   (command "insert" blname ipt blsc blsc insrot)
)



;; function toggles MED variables off or on and prompts the user
;; of the current status of that variable

(defun toggle (medvar togprmpt)
   (cond
      ((= (eval (read medvar)) 1)
         (set (read medvar) 0)
         (prompt (strcat "\n" togprmpt " is now OFF:"))
      )
      ((= (eval (read medvar)) 0)
         (set (read medvar) 1)
         (prompt (strcat "\n" togprmpt " is now ON: "))
      )
      ((= (eval (read medvar)) T)
         (set (read medvar) nil)
         (prompt (strcat "\n" togprmpt " is now OFF: "))
      )
      ((= (eval (read medvar)) nil)
         (set (read medvar) T)
         (prompt (strcat "\n" togprmpt " is now ON: "))
      )
   )
   (princ)
)

(defun retr_size_tag(con_ss / cnt num cmsize consize cmpent cmlent rtsize
                              concode)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     con_ss         ||    Selection set of entities at insertion point
;;;     cnt            ||    counter variable
;;;     num            ||    selection set length
;;;     cmsize         ||    size stored in base entity
;;;     consize        ||    size of conduit set to equal cmsize
;;;     cmpent         ||    compare entity name for filtering therough sset
;;;     cmlent         ||    entity name to be used as base entity
;;;     rtsize         ||    list of data to be returned to calling function
;;;     concode        ||    conduit code used in xdata

   (setq num (sslength con_ss)
         cnt 0
         cmsize 0
         cssize 100
   )
   (while (< cnt num)
     (setq cmpent (ssname con_ss cnt)
           consize(xdataget cmpent _CONDUIT)
     )
     (if (not consize)
        (progn
          (setq consize (xdataget cmpent _FITTING))
        )
     )
     (if consize
       (progn
         (setq contag   (nth 1 consize)
	             concode  (nth 3 consize)
	             consize  (nth 2 consize)
         )
         (if (> consize cmsize)
           (setq cmsize consize
                 cmlent cmpent
                 mxtag  contag
                 mxcode concode
           )
         )
         (if (< consize cssize)
           (setq cssize consize
                 cslent cmpent
                 mntag  contag
                 mncode concode
           )
         )

       )
     )
     (setq cnt (1+ cnt))
   )
   (if (/= cmsize 0)
     (progn
       (if (and (= _SIZEOVR 1) (> _CSIZE cmsize))
         (setq rt_size (list _CSIZE mxtag mxcode cssize mntag mncode)
               testdata rt_size)
        (setq rt_size (list cmsize mxtag mxcode cssize mntag mncode)
               testdata rt_size)
       )
     )
   )

   rt_size
)

; this function simply returns a string concatenation of a block
; prefix name for feed through devices
;

(defun feedset (dbl_name)
   (if (= _FEED 1)
     (setq dbl_name (strcat dbl_name "C"))
   )
   dbl_name
)
;
; This function will simply break out an object and return a
; rotation for a block to be inserted.
;

(defun brk_rot (br_pt br_blname br_sc)
	(princ "\nInside brk_rot")
  (setq DETDATA (dblchck nil)
	br_pt (list (nth 0 br_pt) (nth 1 br_pt))
  )
  (if DETDATA 
     (progn
        (setq brblnm (substr br_blname 1 (- (strlen br_blname) 1))
              brblnm (strcat brblnm DETDATA)
        )
        (if (findfile (strcat brblnm ".dwg"))
          (setq br_blname brblnm
                NEW_BLNAME brblnm
          )
          (setq NEW_BLNAME br_blname)
        )
     )
  )
  (if (not NEW_BLNAME)
    (setq NEW_BLNAME br_blname)
  )
  (if (< br_sc 1.01)
    (setq bl_sz (* _PLOTSCALE 4.5))
    (setq bl_sz (* _PLOTSCALE 0.125))
  )
  (setq br_data   (entget (car (nentselp "\n" br_pt)))
        br_bldata (get_bl_data br_blname)
        br_d1     (* (nth 0 br_bldata) br_sc)
        br_d2     (* (nth 1 br_bldata) br_sc)
        br_d3     (* (nth 2 br_bldata) br_sc)
        br_d4     (* (nth 3 br_bldata) br_sc)
        rt_spec   (nth 4 br_bldata)
        br_list   (list br_d1 br_d2 br_d3 br_d4)
  )
  (if (= _USERROT 1)
     (setq rt_spec 4)
  )
  (setq oldaperture (getvar "APERTURE"))
  (setvar "aperture" 1)
  (cond 
       ((not rt_spec)
          (setq br_ang 0.0)
          (med_brk_out br_ang br_pt br_list nil)

       )
       ((= rt_spec 0)
          (setq br_pt2 (osnap br_pt "MID"))
          (if (or (equal (dxf 10 br_data) br_pt)
                  (equal (osnap (polar br_pt2 (angle (dxf 10 br_data) br_pt2)
                                              (* 0.125 br_sc _PLOTSCALE))
                                              "END") br_pt)
              )
              (progn 
                (setq br_ang (angle br_pt br_pt2))
              )
              (progn
                (setq br_pt2 (osnap (cadr (entsel "\nSelect point on line for rotation: ")) "NEA"))
                (if (not br_pt2)
                  (setq br_pt2 (osnap br_pt "MID"))
                )
                (setq br_ang (angle br_pt br_pt2))
              )
          )
          
          (med_brk_out br_ang br_pt br_list nil)
       )
       ((= rt_spec 1)
          (setq br_pt2 (osnap br_pt "MID")
                br_ang (angle br_pt br_pt2)
          )
          (med_brk_out br_ang br_pt br_list nil)
       )
       ((= rt_spec 22)
          (setq br_pt2 (osnap br_pt "MID")
                tmp_ang(angle br_pt br_pt2)
                br_pt3 (polar br_pt (+ (* 0.5 PI) tmp_ang) (* bl_sz br_sc))
                br_pt4 (polar br_pt (+ (* 1.5 PI) tmp_ang) (* bl_sz br_sc))
          )
          (if (nentselp "\n" br_pt3)
              (setq br_ang tmp_ang)
              (setq br_ang (angle br_pt br_pt4))
          )
          (med_brk_out br_ang br_pt br_list nil)
       )   
       ((= rt_spec 24)
          (setq br_pt2 (osnap br_pt "MID")
                tmp_ang(angle br_pt br_pt2)
                br_pt3 (polar br_pt (+ (* 0.5 PI) tmp_ang) (* bl_sz br_sc))
                br_pt4 (polar br_pt (+ (* 1.5 PI) tmp_ang) (* bl_sz br_sc))
          )
          (if (nentselp "\n" br_pt4)
            (progn
              (setq br_ang tmp_ang)
              (prompt "\nPT4")
            )
            (progn
              (setq br_ang (angle br_pt br_pt3))
              (prompt "\nPT3")
            )
          )
          (med_brk_out br_ang br_pt br_list nil)
       )   
       ((= rt_spec 3)
          (setq br_pt2 (osnap br_pt "MID")
                tmp_ang(angle br_pt br_pt2)
                br_pt3 (polar br_pt (+ (* 0.5 PI) tmp_ang) (* bl_sz br_sc))
                br_pt4 (polar br_pt (+ (* 1.5 PI) tmp_ang) (* bl_sz br_sc))
          )
          (if (and (nentselp "\n" br_pt3) (nentselp "\n" br_pt4))
              (setq br_ang tmp_ang)
              (progn
                (if (nentselp "\n" br_pt3)
                    (setq br_ang (angle br_pt br_pt3))
                    (setq br_ang (angle br_pt br_pt4))
                )
              )
          )
          (med_brk_out br_ang br_pt br_list nil)
       )   
       ((= rt_spec 4)
          (command "insert" NEW_BLNAME br_pt br_sc br_sc pause)
          (setq tmpdata (dxf 50 (entget (entlast))))
          (entdel (entlast))
          (setq br_ang tmpdata)
          (setq tmpdata nil)
;          (setq br_ang (getangle br_pt "\nRotation: "))
          (med_brk_out br_ang br_pt br_list nil)
       )
       ((= rt_spec 5)
          (setq br_pt2 (osnap br_pt "MID")
                br_ang (angle br_pt br_pt2)
          )
          (if (and (> br_ang (* PI 0.5)) (<= br_ang (* PI 1.5)))
            (setq br_ang (angle br_pt2 br_pt))
          )
          (med_brk_out br_ang br_pt br_list nil)
       )
       ((= rt_spec 6)
          (setq br_pt2 (osnap br_pt "MID")
                br_ang (angle br_pt2 br_pt)
          )
          (if (and (>= br_ang (* PI 0.5)) (< br_ang (* PI 1.5)))
            (setq br_ang (angle br_pt br_pt2))
          )
          (med_brk_out br_ang br_pt br_list nil)
       )


  )
  (setvar "APERTURE" oldaperture)
  (setq DETDATA nil)
  br_ang
)


(defun med_cur_set(func_name)
   (setvar "ATTREQ" 1)
   ;(setq MakeEdDes(savevars))
   (if (not MED_ERROR)
     (progn
        (setq MED_ERROR T
              MED_ERR_CNT 0
        )
        (setq MED_SYSVARS (list  (getvar "CELTYPE")
                                 (getvar "DIMASZ")
                                 (getvar "DIMBLK")
                                 (getvar "CLAYER")
                                 (getvar "OSMODE")
                                 (getvar "ATTDIA")
                                 (getvar "ATTREQ")
                                 (getvar "FILLETRAD")
                                 (getvar "HIGHLIGHT")
                                 (getvar "PICKBOX")
                          )
        )
        (setq olderr *error*
              _FUNCNAME func_name
        )
        (setq trap_trcode  _TRCODE
              trap_trtype  _TRTYPE
              trap_trdepth _TRDEPTH
              trap_trsize  _TRSIZE
        )
        (defun *error*(errmsg)
           ;(restvars)
           (med_reset)
           (prompt (strcat "\n"_FUNCNAME " " errmsg "\n"))
           (setq *error* olderr)
        )
        (if (= MakeEdDes 0)
          (progn
            (alert "MED has failed verification!")
            (exit)
          )
        )
     )
     (setq MED_ERR_CNT (1+ MED_ERR_CNT))
   )
)
(defun med_reset()
     (command nil nil)
     (setvar "DIMASZ"    (nth 1 MED_SYSVARS))
     (if (= (nth 2 MED_SYSVARS) "")
        (command nil "dim1" "DIMBLK" ".")
        (command nil "dim1" "DIMBLK" (nth 2 MED_SYSVARS))
     )
     (setq _TRCODE  trap_trcode)
     (setq _TRTYPE  trap_trtype)  
     (setq _TRDEPTH trap_trdepth) 
     (setq _TRSIZE  trap_trsize)  
     (setq *error* olderr)
)
(defun med_ret_ok()
    (if (< MED_ERR_CNT 1)
      (progn
        (setq *error* olderr)
      )
      (progn
        (setq MED_ERR_CNT (1- MED_ERR_CNT))
      )
    )
    (princ)
)

(defun med_verify( / rkval expdate)
  (setq dtnum (getvar "CDATE")
        dtstr (rtos dtnum 2 0)
        expdate 20010315
        dtnum (atoi dtstr)
       ; rkval (adsverify "tnilc")
  )

  (if (> dtnum expdate)
     (progn
       (alert "MED has failed verification")
       (exit)
     )
     (setq rkval 1)
  )
  rkval
)


(defun addatrib(at_tag at_val at_ent at_pt)

  (setq at_ent(car (entsel "\nSelect Block to Add Attribute to: "))
        tagnm (getstring "\nTAG: ")
        atval (getstring T "\nValue: ")
        inspt (getpoint "\nSelect Point for Insertion of Attribute: ")
        blkdata (entget at_ent (list"*")) 
  )

  (if (= (dxf 66 blkdata) 1)
    (progn
       (entmake blkdata)
       (setq suben (entnext at_ent)
             subdata (entget suben)
       ) 
       (while (/= (dxf 0 subdata) "SEQEND")
         (entmake subdata)
         (setq suben (entnext suben)
               subdata (entget suben)
         )
       )
    )
    (progn
       (setq newblk (list (cons 0 "INSERT")
                          (assoc 10 blkdata)
                          (assoc 2 blkdata)
                          (assoc 41 blkdata)
                          (assoc 8 blkdata)
                          (assoc 42 blkdata)
                          (assoc 43 blkdata)
                          (assoc 50 blkdata)
                          (cons 66 1)
                    )
       )
       (if (assoc -3 blkdata)
           (setq newblk (append newblk (list (assoc -3 blkdata))))
       )
       (entmake newblk)
    )
  )
  (setq addent (list (cons 0 "ATTRIB")
                     (cons 8 (nth 0 _MEDTEXT))
                     (cons 70 0)
                     (cons 10 inspt)
                     (cons 1 atval)
                     (cons 2 tagnm)
                     (cons 40 (getvar "TEXTSIZE"))
                     (cons 7  (getvar "TEXTSTYLE"))
               )
  )
  (entmake addent)
  (entdel at_ent)
  (entmake (list (cons 0 "SEQEND")))
)
(defun newsz (act let sz)
  (if (and _NEWSIZELST (not act))
    (progn
     (setq _ACSIZE (nth 0 _NEWSIZELST)
           _CLETT  (nth 1 _NEWSIZELST)
           _CSIZE  (nth 2 _NEWSIZELST)
           _NEWSIZELST nil
     )
     (prompt (strcat "\nCurrent Size is Now " (rtos _CSIZE 4 4)))
     (terpri)
    )
  )
  (if act
     (setq _NEWSIZELST (list act let sz))
  )
)
(defun settog (option togval)
  (if option
     (progn
        (cond
           ((= option 1)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_CONFILL" 1))))
                  (set_tile "conbend" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_CONFILL" 0))))
                  (set_tile "conbend" "0")
               )
             )
           )
           ((= option 2)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_SIZEOVR" 1))))
                  (set_tile "sizeovr" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_SIZEOVR" 0))))
                  (set_tile "sizeovr" "0")
               )
             )
           )
           ((= option 3)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_USERROT" 1))))
                  (set_tile "userrot" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_USERROT" 0))))
                  (set_tile "userrot" "0")
               )
             )
           )
           ((= option 4)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_FEED" 1))))
                  (set_tile "devfeed" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_FEED" 0))))
                  (set_tile "devfeed" "0")
               )
             )
           )
           ((= option 5)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_TAGOFF" nil))))
                  (set_tile "tagging" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_TAGOFF" T))))
                  (set_tile "tagging" "0")
               )
             )
           )
           ((= option 6)
             (if (equal togval "1")
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_VERTICALTRAY" T))))
                  (set_tile "verttray" "1")
               )
               (progn
                  (setq _NTOGGLES (append _NTOGGLES (list (list "_VERTICALTRAY" nil))))
                  (set_tile "verttray" "0")
               )
             )
           )

        )
     )
     (progn
        (foreach var _NTOGGLES
           (set (read (nth 0 var)) (nth 1 var))
        )
     )
  )
)
(defun setmedval (option $value)
   (if option
      (progn
        (cond
          ((= option 5)
            (setq _NVALS (append _NVALS (list (list "_MEDRADFAC" (atof $value)))))
          )
          ((= option 6)
            (setq _NVALS (append _NVALS (list (list "_TRTANFAC" (atof $value)))))
          )
        )
      )
      (progn
         (foreach var _NVALS
            (set (read (nth 0 var)) (nth 1 var))
         )
      )
  )
)

(defun MEDremoveitemfromlist (originallist removelist)
	(setq returnlist (list))
	(if (equal originallist removelist)
		(setq returnlist (list))
		(foreach litem originallist
			(if (not (member litem removelist))
				(setq ReturnList (append ReturnList (list litem)))
			)
		)
	)
	returnlist
)

(defun MEDRemapEQCodeToProjectCode(equipmentcode)
	(setq SQLLookupStatement (strcat "SELECT ITEMCODE from MEDTYPE WHERE ITEMTYPE='EQUIP' AND USER3='" 
			                         (itoa equipmentcode) "' AND USER4='" _MEDPROJECT "'")
		  Lookupresults (MEDProcessSQLStatement SQLLookupStatement)
	)
	(if (> (length lookupresults) 1)
		(setq CodeToUse (fix (nth 0 (car (cdr lookupresults)))))
		(setq CodeToUse equipmentcode)
	)
	CodeToUse
)
			
(princ "Done.")
			
