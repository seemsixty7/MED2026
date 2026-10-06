# MEDDuctbankTest.ps1 - headless DUCTBANK test with accoreconsole (AutoCAD 2024).
# Works on a COPY of Samples\ConduitDuctbankStart.dwg in %TEMP%\dbk; the sample is never modified.
# MED auto-loads from the profile's Support path; this script then loads MEDDuctbank.lsp and med.spc
# from THIS checkout, runs DUCTBANK with scripted answers, runs DBKTEST / DBLIST, and saves
# <name>-result.dwg / .dxf / -report.txt in %TEMP%\dbk. BOM statements are captured, not written.
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1            (3" as drawn)
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Size 4     (4" variant + DBDELETE)
param([double]$Size = 0, [string]$Name = "dbktest", [string]$Sample = "",
      [string]$Accore = "C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$fw = $repo.Replace('\', '/')
$d = "$env:TEMP\dbk"; New-Item -ItemType Directory -Force $d | Out-Null
$dd = $d.Replace('\', '/')
$sample = if ($Sample) { $Sample } else { Join-Path $repo "Samples\ConduitDuctbankStart.dwg" }   # Samples\ is gitignored
if (-not (Test-Path $sample)) { throw "Sample not found: $sample" }
Copy-Item $sample "$d\$Name-start.dwg" -Force
Remove-Item "$d\$Name-result.dwg", "$d\$Name-result.dxf", "$d\$Name-report.txt" -ErrorAction SilentlyContinue
if ($Size -eq 4) { $edit = "S`n*`n4`n"; $wt = 28.0; $ht = 17.88; $del = "DBKTDEL`nYes`n" }
else { $edit = ""; $wt = 24.0; $ht = 15.63; $del = "" }
$scr = @"
(load "$fw/Support/MEDDuctbank.lsp")
(load "$fw/Support/med.spc")
(load "$fw/tests/autocad/MEDDuctbankTest.lsp")
DUCTBANK
H
264

2
4
4
B1
Stubup
Stubup
6
6
A
${edit}G

(setq *DBKT-OUT* "$dd/$Name-report.txt" *DBKT-ROWS* 2 *DBKT-COLS* 4 *DBKT-REFTAG* "C-101" *DBKT-SX* 6.0 *DBKT-WT* $wt *DBKT-HT* $ht *DBKT-STATIONS* 4 *DBKT-SEGS* 32 *DBKT-ELBOWS* 24)
DBKTEST
DBKTLIST
${del}(command "_.SAVEAS" "" "$dd/$Name-result.dwg")
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
$i = $t.IndexOf("Command: DUCTBANK"); if ($i -ge 0) { $t.Substring($i) } else { $t }
if (Test-Path "$d\$Name-report.txt") { "`n---- report: $d\$Name-report.txt"; Get-Content "$d\$Name-report.txt" | Select-String "PASS|FAIL|passed" }
