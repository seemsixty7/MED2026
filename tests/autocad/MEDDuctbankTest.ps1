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
#   ... -Route Slope      MVP4: plain 3DPOLY route with a 1.5 deg slope over 120 ft (flex, no fittings), Options > FLex 4 deg
#   ... -Route Step       MVP4: straight route stepping down 30" at 22.5 deg and up 24" at 45 deg (vertical bends)
#   ... -Route Bub        MVP4: sample reference, 1 row x 4, end B 45 deg stub-ups into Mogul BUBs (Options > ANgle)
#   ... -Route Bub2       MVP4: as Bub with 2 rows x 4 (rows collide at 45 deg: flagged)
#   -Route runs DBKTPROF (profile / BUB / cover checks); with -Edit a -DBEDIT round trip (retag A1) + DBKTPROF again
# Uses -DUCTBANK (command line); accoreconsole has no WinForms UI, so DUCTBANK would fall back to it anyway.
param([double]$Size = 0, [string]$Name = "dbktest", [string]$Sample = "", [switch]$Rgs, [string]$Enc = "", [switch]$Plain, [switch]$Edit, [switch]$Sweep, [string]$Route = "",
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
$bank = "2`n4`n4`nB1`nStubup`nStubup`n6`n6`nA`n"; $rows = 2; $cols = 4; $segs = 32; $elb = 24; $stations = 4; $prof = ""; $nrows = 2
if ($Route) {
  $pc = @{ NFLEX = 0; NVB = 0; VBSTOCK = "nil"; FREE = 2; NBUB = 0; ANGA = 90; ANGB = 90; FLAGS = "nil"; BOM = "nil" }
  switch ($Route) {
    "Slope" { $pre = "(setq *DBKT-REFH* `"264`" *DBKT-ROUTE* '((2000 0 0) (2000 0 -48) (2000 480 -48) (2000 1920 -85.7077) (2000 2400 -85.7077) (2360 2400 -85.7077) (2360 2400 0)))`nDBKTROUTE`n"
              $answers += "O`nFL`n4`n120`n"; $stations = 29; $pc.NFLEX = 2; $pc.BOM = "'(160 170)" }
    "Step"  { $pre = "(setq *DBKT-REFH* `"264`" *DBKT-ROUTE* '((3000 0 0) (3000 0 -48) (3000 360 -48) (3000 432.4264 -78) (3000 912.4264 -78) (3000 936.4264 -54) (3000 1296.4264 -54) (3000 1296.4264 0)))`nDBKTROUTE`n"
              $segs = 56; $elb = 48; $stations = 17; $pc.NVB = 4; $pc.VBSTOCK = "'(22.5 22.5 45.0 45.0)"; $pc.BOM = "'(178 163)" }
    "Bub"   { $pre = ""; $bank = "1`n4`nA1`nStubup`nStubup`n6`n6`nA`n"; $rows = 1; $nrows = 1; $segs = 16; $elb = 12; $stations = 4; $ht = 10.13
              $answers += "O`nAN`n90`n45`n"; $pc.NBUB = 4; $pc.ANGB = 45; $pc.FLAGS = "'(`"End B: 45 deg stub-ups end at Mogul BUB*`")"; $pc.BOM = "'(94 163)" }
    "Bub2"  { $pre = ""; $answers += "O`nAN`n90`n45`n"; $pc.NBUB = 8; $pc.ANGB = 45; $stations = 4
              $pc.FLAGS = "'(`"End B 45 deg risers: clear gap*`" `"End B: 3* BUB bodies are*row pitch*`")"; $pc.BOM = "'(94 163)" }
    default { throw "Unknown -Route $Route (Slope, Step, Bub, Bub2)" }
  }
  if ($Route -in @("Slope", "Step")) { $pick = ""; $refans = "3`n3`n"; $reftag = ""; $mat = $mat -replace '\*DBKT-PLAIN\* nil', '*DBKT-PLAIN* T' }
  $mat = $mat -replace '\*DBKT-ENCZ\* \S+', '*DBKT-ENCZ* nil'
  $prof = "(setq *DBKT-NFLEX* $($pc.NFLEX) *DBKT-NVB* $($pc.NVB) *DBKT-VBSTOCK* $($pc.VBSTOCK) *DBKT-FREEENDS* $($pc.FREE) *DBKT-NBUB* $($pc.NBUB) *DBKT-ANGA* $($pc.ANGA) *DBKT-ANGB* $($pc.ANGB) *DBKT-FLAGPATS* $($pc.FLAGS) *DBKT-BOMCODES* $($pc.BOM))`nDBKTPROF`n"
}
$editblk = ""
if ($Edit -and $Route) {
  $editblk = "(setq *DBKT-EMOVE* nil)`nDBKTEDITPRE`nDBKTEDIT`n" + $(if ($pick -eq "") { "`n`n" } else { "" }) + ("`n" * (1 + $nrows)) + "`n`n`n`n`n`nT`nA1`nMV-101`nG`n" +
             "(setq *DBKT-ETAG* `"MV-101`" *DBKT-ESIZE* nil)`nDBKTEDITCHK`n" + $prof
} elseif ($Edit) {
  $editblk = "(setq *DBKT-EMOVE* 12.0)`nDBKTEDITPRE`nDBKTEDIT`n" + $(if ($Plain) { "`n`n" } else { "" }) + "2`n4`n4`nB1`nStubup`nStubup`n6`n6`nA`nT`nA1`nMV-101`nS`nB2`n4`nG`n" +
             "(setq *DBKT-ETAG* `"MV-101`" *DBKT-ESIZE* 4.0)`nDBKTEDITCHK`n"
}
$scr = @"
(load "$fw/Support/MEDDuctbank.lsp")
(load "$fw/Support/med.spc")
(load "$fw/tests/autocad/MEDDuctbankTest.lsp")
${pre}-DUCTBANK
${pick}${refans}
${bank}${answers}G

(setq *DBKT-OUT* "$dd/$Name-report.txt" *DBKT-ROWS* $rows *DBKT-COLS* $cols *DBKT-REFTAG* "$reftag" *DBKT-SX* 6.0 *DBKT-WT* $wt *DBKT-HT* $ht *DBKT-STATIONS* $stations *DBKT-SEGS* $segs *DBKT-ELBOWS* $elb $mat *DBKT-SPEC* "$dd/$Name-spec.txt")
DBKTEST
DBKTLIST
${prof}${editblk}${del}(command "_.SAVEAS" "" "$dd/$Name-result.dwg")
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
