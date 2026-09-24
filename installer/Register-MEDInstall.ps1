<#
.SYNOPSIS
  POST MED opt-in registration to MooreDesign Netlify. Failures are logged only.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RegistrationFile,
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$Version = "",
  [string]$Channel = "full",
  [string]$Git = "",
  [string]$BuildDate = "",
  [string]$LogPath = ""
)

$ErrorActionPreference = "Continue"
function Write-RegLog([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  if ($LogPath) {
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 } catch {}
  }
}

try {
  if (-not $Url -or $Url -match 'YOUR_|placeholder|example\.com') {
    Write-RegLog "Skip POST: MedRegisterUrl not configured ($Url)"
    exit 0
  }
  if (-not (Test-Path $RegistrationFile)) {
    Write-RegLog "Skip POST: registration file missing"
    exit 0
  }
  $reg = Get-Content -Raw -Path $RegistrationFile | ConvertFrom-Json
  if (-not $reg.optIn) {
    Write-RegLog "Skip POST: optIn false"
    exit 0
  }
  $payload = @{
    name        = [string]$reg.name
    email       = [string]$reg.email
    version     = $(if ($Version) { $Version } else { [string]$reg.lastVersion })
    channel     = $(if ($Channel) { $Channel } else { [string]$reg.lastChannel })
    git         = $Git
    buildDate   = $BuildDate
    machineName = $env:COMPUTERNAME
    timestamp   = (Get-Date).ToString("o")
  }
  $json = $payload | ConvertTo-Json -Compress
  Write-RegLog "POST $Url"
  Invoke-RestMethod -Method Post -Uri $Url -ContentType "application/json; charset=utf-8" -Body $json -TimeoutSec 20 | Out-Null
  Write-RegLog "POST ok"
}
catch {
  Write-RegLog ("POST failed (ignored): " + $_.Exception.Message)
}
exit 0
