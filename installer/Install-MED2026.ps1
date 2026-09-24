# MED2026 post-setup. Called by Inno as the logged-in user (visible for diagnosis),
# or run directly for a no-Inno test install.
# 0924d: -LiteralPath for <<Unnamed Profile>> (Core 0916f) so TRUSTEDPATHS/Support stick.
# 0924e: -SkipCopy for Inno unpack path; no runhidden; pause-on-error like Core 0916j.

param(
    [string]$InstallDir = "C:\MED2026",
    [ValidateSet("SQLite","SqlServer")]
    [string]$Provider = "SQLite",
    [string]$SqlConnectString = "",
    [string]$AcadYear = "",
    [switch]$SkipCopy
)

$ErrorActionPreference = "Stop"
$Log = Join-Path $InstallDir "installer\Install-MED2026.log"
function Write-Log($m) {
    $line = "$(Get-Date -Format o)  $m"
    Add-Content -LiteralPath $Log -Value $line -ErrorAction SilentlyContinue
    Write-Host $m
}

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
            if (Test-Path -LiteralPath $exe) { return @{ Root = $r; Exe = $exe; Year = $year } }
        }
    }
    return $null
}

function Get-AcadRelease([string]$year) {
    @{ "2020"="R23.1"; "2021"="R24.0"; "2022"="R24.1"; "2023"="R24.2"; "2024"="R24.3"; "2025"="R25.0"; "2026"="R25.1" }[$year]
}

function Get-AcadProductIds([string]$release) {
    $ids = @()
    foreach ($rootKey in @(
        "HKCU:\Software\Autodesk\AutoCAD\$release",
        "HKLM:\SOFTWARE\Autodesk\AutoCAD\$release"
    )) {
        if (Test-Path -LiteralPath $rootKey) {
            $ids += @(Get-ChildItem -LiteralPath $rootKey -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -like "ACAD-*" } |
                ForEach-Object { $_.PSChildName })
        }
    }
    $ids | Select-Object -Unique
}

# Ported from Core2026 0916f: <<Unnamed Profile>> requires -LiteralPath
# (PowerShell treats <<>> as wildcards). Never write paths onto Unnamed itself.
function Get-StockAcadSupportPath([string]$acadRoot) {
    $dirs = @(
        (Join-Path $acadRoot "Support"),
        (Join-Path $acadRoot "Support\en-us"),
        (Join-Path $acadRoot "Fonts"),
        (Join-Path $acadRoot "Help"),
        (Join-Path $acadRoot "Express")
    ) | Where-Object { Test-Path -LiteralPath $_ }
    return ($dirs -join ';')
}

function Get-ProfileAcadPath([string]$profileKey) {
    $general = Join-Path $profileKey "General"
    try { return [string](Get-ItemProperty -LiteralPath $general -Name "ACAD" -ErrorAction Stop).ACAD } catch { return "" }
}

function Get-ProfileTrustedPaths([string]$profileKey) {
    $vars = Join-Path $profileKey "Variables"
    try { return [string](Get-ItemProperty -LiteralPath $vars -Name "TRUSTEDPATHS" -ErrorAction Stop).TRUSTEDPATHS } catch { return "" }
}

function Get-BestCloneSource([string]$profilesRoot) {
    $unnamed = Join-Path $profilesRoot "<<Unnamed Profile>>"
    if (Test-Path -LiteralPath $unnamed) {
        Write-Log "Clone source: <<Unnamed Profile>> (current default)"
        return $unnamed
    }
    $best = $null
    $bestLen = -1
    $names = @('Default') + @(Get-ChildItem -LiteralPath $profilesRoot -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName })
    foreach ($name in ($names | Select-Object -Unique)) {
        if ($name -eq '<<Unnamed Profile>>') { continue }
        $key = Join-Path $profilesRoot $name
        if (-not (Test-Path -LiteralPath $key)) { continue }
        $len = (Get-ProfileAcadPath $key).Length
        if ($len -gt $bestLen) { $bestLen = $len; $best = $key }
    }
    if ($best) { Write-Log "Clone source (fallback): $best" }
    return $best
}

function Set-MedProfilePaths([string]$dest, [string]$supportDstLocal, [string]$stockAcadPath) {
    $general = Join-Path $dest "General"
    $vars = Join-Path $dest "Variables"
    if (-not (Test-Path -LiteralPath $general)) { New-Item -Path $general -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $vars)) { New-Item -Path $vars -Force | Out-Null }

    $cur = ""
    try { $cur = [string](Get-ItemProperty -LiteralPath $general -Name "ACAD" -ErrorAction Stop).ACAD } catch { $cur = "" }
    if ([string]::IsNullOrWhiteSpace($cur) -and $stockAcadPath) {
        $cur = $stockAcadPath
        Write-Log "Seeded stock AutoCAD support paths into profile (was empty)"
    }
    $parts = @($cur -split ';' | Where-Object { $_ -and $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $supportDstLocal.TrimEnd('\')) })
    $newAcad = ((@($supportDstLocal) + $parts) -join ';')
    New-ItemProperty -LiteralPath $general -Name "ACAD" -Value $newAcad -PropertyType String -Force | Out-Null

    $curT = ""
    try { $curT = [string](Get-ItemProperty -LiteralPath $vars -Name "TRUSTEDPATHS" -ErrorAction Stop).TRUSTEDPATHS } catch { $curT = "" }
    $tparts = @($curT -split ';' | Where-Object { $_ -and $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $supportDstLocal.TrimEnd('\')) })
    $newTrusted = ((@($supportDstLocal) + $tparts) -join ';')
    New-ItemProperty -LiteralPath $vars -Name "TRUSTEDPATHS" -Value $newTrusted -PropertyType String -Force | Out-Null
    Write-Log "Set ACAD/TRUSTEDPATHS on $dest (ACAD len=$($newAcad.Length); TRUSTEDPATHS len=$($newTrusted.Length))"
}

try {
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
Write-Log "Installing MED2026 to $InstallDir  (provider $Provider; SkipCopy=$SkipCopy) as $env:USERNAME"

$supportDst = Join-Path $InstallDir "Support"
$dwgDst     = Join-Path $InstallDir "Dwg"
$dataDst    = Join-Path $InstallDir "Data"
New-Item -ItemType Directory -Force -Path $InstallDir, $supportDst, $dwgDst, $dataDst | Out-Null

$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not $SkipCopy) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot "Support\ACAD.LSP"))) {
        throw "Cannot find Support\ACAD.LSP under $RepoRoot"
    }
    Write-Log "Copying Support from $RepoRoot ..."
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
    if (Test-Path -LiteralPath $srcDwg) {
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
    $restoreCmd = Join-Path $RepoRoot "installer\RestoreMEDProfile.cmd"
    if (Test-Path -LiteralPath $restoreCmd) {
        Copy-Item -Path $restoreCmd -Destination (Join-Path $InstallDir "RestoreMEDProfile.cmd") -Force
        Write-Log "Copied RestoreMEDProfile.cmd to $InstallDir"
    }

    $seedDb = Join-Path $RepoRoot "Data\MED.db"
    if (Test-Path -LiteralPath $seedDb) {
        Copy-Item $seedDb (Join-Path $dataDst "MED.db") -Force
    }
} else {
    Write-Log "SkipCopy: using files already under $InstallDir (Inno unpacked)"
    $acadLsp = Join-Path $supportDst "ACAD.LSP"
    $medCore = Join-Path $supportDst "MEDCore.lsp"
    if (-not ((Test-Path -LiteralPath $acadLsp) -or (Test-Path -LiteralPath $medCore))) {
        throw "SkipCopy: neither Support\ACAD.LSP nor Support\MEDCore.lsp found under $InstallDir"
    }
    Write-Log "SkipCopy gate OK (found Support LSP under $supportDst)"
}

$dbPath = Join-Path $dataDst "MED.db"
$projectDatPath = Join-Path $supportDst "Project.dat"
if (-not (Test-Path -LiteralPath $projectDatPath)) {
    $projectDat = @"
MED.db
$supportDst
$supportDst
$supportDst
$dwgDst
"@
    Set-Content -LiteralPath $projectDatPath -Value $projectDat.TrimEnd() -Encoding ASCII
    Write-Log "Wrote $projectDatPath"
} else {
    Write-Log "Left existing Project.dat in place"
}

# Do not clobber a live SQL Server dat if one is already there (re-run / update).
$settingsPath = Join-Path $supportDst "MEDDataBaseSettings.dat"
if (-not (Test-Path -LiteralPath $settingsPath)) {
    if ($Provider -eq "SqlServer") {
        if (-not $SqlConnectString) { throw "SqlServer provider requires -SqlConnectString" }
        $settings = "Provider=SqlServer`r`nConnectString=$SqlConnectString"
    } else {
        $settings = "Provider=SQLite`r`nConnectString=Data Source=$dbPath"
    }
    Set-Content -LiteralPath $settingsPath -Value $settings -Encoding ASCII
    Write-Log "Wrote $settingsPath"
} else {
    Write-Log "Left existing MEDDataBaseSettings.dat in place"
}

try {
    $sqliteDll = Join-Path $supportDst "System.Data.SQLite.dll"
    if ((Test-Path -LiteralPath $sqliteDll) -and (Test-Path -LiteralPath $dbPath)) {
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
Write-Log "Set user env MED2026=$InstallDir"

$acad = Get-AcadInfo
if (-not $acad) {
    Write-Log "AutoCAD 2020-2024 not found. Files are in place. Add $supportDst to the support path after AutoCAD is installed."
} else {
    Write-Log "Found AutoCAD $($acad.Year) at $($acad.Exe)"
    $rel = Get-AcadRelease $acad.Year

    $stock = Get-StockAcadSupportPath $acad.Root
    Write-Log "Stock support seed length=$($stock.Length)"
    Write-Log "NonInteractive -> Clone Unnamed into 'MED2026' (never write onto Unnamed itself)"

    $products = @(Get-AcadProductIds $rel)
    Write-Log "Product keys found for $rel : $(if ($products) { $products -join ', ' } else { '(none)' })"
    if (-not $products) {
        Write-Log "No ACAD-* product key for $rel. Creating MED2026 profile keys anyway."
        $products = @("ACAD-7101:409")
    }
    foreach ($product in $products) {
        $hkcuProduct = "HKCU:\Software\Autodesk\AutoCAD\$rel\$product"
        $profiles = Join-Path $hkcuProduct "Profiles"
        if (-not (Test-Path -LiteralPath $profiles)) {
            New-Item -Path $profiles -Force | Out-Null
        }
        $dest = Join-Path $profiles "MED2026"
        if (-not (Test-Path -LiteralPath $dest)) {
            $src = Get-BestCloneSource $profiles
            if ($src -and (Test-Path -LiteralPath $src)) {
                Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
                Write-Log "Created profile MED2026 on $product from $src (ACAD len=$((Get-ProfileAcadPath $dest).Length))"
            } else {
                New-Item -Path $dest -Force | Out-Null
                Write-Log "No clone source on $product - created empty MED2026 then seeding stock paths"
            }
        } else {
            Write-Log "Profile MED2026 already exists on $product (will patch paths)"
        }
        Set-MedProfilePaths $dest $supportDst $stock
        $acadLen = (Get-ProfileAcadPath $dest).Length
        $tpLen = (Get-ProfileTrustedPaths $dest).Length
        Write-Log "Patched TRUSTEDPATHS/ACAD for $product (ACAD len=$acadLen; TRUSTEDPATHS len=$tpLen) -> $supportDst"
    }

    # Always create user desktop shortcut (single source of truth; Inno [Icons] removed).
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

    Write-Host "MED2026 profile configured OK (ACAD support + TRUSTEDPATHS include $supportDst)." -ForegroundColor Green
}

# Navisworks MEDProperties plugin -> per-user AppData (this script runs as logged-in user).
$navisDll = Join-Path $InstallDir "installer\navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll"
if (Test-Path -LiteralPath $navisDll) {
    foreach ($edition in @("Manage", "Simulate")) {
        $roamer = "C:\Program Files\Autodesk\Navisworks $edition 2024\Roamer.exe"
        if (-not (Test-Path -LiteralPath $roamer)) {
            Write-Log "Navisworks $edition 2024 not found; skip plugin"
            continue
        }
        $destDir = Join-Path $env:APPDATA "Autodesk\Navisworks $edition 2024\Plugins\MEDPropertiesPlugin"
        try {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
            Copy-Item $navisDll (Join-Path $destDir "MEDPropertiesPlugin.dll") -Force
            Write-Log "Installed Navis plugin for $edition -> $destDir"
        } catch {
            Write-Log ("Navis plugin for $edition failed: " + $_.Exception.Message)
        }
    }
} else {
    Write-Log "Navis plugin staging DLL not present (component skipped or missing)"
}

Write-Log "Done. Files are in $InstallDir"
Write-Log "Launch MED2026 AutoCAD from the desktop shortcut (first-run script applies the profile)."
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message)
    Write-Host ""
    Write-Host ("INSTALL FAILED: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("Full log: " + $Log) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    try { [void](Read-Host) } catch { Start-Sleep 30 }
    throw
}