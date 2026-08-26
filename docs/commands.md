# Commands

Documented this pass: install + new C# UI. Old LISP routing/detail/oneline commands are not listed yet.

| Command | Aliases | What it does |
| --- | --- | --- |
| [MEDTYPE](medtype.md) | MEDTYPES | Excel-style grid on catalog table `MEDType` |
| [MEDSETTINGS](medsettings.md) | MEDSET | Docked C# palette; writes lisp globals and drawing scale |
| [MEDCHG](medchg.md) | MEDPROPERTIES, MEDPROPS, MED, MC | MED Properties palette (entity xdata) |
| MEDCHG-CLASSIC | | Old DCL editor in `Support\medchg.lsp` |
| [MEDRECORDS](medrecords.md) | MEDXDEDIT | Handle-based grid for multi-xdata picks |
| [MEDSHOWBOM](medshowbom.md) | MEDSHOW, MEDSHOWSUM | Current-drawing BOM with type filters |

`MED` is defined in `Support\medchg.lsp`. `MC` is defined in `Support\QKEY.lsp`. Both call `MEDCHG`.
