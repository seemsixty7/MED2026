# MEDSETTINGS

Commands: `MEDSETTINGS`, `MEDSET`.

Docked C# palette ("MED Settings"). Writes lisp globals for the current drawing session. Same role as the 2012 MEDSET dialog: conduit, tray, and scale defaults used while you draw.

The 2012 dialog was DCL and reverted to `MED.SPC` on the next drawing. That is still true: session values are not stored in the DWG except scale (`DIMSCALE`, `USERR1`, `_PLOTSCALE`). `Support\med.spc` is still loaded by `MEDCore.lsp` and is the default source.

OpenDCL `C:MEDSETTINGS` in `Support\MEDMainDialogs-RedoWithCSharp.lsp` is **not** loaded. The C# palette is the command.

![MED Settings palette](images/medsettings.png)

MED Settings palette with scale combo. *Screenshot still needed — do not invent one. `docs/images/acad-ui.png` shows Settings docked next to Properties.*

## General

| Control | Lisp / sysvar | 2012 meaning, still true |
| --- | --- | --- |
| Scale | `_SC`, `DIMSCALE`, `USERR1`, `_PLOTSCALE` | Same sets `SETUP` uses. See [setup.md](setup.md) |
| Project | `_MEDPROJECT` | Stamped onto `BOM` rows |
| Tagging On | `_TAGOFF` (checked means tagging is on, `_TAGOFF` is nil) | Off → conduit / tray / cable skip the tag prompt (tag becomes NONE) |
| Size Override | `_SIZEOVR` / `_SIZEOVER` | On → place a fitting at the current size even if connected raceway is smaller. Off → MED sizes the fitting to the largest conduit/tray at the insert point |
| User Rotate | `_USERROT` | On → you type rotation for inserts. Off → MED autorotates. Turn on when autorotate guesses wrong |

Scale combo:

- Full Size 1=1
- Arch 3" through 1/16" = 1'-0"
- Eng 1" = 10' through 200'
- Metric 1=1 through 2500

Imperial plot scale is `1`. Metric plot scale is `25.4`. Changing scale writes `_SC`, `DIMSCALE`, `USERR1`, and `_PLOTSCALE`.

## Conduit

| Control | Lisp | Notes |
| --- | --- | --- |
| Conduit Bends | `_CONFILL` | On: `CONDUIT` fillets the polyline to radius `bend multiplier × size × plot scale`. Off: square corners so you can place L fittings / pull points |
| Bend Multiplier | `_MEDRADFAC` | Default 5. A 1" conduit with bends on gets a 5" radius |
| Size | `_CSIZE` (also `_ACSIZE` / `_CLETT` via getsize) | Set before you route. `CONSIZE` is the old DCL size picker; this combo is the daily control |

## Tray

| Control | Lisp | Notes |
| --- | --- | --- |
| Size | `_TRSIZE` | Width. Default 24" in `med.spc` (`_TRWIDTH` in the 2012 text; code uses `_TRSIZE`) |
| Depth | `_TRDEPTH` | Rail height. Default 6". Often a project spec, set once |
| Radius | `_TRRAD` (and `_TRFITTADD`) | Fitting radius. Default 24" |
| Tangent | `_TRTANFAC` / `_TRAYTANFAC` | Straight at each end of a fitting before the arc. MED cannot draw a true zero-tangent fitting; 0.0000001 is the 2012 workaround and still the idea |
| Flange | `_TRAYFLANGE` | Stored on tray xdata |
| Vertical Tray | `_VERTICALTRAY` | On: draw tray in side view (depth becomes the plan width). If every tray you draw is "the depth wide," this is probably on by mistake — clear it here or reopen the drawing |

Size lists come from lisp (`_CONSIZE_LIST`, `_TRAYSIZE_LIST`, …) with built-in fallbacks.

Defaults that are **not** on the palette still live in `med.spc`: default tray type/code, flex type, cable count (`_CABNUM`), default up/down distance (`_MEDDIST`, 10'), file-info block names, layer names, title block. Cable type/code is the [Cable palette](cable.md) (`CABLE` / `CABLEPALETTE`).
