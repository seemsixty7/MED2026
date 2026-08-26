# Commands

Grouped like the 2012 guide. C# UI has its own pages — this index does not re-describe those dialogs. LISP commands are `defun C:` in `Support`. OpenDCL copies of Settings / Show / MEDCHANGE in `MEDMainDialogs-RedoWithCSharp.lsp` are **not** loaded by `MEDCore.lsp`.

Aliases: `MED` and `MC` call `MEDCHG`. Classic DCL: `MEDCHG-CLASSIC`.

## Setup

| Command | File | What it does |
| --- | --- | --- |
| `SETUP` | medsetup.lsp | Scale, title block, text styles. See [setup.md](setup.md) |
| `SETLIM` | medsetup.lsp | Drawing limits helper |
| `SETPLOT` | medsetup.lsp | Plot scale helper |
| `BLDIST` | medsetup.lsp | Baseline distance |
| `FD` | medtext.lsp | File-info block |
| `LOADLAYERS` | MEDCommands.lsp | Layers from `Layers1` |
| `MED2026SETUP` | MED2026-ProfileSetup.lsp | Search path, trusted paths, CUILOAD `med.cuix`. See [install.md](install.md) |

## Catalog, settings, properties, BOM

| Command | Aliases | What it does |
| --- | --- | --- |
| [MEDTYPE](medtype.md) | `MEDTYPES` | C# grid on `MEDType` |
| [MEDSETTINGS](medsettings.md) | `MEDSET` | C# palette; lisp globals + scale |
| [Cable palette](cable.md) | `CABLEPALETTE`, `CABLESET` | Type then cable; `CABLE` draws |
| [MEDCHG](medchg.md) | `MEDPROPERTIES`, `MEDPROPS`, `MED`, `MC` | Properties palette (entity xdata) |
| `MEDCHG-CLASSIC` | | Old DCL editor |
| [MEDRECORDS](medrecords.md) | `MEDXDEDIT` | Handle-based multi-xdata grid |
| [MEDSHOWBOM](medshowbom.md) | `MEDSHOW`, `MEDSHOWSUM` | Browse `MEDProject` for this DWG |
| `BOM` | | Extract xdata → `MEDProject`. Not live. [database.md](database.md) |
| `MEDDBBACKUP` / `MEDDBRESTORE` | | CSV snapshot of `MEDType` |
| `MEDLIST` | | Command-line xdata + catalog description |
| `DDMEDLIST` | | DCL list; Next through a set; can open classic MEDCHG |
| `MEDSTRIP` | | Remove all MED xdata from a selection |
| `MCON` `MCABLE` `MTRAY` `MFIT` `MEQUIP` | | Add a MED record to an existing entity |
| `CHGSIZE` | | Size on a conduit/fitting selection |
| `CHGTAG` | | Tag on a selection |
| `MEDFIND` `MEDCOPY` | | Find / copy MED entities |

2012 `SHOW` is `MEDSHOWBOM`. 2012 `MEDPACK` / Access are gone. 2012 `MEDCHANGE` as a separate command is gone (commented LISP); use `MEDCHG`.

## Conduit

See [conduit.md](conduit.md).

| Command | What it does |
| --- | --- |
| `CONDUIT` | Route polyline + xdata; optional fillet; tag prompt |
| `CONSIZE` | DCL size picker |
| `DEFINE` | Attach current conduit settings to existing geometry |
| `FLEX` | Flex run + connectors |
| `FC` | Fillet at conduit-size radius |
| `2LCON` `2LFLEX` `CONFIX` | Two-line detail conduit. [detail-conduit.md](detail-conduit.md) |
| `2AWAY` `2TOWARD` `2BREAK` | Away / toward / break symbols |
| `HUBS` | RS j-box hubs |
| `ADDRE` | Add reducing fittings (RE) to an entity |

## Cable tray

See [tray.md](tray.md). 2012 `TROFF` = `TRAYOFF`.

| Command | What it does |
| --- | --- |
| `TRAY` | Two-point tray |
| `TRAYSIZE` | Size/depth/radius DCL |
| `TRAYFIX` | Rebuild outline from centerline |
| `TRAYOFF` | Plan horizontal offset |
| `PTRAYOFF` | Plan vertical offset |
| `VTRAY` `VTRAYOFF` | Side-view tray / offset |
| `TRAY90` `TRAY30` `TRAY45` `TRAY60` | Elbows |
| `TRAYTEE` `TRAYCROSS` `TRAYRE` | Tee, cross, reducer |
| `TRAYV90` `TRAYDN` `TRAYUP` | Vertical elbow / down / up |
| `VTRAY30` `VTRAY45` `VTRAY60` `VTRAY90` | Side-view elbows |
| `TRAYTEERE` `TRAYREL` `TRAYRER` | Tee/reducer variants |
| `CHANNEL` `CHAN30`…`CHAN90` `CHANTEE` `CHANCROSS` `CHANOFF` `CHANUP` `CHANDN` `CHANV90` | Cable channel |
| `STRUT` `STRUT1` | Strut |
| `TRAYEP` `TRAYEG` `TRAYHD` `TRAYHANG` `TRAYDROP` `TRAYBLIND` `TRAYHINGE` `TRAYCON` | Tray hardware details |
| `CF` `CN` | Centerline layer off / on |
| `TELEV` | Tray elevation helper |

## Cable and wire

See [cable.md](cable.md).

| Command | What it does |
| --- | --- |
| `CABLE` | Cable palette, type layer, route polyline; tag + related tag |
| `CABLEPALETTE` / `CABLESET` | Show the Cable palette only |
| `CABLE-CLASSIC` | Old lisp-only CABLE (no palette) |
| `RUN3DCABLE` | Same on a 3DPOLY using current `_CABCODE` and type layer |
| `2LINE` `3LINE` | Double / triple line |
| `MEDLINE` | Polyline on current MED linetype |
| `TSTRIP` | Terminal strip |

## Details / equipment

See [detail.md](detail.md).

| Command | What it does |
| --- | --- |
| `DETAIL` | DCL group picker |
| `LTG` `GND` `PWR` `INS` `TRY` `COM` `JBX` `MSC` | Insert from that `MEDType` group |
| `MEDBLOCKINSERT` | Block insert used by the detail pipeline |
| `PLANMOTOR` | Motor from `MOTOR.DAT` |

## Tagging

See [tagging.md](tagging.md).

`CTAG` `TTAG` `TTAGS` `DETAG` `DETAG2` `DETAGUPD` `MB` `MB1` `MBL` `ABL` `HDTAG` `IT` `ITAGA` `ITAGE` `ITAGT` `WIRES` `ALEAD` `AL` `GLEAD` `GL` `GRAB` `GR` `SECT` `SECTD` `CUT` `CLOUD` `BOXCLOUD` `BRACKET`

## 3D

See [3d.md](3d.md).

| Command | What it does |
| --- | --- |
| `MAKE3DTRAY` | Solids from tray. Loaded |
| `ESOLID` | Erase all solids |
| `MAKE3DCONDUIT` `M3D` | In `MED3DCON.lsp` — **not** loaded by MEDCore; APPLOAD if needed |
| `3DJBOX` | 3D j-box (`MED3DMisc.lsp`, loaded) |

## Text, layers, view

See [utilities.md](utilities.md).

Text: `AC` `ACX` `CT` `CTEDIT` `CX` `DD` `RT` `TJ` `UPCASE` `UT` `XT` `T1` `T2` `T3` `B1` `B2` `B3` `MT` `ATADD` `ATTCOPY` `LOADTXT`

Layers / edit: `IL` `FL` `SL` `CL` `LT` `ISOLATE` `UNISOLATE` `BN` `BLK2BYL` `EM` `TM` `ST` `BF` `LB` `LBREAK` `PLMAKE` `PW` `PBOX` `QC` `CD`

View / erase macros: `ZW` `ZD` `ZP` `ZV` `ZE` `VA` `VR` `EW` `EC` `CW` `CC` `MW` `RW` `RC`

## Not in MED2026

| 2012 name | Status |
| --- | --- |
| Training icon / MED 1.53 | Removed |
| `MEDPLAN` `MEDDETAIL` `MEDWIRING` | Removed. Use `med.cuix` / `MEDRibbon.cuix` |
| `MEDPACK` | Removed (no `.dbf`) |
| Access / `MEDTYPE.dbf` / `PROJECT.dbf` | Replaced by SQLite or SQL Server |
| `TROFF` | Use `TRAYOFF` |
| `DDCPLIST` | Typo in 2012; use `DDMEDLIST` |
| `SHOW` as DCL | Use `MEDSHOWBOM` |
| `MEDSET` DCL | Use the C# `MEDSETTINGS` palette |
| `LAT` (thaw all) | Not in Support |

Internal test commands (`TEST`, `TRAYTEST`, `TRAYFITTEST`, `MYTEST`, `QVTEST`, …) and OpenDCL callback names (`MEDMAIN_…`) are not user commands.
