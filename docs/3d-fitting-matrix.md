# Conduit body orientation matrix (MEDMAKE3D)

This page lists every 2D conduit-fitting symbol the MED menus can place, the fitting codes it can carry, and what MEDMAKE3D (MED3DPath r12 / MED3DFittings r6) does with each. The same rows are in `tests\med3dpath\fitting_matrix.csv`: the desk test `tests\med3dpath\test_fitting_matrix.py` rebuilds each row and checks the `cur_*` columns, and `MEDCBGRID` (`tests\autocad\MEDCBGrid.lsp`) draws them all in a drawing.

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
- **LBD / LBY / Mogul BLB** use LB logic (M21 - M23, M31): on `1lbdl` / `1lbdr` / `1lby` / `1lbl` they lie on their side like the LB. Real bodies since r6 (phase 2).
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
| M20 | `1exs` | 80 (81 82) | X (F7) | PASSX PASSY | BRANCHES:Y COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ BRANCHES:Y COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ BRANCHES:Y COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | Q9 decided |
| M21 | `1lbdl` | 39 | LBD (CH) | +X +Y | BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M22 | `1lbdr` | 39 | LBD (CH) | +X -Y | BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK-Y COVER+Y RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M23 | `1lby` | 41 | LBY (CH) | +X +Y | BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M24 | `1gual` | 141 | GUAL (XP) | +X +Y | BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0, vert 0 | Q9 decided |
| M25 | `1guat` | 142 | GUAT (XP) | +X +Y -Y | BRANCH+X COVER+Z RUNS:Y, cuts 3, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 3, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 3, flags 0, vert 0 | Q9 decided |
| M26 | `1guax` | 143 | GUAX (XP) | PASSX PASSY | BRANCHES:Y COVER+Z RUNS:X, cuts 4, flags 0, vert 0 | ✓ BRANCHES:Y COVER+Z RUNS:X, cuts 4, flags 0, vert 0 | ✓ BRANCHES:Y COVER+Z RUNS:X, cuts 4, flags 0, vert 0 | Q9 decided |
| M27 | `1gualsid` | 141 | GUAL (XP) | +X | BRANCH-Z COVER+Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BRANCH-Z COVER+Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BRANCH-Z COVER+Y RUN+X, cuts 1, flags 0, vert 0 | Q9 decided |
| M28 | `1guatsid` | 142 | GUAT (XP) | PASSX | BRANCH-Z COVER+Y RUNS:X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Z COVER+Y RUNS:X, cuts 2, flags 0, vert 0 | ✓ BRANCH-Z COVER+Y RUNS:X, cuts 2, flags 0, vert 0 | Q9 decided |
| M29 | `1bub` | 94 | BUB (Mogul) | PASSX | COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | Q9 decided |
| M31 | `1lbl` | 40 | BLB (Mogul) | +X +Y | BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0, vert 0 | Clint r5 |
| M32 | `1lbl` | 30 (31 32) | LB | +X | BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 1, flags 0, vert 0 | Clint r5 |
| M33 | `1union` | 72 | UNY (CH) | PASSX | COVER+Z RUNS:X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0, vert 0 | decided |
| M34 | `1seal` | 61 | EYS (CH) | PASSX | COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | decided |
| M35 | `1sealdr` | 64 | EYD (CH) | PASSX | COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | decided |
| M36 | `1cap` | 100 (101) | PLGR (CH) | +X | COVER+Z RUN+X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 0, flags 0, vert 0 | decided |
| M37 | `1hub` | 120 | HUB (CH) | +X | COVER+Z RUN+X, cuts 1, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 1, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 1, flags 0, vert 0 | decided |
| M38 | `1re` | 103 | RE (CH) | PASSX | COVER+Z RUN+X RUN2-X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUN+X RUN2-X, cuts 2, flags 0, vert 0 | ✓ COVER+Z RUN+X RUN2-X, cuts 2, flags 0, vert 0 | decided |
| M41 | `1tee` | 18 | BT (Mogul) | PASSY +X | BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0, vert 0 |  |
| M42 | `1cee` | 53 | BC (Mogul) | PASSX | COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0, vert 0 |  |
| M43 | `1hub` | 121 | HUB (Myers ST) | +X | COVER+Z RUN+X, cuts 1, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 1, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 1, flags 0, vert 0 |  |
| M44 | `1cap` | 101 | PLGS (CH) | +X | COVER+Z RUN+X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 0, flags 0, vert 0 | ✓ COVER+Z RUN+X, cuts 0, flags 0, vert 0 |  |
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
| M20 | Fittings>X; ribbon Cross Fitting; image menu X | 2 | X body (r6, CH1F-2022 p.13): face up, both runs continuous through it |
| M21 | Fittings>Lbd L; ribbon LBD Fitting; image menu LBD Fitting | 2 | LBD (r6, CH 2006 1F p.13): LB orientation on its side along the long leg |
| M22 | Fittings>Lbd R; ribbon LBD Fitting; image menu LBD Fitting | 2 | LBD on its side, opposite presentation (r6 builder) |
| M23 | Fittings>Lby; ribbon LBY Fitting; image menu Lby | 2 | LBY (r6, CH 2006 1F p.16): LB logic, symmetrical legs; COVER token = body +Z (the round cover sits on the 45 deg corner between body +Z and -X) |
| M24 | Fittings>Gual; image menu Gual Fitting | 2 | GUAL (r9, tuned to Clint's reference DWGs): face up, legs symmetrical (hub faces at a/2 + hub length from the centre) |
| M25 | Fittings>Guat; image menu Guat Fitting | 2 | GUAT: tee logic, face up; 1guat -90 deg offset like 1tee (branch = symbol +X) |
| M26 | Fittings>Guax; image menu Guax Fitting | 2 | GUAX: X logic, face up |
| M27 | Fittings>Gualside | 2 | GUAL side view: tilted -90 deg about X - branch down, cover toward +Y (same for GUAT side) |
| M28 | Fittings>Guatside; image menu Guat side view | 2 | GUAT side view: branch down / away, cover toward +Y (consistent with GUAL side) |
| M29 | Fittings>Bub; image menu Pulling fitting | 2 | BUB (r6, CH 2006 1F p.15): face up at the insert point, hubs 45 deg down; planner sees horizontal hubs at the faces |
| M31 | code changed to Mogul BLB (MEDCHG) | 2 | Mogul BLB (r6, CH 2006 1F p.14): larger LB on its side |
| M32 | LB turn with only one leg drawn | 2 | LB on 1lbl with one leg drawn: on its side toward the symbol's short leg (opening sideways, not up) |
| M33 | Fittings>Union; image menu Union | 2 | union (r6, Eaton UNY): coupling-like; conduit trimmed / extended to the union faces (menu break 2.25 in at 48 > half the union) |
| M34 | Fittings>Seal; image menu Seal | 2 | EYS seal (r10): inline, body centred on the conduit, pour hub up, leaning boss toward +X, nothing past the catalog turning radius; conduit continuous (no menu break) |
| M35 | Fittings>Seal-Drn; image menu Seal-Drain | 2 | EYD seal with drain (r10): upright EYS body + lower large opening (within the turning radius) with a special plug and an ECD drain 45 deg down toward -X |
| M36 | Fittings>Plug-Rec / Plug-SqH; image menu plugs | 2 | plugged coupling (r6, approx): coupling centred on the conduit end, recessed plug at -X |
| M37 | Fittings>Hub; image menu Hub | 2 | conduit hub (r6, CH MHUB): wall face at the insert point, conduit extended to the hub face (menu break 3 in at 48) |
| M38 | Fittings>Reducer; image menu Reducer | 8 | reducer (r6, approx): large coupling -X (RUN2), head sticks out, small end +X (RUN); reduce-to size from #ITEM_ALT; the 4.38 in menu break on +X (0.09125 x 48, medblck.dat) is extended to the head |
| M41 | code changed to Mogul BT (MEDCHG) | 2 | Mogul BT = T geometry (CH 2006 1F p.15) |
| M42 | code changed to Mogul BC (MEDCHG) | 2 | Mogul BC = C geometry (CH 2006 1F p.14) |
| M43 | Myers hub code (MEDCHG) | 2 | Myers ST hub (CP-270): body above the wall, neck + locknut inside |
| M44 | Fittings>Plug-SqH | 2 | plugged coupling, square-head plug (approx) |
| M39 | any LB/LL menu entry, then MIRROR (X scale -1) | 2 | mirrored symbol: no 3D body, conduit left as drawn, one MIRRORED FITTING flag + Skipped line |
| M40 | any T menu entry, then MIRROR (Y scale -1) | 2 | mirrored symbol: no 3D body, conduit left as drawn, one MIRRORED FITTING flag + Skipped line |

## Summary

- 41 rows (M10, M17, M30 removed; M41 - M44 added in r6): 41 match at DIMSCALE 1, 41 at DIMSCALE 48.
- Changed in r5 / r11: M03 - M06 (LL / LR), M07 - M09 and M13 - M16 (vertical conduit; up symbols at 48 now find and trim their conduit), M12 (TB tilted), M21 - M23 and M31 (LB logic on the placeholders), M32 (on its side).
- Changed in r6 / r12 (phase 2): every placeholder and "not modelled" row now gets a real body - M20 (X), M21 - M23 (LBD, LBY), M24 - M28 (GUA), M29 (BUB), M31 (BLB), M33 - M38 (union, seals, plug, hub, reducer); new rows M41 - M44 (Mogul BT, Mogul BC, Myers hub, square-head plug). No placeholders or flags remain in the matrix except the mirrored rows M39 / M40.

## Phase 2: bodies (done in r6)

Clint's notes are kept in the table; the last two columns say what was built and where the numbers come from. Data rule: published catalog dimensions with sources where found; otherwise clearly labelled approximations (`SourceId` `APPROX`, "approx" in the `Notes` column of `Data\seed\conduit_body_dims.csv`). Sources are listed in `Data\seed\conduit_body_sources.csv`.

| Row | Body | Clint | Built (r6) | Dimensions from |
| --- | --- | --- | --- | --- |
| M20 | X (cross) | logic tracks; add the X builder | X: two run hubs on X, two branch hubs on Y, cover up; codes 80 / 81 / 82 (F7 / F8 / M9) | CH1F-2022 printed p.13 (Form 8 / Mark 9 X; F8 X 1-1/2 `c` kept as printed) |
| M21, M22 | LBD | LB with a bigger body and a better bend radius for cables; on its side like the LB | LB geometry with the LBD letters; code 39 (CH) | CH1F-2006 section 1F p.13 (CH LBD 1" `e` kept as printed) |
| M23 | LBY | LB logic, symmetrical legs (easier) | own builder: round body with LB hubs (RUN, BACK) at 90°, legs symmetrical, round cover on the 45° corner opposite the hubs; code 41 | CH1F-2006 p.16 (a / b read as hub-face distances; body internals derived) |
| M24 | GUAL | face up; GUA legs typically symmetrical | round box, cover (full-diameter disc + lugs) up, bored hubs, faces at a/2 + hub length; code 141 | CH3F-GUA-2024 (a, HubLen); 3D proportions **tuned to Clint's reference DWGs** (`CLINT-GUA-DWG`, r9) |
| M25 | GUAT | tee logic, face up | as GUAL + third hub; `1guat` -90° offset like `1tee`; code 142 | CH3F-GUA-2024; tuned to Clint's reference DWGs (r9) |
| M26 | GUAX | X logic, legs the same, face up | four hubs; code 143 | CH3F-GUA-2024; tuned to Clint's reference DWGs (r9) |
| M27 | GUAL side view | LL / LR-like; the face can lie either way - be consistent | `1gualsid`: tilted -90° about X - branch down, cover toward +Y | CH3F-GUA-2024 |
| M28 | GUAT side view | branch assumed down / away; face either way, consistent | `1guatsid`: same tilt as GUAL side | CH3F-GUA-2024 |
| M29 | BUB | a 45° body; face up at the insertion point | body with the two hubs at 45° down (oblique cylinders); planner treats the hub faces as horizontal; code 94 (Mogul) | CH1F-2006 p.15 (internals derived) |
| M31 | Mogul BLB | LB logic, larger body | LB geometry with the Mogul letters; code 40 | CH1F-2006 p.14, cross-checked with the current Eaton Mogul page |
| M41 | Mogul BT | - | T geometry; code 18 | CH1F-2006 p.15 |
| M42 | Mogul BC | - | C geometry; code 53 | CH1F-2006 p.14 |
| M33 | Union (UNY) | coupling-like; the menu break may be longer than the union - extend the conduit to the union faces | inline body; conduit trimmed / extended to the faces (on-axis guard in MED3DPath r12); code 72 | CH5F-UNY-2022 printed p.82 |
| M34 | Seal (EYS) | sealing fitting; draw function; r7: "massage to look like they are" + reference model | r10: straight-through bored tube, plain hub rings, body centred on the conduit axis, large short pour hub up + leaning boss toward +X, both with recessed square-drive plugs; every part (rim corners included) within the turning radius D at every size (r9); code 61 | CH6F-EYS-2020 printed p.114 (a, b, turning radius D); shape details **approx** |
| M35 | Seal with drain (EYD) | draw function | r10 (Clint's AutoCAD test): upright like the EYS (centred body, pour hub and leaning boss +Z, within D) + the lower large opening (−Z, opposite the pour hub) closed by a special plug with a 1/2" nipple and an ECD drain pointing down at 45° toward −X; code 64 | CH6F-EYD table (a, b, turning radius D; EYD 1" `b` kept as printed); ECD11 per `EATON-ECD11` (1.56 in long, 0.88 in; hex / body split **approx**); body details **approx**; `CLINT-EYD-PROFILE` = proportion reference only |
| M36, M44 | Plug | a coupling with a plug (recessed or extruded) | coupling on the conduit end + recessed (PLGR, code 100) or square-head (PLGS, code 101) plug | **approx**: Wheatland coupling (WH-ECN-2017) + ANSI C80.1 OD; the CH PLG page has no dimensions |
| M37 | Hub | Myers-style or plain conduit hub: same logic, different dimensions - middle ground, or a separate Myers block | two blocks: CH conduit hub (code 120) and Myers ST (code 121); wall face at the insert point | CH-CP269-2006 (MHUB letters a b c d x, Myers ST A B C D K) |
| M38 | Reducer | recessed, sticks out a little to show it's there; one size to another | coupling on the large conduit + head sticking out + small conduit; reduce-to size from the fitting's alt size (else one size down, with a note); code 103 | **approx**: Wheatland coupling + C80.1 OD |

**Code → body.** `MEDType.ITEMKEY2` is filled for all of these codes in `Data\MED.db` (`tools\build_fitting_body_keys.py`, `Data\seed\fitting_body_keys.csv`). If a database has no key, MEDMAKE3D falls back to the description, then to the keys CSV (same code and same description only).

**Block rule (Clint).** Every entity inside a generated fitting block is on layer 0 with colour, linetype and lineweight ByLayer - no cover colour or other fixed properties. The insert carries the layer: `MED_3DCONDUIT` for real bodies, `MED_3DFLAG` for placeholders. Blocks built by r5 or earlier (gray cover) are renamed `..._PRE_R6` and rebuilt the first time they are needed; PURGE the `_PRE_R6` blocks once nothing uses them.

**Still open.** `2teed` has no DWG; the reducing coupling (REC), the EYS elbow and EZS / EZD are not modelled; the GUA and plug codes cover only the catalog variants chosen here; the `1re` large end is assumed to be on the symbol's -X side.

## Running the grid

1. Open a new drawing from your MED template. `(load "acad")` if MED isn't loaded.
2. Optional: set the conduit size you want (the menu's size setting, `_CSIZE`). The default is 1".
3. `(load "C:/Users/moore/Dropbox/Development/Jane/MED2026-OpenSource/tests/autocad/MEDCBGrid.lsp")`
4. Run `MEDCBGRID`. Pick or type the base point (Enter = 0,0), then the rotation for every cell (Enter = 0; try 30 to check that rotation doesn't matter).
5. Drawing scale: MEDCBGRID uses the MED scale (`USERR1`, else `DIMSCALE`, as SETUP sets them). If that is 1 (or 0), it asks `scale to use <48>`; Enter = 48. It then sets `_SC`, `DIMSCALE` and `USERR1` to that value, as SETUP does, so the grid and MEDMAKE3D use the same scale.
6. Every symbol is inserted at +scale on X and Y, the way the menu inserts it (`insert name pt _SC _SC rot`). Only M39 / M40 get one negative scale factor, to fake a user MIRROR. The last line reports `scale check N ok`, and names any cell with the wrong scale or mirror.
7. `ZOOM E`. There are 41 cells, 10' x 10' at scale 48 (cell size, run length and text scale with scale / 48), 6 per row. Each cell is labelled with the row id, block, code, legs, expected result, and the current match at the grid's scale. M39 / M40 are labelled MIRRORED; after MEDMAKE3D they show only the `MIRRORED FITTING - re-insert, do not mirror` marker, with the conduit untouched.
8. Run `MEDMAKE3D`, choose Layer, and look at each cell (e.g. `-VIEW _SWISO`, or orbit). The up / down cells also get their vertical conduit (36").
9. To repeat, erase everything (or use a new drawing) and run `MEDCBGRID` again.

**Negative scales.** MED's menus never insert a fitting with a negative scale. Every `setblkins` / `medblkins` fitting entry in `med.mnu`, `med.cuix` and `MEDRibbon.cuix` passes `_SC`. `C:MEDBlockInsert` and `brk_rot` insert at `bl_scale bl_scale` (or `bl_scale ""`, Y = X). `brk_rot` picks the rotation only (rules 22 / 24 turn `1lbl` / `1lbr`; they don't flip them). The `-1` in the symbol entries is the insert type, not a scale. The only negative scale in the Support code is the GRABIT leader block (`medtext.lsp`), which is not a fitting. So the mirror check stays strict: any mirrored `MED_FITTING` conduit body is a user MIRROR / negative scale and is flagged.

## Keeping this page current

After a change to the resolution / orientation code:
1. Run `python tests/med3dpath/test_fitting_matrix.py --write` to refresh the `cur_*` columns in the CSV.
2. Re-check the ✓ / ✗ here and the summary.

Without `--write`, the test fails whenever the code stops matching what the CSV records.
