# Conduit body orientation matrix (MEDMAKE3D)

This page lists every 2D conduit-fitting symbol the MED menus can place, the fitting codes it can carry, and what MEDMAKE3D (MED3DPath r11 / MED3DFittings r5) does with each. The same rows are in `tests\med3dpath\fitting_matrix.csv`: the desk test `tests\med3dpath\test_fitting_matrix.py` rebuilds each row and checks the `cur_*` columns, and `MEDCBGRID` (`tests\autocad\MEDCBGrid.lsp`) draws them all in a drawing.

**Principle:**
1. The fitting code picks the body (`MEDType.ITEMKEY2`, else the description).
2. The symbol says where the body lies: along its long leg (+X, the conduit picked), with the other hub toward its short leg / up / down mark.
3. The conduit legs at the insertion point confirm or correct it (snap); the drawn rotation breaks ties.

## Decisions (Clint)

After 95524a2:
- **Mirrored symbols are not accommodated.** A `MED_FITTING` conduit body whose plan symbol is mirrored (X scale × Y scale × extrusion Z < 0) gets no 3D body; the conduit is left as drawn; one marker `MIRRORED FITTING - re-insert, do not mirror` on `MED_3DFLAG`, a Skipped line and the summary line `Mirrored fittings: N (bad practice - re-insert without mirroring)`. MED's menus never insert fittings with a negative scale, so any mirrored one is a user MIRROR. M39 / M40 stay only as the mirror-error test cells.
- **Flat-turn LB (Q1).** An LB used as a flat plan turn lies on its side along the symbol's long leg, back hub on the other leg, cover sideways away from it (M01, M02).

From the grid review at DIMSCALE 48 (applied in r5 / r11):
- **LL / LR were swapped** in the 3D blocks. Now, with the cover up and the RUN (end) hub at +X, an **LL's side hub is at +Y and an LR's at -Y** (side hub up, looking into the end hub: cover on the left = LL). This replaces the earlier "cover always up" (Q2 option A): the body always lies along the symbol's long leg, and the cover faces **down** when the code and the symbol need it: LR on `1lbl` opens on the bottom (M04), LL on `1lbr` opens down (M06). LL / LR blocks made before r5 are renamed `<name>_PRE_R5` the first time MEDMAKE3D needs the name, and rebuilt.
- **TB on a flat tee (M12):** back hub tilted into the plan toward the branch, opening on the side opposite the joining leg.
- **LB with one leg drawn (M32):** still on its side (opening sideways, toward the symbol's side), not face up.
- **LBD / LBY / Mogul BLB** use LB logic (M21 - M23, M31): on `1lbdl` / `1lbdr` / `1lby` / `1lbl` they lie on their side like the LB. They are still placeholders until their builders exist (phase 2).
- **Vertical conduit** from the fitting's own xdata (M07 - M09, M13 - M16): the menu stores the up / down conduit on the insert (`MED_CONDUIT` distance + `VERT_DATA` direction). MEDMAKE3D now builds it as a solid from the face of the hub pointing that way to insertion Z ± distance (flagged when no hub points that way).
- **Q5:** legs are searched out to the `medblck.dat` break × insert scale + 0.25", so up symbols at DIMSCALE 48 find their conduit; it is trimmed or extended to the hub face.
- **LB up / down, tee up / down, T, C** look good (Q3, Q4 kept).
- **M10** (LL code on the LB-down symbol `1lbd`) was a made-up MEDCHG case, and `1lbd` is the LB-**down** symbol, not an LBD. Removed; the LBD is code 39 on `1lbdl` / `1lbdr` (M21, M22).
- **M17 `2teed`:** only the image menu's "T-down to Tee" entry (`med.mnu` line 1205 / `med.mns`) uses it; the ribbon and the CUIX don't, and `Dwg\2teed.dwg` doesn't exist, so the entry inserts nothing. Removed from the matrix; the menu entry is left alone (Clint: likely not a valid block - fix or drop the entry in the menus when convenient).
- **M30 TA** (code 17, Form 7 "TA", only reachable by MEDCHG): "simply a Tee fitting" - TA is now modelled as a T with the T dimensions (a note is printed), and the row is dropped as a duplicate of M11.

## How to read the table

- **Coordinates** are the 2D symbol's own axes (block at rotation 0, insertion point at 0,0). +X is the conduit that was picked when the symbol was inserted. The table holds for any drawn rotation; the test checks rotations 0 and 90.
- **Legs:** `+X +Y`: horizontal conduits leaving the fitting in those directions. `PASSX`: one conduit running straight through along X. `UP` / `DN`: the vertical conduit stored on the fitting insert (`MED_CONDUIT` + `VERT_DATA`, 36" in the test).
- **Expected / Now:** which way each hub and the cover face (`RUN+X` = RUN hub toward +X; `RUNS:X` = both run hubs on X; `COVER+Z` = cover up, `COVER-Z` = cover down); `cuts` = conduit ends trimmed / extended to a hub face; `flags` = markers on `MED_3DFLAG`; `vert` = vertical conduit solids. `PH ...` = placeholder (no 3D data yet; its orientation follows); `MIRROR` = mirrored symbol; `NM` = not a conduit body; `*` = don't care.
- **DIMSCALE.** The menu breaks the conduit back from some symbols by the `Support\medblck.dat` distance × DIMSCALE. The table shows the result at DIMSCALE 1 and 48.

## What the 2D symbols show (from the DWGs in `Dwg\`)

The symbols are hub ticks: short bars across the conduit where a hub is.
- `1lbl`: ticks at +X (0.187) and +Y (0.093). The body is drawn along +X, with the side / back opening at +Y.
- `1lbr`: the mirror, with the opening at -Y.
- `1lbd` / `1lbu` / `1lbuo`: a tick at +X plus a down arc / filled dot / open circle at the insertion point.
- `1tee`: ticks at ±Y (main) and +X (branch).
- `1teed` / `1teeu` / `1teeuo`: ticks at ±X (main) plus the down / up mark.
- `1cee`: ticks at ±X. `1exs`: ticks on all four sides.
- `1lbdl` / `1lbdr` / `1lby`: like `1lbl` / `1lbr`, plus a diagonal.
- GUA symbols: a circle with tabs on the hub sides.
- `2teed`: **the DWG is missing**.

`medblck.dat` (insert rotation rule / breaks):

| Block | Rotation rule | Breaks d1..d4 (block +X, +Y, -X, -Y, × DIMSCALE) |
| --- | --- | --- |
| 1lbl, 1lbdl, 1lby | 22: +X = picked conduit, other leg at +Y | 0 |
| 1lbr, 1lbdr | 24: +X = picked conduit, other leg at -Y | 0 |
| 1lbd | 0: +X toward the conduit | 0, 0.0527, 0.0527, 0.0527 (no conduit there) |
| 1lbu | 0 | 0.0527 all four |
| 1lbuo | 1 | 0.046875 all four |
| 1tee | 3: +X = branch | 0 |
| 1teed, 1cee, 1exs | 1: +X along the conduit | 0 |
| 1teeu | 1 | 0.0527 all four |
| 1teeuo | 1 | 0.046875 all four |
| 2teed | 4: user rotation | 0, 0.0527, 0, 0.0527 |
| 1gual / 1guat / 1guax | 22 / 3 / 1 | 0.0875 on the hub sides |

## Matrix

| Row | 2D block | Code (alt) | Body | Legs | Expected | Now at DIMSCALE 1 | Now at DIMSCALE 48 | Note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M01 | `1lbl` | 30 (31 32) | LB | +X +Y | BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | Q1 decided |
| M02 | `1lbr` | 30 (31 32) | LB | +X -Y | BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | Q1 decided |
| M03 | `1lbl` | 33 (34 35) | LL | +X +Y | BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M04 | `1lbl` | 36 (37 38) | LR | +X +Y | BRANCH+Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M05 | `1lbr` | 36 (37 38) | LR | +X -Y | BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M06 | `1lbr` | 33 (34 35) | LL | +X -Y | BRANCH-Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Y COVER-Z RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M07 | `1lbd` | 30 (31 32) | LB | +X DN | BACK-Z COVER+Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0, vert 1 | Q3 |
| M08 | `1lbu` | 30 (31 32) | LB | +X UP | BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | Q3 Q5 |
| M09 | `1lbuo` | 30 (31 32) | LB | +X UP | BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0, vert 1 | Q3 Q5 |
| M11 | `1tee` | 11 (12 13) | T | PASSY +X | BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 |  |
| M12 | `1tee` | 14 (15 16) | TB | PASSY +X | BACK+X COVER-X RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BACK+X COVER-X RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BACK+X COVER-X RUNS:Y, cuts 1, flags 0, vert 0 | Clint r5 |
| M13 | `1teed` | 11 (12 13) | TB | PASSX DN | BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 | Q4 |
| M14 | `1teed` | 14 (15 16) | TB | PASSX DN | BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0, vert 1 |  |
| M15 | `1teeu` | 11 (12 13) | TB | PASSX UP | BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | Q4 Q5 |
| M16 | `1teeuo` | 11 (12 13) | TB | PASSX UP | BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0, vert 1 | Q4 Q5 |
| M18 | `1cee` | 50 (51 52) | C | PASSX | COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 |  |
| M19 | `1cee` | 50 (51 52) | C | -X +X | COVER+Z RUNS:X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0, vert 0 |  |
| M20 | `1exs` | 80 (81 82) | X | PASSX PASSY | PH*, cuts *, flags 1+, vert 0 | ✓ PH BRANCH+Y BRANCH2-Y COVER+Z RUN+X RUN2-X, cuts 0, flags 1, vert 0 | ✓ PH BRANCH+Y BRANCH2-Y COVER+Z RUN+X RUN2-X, cuts 0, flags 1, vert 0 | Q9 |
| M21 | `1lbdl` | 39 | LBD | +X +Y | PH BACK+Y COVER-Y RUN+X, cuts *, flags 1+, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | Clint r5 |
| M22 | `1lbdr` | 39 | LBD | +X -Y | PH BACK-Y COVER+Y RUN+X, cuts *, flags 1+, vert 0 | ✓ PH BACK-Y COVER+Y RUN+X, cuts 2, flags 1, vert 0 | ✓ PH BACK-Y COVER+Y RUN+X, cuts 2, flags 1, vert 0 | Clint r5 |
| M23 | `1lby` | 41 | LBY | +X +Y | PH BACK+Y COVER-Y RUN+X, cuts *, flags 1+, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | Clint r5 |
| M24 | `1gual` | 141 | GUAL | +X +Y | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 1, flags 2, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 1, flags 2, vert 0 | Q9 |
| M25 | `1guat` | 142 | GUAT | +X +Y -Y | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+Y RUN2-Y, cuts 2, flags 2, vert 0 | ✓ PH COVER+Z RUN+Y RUN2-Y, cuts 2, flags 2, vert 0 | Q9 |
| M26 | `1guax` | 143 | GUAX | PASSX PASSY | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 2, flags 3, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 2, flags 3, vert 0 | Q9 |
| M27 | `1gualsid` | 141 | GUAL | +X | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 1, flags 1, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 1, flags 1, vert 0 | Q9 |
| M28 | `1guatsid` | 142 | GUAT | PASSX | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 2, flags 1, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 2, flags 1, vert 0 | Q9 |
| M29 | `1bub` | 94 | BUB (Mogul) | PASSX | PH*, cuts *, flags 1+, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 0, flags 1, vert 0 | ✓ PH COVER+Z RUN+X RUN2-X, cuts 0, flags 1, vert 0 | Q9 |
| M31 | `1lbl` | 40 | BLB (Mogul) | +X +Y | PH BACK+Y COVER-Y RUN+X, cuts *, flags 1+, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | ✓ PH BACK+Y COVER-Y RUN+X, cuts 2, flags 1, vert 0 | Clint r5 |
| M32 | `1lbl` | 30 (31 32) | LB | +X | BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | Clint r5 |
| M33 | `1union` | 72 | - | PASSX | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M34 | `1seal` | 61 | - | PASSX | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M35 | `1sealdr` | 64 | - | PASSX | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M36 | `1cap` | 100 (101) | - | +X | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M37 | `1hub` | 120 | - | +X | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M38 | `1re` | 103 | - | PASSX | NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 | ✓ NM, cuts 0, flags 0, vert 0 |  |
| M39 | `1lbl` | 30 (31 32 33 34 35 36 37 38) | none | -X +Y, **mirrored** (X scale -1) | MIRROR, cuts 0, flags 1, vert 0 | ✓ MIRROR, cuts 0, flags 1, vert 0 | ✓ MIRROR, cuts 0, flags 1, vert 0 | decided |
| M40 | `1tee` | 11 (12 13 14 15 16) | none | PASSY +X, **mirrored** (Y scale -1) | MIRROR, cuts 0, flags 1, vert 0 | ✓ MIRROR, cuts 0, flags 1, vert 0 | ✓ MIRROR, cuts 0, flags 1, vert 0 | decided |

### Where each row comes from

| Row | Menu / how it gets there | Insert type | Notes |
| --- | --- | --- | --- |
| M01 | Fittings>Lbl; ribbon LB Fitting (CON_LB1); image menu LB Fitting | 2 | flat plan turn: LB on its side along the symbol's long leg (+X), cover sideways away from the +Y leg |
| M02 | Fittings>Lbr; ribbon LB Fitting (CON_LB2); image menu LB Fitting | 2 | flat plan turn: LB on its side along the long leg (+X), cover sideways away from the -Y leg |
| M03 | ribbon LL Fitting (CON_LL) | 2 | LL on 1lbl: body along the long leg, side hub +Y, cover up (r4 had LL/LR swapped) |
| M04 | code changed to LR (MEDCHG) | 2 | LR on 1lbl: body along the long leg, turned over - opening on the bottom (Clint) |
| M05 | ribbon LR Fitting (CON_LR) | 2 | LR on 1lbr: body along the long leg, side hub -Y, cover up |
| M06 | code changed to LL (MEDCHG) | 2 | LL on 1lbr: body along the long leg, turned over - opening down (Clint) |
| M07 | Fittings>Lb-down; ribbon LB Fitting Down; image menu Lb down | 3 | vertical conduit (VERT_DATA + MED_CONDUIT distance on the insert) built from the back hub face (r5) |
| M08 | Fittings>Lb-up; ribbon LB Fitting Up Solid; image menu Lb up | 6 | menu breaks the conduit back by 0.0527 x DIMSCALE - found and extended to the hub face (Q5); vertical conduit built up |
| M09 | ribbon LB Fitting Up Open (CON_LBOUPOPEN) | 6 | menu breaks the conduit back by 0.046875 x DIMSCALE - found and extended (Q5); vertical conduit built up |
| M11 | Fittings>Tee; ribbon Tee Fitting; image menu Tee | 2 | main runs through along the symbol's Y; branch = +X |
| M12 | code changed to TB (MEDCHG) | 2 | TB on a flat tee: back hub tilted into the plan toward the branch, opening on the side opposite the joining leg |
| M13 | Fittings>T-down; ribbon Tee Fitting Down; image menu T-down | 3 | T code on a tee-down symbol -> TB; vertical conduit built down from the back hub |
| M14 | code changed to TB (MEDCHG) | 3 |  |
| M15 | Fittings>T-up; ribbon Tee Fitting Up Solid; image menu T-up | 6 | menu breaks the conduit both sides by 0.0527 x DIMSCALE - found and extended (Q5); vertical conduit built up |
| M16 | ribbon Tee Fitting Up Open | 6 | menu breaks by 0.046875 x DIMSCALE - found and extended (Q5); vertical conduit built up |
| M18 | Fittings>Cee; ribbon Cee; image menu 'C' Fitting | 2 | conduit stays continuous through the body |
| M19 | same with the conduit drawn as two runs | 2 |  |
| M20 | Fittings>X; ribbon Cross Fitting; image menu X | 2 | X: logic OK (Clint); needs the X body builder (phase 2) |
| M21 | Fittings>Lbd L; ribbon LBD Fitting; image menu LBD Fitting | 2 | LBD = LB with a bigger body: LB orientation on its side; placeholder until the LBD builder (phase 2) |
| M22 | Fittings>Lbd R; ribbon LBD Fitting; image menu LBD Fitting | 2 | LBD on its side, opposite presentation; placeholder until the LBD builder (phase 2) |
| M23 | Fittings>Lby; ribbon LBY Fitting; image menu Lby | 2 | LBY = LB logic, symmetrical legs; placeholder until the LBY builder (phase 2) |
| M24 | Fittings>Gual; image menu Gual Fitting | 2 | GUAL: face up, symmetrical legs; needs builder (phase 2) |
| M25 | Fittings>Guat; image menu Guat Fitting | 2 | GUAT: tee logic, face up; needs builder (phase 2) |
| M26 | Fittings>Guax; image menu Guax Fitting | 2 | GUAX: X logic, face up; needs builder (phase 2) |
| M27 | Fittings>Gualside | 2 | GUAL side view: LL/LR-like, face either way - be consistent; needs builder (phase 2) |
| M28 | Fittings>Guatside; image menu Guat side view | 2 | GUAT side view: branch assumed down / away; needs builder (phase 2) |
| M29 | Fittings>Bub; image menu Pulling fitting | 2 | BUB = 45 deg body: face up at the insert point; needs builder (phase 2) |
| M31 | code changed to Mogul BLB (MEDCHG) | 2 | Mogul BLB = larger LB: LB orientation on its side; placeholder until the BLB builder (phase 2) |
| M32 | LB turn with only one leg drawn | 2 | LB on 1lbl with one leg drawn: on its side toward the symbol's short leg (opening sideways, not up) |
| M33 | Fittings>Union; image menu Union | 2 | union: not modelled yet; needs a coupling-like builder (phase 2; menu break may exceed the union length) |
| M34 | Fittings>Seal; image menu Seal | 2 | not a conduit body |
| M35 | Fittings>Seal-Drn; image menu Seal-Drain | 2 | not a conduit body |
| M36 | Fittings>Plug-Rec / Plug-SqH; image menu plugs | 2 | not a conduit body |
| M37 | Fittings>Hub; image menu Hub | 2 | not a conduit body |
| M38 | Fittings>Reducer; image menu Reducer | 8 | not a conduit body |
| M39 | any LB/LL menu entry, then MIRROR (X scale -1) | 2 | mirrored symbol: no 3D body, conduit left as drawn, one MIRRORED FITTING flag + Skipped line |
| M40 | any T menu entry, then MIRROR (Y scale -1) | 2 | mirrored symbol: no 3D body, conduit left as drawn, one MIRRORED FITTING flag + Skipped line |

## Summary

- 37 rows (M10, M17, M30 removed): 37 match at DIMSCALE 1, 37 at DIMSCALE 48.
- Changed in r5 / r11: M03 - M06 (LL / LR), M07 - M09 and M13 - M16 (vertical conduit; up symbols at 48 now find and trim their conduit), M12 (TB tilted), M21 - M23 and M31 (LB logic on the placeholders), M32 (on its side).

## Phase 2: bodies still to build (Clint's notes)

Placeholders stay on `MED_3DFLAG` with a flag until each builder exists. Data rule: published catalog dimensions with sources where found; otherwise clearly labelled approximations derived from the LB / T data, marked "approx" in the CSV and here. Keep the presentation simple, like the existing bodies.

| Row | Body | Clint |
| --- | --- | --- |
| M20 | X (cross) | logic tracks; add the X builder |
| M21, M22 | LBD | LB with a bigger body and a better bend radius for cables; on its side like the LB |
| M23 | LBY | LB logic, symmetrical legs (easier) |
| M24 | GUAL | face up; GUA legs typically symmetrical |
| M25 | GUAT | tee logic, face up |
| M26 | GUAX | X logic, legs the same, face up |
| M27 | GUAL side view | LL / LR-like; the face can lie either way - be consistent |
| M28 | GUAT side view | branch assumed down / away (the presentation means it goes away); face either way, consistent |
| M29 | BUB | a 45° body; face up at the insertion point |
| M31 | Mogul BLB | LB logic, larger body |
| M33 | Union (UNY) | coupling-like; the menu break may be longer than the union - extend the conduit to the union faces |
| M34 | Seal (EYS) | sealing fitting; draw function |
| M35 | Seal with drain (EYD) | draw function |
| M36 | Plug | a coupling with a plug (recessed or extruded) |
| M37 | Hub | Myers-style or plain conduit hub: same logic, different dimensions - middle ground, or a separate Myers block |
| M38 | Reducer | recessed, sticks out a little to show it's there; one size to another |

M33 - M38 are not conduit bodies today (counted "not modelled"); they need their own resolution (code → builder) besides the geometry.

## Running the grid

1. Open a new drawing from your MED template. `(load "acad")` if MED isn't loaded.
2. Optional: set the conduit size you want (the menu's size setting, `_CSIZE`). The default is 1".
3. `(load "C:/Users/moore/Dropbox/Development/Jane/MED2026-OpenSource/tests/autocad/MEDCBGrid.lsp")`
4. Run `MEDCBGRID`. Pick or type the base point (Enter = 0,0), then the rotation for every cell (Enter = 0; try 30 to check that rotation doesn't matter).
5. Drawing scale: MEDCBGRID uses the MED scale (`USERR1`, else `DIMSCALE`, as SETUP sets them). If that is 1 (or 0), it asks `scale to use <48>`; Enter = 48. It then sets `_SC`, `DIMSCALE` and `USERR1` to that value, as SETUP does, so the grid and MEDMAKE3D use the same scale.
6. Every symbol is inserted at +scale on X and Y, the way the menu inserts it (`insert name pt _SC _SC rot`). Only M39 / M40 get one negative scale factor, to fake a user MIRROR. The last line reports `scale check N ok`, and names any cell with the wrong scale or mirror.
7. `ZOOM E`. There are 37 cells, 10' x 10' at scale 48 (cell size, run length and text scale with scale / 48), 6 per row. Each cell is labelled with the row id, block, code, legs, expected result, and the current match at the grid's scale. M39 / M40 are labelled MIRRORED; after MEDMAKE3D they show only the `MIRRORED FITTING - re-insert, do not mirror` marker, with the conduit untouched.
8. Run `MEDMAKE3D`, choose Layer, and look at each cell (e.g. `-VIEW _SWISO`, or orbit). The up / down cells also get their vertical conduit (36").
9. To repeat, erase everything (or use a new drawing) and run `MEDCBGRID` again.

**Negative scales.** MED's menus never insert a fitting with a negative scale. Every `setblkins` / `medblkins` fitting entry in `med.mnu`, `med.cuix` and `MEDRibbon.cuix` passes `_SC`. `C:MEDBlockInsert` and `brk_rot` insert at `bl_scale bl_scale` (or `bl_scale ""`, Y = X). `brk_rot` picks the rotation only (rules 22 / 24 turn `1lbl` / `1lbr`; they don't flip them). The `-1` in the symbol entries is the insert type, not a scale. The only negative scale in the Support code is the GRABIT leader block (`medtext.lsp`), which is not a fitting. So the mirror check stays strict: any mirrored `MED_FITTING` conduit body is a user MIRROR / negative scale and is flagged.

## Keeping this page current

After a change to the resolution / orientation code:
1. Run `python tests/med3dpath/test_fitting_matrix.py --write` to refresh the `cur_*` columns in the CSV.
2. Re-check the ✓ / ✗ here and the summary.

Without `--write`, the test fails whenever the code stops matching what the CSV records.
