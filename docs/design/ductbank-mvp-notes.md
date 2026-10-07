# Ductbank routing: build notes (MVP2 + MVP3, 2026-10-06)

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
- ~~The trunk is flat (constant elevation).~~ Removed in MVP4: the trunk follows the route profile (see below). DBEDIT exists since MVP3. There is no DBSECT, DBCHECK or DBSPEC yet. There are no spec profiles or bank types.
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

## MVP3 (2026-10-06): stub-up encasement, plain route reference, DBEDIT

- **Stub-up encasement.** Setting `ENCH` (Auto | Top | elevation; `_DBKENCASE`, code default `"Auto"`). dbk-solve computes `SWEEPTOP` = max(ZC + RV) and `ENCZA` / `ENCZB` per stub-up end (clamped to the top EL, with flags below the sweep top or at/below the trunk top). The turn-up is drawn by `dbk-tu-solid` (MEDDuctbank p9): a profile in the vertical plane of the end leg runs from the end face (min ALONG - maxOD/2 - end cover) up to the encasement top and back down along the inner elbow arc (radius RV - OD/2 - cover) to about 1" below the trunk top. It is extruded across LSA..RSA and UNIONed into the ENV3D solid (`TURNUPS=n`, `ENCZA/ENCZB` on the solid). Plan: `ROLE=TURNUP` outline on MED_DBENVELOPE plus a `NOTE=TURNUP` text. Section 1-1: hidden outline + note.
- **Plain route.** `dbk-setup-ref` accepts LWPOLYLINE / POLYLINE / LINE with no MED_CONDUIT. The size / type come from the dialog (Ref size / type, `REFSIZE` / `REFCODE` in the spec) or two prompts in `-DUCTBANK` (default last used / `_DBKREFSIZE` 4" / `_DBKCONCODE`). The reference goes to MED_DBREF with `REFPLAIN=1` and no MED_CONDUIT. DBDELETE strips DBANK_DATA only.
- **Bank record.** The envelope DBANK_DATA now also holds COVE SPEND STUBSTR SEP SECTSCALE TAGPAT TOPA TOPB WRAPSET M3DON SECTX SECTY ENCH ENCZA ENCZB SWEEPTOP REFPLAIN and one `P=pos|tag|size|code|C/D` per position.
- **DBEDIT / -DBEDIT.** `dbk-edit-load` reads the bank record and the reference route. It applies the stored globals (and restores the session ones afterwards), sets `*DBK-EDITING*` (bank ID kept, no collision error, spec `MODE=EDIT`), and runs the dialog loop or the text flow. `dbk-commit` erases every old member except the REF and calls `dbk-build` with the stored section point. Banks without `P=` records fall back to the conduits' MED_CONDUIT data.
- **Dialog.** 1240x864. New controls: Ref size / type (plain only), Encasement top EL (editable combo) with a hint showing the sweep EL, a stub-section turn-up preview, `VIEW=STUB`, and `MODE=EDIT` (title, read-only bank ID, **Rebuild**). New spec keys: MODE REFPLAIN REFTYPE REFSIZE REFCODE ENCH BOTZ TOPZ SWEEPTOPZ ENCZA ENCZB.
- **Tests (accoreconsole, sample copies):** default (26/26), `-Enc -30` (26/26), `-Enc Top` (26/26), `-Plain` (27/27), `-Edit` (40/40), `-Plain -Edit` (41/41), `-Size 4` + DBDELETE (24/24), `-Rgs` (26/26), `-Plain -Size 4` + DBDELETE (25/25). MEDMAKE3D (scripted AutoCAD) on the default and Top results: 61 solids each (RUN 16, RISER 16, ELBOW 24, SPACER 4, ENVELOPE 1); envelope bbox top Z -18.5 (Auto) and 0.0 (Top). Live AutoCAD: DUCTBANK dialog OK, then DBEDIT dialog Rebuild: 170 bank entities / 5 model solids / 188 drawing entities before and after.

## Chamfered concrete at bends (2026-10-06)

- **Setting.** `_DBKBENDCONC` ("Chamfer" | "Sweep", code default "Chamfer", med.spc comment line). Stored as `BENDCONC=` on the envelope record, in `*DBK-EDIT-GLOBALS*` (DBEDIT keeps the bank's value and restores the session one), spec key `BENDCONC`, `-DUCTBANK` Options > Bends, dialog Cover box **Bends** combo. DBLIST, the print grid and the dialog envelope summary show it.
- **Plan (p5 `dbk-bend-cut`).** Per side of each corner: a face square to the bisector, m = unit miter x sign(ext - RELT(gov)). Every position's elbow (CRN radius and tangent points, center = tin - normIn x turnSign x r, 32 samples, both tiers) is offset by (elbow OD)/2 + side cover. The elbow OD is the PVC-coated RGS OD (`dbk-od 2`). The face goes at the max of (point . m). Outside: the convex corner is cut when that max is short of the sharp corner (tangent at mid-bend for equal radii). Inside: the reflex corner is filled out to the max when the cover points reach past it (the chord through the cover-arc ends for equal radii). The sharp corner is kept when it already covers everything.
- **Sweep.** The governing arc as before. `dbk-bend-poke` checks every position's cover points against that arc (in the sector). If one pokes out (mixed radii: the sample with B2 = 4" R36 poked 3" out of the inside arc in 6b0a15e), that side uses `dbk-bend-cut` and a "Note: Bend n inside/outside ..." line is printed.
- **Turn-up (p9).** `dbk-tu-od` = max(position OD, stub material OD). The back edge on [cz - rr, cz] is the 45 deg chord `s = cx - rr + (cz - z)` (Chamfer) or the arc (Sweep), with rr = RV - stubOD/2 - end cover. The riser back is at ALONG + stubOD/2 + end cover. Key z values are cz and cz - rr.
- **Wording.** Dialog: "Stub pitch center to center (in)" with **across** / **along** boxes on their own row and tooltips (column to column / row to row). The Cover box row 3 now holds Min gap + Bends. ClientSize is 1240x890. Prompts: "Stub-up pitch center to center across (column to column)" / "... along (row to row)". The flag reads "Stub-up pitch (center to center across)". The help text is updated.
- **Tests.** `dbkt-bend-cover`:
  - outline arcs (none for Chamfer)
  - BENDCONC stored
  - plan elbows (49 samples each): distance to the outline minus the position OD/2 is at least the side cover
  - outside chamfer faces: the same with the coated elbow OD
  - stub elbows in the turn-up (s, z) frame: distance to the back edge above the trunk top plus the trunk-top ray, minus the elbow OD/2, is at least min(end, top) cover

  It runs again after the `-Edit` rebuild (mixed R24 / R36). New switch `-Sweep`.

  Results:

  | Run | Passed |
  | --- | --- |
  | default, `-Enc -30`, `-Enc Top`, `-Rgs` | 31/31 |
  | `-Plain` | 32/32 |
  | `-Edit` | 50/50 |
  | `-Plain -Edit` | 51/51 |
  | `-Size 4` | 29/29 |
  | `-Plain -Size 4` | 30/30 |
  | `-Sweep` | 30/30 |
  | `-Sweep -Edit` | 48/48 |

  Minimum cover (side and end covers 2"):

  - plan elbows and chamfer faces: 2.000
  - turn-up: 2.068 (3"), 2.140 (4"), 2.160 (mixed)

  MEDMAKE3D on the default result: 61 solids (RUN 16, RISER 16, ELBOW 24, SPACER 4, ENVELOPE 1), envelope volume 198890.6 in3 (one solid).

## MVP4 (2026-10-07): 45 deg BUB stub-ups, route rises

Clint: "I am unable to do a stub up at 45 degrees. Often times a duct bank (single level) could pop up into BUB fittings and then continue on. We should be able to adapt to a rise on the duct bank. Sometimes there may be elevation changes that can be compensated over distance in just the flex of the conduit and not a hard bend."

- **Stub-up angle (per end).** `ANGA` / `ANGB` (90 | 45) in `*DBK*`, the bank record and the spec; `_DBKSTUBANGLE` (code default 90) for new banks. `-DUCTBANK` Options > ANgle; dialog combos next to End A / End B. `dbk-stub-se` gives each position's stub elbow start/end for the angle, `dbk-stub-elbow-code` the 45 codes (coated 163-165, RGS 167-169), `dbk-stub-sweep` the 45 sweep top ZC + RV (1 - cos 45).
- **BUB (p11).** At a 45 end every conduit up to 4" gets `dbk-bub-insert`: MED_DBSTUB layer, insert point = the stub-up point at the top EL, face up, rotated outward along the end leg, MED_FITTING code 94 + DBANK_DATA `ROLE=BUB END= XF= HUB=RUN2`. The riser ends at the BUB hub face (insert point - XF along the leg; XF from `medcb-hubs` "MOG" "BUB", else the table formula). Block: existing `1bub` definition, else ObjectDBX copy of `1BUB.DWG` (full AutoCAD), else a stand-in `DBK_BUB` (accoreconsole cannot ObjectDBX or -INSERT a file from a script-run LISP). **MVP:** the run ends at the BUB; the far hub is left open (info line in the checks).
- **BUB checks.** Rows > 1: 45 deg riser clear gap (sy / sqrt 2 - OD) against the minimum gap; BUB length a > row pitch; BUB width c > stub pitch; > 4" no BUB.
- **Turn-up at a 45 end (p9).** `dbk-tu-set` per end (`*DBK-TUEND*`, `*DBK-TUDZ*`, `*DBK-TUZ*`); `dbk-tu-face` puts the end face at the minimum outer cover over the 45 risers at the encasement top; `dbk-tu-outer45` / `dbk-tu-inner45` / `dbk-tu-back` give the 45 chamfered back. Cover uses the primary (position) OD (standing rule, Oct 7).
- **Route profile (p10).** `dbk-ref-geom` returns the profile ((s z) ...) projected on the plan route (the flat-trunk error is gone). `dbk-prof-clean` merges collinear points, `dbk-prof-land` holds a level landing through each plan bend (flag when it moves grade), `dbk-prof-vertices` lists the grade changes, and `dbk-profile-solve` classifies each: deflection <= `_DBKFLEXMAX` -> FLEX (needs `_DBKFLEXLEN` of run, radius checked against `_DBKFLEXRMIN` x OD), else BEND at `dbk-stock-angle` (nearest of 11.25 / 22.5 / 30 / 45 / 90, residual > 0.05 deg flagged, > 80 deg error). Radii per bend and column by the nested rule (sorted by ZC). Fit checks against the route ends, stub zones, transitions and plan bends. `*DBK-PV*` holds the profile, `VX` the vertices, `VBZ` the vertical-bend zones.
- **Generation (p5 / p11).** Conduit paths are built from the plan vertices plus the profile nodes (`dbk-prof-nodes`): `dbk-mk-run` draws an LWPOLYLINE when level, else a 3D polyline. Vertical elbows `PART=VBEND<k>` (RAD, drawn ANG, STOCK, DIR, OD, MAT=2) with `dbk-elbow-code stock R` (160-165, 175-183) + 2 adapters. Spacer stations: inserted at BOT + dz(station), kept out of VBZ, tilted to the run (`dbk-ocs-pts2`). Sections: cut-line EL and CL/TOP texts include dz.
- **Envelope (p7).** Level routes keep the extruded plan outline. Graded routes: `dbk-env-profile` builds one slab per profile leg (clipped at the vertical-bend chamfers `dbk-vbend-cut` / `dbk-vb-outside`), UNIONs them and INTERSECTs with the plan prism: one solid, chamfered at vertical bends.
- **Record / spec.** Envelope DBANK_DATA adds ANGA ANGB FLEXMAX FLEXLEN PROFILE (LEVEL / GRADE) DZB VBENDS FLEXPTS BUBS. Spec out: ANGA ANGB FLEXMAX FLEXLEN FLEXRMIN DZB and `PROF=` lines (summary). Spec in: ANGA / ANGB, FLEXMAX (0-10), FLEXLEN (>= 1). `*DBK-EDIT-GLOBALS*` adds `_DBKFLEXMAX` `_DBKFLEXLEN`.
- **Dialog.** Stub-up zone: End A / End B rows now hold the end combo, the angle combo (90 / 45 BUB) and the top EL. Envelope box: flex deg / length boxes on top; the summary is a scrolling read-only text box and lists the `PROF=` lines. The Auto encasement hint uses the 45 sweep and DZB at end B. Validation: flex 0-10 deg, length >= 1.
- **MED3DFittings.** `medcb-collect` skipped every INSERT with DBANK_DATA; now `medcb-dbk-skip-p` skips only non-BUB ones (spacer stations), so the BUBs are modelled as Mogul BUB conduit bodies.
- **MEDType.** Backup `dbo.MEDType_bak_20261007_0824` (1151 rows) and `%TEMP%\dbk\MEDType_bak_20261007_0824.csv`; inserted FITTING 175-183 (PVC Coated RGS 30 / 22.5 / 11.25 Deg Elbow 24" / 36" / 48" Radius); same rows in `Data\seed\ductbank_medtype.csv`. 1160 rows after.
- **med.spc.** `_DBKSTUBANGLE 90`, `_DBKFLEXMAX 5.0`, `_DBKFLEXLEN 120.0`, `_DBKFLEXRMIN 160.0` (all also have code defaults).
- **Flex default.** PVC electrical conduit minimum field-bend radius 160 x OD (PW Eagle / Hultec TB-D4 tables; pressure 200 x OD, C900 250 x OD; Uni-Bell 250 x OD rule of thumb; gasketed joints max about 2 deg, so the flex is in the pipe, not the joints). 5 deg over 120" = R about 1375" >= 160 x 6.625" (6") = 1060".
- **Tests (accoreconsole, sample copies).** Existing: default / `-Enc -30` / `-Enc Top` / `-Rgs` 31/31, `-Plain` 32/32, `-Edit` 50/50, `-Plain -Edit` 51/51, `-Size 4` 29/29, `-Plain -Size 4` 30/30, `-Sweep` 30/30, `-Sweep -Edit` 48/48. New (`-Route`, `DBKTPROF`): Bub 42/42, Bub2 43/43, Slope 42/42, Step 39/39; with `-Edit` (DBEDIT round trip) Bub 72/72, Bub2 74/74, Slope 71/71, Step 65/65. Profile cover min 3.000 (Slope, Step); turn-up cover at 45 ends min 2.068.
- **MEDMAKE3D (scripted AutoCAD 2024).** Bub: 33 solids (RUN 8, 45 deg risers 4, end A risers 4, ELBOW 12, SPACER 4, ENVELOPE 1) + 4 Mogul BUB conduit-body blocks (`Conduit bodies: 4 block(s)`). Step: 122 solids (RISER 16, RUN 24, sloped 16, ELBOW 48 = 16 stub + 32 vertical, SPACER 17, ENVELOPE 1). Slope: 86 solids (RISER 16, RUN 8, sloped 8, ELBOW 24, SPACER 29, ENVELOPE 1). The 3D notice printed each time.
- **Open points for Clint:** BUB MVP (ends at the BUB, no continuation run); MED3D models the BUB hubs horizontal (the 45 deg riser meets a horizontal hub); level landings at plan bends; non-stock residual angles are drawn as routed with the stock code; codes 175-183 are new; the 45 deg coated codes are 163-165 (161 is the coated 90 R36); the existing coated-OD chamfer / turn-up sizing (18af174) is kept, the new code uses the primary OD.
