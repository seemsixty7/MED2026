# Drawing setup

Drawing setup is still required before you route: scale, title block, text heights, layers. `SETUP` does that. Command: `SETUP` (`Support\medsetup.lsp`).

The 2012 main-toolbar icon and MED 1.53 training icon are gone. Type `SETUP`, or pick it from the MED CUI if your profile loaded `med.cuix`.

## ATTDIA

Attribute prompts at the command line are noisy. Set `ATTDIA` to `1` so title-block attributes use a dialog:

```
Command: ATTDIA
New value for ATTDIA <0>: 1
```

## Scale sets

`SETUP` asks for a scale factor. Three imperial sets plus metric, same idea as 2012, now also on the [MEDSETTINGS](medsettings.md) scale combo:

| Set | Examples |
| --- | --- |
| Full | 1 = 1 |
| Architectural | 3" through 1/16" = 1'-0" |
| Engineering | 1" = 10' through 200' |
| Metric | 1 = 1 through 2500 |

Imperial plot scale is `1`. Metric plot scale is `25.4`. Changing scale writes `_SC`, `DIMSCALE`, `USERR1`, and `_PLOTSCALE`.

The 2012 tutorial used 1/4" = 1'-0" Architectural. That is still a valid pick. Use whatever the sheet needs.

## Title block and file info

`SETUP` inserts the title block named in `Support\med.spc` (`MED_TBLK`, currently `TITLE_D2021`) and prompts for insertion point and rotation. Default tutorial values were `0,0` and rotation `0`.

It then inserts a file-info block (`_FDBLOCK`, default `FILEINFO`). `FD` fills filename, scale, date, and the last person to update it. Run `FD` again to refresh. `DD` (or AutoCAD `ATTEDIT`) edits title-block attributes.

If the title block already exists, `SETUP` rescales it and resets text styles for the new scale. Existing text in the drawing is **not** auto-rescaled — use AutoCAD `SCALE` or `XT` (text style convert) from [utilities.md](utilities.md).

`SETLIM` and `SETPLOT` are related setup helpers in `medsetup.lsp`. `BLDIST` sets a baseline distance used by setup geometry.

## After setup

1. [MEDSETTINGS](medsettings.md) for conduit / tray defaults this session.
2. [MEDTYPE](medtype.md) if the catalog is not already loaded for the shop.
3. Draw. See [conduit.md](conduit.md), [tray.md](tray.md), [cable.md](cable.md), [detail.md](detail.md).
