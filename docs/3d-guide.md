# 3D guide (MEDMAKE3D, conduit bodies, data)

A short map of the 3D work on `feature/3dpath` (MED3DPath r12 / MED3DFittings r12, `*MED3D-VERSION*` / `*MEDCB-VERSION*` = `2026-09-30 r12`). It points into the detailed pages instead of repeating them:

- [3d.md](3d.md) - behaviour of every 3D command, bends, flags, debug, tests.
- [3d-fitting-matrix.md](3d-fitting-matrix.md) - every 2D fitting symbol × code × leg case and what MEDMAKE3D builds; Clint's decisions.
- [database.md](database.md#conduit-bodies) - the `MEDConduitBody` table and the OD tables.
- Commands: [command-reference.md](command-reference.md#by-topic) (topic "3D"); functions: [lisp/MED3DPath.md](lisp/MED3DPath.md), [lisp/MED3DFittings.md](lisp/MED3DFittings.md), [lisp/MED3DTrayFunctions.md](lisp/MED3DTrayFunctions.md), [lisp/MEDCore.md](lisp/MEDCore.md).

## Commands at a glance

| Command | File | Use |
| --- | --- | --- |
| [`MEDMAKE3D`](command-reference.md#medmake3d) | MED3DPath.lsp | Everything in one go: tray, tray fittings, conduit, conduit bodies, cable. One prompt `[Dwg/Layer] <Dwg>`, one summary |
| [`MAKE3DTRAY`](command-reference.md#make3dtray) | MED3DTrayFunctions.lsp | Tray + tray fittings only (`3DS/Dwg/Layer`) |
| [`M3D`](command-reference.md#m3d) / [`C3D`](command-reference.md#c3d) | MED3DPath.lsp | Selected conduit / cable runs |
| [`MAKE3DCONDUIT`](command-reference.md#make3dconduit) / [`MAKE3DCABLE`](command-reference.md#make3dcable) | MED3DPath.lsp | Every conduit / cable run (`Dwg/Layer`) |
| [`MED3DPLAN`](command-reference.md#med3dplan) | MED3DPath.lsp | Corner table of one run, draws nothing |
| [`MED3DVER`](command-reference.md#med3dver) / [`MEDCBVER`](command-reference.md#medcbver) | MED3DPath / MED3DFittings | Version, who owns the commands, data source |
| [`MEDCBINS`](command-reference.md#medcbins) / [`MEDCBTEST`](command-reference.md#medcbtest) / [`MEDCBALL`](command-reference.md#medcball) | MED3DFittings.lsp | Insert one body / a row of one form / a gallery of all bodies at one size |
| [`MEDCBDATA`](command-reference.md#medcbdata) | MED3DFittings.lsp | Reload the body data and list what sizes exist |
| [`MEDCBGRID`](command-reference.md#medcbgrid) | tests\autocad\MEDCBGrid.lsp (APPLOAD) | Draw the whole fitting matrix in a test drawing |
| [`MED3DPATHTEST`](command-reference.md#med3dpathtest) | tests\autocad\MED3DPathTest.lsp (APPLOAD) | Sample conduit/cable runs converted |
| [`ESOLID`](command-reference.md#esolid) | medtray.lsp | Erases **all** 3DSOLIDs |

MEDCore loads `MED3DPath.lsp` and `MED3DFittings.lsp` last, each inside `vl-catch-all-apply`, so a load error prints `... failed to load; APPLOAD it to see the error` instead of stopping MED. `MED3DCON.lsp` (2012 code, `M3DOLD` / `MAKE3DCONDUITOLD`) is not loaded.

## MEDMAKE3D workflow

1. Draw the plan as usual: tray (`TRAY` ...), conduit (`CONDUIT`), conduit fittings from the MED fitting menus (they carry `MED_FITTING` xdata; up/down conduit is stored on the insert as `MED_CONDUIT` distance + `VERT_DATA` direction), cable (`CABLE`, `RUN3DCABLE`).
2. Check the scale (`SETUP`: `_SC` / `DIMSCALE` / `USERR1`). The conduit-to-body search uses the `medblck.dat` break distance × the insert scale.
3. Save the drawing if you want the `.medprops.json` sidecar with the Layer option.
4. Run `MEDMAKE3D` and answer `Dwg` (one combined DWG + `<name>.medprops.json`, solids taken out of this drawing) or `Layer` (solids stay on `MED_3DTRAY-*`, `MED_3DCONDUIT`, `MED_3DCABLE`; viewpoint `1,1,1`, `PLAN` to go back).
5. Stages, in order (each one's error goes to the summary and the next still runs): tray + tray fittings (`med3d-tray-build`), conduit bodies resolved (`medcb-collect`), conduit runs cut back to the hub faces (`med3d-path-build-all "CONDUIT"`), body blocks inserted (`medcb-place-all`), cable (`med3d-path-build-all "CABLE"`).
6. Read the summary. **Flagged** = markers on `MED_3DFLAG` (sharp corners that could not be bent, legs no hub lines up with, placeholders, mirrored fittings). **Skipped** lists each run / fitting with no solid and why. Fix the drawing and run again (`MAKE3DCONDUIT` / `MAKE3DCABLE` clear `MED_3DFLAG` first; with Layer output erase the old solids, or they stack).
7. Debug: `MEDDEBUG` On, or `(setq *MED3D-DEBUG* T)` for the per-run / per-body trace. See [3d.md](3d.md#medmake3d-everything-in-one-go) and [debug.md](debug.md).

Tuning globals (defaults in brackets): `*MED3D-BEND-FACTOR*` [5 × OD conduit], `*MED3D-CABLE-BEND-FACTOR*` [7 × OD], `*MED3D-BEND-OVERRIDES*` (per handle), `*MED3D-DUP-FACTOR*` [0.1], `*MED3D-FIT-TOL*` [0.25"], `*MED3D-FIT-ANG*` [30°], `*MEDCB-SNAP*` [T], `*MED3D-METHOD*` [`"SWEEP"`].

## Fitting body keys

MEDMAKE3D decides which 3D body a `MED_FITTING` insert gets from its fitting code (details: [3d.md, "Which body"](3d.md#conduit-bodies-in-medmake3d)):

1. `MEDType.ITEMKEY2` on the FITTING row: `material|form|shape`, e.g. `RGD|F7|LB`, `RGD|M9|TB`, `RGD|XP|GUAT`, `RGD|CH|EYD`.
2. Blank key: parsed from the description (only descriptions with `condulet`; `Form 7` / `Form 8` / `Mark 9`, `Mogul` → `MOG`, `Explosion Proof` → `XP`; shape = the quoted word).
3. Else the row with the same code **and the same description** in `Data\seed\fitting_body_keys.csv`.
4. Nothing → "not modelled" (couplings, connectors, straps ...): no solid, no message.

Forms: `F7` `F8` `M9` (Condulet Form 7 / Form 8 / Mark 9), `CH` (Crouse-Hinds without a form number: LBD, LBY, UNY, EYS, EYD, HUB, PLGR, PLGS, RE), `MOG` Mogul (BLB, BC, BT, BUB), `XP` GUA (GUAL, GUAT, GUAX), `MYR` Myers hub, `WH` Wheatland coupling (data only). Stock codes keyed: 11-16, 18, 30-41, 50-53, 61, 64, 72, 80-82, 94, 100, 101, 103, 120, 121, 141-143. You can type your own key in `MEDTYPE`; MED-DotNet never overwrites a key.

## Data: MEDConduitBody and the seed CSVs

| File (Data\seed\) | What | Used by |
| --- | --- | --- |
| `conduit_body_dims.csv` | Body dimensions per `Form` + `Shape` + `TradeSize` (published letters A-E, optional `HubOD_in` / `HubLen_in`, source + page, `Notes` says approx) | MED-DotNet `MedODSeed` seeds `MEDConduitBody`; MED3DFittings reads the table, else this CSV directly |
| `conduit_body_sources.csv` | The catalogs / pages behind every row (`SourceId`) | documentation / audit |
| `fitting_body_keys.csv` | `ITEMCODE, ITEMDESC, BodyKey` | MedODSeed fills blank `MEDType.ITEMKEY2`; MED3DFittings fallback 3 above |
| `conduit_od.csv`, `cable_od_sources.csv` | Conduit OD per code + trade size (`MEDConduitOD`) and cable OD (`MEDType.USER3`) | M3D / C3D / MEDMAKE3D sizes; hub OD estimate |

How to update:

- **A value in one drawing's database**: edit `MEDConduitBody` (or `MEDType.ITEMKEY2` in `MEDTYPE`) directly, then `MEDCBDATA` (or `(setq *MEDCB-DATA* nil)`) to reload. Seeding only fills blanks, so your edit stays.
- **The shipped data**: edit the transcribed tables in `tools\build_conduit_body_seed.py` / `tools\build_fitting_body_keys.py` (not the CSVs by hand), then from the repo root run `python tools/build_conduit_body_seed.py` and `python tools/build_fitting_body_keys.py` (add `--no-db` to write the CSVs only). They rewrite the CSVs and update the seed `Data\MED.db` (blanks only). The patch installer ships the CSVs, never `MED.db`; existing databases pick up new rows / blank columns when MED-DotNet loads.
- **Existing blocks do not change** when data changes: a body block is built once per drawing and never redefined. Delete / purge `MED_CB_RGD_...` to get it rebuilt from the new numbers.
- Run the desk tests after a data or geometry change: `python tests/med3dpath/test_med3dfittings.py`, `python tests/med3dpath/test_med3dphase2.py`, `python tests/med3dpath/test_fitting_matrix.py` (see [3d-fitting-matrix.md](3d-fitting-matrix.md#keeping-this-page-current)).

## Block names, version tags and `_PRE_` rebuilds

- Name: `MED_CB_RGD_<form>_<shape>_<size>`, size = trade size to two decimals with `-` for the point (`MED_CB_RGD_F7_LB_1-00`, `MED_CB_RGD_F8_T_1-25`); reducer `MED_CB_RGD_CH_RE_1-00X0-75` (large X small). No data → placeholder box block `<name>_PH` on `MED_3DFLAG`.
- Contents (Clint's block rule): every entity on layer 0, colour / linetype / lineweight ByLayer; the insert carries the layer (`MED_3DCONDUIT`, placeholders `MED_3DFLAG`). Units are inches.
- Each definition stores a geometry tag in its block **Comments**. Current tags (`*MEDCB-GEOM-TAG*`, `*MEDCB-SHAPE-TAGS*`):

| Shapes | Tag | An older block is renamed to |
| --- | --- | --- |
| EYD | `MEDCB geom r12` | `<name>_PRE_R12` |
| EYS | `MEDCB geom r10` | `<name>_PRE_R10` |
| GUAL, GUAT, GUAX | `MEDCB geom r9` | `<name>_PRE_R9` |
| all others | `MEDCB geom r6` | `<name>_PRE_R6` |

- When MEDMAKE3D / MEDCBINS needs a block whose tag is older, the old definition is renamed (`_n` added if the name is taken; existing inserts keep pointing at it) and a new one is built. Run `PURGE` (Blocks) afterwards to remove `_PRE_` definitions nothing references. See [3d.md, "Blocks"](3d.md#conduit-bodies-rigid-medcbins-medcbtest-medcball) and "Revisions r9 - r12".
- Block axes: insertion point = where the conduit centerlines cross, cover +Z, RUN hub +X. Hub table per shape: [3d.md, "Block axes"](3d.md#conduit-bodies-rigid-medcbins-medcbtest-medcball).

## Mirror flag

A `MED_FITTING` conduit body whose symbol is mirrored (X scale × Y scale × extrusion Z < 0, e.g. made with `MIRROR`) is **not** built: no body, the conduit is left as drawn, one marker `MIRRORED FITTING - re-insert, do not mirror` on `MED_3DFLAG`, a Skipped line with the handle, and the summary line `Mirrored fittings: N (bad practice - re-insert without mirroring)`. Re-insert the other-handed symbol instead (`1lbr` rather than a mirrored `1lbl`). MED's menus never insert with a negative scale. Test: `medcb-mirrored-p`; grid rows M39 / M40. Details: [3d-fitting-matrix.md, "Decisions"](3d-fitting-matrix.md#decisions-clint).

## EYS / EYD / GUA conventions

- **EYS** (sealing fitting, code 61, `CH|EYS`): body is a cylinder of dia `b` centred on the conduit axis (r10); large short pour hub on +Z at −X, smaller boss leaning 40° toward +X; nothing reaches past the catalog turning radius `D` (r9 limit, rim corners included). RUN +X, RUN2 −X.
- **EYD** (seal with drain, code 64, `CH|EYD`): exactly the EYS mirrored along X (r12): pour hub with the drain plug toward +X (RUN), boss toward −X, 1/2" nipple + Crouse-Hinds ECD11 at 45° toward +X. Block +X follows the 2D symbol's drain end (`1sealdr` draws the drain at its local +X), so with the symbol drain-end-down the ECD points down. MEDMAKE3D keeps the drawn rotation for the EYD; flip the 2D symbol to move the drain.
- **GUAL / GUAT / GUAX** (codes 141-143, form `XP`): round box, full-diameter cover disc + wrench lugs on +Z, bored hubs; dimensions tuned to Clint's reference DWGs (r9, source `CLINT-GUA-DWG`); `1guat` gets −90° like `1tee`; side-view symbols (`1gualsid`, `1guatsid`) are tilted −90° about X (branch down, cover +Y).
- Full history and numbers: [3d.md](3d.md) ("EYS / EYD history", "Turning-radius limit", "Centred body", "EYD (r11)", "EYD mirrored (r12)", "GUAL / GUAT / GUAX (r9)") and [3d-fitting-matrix.md, "Phase 2"](3d-fitting-matrix.md#phase-2-bodies-done-in-r6).

## MEDCore and the 3D modules

`MEDCore.lsp` registers the xdata apps the 3D code reads (`MED_CONDUIT`, `MED_CABLE`, `MED_TRAY`, `MED_FITTING`, `VERT_DATA`) and `MEDProperties` (3D model ID written on each solid through `MEDStamp3DFromBom` / `MED-SetMedProperties`, exported in `.medprops.json` for the Navisworks plugin). It also sets `*MED-DEBUG*` from `MEDDEBUG`. See [lisp/MEDCore.md](lisp/MEDCore.md).

## Open items

- `2teed` has no DWG; REC, EYS elbows, EZS / EZD are not modelled; plugs and reducers are approximate ([3d-fitting-matrix.md, "Still open"](3d-fitting-matrix.md#phase-2-bodies-done-in-r6)).
