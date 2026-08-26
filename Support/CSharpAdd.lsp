(princ "\nLoading MED-DotNet")
(vl-load-com)

(defun MED-DotNet-Ready ( )
  (member (type processsqlstatementNET) '(EXRXSUBR SUBR USUBR EXSUBR))
)

(defun MED-NetLoad ( / p err oldfd )
  (cond
    ((MED-DotNet-Ready)
      (princ "\nMED-DotNet already loaded.")
    )
    ((null (setq p (findfile "MED-DotNet.dll")))
      (princ "\nMED-DotNet.dll not found on the AutoCAD support path.")
    )
    (T
      ;; Managed DLL: do not arxload. NETLOAD is a command, so only try when commands work.
      (setq oldfd (getvar "FILEDIA"))
      (setvar "FILEDIA" 0)
      (setq err (vl-catch-all-apply 'command-s (list "_.NETLOAD" p)))
      (setvar "FILEDIA" oldfd)
      (cond
        ((MED-DotNet-Ready)
          (princ "\nMED-DotNet loaded.")
        )
        ((vl-catch-all-error-p err)
          (princ (strcat "\nNETLOAD deferred: " (vl-catch-all-error-message err)))
        )
        (T
          (princ "\nMED-DotNet LispFunction not registered after NETLOAD.")
        )
      )
    )
  )
  (if (and (MED-DotNet-Ready) (= (type MEDUserStatus) 'USUBR))
    (vl-catch-all-apply 'MEDUserStatus)
  )
  (princ)
)

;; acad.lsp cannot NETLOAD (command processor not ready). Demand-load / s::startup will.
(defun-q MED-DotNet-Startup ()
  (MED-NetLoad)
)

(if (= (type S::STARTUP) 'LIST)
  (setq S::STARTUP (append S::STARTUP MED-DotNet-Startup))
  (defun-q S::STARTUP () (MED-DotNet-Startup))
)

;; Called from MED-DotNet MED Settings palette via Application.Invoke
(defun MED-GetSym (s) (eval (read s)))
(defun MED-SetSym (s v) (set (read s) v) v)
(defun MEDGETSYM (s) (MED-GetSym s))
(defun MEDSETSYM (s v) (MED-SetSym s v))
(defun MEDDO (e / r)
  (setq r (vl-catch-all-apply 'eval (list (read e))))
  (if (vl-catch-all-error-p r)
    (progn
      (princ (strcat "\nMED Settings: " (vl-catch-all-error-message r)))
      nil
    )
    r
  )
)
