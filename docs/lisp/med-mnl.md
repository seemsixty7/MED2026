# med.mnl

`Support\med.mnl` - Menu lisp loaded with med.cuix: MEDMENU, MEDPLAN, MEDDETAIL, MEDWIRING (menucmd switcher).

Loaded by MEDCore (order 28). 5 defun(s): 4 command(s), 1 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 8 | [`c:MEDMENU`](#cmedmenu) | command |
| 15 | [`c:MEDPLAN`](#cmedplan) | command |
| 18 | [`c:MEDDETAIL`](#cmeddetail) | command |
| 21 | [`c:MEDWIRING`](#cmedwiring) | command |
| 25 | [`medmenuset`](#medmenuset) | function |

## c:MEDMENU

`(c:MEDMENU)`  - line 8-14

Reloads the AutoCAD menu then MENULOADs med and shows the Plan pull-downs (legacy .mnu workflow). User entry: [MEDMENU](../command-reference.md#medmenu).

- **Arguments**: none
- **Returns**: value of the last expression: `(medmenuset 1)`
- **Side effects**: AutoCAD commands: `MENU`, `MENULOAD`
- **Referenced**: 0

## c:MEDPLAN

`(c:MEDPLAN)`  - line 15-17

Swaps the MED pull-down menus to the Plan set (med.mnl menucmd switcher). User entry: [MEDPLAN](../command-reference.md#medplan).

- **Arguments**: none
- **Returns**: value of the last expression: `(medmenuset 1)`
- **Referenced**: 0

## c:MEDDETAIL

`(c:MEDDETAIL)`  - line 18-20

Swaps the MED pull-down menus to the Detail set. User entry: [MEDDETAIL](../command-reference.md#meddetail).

- **Arguments**: none
- **Returns**: value of the last expression: `(medmenuset 2)`
- **Referenced**: 0

## c:MEDWIRING

`(c:MEDWIRING)`  - line 21-23

Swaps the MED pull-down menus to the Wiring Diagram set. User entry: [MEDWIRING](../command-reference.md#medwiring).

- **Arguments**: none
- **Returns**: value of the last expression: `(medmenuset 3)`
- **Referenced**: 0

## medmenuset

`(medmenuset medgrppos)`  - line 25-55

Switches the MED pull-downs to a group (1 Plans, 2 Details, 3 Wiring) via menucmd.

- **Arguments**: `medgrppos`
- **Returns**: value of the last expression: `(foreach medpop _MEDMENULIST (if (not medmenupos) (progn (menucmd (strcat "P" (itoa (setq popmenucnt (1+ popme...`
- **Side effects**: Globals set (not declared local): `popmenucnt`, `medmenupos`
- **Referenced**: 4

