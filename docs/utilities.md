# Utilities

Text, layers, leaders, and quick keys. Ported from the 2012 appendix where the `C:` command still exists in Support. These are drafting helpers, not a second BOM system.

## Attributes and text (`medtext.lsp`, `QKEY.lsp`)

| Command | What it does |
| --- | --- |
| `AC` | Change selected attribute to a new value |
| `ACX` | Replace part of an attribute (old string → new string) |
| `ATADD` / `ATTCOPY` | Add / copy attributes |
| `CT` | Change text strings; pick several in the order to change |
| `CTEDIT` | Edit a set; prefixes/suffixes, autostep, or simple edit. `TSTRIP` offers to run this on new terminal text |
| `CX` | Exchange old substring for new across a text selection |
| `DD` | `DDEDIT` for TEXT / ATTDEF / MTEXT; `DDATTE` for INSERT |
| `FD` | FileDate. Insert or update the `FILEINFO` block (name, scale, date, user). See [setup.md](setup.md) |
| `LOADTXT` | Load a text file into the drawing |
| `NCE` | Numeric / text helper in `medtext.lsp` |
| `RT` | Replace several text entities with one new value (pick or type) |
| `TJ` | Set justification and align to a common X |
| `UPCASE` | Selection to uppercase |
| `UT` | Underline text |
| `XT` | Convert selected text to another style; optional spacing adjust if heights differ |
| `T1` `T2` `T3` `B1` `B2` `B3` | Standard MED text styles from `med.spc` |
| `MT` | MText helper |

## Layers, lines, blocks (`medutil.lsp`, `QKEY.lsp`)

| Command | What it does |
| --- | --- |
| `IL` | Isolate: freeze every layer except the picked entity's (that layer becomes current). Thaw all: AutoCAD layer UI (2012 mentioned `LAT`; that qkey is not in Support) |
| `FL` | Freeze layer of a picked entity |
| `SL` | Set current layer from a picked entity |
| `CL` | Change a selection to the layer of a picked entity |
| `LT` | Change linetype of a set to a picked entity's. If that entity is BYLAYER, asks before using BYLAYER vs the layer's linetype |
| `UIL` | Un-isolate helper |
| `ISOLATE` / `UNISOLATE` | Isolate selection (`MEDCommands.lsp`) |
| `BN` | Block name of a pick |
| `BLK2BYL` | 2012 `BLK20`: redefine a block's internal layers to 0. Insert layer is unchanged |
| `BLKREINS` | Reinsert blocks |
| `EM` | Extend multiple to a border set |
| `TM` | Trim multiple to a border set |
| `ST` | Stretch with crossing already chosen |
| `BF` | Break: pick entity, then two points (`BREAK` first-point mode) |
| `LB` / `LBK` / `LBREAK` | Line break helpers (terminal-strip drawings; break symbol at two points) |
| `PLMAKE` | Lines → polylines |
| `PW` / `PLWIDE` | Polyline width |
| `PBOX` | Closed polyline box from two corners |
| `QC` | Circles of several radii from one center |
| `PAR` | Parallel helper |
| `LISP` | Load a lisp file from a directory or the AutoCAD path |
| `CD` | Coordinate text from a grid line, current style/layer |
| `LINKPREFIX` / `LINKPREFIXATT` / `LINKVALUE` / `SETLINK` / `SETLINKSUM` | Attribute / prefix link helpers |
| `SHOWFIELDCODE` | Show field codes |
| `HAND` | Handle of a pick |
| `MEDCOPY` / `MEDFIND` | Copy / find MED entities |
| `LOADLAYERS` | Create layers from the `Layers1` table |
| `REFDWG` | Reference drawing helper |
| `IOD` / `MEDDIMSETUP` | Dimension setup (`MEDDim.lsp`) |

## View and erase macros (`QKEY.lsp`)

`ZW` zoom window, `ZD` dynamic, `ZP` previous, `ZV` vmax, `ZE` extents. `VA` restore view ALL (must exist). `VR` restore a named view.

`EW` / `EC` erase window/crossing. `CW` / `CC` copy window/crossing. `MW` move window. `RW` / `RC` rotate window/crossing. `MC` is **not** move-crossing in MED2026 — it aliases `MEDCHG`.

## Wiring diagram helpers

`2LINE` / `3LINE` offset a polyline by `_2LINOFF` / `_3LINOFF`. `MEDLINE` is a plain polyline on the current MED linetype. `TSTRIP` draws a terminal strip and can chain into `CTEDIT`.

Oneline and elementary **symbols** are CUI / slide libraries (`medwire1.slb`, `medwire2.slb`). The 2012 `MEDWIRING` menu switcher is gone. The 2012 oneline tutorial (stab, breaker, HOA, typical branch from an image menu) is toolbar training and was not ported. Place symbols from the ribbon; osnap the same way you would any block.

## ACAD.PGP

`Support\ACAD.PGP` still ships AutoCAD aliases (`L` line, `C` copy, `Z` zoom, …). That is AutoCAD, not MED. Edit it as you would any pgp. The 2012 appendix listed those aliases; they are not MED commands.

## Defaults file

`Support\med.spc` is the lisp default sheet (sizes, layers, title block, detail-bubble attribute names). Loaded by `MEDCore.lsp`. Session overrides: [MEDSETTINGS](medsettings.md).
