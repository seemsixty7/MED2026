;;;MED User specification file
;;;Copyright Momentum Design Systems (c) 1992-2007

(setq   _MEDDIR (strcat (getmeddir 3) "/"))
(setq   _MEDDWG (strcat (getmeddir 4) "/"))


;;
;; Defualt settings for med variables
;;

;
; Variables for Conduit Size settings
; ***Warning: These variables must all co-inside with each other
; These are only defaults and change upon picks in the menu

(setq _CLETT     "C"    ;Code letter for conduit size 
      _CSIZE     1.0    ;Size of conduit
      _ACSIZE    1.315  ;Actual outer diameter of conduit
      _MEDRADFAC 5.0    ;Bend radius calculation factor
      _TRSIZE    24.0   ;Cable tray Default Size
      _TRDEPTH   6.0    ;Default Tray Depth
      _TRTYPE    2      ;Default of Heavy Duty Tray
      _TRCODE    1      ;default TRay material code
      _TRRAD     24.0   ;default tray radius
      _TRFITCODE 100
      _TRTANFAC  3.0    ;Default Tangent to be added to Tray Fittings
      _TRFITTADD 1      ;Default to selected radius addition
      _TRFITSTRT 340    ;Starting point for Tray Fitting codes
      _TRFITVSTR 370    ;Starting Point for Tray Vertical Fittings
      _STRCODE   11     ;default strut code
      _CHANCODE  4      ;default material code for cable channel
      _CHANSIZE  4.0    ;defualt Cable channel width
      _CHANDEPTH 1.75   ;Default depth for cable channel
      _CHANFITST 401    ;starting point for Channel fittings
      _EQCODE    1      ;default equip material code
      _EQTAG    "NONE"  ;Default tag setting for equipment inserts
      _SIZEOVR   0      ;Size override to use currently selected size
      _USERROT   0      ;User override rotation specification
      _FEED      0      ;Device feed through
      _TAGOFF    nil    ;Tag request on set to T to suppress tags
      _DETTYP (list "TYP" 6) ;Detail Tag Typical Prefix length and tag name
      _DETNUM "DETNUM"       ;Detail number tagname.
      _DETNUM1 "TAGINFO1"     ;Secondary detail number.
      _DETNUM1A "TYPE"        ;Secondary Detail Suffix.
      _DETBLK (list "DETBUB2") ;name of detail bubble or block
      _VERTICALTRAY nil ;default setting for Regular tray Set to T for Vertical
      _FDBLOCK "FILEINFO"     ; FILEDate block specification
      _FDATT   "NEWDATE"      ;Filedate attribute spec
      _FDFULLPATH nil         ;If True specifies to show full path
      _FDALLCAPS nil          ;If true Filedate is ALL CAPS
      _FDDEFAULTINS  nil      ;If a point and rotation is specified that point and rotation will be used for insertion
;      _FDDEFAULTINS (list (list 0.0 0.0 0.0) 0) ; This is the format for specifying FD Insert and Rotation
      _TRPLWIDTH 0.0    ;Width for tray entities
      _CONPLWIDTH 0.0   ;Width for conduit entities
      _CONDTLPLWIDTH 0.0 ; Width of Detail Conduit Center Line will always be 0.0
      _TR_X_WIDTH    0.0 ; Width used to display the X in the VertTray fitings
      _SCHEDATT      "FIXTYPE";  Variable for specifying Fixture Schedule Detail
      _TR_SIZETAG    "TR_SIZE"  ; Attribute Tag name for Tray Tag
     

)

;
; Various other settings required by MED
;

(setq _CODE     1           ;Default material code
      _FLEXTYPE 7           ;Material specification for flex
      _FITTCODE 8           ;Default Material code for fittings
      _CONFILL  1           ;Conduit fillet is on ( 0 = off : 1 = on)
      _CABCODE  310         ;Default Cable setting
      _CABNUM   1           ;Cable number to prefix cable code
      _GRTAG    "GRNDMAIN"  ;Ground cable tag defualt
      _GRTYPE   311         ;Cadweld default splice connections
      _FLEXCON  321         ;Flexible conduit connector default
      _MEDDIST  120.0       ;Default Conduit up or down distance
      _TERMVER  0.25        ;Default Vertical Dimension for Terminals
      _TERMHOR  0.5625      ;Default Horizontal Dimesion for Terminals
      _2LINOFF  0.375       ;Default distance between double lines
      _3LINOFF  0.375       ;Defualt distance beteeen triple lines
)

;;Tray hardware detail settings

(setq _TRAYCON   (list 65 72)  ;([sideentry start] [end entry])
      _TRAYEP    (list 105);expansion plate details
      _TRAYEG    (list 101);expansion guide details
      _TRAYHD    (list 100 103) ;hold down details
      _TRAYHANG  (list 127 128); hanger details
      _TRAYDROP  (list 365)    ;drop out fitting code
      _TRAYBLIND (list 366)    ;tray blind end fitting code
      _TRAYHINGE (list 107)    ;tray hinge detail list code
)      

;;
;; Layer settings for MED
;;

;      Variable        Layer name    Color     Linetype
;___________________________________________________________
(setq MED_LAYER_LIST (list
     (setq  	 _MEDFIT    (list "MED_FITTINGS" "MAGENTA" "CONTINUOUS"))
     (setq  	 _MEDDETFIT (list "MEDDETFIT"    "CYAN"    "CONTINUOUS")) 
     (setq  	 _MEDDETCON (list "MEDDETCON"    "CYAN"    "CONTINUOUS"))
     (setq  	 _MEDTEXT   (list "MED_TEXT"     "YELLOW"  "CONTINUOUS"))
     (setq  	 _EBOM      (list "EBOM"         "RED"     "CONTINUOUS"))
     (setq  	 _ECTAG     (list "ECTAG"        "RED"     "CONTINUOUS"))
     (setq  	 _COORDS    (list "COORDS"       "RED"     "CONTINUOUS")) 
     (setq  	 _MCON      (list "MCON"         "BLUE"    "CONTINUOUS"))
     (setq  	 _EMATBUB   (list "EMATBUB"      "CYAN"    "CONTINUOUS"))
     (setq  	 _MEDINST   (list "MEDINST"      "MAGENTA" "CONTINUOUS"))
     (setq  	 _MEDELEQP  (list "MEDELEQP"     "MAGENTA" "CONTINUOUS"))
     (setq  	 _MEDEQP    (list "MEDEQP"       "RED"     "CONTINUOUS"))
     (setq  	 _MEDGRND   (list "MEDGRND"      "GREEN"   "PHANTOM2"  ))
     (setq  	 _MEDCENLAY (list "MEDCENTER"    "WHITE"   "CONTINUOUS"))
     (setq  	 _MEDTRAY   (list "MEDTRAY"      "BLUE"    "CONTINUOUS"))
     (setq  	 _MEDWIRE   (list "MEDWIRE"      "GREEN"   "CONTINUOUS"))
     (setq  	 _MEDPCABLE (list "MEDPOWER"     "BLUE"    "CONTINUOUS"))
     (setq  	 _MEDCCABLE (list "MEDCONTROL"   "CYAN"    "CONTINUOUS"))
     (setq  	 _MEDICABLE (list "MEDINSTRMNT"  "MAGENTA" "CONTINUOUS"))
     (setq  	 _MEDBUS    (list "MEDBUS"       "BLUE"    "CONTINUOUS"))
     (setq  	 _MEDSYM    (list "MEDSYM"       "CYAN"    "CONTINUOUS"))
     (setq  	 _ZEROLAY   (list "0"            "WHITE"   "CONTINUOUS"))
     (setq  	 _BCKGND    (list "bckgnd"       "8"       "CONTINUOUS"))
     (setq  	 _REVISION  (list "MED_TEXT"     "YELLOW"  "CONTINUOUS"))
     (setq  	 _FDTEXT    (list "MED_TEXT"     "YELLOW"  "CONTINUOUS"))
     (setq  	 _MED3DTRAY (list "MED_3DTRAY"   "BLUE"    "CONTINUOUS"))
     (setq  	 _MED3DCONDUIT (list "MED_3DCONDUIT"   "GREEN"    "CONTINUOUS"))
))
(setq  	 _CON       (list                "MAGENTA" "CONTINUOUS"))

;;
;;  Title Block Default name
;;

(setq MED_TBLK "TITLE_D2021")

;;  Title blocks not on AutoCAD search path should include the
;;  path prefix. The following is a sample of how a titleblock
;;  would be specified with the path.
;;
;;  EXAMPLE:   (setq MED_TBLK "C:\\BORDERS\\CLIENTA\\SHEET_D")


;;
;;  Linetype settings to be used for various entities
;;
;;

(setq U_CON "dashed"   ; Under ground conduit setting
      H_CON "hidden"   ; Hidden conduit linetype setting
      TR_DNLTYPE "HIDDEN2"  ; Linetype for Tray x representing tray up or down
)


;;
;;  Here is where the default text styles are loaded
;;

(setq _TXTSTYLE "T937THIN")  ;Primary Text Style to be used by text related
                        ; lisp routines
(setq _MATCHTXTSTYLE "B187") ; Matchline Text Style
(setq _LEADSYMSIZE 0.1875)


(defun c:loadtxt()
    (setvar "REGENMODE" 0)
    (setvar "CMDECHO" 0)
    (command "STYLE" "B250" "ROMAND" (* 0.25 _SC) "0.75" "0" "N" "N" "N")
    (command "STYLE" "B187" "ROMAND" (* 0.1875 _SC) "0.75" "0" "N" "N" "N")
    (command "STYLE" "B125" "ROMAND" (* 0.125 _SC) ".85" "0" "N" "N" "N")
    (command "STYLE" "T125" "TXT" (* 0.125 _SC) "0.85" "0" "N" "N" "N")
    (command "STYLE" "T125THIN" "TXT" (* 0.125 _SC) "0.75" "0" "N" "N" "N")
    (command "STYLE" "T187" "TXT" (* 0.1875 _SC) "0.75" "0" "N" "N" "N")
    (command "STYLE" "T937THIN" "TXT" (* 0.09375 _SC) "0.75" "0" "N" "N" "N")
    (command "STYLE" "T937" "TXT" (* 0.09375 _SC) "1" "0" "N" "N" "N")

    (c:bldstl)
(prompt "Text Styles are now loaded.")
(princ)
)
