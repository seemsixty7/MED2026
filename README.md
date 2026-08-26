# MED2026

AutoCAD electrical and instrumentation toolkit: equipment types, bill of materials, records, and drawing settings.

Windows x64. AutoCAD 2020 or later. MIT license.

Author: Clint Moore, PMP. Consulting: [mooredesign.net](https://mooredesign.net).

## Docs

See [docs/README.md](docs/README.md).

- [Overview](docs/overview.md) — xdata vs catalog vs BOM
- [Install](docs/install.md)
- [Database](docs/database.md)
- [Drawing setup](docs/setup.md)
- [Commands](docs/commands.md)
- C# UI: [MEDTYPE](docs/medtype.md), [MEDSETTINGS](docs/medsettings.md), [MEDCHG](docs/medchg.md), [MEDRECORDS](docs/medrecords.md), [MEDSHOWBOM](docs/medshowbom.md)
- Draw: [conduit](docs/conduit.md), [tray](docs/tray.md), [cable](docs/cable.md), [details](docs/detail.md), [two-line conduit](docs/detail-conduit.md), [tagging](docs/tagging.md), [3D](docs/3d.md), [utilities](docs/utilities.md)

## Database

Default is SQLite at `Data\MED.db`.

SQL Server is optional. Set `Provider=SqlServer` (and a connection string) in `Support\MEDDataBaseSettings.dat`.

Material codes live on entities (xdata). Descriptions live in `MEDType`. `BOM` extracts into `MEDProject`.

## Install

Run `MED2026-Setup.exe` (Inno wrapper) or `installer\Install-MED2026.ps1`.

The PowerShell installer copies Support, sample drawings, and the seed database, writes local `Project.dat` / `MEDDataBaseSettings.dat`, and can create a **MED2026 AutoCAD** desktop shortcut. You choose the install directory; the Setup default is `C:\MED2026`.

After files are in place, APPLOAD `installer\MED2026-ProfileSetup.lsp` and run `MED2026SETUP` once. Then `SETUP` for scale.

Do not install over a live shop PC that already uses SQL Server as the production MED database.

Useful commands: `MEDTYPE`  `MEDSETTINGS`  `MEDCHG`  `MEDSHOWBOM`  `CONDUIT`  `TRAY`  `BOM`

No warranty. See [LICENSE](LICENSE) (MIT).
