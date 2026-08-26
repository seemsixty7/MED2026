(vl-load-com)
(setvar "MENUECHO" 1)
(setvar "CMDECHO" 0)
(setvar "MENUCTL" 0)


(defun getmeddir (medprojectlineno) ;Argument passed is the line number of the setting desired
    (setq projectfile (findfile "project.dat"))
    (if (not projectfile)
      (princ "\nCould not find PROJECT.DAT file. Possibly due to MED environment not set up correctly!")
      (progn
	(setq ofn (open projectfile "r")
	      meddirinfo (list (read-line ofn))
	      meddirinfo (append meddirinfo (list (read-line ofn)))
	      meddirinfo (append meddirinfo (list (read-line ofn)))
	      meddirinfo (append meddirinfo (list (read-line ofn)))
              meddirinfo (append meddirinfo (list (read-line ofn)))
	)
	(close ofn)
      )

    )
    (nth medprojectlineno meddirinfo)
)

;(load "MEDVariables")
;(load "MEDTray.fas")
;(load "MEDCon.fas")
;(load "MEDWire.fas")
;(load "MEDSetup.fas")
;(load "MEDFunctions.fas")
;(load "MEDDatabase")
;(load "MEDCommands.fas")
;(load "MEDMainDialogs.fas")
;(load "MEDCable.fas")
;(load "MEDCableTray.fas")
;(load "MEDBuildXData.fas")
;(load "MEDDim.fas")
;(load "MED3DTrayFunctions.fas")
;(load "MEDChg.fas")
;(load "MEDDetl.fas")
;(load "MEDInser.fas")
;(load "MEDText.fas")
;(load "MEDTag.fas")
;(load "medutil.fas")
;(load "MED3DMisc.fas")
;(load "MED3DConduit.fas")

;;MEDCore.lsp             ;Checked 02/05/2022
(load "MEDVariables")     ; Chedcked 02/05/2022
(load "MEDTray.lsp")      ;Checked 02/05/2022
(load "MEDCon.lsp")       ;Checked 02/05/2022
(load "MEDWire.lsp")      ;Checked 02/05/2022
(load "MEDSetup.lsp")     ;Checked 02/05/2022
(load "MEDFunctions.lsp") ; Checked 02/05/2022
(load "MEDTextStyles.lsp") ; Cehcked 02/05/2022
(load "MEDDatabase")      ;Checked 02/05/2022
(load "MEDCommands.lsp")  ; Checked 02/05/2022
;(load "MEDMainDialogs.lsp") ; Checked 02/05/2022  ; renamed RedoWithCSharp, skip until C# UI
(load "MEDCable.lsp")     ; checked 02/05/2022
(load "MEDCableTray.lsp") ; Checked 02/05/2022
(load "MEDBuildXData.lsp");Checked 02/05/2022
(load "MEDDim.lsp")       ;Checked 02/05/2022
(load "MED3DTrayFunctions.lsp") ;Checked 02/05/2022
(load "MEDChg.lsp")       ;Checked 02/05/2022
(load "MEDDetl.lsp")      ;Checked 02/05/2022
(load "MEDInser.lsp")     ;Checked 02/05/2022
(load "MEDText.lsp")      ;Checked 02/05/2022
(load "MEDTag.lsp")      ;Checked 02/05/2022
(load "medutil.lsp")     ;Checked 02/05/2022
(load "MED3DMisc.lsp")   ;Checked 02/05/2022
(load "med.spc")         ;Checked 02/05/2022

(if (/= (getvar "USERR2") 0.0)
   (setq _PLOTSCALE (getvar "USERR2"))
   (setq _PLOTSCALE 1.0)
)

(defun MED_cur_set (CommandName)
	(setq nothing nil)
)

(setq   _ELEC     "MED_ELEC"
        _FITTING  "MED_FITTING"
        _CONDUIT  "MED_CONDUIT"
        _RELATE   "MED_RELATE"
        _ATTRIB   "MED_ATTRIB"
        _DOUBLE   "MED_DOUBLE"
        _CABLE    "MED_CABLE"
        _TRAY     "MED_TRAY"
        _EQUIP    "MED_EQUIP"
)
(regapp "MED_ELEC")
(regapp "MED_FITTING") (setq len_fitting 6)
(regapp "MED_CONDUIT") (setq len_conduit 5)
(regapp "MED_TRAY")    (setq len_tray    7)
(regapp "MED_EQUIP")   (setq len_equip   2)
(regapp "MED_RELATE")
(regapp "MED_ATTRIB")
(regapp "MED_DOUBLE")
(regapp "MED_CABLE")   (setq len_cable   6)
(regapp "VERT_DATA")

;;;Set MED Document Variable
;;Left for last incase of error
(setq meddirdata(mparse _MEDDIR "\\" nil nil)
      meddirlen (length meddirdata)
      meddocdir ""
      meddircnt 0
)
(repeat (1- meddirlen)
   (setq meddocdir (strcat meddocdir (nth meddircnt meddirdata) "/")
         meddircnt (1+ meddircnt)
   )
)
(setq meddocdir  (strcat meddocdir "Tutorial")
      _MEDDOCFILE(strcat meddocdir "/" "MEDDOCS.HTM")
      meddirdata nil
      meddirlen nil
      meddocdir nil
      meddircnt nil

)
