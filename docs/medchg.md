# MEDCHG / MED Properties

`MEDCHG` now opens the MED Properties palette. Same palette: `MEDPROPERTIES`, `MEDPROPS`.

`C:MED` (`Support\medchg.lsp`) and `C:MC` (`Support\QKEY.lsp`, last definition) call `MEDCHG`.

Old DCL editor: `MEDCHG-CLASSIC` in `Support\medchg.lsp`. The 2012 `MEDCHANGE` / `MEDCHG` dialog is that DCL. Use the palette unless you have a reason to open classic.

![MED Properties palette](images/medproperties.png)

MED Properties palette (MEDCHG).

## Palette

Dockable. Follows the implied pick set.

- Type dropdown works like AutoCAD Properties: All (n), or Conduit / Cable / Tray / Fitting / Equipment (n).
- Differing values show `*VARIES*`. Edit a field (Enter or leave the box) to write xdata on every selected item of the filtered type.
- Measure is a checkbox; mixed selection is the third / indeterminate state.
- Single-record entities stay on the palette.
- Multi-entity edits (or more than one MED record on an entity) use [MEDRECORDS](medrecords.md). No Add on a multi-entity grid. Palette **Edit records...** opens that grid.

## Fields by type

Xdata keys match the old MEDBuildXData / MEDCHG names. Same layout the 2012 dialog taught:

| Type | Fields |
| --- | --- |
| Conduit | Tag, Size/Count, Code, Distance, Measure |
| Cable | Tag, Related Tag, Alternate (count), Code, Distance, Measure |
| Tray | Tag, Size/Count, Code, Distance, Depth, Measure, Flange |
| Fitting | Tag, Size/Count, Alternate, Depth, Distance, Code, Flange |
| Equipment | Tag, Code |

Size/Count is conduit/tray size, or cable quantity; Equipment has no Size.

Measure on: extract uses the entity length. Measure off: extract uses Distance (blocks such as conduit up/down cannot be measured — the checkbox will not stay on). Description is **not** stored; it is looked up from [MEDTYPE](medtype.md) by type+code.

You can add conduit, cable, tray, fitting, or equipment records on a single entity (classic dialog had Add buttons; the palette sends multi-record work to MEDRECORDS).

## What MEDCHG does not do

Changing a main conduit does **not** update up/down symbols that inherited tag/size at insert. Change those too, or use `CHGSIZE` for size on a selection set. Tray linework does not redraw when you change size in properties — size in xdata and the drawn outline can disagree until you `TRAYFIX` / redraw. See [conduit.md](conduit.md) and [tray.md](tray.md).
