# MEDDuctbankTest.ps1 - headless DUCTBANK test with accoreconsole (AutoCAD 2024).
# Works on a COPY of Samples\ConduitDuctbankStart.dwg in %TEMP%\dbk; the sample is never modified.
# MED auto-loads from the profile's Support path; this script then loads MEDDuctbank.lsp and med.spc
# from THIS checkout, runs DUCTBANK with scripted answers, runs DBKTEST / DBLIST, and saves
# <name>-result.dwg / .dxf / -report.txt in %TEMP%\dbk. BOM statements are captured, not written.
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1            (3" as drawn)
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Size 4     (4" variant + DBDELETE)
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Rgs        (plain RGS stub-ups, wrapped)
#   ... -Enc -30          stub-up encasement (turn-up) to EL -30 (default Auto = top of the elbow sweep; Top = stub top)
#   ... -Plain            reference = plain 3DPOLY made from the sample reference's vertices (no MED data; size 3, type 3)
#   ... -Edit             after the checks: move the MED_DBREF route 12" east, -DBEDIT: retag A1 -> MV-101, B2 -> 4",
#                       rebuild in place, DBKTEDITCHK (no orphans / duplicates, edited route used)
#   ... -Sweep            Options > Bends > Sweep (concrete follows the elbow arcs; default Chamfer)
# Uses -DUCTBANK (command line); accoreconsole has no WinForms UI, so DUCTBANK would fall back to it anyway.
param([double]$Size = 0, [string]$Name = "dbktest", [string]$Sample = "", [switch]$Rgs, [string]$Enc = "", [switch]$Plain, [switch]$Edit, [switch]$Sweep,
      [string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$fw = $repo.Replace('\', '/')
$d = "$env:TEMP\dbk"; New-Item -ItemType Directory -Force $d | Out-Null
$dd = $d.Replace('\', '/')
$sample = if ($Sample) { $Sample } else { Join-Path $repo "Samples\ConduitDuctbankStart.dwg" }   # Samples\ is gitignored
if (-not (Test-Path $sample)) { throw "Sample not found: $sample" }
Copy-Item $sample "$d\$Name-start.dwg" -Force
Remove-Item "$d\$Name-result.dwg", "$d\$Name-result.dxf", "$d\$Name-report.txt" -ErrorAction SilentlyContinue
if ($Size -eq 4) { $answers = "S`n*`n4`n"; $wt = 28.0; $ht = 17.88; $del = "DBKTDEL`nYes`n" }
else { $answers = ""; $wt = 24.0; $ht = 15.63; $del = "" }
if ($Rgs) { $answers += "O`nSTU`nRgs`nYes`n"; $mat = "*DBKT-STUBCODE* 1 *DBKT-WRAP* T" } else { $mat = "*DBKT-STUBCODE* 2 *DBKT-WRAP* nil" }
# stub-up encasement: both sample ends stub up -> 2 turn-ups. Auto (3") = sweep top EL -18.5 (tier 2 CL -42.5 + R24)
if ($Enc) { $answers += "O`nENcasement`n$Enc`n" }
if ($Sweep) { $answers += "O`nBends`nSweep`n" }
$encz = if ($Enc -match '^[Tt]') { "0.0" } elseif ($Enc) { $Enc } elseif ($Size -eq 4) { "nil" } else { "-18.5" }
$mat += " *DBKT-TURNUPS* 2 *DBKT-ENCZ* $encz"
if ($Plain) { $pre = "(setq *DBKT-REFH* `"264`")`nDBKTPLAIN`n"; $pick = ""; $refans = "3`n3`n"; $reftag = ""; $mat += " *DBKT-PLAIN* T" }
else { $pre = ""; $pick = "H`n264`n"; $refans = ""; $reftag = "C-101"; $mat += " *DBKT-PLAIN* nil" }
$editblk = ""
if ($Edit) {
  $editblk = "(setq *DBKT-EMOVE* 12.0)`nDBKTEDITPRE`nDBKTEDIT`n" + $(if ($Plain) { "`n`n" } else { "" }) + "2`n4`n4`nB1`nStubup`nStubup`n6`n6`nA`nT`nA1`nMV-101`nS`nB2`n4`nG`n" +
             "(setq *DBKT-ETAG* `"MV-101`" *DBKT-ESIZE* 4.0)`nDBKTEDITCHK`n"
}
$scr = @"
(load "$fw/Support/MEDDuctbank.lsp")
(load "$fw/Support/med.spc")
(load "$fw/tests/autocad/MEDDuctbankTest.lsp")
${pre}-DUCTBANK
${pick}${refans}
2
4
4
B1
Stubup
Stubup
6
6
A
${answers}G

(setq *DBKT-OUT* "$dd/$Name-report.txt" *DBKT-ROWS* 2 *DBKT-COLS* 4 *DBKT-REFTAG* "$reftag" *DBKT-SX* 6.0 *DBKT-WT* $wt *DBKT-HT* $ht *DBKT-STATIONS* 4 *DBKT-SEGS* 32 *DBKT-ELBOWS* 24 $mat *DBKT-SPEC* "$dd/$Name-spec.txt")
DBKTEST
DBKTLIST
${editblk}${del}(command "_.SAVEAS" "" "$dd/$Name-result.dwg")
(command "_.DXFOUT" "$dd/$Name-result.dxf" "16")
_.QUIT
_Y
"@
Set-Content "$d\$Name.scr" $scr -Encoding ASCII
$p = Start-Process $Accore -ArgumentList "/i `"$d\$Name-start.dwg`" /s `"$d\$Name.scr`" /l en-US" `
     -RedirectStandardOutput "$d\$Name-out.raw" -PassThru -NoNewWindow
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "accoreconsole timed out (a prompt was waiting for input)" }
$t = [IO.File]::ReadAllText("$d\$Name-out.raw") -replace "`0", ""
Set-Content "$d\$Name-out.txt" $t
$i = $t.IndexOf("Command: -DUCTBANK"); if ($i -ge 0) { $t.Substring($i) } else { $t }
if (Test-Path "$d\$Name-report.txt") { "`n---- report: $d\$Name-report.txt"; Get-Content "$d\$Name-report.txt" | Select-String "PASS|FAIL|passed" }
