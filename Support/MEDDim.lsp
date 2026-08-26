(princ "\rLoading MEDDim...")
(defun GetDimStyleVariable (gdsv-stylename gdsv-dimvariable)
   (setq gdsv-AcadObject
           (vlax-get-acad-object)
         gdsv-CurrentDwg
           (vla-get-activedocument gdsv-AcadObject)
         gdsv-ActiveDimStyle
           (vla-get-ActiveDimStyle gdsv-CurrentDwg)
         gdsv-ReturnValue
           nil
   )
   (if (tblsearch "dimstyle" gdsv-stylename nil)
      (progn
         (setq gdsv-NewActiveDimstyle
                 (vla-item (vla-get-dimstyles
                              gdsv-CurrentDwg
                           )
                           gdsv-stylename
                 )
         )
         (vla-put-activedimstyle gdsv-CurrentDwg gdsv-NewActiveDimStyle)
         (setq gdsv-ReturnValue (getvar gdsv-dimvariable))
         (vla-put-activedimstyle gdsv-CurrentDwg gdsv-ActiveDimStyle)
      )
   )
   gdsv-ReturnValue
)	
	
(defun SetDimstyleVariable (udv-stylename udv-variable udv-newvalue)
   (setq udv-AcadObject     (vlax-get-acad-object)
         udv-CurrentDwg     (vla-get-activedocument udv-AcadObject)
         udv-ActiveDimStyle (vla-get-ActiveDimStyle udv-CurrentDwg)
   )
   (if (tblsearch "dimstyle" udv-stylename nil)
      (progn
         (setq udv-NewActiveDimstyle
                 (vla-item
                    (vla-get-dimstyles udv-CurrentDwg)
                    udv-stylename
                 )
         )
         (vla-put-activedimstyle udv-CurrentDwg udv-NewActiveDimStyle)
         (setvar udv-variable udv-newvalue)
         (vla-CopyFrom udv-NewActiveDimstyle udv-CurrentDwg)
         (vla-put-activedimstyle udv-CurrentDwg udv-ActiveDimStyle)
      )
   )
)


(defun c:MEDDIMSETUP ()
   (if
      (not
         (tblsearch "STYLE" (nth 1 (assoc "T1" MED_TXT_STYLE_MAP)) nil)
      )
        (c:loadtxt)
   )
   (setq dimspc            "Standard"
         dimentry          (assoc dimspc UEI_DIMSETTINGS)
         dimlayer          (nth 1 dimentry)
         dimvars           (cddr dimentry)
         AcadObject        (vlax-get-acad-object)
         CurrentDwg        (vla-get-activedocument AcadObject)
         ActiveDimStyle    (vla-get-ActiveDimStyle CurrentDwg)
         NewActiveDimstyle (vla-item (vla-get-dimstyles CurrentDwg) dimspc)
   )
   (vla-put-activedimstyle CurrentDwg NewActiveDimStyle)
   (foreach dimvar dimvars
      (setq varname  (nth 0 dimvar)
            varvalue (nth 1 dimvar)
      )
      (setvar varname varvalue)
   )
   (vla-CopyFrom NewActiveDimstyle CurrentDwg)
                                        ; (to from) not from to methodolgy
)

(defun C:IOD ( /
					All_Dimensions
					LayerTable
					FakeDimensionLayer
					DimensionDefinition
					DimensionText
   		     )
   	(princ "\nStarting")
   (if (setq All_Dimensions (ssget "X" '((0 . "DIMENSION"))))
      (progn
         (setq DimensionCounter         0
               IsolatedDimensionCounter 0
               FakeDimensionLayer       "_Faked Dimensions"
         )
         (princ ".")
         (while (< DimensionCounter (sslength All_Dimensions))
         	 (princ "+")
         	 (smlayer (list fakeDimensionLayer 30 "Continuous"))
            (while (setq DimensionObject (ssname All_Dimensions DimensionCounter))
            	            	(princ "-")
               (setq Dimension             (vlax-ename->vla-Object DimensionObject)
                     DimensionTextOverride (vlax-get Dimension "TextOverride")
               )
               (if (not (or (= DimensionTextOverride "")
                            (wcmatch DimensionTextOverride "*<>*")
                            (wcmatch DimensionTextOverride "*NTS*")
                            (= (vla-getxdata (vlax-ename->vla-object Dimension
                                                "ACAD_DSTYLE_DIMJAG_POSITION"
                                             )
                               )
                            )
                        )
                    )
                  (progn
                     (setq TrueMeasurement (vlax-get-property Dimension
                                              "Measurement"
                                           )
                     )
                     (vlax-put-property Dimension "TextOverride"
                        (strcat DimensionTextOverride "\\X[ <> ]")
                     )
                     (vla-put-layer Dimension FakeDimensionLayer)
                     ;(vla-put-color Dimension 256)
                     (vlax-release-object Dimension)
                     (setq IsolatedDimensionCounter (1+ IsolatedDimensionCounter))
                  )
               )
               (setq DimensionCounter (1+ DimensionCounter))
            )

         )
      )
   )
  (princ (strcat "\n"
                  (itoa DimensionCounter) " Dimensions were Processed -"
                  (itoa IsolatedDimensionCounter) " Dimensions were Isolated"
          )
   )
   (princ)
)

(princ "Done.")
