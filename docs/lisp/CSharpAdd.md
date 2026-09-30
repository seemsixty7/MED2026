# CSharpAdd.lsp

`Support\CSharpAdd.lsp` - MED-DotNet loader and the lisp<->.NET symbol bridge (MED-GetSym / MED-SetSym / MEDDO).

Loaded by MEDCore (order 1). 9 defun(s): 0 command(s), 9 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 4 | [`MED-DotNet-Ready`](#med-dotnet-ready) | function |
| 8 | [`MED-NetLoad`](#med-netload) | function |
| 42 | [`MED-DotNet-Startup`](#med-dotnet-startup) | function |
| 48 | [`S::STARTUP`](#sstartup) | function |
| 52 | [`MED-GetSym`](#med-getsym) | function |
| 53 | [`MED-SetSym`](#med-setsym) | function |
| 54 | [`MEDGETSYM`](#medgetsym) | function |
| 55 | [`MEDSETSYM`](#medsetsym) | function |
| 56 | [`MEDDO`](#meddo) | function |

## MED-DotNet-Ready

`(MED-DotNet-Ready)`  - line 4-6

T when MED-DotNet lisp functions are registered (overridden later by MEDDatabase.lsp copy).

- **Arguments**: none
- **Returns**: value of the last expression: `(member (type processsqlstatementNET) '(EXRXSUBR SUBR USUBR EXSUBR))`
- **Referenced**: 14
- **Duplicate**: also defined in Support\MEDDatabase.lsp:11; replaced at load time by Support\MEDDatabase.lsp:11

## MED-NetLoad

`(MED-NetLoad / p err oldfd)`  - line 8-39

NETLOADs MED-DotNet.dll from the support path if not already loaded.

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## MED-DotNet-Startup

`(MED-DotNet-Startup)`  - line 42-44

Startup hook: loads MED-DotNet and runs its init.

- **Arguments**: none
- **Returns**: value of the last expression: `(MED-NetLoad)`
- **Referenced**: 3

## S::STARTUP

`(S::STARTUP)`  - line 48-48 (nested defun)

AutoCAD startup hook (appended by CSharpAdd.lsp) that runs MED-DotNet-Startup.

- **Arguments**: none
- **Returns**: value of the last expression: `(MED-DotNet-Startup)`
- **Referenced**: 5

## MED-GetSym

`(MED-GetSym s)`  - line 52-52

Returns the value of a lisp symbol by name. Called from the MED-DotNet MED Settings palette via Application.Invoke.

- **Arguments**: `s`
- **Returns**: value of the last expression: `(eval (read s))`
- **Referenced**: 3

## MED-SetSym

`(MED-SetSym s v)`  - line 53-53

Sets a lisp symbol by name (bridge used by MED-DotNet to push values into lisp).

- **Arguments**: `s`, `v`
- **Returns**: value of the last expression: `v`
- **Referenced**: 2

## MEDGETSYM

`(MEDGETSYM s)`  - line 54-54

Returns the value of a lisp symbol by name (bridge for MED-DotNet).

- **Arguments**: `s`
- **Returns**: value of the last expression: `(MED-GetSym s)`
- **Referenced**: 0

## MEDSETSYM

`(MEDSETSYM s v)`  - line 55-55

Sets a lisp symbol by name (bridge used by MED-DotNet to push values into lisp).

- **Arguments**: `s`, `v`
- **Returns**: value of the last expression: `(MED-SetSym s v)`
- **Referenced**: 0

## MEDDO

`(MEDDO e / r)`  - line 56-65

Evaluates a lisp expression passed from MED-DotNet.

- **Arguments**: `e`
- **Returns**: value of the last expression: `(if (vl-catch-all-error-p r) (progn (princ (strcat "\nMED Settings: " (vl-catch-all-error-message r))) nil ) r...`
- **Referenced**: 1

