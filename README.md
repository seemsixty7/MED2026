# MED2026

AutoCAD electrical and instrumentation toolkit: equipment types, bill of materials, records, and drawing settings.

Windows x64. AutoCAD 2020 or later. MIT license.

Author: Clint Moore, PMP. Consulting: [mooredesign.net](https://mooredesign.net).

## Docs

See [docs/README.md](docs/README.md) for install, database, and the new C# commands (`MEDTYPE`, `MEDSETTINGS`, `MEDCHG`, `MEDRECORDS`, `MEDSHOWBOM`).

## Database

Default is SQLite at `Data\MED.db`.

SQL Server is optional. Set `Provider=SqlServer` (and a connection string) in `Support\MEDDataBaseSettings.dat`.

## Install

Run `MED2026-Setup.exe` (Inno wrapper) or `installer\Install-MED2026.ps1`.

The PowerShell installer copies Support, sample drawings, and the seed database, writes local `Project.dat` / `MEDDataBaseSettings.dat`, and can create a **MED2026 AutoCAD** desktop shortcut. You choose the install directory; the Setup default is `C:\MED2026`.

After files are in place, APPLOAD `Support\MED2026-ProfileSetup.lsp` and run `MED2026SETUP` once.

Do not install over a live shop PC that already uses SQL Server as the production MED database.

Useful commands: `MEDTYPE`  `MEDSETTINGS`  `MEDCHG`  `MEDSHOWBOM`

No warranty. See [LICENSE](LICENSE) (MIT).
