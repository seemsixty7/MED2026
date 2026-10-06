# MED Ductbank Routing: Design (draft for Clint's markup)

**Status:** Draft 2, 2026-10-06. Design only. No code or Support files have changed. Draft 2 adds the Carlon Snap-N-Stac / Snap-Loc spacer catalog as the default family and seed data, Carlon's suggested cover (3" top and bottom, 2" sides), an 8-10 ft spacer interval and a worked example on SP4W20-2.
**Branch studied:** `feature/3dpath` (master at `fa3ed13`).
**Mockup:** `ductbank-dialog-mockup.png`: dialog with grid, cheat image, spacer family/part selection, stub-up vs trunk spacing, per-edge cover and the envelope W x H readout. It shows the §6.8 worked example.

Units are drawing inches, the same as the rest of MED (MED3DFittings: "Drawing units are inches"). Items marked **[VERIFY]** are assumptions or placeholder values that need your call or a data sheet.

---

## 1. Goals and non-goals

### Goals
1. Route a whole ductbank by first routing **one conduit**, the *reference conduit*. In the field you usually know that conduit's stub-up, not the bank centerline.
2. Ask for **rows (conduits deep)** and **conduits per row**, and let the user choose which grid position the reference conduit holds.
3. Lay out the bank in **three zones**, measured from the stub-up end the user picks:
   * **Stub-up zone:** layout comes from the stub-up center spacing, anchored on the reference conduit's stub-up. Spacers do not control it.
   * **Transition:** a short, simple taper from stub-up spacing to spacer spacing.
   * **Main trunk:** each conduit's position comes from the **spacer geometry** (seat positions and the bottom seat). It does not come from offsetting a centerline.
4. Use one dialog for everything: a **grid** showing which conduit is which (position, tag, size, type), a **cheat image** that highlights the conduit being edited, cover and spacing inputs, spacer selection, stub-up spacing, and a live **envelope W x H** readout.
5. Generate **normal MED conduit entities** (`MED_CONDUIT` xdata) so BOM, MEDLIST, MEDPROPERTIES, MEDRECORDS, CHGSIZE and MEDMAKE3D keep working. Each conduit also gets a bank ID and a position ID (A1, A2, ...).
6. Build underground rules in from a **spec profile in MED.db**: 1" minimum size; bend radius 24" for sizes under 4" and 36" for 4" and up; PVC straights; PVC-coated RGS bends; adapters where they meet. An elbow carries **3 fitting records** (elbow + 2 adapters).
7. Compute the **concrete envelope from cover on each edge (top, bottom, left, right), measured from actual conduit OD** (`MEDConduitOD`). Defaults come from Carlon's suggested spec: **3" top and bottom, 2" each side**. The same computed boundary drives the plan outline, the section views and the MEDMAKE3D solid, and the dialog shows the resulting W x H live.
8. Use **Carlon Snap-N-Stac combo spacers** as the default spacer family (Snap-Loc base + intermediate as the alternate). The full catalog is seeded into MED.db (§5.6), including the S287F/S287J reducers so 1" and 2" conduit can sit in a larger seat, plus the S28612 beaded strap and S258RH rebar holder as BOM accessories.
9. Support reusable **named bank types**, an automatic **section view**, ends at stub-ups, manholes or handholes, and spacer counts in the BOM.

### Non-goals (for now)
* Voltage drop, ampacity or derating (Neher-McGrath / NEC 310.15), pulling tension and sidewall pressure. MED will **remind** the user about these (see §3.3) but won't calculate them.
* Cables in conduits and cable fill reports. These are a later phase; the position IDs are designed for them.
* 3D (sloped) trunks and vertical bends inside the trunk. Phase 2.
* Detailed modeling of the transition. It's kept simple on purpose.

---

## 2. What MED does today (code hooks this design builds on)

| Area | What exists | Where |
|---|---|---|
| Conduit entity | LWPOLYLINE + `MED_CONDUIT` xdata `ITEM_TAG_`, `#ITEMSIZE`, `#ITEMCODE`, `#ITEMDIST`, `ITEM_MESR` (5 fields, `len_conduit 5`) | `MEDCore.lsp` (regapp list), `MEDBuildXData.lsp` `bld_conduit` |
| Routing | `c:conduit`: `PLINE` picks, then fillet `filletrad = _MEDRADFAC * _CSIZE * _PLOTSCALE` (5 x trade size), then tag prompt, `bld_conduit` + `xdatadd`. `c:define` attaches data to an existing polyline | `medcon.lsp` |
| Several records on one entity | `bld_app` takes **lists** for code/size/tag/... and writes several records inside one app's `{ }` group. BOM writes one row per record (`ITEM_HAND` repeats). .NET `MedXdata.ParseApp` starts a new record whenever a key repeats | `MEDBuildXData.lsp`, `MEDFunctions.lsp` `MEDSendEntityDataToBOM`, `MedXdata.cs` |
| Fitting record | `MED_FITTING` `ITEM_TAG_`, `#ITEMSIZE`, `#ITEMCODE`, `#ITEM_ALT`, `#ITEMDPTH`, `#ITEMFLNG` (`len_fitting 6`); `attachfitting` adds a fitting record to any picked entity (the menu uses it for elbow codes 89/90/91) | `bld_fitting`, `MEDFunctions.lsp` `attachfitting`, `med.mnu` lines 140-143 |
| Up / down symbols | `C:MEDBlockInsert`, `bl_instype` 4/5 = dependent conduit turned down/up; `dcon_ins` writes `MED_CONDUIT` distance + `VERT_DATA` (r1 r2 dir r4); menu `(setblkins nil "1conu" nil nil _SC 5)` | `medinser.lsp` |
| Tags | `c:ctag` inserts block `contag` on `_ECTAG` from conduit xdata | `QKEY.lsp` |
| Section marks | `c:sect` (blocks `sect1`, `sect`, `sect2`), `c:sectd` (`sect-dyn`) | `MEDCommands.lsp` |
| List / BOM | `MEDListAppDataFormat`, `c:MEDlist`, `C:BOM` / `C:BOMSS` -> `MEDBomFromSelection` -> `MEDProject` | `MEDCommands.lsp` |
| App filter | `xd_apps` returns every `MED*` app **except** `MED_DOUBLE`, `MED_ELEC`, `MEDProperties`. BOM and MEDLIST then `eval` `len<app>`. **A new app named `MED...` would break BOM.** .NET `MedApps.All` only knows the five `MED_` apps, and `WriteApp` replaces only its own app's xdata | `MEDFunctions.lsp` `xd_apps`, `MedXdata.cs` |
| Size edits | `c:chgsize`, `c:chgtag`; MEDCHG / MEDPROPERTIES / MEDRECORDS palettes (.NET) | `MEDCommands.lsp`, `MedPropertiesPalette.cs`, `MedRecordsGridForm.cs` |
| OD | `med_conduit_od (code size)` -> `MEDConduitOD.OD_in` (cached; falls back to `getsize` steel OD). Seeded for codes 1-7, e.g. code 3 PVC Sch 40: 4" = 4.500, 2" = 2.375, 1" = 1.315; code 2 PVC-coated RGS: 4" = 4.580 | `MEDFunctions.lsp`, `Data\MED.db` |
| Catalog | `MEDType` CONDUIT 1-7 (1 RGS, 2 PVC-coated RGS, 3 Rigid non-metallic, ...). FITTING 90 = "RGS 24" Radius Conduit Elbow", 91 = 36", 8 = RGS coupling. **Code 89 (18" elbow) is on the menu but not in MED.db.** No PVC-coated elbow, PVC adapter, end bell or spacer rows yet. Free FITTING code ranges: 157-197, 448-463, >520 | `Data\MED.db` |
| Runtime tables | `MedODSeed.EnsureReady()` creates `MEDConduitOD` / `MEDConduitBody` if missing (SQLite or SQL Server) and inserts missing seed rows from `Data\seed\*.csv`, never overwriting edits | `MedODSeed.cs` |
| Settings bridge | `MedLisp.GetReal/SetReal/GetInt/Run` (e.g. `_MEDRADFAC`, `_CONFILL`) | `MedSettingsControl.cs`, `MedLisp.cs` |
| Site settings | `med.spc` (`MED_LAYER_LIST`, `U_CON "dashed"` underground linetype, `_MEDDIST 120`). The patch never overwrites `med.spc`, so new variables need code defaults, e.g. `(if _MED3DFLAG _MED3DFLAG '("MED_3DFLAG" "RED" "CONTINUOUS"))` | `med.spc`, `MED3DPath.lsp` `med3d-flag-layer` |
| 3D | `med3d-plan` (fillet/tangent allocation, flags), `med3d-bend-radius` + `*MED3D-BEND-OVERRIDES*` (session-only), **drawn bulge arcs are kept exactly**, `med3d-path-build-all`, `med3d-make3d-all` (staged, `med3d-stage`), `MEDStamp3DFromBom` | `MED3DPath.lsp` |
| 3D gotcha | `med3d-tray-build` treats **any non-INSERT entity with `MED_FITTING`** as a tray-fitting outline. A polyline elbow segment would be mis-built. Needs a one-line skip | `MED3DTrayFunctions.lsp` ~line 437 |
| Conduit bodies | `medcb-collect` (MED_FITTING INSERTs, otherwise "not modelled"), `medcb-vert-leg` (vertical conduit only off resolved body inserts) | `MED3DFittings.lsp` |
| Dialogs | 16 DCL dialogs in `med.dcl` (lists, slides). Modern editors are WinForms in MED-DotNet: `MedRecordsGridForm` (DataGridView), `MedTypeForm`, `MedShowBomForm`, palettes | `med.dcl`, `src\MED-DotNet` |
| Tests | Mini AutoLISP interpreter + AutoCAD mock: `tests\med3dpath\lispmini.py`, `acadmock.py`, `test_med3dpath.py` | `tests\med3dpath` |

---

## 3. User workflow

### 3.1 Command flow (`DUCTBANK`)

```
Command: DUCTBANK
Select reference conduit or [Route] <Route>:            (Route = same picks as CONDUIT; fillet off)
  Pick start point of reference conduit (stub-up end):
  Pick point: ...  <Enter>
Pick stub-up end of reference conduit <start>:          (selects end A, which sets the stub-up zone)
Number of conduits deep (rows) <2>:
Number of conduits per row <3>:
Reference conduit position (row letter + column) <B1>:   (can also be clicked in the grid)
Spec profile [UG-DEFAULT/...] <UG-DEFAULT>:              (Carlon Snap-N-Stac, 2" sep, cover 3/3/2/2, spacers every 8 ft)
  -> dialog opens (section 4). Preview < hides it and draws a temporary preview of conduits, zones, envelope and sections.
  -> OK
Pick location for STUB-UP section <Enter = beside end A>:
Pick cut point for TRUNK section on the bank <Enter = mid-trunk>:
Pick location for TRUNK section:
DUCTBANK DB-1: 6 conduits (2 x 3, SP4W20-2), 10 spacer stations (40 spacers, 20 straps), 4 bends, 30 elbows (90 fitting records).
Reminder: MED does not calculate voltage drop, cable fill/derating or pulling tension. Check them per project spec.
```

* **Selecting an existing conduit** works on a filleted polyline. Its arcs are read back to corner points: the tangent lines are intersected, so the bank rules re-fillet every conduit, including the reference.
* **Stub-up end:** it's end A. The other end, B, is chosen in the dialog: Stub-up, Manhole/Handhole (end bells at a picked wall line), or Open.
* **Column 1** is on the **left looking from end A along the run**. **Row A is the top row.** Spacer tiers are counted from the bottom (tier 1 = base). **[VERIFY]**
* MVP constraint: no plan bends inside the stub-up zone or the transition. The generator flags a bend there.

### 3.2 What OK generates
1. A conduit polyline per grid position: PVC (code 3 by default), `MED_CONDUIT` + `DBANK_DATA`, U_CON linetype, elevation from the spacer seat.
2. Elbows at every trunk bend and at every stub-up vertical 90. Each carries 3 fitting records (§5.3).
3. Stub-up risers: a conduit-up symbol per conduit (`1conu` style, `MED_CONDUIT` dist + `VERT_DATA`, same data `dcon_ins` writes).
4. Spacer stations along the trunk: symbol blocks carrying BOM records (§6.6).
5. The envelope outline (closed polyline, layer `MED_DUCTBANK`), which holds the **bank record**.
6. A stub-up section and a trunk section (§6.8), plus section cut marks using the existing `sect1`/`sect`/`sect2` blocks.
7. Tags: positions and tags in both sections. Optional `contag` at each stub-up.

### 3.3 Calc reminder
The reminder is printed on the command line after OK and shown permanently in the dialog: *"Not calculated by MED: voltage drop; cable fill and ampacity derating (NEC 310.15 / Neher-McGrath); pulling tension and sidewall pressure; burial depth and separation per NEC 300.5 / utility / project spec."*

---

## 4. Dialog

See **`ductbank-dialog-mockup.png`**. It's a modal WinForms form in MED-DotNet (`MedDuctbankForm.cs`), in the same style as `MedRecordsGridForm` and `MedTypeForm`. DCL can't do an editable grid or a live drawn preview.

| Panel | Contents |
|---|---|
| Spec / bank type | Spec profile dropdown (`MEDDuctbankSpec`); Bank type dropdown + **Save type...** (`MEDDuctbankType`); Rows, Per row; Reference position; Envelope (Concrete / Direct-buried / Slurry); straight + bend material; Elbow as (Broken segment / Dot) |
| Main trunk: spacers | **Family** dropdown (Carlon Snap-N-Stac combo [default] / Carlon Snap-Loc base + intermediate / None, computed from OD) and **Part** dropdown (`MEDDuctbankSpacer` rows of that family that fit the largest conduit, for example `SP4W20-2 (4", 2" sep, 2-way)`). The default part = family + largest size + spec separation (2"). Read-only catalog **C-C pitch H / V** and **seat bottom** (trench to bottom of duct, with the catalog center value shown for comparison). **Interval** (default 96" = 8 ft; Carlon prefers 8-10 ft); trunk bend style; "Spacer symbols"; per-station and total counts for spacers, straps, rebar holders and reducers |
| Cover and clearances | **Cover Top / Bottom / Left / Right**, measured from conduit OD (defaults 3 / 3 / 2 / 2, Carlon's suggested spec); Min clear gap (OD to OD, checked; default 2"); Depth to top of envelope; **Reset to spec** |
| Stub-up zone and transition | **Stub pitch across** (center to center) and **along** (row stagger, top row first); stub-up rise above grade; **Transition length**; taper style (Straight / Short bends); End B type |
| Grid | rows x columns cells, each showing position (A1...), size, type and tag. **REF** badge on the reference cell; the selected cell is highlighted. Editor below: Tag, Size (dropdown from `_CONSIZE_LIST`, filtered to >= spec minimum), Type, **Reducer** (auto: S287F for 1" / S287J for 2" in a larger seat), Spare, **Set as REF**, **Fill size**, **Auto tags** (pattern `{BANK}-{POS}`), Ctrl+D fill down like MEDRECORDS. Per-cell readout: trunk seat bottom and centerline, stub offset, taper |
| Cheat image | Trunk section to scale from OD: envelope, spacer pieces with seats (2-way Snap-N-Stac pieces or 1-cell Snap-Loc), any **empty seat and any piece end sticking out past the envelope (red)**, each conduit drawn at its OD, current conduit yellow, REF crosshair, dims (W, H, seat pitch, base height). Below it, a not-to-scale **plan strip** of the three zones showing stub pitch vs seat pitch |
| Envelope readout | **Trunk W x H** and **Stub zone W x H**, with the formula and an approximate concrete CY/10 ft |
| Checks | Live list: clear gaps (trunk, stub), seat bottom vs bottom cover, minimum size, inner/outer bend radii, piece end past envelope (odd columns), catalog CL vs seat rule, reducer mode, unverified catalog data |
| Buttons | Preview <, Trunk section at... <, Stub section, OK, Cancel, Help |

Interface between the two halves: LISP builds an alist (bank parameters + cell list) and calls a new LispFunction `MED-DuctbankDialog`. The form edits the alist and returns it, or nil on Cancel. The form reads the spec, spacer and OD tables directly through `ProcessSQL`. All geometry stays in LISP (§7) so it can be unit-tested with the existing mini interpreter.

---

## 5. Data model

### 5.1 Per conduit: a normal MED conduit plus bank data
* `MED_CONDUIT` exactly as `bld_conduit` writes it: `(bld_conduit code size tag nil "T")`. Measured, PVC code 3, so length, BOM, MEDLIST, MEDPROPERTIES and MEDMAKE3D behave as for any conduit.
* **New regapp `DBANK_DATA`.** The name deliberately doesn't start with `MED`, so `xd_apps`, BOM, MEDLIST and `MedApps.All` never see it. It follows the `VERT_DATA` precedent. Group 1000 `KEY=VALUE` strings, like MED, plus 1005 for handles:

| Key | Example | Meaning |
|---|---|---|
| `ROLE` | `CONDUIT` | CONDUIT / ELBOW / STUB / SPACER / ENVELOPE / SECTION |
| `BANK` | `DB-1` | bank ID |
| (1005) | master handle | envelope polyline (translated by AutoCAD on COPY/WBLOCK) |
| `POS` | `B1` | position ID (row letter + column) for later cable assignment |
| `ROW` / `COL` / `TIER` | `2` / `1` / `1` | grid row from the top, column, spacer tier from the bottom |
| `LAT` | `0.0` | trunk lateral seat offset from the REF seat (+ = right looking from A) |
| `SEATZ` | `0.0` | trunk seat-bottom offset from the REF seat bottom |
| `STUBX` / `STUBY` | `0.0` / `10.0` | stub-up grid offset from the REF stub point (across / along) |
| `GEN` | `1` | generator version |

### 5.2 Bank record (on the envelope outline polyline)
`DBANK_DATA` with `ROLE=ENVELOPE`: `BANK`, `NAME` (bank type), `SPEC`, `ROWS`, `COLS`, `REFPOS`, `SPACER` (SpacerId), `SPINT`, `BENDSTYLE`, `COVT/COVB/COVL/COVR`, `GAP`, `DEPTH`, `ENCASE`, `STUBSX/STUBSY`, `STUBRISE`, `TRANSL`, `TAPER`, `ENDA/ENDB`, `WT/HT` (trunk W/H), `WS/HS` (stub zone W/H). Also 1005 handles of every member. MVP banks are small enough for xdata (the 16 KB limit allows a few hundred handles). The envelope itself has **no** `MED_*` xdata in the MVP, so it isn't in the BOM. Concrete quantity is Phase 3.

### 5.3 Elbows: 3 fitting records

**Option B, "Broken segment" (default, Clint's preference):** the conduit is broken at each conduit's own tangent points, and the bend becomes its own LWPOLYLINE arc (bulge). That segment carries:
* `MED_FITTING` with **3 records** through the list form of `bld_fitting`:
  `(bld_fitting (list ELB ADP ADP) (list sz sz sz) (list tag tag tag) '(0.0 0.0 0.0) '(0.0 0.0 0.0) '(0.0 0.0 0.0))`, giving elbow + adapter + adapter. BOM writes 3 rows with the same handle, which BOM already allows.
* `MED_CONDUIT` code 2 (PVC-coated RGS), `#ITEMDIST=0`, `ITEM_MESR=F`. MEDMAKE3D then sweeps the elbow at the coated OD with no changes, and PVC footage isn't inflated. The side effect is a zero-qty CONDUIT row per elbow in `MEDProject`. **[VERIFY]**: OK, or should MEDSHOWBOM hide qty 0?
* `DBANK_DATA ROLE=ELBOW`, `POS`, `RAD=36`.
* Required change: `med3d-tray-build` must skip non-INSERT `MED_FITTING` entities that also carry `MED_CONDUIT` or `DBANK_DATA`.

**Option A, "Dot" (simple):** the conduit stays continuous with its arc. A small dot block (new `DBFIT`, layer `MED_FITTINGS`) at the arc midpoint carries the same 3 `MED_FITTING` records. It's simpler to edit, but PVC footage includes the arc length and 3D sweeps the elbow at the PVC OD. `medcb-collect` reports it as "not modelled" and stays quiet.

**Stub-up vertical elbow:** in plan it's drawn as a straight segment of length R, from the elbow start to the stub point, using the same Option B data. The 3 records are elbow + adapter (PVC side) + the riser-side fitting, which defaults to an adapter. **[VERIFY]**: coupling to an RGS riser instead?

### 5.4 Catalog rows needed (`MEDType`, FITTING; proposed free codes)
| Code | Description |
|---|---|
| 160 / 161 / 162 | PVC-coated RGS 90° elbow, 24" / 36" / 48" radius |
| 163 / 164 / 165 | PVC-coated RGS 45° elbow, 24" / 36" / 48" radius |
| 170 | PVC female adapter (PVC to threaded rigid) |
| 171 | PVC end bell |
| 172 | PVC coupling |
| 521-531 | Carlon Snap-N-Stac SP2W20-2 ... SP6W30-2 (11 parts, §5.6) |
| 532-549 | Carlon Snap-Loc base spacers S288JHN ... S288SJN (18 parts) |
| 550-567 | Carlon Snap-Loc intermediate spacers S289JHN ... S289SJN (18 parts) |
| 568 / 569 | Carlon Snap-Loc reducer 1" S287F / 2" S287J |
| 570 / 571 | Carlon beaded strap S28612 / rebar holder S258RH |

Codes 521-571 are in the free range above 520. Also add the missing **89** (18" RGS elbow, referenced by `med.mnu`). Optional CONDUIT additions: PVC Sch 80 and Type EB/DB-120 duct, with `MEDConduitOD` rows. **[VERIFY]**

### 5.5 New database tables (MED.db; created and seeded at NETLOAD like `MedODSeed`)

**`MEDDuctbankSpec`**: spec profiles, key `SpecName`.
`SpecName, Description, MinTradeSize (1.0), StraightCode (3), BendCode (2), ElbowAdapterCode (170), StubRiserFitCode (170), DefaultSpacerFamily (SNAPNSTAC), DefaultSeparation_in (2.0), SpacerInterval_in (96; Carlon prefers 8-10 ft), SpacerEndOffset_in (12) [VERIFY], BendStyleTrunk (STOCK|CONCENTRIC), FittingStyle (SEGMENT|DOT), MinClearGap_in (2.0), CoverTop_in (3.0), CoverBottom_in (3.0), CoverLeft_in (2.0), CoverRight_in (2.0), DepthToTop_in (24) [VERIFY], Encasement (CONCRETE|DIRECT|SLURRY), StubPitchAcross_in, StubPitchAlong_in, StubRise_in (36), TransitionLength_in (60), MaxTaperDeg (5) [VERIFY], TaperStyle (STRAIGHT|SHORTBEND), TagPattern ({BANK}-{POS}), IsDefault, Notes`

**`MEDDuctbankBendRule`**: radius by size, key `SpecName, MinTradeSize`.
`SpecName, MinTradeSize, MaxTradeSize (exclusive), BendRadius_in, Elbow90Code, Elbow45Code`
Seed for `UG-DEFAULT`: `(0, 4.0, 24, 160, 163)` and `(4.0, 99, 36, 161, 164)`.

**`MEDDuctbankSpacer`**: spacer catalog, one row per part (or base + intermediate pair), key `SpacerId`.
`SpacerId (part no.), Family (SNAPNSTAC|SNAPLOC|GENERIC), Mfr, PartBase, PartIntermediate (same part for Snap-N-Stac), DuctSize (trade), DuctOD_in (catalog value), Positions (seats across one piece: 2 for Snap-N-Stac, 1 for Snap-Loc), SepV_in, SepH_in (duct to duct), PitchV_in, PitchH_in (center to center), SeatBottom_in (bottom of trench to bottom of the bottom duct), BotToCenter_in (catalog bottom of trench to center of bottom duct, kept for checking), SeatDia_in (Snap-Loc D), BaseA_in (Snap-Loc A), IntermB_in (Snap-Loc B), PieceLength_in (overall length across), Interlock (H|V|HV), RebarHolderMolded (T/F), CodeBase, CodeIntermediate (MEDType FITTING), Source, Verified (T/F), Notes`

**`MEDDuctbankReducer`**: `Part, ConduitSize, HostSizes (spacer sizes it fits), Mode (CENTER|BOTTOM), OffsetZ_in, Code, Source, Verified`. Seed: S287F 1" and S287J 2". Host sizes and mode are **[VERIFY]** (§6.1).

**`MEDDuctbankAccessory`**: `Part, Description, Family, Rule (PER_TOP_PIECE|PER_TOP_CONDUIT|PER_STATION|PER_N_COLS), Qty, Code, Source`. Seed: S28612 beaded strap, S258RH rebar holder (Snap-Loc only; Snap-N-Stac has a molded-in rebar holder).

**`MEDDuctbankSpacerSeat`** (optional override for non-uniform spacers): `SpacerId, Tier, Cell, SeatX_in, SeatBottomZ_in`. If rows exist, they replace the pitch formula.

**`MEDDuctbankType`** + **`MEDDuctbankTypeCell`**: named bank types.
`TypeName, SpecName, Rows, Cols, RefRow, RefCol, SpacerId, StubPitchAcross_in, StubPitchAlong_in, Notes` / `TypeName, Row, Col, TradeSize, ConduitCode, TagPattern, Spare`

Seeds go in `Data\seed\ductbank_spec.csv`, `ductbank_bend_rules.csv`, `ductbank_spacers.csv`, `ductbank_reducers.csv`, `ductbank_accessories.csv` (the patch ships CSVs, never MED.db). A new `MedDuctbankSeed.EnsureReady()` creates the tables and fills only missing rows, using the same pattern as `MedODSeed`. **Spacer seed = the Carlon catalog in §5.6** (`Source` = Carlon 7F78 Spacers, Lamson & Sessions 2006, pp. 225-226; `Verified=F` until checked against current ABB/Carlon data). GENERIC rows stay available only for the "None / computed" fallback. More manufacturers can be added later with a source per row, like `conduit_od.csv`.

### 5.6 Seed data: Carlon spacers (default family)

Source: Carlon catalog 7F78 "Spacers" (Lamson & Sessions, rev 10/06; pp. 225-226), from Clint (`/workspace/ductbank/spacer.pdf`). **Verify every row against current ABB/Carlon data before release.** The rows ship with `Verified=F`.

**Snap-N-Stac combo spacers** (one piece works as base or intermediate; 2 horizontal positions per piece; locks horizontally and vertically; molded-in rebar holder; pieces interlock horizontally regardless of size):

| Part | Duct | OD | H pos | Sep V | Sep H | C-C V | C-C H | Trench to duct bottom | Trench to bottom-duct CL | Overall length |
|---|---|---|---|---|---|---|---|---|---|---|
| SP2W20-2 | 2" | 2.375 | 2 | 2 | 2 | 4.38 | 4.38 | 3.13 | 4.25 | 8.75 |
| SP2W30-2 | 2" | 2.375 | 2 | 3 | 3 | 5.38 | 5.38 | 4.13 | 5.25 | 10.75 |
| SP3W20-2 | 3" | 3.500 | 2 | 2 | 2 | 5.50 | 5.50 | 3.63 | 5.38 | 11.00 |
| SP3W30-2 | 3" | 3.500 | 2 | 3 | 3 | 6.50 | 6.50 | 4.63 | 6.38 | 13.00 |
| SP4W15-2 | 4" | 4.500 | 2 | 1.5 | 1.5 | 6.00 | 6.00 | 3.38 | 5.56 | 12.00 |
| SP4W20-2 | 4" | 4.500 | 2 | 2 | 2 | 6.50 | 6.50 | 3.88 | 6.06 | 13.00 |
| SP4W30-2 | 4" | 4.500 | 2 | 3 | 3 | 7.50 | 7.50 | 4.88 | 7.06 | 15.00 |
| SP5W20-2 | 5" | 5.500 | 2 | 2 | 2 | 7.56 | 7.56 | 4.38 | 7.25 | 15.12 |
| SP5W30-2 | 5" | 5.500 | 2 | 3 | 3 | 8.56 | 8.56 | 5.38 | 8.25 | 17.14 |
| SP6W20-2 | 6" | 6.625 | 2 | 2 | 2 | 8.62 | 8.62 | 4.13 | 7.38 | 17.25 |
| SP6W30-2 | 6" | 6.625 | 2 | 3 | 3 | 9.62 | 9.62 | 5.13 | 8.38 | 19.25 |

Mapping: `PitchV/PitchH` = C-C columns; `SeatBottom` = trench to duct bottom; `BotToCenter` = trench to bottom-duct CL; `PieceLength` = overall length, which equals 2 x C-C H, so each position is one pitch wide and the outer seat center sits pitch/2 in from the piece end.

**Snap-Loc base (S288) and intermediate (S289) spacers** (single cell; dovetail rail lets sizes interlock side by side; intermediates have key ways for the beaded strap, so no top spacer is needed; **3" standard base for all base spacers**). Size = trade size x separation.

| Base part | Inter. part | Size | A (base) | B (inter.) | C | D (seat dia) |
|---|---|---|---|---|---|---|
| S288JHN | S289JHN | 2 x 1-1/2 | 4.25 | 3.88 | 4.12 | 2.50 |
| S288JJN | S289JJN | 2 x 2 | 4.25 | 4.38 | 4.62 | 2.50 |
| S288JLN | S289JLN | 2 x 3 | 4.25 | 5.38 | 5.62 | 2.50 |
| S288LHN | S289LHN | 3 x 1-1/2 | 4.81 | 5.01 | 5.25 | 3.63 |
| S288LJN | S289LJN | 3 x 2 | 4.81 | 5.51 | 5.75 | 3.63 |
| S288LLN | S289LLN | 3 x 3 | 4.81 | 6.51 | 6.75 | 3.63 |
| S288NFN | S289NFN | 4 x 1 | 5.31 | 5.51 | 5.75 | 4.63 |
| S288NHN | S289NHN | 4 x 1-1/2 | 5.31 | 6.01 | 6.25 | 4.63 |
| S288NJN | S289NJN | 4 x 2 | 5.31 | 6.51 | 6.75 | 4.63 |
| S288NLN | S289NLN | 4 x 3 | 5.31 | 7.51 | 7.75 | 4.63 |
| S288PHN | S289PHN | 5 x 1-1/2 | 5.84 | 7.07 | 7.31 | 5.69 |
| S288PJN | S289PJN | 5 x 2 | 5.84 | 7.57 | 7.81 | 5.69 |
| S288PLN | S289PLN | 5 x 3 | 5.84 | 8.57 | 8.81 | 5.69 |
| S288RHN | S289RHN | 6 x 1-1/2 | 6.38 | 8.14 | 8.38 | 6.75 |
| S288RJN | S289RJN | 6 x 2 | 6.38 | 8.64 | 8.88 | 6.75 |
| S288RLN | S289RLN | 6 x 3 | 6.38 | 9.64 | 9.88 | 6.75 |
| S288SHN | S289SHN | 8 x 1-1/2 | 7.38 | 10.14 | 10.30 | 8.75 |
| S288SJN | S289SJN | 8 x 2 | 7.38 | 10.64 | 10.76 | 8.75 |

How I read A/B/C/D (**[VERIFY]** against the catalog figure):
* **A** = trench to seat center of the base (A - D/2 = 3.00 on every row, which matches the "3" standard base").
* **B** = vertical center-to-center (B - OD = separation: 4x2: 6.51 - 4.50 = 2.01; 2x2: 4.38 - 2.375 = 2.00).
* **C** = horizontal center-to-center (cell width; about 0.12-0.25 wider than OD + separation because of the dovetail).
* **D** = seat diameter.

So `SeatBottom = 3.0`, `PitchV = B`, `PitchH = C`, `Positions = 1`.

**Accessories and reducers**
| Part | Item | BOM rule (proposed) |
|---|---|---|
| S287F | 1" Snap-Loc reducer | one per station per 1" conduit sitting in a larger seat |
| S287J | 2" Snap-Loc reducer | one per station per 2" conduit sitting in a larger seat |
| S28612 | Beaded strap (15" long) | one per top-tier piece per station **[VERIFY]** |
| S258RH | Rebar holder (hole 0.688-0.750) | Snap-Loc only, 2 per station on large banks **[VERIFY]**. Not needed for Snap-N-Stac (molded-in) |

**Data checks to verify with Carlon** (computed from the table):
* Snap-N-Stac C-C = OD + separation exactly, except 5" (7.56 vs 5.500 + 2 = 7.50). The 5" pitch matches the Sch 40 PVC OD of 5.563 that `MEDConduitOD` already holds, so the catalog's 5.500 OD looks rounded.
* Trench-to-CL vs trench-to-bottom + OD/2 differs by 0.06-0.12" on the 2", 4", 5" and 6" rows (e.g. SP4W20-2: 6.06 vs 3.88 + 2.25 = 6.13); the 3" rows agree. MED uses **seat bottom + OD/2**, Clint's rule, and DBCHECK reports the catalog difference.

---

## 6. Geometry

### 6.1 The frame: seat-driven, not centerline tracking
The reference path is converted into a **seat frame**. At every station s along the reference route there is an origin **O(s)**, the bottom of the reference conduit's seat at its seat center, plus unit vectors **t** (along the run), **e** (to the right looking from A) and **z** (up). The reference conduit's centerline is O + z * OD_ref/2. Every other conduit is placed from the frame, not from the reference centerline:

* Seat center across: `X(c) = (c-1) * PitchH` (or `SeatX` from `MEDDuctbankSpacerSeat`). For 2-way Snap-N-Stac pieces, columns pair up (1-2, 3-4, ...) and the piece spans `X - PitchH/2` to `X + 3*PitchH/2`.
* Seat bottom: `Zs(tier) = SeatBottom + (tier-1) * PitchV`, with tier counted from the bottom (SP4W20-2: 3.88, 10.38, 16.88 ...).
* Conduit (row r, col c), trunk: **`P = O + e*(X(c) - X(c_ref)) + z*(Zs(tier) - Zs(tier_ref)) + z*h(r,c)`**, where `h = OD/2` for a conduit in its own-size seat.

So **lateral position is the seat center and doesn't depend on OD**, while the **centerline height depends on what sits in the seat**. If the reference conduit's size changes later, the seat bottom stays put and only its centerline moves, which is why the frame is the seat and not the centerline.

**One spacer part per bank (MVP).** The part is chosen for the largest conduit. Smaller conduits sit in that seat:
* **1" or 2" with a reducer** (S287F / S287J, automatic when `MEDDuctbankReducer` lists the host size). The centering mode is unknown from the catalog, so it's modeled both ways. `CENTER` (assumed default): CL = seat design center = `Zs + DesignOD/2`, so a 1" in a 4" SP4W20-2 seat sits at the same height as a 4". `BOTTOM`: CL = `Zs + OffsetZ + OD/2` (OffsetZ = reducer wall, default 0), so a 1" sits 1.59" lower (2.250 - 0.658). Lateral stays on the seat center either way. **[VERIFY with Carlon]**
* **Other small sizes with no reducer** (1-1/4", 1-1/2", 2-1/2" ...) sit loose on the seat bottom: CL = `Zs + OD/2`. DBCHECK warns that the conduit isn't fixtured.
* **Mixed piece sizes in a row** (allowed physically, since pieces interlock horizontally regardless of size) is Phase 2. Each piece has its own seat bottom (SP2W20-2 3.13 vs SP4W20-2 3.88) and vertical pitch, so tiers stop being level. The model already supports it through `MEDDuctbankSpacerSeat`.

Elevation: envelope bottom `Eb = Grade - DepthToTop - H_trunk` and `O.z = Eb + Zs(tier_ref)` (`Zs` already includes the base height). MVP trunks sit at a constant elevation, so each conduit is an LWPOLYLINE with its own elevation (DXF 38). **[VERIFY: keep a routed polyline's own elevation instead?]**

### 6.2 Zones along the reference route (measured from end A)
```
end A |<-- stub-up zone -->|<-- transition -->|<------------- main trunk (spacers) ------------->| end B
       stub grid Sx x Sy     straight taper L_t   seat pitch H/V, spacer every SpacerInterval
```
* Stub-up zone length = `(rows-1)*Sy + R_max(stub elbows) + 12"`.
* Transition = `TransitionLength`.
* Trunk = the rest, plus a mirrored stub-up zone and transition at B if B is a stub-up too.

### 6.3 Stub-up zone (stub spacing controls; spacers don't)
* Stub point of (r,c): **`S(r,c) = S_ref + e*(c - c_ref)*Sx + t*(k(r) - k(r_ref))*Sy`**, where k(r) = 0 for the top row and increases with depth, moving **toward end A**. The **top row turns up first**, nearest the trunk; deeper rows pass under and rise beyond it. Otherwise a deeper riser would pass through the straight above it.
* Lateral offset in the zone = `(c - c_ref)*Sx`. Elevation = the conduit's trunk tier elevation, carried through unchanged: no spacers here, the conduits are held by a stub-up template or support.
* Vertical 90 per conduit: radius from `MEDDuctbankBendRule` by size. In plan it's a straight from `S - t*R` to `S`, then the riser from `z_c + R` to Grade + StubRise.
* Radius rule for the vertical bend: the top row is the **inside**. A deeper (outer) elbow may be smaller than, equal to, or at most `min(Sy, dz)` larger than the elbow above it (dz = vertical center spacing). A larger outer radius cuts the corner more and pulls toward the row above. The generator works from the deepest row upward, sets `R_upper = max(Rule(size), R_deeper - min(Sy, dz))`, rounds up to the next stock radius, and reports any radius it raised. I checked this numerically: R 24 over R 34 with Sy 10 / dz 7.5 holds 7.5"; R 24 over R 36 closes to 7.08".
* Checks (warnings, since the user owns the stub layout): `Sx - (OD_a+OD_b)/2 >= MinClearGap` across, and `Sy - (OD_a+OD_b)/2 >= MinClearGap` along.

### 6.4 Transition (kept simple)
Over `TransitionLength`, each conduit's lateral offset changes linearly from its stub offset to its trunk offset. Elevation doesn't change.
* `STRAIGHT` (default): two vertices per conduit, giving a straight taper. Angle `a = atan(|dLat| / L_t)`. If `a > MaxTaperDeg` the generator warns and suggests a length, or switches to:
* `SHORTBEND`: two opposing short fillets at the bend-rule radius.
The reference conduit has offset 0 in both zones, so its routed path is unchanged.

### 6.5 Main trunk: spacer-driven positions
* Spacer choice: family + part from `MEDDuctbankSpacer`. The default is the **Snap-N-Stac** part for the largest conduit at the spec separation (2"); smaller conduits use reducers (§6.1). "None / computed" falls back to an OD-driven grid for direct-buried or formed banks: column width = largest OD in the column, row height = largest OD in the row, pitch = adjacent half-widths + MinClearGap.
* Checks:
  * horizontal clear `PitchH - (OD_a+OD_b)/2 >= MinClearGap`
  * vertical clear `PitchV - OD(lower tier) >= MinClearGap`
  * `SeatBottom >= CoverBottom` (SP4W20-2: 3.88 >= 3; Snap-Loc: 3.00 >= 3)
  * catalog CL vs seat rule (reported)
  * **2-way pieces with an odd column count**: one empty seat per tier, and the piece runs one pitch past the last conduit. If the piece end goes beyond the OD-based envelope edge, DBCHECK flags it, shows it red in the cheat image, and offers: trim the piece in the field, add a column (spare), or widen that envelope side to the piece end. The default keeps Clint's OD-based cover. **[VERIFY]**

### 6.6 Spacer placement and BOM
* Stations along the trunk frame: the first at `SpacerEndOffset` from each trunk end, then every `SpacerInterval` (**default 96" = 8 ft**; Carlon's preferred interval is 8-10 ft, and the dialog allows 96-120" without a warning). Count = `ceil((L - 2*EndOffset) / Interval) + 1`. With Stock bend style there are **none inside a bend zone** (from the earliest tangent-in to the latest tangent-out), but one is placed on each side. With Concentric they continue around the arc at the interval, measured on the frame arc, and are set radially.
* Pieces per station:
  * **Snap-N-Stac:** `rows * ceil(cols / 2)` combo pieces.
  * **Snap-Loc:** `cols` base + `cols * (rows-1)` intermediate.
  * Accessories per `MEDDuctbankAccessory`: beaded straps on the top tier, rebar holders (Snap-Loc only), and one reducer per reduced conduit per station.
* Each station is an INSERT of a simple block `DBSPACER` (a bar across the envelope, perpendicular to the path) on new layer `MED_DBSPACER`. It carries `MED_FITTING` with one record per piece and accessory (codes 521-571, size = spacer nominal size) and `DBANK_DATA ROLE=SPACER STATION=n`. "Place spacer symbols" off = the layer is frozen, but the stations still exist, so **BOM counts stay right**. `medcb-collect` ignores them ("not modelled"). **[VERIFY: OK to always create stations?]**

### 6.7 Bends in the trunk (effect of spacers on radii)
Spacers lock lateral spacing. That gives two physically different choices:

**a) Stock elbows, no spacers in the bend (default).** Each conduit gets a stock radius from the bend rule, filleted at **its own** offset corner. Why the spacing holds: with **equal** radii, each conduit's bend is the inner bend shifted along the bisector. The gap is exactly the seat pitch d on both tangents and grows to `d / cos(theta/2)` at mid-bend (1.41 d at 90°). A **smaller** outer radius only opens the gap. A **larger** outer radius cuts the corner more and pulls the outer arc toward the inside; concentric (`R_outer = R_inner + d`) is the limit. Rule: **`R_outer - R_inner <= d` for every adjacent pair.** The generator works from the **outermost** conduit inward, sets `R_c = max(Rule(size_c), R_(c+1) - d)`, rounds up to the next stock radius, and reports any radius it raised. I checked this numerically at 90° with d = 7.5: 36/36 holds 7.5", 36 inside / 24 outside holds 7.5", but 24 inside / 36 outside closes to 5.64". So a 2" on the inside of a 4" gets raised from 24" to 36". Spacers resume once every conduit is back on its tangent (one each side of the bend zone). The envelope's outer edge follows the outer conduit (extra concrete at the outside corner). All elbows stay factory stock (24/36/48), which matches coated RGS.

**b) Concentric, spacers through the bend.** The frame bends with radius Rf, and each conduit has `R = Rf - (offset toward the center)`, so spacing stays constant and spacers are placed radially. Choose **`Rf = max over conduits of (Rule(size_c) + inward offset_c)`**. Normally the **innermost conduit governs**, but a large conduit further out can govern if its rule radius is bigger. Outer radii come out non-stock (e.g. 36 + 7.5 = 43.5"). That suits field-bent or custom sweeps; the BOM would carry the next stock radius or a "custom sweep" code with the real radius in `DBANK_DATA RAD`. **[VERIFY]**

Both styles: tangent `T = R*tan(theta/2)` must fit on each conduit's straights. The generator reuses `med3d-plan` / `med3d-allocate` logic per conduit, and refuses or flags a bend where any conduit doesn't fit. Drawn bends are true bulge arcs, which `MED3DPath` keeps exactly, so no `*MED3D-BEND-OVERRIDES*` (session-only) are needed.

### 6.8 Envelope boundary: one function, three consumers
`(dbk-envelope bank zone)` returns the section rectangle relative to the frame, from **actual OD** (`med_conduit_od`, `MEDConduitOD`):

* Left = `min_c(lat_c - OD_c/2) - CoverLeft`
* Right = `max_c(lat_c + OD_c/2) + CoverRight`
* Top = `max(z_c + OD_c/2) + CoverTop`
* Bottom: **trunk** = trench bottom, where the spacer feet sit = `min seat bottom - SeatBottom`. The effective bottom cover is the catalog seat bottom; flag if `SeatBottom < CoverBottom`. **Stub zone** = `min(z_c - OD_c/2) - CoverBottom`, then the lower of the two is used so the bottom is continuous.
* `W = Right - Left`, `H = Top - Bottom`. Each row and column is governed by its largest OD; mixed sizes are handled per conduit.

**Worked example (the mockup):** a bank 2 deep x 3 wide of 4" PVC Sch 40 (OD 4.500), Snap-N-Stac **SP4W20-2** (C-C 6.50 x 6.50, seat bottom 3.88), default cover T 3 / B 3 / L 2 / R 2, reference conduit B1, stub pitch 8.00 across x 10.00 along, transition 60".

| | Trunk (spacer-driven) | Stub-up zone (stub spacing) |
|---|---|---|
| Lateral centers from REF (cols 1/2/3) | 0.00 / 6.50 / 13.00 | 0.00 / 8.00 / 16.00 |
| Tier 1 (row B) seat bottom / CL | 3.88 / **6.13** (catalog 6.06) | carried: CL 6.13 |
| Tier 2 (row A) seat bottom / CL | 10.38 / **12.63** | carried: CL 12.63 |
| Clear gap H / V | 2.00 / 2.00 | 3.50 across, 5.50 along (rows staggered 10.00) |
| Left edge | 0 - 2.25 - 2 = -4.25 | -4.25 |
| Right edge | 13.00 + 2.25 + 2 = 17.25 | 16.00 + 2.25 + 2 = 20.25 |
| Bottom / top | 0 (trench; bottom cover = 3.88 >= 3) / 12.63 + 2.25 + 3 = 17.88 | same |
| **W x H** | **21.500" x 17.880"** | **24.500" x 17.880"** |
| Concrete | about 0.74 CY per 10 ft (net of conduit) | |

* Transition: cols 2 and 3 move 1.50" and 3.00" over 60", so the taper is 1.43° and 2.86° (under the 5° limit). Plan outline: straight taper from W 21.50 to 24.50.
* Spacers: 3 columns on 2-way pieces = 2 pieces per tier with one empty seat. The right piece ends at 13.00 + 3.25 + 6.50 = 22.75, which is **5.50" past** the 17.25 envelope edge, so it's flagged (see §6.5). A 68 ft trunk at 8 ft = 10 stations, giving 40 SP4W20-2 + 20 S28612 straps (no rebar holders, since they're molded in).
* Bends: all 4", so every elbow is R 36. The stub-up rows (dz 6.50, Sy 10.00) and the trunk pairs (d 6.50) pass the radius rules in §6.3 / §6.7.
* Reducer variant: with B3 = 1" (OD 1.315) in the 4" seat using S287F, `CENTER` gives CL 6.13, the same as B1; `BOTTOM` gives CL 3.88 + 0.66 = 4.54. Envelope W x H is unchanged, because the 4" conduits govern each edge.

**Consumers, all from the same numbers:**
1. **Plan outline:** the trunk sides are the outermost conduits' actual paths offset by OD/2 + cover. In straights that's exactly Left/Right; in stock bends they follow the outer conduit arcs. Transition sides are straight lines between the zone rectangles. The end at a stub-up wraps the last elbow by cover **[VERIFY: or stop at elbow start]**. The end at a manhole is the wall line.
2. **Sections:** the rectangle for that zone, drawn to scale.
3. **MEDMAKE3D (Phase 2):** each zone's plan outline region extruded from Bottom by H; the transition is lofted between its two end rectangles, or extruded at the larger H as a fallback. It goes on `MED_3DDUCTBANK` with `MEDSetMedProperties` type `DUCTBANK`.

### 6.9 Section views
* **Trunk section:** spacers drawn from catalog geometry (2-way Snap-N-Stac pieces, or Snap-Loc base + intermediates with seats, reducers where used, strap on the top tier), conduits at OD sitting on their seat bottoms, POS/size/tag labels, hatched envelope, grade line, dimensions for W, H, each cover, C-C pitch H/V, seat bottom and depth to top, plus a callout with the spacer part and interval ("SP4W20-2 @ 8'-0\" O.C."). Title "SECTION X-X", with the cut marked on plan using the `c:sect` blocks.
* **Stub-up section** (at the end the user picked): cut on the trunk side of the first elbow. **No spacers** (note: "held by stub-up template"), conduits at **Sx** pitch and tier elevations, stub-zone W x H, plus a small stub-point grid dimensioned Sx x Sy from REF. Optional (Phase 2): a longitudinal elevation showing the staggered vertical elbows.
* Sections are built as a named block `DBSECT_<bank>_<letter>` on `MED_DBSECT`, with `DBANK_DATA ROLE=SECTION` so `DBEDIT` can rebuild them. They have no MED xdata, so they stay out of the BOM.

---

## 7. Integration

| Feature | Effect |
|---|---|
| BOM / BOMSS | Conduits are measured PVC footage. Elbows give 3 fitting rows each (plus a 0-qty conduit row in Option B). Spacer stations give one fitting row per piece. Stub risers are read from the symbol like today. No BOM code change, because `DBANK_DATA` is invisible to `xd_apps` |
| MEDLIST / MEDPROPERTIES / MEDRECORDS | Work unchanged on every member. Phase 2: MEDPROPERTIES shows a read-only "Ductbank DB-1, position A3" line (read `DBANK_DATA` in `MedPropertiesControl`) |
| CHGSIZE / MEDCHG on a member | Allowed, but the bank becomes stale. `DBCHECK` compares `MED_CONDUIT` size against the bank record and offers `DBEDIT` to regenerate (positions keep their tags) |
| MEDMAKE3D | Conduits and elbow segments already work: bulge arcs are kept, and coated OD comes from code 2. Required: the `med3d-tray-build` skip (§5.3). Phase 2: a new stage `(med3d-dbank-build)` in `med3d-make3d-all` via `med3d-stage` for envelopes, stub risers (today's `medcb-vert-leg` only builds risers off conduit-body inserts) and optional spacer solids |
| Layers | New `_MEDDBANK` (`MED_DUCTBANK`), `_MEDDBSPACER`, `_MEDDBSECT`, `_MED3DDBANK`, each with a code default when missing from `med.spc` |
| Files | New `Support\MEDDuctbank.lsp` (loaded by `MEDCore` after `MED3DPath.lsp`; reuses `med3d-*` vector helpers), MED-DotNet `MedDuctbankForm.cs`, `MedDuctbankSeed.cs`, `MedDuctbankSpecForm.cs`; `Data\seed\ductbank_*.csv`; menu and ribbon buttons; `docs\ductbank.md`; tests `tests\med3dpath\test_ductbank.py` (frame, seats, zones, envelope, bend rules, through `lispmini.py`) |

---

## 8. Commands (proposed)

| Command | Does |
|---|---|
| `DUCTBANK` (alias `DBANK`) | Create a bank from a reference conduit (section 3) |
| `DBEDIT` | Pick any member, reopen the dialog with current data, regenerate (keeps tags and positions) |
| `DBSECT` | Add another trunk or stub-up section at a picked station |
| `DBTAG` | Place `contag` tags per conduit at the stub-ups, or a bank tag |
| `DBLIST` | List a bank (positions, tags, sizes, lengths, spacer counts) to the command line or CSV |
| `DBCHECK` | Validate spacing, cover, min size, radii and stale sizes; mark problems on `MED_3DFLAG` |
| `DBSPEC` | Edit spec profiles, bend rules, spacer catalog and bank types in MED.db (grid forms like MEDTYPE) |
| Later: `DBCABLE`, `DBFILL` | Assign cables to positions (`MED_CABLE`); fill report using cable OD in `MEDType.USER3` (already seeded) |

---

## 9. Phases

**Phase 1 (MVP):** `DUCTBANK` with reference conduit (plan, constant elevation); stub-up zone at A (B optional), straight transition, spacer-driven trunk using the Carlon seeds (Snap-N-Stac default, Snap-Loc alternate, S287F/S287J reducers, strap/rebar-holder accessories; one part per bank), stock-elbow bend style; Option B elbows with 3 records; stub risers with `VERT_DATA`; spacer stations + BOM; envelope from OD + cover; stub and trunk sections; tags; DB tables + seeds; reminder; `med3d-tray-build` skip; basic `DBEDIT`, `DBLIST`; geometry tests.

**Phase 2:** MEDMAKE3D ductbank stage (envelope, risers, spacer solids); Concentric bend style; `DBSPEC` editor and named-type library; manhole/handhole blocks and end bells; sloped trunks and vertical bends (3D polylines; tiers become inside/outside, same rules); `DBCHECK`; MEDPROPERTIES bank line; mixed spacer sizes within a row; more manufacturers' spacer data.

**Phase 3:** cables per position, cable fill report, bank junctions/tees, concrete quantity in the BOM, custom stub-up patterns (picked points or from an equipment block).

---

## 10. Open questions for Clint
1. **Labels:** row A = top and column 1 = left looking from the stub-up end? Should tiers be counted from the bottom for spacers?
2. **Trunk bend style default:** stock elbows with no spacers in the bend (my recommendation, since coated RGS elbows are stock radii), or concentric with spacers through the bend? For concentric, how should non-stock outer radii go in the BOM?
3. **Elbow representation:** is broken segment the default? Is the zero-qty PVC-coated conduit row on each elbow segment acceptable?
4. **Stub-up riser:** is the third record on the vertical elbow an adapter or a coupling? Is the riser above grade PVC-coated RGS footage? What's the default rise?
5. **Catalog:** OK to add codes 160-172 (coated elbows, PVC adapter, end bell, coupling), 521-571 (Carlon spacers and accessories) and the missing 89? Should PVC Sch 80 and EB/DB-120 duct be added as conduit types?
6. **Spacers:** Snap-N-Stac as the default family and 2" separation as the default part (SP4W20-2 for 4")? Is 8 ft the default interval (Carlon says 8-10 ft)? What first-spacer offset from each trunk end?
7. **Reducers (S287F / S287J):** do they center the small conduit in the seat or let it sit on the bottom? Which spacer sizes does each one fit?
8. **Odd column counts on 2-way Snap-N-Stac pieces:** trim the piece in the field, add a spare column, or widen the envelope to the piece end (5.50" in the worked example)?
9. **Catalog checks:** do we use seat bottom + OD/2 when Carlon's "bottom of trench to center" differs by 0.06-0.12"? Does the 5" OD of 5.500 vs 5.563 matter? Is this 2006 catalog still current?
10. **Accessory counts:** beaded straps per top-tier piece per station? Rebar holders for Snap-Loc: how many, and from what bank size up?
11. **Mixed piece sizes in one row** (e.g. 2" pieces beside 4" pieces): needed for the MVP, or Phase 2?
12. **Stub-up pattern:** is a rows x columns grid with Sx x Sy and the top row first enough for the MVP? Is the across pitch ever different per column (e.g. switchgear sections)?
13. **Concrete at the stub-up:** does the envelope wrap the elbows by cover, or stop at the elbow start?
14. **Transition:** default length and maximum taper angle? Straight or short bends by default?
15. **Depth:** set by grade + depth to top of concrete, or keep the routed polyline's elevation?
16. **Tags:** is `{BANK}-{POS}` the right default? Should tags go on plan at each stub-up, or only in the sections?
17. **Sections:** scale and placement (model space at what scale)? Generate both stub and trunk sections every time?
18. **Spacer stations:** OK to always create them (layer frozen when hidden) so BOM counts are right?
19. **3D:** sloped trunks and vertical bends in the MVP or Phase 2?
