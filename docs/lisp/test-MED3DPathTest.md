# MED3DPathTest.lsp

`tests\autocad\MED3DPathTest.lsp` - Test: MED3DPATHTEST sample runs (tests\autocad, APPLOAD manually).

**Not loaded by MEDCore.** APPLOAD it to use it. 7 defun(s): 1 command(s), 6 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 18 | [`med3dt-lw`](#med3dt-lw) | function |
| 26 | [`med3dt-2d`](#med3dt-2d) | function |
| 36 | [`med3dt-3d`](#med3dt-3d) | function |
| 45 | [`med3dt-conduit`](#med3dt-conduit) | function |
| 46 | [`med3dt-cable`](#med3dt-cable) | function |
| 48 | [`med3dt-go`](#med3dt-go) | function |
| 54 | [`c:MED3DPATHTEST`](#cmed3dpathtest) | command |

## med3dt-lw

`(med3dt-lw pts closed elev / ed)`  - line 18-24

MED3DPathTest.lsp - sample runs for Support\MED3DPath.lsp (not shipped). Needs MED loaded (MEDCore: xdatadd, bld_conduit, bld_cable, MED3DPath). APPLOAD this file in a scratch drawing (inches), then run MED3DPATHTEST. Draws the source runs on layer MED3DTEST at X >= 1000, builds solids with the same code M3D / C3D ...

- **Arguments**: `pts`, `closed`, `elev`
- **Returns**: value of the last expression: `(entlast)`
- **Side effects**: Entities: `entmake`
- **Referenced**: 2

## med3dt-2d

`(med3dt-2d pts elev)`  - line 26-34

MED3DPATHTEST: draws a 2D / 3D polyline.

- **Arguments**: `pts`, `elev`
- **Returns**: value of the last expression: `(entlast)`
- **Side effects**: Entities: `entmake`
- **Referenced**: 1

## med3dt-3d

`(med3dt-3d pts)`  - line 36-43

MED3DPATHTEST: draws a 2D / 3D polyline.

- **Arguments**: `pts`
- **Returns**: value of the last expression: `(entlast)`
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp); Entities: `entmake`
- **Referenced**: 6

## med3dt-conduit

`(med3dt-conduit e code size tag)`  - line 45-45

MED3DPATHTEST: adds conduit / cable xdata.

- **Arguments**: `e`, `code`, `size`, `tag`
- **Returns**: value of the last expression: `e`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 8

## med3dt-cable

`(med3dt-cable e code tag)`  - line 46-46

MED3DPATHTEST: adds conduit / cable xdata.

- **Arguments**: `e`, `code`, `tag`
- **Returns**: value of the last expression: `e`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 1

## med3dt-go

`(med3dt-go label e kind / r)`  - line 48-52

MED3DPATHTEST: converts one run and prints its plan.

- **Arguments**: `label`, `e`, `kind`
- **Returns**: value of the last expression: `(if (setq r (med3d-run e kind)) (med3d-print-plan (cadr r)) (princ "\n (no solid)"))`
- **Referenced**: 9

## c:MED3DPATHTEST

`(c:MED3DPATHTEST / b)`  - line 54-92

Draws sample runs in a scratch drawing and converts them (tests\autocad\MED3DPathTest.lsp; APPLOAD first). User entry: [MED3DPATHTEST](../command-reference.md#med3dpathtest).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Xdata: reads/writes xdata directly (-3 group / regapp); AutoCAD commands: `ZOOM`
- **Referenced**: 0

