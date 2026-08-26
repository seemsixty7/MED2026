# Cable

`CABLE` is a C# command. It shows the Cable palette, sets `_CABCODE` and the current layer from the selected type, then draws an LWPOLYLINE with `MED_CABLE` xdata via lisp `med-cable-draw`. Cables differ from conduit and tray: they have a **related tag** (`RTAG`) for the raceway they ride in (conduit tag or tray tag). The relationship is stored for the database only — nothing in the drawing auto-updates when the raceway changes.

Conduit stays icon-based. Cables are picked on the palette: **Cable Type** (`MEDType.ITEM_GRP`) then **Cable** (`ITEMCODE` + `ITEMDESC`). `_CABNUM` (count) is left as-is from settings / `med.spc`.

## Cable Type

`ITEM_GRP` on `MEDType` rows with `ITEMTYPE` CABLE:

| Cable Type | ITEMCODE range | Layer (spaces stripped) |
| --- | --- | --- |
| Building Wire | 1–173 | `MEDCable-BuildingWire` |
| Tray Cable | 190–293 | `MEDCable-TrayCable` |
| Ground Cable | 300–338 | `MEDCable-GroundCable` |
| Residential Cable | 1000+ | `MEDCable-ResidentialCable` |

The layer is created if missing. Color and linetype stay AutoCAD default. Changing type or cable on the palette writes `_CABCODE` and sets `CLAYER`; `CABLE` sets the layer again before drawing.

## Commands

| Command | What it does |
| --- | --- |
| `CABLE` | Show palette, apply type layer + `_CABCODE`, then `med-cable-draw`. If no cable is selected yet, the palette stays up and you get a prompt — nothing is drawn. |
| `CABLEPALETTE` / `CABLESET` | Show the palette only. |
| `CABLE-CLASSIC` | Old lisp-only route (`c:cable-classic` in `Support\medcable.lsp`). Same draw body, no palette. |
| `RUN3DCABLE` | Same prompts on a `3DPOLY`, using current `_CABCODE` and the same type layer. |

Ribbon / CUI `CABLE` hits the .NET command (the macro name is `CABLE`, not a hardcoded lisp call). Grounding-size toolbar buttons still `(setq _CABCODE …) cable`; the palette refreshes to that code, then draws.

## Route

1. `CABLE` (or `CABLEPALETTE` then pick type/cable, then `CABLE`).
2. `Pick start point of <catalog description>:`, then `Pick point:` until Enter. Internally this is a PLINE.
3. `Cable Tag number <NONE>:`
4. `Cable Relate Tag <NONE>:` — the raceway tag, if any.

Osnap when connecting to other cables. Tagging off (`MEDSETTINGS`) fills both tags with NONE.

## Up / down

Same idea as conduit: a block with a stored distance, Measure off. Insert from the CUI onto the cable with endpoint osnap. MED reads the cable type from the entity you insert on (so an up symbol on #2/0 stays #2/0 even if Settings still says 4/0).

## Edit

[MEDCHG](medchg.md) changes tag, related tag, count, code, distance/measure. Count `1.000` means one cable in the reference; raise it to represent several cables with one line.

`MCABLE` adds a cable record to an existing entity.
