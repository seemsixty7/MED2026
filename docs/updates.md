# MED2026 updates (full vs patch)

Version scheme: **`2026.0.MMDD`** (example: `2026.0.0924b`).  
Setup filenames use the same date stamp: `MED2026-Setup-0924b`, `MED2026-Patch-0924b`.

## Version file

After install (full or patch), read:

`{app}\Support\MED.version.txt`

Fields:

| Key | Meaning |
|-----|---------|
| `version` | Product version (`2026.0.0924b`) |
| `build_date` | ISO date the installer was built |
| `git` | Short commit hash of the tree that shipped |
| `channel` | `full` (admin Setup) or `patch` (non-admin patch) |

## Optional install registration (opt-in)

Full Setup and Patch show an optional wizard page:

- Checkbox: **Register this install (optional)**
- Name + Email (enabled only when checked; light email validation)

**Privacy**

- Registration is **opt-in only**. Nothing is sent unless the box is checked (or a prior opt-in file already exists).
- Payload to Moore Design: name, email, version, channel (`full`|`patch`), git hash, build date, optional machine name, timestamp.
- No drawings, project paths, licenses, or Autodesk credentials are sent.
- Endpoint is **MooreDesign Netlify only** (`mooredesign.net`) - not InstallHer.

**Local reuse file**

`{app}\Support\MED.registration.json`

```json
{
  "optIn": true,
  "name": "...",
  "email": "...",
  "firstRegistered": "ISO",
  "lastVersion": "2026.0.0924b",
  "lastChannel": "full|patch"
}
```

- **Patch**: if this file exists with `optIn: true`, the wizard page is skipped and the installer POSTs an update with the new version/channel.
- HTTP failures are logged only and **never** fail the install.
- Configure URL via `#define MedRegisterUrl` in `installer\MED2026.iss` / `MED2026-Patch.iss` (default `https://mooredesign.net/.netlify/functions/med-register`).

**Online delivery + local SQLite (email-only)**

| Piece | Path / URL |
|-------|------------|
| Netlify Function (email-only) | `netlify/functions/med-register.js` on mooredesign.net |
| Destination inbox | `MED_REGISTER_TO` = `clintmoore@mooredesign.net` |
| Subject filter | `[MED-REGISTER] {name} \| {email} \| {version} \| {channel}` |
| Local SQLite copy | `Data\MEDRegistrations.db` in this repo |

The function emails each opt-in registration (FormSubmit by default; Resend if `RESEND_API_KEY` is set). **No Netlify Blobs.** Jane/Clint apply `[MED-REGISTER]` emails into `Data\MEDRegistrations.db` manually (or a future Jane routine).

Local DB helpers (import / init still useful; live `-Pull` export is obsolete):

```powershell
.\tools\Sync-MEDRegistrations.ps1 -InitDb
.\tools\Sync-MEDRegistrations.ps1 -ImportJson .\tools\med-registrations-export.sample.json
```

Deploy steps: `netlify\README-med-register.md`. Do **not** deploy this function to InstallHer Netlify sites.
FormSubmit may require a one-time confirmation click the first time mail is sent to `clintmoore@mooredesign.net`. Production serverless IPs often fall through to **Netlify Forms** + email notify to the same address.

## Full Setup (`installer\MED2026.iss`)

- **PrivilegesRequired=admin**
- Default dir: `{sd}\MED2026` (typically `C:\MED2026`)
- Installs Support, Data, Dwg, profile setup script
- Creates AutoCAD **MED2026** profile (via `Install-MED2026.ps1`)
- Does **not** overwrite existing `MEDDataBaseSettings.dat` / `Project.dat` / `MED.registration.json`
- Optional component **navis**: stages MEDPropertiesPlugin.dll under {app}\installer\navis\; post-setup PowerShell (logged-in user) copies it to %AppData%\Autodesk\Navisworks Manage|Simulate 2024\Plugins\MEDPropertiesPlugin\ only if Roamer.exe exists
- Does **not** redistribute Autodesk Navisworks API DLLs
- Optional registration page (see above)

## Patch (`installer\MED2026-Patch.iss`)

- **PrivilegesRequired=lowest** (no UAC elevation)
- Detects install dir from env `MED2026`, else `{sd}\MED2026`, else suggests `{userdocs}\MED2026`
- Overwrites Support DLL + changed LISP + `MED.version.txt` **when `{app}\Support` is writable**
- Always can install the Navisworks plugin under `%AppData%\Autodesk\...` (per-user)
- Does **not** rewrite AutoCAD profile, `.dat` settings, or `MED.db`
- Reuses `MED.registration.json` when opted in (skips page; POSTs version update)
- Restart AutoCAD and Navisworks after patching

### Non-admin limit

If `C:\MED2026` was created by an elevated full Setup, a normal user often **cannot** write Support there. The patch wizard warns and can still install the Navisworks AppData plugin. Fixes:

1. Re-run full Setup as administrator, or  
2. Choose / install MED under a user-writable path, or  
3. Copy Support files manually from a machine that can write the folder

## Preferred non-admin path

For shops that want zero-admin updates:

1. First install with full Setup once (admin) **or** install MED under a user-owned folder.
2. Distribute `MED2026-Patch-*.exe` for subsequent Support + Navis updates.
3. Confirm `Support\MED.version.txt` shows the new `version` / `channel=patch`.

## Update tracking

1. **Local** - `MED.version.txt` (implemented).
2. **GitHub Releases** - [seemsixty7/MED2026](https://github.com/seemsixty7/MED2026/releases) as source of truth for Setup/Patch EXEs.
3. **Opt-in registration** - MooreDesign Netlify function + local SQLite sync (implemented; function deploy may need Clint Netlify login).

## Build notes

```text
MSBuild src\MED-DotNet\MED-DotNet\MED-DotNet.csproj /p:Configuration=Release /p:Platform=x64
MSBuild src\MED-Navisworks\MED-Navisworks\MED-Navisworks.csproj /p:Configuration=Release /p:Platform=x64
copy MED-DotNet.dll -> Support\
copy MEDPropertiesPlugin.dll -> installer\staging\Navis\MEDPropertiesPlugin\
ISCC installer\MED2026.iss
ISCC installer\MED2026-Patch.iss
```

If Dropbox locks `installer\Output`, compile with `/O` to `%LOCALAPPDATA%\Temp\MED2026-Output` then copy the EXEs into `installer\Output`.
