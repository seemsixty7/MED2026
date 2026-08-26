# MED2026 installer
# Copies Support, Dwgs, Data to C:\MED2026, writes Project.dat and
# MEDDataBaseSettings.dat, creates an AutoCAD profile shortcut, inserts
# the current Windows login into MEDUsers.
#
# GitHub: this script is the install source of truth. Inno Setup can wrap it later.

param(
    [string]$InstallDir = "C:\MED2026",
    [ValidateSet("SQLite","SqlServer")]
    [string]$Provider = "SQLite",
    [string]$SqlConnectString = "",
    [string]$AcadYear = "2024"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot "Support\ACAD.LSP"))) {
    throw "Cannot find Support\ACAD.LSP under $RepoRoot"
}

function Get-AcadInfo([string]$year) {
    foreach ($r in @(
        "C:\Program Files\Autodesk\AutoCAD $year",
        "C:\Program Files\Autodesk\AutoCAD $year - English"
    )) {
        $exe = Join-Path $r "acad.exe"
        if (Test-Path $exe) { return @{ Root = $r; Exe = $exe; Year = $year } }
    }
    return $null
}

function Get-AcadRelease([string]$year) {
    @{ "2020"="R23.1"; "2022"="R24.1"; "2024"="R24.3"; "2025"="R25.0"; "2026"="R25.1" }[$year]
}

Write-Host "Installing MED2026 to $InstallDir  (provider $Provider)"
$supportDst = Join-Path $InstallDir "Support"
$dwgsDst = Join-Path $InstallDir "Dwgs"
$dataDst = Join-Path $InstallDir "Data"
New-Item -ItemType Directory -Force -Path $InstallDir, $supportDst, $dwgsDst, $dataDst | Out-Null

Write-Host "Copying Support..."
Copy-Item -Path (Join-Path $RepoRoot "Support\*") -Destination $supportDst -Recurse -Force

$sample = Join-Path $RepoRoot "Samples"
if (Test-Path $sample) {
    Copy-Item -Path (Join-Path $sample "*") -Destination $dwgsDst -Recurse -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path (Join-Path $RepoRoot "installer\MED2026-ProfileSetup.lsp") -Destination (Join-Path $supportDst "MED2026-ProfileSetup.lsp") -Force
Copy-Item -Path (Join-Path $RepoRoot "Data\MED.db") -Destination (Join-Path $dataDst "MED.db") -Force

$dbPath = Join-Path $dataDst "MED.db"
$projectDat = @"
MED.db
$supportDst
$supportDst
$supportDst
$dwgsDst
"@
Set-Content -Path (Join-Path $supportDst "Project.dat") -Value $projectDat.TrimEnd() -Encoding ASCII

if ($Provider -eq "SqlServer") {
    if (-not $SqlConnectString) { throw "SqlServer provider requires -SqlConnectString" }
    $settings = "Provider=SqlServer`r`nConnectString=$SqlConnectString"
} else {
    $settings = "Provider=SQLite`r`nConnectString=Data Source=$dbPath"
}
Set-Content -Path (Join-Path $supportDst "MEDDataBaseSettings.dat") -Value $settings -Encoding ASCII

try {
    $sqliteDll = Join-Path $supportDst "System.Data.SQLite.dll"
    if (Test-Path $sqliteDll) {
        Add-Type -Path $sqliteDll
        $conn = New-Object System.Data.SQLite.SQLiteConnection ("Data Source=$dbPath")
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "INSERT OR IGNORE INTO MEDUsers (UserName, UserType, DefaultSpec) VALUES (@u, @t, @s)"
        [void]$cmd.Parameters.AddWithValue("@u", $env:USERNAME)
        [void]$cmd.Parameters.AddWithValue("@t", "User")
        [void]$cmd.Parameters.AddWithValue("@s", "")
        [void]$cmd.ExecuteNonQuery()
        $conn.Close()
        Write-Host "MEDUsers: added $env:USERNAME"
    }
} catch {
    Write-Host "MEDUsers insert skipped: $($_.Exception.Message)"
}

[Environment]::SetEnvironmentVariable("MED2026", $InstallDir, "User")
$env:MED2026 = $InstallDir

$acad = Get-AcadInfo $AcadYear
if (-not $acad) {
    Write-Host "AutoCAD $AcadYear not found. Files are in place. Add $supportDst to the support path manually."
} else {
    $rel = Get-AcadRelease $AcadYear
    $base = "HKCU:\Software\Autodesk\AutoCAD\$rel"
    if (Test-Path $base) {
        $product = (Get-ChildItem $base | Where-Object { $_.PSChildName -like "ACAD-*" } | Select-Object -First 1).PSChildName
        if ($product) {
            $profiles = "HKCU:\Software\Autodesk\AutoCAD\$rel\$product\Profiles"
            $dest = Join-Path $profiles "MED2026"
            if (-not (Test-Path $dest)) {
                $src = Join-Path $profiles "<<Unnamed Profile>>"
                if (-not (Test-Path $src)) { $src = Join-Path $profiles "Default" }
                if (Test-Path $src) {
                    Copy-Item $src $dest -Recurse -Force
                    Write-Host "Created AutoCAD profile MED2026"
                } else {
                    New-Item -ItemType Directory -Force -Path $dest | Out-Null
                }
            }
        }
    }
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "MED2026 AutoCAD.lnk"
    $sc = $wsh.CreateShortcut($lnk)
    $sc.TargetPath = $acad.Exe
    $sc.Arguments = "/p MED2026"
    $sc.WorkingDirectory = $InstallDir
    $sc.Description = "AutoCAD with MED2026 profile"
    $sc.Save()
    Write-Host "Desktop shortcut: $lnk"
}

Write-Host ""
Write-Host "Done. Files are in $InstallDir"
Write-Host "Launch the MED2026 AutoCAD shortcut, then APPLOAD Support\MED2026-ProfileSetup.lsp and run MED2026SETUP once."
Write-Host "Commands: MEDTYPE  MEDSETTINGS  MEDCHG  MEDSHOWBOM"
