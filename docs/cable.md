# Cable

`CABLE` draws an LWPOLYLINE with `MED_CABLE` xdata. Cables differ from conduit and tray: they have a **related tag** (`RTAG`) for the raceway they ride in (conduit tag or tray tag). The relationship is stored for the database only — nothing in the drawing auto-updates when the raceway changes.

The 2012 cable toolbar was mostly grounding sizes. That is still the common use. Size/code come from `_CABCODE` / `_CABNUM` (defaults in `med.spc`; Settings palette does not currently expose cable code — set it in lisp or pick a CUI button that sets the code then calls `CABLE`).

## Route

1. Pick the CUI size (or set `_CABCODE`) and run `CABLE`.
2. `Pick start point of <catalog description>:`, then `Pick point:` until Enter. Internally this is a PLINE.
3. `Cable Tag number <NONE>:`
4. `Cable Relate Tag <NONE>:` — the raceway tag, if any.

Osnap when connecting to other cables. Tagging off (`MEDSETTINGS`) fills both tags with NONE.

`RUN3DCABLE` is the same prompts on a `3DPOLY`.

## Up / down

Same idea as conduit: a block with a stored distance, Measure off. Insert from the CUI onto the cable with endpoint osnap. MED reads the cable type from the entity you insert on (so an up symbol on #2/0 stays #2/0 even if Settings still says 4/0).

## Edit

[MEDCHG](medchg.md) changes tag, related tag, count, code, distance/measure. Count `1.000` means one cable in the reference; raise it to represent several cables with one line.

`MCABLE` adds a cable record to an existing entity.
