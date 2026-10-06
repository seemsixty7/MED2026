# Ductbank routing: MVP test build notes

Branch `feature/ductbank`. This is the first test build of the design in `ductbank-routing.md` (Draft 2).

## Commands (Support\MEDDuctbank.lsp, loaded by MEDCore.lsp)

| Command | What it does |
|---|---|
| `DUCTBANK` | Builds a bank from a routed MED reference conduit: plan conduits, elbows, risers, spacer stations, envelope, and sections |
| `DBLIST` | Lists a bank's positions, conduit lengths, elbows, stations, and envelope |
| `DBDELETE` | Erases a bank and restores the reference conduit (layer + MED_CONDUIT) |
| `DBSEED` | Adds the ductbank fitting/spacer codes to MEDType (one time per database; `Data\seed\ductbank_medtype.csv`) |

The MVP runs from the command line. The WinForms dialog is not built yet; a text grid stands in for the "cheat image".

### DUCTBANK prompt sequence

1. `Select reference MED conduit [Handle]:`
2. `Bank ID <DB1>:`
3. `Number of rows (deep) <2>:`
4. `Conduits in row A (top) <4>:`, then one prompt per row; the last row is labeled (bottom).
5. `Reference conduit position (row letter + column, e.g. B1) <B1>:`
6. `End A (reference start) [Stubup/Open] <Stubup>:`, then the same for End B. The default comes from the reference's vertical end legs.
7. `Stub-up pitch across (center to center) <spacer pitch>:` then `Stub-up pitch along the run (row to row) <same>:`
8. `Section at stub-up end (columns are numbered looking from that end) [A/B] <A>:` (asked only when both ends are stub-ups)
9. The grid and the checks print, then `Positions [Tag/Size/Type/Options/Generate/Cancel] <Generate>:`
   - Tag, Size, and Type each ask `Position, or * for all <*>:`.
   - Options covers Cover, Gap, Interval, Transition, Stubstraight, Separation, and Scale.
   - Generate is refused while errors are listed.
10. `Section drawing location <auto, right of the bank>:` (press Enter for auto)

## What gets drawn

Each position gets the following, all tagged `{BANK}-{POS}` (for example DB1-A1):

- **Straight runs:** LWPOLYLINE at the centerline elevation, MED_CONDUIT, code `_DBKCONCODE` (PVC 3), measured.
- **Plan elbows and stub-up elbows:** arc polylines. The stub-up elbows lie in a vertical plane. Each carries 3 MED_FITTING records: a PVC-coated RGS elbow (160-165, chosen by sweep and radius) and an adapter (170) at each end.
- **Risers:** 3D polyline from the stub elbow up to the stub-up elevation, MED_CONDUIT code `_DBKRISERCODE`.
- **Markers:** a stub marker circle and position text.

The bank also gets:

- **Spacer stations:** a DBSPACER block on MED_DBSPACER. Each station carries MED_FITTING records for the Snap-N-Stac pieces (521-531), the S28612 straps (570), and the S287F/J reducers (568/569).
- **Envelope:** a closed polyline on MED_DBENVELOPE at the top-of-concrete elevation. It carries the bank record (DBANK_DATA) and the handles of every member.
- **Sections:** 1-1 through the stub zone at the chosen end and 2-2 through the trunk, on MED_DBSECTION / MED_DBTEXT.
- **Reference conduit:** moved to MED_DBREF and stripped of MED_CONDUIT so it does not count in the BOM. DBDELETE restores it.

## Deviations from Draft 2 (MVP)

- **Command line instead of the WinForms dialog.**
- **Elbows carry no MED_CONDUIT.** This avoids zero-length conduit rows in the BOM; 3D is out of scope.
- **Risers are plain 3D polylines** with MED_CONDUIT, not VERT_DATA.
- **Fitting descriptions:** the new codes show "INVALID DATABASE ENTRY" in MEDLIST and the BOM until DBSEED runs.
- **Flat trunk only.** There is no 3D generation.

## Settings

All `_DBK*` variables have defaults in code. The same values are documented in `med.spc`, which overrides them.

## Test

```
powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1          # 3" as drawn
powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Size 4  # 4" + DBDELETE
```

The test works on a copy of `Samples\ConduitDuctbankStart.dwg`. It captures the BOM SQL statements instead of executing them.
