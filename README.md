# MED2026

AutoCAD electrical and instrumentation toolkit: equipment types, bill of materials, records, and drawing settings.

## Requirements

- Windows x64
- AutoCAD 2020 or later

## Database

Default is SQLite at `Data\MED.db`.

SQL Server is optional. Set `Provider=SqlServer` (and a connection string) in `Support\MEDDataBaseSettings.dat`.

## Install

Run `MED2026-Setup.exe` (Inno wrapper) or `installer\Install-MED2026.ps1`.

The PowerShell installer copies Support, sample drawings, and the seed database, writes local `Project.dat` / `MEDDataBaseSettings.dat`, and can create a **MED2026 AutoCAD** desktop shortcut. You choose the install directory; the Setup default is `C:\MED2026`.

After files are in place, APPLOAD `Support\MED2026-ProfileSetup.lsp` and run `MED2026SETUP` once.

Useful commands: `MEDTYPE`  `MEDSETTINGS`  `MEDCHG`  `MEDSHOWBOM`

## Author

Dewitt Clinton Moore. Find MED and consulting at [mooredesign.net](https://mooredesign.net).

No warranty. See [LICENSE](LICENSE) (MIT).
