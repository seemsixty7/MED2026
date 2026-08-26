(princ "\rLoading MEDChg...")
(defun c:MEDCHG-CLASSIC()
   (med_cur_set "c:MEDCHG-CLASSIC")
   (medchg nil)
   (med_ret_ok)
   (princ)
)  
(defun medchg( chg_ent / index_val result)
   (while (not chg_ent)
       (setq chg_ent (car (entsel "\nSelect Entity to change: ")))
   )
   (if (> (setq index_val (load_dialog "MED")) 0)
      (progn
         (if (new_dialog "MED_Change" index_val)
            (progn 
                (app_chg_lst chg_ent T)
                (action_tile "taglist" "(prc_list $value)")
                (action_tile "add_con" "(add_app _CONDUIT)")
                (action_tile "add_cab" "(add_app _CABLE)")
                (action_tile "add_fit" "(add_app _FITTING)")
                (action_tile "add_try" "(add_app _TRAY)")
                (action_tile "add_eqp" "(add_app _EQUIP)")
                (action_tile "edit_msr" "(mod_msr $value)")
                (action_tile "edit_tag" "(mod_tag $value)")
                (action_tile "edit_rtag" "(mod_rtag $value)")
                (action_tile "edit_size" "(prc_size $value)")
                (action_tile "edit_dist" "(mod_dist $value)")
                (action_tile "edit_code" "(mod_code $value)")
                (action_tile "edit_alt"  "(prc_alt_dpth $value ALT_LIST)")
                (action_tile "edit_dpth" "(prc_alt_dpth $value DPTH_LIST)")
                (action_tile "upd_del" "(upd_delete)")
                (action_tile "accept" "(done_dialog 1)")
                (action_tile "cancel" "(done_dialog 0)")

                (setq result (start_dialog))
            )
         )
         (unload_dialog index_val)
         (if (= result 1)
            (upd_tag_list)
         )
      )
   )
   
)
(defun add_app (app_name)
   (setq rtag_list (reverse tag_list)
         ntag_list tag_list
         lapp      (assoc (cons 0 app_name) rtag_list)
         nxt       (dxf 1 lapp)
         last_list nil
         first_list nil
         MED_ADD_APP T
   )
   (if (not nxt)
     (setq nxt -1)
   )
   (cond
      ((= app_name _CONDUIT)
            (setq add2list (list (cons 0 _CONDUIT)
                           (cons 1 (1+ nxt))
                           (cons 2 "MED_CONDUIT | NONE")
                           (cons 3 "NONE")
                           (cons 4 _CSIZE)
                           (cons 6 _CODE)
                           (cons 8 0.0)
                           (cons 9 "F")
                           (cons 12 (getindxfromcode _CODE _CONDUIT))
                           )
            )
      )
      ((= app_name _CABLE)
            (setq add2list (list (cons 0 _CABLE)
                           (cons 1 (1+ nxt))
                           (cons 2 "MED_CABLE | NONE")
                           (cons 3 "NONE")
                           (cons 5 1)
                           (cons 6 _CABCODE)
                           (cons 7 "NONE")
                           (cons 8 0.0)
                           (cons 9 "F")
                           (cons 12 (getindxfromcode _CABCODE _CABLE))
                           )
            )
      )
      ((= app_name _FITTING)
            (setq add2list (list (cons 0 _FITTING)
                           (cons 1 (1+ nxt))
                           (cons 2 "MED_FITTING | NONE")
                           (cons 3 "NONE")
                           (cons 4 _CSIZE)
                           (cons 6 _FITTCODE)
                           (cons 10 0.0)
                           (cons 11 0.0)
                           (cons 12 (getindxfromcode _FITTCODE _FITTING))
                           (cons 13 0.0)
                           )
            )
      )
      ((= app_name _TRAY)
            (setq add2list (list (cons 0 _TRAY)
                           (cons 1 (1+ nxt))
                           (cons 2 "MED_TRAY | NONE")
                           (cons 3 "NONE")
                           (cons 4 _TRSIZE)
                           (cons 6 _TRCODE)
                           (cons 8 0.0)
                           (cons 9 "F")
                           (cons 11 _TRDEPTH)
                           (cons 12 (getindxfromcode _TRCODE _TRAY))
                           (cons 13 _TRAYFLANGE)
                           )
            )
      )
      ((= app_name _EQUIP)
            (setq add2list (list (cons 0 _EQUIP)
                           (cons 1 (1+ nxt))
                           (cons 2 "MED_EQUIP | NONE")
                           (cons 3 "NONE")
                           (cons 6 _EQCODE)
                           (cons 12 (getindxfromcode _EQCODE _EQUIP))
                           )
            )
      )
   )
   (if lapp
      (progn
         (setq last_list (cdr (member lapp tag_list))
               r_len (length last_list)
               len_lst (- (length tag_list) r_len)
               cnt 0
         )
         (while (< cnt len_lst)
            (setq first_list (append first_list (list (nth cnt tag_list)))
                  cnt (1+ cnt)
            )
         )
         (if last_list
            (progn
                 (setq ntag_list(append first_list (list add2list)))
                 (foreach item last_list
                     (setq old (assoc 1 item)
                           new (cons 1 (1+ (dxf 1 item)))
                           nitem (subst new old item)
                           last_list (subst nitem item last_list)
                     )
                 )
                 (setq ntag_list(append ntag_list last_list))
            )
            (progn
                 (setq add2list (subst (cons 1 (length tag_list))
                                       (assoc 1 add2list) add2list)
                       ntag_list(append first_list (list add2list))
                 )
            )
         )
                              
      )
      (progn
         (setq ntag_list(append tag_list (list add2list)))
      )
   )
   (add_tag_list)
)

(defun prc_list(l_index)
   (setq trim 1
         cnt  1
         datalist nil
   )
   (while (= " " (substr l_index trim))
      (setq trim (1+ trim))
   )
   (setq l_index (substr l_index trim))
   (while (setq item (read l_index))
      (setq datalist (append datalist (nth item tag_list)))
      (while (and (/= " " (substr l_index cnt 1))
                  (/= ""  (substr l_index cnt 1))
             )
             (setq cnt (1+ cnt))
      )
      (setq l_index (substr l_index cnt))
   )
   (upd_dlg (dxf 0 datalist))

)

(defun prc_size(l_index)
   (setq trim 1
         cnt  1
         sizelist nil
   )
   (while (= " " (substr l_index trim))
      (setq trim (1+ trim))
   )
   (setq l_index (substr l_index trim))
   (while (setq item (read l_index))
      (setq sizelist (append sizelist (list (nth item SIZE_LIST))))
      (while (and (/= " " (substr l_index cnt 1))
                  (/= ""  (substr l_index cnt 1))
             )
             (setq cnt (1+ cnt))
      )
      (setq l_index (substr l_index cnt))
   )
   (if (> (nth 0 sizelist) 0)
      (progn
         (setq  oldval   (assoc 4 datalist))
         (if (not oldval)
             (setq oldval (assoc 5 datalist)
                   newval (cons 5 (nth 0 sizelist))
             )
             (setq newval   (cons 4 (nth 0 sizelist)))
         )
         (setq  oldlst   datalist
                datalist (subst newval oldval datalist)
                tag_list (subst datalist oldlst tag_list)
         )
      )
   )
   (setq MEDUPD T)
   (upd_dlg (dxf 0 datalist))

)
(defun prc_alt_dpth(l_index listnm)
   (setq trim 1
         cnt  1
         sizelist nil
   )
   (while (= " " (substr l_index trim))
      (setq trim (1+ trim))
   )
   (setq l_index (substr l_index trim))
   (while (setq item (read l_index))
      (setq sizelist (append sizelist (list (nth item listnm))))
      (while (and (/= " " (substr l_index cnt 1))
                  (/= ""  (substr l_index cnt 1))
             )
             (setq cnt (1+ cnt))
      )
      (setq l_index (substr l_index cnt))
   )
   (if (> (nth 0 sizelist) 0)
      (progn
         (if (= listnm ALT_LIST)
            (progn
                (setq oldval (assoc 10 datalist)
                      newval (cons 10 (nth 0 sizelist))
                )
            )
            (progn
                (setq oldval (assoc 11 datalist)
                      newval (cons 11 (nth 0 sizelist))
                )
            )
         )
         (setq  oldlst   datalist
                datalist (subst newval oldval datalist)
                tag_list (subst datalist oldlst tag_list)
         )
      )
   )
   (setq MEDUPD T)
   (upd_dlg (dxf 0 datalist))

)


(defun mod_code(l_index)
   (setq trim 1
         cnt  1
   )
   (while (= " " (substr l_index trim))
      (setq trim (1+ trim))
   )
   (setq l_index (substr l_index trim))
   (while (setq item (read l_index))
      (setq mat_code item)
      (while (and (/= " " (substr l_index cnt 1))
                  (/= ""  (substr l_index cnt 1))
             )
             (setq cnt (1+ cnt))
      )
      (setq l_index (substr l_index cnt))
   )
   (if (> mat_code 0)
     (progn
        (setq oldval (assoc 6 datalist)
              newval (getfromcodelist (dxf 0 datalist) (- mat_code 1))
              newval (cons 6 newval)
              oldlst datalist
              datalist (subst newval oldval datalist)
              oldval (assoc 12 datalist)
              newval (cons 12 (getindxfromcode (dxf 6 datalist)  (dxf 0 datalist)))
              datalist (subst newval oldval datalist)
              tag_list (subst datalist oldlst tag_list)

        )
     )
   )
   (setq MEDUPD T)
   (upd_dlg (dxf 0 datalist))
)
(defun getfromcodelist(codetype codenum)
  (cond
     ((= codetype _CONDUIT)
        (setq bldlstcode _CONCODELIST)
     )
     ((= codetype _TRAY)
        (setq bldlstcode _TRYCODELIST)
     )
     ((= codetype _CABLE)
        (setq bldlstcode _CABCODELIST)
     )
     ((= codetype _FITTING)
        (setq bldlstcode _FITCODELIST)
     )
     ((= codetype _EQUIP)
        (setq bldlstcode _EQPCODELIST)
     )
  )
  (nth codenum bldlstcode)
)  

(defun getindxfromcode(codenum codetype)
  (cond
     ((= codetype _CONDUIT)
        (setq bldlstcode _CONCODELIST)
     )
     ((= codetype _TRAY)
        (setq bldlstcode _TRYCODELIST)
     )
     ((= codetype _CABLE)
        (setq bldlstcode _CABCODELIST)
     )
     ((= codetype _FITTING)
        (setq bldlstcode _FITCODELIST)
     )
     ((= codetype _EQUIP)
        (setq bldlstcode _EQPCODELIST)
     )
  )
  (setq lst_len (length bldlstcode)
        lst_itm (member codenum bldlstcode)
        lst_itm (length lst_itm)
        lst_itm (+ (- lst_len lst_itm) 1)
  )
  lst_itm
)  


(defun bldcodelst()
  (setq codetype (dxf 0 datalist))
  (cond
     ((= codetype _CONDUIT)
        (setq lst_type "_CONLIST")
     )
     ((= codetype _TRAY)
        (setq lst_type "_TRYLIST")
     )
     ((= codetype _CABLE)
        (setq lst_type "_CABLIST")
     )
     ((= codetype _FITTING)
        (setq lst_type "_FITLIST")
     )
     ((= codetype _EQUIP)
        (setq lst_type "_EQPLIST")
     )
  )
  (start_list "edit_code")
  (add_list " ")
  (foreach val (eval (read lst_type))
      (add_list val)
  )
  (end_list)
;  (upd_dlg (dxf 0 (nth 0 tag_list)))

)


(defun app_chg_lst(ent bld_dcl_list)
  (setq app_lst (xd_apps ent)
        all_list nil
        tag_list nil
        tag_indx 0
  )
  (foreach appnm app_lst
     (setq list_app (xdataget ent appnm)
           app_len  (eval (read (strcat "len" (substr appnm 4))))
           num_tags (/ (1- (length list_app)) app_len)
           tag_cnt 0
     )
     (repeat num_tags
       (setq lstcompl nil)
       (setq lst_tag (cons 3 (nth (+ 1 (* app_len tag_cnt)) list_app))
             app_tag (cons 2 (strcat appnm " | " (cdr lst_tag)))
             lst_code(cons 6 (nth (+ 3 (* app_len tag_cnt)) list_app))
       )
       (if (equal lst_code (cons 6 nil))
         (setq lst_code(cons 6 (nth (+ 2 (* app_len tag_cnt)) list_app)))
       )
       (cond
          ((= appnm _CABLE)
            (setq lst_rtag(cons 7 (nth (+ 4 (* app_len tag_cnt)) list_app))
                  lst_siz (cons 5 (nth (+ 2 (* app_len tag_cnt)) list_app))
                  lst_dist(cons 8 (nth (+ 5 (* app_len tag_cnt)) list_app))
                  lst_msr (cons 9 (nth (+ 6 (* app_len tag_cnt)) list_app))
                  lst_indx(cons 12 (getindxfromcode (cdr lst_code) appnm))
                  lstcompl(list (cons 0 appnm) (cons 1 tag_indx)
                                                       app_tag
                                                       lst_tag
                                                       lst_siz
                                                       lst_code
                                                       lst_rtag
                                                       lst_dist
                                                       lst_msr
                                                       lst_indx
                                                       )
            )
          )
          ((= appnm _EQUIP)
            (setq lst_code(cons 6 (nth (+ 2 (* app_len tag_cnt)) list_app))
                  lst_indx(cons 12 (getindxfromcode (cdr lst_code) appnm))
                  lstcompl(list (cons 0 appnm) (cons 1 tag_indx)
                                                       app_tag
                                                       lst_tag
                                                       lst_code
                                                       lst_indx
                                                       )
            )
          )
          
          ((= appnm _CONDUIT)
            (setq lst_siz (cons 4 (nth (+ 2 (* app_len tag_cnt)) list_app))
                  lst_dist(cons 8 (nth (+ 4 (* app_len tag_cnt)) list_app))
                  lst_msr (cons 9 (nth (+ 5 (* app_len tag_cnt)) list_app))
                  lst_indx(cons 12 (getindxfromcode (cdr lst_code) appnm))
                  lstcompl(list (cons 0 appnm) (cons 1 tag_indx)
                                                       app_tag
                                                       lst_tag
                                                       lst_siz
                                                       lst_code
                                                       lst_dist
                                                       lst_msr
                                                       lst_indx
                                                       )

            )
          )
          ((= appnm _TRAY)
            (setq lst_siz (cons 4  (nth (+ 2 (* app_len tag_cnt)) list_app))
                  lst_dist(cons 8  (nth (+ 4 (* app_len tag_cnt)) list_app))
                  lst_msr (cons 9  (nth (+ 6 (* app_len tag_cnt)) list_app))
                  lst_dpth(cons 11 (nth (+ 5 (* app_len tag_cnt)) list_app))
                  lst_indx(cons 12 (getindxfromcode (cdr lst_code) appnm))
                  lst_flng(cons 13 (nth (+ 7 (* app_len tag_cnt)) list_app))
                  lstcompl(list (cons 0 appnm) (cons 1 tag_indx)
                                                       app_tag
                                                       lst_tag
                                                       lst_siz
                                                       lst_code
                                                       lst_dist
                                                       lst_dpth
                                                       lst_msr
                                                       lst_indx
                                                       lst_flng
                                                       )

            )
          )
          ((= appnm _FITTING)
            (setq lst_siz (cons 4  (nth (+ 2 (* app_len tag_cnt)) list_app))
                  lst_alt (cons 10 (nth (+ 4 (* app_len tag_cnt)) list_app))
                  lst_flng(cons 13 (nth (+ 6 (* app_len tag_cnt)) list_app))
                  lst_dpth(cons 11 (nth (+ 5 (* app_len tag_cnt)) list_app))
                  lst_indx(cons 12 (getindxfromcode (cdr lst_code) appnm))
                  mytmpvar lst_indx
                  mytmpvar1 lst_code
                  lstcompl(list (cons 0 appnm) (cons 1 tag_indx)
                                                       app_tag
                                                       lst_tag
                                                       lst_siz
                                                       lst_code
                                                       lst_alt
                                                       lst_dpth
                                                       lst_indx
                                                       lst_flng
                                                       )

            )
          )
       )       
       (setq tag_list (append tag_list (list lstcompl))
                tag_cnt (1+ tag_cnt)
                tag_indx (1+ tag_indx)
        )
     )
     (setq list_app (list list_app)
           all_list (append all_list list_app)
     )
  )
  (if (not tag_list)
    (progn
      (if (or (= (dxf 0 (entget chg_ent)) "POLYLINE") 
              (= (dxf 0 (entget chg_ent)) "LWPOLYLINE") 
          )
          (setq tag_list (list (list (cons 0 _CONDUIT)
                                     (cons 1 0)
                                     (cons 2 "MED_CONDUIT | NONE")
                                     (cons 3 "NONE")
                                     (cons 4 _CSIZE)
                                     (cons 6 _CODE)
                                     (cons 8 0.0)
                                     (cons 9 "T")
                         )     )
          )
          (setq tag_list (list (list (cons 0 _FITTING)
                                     (cons 1 0)
                                     (cons 2 "MED_FITTTING | NONE")
                                     (cons 3 "NONE")
                                     (cons 4 _CSIZE)
                                     (cons 6 _FITTCODE)
                                     (cons 10 0.0)
                                     (cons 11 0.0)
                                     (cons 13 0.0)
                         )     )
          )
      )
    )
  )
  (if bld_dcl_list 
     (progn
       (start_list "taglist")
       (foreach itemtag tag_list
         (add_list (dxf 2 itemtag))
       )
       (end_list)
       (prc_list "0")
     )
  )
  tag_list
)
(defun setdlg_vals(tag rtag size code alt dpth dist txt msr flng / dlgvals)
    (setq dlgvals (list tag
                        rtag
                        size
                        code
                        alt
                        dpth
                        dist
                        txt
                        msr
                        flng
                  )
    )
    dlgvals
)
(defun upd_dlg(chg_code)
   (cond 
     ((= _CONDUIT chg_code)
        (setq vals (setdlg_vals (dxf 3 datalist)
                                nil
                                (list (dxf 4 datalist) _CONDUIT)
                                (dxf 12 datalist)
                                nil
                                nil
                                (list (dxf 8 datalist) (dxf 9 datalist))
                                (clookup (dxf 6 datalist) (dxf 4 datalist) _CONDUIT)
                                (dxf 9 datalist)
                                nil
                   )
        )
     )
     ((= _CABLE chg_code)
        (setq vals (setdlg_vals (dxf 3 datalist)
                                (dxf 7 datalist)
                                (list (dxf 5 datalist) _CABLE)
                                (dxf 12 datalist)
                                nil
                                nil
                                (list (dxf 8 datalist) (dxf 9 datalist))
                                (clookup (dxf 6 datalist) (dxf 5 datalist) _CABLE)
                                (dxf 9 datalist)
                                nil
                   )
        )
     )
     ((= _TRAY chg_code)
        (setq vals (setdlg_vals (dxf 3 datalist)
                                nil
                                (list (dxf 4 datalist) _TRAY)
                                (dxf 12 datalist)
                                nil
                                (dxf 11 datalist)
                                (list (dxf 8 datalist) (dxf 9 datalist))
                                (clookup (dxf 6 datalist) (dxf 4 datalist) _TRAY)
                                (dxf 9 datalist)
                                (dxf 13 datalist)
                   )
        )
     )
     ((= _FITTING chg_code)
        (setq vals (setdlg_vals (dxf 3 datalist)
                                nil
                                (list (dxf 4 datalist) _FITTING)
                                (dxf 12 datalist)
                                (dxf 10 datalist)
                                (dxf 11 datalist)
                                (list nil nil)
                                (clookup (dxf 6 datalist) (dxf 4 datalist) _FITTING)
                                nil
                                (dxf 13 datalist)
                   )
        )
     )
     ((= _EQUIP chg_code)
        (setq vals (setdlg_vals (dxf 3 datalist)
                                nil
                                (list nil nil)
                                (dxf 12 datalist)
                                nil
                                nil
                                (list nil nil)
                                (clookup (dxf 6 datalist) nil _EQUIP)
                                nil
                                nil
                   )
        )
     )
   )
   (cond
     ((= (dxf 0 datalist) _CONDUIT)
        (setsize_lst 1)
     )
     ((= (dxf 0 datalist) _TRAY)
        (setsize_lst 2)
     )
     ((= (dxf 0 datalist) _CABLE)
        (setsize_lst 3)
     )
     ((= (dxf 0 datalist) _FITTING)
        (setsize_lst 4)
     )
     ((= (dxf 0 datalist) _EQUIP)
        (setsize_lst 5)
     )
   )
   (chg_edit_tag (nth 0 vals))
   (chg_edit_rtag(nth 1 vals))
   (chg_edit_size(nth 2 vals))
   (chg_edit_code(nth 3 vals))
   (chg_edit_alt (nth 4 vals))
   (chg_edit_dpth(nth 5 vals))
   (chg_edit_dist(nth 6 vals))
   (chg_edit_text(nth 7 vals))
   (chg_edit_msr(nth 8 vals))
    
)
(defun chg_edit_tag(n_value)
   (set_tile "edit_tag" n_value)
)
(defun chg_edit_rtag(n_value)
   (if n_value
      (progn
        (mode_tile "edit_rtag" 0)
        (set_tile "edit_rtag" n_value)
        (mode_tile "rtag_txt" 0)

      )
      (progn
        (set_tile "edit_rtag" " ")
        (mode_tile "edit_rtag" 1)
        (mode_tile "rtag_txt" 1)
      )
   )
)
(defun chg_edit_size(n_value)
   (if (nth 0 n_value)
      (progn
        (cond
           ((= (nth 1 n_value) _CONDUIT)
              (setq  nvalue (nth 4 (getsize nil (rtos (nth 0 n_value) 4))))
			  (set_tile "size_txt" "Size:")
           )
           ((= (nth 1 n_value) _FITTING)
              (setq lstlen (length SIZE_LIST)
                    lstpos (member (nth 0 n_value) SIZE_LIST)
                    lstpos (- lstlen (length lstpos))
                    nvalue (itoa lstpos)
              )
			  (set_tile "size_txt" "Size:")
           )
           ((= (nth 1 n_value) _CABLE)
              (setq nvalue (itoa (fix (nth 0 n_value))))
			  (set_tile "size_txt" "Number:")
           )
           ((= (nth 1 n_value) _TRAY)
              (setq nvalue (nth 4 (getsize nil (nth 0 n_value))))
			  (set_tile "size_txt" "Size:")
           )
        )
        (mode_tile "edit_size" 0)
        (mode_tile "size_txt" 0)
        (set_tile "edit_size" nvalue)

      )
      (progn
        (set_tile "edit_size" "0")
        (mode_tile "edit_size" 1)
        (mode_tile "size_txt"  1)
      )
   )
)
(defun chg_edit_alt(n_value)
   (if n_value
      (progn
        (setq len1 (length ALT_LIST)
              len2 (length (member n_value ALT_LIST))
              nvalue (itoa (- len1 len2))
        )
        (mode_tile "edit_alt" 0)
        (mode_tile "alt_txt" 0)
        (set_tile "edit_alt" nvalue)

      )
      (progn
        (set_tile "edit_alt" "0")
        (mode_tile "edit_alt" 1)
        (mode_tile "alt_txt"  1)
      )
   )
)
(defun chg_edit_dpth(n_value)
   (if n_value
      (progn
        (setq len1 (length DPTH_LIST)
              len2 (length (member n_value DPTH_LIST))
              nvalue (itoa (- len1 len2))
        )
        (mode_tile "edit_dpth" 0)
        (mode_tile "dpth_txt" 0)
        (set_tile "edit_dpth" nvalue)

      )
      (progn
        (set_tile "edit_dpth" "0")
        (mode_tile "edit_dpth" 1)
        (mode_tile "dpth_txt"  1)
      )
   )
)

(defun chg_edit_dist(n_value)
   (if (and (nth 0 n_value) (/= (nth 1 n_value) "T"))
      (progn
         (mode_tile "edit_dist" 0)
         (mode_tile "dist_txt"  0)
         (set_tile "edit_dist" (rtos (nth 0 n_value)))
      )
      (progn
         (set_tile "edit_dist" " ")
         (mode_tile "edit_dist" 1)
         (mode_tile "dist_txt"  1)
      )
   )
)
(defun chg_edit_code(n_value)
   (if n_value
      (progn
         (mode_tile "edit_code" 0)
         (set_tile "edit_code" (itoa n_value))
      )
      (progn
         (set_tile "edit_code" "0")
         (mode_tile "edit_code" 1)
      )
   )
)

(defun chg_edit_text(n_value)
   (set_tile "edit_text" n_value)
)

(defun chg_edit_msr(n_value)
   (if n_value
      (progn
         (if (= n_value "T")
            (setq n_value "1")
            (setq n_value "0")
         )
         (mode_tile "edit_msr" 0)
         (set_tile "edit_msr" n_value)
      )
      (progn
         (set_tile "edit_msr" "0")
         (mode_tile "edit_msr" 1)
      )
   )
)

(defun mod_tag(n_value)
   (setq lstindx (dxf 1 datalist)
         lstapp  (dxf 0 datalist)
         oldval  (nth 2 datalist)
         newval  (cons 2 (strcat lstapp " | " n_value))
         oldlst  datalist
         datalist(subst newval oldval datalist)
         oldval  (nth 3 datalist)
         newval  (cons 3 n_value)
         datalist(subst newval oldval datalist)
         tag_list(subst datalist oldlst tag_list)
   )
   (start_list "taglist")
   (foreach itemtag tag_list
      (add_list (dxf 2 itemtag))
   )
   (end_list)
   (setq MEDUPD T)

   (set_tile "taglist" (itoa lstindx))
)
(defun mod_rtag(n_value)
   (setq lstindx (dxf 1 datalist)
         lstapp  (dxf 0 datalist)
         oldval  (assoc 7 datalist)
         newval  (cons 7 n_value)
         oldlst  datalist
         datalist(subst newval oldval datalist)
         tag_list(subst datalist oldlst tag_list)
   )
   (setq MEDUPD T)
)

(defun mod_dist (n_value)
   (if (> (atof n_value) 0.0)
     (progn
        (setq oldval   (assoc 8 datalist)
              newval   (distof n_value)
        )
        (if (not newval)
            (setq newval oldval)
            (setq newval (cons 8 newval))
        )
        (setq oldlst   datalist
              datalist (subst newval oldval datalist)
              tag_list (subst datalist oldlst tag_list)
        )
     )
   )
   (setq MEDUPD T)
   (upd_dlg (dxf 0 datalist))
)

(defun mod_msr (n_value)
   (if (= n_value "0")
      (setq n_value "F")
      (setq n_value "T")
   )
   (if (or (= (dxf 0 (entget chg_ent)) "POLYLINE")
           (= (dxf 0 (entget chg_ent)) "LWPOLYLINE")
       )
     (progn
        (setq oldval   (assoc 9 datalist)
              newval   (cons 9 n_value)
              oldlst   datalist
              datalist (subst newval oldval datalist)
              tag_list (subst datalist oldlst tag_list)
        )
     )
   )
   (setq MEDUPD T)
   (upd_dlg (dxf 0 datalist))
)

(defun upd_tag_list()
   (unload_dialog index_val)
   (if MEDUPD
     (progn
        (setq num (length tag_list)
              trans_lst nil
              nw_list nil
              wk_list nil
              currlist nil
              cnt 0
        )
        (repeat num
            (setq wk_list (nth cnt tag_list)
                  wk_app  (dxf 0 wk_list)
                  wk_tag  (dxf 3 wk_list)
                  wk_code (dxf 6 wk_list)
                  nw_list (list wk_tag)
                  work_list wk_list
            )
            (cond
               ((= (dxf 2 wk_list) "DELETED")
                  (setq nw_list nil)
                  (xdstrip chg_ent wk_app)
               )
               ((= wk_app _CABLE)
                  (setq wk_size (dxf 5 wk_list)
                        wk_last (dxf 7 wk_list)
                        wk_dist (dxf 8 wk_list)
                        wk_msr  (dxf 9 wk_list)
                        nw_list (append nw_list (list wk_size
                                                      wk_code
                                                      wk_last
                                                      wk_dist
                                                      wk_msr))
                  )
               )
               ((= wk_app _CONDUIT)
                  (setq wk_size (dxf 4 wk_list)
                        wk_dist (dxf 8 wk_list)
                        wk_msr  (dxf 9 wk_list)
                        nw_list (append nw_list (list wk_size
                                                      wk_code
                                                      wk_dist
                                                      wk_msr))
                  )
               )
               ((= wk_app _FITTING)
                  (setq wk_size (dxf 4 wk_list)
                        wk_alt  (dxf 10 wk_list)
                        wk_dpth (dxf 11 wk_list)
                        wk_flng (dxf 13 wk_list)
                        nw_list (append nw_list (list wk_size
                                                      wk_code
                                                      wk_alt
                                                      wk_dpth wk_flng))
                  )
               )
               ((= wk_app _TRAY)
                  (setq wk_size (dxf 4 wk_list)
                        wk_dist (dxf 8 wk_list)
                        wk_msr  (dxf 9 wk_list)
                        wk_dpth (dxf 11 wk_list)
                        wk_flng (dxf 13 wk_list)
                        nw_list (append nw_list (list wk_size
                                                      wk_code
                                                      wk_dist
                                                      wk_dpth
                                                      wk_msr wk_flng))
                  )
               )
               ((= wk_app _EQUIP)
                  (setq nw_list (append nw_list (list wk_code))
                  )
               )

            )
            (if nw_list
              (progn
                 (if (setq currlist (assoc wk_app trans_lst))
                   (progn
                     (setq nw_list (append currlist nw_list)
                           trans_lst (subst nw_list currlist trans_lst)
                     )
                   )
                   (progn
                     (setq nw_list (append (list wk_app) nw_list)
                           trans_lst (append trans_lst (list nw_list))
                     )
                   )
                 )
              )
            )
            (setq cnt (1+ cnt))
        )
        (setq upd_num (length trans_lst)
              upd_cnt 0
        )
        (while (< upd_cnt upd_num)
           (setq wk_list   (nth upd_cnt trans_lst)
                 wk_len    (length wk_list)
                 wk_app    (nth 0 wk_list)
                 wk_applen (eval (read (strcat "LEN_" (substr wk_app 5))))
                 wk_taglen (/ (1- wk_len) wk_applen)
                 wk_cnt    0
                 wk_size nil
                 wk_tag nil
                 wk_rtag nil
                 wk_code nil
                 wk_dist nil
                 wk_msr nil
                 wk_alt nil
                 wk_dpth nil
                 wk_flng nil

           )
           (while (< wk_cnt wk_taglen)
              (cond
                  ((= wk_app _CABLE)
                     (setq wk_size (append wk_size (list (nth (+ 2 (* wk_cnt wk_applen)) wk_list)))
                           wk_code (append wk_code (list (nth (+ 3 (* wk_cnt wk_applen)) wk_list)))
                           wk_tag  (append wk_tag  (list (nth (+ 1 (* wk_cnt wk_applen)) wk_list)))
                           wk_rtag (append wk_rtag (list (nth (+ 4 (* wk_cnt wk_applen)) wk_list)))
                           wk_dist (append wk_dist (list (nth (+ 5 (* wk_cnt wk_applen)) wk_list)))
                           wk_msr  (append wk_msr  (list (nth (+ 6 (* wk_cnt wk_applen)) wk_list)))
                     )
                  )
                  ((= wk_app _CONDUIT)
                     (setq wk_size (append wk_size (list (nth (+ 2 (* wk_cnt wk_applen)) wk_list)))
                           wk_code (append wk_code (list (nth (+ 3 (* wk_cnt wk_applen)) wk_list)))
                           wk_tag  (append wk_tag  (list (nth (+ 1 (* wk_cnt wk_applen)) wk_list)))
                           wk_dist (append wk_dist (list (nth (+ 4 (* wk_cnt wk_applen)) wk_list)))
                           wk_msr  (append wk_msr  (list (nth (+ 5 (* wk_cnt wk_applen)) wk_list)))
                     )
                  )
                  ((= wk_app _TRAY)
                     (setq wk_size (append wk_size (list (nth (+ 2 (* wk_cnt wk_applen)) wk_list)))
                           wk_code (append wk_code (list (nth (+ 3 (* wk_cnt wk_applen)) wk_list)))
                           wk_tag  (append wk_tag  (list (nth (+ 1 (* wk_cnt wk_applen)) wk_list)))
                           wk_dist (append wk_dist (list (nth (+ 4 (* wk_cnt wk_applen)) wk_list)))
                           wk_dpth (append wk_dpth (list (nth (+ 5 (* wk_cnt wk_applen)) wk_list)))
                           wk_msr  (append wk_msr  (list (nth (+ 6 (* wk_cnt wk_applen)) wk_list)))
                           wk_flng (append wk_flng  (list (nth (+ 7 (* wk_cnt wk_applen)) wk_list)))
                     )
                  )
                  ((= wk_app _FITTING)
                     (setq wk_size (append wk_size (list (nth (+ 2 (* wk_cnt wk_applen)) wk_list)))
                           wk_code (append wk_code (list (nth (+ 3 (* wk_cnt wk_applen)) wk_list)))
                           wk_tag  (append wk_tag  (list (nth (+ 1 (* wk_cnt wk_applen)) wk_list)))
                           wk_alt  (append wk_alt  (list (nth (+ 4 (* wk_cnt wk_applen)) wk_list)))
                           wk_dpth (append wk_dpth (list (nth (+ 5 (* wk_cnt wk_applen)) wk_list)))
                           wk_flng (append wk_flng  (list (nth (+ 6 (* wk_cnt wk_applen)) wk_list)))
                     )
                  )
                  ((= wk_app _EQUIP)
                     (setq wk_code (append wk_code (list (nth (+ 2 (* wk_cnt wk_applen)) wk_list)))
                           wk_tag  (append wk_tag  (list (nth (+ 1 (* wk_cnt wk_applen)) wk_list)))
                     )
                  )
              )
              (setq wk_cnt (1+ wk_cnt))
           )
           (cond
               ((= wk_app _CABLE)
                  (setq xdlist (bld_cable wk_code wk_size wk_tag wk_rtag wk_dist wk_msr))
                  (xdatadd chg_ent xdlist)
               )
               ((= wk_app _CONDUIT)
                  (setq xdlist (bld_conduit wk_code wk_size wk_tag wk_dist wk_msr))
                  (xdatadd chg_ent xdlist)
               )
               ((= wk_app _TRAY)
                  (setq xdlist (bld_tray wk_code wk_size wk_tag wk_dist wk_dpth wk_msr wk_flng))
                  (xdatadd chg_ent xdlist)
               )
               ((= wk_app _FITTING)
                  (setq xdlist (bld_fitting wk_code wk_size wk_tag wk_alt wk_dpth wk_flng))
                  (xdatadd chg_ent xdlist)
               )
               ((= wk_app _EQUIP)
                  (setq xdlist (bld_equip wk_code wk_tag))
                  (xdatadd chg_ent xdlist)
               )
           )
           (setq upd_cnt (1+ upd_cnt))
        )
     )
   )
)

(defun add_tag_list()
   (if MED_ADD_APP
     (progn 
       (setq MED_ADD_APP nil
             tag_list ntag_list
       )
       (start_list "taglist")
       (foreach itemtag tag_list
          (add_list (dxf 2 itemtag))
       )
       (end_list)
       (prc_list "0")
       (upd_dlg (dxf 0 (nth 0 tag_list)))
     )
   )
)
(defun upd_delete()
   (setq old_lst datalist
         new_list (subst (cons 2 "DELETED") (assoc 2 datalist) datalist)
         tag_list (subst new_list old_lst tag_list)
   )
   (start_list "taglist")
   (foreach itemtag tag_list
      (add_list (dxf 2 itemtag))
   )
   (end_list)
   (prc_list "0")
   (upd_dlg (dxf 0 (nth 0 tag_list)))
)



(defun setsize_lst(val)
   (cond
     ((= val 1)
        (setq SIZE_LIST (list 0.0 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0))
        (start_list "edit_size")
        (add_list " ")
        (foreach val (cdr SIZE_LIST)
          (add_list (rtos val 2 4))
        )
        (end_list)
     )
     ((= val 2)
        (setq SIZE_LIST (list 0.0 1.625 4.0 6.00 9.00 12.00 18.00 24.00 30.00 36.00 42.0 48.0)
              DPTH_LIST (list 0.0 1.625 1.75 3.0 4.0 6.0)
        )
        (start_list "edit_size")
        (add_list " ")
        (foreach val (cdr SIZE_LIST)
          (add_list (rtos val 2 4))
        )
        (end_list)
        
        (start_list "edit_dpth")
        (foreach val DPTH_LIST
          (add_list (rtos val 2 4))
        )
        (end_list)
     )
     ((= val 3)
        (setq cnt 0.0
              SIZE_LIST nil
        )
        (repeat 50
          (setq SIZE_LIST (append SIZE_LIST (list cnt))
                cnt (+ 1.0 cnt)
          )
        )
        (start_list "edit_size")
        (add_list " ")
        (foreach val (cdr SIZE_LIST)
          (add_list (rtos val 2 4))
        )
        (end_list)

     )
     ((= val 4)
        (setq SIZE_LIST (list 0.0 0.5 0.75 1.0 1.25 1.5 1.625 1.75 
                              2.0 2.5 3.0 3.5 4.0 5.0 6.0 9.00 12.00
                              18.00 24.00 30.0 36.0 42.0 48.0
                        )
              currsz (dxf 4 datalist)
              ALT_LIST  (reverse (cdr (member currsz (reverse SIZE_LIST))))
              DPTH_LIST (list 0.0 1.625 1.75 3.0 4.0 6.0)
        )
        (start_list "edit_size")
        (add_list " ")
        (foreach val (cdr SIZE_LIST)
          (add_list (rtos val 2 4))
        )
        (end_list)
        
        (start_list "edit_dpth")
        (foreach val DPTH_LIST
          (add_list (rtos val 2 4))
        )
        (end_list)

        (start_list "edit_alt")
        (foreach val ALT_LIST
          (add_list (rtos val 2 4))
        )
        (end_list)

     )
   )
   (bldcodelst)
)

(defun bld_list(listvar cnt)
  (setq num (length listvar)
        rlist nil
  )
  (while (< cnt num)
    (setq rlist (append rlist (list (nth cnt listvar))))
    (setq cnt (+ 2 cnt))
  )
  rlist
)

(setq tlist (bld_data_list "CONDUIT"))
(setq _CONCODELIST (bld_list tlist 1)
      _CONLIST     (bld_list tlist 0)
)
(setq tlist (bld_data_list "CABLE"))
(setq _CABCODELIST (bld_list tlist 1)
      _CABLIST     (bld_list tlist 0)
)
(setq tlist (bld_data_list "TRAY"))
(setq _TRYCODELIST (bld_list tlist 1)
      _TRYLIST     (bld_list tlist 0)
)
(setq tlist (bld_data_list "FITTING"))
(setq _FITCODELIST (bld_list tlist 1)
      _FITLIST     (bld_list tlist 0)
)
(setq tlist (bld_data_list "EQUIP"))
(setq _EQPCODELIST (bld_list tlist 1)
      _EQPLIST     (bld_list tlist 0)
)



(defun c:MED() (vl-cmdf "MEDCHG") (princ))

(princ "Done.")
