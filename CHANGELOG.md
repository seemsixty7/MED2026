# Changelog

## Unreleased

### Added
- **Conduit / cable OD storage (Option B).** New `MEDConduitOD` table (conduit type code + trade size → OD in inches, with source) for all 7 seed conduit types, from ANSI C80.1 / C80.3 / C80.6, NEMA TC-2 and manufacturer data sheets (Wheatland, Allied, Cantex, Carlon, Robroy Plasti-Bond, Anaconda Sealtite).
- `MEDType.USER3` on CABLE rows = cable OD in inches (Southwire / Encore Wire data sheets). 263 of 359 seed cable rows filled; the rest stay blank (not sourced). Sources per row: `Data\seed\cable_od_sources.csv`.
- `Data\seed\*.csv` + `MedODSeed.cs`: at NETLOAD MED-DotNet creates `MEDConduitOD` (SQLite or SQL Server) and fills missing rows / blank CABLE USER3 only. Existing installs get the data from the patch without replacing `MED.db`.
- `med_conduit_od` (`MEDFunctions.lsp`): OD lookup by conduit type + trade size with fallback to the old `getsize` steel-pipe OD.
- **`Support\MED3DPath.lsp`: one 3D solid per conduit or cable run** (loaded by MEDCore). `M3D` / `MAKE3DCONDUIT` (conduit), new `C3D` / `MAKE3DCABLE` (cable), `MED3DPLAN` (corner table). LWPOLYLINE, 2D and 3D POLYLINE; bends at 5 × OD (`med3d-bend-radius`, per-run override hook); tangents allocated so neighbouring bends never overlap; corners that cannot fit are left sharp with a sphere and flagged (message + marker on `MED_3DFLAG`). SWEEP along a computed filleted centerline for planar runs, ActiveX pieces + union otherwise. Corner list exposed for future fittings. See `docs/3d.md`.
- `*MED3D-DEBUG*`: set to T for a per-run / per-piece trace (planned start/end, solid bounding box, SWEEP vs PIECES and why). See `docs/3d.md`.
- `tests/med3dpath` (geometry desk test through a mini AutoLISP interpreter; `test_med3d_acad.py` with a mock AutoCAD checks LW / 2D / 3D polylines with OCS normals end to end) and `tests/autocad/MED3DPathTest.lsp` (sample runs in AutoCAD).

### Changed
- `MAKE3DCONDUIT` / `M3D` size conduit solids by conduit type (e.g. EMT is now 0.706" at 1/2", not 0.840"). Same result as before when the table/row is missing.
- Vertical conduit solids use the OD instead of the nominal trade size.
- MEDTYPE: USER3 header shows `OD (in)` for Cable (`User3 / OD (in)` on All).
- Patch installer also ships `Support\MED3DCON.lsp`, `Support\MED3DPath.lsp` and `Data\seed\*.csv` (still never `MED.db` or `med.spc`).
- M3D / C3D straights (feature/3dpath test): made with `AddExtrudedSolidAlongPath` along a temporary LINE and checked by bounding box, with `_.EXTRUDE _Direction` as fallback. The earlier `AddExtrudedSolid` + centroid flip could leave straights misplaced or short. SWEEP planar test uses a relative tolerance (large coordinates) and SWEEP failures are no longer silent under debug.
- M3D / C3D bends (3D runs came out as balls at every corner): bends are extruded along a temporary ARC in the bend plane, with AddRevolvedSolid ±axis as fallbacks, and kept only if the box matches the bend (start, middle, end, no larger than the ideal). Vertices closer than 0.1 × OD to the previous one are dropped. Debug prints each corner's status and reason.
- Cable bend radius default is 7 × OD (`*MED3D-CABLE-BEND-FACTOR*`); conduit stays 5 × OD.
- MED3DPath prints a load banner with its version; new `MED3DVER`. M3D / C3D / MAKE3DCONDUIT / MAKE3DCABLE are re-claimed if an old 2012 MED3DCON.lsp is loaded later (it used to win with its `Output to 3DS Layer` prompt).
- `ProcessSQLStatementNET` (MED-DotNet): when LISP `*MED-SQL-QUIET*` is non-nil, the `n row(s)` / `No Rows` messages are skipped (errors still print). MED3DPath sets it for its OD lookups and reads all ODs with one SELECT per command.
- M3D / C3D select any LWPOLYLINE / POLYLINE and say why one is skipped (no MED xdata) instead of silently filtering it out; a run carrying the other kind's xdata is converted as that kind.
- The 2012 commands in `MED3DCON.lsp` are renamed `M3DOLD` / `MAKE3DCONDUITOLD`; `M3D` and `MAKE3DCONDUIT` now come from `MED3DPath.lsp`.

### Fixed
- Old conduit 3D (`MED3DCON.lsp`): `EXTRUDE` streams still sent the pre-2007 taper-angle `""`, which re-ran EXTRUDE and fed later commands into the wrong prompts; straights now `entmake` the circle square to the segment and use `_Direction`. 2D heavy / 3D POLYLINE runs were measured but never drawn; running OSNAPs were live during the export (now off, restored on exit/error); a missing OD crashed with `(* nil 0.5)`.
- MEDTYPE CSV import truncated ITEM_GRP to 12 characters (`Residential Cable` → `Residential `); limit is now 40.
- `docs/database.md` listed USER3 as unused (EQUIP uses it for the project remap).
