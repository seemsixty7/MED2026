;; MED2026 App Store bundle loader (replaces ACAD.LSP; loaded per document by the Autoloader).
;;
;; First launch (no %APPDATA%\MooreDesign\MED2026\FirstRun.done): MEDFIRSTRUN seeds the per-user
;; files, appends the MED folders to TRUSTEDPATHS and the support path of the current profile
;; (nothing removed, no duplicates), writes FirstRun.done and asks for an AutoCAD restart.
;; Until that restart, MED commands only show the restart notice (MEDCore globals and APPIDs
;; are not reliable in the session that created the files).
(vl-load-com)

(defun MED-BundleDirs ( / flag sup con app root)
  (if (and (setq flag (findfile "MEDBundle.flag")) (setq app (getenv "APPDATA")))
    (progn
      (setq sup  (vl-filename-directory flag)
            con  (vl-filename-directory sup)
            root (strcat app "\\MooreDesign\\MED2026"))
      (list (cons "support" sup) (cons "contents" con) (cons "root" root)
            (cons "usersup" (strcat root "\\Support")) (cons "userdata" (strcat root "\\Data"))
            (cons "flag" (strcat root "\\FirstRun.done")))
    )
  )
)
(defun MED-Dir (k) (cdr (assoc k (MED-BundleDirs))))

;; 1) per-user files, never overwritten (same set as MED-DotNet MedAppStore.EnsureFirstRun)
(defun MED-BundleSeed ( / src con root sup dat db f h)
  (if (MED-BundleDirs)
    (progn
      (setq src (MED-Dir "support") con (MED-Dir "contents") root (MED-Dir "root")
            sup (MED-Dir "usersup") dat (MED-Dir "userdata") db (strcat dat "\\MED.db"))
      (vl-mkdir (vl-filename-directory root)) (vl-mkdir root) (vl-mkdir sup) (vl-mkdir dat)
      (foreach f (list "med.spc" "MOTOR.DAT" "medblck.dat" "setup.add" "QKEY.lsp")
        (if (not (findfile (strcat sup "\\" f)))
          (vl-file-copy (strcat src "\\" f) (strcat sup "\\" f))))
      (if (not (findfile db)) (vl-file-copy (strcat con "\\Data\\MED.db") db))
      (if (not (findfile (strcat sup "\\Project.dat")))
        (if (setq h (open (strcat sup "\\Project.dat") "w"))
          (progn (foreach f (list "MED.db" sup sup sup (strcat con "\\Dwg")) (write-line f h)) (close h))))
      (if (not (findfile (strcat sup "\\MEDDataBaseSettings.dat")))
        (if (setq h (open (strcat sup "\\MEDDataBaseSettings.dat") "w"))
          (progn (write-line "Provider=SQLite" h)
                 (write-line (strcat "ConnectString=Data Source=" db) h) (close h))))
      (and (findfile (strcat sup "\\Project.dat")) (findfile (strcat sup "\\med.spc")) (findfile db))
    )
  )
)

;; "a;b;c" + list of new entries -> appended, case-insensitive de-dup, nothing removed
(defun MED-PathAppend (cur new / parts p s)
  (setq parts nil s (if cur cur ""))
  (while (setq p (vl-string-search ";" s))
    (setq parts (append parts (list (substr s 1 p))) s (substr s (+ p 2))))
  (if (/= s "") (setq parts (append parts (list s))))
  (foreach n new
    (if (not (vl-some '(lambda (x) (= (strcase (vl-string-right-trim "\\" x)) (strcase (vl-string-right-trim "\\" n)))) parts))
      (setq parts (append parts (list n)))))
  (setq s "")
  (foreach p parts (if (/= p "") (setq s (if (= s "") p (strcat s ";" p)))))
  s
)

;; 2) TRUSTEDPATHS + support path of the current profile
(defun MED-BundleProfile ( / files r)
  (setvar "TRUSTEDPATHS"
    (MED-PathAppend (getvar "TRUSTEDPATHS")
      (list (strcat (MED-Dir "contents") "\\...") (MED-Dir "support") (MED-Dir "usersup"))))
  (setq r (vl-catch-all-apply
            '(lambda ()
               (setq files (vla-get-Files (vla-get-Preferences (vlax-get-acad-object))))
               (vla-put-SupportPath files
                 (MED-PathAppend (vla-get-SupportPath files) (list (MED-Dir "usersup") (MED-Dir "support")))))))
  (if (vl-catch-all-error-p r)
    (princ (strcat "\nMED2026: could not update the support path: " (vl-catch-all-error-message r))))
  T
)

(defun MED-RestartNotice ()
  (princ "\nMED2026 first-run setup is complete. Please close and restart AutoCAD before using MED commands.")
  (princ)
)

;; MEDFIRSTRUN: full first-run setup; safe to re-run any time
(defun C:MEDFIRSTRUN ( / ok h msg)
  (if (not (MED-BundleDirs))
    (princ "\nMEDFIRSTRUN: not running from the MED2026 App Store bundle; nothing to do.")
    (progn
      (setq ok (MED-BundleSeed))
      (MED-BundleProfile)
      (if ok
        (progn
          (if (setq h (open (MED-Dir "flag") "w"))
            (progn (write-line (strcat "MED2026 first run completed " (rtos (getvar "CDATE") 2 6)) h) (close h)))
          (setq msg (strcat "MED2026 first-run setup is complete.\n\n"
                            "User files: " (MED-Dir "root") "\n"
                            "The MED folders were added to Trusted Locations and the support path.\n\n"
                            "Please close and restart AutoCAD before using MED.")))
        (setq msg (strcat "MED2026 first-run setup could not create all user files in\n" (MED-Dir "root")
                          "\n\nRun MEDFIRSTRUN again, or contact Moore Design.")))
      (princ (strcat "\n" (vl-string-translate "\n" " " msg)))
      (alert msg)
    )
  )
  (princ)
)

(defun MED-FirstRunNeeded ()
  (and (MED-BundleDirs) (not (findfile (MED-Dir "flag"))))
)

(if (MED-FirstRunNeeded)
  (progn
    ;; first launch: set up, then hold MED commands until restart
    (vl-bb-set '*MED-NEEDS-RESTART* T)   ; blackboard: applies to every drawing this session
    (C:MEDFIRSTRUN)
  )
)

(if (vl-bb-ref '*MED-NEEDS-RESTART*)
  (progn
    ;; Load MEDCore so the menus' commands exist, then replace every C: command it defined
    ;; with the restart notice (MEDFIRSTRUN, MEDABOUT and MEDPRIVACY stay usable).
    (setq MED-Before (atoms-family 1))
    (vl-catch-all-apply 'load (list "qkey.lsp"))
    (vl-catch-all-apply 'load (list "MEDCore.lsp"))
    (foreach s (atoms-family 1)
      (if (and (wcmatch (strcase s) "C:*")
               (not (member s MED-Before))
               (not (member (strcase s) '("C:MEDFIRSTRUN" "C:MEDABOUT" "C:MEDPRIVACY"))))
        (set (read s) (lambda () (MED-RestartNotice)))))
    (setq MED-Before nil)
    (MED-RestartNotice)
  )
  (progn
    (prompt "\nLoading MED User defined Quick Keys")
    (load "qkey.lsp")
    (prompt "\nLoading MED2026")
    (setq MED-CoreLoad (vl-catch-all-apply 'load (list "MEDCore.lsp")))
    (if (vl-catch-all-error-p MED-CoreLoad)
      (princ (strcat "\nMED2026: MEDCore load stopped (" (vl-catch-all-error-message MED-CoreLoad)
                     "). Run MEDFIRSTRUN, then restart AutoCAD.")))
    ;; XData needs these APPIDs even if MEDCore stopped early
    (foreach a (list "MED_ELEC" "MED_FITTING" "MED_CONDUIT" "MED_TRAY" "MED_EQUIP" "MED_RELATE"
                     "MED_ATTRIB" "MED_DOUBLE" "MED_CABLE" "VERT_DATA" "MEDProperties")
      (if (not (tblsearch "APPID" a)) (regapp a)))
  )
)
(princ)
