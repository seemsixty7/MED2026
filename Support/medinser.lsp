(princ "\rLoading MEDInser...")
(defun setblkins ( bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype)
	(setq MED_LASTUSEDINSERTDATA (list bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype))
)

(defun medblkins ( bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype / bl_ent)
	(setq MED_LASTUSEDINSERTDATA (list bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype))
	(C:MEDBlockInsert)
)
(defun C:MEDBlockInsert ( /  bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype bl_ent)
	(setq bl_lay (nth 0 MED_LASTUSEDINSERTDATA)
		  bl_name (nth 1 MED_LASTUSEDINSERTDATA)
		  bl_inspt (nth 2 MED_LASTUSEDINSERTDATA)
		  bl_rot (nth 3 MED_LASTUSEDINSERTDATA)
		  bl_scale (nth 4 MED_LASTUSEDINSERTDATA)
		  bl_instype (nth 5 MED_LASTUSEDINSERTDATA)
	)
	
;;;		The MED_LASTUSEDINSERTDATA Variable holds the following values
;;;     Variable Name  ||    Description
;;;     ----------------------------------------------------------------
;;;     bl_name        ||    Name of block to insert
;;;     bl_inspt       ||    Insertion point if provided will use
;;;                    ||       other wise will prompt for insertion point
;;;     bl_rot         ||    Block rotation if provided will use
;;;                    ||       other wise will prompt for rotation angle
;;;     bl_scale       ||    Scale factor to use for insertion of block
;;;     bl_instype     ||    Type of insert to perform.
;;;                    ||        0...General Insertion
;;;                    ||        1...Insertion of dependent block
;;;                    ||        2...Insertion of Non dependent block
;;;                    ||        3...NonDependent fittings with conduit down
;;;                    ||        4...Dependent conduit turned down
;;;                    ||        5...Dependent conduit turned up
;;;                    ||        6...Non-dependent fittings with conduit up
;;;                    ||        7...Tag inserts with dependent attributes
;;;                    ||        8...Reducer type inserts
;;;                    ||        9...Equipment Inserts
;;;				                10...Dependent Cable Turned Down
;;;				                11...Dependent Cable turned Up
;;;                    ||
;;;     RL_SS          ||    Relational Selection Set based on insertpoint
;;;     bl_ent         ||    Entity name of inserted block
;;;
  (setq TR_MAIN nil)
  (ltback nil)
  (med_cur_set "medblkins")
  (setq attre (getvar "ATTREQ"))
  (if _ZERO
     (setq storsize _CSIZE
           _CSIZE 0.0
     )
  )
  (setq medins_prmpt "\nInsertion Point: ")
  (cond
    ((= bl_instype 9)
     (setq medins_prmpt (strcat "\nSelect Insertion Point for "
                                (clookup _EQCODE nil _EQUIP) ": ")
     )
    )
    ((or (= bl_instype 1) (= bl_instype 2) (= bl_instype 3)
         (= bl_instype 6) (= bl_instype 8)
     )
     (setq medins_prmpt (strcat "\nSelect Insertion Point for "
                                (clookup _FITTCODE _CSIZE _FITTING) ": ")
     )
    )
    ((or (= bl_instype 4) (= bl_instype 5)
     )
     (setq medins_prmpt (strcat "\nSelect Insertion Point for "
                                (clookup _CODE _CSIZE _CONDUIT) ": ")
     )
    )
    ((or (= bl_instype 10) (= bl_instype 11))
       (setq medins_prmpt (strcat "\nSelect Insertion point for "
				  (clookup _CABCODE 1 _CABLE) ": ")
       )
    )
  )
  (setq curr_lay (getvar "clayer"))
  (if bl_lay
     (smlayer bl_lay)
  )
  (if (not bl_scale)
    (setq bl_scale _SC)
  )
  ;Removed 09/2009 for Blocks with Built in Scale Settings
  ;(if (and (= bl_scale _SC) _PLOTSCALE)
  ;   (setq bl_scale (* bl_scale _PLOTSCALE))
  ;)
  (setvar "CMDECHO" 0)
  (command "insert")
  (setq blnm bl_name)
  (setq bl_name (strcat _MEDDWG bl_name ".dwg"))
  (setq meddwgfind nil
        medoptfind nil
  )
  (if (findfile bl_name)
    (setq meddwgfind T)
    (progn
      (if (findfile (strcat blnm ".dwg"))
        (setq medoptfind T
              bl_name blnm
        )
      )
    )
  )
  (if (or meddwgfind medoptfind)
   (progn
     (command bl_name "pscale" bl_scale)
     (if (not bl_inspt)
       (progn 
          (prompt medins_prmpt)
          (command pause) (setq bl_inspt (getvar "LASTPOINT"))
       )
       (command bl_inspt)
     )
     (command nil nil)
     (setq RL_SS (ssget "C" (polar bl_inspt (* PI 0.25) (* _SC 0.0125))
                            (polar bl_inspt (* PI 1.25) (* _SC 0.0125))
                 )
     )
     (setvar  "ATTREQ" 0)
     (command "insert" bl_name bl_inspt)
     (command bl_scale bl_scale)
     (if (not bl_rot)
       (progn
        (if (not RL_SS)
          (progn
            (prompt "\nBlock Rotation <0>: ")
            (command pause)
          )
          (progn
            (command nil)
            (setq RL_SS_DATA (retr_size_tag RL_SS))
            (setq bl_rot (brk_rot bl_inspt blnm bl_scale))
            (setq bl_rot (* bl_rot (/ 180.0 PI)))
            (command "insert" NEW_BLNAME bl_inspt bl_scale "" bl_rot)
          )
        )
       )
       (command bl_rot)
     )
     (setvar "ATTREQ" attre)
     (setq bl_ent (entlast))
     (cond
        ((= bl_instype 0)
         (gen_ins bl_ent)
        )
        ((= bl_instype 1)
         (dfitt_ins bl_ent RL_SS)
        )
        ((= bl_instype 2)
         (ifitt_ins bl_ent RL_SS)
        )
        ((or (= bl_instype 3) (= bl_instype 6))
         (ifitt_ins bl_ent RL_SS)
         (dcon_ins bl_ent bl_inspt bl_instype RL_SS)
        )
        ((or (= bl_instype 4) (= bl_instype 5))
         (dcon_ins bl_ent bl_inspt bl_instype RL_SS)
        )
        ((= bl_instype 8)
         (refitt_ins bl_ent RL_SS _TYPE _DEPTH)
        )
        ((= bl_instype 9)
         (eqp_ins bl_ent)
        )
	((= bl_instype 10)
         (cab_ins bl_ent bl_inspt nil RL_SS)
        )
	((= bl_instype 11)
         (cab_ins bl_ent bl_inspt T RL_SS)
        )
     )
     (attmod bl_ent)
   )
   (progn 
    (command nil)
    (prompt "\nBlock Size is Invalid:")
    (terpri)
   )
  )
  (setq NEW_BLNAME nil)
  (if _ZERO
     (setq _CSIZE storsize
;           storsize nil
           _ZERO nil
     )
  )
;  (setvar  "ATTREQ" attre)
  (setvar "CLAYER" curr_lay)
  (med_ret_ok)
  (princ)
  (terpri)
)
(defun eqp_ins( genent / xdlist )
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     genent         ||    Entity name of inserted block
;;;     xdlist         ||    list of xdata used to attach data to block

   (setq xdlist (bld_equip _EQCODE _EQTAG))
   (xdatadd genent xdlist)
)

;;;---------------------------------------------------------------------
;;;** gen_ins is a function specifically for general insertions
;;;---------------------------------------------------------------------

(defun gen_ins( genent / xdlist )
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     genent         ||    Entity name of inserted block
;;;     xdlist         ||    list of xdata used to attach data to block

   (setq xdlist (list _ELEC
                      (cons 1002 "{")
	     	              (cons 1000 "General block Insert")
		                  (cons 1002 "}")
	              )
   )
   (xdatadd genent xdlist)
)

;;;--------------------------------------------------------------------
;;;** ifitt_ins is a function for inserting independent fittings
;;;--------------------------------------------------------------------

(defun ifitt_ins( ifittent dcon_ss / xdlist )
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     ifittent       ||    Entity name of inserted block
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     dcon_ss        ||    base selection set for retrieving tag name
;;;                    ||       and default size
  (setq tss dcon_ss)  

  (if _TAGSUPRESS
     (setq dcon_ss nil)
  )
  (if dcon_ss
     (progn
       (setq r_val RL_SS_DATA)
     ) 
  )
  (if r_val
    (progn
      (setq dconsize  (nth 0 r_val)
            con_tag   (nth 1 r_val)
	          con_code  (nth 2 r_val)
      )
    )
    (progn
      (setq dconsize _CSIZE)
      (if _TAGSUPRESS
         (setq con_tag "NONE")
         (setq con_tag (get_con_tag))
      )
	    (setq con_code _CODE)
    )
  )
  (setq xdlist (bld_fitting _FITTCODE dconsize con_tag nil nil nil))
  (xdatadd ifittent xdlist)
  (setq _TAGSUPRESS nil)
)

;;;--------------------------------------------------------------------
;;;** get_con_dist is a function for retrieving a distance for placing
;;;   conduit length in a block representing conduit traveling up or down
;;;--------------------------------------------------------------------

(defun get_con_dist(spt condir)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     spt            ||    Start point for drag mode is Insertion point
;;;     condir         ||    Text string for presenting direction traveled
;;;     r_dist         ||    Distance to be returned to calling function.
;;;                    ||    Default distance is 0.0.

  (if r_dist
    (setq z_dist r_dist)
    (setq z_dist _MEDDIST)
  )
  (if _PROMPTFORCABLE
    (setq r_dist (getdist spt (strcat "\nLength of Cable traveling " med_dir_con
                                    "<" (rtos z_dist) ">: "))
	  _PROMPTFORCABLE nil
    )
    (setq r_dist (getdist spt (strcat "\nLength of Conduit traveling " med_dir_con
                                    "<" (rtos z_dist) ">: "))
    )
  )
  (if (not r_dist)
    (setq r_dist z_dist)
  )
  (setq _MEDDIST r_dist)
  r_dist
)

;;;--------------------------------------------------------------------
;;;** icon_ins is a function for inserting a independent conduit traveling
;;;   up or down in the Z coordinate direction. Will prompt user for Tag info
;;;   and distance of conduit traveled.
;;;--------------------------------------------------------------------

(defun icon_ins ( iconent pt con_dir / xdlist con_tag condist )
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     iconen t       ||    Entity name of inserted block
;;;     pt             ||    Point for use with drag for distance of conduit
;;;     con_dir        ||    Conduit direction to be traveled
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     con_tag        ||    Conduit tag name used for xdata
;;;     condist        ||    distance used for storing in xdata

   (if (= con_dir 3)
       (setq med_dir_con     "Down")
       (setq med_dir_con     "Up"  )
   )
   (setq condist (get_con_dist pt med_dir_con)
         con_tag (get_con_tag)
   )
   (setq xdlist (bld_conduit _CODE _CSIZE con_tag condist "F"))
   (xdatadd iconent xdlist)
)

;;;--------------------------------------------------------------------
;;;** dcon_ins is a function used for inserting blocks that are dependent
;;;   in size based on the entity inserted on. Will retrieve xdata from
;;;   host entity if exist.
;;;--------------------------------------------------------------------

(defun dcon_ins ( iconent pt con_dir dcon_ss / xdlist dconsize con_tag con_code r_val)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     iconent        ||    Entity name of inserted block
;;;     pt             ||    Point for use with drag for distance of conduit
;;;     con_dir        ||    Conduit direction to be traveled
;;;     dcon_ss		   ||    Dependent entity selection set if exist
;;;                    ||       xdata for tag name, size, and  code will
;;;                    ||       be used
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     dconsize       ||    dependent conduit size
;;;     con_tag        ||    Conduit tag name used for xdata
;;;     con_code	   ||    Conduit code  to be set in xdata
;;;     condist        ||    distance used for storing in xdata

   (if (or (= con_dir 4) (= con_dir 3))
     (progn
       (setq med_dir_con     "Down")
       (if (= con_dir 3)
	 (setq verticaldata (list 0.0 0.0 -1 0.0))
	 (setq verticaldata (list _MEDRADFAC 0.0 -1 0.0))
	)
      )
      (progn
       (setq med_dir_con     "Up")
         (if (= con_dir 6)
	   (setq verticaldata (list 0.0 0.0 1 0.0))
	   (setq verticaldata (list _MEDRADFAC 0.0 1 0.0))
	 )
      )
     
   )
  (if dcon_ss
     (progn
       (setq r_val RL_SS_DATA)
     ) 
  )
  (setq condist (get_con_dist pt med_dir_con))
  (if r_val
      (setq dconsize  (nth 0 r_val)
            con_tag   (nth 1 r_val)
	    con_code  (nth 2 r_val)
      )
      (setq dconsize _CSIZE
            con_tag (get_con_tag)
	    con_code _CODE
      )
  )
  (setq xdlist (bld_conduit con_code dconsize con_tag condist "F"))
  (xdatadd iconent xdlist)
  ;;addin new Ability to identify Conduits travling up or down for 3d Extraction
  (addvtraydata iconent verticaldata)
    
)


;;;--------------------------------------------------------------------
;;;** dfitt_ins is a function for inserting dependent fittings that do
;;;   not require the size of entity inserted upon.
;;;--------------------------------------------------------------------

(defun dfitt_ins(dfittent dcon_ss / xdlist dfittsize r_val)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     ddittent       ||    Entity name of inserted block
;;;     dcon_ss		   ||    Dependent entity selection set if exist
;;;                    ||       xdata for tag name, size, and  code will
;;;                    ||       be used
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     dfittsize      ||    dependent fitting size
;;;     r_val          ||    Result val returned form reteiving enetity data
;;;
  (if dcon_ss
     (progn
       (setq r_val RL_SS_DATA)
     ) 
  )
  (if r_val
      (setq dfittsize (nth 0 r_val)
            con_tag   (nth 1 r_val)
      )
      (setq dfittsize _CSIZE
            con_tag (get_con_tag)
      )

  )
  (setq xdlist (bld_fitting _FITTCODE dfittsize con_tag nil nil nil))
  (xdatadd dfittent xdlist)
)

(defun refitt_ins(dfittent dcon_ss typelist depth / xdlist dfittsize r_val)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     ddittent       ||    Entity name of inserted block
;;;     dcon_ss	       ||    Dependent entity selection set if exist
;;;                    ||       xdata for tag name, size, and  code will
;;;                    ||       be used
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     dfittsize      ||    dependent fitting size
;;;     r_val          ||    Result val returned form reteiving enetity data
;;;
    
  (if dcon_ss
     (progn
       (setq r_val RL_SS_DATA)
     ) 
  )
  (if r_val
      (progn 
         (setq dfittsize (nth 0 r_val)
               con_tag   (nth 1 r_val)
               rfittsize (nth 3 r_val)
         )
               
      )
      (progn
         (setq dfittsize _CSIZE
               con_tag (get_con_tag)
               rfittsize 0.0
         )
         (if typelist
           (setq rsizelist (list 0.50 0.75 1.00
                                 1.25 1.50 2.00
                                 2.50 3.00 3.50
                                 4.00 5.00 6.00
                           )
           )
           (setq rsizelist (list 1.625 1.75 4.00 6.00 9.00 12.0
                                 18.0 24.0 36.0 42.0
                           )
           )
         )
         (if (not depth)
            (setq depth 0.0)
         )
         (while (not (member rfittsize rsizelist))
            (initget 1)
            (setq rfittsize (getreal "\nSize to: "))
         )
      )

  )
  (setq _TYPE nil
        _DEPTH nil
  )
  (setq xdlist (bld_fitting _FITTCODE dfittsize con_tag rfittsize depth nil))
  (xdatadd dfittent xdlist)
)
;
; This function will return a list value of distances for a blockname
; and its rotation specification
;

(defun get_bl_data (med_bl_name / d1 d2 d3 d4)
   (setq bldatafn (strcat _MEDDIR "MEDblck.dat")
         fn       (open bldatafn "r")
         bnamelen (strlen med_bl_name)
   )
   (while (not bl_found)
     (setq lndata (read-line fn))
     (if lndata
         (progn
            (setq tblname (substr lndata 1 8))
            (if (= (strcase (chopspace tblname)) (strcase med_bl_name))
               (setq bl_found T)
            )
         )
         (progn
           (setq bl_found T)
         )
     )
  )
  (setq bl_found nil)
   (if lndata
       (progn
          (setq d1 (atof (substr lndata 10 18))
                d2 (atof (substr lndata 28 18))
                d3 (atof (substr lndata 46 18))
                d4 (atof (substr lndata 64 18))
          )
          (if  (= (substr lndata 82 3) "nil")
             (setq rt_spec nil)
             (setq rt_spec (atoi (substr lndata 82 2)))
          )
       )
       (progn
          (setq d1 0
                d2 0 
                d3 0
                d4 0
                rt_spec 4
          )
          (princ "Not found")
       )
   )
   (close fn)
   (setq rt_list (list d1 d2 d3 d4 rt_spec))
)


(defun cab_ins ( iconent pt con_dir dcon_ss / xdlist dconsize con_tag con_code r_val)
;;;
;;;     Variable Name  ||    Description
;;;     ---------------------------------------------------------------
;;;     iconent        ||    Entity name of inserted block
;;;     pt             ||    Point for use with drag for distance of conduit
;;;     con_dir        ||    Conduit direction to be traveled
;;;     dcon_ss		   ||    Dependent entity selection set if exist
;;;                    ||       xdata for tag name, size, and  code will
;;;                    ||       be used
;;;     xdlist         ||    list of xdata used to attach data to block
;;;     dconsize       ||    dependent conduit size
;;;     con_tag        ||    Conduit tag name used for xdata
;;;     con_code	   ||    Conduit code  to be set in xdata
;;;     condist        ||    distance used for storing in xdata

   (if (not con_dir)
       (setq med_dir_con     "Down")
       (setq med_dir_con     "Up"  )
   )
  (if dcon_ss
     (progn
       (setq r_val (xdataget (ssname dcon_ss 0) _CABLE))
     ) 
  )
  (setq _PROMPTFORCABLE T)
  (setq condist (get_con_dist pt med_dir_con))
  (if r_val
      (setq dconsize  (nth 2 r_val)
            con_tag   (nth 1 r_val)
	    con_code  (nth 3 r_val)
	    cab_rtag  (nth 4 r_val)
      )
      (progn
	 (setq dconsize 1.0
               con_tag (get_con_tag)
	       con_code _CABCODE
         )
	 (if (not _TAGOFF)
           (setq cab_rtag (getstring T "\nCable Relate Tag <NONE>: "))
           (setq cab_rtag "NONE")
         )
         (if (= cab_rtag "")
             (setq cab_rtag "NONE")
         )
      )
  )
  (setq xdlist (bld_cable con_code dconsize con_tag cab_rtag condist "F"))
  
  (xdatadd iconent xdlist)
)
(princ "Done.")
