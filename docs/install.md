# Install

Default directory: `C:\MED2026`.

After files are in place, see [overview.md](overview.md) and [setup.md](setup.md) for what MED is and how to scale a drawing.

The shipped `MED-DotNet.dll` is .NET Framework 4.7.2, built against AutoCAD 2020 references. That covers AutoCAD **2020–2024**. AutoCAD **2025/2026** need a separate .NET 8 build (not in this tree yet). Native ObjectARX is also later, as per-year rebuilds.

## MED2026-Setup.exe

Run `MED2026-Setup.exe`. Users do not run a PowerShell script.

It unpacks `Support`, `Data`, and the block library as `{app}\Dwg` (the Jane `Dwg` folder, not Samples, not a `Dwgs` folder). Then it silently creates the AutoCAD profile **MED2026** and a **MED2026 AutoCAD** desktop shortcut (`acad.exe /p MED2026`). Default install dir is `C:\MED2026`.

Run Setup as the Windows user who will use AutoCAD, and click Yes on UAC. The AutoCAD profile is per-user (HKCU). AutoCAD 2020, 2022, or 2024 must already be installed.

## After files are in place

1. Double-click **MED2026 AutoCAD** on the desktop.
2. APPLOAD `Support\MED2026-ProfileSetup.lsp` and run `MED2026SETUP` once. That CUILOADs `med.cuix`. Safe to run more than once.

`CSharpAdd.lsp` NETLOADs `MED-DotNet.dll` on startup. Then: `MEDTYPE`, `MEDSETTINGS`, `MEDCABLE`, `MEDCHG`, `MEDSHOWBOM`.

3. `SETUP` for scale and title block. `MEDSETTINGS` for conduit/tray defaults this session.

## Do not

Do not install this over a live shop PC that already runs MED against SQL Server. Default is a local SQLite file at `C:\MED2026\Data\MED.db`. SQL Server is optional and separate; see [database.md](database.md).

Do not let Setup overwrite a live `Support\MEDDataBaseSettings.dat` or `Project.dat`.
