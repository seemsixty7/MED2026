# MEDVariables.lsp

`Support\MEDVariables.lsp` - Default MED globals (project, tagging, scale, DB connection string, text style map). Overridden by med.spc.

Loaded by MEDCore (order 4). 1 defun(s): 0 command(s), 1 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 76 | [`MEDGetProjectNumber`](#medgetprojectnumber) | function |

## MEDGetProjectNumber

`(MEDGetProjectNumber)`  - line 76-78

Returns the project number. Customisation hook ("update this function to point to a custom project function").

- **Arguments**: none
- **Returns**: value of the last expression: `_MEDPROJECT`
- **Referenced**: 0

