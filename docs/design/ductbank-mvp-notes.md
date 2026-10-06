# Ductbank routing: build notes (MVP2, 2026-10-06)

This is on `master` in the live repo (Clint's standing rule: no separate branch or environment). It implements the design in `ductbank-routing.md` (Draft 2). User page: [`docs/ductbank.md`](../ductbank.md).

## Commands (Support\MEDDuctbank.lsp, loaded by MEDCore.lsp)

| Command | What it does |
|---|---|
| `DUCTBANK` | Pick the reference conduit; the WinForms **Ductbank dialog** opens (`MED-DotNet.dll`); OK generates |
| `-DUCTBANK` | Command-line version (the MVP text flow). It is also the fallback when the DLL isn't loaded, the dialog fails, there is no UI (accoreconsole), or `_DBKUSEDIALOG` is 0 |
| `DBLIST` | Lists positions, conduit lengths, elbows, stations, envelope, stub-up material and 3D solids |
| `DBDELETE` | Erases a bank (including its 3D solids) and restores the reference conduit (layer + MED_CONDUIT) |
| `DBSEED` | Adds the ductbank codes to MEDType. Idempotent; it only adds missing codes from `Data\seed\ductbank_medtype.csv` |

## Dialog (MedDuctbankForm.cs + MedDuctbankLisp.cs)

Screenshot: `ductbank-dialog.png` (in this folder and in `docs/images/`). It was rendered from the real form with `MedDuctbankForm.RenderToPng` and a spec produced by `dbk-spec-out` on `Samples\ConduitDuctbankStart.dwg`, 4" positions, B2 selected.

| Area | Contents |
|---|---|
| Left: Bank | ID, Rows, Conduits per row (`4,4`, top row first), reference info |
| Left: Main trunk spacers | Family, Separation (1.5 / 2 / 3), Part (Auto + catalog parts), interval / first station, solved part + pitch + seat |
| Left: Cover from conduit OD | Top, Bottom, End, Left, Right, Min clear gap OD to OD |
| Left: Stub-up zone | End A / End B (Stubup / Open) + top EL, stub pitch across / along, transition / stub straight, section end, **Risers + stub elbows** (PVC-coated RGS / Plain RGS), **Tape wrap** (plain RGS only) |
| Left: Output | 3D envelope + spacer solids (layer shown), section scale, Pick section location |
| Middle: Conduit positions | One card per position (top row A first, columns left to right looking from the stub-up end). REF badge; the selected card is orange/yellow |
| Middle: Selected position | Tag, Size, Type, Set as REF, Size to all, Type to all, Auto tags, tag pattern; calc reminder |
| Middle: Envelope (last check) | SUM lines from the last LISP solve + live preview W x H |
| Right: Cheat image | Trunk / Stub-up section toggle: hatched envelope, spacer pieces (green), every conduit at its OD, current conduit gold, REF label, info line |
| Right: Checks | X error (blocks OK), ! flag, i note (preview differs from the last check) |
| Bottom | Status line; Help, Check, **OK**, Cancel |

### LISP / C# interface

The interface is text and line-based so the two sides are easy to test separately:

1. `dbk-spec-out` emits a `KEY=VALUE` spec. It holds:
   - the inputs
   - `POS=id|tag|size|code|C/D` lines (C = custom tag, D = default)
   - catalog `CAT=` rows, `OD=` rows and `CODE=` rows (live SQL MEDType CONDUIT rows, with a fallback list)
   - the last solve: `SOLVEDPART`, pitch, `ENVT`, `PZ=` positions, `PIECE=` spacer pieces, `SUM=`, `ERR=`, `FLAG=`
2. `(MED-DuctbankDialog spec)` shows the form modally and returns the edited spec with `ACTION=OK|CHECK|CANCEL`.
3. `dbk-spec-in` applies the returned spec:
   - It reshapes the grid when rows or counts change.
   - **CHECK** re-solves in LISP and reopens the dialog.
   - **OK** re-solves and generates. It reopens instead if the solve has errors.
4. `(MED-DuctbankDialogAvailable)` is T only in full AutoCAD (acmgd loaded, interactive). `DUCTBANK` uses it to choose the dialog or the command line.

The form's live preview copies the `dbk-solve` rules (seat-driven frame, cover, stub zone), but LISP stays the authority. All generated geometry comes from LISP.

## What gets drawn

Each position gets the following, all tagged `{BANK}-{POS}` unless a tag is entered:

- **Straight runs:** LWPOLYLINE at the centerline elevation, MED_CONDUIT, code `_DBKCONCODE` (PVC 3).
- **Plan elbows** (trunk bends): broken-segment arc polylines. DBANK_DATA `ROLE=ELBOW` carries `OD=` (PVC-coated RGS OD) and `MAT=2`. Fitting records: PVC-coated RGS elbow 160-165 plus adapter 170 at each end.
- **Stub-up elbows:** in a vertical plane. DBANK_DATA carries `OD=`, `MAT=` and `WRAP=`.
  - PVC-coated RGS (default): elbow 160-165 + adapter 170 + coupling 173.
  - Plain RGS: elbow 89/90/91/166 (90 deg) or 167-169 (45 deg) + adapter 170 + coupling 8, plus 174 tape wrap when wrapped.
- **Risers:** 3D polyline from the stub elbow to the stub-up elevation. MED_CONDUIT code = stub material (2, or 1 for plain RGS). DBANK_DATA `MAT=` / `WRAP=`.
- **Markers:** a stub circle at the material OD, position text, and a `WRAP` note when the stub-up is wrapped.

The bank also gets:

- **Spacer stations:** DBSPACER blocks with MED_FITTING records (521-531 pieces, 570 straps, 568/569 reducers).
- **Envelope:** closed polyline on MED_DBENVELOPE with the bank record. It now also carries `STUBMAT`, `WRAP`, `PARTOVR` and `MODEL3D`.
- **Sections:** 1-1 (stub zone) and 2-2 (trunk).
- **3D (new):** when `_DBKMODEL3D` is 1, on `3DMEDModel-Ductbank` (non-plotting, color 8):
  - the envelope solid: the outline at the bottom elevation extruded by H; `ROLE=ENV3D`
  - one solid per spacer station: the section pieces in the plane normal to the run, extruded `_DBKSPTHICK`, unioned, seats subtracted; `ROLE=SPACER3D`

  Both carry DBANK_DATA, so DBDELETE removes them. The 3D disclaimer is printed.

## MEDMAKE3D (MED3DPath r13)

- **Stage 3 (conduit)** already built the plan runs and the risers, since both are ordinary MED conduits.
- **New stage 6 `DUCTBANK`:** `med3d-dbank-build` sweeps every `ROLE=ELBOW` polyline. The OD comes from `OD=`, because elbows carry no MED_CONDUIT. Each solid is stamped `ObjectType=FITTING` with the elbow's MEDType description.
- **New stage 7 `MODEL`:** `med3d-model-collect` copies every entity on `_MED3DMODELPREFIX*` layers into the export. It thaws, turns on and unlocks those layers for the copy, then restores them; the originals stay. `MAKE3DCONDUIT` does the same.
- `medcb-collect` skips DBANK_DATA inserts (spacer blocks are not conduit bodies).
- The disclaimer is printed by MEDMAKE3D, MAKE3DCONDUIT, M3D, MAKE3DTRAY, MEDCBINS and MED3DLIB inserts.

## MEDType codes added this round (seed CSV + live MED table)

| Code | Description |
|---|---|
| 166 | RGS 48" Radius Conduit Elbow |
| 167 / 168 / 169 | RGS 45 Deg Elbow 24" / 36" / 48" Radius |
| 173 | PVC Coated RGS Coupling |
| 174 | Corrosion Protection Tape Wrap (Plain RGS Stub-Up) |

The existing codes used are 89/90/91 (RGS 90 deg elbows 18/24/36" radius) and 8 (RGS coupling).

Live DB, 2026-10-06:

- Backup `dbo.MEDType_bak_20261006_1353` (1145 rows) and `C:\Users\moore\Downloads\MEDType_bak_20261006_1353.csv`.
- 6 rows inserted. A second pass inserted 0. MEDType now has 1151 rows.

## Settings

All `_DBK*` variables have code defaults. `med.spc` documents them and overrides.

| Variable | Default | Meaning |
|---|---|---|
| `_DBKUSEDIALOG` | 1 | 0 makes DUCTBANK always use the command line |
| `_DBKRISERCODE` | 2 | Stub-up material (2 = PVC-coated RGS, 1 = plain RGS) |
| `_DBKSTUBWRAP` | 1 | Tape wrap for plain RGS |
| `_DBKMODEL3D` | 1 | 3D envelope + spacer solids |
| `_DBKSPTHICK` | 2.0 | Spacer solid thickness (in) |
| `_DBKMODELSUFFIX` | `Ductbank` | Model layer = prefix + suffix |
| `_MED3DMODELPREFIX` | `3DMEDModel-` | 3D model layer prefix (MED3DPath) |

## Remaining deviations from Draft 2

- Risers are 3D polylines with MED_CONDUIT, not VERT_DATA.
- The trunk is flat (constant elevation). There is no DBEDIT, DBSECT, DBCHECK or DBSPEC yet. There are no spec profiles or bank types.
- The cheat image's spacer pieces are a preview of the LISP solve, not drawn seats.

## Tests

```
powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1          # 3" as drawn
powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Size 4  # 4" + DBDELETE
powershell -ExecutionPolicy Bypass -File tests\autocad\MEDDuctbankTest.ps1 -Rgs     # plain RGS stub-ups, wrapped
```

All three use accoreconsole on a copy of `Samples\ConduitDuctbankStart.dwg`. They run `-DUCTBANK`, capture the BOM SQL instead of writing it, and write `<name>-spec.txt` (the dialog spec). 20/20 checks pass in each run. The checks cover:

- elbow record sets
- riser code
- WRAP notes
- ENV3D/SPACER3D solids on the model layer
- spec positions

The round trip (form `BuildSpec` -> `dbk-spec-in` -> generate) was checked with an edited custom tag, one 4" position and plain RGS. MEDMAKE3D (scripted full AutoCAD, Dwg) on the 3" result gave:

- conduit: 32 solids (16 runs + 16 risers)
- ductbank elbows: 24/24
- 3D model layer: 5 entities
- output DWG: 61 solids (RUN 16, RISER 16, ELBOW 24 as FITTING, SPACER 4, ENVELOPE 1)
