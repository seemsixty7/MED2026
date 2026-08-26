;;load the MEDSettings Pallet
(princ "\rLoading MEDMainDialogs...")

(defun ShowMEDSettings ( / Result)
  (command "_OPENDCL") ; Load OpenDCL Runtime
  (if (dcl_Project_Load "MEDMain") ; Load project data from MyProject.odcl
    (progn
      (setq Result (dcl_Form_Show MEDMain_MEDSettings))
    )
  )
  (princ)
)
(defun c:MEDSettings()
	(ShowMEDSettings)
)
;(defun c:MEDChange()
;	(while (not MEDCHANGE_ENT)
;       (setq MEDCHANGE_ENT (car (entsel "\nSelect MED Entity to change: ")))
;   )
;   (ShowMEDChange)
;)

;(defun ShowMEDChange ( / Result)
;  (command "_OPENDCL") ; Load OpenDCL Runtime
;  (if (dcl_Project_Load "MEDMain") ; Load project data from MyProject.odcl
;    (progn
;      (setq Result (dcl_Form_Show MEDMain_MEDChange))
;    )
;  )
;  (princ)
;)

(defun SetMEDMainSettingsValues()
	;;TaggingOn controls _TAGOFF Variable A bit reversed on the actual use
	(if _TAGOFF
		(dcl_Control_SetValue MEDMain_MEDSettings_TaggingOn 0)
		(dcl_Control_SetValue MEDMain_MEDSettings_TaggingOn 1)
	)
	;;ProjectNumber
	(dcl_Control_SetText MEDMain_MEDSettings_Project _MEDPROJECT)
	;;Size OverRide Control Size OverRide to put in a larger Fitting when placonfittings Variable is
	(dcl_Control_SetValue MEDMain_MEDSettings_SizeOverrideOn _SIZEOVR)
	;;User Rotate Control
	(dcl_Control_SetValue MEDMain_MEDSettings_UserRotateOn _USERROT)
	;;Conduit Bends On
	(dcl_Control_SetValue MEDMain_MEDSettings_ConduitBendsOn _CONFILL)
	;;Conduit Bend Multiplier
	(dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _MEDRADFAC 2 2))
	;;ConduitSizes
	(PopulateComboBoxControl MEDMain_MEDSettings_ConduitSize _CONSIZE_LIST (rtos _CSIZE 2 2) 1)
	;;TraySizes
	(PopulateComboBoxControl MEDMain_MEDSettings_TraySize _TRAYSIZE_LIST (rtos _TRSIZE 2 2) 1)
	;;TrayDepth
	(PopulateComboBoxControl MEDMain_MEDSettings_TrayDepth _TRAYDPTH_LIST (rtos _TRDEPTH 2 2) 1)
	;;TrayRadius
	(PopulateComboBoxControl MEDMain_MEDSettings_TrayRadius _TRAYRADIUS_LIST (rtos _TRRAD 2 2) 1)
)

;;;This function will populate a combobox and convert the passed list from the convertype specified to a string
;;; 0 = no conversion
;;; 1 = Real numbers
;;; 2 = Ints
(defun PopulateComboBoxControl(ControlVariable ControlList DefaultValue ConvertType) 
	(setq ComboBoxListData (list)
		  ComboBoxIndex 0
		  ComboBoxListCount 0
	)
	(foreach ComboListItem ControlList
		(cond
			((= ConvertType 1)
				(setq ComboListItem  (rtos ComboListItem 2 2))
			)
			((= ConvertType 2)
				(setq ComboListItem  (itoa ComboListItem))
			)
		)
		(if (= ComboListItem DefaultValue)
			(setq ComboBoxIndex ComboBoxListCount)
		)
		(setq ComboBoxListData (append ComboBoxListData (list ComboListItem))
		      ComboBoxListCount (1+ ComboBoxListCount)
		)
	)
	(dcl_ComboBox_Clear ControlVariable)
	(dcl_ComboBox_AddList ControlVariable  ComboBoxListData)
	(dcl_ComboBox_SetCurSel ControlVariable ComboBoxIndex)
)

(defun c:MEDMain_MEDSettings_OnInitialize (/)
  (SetMEDMainSettingsValues)
)


(defun c:MEDMain_MEDSettings_OnDocActivated (/)
  (SetMEDMainSettingsValues)
)

(defun c:MEDMain_MEDSettings_TaggingOn_OnClicked (Value /)
  	(if (= Value 0)
  		(setq _TAGOFF T)
  		(setq _TAGOFF nil)
	)
)

(defun c:MEDMain_MEDSettings_SizeOverrideOn_OnClicked (Value /)
	(setq _SIZEOVER Value)
)

(defun c:MEDMain_MEDSettings_UserRotateOn_OnClicked (Value /)
	(setq _USERROT Value)
)

(defun c:MEDMain_MEDSettings_ConduitBendsOn_OnClicked (Value /)
  (setq _CONFILL Value)
)

(defun c:MEDMain_MEDSettings_BendMultiplier_OnEditChanged (NewValue /)
  (setq ActualValue (read NewValue))
  (if (or (= (type ActualValue) 'INT) (= (type ActualValue) 'REAL))
  	  (progn
  	  	  (setq _MEDRADFAC (* 1.0 ActualValue))
  	  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _MEDRADFAC 2 2))
  	  )
  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _MEDRADFAC 2 2))
  )
)

(defun c:MEDMain_MEDSettings_ConduitSize_OnSelChanged (ItemIndexOrCount Value / ConduitSizeData)
	(setq _CSIZE (atof Value)
		  ConduitSizeData (getsize "" (rtos _CSIZE 4))
		  _ACSIZE (nth 1 ConduitSizeData)
		  _CLETT (nth 3 ConduitSizeData)
	)
	
)

(defun c:MEDMain_MEDSettings_TraySize_OnSelChanged (ItemIndexOrCount Value /)
	(setq _TRSIZE (atof Value))
)

(defun c:MEDMain_MEDSettings_TrayDepth_OnSelChanged (ItemIndexOrCount Value /)
	(setq _TRDEPTH (atof Value))
)

(defun c:MEDMain_MEDSettings_TrayRadius_OnSelChanged (ItemIndexOrCount Value /)
	(setq _TRRAD (atof Value))
	(cond
		((= _TRRAD 12.0)
			(setq _TRFITTADD 0)
		)
		((= _TRRAD 24.0)
			(setq _TRFITTADD 1)
		)
		((= _TRRAD 36.0)
			(setq _TRFITTADD 3)
		)
		((= _TRRAD 48.0)
			(setq _TRFITTADD 120)
		)
	)
)

(defun c:MEDMain_MEDSettings_TrayTangent_OnEditChanged (NewValue /)
  (setq ActualValue (read NewValue))
  (if (or (= (type ActualValue) 'INT) (= (type ActualValue) 'REAL))
  	  (progn
  	  	  (setq _TRAYTANFAC (* 1.0 ActualValue))
  	  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _TRAYTANFAC 2 2))
  	  )
  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _TRAYTANFAC 2 2))
  )
)

(defun c:MEDMain_MEDSettings_TrayFlange_OnEditChanged (NewValue /)
  (setq ActualValue (read NewValue))
  (if (or (= (type ActualValue) 'INT) (= (type ActualValue) 'REAL))
  	  (progn
  	  	  (setq _TRAYFLANGE (* 1.0 ActualValue))
  	  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _TRAYFLANGE 2 2))
  	  )
  	  (dcl_Control_SetText MEDMain_MEDSettings_BendMultiplier (rtos _TRAYFLANGE 2 2))
  )
)


(defun c:MEDMain_MEDSettings_VerticalTrayOn_OnClicked (Value /)
	(if (= Value 0)
  		(setq _VERTICALTRAY nil)
  		(setq _VERTICALTRAY T)
	)
)

(defun c:MEDMain_MEDSettings_Project_OnEditChanged (NewValue /)
  (if (> (strlen NewValue) 0)
  	  (progn
  	  	  (setq _MEDPROJECT NewValue)
  	  )
  	  (dcl_Control_SetText MEDMain_MEDSettings_ProjectNumber _MEDPROJECT)
  )
)

;;;;;Begin MED Change Dialog

(defun c:MEDMain_MEDChange_MEDDataItem_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDDataItem_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_AddMEDData_OnClicked (/)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_AddMEDData_OnClicked" "To do")
)


(defun c:MEDMain_MEDChange_MEDItemTag_OnUpdate (NewValue /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemTag_OnUpdate" "To do")
)


(defun c:MEDMain_MEDChange_MEDItemSize_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemSize_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_MEDItemAlt_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemAlt_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_MEDItemDepth_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemDepth_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_MEDItemDistance_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemDistance_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_MEDItemFlange_OnUpdate (NewValue /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemFlange_OnUpdate" "To do")
)


(defun c:MEDMain_MEDChange_MEDItemMeasure_OnClicked (Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemMeasure_OnClicked" "To do")
)

(defun c:MEDMain_MEDChange_MEDItemCode_OnSelChanged (ItemIndexOrCount Value /)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_MEDItemCode_OnSelChanged" "To do")
)

(defun c:MEDMain_MEDChange_OkButton_OnClicked (/)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_OkButton_OnClicked" "To do")
)

(defun c:MEDMain_MEDChange_CancelButton_OnClicked (/)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_CancelButton_OnClicked" "To do")
)

(defun c:MEDMain_MEDChange_OnCancel (/)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_OnCancel" "To do")
)

(defun c:MEDMain_MEDChange_OnOK (/)
  (dcl_MessageBox "To Do: code must be added to event handler\r\nc:MEDMain_MEDChange_OnOK" "To do")
)

(defun c:MEDMain_MEDChange_OnInitialize (/)
	(app_chg_lst) 
  
)

(defun ShowMEDBOM ( / Result)
  (command "_OPENDCL") ; Load OpenDCL Runtime
  (if (dcl_Project_Load "MEDMain") ; Load project data from MyProject.odcl
    (progn
      (setq Result (dcl_Form_Show MEDMain_MEDShow))
    )
  )
  (princ)
)
(defun c:MEDSHOW()
	(setq MEDSHOW_Summary nil)
	(ShowMEDBOM)
)
(defun c:MEDSHOWSUM()
	(setq MEDSHOW_Summary T)
	(ShowMEDBOM)
)
(defun c:MEDMain_MEDShow_OnInitialize (/)
  (showBOMData)
)

(defun c:MEDMain_MEDShow_OKButton_OnClicked (/)
  (dcl_form_close MEDMain_MEDShow 1)
)

(defun showBOMData()
	(if MEDSHOW_Summary
		(setq BOMData (MEDProcessSQLStatement (strcat "Select ITEM_TYPE, ITEM_CODE, 'ALL TAGS', SUM(ITEM_QTY_) as QTY, ITEM_SIZE, ITEMDESC from MEDProject"
				                                  " inner join MEDType on ITEM_CODE=ITEMCODE and ITEM_TYPE=ITEMTYPE where ITEM_DWG_='"
				                                  (getvar "DWGNAME") "' GROUP BY ITEM_TYPE, ITEM_CODE, ITEM_SIZE, ITEMDESC Order by ITEM_TYPE, ITEM_CODE"))
		)
		(setq BOMData (MEDProcessSQLStatement (strcat "Select ITEM_TYPE, ITEM_CODE, ITEM_TAG_, ITEM_QTY_, ITEM_SIZE, ITEMDESC from MEDProject"
				                                  " inner join MEDType on ITEM_CODE=ITEMCODE and ITEM_TYPE=ITEMTYPE where ITEM_DWG_='"
				                                  (getvar "DWGNAME") "' Order by ITEM_TYPE, ITEM_CODE"))
		)
	)
	(if (not GRID_Setup_Complete)
		(progn
			(princ "\nInside GridSetup")
			(while (dcl_Grid_DeleteColumn MEDMain_MEDShow_BOMGrid 0))
			(dcl_Grid_Clear MEDMain_MEDShow_BOMGrid)
			(dcl_Control_SetRowHeader MEDMain_MEDShow_BOMGrid T)
			(dcl_Grid_AddColumns MEDMain_MEDShow_BOMGrid (list (list "" 0 20 0) (list "" 0 20 0) 
															   (list "ITEM TYPE" 0 100 0)
					                                           (list "ITEM CODE" 0 100 0)
					                                           (list "ITEM TAG" 0 100 0)
					                                           (list "ITEM QTY" 0 100 0)
					                                           (list "ITEM SIZE" 0 100 0)
					                                           (list "ITEM Description" 0 400 0)
					                                           ))
			(dcl_Control_SetColumnStyleList MEDMain_MEDShow_BOMGrid 0 0 0 0 0 0 0 0)
			;(setq test3 (dcl_Grid_DeleteColumn MEDMain_MEDShow_BOMGrid 8))
			(setq GRID_Setup_Complete T)
		)
	)
	(dcl_Grid_Clear MEDMain_MEDShow_BOMGrid)
	(setq TEST1 (dcl_Grid_GetColumnCount MEDMain_MEDShow_BOMGrid))
	(foreach BomRecord (cdr BOMData)
		(setq NewRowCnt (dcl_Grid_AddRow MEDMain_MEDShow_BOMGrid (list "" "" (nth 0 BomRecord) (rtos (nth 1 BomRecord) 2 0)
				                                                 (nth 2 BomRecord) (rtos (nth 3 BomRecord) 2 4)
				                                                 (if (nth 4 bomrecord) (rtos (nth 4 BomRecord) 2 2) "") (nth 5 BomRecord))
				                                                 )
		)
			

	;	(setq combodatalist (append (list (nth 0 mapfield)) dbfieldlist))
	;	(setq combotagdatalist (append (list (nth 1 mapfield)) atttaglist))
	;	(dcl_Grid_SetCellStyle MEDMain_MEDShow_BOMGrid NewRowCnt 2 36)
	;	(dcl_Grid_SetCellStyle UE-TitleBlockManager_UETBManager_TBMapping NewRowCnt 3 36)
	;	(dcl_Grid_SetCellDropList UE-TitleBlockManager_UETBManager_TBMapping newrowcnt 2 combodatalist)
	;	(dcl_Grid_SetCellDropList UE-TitleBlockManager_UETBManager_TBMapping newrowcnt 3 combotagdatalist)
	)
)


;;;;;;Begin MEDDetail Manager Dialog box


(defun ShowMEDDetailManager ( / Result)
  (command "_OPENDCL") ; Load OpenDCL Runtime
  (if (dcl_Project_Load "MEDMain") ; Load project data from MyProject.odcl
    (progn
      (setq Result (dcl_Form_Show MEDMain_DetailManager))
    )
  )
  (princ)
)
(defun c:MEDDETMAN()
	(ShowMEDDetailManager)
)
(defun c:MEDMain_DetailManager_OKButton_OnClicked (/)
	(if DETMAN_ActiveCellEdit
		(c:MEDMain_DetailManager_DetailResults_OnEndLabelEdit (nth 0 DETMAN_ActiveCellEdit) (nth 1 DETMAN_ActiveCellEdit))
	)
	(dcl_form_close MEDMain_DetailManager 1)
)

(defun c:MEDMain_DetailManager_DeleteRecords_OnClicked ( / RunDelete DelitemCode)
	(if DETMAN_ActiveCellEdit
		(c:MEDMain_DetailManager_DetailResults_OnEndLabelEdit (nth 0 DETMAN_ActiveCellEdit) (nth 1 DETMAN_ActiveCellEdit))
	)
	(if DETMAN_selectedRows
		(progn
			(setq SQLDeleteStatement "DELETE FROM MEDTYPE WHERE ITEMTYPE='EQUIP' AND ITEMCODE in (")
			(foreach Row DETMAN_SelectedRows
				(if (= (dcl_Grid_GetCellCheckState MEDMain_DetailManager_DetailResults Row 1) 1)
					(setq DelItemCode (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults Row 2)
						  SQLDeleteStatement (strcat SQLDeleteStatement DelItemCode ",")
						  RunDelete T
					)
				)
			)
			(setq SQLDeleteStatement (strcat (substr SQLDeleteStatement 1 (1- (strlen SQLDeleteStatement))) ")"))
			(if RunDelete
				(progn
					(MEDProcessSQLStatement SQLDeleteStatement)
					(setq DETMAN_SelectedRows (list)) 
					(MEDMainDetailManagerPopulateGrid)
				)
			)
		)
	)
)

(defun c:MEDMain_DetailManager_SelectProject_OnSelChanged (ItemIndexOrCount Value /)
	(setq DETMAN_Project Value)
	(MEDMainDetailManagerPopulateGrid)
)

(defun c:MEDMain_DetailManager_GroupFilter_OnSelChanged (ItemIndexOrCount Value /)
   (setq DETMAN_Group Value)
   (MEDMainDetailManagerPopulateGrid)
)

(defun c:MEDMain_DetailManager_CopyFromProject_OnSelChanged (ItemIndexOrCount Value /)
	(if (and (/= _MEDPROJECT Value) (/= "" Value))
		(progn
			(dcl_Control_SetEnabled MEDMain_DetailManager_CopyDetails T)
			(setq DETMAN_CopyFromProject Value)
			(dcl_Control_SetEnabled MEDMain_DetailManager_CopyFromProject nil)
		)
	)
)

(defun c:MEDMain_DetailManager_CopyDetails_OnClicked (/)
	(MEDMainDetailManagerCopyDetails)
	(dcl_Control_SetEnabled MEDMain_DetailManager_CopyDetails T)
	(dcl_Control_SetEnabled MEDMain_DetailManager_CopyDetails nil)
)

(defun MEDMAIN_DetailManagerCheckStates(CheckRow CheckCol)
	(if (= (dcl_Grid_GetCellCheckState MEDMain_DetailManager_DetailResults CheckRow CheckCol) 1)
		(setq DETMAN_SelectedRows (append DETMAN_SelectedRows (list CheckRow)))
		(setq DETMAN_SelectedRows (MEDRemoveitemfromlist DETMAN_SelectedRows (list CheckRow)))
	)
)
(defun c:MEDMain_DetailManager_DetailResults_OnEndLabelEdit (Row Column /)
	(setq NewValue (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults Row Column))
	(if (/= DETMAN_CurrentValue NewValue)
		(progn
			(MEDMainDetailManagerUpdateDatabase Row Column)
			(if (= Column 7)
				(DETMANShowPreview)
			)
		)
	)
	(if (= Column 1)
		(MEDMain_DetailManagerCheckStates Row Column)
	)
	(setq DETMAN_ActiveCellEdit nil)
)

(defun c:MEDMain_DetailManager_DetailResults_OnBeginLabelEdit (Row Column /)
	(setq DETMAN_CurrentValue (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults Row Column)
		  DETMAN_ActiveCellEdit (list Row Column)
	)
	(if (/= DETMAN_SelectedRow Row)
		(progn
			(setq DETMAN_SelectedRow Row)
			(DETMANShowPreview)
		)
	)
)

(defun c:MEDMain_DetailManager_DetailResults_OnSelChanged (Row Column /)
	(if (/= DETMAN_SelectedRow Row)
		(progn
			(MEDMain_DetailManagerCheckStates Row Column)
			(setq DETMAN_SelectedRow Row)
			(DETMANShowPreview)
		)
	)
)


(defun DETMANShowPreview()
	(setq BlockFileToPreview (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults DETMAN_SelectedRow 7)
	      BlockFileToPreview (findfile (strcat BlockFileToPreview ".dwg"))
	)
	(if BlockFileToPreview
		(dcl_DWGPreview_LoadDwg MEDMain_DetailManager_DwgPreview BlockFileToPreview)
		(dcl_DWGPreview_Clear MEDMain_DetailManager_DwgPreview)
	)
)

(defun c:MEDMain_DetailManager_OnOK (/)
	(if DETMAN_ActiveCellEdit
		(c:MEDMain_DetailManager_DetailResults_OnEndLabelEdit (nth 0 DETMAN_ActiveCellEdit) (nth 1 DETMAN_ActiveCellEdit))
	)
)


(defun MEDMainDetailManagerUpdateDatabase (RowPosition ColumnPosition)
	(setq ItemType "'EQUIP'"
		  ItemCode (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults RowPosition 2)
		  ItemData (dcl_Grid_GetCellText MEDMain_DetailManager_DetailResults RowPosition ColumnPosition)
		  ItemField (dxf columnPosition DETMAN_GridMappings)
		  SQLUpdateStatement (strcat "UPDATE MEDTYPE SET " itemfield "='" itemdata "' WHERE ITEMTYPE=" ItemType " AND ITEMCODE=" ItemCode)
	)
	(princ "\nAbout to Update REcord")
	(MEDProcessSQLStatement SQLUpdateStatement)
	(princ "\nRecord Should be updated now:")
)
(defun MEDGetNextDetailCode()
	(setq MEDResult (MEDProcessSQLStatement "SELECT MAX(ITEMCODE) from MEDTYPE"))
	(if (> (length MEDResult) 1)
		(setq ReturnCode (1+ (fix (car (car (cdr MEDResult))))))
		(setq ReturnCode nil)
	)
	ReturnCode
)

(defun c:MEDMain_DetailManager_AddDetailButton_OnClicked (/)
	(setq NewCode (MEDGetNextDetailCode))
	(if (/= DETMAN_Project "All")
		(setq newRecordProjectNumber (strcat "'" DETMAN_Project "'"))
		(setq newRecordProjectNumber "NULL")
	)
		
	(if NewCode
		(MEDProcessSQLStatement (setq updsqlstatement (strcat "INSERT INTO MEDTYPE  (ITEMCODE, ITEMTYPE,ITEMDESC, User4) VALUES ("
				                        (itoa NewCode) ", 'EQUIP', '----NEW RECORD----', " newRecordProjectNumber ")")))
		(prompt "\nUnable to Create new Record")
	)
	(MEDMainDetailManagerPopulateGrid)
	
)

(defun c:MEDMain_DetailManager_OnInitialize (/)
	(setq DETMAN_GridMappings (list (cons 2 "ITEMCODE")
			                 (cons 3 "ITEMDESC")
			                 (cons 4 "ITEM_GRP")
			                 (cons 5 "ITEMKEY1")
			                 (cons 6 "ITEMKEY2")
			                 (cons 7 "ITEMKEY3")
			                 (cons 8 "ITEMKEY4")
			                 (cons 9 "USER1")
			                 (cons 10 "USER2")
			                 (cons 11 "USER3")
			                 (cons 12 "USER4")
			            )
		DETMAN_ActiveCellEdit nil
		DETMAN_CurrentValue   nil
		DETMAN_SelectedRow    nil
		DETMAN_SelectedRows   (list)
	)
	(dcl_Control_SetEnabled MEDMain_DetailManager_CopyFromProject T)
	(dcl_Control_SetEnabled MEDMain_DetailManager_CopyDetails nil)
    (MEDMainDetailManagerPopulateProjectList)
    (MEDMainDetailManagerPopulateGroupList)
    (MEDMainDetailManagerPopulateGrid)
    
)
(defun MEDMainDetailManagerPopulateProjectList()
	(setq projectlist (MEDProcessSQLStatement "SELECT DISTINCT USER4 FROM MEDTYPE WHERE ITEMTYPE='EQUIP'"))
	(if (member (list _MEDPROJECT) projectlist)
		(setq ComboProjectList (list "All"))
		(setq ComboProjectList (list "All" _MEDPROJECT))
	)
	(if (> (length ProjectList) 1)
		(progn

			(foreach projectnumber (cdr Projectlist)
				(setq ComboProjectList (append ComboProjectList projectnumber))
			)
		)
	)
	(setq ProjectListOnly (append (list "") (cdr ComboProjectList))
		  DETMAN_Project _MEDPROJECT
		  DETMAN_CopyFrom ""
	)
	
	(PopulateComboBoxControl MEDMain_DetailManager_SelectProject ComboProjectList _MEDPROJECT 0)
	(PopulateComboBoxControl MEDMain_DetailManager_CopyFromProject ProjectListOnly "" 0)
	                         
)

(defun MEDMainDetailManagerPopulateGroupList()
	(setq grouplist (MEDProcessSQLStatement "SELECT DISTINCT ITEM_GRP FROM MEDTYPE WHERE ITEMTYPE='EQUIP'"))
	(setq ComboGroupList (list "All")
		  DETMAN_Group "All"
	)
	(if (> (length GroupList) 1)
		(progn
			(foreach groupname (cdr Grouplist)
				(setq ComboGroupList (append ComboGroupList groupname))
			)
		)
	)
	(PopulateComboBoxControl MEDMain_DetailManager_GroupFilter ComboGroupList "All" 0)
)
(defun MEDMainDetailManagerAddRecordToGrid (RecordToAdd)
	(setq RowCnt (dcl_Grid_AddRow MEDMain_DetailManager_DetailResults 
			"" "" (itoa (fix (nth 0 DetailRecord))) (nth 1 DetailRecord)
			(nth 2 DetailRecord) (nth 3 DetailRecord)
			(nth 4 DetailRecord) (nth 5 DetailRecord)
			(nth 6 DetailRecord) (nth 7 DetailRecord)
			(nth 8 DetailRecord)(nth 9 DetailRecord)
			(nth 10 DetailRecord))
		    CellSettings (list 3 4 5 6 7 8 9 10 11 12)
	)
	(foreach cellcolumn CellSettings 
		(dcl_Grid_SetCellStyle MEDMain_DetailManager_DetailResults RowCnt cellcolumn 6)
	)
)
(defun MEDMainDetailManagerPopulateGrid()
	(setq DetailDataSQL (strcat "SELECT ITEMCODE, ITEMDESC, ITEM_GRP, ITEMKEY1, ITEMKEY2, ITEMKEY3, ITEMKEY4, USER1, USER2, USER3, USER4"
				                                    " FROM MEDTYPE WHERE ITEMTYPE='EQUIP'"))
	(if (/= DETMAN_Group "All")
		(setq DetailDataSQL (strcat DetailDataSQL " AND ITEM_GRP='" DETMAN_GRoup "'"))
	)
	(if (/= DETMAN_Project "All")
		(setq DetailDataSQL (strcat DetailDataSQL " AND USER4='" DETMAN_Project "'"))
	)
	(setq DetailDataRecordSet (MEDProcessSQLStatement DetailDataSQL))
	(dcl_Grid_Clear MEDMain_DetailManager_DetailResults)
	(if (> (length DetailDataRecordSet) 1)
		(foreach DetailRecord (cdr DetailDataRecordSet)
			(setq NewRowCnt (MEDMainDetailManagerAddRecordToGrid DetailRecord))

		)
	)
)
;;;This is the SQL code to use to generate the new records.
;CREATE SEQUENCE MED_TEMPSEQ
;AS BIGINT 
;START WITH 639
;increment by 1
;
;insert into MEDTYPE (ITEMTYPE,ITEMCODE,ITEMDESC,ITEM_GRP,ITEMKEY1,ITEMKEY2, ITEMKEY3, ITEMKey4, USER1, USER2, USER3, USER4)
;select ITEMTYPE,NEXT VALUE FOR MED_TEMPSEQ, ITEMDESC, ITEM_GRP, ITEMKEY1,ITEMKEY2, ITEMKEY3, ITEMKey4, USER1, USER2, USER3, 'NEWPROJECT'
;FROM MEDTYPE where ITEMTYPE='EQUIP' and USER4='PROJECT1'
;
;drop sequence MED_TEMPSEQ
;This only works with SQL Server version older than 2008.

(defun MEDMainDetailManagerCopyDetails()
	(setq CopyFromProject DETMAN_CopyFromProject
		  CopyToProject DETMAN_Project
		  SequenceSeed (nth 0 (car (cdr (MEDProcessSQLStatement "SELECT MAX(ITEMCODE) from MEDTYPE WHERE ITEMTYPE='EQUIP'"))))
		  CreateSequence (strcat "CREATE SEQUENCE MED_TEMPSEQ AS BIGINT START WITH " (itoa (1+ (fix SequenceSeed))) " INCREMENT BY 1")
		  SQLCopyStatement (strcat "INSERT INTO MEDTYPE (ITEMTYPE,ITEMCODE,ITEMDESC,ITEM_GRP,ITEMKEY1,ITEMKEY2, ITEMKEY3, ITEMKey4, USER1, USER2, USER3, USER4) "
		  	                       "SELECT ITEMTYPE,NEXT VALUE FOR MED_TEMPSEQ, ITEMDESC, ITEM_GRP, ITEMKEY1,ITEMKEY2, ITEMKEY3, ITEMKey4, USER1, USER2, USER3, '" CopyToProject
		  	                       "' FROM MEDTYPE where ITEMTYPE='EQUIP' and USER4='" CopyFromProject "'")
	)
	(MEDProcessSQLStatement CreateSequence)
	(MEDProcessSQLStatement SQLCopyStatement)
	(MEDProcessSQLStatement "DROP SEQUENCE MED_TEMPSEQ")
	(MEDMainDetailManagerPopulateGroupList)
	(MEDMainDetailManagerPopulateGrid)
)
		  
(princ "Done.")	
