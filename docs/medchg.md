# MEDCHG / MED Properties

`MEDCHG` now opens the MED Properties palette. Same palette: `MEDPROPERTIES`, `MEDPROPS`.

`C:MED` (`Support\medchg.lsp`) and `C:MC` (`Support\QKEY.lsp`) call `MEDCHG`.

Old DCL editor: `MEDCHG-CLASSIC` in `Support\medchg.lsp`.

![MED Properties palette](images/medchg.png)

MED Properties palette (MEDCHG).

## Palette

Dockable. Follows the implied pick set.

- Type dropdown works like AutoCAD Properties: All (n), or Conduit / Cable / Tray / Fitting / Equipment (n).
- Differing values show `*VARIES*`. Edit a field (Enter or leave the box) to write xdata on every selected item of the filtered type.
- Measure is a checkbox; mixed selection is the third / indeterminate state.
- Single-record entities stay on the palette.
- Multi-entity edits (or more than one MED record on an entity) use [MEDRECORDS](medrecords.md). No Add on a multi-entity grid. Palette **Edit records...** opens that grid.

## Fields by type

Xdata keys match the old MEDBuildXData / MEDCHG names.

| Type | Fields |
| --- | --- |
| Conduit | Tag, Size, Code, Distance, Measure |
| Cable | Tag, Related Tag, Alternate, Code, Distance, Measure |
| Tray | Tag, Size, Code, Distance, Depth, Measure, Flange |
| Fitting | Tag, Size, Alternate, Depth, Distance, Code, Flange |
| Equipment | Tag, Code |
