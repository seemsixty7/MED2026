# MEDChgDeleteTest.ps1 - classic MEDCHG Delete removes only the selected record (accoreconsole 2024).
param([string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path; $fw = $repo.Replace('\', '/')
$d = "$env:TEMP\medchgdel"; New-Item -ItemType Directory -Force $d | Out-Null; $dd = $d.Replace('\','/')
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
(load "$fw/Support/medchg.lsp")
(setq _TAGOFF T _CONFILL 1)
(setq ct-e (bt-3dpoly '((300000 2000 0) (300120 2000 0))))
(xdatadd ct-e (bld_cable '(1 1 1) '(1.0 1.0 1.0) '("CA" "CB" "CC") '("NONE" "NONE" "NONE") '(10.0 20.0 30.0) '("T" "T" "T")))
(xdatadd ct-e (bld_conduit 1 1.0 "C1" nil "T"))
(defun ct-show (k / ) (app_chg_lst ct-e nil) (princ (strcat "\n[RT] " k " records " (itoa (length tag_list)))) (foreach r tag_list (princ (strcat "\n[RT]   " (cdr (assoc 2 r))))) (princ))
(ct-show "BEFORE")
(setq chg_ent ct-e MEDUPD T index_val -1)
(setq datalist (car (vl-remove-if-not '(lambda (r) (equal (assoc 3 r) (cons 3 "CB"))) tag_list)) tag_list (subst (subst (cons 2 "DELETED") (assoc 2 datalist) datalist) datalist tag_list))
(upd_tag_list)
(ct-show "AFTER del CB")
(princ (strcat "\n[RT] entity alive " (if (entget ct-e) "YES" "NO")))
(setvar "SECURELOAD" 1)
(princ (strcat "\n[RT] SECURELOAD " (itoa (getvar "SECURELOAD"))))
_.QUIT
_Y
"@
Set-Content "$d\ct.scr" $scr -Encoding Default
$p = Start-Process $Accore -ArgumentList "/i `"$d\start.dwg`" /s `"$d\ct.scr`" /l en-US" -NoNewWindow -PassThru -RedirectStandardOutput "$d\out.txt"
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "timed out" }
$t = [IO.File]::ReadAllText("$d\out.txt", [Text.Encoding]::Unicode); Set-Content "$d\out-u.txt" $t
$t -split "`n" | ? { $_ -match '\[RT\]|error|node|Unknown|^Volume:|bad' }

