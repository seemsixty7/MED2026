# MEDSETTINGS

Commands: `MEDSETTINGS`, `MEDSET`.

Docked C# palette ("MED Settings"). Writes lisp globals for the current drawing session. Same role as the old MEDSET dialog: conduit, tray, and scale defaults used while you draw.

![MED Settings palette](images/medsettings.png)

MED Settings palette with scale combo.

## General

| Control | Lisp / sysvar |
| --- | --- |
| Scale | `_SC`, `DIMSCALE`, `USERR1`, `_PLOTSCALE` |
| Project | `_MEDPROJECT` |
| Tagging On | `_TAGOFF` (checked means tagging is on, `_TAGOFF` is nil) |
| Size Override | `_SIZEOVR` / `_SIZEOVER` |
| User Rotate | `_USERROT` |

Scale combo is the same set SETUP uses:

- Full Size 1=1
- Arch 3" through 1/16" = 1'-0"
- Eng 1" = 10' through 200'
- Metric 1=1 through 2500

Imperial plot scale is `1`. Metric plot scale is `25.4`. Changing scale writes `_SC`, `DIMSCALE`, `USERR1`, and `_PLOTSCALE`.

## Conduit

| Control | Lisp |
| --- | --- |
| Conduit Bends | `_CONFILL` |
| Bend Multiplier | `_MEDRADFAC` |
| Size | `_CSIZE` (also `_ACSIZE` / `_CLETT` via getsize) |

## Tray

| Control | Lisp |
| --- | --- |
| Size | `_TRSIZE` |
| Depth | `_TRDEPTH` |
| Radius | `_TRRAD` (and `_TRFITTADD`) |
| Tangent | `_TRTANFAC` / `_TRAYTANFAC` |
| Flange | `_TRAYFLANGE` |
| Vertical Tray | `_VERTICALTRAY` |

Size lists come from lisp (`_CONSIZE_LIST`, `_TRAYSIZE_LIST`, …) with built-in fallbacks.
