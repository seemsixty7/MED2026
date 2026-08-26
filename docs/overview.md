# What MED is

MED helps you generate electrical plans, details, and wiring diagrams in AutoCAD. You draw raceway and equipment in the DWG. MED stores a small material record on each entity, looks up a description in the catalog, and can extract a bill of materials for the current drawing.

Windows x64. AutoCAD 2020 or later. MIT license.

Author: Clint Moore, PMP. Consulting: [mooredesign.net](https://mooredesign.net).

## Codes on entities, descriptions in the catalog

There are five material types:

| Type | Typical entity | What the drawing stores |
| --- | --- | --- |
| Conduit | LWPOLYLINE | Tag, size, code, distance, measure |
| Cable | LWPOLYLINE | Tag, count, code, related tag, distance, measure |
| Tray | LWPOLYLINE (centerline) | Tag, size, code, distance, depth, measure, flange |
| Fitting | INSERT (block) | Tag, size, code, alt, depth, flange |
| Equipment | Usually an INSERT | Tag, code |

The **code** is the only catalog key stored on the entity. The description is looked up in `MEDType` by type + code. That keeps the DWG from carrying warehouse text on every line.

Xdata application names (registered at load): `MED_CONDUIT`, `MED_CABLE`, `MED_TRAY`, `MED_FITTING`, `MED_EQUIP`. One entity can hold more than one MED record. Edit a single record on the [MED Properties](medchg.md) palette; several records (or several entities) use [MEDRECORDS](medrecords.md).

## Catalog vs BOM

Same split as the 2012 guide:

- **`MEDType`** is the warehouse. Unlimited catalog rows. Set this up before you draw. Command: [MEDTYPE](medtype.md).
- **`MEDProject`** is what this drawing used. Empty at install. Written when you run `BOM`. Browse with [MEDSHOWBOM](medshowbom.md).

`BOM` is not live. It deletes existing `MEDProject` rows for this drawing + project + path + Windows login, then walks every entity that has MED xdata and writes a new row per material record. If the [MEDSHOWBOM](medshowbom.md) grid is empty, run `BOM` first.

The 2012 guide used FoxPro/Access `.dbf` files (`MEDTYPE.dbf`, `PROJECT.dbf`) and a `MEDPACK` pack/reindex step. MED2026 uses SQLite (default) or SQL Server. See [database.md](database.md). There is no Access front end and no `MEDPACK`.

## Settings vs the drawing

[MEDSETTINGS](medsettings.md) (`MEDSET`) writes lisp globals for the **current drawing session**: conduit size and bends, tray width / depth / radius / tangent, tagging on/off, size override, user rotate, scale. Open another drawing and you get the defaults from `Support\med.spc` again (plus whatever that drawing already stored in `DIMSCALE` / `USERR1`).

`SETUP` still sets drawing scale, title block, and text styles. See [setup.md](setup.md).

## What still lives in LISP

Routing, fittings, details, tags, and `BOM` are still AutoLISP in `Support`. Type the command; the CUI / ribbon is a pick list, not a second product. Commands that still exist are listed in [commands.md](commands.md) and the topic pages.

Gone from MED2026 (2012 delivery, not how-tos):

- MED 1.53 training icon / "start in training mode"
- `MEDPLAN` / `MEDDETAIL` / `MEDWIRING` pull-down menu switchers — use `med.cuix` / `MEDRibbon.cuix`
- Access, `.dbf`, `MEDPACK`
- Toolbar-icon tutorials that assume the 2012 flyouts

Oneline / elementary symbol libraries are still in Support (`medwire1.slb`, `medwire2.slb`, CUI). `2LINE`, `3LINE`, `MEDLINE`, and `TSTRIP` still exist. There is no separate MEDWIRING workspace command.
