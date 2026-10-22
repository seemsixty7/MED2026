# MEDRouteTest.ps1 - headless CONDUIT / CABLE 2D-3D routing test (accoreconsole 2024).
# Case 1: old CONDUIT steps (PLINE + fillet; the old pause loop can't be scripted) vs new CONDUIT in Auto, flat points -> same filleted LWPOLYLINE.
# Case 2: CONDUIT Auto with an Elev rise -> 3DPOLY, no fillet; M3D solid with mitered corners.
# Case 3: LINE with MED_CONDUIT xdata -> solid.  Case 4: CABLE 3D mode (remembered) + RUN3DCABLE.
param([string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path; $fw = $repo.Replace('\', '/')
$d = "$env:TEMP\medroute"; New-Item -ItemType Directory -Force $d | Out-Null; $dd = $d.Replace('\','/')
Copy-Item (Join-Path $repo "Samples\ConduitDuctbankStart.dwg") "$d\start.dwg" -Force
Copy-Item "$PSScriptRoot\MEDRouteTest.lsp" "$d\rt.lsp" -Force
$scr = @"
(setvar "SECURELOAD" 0)
(load "$fw/Support/MEDFunctions.lsp")
(load "$dd/rt.lsp")
(setq _TAGOFF nil _CONFILL 1)
(rt-oldsim '((100000 0) (100120 0) (100120 96) (100240 96)))
(setq rt-old (rt-info "OLD CONDUIT 2D" (entlast)))
(load "$fw/Support/medcon.lsp")
(load "$fw/Support/medcable.lsp")
(load "$fw/Support/MED3DPath.lsp")
(setq _TAGOFF nil _CONFILL 1)
CONDUIT
Auto
100000,1000
100120,1000
100120,1096
100240,1096

NEW2D
(setq rt-new (rt-info "NEW CONDUIT 2D (Auto)" (entlast)))
(rt-cmp rt-old rt-new)
CONDUIT

100000,2000
100120,2000
E
48
100120,2000
100240,2000
100240,2120

NEW3D
(rt-info "NEW CONDUIT 3D (Auto+Elev)" (entlast))
(rt-solid "CONDUIT 3D" (entlast) "CONDUIT")
(rt-line)
(rt-solid "LINE" (entlast) "CONDUIT")
(rt-solid "2D LW" rt-new "CONDUIT")
CONDUIT
3D
100000,4000,10
100100,4000,10

T3
(rt-info "CONDUIT 3D mode flat" (entlast))
(princ (strcat "\n[RT] remembered mode " *MED-ROUTE-MODE*))
(setvar "SECURELOAD" 1)
(princ (strcat "\n[RT] SECURELOAD " (itoa (getvar "SECURELOAD"))))
_.QUIT
_Y
"@
Set-Content "$d\rt.scr" $scr -Encoding Default
$p = Start-Process $Accore -ArgumentList "/i `"$d\start.dwg`" /s `"$d\rt.scr`" /l en-US" -NoNewWindow -PassThru -RedirectStandardOutput "$d\out.txt"
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "timed out" }
$t = [IO.File]::ReadAllText("$d\out.txt", [Text.Encoding]::Unicode); Set-Content "$d\out-u.txt" $t
$t -split "`n" | ? { $_ -match '\[RT\]|error|3D route|MED3D|Unknown|^Volume:' }
