(princ "\rLoading MEDBuildXData...")
(defun bld_app (bld_appnm bld_code bld_size bld_tag bld_rtag bld_dist bld_alt 
                bld_dpth bld_msr bld_flg / bld_xdlist)
     (if (= (type bld_code) 'LIST)
       (progn
          (setq bldnum (length bld_code)
                bldcnt 0
          )
          (setq bld_xdlist (list bld_appnm (cons 1002 "{")))
          (while (< bldcnt bldnum)
            (setq bld_xdlist (append bld_xdlist 
              (list (cons 1000 (strcat "ITEM_TAG_="  (nth bldcnt bld_tag)))))
            )
            (if bld_size
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "#ITEMSIZE=" (rtos (nth bldcnt bld_size) 2 4)))))
              )
            )
            (if bld_code
			  (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "#ITEMCODE=" (itoa (nth bldcnt bld_code))))))
              )
            )
			(if bld_rtag
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "ITEM_RTAG=" (nth bldcnt bld_rtag)))))
              )
            )
            (if bld_dist
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "#ITEMDIST=" (rtos (nth bldcnt bld_dist) 2)))))   
              )
            )
            (if bld_alt
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "#ITEM_ALT=" (rtos (nth bldcnt bld_alt) 2 4)))))
              )
            )
	        (if bld_dpth
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "#ITEMDPTH=" (rtos (nth bldcnt bld_dpth) 2 4)))))
              )
            )
            (if bld_msr
              (setq bld_xdlist (append bld_xdlist
               (list (cons 1000 (strcat "ITEM_MESR=" (nth bldcnt bld_msr)))))
              )
            )
            (if bld_flg
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "#ITEMFLNG=" (rtos (nth bldcnt bld_flg) 2 4)))))
              )
            )
            (setq bldcnt (1+ bldcnt))
          )
          (setq bld_xdlist (append bld_xdlist (list (cons 1002 "}"))))
       )
       (progn
          (if (or (= bld_appnm _CONDUIT)
                  (= bld_appnm _CABLE)
                  (= bld_appnm _TRAY)
              )
              (progn
                (if bld_dist
                   (setq bld_msr "F")
                   (setq bld_msr "T"
                         bld_dist 0.0
                   )
                )
              )
          )
          (setq bld_xdlist (list bld_appnm (cons 1002 "{")
		  	                  (cons 1000 (strcat "ITEM_TAG_="   bld_tag)))
          )
          (if bld_size
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "#ITEMSIZE=" (rtos bld_size 2 4)))))
              )
          )
          (if bld_code
			  (setq bld_xdlist (append bld_xdlist
						  (list (cons 1000 (strcat "#ITEMCODE=" (itoa bld_code)))))
              )
          )
          (if bld_rtag
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "ITEM_RTAG=" bld_rtag))))
              )
          )
          (if bld_dist
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "#ITEMDIST=" (rtos bld_dist 2)))))
              )
          )
          (if bld_alt
			  (setq bld_xdlist (append bld_xdlist
					      (list (cons 1000 (strcat "#ITEM_ALT=" (rtos bld_alt 2 4 )))))
              )
          )
          (if bld_dpth
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "#ITEMDPTH=" (rtos bld_dpth 2 4 )))))
              )
          )
          (if bld_msr
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "ITEM_MESR=" bld_msr))))
              )
          )
           (if bld_flg
			  (setq bld_xdlist (append bld_xdlist
                          (list (cons 1000 (strcat "#ITEMFLNG=" (rtos bld_flg 2 4)))))
              )
          )
	  (setq bld_xdlist (append bld_xdlist (list (cons 1002 "}"))))
       )
     )
     bld_xdlist
)
; function bulids data to be placed into conduits

(defun bld_conduit (bld_code bld_size bld_tag bld_dist bld_msr / bld_xdlist)
   (setq bld_xdlist 
         (bld_app _CONDUIT
                  bld_code
                  bld_size
                  bld_tag
                  nil
                  bld_dist
                  nil
                  nil
                  bld_msr
                  nil
         )
   )
)




; function bulids replacement data to be placed into cables

(defun bld_cable (bld_code bld_size bld_tag bld_rtag bld_dist bld_msr / bld_xdlist)
   (setq bld_xdlist 
         (bld_app _CABLE
                  bld_code
                  bld_size
                  bld_tag
                  bld_rtag
                  bld_dist
                  nil
                  nil
                  bld_msr
                  nil
         )
   )
)
; function bulids replacement data to be placed into cable trays

(defun bld_tray (bld_code bld_size bld_tag bld_dist bld_dpth bld_msr bld_flange / bld_xdlist)
   (setq bld_xdlist 
         (bld_app _TRAY
                  bld_code
                  bld_size
                  bld_tag
                  nil
                  bld_dist
                  nil
                  bld_dpth
                  bld_msr
                  bld_flange
         )
   )
)

; function bulids replacement data to be placed into fittings

(defun bld_fitting (bld_code bld_size bld_tag bld_alt bld_dpth bld_flange / bld_xdlist)
   (if (not bld_alt)
      (setq bld_alt 0.0)
   )
   (if (not bld_dpth)
      (setq bld_dpth 0.0)
   )
   (if (not bld_flange)
      (setq bld_flange 0.0)
   )
   (setq bld_xdlist 
         (bld_app _FITTING
                  bld_code
                  bld_size
                  bld_tag
                  nil
                  nil
                  bld_alt
                  bld_dpth
                  nil
                  bld_flange
         )
   )
)

(defun bld_equip (bld_code bld_tag / bld_xdlist)
   (setq bld_xdlist 
         (bld_app _EQUIP
                  bld_code
                  nil
                  bld_tag
                  nil
                  nil
                  nil
                  nil
                  nil
                  nil
         )
   )
)
(princ "Done.")
