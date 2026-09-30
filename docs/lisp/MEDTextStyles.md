# MEDTextStyles.lsp

`Support\MEDTextStyles.lsp` - Text style creation / height helpers.

Loaded by MEDCore (order 10). 2 defun(s): 0 command(s), 2 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 1 | [`MEDSetTextStyleHeight`](#medsettextstyleheight) | function |
| 12 | [`MEDMakeTextStyle`](#medmaketextstyle) | function |

## MEDSetTextStyleHeight

`(MEDSetTextStyleHeight StyleName NewHeight)`  - line 1-11

Sets a text style height (ActiveX).

- **Arguments**: `StyleName`, `NewHeight`
- **Returns**: value of the last expression: `(if (vl-catch-all-error-p StyleObject) (princ "\nStyle Not Found") (vla-put-height StyleObject NewHeight) )`
- **Side effects**: Globals set (not declared local): `AcadObject`, `AcadDocument`, `DocTextStyles`, `StyleObject`
- **Referenced**: 2

## MEDMakeTextStyle

`(MEDMakeTextStyle StyleDataList)`  - line 12-30

Creates a text style from (name font height width ...).

- **Arguments**: `StyleDataList`
- **Returns**: value of the last expression: `(if (vl-catch-all-error-p StyleObject) (princ "\nUnable To Create Text Style") (progn (vla-put-height StyleObj...`
- **Side effects**: Globals set (not declared local): `TextStyleName`, `TextStyleFont`, `TextStyleHeight`, `TextStyleWidth`, `AcadObject`, `AcadDocument`, `DocTextStyles`, `StyleObject`
- **Referenced**: 2

