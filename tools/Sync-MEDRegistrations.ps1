<#
.SYNOPSIS
  Sync MED install registrations into local SQLite (Data\MEDRegistrations.db).

.DESCRIPTION
  v1 modes:
    -ImportJson <path>   Import a downloaded export JSON (works without Netlify auth).
    -Pull                GET from MedRegisterUrl?export=1 using MED_EXPORT_KEY env.
    -InitDb              Create empty schema if DB missing.

  Env (for -Pull):
    MED_REGISTER_URL   default https://mooredesign.net/.netlify/functions/med-register
    MED_EXPORT_KEY     must match Netlify site env MED_EXPORT_KEY

  MooreDesign / mooredesign.net only — not InstallHer.
#>
[CmdletBinding()]
param(
  [string]$DbPath = "",
  [string]$ImportJson = "",
  [switch]$Pull,
  [switch]$InitDb,
  [string]$MedRegisterUrl = $env:MED_REGISTER_URL
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $DbPath) {
  $DbPath = Join-Path $RepoRoot "Data\MEDRegistrations.db"
}
if (-not $MedRegisterUrl) {
  $MedRegisterUrl = "https://mooredesign.net/.netlify/functions/med-register"
}

function Ensure-Python {
  $py = Get-Command python -ErrorAction SilentlyContinue
  if (-not $py) { throw "Python required to maintain SQLite DB (python not found)." }
  return $py.Source
}

function Init-Database([string]$Path) {
  $py = Ensure-Python
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  & $py -c @"
import sqlite3, os
path = r'''$Path'''
con = sqlite3.connect(path)
con.execute('''
CREATE TABLE IF NOT EXISTS registrations (
  email TEXT PRIMARY KEY COLLATE NOCASE,
  name TEXT,
  opt_in INTEGER,
  first_seen TEXT,
  last_seen TEXT,
  last_version TEXT,
  last_channel TEXT,
  last_git TEXT,
  machine_name TEXT
)
''')
con.execute('CREATE INDEX IF NOT EXISTS idx_reg_last_seen ON registrations(last_seen)')
con.commit()
con.close()
print('ok', path)
"@
}

function Import-Records([string]$Path, [object[]]$Records) {
  $py = Ensure-Python
  $tmp = Join-Path $env:TEMP ("med-reg-import-{0}.json" -f [guid]::NewGuid().ToString("n"))
  $jsonOut = (@{ records = @($Records) } | ConvertTo-Json -Depth 6)
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($tmp, $jsonOut, $utf8NoBom)
  try {
    & $py -c @"
import sqlite3, json
db = r'''$Path'''
with open(r'''$tmp''', encoding='utf-8-sig') as f:
    data = json.load(f)
recs = data.get('records') or data.get('Registrations') or data
if isinstance(recs, dict) and 'records' in recs:
    recs = recs['records']
con = sqlite3.connect(db)
con.execute('''
CREATE TABLE IF NOT EXISTS registrations (
  email TEXT PRIMARY KEY COLLATE NOCASE,
  name TEXT,
  opt_in INTEGER,
  first_seen TEXT,
  last_seen TEXT,
  last_version TEXT,
  last_channel TEXT,
  last_git TEXT,
  machine_name TEXT
)
''')
n = 0
for r in recs:
    email = (r.get('email') or '').strip().lower()
    if not email:
        continue
    name = r.get('name') or ''
    opt = 1 if r.get('optIn', r.get('opt_in', True)) else 0
    first = r.get('firstSeen') or r.get('first_seen') or ''
    last = r.get('lastSeen') or r.get('last_seen') or ''
    ver = r.get('lastVersion') or r.get('last_version') or r.get('version') or ''
    ch = r.get('lastChannel') or r.get('last_channel') or r.get('channel') or ''
    git = r.get('lastGit') or r.get('last_git') or r.get('git') or ''
    mach = r.get('machineName') or r.get('machine_name') or ''
    con.execute('''
INSERT INTO registrations(email,name,opt_in,first_seen,last_seen,last_version,last_channel,last_git,machine_name)
VALUES(?,?,?,?,?,?,?,?,?)
ON CONFLICT(email) DO UPDATE SET
  name=excluded.name,
  opt_in=excluded.opt_in,
  first_seen=COALESCE(NULLIF(registrations.first_seen,''), excluded.first_seen),
  last_seen=excluded.last_seen,
  last_version=excluded.last_version,
  last_channel=excluded.last_channel,
  last_git=excluded.last_git,
  machine_name=excluded.machine_name
''', (email, name, opt, first, last, ver, ch, git, mach))
    n += 1
con.commit()
con.close()
print('upserted', n)
"@
  }
  finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $tmp
  }
}

if ($InitDb -or -not (Test-Path $DbPath)) {
  Write-Host "Initializing DB: $DbPath"
  Init-Database $DbPath
  if (-not $ImportJson -and -not $Pull) { return }
}

if ($ImportJson) {
  if (-not (Test-Path $ImportJson)) { throw "Import file not found: $ImportJson" }
  $doc = Get-Content -Raw -Path $ImportJson | ConvertFrom-Json
  $recs = @()
  if ($doc.records) { $recs = @($doc.records) }
  elseif ($doc -is [System.Array]) { $recs = @($doc) }
  else { throw "JSON must contain a 'records' array (export format)." }
  Write-Host "Importing $($recs.Count) record(s) from $ImportJson"
  Import-Records -Path $DbPath -Records $recs
  Write-Host "Done. DB: $DbPath"
  return
}

if ($Pull) {
  $key = $env:MED_EXPORT_KEY
  if (-not $key) {
    throw "Set MED_EXPORT_KEY env to match Netlify site env before -Pull. Or use -ImportJson with a downloaded export."
  }
  $uri = $MedRegisterUrl
  if ($uri -notmatch '\?') { $uri = "$uri?export=1" }
  elseif ($uri -notmatch 'export=') { $uri = "$uri&export=1" }
  Write-Host "Pulling from $uri"
  $headers = @{ "X-Med-Export-Key" = $key }
  $doc = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 60
  $recs = @($doc.records)
  Write-Host "Pulled $($recs.Count) record(s)"
  Import-Records -Path $DbPath -Records $recs
  Write-Host "Done. DB: $DbPath"
  return
}

Write-Host @"
Usage:
  .\tools\Sync-MEDRegistrations.ps1 -InitDb
  .\tools\Sync-MEDRegistrations.ps1 -ImportJson .\tools\med-registrations-export.sample.json
  `$env:MED_EXPORT_KEY='...'; .\tools\Sync-MEDRegistrations.ps1 -Pull

DB: $DbPath
URL: $MedRegisterUrl
"@
