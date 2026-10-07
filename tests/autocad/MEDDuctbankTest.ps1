# MEDDuctbankTest.ps1 - headless DUCTBANK test with accoreconsole (AutoCAD 2024).
# Works on a COPY of Samples\ConduitDuctbankStart.dwg in %TEMP%\dbk; the sample is never modified.
# MED auto-loads from the profile's Support path; this script then loads MEDDuctbank.lsp and med.spc
# from THIS checkout, runs DUCTBANK with scripted answers, runs DBKTEST / DBLIST, and saves
# <name>-result.dwg / .dxf / -report.txt in %TEMP%\dbk. BOM statements are captured, not written.
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1            (3" as drawn)
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Size 4     (4" variant + DBDELETE)
#   powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Rgs        (plain RGS stub-ups, wrapped)
#   ... -Enc -30          stub-up encasement (turn-up) to EL -30 (default Auto = top of the elbow sweep at 90 deg ends,
#                       the Top limit at 45 deg ends; Top = stub top
#                       less the riser projection; anything higher is cut level _DBKRISERPROJ below the riser ends)
#   ... -Proj 6           MVP4c: minimum riser projection above the level turn-up top (Options > ENcasement; default 4)
#   ... -Lay old|user     MVP4c: 3DMEDModel-Ductbank made before the build: "old" = no transparency (an earlier build;
#                       must become 75 %), "user" = 40 % set by the user (must stay 40 %)
#   ... -Plain            reference = plain 3DPOLY made from the sample reference's vertices (no MED data; size 3, type 3)
#   ... -Edit             after the checks: move the MED_DBREF route 12" east, -DBEDIT: retag A1 -> MV-101, B2 -> 4",
#                       rebuild in place, DBKTEDITCHK (no orphans / duplicates, edited route used)
#   ... -Sweep            Options > Bends > Sweep (concrete follows the elbow arcs; default Chamfer)
#   ... -Route Slope      MVP4: plain 3DPOLY route with a 1.5 deg slope over 120 ft (flex, no fittings), Options > FLex 4 deg
#   ... -Route Step       MVP4: straight route stepping down 30" at 22.5 deg and up 24" at 45 deg (vertical bends)
#   ... -Route S45        MVP4: sample reference, 1 row x 4, end B 45 deg stub-ups (Options > ANgle): 45 deg stub elbows +
#                       45 deg risers ending open at the stub-up top EL, no fitting (alias: Bub)
#   ... -Route S45x2      MVP4: as S45 with 2 rows x 4 (45 deg risers of the two rows collide: flagged) (alias: Bub2)
#   ... -Route OldBub     builds the S45 bank with e91df9d's MEDDuctbank.lsp (Mogul BUB inserts), loads this checkout's,
#                       -DBEDIT: the rebuild must drop the BUBs and purge the DBK_BUB stand-in block
#   ... -Route OldBubDel  as OldBub, then DBDELETE instead of DBEDIT: BUBs removed with the bank
#   ... -Route Old4c      MVP4d: builds the S45 bank (Auto) with f1d7184's MEDDuctbank.lsp (45 deg Auto = elbow sweep top,
#                       EL -40.97), loads this checkout's, -DBEDIT: end B rebuilt up to the riser ends less 4" (EL -5.24)
#   -Route runs DBKTPROF (profile / 45 deg / cover checks); with -Edit a -DBEDIT round trip (retag A1) + DBKTPROF again
# Uses -DUCTBANK (command line); accoreconsole has no WinForms UI, so DUCTBANK would fall back to it anyway.
param([double]$Size = 0, [string]$Name = "dbktest", [string]$Sample = "", [switch]$Rgs, [string]$Enc = "", [switch]$Plain, [switch]$Edit, [switch]$Sweep, [string]$Route = "", [string]$Proj = "", [string]$Lay = "",
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
if ($Enc -or $Proj) { $answers += "O`nENcasement`n$Enc`n$Proj`n" }
$projv = if ($Proj) { [double]$Proj } else { 4.0 }
$laytrans = if ($Lay -eq "user") { 40 } else { 75 }
$laypre = if ($Lay) { "(setq *DBKT-LAYPRE* `"$Lay`")`nDBKTLAYPRE`n" } else { "" }
if ($Sweep) { $answers += "O`nBends`nSweep`n" }
# both sample ends stub up to EL 0 (90 deg): the level cut stays $projv below the riser tops
$encz = if ($Enc -match '^[Tt]') { "$(-$projv)" } elseif ($Enc) { "$([Math]::Min([double]$Enc, -$projv))" } elseif ($Size -eq 4) { "nil" } else { "-18.5" }
$mat += " *DBKT-TURNUPS* 2 *DBKT-ENCZ* $encz *DBKT-PROJ* $projv *DBKT-LAYTRANS* $laytrans"
if ($Plain) { $pre = "(setq *DBKT-REFH* `"264`")`nDBKTPLAIN`n"; $pick = ""; $refans = "3`n3`n"; $reftag = ""; $mat += " *DBKT-PLAIN* T" }
else { $pre = ""; $pick = "H`n264`n"; $refans = ""; $reftag = "C-101"; $mat += " *DBKT-PLAIN* nil" }
$bank = "2`n4`n4`nB1`nStubup`nStubup`n6`n6`nA`n"; $rows = 2; $cols = 4; $segs = 32; $elb = 24; $stations = 4; $prof = ""; $nrows = 2
if ($Route) {
  $pc = @{ NFLEX = 0; NVB = 0; VBSTOCK = "nil"; FREE = 2; N45 = 0; ANGA = 90; ANGB = 90; FLAGS = "nil"; BOM = "nil" }
  if ($Route -eq "Bub") { $Route = "S45" }; if ($Route -eq "Bub2") { $Route = "S45x2" }
  $old = ($Route -like "OldBub*")
  switch -regex ($Route) {
    "^Slope$" { $pre = "(setq *DBKT-REFH* `"264`" *DBKT-ROUTE* '((2000 0 0) (2000 0 -48) (2000 480 -48) (2000 1920 -85.7077) (2000 2400 -85.7077) (2360 2400 -85.7077) (2360 2400 0)))`nDBKTROUTE`n"
              $answers += "O`nFL`n4`n120`n"; $stations = 29; $pc.NFLEX = 2; $pc.BOM = "'(160 170)" }
    "^Step$"  { $pre = "(setq *DBKT-REFH* `"264`" *DBKT-ROUTE* '((3000 0 0) (3000 0 -48) (3000 360 -48) (3000 432.4264 -78) (3000 912.4264 -78) (3000 936.4264 -54) (3000 1296.4264 -54) (3000 1296.4264 0)))`nDBKTROUTE`n"
              $segs = 56; $elb = 48; $stations = 17; $pc.NVB = 4; $pc.VBSTOCK = "'(22.5 22.5 45.0 45.0)"; $pc.BOM = "'(178 163)" }
    "^(S45|OldBub|OldBubDel|Old4c)$" { $pre = ""; $bank = "1`n4`nA1`nStubup`nStubup`n6`n6`nA`n"; $rows = 1; $nrows = 1; $segs = 16; $elb = 12; $stations = 4; $ht = 10.13
              $answers += "O`nAN`n90`n45`n"; $pc.N45 = 4; $pc.ANGB = 45; $pc.FLAGS = "'(`"End B: 45 deg stub-ups: the risers end open*`")"; $pc.BOM = "'(163)" }
    "^S45x2$" { $pre = ""; $answers += "O`nAN`n90`n45`n"; $pc.N45 = 8; $pc.ANGB = 45; $stations = 4
              $pc.FLAGS = "'(`"End B 45 deg risers: clear gap*`" `"End B: 45 deg stub-ups: the risers end open*`")"; $pc.BOM = "'(163)" }
    default { throw "Unknown -Route $Route (Slope, Step, S45, S45x2, OldBub, OldBubDel, Old4c)" }
  }
  if ($Route -in @("Slope", "Step")) { $pick = ""; $refans = "3`n3`n"; $reftag = ""; $mat = $mat -replace '\*DBKT-PLAIN\* nil', '*DBKT-PLAIN* T' }
  $mat = $mat -replace '\*DBKT-ENCZ\* \S+', '*DBKT-ENCZ* nil'
  $prof = "(setq *DBKT-NFLEX* $($pc.NFLEX) *DBKT-NVB* $($pc.NVB) *DBKT-VBSTOCK* $($pc.VBSTOCK) *DBKT-FREEENDS* $($pc.FREE) *DBKT-N45* $($pc.N45) *DBKT-ANGA* $($pc.ANGA) *DBKT-ANGB* $($pc.ANGB) *DBKT-FLAGPATS* $($pc.FLAGS) *DBKT-BOMCODES* $($pc.BOM))`nDBKTPROF`n"
}
$editblk = ""
# DBEDIT must take the riser projection from the bank record, not the session: reset the session value first
$projreset = "(setq _DBKRISERPROJ 4.0)`n"
if ($Route -like "Old*") { $Edit = ($Route -ne "OldBubDel") }
if ($Edit -and $Route) {
  $editblk = $projreset + "(setq *DBKT-EMOVE* nil)`nDBKTEDITPRE`nDBKTEDIT`n" + $(if ($pick -eq "") { "`n`n" } else { "" }) + ("`n" * (1 + $nrows)) + "`n`n`n`n`n`nT`nA1`nMV-101`nG`n" +
             "(setq *DBKT-ETAG* `"MV-101`" *DBKT-ESIZE* nil)`nDBKTEDITCHK`n" + $prof
} elseif ($Edit) {
  $editblk = $projreset + "(setq *DBKT-EMOVE* 12.0)`nDBKTEDITPRE`nDBKTEDIT`n" + $(if ($Plain) { "`n`n" } else { "" }) + "2`n4`n4`nB1`nStubup`nStubup`n6`n6`nA`nT`nA1`nMV-101`nS`nB2`n4`nG`n" +
             "(setq *DBKT-ETAG* `"MV-101`" *DBKT-ESIZE* 4.0)`nDBKTEDITCHK`n"
}
$setq = "(setq *DBKT-OUT* `"$dd/$Name-report.txt`" *DBKT-ROWS* $rows *DBKT-COLS* $cols *DBKT-REFTAG* `"$reftag`" *DBKT-SX* 6.0 *DBKT-WT* $wt *DBKT-HT* $ht *DBKT-STATIONS* $stations *DBKT-SEGS* $segs *DBKT-ELBOWS* $elb $mat *DBKT-SPEC* `"$dd/$Name-spec.txt`")"
if ($Route -like "Old*") {
  # a bank built by an earlier commit (e91df9d: 45 deg stub-ups with Mogul BUB inserts; f1d7184: 45 deg Auto turn-up at
  # the elbow sweep top), then this checkout's LISP: DBEDIT / DBDELETE
  $oc = if ($Route -eq "Old4c") { "f1d7184" } else { "e91df9d" }
  $oldf = "$d\MEDDuctbank-$oc.lsp"
  cmd /c "git -C `"$repo`" show ${oc}:Support/MEDDuctbank.lsp > `"$oldf`""
  if (-not (Test-Path $oldf) -or (Get-Item $oldf).Length -lt 100000) { throw "could not extract ${oc}:Support/MEDDuctbank.lsp" }
  $after = if ($Route -eq "OldBub") { $editblk + "DBKTOLDBUB`n" } elseif ($Route -eq "Old4c") { $editblk } else { "DBKTDELPRE`nDBKTDEL`nYes`nDBKTDELCHK`nDBKTOLDBUB`n" }
  $oldset = if ($Route -eq "Old4c") { "*DBKT-OLDBUBEXP* 0 *DBKT-EDROP* 0" } else { "*DBKT-OLDBUBEXP* 4 *DBKT-EDROP* 4" }
  $scr = @"
(load "$($oldf.Replace('\', '/'))")
(load "$fw/Support/med.spc")
(load "$fw/tests/autocad/MEDDuctbankTest.lsp")
-DUCTBANK
${pick}${refans}
${bank}${answers}G

DBKTBUBCOUNT
(princ (strcat "\n[T] old build: ENCZA " (vl-princ-to-string (dbk-xdval (car (dbkt-ents "ENVELOPE")) "ENCZA")) " ENCZB " (vl-princ-to-string (dbk-xdval (car (dbkt-ents "ENVELOPE")) "ENCZB"))))
(load "$fw/Support/MEDDuctbank.lsp")
(setq *DBKT-PASS* 0 *DBKT-FAIL* nil $oldset)
$setq
${after}(command "_.SAVEAS" "" "$dd/$Name-result.dwg")
(command "_.DXFOUT" "$dd/$Name-result.dxf" "16")
_.QUIT
_Y
"@
} else {
$scr = @"
(load "$fw/Support/MEDDuctbank.lsp")
(load "$fw/Support/med.spc")
(load "$fw/tests/autocad/MEDDuctbankTest.lsp")
${laypre}${pre}-DUCTBANK
${pick}${refans}
${bank}${answers}G

$setq
DBKTEST
DBKTLIST
${prof}${editblk}${del}(command "_.SAVEAS" "" "$dd/$Name-result.dwg")
(command "_.DXFOUT" "$dd/$Name-result.dxf" "16")
_.QUIT
_Y
"@
}
Set-Content "$d\$Name.scr" $scr -Encoding ASCII
$p = Start-Process $Accore -ArgumentList "/i `"$d\$Name-start.dwg`" /s `"$d\$Name.scr`" /l en-US" `
     -RedirectStandardOutput "$d\$Name-out.raw" -PassThru -NoNewWindow
if (-not $p.WaitForExit(240000)) { $p.Kill(); Write-Warning "accoreconsole timed out (a prompt was waiting for input)" }
$t = [IO.File]::ReadAllText("$d\$Name-out.raw") -replace "`0", ""
Set-Content "$d\$Name-out.txt" $t
$i = $t.IndexOf("Command: -DUCTBANK"); if ($i -ge 0) { $t.Substring($i) } else { $t }
if (Test-Path "$d\$Name-report.txt") { "`n---- report: $d\$Name-report.txt"; Get-Content "$d\$Name-report.txt" | Select-String "PASS|FAIL|passed" }
