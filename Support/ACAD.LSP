;;;  Set MED to assign SCALE Automatically based on DIMSCALE
;;;  (setq _MEDAUTOSCALE T) will use DIMSCALE, but
;;;  if value is set to numeric value that value will be used
;;;  as scale factor instead (i.e. (setq _MEDAUTOSCALE 1.0) will
;;;  force scales not set to 1.0
;;;
;
;(setq _MEDAUTOSCALE T) ;nil will prompt user for scale.
;

;;Load up Lisp file for DotNET functionality
(load "CSharpAdd")
(prompt "\nLoading MED User defined Quick Keys")
(load "qkey.lsp")
(prompt "\nLoading MED2022")
(load "MEDCore.lsp")

