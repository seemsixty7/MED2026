# MED2026 post-setup. Called hidden by Inno as the logged-in user.
# Users do not run this file. It writes Project.dat / MEDDataBaseSettings.dat,
# inserts MEDUsers, clones an AutoCAD HKCU profile named MED2026, and
# creates a desktop shortcut if Inno did not.

param(
    [string]$InstallDir = "C:\MED2026",
    [ValidateSet("SQLite","SqlServer")]
    [string]$Provider = "SQLite",
    [string]$SqlConnectString = "",
    [string]$AcadYear = ""
)

$ErrorActionPreference = "Stop"
$Log = Join-Path $InstallDir "installer\Install-MED2026.log"
function Write-Log($m) {
    $line = "$(Get-Date -Format o)  $m"
    Add-Content -Path $Log -Value $line -ErrorAction SilentlyContinue
    Write-Host $m
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot "Support\ACAD.LSP"))) {
    throw "Cannot find Support\ACAD.LSP under $RepoRoot"
}

New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
Write-Log "Installing MED2026 to $InstallDir  (provider $Provider) as $env:USERNAME"

$supportDst = Join-Path $InstallDir "Support"
$dwgDst     = Join-Path $InstallDir "Dwg"
$dataDst    = Join-Path $InstallDir "Data"
New-Item -ItemType Directory -Force -Path $InstallDir, $supportDst, $dwgDst, $dataDst | Out-Null

Write-Log "Copying Support..."
Get-ChildItem -Path (Join-Path $RepoRoot "Support") -Recurse -File | ForEach-Object {
    $skip = @(
        "MEDDataBaseSettings.dat","Project.dat","acad.rx",
        "MEDMain.odcl","TODO-MEDMainDialogs-CSharpUI.txt",
        "MEDMainDialogs-RedoWithCSharp.lsp","TESTICONONEINCHa.bmp",
        "MEDDataBaseSettings.example.dat"
    )
    if ($skip -contains $_.Name) { return }
    $rel = $_.FullName.Substring((Join-Path $RepoRoot "Support").Length).TrimStart('\')
    $dest = Join-Path $supportDst $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item $_.FullName $dest -Force
}

# Block library is Dwg (not Dwgs, not Samples). Skip leftover Csch1.
$srcDwg = Join-Path $RepoRoot "Dwg"
if (Test-Path $srcDwg) {
    Write-Log "Copying Dwg library..."
    Get-ChildItem -Path $srcDwg -Recurse -File | ForEach-Object {
        if ($_.Name -match '^(?i)csch1\.dwg$') { return }
        $rel = $_.FullName.Substring($srcDwg.Length).TrimStart('\')
        $dest = Join-Path $dwgDst $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item $_.FullName $dest -Force
    }
} else {
    Write-Log "WARNING: no Dwg folder at $srcDwg"
}

Copy-Item -Path (Join-Path $RepoRoot "installer\MED2026-ProfileSetup.lsp") -Destination (Join-Path $supportDst "MED2026-ProfileSetup.lsp") -Force
Copy-Item -Path (Join-Path $RepoRoot "installer\MED2026-FirstRun.scr") -Destination (Join-Path $supportDst "MED2026-FirstRun.scr") -Force -ErrorAction SilentlyContinue

$seedDb = Join-Path $RepoRoot "Data\MED.db"
if (Test-Path $seedDb) {
    Copy-Item $seedDb (Join-Path $dataDst "MED.db") -Force
}

$dbPath = Join-Path $dataDst "MED.db"
$projectDat = @"
MED.db
$supportDst
$supportDst
$supportDst
$dwgDst
"@
Set-Content -Path (Join-Path $supportDst "Project.dat") -Value $projectDat.TrimEnd() -Encoding ASCII

# Do not clobber a live SQL Server dat if one is already there (re-run / update).
$settingsPath = Join-Path $supportDst "MEDDataBaseSettings.dat"
if (-not (Test-Path $settingsPath)) {
    if ($Provider -eq "SqlServer") {
        if (-not $SqlConnectString) { throw "SqlServer provider requires -SqlConnectString" }
        $settings = "Provider=SqlServer`r`nConnectString=$SqlConnectString"
    } else {
        $settings = "Provider=SQLite`r`nConnectString=Data Source=$dbPath"
    }
    Set-Content -Path $settingsPath -Value $settings -Encoding ASCII
    Write-Log "Wrote $settingsPath"
} else {
    Write-Log "Left existing MEDDataBaseSettings.dat in place"
}

try {
    $sqliteDll = Join-Path $supportDst "System.Data.SQLite.dll"
    if ((Test-Path $sqliteDll) -and (Test-Path $dbPath)) {
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
        Write-Log "MEDUsers: added $env:USERNAME"
    }
} catch {
    Write-Log "MEDUsers insert skipped: $($_.Exception.Message)"
}

[Environment]::SetEnvironmentVariable("MED2026", $InstallDir, "User")
$env:MED2026 = $InstallDir

function Get-AcadInfo {
    $years = @()
    if ($AcadYear) { $years += $AcadYear }
    $years += "2024","2023","2022","2021","2020"
    $years = $years | Select-Object -Unique
    foreach ($year in $years) {
        foreach ($r in @(
            "C:\Program Files\Autodesk\AutoCAD $year",
            "C:\Program Files\Autodesk\AutoCAD $year - English"
        )) {
            $exe = Join-Path $r "acad.exe"
            if (Test-Path $exe) { return @{ Root = $r; Exe = $exe; Year = $year } }
        }
    }
    return $null
}

function Get-AcadRelease([string]$year) {
    @{ "2020"="R23.1"; "2021"="R24.0"; "2022"="R24.1"; "2023"="R24.2"; "2024"="R24.3"; "2025"="R25.0"; "2026"="R25.1" }[$year]
}

$acad = Get-AcadInfo
if (-not $acad) {
    Write-Log "AutoCAD 2020-2024 not found. Files are in place. Add $supportDst to the support path after AutoCAD is installed."
} else {
    Write-Log "Found AutoCAD $($acad.Year) at $($acad.Exe)"
    $rel = Get-AcadRelease $acad.Year
    function Get-AcadProductIds([string]$release) {
        $ids = @()
        foreach ($root in @(
            "HKCU:\Software\Autodesk\AutoCAD\$release",
            "HKLM:\SOFTWARE\Autodesk\AutoCAD\$release"
        )) {
            if (Test-Path $root) {
                $ids += @(Get-ChildItem $root | Where-Object { $_.PSChildName -like "ACAD-*" } | ForEach-Object { $_.PSChildName })
            }
        }
        $ids | Select-Object -Unique
    }
    function Set-MedProfilePaths([string]$dest) {
        $general = Join-Path $dest "General"
        $vars = Join-Path $dest "Variables"
        New-Item -ItemType Directory -Force -Path $general, $vars | Out-Null
        # Support search path lives on General\ACAD.
        $cur = ""
        try { $cur = (Get-ItemProperty -Path $general -Name "ACAD" -ErrorAction Stop).ACAD } catch { $cur = "" }
        $parts = @($cur -split ';' | Where-Object { $_ -and $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $supportDst.TrimEnd('\')) })
        New-ItemProperty -Path $general -Name "ACAD" -Value ((@($supportDst) + $parts) -join ';') -PropertyType String -Force | Out-Null
        # AutoCAD 2024+ Trusted Locations are Variables\TRUSTEDPATHS, not General.
        $cur = ""
        try { $cur = (Get-ItemProperty -Path $vars -Name "TRUSTEDPATHS" -ErrorAction Stop).TRUSTEDPATHS } catch { $cur = "" }
        $parts = @($cur -split ';' | Where-Object { $_ -and $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $supportDst.TrimEnd('\')) })
        New-ItemProperty -Path $vars -Name "TRUSTEDPATHS" -Value ((@($supportDst) + $parts) -join ';') -PropertyType String -Force | Out-Null
    }
    $products = @(Get-AcadProductIds $rel)
    if (-not $products) {
        Write-Log "No ACAD-* product key for $rel. Creating MED2026 profile keys anyway."
        $products = @("ACAD-7101:409")
    }
    foreach ($product in $products) {
        $hkcuProduct = "HKCU:\Software\Autodesk\AutoCAD\$rel\$product"
        $profiles = Join-Path $hkcuProduct "Profiles"
        New-Item -ItemType Directory -Force -Path $profiles | Out-Null
        $dest = Join-Path $profiles "MED2026"
        if (-not (Test-Path $dest)) {
            $src = Join-Path $profiles "<<Unnamed Profile>>"
            if (-not (Test-Path $src)) { $src = Join-Path $profiles "Default" }
            if (Test-Path $src) {
                Copy-Item $src $dest -Recurse -Force
                Write-Log "Created profile MED2026 on $product from $src"
            } else {
                New-Item -ItemType Directory -Force -Path $dest | Out-Null
                Write-Log "Created empty profile MED2026 on $product"
            }
        } else {
            Write-Log "Profile MED2026 already exists on $product"
        }
        Set-MedProfilePaths $dest
        Write-Log "Wrote Variables\\TRUSTEDPATHS and General\\ACAD for $product -> $supportDst"
    }

    $wsh = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "MED2026 AutoCAD.lnk"
    $sc = $wsh.CreateShortcut($lnk)
    $sc.TargetPath = $acad.Exe
    $sc.Arguments = "/p MED2026 /b `"$($supportDst)\MED2026-FirstRun.scr`""
    $sc.WorkingDirectory = $InstallDir
    $sc.Description = "AutoCAD with MED2026 profile"
    $sc.Save()
    Write-Log "Desktop shortcut: $lnk"

    $public = [Environment]::GetFolderPath("CommonDesktopDirectory")
    if ($public -and ($public -ne $desktop)) {
        $plnk = Join-Path $public "MED2026 AutoCAD.lnk"
        try {
            $psc = $wsh.CreateShortcut($plnk)
            $psc.TargetPath = $acad.Exe
            $psc.Arguments = "/p MED2026 /b `"$($supportDst)\MED2026-FirstRun.scr`""
            $psc.WorkingDirectory = $InstallDir
            $psc.Description = "AutoCAD with MED2026 profile"
            $psc.Save()
            Write-Log "Public desktop shortcut: $plnk"
        } catch {
            Write-Log "Public desktop shortcut skipped: $($_.Exception.Message)"
        }
    }
}

Write-Log "Done. Files are in $InstallDir"
Write-Log "Launch MED2026 AutoCAD from the desktop shortcut (first-run script applies the profile)."
