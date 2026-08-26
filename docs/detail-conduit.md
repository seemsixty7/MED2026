# Detail conduit (two-line)

Two-line conduit is a **detail** drawing of conduit: a centerline plus two offsets at the rigid OD. Data stays on the centerline (`MED_CONDUIT`). Outlines live on `MEDDETCON`; centerline can be moved to `MEDCENTER`.

The 2012 Detail Conduit toolbar is gone as a documented flyout. `MEDDETAIL` (menu switcher) was removed. Commands below are live in `Support\medcon.lsp`.

## Route

1. Set size (`MEDSETTINGS` / `CONSIZE`). Width is rigid-conduit outside diameter (`_ACSIZE`).
2. Bends on/off and bend multiplier — same as plan conduit.
3. `2LCON` — runs `CONDUIT` then offsets both sides and zeros the centerline width. Pick points are the **centerline**. Finish with Enter. Fillet (if on) is applied to that centerline; the offsets follow.

`2LFLEX` is the flex variant (spline the centerline, offset both sides, flex type `_FLEXTYPE`).

`CONFIX` rebuilds the two-line offsets from a selected conduit centerline.

## Away, toward, break

Conduit does not always stay in the plane of the sheet.

| Command | Block | Pick |
| --- | --- | --- |
| `2AWAY` | away | First outer line, then second |
| `2TOWARD` | toward | Same two-line pick |
| `2BREAK` | break | Same two-line pick |

## Fittings and lights

Place from the CUI image menus (Support still has `meddtl.slb`, `medplan*.slb`). Tee at an INT of a branch `2LCON` run (NEA on the main when routing the branch). Size override and User Rotate work the same as plan fittings ([conduit.md](conduit.md)).

**Block size invalid or not found** means there is no block for that catalog size. Example from 2012: a stanchion light that exists only at 1½". Set size to 1½", `2LCON` the riser, place the fixture on the **centerline**, then rotate. 1¼" would error.

Hubs / RS j-boxes: `HUBS`. `UNJ` is an un-junction helper in `MEDCommands.lsp`.
