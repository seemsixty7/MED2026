# MED2026 docs

MED is an AutoCAD electrical and instrumentation toolkit. Material codes live on entities (xdata). Descriptions live in the catalog table `MEDType`. A bill of materials extract goes into `MEDProject`.

Windows x64. AutoCAD 2020 or later. MIT license.

Author: Clint Moore, PMP. Consulting: [mooredesign.net](https://mooredesign.net).

## Start here

- [What MED is](overview.md) — xdata vs catalog vs BOM
- [Install](install.md)
- [Database](database.md)
- [Drawing setup](setup.md) — `SETUP`, scale sets
- [Commands](commands.md) — full index, grouped like the 2012 guide

## Catalog, settings, properties (C# UI)

These replaced the 2012 DCL dialogs. Do not treat the old DCL screens as current.

- [MEDTYPE](medtype.md) — catalog grid (`MEDTYPES`)
- [MEDSETTINGS](medsettings.md) — conduit / tray / scale defaults (`MEDSET`)
- [Cable palette](cable.md) — type then cable (`CABLE`, `CABLEPALETTE`, `CABLESET`)
- [MEDCHG / MED Properties](medchg.md) — entity xdata (`MEDPROPERTIES`, `MEDPROPS`; `MED` and `MC` still call `MEDCHG`)
- [MEDRECORDS](medrecords.md) — handle-based multi-xdata grid (`MEDXDEDIT`)
- [MEDSHOWBOM](medshowbom.md) — current-drawing BOM browse (`MEDSHOW`, `MEDSHOWSUM`)

Classic DCL editor: `MEDCHG-CLASSIC` in `Support\medchg.lsp`.

## Draw

LISP in `Support` still routes raceway, places details, tags, and extracts BOM.

- [Conduit](conduit.md) — `CONDUIT`, bends, fittings, `CHGSIZE`, `MEDLIST`
- [Cable tray](tray.md) — two-point tray, centerline, offsets, fittings
- [Cable](cable.md) — `CABLE` palette (type then cable), related tag, `CABLE-CLASSIC`
- [Details / equipment](detail.md) — `DETAIL`, `LTG` / `GND` / `PWR` / `INS` / `TRY`, `DETAG`
- [Detail conduit (two-line)](detail-conduit.md) — `2LCON`, away / toward / break
- [Tagging](tagging.md) — `CTAG`, `TTAG`, balloons, section marks
- [3D extract](3d.md) — `MAKE3DTRAY`, `ESOLID`
- [Utilities](utilities.md) — text, layers, leaders, quick keys

## Screenshots

Real shots under `docs/images/`: `medshowbom.png`, `medproperties.png`, `medrecords.png`, `acad-ui.png`. Placeholders still noted for `medtype.png` and `medsettings.png`. Do not invent UI pictures. See [images/README.md](images/README.md).

## Source notes

`D:\MEDConsolidate\MEDDocs\UserGuide.docx` is an empty 2013 Word manual template. Not used.

These pages port the 2012 users guide (`MED 2012 Full Docs.doc`, 21 Mar 2013) where the workflow still matches MED2026. Toolbar-icon training, Access / `.dbf` / `MEDPACK`, and the MED 1.53 training-icon steps are obsolete and were not ported. When 2012 and 2026 disagree, 2026 wins.
