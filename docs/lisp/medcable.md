# medcable.lsp

`Support\medcable.lsp` - CABLE and RUN3DCABLE.

Loaded by MEDCore (order 13). 3 defun(s): 2 command(s), 1 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 3 | [`med-cable-draw`](#med-cable-draw) | function |
| 37 | [`c:cable`](#ccable) | command |
| 44 | [`c:run3dcable`](#crun3dcable) | command |

## med-cable-draw

`(med-cable-draw / conent conpt conqty cabtag cabreltag ptprompt xdlist)`  - line 3-36

Draw body used by CABLE.

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Xdata: writes xdata; AutoCAD commands: `LINETYPE`, `PLINE`
- **Prompts**: `Pick point:`; `Cable Tag number <NONE>:`; `Cable Relate Tag <NONE>:`
- **Referenced**: 2

## c:cable

`(c:cable)`  - line 37-43

Draws a cable run (MED_CABLE xdata, tag + related tag). Palette "Route Cable" runs this. User entry: [CABLE](../command-reference.md#cable).

- **Arguments**: none
- **Returns**: value of the last expression: `(med-cable-draw)`
- **Referenced**: 2

## c:run3dcable

`(c:run3dcable / conent conpt conqty cabtag cabreltag ptprompt xdlist)`  - line 44-83

Cable on a 3DPOLY using the current _CABCODE and cable-type layer. User entry: [RUN3DCABLE](../command-reference.md#run3dcable).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Xdata: writes xdata; AutoCAD commands: `3DPOLY`, `LINETYPE`
- **Referenced**: 1

