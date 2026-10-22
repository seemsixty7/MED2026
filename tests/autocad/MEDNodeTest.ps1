# MEDNodeTest.ps1 - headless MEDNODE test (accoreconsole 2024).
# 1: tag all corners of a 3DPOLY run -> 3 VERTEX nodes, MED_NODE xdata, no fitting
# 2: a LINE branch tagged at a corner -> same node, 3 connections, JUNCTION (no second block)
# 3: M3D reads the nodes (no fitting = bend; same volume as MEDBendTest case 1)
# 4: med-node-set-fitting on one node -> XData only; M3D reports it, still a bend
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
