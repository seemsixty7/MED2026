# MEDCore.lsp

`Support\MEDCore.lsp` - Loader: loads every MED lisp file in order, registers the xdata apps, sets core globals.

Loaded by MEDCore (order 3). 2 defun(s): 0 command(s), 2 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 7 | [`getmeddir`](#getmeddir) | function |
| 87 | [`MED_cur_set`](#med_cur_set) | function |

## getmeddir

`(getmeddir medprojectlineno)`  - line 7-24

Returns line N of Project.dat (MED dir, drawing dir, ...).

- **Arguments**: `medprojectlineno`
- **Returns**: value of the last expression: `(nth medprojectlineno meddirinfo)`
- **Side effects**: Globals set (not declared local): `projectfile`, `ofn`, `meddirinfo`
- **Referenced**: 4

## MED_cur_set

`(MED_cur_set CommandName)`  - line 87-89

Command-start hook stub: (setq nothing nil). MEDCore.lsp defines it after loading MEDFunctions.lsp, so this stub replaces the full med_cur_set - it is the one that runs. TODO: confirm with Clint that disabling the MED error handler this way is intended.

- **Arguments**: `CommandName`
- **Returns**: value of the last expression: `(setq nothing nil)`
- **Side effects**: Globals set (not declared local): `nothing`
- **Referenced**: 62
- **Duplicate**: also defined in Support\MEDFunctions.lsp:2788; MEDCore defines this stub AFTER loading MEDFunctions.lsp, so the stub wins

