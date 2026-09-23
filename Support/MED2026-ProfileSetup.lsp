;; MED2026 first-run / repair. Same pattern as UECoreInstall.lsp:
;; write the current AutoCAD profile via Preferences COM, not ACADPREFIX.
;; Trusted location is set FIRST so later lsp/dll loads do not stack prompts.
;;
;; EnterpriseMenuFile is UE-CORE only. MED never owns that slot.
;; MED loads med.cuix with a one-shot CUILOAD when the MED group is not
;; already loaded. After the first successful run, desktop shortcuts drop /b
;; so this file is not re-run every launch (that was the "group already exists" nag).
(vl-load-com)

(defun MED2026-Root ( / root )
  (setq root (getenv "MED2026"))
  (if (or (not root) (= root "")) (setq root "C:\\MED2026"))
  root
)

(defun MED2026-SupportRoot ( )
  (strcat (MED2026-Root) "\\Support")
)

(defun MED2026-FilesPref ( )
  (vla-get-files (vla-get-preferences (vlax-get-acad-object)))
)

(defun MED2026-EnsureSettings ( / p f db )
  (setq p (strcat (MED2026-SupportRoot) "\\MEDDataBaseSettings.dat")
        db (strcat (MED2026-Root) "\\Data\\MED.db")
  )
  (if (not (findfile p))
    (progn
      (setq f (open p "w"))
      (if f
        (progn
          (write-line "Provider=SQLite" f)
          (write-line (strcat "ConnectString=Data Source=" db) f)
          (close f)
        )
      )
    )
  )
)

(defun MED2026-EnsureTrusted ( support / files tp )
  ;; setenv writes Profiles\<name>\Variables\TRUSTEDPATHS (what Options shows).
  (setq tp (getenv "TRUSTEDPATHS"))
  (if (not tp) (setq tp ""))
  (if (not (vl-string-search (strcase support) (strcase tp)))
    (setenv "TRUSTEDPATHS" (if (= tp "") support (strcat support ";" tp)))
  )
  (vl-catch-all-apply
    '(lambda ( )
       (setq files (MED2026-FilesPref)
             tp (vlax-get-property files 'TrustedPaths)
       )
       (if (not tp) (setq tp ""))
       (if (not (vl-string-search (strcase support) (strcase tp)))
         (vlax-put-property files 'TrustedPaths
           (if (= tp "") support (strcat support ";" tp))
         )
       )
     )
  )
)

(defun MED2026-EnsureSupportPath ( support / files acadPath )
  (setq files (MED2026-FilesPref)
        acadPath (vla-get-SupportPath files)
  )
  (if (not (vl-string-search (strcase support) (strcase acadPath)))
    (vla-put-SupportPath files (strcat support ";" acadPath))
  )
)

(defun MED2026-ClearEnterpriseIfOurs ( support / files cur menubase )
  ;; If a prior MED installer parked med.cuix in EnterpriseMenuFile, clear it.
  ;; Leave any other enterprise menu alone (UE-Core profiles).
  (setq menubase (strcat support "\\med")
        files (MED2026-FilesPref)
        cur (vl-catch-all-apply
              '(lambda ( ) (vla-get-EnterpriseMenuFile files))
            )
  )
  (if (vl-catch-all-error-p cur) (setq cur ""))
  (if (not cur) (setq cur ""))
  (setq cur (vl-princ-to-string cur))
  (if (and (/= cur "")
           (or (vl-string-search (strcase menubase) (strcase cur))
               (vl-string-search "\\MED.CUIX" (strcase cur))
               (vl-string-search "/MED.CUIX" (strcase cur))
               (vl-string-search "\\MED/" (strcase cur))
               (vl-string-search "/MED/" (strcase cur))))
    (progn
      (vl-catch-all-apply
        '(lambda ( ) (vla-put-EnterpriseMenuFile files ""))
      )
      (vl-catch-all-apply '(lambda ( ) (setenv "EnterpriseMenuFile" "")))
    )
  )
)

(defun MED2026-UnloadRibbon ( )
  (foreach g '("MEDRibbon" "MEDRIBBON" "MedRibbon")
    (if (menugroup g)
      (vl-catch-all-apply 'command-s (list "_.CUIUNLOAD" g))
    )
  )
)

(defun MED2026-MedGroupLoaded ( / )
  (or (menugroup "MED")
      (menugroup "Med")
      (menugroup "med")
  )
)

(defun MED2026-LoadMedMenu ( support / p )
  ;; Partial CUILOAD only when MED is not already a loaded group.
  (setq p (strcat support "\\med.cuix"))
  (if (not (findfile p)) (setq p (strcat support "\\MED.cuix")))
  (if (and (findfile p) (not (MED2026-MedGroupLoaded)))
    (vl-catch-all-apply 'command-s (list "_.CUILOAD" p))
  )
  (vl-catch-all-apply 'setvar (list "MENUBAR" 1))
)

(defun MED2026-FixShortcut ( lnk / wsh sc args )
  (if (findfile lnk)
    (progn
      (setq wsh (vlax-create-object "WScript.Shell")
            sc (vlax-invoke-method wsh 'CreateShortcut lnk)
            args (vlax-get-property sc 'Arguments)
      )
      (if (not args) (setq args ""))
      ;; Drop any /b first-run script; keep only the MED2026 profile.
      (if (or (vl-string-search "/B" (strcase args))
              (vl-string-search "FIRSTRUN" (strcase args))
              (vl-string-search "PROFILESETUP" (strcase args)))
        (progn
          (vlax-put-property sc 'Arguments "/p MED2026")
          (vlax-invoke-method sc 'Save)
        )
      )
      (if sc (vlax-release-object sc))
      (if wsh (vlax-release-object wsh))
    )
  )
)

(defun MED2026-StripRunOnce ( / pub )
  (setq pub (getenv "PUBLIC"))
  (if (not pub) (setq pub "C:\\Users\\Public"))
  (foreach lnk (list
      (strcat (getenv "USERPROFILE") "\\Desktop\\MED2026 AutoCAD.lnk")
      (strcat pub "\\Desktop\\MED2026 AutoCAD.lnk")
    )
    (vl-catch-all-apply 'MED2026-FixShortcut (list lnk))
  )
)

(defun C:MED2026SETUP ( / support )
  (setq support (MED2026-SupportRoot))
  (MED2026-EnsureSettings)
  (MED2026-EnsureTrusted support)
  (MED2026-EnsureSupportPath support)
  (MED2026-ClearEnterpriseIfOurs support)
  (vla-put-LoadAcadLspInAllDocuments
    (vla-get-system (vla-get-preferences (vlax-get-acad-object)))
    :vlax-true
  )
  (MED2026-UnloadRibbon)
  (MED2026-LoadMedMenu support)
  (if (and (findfile "ACAD.LSP") (not (boundp 'C:MEDCHG)))
    (vl-catch-all-apply 'load (list "ACAD.LSP"))
  )
  (MED2026-StripRunOnce)
  (princ "\nMED2026 profile updated (CUILOAD med.cuix if needed, MENUBAR=1, no enterprise menu).")
  (princ)
)

(C:MED2026SETUP)
