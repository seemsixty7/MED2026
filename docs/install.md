# Install

Default directory: `C:\MED2026`.

After files are in place, see [overview.md](overview.md) and [setup.md](setup.md) for what MED is and how to scale a drawing.

## MED2026-Setup.exe

Run `MED2026-Setup.exe` (Inno wrapper). It unpacks the tree under `{app}` then runs `installer\Install-MED2026.ps1` with `-Provider SQLite`. Setup default is `C:\MED2026`.

## PowerShell

From the repo or an unpacked tree:

```
powershell -ExecutionPolicy Bypass -File installer\Install-MED2026.ps1
```

Optional parameters: `-InstallDir`, `-Provider SQLite|SqlServer`, `-SqlConnectString`, `-AcadYear` (default 2024).

The script copies Support and the seed database `Data\MED.db`. It writes local `Support\Project.dat` and `Support\MEDDataBaseSettings.dat`, inserts the current Windows login into `MEDUsers`, sets user environment variable `MED2026`, and can create a **MED2026 AutoCAD** desktop shortcut (`acad.exe /p MED2026`).

## After files are in place

1. Launch AutoCAD (the MED2026 shortcut if you have it).
2. APPLOAD `installer\MED2026-ProfileSetup.lsp` (the installer also copies this next to Support).
3. Run `MED2026SETUP` once.

`MED2026SETUP` puts Support first on the AutoCAD search path, adds it to trusted paths, and CUILOADs `med.cuix` if found. Safe to run more than once.

`CSharpAdd.lsp` NETLOADs `MED-DotNet.dll` on startup. Then: `MEDTYPE`, `MEDSETTINGS`, `MEDCHG`, `MEDSHOWBOM`.

4. `SETUP` for scale and title block. `MEDSETTINGS` for conduit/tray defaults this session.

## Do not

Do not install this over a live shop PC that already runs MED against SQL Server. Default is a local SQLite file at `C:\MED2026\Data\MED.db`. SQL Server is optional and separate; see [database.md](database.md).
