# MED3DMisc.lsp

`Support\MED3DMisc.lsp` - 3D junction box (3DJBOX).

Loaded by MEDCore (order 24). 1 defun(s): 1 command(s), 0 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 9 | [`c:3DJbox`](#c3djbox) | command |

## c:3DJbox

`(c:3DJbox)`  - line 9-42

3D junction box from corner, angle, height, width, depth. User entry: [3DJBOX](../command-reference.md#3djbox).

- **Arguments**: none
- **Returns**: value of the last expression: `(if JBoxStartPoint (progn (setq JBoxHeight (getreal "\nJBox Height: ") JBoxWidth (getreal "\nJBox Width: ") JB...`
- **Side effects**: Globals set (not declared local): `JBoxStartPoint`, `JboxEndPoint`, `JBoxHeight`, `JBoxWidth`, `JBoxDepth`, `JboxGenAngle`, `JBPt2`, `JBPt3`, `JBPt4`, `BoxEnt`, `DoorStartPoint`, `DSPt2`, `DSPt3`, `Dspt4`, `DoorEnt`; AutoCAD commands: `EXTRUDE`, `PLINE`, `UNION`
- **Referenced**: 0

