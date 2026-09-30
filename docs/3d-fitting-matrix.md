# Conduit body orientation matrix (MEDMAKE3D)

This page lists every 2D conduit-fitting symbol the MED menus can place, the fitting codes it can carry, and what MEDMAKE3D (MED3DPath r9 / MED3DFittings r3) does with each. The same rows are in `tests\med3dpath\fitting_matrix.csv`: the desk test `tests\med3dpath\test_fitting_matrix.py` rebuilds each row and checks the r9 columns, and `MEDCBGRID` (`tests\autocad\MEDCBGrid.lsp`) draws them all in a drawing.

**Principle:**
1. The fitting code picks the body (`MEDType.ITEMKEY2`, else the description).
2. The conduit legs at the insertion point pick the orientation.
3. The 2D block rotation (and which symbol was used) is only a hint, for breaking ties.

## How to read the table

- **Coordinates** are the 2D symbol's own axes (block at rotation 0, insertion point at 0,0). +X is the conduit that was picked when the symbol was inserted. The table holds for any drawn rotation; the test checks rotations 0 and 90.
- **Legs:**
  - `+X +Y`: horizontal conduits leaving the fitting in those directions.
  - `PASSX`: one conduit running straight through along X.
  - `UP` / `DN`: the vertical conduit. It is not a polyline: the menu stores it on the fitting insert itself (`MED_CONDUIT` + `VERT_DATA` direction ±1 + the length you type). MEDMAKE3D does not build vertical legs yet.
- **Expected / r9:**
  - Which way each hub and the cover face: `RUN+X` = RUN hub toward +X; `RUNS:X` = both run hubs on the X axis; `COVER+Z` = cover up.
  - `cuts` = conduit ends trimmed back to a hub face. `flags` = markers on `MED_3DFLAG`.
  - `PH` = placeholder (no 3D data); `NM` = not a conduit body (counted "not modelled"); `*` = don't care.
- **DIMSCALE.** The menu breaks the conduit back from some symbols by the `Support\medblck.dat` distance × DIMSCALE (`_SC`). The table shows r9 at DIMSCALE 1 (breaks under 0.05") and at 48 (1/4" = 1'-0", breaks of 2.2" to 4.2").
- **✓ / ✗** says whether r9 gives the expected result. **Ask** points to the questions below.

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

| Row | 2D block | Code (alt) | Body | Legs | Expected | r9 at DIMSCALE 1 | r9 at DIMSCALE 48 | Ask |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| M01 | `1lbl` | 30 (31 32) | LB | +X +Y | BACK+Y COVER-Y RUN+X, cuts 2, flags 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0 | ✓ BACK+Y COVER-Y RUN+X, cuts 2, flags 0 | Q1 |
| M02 | `1lbr` | 30 (31 32) | LB | +X -Y | BACK-Y COVER+Y RUN+X, cuts 2, flags 0 | ✗ BACK+X COVER-X RUN-Y, cuts 2, flags 0 | ✗ BACK+X COVER-X RUN-Y, cuts 2, flags 0 | Q1 |
| M03 | `1lbl` | 33 (34 35) | LL | +X +Y | BRANCH+X COVER+Z RUN+Y, cuts 2, flags 0 | ✓ BRANCH+X COVER+Z RUN+Y, cuts 2, flags 0 | ✓ BRANCH+X COVER+Z RUN+Y, cuts 2, flags 0 | Q2 |
| M04 | `1lbl` | 36 (37 38) | LR | +X +Y | BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0 | ✓ BRANCH+Y COVER+Z RUN+X, cuts 2, flags 0 |  |
| M05 | `1lbr` | 36 (37 38) | LR | +X -Y | BRANCH+X COVER+Z RUN-Y, cuts 2, flags 0 | ✓ BRANCH+X COVER+Z RUN-Y, cuts 2, flags 0 | ✓ BRANCH+X COVER+Z RUN-Y, cuts 2, flags 0 | Q2 |
| M06 | `1lbr` | 33 (34 35) | LL | +X -Y | BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0 | ✓ BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0 | ✓ BRANCH-Y COVER+Z RUN+X, cuts 2, flags 0 |  |
| M07 | `1lbd` | 30 (31 32) | LB | +X DN | BACK-Z COVER+Z RUN+X, cuts 1, flags 0 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0 | Q3 |
| M08 | `1lbu` | 30 (31 32) | LB | +X UP | BACK+Z COVER-Z RUN+X, cuts 1, flags 0 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0 | ✗ BACK+Z COVER-Z RUN+X, cuts 0, flags 0 | Q3 Q5 |
| M09 | `1lbuo` | 30 (31 32) | LB | +X UP | BACK+Z COVER-Z RUN+X, cuts 1, flags 0 | ✓ BACK+Z COVER-Z RUN+X, cuts 1, flags 0 | ✗ BACK+Z COVER-Z RUN+X, cuts 0, flags 0 | Q3 Q5 |
| M10 | `1lbd` | 33 (34 35 36 37 38) | LL | +X DN | *, cuts 1, flags 1 | ✗ BRANCH-Y COVER+Z RUN+X, cuts 1, flags 0 | ✗ BRANCH-Y COVER+Z RUN+X, cuts 1, flags 0 | Q6 |
| M11 | `1tee` | 11 (12 13) | T | PASSY +X | BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0 | ✓ BRANCH+X COVER+Z RUNS:Y, cuts 1, flags 0 |  |
| M12 | `1tee` | 14 (15 16) | TB | PASSY +X | BACK+X COVER-X RUNS:Y, cuts 1, flags 0 | ✗ BACK-Z COVER+Z RUNS:Y, cuts 0, flags 1 | ✗ BACK-Z COVER+Z RUNS:Y, cuts 0, flags 1 | Q7 |
| M13 | `1teed` | 11 (12 13) | TB | PASSX DN | BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | Q4 |
| M14 | `1teed` | 14 (15 16) | TB | PASSX DN | BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | ✓ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 |  |
| M15 | `1teeu` | 11 (12 13) | TB | PASSX UP | BACK+Z COVER-Z RUNS:X, cuts 2, flags 0 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0 | ✗ BACK+Z COVER-Z RUNS:X, cuts 0, flags 0 | Q4 Q5 |
| M16 | `1teeuo` | 11 (12 13) | TB | PASSX UP | BACK+Z COVER-Z RUNS:X, cuts 2, flags 0 | ✓ BACK+Z COVER-Z RUNS:X, cuts 2, flags 0 | ✗ BACK+Z COVER-Z RUNS:X, cuts 0, flags 0 | Q4 Q5 |
| M17 | `2teed` | 11 (12 13) | TB | PASSY DN | BACK-Z COVER+Z RUNS:Y, cuts 2, flags 0 | ✓ BACK-Z COVER+Z RUNS:Y, cuts 2, flags 0 | ✗ BACK-Z COVER+Z RUNS:X, cuts 0, flags 0 | Q8 |
| M18 | `1cee` | 50 (51 52) | C | PASSX | COVER+Z RUNS:X, cuts 0, flags 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0 | ✓ COVER+Z RUNS:X, cuts 0, flags 0 |  |
| M19 | `1cee` | 50 (51 52) | C | -X +X | COVER+Z RUNS:X, cuts 2, flags 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0 | ✓ COVER+Z RUNS:X, cuts 2, flags 0 |  |
| M20 | `1exs` | 80 (81 82) | X | PASSX PASSY | PH, cuts *, flags 1+ | ✓ PH, cuts 0, flags 1 | ✓ PH, cuts 0, flags 1 | Q9 |
| M21 | `1lbdl` | 39 | LBD | +X +Y | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 2 | ✓ PH, cuts 2, flags 2 | Q9 |
| M22 | `1lbdr` | 39 | LBD | +X -Y | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 2 | ✓ PH, cuts 2, flags 2 | Q9 |
| M23 | `1lby` | 41 | LBY | +X +Y | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 2 | ✓ PH, cuts 2, flags 2 | Q9 |
| M24 | `1gual` | 141 | GUAL | +X +Y | PH, cuts *, flags 1+ | ✓ PH, cuts 1, flags 2 | ✓ PH, cuts 0, flags 1 | Q9 |
| M25 | `1guat` | 142 | GUAT | +X +Y -Y | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 2 | ✓ PH, cuts 0, flags 1 | Q9 |
| M26 | `1guax` | 143 | GUAX | PASSX PASSY | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 3 | ✓ PH, cuts 0, flags 1 | Q9 |
| M27 | `1gualsid` | 141 | GUAL | +X | PH, cuts *, flags 1+ | ✓ PH, cuts 1, flags 1 | ✓ PH, cuts 0, flags 1 | Q9 |
| M28 | `1guatsid` | 142 | GUAT | PASSX | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 1 | ✓ PH, cuts 0, flags 1 | Q9 |
| M29 | `1bub` | 94 | BUB (Mogul) | PASSX | PH, cuts *, flags 1+ | ✓ PH, cuts 0, flags 1 | ✓ PH, cuts 0, flags 1 | Q9 |
| M30 | `1tee` | 17 (18) | TA | PASSY +X | PH, cuts *, flags 1+ | ✓ PH, cuts 0, flags 2 | ✓ PH, cuts 0, flags 2 | Q9 |
| M31 | `1lbl` | 40 | BLB (Mogul) | +X +Y | PH, cuts *, flags 1+ | ✓ PH, cuts 2, flags 2 | ✓ PH, cuts 2, flags 2 | Q9 |
| M32 | `1lbl` | 30 (31 32) | LB | +X | BACK-Z COVER+Z RUN+X, cuts 1, flags 0 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0 | ✓ BACK-Z COVER+Z RUN+X, cuts 1, flags 0 |  |
| M33 | `1union` | 72 | - | PASSX | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |
| M34 | `1seal` | 61 | - | PASSX | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |
| M35 | `1sealdr` | 64 | - | PASSX | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |
| M36 | `1cap` | 100 (101) | - | +X | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |
| M37 | `1hub` | 120 | - | +X | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |
| M38 | `1re` | 103 | - | PASSX | NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 | ✓ NM, cuts 0, flags 0 |  |

### Where each row comes from

| Row | Menu / how it gets there | Insert type | Notes |
| --- | --- | --- | --- |
| M01 | Fittings>Lbl; ribbon LB Fitting (CON_LB1); image menu LB Fitting | 2 | flat plan turn; body along the symbol's long leg (+X) |
| M02 | Fittings>Lbr; ribbon LB Fitting (CON_LB2); image menu LB Fitting | 2 | flat plan turn; body along the symbol's long leg (+X) |
| M03 | ribbon LL Fitting (CON_LL) | 2 | cover up puts the body on the symbol's short leg |
| M04 | code changed to LR (MEDCHG) | 2 |  |
| M05 | ribbon LR Fitting (CON_LR) | 2 | cover up puts the body on the symbol's short leg |
| M06 | code changed to LL (MEDCHG) | 2 |  |
| M07 | Fittings>Lb-down; ribbon LB Fitting Down; image menu Lb down | 3 | vertical leg = VERT_DATA on the fitting insert (not built) |
| M08 | Fittings>Lb-up; ribbon LB Fitting Up Solid; image menu Lb up | 6 | menu breaks the conduit back by 0.0527 x DIMSCALE |
| M09 | ribbon LB Fitting Up Open (CON_LBOUPOPEN) | 6 | menu breaks the conduit back by 0.046875 x DIMSCALE |
| M10 | code changed to LL (MEDCHG) | 3 | an LL has no hub for the vertical leg |
| M11 | Fittings>Tee; ribbon Tee Fitting; image menu Tee | 2 | main runs through along the symbol's Y; branch = +X |
| M12 | code changed to TB (MEDCHG) | 2 | flat tee with a TB code |
| M13 | Fittings>T-down; ribbon Tee Fitting Down; image menu T-down | 3 | T code on a tee-down symbol -> TB |
| M14 | code changed to TB (MEDCHG) | 3 |  |
| M15 | Fittings>T-up; ribbon Tee Fitting Up Solid; image menu T-up | 6 | menu breaks the conduit on both sides by 0.0527 x DIMSCALE |
| M16 | ribbon Tee Fitting Up Open | 6 | menu breaks the conduit on both sides by 0.046875 x DIMSCALE |
| M17 | image menu T-down to Tee | 3 | Dwg\2teed.dwg is missing - the menu entry cannot insert it |
| M18 | Fittings>Cee; ribbon Cee; image menu 'C' Fitting | 2 | conduit stays continuous through the body |
| M19 | same with the conduit drawn as two runs | 2 |  |
| M20 | Fittings>X; ribbon Cross Fitting; image menu X | 2 | no X data - placeholder |
| M21 | Fittings>Lbd L; ribbon LBD Fitting; image menu LBD Fitting | 2 | no form / data - placeholder |
| M22 | Fittings>Lbd R; ribbon LBD Fitting; image menu LBD Fitting | 2 | no form / data - placeholder |
| M23 | Fittings>Lby; ribbon LBY Fitting; image menu Lby | 2 | no form / data - placeholder |
| M24 | Fittings>Gual; image menu Gual Fitting | 2 | explosion proof - placeholder |
| M25 | Fittings>Guat; image menu Guat Fitting | 2 | explosion proof - placeholder |
| M26 | Fittings>Guax; image menu Guax Fitting | 2 | explosion proof - placeholder |
| M27 | Fittings>Gualside | 2 | side view symbol - placeholder |
| M28 | Fittings>Guatside; image menu Guat side view | 2 | side view symbol - placeholder |
| M29 | Fittings>Bub; image menu Pulling fitting | 2 | Mogul - placeholder |
| M30 | code changed to TA (MEDCHG) | 2 | no TA data - placeholder |
| M31 | code changed to Mogul BLB (MEDCHG) | 2 | Mogul - placeholder |
| M32 | LB turn with only one leg drawn | 2 | prints the flat plan turn note |
| M33 | Fittings>Union; image menu Union | 2 | not a conduit body - counted not modelled |
| M34 | Fittings>Seal; image menu Seal | 2 | not a conduit body |
| M35 | Fittings>Seal-Drn; image menu Seal-Drain | 2 | not a conduit body |
| M36 | Fittings>Plug-Rec / Plug-SqH; image menu plugs | 2 | not a conduit body |
| M37 | Fittings>Hub; image menu Hub | 2 | not a conduit body |
| M38 | Fittings>Reducer; image menu Reducer | 8 | not a conduit body |

Form 8 / Mark 9 codes (the alt codes) resolve the same way. The table only checks that the size row exists: at 1" every form has LB / LL / LR / T / TB / C, and TB exists only up to 2".

## Summary (r9)

- 38 rows: 35 match at DIMSCALE 1, 30 at DIMSCALE 48.
- **Mismatches:**
  - **M02** `1lbr` + LB (code 30): the body lies along the symbol's short leg (-Y) with the back hub on +X. The symbol and `1lbl` (M01) put it along +X. The snap takes the first orientation that meets both legs, and for `1lbr` that is the other one. This is the case in Clint's screenshot (Q1).
  - **M08 / M09 / M15 / M16** `1lbu`, `1lbuo`, `1teeu`, `1teeuo` at DIMSCALE 48: the menu cut the conduit back by 2.2 - 2.5". r9 only looks within 0.25" of the insertion point, so the legs are not found. The orientation is still right, because the drawn rotation from `medblck.dat` puts +X on the conduit. But the conduit is not trimmed (it runs about 2.5" into the body), there is no snap, and the block Z is used instead of the conduit Z (Q5).
  - **M17** `2teed` at DIMSCALE 48: legs not found, and the drawn rotation (+X) is 90° off the main run (block Y), so the TB is turned the wrong way. It cannot be placed anyway (DWG missing, Q8).
  - **M10** LL / LR code on an LB-down symbol: placed flat with no flag. It has no hub for the vertical conduit (Q6).
  - **M12** TB code on a flat tee: back hub down, branch leg left uncut and flagged (Q7).
- **Observation (not counted as a mismatch):** placeholders (X, LBD, LBY, GUA, TA, Mogul) also trim the conduit to their rough hubs. Legs that miss a placeholder hub get an extra flag on top of the placeholder's own (Q9).
- **Not generated faithfully by MEDCBGRID:**
  - `2teed` (no DWG).
  - The up / down length is 36" (the menu asks for it).
  - Conduit breaks are drawn as shortened runs instead of BREAK. The xdata is written by the menu's own `ifitt_ins` / `dcon_ins` / `bld_conduit`.

## Questions for Clint

**Q1 - LB used as a flat plan turn (`1lbl` / `1lbr`, code 30): which leg carries the body?**
Proposed: the symbol's long leg (block +X, the conduit you picked), with the back hub on the other leg; the cover then faces away from that leg (sideways). r9 does this for `1lbl` but not for `1lbr`.

**Q2 - LL / LR naming against the symbols.**
- By the Crouse-Hinds rule used for the 3D blocks (cover toward you, end hub down: side opening left = LL):
  - the `1lbl` symbol (body along +X, opening +Y) is an **LR** with the cover up;
  - `1lbr` is an **LL** with the cover up.
- The ribbon places LL as `1lbl` + 33 and LR as `1lbr` + 36. r9 keeps the cover up, so those two put the body on the symbol's short leg (M03, M05).
- Options:
  - (a) cover always up, body wherever that puts it (r9);
  - (b) body along the symbol's long leg, cover down when the code and symbol disagree;
  - (c) MED's LL / LR are the mirror of the catalog, so swap them.

**Q3 - LB up / down (`1lbd`, `1lbu`, `1lbuo`).**
- r9: the body lies horizontal along the run with the back hub vertical (cover up for down, cover down for up).
- The other common way, at a wall: the body vertical along the riser, the back hub toward the horizontal run, and the cover facing away from the run.
- Which one should MEDMAKE3D use, and is it the same for up and down?

**Q4 - Tee up / down (`1teeu`, `1teeuo`, `1teed`, code 11).**
- r9 uses a TB: back hub down (tee down), or turned over with the back hub up and the cover down (tee up).
- Alternative: a T tilted 90° about its run, so the branch points down / up and the cover faces sideways.
- Keep TB (you chose it earlier), or use a T for up only?

**Q5 - Conduit breaks around up symbols.**
- At your usual DIMSCALE, the menu leaves the conduit 2 - 3" short of `1lbu` / `1lbuo` / `1teeu` / `1teeuo` (0.0527 × DIMSCALE), so r9 doesn't see those legs.
- Proposed: search each fitting out to its `medblck.dat` break distance × DIMSCALE + 0.25", and trim / extend the leg to the hub face.
- What DIMSCALE do your drawings use?

**Q6 - A code that can't meet the legs** (LL / LR / C / T code on an LB-down / up symbol, ...): flag it (proposed), or trust the code silently (r9)?

**Q7 - TB code on a flat tee (`1tee` + 14 / 15 / 16):** tilt the back hub into the plan toward the branch, like the flat LB (proposed), or keep the back hub down and flag the branch (r9)?

**Q8 - `2teed` ("T-down to Tee" in the image menu):** `Dwg\2teed.dwg` is missing, so the entry can't insert anything. Its `medblck.dat` breaks say the main run lies along the symbol's Y. Restore the DWG, or remove the entry?

**Q9 - Placeholders:** keep trimming the conduit to placeholder hubs, but drop the extra leg flags (proposed; one flag per placeholder)?

## Running the grid

1. Open a new drawing from your MED template, or any MED drawing with DIMSCALE set. `(load "acad")` if MED isn't loaded.
2. Optional: set the conduit size you want (the menu's size setting, `_CSIZE`). The default is 1".
3. `(load "C:/Users/moore/Dropbox/Development/Jane/MED2026-OpenSource/tests/autocad/MEDCBGrid.lsp")`
4. Run `MEDCBGRID`. Pick or type the base point (Enter = 0,0), then the rotation for every cell (Enter = 0; try 30 to check that rotation doesn't matter).
5. `ZOOM E`. There are 38 cells of 10' x 10', 6 per row. Each cell is labelled with the row id, block, code, legs, expected result, and r9 match at DIMSCALE 1 / 48.
6. Run `MEDMAKE3D`, choose Layer, and look at each cell (e.g. `-VIEW _SWISO`, or orbit).
7. To repeat, erase everything (or use a new drawing) and run `MEDCBGRID` again.

## Keeping this page current

After a change to the resolution / orientation code:
1. Run `python tests/med3dpath/test_fitting_matrix.py --write` to refresh the r9 columns in the CSV.
2. Re-check the ✓ / ✗ here and the summary.

Without `--write`, the test fails whenever the code stops matching what the CSV records.
