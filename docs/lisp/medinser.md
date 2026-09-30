# medinser.lsp

`Support\medinser.lsp` - Block insertion pipeline used by the menus (medblkins / MEDBLOCKINSERT, fittings, equipment, up/down conduit).

Loaded by MEDCore (order 20). 13 defun(s): 1 command(s), 12 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`setblkins`](#setblkins) | function |
| 6 | [`medblkins`](#medblkins) | function |
| 10 | [`c:MEDBlockInsert`](#cmedblockinsert) | command |
| 197 | [`eqp_ins`](#eqp_ins) | function |
| 212 | [`gen_ins`](#gen_ins) | function |
| 232 | [`ifitt_ins`](#ifitt_ins) | function |
| 276 | [`get_con_dist`](#get_con_dist) | function |
| 311 | [`icon_ins`](#icon_ins) | function |
| 339 | [`dcon_ins`](#dcon_ins) | function |
| 401 | [`dfitt_ins`](#dfitt_ins) | function |
| 431 | [`refitt_ins`](#refitt_ins) | function |
| 495 | [`get_bl_data`](#get_bl_data) | function |
| 542 | [`cab_ins`](#cab_ins) | function |

## setblkins

`(setblkins bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype)`  - line 2-4

Menu helper: stores insert data then runs MEDBLOCKINSERT.

- **Arguments**: `bl_lay`, `bl_name`, `bl_inspt`, `bl_rot`, `bl_scale`, `bl_instype`
- **Returns**: value of the last expression: `(setq MED_LASTUSEDINSERTDATA (list bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype))`
- **Side effects**: Globals set (not declared local): `MED_LASTUSEDINSERTDATA`
- **Called from menu macros**: 27 item(s), e.g. MEDRibbon.cuix Ribbon: Conduit > Conduit Up Solid
- **Referenced**: 27

## medblkins

`(medblkins bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype / bl_ent)`  - line 6-9

Menu helper: inserts a MED block (layer, name, point, rotation, scale, insert type) with break/rotation rules.

- **Arguments**: `bl_lay`, `bl_name`, `bl_inspt`, `bl_rot`, `bl_scale`, `bl_instype`
- **Returns**: value of the last expression: `(C:MEDBlockInsert)`
- **Side effects**: Globals set (not declared local): `MED_LASTUSEDINSERTDATA`
- **Called from menu macros**: 746 item(s), e.g. MEDRibbon.cuix Ribbon: Cables > Ground Cable Down
- **Referenced**: 498

## c:MEDBlockInsert

`(c:MEDBlockInsert / bl_lay bl_name bl_inspt bl_rot bl_scale bl_instype bl_ent)`  - line 10-196

Block insert used by the fitting/detail menu pipeline (setblkins data, break + rotation). User entry: [MEDBLOCKINSERT](../command-reference.md#medblockinsert).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `TR_MAIN`, `attre`, `storsize`, `_CSIZE`, `medins_prmpt`, `curr_lay`, `blnm`, `meddwgfind`, `medoptfind`, `RL_SS`, `RL_SS_DATA`, `NEW_BLNAME`, `_ZERO`; Layers: `bl_lay` (LAYER command / CLAYER); AutoCAD commands: `INSERT`
- **Referenced**: 2

## eqp_ins

`(eqp_ins genent / xdlist)`  - line 197-206

Equipment insert worker (break + xdata).

- **Arguments**: `genent`
- **Returns**: value of the last expression: `(xdatadd genent xdlist)`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 4

## gen_ins

`(gen_ins genent / xdlist)`  - line 212-226

** gen_ins is a function specifically for general insertions

- **Arguments**: `genent`
- **Returns**: value of the last expression: `(xdatadd genent xdlist)`
- **Side effects**: Xdata: writes xdata
- **Referenced**: 2

## ifitt_ins

`(ifitt_ins ifittent dcon_ss / xdlist)`  - line 232-269

** ifitt_ins is a function for inserting independent fittings

- **Arguments**: `ifittent`, `dcon_ss`
- **Returns**: value of the last expression: `(setq _TAGSUPRESS nil)`
- **Side effects**: Globals set (not declared local): `tss`, `r_val`, `dconsize`, `con_tag`, `con_code`, `_TAGSUPRESS`; Xdata: writes xdata
- **Referenced**: 8

## get_con_dist

`(get_con_dist spt condir)`  - line 276-303

Asks the distance for a conduit going up or down (length stored on the block).

- **Arguments**: `spt`, `condir`
- **Returns**: value of the last expression: `r_dist`
- **Side effects**: Globals set (not declared local): `z_dist`, `r_dist`, `_PROMPTFORCABLE`, `_MEDDIST`
- **Referenced**: 6
- **Duplicate**: also defined in tests\autocad\MEDCBGrid.lsp:173; this definition loads last and wins

## icon_ins

`(icon_ins iconent pt con_dir / xdlist con_tag condist)`  - line 311-331

** icon_ins is a function for inserting a independent conduit traveling up or down in the Z coordinate direction. Will prompt user for Tag info and distance of conduit traveled.

- **Arguments**: `iconent`, `pt`, `con_dir`
- **Returns**: value of the last expression: `(xdatadd iconent xdlist)`
- **Side effects**: Globals set (not declared local): `med_dir_con`; Xdata: writes xdata
- **Referenced**: 1

## dcon_ins

`(dcon_ins iconent pt con_dir dcon_ss / xdlist dconsize con_tag con_code r_val)`  - line 339-393

** dcon_ins is a function used for inserting blocks that are dependent in size based on the entity inserted on. Will retrieve xdata from host entity if exist.

- **Arguments**: `iconent`, `pt`, `con_dir`, `dcon_ss`
- **Returns**: value of the last expression: `(addvtraydata iconent verticaldata)`
- **Side effects**: Globals set (not declared local): `med_dir_con`, `verticaldata`, `condist`; Xdata: writes xdata
- **Referenced**: 9

## dfitt_ins

`(dfitt_ins dfittent dcon_ss / xdlist dfittsize r_val)`  - line 401-429

** dfitt_ins is a function for inserting dependent fittings that do not require the size of entity inserted upon.

- **Arguments**: `dfittent`, `dcon_ss`
- **Returns**: value of the last expression: `(xdatadd dfittent xdlist)`
- **Side effects**: Globals set (not declared local): `con_tag`; Xdata: writes xdata
- **Referenced**: 2

## refitt_ins

`(refitt_ins dfittent dcon_ss typelist depth / xdlist dfittsize r_val)`  - line 431-489

Reducing fitting insert: asks reduce-to size, breaks conduit, adds xdata.

- **Arguments**: `dfittent`, `dcon_ss`, `typelist`, `depth`
- **Returns**: value of the last expression: `(xdatadd dfittent xdlist)`
- **Side effects**: Globals set (not declared local): `con_tag`, `rfittsize`, `rsizelist`, `_TYPE`, `_DEPTH`; Xdata: writes xdata
- **Prompts**: `Size to:`
- **Referenced**: 5

## get_bl_data

`(get_bl_data med_bl_name / d1 d2 d3 d4)`  - line 495-539

This function will return a list value of distances for a blockname and its rotation specification

- **Arguments**: `med_bl_name`
- **Returns**: value of the last expression: `(setq rt_list (list d1 d2 d3 d4 rt_spec))`
- **Side effects**: Globals set (not declared local): `bldatafn`, `fn`, `bnamelen`, `lndata`, `tblname`, `bl_found`, `rt_spec`, `rt_list`
- **Referenced**: 10

## cab_ins

`(cab_ins iconent pt con_dir dcon_ss / xdlist dconsize con_tag con_code r_val)`  - line 542-592

Cable insert at a fitting (related tag prompt).

- **Arguments**: `iconent`, `pt`, `con_dir`, `dcon_ss`
- **Returns**: value of the last expression: `(xdatadd iconent xdlist)`
- **Side effects**: Globals set (not declared local): `med_dir_con`, `_PROMPTFORCABLE`, `condist`, `cab_rtag`; Xdata: writes xdata, reads xdata
- **Prompts**: `Cable Relate Tag <NONE>:`
- **Referenced**: 2

