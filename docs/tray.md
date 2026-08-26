# Cable tray

Cable tray is wide enough to 3D-check. MED draws a **centerline** (the data) plus outline linework. A myriad of widths, depths, radii, and fittings; codes come from `MEDType`.

The 2012 Cabletray toolbar is gone as a documented flyout. Type the commands or pick them from the CUI. 2012 called the horizontal offset `TROFF`; the live command is `TRAYOFF`.

## Two-point placement

Tray is installed the way it is drawn: two points. Use osnaps. MED does not preset them.

1. Set width, depth, radius (`MEDSETTINGS` or `TRAYSIZE`). Defaults in `med.spc`: 24" wide, 6" deep, 24" radius, Heavy Duty.
2. `TRAY`. Prompt: `Startpoint of <catalog description>:`, then `To Point:`.
3. Unless tagging is off: `CableTray Tag number <NONE>:`. Enter completes the command. Aborting before the tag leaves a bad entity — erase and place again.

The last width selected is used for new tray and fittings. A smaller fitting on a larger tray is bumped up to the tray width (then you place a reducer).

## Centerline

The centerline **is** the tray. Outline is graphics.

- `CF` — freeze/off the centerline layer (`MEDCENTER`) so it does not plot.
- `CN` — turn that layer back on.
- Do not erase the centerline. That deletes the BOM record.
- Do not TRIM the centerline. TRIM the outline only, so stacked elevations still look like one tray over another.
- Copy: copy the centerline, then `TRAYFIX`.
- Rebuild outline: erase outline, keep centerline, `TRAYFIX`.

When a command says "pick the tray," it means the centerline.

## Fittings

| Command | Fitting |
| --- | --- |
| `TRAY90` | 90° elbow (autorotate at INT) |
| `TRAY30` `TRAY45` `TRAY60` | Non-90 elbows. No autorotate. Place on centerline endpoints. `TRAYOFF` uses these for offsets |
| `TRAYTEE` | Tee at a perpendicular branch. Place the branch first if you want autorotate to aim the right way; else User Rotate |
| `TRAYCROSS` | Cross where two trays fully cross |
| `TRAYRE` | Reducer. Rotation: drag along the run or type 270 |
| `TRAYTEERE` `TRAYREL` `TRAYRER` | Tee/reducer variants |
| `TRAYV90` | Vertical 90 in plan. `Inside or <Outside>:` — inside = up, outside = down. Then angle of generation and tag |
| `TRAYDN` `TRAYUP` | Vertical drop/riser from a tray end. Default length 10'. Down = hidden X, up = continuous X |
| `VTRAY` `VTRAY30` `VTRAY45` `VTRAY60` `VTRAY90` | Side-view tray and elbows |

`TRAYDN` sets linetype HIDDEN2. If you cancel mid-command and the drawing goes hidden, `LINETYPE` current = BYLAYER, then CHANGE leftover entities to BYLAYER. Rare; noted because 2012 hit it.

Channel (smaller tray) uses `CHANNEL`, `CHAN30`…`CHAN90`, `CHANTEE`, `CHANCROSS`, `CHANOFF`, `CHANUP`, `CHANDN`, `CHANV90`. Strut: `STRUT`.

## Offsets

Distances are **center to center**.

| Command | View | What it does |
| --- | --- | --- |
| `TRAYOFF` | Plan, horizontal | Pick near the centerline end. Distance, then direction. No elevation change |
| `PTRAYOFF` | Plan, vertical | Elevation change (grade, pipe rack). Distance, 30/45/60/90, Up/Down |
| `VTRAYOFF` | Side view | Same idea in elevation |

Continue tray from the end of the fitting.

## Side view

`VTRAY` uses the same two-point method. Tag prompt still matters. Pair with `SECT` section marks ([tagging.md](tagging.md)). If the same run exists in plan and in section, `MEDSTRIP` the extra centerlines or you double-count the BOM.

## Edit

[MEDCHG](medchg.md) changes tag, type, size, depth, measure/distance. It does **not** redraw the outline. `TRAYFIX` rebuilds linework from the centerline (tray entities; 2012 said not fittings — the current `TRAYFIX` also attempts fitting outline).

`MEDLIST` / `DDMEDLIST` identify overlapping tray that looks the same on screen.

## Tag

`TTAG` — pick the **centerline**, then leader points. Fills tag, size, and prompts for elevation (default is the tray elevation). Block `traytag`. `TTAGS` is a variant.

## Hardware details

Catalog-driven tray hardware (expansion plate, hold-down, hanger, dropout, blind end, hinge) is placed with `TRAYEP`, `TRAYEG`, `TRAYHD`, `TRAYHANG`, `TRAYDROP`, `TRAYBLIND`, `TRAYHINGE`, `TRAYCON`. Those are detail occurrences — see [detail.md](detail.md). The connecting line between two side blocks is the data. Do not offset that line as a construction line without `MEDSTRIP` on the extra.

## 3D

`MAKE3DTRAY` — see [3d.md](3d.md).
