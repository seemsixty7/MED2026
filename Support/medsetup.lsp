(princ "\rLoading MEDSetup...")
;
; C:SETUP is for setting up drawing using specified title block
; and sets up limits for drawing
;

;;
;;Setup.lsp
;;

(defun scale_for (tilename)
  (cond 
    ((= tilename "Full")
      (mode_tile "Arch" 1)
      (mode_tile "Eng" 1)
      (mode_tile "Met" 1)
      (setq tmp_sc 1.0)
    )
    ((= tilename  "A00")
      (mode_tile "Arch" 0)
      (mode_tile "Eng" 1)
      (mode_tile "Met" 1)
    )
    ((= tilename "E00")
      (mode_tile "Arch" 1)
      (mode_tile "Eng" 0)
      (mode_tile "Met" 1)
    )
    ((= tilename "M00")
      (mode_tile "Arch" 1)
      (mode_tile "Eng" 1)
      (mode_tile "Met" 0)
     
     
    )
  )
  
)
(defun settmpsc(radnm scflag)
  (cond
     ((= scflag 0)
      (setq tmp_sc (atof (substr radnm 2))
	    tmp_asc tmp_sc
	    tmp_pltsc 1.0
      )
     )
     ((= scflag 1)
      (setq tmp_sc (atof (substr radnm 2))
            tmp_esc tmp_sc
	    tmp_pltsc 1.0
      )
     )
     ((= scflag 2)
      (setq tmp_sc (atof (substr radnm 2))
	    tmp_msc tmp_sc
	    tmp_pltsc 25.4
      )
     )
  )
  (setq tmpvar radnm)
)
(defun select_title(fname)
  (setq newfname (getfiled "Select Titleblock Drawing" fname "dwg" 0))
  (if newfname
    (setq titblktouse newfname)
  )
  (set_tile "Title" titblktouse)
  titblktouse
)
(defun ins_border()
  (MEDtitle)
  (load "setup.add")
)

(defun c:setup ()
  (med_cur_set "c:setup")
  (setq archlist (list 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0 192.0)
        englist (list 120.0 240.0 360.0 480.0 600.0 720.0 1200.0 2400.0)
	metlist (list 1.0 500.0 1000.0 1250.0 1500.0 2000.0 2500.0)
  )
  (setq titblktouse MED_TBLK)
  (if (/= 0.0 (getvar "USERR1"))
    (setq _SC (getvar "USERR1"))
    (setq _SC (getvar "DIMSCALE"))
  )
  (if (> (setq index_val (load_dialog "MED")) 0)
     (progn
      (if (new_dialog "MED_setup" index_val)
	   (progn 
           (if (member _SC archlist)
             (progn
               (setq radbut (strcat "A" (itoa (fix _SC))))
               (mode_tile "Arch" 0)
               (mode_tile "Eng" 1)
               (mode_tile "Met" 1)
               (set_tile "A00" "1")
               (set_tile radbut "1")
               (setq tmp_sc _SC
                     tmp_asc _SC
                     tmp_pltsc 1.0
               )
             )
             (progn
               (if (member _SC englist)
                (progn
                  (setq radbut (strcat "E" (itoa (fix _SC))))
                  (mode_tile "Arch" 1)
                  (mode_tile "Eng" 0)
		  (mode_tile "Met" 1)
                  (set_tile "E00" "1")
                  (set_tile radbut "1")
                  (setq tmp_sc _SC
                        tmp_esc _SC
                        tmp_pltsc 1.0
                  )
                )
                (progn
		  (if (and (member _SC metlist) (= _PLOTSCALE 25.4))
		    (progn
		      (setq radbut (strcat "M" (itoa (fix _SC))))
		      (mode_tile "Arch" 1)
		      (mode_tile "Eng" 1)
		      (mode_tile "Met" 0)
		      (set_tile "M00" "1")
		      (set_tile radbut "1")
		      (setq tmp_sc _SC
		      	 	tmp_msc _SC
		      	  	tmp_pltsc 25.4
		      )

		    )
		    (progn
		      (set_tile "Full" "1")
              (mode_tile "Arch" 1)
              (mode_tile "Eng" 1)
		      (mode_tile "Met" 1)
              (setq tmp_sc 1.0
                    tmp_asc 4.0
                    tmp_esc 120.0
                    tmp_msc 500.0
                    tmp_pltsc 1.0
              )
            )
		  )
        )
      )
     )
    )
           (set_tile "Title" titblktouse)
           (action_tile "Full" "(scale_for $key)")
           (action_tile "A00" "(scale_for $key)")
           (action_tile "E00"  "(scale_for $key)")
	       (action_tile "M00"  "(scale_for $key)")
           (action_tile "Arch" "(settmpsc $value 0)")
           (action_tile "Eng"  "(settmpsc $value 1)")
	       (action_tile "Met"  "(settmpsc $value 2)")
           (action_tile "GetTitle" "(select_title titblktouse)")
           (action_tile "accept" "(done_dialog 0)")
           (action_tile "cancel" "(done_dialog 1)")
           (action_tile "usepaperspace" "(mod_paperspace $value)")
	       (setq result (start_dialog))
	   )
      )
	  
      (unload_dialog index_val)
      (if (= result 0)
       (progn
        (setq _SC tmp_sc)
        (setq MED_TBLK titblktouse)
	(setq _PLOTSCALE tmp_pltsc)
        (setvar "DIMSCALE" _SC)
        (setvar "USERR1" _SC)
	(setvar "attdia" 1)
	(setvar "GRIDMODE" 0)
        (ins_border)
       )
      )
     )
  )
  (med_ret_ok)
  (princ)
) 

(defun mod_paperspace (n_value)
   (if (= n_value "0")
      (setq MEDSETUPUSEPAPERSPACE nil)
      (setq MEDSETUPUSEPAPERSPACE T)
   )
)

(defun c:bldist( / fn fnh inspt d1 d2 d3 d4 rtsc dwgpr dwgnm
                   prelen nmlen wrstr)
  (setq blexprt (entsel "\nSelect block to build break and rotate info on"))
  (if blexprt
    (progn
      (setq blexprt (entget (car blexprt))
            inspt (dxf 10 blexprt)
            d1    (getdist inspt "\nFirst distance point for 0 rotation: ")
            d2    (getdist inspt "\nSecond distance point for 90 rotation : ")
            d3    (getdist inspt "\nThird distance point for 180 rotation: ")
            d4    (getdist inspt "\nFourth distance point for 270 rotation: ")
      )
      (if (not d1)
        (setq d1 0.0)
        (setq d1 (abs d1))
      )
      (if (not d2)
        (setq d2 0.0)
        (setq d2 (abs d2))
      )
      (if (not d3)
        (setq d3 0.0)
        (setq d3 (abs d3))
      )
      (if (not d4)
        (setq d4 0.0)
        (setq d4 (abs d4))
      )
      (initget 1 "Nil 0 1 22 24 3 4 5 6")
      (setq rtspc (getkword "\nRotation Specification <nil 0 1 22 24 3 4 5 6>: "))
      (setq dwgnm (dxf 2 blexprt))
      (if (= rtspc "Nil")
        (setq rtspc "nil")
      )
      (setq wrstr dwgnm)
      (while (< (strlen wrstr) 9)
        (setq wrstr (strcat wrstr " "))
      )
      (setq wrstr (strcat wrstr (rtos d1 2 12)))
      (while (< (strlen wrstr) 27)
         (setq wrstr (strcat wrstr " "))
      )
      (setq wrstr (strcat wrstr (rtos d2 2 12)))
      (setq fn (strcat _MEDDIR "MEDblck.dat"))
      (setq fnh (open fn "a"))
      (while (< (strlen wrstr) 45)
         (setq wrstr (strcat wrstr " "))
      )
      (setq wrstr (strcat wrstr (rtos d3 2 12)))
      (while (< (strlen wrstr) 63)
        (setq wrstr (strcat wrstr " "))
      )
      (setq wrstr (strcat wrstr (rtos d4 2 12)))
      (while (< (strlen wrstr) 81)
        (setq wrstr (strcat wrstr " "))
      )
      (setq wrstr (strcat wrstr rtspc))
      (write-line wrstr fnh)
      (close fnh)
   )
   (Prompt "\nNo entity selected")
  )
)
(defun c:setplot( / oldval pltval)
  (if _PLOTSCALE
     (setq oldval _PLOTSCALE)
     (setq oldval 1.0)
  )
  (setq pltval (getreal (strcat "\Plot Correction factor " (rtos oldval 2 8) ": ")))
  (if (not pltval)
      (setq pltval oldval)
  )
  (if (= pltval 1.0)
    (progn
      (setq _PLOTSCALE 1.0)
      (setvar "userr2" 1.0)
      (prompt "\nPlot correction has been turned off.")
    )
    (progn
      (setq _PLOTSCALE pltval)
      (setvar "userr2" pltval)
      (prompt (strcat "\nPlot correction has been set to " (rtos pltval 2 8) "."))
    )
  )
  (princ)
)
;; function for setting up a title block definition file

(defun setblk()
  (setq MED_TBLK (getstring "\nTitle block name(Path if needed): "))
  (prompt "\nThe MED.SPC file has not been modified.")
  (terpri)
)

;; function for changing existing title block in current drawing

(defun MEDtitle(/ old ss1 str tdwg su cnt tit)
  (setq atmode (getvar "ATTREQ")
        cnt (strlen MED_TBLK)
        tdwg MED_TBLK
  )
  (while (and (> cnt 0) (and (/= str "\\") (/= str "/")) )
    (setq str (substr tdwg cnt 1)
          cnt (1- cnt)
    )
  )
  (if (or (= str "\\") (= str "/"))
    (setq su 2)
    (setq su 1)
  )
  (setq s3 (substr tdwg (+ su cnt)))
  (setvar "ATTREQ" 0)
  (setq titleinscale 1.0)
  (if MEDSETUPUSEPAPERSPACE
  	  (progn
  	  	  (command "-Layout" "s" "Layout1")
  	  	  (setq titleinscale 1.0)
  	  )
  	  (progn
  	  	  (setq titleinscale _SC)
  	  )
  )
  (command "-insert" MED_TBLK "pscale" (* _PLOTSCALE titleinscale))
  (prompt "\nInsertion point for Title block: ")
  (command pause (* _PLOTSCALE titleinscale) "")
  (prompt "\nRotation Angle <0>: ")
  (command pause)
  (setq _INSPT (getvar "lastpoint"))
  (attmod (entlast))
  (setvar "ATTREQ" 1)
)
;; functions sets the limits to the extents of the drawing

(defun setlim( / pt)
  (setvar "LIMMIN"
    (setq PT (getvar "EXTMIN")
          PT (list (car PT) (cadr PT))
    )
  )
  (setvar "LIMMAX"
    (setq PT (getvar "EXTMAX")
          PT (list (car PT) (cadr PT))
    )
  )
  (command "zoom" "w" (getvar "limmin") (getvar "limmax"))
  (princ)
)
(defun c:setlim ()
   (setlim)
)
(princ "Done.")
