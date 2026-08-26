# Conduit

Conduit is plan-view raceway: an LWPOLYLINE with `MED_CONDUIT` xdata. Type and size come from the catalog (`MEDType`) plus the current [MEDSETTINGS](medsettings.md) size. Fittings are blocks with `MED_FITTING` xdata.

The 2012 Conduit toolbar is gone as a documented flyout. Type the commands or pick them from `med.cuix` / the MED ribbon. `MEDPLAN` (2012 pull-down switcher) was removed.

## Route

1. Set size (`MEDSETTINGS` or `CONSIZE`).
2. Set bends on/off and bend multiplier (`MEDSETTINGS`). Default multiplier is 5 × conduit size.
3. `CONDUIT`. Prompt: `Pick start point of <catalog description>:`, then `Pick point:` until Enter.
4. Unless tagging is off: `Conduit Tag number <NONE>:`. Empty → `NONE`.

Bends on: MED fillets the polyline to `filletrad = _MEDRADFAC * _CSIZE * _PLOTSCALE` after you finish picks. Bends off: square corners so L fittings and pull points fit.

`DEFINE` attaches the current size/code/tag to an existing polyline (joins a selection into a polyline if needed, optional fillet). Use it when you already drew the run.

`FLEX` places flex connectors and a spline-like run (block `1flexcon`). `FC` runs `FILLET` with radius from a prompted conduit size.

## Up / down

Plan symbols for vertical travel are blocks, not measurable polylines. Insert from the CUI (open up, solid up, down). MED prompts for length traveling up/down; default distance is `_MEDDIST` (10' in `med.spc`). That length is stored on the block (Measure off). Endpoint osnap onto the run.

The symbol inherits type, size, and tag from the conduit you insert on. Changing the main run later does **not** update the symbols. Edit them with [MEDCHG](medchg.md) or `CHGSIZE`.

## Change size and tag

[MEDCHG](medchg.md) edits one entity (or a pick set via the palette). Typical 2012 story still applies: pump grew, 1" `P-101` becomes 1½" `PC240` — pick the main line, change tag and size, then fix the up/down symbols.

`CHGSIZE` changes size on a selection set:

```
Select Entities to change Size:
Change Conduit or Fitting <CO>:
New Size for Selected Entities:
```

Default `<CO>` is conduit. Size is decimal inches (`1.5` not `1-1/2`).

## Fittings

Place from the CUI. Always osnap (END, INT, NEA). MED does not preset osnaps.

- **Size override off:** fitting size = largest conduit at the insert point, even if Settings says 1½".
- **Size override on:** fitting uses the current Settings size (oversized tee for splices).
- **User rotate on:** you type the rotation when autorotate guesses wrong.

Identify afterward with `MEDLIST` (command-line dump) or `DDMEDLIST` (DCL, Next through the set, can launch classic `MEDCHG` on the current entity). The 2012 typo `DDCPLIST` was `DDMEDLIST`.

## Tag

`CTAG` — select conduit, pick insert point. Pulls tag and size from xdata into block `contag` on layer `ECTAG`. See [tagging.md](tagging.md).

## Strip / add records

`MEDSTRIP` — selection set; removes all MED xdata from those entities (they leave the BOM).

`MCON` — add a conduit record to an existing polyline. `MFIT` / `MCABLE` / `MTRAY` / `MEQUIP` add the other types (`QKEY.lsp`).
