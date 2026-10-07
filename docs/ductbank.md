# Ductbank (DUCTBANK)

`DUCTBANK` (`Support\MEDDuctbank.lsp`, loaded by MEDCore) turns one routed MED conduit, or a plain 3D polyline route, into a full encased ductbank. You get plan conduits for every position, plan elbows and stub-up elbows, risers, spacer stations, the concrete envelope with its stub-up turn-ups, sections 1-1 and 2-2, and BOM records for all of it. `DBEDIT` reopens a bank and rebuilds it in place. It can also build 3D envelope and spacer solids for `MEDMAKE3D`.

Design background: [design/ductbank-routing.md](design/ductbank-routing.md). Build notes: [design/ductbank-mvp-notes.md](design/ductbank-mvp-notes.md).

![DUCTBANK dialog](images/ductbank-dialog.png)

## Commands

| Command | What it does |
| --- | --- |
| `DUCTBANK` | Pick the reference (a MED conduit or a plain 3D polyline route), then the **Ductbank dialog** opens. Set tags and sizes, then click OK to generate. |
| `-DUCTBANK` | The same command at the command line (standard AutoCAD dash convention). `DUCTBANK` also falls back to this when `MED-DotNet.dll` is not loaded, or when there is no UI (accoreconsole). |
| `DBEDIT` | Pick any part of a bank. The dialog reopens with that bank's stored settings; **Rebuild** erases the old bank (2D and 3D) and regenerates it in place with the same bank ID. |
| `-DBEDIT` | The same at the command line (the `-DUCTBANK` prompts, then the Tag/Size/Type/Options loop). |
| `DBLIST` | Lists a bank: positions, tags, sizes, lengths, elbows, stations, stub-up material and angle per end, stub-up encasement, concrete at bends, route profile, reference route and 3D solid count. |
| `DBDELETE` | Erases a bank (including its 3D solids) and restores the reference route: a MED conduit gets its MED data back, a plain polyline goes back to its layer with no data. |
| `DBSEED` | Adds the ductbank catalog codes to `MEDType`. It is idempotent and only adds missing codes (`Data\seed\ductbank_medtype.csv`). |

## Workflow

1. Draw the route as a normal MED conduit (`CONDUIT`), or as a plain `3DPOLY` (an `LWPOLYLINE` or `LINE` at an elevation also works). Vertical legs at either end mean stub-ups. The trunk can change elevation: give the 3D polyline vertices their elevations (see [Route rises and elevation changes](#route-rises-and-elevation-changes)).
2. Run `DUCTBANK` and pick it. For a plain route (no MED data), set the reference conduit size and type (see [Plain 3D polyline reference](#plain-3d-polyline-reference)).
3. In the dialog, click each position card and set its **Tag**, **Size** and **Type**. **Size to all** and **Type to all** copy the current values to every position, and **Auto tags** re-applies the tag pattern (`{BANK}-{POS}`).
4. Click **Check** to re-run the solver and refresh the envelope and checks. Click **OK** to generate. OK is refused while any check shows an error (X).

The defaults handle everything else:

| Setting | Default |
| --- | --- |
| Spacer | Carlon Snap-N-Stac, 2" separation, part sized to the largest conduit |
| Spacer interval | 8 ft (first station 12" in) |
| Cover | 3" top and bottom, 2" sides |
| Stub-up pitch | 5.5" |
| Transition | 60" |
| Stub-up material | PVC-coated RGS |
| Stub-up angle | 90 at both ends (45 = 45 deg risers into BUB fittings) |
| Stub-up encasement | Auto (top of the elbow sweep) |
| Concrete at bends | Chamfer (straight faces, cover kept) |
| Route rises | Flex (no fitting) up to 5 deg over at least 120", stock vertical bends above that |
| 3D solids | On |

## Dialog layout

- **Left column:**
  - **Bank:** ID, rows, conduits per row (for example `4,4`), **Ref size / type** (enabled for a plain route only) and the reference info.
  - **Main trunk spacers:** family, separation, part (Auto or a catalog part), interval and first-station offset, plus the solved pitch and seat.
  - **Cover from conduit OD:** top, bottom, end, left, right, **Min gap** (minimum clear gap OD to OD, checks only) and **Bends** (Chamfer or Sweep, see [Concrete at bends](#concrete-at-bends-chamfer)).
  - **Stub-up zone:** End A / End B (Stubup / Open), the stub-up angle at each end (**90** or **45 BUB**) and their top elevations, **Stub pitch center to center** (across = column to column, along = row to row; the tooltips say the same), transition and stub straight, section end, **Risers + stub elbows** material (PVC-coated RGS or plain RGS), the **Tape wrap** box for plain RGS and **Encasement top EL** (Auto, Top or an elevation; the hint shows the elbow sweep top EL). `-DUCTBANK` asks *Stub-up pitch center to center across (column to column)* and *Stub-up pitch center to center along (row to row)*.
  - **Output:** 3D envelope and spacer solids, section scale, and **Pick section location** (otherwise the sections are placed automatically to the right of the bank).
- **Middle column:**
  - **Position grid:** one card per position, top row A first, columns left to right looking from the stub-up end. REF marks the reference position; the selected card is highlighted.
  - **Selected-position editor:** Tag, Size, Type, **Set as REF**, **Size to all**, **Type to all**, **Auto tags** and the tag pattern.
  - **Calc reminder:** MED does not calculate cable fill, ampacity derating, voltage drop, pulling tension or burial depth.
  - **Envelope (last check):** the route-rise flex setting (**flex up to (deg)** and **over at least (in)**), then trunk W x H, elevations, stub zone, stub-up angles, elbows, turn-up, concrete at bends, spacers, bank length and the **route profile** (one line per flat / slope segment and one per flex point or vertical bend, with its drawn and stock angle and radius). The box scrolls.
- **Right column:**
  - **Cheat image:** trunk or stub-up section with the envelope, the spacer pieces (green) and each conduit at its OD. The current conduit is gold. The stub-up section also shows the concrete turn-up beyond (light hatch, dashed outline, risers dashed) up to the encasement top.
  - **Checks:** X = error (blocks OK), ! = flag (review), i = note.

## Stub-up encasement (turn-up)

At each stub-up end, the concrete turns up around the stub elbows and risers. It is part of the bank, not a separate pour:

- **Encasement top EL** (dialog, Stub-up zone) or `-DUCTBANK` Options > ENcasement:
  - **Auto** (default): the top of the highest stub elbow sweep (the end of the R24 / R36 bend). For the 3" sample that is EL -18.5.
  - **Top**: the stub-up top EL (grade).
  - **an elevation**: any value up to the stub-up top EL. Higher values are clamped to the top EL. A value below the sweep top is accepted with a flag (the elbow tops are not encased). A value at or below the trunk top means no turn-up (flag).
- **3D:** the turn-up is modelled as a profile in the vertical plane of the end leg and extruded across the stub zone width. The profile runs from the end face (stub OD + end cover) back along the elbow sweep and up to the encasement top. Along the sweep the back face is a 45 deg **chamfer** on the chord of the cover arc (inner elbow radius minus riser OD/2 and end cover), or follows that arc with `_DBKBENDCONC` Sweep. It is unioned into the `3DMEDModel-Ductbank` envelope solid, so the bank still has one envelope solid. `MEDMAKE3D` exports it with the envelope.
- **Plan:** a closed outline on `MED_DBENVELOPE` at the turn-up top elevation, with the note `CONCRETE TURN-UP TO EL x`.
- **Section 1-1 (stub-up section):** a hidden-line outline of the turn-up beyond, the note `CONCRETE TURN-UP BEYOND, TOP EL x`, and the turn-up EL in the subtitle.
- **Stored:** `ENCH` (the setting) and `ENCZA` / `ENCZB` (the solved elevations) in the bank record. `DBEDIT` reuses them.

![Stub-up section with the turn-up](images/ductbank-dialog-turnup.png)

![3D export: turn-up at end A](images/ductbank-3d-turnup.png)

## Concrete at bends (chamfer)

Concrete is formed with straight faces, so by default (`_DBKBENDCONC` = `"Chamfer"`) the envelope is **chamfered** at every bend instead of swept:

- **Plan bends, outside:** one straight chamfer per bend, square to the bend bisector. It is tangent to the cover over the outermost elbow at mid-bend, measured to the elbow's own OD (PVC-coated RGS, slightly over the PVC OD). Everywhere else along the elbow the cover is larger.
- **Plan bends, inside:** a square (sharp) inside corner would cut into the inner elbows (about 3" short for the R24 3" bank), so the inside gets a chamfer too, on the chord of the cover arc. The chord is closer to the bend center than the arc, so it adds concrete and keeps the cover.
- **Mixed radii** (for example one 4" R36 among 3" R24): each chamfer is pushed out just far enough for every position's elbow (both tiers, its own radius and OD), so a larger-radius elbow that cuts inside its neighbours is still covered.
- **Stub-up turn-up:** the back face along the vertical elbow sweep is a 45 deg chamfer on the chord of the cover arc (see above). The outside of the vertical bend (end face down to the bottom) was already square.
- **3D:** the `3DMEDModel-Ductbank` envelope is the plan outline extruded, with the turn-ups unioned in, so the chamfers carry into the solid. It stays one solid.
- **Sections and notes:** unchanged. The sections cut the straight trunk and the stub zone, not the bends.
- **Sweep:** `_DBKBENDCONC "Sweep"`, the dialog **Bends** box or `-DUCTBANK` Options > Bends puts back the concentric arcs (the previous geometry). If another position's elbow would poke out of the swept arc (mixed radii), that side is chamfered instead and the command line says so.
- **Stored:** `BENDCONC` in the bank record. `DBEDIT` keeps the bank's setting; `DBLIST` shows it. Banks built before this option list as swept until they are rebuilt.

The tests measure the cover at the bends (see [Testing](#testing)). With the default 2" side and end covers:

- at the chamfer faces, to the coated elbow OD: 2.00" minimum
- over every plan elbow, to the position OD: 2.00" minimum
- stub elbows to the turn-up faces: 2.07" (3") / 2.14" (4")

The trunk sides and the stub zone are still sized on the position (PVC) OD, so the coated elbows and risers sit 0.04" (the coating) closer to the straight faces at their ends. That is unchanged from the previous version.

![Plan corner: chamfer (default) vs sweep](images/ductbank-plan-corner-chamfer.png)

![3D: chamfered plan bend](images/ductbank-3d-chamfer-bend.png)

![3D: chamfered stub-up turn-up](images/ductbank-3d-chamfer-turnup.png)

## 45 deg stub-ups into BUB fittings

A bank (usually a single row) can pop up into Mogul BUB fittings at grade instead of turning straight up:

- **Setting:** per end, dialog **Stub-up zone** (the combo next to End A / End B: 90 or 45 BUB), `-DUCTBANK` Options > ANgle (asks end A, then end B: 90 or 45), or `_DBKSTUBANGLE` (default for new banks, 90). Stored as `ANGA` / `ANGB` on the bank record; `DBEDIT` rebuilds with them.
- **Geometry:** each conduit leaves the trunk through a 45 deg stub elbow (same radius rule as the 90s) and rises on a 45 deg riser to the stub-up point at the top EL. The BUB is inserted there face up (Clint's rule: same insert point), rotated so its run points away from the bank.
- **MVP: the run ends at the BUB.** The far hub is left open, so you continue the run from it (a note in the checks says so). No continuation conduit is drawn.
- **BOM:** 45 deg stub elbows are PVC-coated RGS 163 / 164 / 165 (R24 / R36 / R48) or plain RGS 167 / 168 / 169. Each BUB is a MED_FITTING with code 94 (Mogul BUB), size = the conduit size. There is no Mogul BUB above 4": larger conduits get the 45 deg stub without a BUB, with a flag.
- **Block:** in full AutoCAD the `1bub` symbol (`1BUB.DWG` from the MED drawing folder) is used. In accoreconsole (no ObjectDBX) a stand-in block `DBK_BUB` is drawn instead. Both carry the same MED_FITTING and DBANK_DATA (`ROLE=BUB`).
- **Multi-row:** allowed. Checks flag 45 deg risers whose clear gap is under the minimum gap, and BUB bodies longer than the row pitch or wider than the stub pitch (they would collide).
- **Concrete:** the turn-up follows the 45: the end face is set so the 45 deg risers keep the end cover, the top is the top of the 45 deg elbow sweep (Auto), and the back face is chamfered on the 45 like the 90 deg turn-up. Cover is sized off the primary conduit OD (standing rule).
- **MEDMAKE3D:** the BUBs are modelled as Mogul BUB conduit bodies (MEDCBINS builder, `Conduit bodies: n block(s)`); the 45 deg risers and elbows as conduit and FITTING solids.

![3D: 45 deg stub-ups into BUB fittings](images/ductbank-3d-bub-stubup.png)

## Route rises and elevation changes

The trunk follows the elevation of the reference route (3D polyline vertex Z, or a MED conduit's 3D path). Each change of grade along the route is classified by its deflection angle:

- **Flex (no fitting):** a change of up to `_DBKFLEXMAX` (default **5 deg**) is taken in the flex of the PVC: the conduits run continuously on the slope, with no fitting. The change must be spread over at least `_DBKFLEXLEN` (default **120"**). If the flex radius that implies is tighter than `_DBKFLEXRMIN` x OD (default **160 x OD**), the check flags it.
- **Vertical bends:** a larger change gets vertical bends at the **nearest stock elbow angle** (11.25 / 22.5 / 30 / 45 / 90), at the same radius rule as plan bends (R24 to 3", R36 above), with the nested rule applied row over row. If the drawn angle differs from the stock angle by more than 0.05 deg, a flag reports the residual.
- **Why 5 deg over 120":** PVC electrical conduit (PW Eagle / Hultec TB-D4 data) can be field-flexed to a radius of about 160 x OD (pressure pipe is held to 200-250 x OD, Uni-Bell). A 5 deg change over 120" is a radius of about 1375", which is above 160 x OD for every size up to 6" (6.625" OD x 160 = 1060"). Couplings and bells are not deflected.
- **Plan bends** stay level: each plan bend gets a level landing (the elbow tangents plus about half the bank width + 6" either side). If the route slopes through a plan bend, the grade change is moved to the landing ends and a flag says so.
- **Everything follows the profile:** the conduits (3D polylines on the slope), the vertical elbows (`PART=VBEND<n>`, coated RGS codes 160-165 and 175-183 + adapters), the spacer stations (perpendicular to the run, also on slopes, and kept out of the vertical bends), the sections (cut-line EL), the concrete envelope (one solid: per-leg slabs, chamfered at each vertical bend, intersected with the plan outline) and the BOM.
- **Profile summary:** the dialog's Envelope box, `DBLIST` and the `-DUCTBANK` grid show it, for example `Route profile: 5 segment(s), 0 flex, 4 vertical bend(s), end B -6.00"`, then lines like `@30.0' bend 22.50 deg down -> 22.50 deg stock, R24`.
- **Stored:** `FLEXMAX`, `FLEXLEN`, `PROFILE` (LEVEL / GRADE), `DZB` (end B elevation change), `VBENDS`, `FLEXPTS` on the bank record. `DBEDIT` reads them back and rebuilds the profile from the (possibly edited) route on `MED_DBREF`.
- **Settings:** dialog Envelope box (**flex up to (deg)** / **over at least (in)**), `-DUCTBANK` Options > FLex.

New codes (added to `MEDType` and `Data\seed\ductbank_medtype.csv`; `DBSEED` adds them to other databases):

| Code | Description |
| --- | --- |
| 175 / 176 / 177 | PVC Coated RGS 30 Deg Elbow 24" / 36" / 48" Radius |
| 178 / 179 / 180 | PVC Coated RGS 22.5 Deg Elbow 24" / 36" / 48" Radius |
| 181 / 182 / 183 | PVC Coated RGS 11.25 Deg Elbow 24" / 36" / 48" Radius |

![Side elevation: step route with 22.5 and 45 deg vertical bends](images/ductbank-profile-step-side.png)

![Side elevation: 1.5 deg grade taken in the flex of the PVC](images/ductbank-profile-slope-side.png)

![Dialog: route profile in the Envelope box](images/ductbank-dialog-profile.png)

## Plain 3D polyline reference

The reference can be a plain `3DPOLY`, `LWPOLYLINE` (with elevation) or `LINE` that has no MED data:

- The dialog enables **Ref size / type** in the Bank box. `-DUCTBANK` asks *Reference conduit trade size* and *Reference conduit type code* first. The default is the last value used, otherwise `_DBKREFSIZE` (4") and `_DBKCONCODE` (3 = PVC).
- Changing the reference size / type also changes every position still at the old default (and the REF position).
- The route is moved to `MED_DBREF` and tagged `REFPLAIN=1`. `DBDELETE` puts it back on its original layer with no data.
- MED conduit references work as before (their size and type come from the MED data).

## DBEDIT (rebuild in place)

1. Run `DBEDIT` and pick any member of the bank (conduit, elbow, envelope, text, 3D solid...).
2. The dialog opens pre-filled from the bank record: rows and counts, REF position, tags, sizes, types, spacer separation and part, cover, interval, stub-up ends and top ELs, stub pitch, material and wrap, encasement, 3D option, tag pattern, section end and scale. The title shows *(DBEDIT: rebuild in place)*, the bank ID is read-only and OK reads **Rebuild**.
3. **Rebuild** erases every old member (plan entities, sections, notes, 3D envelope and spacer solids) and regenerates the bank from the reference route on `MED_DBREF` with the same bank ID. The sections are drawn at the same place.

Notes:

- If you edited the reference route on `MED_DBREF` (moved it, stretched a vertex), DBEDIT rebuilds on the edited route.
- `-DBEDIT` does the same at the command line.
- Your session settings (covers, interval and so on) are put back after DBEDIT. The bank's own settings only apply to that bank.
- Banks built before this version have no position records. DBEDIT reads their positions from the conduits' MED data, and the defaults for the new settings.

## Stub-up material and wrap

Risers and stub-up elbows default to **PVC-coated RGS**:

- conduit code 2
- elbows 160-162 (90 deg) and 163-165 (45 deg, also the 45 deg BUB stub-ups)
- adapter 170 to the encased PVC
- PVC-coated RGS coupling 173

For **plain RGS**, use the dialog or `-DUCTBANK` Options > STUbmaterial > Rgs. You get:

- conduit code 1
- RGS elbows 89/90/91/166 (90 deg) or 167-169 (45 deg, also the 45 deg BUB stub-ups)
- adapter 170
- coupling 8

The **Tape wrap** option (on by default) adds code 174, *Corrosion Protection Tape Wrap (Plain RGS Stub-Up)*, at each stub-up, puts a `WRAP` note at the stub and adds a flag to the checks.

Plan bends and vertical bends in the trunk are always PVC-coated RGS elbows (vertical: 160-165 and 175-183 by stock angle and radius).

## 3D model layer

When **3D envelope + spacer solids** is on (`_DBKMODEL3D 1`), DUCTBANK models:

- the concrete envelope as one solid, with the stub-up turn-ups unioned in
- each spacer station as one solid (pieces unioned, conduit seats subtracted)

They go on `3DMEDModel-Ductbank`. The layer is non-plotting, color 8. `MEDMAKE3D` picks them up automatically (see [3d.md](3d.md#3d-model-layers-3dmedmodel-)). `DBDELETE` erases them with the bank.

> 3D models are approximations for layout and coordination only and are not reproductions of manufacturer specifications. Verify all dimensions against manufacturer data.

## Settings (med.spc)

Every variable has a default in code. `med.spc` only overrides it.

| Variable | Default | Meaning |
| --- | --- | --- |
| `_DBKUSEDIALOG` | 1 | 0 makes `DUCTBANK` always use the command line |
| `_DBKENCASE` | `"Auto"` | Stub-up encasement top: `"Auto"` (top of the elbow sweep), `"Top"` (stub-up top EL) or an elevation |
| `_DBKREFSIZE` | 4.0 | Plain route reference: default reference conduit size (the last value used wins) |
| `_DBKSTUBANGLE` | 90 | Stub-up angle for new banks: 90, or 45 (45 deg risers into Mogul BUB fittings); per end in the dialog |
| `_DBKFLEXMAX` | 5.0 | Route rises: grade changes up to this angle (deg) are taken in the flex of the PVC (sloped run, no fitting) |
| `_DBKFLEXLEN` | 120.0 | ... spread over at least this run length (in); steeper or shorter changes get stock vertical bends |
| `_DBKFLEXRMIN` | 160.0 | Minimum field-flex radius in conduit ODs (PW Eagle / Hultec TB-D4); tighter flex is flagged |
| `_DBKBENDCONC` | `"Chamfer"` | Concrete at bends (plan bends and the stub-up turn-ups): `"Chamfer"` (straight faces sized for cover) or `"Sweep"` (follows the elbow arcs) |
| `_DBKRISERCODE` | 2 | Stub-up riser and elbow material: 2 = PVC-coated RGS, 1 = plain RGS |
| `_DBKSTUBWRAP` | 1 | Tape wrap (code 174) for plain RGS stub-ups |
| `_DBKMODEL3D` | 1 | Build 3D envelope and spacer solids |
| `_DBKSPTHICK` | 2.0 | Spacer solid thickness along the run (in) |
| `_MED3DMODELPREFIX` | `3DMEDModel-` | Layer prefix that MEDMAKE3D pulls into the 3D export |

## MEDMAKE3D and the bank

`MEDMAKE3D` turns the bank into 3D as follows:

- **Plan runs and risers:** conduit solids (risers at the stub-up material OD).
- **Elbows:** each broken-segment elbow (plan, vertical and stub-up, 90 or 45 deg) becomes a swept solid at its radius, stamped as a FITTING with its elbow description.
- **BUB fittings (45 deg stub-ups):** Mogul BUB conduit bodies, counted under `Conduit bodies:`. The spacer stations are still skipped there (they are BOM carriers, modelled on the 3D model layer).
- **Envelope (with the stub-up turn-ups) and spacer solids:** copied from the `3DMEDModel-` layers.

The summary shows `Ductbank elbow:` and `3D model layer:` lines.

## Testing

`tests\autocad\MEDDuctbankTest.ps1` runs headless (accoreconsole) on a copy of `Samples\ConduitDuctbankStart.dwg`:

| Switch | What it adds |
| --- | --- |
| (none) | 3" bank as drawn, default encasement (turn-up to EL -18.5 at both ends), concrete at bends Chamfer |
| `-Size 4` | 4" variant, then `DBDELETE` |
| `-Rgs` | plain RGS stub-ups, wrapped |
| `-Enc -30` / `-Enc Top` | custom encasement top |
| `-Plain` | reference = plain 3DPOLY made from the sample reference's vertices (size 3, type 3) |
| `-Edit` | after the checks: moves the `MED_DBREF` route 12" east, `-DBEDIT` retags A1 to MV-101 and sets B2 to 4", then checks counts, handles, orphans, duplicate solids, the edited route and the cover at the bends again (mixed R24 / R36) |
| `-Sweep` | Options > Bends > Sweep (the old swept concrete) |
| `-Route Bub` | 1x4 bank on the sample, end B 45 deg BUB stub-ups: BUB count, size, code 94 and place; 45 deg stub elbows (163); risers end at the BUB; flags; BOM |
| `-Route Bub2` | the 2x4 sample with end B 45 deg BUB: the riser-gap and BUB-collision flags |
| `-Route Slope` | plain 3DPOLY with a 1.5 deg grade over 120 ft (flex 4 deg / 120"): 2 flex points, no vertical fittings, 29 stations, slab cover |
| `-Route Step` | plain 3DPOLY with a 30" drop over 6 ft and a 24" rise over 2 ft: 4 vertical bends (22.5, 22.5, 45, 45, R24), codes 178 / 163, path continuity, spacers outside the bends, slab cover |
| `-Route ... -Edit` | the route tests followed by `-DBEDIT` (retag A1 to MV-101): the profile, angles and flex setting survive the rebuild |

Every run also checks the concrete at the bends:

- the plan outline has no arcs (Chamfer) or has the swept arcs (Sweep)
- `BENDCONC` is stored on the bank record
- plan elbows: the minimum distance from the elbow OD to the envelope face is at least the side cover (49 samples per elbow)
- the outside chamfer: the same, to the coated elbow OD
- stub elbows: the minimum distance to the turn-up faces is at least the end cover (45 deg ends: elbows and risers, primary OD)
- route tests: conduit and vertical elbow OD to the top and bottom of the concrete along the whole profile is at least the top / bottom cover
