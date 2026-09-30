# med.spc

`Support\med.spc` - Default spec sheet (sizes, layers, title block, text); loaded last by MEDCore; defines c:loadtxt.

Loaded by MEDCore (order 27). 1 defun(s): 1 command(s), 0 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 167 | [`c:loadtxt`](#cloadtxt) | command |

## c:loadtxt

`(c:loadtxt)`  - line 167-182

Creates the older style set B250 B187 B125 T125 T125THIN T187 T937THIN T937 at _SC, then BLDSTL. MEDCore loads med.spc last, so this is the LOADTXT that runs. User entry: [LOADTXT](../command-reference.md#loadtxt).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: AutoCAD commands: `STYLE`
- **Referenced**: 15
- **Duplicate**: also defined in Support\medtext.lsp:1136; med.spc loads last in MEDCore, so this one wins

