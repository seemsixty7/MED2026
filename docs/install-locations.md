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

**Setup (full install, or re-running it)** is a new install. If any of these already exist, Setup **renames** them first to `<name>.bak-YYYYMMDD-HHMMSS` and then installs fresh copies: `Data\MED.db`, `Support\med.spc`, `ACAD.PGP`, `QKEY.lsp`, `MOTOR.DAT`, `medblck.dat` and `setup.add`. Nothing is overwritten silently. The renamed files are listed in a message at the end of Setup and in `C:\MED2026\install-backups.log` (and the Setup log). Copy a `.bak-` file back over the new one to keep your old catalog or settings. Setup keeps `Project.dat` and `MEDDataBaseSettings.dat` (it only creates them if missing) and keeps an existing `Dwg3D\Dwg3DCatalog.db`. Program files under `Support`, `Dwg`, `Dwg3D` and `Data\seed` are replaced.

**Patch** updates whichever installs it finds: the classic Setup install (`C:\MED2026` or the folder you choose) and/or the App Store bundle (`C:\ProgramData\Autodesk\ApplicationPlugins\MED2026.bundle`). It asks for administrator rights because the bundle is in ProgramData. If it finds neither, it says so and exits.

- Program files (LISP, menus, DLLs, seed CSVs; for the bundle, `Contents\Support`, `Win64`, `Dwg`, `Dwg3D`, `Data\seed`) are replaced.
- Your editable files (`med.spc`, `ACAD.PGP`, `QKEY.lsp`, `MOTOR.DAT`, `medblck.dat`, `setup.add`) are installed **only if missing**, in `C:\MED2026\Support` and, for the bundle, in `%APPDATA%\MooreDesign\MED2026\Support`. If your copy differs from the new one, yours is kept and the new one is saved beside it as `<name>.new`. The Patch's finish page and `patch-updates.log` (in `C:\MED2026` and/or `%APPDATA%\MooreDesign\MED2026`) list the files that were not applied, so you can merge them by hand.
- It never ships or touches any `MED.db` (classic, per-user, or the bundle's starter copy), `Project.dat`, `MEDDataBaseSettings.dat` or the AutoCAD profile. Database changes come from the update path below.

## Database updates (Setup/Patch installs)

Database changes never come from copying a new `MED.db` over yours. They come from MED-DotNet's update path when AutoCAD loads MED:

1. **Backup first.** The first time a new MED version opens a SQLite `MED.db`, it copies it to `MED.db.bak-YYYYMMDD-HHMMSS` next to the original before changing anything (a `MED.db.medver` file records the version). SQL Server databases are not file-copied; back them up in SQL Server first.
2. **Schema check.** Missing optional `MEDType` columns are added. A missing core table (`MEDType`, `MEDUsers`, `MEDProject`) is reported, not created.
3. **Idempotent seeds.** Missing duct bank `MEDType` rows are added and blank descriptions filled (the `DBSEED` data); the OD, conduit body and `MEDUsers.LastProject` updates run as before. Rows you added or edited are never changed.

`MEDDBUPDATE` runs the same steps on demand, always makes a fresh backup, and reports what it did. `DBSEED` still works as before.

**App Store update** replaces the whole `MED2026.bundle` folder; uninstalling removes it. `%APPDATA%\MooreDesign\MED2026` is never replaced or deleted, so the database, `med.spc`, `Project.dat` and the flags carry over. Missing per-user files are recreated and never overwritten. The per-user `MED.db` gets the same database update path as Setup/Patch installs (backup first, schema check, idempotent seeds) on every start; `MEDDBUPDATE` runs it on demand.

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

Setup, Patch and the App Store bundle all register through the same endpoint (`https://mooredesign.net/.netlify/functions/med-register`), sending name, email, version and an install type (`setup` or `appstore`); the bundle also sends company and the update opt-in. Setup and Patch ask on an optional wizard page.
