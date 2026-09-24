# MED2026 updates (full vs patch)

Version scheme: **`2026.0.MMDD`** (example: `2026.0.0924`).  
Setup filenames use the same date stamp: `MED2026-Setup-0924a`, `MED2026-Patch-0924a`.

## Version file

After install (full or patch), read:

`{app}\Support\MED.version.txt`

Fields:

| Key | Meaning |
|-----|---------|
| `version` | Product version (`2026.0.0924`) |
| `build_date` | ISO date the installer was built |
| `git` | Short commit hash of the tree that shipped |
| `channel` | `full` (admin Setup) or `patch` (non-admin patch) |

## Full Setup (`installer\MED2026.iss`)

- **PrivilegesRequired=admin**
- Default dir: `{sd}\MED2026` (typically `C:\MED2026`)
- Installs Support, Data, Dwg, profile setup script
- Creates AutoCAD **MED2026** profile (via `Install-MED2026.ps1`)
- Does **not** overwrite existing `MEDDataBaseSettings.dat` / `Project.dat`
- Optional component **navis**: stages MEDPropertiesPlugin.dll under {app}\installer\navis\; post-setup PowerShell (logged-in user) copies it to %AppData%\Autodesk\Navisworks Manage|Simulate 2024\Plugins\MEDPropertiesPlugin\ only if Roamer.exe exists
- Does **not** redistribute Autodesk Navisworks API DLLs

## Patch (`installer\MED2026-Patch.iss`)

- **PrivilegesRequired=lowest** (no UAC elevation)
- Detects install dir from env `MED2026`, else `{sd}\MED2026`, else suggests `{userdocs}\MED2026`
- Overwrites Support DLL + changed LISP + `MED.version.txt` **when `{app}\Support` is writable**
- Always can install the Navisworks plugin under `%AppData%\Autodesk\...` (per-user)
- Does **not** rewrite AutoCAD profile, `.dat` settings, or `MED.db`
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

## Future update tracking (not built yet)

1. **Local** — `MED.version.txt` (implemented now).  
2. **GitHub Releases** — treat [seemsixty7/MED2026](https://github.com/seemsixty7/MED2026/releases) as the source of truth for available Setup/Patch EXEs.  
3. **Optional later** — phone-home / register install — out of scope; do not build a server for this.

## Build notes

```text
MSBuild src\MED-DotNet\MED-DotNet\MED-DotNet.csproj /p:Configuration=Release /p:Platform=x64
MSBuild src\MED-Navisworks\MED-Navisworks\MED-Navisworks.csproj /p:Configuration=Release /p:Platform=x64
copy MED-DotNet.dll → Support\
copy MEDPropertiesPlugin.dll → installer\staging\Navis\MEDPropertiesPlugin\
ISCC installer\MED2026.iss
ISCC installer\MED2026-Patch.iss
```

If Dropbox locks `installer\Output`, compile with `/O` to `%LOCALAPPDATA%\Temp\MED2026-Output` then copy the EXEs into `installer\Output`.

