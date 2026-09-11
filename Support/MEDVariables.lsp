;This file is for setting MED Default Variables
;These Variables are loaded by deafult and if a Spec is used and has a setting
;for the same variable, the the spec variable will override the defaults listed
;in this file.

;;General Environment Settings
;;;Default Project Setting
(setq _MEDPROJECT "PROJECT1")
;;;Default Setting for TAGGING  Values are T for No Tagging or nil for Tagging
(setq _TAGOFF nil)
;;;Default Value for Size Override Values are 0 for No Overrides or 1 for allow overrides
(setq _SIZEOVR 0)
;;;Default Value for Enabling User Rotate Values are 0 for off and 1 for on.
(setq _USERROT 0)
;;;this is the scale factor variable used by med for scaling text and blocks
(setq _SC (getvar "DIMSCALE"))
;;;This is the Scale Adjustment variable for plotting purposes. shoudl be used for metric efforts
(setq _PLOTSCALE 1.0)
;;;This variable turns off the Database write confirmation notice
(setq _MEDSUPRESSDBConfirm T)
;;;This Setting is for the Database connection String.
;(setq MEDDBCONNECTSTRING "Provider=sqloledb;Data Source=DESKTOP-VV94PHL\\SQLEXPRESS;Initial Catalog=MED;Integrated Security=SSPI;")
;(setq MEDDBCONNECTSTRING "Provider=sqloledb;Data Source=DRAFTING380\\SQLEXPRESS;Initial Catalog=MED2012;Integrated Security=SSPI;")
;(setq MEDDBCONNECTSTRING "Provider=sqloledb;Data Source=ROMULUS\\SQLEXPRESS;Initial Catalog=MED2012;Integrated Security=SSPI;")
;This one is for a Local DB Using MSAccess. This connect method only works if OS/MS Office/AutoCAD are all 32bit
;(setq MEDDBCONNECTSTRING (strcat "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" (getmdedir 1) "\\" (getmdedir 0) ";User ID=admin;Password=;"))

(setq MEDDBCONNECTSTRING "Provider=sqloledb;Data Source=DESKTOP-UGG2A0V\\MDDEVELOPMENT;Initial Catalog=MED;Integrated Security=SSPI;")
;This Connect string works for Azure Data Source SCORE! Need to figure out a different means of authentication or put his in an ecrypted file.
;(setq MEDDBCONNECTSTRING "Provider=SQLOLEDB.1;Data Source=yourcompany.database.windows.net,1433;Initial Catalog=MEDMain;Persist Security Info=False;User ID=clintmoore;Password=\"PASSWORDHERE\";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;")
;(setq MEDDBCONNECTSTRING (strcat "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\\MED2018\\Data\\MED2018.accdb;Persist Security Info=False;"))


;;;Default Value for Conduit Bends to be Filleted
(setq _CONFILL 1)
;;;Default Value for Conduit Bend Multplier
(setq _MEDRADFAC 5.0)
;;;Conduit Size List
(setq _CONSIZE_LIST (list 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0))

;;Cable Tray Settings
;;;Tray Size List
(setq _TRAYSIZE_LIST (list 6.0 9.00 12.00 18.00 24.00 30.0 36.0 42.0 48.0))
;;;Tray Depth List
(setq _TRAYDPTH_LIST (list 3.0 4.0 6.0))
;;;Tray Radius List
(setq _TRAYRADIUS_LIST (list 12.0 24.0 36.0 48.0))
;;;Tray Default Size
(setq _TRSIZE 24.0)
;;;Tray Default Depth
(setq _TRDEPTH 6.0)
;;;Tray Default Radius
(setq _TRRAD 24.0)
;;;Cable Tray Default Flange Setting
(setq _TRAYFLANGE 1.5)
;;;Cable Tray Material Thickness
(setq MED_TRAY_MATERIALWIDTH 0.125)


;;Text Settings
;;;Default Text Map Settings These can be overrideen by a Spec
;;;List is
;;;Command Association, TextStyle Name, Font, Height without scale, TextWidth, Oblique Angle, Backwards, Upside Down, Vertical, LayerPrefixSuffix ("txt" 0 or 1), Layer Color
(setq MED_TXT_STYLE_MAP  (list (list "T1HALF" "TXT0625" "romans.shx" 0.0625 0.85 0 "No" "No" "No")
		                       (list "T0" "TXT09375" "romans.shx" 0.09375 0.85 0 "No" "No" "No")
							   (list "T1" "TXT125" "romans.shx" 0.125 0.85 0 "No" "No" "No")
		                       (list "T2" "TXT15625" "romans.shx" 0.15625 0.85 0 "No" "No" "No")
		                       (list "T3" "TXT1875" "romans.shx" 0.1875 0.85 0 "No" "No" "No")
		                       (list "B1" "TXT125" "romans.shx" 0.125 0.85 0 "No" "No" "No" (list "-BOLD" 1) "Red")
		                       (list "B2" "TXT15625" "romans.shx" 0.15625 0.85 0 "No" "No" "No" (list "-BOLD" 1) "Red")
		                       (list "B3" "TXT1875"  "romans.shx" 0.1875 0.85 0 "No" "No" "No" (list "-BOLD" 1) "Red")
		                 )
)

;;;Update this Function to Point to custom Project Function.
(defun MEDGetProjectNumber()
	_MEDPROJECT
)
