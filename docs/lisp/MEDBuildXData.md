# MEDBuildXData.lsp

`Support\MEDBuildXData.lsp` - Builders for MED xdata lists (conduit, cable, tray, fitting, equipment).

Loaded by MEDCore (order 15). 6 defun(s): 0 command(s), 6 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`bld_app`](#bld_app) | function |
| 122 | [`bld_conduit`](#bld_conduit) | function |
| 143 | [`bld_cable`](#bld_cable) | function |
| 160 | [`bld_tray`](#bld_tray) | function |
| 178 | [`bld_fitting`](#bld_fitting) | function |
| 203 | [`bld_equip`](#bld_equip) | function |

## bld_app

`(bld_app bld_appnm bld_code bld_size bld_tag bld_rtag bld_dist bld_alt bld_dpth bld_msr bld_flg / bld_xdlist)`  - line 2-119

Builds a MED xdata list (-3 group) for an app: code, size, tag, related tag, distance, alt, depth, measure flag.

- **Arguments**: `bld_appnm`, `bld_code`, `bld_size`, `bld_tag`, `bld_rtag`, `bld_dist`, `bld_alt`, `bld_dpth`, `bld_msr`, `bld_flg`
- **Returns**: value of the last expression: `bld_xdlist`
- **Side effects**: Globals set (not declared local): `bldnum`, `bldcnt`, `0.0`
- **Referenced**: 5

## bld_conduit

`(bld_conduit bld_code bld_size bld_tag bld_dist bld_msr / bld_xdlist)`  - line 122-136

function bulids data to be placed into conduits

- **Arguments**: `bld_code`, `bld_size`, `bld_tag`, `bld_dist`, `bld_msr`
- **Returns**: value of the last expression: `(setq bld_xdlist (bld_app _CONDUIT bld_code bld_size bld_tag nil bld_dist nil nil bld_msr nil ) )`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 15

## bld_cable

`(bld_cable bld_code bld_size bld_tag bld_rtag bld_dist bld_msr / bld_xdlist)`  - line 143-157

function bulids replacement data to be placed into cables

- **Arguments**: `bld_code`, `bld_size`, `bld_tag`, `bld_rtag`, `bld_dist`, `bld_msr`
- **Returns**: value of the last expression: `(setq bld_xdlist (bld_app _CABLE bld_code bld_size bld_tag bld_rtag bld_dist nil nil bld_msr nil ) )`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 9

## bld_tray

`(bld_tray bld_code bld_size bld_tag bld_dist bld_dpth bld_msr bld_flange / bld_xdlist)`  - line 160-174

function bulids replacement data to be placed into cable trays

- **Arguments**: `bld_code`, `bld_size`, `bld_tag`, `bld_dist`, `bld_dpth`, `bld_msr`, `bld_flange`
- **Returns**: value of the last expression: `(setq bld_xdlist (bld_app _TRAY bld_code bld_size bld_tag nil bld_dist nil bld_dpth bld_msr bld_flange ) )`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 12

## bld_fitting

`(bld_fitting bld_code bld_size bld_tag bld_alt bld_dpth bld_flange / bld_xdlist)`  - line 178-201

function bulids replacement data to be placed into fittings

- **Arguments**: `bld_code`, `bld_size`, `bld_tag`, `bld_alt`, `bld_dpth`, `bld_flange`
- **Returns**: value of the last expression: `(setq bld_xdlist (bld_app _FITTING bld_code bld_size bld_tag nil nil bld_alt bld_dpth nil bld_flange ) )`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 24

## bld_equip

`(bld_equip bld_code bld_tag / bld_xdlist)`  - line 203-217

Builds MED_EQUIP xdata for an equipment code and tag.

- **Arguments**: `bld_code`, `bld_tag`
- **Returns**: value of the last expression: `(setq bld_xdlist (bld_app _EQUIP bld_code nil bld_tag nil nil nil nil nil nil ) )`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 12

