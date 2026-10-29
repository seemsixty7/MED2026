(princ "\rLoading MEDCableTray...")
(defun MEDSetTrayValues (ValueList)
	(setq _TRCODE (nth 0 ValueList)
		  _TRTYPE (nth 1 ValueList)
		  _TRSIZE (nth 2 ValueList)
		  _TRDEPTH(nth 3 ValueList)
		  _TRAYFLANGE (nth 4 ValueList)
	)
)
(defun c:TRAY()
	(MEDSettings "C:TRAY")  ; The intent of this function is to set the layer and environment properly for this function.
	(if _MEDTRAYPT1
		(setq TRAY_Point1 _MEDTRAYPT1)
		(setq TRAY_Point1 (getpoint (strcat "\nStartpoint of " (clookup (+ _TRCODE _TRTYPE) _TRSIZE _TRAY) ": ")))
	)
	(if _MEDTRAYPT2
		(setq TRAY_Point2 _MEDTRAYPT2)
		(setq TRAY_Point2 (getpoint TRAY_Point1 "\nTo Point: "))
	)
	(MEDTray (list (list TRAY_Point1 TRAY_Point2) (+ _TRCODE _TRTYPE) _TRSIZE))
	(setq TrayTag (MEDGetTrayTag nil))
	(setq xdlist (bld_tray (+ _TRCODE _TRTYPE) _TRSIZE traytag nil _TRDEPTH "T" _TRAYFLANGE))
    (xdatadd (entlast) xdlist)
    (MEDTrayOutline (entlast))
    (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
    (princ)
)
	
(defun MEDGetTrayTag(mgtt-data) ; This function will return a traytag
	(setq mgtt-traytag "")
	(if (not _TRAYTAGDEFAULT)
		(setq mgtt-defaulttraytag "NONE")
		(setq mgtt-defaulttraytag _TRAYTAGDEFAULT)
	)
	(if (not _TAGOFF)
		(progn
			(if _MEDTAG
				(setq mgtt-traytag  _MEDTAG
					  _MEDTAG nil
				)
				(setq mgtt-traytag (getstring T (strcat "\nCableTray Tag number <" mgtt-defaulttraytag ">:")))
			)
		)
	)		
	;;Add possibility of rereiving a unique Tray Tag from a Database Table.
	(if (= mgtt-traytag "")
		(setq mgtt-traytag mgtt-defaulttraytag)
	)
	mgtt-traytag
)
		
(defun MEDTray (TrayData)  ;List of Tray specifics
	(setq MEDTray_Point1 (nth 0 (car TrayData))
		  MEDTray_Point2 (nth 2 (car TrayData))
	)
	(setvar "ELEVATION" (caddr MEDTray_Point1))
	(MEDPlineMake (car TrayData) nil nil nil)
)

(defun chg_tray_pl_wdth(trayent width_factor)
  (setq trayentdata (entget trayent)
	trayoldwdth (assoc 43 trayentdata)
	traynewwidth(cons 43 (* _SC width_factor _PLOTSCALE))
	trayentdata (subst traynewwidth trayoldwdth trayentdata)
  )
  (entmod trayentdata)
)

(defun MEDTrayOutline(trent)
  (setq trtype_ref 2
  	  	mtrayelev (getvar "ELEVATION")
  	  	trentdata (entget trent)
  	  	trentOCS (dxf 210 trentdata)
  )
  ;(setvar "ELEVATION" (dxf 38 trentdata))
  (if _VERTICALTRAY
     (setq trtype_ref 5)
  )
  (if (setq origtype (xdataget trent _DOUBLE))
     (progn
        (if (member "VERTICAL" origtype)
           (progn
             (if (not _VERTICALTRAY)
                (setq _VERTICALTRAY T
                      _RESETVTRAY T
                      trtype_ref 5
                )   
                (setq trtype_ref 5)
             )
           )
        )
     )
  )
  (if (dxf -3 (entget trent (list _TRAY)))
    (progn
      (if (= (dxf 0 (entget trent)) "LWPOLYLINE")
        (setq ptlist (bld_lw_ptlist trent)
              trpt1  (cdr (nth 0 (nth 0 ptlist)))
              trpt2  (cdr (nth 1 (nth 0 ptlist)))
        )
        (setq trd1 (entget (entnext (dxf -1 (entget trent))))
              trd2 (entget (entnext (dxf -1 trd1)))
              trpt1(dxf 10 trd1)
              trpt2(dxf 10 trd2)
        )
      )
      (setq trpt1 (trans (append trpt1 (list (dxf 38 trentdata))) trentOCS 1)
      	    trpt2 (trans (append trpt2 (list (dxf 38 trentdata))) trentOCS 1)
      	    trang (angle trpt1 trpt2)
            trdist(distance trpt1 trpt2)
            trdata(xdataget trent _TRAY)
            ;trflng (nth 7 trdata)
            trflng (if (< (nth 7 trdata) 0) 0.0 (nth 7 trdata))
            trsize(+ (* _PLOTSCALE (nth trtype_ref trdata)) trflng)
            trpt3 (polar trpt1 (- trang (* PI 0.5)) (* trsize 0.5))
            trpt4 (polar trpt3 trang trdist)
            trpt5 (polar trpt4 (+ trang (* PI 0.5)) trsize)
            trpt6 (polar trpt5 (+ trang PI) trdist)
      )                
      (xdstrip trent _DOUBLE)
      (setq clay (getvar "CLAYER"))
      (if (not (tblsearch "layer" (nth 0 _MEDTRAY)))
        (progn
          (smlayer _MEDTRAY)
          (setvar "CLAYER" clay)
        )
      )
      (setq CR_LAYER (nth 0 _MEDTRAY))
      (MEDPlineMake (list trpt3 trpt4 trpt5 trpt6) T (dxf 38 trentdata) trentOCS)
      ;(MEDPlineMake (list trpt3 trpt4 trpt5 trpt6) T nil trentOCS)
      (xdrtray (entlast) trent)
      
    )
  )
  (setvar "ELEVATION" mtrayelev)
)
(defun xdrtray (xdrelent1 xdmainent / handmdata handr1data
;                xdrelent1 rent1data 
;                 rxdadd mentdata mxdadd
                )
   (setq handr1data (dxf 5 (entget xdrelent1)))
   (setq mentdata (entget xdmainent (list "MED_*"))
         mxdadd   (list '(1002 . "}"))
   )
   (if _VERTICALTRAY
      (setq mxdadd(cons (cons 1000 "VERTICAL") mxdadd))
   )
   (setq mxdadd   (cons (cons 1000 handr1data) mxdadd)
         mxdadd   (cons '(1002 . "{") mxdadd)
         mxdadd   (cons _DOUBLE  mxdadd)
         mxdadd   (cons -3 (cons mxdadd (cdr (assoc -3 mentdata))))
         mentdata (subst mxdadd (assoc -3 mentdata) mentdata)
   )
   (if _RESETVTRAY
      (setq _VERTICALTRAY nil
            _RESETVTRAY   nil
      )
   )
   (entmod mentdata) 
)

(defun MEDMTray90( tr_vert trfitcd / tr_data intpt tr_ss srtent bul tr_size
                   tr_dpth tr_tag troff br_len br_tr_list genang
                   tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8)
  (med_force_2d_wireframe)
  (if _CHANTEE
     (setq trsize _CHANSIZE
           trdpth _CHANDEPTH
           trflng 0.0
           
     )
     (setq trsize _TRSIZE
           trdpth _TRDEPTH
           trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE) 
           ;trflng _TRAYFLANGE
     )
  )
  (setq medprmpt (strcat "\nSelect Insertion Point for "
                         (clookup (+ trfitcd _TRFITTADD) trsize _FITTING)
                         ": "
                 )
        intpt(getpoint medprmpt)
        TR_MAIN nil
        tr_ss(ssget "c" intpt intpt)
        srtent  (getvar "SORTENTS")
        bul     (med_tan (* (* PI 0.5) 0.25))
        mtray90elev (getvar "ELEVATION")
  )
  (setvar "ELEVATION" (caddr intpt))
  (setvar "SORTENTS" 0)
  (setq tr_data nil)
  (if tr_ss
        (setq tr_data (get_tray_data tr_ss))
  )
  (if tr_data
    (progn
      (traychck intpt)
      (setq tr_size (nth 0 tr_data)
            tr_dpth (nth 3 tr_data)
            tr_tag  (nth 1 tr_data)
            trflng (if (< (nth 10 tr_data) 0) 0.0 (nth 10 tr_data)) 
            ;trflng  (nth 10 tr_data)
      )
      (if tr_vert
          (setq troff   (* tr_dpth 0.5))
          (setq troff   (* tr_size 0.5))
      )
      (setq br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
            br_tr_list (list br_len 0.0 0.0 br_len 24)
            genang (tray_brk_rot intpt br_tr_list)

      )
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: ")
            tr_size trsize
            tr_dpth trdpth
            tr_tag  (get_con_tag)
      )
      (if tr_vert
          (setq troff (* tr_dpth 0.5))
          (setq troff (* tr_size 0.5))
      )
      (setq br_len  (+ _TRRAD troff _TRTANFAC))
    )
  )
  (if tr_vert
     (setq pt_gen tr_dpth)
     (setq pt_gen (+ tr_size trflng))
  )
  (setq tpt    (polar intpt genang (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt1    (polar tpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt2    (polar pt1 (- genang (* PI 0.5)) (* _PLOTSCALE pt_gen))
        prpt1  tpt
        pt3    (polar pt2 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt (- genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        prpt2  tpt
        pt5    (polar tpt genang (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt4    (polar pt5 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        pt6    (polar pt5 (+ genang PI) (* _PLOTSCALE pt_gen))
        pt7    (polar pt6 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        pt8    (polar pt1 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        prpt1a (be pt3 pt8)
        prpt2a (be pt4 pt7)
  )
  (setq mlist  (list (list pt1 nil)
                     (list pt2 nil)
                     (list pt3 bul)
                     (list pt4 nil)
                     (list pt5 nil)
                     (list pt6 nil)
                     (list pt7 (- bul (* bul 2)))
                     (list pt8 nil)
               )
  )
  (MEDMakeTray mlist T nil nil)
  ;(maketray mlist T nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list (list prpt1 nil)
                    (list prpt1a bul)
                    (list prpt2a nil)
                    (list prpt2 nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)
  ;(maketray mlist nil _MEDCENLAY)
  (setq xdlist (bld_fitting (+ trfitcd _TRFITTADD) tr_size tr_tag nil tr_dpth _TRAYFLANGE))
  (xdatadd (entlast) xdlist)
  (setvar "SORTENTS" srtent)
  (setvar "ELEVATION" mtray90elev)
  (princ)
  
)

(defun C:TRAY90( / trfitcd)
  (med_cur_set "C:TRAY90")
  (setq trfitcd (+ _TRFITSTRT 4))
  (MEDMTray90 nil trfitcd)
  (med_ret_ok)
  (princ)
)

(defun c:vtray90( / fittype trfitcd)
  (med_cur_set "c:vtray90")
  (initget "Inside Outside")
  (setq fittype (getkword "\nInside or <Outside>: "))
  (if (or (not fittype) (= "Outside" fittype)) 
    (setq trfitcd (+ _TRFITVSTR 3))
    (setq trfitcd (+ _TRFITVSTR 0))
  )
  (MEDMTray90 T trfitcd)
  (med_ret_ok)
  (princ)
)

(defun get_tray_data(tray_ss / cnt num cmsize tray_size cmpent cmlent rtsize
                              tray_code)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     tray_ss        ||    Selection set of entities at insertion point
;;;     cnt            ||    counter variable
;;;     num            ||    selection set length
;;;     cmsize         ||    size stored in base entity
;;;     tray_size      ||    size of tray_duit set to equal cmsize
;;;     cmpent         ||    compare entity name for filtering therough sset
;;;     cmlent         ||    entity name to be used as base entity
;;;     rtsize         ||    list of data to be returned to calling function
;;;     tray_code      ||    tray_duit code used in xdata

   (setq num (sslength tray_ss)
         cnt 0
         cmsize 0
         cssize 100
   )
   (while (< cnt num)
     (setq cmpent (ssname tray_ss cnt)
           tray_size(xdataget cmpent _TRAY)
     )
     (if (not tray_size)
        (progn
          (setq tray_size (xdataget cmpent _FITTING))
        )
     )
     (if tray_size
       (progn
         (setq tr_tag   (nth 1 tray_size)
	             tr_code  (nth 3 tray_size)
	             tr_size  (nth 2 tray_size)
	             tr_dpth  (nth 5 tray_size)
	             tr_flng  (nth 7 tray_size)

               
         )
         (if (> tr_size cmsize)
           (setq cmsize tr_size
                 cmlent cmpent
                 mxtag  tr_tag
                 mxcode tr_code
                 mxdpth tr_dpth
                 mxent  cmpent
           )
         )
         (if (< tr_size cssize)
           (setq cssize tr_size
                 cslent cmpent
                 mntag  tr_tag
                 mncode tr_code
                 mdpth  tr_dpth
                 mnent  cmpent
           )
         )

       )
     )
     (setq cnt (1+ cnt))
   )
   (if (/= cmsize 0)
       (setq rt_size (list cmsize mxtag mxcode mxdpth cssize mntag mncode mndpth mxent mnent tr_flng))
   )
   rt_size
)

(defun maketray (traylist closeflag layerset / clay vtxt sqend vtxt vert vertxt)
  (setq plin '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (67 . 0)))
  (setq clay (getvar "CLAYER"))
  (if (not layerset)
     (setq bldlayer (nth 0 _MEDTRAY)
           layerset _MEDTRAY
     )
     (setq bldlayer (nth 0 layerset))
  )
  (if (not (tblsearch "layer" bldlayer))
    (progn
       (smlayer layerset)
       (setvar "CLAYER" clay)
    )
  )
  (setq plin (append plin (list (cons 8 bldlayer))))
  (setq plin (append plin (list (cons 100 "AcDbPolyline") (cons 67 0))))
  (setq ptlistlen (length traylist)
        plin (append plin (list (cons 90 ptlistlen)))
  )
  (if closeflag
     (setq plin  (append plin (list (cons 70 1))))
  )
  (setq plin (append plin (list (cons 43 0.0) (cons 38 (getvar "ELEVATION")) (cons 39 0.0))))

  (foreach vertxt traylist
     (setq vert (cons 10 (nth 0 vertxt))
           ver1 (cons 40 0.0)
           ver2 (cons 41 0.0)
     )
     (if (nth 1 vertxt)
         (setq ver3 (cons 42 (nth 1 vertxt)))
         (setq ver3 (cons 42 0.0))
     )
     (setq plin (append plin (list vert ver1 ver2 ver3)))
  )
  (if _ZFLAG
    (setq twoten (cons 210 (list 0.0 -1.0 0.0))
          plin (append plin (list twoten))
    )
  )
  (entmake plin)
)   

(defun trayang( inclang trfitcd tr_dat_lst / tr_data trsize trdpth tr_tag trflng medprmpt genang angpol intpt
		                                     tr_size tr_dpth tr_tag troff br_len bul tpt1 tcen tpt2 pt1 pt2 tpt
		                                     pt3 pt4 pt5 pt6 pt7 pt8 prpt1 prpt1a prpt2 prpt2a mlist tvar
		      )
  (med_force_2d_wireframe)
  (if tr_dat_lst
   (setq trsize (nth 0 tr_dat_lst)
         trdpth (nth 1 tr_dat_lst)
         tr_tag (nth 2 tr_dat_lst)
         trflng (if (< (nth 3 tr_dat_lst) 0) 0.0 (nth 3 tr_dat_lst))
         ;trflng (nth 3 tr_dat_lst)
   )
   (progn
    (if _CHANTEE
       (setq trsize _CHANSIZE
             trdpth _CHANDEPTH
             trflng 0.0
       )
       (setq trsize _TRSIZE
             trdpth _TRDEPTH
             trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
             ;trflng _TRAYFLANGE
       )
    )
   )
  )
  (if _MEDTRAYPT
    (setq intpt _MEDTRAYPT)
    (progn 
      (setq medprmpt (strcat "\nSelect Insertion Point for "
                             (clookup (+ trfitcd _TRFITTADD) trsize _FITTING)
                             ": "
                     )
            intpt(getpoint medprmpt)
      )
    )
  )
  ;(setq trayangelev (getvar "ELEVATION"))
  ;(setvar "ELEVATION" (caddr intpt))
  (if _MEDTRAYANG
    (setq genang _MEDTRAYANG
          angpol _ANGPOL
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: "))
      (initget "+ -")
      (setq angpol (getkword "Positive or Negative degrees <+>/-: "))
      (if (or (not angpol) (= angpol "+"))
        (setq angpol 1)
        (setq angpol -1)
      )
    )
  )
  (setq tr_size trsize
        tr_dpth trdpth
  )
  (if (not tr_tag)
      (setq tr_tag  (get_con_tag))
  )
  (if _VERTICALTRAY
     (setq troff (* tr_dpth 0.5))
     (setq troff (* tr_size 0.5))
  )
  (setq br_len  (+ _TRRAD troff _TRTANFAC)
        bul     (med_tan (* inclang 0.25))
  )
  
  (setq tpt1   (polar intpt genang (* _PLOTSCALE _TRTANFAC))
        tcen   (polar tpt1  (+ genang (* angpol (* PI 0.5))) (* _PLOTSCALE (+ _TRRAD troff)))
        tpt2   (polar tcen  (+ (angle tcen tpt1) (* angpol inclang)) (* _PLOTSCALE (+ _TRRAD troff)))
        pt1    (polar intpt (- genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt2    (polar pt1   genang (* _PLOTSCALE _TRTANFAC))
        tpt    (polar tpt2  (+ genang (* angpol inclang)) (* _PLOTSCALE _TRTANFAC))
        tang   (angle tpt2  tpt)
        pt4    (polar tpt   (- tang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt3    (polar pt4   (+ tang PI) (* _PLOTSCALE _TRTANFAC))
        pt5    (polar tpt   (+ tang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt6    (polar pt5   (+ tang PI) (* _PLOTSCALE _TRTANFAC))
        pt8    (polar intpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt7    (polar pt8   genang (* _PLOTSCALE _TRTANFAC))
        prpt1  (be pt1 pt8)
        prpt1a (be pt2 pt7)
        prpt2  (be pt4 pt5)
        prpt2a (be pt3 pt6)
  )
  (setq mlist  (list (list pt1 nil)
                     (list pt2 (* bul angpol))
                     (list pt3 nil)
                     (list pt4 nil)
                     (list pt5 nil)
                     (list pt6 (* (- bul (* bul 2)) angpol)) 
                     (list pt7 nil)
                     (list pt8 nil)
               )
  )
  (if (not tvar)
    (setq tvar mlist)
  )
  (if _PTONLY
     (setq _TRAYFITPTLIST (list pt4 pt5 (+ trfitcd _TRFITTADD)
                                         tr_size tr_tag nil tr_dpth pt1 pt8 trflng))
     (progn
     	 (MEDMakeTray mlist T nil nil)
       ;(maketray mlist T nil)
       (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
       (setq mlist (list (list prpt1 nil)
                         (list prpt1a (* bul angpol))
                         (list prpt2a nil)
                         (list prpt2 nil)
                   )
       )
       (MEDMakeTray mlist nil _MEDCENLAY nil)
       ;(maketray mlist nil _MEDCENLAY)
       (setq xdlist (bld_fitting (+ trfitcd _TRFITTADD) tr_size tr_tag nil tr_dpth (if tr_dat_lst (nth 3 tr_dat_lst) _TRAYFLANGE)))
       (xdatadd (entlast) xdlist)
     )
  )
  ;(setvar "ELEVATION" trayangelev)
  (princ)
)
(defun MEDMakeTrayFitOutline(MEDTrayTeeEntity)
   
(princ)	
)
(defun c:traytee( / tr_data intpt tr_ss bul srtent trfitcd tr_size
                    tr_dpth tr_tag troff br_len br_tr_list genang
                    tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 
                    mlist xdlist)
  (med_cur_set "c:traytee")
  (medts_begin "TRAYTEE")
  (if _CHANTEE
     (setq trfitcd (+ _CHANFITST 16)
           trprsz _CHANSIZE
           trflng 0.0
     )
     (setq trfitcd (+ _TRFITSTRT 16)
           trprsz _TRSIZE
           trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
           ;trflng _TRAYFLANGE
     )
  )

  (setq medprmpt (strcat "\nSelect Insertion Point for "
                         (clookup (+ trfitcd _TRFITTADD) trprsz _FITTING)
                         ": "
                 )
        intpt(getpoint medprmpt)
        trayteeelev (getvar "ELEVATION")
        TR_MAIN nil
        tr_ss(ssget "c" intpt intpt)
        bul     (med_tan (* (* PI 0.5) 0.25))
        srtent  (getvar "SORTENTS")
  )
  (setvar "ELEVATION" (caddr intpt))
  (setvar "SORTENTS" 0)
  (if tr_ss
        (setq tr_data (get_tray_data tr_ss))
  )
  (if tr_data
    (progn
      (medts_prepick intpt tr_ss T)
      (traychck intpt)
      (setq tr_data (get_tray_data (medts_data_ss tr_ss))
            tr_size (nth 0 tr_data)
            tr_dpth (nth 3 tr_data)
            tr_tag  (nth 1 tr_data)
            troff   (* tr_size 0.5)
            trflng (if (< (nth 10 tr_data) 0) 0.0 (nth 10 tr_data))
            ;trflng  (nth 10 tr_data)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
            br_tr_list (list br_len br_len 0.0 br_len 3)
            genang (medts_brk_rot intpt br_tr_list)
      )
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: "))
      (if _CHANTEE
         (setq tr_size _CHANSIZE
               tr_dpth _CHANDPTH
         )
         (setq tr_size _TRSIZE
               tr_dpth _TRDEPTH
         )
      )
      (setq tr_tag  (get_con_tag)
            troff   (* tr_size 0.5)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
      )
    )
  )
  (setq _CHANTEE nil)
  (setq tpt    (polar intpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt1    (polar tpt (+ genang PI) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt2    (polar pt1 genang (* _PLOTSCALE (+ tr_size trflng)))
        pt3    (polar pt2 (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt genang (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt5    (polar tpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt4    (polar pt5 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        pt6    (polar pt5 (- genang (* PI 0.5)) (* _PLOTSCALE (+ tr_size trflng)))
        pt7    (polar pt6 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt (- genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt9    (polar tpt genang (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt8    (polar pt9 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        pt10   (polar pt9 (+ genang PI) (* _PLOTSCALE (+ tr_size trflng)))
        prpt1  (be pt1 pt2)
        prpt1a (polar prpt1 (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        prpt3  (be pt5 pt6)
        prpt3a (polar prpt3 (- genang PI) (* _PLOTSCALE _TRTANFAC))
        prpt2  (be pt9 pt10)
        prpt2a (polar prpt2 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
  )
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  bul)
                     (list pt4  nil)
                     (list pt5  nil)
                     (list pt6  nil)
                     (list pt7  bul)
                     (list pt8  nil)
                     (list pt9  nil)
                     (list pt10 nil)
               )
  )
  (MEDMakeTray mlist T nil nil)
  ;(maketray mlist T nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list (list prpt1 nil)
                    (list prpt1a bul)
                    (list prpt3a nil)
                    (list prpt3  nil)
                    (list prpt3a bul)
                    (list prpt2a nil)
                    (list prpt2 nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)
  ;(maketray mlist nil _MEDCENLAY)
  (setq xdlist (bld_fitting (+ trfitcd _TRFITTADD) tr_size tr_tag nil tr_dpth _TRAYFLANGE))
  (xdatadd (entlast) xdlist)
  (setvar "SORTENTS" srtent)
  (setvar "ELEVATION" trayteeelev)
  (medts_end)
  (med_ret_ok)
  (princ)
)

(defun c:traycross( / tr_data intpt tr_ss srtent bul trfitcd tr_size
                      tr_dpth tr_tag troff br_len br_tr_list genang
                      tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10
                      pt11 pt12 pt13 pt14 pt15 pt16 mlist xdlist)
  (med_cur_set "c:traycross")
  (medts_begin "TRAYCROSS")
  (if _CHANTEE
     (setq trfitcd (+ _CHANFITST 19)
           trprsz  _CHANSIZE
           trflng 0.0
     )
     (setq trfitcd (+ _TRFITSTRT 19)
           trprsz  _TRSIZE
           trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
           ;trflng _TRAYFLANGE
     )
  )
  (setq medprmpt (strcat "\nSelect Insertion Point for "
                         (clookup (+ trfitcd _TRFITTADD) trprsz _FITTING)
                         ": "
                 )
        intpt(getpoint medprmpt)
        traycrosselev (getvar "ELEVATION")
        TR_MAIN nil
        tr_ss(ssget "c" intpt intpt)
        srtent  (getvar "SORTENTS")
        bul     (med_tan (* (* PI 0.5) 0.25))
  )
  (setvar "SORTENTS" 0)
  (setvar "ELEVATION" (caddr intpt))
  (if tr_ss
        (setq tr_data (get_tray_data tr_ss))
  )
  (if tr_data
    (progn
      (medts_prepick intpt tr_ss nil)
      (traychck intpt)
      (setq tr_data (get_tray_data (medts_data_ss tr_ss))
            tr_size (nth 0 tr_data)
            tr_dpth (nth 3 tr_data)
            tr_tag  (nth 1 tr_data)
            troff   (* tr_size 0.5)
            trflng (if (< (nth 10 tr_data) 0) 0.0 (nth 10 tr_data))
            ;trflng  (nth 10 tr_data)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
            br_tr_list (list br_len br_len br_len br_len 1)
            genang (medts_brk_rot intpt br_tr_list)
      )
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: "))
      (if _CHANTEE
         (setq tr_size _CHANSIZE
               tr_dpth _CHANDPTH
         )
         (setq tr_size _TRSIZE
               tr_dpth _TRDEPTH
         )
      )
      (setq tr_tag  (get_con_tag)
            troff   (* tr_size 0.5)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
      )
    )
  )
  (setq _CHANTEE nil)
  (setq tpt    (polar intpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt1    (polar tpt   (+ genang PI) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt2    (polar pt1   genang (* _PLOTSCALE (+ tr_size trflng)))
        pt3    (polar pt2   (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt genang (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt5    (polar tpt   (+ genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt4    (polar pt5   (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        pt6    (polar pt5   (- genang (* PI 0.5)) (* _PLOTSCALE (+ tr_size trflng)))
        pt7    (polar pt6   (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt (- genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt9    (polar tpt   genang (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt8    (polar pt9   (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        pt10   (polar pt9   (+ genang PI) (* _PLOTSCALE (+ tr_size trflng)))
        pt11   (polar pt10  (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt (+ genang PI) (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt13   (polar tpt   (- genang (* PI 0.5)) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt12   (polar pt13  genang (* _PLOTSCALE _TRTANFAC))
        pt14   (polar pt13  (+ genang (* PI 0.5)) (* _PLOTSCALE (+ tr_size trflng)))
        pt15   (polar pt14  genang (* _PLOTSCALE _TRTANFAC))
        pt16   (polar pt1   (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        prpt1  (be pt1 pt2)
        prpt1a (polar prpt1 (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC) )
        prpt3  (be pt5 pt6)
        prpt3a (polar prpt3 (- genang PI) (* _PLOTSCALE _TRTANFAC))
        prpt2  (be pt9 pt10)
        prpt2a (polar prpt2 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        prpt4  (be pt13 pt14)
        prpt4a (polar prpt4 genang (* _PLOTSCALE _TRTANFAC))

  )
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  bul)
                     (list pt4  nil)
                     (list pt5  nil)
                     (list pt6  nil)
                     (list pt7  bul)
                     (list pt8  nil)
                     (list pt9  nil)
                     (list pt10 nil)
                     (list pt11 bul)
                     (list pt12 nil)
                     (list pt13 nil)
                     (list pt14 nil)
                     (list pt15 bul)
                     (list pt16 nil)
               )
  )
  (MEDMakeTray mlist T nil nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list (list prpt1 nil)
                    (list prpt1a bul)
                    (list prpt3a nil)
                    (list prpt3  nil)
                    (list prpt3a bul)
                    (list prpt2a nil)
                    (list prpt2 nil)
                    (list prpt2a bul)
                    (list prpt4a nil)
                    (list prpt4 nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)

  (setq xdlist (bld_fitting (+ trfitcd _TRFITTADD) tr_size tr_tag nil tr_dpth _TRAYFLANGE))
  (xdatadd (entlast) xdlist)
  (setvar "SORTENTS" srtent)
  (setvar "ELEVATION" traycrosselev)
  (medts_end)
  (med_ret_ok)
  (princ)
)

(defun c:trayre( / tr_data intpt tr_ss srtent bul tr_lsize tr_dpth
                   tr_tag tr_loff tr_ssize tr_soff br_len1 br_len2
                   traydt testent testpt genang tang sizelst redlst
                   tpt pt1 pt2 pt8 pt7 pt4 pt3 pt5 pt6 mlist xdlist)
  (med_cur_set "c:trayre")

  (setq intpt(getpoint "\nSelect insertion point: ")
	trayreelev (getvar "ELEVATION")
        TR_MAIN nil
        tr_ss   (ssget "c" intpt intpt)
        srtent  (getvar "SORTENTS")
        bul     (med_tan (* (* PI 0.5) 0.25))
  )
  (setvar "SORTENTS" 0)
  (setvar "ELEVATION" (caddr intpt))
  (if tr_ss
        (setq tr_data (get_tray_data tr_ss))
  )
  (if tr_data
    (progn
      (traychck intpt)
      (setq tr_data  (get_tray_data tr_ss)
            tr_lsize (nth 0 tr_data)
            tr_dpth (nth 3 tr_data)
            tr_tag   (nth 1 tr_data)
            tr_loff  (* tr_lsize 0.5)
            trflng (if (< (nth 10 tr_data) 0) 0.0 (nth 10 tr_data))
            ;trflng  (nth 10 tr_data)
            tr_ssize (nth 4 tr_data)
            tr_soff  (* tr_ssize 0.5)
            br_len1  (* _PLOTSCALE 9.0)
            br_len2  (* _PLOTSCALE 9.0)
            traydt (xdataget (nth 8 tr_data) _TRAY)
      )
      (if traydt
        (progn
          (setq testent (nth 8 tr_data)
                testpt  (opposite_tray_endpt testent intpt)
          )
	  
          (setq genang (angle intpt testpt))
        )
        (progn
          (setq testent (nth 8 tr_data)
                testpt  (opposite_tray_endpt testent intpt)
          )
          (setq genang (getangle intpt "\nAngle to reduce to: ")
		genang (+ genang PI);(angle testpt intpt)
                br_len1 (* _PLOTSCALE 0.0)
                br_len2 (* _PLOTSCALE 18.0)
          )
        )
      )
      (setq br_tr_list (list br_len1 0.0 br_len2 0.0 0)
            _TANG  genang
            tang   (tray_brk_rot intpt br_tr_list)
            _TANG  nil
      )
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: ")
            tr_lsize _TRSIZE
            tr_dpth _TRDEPTH
            trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
            ;trflng _TRAYFLANGE
            tr_tag  (get_con_tag)
            tr_loff (* tr_lsize 0.5)
            tr_ssize 100.0
            br_len1 (* _PLOTSCALE 9.0)
            br_len2 (* _PLOTSCALE 9.0)
            sizelst (list 4.0 6.0 9.00 12.00 18.00 24.00 30.0 36.0 42.0 48.0)
            redlst  (reverse (cdr (member tr_lsize (reverse sizelst))))
      )
      (while (not (member tr_ssize redlst))
          (prompt "\nSize may not be larger than current size.")
          (initget 1)
          (setq tr_ssize (getreal "\nSize to Reduce to: "))
      )
      (setq tr_soff (* tr_ssize 0.5))
    )

  )
  (setq tpt    (polar intpt genang br_len1)
        pt1    (polar tpt   (- genang (* PI 0.5)) (* _PLOTSCALE (+ tr_loff (* trflng 0.5))))
        pt2    (polar pt1   (+ genang PI) (* _PLOTSCALE 7.0))
        pt8    (polar tpt   (+ genang (* PI 0.5)) (* _PLOTSCALE (+ tr_loff (* trflng 0.5))))
        pt7    (polar pt8   (+ genang PI) (* _PLOTSCALE 7.0))
        tpt    (polar intpt (+ genang PI) br_len2)
        pt4    (polar tpt   (- genang (* PI 0.5)) (* _PLOTSCALE (+ tr_soff (* trflng 0.5))))
        pt3    (polar pt4   genang (* _PLOTSCALE 7.0))
        pt5    (polar tpt   (+ genang (* PI 0.5)) (* _PLOTSCALE (+ tr_soff (* trflng 0.5))))
        pt6    (polar pt5   genang (* _PLOTSCALE 7.0))
  )
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  nil)
                     (list pt4  nil)
                     (list pt5  nil)
                     (list pt6  nil)
                     (list pt7  nil)
                     (list pt8  nil)
               )
  )
  
  (MEDMakeTray mlist T nil nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)

  (setq mlist (list (list (be pt1 pt8) nil)
                    (list (be pt4 pt5) nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)

  (setq xdlist (bld_fitting _TRFITSTRT tr_lsize tr_tag tr_ssize _TRDEPTH (if tr_data (nth 10 tr_data) _TRAYFLANGE)))
  (xdatadd (entlast) xdlist)
  (setvar "SORTENTS" srtent)
  (setvar "ELEVATION" trayreelev)
  (med_ret_ok)
  
  (princ)
)

(defun traylrre( reang fittcode / tr_data)
  (med_force_2d_wireframe)
  (setq intpt(getpoint "\nSelect insertion point: ")
	traylrreelev (getvar "ELEVATION")
  )
  (setvar "ELEVATION" (caddr intpt))
  (initget 1)
  (setq genang (getangle intpt "\nAngle of generation: ")
        tr_lsize _TRSIZE
        tr_dpth _TRDEPTH
        tr_tag  (get_con_tag)
        trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
        ;trflng _TRAYFLANGE
        tr_loff (* tr_lsize 0.5)
        tr_ssize 100.0
        br_len1 (* _PLOTSCALE 18.0)
        sizelst (list 1.626 1.75 4.0 6.0 9.00 12.00 18.00 24.00 30.0 36.0 42.0 48.0)
        redlst  (reverse (cdr (member tr_lsize (reverse sizelst))))
  )
  (if (= reang PI)
     (setq reang (+ genang (* PI 0.5)))
     (setq reang (- genang (* PI 0.5)))
  )
  (while (not (member tr_ssize redlst))
      (prompt "\nSize may not be larger than current size.")
      (initget 1)
      (setq tr_ssize (getreal "\nSize to Reduce to: "))
  )
  (setq tr_soff (* tr_ssize 0.5))
  (setq pt1    (polar intpt reang (* _PLOTSCALE (+ tr_loff (* trflng 0.5))))
        pt2    (polar pt1   genang br_len1)
        pt3    (polar pt2   (+ reang PI) (* _PLOTSCALE (+ tr_ssize trflng)))
        pt4    (polar pt3   (+ genang PI) (* _PLOTSCALE 7.0))
        pt6    (polar intpt (+ reang PI) (* _PLOTSCALE (+ tr_loff (* trflng 0.5))))
        pt5    (polar pt6   genang (* _PLOTSCALE 7.0))
  )
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  nil)
                     (list pt4  nil)
                     (list pt5  nil)
                     (list pt6  nil)
               )
  )
  (MEDMakeTray mlist T nil nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  
  (setq mlist (list (list (be pt1 pt6) nil)
                    (list (be pt2 pt3) nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)

  (setq xdlist (bld_fitting fittcode tr_lsize tr_tag tr_ssize _TRDEPTH _TRAYFLANGE))
  (xdatadd (entlast) xdlist)
  (setvar "ELEVATION" traylrreelev)
)

(defun mtray(trent)
  (setq trtype_ref 2
	mtrayelev (getvar "ELEVATION")
	trentdata (entget trent)
  )
  (setvar "ELEVATION" (dxf 38 trentdata))
  (if _VERTICALTRAY
     (setq trtype_ref 5)
  )
  (if (setq origtype (xdataget trent _DOUBLE))
     (progn
        (if (member "VERTICAL" origtype)
           (progn
             (if (not _VERTICALTRAY)
                (setq _VERTICALTRAY T
                      _RESETVTRAY T
                      trtype_ref 5
                )   
                (setq trtype_ref 5)
             )
           )
        )
     )
  )
  (if (dxf -3 (entget trent (list _TRAY)))
    (progn
      (if (= (dxf 0 (entget trent)) "LWPOLYLINE")
        (setq ptlist (bld_lw_ptlist trent)
              trpt1  (cdr (nth 0 (nth 0 ptlist)))
              trpt2  (cdr (nth 1 (nth 0 ptlist)))
        )
        (setq trd1 (entget (entnext (dxf -1 (entget trent))))
              trd2 (entget (entnext (dxf -1 trd1)))
              trpt1(dxf 10 trd1)
              trpt2(dxf 10 trd2)
        )
      )
      (setq trang (angle trpt1 trpt2)
            trdist(distance trpt1 trpt2)
            trdata(xdataget trent _TRAY)
            trflng (if (< (nth 7 trdata) 0) 0.0 (nth 7 trdata))
            ;trflng  (nth 7 trdata)
            trsize(+ (* _PLOTSCALE (nth trtype_ref trdata)) trflng)
            trpt3 (polar trpt1 (- trang (* PI 0.5)) (* trsize 0.5))
            trpt4 (polar trpt3 trang trdist)
            trpt5 (polar trpt4 (+ trang (* PI 0.5)) trsize)
            trpt6 (polar trpt5 (+ trang PI) trdist)
      )                
      (xdstrip trent _DOUBLE)
      (setq clay (getvar "CLAYER"))
      (if (not (tblsearch "layer" (nth 0 _MEDTRAY)))
        (progn
          (smlayer _MEDTRAY)
          (setvar "CLAYER" clay)
        )
      )
      (setq CR_LAYER (nth 0 _MEDTRAY))
      (pmake (list trpt3 trpt4 trpt5 trpt6) T)
      (xdrtray (entlast) trent)
    )
  )
  (setvar "ELEVATION" mtrayelev)
)

;;; 2026-10-27 UCS fix (rev c): before TRAYFIX rebuilds, switch to the
;;; picked object's UCS (UCS Object), then shift the origin back to the WCS
;;; origin along that plane so the stored OCS elevation (code 38) still matches
;;; ELEVATION. Flat (0,0,1) and World-vertical (0,-1,0) objects use World,
;;; which is how they already worked. No-op in World for those objects.
;;; MEDTrayFixUCSEnd restores the user's UCS.
(defun MEDTrayFixUCSBegin (ment / n210 ce worldplanar)
  (setq MEDTrayFixUCSSet nil
        n210 (cdr (assoc 210 (entget ment)))
        worldplanar (or (null n210)
                        (equal n210 '(0.0 0.0 1.0) 1e-9)
                        (equal n210 '(0.0 -1.0 0.0) 1e-9))
  )
  (if (not (and worldplanar (= (getvar "WORLDUCS") 1)))
    (progn
      (setq ce (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (if (tblsearch "UCS" "MEDFixTmp")
        (command "_.UCS" "_NA" "_D" "MEDFixTmp")
      )
      (command "_.UCS" "_NA" "_S" "MEDFixTmp")
      (if worldplanar
        (command "_.UCS" "_W")
        (progn
          (command "_.UCS" "_OB" ment)
          (command "_.UCS" "_O" (trans '(0.0 0.0 0.0) 0 1))
        )
      )
      (setvar "CMDECHO" ce)
      (setq MEDTrayFixUCSSet T)
    )
  )
)
(defun MEDTrayFixUCSEnd ( / ce)
  (if MEDTrayFixUCSSet
    (progn
      (setq ce (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (command "_.UCS" "_NA" "_R" "MEDFixTmp")
      (command "_.UCS" "_NA" "_D" "MEDFixTmp")
      (setvar "CMDECHO" ce)
      (setq MEDTrayFixUCSSet nil)
    )
  )
)

(defun c:trayfix()
  (setq trayfixent (entsel "\nSelect Tray to fix:"))
  (if trayfixent
    (progn
      (setq trayfixent (car trayfixent)
	    trayfixentdata (entget trayfixent)
	    trayfixelev (getvar "ELEVATION")
      )
      (MEDTrayFixUCSBegin trayfixent)
      (setvar "ELEVATION" (dxf 38 trayfixentdata))
      (setq trayentdata (xdataget trayfixent _TRAY))
      (if trayentdata
	   (progn
	      (MEDTrayOutline trayfixent)
	      (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
	   )
      )
      (setq trayentdata (xdataget trayfixent _FITTING))
      (princ ".")
      (if trayentdata
	   (progn
	      (mtrayfit trayfixent trayentdata nil)
	      (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
	   )
      )
      (MEDTrayFixUCSEnd)
      (setvar "ELEVATION" trayfixelev)
    )
    (princ "Nothing Selected!")
  )
  (princ)
)

;;; 2026-10-27 UCS fix: return the opposite end of a picked tray pline in the
;;; CURRENT UCS (2D, like opposite_tray_endpt). LWPOLYLINE vertices are OCS, so
;;; they are run through trans with the entity. Identical result in World UCS.
(defun MEDTrayOppEndUCS (ment pickpt / mdata mpts p1 p2)
  (setq mdata (entget ment))
  (if (= (cdr (assoc 0 mdata)) "LWPOLYLINE")
    (progn
      (setq mpts (car (bld_lw_ptlist ment))
            p1 (cdr (car mpts))
            p2 (cdr (last mpts))
            p1 (trans (list (car p1) (cadr p1) (cdr (assoc 38 mdata))) ment 1)
            p2 (trans (list (car p2) (cadr p2) (cdr (assoc 38 mdata))) ment 1)
      )
      (if (< (distance (list (car p1) (cadr p1)) (list (car pickpt) (cadr pickpt)))
             (distance (list (car p2) (cadr p2)) (list (car pickpt) (cadr pickpt))))
        (list (car p2) (cadr p2))
        (list (car p1) (cadr p1))
      )
    )
    (opposite_tray_endpt ment pickpt)
  )
)

;;; 2026-10-27 UCS fix: entities built with raw entmake from UCS-style
;;; coordinates land relative to World. Move them into the current UCS.
;;; No-op when the current UCS is World.
(defun MEDXformEntToUCS (ment / ux uy uz uo)
  (if (and ment (= (getvar "WORLDUCS") 0))
    (progn
      (vl-load-com)
      (setq ux (trans '(1.0 0.0 0.0) 1 0 T)
            uy (trans '(0.0 1.0 0.0) 1 0 T)
            uz (trans '(0.0 0.0 1.0) 1 0 T)
            uo (trans '(0.0 0.0 0.0) 1 0)
      )
      (vla-TransformBy (vlax-ename->vla-object ment)
        (vlax-tmatrix
          (list (list (car ux) (car uy) (car uz) (car uo))
                (list (cadr ux) (cadr uy) (cadr uz) (cadr uo))
                (list (caddr ux) (caddr uy) (caddr uz) (caddr uo))
                '(0.0 0.0 0.0 1.0))))
    )
  )
  ment
)

(defun c:trayoff()
   (setq en1 (entsel "\nSelect First Entity: ")
         e1pt1 (osnap (cadr en1) "END")
         e1pt2 (MEDTrayOppEndUCS (car en1) e1pt1)
         disty (getpoint e1pt1 "\nDistance of Offset: ")
         angdir(angle e1pt1 disty)
         disty (distance disty e1pt1)
         troffss (ssadd (car en1))
         tr_data (get_tray_data troffss)
	     trayoffelev (getvar "ELEVATION")
   )
   (setvar "ELEVATION" (caddr e1pt1))
   (if tr_data
     (progn
       (setq offsize (nth 0 tr_data)
       	     offcode (nth 2 tr_data)
             offdpth (nth 3 tr_data)
             offtag  (nth 1 tr_data)
             offflng (nth 10 tr_data)
       )
     )
     (progn 
       (if _CHANTEE
          (setq offsize _CHANSIZE
          	    offcode _CHANCODE
                offdpth _CHANDEPTH
                offflng 0.0
          )
          (setq offsize _TRSIZE
          	    offcode _TRCODE
                offdpth _TRDEPTH
                offflng _TRAYFLANGE
          )
       )
       (setq offtag (get_con_tag))
     )
   )
   (if (and (equal (angle e1pt2 e1pt1) (* PI 1.5)) (equal angdir 0.0))
     (setq angdir (* PI 2.0))
   )
   (if (equal (* -0.5 PI) (- (angle e1pt2 e1pt1) angdir) 0.00000001)
     (setq _ANGPOL 1)
     (setq _ANGPOL -1)
   )
   (setq tangpol _ANGPOL)
   (initget 1 "30 45 60 90")
   (setq incang (getkword "\nOffset with 30 / 45 / 60 / 90 degree angle: "))
   (cond
     ((= incang "30")
        (setq trdatalst (trayoffitt 0.1666665 13 9 18 21 41 44))
     )
     ((= incang "45")
        (setq trdatalst (trayoffitt 0.25 10 6 12 15 35 38))
     )
     ((= incang "60")
        (setq trdatalst (trayoffitt 0.33333333 7 3 6 9 29 32))
     )
     ((= incang "90")
        (setq trdatalst (trayoffitt 0.5 4 0 0 3 23 26))
     )
   )
   (if _VERTICALTRAY
    (progn
      (setq tr_off (* offdpth 0.5))
    )
    (progn
      (setq tr_off (* offsize 0.5))
    )
   )
   (setq offtrlst (list offsize offdpth offtag offflng))
   (setq incang (nth 0 trdatalst)
         degfit1(nth 1 trdatalst)
         degfit2(nth 2 trdatalst)
   )
   (setvar "lastpoint" e1pt1)
  
   (setq gen_ang (angle e1pt2 e1pt1)
         hdist (/ (* _PLOTSCALE (+ _TRRAD tr_off)) (sin (+ (* PI 1.5) (* incang 0.5))))
         xdist (abs (* hdist (cos (+ (* PI 1.5) (* incang 0.5)))))
         offstpt1 e1pt1
         e1pt1 (polar e1pt1 gen_ang (+ (* _PLOTSCALE _TRTANFAC) xdist))
         _MEDTRAYANG gen_ang
         _MEDTRAYPT  offstpt1
   )
   (trayang incang degfit1 offtrlst)
   (setq hoffd (/ disty (sin incang))
         hoffpt (polar e1pt1 (+ gen_ang (* incang _ANGPOL)) hoffd)
         offstpt2 (polar hoffpt gen_ang (+ (* _PLOTSCALE _TRTANFAC) xdist))
         _MEDTRAYANG (+ gen_ang PI)
         _MEDTRAYPT  offstpt2
   )
   (trayang incang degfit2 offtrlst)
   (setq _MEDTRAYANG nil
         _MEDTRAYPT  nil
   )
   (setq _MEDTRAYPT1 (polar e1pt1 (+ gen_ang (* incang _ANGPOL)) (+ (* _PLOTSCALE _TRTANFAC) xdist))
         _MEDTRAYPT2 (polar hoffpt (angle hoffpt e1pt1) (+ (* _PLOTSCALE _TRTANFAC) xdist))
   )
   (setq MEDCurrentTraySettings (list _TRCODE _TRTYPE _TRSIZE _TRDEPTH _TRAYFLANGE))
   (MEDSetTrayValues (list offcode 0 offsize offdpth offflng))
   (setq _MEDTAG offtag)
   (if _CHANTEE
     (c:channel)
     (c:tray)
   )
   (MEDSetTrayValues MedCurrentTraySettings)
   (setvar "ELEVATION" trayoffelev)
   (setq _MEDTRAYPT1 nil
         _MEDTRAYPT2 nil
   )
   (setq _ANGPOL nil)
)

;;; ptrayoff-tray 2026-10-29: PTRAYOFF may pre-set *MED-PTRAYOFF-DIR*
;;; ("Up"/"Down") from a second-tray pick. One-shot: consumed and cleared
;;; here so TRAYOFF / later calls always get the normal Direction prompt.
(defun MEDPtrayoffDir ( / d)
  (if *MED-PTRAYOFF-DIR*
    (setq d *MED-PTRAYOFF-DIR* *MED-PTRAYOFF-DIR* nil)
    (progn
      (initget "Up Down")
      (setq d (getkword "Direction Up/Down <Down>:"))
    )
  )
  d
)

;;; ptrayoff-tray 2026-10-29: current-UCS Z of a picked tray, nearest end to pick.
(defun MEDPtrayoffTrayZ (sel / ent pt ed z)
  (setq ent (car sel)
        pt  (osnap (cadr sel) "END"))
  (cond
    (pt (caddr pt))
    ((and ent (setq ed (entget ent)) (= (cdr (assoc 0 ed)) "LWPOLYLINE"))
       (caddr (trans (list 0.0 0.0 (cdr (assoc 38 ed))) ent 1)))
    (T nil)
  )
)

(defun trayoffitt(angmult htrcode hchcode vitrcode votrcode vichcode vochcode / rtlist)
  (setq incang (* PI angmult))
  (if _VERTICALTRAY
   (progn
    (if _CHANTEE
      (progn
	(setq voffdiroption (MEDPtrayoffDir))
	(if (or (not voffdiroption) (= voffdiroption "Down"))
	  (setq degfit1 (+ _TRFITVSTR vochcode)
                degfit2 (+ _TRFITVSTR vichcode)
	  )
	  (setq degfit1 (+ _TRFITVSTR vichcode)
                degfit2 (+ _TRFITVSTR vochcode)
          )
	)
      )
      (progn
        (setq voffdiroption (MEDPtrayoffDir))
	(if (or (not voffdiroption) (= voffdiroption "Down"))
	  (setq degfit1 (+ _TRFITVSTR votrcode)
                degfit2 (+ _TRFITVSTR vitrcode)
	  )
	  (setq degfit1 (+ _TRFITVSTR vitrcode)
                degfit2 (+ _TRFITVSTR votrcode)
	  )
	)
      )
    )
   )
   (progn
    (if _CHANTEE
      (setq degfit1 (+ _CHANFITST hchcode)
            degfit2 (+ _CHANFITST hchcode)
      )
      (setq degfit1 (+ _TRFITSTRT htrcode)
            degfit2 (+ _TRFITSTRT htrcode)
      )
    )
   )
  )
  (if (not voffdiroption)
    (setq voffdiroption "Down")
  )
  (setq rtlist (list incang degfit1 degfit2 voffdiroption))
)

(defun c:trayv90( / ); tr_data intpt tr_ss srtent bul tr_lsize tr_dpth
                    ;tr_tag tr_loff tr_ssize tr_soff br_len1 br_len2
                    ;traydt testent testpt genang tang sizelst redlst
                    ;tpt pt1 pt2 pt8 pt7 pt4 pt3 pt5 pt6 mlist xdlist)
  (med_cur_set "c:trayv90")
  (if _CHANTEE
     (setq fitcd (+ _CHANFITST 23)
           trprsz  _CHANSIZE
           trflng 0.0
     )
     (setq fitcd _TRFITVSTR
           trprsz  _TRSIZE
           trflng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
           ;trflng _TRAYFLANGE
     )
  )
  (initget "Inside Outside")
  (setq fittype (getkword "\nInside or <Outside>: "))
  (if (or (not fittype) (= "Outside" fittype)) 
		(setq trfitcd (+ fitcd 3)
			  vtrdir1 -1
		)
		(setq trfitcd (+ fitcd 0)
			  vtrdir1 1
		)
  )
  (setq medprmpt (strcat "\nSelect Insertion Point for "
                         (clookup (+ trfitcd _TRFITTADD) trprsz _FITTING)
                         ": "
                 )
        intpt(getpoint medprmpt)
        ;trayv90elev (getvar "ELEVATION")
        TR_MAIN nil
        tr_ss    (ssget "c" intpt intpt)
        srtent  (getvar "SORTENTS")
  )
  (setvar "SORTENTS" 0)
  (setvar "ELEVATION" (caddr intpt))
  (initget 1)
  (setq genang (getangle intpt "\nAngle of generation: "))
  (if _CHANTEE
     (setq tr_lsize _CHANSIZE
           tr_dpth _CHANDEPTH
     )
     (setq tr_lsize _TRSIZE
           tr_dpth _TRDEPTH
     )
  )
  (setq tr_tag  (get_con_tag)
        tr_loff (* tr_lsize 0.5)
        tr_ssize 0.0
        vertlen (+ _TRRAD _TRTANFAC tr_dpth)
        verlen  (+ _TRRAD _TRTANFAC)
  )
  (if (and _CHANTEE (not (or (not fittype) (= "Outside" fittype))))
     (setq vertlen (- vertlen _CHANDEPTH)
           verlen  (- verlen _CHANDEPTH)
     )
  )
  (setq _CHANTEE nil)
  (DrawVerticalTrayFitting (list tr_lsize tr_dpth trfitcd trflng  tr_tag) intpt genang vtrdir1 (* PI 0.5))
  ;insert function call here
  (setvar "SORTENTS" srtent)
  ;(setvar "ELEVATION" trayv90elev)
  (med_ret_ok)
  (princ)
)

(defun DrawVerticalTray (Tray_data StartPoint EndPoint TrayGenAngle VerticalDirection TrayAngle Traylength)
	(setq TraySize (nth 0 Tray_data)
		  TrayDepth (nth 1 Tray_data)
		  TrayCode (nth 2 Tray_data)
		  TrayFlange (if (< (nth 3 tray_data) 0) 0.0 (nth 3 tray_data))
		  ;TrayFlange  (nth 3 Tray_data)
		  TrayTag     (nth 4 Tray_data)
		  StartingOCS (MEDGetCurrentOCS)
		  YAxispoint (polar StartPoint (+ TrayGenAngle (* PI 0.5)) 1.0)
	)
	
	(setq WStartPoint (trans StartPoint 1 0)
		  WEndPoint   (trans EndPoint 1 0)
	)
	(command "UCS" "N" "3P" Startpoint EndPoint YAxispoint)
	(setq TrayPoint1 (trans WStartPoint 0 1)
		  TrayPoint2 (trans WEndPoint 0 1)
	)
    (setvar "ELEVATION" 0.0)
	(smlayer _MEDCENLAY)
	(MEDTray (list (list TrayPoint1 TrayPoint2) TrayCode TraySize))
	(setq xdlist (bld_tray TrayCode TraySize TrayTag nil TrayDepth "T" (nth 3 tray_data)))
	(xdatadd (entlast) xdlist)
    (MEDTrayOutline (entlast))
    (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
;	
;	;Draw the pline at 0.0 with genang of 0 then move and rotate.
;	(setq TrayOffset (+ (* TraySize 0.5) (* TrayFlange 0.5))
;		  TStartPoint (list 0.0 0.0 0.0)
;		  TTrayGenAngle 0.0
;		  TEndpoint  (polar TStartPoint (* VerticalDirection TrayAngle) TrayLength)
;	)
;	(setq _ZFLAG T)
;	(setq mlist  (list (list TStartPoint  nil)
;                       (list TEndPoint  nil)
;               )
;    )
;    (setq CurrentElevation (getvar "ELEVATION"))
;    (setvar "ELEVATION" 0.0)
;    (maketray mlist nil _MEDCENLAY)
;    (setq _ZFLAG nil)
;    (setq TrayEnt (entlast))
;    (setvar "ELEVATION" CurrentElevation)
;    (command "move" TrayEnt "" TStartPoint StartPoint)
;    (command "rotate" TrayEnt "" StartPoint (angtos TrayGenAngle 0 4))
;    (setq xdlist (bld_tray TrayCode TraySize TrayTag nil TrayDepth "T" TrayFlange))
;    (xdatadd (entlast) xdlist)
;    ;DrawOutline
;    (setq pt1 (polar StartPoint (+ TrayGenAngle (* PI 0.5)) Trayoffset)
;    	  pt2 (polar pt1 (+ TrayGenAngle (* PI -0.5)) (* Trayoffset 2.0))
;    	  pt3 (polar StartPoint TrayGenAngle (* (cos TrayAngle) TrayLength))
;    	  pt3 (polar pt3 (+ TrayGenAngle (* PI 0.5)) Trayoffset)
;    	  pt4 (polar pt3 (+ TrayGenAngle (* PI -0.5)) (* Trayoffset 2.0))
;    )
;    (setq mlist  (list (list pt1  nil)
;                     (list pt2 nil)
;                     (list pt4  nil)
;                     (list pt3  nil)
;               )
;    )
;  	(setq CurrentElevation (getvar "ELEVATION"))
;  	(setvar "ELEVATION" (nth 2 StartPoint))
;  	(maketray mlist T nil)
  	(setvar "ELEVATION" CurrentElevation)
)
    
	

(defun DrawVerticalTrayFitting (Tray_data StartPoint TrayGenAngle VerticalDirection TrayFitIncAng /
		                        TraySize TrayDepth TrayFitCode TrayFlange TrayTag PointBuldge pt1 pt2 pt3 pt4 pt5)
;Build CEnterLine
	(setq TraySize (nth 0 Tray_data)
		  TrayDepth (nth 1 Tray_data)
		  TrayFitCode (nth 2 Tray_data)
		  TrayFlange (if (< (nth 3 tray_data) 0) 0.0 (nth 3 tray_data))
		  ;TrayFlange  (nth 3 Tray_data)
		  TrayTag     (nth 4 Tray_data)
	)

;Draw the pline at 0.0 with genang of 0 then move and rotate.
	(setq TrayOffset (* TrayDepth 0.5)
		  PointBuldge (med_tan (* VerticalDirection TrayFitIncAng 0.25))
		  TStartPoint (list 0.0 0.0 0.0)
		  TTrayGenAngle 0.0
		  TempPoint1 (polar TStartPoint TTrayGenAngle (* _PLOTSCALE _TRTANFAC))
		  TempCenter (polar TempPoint1 (+ TTrayGenAngle (* VerticalDirection (* PI 0.5))) (* _PLOTSCALE (+ _TRRAD TrayOffset)))
		  TempPoint2 (polar TempCenter (+ (angle TempCenter TempPoint1) (* VerticalDirection TrayFitIncAng)) (* _PLOTSCALE (+ _TRRAD TrayOffset)))
		  pt1        (polar TStartPoint (- TTrayGenAngle (* PI 0.5)) (* _PLOTSCALE TrayOffset))
		  pt2        (polar pt1 TTrayGenAngle (* _PLOTSCALE _TRTANFAC))
		  TempPoint  (polar TempPoint2 (+ TTrayGenAngle (* VerticalDirection TrayFitIncAng)) (* _PLOTSCALE _TRTANFAC))
		  TempAngle  (angle TempPoint2 TempPoint)
		  pt4        (polar TempPoint (- TempAngle (* PI 0.5)) (* _PLOTSCALE TrayOffset))
		  pt3        (polar pt4 (+ TempAngle PI) (* _PLOTSCALE _TRTANFAC))
		  pt5        (polar TempPoint   (+ TempAngle (* PI 0.5)) (* _PLOTSCALE TrayOffset))
	)
  (setq _ZFLAG T)
  
  (setq mlist  (list (list pt1  nil)
                     (list pt2  PointBuldge)
                     (list pt3  nil)
                     (list pt4  nil)
               )
  )
  (setq CurrentElevation (getvar "ELEVATION"))
  (setvar "ELEVATION" 0.0)
  (maketray mlist nil _MEDCENLAY)
  (setq FitEnt (MEDXformEntToUCS (entlast)))
  (setvar "ELEVATION" CurrentElevation)
  (command "move" FitEnt "" (list 0.0 0.0 (* -1.0 TrayOffset)) (list (car StartPoint) (cadr StartPoint) (getvar "ELEVATION")))
  (command "rotate" Fitent "" startPoint (angtos TrayGenAngle 0 4))
  (setq FitEntPts (car (bld_lw_ptlist FitEnt))
  	    FitEntData (entget FitEnt)
        ReturnPoint (cdr (nth 0 (reverse FitEntPts)))
        ReturnPoint (append ReturnPoint (list (dxf 38 FitEntData)))
        ReturnPoint (trans ReturnPoint (dxf 210 (entget fitent)) 0)
        ReturnPoint (trans ReturnPoint 0 1)
  )
  (setq _ZFLAG nil)
  (setq xdlist (bld_fitting (+ TrayFitCode _TRFITTADD) TraySize TrayTag 0.0 TrayDepth (nth 3 Tray_data)))
  (xdatadd (entlast) xdlist)
  (addvtraydata (entlast) (list _TRRAD _TRTANFAC VerticalDirection (* PI 0.5)))
  ;Build outline
  (if (< VerticalDirection 0)
  	 (setq Overall-length (* (cos (angle pt1 pt5)) (distance pt1 pt5))
  	 	   Short-Length  (* (cos (angle pt1 pt4)) (distance pt1 pt4))
  	 )
  	 (setq Overall-length (* (cos (angle pt1 pt4)) (distance pt1 pt4))
  	  	   Short-Length  (* (cos (angle pt1 pt5)) (distance pt1 pt5))
  	 )
  )
	(setq TrayOffset (* TraySize 0.5)
		  pt1    (polar StartPoint (- TrayGenAngle (* PI 0.5)) (* _PLOTSCALE (+ TrayOffset (* TrayFlange 0.5))))
          pt2    (polar pt1   TrayGenAngle (* _PLOTSCALE Overall-length))
          pt3    (polar pt2   (+ TrayGenAngle (* PI 0.5)) (* _PLOTSCALE (+ TraySize TrayFlange)))
          pt4    (polar pt3   (+ TrayGenAngle PI) (* _PLOTSCALE Overall-length))
          pt5    (polar pt1   TrayGenAngle (* _PLOTSCALE Short-length))
          pt6    (polar pt4   TrayGenAngle (* _PLOTSCALE Short-length))
    )
  
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  nil)
                     (list pt4  nil)
               )
  )
  (maketray mlist T nil)
  (MEDXformEntToUCS (entlast))
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list pt5 pt6))
  (setq CR_LAYER (nth 0 _MEDTRAY))
  (pmake mlist nil)
  (MEDXformEntToUCS (entlast))
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list pt2 pt3 pt5 pt6))
  (setq CR_LAYER (nth 0 _MEDTRAY))
  (pmake mlist T)
  (MEDXformEntToUCS (entlast))
  (chg_tray_pl_wdth (entlast) _TR_X_WIDTH)
  (chg_ent_ltype (entlast) TR_DNLTYPE)
  returnPoint
)
(defun c:strut( / cltp clay trpt1 trpt2 trtag xdlist)
    (med_cur_set "c:strut")
    (setvar "cmdecho" 0)
    (setq cltp (getvar "celtype"))
    (ltback _LTP)
    (setq clay (getvar "CLAYER"))
    (if _MEDCENLAY
      (progn
        (if (not (tblsearch "layer" (nth 0 _MEDCENLAY)))
          (smlayer _MEDCENLAY)
          (setvar "CLAYER" clay)
        )
        (setq CR_LAYER (nth 0 _MEDCENLAY))
      )
    )
    (setq trpt1 (getpoint "\nPick start point of framing channel:")
          trpt2 (getpoint trpt1 "\nto point: ")
	  strutelev (getvar "ELEVATION")
    )
    (setvar "ELEVATION" (caddr trpt1))
    ;(pmake (list trpt1 trpt2) nil)
    (MEDPlineMake (list trpt1 trpt2) nil nil nil)
    (setq trtag "NONE")
    (setq xdlist (bld_tray _STRCODE 1.625 trtag nil 1.625 "T" 0.0))
    (xdatadd (entlast) xdlist)
;    (mtray (entlast))
    (ltback cltp)
    (princ)
    (setvar "ELEVATION" strutelev)
    (med_ret_ok)
    (terpri)
)

(defun DrawTrayVerticalX(TrayData Startpoint Genangle TrayXDistance)
	(princ)
)


;;; ptrayoff-tray 2026-10-29: "Offset distance or [Tray]:" - number/point = old
;;; distance mode (Direction still asked); Tray = pick 2nd-elev tray, disty=|Z2-Z1|,
;;; Up/Down from sign, no Direction prompt.
(defun c:ptrayoff( / en2 z2 dz)
   (setq *MED-PTRAYOFF-DIR* nil disty nil)
   (setq en1 (entsel "\nSelect First Entity: ")
         e1pt1 (osnap (cadr en1) "END")
         e1pt2 (MEDTrayOppEndUCS (car en1) e1pt1)
         troffss (ssadd (car en1))
         tr_data (get_tray_data troffss)
   )
   (while (not disty)
     (initget 6 "Tray")
     (setq disty (getdist e1pt1 "\nOffset distance or [Tray]: "))
     (cond
       ((= disty "Tray")
          (setq disty nil
                en2 (entsel "\nSelect second elevation tray: "))
          (cond
            ((not en2) (princ "\nNothing selected."))
            ((not (setq z2 (MEDPtrayoffTrayZ en2))) (princ "\nCould not read elevation of that tray."))
            ((< (abs (setq dz (- z2 (caddr e1pt1)))) 1e-6) (princ "\nSecond tray is at the same elevation."))
            (T (setq disty (abs dz)
                     *MED-PTRAYOFF-DIR* (if (> dz 0) "Up" "Down"))
               (princ (strcat "\nOffset " (rtos disty) " " *MED-PTRAYOFF-DIR*)))
          )
       )
       ((not disty) (princ "\nEnter a distance or T for Tray."))
     )
   )
   (setq orgelev (getvar "ELEVATION"))
   (setvar "ELEVATION" (caddr e1pt1))
   (setq workelev (getvar "ELEVATION"))
   (setq ctrmode _VERTICALTRAY)
   (setq _VERTICALTRAY T)
   (if tr_data
     (progn
       (setq offsize (nth 0 tr_data)
             offcode (nth 2 tr_data)
             offdpth (nth 3 tr_data)
             offtag  (nth 1 tr_data)
             offflng (nth 10 tr_data)
       )
     )
     (progn 
       (if _CHANTEE
          (setq offsize _CHANSIZE
          	    offcode _CHANCODE
                offdpth _CHANDEPTH
                offflng 0.0
          )
          (setq offsize _TRSIZE
          	    offcode _TRCODE
                offdpth _TRDEPTH
                offflng _TRAYFLANGE
          )
       )
       (setq offtag (get_con_tag))
     )
   )
   (setq MEDCurrentTraySettings (list _TRCODE _TRTYPE _TRSIZE _TRDEPTH _TRAYFLANGE))
   (MEDSetTrayValues (list offcode 0 offsize offdpth offflng))
   (setq _ANGPOL 1)
   (setq tangpol _ANGPOL)
   (initget 1 "30 45 60 90")
   (setq incang (getkword "\nOffset with 30 / 45 / 60 / 90 degree angle: "))
   (cond
     ((= incang "30")
        (setq trdatalst (trayoffitt 0.1666665 13 9 18 21 41 44))
     )
     ((= incang "45")
        (setq trdatalst (trayoffitt 0.25 10 6 12 15 35 38))
     )
     ((= incang "60")
        (setq trdatalst (trayoffitt 0.33333333 7 3 6 9 29 32))
     )
     ((= incang "90")
        (setq trdatalst (trayoffitt 0.5 4 0 0 3 23 26))
     )
   )
   (setq tr_off (* offsize 0.5))
   (setq offtrlst (list offsize offdpth offtag offflng))
   (setq incang (nth 0 trdatalst)
         degfit1(nth 1 trdatalst)
         degfit2(nth 2 trdatalst)
	     ptraydir(nth 3 trdatalst)
   )
   (if (= ptraydir "Down")
     (setq vtrdir1 -1
	   vtrdir2 1
     )
     (setq vtrdir1 1
	   vtrdir2 -1
     )
   )
   (setvar "lastpoint" e1pt1)
   (setq gen_ang (angle e1pt2 e1pt1)
         hdist (/ (+ (* _PLOTSCALE _TRRAD) (* (* _PLOTSCALE offdpth) 0.5)) (sin (+ (* PI 1.5) (* incang 0.5))))
         xdist (abs (* hdist (cos (+ (* PI 1.5) (* incang 0.5)))))
         offstpt1 e1pt1
         e1pt1 (polar e1pt1 gen_ang (+ (* _PLOTSCALE _TRTANFAC) xdist))
         _MEDTRAYANG gen_ang
         _MEDTRAYPT  offstpt1
   )
   (setq traystpt (DrawVerticalTrayFitting (list offsize offdpth degfit1 offflng offtag) offstpt1 gen_ang vtrdir1 (nth 0 trdatalst)))
   (setq hoffd (/ disty (sin incang))
         hoffpt (polar e1pt1 (+ gen_ang (* incang _ANGPOL)) hoffd)
         offstpt2 (polar hoffpt gen_ang (+ (* _PLOTSCALE _TRTANFAC) xdist))
         e1pt2b (polar offstpt2 (+ (+ gen_ang PI) (* PI 0.5)) (* _PLOTSCALE 1))
         offstpt2 (inters e1pt2 offstpt1 offstpt2 e1pt2b nil)
         _MEDTRAYANG (+ gen_ang PI)
         _MEDTRAYPT  offstpt2
   )
   
   (if (= ptraydir "Down")
     (setvar "ELEVATION" (- (getvar "ELEVATION") disty))
     (setvar "ELEVATION" (+ (getvar "ELEVATION") disty))
   )
   (setq trayendpt (DrawVerticalTrayFitting (list offsize offdpth degfit2 offflng offtag) offstpt2 (+ gen_ang PI) vtrdir2 (nth 0 trdatalst)))
   (setq _VERTICALTRAY ctrmode)
   (princ "\nAbout to Draw Tray")
   (command "UCS" "NAmed" "Save" "MEDTemp")
   (DrawVerticalTray (list offsize offdpth offcode offflng offtag) Traystpt TrayEndPt gen_ang vtrdir1 (nth 0 trdatalst) (distance traystpt trayendpt))
   (command "UCS" "NAmed" "Restore" "MEDTemp")
   (command "UCS" "Named" "Delete" "MEDTemp")
   (setvar "ELEVATION" orgelev)
   (setq _MEDTAG offtag)
   (MEDSetTrayValues MedCurrentTraySettings)
   (setq _ANGPOL nil *MED-PTRAYOFF-DIR* nil)
   (princ)
)

(defun c:trayteere( / tr_data intpt tr_ss bul srtent trfitcd tr_size
                    tr_dpth tr_tag troff br_len br_tr_list genang
                    tpt pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 
                    mlist xdlist)
  (med_cur_set "c:trayteeretrayrere")
  (medts_begin "TRAYTEERE")
  (if _CHANTEE
     (setq trfitcd (+ _CHANFITST 16)
           trprsz _CHANSIZE
           trflng 0.0
     )
     (setq trfitcd (+ _TRFITSTRT 16)
           trprsz _TRSIZE
           TrFlng (if (< _TRAYFLANGE 0) 0.0 _TRAYFLANGE)
           ;trflng _TRAYFLANGE
     )
  )
  (setq medprmpt (strcat "\nSelect Insertion Point for "
                         (clookup (+ trfitcd _TRFITTADD) trprsz _FITTING)
                         ": "
                 )
        intpt(getpoint medprmpt)
	trayteeelev (getvar "ELEVATION")
        TR_MAIN nil
        tr_ss(ssget "c" intpt intpt)
        bul     (med_tan (* (* PI 0.5) 0.25))
        srtent  (getvar "SORTENTS")
  )
  (setvar "ELEVATION" (caddr intpt))
  (setvar "SORTENTS" 0)
  (if tr_ss
        (setq tr_data (get_tray_data tr_ss))
  )
  (if tr_data
    (progn
      (medts_prepick intpt tr_ss T)
      (traychck intpt)
      (setq tr_data (get_tray_data (medts_data_ss tr_ss))
            tr_size (nth 0 tr_data)
            tr_dpth (nth 3 tr_data)
            tr_tag  (nth 1 tr_data)
            troff   (* tr_size 0.5)
            trflng  (nth 10 tr_data)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
            br_tr_list (list br_len br_len 0.0 br_len 3)
            genang (medts_brk_rot intpt br_tr_list)
	)    
    )
    (progn
      (initget 1)
      (setq genang (getangle intpt "\nAngle of generation: "))
      (if _CHANTEE
         (setq tr_size _CHANSIZE
               tr_dpth _CHANDPTH
         )
         (setq tr_size _TRSIZE
		tr_lsize _TRSIZE
               tr_dpth _TRDEPTH
         )
      )
      (setq tr_tag  (get_con_tag)
            sizelst (list 4.0 6.0 9.00 12.00 18.00 24.00 30.0 36.0 42.0 48.0)
            redlst  (reverse (cdr (member tr_lsize (reverse sizelst))))
      )
      ;(while (not (member tr_ssize redlst))
	  (while (not (member tr_ssize sizelst))
          (prompt "\nSize may not be larger than current size.")
          (initget 1)
          (setq tr_ssize (getreal "\nSize to Reduce to: "))
      )
      (setq tr_alt_size tr_ssize
	      tr_ssize nil
	      troff   (* tr_size 0.5)
	    altoff  (* tr_alt_size 0.5)
            br_len  (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC))
      )
      
    )
  )
  (setq _CHANTEE nil)
  (setq tpt    (polar intpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD altoff _TRTANFAC)))
        pt1    (polar tpt (+ genang PI) (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt2    (polar pt1 genang (* _PLOTSCALE (+ tr_size trflng)))
        pt3    (polar pt2 (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt genang (* _PLOTSCALE (+ _TRRAD troff _TRTANFAC)))
        pt5    (polar tpt (+ genang (* PI 0.5)) (* _PLOTSCALE (+ altoff (* trflng 0.5))))
        pt4    (polar pt5 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        pt6    (polar pt5 (- genang (* PI 0.5)) (* _PLOTSCALE (+ tr_alt_size trflng)))
        pt7    (polar pt6 (+ genang PI) (* _PLOTSCALE _TRTANFAC))
        tpt    (polar intpt (- genang (* PI 0.5)) (* _PLOTSCALE (+ _TRRAD altoff _TRTANFAC)))
        pt9    (polar tpt genang (* _PLOTSCALE (+ troff (* trflng 0.5))))
        pt8    (polar pt9 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        pt10   (polar pt9 (+ genang PI) (* _PLOTSCALE (+ tr_size trflng)))
        prpt1  (be pt1 pt2)
        prpt1a (polar prpt1 (- genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
        prpt3  (be pt5 pt6)
        prpt3a (polar prpt3 (- genang PI) (* _PLOTSCALE _TRTANFAC))
        prpt2  (be pt9 pt10)
        prpt2a (polar prpt2 (+ genang (* PI 0.5)) (* _PLOTSCALE _TRTANFAC))
  )
  (setq mlist  (list (list pt1  nil)
                     (list pt2  nil)
                     (list pt3  bul)
                     (list pt4  nil)
                     (list pt5  nil)
                     (list pt6  nil)
                     (list pt7  bul)
                     (list pt8  nil)
                     (list pt9  nil)
                     (list pt10 nil)
               )
  )
  (MEDMakeTray mlist T nil nil)
  ;(maketray mlist T nil)
  (chg_tray_pl_wdth (entlast) _TRPLWIDTH)
  (setq mlist (list (list prpt1 nil)
                    (list prpt1a bul)
                    (list prpt3a nil)
                    (list prpt3  nil)
                    (list prpt3a bul)
                    (list prpt2a nil)
                    (list prpt2 nil)
              )
  )
  (MEDMakeTray mlist nil _MEDCENLAY nil)
  ;(maketray mlist nil _MEDCENLAY)
  (setq xdlist (bld_fitting (+ trfitcd _TRFITTADD) tr_size tr_tag nil tr_dpth _TRAYFLANGE))
  (xdatadd (entlast) xdlist)
  (setvar "SORTENTS" srtent)
  (setvar "ELEVATION" trayteeelev)
  (medts_end)
  (med_ret_ok)
  (princ)
)

(defun MEDMakeTray (traylist closeflag layerset OCSData / clay vtxt sqend vtxt vert vertxt)
  (setq plin '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (67 . 0)))
  (setq clay (getvar "CLAYER"))
  (if (not layerset)
     (setq bldlayer (nth 0 _MEDTRAY)
           layerset _MEDTRAY
     )
     (setq bldlayer (nth 0 layerset))
  )
  (if (not (tblsearch "layer" bldlayer))
    (progn
       (smlayer layerset)
       (setvar "CLAYER" clay)
    )
  )
  (setq plin (append plin (list (cons 8 bldlayer))))
  (setq plin (append plin (list (cons 100 "AcDbPolyline") (cons 67 0))))
  (setq ptlistlen (length traylist)
        plin (append plin (list (cons 90 ptlistlen)))
  )
  (if closeflag
     (setq plin  (append plin (list (cons 70 1))))
  )
  (setq elev (getvar "ELEVATION"))
  (if OCSData
  	  (setq UseThisOCSData OCSData)
  	  (setq UseThisOCSDAta (MedGetCurrentOCS))
  )
  (setq PtOnlyList (list))
  (foreach PtPair TrayList
  	  (setq PTOnlyList (append PTOnlyList (list (car PTPair))))
  )
  (setq WCSPointList (MEDTransPointListToUCS PTOnlyList elev UseThisOCSData)
  	    elev (nth 1 WCSPointlist)
  	    PTOnlyList (nth 0 WCSPointList)
  )
  (setq plin (append plin (list (cons 43 0.0) (cons 38 elev) (cons 39 0.0))))
  (setq PtCount 0)
  (foreach vertxt PTOnlyList
     (setq vert (cons 10 vertxt)
           ver1 (cons 40 0.0)
           ver2 (cons 41 0.0)
     )
     (if (nth 1 (nth PtCount TrayList))
         (setq ver3 (cons 42 (nth 1 (nth PtCount TrayList))))
         (setq ver3 (cons 42 0.0))
     )
     (setq plin (append plin (list vert ver1 ver2 ver3))
           PTCount (1+ PTCount)
     )
  )
  (if _ZFLAG
    (setq twoten (cons 210 (list 0.0 -1.0 0.0))
          plin (append plin (list twoten))
          _ZFLAG nil
    )
    (if OCSData
    	(setq OCSTrue "OCSTrue"
    		  twoten (cons 210 OCSData)
    		  plin (append plin (list twoten))
    	)
    	(setq OCSFalse "OCSFalse"
    		  twoten (cons 210 (MEDGetCurrentOCS))
    	      plin (append plin (list twoten))
    	)
    )
  )
  (entmake plin)
)

(defun MEDPromptForVerticalTrayDistance( traydir trcode trsz trstpt )
   (if (not traydir)
     (setq traydir "Down")
   )
   (setq mdprmpt(strcat "\nLength of " (clookup trcode trsz _TRAY)
                        " traveling " traydir
                        " <" (rtos _MEDDIST) ">: "
                 )
        trdist (getdist trstpt mdprmpt)
   )
   (if (not trdist)
      (setq trdist _MEDDIST)
      (setq _MEDDIST trdist)
   )
   trdist
)

(defun trayupdown(traydir trltype)
   (while (not (setq trbasent (entsel "\nSelect Tray item"))))
   (setq vtrayfitent (car trbasent)
   	     vtrayfitentdata (entget vtrayfitent)
   )
   (if (= (dxf 0 vtrayfitentdata) "LWPOLYLINE")
   	   (progn
   	   	   (setq cltp (getvar "celtype")   
   	   	   	   	 clay (getvar "CLAYER")
   	   	   	   	 acttraydir nil
   	   	   	   	 tryptdatalist (bld_lw_ptlist  vtrayfitent)
   	   	   	   	 tryptlist (car tryptdatalist)
   	   	   )
   	   	   (if (= (length tryptlist) 2)
   	   	   	   (progn
   	   	   	   	   (setq traystpt (osnap (cadr trbasent) "ENDPoint")
   	   	   	   	   	     AlignPoint (opposite_tray_endpt (car trbasent) traystpt)
   	   	   	   	   	     genangle (angle alignpoint traystpt)
   	   	   	   	   	     trflng (if _CHANTEE 0.0 _TRAYFLANGE)
   	   	   	   	   	     trsize (if _CHANTEE _CHANSIZE _TRSIZE)
   	   	   	   	   	     trdpth (if _CHANTEE _CHANDEPTH _TRDEPTH)
   	   	   	   	   	     trcode (if _CHANTEE _CHANCODE (+ _TRCODE _TRTYPE))
   	   	   	   	   	     _CHANTEE nil
   	   	   	   	   	     TrayDist (MEDPromptForVerticalTrayDistance traydir trcode trsize traystpt)
   	   	   	   	   	     trtag   (MEDGetTrayTag nil)
   	   	   	   	   	     pt1 (polar traystpt (+ genangle (* PI 0.5)) (* _PLOTSCALE (* 0.5 (+ trflng trsize))))
   	   	   	   	   	     pt2 (polar pt1 genangle (* _PLOTSCALE trdpth))
   	   	   	   	   	     pt3 (polar pt2 (- genangle (* PI 0.5)) (* _PLOTSCALE (+ trflng trsize)))
   	   	   	   	   	     pt4 (polar pt3 (+ PI genangle) (* _PLOTSCALE trdpth))
   	   	   	   	   	     trayendpt (list (car traystpt) (cadr traystpt) (- (caddr traystpt) traydist))
   	   	   	   	   	     currOCS (MEDGetCurrentOCS)
   	   	   	   	   	)
   	   	   	   	    (ltback trltype)
   	   	   	   	    (setvar "CLAYER" (car _MEDTRAY))
   	   	   	   	    (MEDPlineMake (list pt2 pt3 pt1 pt2 pt4 pt3) nil nil nil)
   	   	   	   	    (setvar "CELTYPE" cltp)
   	   	   	   	    (command "UCS" "3P" traystpt trayendpt pt1)
   	   	   	   	    (setvar "CLAYER" (car _MEDCENLAY))
   	   	   	   	    (MEDTray (list (list (trans traystpt currOCS 1) (trans trayendpt currOCS 1)) trcode trsize))
   	   	   	   	    (setq xdlist (bld_tray trcode trsize trtag nil trdpth "T" trflng))
   	   	   	   	    (xdatadd (entlast) xdlist)
   	   	   	   	    (MEDTrayOutline (entlast))
   	   	   	   	    (command "UCS" "P")
   	   	   	   	    
   	   	   	  )
   	   	   	   (progn
   	   	   	   	   (setq traystpt (append (cdr (last tryptlist)) (list (dxf 38 vtrayfitentdata)))
   	   	   	   	   	     traystpt (trans traystpt (dxf 210 vtrayfitentdata) 1)
   	   	   	   	   	     angpt1 (cdr (nth 0 tryptlist))
   	   	   	   	   	     angpt1 (append angpt1 (list (dxf 38 vtrayfitentdata)))
   	   	   	   	   	     angpt1 (trans angpt1 (dxf 210 vtrayfitentdata) 1)
   	   	   	   	   	     angpt2 (cdr (nth 1 tryptlist))
   	   	   	   	   	     angpt2 (append angpt2 (list (dxf 38 vtrayfitentdata)))
   	   	   	   	   	     angpt2 (trans angpt2 (dxf 210 vtrayfitentdata) 1)
   	   	   	   	   	     genangle (angle angpt1 angpt2)
   	   	   	   	   	     trdata (xdataget vtrayfitent _FITTING)
   	   	   	   	   	     trflng (nth 6 trdata)
   	   	   	   	   	     trsize (nth 2 trdata)
   	   	   	   	   	     trdpth (nth 5 trdata)
   	   	   	   	   	     trcode (if _CHANTEE _CHANCODE (+ _TRCODE _TRTYPE))
   	   	   	   	   	     _CHANTEE nil
   	   	   	   	   	     TrayDist (MEDPromptForVerticalTrayDistance traydir _TRCODE trsize traystpt)
   	   	   	   	   	     trtag   (nth 1 trdata)
   	   	   	   	   	     pt1 (polar traystpt (+ genangle (* PI 0.5)) (* _PLOTSCALE (* 0.5 (+ trflng trsize))))
   	   	   	   	   	     trayendpt (list (car traystpt) (cadr traystpt) (- (caddr traystpt) traydist))
   	   	   	   	   	     currOCS (MEDGetCurrentOCS)
   	   	   	   	   	)
   	   	   	   	    ;(ltback trltype)
   	   	   	   	    (setvar "CLAYER" (car _MEDTRAY))
   	   	   	   	    ;(MEDPlineMake (list pt2 pt3 pt1 pt2 pt4 pt3) nil nil nil)
   	   	   	   	    ;(setvar "CELTYPE" cltp)
   	   	   	   	    (command "UCS" "3P" traystpt trayendpt pt1)
   	   	   	   	    (setvar "CLAYER" (car _MEDCENLAY))
   	   	   	   	    (MEDTray (list (list (trans traystpt currOCS 1) (trans trayendpt currOCS 1)) (+ _TRCODE _TRTYPE) _TRSIZE))
   	   	   	   	    (setq xdlist (bld_tray trcode trsize trtag nil trdpth "T" trflng))
   	   	   	   	    (xdatadd (entlast) xdlist)
   	   	   	   	    (MEDTrayOutline (entlast))
   	   	   	   	    (command "UCS" "P")
   	   	   	   	    
   	   	   	  )
   	   	   	  
   	   	   )
   	  )
   )
)

(defun c:traydn()
   (med_cur_set "C:TRAYDN")
   (trayupdown "Down" H_CON)
   (med_ret_ok)
   (princ)
)
(defun c:trayup()
   (med_cur_set "C:TRAYUP")
   (trayupdown "Up" nil)
   (med_ret_ok)
   (princ)
)
(defun c:chandn()
   (med_cur_set "C:CHANDN")
   (setq _CHANTEE T)
   (trayupdown "Down" H_CON)
   (setq _CHANTEE nil)
   (med_ret_ok)
   (princ)
)
(defun c:chanup()
   (med_cur_set "C:CHANUP")
   (setq _CHANTEE T)
   (trayupdown "Up" nil)
   (setq _CHANTEE nil)
   (med_ret_ok)
   (princ)
)
;;; ======================================================================
;;; traytee-s3 2026-10-28  congested prompts + silent OCS/BREAK
;;; traytee-s1 2026-10-28  TRAYTEE / TRAYCROSS / TRAYTEERE safety + explicit picks
;;;  - UNDO group per command; Escape or any error -> UNDO End + UNDO 1 (drawing rolls
;;;    back, deleted outlines come back) and med_reset restores PICKBOX/OSMODE/ELEVATION/
;;;    SORTENTS/CMDECHO.
;;;  - If trays running in 2+ directions are under the pick point (a real intersection),
;;;    prompt "Select MAIN run tray" (+ "Select BRANCH tray" for tees). Fitting angle comes
;;;    from the main segment direction, branch side from the branch entity. No MID osnap /
;;;    4.5" probe guessing in that case. One tray under the point -> old one-point mode.
;;; ======================================================================
(vl-load-com)
(setq MEDTS_UNDO nil MEDTS_MAIN nil MEDTS_BRANCH nil MEDTS_NAME nil MEDTS_OLDERR nil)

(defun medts_begin (nm)
  (setq MEDTS_NAME nm MEDTS_MAIN nil MEDTS_BRANCH nil
        MEDTS_OLDERR *error*)
  (command "_.UNDO" "_BEgin")
  (setq MEDTS_UNDO T)
  (defun *error* (msg)
    (if MEDTS_UNDO
      (progn
        (setq MEDTS_UNDO nil)
        (command-s "_.UNDO" "_End")
        (command-s "_.UNDO" "1")
      )
    )
    (setq MEDTS_MAIN nil MEDTS_BRANCH nil _CHANTEE nil)
    (med_reset)                       ; restores sysvars, re-arms MED_ERROR, *error* <- olderr
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (prompt (strcat "\n" MEDTS_NAME " failed: " msg))
    )
    (prompt (strcat "\n" MEDTS_NAME " cancelled - drawing rolled back, PICKBOX/OSMODE/ELEVATION restored."))
    (princ)
  )
)

(defun medts_end ()
  (if MEDTS_UNDO (progn (command "_.UNDO" "_End") (setq MEDTS_UNDO nil)))
  (setq MEDTS_MAIN nil MEDTS_BRANCH nil)
  (if MED_SYSVARS (progn (med_rv "PICKBOX" 9) (med_rv "OSMODE" 4)))
)

;; MED tray entity? (_TRAY or _FITTING xdata)
(defun medts_is_tray (e)
  (and e (or (xdataget e _TRAY) (xdataget e _FITTING)))
)

;; picked outline (no xdata) -> owning tray via its _DOUBLE pair handle
(defun medts_resolve (e / h ss i x d)
  (cond
    ((medts_is_tray e) e)
    ((and e _DOUBLE (setq h (cdr (assoc 5 (entget e))))
          (setq ss (ssget "_X" (list (list -3 (list _DOUBLE))))))
       (setq i 0)
       (while (and (not x) (< i (sslength ss)))
         (setq d (xdataget (ssname ss i) _DOUBLE))
         (if (and d (= (strcase (nth 1 d)) (strcase h))) (setq x (ssname ss i)))
         (setq i (1+ i)))
       (if (medts_is_tray x) x))
  )
)

;; direction (0..PI) of a curve at the point nearest pt
(defun medts_dir (e pt / cp p d)
  (if (and (not (vl-catch-all-error-p
                  (setq cp (vl-catch-all-apply (function vlax-curve-getClosestPointTo)
                                               (list e (trans pt 1 0))))))
           cp
           (setq p (vlax-curve-getParamAtPoint e cp))
           (setq d (vlax-curve-getFirstDeriv e p)))
    (rem (+ (angle '(0 0 0) (list (car d) (cadr d) 0.0)) (* 2 PI)) PI)
  )
)

;; list of distinct tray directions under pt
(defun medts_dirs (ss pt / i e a lst)
  (setq i 0)
  (if ss
    (while (< i (sslength ss))
      (setq e (ssname ss i) i (1+ i))
      (if (and (medts_is_tray e) (setq a (medts_dir e pt))
               (not (vl-some (function (lambda (b) (or (< (abs (- a b)) 0.02)
                                                        (> (abs (- a b)) (- PI 0.02)))))
                             lst)))
        (setq lst (cons a lst)))))
  lst
)

(defun medts_pick (msg / s e)
  (while (not e)
    (setq s (entsel msg))
    (if (not s) (exit))                      ; Enter/Escape -> *error* -> rollback
    (if (not (setq e (medts_resolve (car s))))
      (prompt "\n  Not a MED tray - pick the tray run.")))
  e
)

;; Called before traychck. Two+ directions under pt -> explicit MAIN (+BRANCH) picks.
(defun medts_prepick (pt ss needbr)
  (setq MEDTS_MAIN nil MEDTS_BRANCH nil)
  (if (> (length (medts_dirs ss pt)) 1)
    (progn
      (prompt "\n  Area congested - make sure which tray entities you pick.")
      (setq MEDTS_MAIN (medts_pick "\nSelect MAIN run tray carefully: "))
      (if needbr
        (progn
          (setq MEDTS_BRANCH (medts_pick "\nSelect BRANCH tray carefully (not the main run): "))
          (while (eq MEDTS_BRANCH MEDTS_MAIN)
            (prompt "\n  That is the MAIN run - pick the BRANCH tray.")
            (setq MEDTS_BRANCH (medts_pick "\nSelect BRANCH tray carefully (not the main run): ")))))
    )
  )
  MEDTS_MAIN
)

;; size/tag from MAIN when picked, else old largest-in-set
(defun medts_data_ss (ss)
  (if (and MEDTS_MAIN (entget MEDTS_MAIN)) (ssadd MEDTS_MAIN) ss)
)

(defun medts_far (e pt / a b)
  (setq a (vlax-curve-getStartPoint e) b (vlax-curve-getEndPoint e)
        pt (trans pt 1 0))
  (if (> (distance (list (car a) (cadr a)) (list (car pt) (cadr pt)))
         (distance (list (car b) (cadr b)) (list (car pt) (cadr pt))))
    a b)
)

;; replaces tray_brk_rot in TRAYTEE/TRAYCROSS/TRAYTEERE
(defun medts_brk_rot (pt bl / osm ma ga far v ang)
  (setq osm (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  (if (and MEDTS_MAIN (/= _USERROT 1) (setq ma (medts_dir MEDTS_MAIN pt)))
    (progn
      (if MEDTS_BRANCH
        (progn                                   ; tee: genang = branch direction
          (setq far (trans (medts_far MEDTS_BRANCH pt) 0 1)
                ga  (+ ma (* 0.5 PI))
                v   (list (- (car far) (car pt)) (- (cadr far) (cadr pt))))
          (if (< (+ (* (car v) (cos ga)) (* (cadr v) (sin ga))) 0.0)
            (setq ga (- ma (* 0.5 PI))))
          (setq ang ga))
        (setq ang ma))                           ; cross: main axis
      (med_brk_out ang pt (list (nth 0 bl) (nth 1 bl) (nth 2 bl) (nth 3 bl)) T)
    )
    (setq ang (tray_brk_rot pt bl))              ; one tray: original one-point logic
  )
  (setvar "OSMODE" osm)
  ang
)
(princ "\nMED Traytee traytee-s3 2026-10-28 loaded (congested MAIN/BRANCH prompts; OCS/BREAK quiet).")

(princ "Done. traytee-s3 2026-10-28")
