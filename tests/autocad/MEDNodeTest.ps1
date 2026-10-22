# MEDNodeTest.ps1 - headless MEDNODE test (accoreconsole 2024).
# 1: tag all corners of a 3DPOLY run -> 3 VERTEX nodes, MED_NODE xdata, no fitting
# 2: a LINE branch tagged at a corner -> same node, 3 connections, JUNCTION (no second block)
# 3: M3D reads the nodes (no fitting = bend; same volume as MEDBendTest case 1)
# 4: med-node-set-fitting on one node -> XData only; M3D reports it, still a bend
# 5: ID = live handle (no NODE_ID__ in XData); block has the insertion POINT
# 6: MOVE route + nodes together -> nodes stay on the vertices, audit 0 (STRETCH: verify by hand, no viewport here)
# 7: node moved off its vertex -> MEDNODEAUDIT orphan; snap back -> 0
# 8: branch LINE erased -> junction node orphan (deleted route); snap drops the dead conn
# 9: flexible conduit (code 7) 3DPOLY -> bend to fit note, MITER corners, no auto radius
# 10: Long class with 48 stamped -> R 48; Long Auto -> table / underground default
param([string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path; $fw = $repo.Replace('\', '/')
$d = "$env:TEMP\mednode"; New-Item -ItemType Directory -Force $d | Out-Null; $dd = $d.Replace('\','/')
Copy-Item (Join-Path $repo "Samples\ConduitDuctbankStart.dwg") "$d\start.dwg" -Force
Copy-Item "$PSScriptRoot\MEDRouteTest.lsp" "$d\rt.lsp" -Force
Copy-Item "$PSScriptRoot\MEDBendTest.lsp" "$d\bt.lsp" -Force
$scr = @"
(setvar "SECURELOAD" 0)
(if (not _CONDUIT) (load "$fw/Support/MEDCore.lsp"))
(load "$fw/Support/MEDFunctions.lsp")
(load "$dd/rt.lsp")
(load "$fw/Support/medcon.lsp")
(load "$fw/Support/MED3DPath.lsp")
(load "$fw/Support/MEDNode.lsp")`r`n(if (not bld_conduit) (load "$fw/Support/MEDBuildXData.lsp"))
(load "$dd/bt.lsp")
(setq _TAGOFF T _CONFILL 1 *MED3D-DEBUG* T)`r`n(if (not _CODE) (setq _CODE 1)) (if (not _CSIZE) (setq _CSIZE 1.0))
(defun nt-show (tag / l) (setq l (med-node-all)) (princ (strcat "\n[RT] " tag ": " (itoa (length l)) " node(s)")) (foreach n l (princ (strcat "\n[RT]   " (cdr (assoc "ID" n)) " " (cdr (assoc "KIND" n)) " " (cdr (assoc "SYS" n)) " conn " (vl-princ-to-string (cdr (assoc "CONN" n))) " fitting " (vl-princ-to-string (cdr (assoc "FITTING" n))) " at " (vl-princ-to-string (cdr (assoc "PT" n)))))) (princ))
(setq bt-r (bt-3dpoly '((100000 2000 0) (100120 2000 0) (100120 2000 48) (100240 2000 48) (100240 2120 48))))
(xdatadd bt-r (bld_conduit _CODE _CSIZE "NONE" nil "T"))
(princ (strcat "\n[RT] tagged " (itoa (med-node-tag-run bt-r nil))))
(nt-show "RUN")
(entmake '((0 . "LINE") (8 . "0") (10 100120.0 2000.0 0.0) (11 100120.0 1900.0 0.0)))
(setq nt-l (entlast))
(xdatadd nt-l (bld_conduit _CODE _CSIZE "NONE" nil "T"))
(med-node-tag nt-l '(100120.0 2000.0 0.0) (list (med-node-seg-id nt-l 1)) T)
(nt-show "BRANCH")
(princ (strcat "\n[RT] blocks " (itoa (sslength (ssget "_X" '((0 . "INSERT") (2 . "MED_NODE")))))))
(bt-solid "M3D with nodes" bt-r "CONDUIT")
(med-node-set-fitting (cdr (assoc "ENT" (med-node-at '(100120.0 2000.0 48.0) 0.5 nil))) 12 1.0 "LB")
(nt-show "FITTING SET")
(bt-solid "M3D node fitting" bt-r "CONDUIT")
(setq nt-n (cdr (assoc "ENT" (med-node-at '(100120.0 2000.0 48.0) 0.5 nil))))
(princ (strcat "\n[RT] ID=handle " (if (= (cdr (assoc "ID" (med-node-read nt-n))) (cdr (assoc 5 (entget nt-n)))) "YES" "NO") " NODE_ID__ in xdata " (if (vl-string-search "NODE_ID__" (vl-princ-to-string (entget nt-n '("MED_NODE")))) "YES" "NO") " key " (med-node-key-of (med-node-read nt-n))))
(setq nt-e (cdr (assoc -2 (tblsearch "BLOCK" "MED_NODE"))) nt-pt nil) (while nt-e (if (= (cdr (assoc 0 (entget nt-e))) "POINT") (setq nt-pt T)) (setq nt-e (entnext nt-e)))
(princ (strcat "\n[RT] block POINT " (if nt-pt "YES" "NO")))
(princ (strcat "\n[RT] audit start " (itoa (length (med-node-audit)))))
(setq nt-ss (ssget "_X" '((0 . "INSERT") (2 . "MED_NODE")))) (ssadd bt-r nt-ss) (ssdel nt-l nt-ss)
(command "_.MOVE" nt-ss "" '(0.0 0.0 0.0) '(10.0 0.0 0.0))
(princ (strcat "\n[RT] after MOVE vertex " (vl-princ-to-string (nth 3 (med-node-verts bt-r))) " node " (vl-princ-to-string (cdr (assoc "PT" (med-node-at (nth 3 (med-node-verts bt-r)) 0.5 nil)))) " audit " (itoa (length (med-node-audit)))))
(command "_.MOVE" nt-ss "" '(10.0 0.0 0.0) '(0.0 0.0 0.0))
(setq nt-ed (entget nt-n)) (entmod (subst (cons 10 '(100125.0 2003.0 48.0)) (assoc 10 nt-ed) nt-ed))
(foreach o (med-node-audit) (princ (strcat "\n[RT] orphan " (med-node-key-of (car o)) " - " (cadr o))))
(foreach o (med-node-audit) (med-node-snap (car o)))
(princ (strcat "\n[RT] after snap audit " (itoa (length (med-node-audit))) " node at " (vl-princ-to-string (cdr (assoc 10 (entget nt-n))))))
(entdel nt-l)
(foreach o (med-node-audit) (princ (strcat "\n[RT] orphan " (med-node-key-of (car o)) " - " (cadr o))))
(foreach o (med-node-audit) (med-node-snap (car o)))
(princ (strcat "\n[RT] after snap audit " (itoa (length (med-node-audit)))))
(nt-show "AUDITED")
(setq nt-f (bt-3dpoly '((100000 3000 0) (100120 3000 0) (100120 3000 48) (100240 3000 48))))
(xdatadd nt-f (bld_conduit 7 1.0 "NONE" nil "T"))
(princ (strcat "\n[RT] flex radius src " (cdr (med3d-run-radius nt-f "CONDUIT" 1.0))))
(bt-solid "M3D flex" nt-f "CONDUIT")
(med-bend-stamp bt-r "Long" 48.0)
(princ (strcat "\n[RT] Long48 " (vl-princ-to-string (med3d-run-radius bt-r "CONDUIT" 1.315))))
(setq nt-ed (entget bt-r '("BEND_DATA"))) (entmod (append (vl-remove (assoc -3 nt-ed) nt-ed) '((-3 ("BEND_DATA" (1000 . "CLASS=STANDARD"))))))
(med-bend-stamp bt-r "Long" nil)
(princ (strcat "\n[RT] LongAuto " (vl-princ-to-string (med3d-run-radius bt-r "CONDUIT" 1.315))))
(setvar "SECURELOAD" 1)
(princ (strcat "\n[RT] SECURELOAD " (itoa (getvar "SECURELOAD"))))
_.QUIT
_Y
"@
Set-Content "$d\nt.scr" $scr -Encoding Default
$p = Start-Process $Accore -ArgumentList "/i `"$d\start.dwg`" /s `"$d\nt.scr`" /l en-US" -NoNewWindow -PassThru -RedirectStandardOutput "$d\out.txt"
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "timed out" }
$t = [IO.File]::ReadAllText("$d\out.txt", [Text.Encoding]::Unicode); Set-Content "$d\out-u.txt" $t
$t -split "`n" | ? { $_ -match '\[RT\]|error|node|Unknown|^Volume:|bad' }
