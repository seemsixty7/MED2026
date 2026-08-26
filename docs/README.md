# MED2026 docs

MED is an AutoCAD electrical and instrumentation toolkit. Material codes live on entities (xdata). Descriptions live in the catalog table `MEDType`. A bill of materials extract goes into `MEDProject`.

Windows x64. AutoCAD 2020 or later. MIT license.

Author: Clint Moore, PMP. Consulting: [mooredesign.net](https://mooredesign.net).

## Layout

This pass is install, the database, and the new C# UI. Old LISP routing/detail/oneline commands are not documented here yet.

- [Install](install.md)
- [Database](database.md)
- [Commands](commands.md)
  - [MEDTYPE](medtype.md)
  - [MEDSETTINGS](medsettings.md)
  - [MEDCHG / MED Properties](medchg.md)
  - [MEDRECORDS](medrecords.md)
  - [MEDSHOWBOM](medshowbom.md)

Screenshot filenames are placeholders under `docs/images/`. Drop real PNGs there. Do not invent UI pictures. `medshowbom.png` is present; the rest still need dedicated shots. See [images/README.md](images/README.md).

## Source notes

`D:\MEDConsolidate\MEDDocs\UserGuide.docx` is an empty 2013 Word manual template. Not used. Do not port its TOC or "how to customize this manual" filler.

`D:\MEDConsolidate\MEDDocs\MED 2012 Full Docs.doc` (858 KB, 2013-03-21) extracted with Python `olefile` (no Word COM). Real facts from that 2012 users guide are reused here: catalog vs BOM, codes on the entity / descriptions in MEDTYPE, MEDTYPE / MEDCHG / MEDSET / SHOW, scale sets (Full / Architectural / Engineering). Toolbar tutorials, Access / `.dbf` / `MEDPACK`, and MED 1.53 training-icon steps are obsolete and were not ported.

## Screenshots needed

1. MEDTYPE grid
2. MED Settings palette with scale combo
3. MED Properties (MEDCHG)
4. MEDRECORDS grid + Show halo
5. MEDSHOWBOM dialog
