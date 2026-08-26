# Details / equipment

Equipment in MED is a **detail reference** — usually a block INSERT with `MED_EQUIP` xdata (tag + code). The block definition does not hold the xdata; the insertion does. Copies of that insert keep the record. `INSERT` from AutoCAD by block name does **not** attach MED data. Place through `DETAIL` / `LTG` / … or the CUI so the catalog row is applied.

`BOM` writes one `MEDProject` row per detail reference. Link those codes to your shop's detail sheets and you have a takeoff. Catalog columns for details: [database.md](database.md).

## Insert

`DETAIL` opens a DCL picker (Lighting, Grounding, Power, Instrument, Cable Tray, Communication, Junction Box, Pole Line). Each group is also a command that queries `MEDType` for that group:

| Command | Group |
| --- | --- |
| `LTG` | Lighting |
| `GND` | Grounding |
| `PWR` | Power |
| `INS` | Instrument |
| `TRY` | Cable tray details |
| `COM` | Communication |
| `JBX` | Junction box |
| `MSC` | Misc (in `meddetl.lsp`) |

A row with no `ITEM_GRP` does not appear in these lists. `ITEMKEY3` is the block (and slide) name. `USER2` is the insert function (`opt_eq_ins` is the usual). Blank `ITEMKEY3` with `opt_eq_ins` prompts you to pick an entity to attach the detail to.

`MEDSTRIP` removes xdata so a copied insert is graphics only.

The 2012 flyouts (receptacles, fluorescent, detectors) were CUI image menus. Use the CUI / ribbon if those buttons are loaded; the commands above are what Support still defines.

## Tray-related details

Tray hardware is sized to the tray. MED places a block on each side of the outline and a line between them. **The line holds the xdata** so you get one BOM row, not two. If you offset that line as a construction line, you just created extra detail occurrences — `MEDSTRIP` the extras.

See `TRAYEP` / `TRAYHD` / `TRAYHANG` / … in [tray.md](tray.md).

## Tagging details

`DETAG` places detail bubble `detbub2`. Pick the entity; MED fills detail number, drawing number, and typical count from `MEDType` (ITEMKEY1 / KEY2 and a count of matching references). Enter instead of picking an entity to type the attributes by hand.

`DETAG2` uses block `dtlhd1`.

`DETAGUPD` walks existing bubbles and shows current typical vs actual count in the drawing. Update selected tags. Relies on `med.spc`:

| Variable | Meaning | Default |
| --- | --- | --- |
| `_DETTYP` | Typical attribute tag and prefix length | `(list "TYP" 6)` for `(TYP. ` |
| `_DETNUM` | Detail number attribute | `DETNUM` |
| `_DETNUM1` / `_DETNUM1A` | Concatenated detailing | `TAGINFO1` / `TYPE` |
| `_DETBLK` | Bubble block name | `DETBUB2` |

Change those only if you change the bubble block. The lisp is in `QKEY.lsp` (`C:DETAG`) and `MEDCommands.lsp` (`C:DETAGUPD`).

## Lighting example (2012, still the workflow)

Place fixtures from the lighting list at intersections (running INT osnap). `DETAG` the typical. After you erase fixtures, `DETAGUPD` rather than hand-editing `(TYP. 9)` to `(TYP. 6)` on every bubble.
