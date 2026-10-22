# MEDBendTest.ps1 - headless 3D-bend test (accoreconsole 2024), r15.
# 1: 3DPOLY flat - rise 48 - flat (route drawing itself is covered by MEDRouteTest.ps1) (1") -> 3DPOLY, M3D bends FITTED, volume = area x (straights+arcs)
# 2: same route with *MED3D-SHARP-3D* T -> r14 miter still available
# 3: 3DPOLY with a 3" rise -> segment too short: run skipped, marker on MED_3DFLAG
# 4: Specific radius stamped by MEDBENDR-style BEND_DATA -> R 10, source run Specific
# 2D unchanged: run MEDRouteTest.ps1 (old vs new geometry IDENTICAL).
param([string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path; $fw = $repo.Replace('\', '/')
$d = "$env:TEMP\medbend"; New-Item -ItemType Directory -Force $d | Out-Null; $dd = $d.Replace('\','/')
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
(load "$dd/bt.lsp")
(setq _TAGOFF T _CONFILL 1 *MED3D-DEBUG* T)`r`n(if (not _CODE) (setq _CODE 1)) (if (not _CSIZE) (setq _CSIZE 1.0))
(princ (strcat "\n[RT] version " *MED3D-VERSION* " sharp3d " (vl-princ-to-string *MED3D-SHARP-3D*) " code " (vl-princ-to-string _CODE)))
(setq bt-r (bt-3dpoly '((100000 2000 0) (100120 2000 0) (100120 2000 48) (100240 2000 48) (100240 2120 48))))
(xdatadd bt-r (bld_conduit _CODE _CSIZE "NONE" nil "T"))
(rt-info "CONDUIT 3D" bt-r)
(bt-solid "BENDS flat-rise48-flat" bt-r "CONDUIT")
(setq *MED3D-SHARP-3D* T)
(bt-solid "SHARP r14 switch" bt-r "CONDUIT")
(setq *MED3D-SHARP-3D* 'OFF)
(setq bt-s (bt-3dpoly '((100000 5000 0) (100120 5000 0) (100120 5000 3) (100240 5000 3))))
(xdatadd bt-s (bld_conduit _CODE _CSIZE "NONE" nil "T"))
(bt-solid "SHORT 3in rise" bt-s "CONDUIT")
(bt-flags)
(med-bend-stamp bt-r "Specific" 10.0)
(bt-solid "SPECIFIC R10" bt-r "CONDUIT")
(setvar "SECURELOAD" 1)
(princ (strcat "\n[RT] SECURELOAD " (itoa (getvar "SECURELOAD"))))
_.QUIT
_Y
"@
Set-Content "$d\bt.scr" $scr -Encoding Default
$p = Start-Process $Accore -ArgumentList "/i `"$d\start.dwg`" /s `"$d\bt.scr`" /l en-US" -NoNewWindow -PassThru -RedirectStandardOutput "$d\out.txt"
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "timed out" }
$t = [IO.File]::ReadAllText("$d\out.txt", [Text.Encoding]::Unicode); Set-Content "$d\out-u.txt" $t
$t -split "`n" | ? { $_ -match '\[RT\]|error|3D route|MED3D|Unknown|^Volume:|bad' }

