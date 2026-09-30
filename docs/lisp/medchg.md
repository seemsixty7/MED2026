# medchg.lsp

`Support\medchg.lsp` - Classic DCL MED xdata editor (MEDCHG-CLASSIC) and the MED alias.

Loaded by MEDCore (order 18). 32 defun(s): 2 command(s), 30 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`c:MEDCHG-CLASSIC`](#cmedchg-classic) | command |
| 8 | [`medchg`](#medchg) | function |
| 46 | [`add_app`](#add_app) | function |
| 166 | [`prc_list`](#prc_list) | function |
| 188 | [`prc_size`](#prc_size) | function |
| 225 | [`prc_alt_dpth`](#prc_alt_dpth) | function |
| 269 | [`mod_code`](#mod_code) | function |
| 304 | [`getfromcodelist`](#getfromcodelist) | function |
| 325 | [`getindxfromcode`](#getindxfromcode) | function |
| 352 | [`bldcodelst`](#bldcodelst) | function |
| 382 | [`app_chg_lst`](#app_chg_lst) | function |
| 544 | [`setdlg_vals`](#setdlg_vals) | function |
| 559 | [`upd_dlg`](#upd_dlg) | function |
| 660 | [`chg_edit_tag`](#chg_edit_tag) | function |
| 663 | [`chg_edit_rtag`](#chg_edit_rtag) | function |
| 678 | [`chg_edit_size`](#chg_edit_size) | function |
| 715 | [`chg_edit_alt`](#chg_edit_alt) | function |
| 734 | [`chg_edit_dpth`](#chg_edit_dpth) | function |
| 754 | [`chg_edit_dist`](#chg_edit_dist) | function |
| 768 | [`chg_edit_code`](#chg_edit_code) | function |
| 781 | [`chg_edit_text`](#chg_edit_text) | function |
| 785 | [`chg_edit_msr`](#chg_edit_msr) | function |
| 802 | [`mod_tag`](#mod_tag) | function |
| 823 | [`mod_rtag`](#mod_rtag) | function |
| 835 | [`mod_dist`](#mod_dist) | function |
| 855 | [`mod_msr`](#mod_msr) | function |
| 876 | [`upd_tag_list`](#upd_tag_list) | function |
| 1065 | [`add_tag_list`](#add_tag_list) | function |
| 1081 | [`upd_delete`](#upd_delete) | function |
| 1097 | [`setsize_lst`](#setsize_lst) | function |
| 1175 | [`bld_list`](#bld_list) | function |
| 1209 | [`c:MED`](#cmed) | command |

## c:MEDCHG-CLASSIC

`(c:MEDCHG-CLASSIC)`  - line 2-7

Old DCL MED xdata editor (medchg.lsp). User entry: [MEDCHG-CLASSIC](../command-reference.md#medchg-classic).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1

## medchg

`(medchg chg_ent / index_val result)`  - line 8-45

Classic MEDCHG worker: DCL xdata editor for one entity.

- **Arguments**: `chg_ent`
- **Returns**: value of the last expression: `(if (> (setq index_val (load_dialog "MED")) 0) (progn (if (new_dialog "MED_Change" index_val) (progn (app_chg_...`
- **Prompts**: `Select Entity to change:`
- **Referenced**: 12

## add_app

`(add_app app_name)`  - line 46-164

MEDCHG-CLASSIC: adds a MED app record to the entity.

- **Arguments**: `app_name`
- **Returns**: value of the last expression: `(add_tag_list)`
- **Side effects**: Globals set (not declared local): `rtag_list`, `ntag_list`, `lapp`, `nxt`, `last_list`, `first_list`, `MED_ADD_APP`, `add2list`, `r_len`, `len_lst`, `cnt`, `old`, `new`, `nitem`
- **Referenced**: 5

## prc_list

`(prc_list l_index)`  - line 166-186

MEDCHG-CLASSIC list callbacks (code, size, alt/depth).

- **Arguments**: `l_index`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `trim`, `cnt`, `datalist`, `item`
- **Referenced**: 4

## prc_size

`(prc_size l_index)`  - line 188-224

MEDCHG-CLASSIC list callbacks (code, size, alt/depth).

- **Arguments**: `l_index`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `trim`, `cnt`, `sizelist`, `item`, `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## prc_alt_dpth

`(prc_alt_dpth l_index listnm)`  - line 225-266

MEDCHG-CLASSIC list callbacks (code, size, alt/depth).

- **Arguments**: `l_index`, `listnm`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `trim`, `cnt`, `sizelist`, `item`, `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 2

## mod_code

`(mod_code l_index)`  - line 269-303

MEDCHG-CLASSIC list callbacks (code, size, alt/depth).

- **Arguments**: `l_index`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `trim`, `cnt`, `item`, `mat_code`, `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## getfromcodelist

`(getfromcodelist codetype codenum)`  - line 304-323

MEDCHG-CLASSIC code list helpers.

- **Arguments**: `codetype`, `codenum`
- **Returns**: value of the last expression: `(nth codenum bldlstcode)`
- **Side effects**: Globals set (not declared local): `bldlstcode`
- **Referenced**: 1

## getindxfromcode

`(getindxfromcode codenum codetype)`  - line 325-349

MEDCHG-CLASSIC code list helpers.

- **Arguments**: `codenum`, `codetype`
- **Returns**: value of the last expression: `lst_itm`
- **Side effects**: Globals set (not declared local): `bldlstcode`, `lst_len`, `lst_itm`
- **Referenced**: 11

## bldcodelst

`(bldcodelst)`  - line 352-379

MEDCHG-CLASSIC code list helpers.

- **Arguments**: none
- **Returns**: value of the last expression: `(end_list)`
- **Side effects**: Globals set (not declared local): `codetype`, `lst_type`
- **Referenced**: 1

## app_chg_lst

`(app_chg_lst ent bld_dcl_list)`  - line 382-543

MEDCHG-CLASSIC: builds the record list of an entity.

- **Arguments**: `ent`, `bld_dcl_list`
- **Returns**: value of the last expression: `tag_list`
- **Side effects**: Globals set (not declared local): `app_lst`, `all_list`, `tag_list`, `tag_indx`, `list_app`, `app_len`, `num_tags`, `tag_cnt`, `lstcompl`, `lst_tag`, `app_tag`, `lst_code`, `lst_rtag`, `lst_siz`, `lst_dist` ...; Xdata: reads xdata
- **Referenced**: 1

## setdlg_vals

`(setdlg_vals tag rtag size code alt dpth dist txt msr flng / dlgvals)`  - line 544-558

MEDCHG-CLASSIC: fills / updates the dialog tiles.

- **Arguments**: `tag`, `rtag`, `size`, `code`, `alt`, `dpth`, `dist`, `txt`, `msr`, `flng`
- **Returns**: value of the last expression: `dlgvals`
- **Referenced**: 5

## upd_dlg

`(upd_dlg chg_code)`  - line 559-659

MEDCHG-CLASSIC: fills / updates the dialog tiles.

- **Arguments**: `chg_code`
- **Returns**: value of the last expression: `(chg_edit_msr(nth 8 vals))`
- **Side effects**: Globals set (not declared local): `vals`
- **Referenced**: 9

## chg_edit_tag

`(chg_edit_tag n_value)`  - line 660-662

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(set_tile "edit_tag" n_value)`
- **Referenced**: 1

## chg_edit_rtag

`(chg_edit_rtag n_value)`  - line 663-677

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if n_value (progn (mode_tile "edit_rtag" 0) (set_tile "edit_rtag" n_value) (mode_tile "rtag_txt" 0) ) (progn ...`
- **Referenced**: 1

## chg_edit_size

`(chg_edit_size n_value)`  - line 678-714

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if (nth 0 n_value) (progn (cond ((= (nth 1 n_value) _CONDUIT) (setq nvalue (nth 4 (getsize nil (rtos (nth 0 n...`
- **Side effects**: Globals set (not declared local): `nvalue`, `lstlen`, `lstpos`
- **Referenced**: 1

## chg_edit_alt

`(chg_edit_alt n_value)`  - line 715-733

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if n_value (progn (setq len1 (length ALT_LIST) len2 (length (member n_value ALT_LIST)) nvalue (itoa (- len1 l...`
- **Side effects**: Globals set (not declared local): `len1`, `len2`, `nvalue`
- **Referenced**: 1

## chg_edit_dpth

`(chg_edit_dpth n_value)`  - line 734-752

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if n_value (progn (setq len1 (length DPTH_LIST) len2 (length (member n_value DPTH_LIST)) nvalue (itoa (- len1...`
- **Side effects**: Globals set (not declared local): `len1`, `len2`, `nvalue`
- **Referenced**: 1

## chg_edit_dist

`(chg_edit_dist n_value)`  - line 754-767

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if (and (nth 0 n_value) (/= (nth 1 n_value) "T")) (progn (mode_tile "edit_dist" 0) (mode_tile "dist_txt" 0) (...`
- **Referenced**: 1

## chg_edit_code

`(chg_edit_code n_value)`  - line 768-779

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if n_value (progn (mode_tile "edit_code" 0) (set_tile "edit_code" (itoa n_value)) ) (progn (set_tile "edit_co...`
- **Referenced**: 1

## chg_edit_text

`(chg_edit_text n_value)`  - line 781-783

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(set_tile "edit_text" n_value)`
- **Referenced**: 1

## chg_edit_msr

`(chg_edit_msr n_value)`  - line 785-800

MEDCHG-CLASSIC edit-box callbacks.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(if n_value (progn (if (= n_value "T") (setq n_value "1") (setq n_value "0") ) (mode_tile "edit_msr" 0) (set_t...`
- **Referenced**: 1

## mod_tag

`(mod_tag n_value)`  - line 802-822

MEDCHG-CLASSIC: modify one field of the current record.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(set_tile "taglist" (itoa lstindx))`
- **Side effects**: Globals set (not declared local): `lstindx`, `lstapp`, `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## mod_rtag

`(mod_rtag n_value)`  - line 823-833

MEDCHG-CLASSIC: modify one field of the current record.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(setq MEDUPD T)`
- **Side effects**: Globals set (not declared local): `lstindx`, `lstapp`, `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## mod_dist

`(mod_dist n_value)`  - line 835-853

MEDCHG-CLASSIC: modify one field of the current record.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## mod_msr

`(mod_msr n_value)`  - line 855-874

MEDCHG-CLASSIC: modify one field of the current record.

- **Arguments**: `n_value`
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 datalist))`
- **Side effects**: Globals set (not declared local): `oldval`, `newval`, `oldlst`, `datalist`, `tag_list`, `MEDUPD`
- **Referenced**: 1

## upd_tag_list

`(upd_tag_list)`  - line 876-1063

MEDCHG-CLASSIC: record list update / add / delete.

- **Arguments**: none
- **Returns**: value of the last expression: `(if MEDUPD (progn (setq num (length tag_list) trans_lst nil nw_list nil wk_list nil currlist nil cnt 0 ) (repe...`
- **Side effects**: Globals set (not declared local): `num`, `trans_lst`, `nw_list`, `wk_list`, `currlist`, `cnt`, `wk_app`, `wk_tag`, `wk_code`, `work_list`, `wk_size`, `wk_last`, `wk_dist`, `wk_msr`, `wk_alt` ...; Xdata: writes xdata
- **Referenced**: 1

## add_tag_list

`(add_tag_list)`  - line 1065-1080

MEDCHG-CLASSIC: record list update / add / delete.

- **Arguments**: none
- **Returns**: value of the last expression: `(if MED_ADD_APP (progn (setq MED_ADD_APP nil tag_list ntag_list ) (start_list "taglist") (foreach itemtag tag_...`
- **Side effects**: Globals set (not declared local): `MED_ADD_APP`, `tag_list`
- **Referenced**: 1

## upd_delete

`(upd_delete)`  - line 1081-1093

MEDCHG-CLASSIC: record list update / add / delete.

- **Arguments**: none
- **Returns**: value of the last expression: `(upd_dlg (dxf 0 (nth 0 tag_list)))`
- **Side effects**: Globals set (not declared local): `old_lst`, `new_list`, `tag_list`
- **Referenced**: 1

## setsize_lst

`(setsize_lst val)`  - line 1097-1173

MEDCHG-CLASSIC: builds the size/alt/depth lists for a type.

- **Arguments**: `val`
- **Returns**: value of the last expression: `(bldcodelst)`
- **Side effects**: Globals set (not declared local): `SIZE_LIST`, `DPTH_LIST`, `cnt`, `currsz`, `ALT_LIST`
- **Referenced**: 5

## bld_list

`(bld_list listvar cnt)`  - line 1175-1184

Builds a numbered list for a DCL list box.

- **Arguments**: `listvar`, `cnt`
- **Returns**: value of the last expression: `rlist`
- **Side effects**: Globals set (not declared local): `num`, `rlist`
- **Referenced**: 10

## c:MED

`(c:MED)`  - line 1209-1209

Alias: runs the .NET MEDCHG properties palette. User entry: [MED](../command-reference.md#med).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 0

