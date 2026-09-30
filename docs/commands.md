# Commands

Grouped like the 2012 guide. C# UI has its own pages — this index does not re-describe those dialogs. LISP commands are `defun C:` in `Support`. OpenDCL copies of Settings / Show / MEDCHANGE in `MEDMainDialogs-RedoWithCSharp.lsp` are **not** loaded by `MEDCore.lsp`.

Aliases: `MED` and `MC` call `MEDCHG`. Classic DCL: `MEDCHG-CLASSIC`.

**Full reference:** [command-reference.md](command-reference.md) has one entry for every command (LISP and .NET): what it does, prompts, menu location, related commands. Developers: [lisp-reference.md](lisp-reference.md) (every AutoLISP function) and [3d-guide.md](3d-guide.md). The audit behind them is [doc-audit.csv](doc-audit.csv).

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
| `MEDMENU` | med.mnl | Reload the AutoCAD menu, MENULOAD `med`, show the Plan pull-downs (legacy) |
| `MEDPLAN` `MEDDETAIL` `MEDWIRING` | med.mnl | Swap the MED pull-downs to the Plan / Detail / Wiring set (on the MED Main menu) |
| `MEDDIMSETUP` | MEDDim.lsp | Make the Standard dimension style current with the MED dim variables |
| `IOD` | MEDDim.lsp | Move dimensions with a text override to layer `_Faked Dimensions` |

## Catalog, settings, properties, BOM

| Command | Aliases | What it does |
| --- | --- | --- |
| [MEDTYPE](medtype.md) | `MEDTYPES` | C# grid on `MEDType` |
| [MEDSETTINGS](medsettings.md) | `MEDSET` | C# palette; lisp globals + scale |
| [Cable palette](cable.md) | `MEDCABLE`, `CABLEPALETTE`, `CABLESET` | Type then cable; `CABLE` draws |
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
| `ISOLATE` `UNISOLATE` | | Hide all but entities with a detail code / show them again |
| `ATLSC` `ATRSC` | | Add schedule data (material 67 / 68) to an entity (legacy) |
| `TAKEOFF` | | HANDLES on, then `BOM` (legacy) |
| `MEDDEBUG` | | .NET debug switch. [debug.md](debug.md) |
| `MEDREBUILDMEDPROPSJSON` | `MED-RebuildMedPropertiesJson` | .NET: rebuild `{dwg}.medprops.json` for the drawing |

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
| `F0` | Fillet with radius 0 |
| `UNJ` | UNJ / UNJC fitting aligned to a reference entity |
| `OFF2CON` | Offset an entity and make the copy a conduit run |

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
| `CHANNEL` `CHAN30` `CHAN45` `CHAN60` `CHAN90` `CHANTEE` `CHANCROSS` `CHANOFF` `CHANUP` `CHANDN` `CHANV90` | Cable channel |
| `STRUT` `STRUT1` | Strut |
| `TRAYEP` `TRAYEG` `TRAYHD` `TRAYHANG` `TRAYDROP` `TRAYBLIND` `TRAYHINGE` `TRAYCON` | Tray hardware details |
| `CF` `CN` | Centerline layer off / on |
| `TELEV` | Tray elevation helper |
| `STRUT1` | Strut on the centerline layer with xdata (QKEY) |
| `MAKE3DTRAY` | 3D solids from tray. See [3d.md](3d.md) |

## Cable and wire

See [cable.md](cable.md).

| Command | What it does |
| --- | --- |
| `MEDCABLE` / `CABLEPALETTE` / `CABLESET` | Show the Cable palette only |
| `CABLE` | Lisp draw (`c:cable`); tag + related tag. Route Cable on the palette runs this |
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

`CTAG` `TTAG` `TTAGS` `DETAG` `DETAG2` `DETAGUPD` `MB` `MB1` `MBL` `ABL` `HDTAG` `HDTAGOLD` `IT` `ITAGA` `ITAGE` `ITAGT` `QTA` `QTE` `QTR` `QTT` `WIRES` `ALEAD` `AL` `GLEAD` `GL` `GRAB` `GR` `LOOPIT` `SECT` `SECTD` `CUT` `CLOUD` `BOXCLOUD` `BC` `BRACKET`

One line each in [command-reference.md](command-reference.md#by-topic) (topic "Tagging").

## 3D

See [3d.md](3d.md).

| Command | What it does |
| --- | --- |
| `MEDMAKE3D` | Tray, tray fittings, conduit, conduit bodies and cable in one go (`MED3DPath.lsp`, loaded). Start with [3d-guide.md](3d-guide.md) |
| `MAKE3DTRAY` | Solids from tray and tray fittings (`MED3DTrayFunctions.lsp`, loaded) |
| `M3D` `C3D` | Selected conduit / cable runs (`MED3DPath.lsp`, loaded) |
| `MAKE3DCONDUIT` `MAKE3DCABLE` | Every conduit / cable run, Dwg or Layer (`MED3DPath.lsp`, loaded) |
| `MED3DPLAN` `MED3DVER` | Corner table of one run / version and command owners |
| `MEDCBINS` `MEDCBTEST` `MEDCBALL` `MEDCBDATA` `MEDCBVER` | 3D conduit bodies: insert / row / gallery / reload data / version (`MED3DFittings.lsp`, loaded) |
| `ESOLID` | Erase **all** solids |
| `3DJBOX` | 3D j-box (`MED3DMisc.lsp`, loaded) |
| `M3DOLD` `MAKE3DCONDUITOLD` | 2012 code in `MED3DCON.lsp` - **not** loaded |
| `MEDCBGRID` `MED3DPATHTEST` | Test drawings, `tests\autocad\*.lsp` - APPLOAD first |

## Text, layers, view

See [utilities.md](utilities.md).

Text: `AC` `ACX` `CT` `CTEDIT` `CX` `DD` `RT` `TJ` `UPCASE` `UT` `XT` `T1` `T2` `T3` `B1` `B2` `B3` `T1THIN` `MT` `ATADD` `ATTCOPY` `ATC` `ATTLAY` `ATTROT` `APP` `PAR` `LOADTXT` `BLDSTL` `LINKPREFIX` `LINKPREFIXATT` `LINKVALUE` `SETLINK` `SETLINKSUM` `SHOWFIELDCODE`

Layers / edit: `IL` `UIL` `FL` `SL` `CL` `LT` `BN` `BLK2BYL` `BLKREINS` `WBL` `EM` `TM` `ST` `BF` `PB` `LB` `LBREAK` `PLMAKE` `PW` `PLWIDE` `PBOX` `QC` `QE` `CD` `HAND` `LISP` `REFDWG` `SORT`

View / erase macros: `ZW` `ZD` `ZP` `ZV` `ZE` `VA` `VR` `EW` `EC` `CW` `CC` `MW` `RW` `RC`

## Not in MED2026

| 2012 name | Status |
| --- | --- |
| Training icon / MED 1.53 | Removed |
| `MEDPLAN` `MEDDETAIL` `MEDWIRING` | Still defined in `Support\med.mnl` and on the MED Main menu (pull-down set switcher). With `med.cuix` / `MEDRibbon.cuix` you rarely need them. See Setup above |
| `MEDPACK` | Removed (no `.dbf`) |
| Access / `MEDTYPE.dbf` / `PROJECT.dbf` | Replaced by SQLite or SQL Server |
| `TROFF` | Use `TRAYOFF` |
| `DDCPLIST` | Typo in 2012; use `DDMEDLIST` |
| `SHOW` as DCL | Use `MEDSHOWBOM`. The MED Main menu and ribbon "Browse BOM" items still send `SHOW`, which no longer exists ([menu macros with no command](command-reference.md#menu-macros-that-start-no-med-command)) |
| `MEDSET` DCL | Use the C# `MEDSETTINGS` palette |
| `LAT` (thaw all) | Not in Support |

Internal test commands (`TEST`, `TRAYTEST`, `TRAYFITTEST`, `TRAYTEETEST`, `TRAYRETEST`, `TRAYLRRETEST`, `MYTEST`, `QVTEST`) and OpenDCL callback names (`MEDMAIN_…`) are not user commands. They are listed in [command-reference.md](command-reference.md#by-topic) under "Test / developer".
