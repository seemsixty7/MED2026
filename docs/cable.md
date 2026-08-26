# Cable

The Cable palette is C# (`MEDCABLE` / `CABLEPALETTE` / `CABLESET`). Drawing the polyline is still lisp `CABLE` (`c:cable` in `Support\medcable.lsp`), which calls `med-cable-draw`.

Cables differ from conduit and tray: they have a **related tag** (`RTAG`) for the raceway they ride in (conduit tag or tray tag). The relationship is stored for the database only. Nothing in the drawing auto-updates when the raceway changes.

Conduit stays icon-based. Cables are picked on the palette: **Cable Type** (`MEDType.ITEM_GRP`) then **Cable** (`ITEMCODE` + `ITEMDESC`). `_CABNUM` (count) is left as-is from settings / `med.spc`.

## Cable Type

`ITEM_GRP` on `MEDType` rows with `ITEMTYPE` CABLE:

| Cable Type | ITEMCODE range | Layer (spaces stripped) |
| --- | --- | --- |
| Building Wire | 1–173 | `MEDCable-BuildingWire` |
| Tray Cable | 190–293 | `MEDCable-TrayCable` |
| Ground Cable | 300–338 | `MEDCable-GroundCable` |
| Instrument Cable | 400–425 | `MEDCable-InstrumentCable` |
| Residential Cable | 1000+ | `MEDCable-ResidentialCable` |

Instrument Cable 400–425 is a generic catalog (shielded/unshielded TC, PLTC, thermocouple extension). Project specs can specialize those rows later.

The layer is created if missing. Color and linetype stay AutoCAD default. Changing type or cable on the palette writes `_CABCODE` and sets `CLAYER`. `CABLE` / Route Cable apply the layer again before drawing.

## Commands

| Command | What it does |
| --- | --- |
| `MEDCABLE` / `CABLEPALETTE` / `CABLESET` | Show the Cable palette only. |
| `CABLE` | Original lisp draw (`c:cable` → `med-cable-draw`). Uses current `_CABCODE`. |
| `RUN3DCABLE` | Same prompts on a `3DPOLY`, using current `_CABCODE` and the same type layer. |

Ribbon / CUI macros named `CABLE` hit the lisp command, not the palette. Grounding-size toolbar buttons still `(setq _CABCODE …) cable` and draw with lisp.

## Route

1. `MEDCABLE` (or `CABLEPALETTE`) and pick Cable Type then Cable.
2. **Route Cable** on the palette (sets `_CABCODE` and runs `CABLE`), or type `CABLE`.
3. `Pick start point of <catalog description>:`, then `Pick point:` until Enter. Internally this is a PLINE.
4. `Cable Tag number <NONE>:`
5. `Cable Relate Tag <NONE>:` — the raceway tag, if any.

If no cable is selected yet, Route Cable / `CABLE` prompts and nothing is drawn. The palette stays up.

Osnap when connecting to other cables. Tagging off (`MEDSETTINGS`) fills both tags with NONE.

## Up / down

Same idea as conduit: a block with a stored distance, Measure off. Insert from the CUI onto the cable with endpoint osnap. MED reads the cable type from the entity you insert on (so an up symbol on #2/0 stays #2/0 even if Settings still says 4/0).

## Edit

[MEDCHG](medchg.md) changes tag, related tag, count, code, distance/measure. Count `1.000` means one cable in the reference; raise it to represent several cables with one line.

`MCABLE` adds a cable record to an existing entity.