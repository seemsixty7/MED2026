# meddetl.lsp

`Support\meddetl.lsp` - Details: DETAIL dialog and group shortcuts, j-box hubs.

Loaded by MEDCore (order 19). 13 defun(s): 9 command(s), 4 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:detail`](#cdetail) | command |
| 52 | [`select_detail`](#select_detail) | function |
| 82 | [`set_detail`](#set_detail) | function |
| 114 | [`do_request`](#do_request) | function |
| 189 | [`c:gnd`](#cgnd) | command |
| 192 | [`c:ltg`](#cltg) | command |
| 195 | [`c:pwr`](#cpwr) | command |
| 198 | [`c:ins`](#cins) | command |
| 201 | [`c:try`](#ctry) | command |
| 204 | [`c:com`](#ccom) | command |
| 207 | [`c:jbx`](#cjbx) | command |
| 210 | [`c:msc`](#cmsc) | command |
| 218 | [`jbhub`](#jbhub) | function |

## c:detail

`(c:detail)`  - line 2-50

DCL detail picker by MEDType group; inserts the block with MED_EQUIP xdata. User entry: [DETAIL](../command-reference.md#detail).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `index_val`, `result`
- **Referenced**: 0

## select_detail

`(select_detail descript d_type)`  - line 52-80

DETAIL dialog: select / set the detail item.

- **Arguments**: `descript`, `d_type`
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `RESULT_LIST`, `index_val`, `result`; DB: `bld_dtl_list`
- **Referenced**: 16

## set_detail

`(set_detail l_index)`  - line 82-113

DETAIL dialog: select / set the detail item.

- **Arguments**: `l_index`
- **Returns**: value of the last expression: `(if (> detl_item -1) (progn (setq ITM_SELECTED (nth detl_item RESULT_LIST) itm_image (nth 3 ITM_SELECTED) ) (s...`
- **Side effects**: Globals set (not declared local): `trim`, `cnt`, `item`, `detl_item`, `ITM_SELECTED`, `itm_image`, `max_x`, `max_y`
- **Referenced**: 1

## do_request

`(do_request arglist / funcfound)`  - line 114-187

DETAIL: inserts the chosen detail block with xdata.

- **Arguments**: `arglist`
- **Returns**: value of the last expression: `(setq _MATCODE nil)`
- **Side effects**: Globals set (not declared local): `layset`, `attval`, `blkname`, `matcode`, `_MATCODE`, `funcname`, `BLNAMEGOOD`, `t1`, `TAT_VAL`
- **Referenced**: 1

## c:gnd

`(c:gnd)`  - line 189-191

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [GND](../command-reference.md#gnd).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Grounding" "GND")`
- **Referenced**: 0

## c:ltg

`(c:ltg)`  - line 192-194

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [LTG](../command-reference.md#ltg).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Lighting" "LTG")`
- **Referenced**: 0

## c:pwr

`(c:pwr)`  - line 195-197

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [PWR](../command-reference.md#pwr).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Power" "PWR")`
- **Referenced**: 0

## c:ins

`(c:ins)`  - line 198-200

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [INS](../command-reference.md#ins).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Instrument" "INS")`
- **Referenced**: 0

## c:try

`(c:try)`  - line 201-203

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [TRY](../command-reference.md#try).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Cable Tray" "TRY")`
- **Referenced**: 0

## c:com

`(c:com)`  - line 204-206

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [COM](../command-reference.md#com).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Communication" "COM")`
- **Referenced**: 0

## c:jbx

`(c:jbx)`  - line 207-209

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [JBX](../command-reference.md#jbx).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Junction Box" "JBX")`
- **Referenced**: 0

## c:msc

`(c:msc)`  - line 210-212

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc). User entry: [MSC](../command-reference.md#msc).

- **Arguments**: none
- **Returns**: value of the last expression: `(select_detail "Miscellaneous" "MSC")`
- **Referenced**: 0

## jbhub

`(jbhub maxsz maxstr bl inspt ang / pt pt1 pt2 apt ans)`  - line 218-296

this function inserts jbox hub plates and hubs as required per user input but does not allow creation of jboxes that are non existance

- **Arguments**: `maxsz`, `maxstr`, `bl`, `inspt`, `ang`
- **Returns**: value of the last expression: `(if (<= _CSIZE maxsz) (progn (initget 1 maxstr) (setq ans (getkword (strcat "\nNumber of hubs " maxstr ":"))) ...`
- **Side effects**: Globals set (not declared local): `blhub`, `_FITTCODE`, `_TAGSUPRESS`; Layers: `_MEDDETFIT`
- **Prompts**: `Invalid number of hubs for hub size`; `Conduit size is to large for jbox`
- **Referenced**: 12

