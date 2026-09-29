# Changelog

## Unreleased

### Added
- **Conduit / cable OD storage (Option B).** New `MEDConduitOD` table (conduit type code + trade size → OD in inches, with source) for all 7 seed conduit types, from ANSI C80.1 / C80.3 / C80.6, NEMA TC-2 and manufacturer data sheets (Wheatland, Allied, Cantex, Carlon, Robroy Plasti-Bond, Anaconda Sealtite).
- `MEDType.USER3` on CABLE rows = cable OD in inches (Southwire / Encore Wire data sheets). 263 of 359 seed cable rows filled; the rest stay blank (not sourced). Sources per row: `Data\seed\cable_od_sources.csv`.
- `Data\seed\*.csv` + `MedODSeed.cs`: at NETLOAD MED-DotNet creates `MEDConduitOD` (SQLite or SQL Server) and fills missing rows / blank CABLE USER3 only. Existing installs get the data from the patch without replacing `MED.db`.
- `med_conduit_od` (`MEDFunctions.lsp`): OD lookup by conduit type + trade size with fallback to the old `getsize` steel-pipe OD.

### Changed
- `MAKE3DCONDUIT` / `M3D` size conduit solids by conduit type (e.g. EMT is now 0.706" at 1/2", not 0.840"). Same result as before when the table/row is missing.
- Vertical conduit solids use the OD instead of the nominal trade size.
- MEDTYPE: USER3 header shows `OD (in)` for Cable (`User3 / OD (in)` on All).
- Patch installer also ships `Support\MED3DCON.lsp` and `Data\seed\*.csv` (still never `MED.db` or `med.spc`).

### Fixed
- MEDTYPE CSV import truncated ITEM_GRP to 12 characters (`Residential Cable` → `Residential `); limit is now 40.
- `docs/database.md` listed USER3 as unused (EQUIP uses it for the project remap).
