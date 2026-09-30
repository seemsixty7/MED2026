# MEDDatabase.lsp

`Support\MEDDatabase.lsp` - Database bridge: MEDProcessSQLStatement over ProcessSQLStatementNET; catalog lookups.

Loaded by MEDCore (order 11). 7 defun(s): 0 command(s), 7 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`MEDUserStatus`](#meduserstatus) | function |
| 11 | [`MED-DotNet-Ready`](#med-dotnet-ready) | function |
| 14 | [`MED-EnsureDotNet`](#med-ensuredotnet) | function |
| 27 | [`MEDProcessSQLStatement`](#medprocesssqlstatement) | function |
| 38 | [`ProcessSQLStatement`](#processsqlstatement) | function |
| 42 | [`med_getdesc`](#med_getdesc) | function |
| 52 | [`bld_data_list`](#bld_data_list) | function |

## MEDUserStatus

`(MEDUserStatus)`  - line 2-10

Queries MEDUsers for the current Windows user and sets _MEDAdministrativeUser.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (and CheckUserResults (> (length CheckUserResults) 1)) (setq _MEDAdministrativeUser T) (setq _MEDAdministr...`
- **Side effects**: Globals set (not declared local): `CheckUserStatement`, `CheckUserResults`, `_MEDAdministrativeUser`; DB: `medprocesssqlstatement`
- **Referenced**: 3

## MED-DotNet-Ready

`(MED-DotNet-Ready)`  - line 11-13

Same test as CSharpAdd.lsp (loads later, so this one wins).

- **Arguments**: none
- **Returns**: value of the last expression: `(member (type processsqlstatementNET) '(EXRXSUBR SUBR USUBR EXSUBR))`
- **Referenced**: 14
- **Duplicate**: also defined in Support\CSharpAdd.lsp:4; this definition loads last and wins

## MED-EnsureDotNet

`(MED-EnsureDotNet / p err)`  - line 14-26

Loads MED-DotNet if needed; warns when the DB bridge is missing.

- **Arguments**: none
- **Returns**: value of the last expression: `(MED-DotNet-Ready)`
- **Referenced**: 1

## MEDProcessSQLStatement

`(MEDProcessSQLStatement SQLStatementToProcess)`  - line 27-36

Runs a SQL statement through ProcessSQLStatementNET; returns rows (header row first).

- **Arguments**: `SQLStatementToProcess`
- **Returns**: value of the last expression: `(if (not (MED-EnsureDotNet)) (progn (princ "\nMEDProcessSQLStatement: ProcessSQLStatementNET is not loaded.") ...`
- **Side effects**: DB: `processsqlstatementnet`
- **Referenced**: 24

## ProcessSQLStatement

`(ProcessSQLStatement SQLStatementToProcess)`  - line 38-40

Legacy name: calls MEDProcessSQLStatement.

- **Arguments**: `SQLStatementToProcess`
- **Returns**: value of the last expression: `(MEDProcessSQLStatement SQLStatementToProcess)`
- **Side effects**: DB: `medprocesssqlstatement`
- **Referenced**: 1

## med_getdesc

`(med_getdesc AppType LookupCode)`  - line 42-51

Returns the MEDType description for an item type and code.

- **Arguments**: `AppType`, `LookupCode`
- **Returns**: value of the last expression: `mgd-returndata`
- **Side effects**: Globals set (not declared local): `mgd-sqlstatement`, `mgd-resultset`, `mgd-returndata`; DB: `medprocesssqlstatement`
- **Referenced**: 4

## bld_data_list

`(bld_data_list bdl_medtype)`  - line 52-63

Returns the MEDType rows for an item type (code lists for dialogs).

- **Arguments**: `bdl_medtype`
- **Returns**: value of the last expression: `bdl_returnlist`
- **Side effects**: Globals set (not declared local): `bdl_SQLStatement`, `bdl_datalist`, `bdl_returnlist`; DB: `medprocesssqlstatement`
- **Referenced**: 5

