# Install methods and file locations

MED2026 ships two ways. Pick one per PC; do not install both on the same machine.

| | Setup / Patch install | App Store bundle |
|---|---|---|
| Installer | `MED2026-Setup-<ver>.exe` (full), `MED2026-Patch-<ver>.exe` (update) | Autodesk App Store installer, built from `MED2026.bundle-<ver>-appstore.zip` |
| Program files | `C:\MED2026` | `C:\ProgramData\Autodesk\ApplicationPlugins\MED2026.bundle` |
| .NET DLLs (`MED-DotNet.dll`, SQLite) | `C:\MED2026\Support` | `MED2026.bundle\Contents\Win64` |
| LISP, menus, DCL, slides | `C:\MED2026\Support` | `MED2026.bundle\Contents\Support` (read-only) |
| Block library | `C:\MED2026\Dwg` | `MED2026.bundle\Contents\Dwg` |
| 3D block library | `C:\MED2026\Dwg3D` | `MED2026.bundle\Contents\Dwg3D` |
| Icons, licence, help page | `C:\MED2026\Support` (icons); licence shown by Setup | `MED2026.bundle\Contents\Resources` |
| Seed CSVs | `C:\MED2026\Data\seed` | `MED2026.bundle\Contents\Data\seed` |
| Starter catalog | `C:\MED2026\Data\MED.db` (the live DB) | `MED2026.bundle\Contents\Data\MED.db` (copied once, never used directly) |
| Live database `MED.db` | `C:\MED2026\Data\MED.db` | `%APPDATA%\MooreDesign\MED2026\Data\MED.db` |
| `med.spc`, `QKEY.lsp`, `MOTOR.DAT`, `medblck.dat`, `setup.add` | `C:\MED2026\Support` | `%APPDATA%\MooreDesign\MED2026\Support` |
| `Project.dat`, `MEDDataBaseSettings.dat` | `C:\MED2026\Support` (created by Setup if missing) | `%APPDATA%\MooreDesign\MED2026\Support` (created at first run) |
| Flags | none | `%APPDATA%\MooreDesign\MED2026\FirstRun.done`, `Registered.flag` or `RegisterSkipped.flag` |
| Startup log | none | `%APPDATA%\MooreDesign\MED2026\MED-startup.log` |
| AutoCAD profile | Setup creates the **MED2026** profile and a **MED2026 AutoCAD** shortcut | Current profile; the Autoloader loads the bundle in any profile |
| Loader | `ACAD.LSP` + `CSharpAdd.lsp` | `MED2026-Bundle.lsp` (per drawing), `MED-DotNet.dll` loaded by the Autoloader |
| Supported AutoCAD | 2020-2024 (.NET Framework 4.7.2) | 2020-2024 (R23.1-R24.3, .NET Framework 4.7.2); tested on AutoCAD 2024 |

## What updates replace and what they keep

**Setup (full install, or re-running it)** replaces everything under `C:\MED2026\Support`, `Dwg`, `Dwg3D` and `Data\seed`. It also replaces `Data\MED.db` and `Support\med.spc`, so back them up first. It keeps `Project.dat` and `MEDDataBaseSettings.dat`, and keeps an existing `Dwg3D\Dwg3DCatalog.db`.

**Patch** replaces the program LISP, menus, DLLs and seed CSVs. It never touches `MED.db`, `med.spc`, `ACAD.PGP`, `Project.dat`, `MEDDataBaseSettings.dat` or the AutoCAD profile. New catalog rows reach an existing `MED.db` through `DBSEED` and the OD seed that MED-DotNet runs at load.

**App Store update** replaces the whole `MED2026.bundle` folder; uninstalling removes it. `%APPDATA%\MooreDesign\MED2026` is never replaced or deleted, so the database, `med.spc`, `Project.dat` and the flags carry over. Missing per-user files are recreated and never overwritten. On every start MED-DotNet adds any missing ductbank `MEDType` rows (the `DBSEED` data) to the per-user `MED.db` and fills a blank description, without prompting.

## First run and MEDFIRSTRUN (App Store bundle)

The first time AutoCAD starts with the bundle (no `FirstRun.done`), MED runs `MEDFIRSTRUN`:

1. Creates `%APPDATA%\MooreDesign\MED2026` and copies the per-user files, never overwriting.
2. Seeds the ductbank `MEDType` rows into the per-user `MED.db`.
3. Adds the bundle folders and the per-user `Support` folder to **Trusted Locations** (`TRUSTEDPATHS`), so AutoCAD stops asking to **Always Load**.
4. Puts the MED folders at the top of the support file search path (see below).
5. Writes `FirstRun.done` and asks you to **restart AutoCAD**. Until you restart, MED commands only show that notice.

Type `MEDFIRSTRUN` any time to repeat it. It never overwrites your files.

## Support path order

`MEDFIRSTRUN` puts these at the very top of **Options > Files > Support File Search Path**, in this order:

1. `%APPDATA%\MooreDesign\MED2026\Support` (your copies of `med.spc`, `QKEY.lsp`, `Project.dat` win)
2. `...\MED2026.bundle\Contents\Support`
3. `...\MED2026.bundle\Contents\Win64`

If a folder is already on the path it is moved to the top. Your other entries stay in the same order. Setup installs use the **MED2026** profile, which Setup configures with `C:\MED2026\Support`.

## MEDREGISTER (App Store bundle)

After first run MED shows an optional registration dialog once: Name, Email, Company, and an **Email me when MED updates are released** box (off by default). **Register** sends the details to Moore Design (mooredesign.net); **Skip** or closing the dialog won't ask again. Without a network connection it fails quietly and notes it in `MED-startup.log`. MED works the same whether or not you register. Type `MEDREGISTER` to open it later. Privacy policy: `MEDPRIVACY` or https://mooredesign.net/privacy/.
