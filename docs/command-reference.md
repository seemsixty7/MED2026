# Command reference (A-Z)

Every MED command, one entry each: LISP `defun c:` in `Support\` (plus `med.mnl`, `med.spc` and the two test files under `tests\autocad\`) and the .NET `[CommandMethod]` commands in `MED-DotNet.dll`. The grouped index is [commands.md](commands.md); topic pages go into more depth. Generated from the source on the `feature/3dpath` branch (see [doc-audit.csv](doc-audit.csv) for file and line of every entry).

How to read an entry:

- **Source**: file and line. *Not loaded* means MEDCore does not load that file (APPLOAD it yourself).
- **Prompts**: the prompt strings in the code, in order. Keywords in `[...]` come from `initget`.
- **Menu**: where `med.cuix` / `MEDRibbon.cuix` place a macro that starts the command (first few only). *None found* means you type it (or a quick key).
- **Image: TODO** marks a place where a screenshot would help. Do not make up screenshots; see [images/README.md](images/README.md).
- **TODO: confirm with Clint** marks something the code does not settle.

## By topic

- **Setup**: [`BLDIST`](#bldist) [`IOD`](#iod) [`LOADLAYERS`](#loadlayers) [`MED2026SETUP`](#med2026setup) [`MEDDETAIL`](#meddetail) [`MEDDIMSETUP`](#meddimsetup) [`MEDMENU`](#medmenu) [`MEDPLAN`](#medplan) [`MEDWIRING`](#medwiring) [`SETLIM`](#setlim) [`SETPLOT`](#setplot) [`SETUP`](#setup)

- **Catalog, xdata and BOM**: [`ATLSC`](#atlsc) [`ATRSC`](#atrsc) [`BOM`](#bom) [`BOMSS`](#bomss) [`CHGSIZE`](#chgsize) [`CHGTAG`](#chgtag) [`ISOLATE`](#isolate) [`MC`](#mc) [`MCABLE`](#mcable) [`MCON`](#mcon) [`MED`](#med) [`MEDCHG-CLASSIC`](#medchg-classic) [`MEDCOPY`](#medcopy) [`MEDDBBACKUP`](#meddbbackup) [`MEDDBRESTORE`](#meddbrestore) [`MEDFIND`](#medfind) [`MEDLIST`](#medlist) [`MEDSTRIP`](#medstrip) [`MEQUIP`](#mequip) [`MFIT`](#mfit) [`MTRAY`](#mtray) [`TAKEOFF`](#takeoff) [`UNISOLATE`](#unisolate)

- **Conduit**: [`2AWAY`](#2away) [`2BREAK`](#2break) [`2LCON`](#2lcon) [`2LFLEX`](#2lflex) [`2TOWARD`](#2toward) [`ADDRE`](#addre) [`CONDUIT`](#conduit) [`CONFIX`](#confix) [`CONSIZE`](#consize) [`DEFINE`](#define) [`F0`](#f0) [`FC`](#fc) [`FLEX`](#flex) [`HUBS`](#hubs) [`OFF2CON`](#off2con) [`UNJ`](#unj)

- **Cable tray and channel**: [`CF`](#cf) [`CHAN30`](#chan30) [`CHAN45`](#chan45) [`CHAN60`](#chan60) [`CHAN90`](#chan90) [`CHANCROSS`](#chancross) [`CHANDN`](#chandn) [`CHANNEL`](#channel) [`CHANOFF`](#chanoff) [`CHANTEE`](#chantee) [`CHANUP`](#chanup) [`CHANV90`](#chanv90) [`CN`](#cn) [`MAKE3DTRAY`](#make3dtray) [`PTRAYOFF`](#ptrayoff) [`STRUT`](#strut) [`STRUT1`](#strut1) [`TELEV`](#telev) [`TRAY`](#tray) [`TRAY30`](#tray30) [`TRAY45`](#tray45) [`TRAY60`](#tray60) [`TRAY90`](#tray90) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon) [`TRAYCROSS`](#traycross) [`TRAYDN`](#traydn) [`TRAYDROP`](#traydrop) [`TRAYEG`](#trayeg) [`TRAYEP`](#trayep) [`TRAYFIX`](#trayfix) [`TRAYHANG`](#trayhang) [`TRAYHD`](#trayhd) [`TRAYHINGE`](#trayhinge) [`TRAYOFF`](#trayoff) [`TRAYRE`](#trayre) [`TRAYREL`](#trayrel) [`TRAYRER`](#trayrer) [`TRAYSIZE`](#traysize) [`TRAYTEE`](#traytee) [`TRAYTEERE`](#trayteere) [`TRAYUP`](#trayup) [`TRAYV90`](#trayv90) [`VTRAY`](#vtray) [`VTRAY30`](#vtray30) [`VTRAY45`](#vtray45) [`VTRAY60`](#vtray60) [`VTRAY90`](#vtray90) [`VTRAYOFF`](#vtrayoff)

- **Cable and wire**: [`2LINE`](#2line) [`3LINE`](#3line) [`CABLE`](#cable) [`MEDLINE`](#medline) [`RUN3DCABLE`](#run3dcable) [`TSTRIP`](#tstrip) [`WIRES`](#wires)

- **Details and equipment**: [`COM`](#com) [`DETAIL`](#detail) [`GND`](#gnd) [`INS`](#ins) [`JBX`](#jbx) [`LTG`](#ltg) [`MEDBLOCKINSERT`](#medblockinsert) [`MSC`](#msc) [`PLANMOTOR`](#planmotor) [`PWR`](#pwr) [`TRY`](#try)

- **Tagging**: [`ABL`](#abl) [`AL`](#al) [`ALEAD`](#alead) [`BC`](#bc) [`BOXCLOUD`](#boxcloud) [`BRACKET`](#bracket) [`CLOUD`](#cloud) [`CTAG`](#ctag) [`CUT`](#cut) [`DETAG`](#detag) [`DETAG2`](#detag2) [`DETAGUPD`](#detagupd) [`GL`](#gl) [`GLEAD`](#glead) [`GR`](#gr) [`GRAB`](#grab) [`HDTAG`](#hdtag) [`HDTAGOLD`](#hdtagold) [`IT`](#it) [`ITAGA`](#itaga) [`ITAGE`](#itage) [`ITAGT`](#itagt) [`LOOPIT`](#loopit) [`MB`](#mb) [`MB1`](#mb1) [`MBL`](#mbl) [`QTA`](#qta) [`QTE`](#qte) [`QTR`](#qtr) [`QTT`](#qtt) [`SECT`](#sect) [`SECTD`](#sectd) [`TTAG`](#ttag) [`TTAGS`](#ttags)

- **Text and attributes**: [`AC`](#ac) [`ACX`](#acx) [`APP`](#app) [`ATADD`](#atadd) [`ATC`](#atc) [`ATTCOPY`](#attcopy) [`ATTLAY`](#attlay) [`ATTROT`](#attrot) [`B1`](#b1) [`B2`](#b2) [`B3`](#b3) [`BLDSTL`](#bldstl) [`CD`](#cd) [`CT`](#ct) [`CTEDIT`](#ctedit) [`CX`](#cx) [`DD`](#dd) [`FD`](#fd) [`LINKPREFIX`](#linkprefix) [`LINKPREFIXATT`](#linkprefixatt) [`LINKVALUE`](#linkvalue) [`LOADTXT`](#loadtxt) [`MT`](#mt) [`PAR`](#par) [`RT`](#rt) [`SETLINK`](#setlink) [`SETLINKSUM`](#setlinksum) [`SHOWFIELDCODE`](#showfieldcode) [`T1`](#t1) [`T1THIN`](#t1thin) [`T2`](#t2) [`T3`](#t3) [`TJ`](#tj) [`UPCASE`](#upcase) [`UT`](#ut) [`XT`](#xt)

- **Layers, editing, view**: [`BF`](#bf) [`BLK2BYL`](#blk2byl) [`BLKREINS`](#blkreins) [`BN`](#bn) [`CC`](#cc) [`CL`](#cl) [`CW`](#cw) [`EC`](#ec) [`EM`](#em) [`EW`](#ew) [`FL`](#fl) [`HAND`](#hand) [`IL`](#il) [`LB`](#lb) [`LBREAK`](#lbreak) [`LISP`](#lisp) [`LT`](#lt) [`MW`](#mw) [`PB`](#pb) [`PBOX`](#pbox) [`PLMAKE`](#plmake) [`PLWIDE`](#plwide) [`PW`](#pw) [`QC`](#qc) [`QE`](#qe) [`RC`](#rc) [`REFDWG`](#refdwg) [`RW`](#rw) [`SL`](#sl) [`SORT`](#sort) [`ST`](#st) [`TM`](#tm) [`UIL`](#uil) [`VA`](#va) [`VR`](#vr) [`WBL`](#wbl) [`ZD`](#zd) [`ZE`](#ze) [`ZP`](#zp) [`ZV`](#zv) [`ZW`](#zw)

- **3D**: [`3DJBOX`](#3djbox) [`C3D`](#c3d) [`ESOLID`](#esolid) [`M3D`](#m3d) [`M3DOLD`](#m3dold) [`MAKE3DCABLE`](#make3dcable) [`MAKE3DCONDUIT`](#make3dconduit) [`MAKE3DCONDUITOLD`](#make3dconduitold) [`MED3DPLAN`](#med3dplan) [`MED3DVER`](#med3dver) [`MEDCBALL`](#medcball) [`MEDCBDATA`](#medcbdata) [`MEDCBINS`](#medcbins) [`MEDCBTEST`](#medcbtest) [`MEDCBVER`](#medcbver) [`MEDMAKE3D`](#medmake3d)

- **Test / developer**: [`MED3DPATHTEST`](#med3dpathtest) [`MEDCBGRID`](#medcbgrid) [`MYTEST`](#mytest) [`QVTEST`](#qvtest) [`TEST`](#test) [`TRAYFITTEST`](#trayfittest) [`TRAYLRRETEST`](#traylrretest) [`TRAYRETEST`](#trayretest) [`TRAYTEETEST`](#trayteetest) [`TRAYTEST`](#traytest)

- **.NET (MED-DotNet)**: [`CABLEPALETTE`](#cablepalette) [`CABLESET`](#cableset) [`MED-REBUILDMEDPROPERTIESJSON`](#med-rebuildmedpropertiesjson) [`MEDCABLE`](#medcable) [`MEDCHG`](#medchg) [`MED3DLIB`](#med3dlib) [`MED3DLIBINSERT`](#med3dlibinsert) [`MED3DLIBTEST`](#med3dlibtest) [`MEDDEBUG`](#meddebug) [`MEDPROPERTIES`](#medproperties) [`MEDPROPS`](#medprops) [`MEDREBUILDMEDPROPSJSON`](#medrebuildmedpropsjson) [`MEDRECORDS`](#medrecords) [`MEDRIBBONMODE`](#medribbonmode) [`MEDSET`](#medset) [`MEDSETTINGS`](#medsettings) [`MEDSHOW`](#medshow) [`MEDSHOWBOM`](#medshowbom) [`MEDSHOWSUM`](#medshowsum) [`MEDTYPE`](#medtype) [`MEDTYPES`](#medtypes) [`MEDXDEDIT`](#medxdedit)


## A-Z

### 2AWAY

Inserts the conduit-away symbol on a two-line conduit.

- **Source**: `Support\medcon.lsp` line 299
- **Prompts / options**: `Select lines of conduit:`; `First line:`; `Second line:`; `Select first point:`; `Select second point:` (via `dblins`, `be`)
- **Menu**: none found (type it)
- **Related**: [`2TOWARD`](#2toward) [`2BREAK`](#2break) [`2LCON`](#2lcon)

### 2BREAK

Inserts a break symbol on a two-line conduit.

- **Source**: `Support\medcon.lsp` line 158
- **Prompts / options**: `Select lines of conduit:`; `First line:`; `Second line:`; `Select first point:`; `Select second point:` (via `dblins`, `be`)
- **Menu**: none found (type it)
- **Related**: [`2AWAY`](#2away) [`2TOWARD`](#2toward)

### 2LCON

Two-line (detail) conduit run.

- **Source**: `Support\medcon.lsp` line 164
- **Prompts / options**: `Pick point:`; `Conduit Tag number <NONE>:` (via `c:conduit`)
- **Menu**: none found (type it)
- **Related**: [`2LFLEX`](#2lflex) [`CONFIX`](#confix) [`2AWAY`](#2away) [`2TOWARD`](#2toward) [`2BREAK`](#2break)
- Image: TODO

### 2LFLEX

Two-line flexible conduit run.

- **Source**: `Support\medcon.lsp` line 170
- **Prompts / options**: `Pick point:`; `Conduit Tag number <NONE>:` (via `c:conduit`)
- **Menu**: none found (type it)
- **Related**: [`2LCON`](#2lcon)

### 2LINE

Double / triple line: offsets a polyline by _2LINOFF / _3LINOFF.

- **Source**: `Support\medwire.lsp` line 80
- **Prompts / options**: `Pick point:`; `Select Side to offset to:`
- **Menu**: none found (type it)
- **Related**: [`MEDLINE`](#medline)

### 2TOWARD

Inserts the conduit-toward symbol on a two-line conduit.

- **Source**: `Support\medcon.lsp` line 305
- **Prompts / options**: `Select lines of conduit:`; `First line:`; `Second line:`; `Select first point:`; `Select second point:` (via `dblins`, `be`)
- **Menu**: none found (type it)
- **Related**: [`2AWAY`](#2away) [`2BREAK`](#2break)

### 3DJBOX

3D junction box from corner, angle, height, width, depth.

- **Source**: `Support\MED3DMisc.lsp` line 9
- **Prompts / options**: `Insertion Point (Left Bottom Front Corner):`; `Angle of Generation (Face Alignment):`; `JBox Height:`; `JBox Width:`; `JBox Depth:`
- **Menu**: none found (type it)
- **Related**: [`HUBS`](#hubs)
- Image: TODO

### 3LINE

Double / triple line: offsets a polyline by _2LINOFF / _3LINOFF.

- **Source**: `Support\medwire.lsp` line 104
- **Prompts / options**: `Pick point:`; `Select Side to offset to:`
- **Menu**: none found (type it)
- **Related**: [`MEDLINE`](#medline)

### ABL

Adds a leader to a selected bubble.

- **Source**: `Support\medtag.lsp` line 83
- **Prompts / options**: `Select bubble to add leader:`; `To:`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Add Bubble Leader; MEDRibbon.cuix Ribbon: MEDUtilities > Add Bubble Leader; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`MB`](#mb)

### AC

Changes a selected attribute to a new value.

- **Source**: `Support\medtext.lsp` line 362
- **Prompts / options**: `Enter new value:`; `Select Attribute:`
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Attribute Replace; MEDRibbon.cuix Ribbon: Attribute Tools > Attribute Replace; med.cuix Toolbar: Attribute Tools (+1 more)
- **Related**: [`ACX`](#acx) [`ATTCOPY`](#attcopy)

### ACX

Replaces part of attribute values (old string -> new string).

- **Source**: `Support\medtext.lsp` line 331
- **Prompts / options**: `For window selection hit return for attribute selection.`; `Select attributes to change:`; `old string:`; `new string:`
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Attribute Change; MEDRibbon.cuix Ribbon: Attribute Tools > Attribute Change; med.cuix Toolbar: Attribute Tools (+1 more)
- **Related**: [`AC`](#ac) [`CX`](#cx)

### ADDRE

Adds a given number of reducing fittings (RE) to an entity's MED_FITTING xdata.

- **Source**: `Support\QKEY.lsp` line 712
- **Prompts / options**: `Select Entity to Add RE'S to:`; `Size may not be larger than current size.`; `Size to Reduce to:`; `Number of Reducers to add:`
- **Menu**: none found (type it)
- **Related**: [`MFIT`](#mfit) [`CHGSIZE`](#chgsize)

### AL

Arrow leader.

- **Source**: `Support\MEDCommands.lsp` line 170
- **Prompts / options**: `Leader Start Point:`; `*********Layer Info Not Found Using Current Layer` (via `medleader`, `med_text`)
- **Menu**: none found (type it)
- **Related**: [`GLEAD`](#glead) [`GRAB`](#grab)

### ALEAD

Arrow leader.

- **Source**: `Support\MEDCommands.lsp` line 159
- **Prompts / options**: `Leader Start Point:`; `*********Layer Info Not Found Using Current Layer` (via `medleader`, `med_text`)
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Arrow Leader; MEDRibbon.cuix Ribbon: MEDUtilities > Arrow Leader; MEDRibbon.cuix Ribbon: Tagging > Arrow Leader (+4 more)
- **Related**: [`GLEAD`](#glead) [`GRAB`](#grab)

### APP

Appends a string to selected text.

- **Source**: `Support\QKEY.lsp` line 1510
- **Prompts / options**: `Text to append:`
- **Menu**: none found (type it)
- **Related**: [`PAR`](#par) [`CTEDIT`](#ctedit)

### ATADD

Adds an attribute to a block insert.

- **Source**: `Support\medtext.lsp` line 751
- **Prompts / options**: `Select Block to Add Attribute to:`; `TAG:`; `Value:`; `Select Point for Insertion of Attribute:`; `Justification of Text: L/ML/TL/C/M/TC/R/MR/TR:`; `Pick point for text to align by justification:` [Left MLeft TLeft Center Middle TCenter Right MRight TRight]
- **Menu**: none found (type it)
- **Related**: [`ATTCOPY`](#attcopy)

### ATC

Alias for ATTCOPY.

- **Source**: `Support\QKEY.lsp` line 1750
- **Prompts / options**: `Select Attribute to Copy:`; `Select Attribute to copy to:` (via `c:attcopy`)
- **Menu**: none found (type it)
- **Related**: [`ATTCOPY`](#attcopy)

### ATLSC

Adds schedule data (material 67 / 68) to a picked entity's xdata (legacy lighting/receptacle schedule).

- **Source**: `Support\QKEY.lsp` line 1251
- **Prompts / options**: `Select Entity to add Schedule data:` (via `atsched`)
- **Menu**: none found (type it)
- **Related**: [`MEDCHG`](#medchg)

### ATRSC

Adds schedule data (material 67 / 68) to a picked entity's xdata (legacy lighting/receptacle schedule).

- **Source**: `Support\QKEY.lsp` line 1254
- **Prompts / options**: `Select Entity to add Schedule data:` (via `atsched`)
- **Menu**: none found (type it)
- **Related**: [`MEDCHG`](#medchg)

### ATTCOPY

Copies one attribute value to another attribute.

- **Source**: `Support\medtext.lsp` line 1113
- **Prompts / options**: `Select Attribute to Copy:`; `Select Attribute to copy to:`
- **Menu**: none found (type it)
- **Related**: [`ATC`](#atc) [`AC`](#ac)

### ATTLAY

Moves the attributes of selected blocks to the MED text layer.

- **Source**: `Support\QKEY.lsp` line 470
- **Prompts / options**: `Select blocks to change attribute layer:`
- **Menu**: none found (type it)
- **Related**: [`ATTROT`](#attrot)

### ATTROT

Rotates the attributes of selected blocks to 0 degrees.

- **Source**: `Support\QKEY.lsp` line 518
- **Prompts / options**: `Select blocks to rotate attributes to 0 degrees:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Attribute Rotate; MEDRibbon.cuix Ribbon: Attribute Tools > Attribute Rotate; med.cuix Toolbar: Attribute Tools (+1 more)
- **Related**: [`ATTLAY`](#attlay)

### B1

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 187
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.125 Bold Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.125 Bold Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### B2

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 190
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.15625 Bold Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.15625 Bold Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### B3

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 193
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.1875 Bold Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.1875 Bold Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### BC

Alias for BOXCLOUD.

- **Source**: `Support\QKEY.lsp` line 1747
- **Prompts / options**: `First Corner of Cloud:`; `Second Corner of Cloud:` (via `c:boxcloud`)
- **Menu**: none found (type it)
- **Related**: [`BOXCLOUD`](#boxcloud)

### BF

BREAK at two points.

- **Source**: `Support\QKEY.lsp` line 57
- **Prompts / options**: `Select Entity to break:`; `First Point:`; `Second Point:`
- **Menu**: none found (type it)
- **Related**: [`PB`](#pb) [`LB`](#lb)

### BLDIST

Builds break/rotation distances for a block (0/90/180/270 points) for medblck.dat.

- **Source**: `Support\medsetup.lsp` line 191
- **Prompts / options**: `Select block to build break and rotate info on`; `First distance point for 0 rotation:`; `Second distance point for 90 rotation :`; `Third distance point for 180 rotation:`; `Fourth distance point for 270 rotation:`; `Rotation Specification <nil 0 1 22 24 3 4 5 6>:` [Nil 0 1 22 24 3 4 5 6]
- **Menu**: none found (type it)
- **Related**: [`MEDBLOCKINSERT`](#medblockinsert)

### BLDSTL

Builds temporary commands named after each text style (MEDlsp.tmp) to set that style.

- **Source**: `Support\medutil.lsp` line 558
- **Prompts / options**: none of its own (calls `append`, `atoms-family`, `close`)
- **Menu**: none found (type it)
- **Related**: [`XT`](#xt)

### BLK2BYL

Loads blk2byl.lsp and runs its BLK2BYL (block layers to 0/ByLayer). blk2byl.lsp is not in Support.

- **Source**: `Support\QKEY.lsp` line 1779
- **Prompts / options**: none of its own (calls `c:blk2byl`, `load`)
- **Menu**: none found (type it)
- **Related**: [`BN`](#bn)

### BLKREINS

Re-inserts blocks by name.

- **Source**: `Support\medutil.lsp` line 686
- **Prompts / options**: `Block Name to re-insert:`
- **Menu**: none found (type it)
- **Related**: [`BN`](#bn)

### BN

Shows the block name of a picked insert.

- **Source**: `Support\medutil.lsp` line 299
- **Prompts / options**: `Entity Selected is not a block.`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Block Name
- **Related**: [`BLKREINS`](#blkreins)

### BOM

Extracts all MED xdata in the drawing to MEDProject (deletes this drawing's old rows first). Not live.

- **Source**: `Support\MEDCommands.lsp` (`C:BOM` / `MEDBomFromSelection`)
- **Prompts / options**: none of its own (ssget "X" MED* xdata; calls `medprocesssqlstatement`, `medsendentitydatatobom`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Data to BOM; MEDRibbon.cuix Ribbon: MED Data Tools > MED Data to BOM; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`BOMSS`](#bomss) [`MEDSHOWBOM`](#medshowbom) [`TAKEOFF`](#takeoff)

### BOMSS

Bill of materials from a user selection of MED entities (same write path as BOM).

- **Source**: `Support\MEDCommands.lsp` (`C:BOMSS` / `MEDBomFromSelection`)
- **Prompts / options**: `Select MED entities for BOM:` (ssget filtered to MED* xdata). Empty/cancel leaves the BOM unchanged.
- **Menu**: med.cuix Menu: MED Main > MED BOM Selection; MEDRibbon.cuix Ribbon: MED Data Tools > MED BOM Selection; med.cuix Toolbar: MED Data Tools
- **Related**: [`BOM`](#bom) [`MEDSHOWBOM`](#medshowbom) [`TAKEOFF`](#takeoff)


### BOXCLOUD

Rectangular revision cloud from two corners with X/Y arc spacing.

- **Source**: `Support\medtag.lsp` line 413
- **Prompts / options**: `First Corner of Cloud:`; `Second Corner of Cloud:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Box Cloud; MEDRibbon.cuix Ribbon: MEDUtilities > Box Cloud; med.cuix Toolbar: Lisp Tools (+1 more)
- **Related**: [`CLOUD`](#cloud) [`BC`](#bc)
- Image: TODO

### BRACKET

Bracket mark from two points and a direction.

- **Source**: `Support\medtag.lsp` line 96
- **Prompts / options**: `First point of bracket:`; `Second point of bracket:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Bracket; MEDRibbon.cuix Ribbon: MEDUtilities > Bracket; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`CUT`](#cut)

### C3D

Selected cable runs to 3D solids on MED_3DCABLE.

- **Source**: `Support\MED3DPath.lsp` line 1337
- **Prompts / options**: `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).` (via `medrebuildmedpropsjsonbeside`)
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d) [`MAKE3DCABLE`](#make3dcable)

### CABLE

Draws a cable run (MED_CABLE xdata, tag + related tag). Palette "Route Cable" runs this.

- **Source**: `Support\medcable.lsp` line 37
- **Prompts / options**: `Pick point:`; `Cable Tag number <NONE>:`; `Cable Relate Tag <NONE>:` (via `med-cable-draw`)
- **Menu**: med.cuix Menu: Cables; med.cuix Menu: Cables > #2 Gnd Cable; med.cuix Menu: Cables > #2/0 Gnd Cable; med.cuix Menu: Cables > #4/0 Gnd Cable (+7 more)
- **Related**: [`MEDCABLE`](#medcable) [`RUN3DCABLE`](#run3dcable) [`C3D`](#c3d)
- Image: TODO

### CABLEPALETTE

Shows the MED Cable palette (type, then cable). See [cable.md](cable.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedCablePalette.cs` line 13 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDCABLE`](#medcable) [`CABLESET`](#cableset) [`CABLE`](#cable)


### CABLESET

Alias: shows the Cable palette. See [cable.md](cable.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedCablePalette.cs` line 20 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDCABLE`](#medcable) [`CABLEPALETTE`](#cablepalette)


### CC

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 45
- **Prompts / options**: none of its own (runs `COPY`)
- **Menu**: none found (type it)

### CD

Coordinate text from a grid line or two points.

- **Source**: `Support\MEDCommands.lsp` line 197
- **Prompts / options**: `Select coordinate line:[Press Enter to Pick two Points]`; `Select Point:`; `Select otherpoint`; `Starting point of text:`; `Rotation of text:`
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Coordinate Text
- **Related**: [`T1`](#t1)

### CF

Centerline layer off / on.

- **Source**: `Support\QKEY.lsp` line 757
- **Prompts / options**: none of its own (runs `LAYER`)
- **Menu**: none found (type it)
- **Related**: [`TRAY`](#tray)

### CHAN30

Cable channel elbow of that angle.

- **Source**: `Support\medtray.lsp` line 243
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > 30 Deg Chan. Fit; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Horizontal 30 deg
- **Related**: [`CHANNEL`](#channel)

### CHAN45

Cable channel elbow of that angle.

- **Source**: `Support\medtray.lsp` line 237
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > 45 Deg Chan. Fit; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Horizontal 45 deg
- **Related**: [`CHANNEL`](#channel)

### CHAN60

Cable channel elbow of that angle.

- **Source**: `Support\medtray.lsp` line 231
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > 60 Deg Chan. Fit; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Horizontal 60 deg
- **Related**: [`CHANNEL`](#channel)

### CHAN90

Cable channel elbow of that angle.

- **Source**: `Support\medtray.lsp` line 249
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `medmtray90`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > 90 Deg Chan. Fit; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Horizontal 90 deg
- **Related**: [`CHANNEL`](#channel)

### CHANCROSS

Cable channel tee / cross.

- **Source**: `Support\medtray.lsp` line 221
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `c:traycross`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > Channel Cross; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > chan Cross Fitt.
- **Related**: [`CHANNEL`](#channel)

### CHANDN

Cable channel up / down / plan vertical 90.

- **Source**: `Support\MEDCableTray.lsp` line 1911
- **Prompts / options**: `Select Tray item` (via `trayupdown`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Channel Down; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > chan Down
- **Related**: [`CHANNEL`](#channel) [`TRAYUP`](#trayup)

### CHANNEL

Cable channel run (4" default).

- **Source**: `Support\medtray.lsp` line 108
- **Prompts / options**: `To Point:` (via `c:tray`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > 4" Cable Channel; med.cuix Menu: Cable Tray > 6" Cable Channel; med.cuix Image menu: Plan Cable Channel and Fittings (+2 more)
- **Related**: [`CHAN90`](#chan90) [`CHANTEE`](#chantee) [`CHANOFF`](#chanoff)

### CHANOFF

Cable channel offset.

- **Source**: `Support\medtray.lsp` line 255
- **Prompts / options**: `Select First Entity:`; `Distance of Offset:`; `Offset with 30 / 45 / 60 / 90 degree angle:`; `To Point:`; `Tag <NONE>:`; `Angle of generation:` [30 45 60 90] [+ -] [Up Down] (via `c:trayoff`, `c:tray`, `get_con_tag`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Channel Offset; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Offset Cable Chan
- **Related**: [`CHANNEL`](#channel) [`TRAYOFF`](#trayoff)

### CHANTEE

Cable channel tee / cross.

- **Source**: `Support\medtray.lsp` line 217
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `c:traytee`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Channel Fittings; med.cuix Menu: Channel Fittings > Channel Tee; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > chan Tee Fitt.
- **Related**: [`CHANNEL`](#channel)

### CHANUP

Cable channel up / down / plan vertical 90.

- **Source**: `Support\MEDCableTray.lsp` line 1919
- **Prompts / options**: `Select Tray item` (via `trayupdown`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Channel Up; med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > chan Up
- **Related**: [`CHANNEL`](#channel) [`TRAYUP`](#trayup)

### CHANV90

Cable channel up / down / plan vertical 90.

- **Source**: `Support\medtray.lsp` line 225
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:`; `Tag <NONE>:` [Inside Outside] (via `c:trayv90`, `get_con_tag`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Plan Vert 90
- **Related**: [`CHANNEL`](#channel) [`TRAYUP`](#trayup)

### CHGSIZE

Changes the size in the MED xdata of a selection of conduits or fittings.

- **Source**: `Support\MEDCommands.lsp` line 406
- **Prompts / options**: `Select Entities to change Size:`; `Change COnduit or Fitting <CO>:`; `New Size for Selected Entities:` [COnduit Fitting]
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Change Size; MEDRibbon.cuix Ribbon: MED Data Tools > Change Size; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`CHGTAG`](#chgtag) [`MEDCHG`](#medchg)

### CHGTAG

Changes the tag in the MED xdata of a selection. (Prompt text still says "New Size".)

- **Source**: `Support\MEDCommands.lsp` line 758
- **Prompts / options**: `Select Entities to change TAG:`; `New Size for Selected Entities:`
- **Menu**: none found (type it)
- **Related**: [`CHGSIZE`](#chgsize) [`CTAG`](#ctag)

### CL

Moves a selection to the layer of a picked entity.

- **Source**: `Support\medutil.lsp` line 312
- **Prompts / options**: `Select entities to be changed to selected layer:`; `Select Entity of desired layer:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Change Layer; MEDRibbon.cuix Ribbon: Layer Tools > Change Layer; med.cuix Toolbar: Layer Tools (+1 more)
- **Related**: [`SL`](#sl)

### CLOUD

Revision cloud: pick-and-drag closed polyline cloud.

- **Source**: `Support\medtag.lsp` line 38
- **Prompts / options**: `Pick point:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Revison Cloud; MEDRibbon.cuix Ribbon: MEDUtilities > Revison Cloud; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`BOXCLOUD`](#boxcloud)
- Image: TODO

### CN

Centerline layer off / on.

- **Source**: `Support\QKEY.lsp` line 763
- **Prompts / options**: none of its own (runs `LAYER`)
- **Menu**: none found (type it)
- **Related**: [`TRAY`](#tray)

### COM

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 204
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: none found (type it)
- **Related**: [`DETAIL`](#detail)

### CONDUIT

Draws a conduit polyline run with MED_CONDUIT xdata; optional bend fillet; tag prompt.

- **Source**: `Support\medcon.lsp` line 2
- **Prompts / options**: `Pick point:`; `Conduit Tag number <NONE>:`
- **Menu**: med.cuix Menu: Plan Conduit; med.cuix Menu: Plan Conduit > EMT; med.cuix Menu: Plan Conduit > PVC; med.cuix Menu: Plan Conduit > PVC-COAT (+25 more)
- **Related**: [`CONSIZE`](#consize) [`DEFINE`](#define) [`FC`](#fc) [`FLEX`](#flex) [`CTAG`](#ctag)
- Image: TODO

### CONFIX

Rebuilds a two-line conduit from its centerline.

- **Source**: `Support\medcon.lsp` line 192
- **Prompts / options**: `Select Conduit to fix:`
- **Menu**: none found (type it)
- **Related**: [`2LCON`](#2lcon)

### CONSIZE

DCL conduit size picker (sets _CSIZE/_ACSIZE/_CLETT).

- **Source**: `Support\medcon.lsp` line 114
- **Prompts / options**: `Pick point:`; `Conduit Tag number <NONE>:` (via `c:conduit`)
- **Menu**: med.cuix Menu: Set Size; med.cuix Menu: Set Size > Set Size...
- **Related**: [`CONDUIT`](#conduit) [`MEDSETTINGS`](#medsettings)
- Image: TODO

### CT

Changes text strings; pick several in the order to change.

- **Source**: `Support\medtext.lsp` line 299
- **Prompts / options**: none of its own (runs `SELECT`)
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Change Text; MEDRibbon.cuix Ribbon: Text Styles > Change Text; med.cuix Toolbar: Text Styles (+1 more)
- **Related**: [`CX`](#cx) [`RT`](#rt)

### CTAG

Conduit tag (block contag) from xdata size/tag.

- **Source**: `Support\QKEY.lsp` line 204
- **Prompts / options**: `Select conduit to tag:`; `Invalid selection of conduit`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Conduit Tag; MEDRibbon.cuix Ribbon: Tagging > Conduit Tag; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`TTAG`](#ttag) [`HDTAG`](#hdtag)
- Image: TODO

### CTEDIT

Edits a text set: change / prefix / suffix, autostep or typical.

- **Source**: `Support\medtext.lsp` line 375
- **Prompts / options**: `Prefix:`; `Suffix:`; `Change/Prefix/Suffix <Change>:`; `Single or Multiple edit:`; `Autostep Or Typical:`; `Start point:` [Change Prefix Suffix] [Single Multiple] [Autostep Typical] (via `ntext`, `sets`, `edadd`)
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Suffix & Prefix
- **Related**: [`CT`](#ct) [`TSTRIP`](#tstrip)

### CUT

Cut marks plus a section letter.

- **Source**: `Support\medtag.lsp` line 19
- **Prompts / options**: `Pick first section point`; `Pick second section point`; `Enter section letter :`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Cut Marks; MEDRibbon.cuix Ribbon: Tagging > Cut Marks; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`SECT`](#sect)

### CW

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 43
- **Prompts / options**: none of its own (runs `COPY`)
- **Menu**: none found (type it)

### CX

Find and replace a substring across selected text.

- **Source**: `Support\medtext.lsp` line 658
- **Prompts / options**: `Select text to be changed:`; `New String:`; `Nothing to do!`
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Find & Replace Txt
- **Related**: [`CT`](#ct) [`ACX`](#acx)

### DD

DDEDIT for TEXT/ATTDEF/MTEXT, DDATTE for INSERT.

- **Source**: `Support\QKEY.lsp` line 65
- **Prompts / options**: none of its own (runs `DDATTE`, `DDEDIT`)
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Dialog Edit
- **Related**: [`CT`](#ct)

### DEFINE

Attaches the current conduit settings (xdata) to existing geometry of a run.

- **Source**: `Support\medcon.lsp` line 38
- **Prompts / options**: `Select conduit run to define to current settings:`; `Select all entities of conduit run (all entities must meet):`; `Conduit Tag number <NONE>:`
- **Menu**: med.cuix Menu: Plan Conduit; med.cuix Menu: Plan Conduit > Define:
- **Related**: [`CONDUIT`](#conduit) [`MCON`](#mcon)

### DETAG

Detail bubble detbub2 from catalog keys.

- **Source**: `Support\QKEY.lsp` line 1242
- **Prompts / options**: `From point:`; `To point:`; `Select Entity with Detail info:`; `Detail Number:`; `Drawing Number:`; `Typical:` (via `detailtag`)
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Detail Tag; MEDRibbon.cuix Ribbon: Tagging > Detail Tag; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`DETAG2`](#detag2) [`DETAGUPD`](#detagupd)
- Image: TODO

### DETAG2

Alternate detail bubble dtlhd1.

- **Source**: `Support\QKEY.lsp` line 1246
- **Prompts / options**: `From point:`; `To point:`; `Select Entity with Detail info:`; `Detail Number:`; `Drawing Number:`; `Typical:` (via `detailtag`)
- **Menu**: none found (type it)
- **Related**: [`DETAG`](#detag)

### DETAGUPD

Refreshes typical counts on existing detail bubbles.

- **Source**: `Support\MEDCommands.lsp` line 617
- **Prompts / options**: none of its own (calls `action_tile`, `add_list`, `end_list`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Detail Update; MEDRibbon.cuix Ribbon: MED Data Tools > Detail Update; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`DETAG`](#detag)

### DETAIL

DCL detail picker by MEDType group; inserts the block with MED_EQUIP xdata.

- **Source**: `Support\meddetl.lsp` line 2
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Menu: Details; med.cuix Menu: Details > Details...
- **Related**: [`LTG`](#ltg) [`GND`](#gnd) [`PWR`](#pwr) [`DETAG`](#detag)
- Image: TODO

### EC

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 41
- **Prompts / options**: none of its own (runs `ERASE`)
- **Menu**: none found (type it)

### EM

Extend multiple to a boundary set.

- **Source**: `Support\medutil.lsp` line 339
- **Prompts / options**: `Select Boundries to extend to:`; `Select entities to be extended:`; `Select point to base extension:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Extend Multi; med.cuix Image menu: Misc. Tools; med.cuix Image menu: Misc. Tools > Extend Multi
- **Related**: [`TM`](#tm)

### ESOLID

**Definition in `Support\MED3DCON.lsp`:**

Erases all 3D solids (copy in unloaded MED3DCON.lsp).

- **Source**: `Support\MED3DCON.lsp` line 562 - *not loaded by MEDCore*. also defined in Support\medtray.lsp:1322; replaced at load time by Support\medtray.lsp:1322
- **Prompts / options**: none of its own (runs `ERASE`)
- **Menu**: none found (type it)
- **Related**: 

**Definition in `Support\medtray.lsp`:**

Erases ALL 3DSOLIDs in the drawing (loaded version).

- **Source**: `Support\medtray.lsp` line 1322. also defined in Support\MED3DCON.lsp:562; this definition loads last and wins
- **Prompts / options**: none of its own (runs `ERASE`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### EW

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 39
- **Prompts / options**: none of its own (runs `ERASE`)
- **Menu**: none found (type it)

### F0

FILLET with radius 0 (restores FILLETRAD after).

- **Source**: `Support\QKEY.lsp` line 1691
- **Prompts / options**: `Pick`
- **Menu**: MEDRibbon.cuix Ribbon: Fillets > Fillet Zero Radius; med.cuix Toolbar: Fillets; med.cuix Toolbar: Fillets > Fillet Zero Radius
- **Related**: [`FC`](#fc)

### FC

Fillet at the bend radius for a conduit size (asks the size).

- **Source**: `Support\medcon.lsp` line 78
- **Prompts / options**: `Enter conduit size number only:`
- **Menu**: MEDRibbon.cuix Ribbon: Fillets > Fillet Conduit; med.cuix Toolbar: Fillets; med.cuix Toolbar: Fillets > Fillet Conduit
- **Related**: [`CONDUIT`](#conduit) [`F0`](#f0)

### FD

Inserts/updates the FILEINFO block (name, scale, date, user).

- **Source**: `Support\medtext.lsp` line 2
- **Prompts / options**: `Select Insertion Point:`; `Angle of insertion:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > File Date; med.cuix Toolbar: Lisp Tools; med.cuix Toolbar: Lisp Tools > File Date (+2 more)
- **Related**: [`SETUP`](#setup)

### FL

Freezes the layers of picked entities.

- **Source**: `Support\medutil.lsp` line 253
- **Prompts / options**: `Select entities upon layers to be frozen:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Freeze Layers; MEDRibbon.cuix Ribbon: Layer Tools > Freeze Layers; med.cuix Toolbar: Layer Tools (+1 more)
- **Related**: [`IL`](#il)

### FLEX

Draws a flexible conduit (4-point spline-like run) with connectors.

- **Source**: `Support\medcon.lsp` line 95
- **Prompts / options**: `Enter start point of flex`; `Enter second point of flex`; `Enter third point of flex`; `Enter fourth point of flex`; `Enter last point of flex`
- **Menu**: med.cuix Menu: Plan Conduit; med.cuix Menu: Plan Conduit > Flex; med.cuix Image menu: Plan Conduit; med.cuix Image menu: Plan Conduit > Flexible Conduit
- **Related**: [`CONDUIT`](#conduit) [`2LFLEX`](#2lflex)
- Image: TODO

### GL

Hook ("grab") leader / add a hoop at a line end.

- **Source**: `Support\MEDCommands.lsp` line 174
- **Prompts / options**: `Leader Start Point:`; `*********Layer Info Not Found Using Current Layer` (via `medleader`, `med_text`)
- **Menu**: none found (type it)
- **Related**: [`ALEAD`](#alead)

### GLEAD

Hook ("grab") leader / add a hoop at a line end.

- **Source**: `Support\MEDCommands.lsp` line 163
- **Prompts / options**: `Leader Start Point:`; `*********Layer Info Not Found Using Current Layer` (via `medleader`, `med_text`)
- **Menu**: none found (type it)
- **Related**: [`ALEAD`](#alead)

### GND

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 189
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Menu: Details; med.cuix Menu: Details > Grounding; med.cuix Toolbar: Details; med.cuix Toolbar: Details > Grounding Details
- **Related**: [`DETAIL`](#detail)

### GR

Hook ("grab") leader / add a hoop at a line end.

- **Source**: `Support\medtag.lsp` line 125
- **Prompts / options**: `Select Point near Endpoint of Line:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Add Hoop; MEDRibbon.cuix Ribbon: Tagging > Add Hoop; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`ALEAD`](#alead)

### GRAB

Hook ("grab") leader / add a hoop at a line end.

- **Source**: `Support\MEDCommands.lsp` line 166
- **Prompts / options**: `Leader Start Point:`; `*********Layer Info Not Found Using Current Layer` (via `medleader`, `med_text`)
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Hoop Leader; MEDRibbon.cuix Ribbon: MEDUtilities > Hoop Leader; MEDRibbon.cuix Ribbon: Tagging > Hoop Leader (+4 more)
- **Related**: [`ALEAD`](#alead)

### HAND

Copies the entity with a typed handle.

- **Source**: `Support\QKEY.lsp` line 1754
- **Prompts / options**: `\Enter Handle:`; `Handle not found!`
- **Menu**: none found (type it)

### HDTAG

"Hot dog" conduit tag sized to the text.

- **Source**: `Support\medtag.lsp` line 190
- **Prompts / options**: `Select Conduit to Tag:`; `Conduit Size:`; `Conduit Tag:`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > HotDog Tag; MEDRibbon.cuix Ribbon: Tagging > HotDog Tag; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`HDTAGOLD`](#hdtagold) [`CTAG`](#ctag)
- Image: TODO

### HDTAGOLD

Previous hot dog tag version.

- **Source**: `Support\medtag.lsp` line 305
- **Prompts / options**: `Tag Information:`; `Insertion Pont:`; `Rotation:`
- **Menu**: none found (type it)
- **Related**: [`HDTAG`](#hdtag)

### HUBS

Adds hubs to an RS junction box at picked locations.

- **Source**: `Support\MEDCommands.lsp` line 553
- **Prompts / options**: `Select Jbox and location of hub:`; `Invalid number of hubs for hub size`; `Conduit size is to large for jbox`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `jbhub`, `c:medblockinsert`)
- **Menu**: med.cuix Menu: J-Boxes; med.cuix Menu: J-Boxes > HUBS; MEDRibbon.cuix Ribbon: Detail Conduit > RS Jboxes > RS JBOX Hubs; MEDRibbon.cuix Ribbon: RS Jboxes > RS JBOX Hubs (+2 more)
- **Related**: [`3DJBOX`](#3djbox)
- Image: TODO

### IL

Isolate layer: makes the picked entity's layer current and turns all other layers off (remembered in _LAYLIST).

- **Source**: `Support\medutil.lsp` line 652
- **Prompts / options**: `Select Entity to Isolate Layer:`
- **Menu**: none found (type it)
- **Related**: [`UIL`](#uil) [`FL`](#fl)

### INS

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 198
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Toolbar: Details; med.cuix Toolbar: Details > Instrument Details
- **Related**: [`DETAIL`](#detail)

### IOD

Finds dimensions with a text override and moves them to layer "_Faked Dimensions" so overridden (faked) dimensions stand out.

- **Source**: `Support\MEDDim.lsp` line 78
- **Prompts / options**: none of its own (calls `itoa`, `smlayer`, `ssget`)
- **Menu**: none found (type it)
- **Related**: [`MEDDIMSETUP`](#meddimsetup)

### ISOLATE

Hides everything except entities whose detail/equipment code matches a picked entity or typed code.

- **Source**: `Support\MEDCommands.lsp` line 326
- **Prompts / options**: `Select Entity with Detail info:`; `Code value to be used:`
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Isolate   Equip
- **Related**: [`UNISOLATE`](#unisolate) [`MEDFIND`](#medfind)

### IT

Instrument bubble (tag + number).

- **Source**: `Support\QKEY.lsp` line 1673
- **Prompts / options**: `Instrument Tag:`; `Instrument number:`; `Pick point`; `Tag location:`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Instrument Bubble; MEDRibbon.cuix Ribbon: Tagging > Instrument Bubble; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`ITAGA`](#itaga) [`ITAGE`](#itage) [`ITAGT`](#itagt)
- Image: TODO

### ITAGA

Instrument tag series with prefix A / E / T along a line.

- **Source**: `Support\QKEY.lsp` line 1479
- **Prompts / options**: `Startpoint for tags:`; `Tag string:` (via `itag`)
- **Menu**: none found (type it)
- **Related**: [`IT`](#it) [`QTA`](#qta)

### ITAGE

Instrument tag series with prefix A / E / T along a line.

- **Source**: `Support\QKEY.lsp` line 1476
- **Prompts / options**: `Startpoint for tags:`; `Tag string:` (via `itag`)
- **Menu**: none found (type it)
- **Related**: [`IT`](#it) [`QTA`](#qta)

### ITAGT

Instrument tag series with prefix A / E / T along a line.

- **Source**: `Support\QKEY.lsp` line 1482
- **Prompts / options**: `Startpoint for tags:`; `Tag string:` (via `itag`)
- **Menu**: none found (type it)
- **Related**: [`IT`](#it) [`QTA`](#qta)

### JBX

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 207
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: none found (type it)
- **Related**: [`DETAIL`](#detail)

### LB

Priority break: break entities around one that stays whole.

- **Source**: `Support\medutil.lsp` line 156
- **Prompts / options**: `Select entity not to be broken`; `Select entities to be broken`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Priority Break; MEDRibbon.cuix Ribbon: MEDUtilities > Priority Break; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`LBREAK`](#lbreak)

### LBREAK

Line break symbol between two points.

- **Source**: `Support\medutil.lsp` line 6
- **Prompts / options**: `Select entity to break`; `Pick 1st point of break:`; `Pick 2nd point of break:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Line Break; MEDRibbon.cuix Ribbon: MEDUtilities > Line Break; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`LB`](#lb)

### LINKPREFIX

Links a prefix text to other text / attributes (field-based).

- **Source**: `Support\medutil.lsp` line 788
- **Prompts / options**: `Select Prefix Text Entity:`; `Select Text Entities to Prefix (Chars replaced will match the prefix selected):`
- **Menu**: none found (type it)
- **Related**: [`LINKVALUE`](#linkvalue) [`SETLINK`](#setlink)

### LINKPREFIXATT

Links a prefix text to other text / attributes (field-based).

- **Source**: `Support\medutil.lsp` line 829
- **Prompts / options**: `Select Prefix Text Entity:`; `Select Text Entities to Prefix (Chars replaced will match the prefix selected):`; `Select Attribute:`
- **Menu**: none found (type it)
- **Related**: [`LINKVALUE`](#linkvalue) [`SETLINK`](#setlink)

### LINKVALUE

Links target text/attributes to a source value (field).

- **Source**: `Support\medutil.lsp` line 860
- **Prompts / options**: `Select Source Text/Atribute Entity:`; `Select Text/Attribute Entities Link`; `Select Text/Attribute:`
- **Menu**: none found (type it)
- **Related**: [`SETLINK`](#setlink)

### LISP

Loads a lisp file by name.

- **Source**: `Support\medutil.lsp` line 288
- **Prompts / options**: `Name of lisp file to load:`; `File name not found.`
- **Menu**: none found (type it)

### LOADLAYERS

Creates the MED layers from the Layers1 table (colour, linetype, lineweight).

- **Source**: `Support\MEDCommands.lsp` line 2
- **Prompts / options**: none of its own (calls `cdr`, `foreach`, `medmakelayer`)
- **Menu**: none found (type it)
- **Related**: [`SL`](#sl) [`CL`](#cl)

### LOADTXT

**Definition in `Support\medtext.lsp`:**

Creates the MED text styles from MED_TXT_STYLE_MAP (TXT0625 ... TXT1875), then runs BLDSTL. Replaced at load time by the med.spc version (med.spc loads after medtext.lsp).

- **Source**: `Support\medtext.lsp` line 1136. also defined in Support\med.spc:167; replaced at load time by the med.spc version
- **Prompts / options**: none of its own (runs `STYLE`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.09375 Text; MEDRibbon.cuix Ribbon: Text Styles > 0.125 Bold Text; MEDRibbon.cuix Ribbon: Text Styles > 0.125 Text; MEDRibbon.cuix Ribbon: Text Styles > 0.15625 Bold Text (+13 more)
- **Related**: [`T1`](#t1) [`XT`](#xt) [`BLDSTL`](#bldstl)

**Definition in `Support\med.spc`:**

Creates the older style set B250 B187 B125 T125 T125THIN T187 T937THIN T937 at _SC, then BLDSTL. MEDCore loads med.spc last, so this is the LOADTXT that runs.

- **Source**: `Support\med.spc` line 167. also defined in Support\medtext.lsp:1136; med.spc loads last in MEDCore, so this one wins
- **Prompts / options**: `Text Styles are now loaded.`
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.09375 Text; MEDRibbon.cuix Ribbon: Text Styles > 0.125 Bold Text; MEDRibbon.cuix Ribbon: Text Styles > 0.125 Text; MEDRibbon.cuix Ribbon: Text Styles > 0.15625 Bold Text (+13 more)
- **Related**: [`T1`](#t1) [`XT`](#xt) [`BLDSTL`](#bldstl)

### LOOPIT

Loop leader: draws a loop mark between two points on the text layer.

- **Source**: `Support\QKEY.lsp` line 1331
- **Prompts / options**: `Select First point:`; `Select Second point:`
- **Menu**: MEDRibbon.cuix Ribbon: MEDUtilities > Loop Leader; MEDRibbon.cuix Ribbon: Tagging > Loop Leader; med.cuix Toolbar: Tagging; med.cuix Toolbar: Tagging > Loop Leader
- **Related**: [`ALEAD`](#alead)

### LT

Changes linetype of a selection to a picked entity's.

- **Source**: `Support\medutil.lsp` line 359
- **Prompts / options**: `Select entities to be changed to selected entity's linetype:`; `Select Entity of desired linetype:`; `Set linetypes to bylayer Yes/<No>:`
- **Menu**: none found (type it)
- **Related**: [`CL`](#cl)

### LTG

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 192
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Menu: Details; med.cuix Menu: Details > Lighting; med.cuix Toolbar: Details; med.cuix Toolbar: Details > Lighting Details
- **Related**: [`DETAIL`](#detail)

### M3D

Selected conduit runs to 3D solids on MED_3DCONDUIT.

- **Source**: `Support\MED3DPath.lsp` line 1334
- **Prompts / options**: `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).` (via `medrebuildmedpropsjsonbeside`)
- **Menu**: none found (type it)
- **Related**: [`C3D`](#c3d) [`MAKE3DCONDUIT`](#make3dconduit) [`MED3DPLAN`](#med3dplan)
- Image: TODO

### M3DOLD

2012 single-run conduit to 3D (MED3DCON.lsp, not loaded).

- **Source**: `Support\MED3DCON.lsp` line 429 - *not loaded by MEDCore*
- **Prompts / options**: `Select MED conduit polyline:`
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d)

### MAKE3DCABLE

Every cable run to 3D; Dwg or Layer.

- **Source**: `Support\MED3DPath.lsp` line 1343
- **Prompts / options**: `Use the PLAN command to return to plan view.`; `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).` [Dwg Layer] (via `med3d-export`, `medrebuildmedpropsjsonbeside`)
- **Menu**: none found (type it)
- **Related**: [`C3D`](#c3d) [`MEDMAKE3D`](#medmake3d)

### MAKE3DCONDUIT

Every conduit run to 3D; Dwg (WBLOCK + .medprops.json) or Layer.

- **Source**: `Support\MED3DPath.lsp` line 1340
- **Prompts / options**: `Use the PLAN command to return to plan view.`; `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).` [Dwg Layer] (via `med3d-export`, `medrebuildmedpropsjsonbeside`)
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d) [`MEDMAKE3D`](#medmake3d)

### MAKE3DCONDUITOLD

2012 all-conduit to 3D/3DS export (MED3DCON.lsp, not loaded).

- **Source**: `Support\MED3DCON.lsp` line 443 - *not loaded by MEDCore*
- **Prompts / options**: `Output to 3DS Layer <Dwg>:`; `Make3dconduit will export to 3ds file:`; `Use the PLAN command to return to plan view:` [3DS Dwg Layer]
- **Menu**: none found (type it)
- **Related**: [`MAKE3DCONDUIT`](#make3dconduit)

### MAKE3DTRAY

3D solids from all tray and tray fittings (Dwg/Layer/3DS). See 3d.md.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 464
- **Prompts / options**: `Output to 3DS Layer <Dwg>:`; `Make3dtray will export to 3ds file:`; `Use the PLAN command to return to plan view:` [3DS Dwg Layer]
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > 3D Tray Out; MEDRibbon.cuix Ribbon: Cable Tray Tools > 3D Tray Out; med.cuix Toolbar: Cable Tray (+1 more)
- **Related**: [`MEDMAKE3D`](#medmake3d) [`ESOLID`](#esolid)
- Image: TODO

### MB

Material bubble(s) with leader.

- **Source**: `Support\medtag.lsp` line 330
- **Prompts / options**: `Material code:`; `Material I.D.#:`; `Quantity <1>:`; `Pickpoint:`; `Pick point of first bubble:`; `Direction of bubbles:`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Material Bubble; MEDRibbon.cuix Ribbon: Tagging > Material Bubble; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`MBL`](#mbl) [`ABL`](#abl)
- Image: TODO

### MB1

Material bubble(s) with leader.

- **Source**: `Support\medtag.lsp` line 374
- **Prompts / options**: `Material I.D.#:`; `Pickpoint:`; `Pick point of first bubble:`; `Direction of bubbles:`
- **Menu**: MEDRibbon.cuix Ribbon: Tagging > Material Bubble; med.cuix Toolbar: Tagging; med.cuix Toolbar: Tagging > Material Bubble
- **Related**: [`MBL`](#mbl) [`ABL`](#abl)

### MBL

Moves a bubble or its leader point.

- **Source**: `Support\medtag.lsp` line 142
- **Prompts / options**: `Select leader to change of bubble to change:`; `Change Bubble point or Leader point <B>:`; `New point of Bubble:`; `New leader point:` [Bubble Leader]
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Move Bubble/Leadr; MEDRibbon.cuix Ribbon: MEDUtilities > Move Bubble Leader; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`MB`](#mb) [`ABL`](#abl)

### MC

**Definition in `Support\QKEY.lsp`:**

Move with crossing window. Overridden by the later MC defun (line 706) - never reachable.

- **Source**: `Support\QKEY.lsp` line 49. also defined in Support\QKEY.lsp:706; replaced at load time by Support\QKEY.lsp:706
- **Prompts / options**: none of its own (runs `MOVE`)
- **Menu**: none found (type it)
- **Related**: 

**Definition in `Support\QKEY.lsp`:**

Alias: runs the .NET MEDCHG properties palette (replaces the earlier move-crossing MC).

- **Source**: `Support\QKEY.lsp` line 706. also defined in Support\QKEY.lsp:49; this definition loads last and wins
- **Prompts / options**: none of its own (calls )
- **Menu**: none found (type it)
- **Related**: [`MEDCHG`](#medchg) [`MED`](#med)

### MCABLE

Adds a MED_CABLE record (current _CABCODE, tag NONE) to a picked polyline.

- **Source**: `Support\QKEY.lsp` line 160
- **Prompts / options**: `Select Entity to add a cable:`; `Entity selected is not a polyline`
- **Menu**: none found (type it)
- **Related**: [`MCON`](#mcon) [`CABLE`](#cable)

### MCON

Adds a MED_CONDUIT record (current _CODE/_CSIZE, tag NONE) to a picked polyline.

- **Source**: `Support\QKEY.lsp` line 75
- **Prompts / options**: `Select Entity to add a conduit:`; `Entity selected is not a polyline`
- **Menu**: none found (type it)
- **Related**: [`DEFINE`](#define) [`MTRAY`](#mtray) [`MCABLE`](#mcable) [`MFIT`](#mfit) [`MEQUIP`](#mequip)

### MED

Alias: runs the .NET MEDCHG properties palette.

- **Source**: `Support\medchg.lsp` line 1209
- **Prompts / options**: none of its own (calls )
- **Menu**: none found (type it)
- **Related**: [`MEDCHG`](#medchg) [`MC`](#mc)

### MED-REBUILDMEDPROPERTIESJSON

Command alias of MEDREBUILDMEDPROPSJSON (same name as the lisp function).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesLisp.cs` line 137 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDREBUILDMEDPROPSJSON`](#medrebuildmedpropsjson)


### MED2026SETUP

One-time profile setup: support + trusted paths, CUILOAD med.cuix, MENUBAR=1, clears an old enterprise-menu entry. See install.md.

- **Source**: `Support\MED2026-ProfileSetup.lsp` line 160 - *not loaded by MEDCore*
- **Prompts / options**: none of its own (calls `boundp`, `findfile`, `med2026-clearenterpriseifours`)
- **Menu**: none found (type it)
- **Related**: [`SETUP`](#setup)

### MED3DPATHTEST

Draws sample runs in a scratch drawing and converts them (tests\autocad\MED3DPathTest.lsp; APPLOAD first).

- **Source**: `tests\autocad\MED3DPathTest.lsp` line 54 - *not loaded by MEDCore*
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d)

### MED3DPLAN

Prints the corner/bend table of one run; draws nothing.

- **Source**: `Support\MED3DPath.lsp` line 1394
- **Prompts / options**: `Select MED conduit or cable run:`
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d)

### MED3DVER

Prints the MED3DPath version, command ownership, tray worker, debug and file paths.

- **Source**: `Support\MED3DPath.lsp` line 1368
- **Prompts / options**: none of its own (calls `findfile`, `med3d-debug-on`, `med3d-owner`)
- **Menu**: none found (type it)
- **Related**: [`MEDCBVER`](#medcbver) [`MEDMAKE3D`](#medmake3d)

### MEDBLOCKINSERT

Block insert used by the fitting/detail menu pipeline (setblkins data, break + rotation).

- **Source**: `Support\medinser.lsp` line 10
- **Prompts / options**: `Block Rotation <0>:`; `Block Size is Invalid:`
- **Menu**: MEDRibbon.cuix Ribbon: Conduit > Conduit Up Solid; MEDRibbon.cuix Ribbon: Conduit > Down; MEDRibbon.cuix Ribbon: Conduit > Up; MEDRibbon.cuix Ribbon: Conduit Fittings > ELL Fittings > LB Up (+23 more)
- **Related**: [`BLDIST`](#bldist) [`UNJ`](#unj)

### MEDCABLE

Shows the Cable palette; Route Cable on it runs lisp CABLE. See [cable.md](cable.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedCablePalette.cs` line 27 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`CABLEPALETTE`](#cablepalette) [`CABLE`](#cable)
- Image: TODO

### MEDCBALL

Gallery of every body type of every form at one trade size.

- **Source**: `Support\MED3DFittings.lsp` line 1020
- **Prompts / options**: `Base point <0,0,0>:`
- **Menu**: none found (type it)
- **Related**: [`MEDCBTEST`](#medcbtest)
- Image: TODO

### MEDCBDATA

Reloads conduit-body dimension data and lists sizes per form/shape.

- **Source**: `Support\MED3DFittings.lsp` line 1081
- **Prompts / options**: none of its own (calls `append`, `apply`, `cons`)
- **Menu**: none found (type it)
- **Related**: [`MEDCBVER`](#medcbver)

### MEDCBGRID

Draws every 2D fitting-symbol matrix row (fitting_matrix.csv) for a MEDMAKE3D check (tests\autocad\MEDCBGrid.lsp).

- **Source**: `tests\autocad\MEDCBGrid.lsp` line 155 - *not loaded by MEDCore*
- **Prompts / options**: `MEDCBGRID base point (top-left cell) <0,0>:`; `Rotation of every cell (degrees) <0>:`
- **Menu**: none found (type it)
- **Related**: [`MEDMAKE3D`](#medmake3d) [`MEDCBALL`](#medcball)
- Image: TODO

### MEDCBINS

Inserts one 3D conduit body (type, form, trade size) at picked points.

- **Source**: `Support\MED3DFittings.lsp` line 971
- **Prompts / options**: `Rotation about Z <0>:`
- **Menu**: none found (type it)
- **Related**: [`MEDCBTEST`](#medcbtest) [`MEDCBALL`](#medcball)
- Image: TODO

### MEDCBTEST

Row of LB LR LL T TB C X for one form and size, labelled.

- **Source**: `Support\MED3DFittings.lsp` line 992
- **Prompts / options**: `Base point for the row <0,0,0>:`
- **Menu**: none found (type it)
- **Related**: [`MEDCBINS`](#medcbins) [`MEDCBALL`](#medcball)
- Image: TODO

### MEDCBVER

Prints MED3DFittings version, row count and CSV path.

- **Source**: `Support\MED3DFittings.lsp` line 1095
- **Prompts / options**: none of its own (calls `findfile`, `itoa`, `length`)
- **Menu**: none found (type it)
- **Related**: [`MEDCBDATA`](#medcbdata) [`MED3DVER`](#med3dver)

### MEDCHG

MED Properties palette (entity xdata); UsePickSet. See [medchg.md](medchg.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesPalette.cs` line 16 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Change; MEDRibbon.cuix Ribbon: MED Data Tools > MED Change; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDPROPERTIES`](#medproperties) [`MEDPROPS`](#medprops) [`MED`](#med) [`MC`](#mc)


### MEDCHG-CLASSIC

Old DCL MED xdata editor (medchg.lsp).

- **Source**: `Support\medchg.lsp` line 2
- **Prompts / options**: `Select Entity to change:` (via `medchg`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Change Classic; MEDRibbon.cuix Ribbon: MED Data Tools > MED Change Classic; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDCHG`](#medchg) [`MEDLIST`](#medlist)
- Image: TODO

### MEDCOPY

Copies the MED xdata of one entity onto other selected entities.

- **Source**: `Support\QKEY.lsp` line 91
- **Prompts / options**: `Select Entity to with Xdata to Copy:`; `Select Entities to copy data to:`
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Data Copy; MEDRibbon.cuix Ribbon: MED Data Tools > MED Data Copy; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDFIND`](#medfind) [`MEDSTRIP`](#medstrip)

### MEDDBBACKUP

Writes a CSV snapshot of MEDType (MEDTYPE-DB-Backup.csv) under the MED directory.

- **Source**: `Support\MEDCommands.lsp` line 692
- **Prompts / options**: none of its own (calls `close`, `fix`, `foreach`)
- **Menu**: none found (type it)
- **Related**: [`MEDDBRESTORE`](#meddbrestore)

### MEDDBRESTORE

Restores MEDType rows from the CSV snapshot; asks project name (ALL) and whether to delete first.

- **Source**: `Support\MEDCommands.lsp` line 720
- **Prompts / options**: `Project Name To Restore [ALL for All Projects]:`; `MED Database Restore utility`; `DeleteRecords prior to restore [Yes/No]:` [Yes No] (via `meddatabaserestore`)
- **Menu**: none found (type it)
- **Related**: [`MEDDBBACKUP`](#meddbbackup)

### MEDDEBUG

Sets MED debug Off / On / Verbose (MED log, *MED-DEBUG*). See [debug.md](debug.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedDebug.cs` line 364 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: Off / On / Verbose (see [debug.md](debug.md)).
- **Menu**: none found


### MEDDETAIL

Swaps the MED pull-down menus to the Detail set.

- **Source**: `Support\med.mnl` line 18
- **Prompts / options**: none of its own (calls `medmenuset`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Detail Drawings
- **Related**: [`MEDPLAN`](#medplan) [`MEDWIRING`](#medwiring) [`MEDMENU`](#medmenu)

### MEDDIMSETUP

Makes the "Standard" dimension style current and applies the UEI_DIMSETTINGS variables (loads text styles first if needed).

- **Source**: `Support\MEDDim.lsp` line 51
- **Prompts / options**: `Text Styles are now loaded.` (via `c:loadtxt`)
- **Menu**: none found (type it)
- **Related**: [`IOD`](#iod) [`LOADTXT`](#loadtxt)

### MEDFIND

Selects/highlights MED entities of a type (Conduit/Cable/Tray/Fitting/Equipment) and optional code.

- **Source**: `Support\QKEY.lsp` line 1533
- **Prompts / options**: `Select COnduit/Cable/Tray/Fitting/Equipment <Tray>:` [COnduit CAble Tray Fitting Equipment]
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Item Find; MEDRibbon.cuix Ribbon: MED Data Tools > MED Item Find; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDCOPY`](#medcopy) [`ISOLATE`](#isolate)

### MEDLINE

Plain polyline on the current MED linetype/layer (wiring diagrams).

- **Source**: `Support\medwire.lsp` line 61
- **Prompts / options**: `Pick point:`
- **Menu**: med.cuix Menu: Elementary; med.cuix Menu: Elementary > Control Wiring; med.cuix Menu: Elementary > Field Wiring; med.cuix Menu: Elementary > Power Wiring (+45 more)
- **Related**: [`2LINE`](#2line)

### MEDLIST

Command-line listing of an entity's MED xdata with catalog descriptions.

- **Source**: `Support\MEDCommands.lsp` line 19
- **Prompts / options**: `Select Entity to list:`; `Press Return to Continue`
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED List
- **Related**: [`MEDPROPERTIES`](#medproperties) [`MEDCHG`](#medchg)

### MEDMAKE3D

Tray, tray fittings, conduit, conduit bodies and cable to 3D in one go (Dwg/Layer). See 3d.md.

- **Source**: `Support\MED3DPath.lsp` line 1321
- **Prompts / options**: `MEDMAKE3D output to [Dwg/Layer] <Dwg>:`; `Use the PLAN command to return to plan view.`; `MEDProperties: drawing not saved — skipped .medprops.json (SAVE then MEDREBUILDMEDPROPSJSON).` [Dwg Layer] (via `med3d-make3d-all`, `medrebuildmedpropsjsonbeside`)
- **Menu**: none found (type it)
- **Related**: [`M3D`](#m3d) [`MAKE3DTRAY`](#make3dtray) [`MED3DVER`](#med3dver)
- Image: TODO

### MEDMENU

Reloads the AutoCAD menu then MENULOADs med and shows the Plan pull-downs (legacy .mnu workflow).

- **Source**: `Support\med.mnl` line 8
- **Prompts / options**: none of its own (runs `MENU`, `MENULOAD`)
- **Menu**: none found (type it)
- **Related**: [`MEDPLAN`](#medplan) [`MEDDETAIL`](#meddetail) [`MEDWIRING`](#medwiring)

### MEDPLAN

Swaps the MED pull-down menus to the Plan set (med.mnl menucmd switcher).

- **Source**: `Support\med.mnl` line 15
- **Prompts / options**: none of its own (calls `medmenuset`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Plan Drawings
- **Related**: [`MEDDETAIL`](#meddetail) [`MEDWIRING`](#medwiring) [`MEDMENU`](#medmenu)

### MEDPROPERTIES

Alias of MEDCHG. See [medchg.md](medchg.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesPalette.cs` line 23 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDCHG`](#medchg)


### MEDPROPS

Alias of MEDCHG. See [medchg.md](medchg.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesPalette.cs` line 30 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDCHG`](#medchg)


### MEDREBUILDMEDPROPSJSON

Command: rebuilds {dwg}.medprops.json for the current drawing.

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesLisp.cs` line 129 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MED-RebuildMedPropertiesJson`](#med-rebuildmedpropertiesjson)


### MED3DLIB

Dockable 3D block library palette over `Dwg3D\` and `Dwg3D\Dwg3DCatalog.db` (search, categories, thumbnails, List/Tiles/Grid, Excel bulk edit, insert). Drag from the list, Grid, or preview inserts at the drop point (does not open the DWG; only **Open DWG** opens). See [src/MED-DotNet/README.md](../src/MED-DotNet/README.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\Dwg3DLib\Dwg3DLibCommands.cs` (loaded with `MED-DotNet.dll`).
- **Prompts / options**: palette; Insert / double-click jigs for point then rotation; drag-drop places at the drop point then prompts for rotation.
- **Menu**: med.cuix Menu: MED Main > MED 3D Library; MEDRibbon.cuix Ribbon: MED Data Tools > MED 3D Library; med.cuix Toolbar: MED Data Tools; med.mnu POP1 + toolbar
- **Related**: [`MED3DLIBINSERT`](#med3dlibinsert) [`MED3DLIBTEST`](#med3dlibtest)

### MED3DLIBINSERT

Inserts a library DWG from the command line (full path or file name in the library folder).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\Dwg3DLib\Dwg3DLibCommands.cs`.
- **Menu**: none
- **Related**: [`MED3DLIB`](#med3dlib)

### MED3DLIBTEST

Non-UI self test (works in accoreconsole): prints the DLL, library folder and how it was resolved (saved setting / beside DLL / developer default), reads the DB, rescans a temp copy, Excel export/import dry run, inserts one library DWG. Never writes the real DB.

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\Dwg3DLib\Dwg3DLibCommands.cs`.
- **Menu**: none
- **Related**: [`MED3DLIB`](#med3dlib)

### MEDRECORDS

Handle-based multi-record xdata grid for the selected entity. See [medrecords.md](medrecords.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesPalette.cs` line 37 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Records; MEDRibbon.cuix Ribbon: MED Data Tools > MED Records; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDXDEDIT`](#medxdedit) [`MEDCHG`](#medchg)


### MEDRIBBONMODE

Switch the MED ribbon mode: shows MED Main plus only the MED Plan, MED Detail or MED Wiring tab (and makes it active). MEDPLAN, MEDDETAIL and MEDWIRING call the same code through the LISP function `(MEDRIBBON-SETMODE "Plan"|"Detail"|"Wiring")` after swapping the pulldowns. The mode is re-applied at startup (default Plan) and whenever the ribbon or workspace is rebuilt.

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedRibbonMode.cs` (loaded with `MED-DotNet.dll`).
- **Prompts / options**: `MED ribbon mode [Plan/Detail/Wiring] <current>`.
- **Menu**: None found (MEDPLAN / MEDDETAIL / MEDWIRING buttons on MED Main > Mode switch it too).
- **Related**: [`MEDPLAN`](#medplan) [`MEDDETAIL`](#meddetail) [`MEDWIRING`](#medwiring)


### MEDSET

Alias of MEDSETTINGS. See [medsettings.md](medsettings.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedSettingsPalette.cs` line 19 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Settings; MEDRibbon.cuix Ribbon: MED Data Tools > MED Settings; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDSETTINGS`](#medsettings)


### MEDSETTINGS

MED Settings palette (conduit / tray / scale defaults; lisp globals). See [medsettings.md](medsettings.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedSettingsPalette.cs` line 12 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDSET`](#medset)
- Image: TODO

### MEDSHOW

Alias of MEDSHOWBOM. See [medshowbom.md](medshowbom.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedShowBomForm.cs` line 26 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDSHOWBOM`](#medshowbom)


### MEDSHOWBOM

Browse MEDProject rows for this drawing (filters, summary, CSV). See [medshowbom.md](medshowbom.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedShowBomForm.cs` line 19 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: med.cuix Menu: MED Main > Browse BOM; MEDRibbon.cuix Ribbon: MED Data Tools > Browse BOM; med.cuix Toolbar: MED Data Tools
- **Related**: [`MEDSHOW`](#medshow) [`MEDSHOWSUM`](#medshowsum) [`BOM`](#bom) [`BOMSS`](#bomss)


### MEDSHOWSUM

MEDSHOWBOM opened in summary mode. See [medshowbom.md](medshowbom.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedShowBomForm.cs` line 33 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDSHOWBOM`](#medshowbom)


### MEDSTRIP

Removes all MED xdata from the selected entities.

- **Source**: `Support\MEDCommands.lsp` line 388
- **Prompts / options**: `MEDSTRIP Select Entities to strip XDATA from:`; `Xdata has been removed!`
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > MED Data Strip; MEDRibbon.cuix Ribbon: MED Data Tools > MED Data Strip; med.cuix Toolbar: MED Data Tools (+1 more)
- **Related**: [`MEDCHG`](#medchg) [`MEDRECORDS`](#medrecords)

### MEDTYPE

Catalog grid on MEDType. See [medtype.md](medtype.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedTypeForm.cs` line 41 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDTYPES`](#medtypes)
- Image: TODO

### MEDTYPES

Alias of MEDTYPE. See [medtype.md](medtype.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedTypeForm.cs` line 55 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDTYPE`](#medtype)


### MEDWIRING

Swaps the MED pull-down menus to the Wiring Diagram set.

- **Source**: `Support\med.mnl` line 21
- **Prompts / options**: none of its own (calls `medmenuset`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Wiring Diagrams
- **Related**: [`MEDPLAN`](#medplan) [`MEDDETAIL`](#meddetail) [`MEDMENU`](#medmenu)

### MEDXDEDIT

Alias of MEDRECORDS. See [medrecords.md](medrecords.md).

- **Source**: .NET `[CommandMethod]`, `src\MED-DotNet\MED-DotNet\MedPropertiesPalette.cs` line 44 (loaded with `MED-DotNet.dll`).
- **Prompts / options**: dialog or palette; no command-line prompts.
- **Menu**: none found
- **Related**: [`MEDRECORDS`](#medrecords)


### MEQUIP

Adds a MED_EQUIP record (current _EQCODE) to a picked entity.

- **Source**: `Support\QKEY.lsp` line 176
- **Prompts / options**: `Select Entity to add equipment:`
- **Menu**: none found (type it)
- **Related**: [`MCON`](#mcon) [`DETAIL`](#detail)

### MFIT

Adds a MED_FITTING record (current _FITTCODE and _CSIZE) to a picked entity.

- **Source**: `Support\QKEY.lsp` line 183
- **Prompts / options**: `Select Entity to add a fitting:`
- **Menu**: none found (type it)
- **Related**: [`MCON`](#mcon) [`ADDRE`](#addre)

### MSC

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 210
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: none found (type it)
- **Related**: [`DETAIL`](#detail)

### MT

Matches text properties from a master text entity.

- **Source**: `Support\medtext.lsp` line 965
- **Prompts / options**: `Select Text Objects to be changed:`; `Select Master Text Entity`; `Entity must be a text entity:`; `You must select a text entity:`; `No text selected:`
- **Menu**: none found (type it)
- **Related**: [`XT`](#xt)

### MTRAY

Adds a MED_TRAY record (current tray code/size/depth, tag NONE) to a picked polyline.

- **Source**: `Support\QKEY.lsp` line 144
- **Prompts / options**: `Select Entity to add a tray:`; `Entity selected is not a polyline`
- **Menu**: none found (type it)
- **Related**: [`MCON`](#mcon)

### MW

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 47
- **Prompts / options**: none of its own (runs `MOVE`)
- **Menu**: none found (type it)

### MYTEST

Developer test: picks a polyline arc (MED3DCON.lsp, not loaded).

- **Source**: `Support\MED3DCON.lsp` line 411 - *not loaded by MEDCore*
- **Prompts / options**: `Select Pline Arc`
- **Menu**: none found (type it)

### OFF2CON

Offsets a picked entity by a distance and turns the copy into a conduit run.

- **Source**: `Support\QKEY.lsp` line 1702
- **Prompts / options**: `Select Entity to Offset to Conduit:`; `Offset point:`
- **Menu**: none found (type it)
- **Related**: [`CONDUIT`](#conduit) [`DEFINE`](#define)

### PAR

Wraps each selected TEXT string in parentheses.

- **Source**: `Support\QKEY.lsp` line 1489
- **Prompts / options**: none of its own (calls `assoc`, `cons`, `dxf`)
- **Menu**: none found (type it)
- **Related**: [`APP`](#app)

### PB

Break an entity at one point.

- **Source**: `Support\QKEY.lsp` line 1319
- **Prompts / options**: `Select entity to be broken:`; `Select point to be broken:`
- **Menu**: none found (type it)
- **Related**: [`BF`](#bf)

### PBOX

Closed polyline box from two corners.

- **Source**: `Support\medutil.lsp` line 481
- **Prompts / options**: `First corner:`; `Second corner:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Draw Pline Box; MEDRibbon.cuix Ribbon: MEDUtilities > Draw Pline Box; med.cuix Toolbar: Lisp Tools (+3 more)
- **Related**: [`QC`](#qc)

### PLANMOTOR

Plan motor symbol sized from MOTOR.DAT (horizontal/vertical).

- **Source**: `Support\QKEY.lsp` line 1024
- **Prompts / options**: `Horizontal or Vertical <H>:`; `Start Point:`; `Angle of Genration:`; `Select Direction of Motor Box:`; `Select first point:`; `Select second point:` [Horz Vertical] (via `motor`, `be`)
- **Menu**: none found (type it)
- **Related**: [`DETAIL`](#detail)
- Image: TODO

### PLMAKE

Converts lines to polylines.

- **Source**: `Support\medutil.lsp` line 385
- **Prompts / options**: `Select lines to be changed to polylines:`; `All lines converted.`
- **Menu**: none found (type it)
- **Related**: [`PW`](#pw)

### PLWIDE

Polyline width change (match or type).

- **Source**: `Support\medutil.lsp` line 405
- **Prompts / options**: `Select PLINE with width to match:`; `New width for selected polylines:`
- **Menu**: none found (type it)
- **Related**: [`PLMAKE`](#plmake)

### PTRAYOFF

Plan vertical tray offset at 30/45/60/90 degrees (up/down).

- **Source**: `Support\MEDCableTray.lsp` line 1485
- **Prompts / options**: `Select First Entity:`; `Distance of Offset:`; `Offset with 30 / 45 / 60 / 90 degree angle:` [30 45 60 90]
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Vertical Offset; MEDRibbon.cuix Ribbon: Cable Tray Tools > Vertical Offset; med.cuix Toolbar: Cable Tray (+1 more)
- **Related**: [`TRAYOFF`](#trayoff)

### PW

Polyline width change (match or type).

- **Source**: `Support\medutil.lsp` line 402
- **Prompts / options**: `Select PLINE with width to match:`; `New width for selected polylines:` (via `c:plwide`)
- **Menu**: MEDRibbon.cuix Ribbon: MEDUtilities > Polyline Width; med.cuix Toolbar: Lisp Tools; med.cuix Toolbar: Lisp Tools > Polyline Width
- **Related**: [`PLMAKE`](#plmake)

### PWR

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 195
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Menu: Details; med.cuix Menu: Details > Power; med.cuix Toolbar: Details; med.cuix Toolbar: Details > Power Details
- **Related**: [`DETAIL`](#detail)

### QC

Circles of several radii from one center.

- **Source**: `Support\QKEY.lsp` line 191
- **Prompts / options**: `Center point:`; `Radius of circle:`
- **Menu**: none found (type it)
- **Related**: [`PBOX`](#pbox)

### QE

Erases a fixed-size crossing window from a picked point (legacy sheet helper).

- **Source**: `Support\QKEY.lsp` line 1418
- **Prompts / options**: `Select first point:`
- **Menu**: none found (type it)

### QTA

Quick cable-tag text with prefix A / E / R / T on selected text.

- **Source**: `Support\QKEY.lsp` line 1470
- **Prompts / options**: `Cable Tag:` (via `qt`)
- **Menu**: none found (type it)
- **Related**: [`ITAGA`](#itaga)

### QTE

Quick cable-tag text with prefix A / E / R / T on selected text.

- **Source**: `Support\QKEY.lsp` line 1467
- **Prompts / options**: `Cable Tag:` (via `qt`)
- **Menu**: none found (type it)
- **Related**: [`ITAGA`](#itaga)

### QTR

Quick cable-tag text with prefix A / E / R / T on selected text.

- **Source**: `Support\QKEY.lsp` line 1473
- **Prompts / options**: `Cable Tag:` (via `qt`)
- **Menu**: none found (type it)
- **Related**: [`ITAGA`](#itaga)

### QTT

Quick cable-tag text with prefix A / E / R / T on selected text.

- **Source**: `Support\QKEY.lsp` line 1486
- **Prompts / options**: `Cable Tag:` (via `qt`)
- **Menu**: none found (type it)
- **Related**: [`ITAGA`](#itaga)

### QVTEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 295
- **Prompts / options**: none of its own (calls `*`, `maketray`, `med_tan`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### RC

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 53
- **Prompts / options**: none of its own (runs `ROTATE`)
- **Menu**: none found (type it)

### REFDWG

Reference drawing list next to the title block (from the drawing list).

- **Source**: `Support\QKEY.lsp` line 914
- **Prompts / options**: `Select Title Block:`; `Add Refrences or New Refrences<N>:`; `Select Existing Reference drawings:`; `Drawing Number:` [Add New]
- **Menu**: none found (type it)
- **Related**: [`SORT`](#sort)

### RT

Replaces several text entities with one value (pick or type).

- **Source**: `Support\medtext.lsp` line 255
- **Prompts / options**: `Select text to be replaced:`; `Select New Value - [Press Enter to Type New Value]:`; `Object selected does not have any data to copy!`; `New Value:`
- **Menu**: med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Replace Text; MEDRibbon.cuix Ribbon: Text Styles > Replace Text; med.cuix Toolbar: Text Styles (+1 more)
- **Related**: [`CT`](#ct)

### RUN3DCABLE

Cable on a 3DPOLY using the current _CABCODE and cable-type layer.

- **Source**: `Support\medcable.lsp` line 44
- **Prompts / options**: `Pick point:`; `Cable Tag number <NONE>:`; `Cable Relate Tag <NONE>:`
- **Menu**: none found (type it)
- **Related**: [`CABLE`](#cable) [`C3D`](#c3d)

### RW

Erase / copy / move / rotate with window or crossing preselected.

- **Source**: `Support\QKEY.lsp` line 51
- **Prompts / options**: none of its own (runs `ROTATE`)
- **Menu**: none found (type it)

### SECT

**Definition in `Support\MEDCommands.lsp`:**

Section marks in plan (defined in MEDCommands.lsp; overridden by medtag.lsp, which loads later).

- **Source**: `Support\MEDCommands.lsp` line 303. also defined in Support\medtag.lsp:2; replaced at load time by Support\medtag.lsp:2
- **Prompts / options**: `Pick first section point`; `Pick second section point`; `Enter section letter <A>:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Section Marks; MEDRibbon.cuix Ribbon: Tagging > Section Marks; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`SECTD`](#sectd) [`CUT`](#cut)
- Image: TODO

**Definition in `Support\medtag.lsp`:**

Section marks in plan (two points + letter). This definition wins (loads after MEDCommands.lsp).

- **Source**: `Support\medtag.lsp` line 2. also defined in Support\MEDCommands.lsp:303; this definition loads last and wins
- **Prompts / options**: `Pick first section point`; `Pick second section point`; `Enter section letter <A>:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Section Marks; MEDRibbon.cuix Ribbon: Tagging > Section Marks; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`SECTD`](#sectd) [`CUT`](#cut)
- Image: TODO

### SECTD

Inserts the dynamic section-mark block sect-dyn on the MED text layer.

- **Source**: `Support\MEDCommands.lsp` line 321
- **Prompts / options**: `Block Rotation <0>:`; `Block Size is Invalid:`; `No Attributes`; `Select point on line for rotation:`; `PT4`; `PT3` (via `c:medblockinsert`, `attmod`, `brk_rot`)
- **Menu**: none found (type it)
- **Related**: [`SECT`](#sect)

### SETLIM

Sets drawing limits from the title block size and current MED scale.

- **Source**: `Support\medsetup.lsp` line 338
- **Prompts / options**: none of its own (calls `setlim`)
- **Menu**: none found (type it)
- **Related**: [`SETUP`](#setup)

### SETLINK

Builds a linked (field) string / sum from several sources into a target.

- **Source**: `Support\medutil.lsp` line 894
- **Prompts / options**: `Select Item to recieve Link data:`; `Select Text/Attribute Entities Link to:`; `Select Text/Attribute:`
- **Menu**: none found (type it)
- **Related**: [`LINKVALUE`](#linkvalue)

### SETLINKSUM

Builds a linked (field) string / sum from several sources into a target.

- **Source**: `Support\medutil.lsp` line 931
- **Prompts / options**: `Select Item to recieve Link data:`; `Select Text/Attribute Entities Link to:`; `Select Text/Attribute:`
- **Menu**: none found (type it)
- **Related**: [`LINKVALUE`](#linkvalue)

### SETPLOT

Sets or turns off the plot correction factor used by MED text/symbol scaling.

- **Source**: `Support\medsetup.lsp` line 254
- **Prompts / options**: `Plot correction has been turned off.`
- **Menu**: none found (type it)
- **Related**: [`SETUP`](#setup)

### SETUP

Drawing setup: DCL for scale set, title block (model or paper space), text styles; sets _SC, DIMSCALE, USERR1.

- **Source**: `Support\medsetup.lsp` line 75
- **Prompts / options**: `Insertion point for Title block:`; `Rotation Angle <0>:`; `No Attributes` (via `medtitle`, `attmod`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Title Block Setup; med.cuix Toolbar: Main Tool Bar; med.cuix Toolbar: Main Tool Bar > Drawing Setup
- **Related**: [`SETLIM`](#setlim) [`SETPLOT`](#setplot) [`LOADTXT`](#loadtxt) [`MEDSETTINGS`](#medsettings)
- Image: TODO

### SHOWFIELDCODE

Shows the field code of a picked entity.

- **Source**: `Support\medutil.lsp` line 967
- **Prompts / options**: `Select Entity to show field code`
- **Menu**: none found (type it)
- **Related**: [`LINKVALUE`](#linkvalue)

### SL

Sets the current layer from a picked entity.

- **Source**: `Support\medutil.lsp` line 525
- **Prompts / options**: `Select entity to set new layer:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Set Curr. Layr; MEDRibbon.cuix Ribbon: Layer Tools > Set Curr. Layr; med.cuix Toolbar: Layer Tools (+1 more)
- **Related**: [`CL`](#cl)

### SORT

Sorts and rewrites the existing reference drawing list text.

- **Source**: `Support\QKEY.lsp` line 1345
- **Prompts / options**: `Start point:`; `Select Existing Reference drawings:`
- **Menu**: none found (type it)
- **Related**: [`REFDWG`](#refdwg)

### ST

STRETCH with crossing already chosen.

- **Source**: `Support\QKEY.lsp` line 55
- **Prompts / options**: none of its own (runs `STRETCH`)
- **Menu**: none found (type it)

### STRUT

Framing channel (strut) run between two points.

- **Source**: `Support\MEDCableTray.lsp` line 1447
- **Prompts / options**: `Pick start point of framing channel:`; `to point:`
- **Menu**: med.cuix Image menu: Plan Cable Tray Hardware; med.cuix Image menu: Plan Cable Tray Hardware > Strut Support
- **Related**: [`STRUT1`](#strut1)

### STRUT1

Strut on the centerline layer with MED xdata (QKEY variant).

- **Source**: `Support\QKEY.lsp` line 1118
- **Prompts / options**: `Pick start point of double framing channel:`; `to point:`
- **Menu**: none found (type it)
- **Related**: [`STRUT`](#strut)

### T1

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 178
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.125 Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.125 Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### T1THIN

Sets the T1Thin MED text style.

- **Source**: `Support\QKEY.lsp` line 1784
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: none found (type it)
- **Related**: [`T1`](#t1)

### T2

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 181
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.15625 Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.15625 Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### T3

Sets the MED text style (T = normal, B = bold; 1/2/3 = 0.125/0.15625/0.1875 plotted).

- **Source**: `Support\MEDCommands.lsp` line 184
- **Prompts / options**: `*********Layer Info Not Found Using Current Layer` (via `med_text`)
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > 0.1875 Text; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > 0.1875 Text
- **Related**: [`LOADTXT`](#loadtxt) [`T1THIN`](#t1thin)

### TAKEOFF

Turns HANDLES on and runs BOM (legacy take-off wrapper).

- **Source**: `Support\QKEY.lsp` line 1145
- **Prompts / options**: none of its own (runs `ATTEXT`, `HANDLES`)
- **Menu**: none found (type it)
- **Related**: [`BOM`](#bom)

### TELEV

Labels tray elevations with a leader tag.

- **Source**: `Support\QKEY.lsp` line 1833
- **Prompts / options**: `Select Tray CenterLine`; `Select Point for Text Placement:`
- **Menu**: none found (type it)
- **Related**: [`TTAG`](#ttag) [`TTAGS`](#ttags)

### TEST

Developer test in medtray.lsp. Not a user command.

- **Source**: `Support\medtray.lsp` line 1279
- **Prompts / options**: none of its own (calls `*`, `angle`, `atan`)
- **Menu**: none found (type it)

### TJ

Sets text justification and aligns text to a picked point.

- **Source**: `Support\medtext.lsp` line 528
- **Prompts / options**: `Select text entities to be converted:`; `Justification of Text: L/ML/TL/C/M/TC/R/MR/TR:`; `Pick point for text to align by justification:`; `That's it!!` [Left MLeft TLeft Center Middle TCenter Right MRight TRight]
- **Menu**: none found (type it)
- **Related**: [`CT`](#ct)

### TM

Trim multiple to a boundary set.

- **Source**: `Support\medutil.lsp` line 535
- **Prompts / options**: `Select edges:`; `Select objects to be trimed:`; `Select point to base trim:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Trim Multiple; med.cuix Image menu: Misc. Tools; med.cuix Image menu: Misc. Tools > Trim Multiple
- **Related**: [`EM`](#em)

### TRAY

Two-point cable tray (outline + centerline + MED_TRAY xdata).

- **Source**: `Support\MEDCableTray.lsp` line 10
- **Prompts / options**: `To Point:`
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Heavy Duty Cable Tray; med.cuix Menu: Cable Tray > Light Duty Cable Tray; med.cuix Menu: Cable Tray > Medium Duty Cable Tray (+10 more)
- **Related**: [`TRAYSIZE`](#traysize) [`TRAYFIX`](#trayfix) [`TRAYOFF`](#trayoff) [`TTAG`](#ttag)
- Image: TODO

### TRAY30

Horizontal tray elbow of that angle at a tray end.

- **Source**: `Support\medtray.lsp` line 18
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > 30 Elbow; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Elbows > 30 Elbow; med.cuix Toolbar: Tray Elbows (+3 more)
- **Related**: [`TRAYTEE`](#traytee) [`TRAYCROSS`](#traycross) [`TRAYV90`](#trayv90)

### TRAY45

Horizontal tray elbow of that angle at a tray end.

- **Source**: `Support\medtray.lsp` line 14
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > 45 Elbow; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Elbows > 45 Elbow; med.cuix Toolbar: Tray Elbows (+3 more)
- **Related**: [`TRAYTEE`](#traytee) [`TRAYCROSS`](#traycross) [`TRAYV90`](#trayv90)

### TRAY60

Horizontal tray elbow of that angle at a tray end.

- **Source**: `Support\medtray.lsp` line 10
- **Prompts / options**: `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > 60 Elbow; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Elbows > 60 Elbow; med.cuix Toolbar: Tray Elbows (+3 more)
- **Related**: [`TRAYTEE`](#traytee) [`TRAYCROSS`](#traycross) [`TRAYV90`](#trayv90)

### TRAY90

Horizontal tray elbow of that angle at a tray end.

- **Source**: `Support\MEDCableTray.lsp` line 275
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `medmtray90`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > 90 Elbow; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Elbows > 90 Elbow; med.cuix Toolbar: Tray Elbows (+3 more)
- **Related**: [`TRAYTEE`](#traytee) [`TRAYCROSS`](#traycross) [`TRAYV90`](#trayv90)

### TRAYBLIND

Adds a drop-out / blind-end fitting record to a picked tray.

- **Source**: `Support\QKEY.lsp` line 1066
- **Prompts / options**: `Xdata has been added!`; `Xdata Add has Failed!!!` (via `trayfit`)
- **Menu**: none found (type it)
- **Related**: [`TRAYEP`](#trayep)

### TRAYCON

Tray-to-conduit connector (side or end entry) by conduit size.

- **Source**: `Support\QKEY.lsp` line 253
- **Prompts / options**: `Side entry or End entry <S>/E:`; `Select conduit:`
- **Menu**: none found (type it)
- **Related**: [`TRAYEP`](#trayep)

### TRAYCROSS

Horizontal tray cross.

- **Source**: `Support\MEDCableTray.lsp` line 652
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `be`, `get_con_tag`, `tray_brk_rot`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > Cross; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Fittings > Cross; med.cuix Toolbar: Tray Fittings (+3 more)
- **Related**: [`TRAYTEE`](#traytee)

### TRAYDN

Tray turning up / down in plan (vertical fitting symbol + elevation).

- **Source**: `Support\MEDCableTray.lsp` line 1899
- **Prompts / options**: `Select Tray item` (via `trayupdown`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > TrayDown; MEDRibbon.cuix Ribbon: Cable Tray Tools > TrayDown; med.cuix Toolbar: Cable Tray (+3 more)
- **Related**: [`TRAYV90`](#trayv90) [`CHANUP`](#chanup) [`CHANDN`](#chandn)

### TRAYDROP

Adds a drop-out / blind-end fitting record to a picked tray.

- **Source**: `Support\QKEY.lsp` line 1062
- **Prompts / options**: `Xdata has been added!`; `Xdata Add has Failed!!!` (via `trayfit`)
- **Menu**: none found (type it)
- **Related**: [`TRAYEP`](#trayep)

### TRAYEG

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge.

- **Source**: `Support\QKEY.lsp` line 290
- **Prompts / options**: `Select Point for insertion:`; `Rotation:`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `trayepg_hd`, `c:medblockinsert`)
- **Menu**: med.cuix Image menu: Plan Cable Tray Hardware; med.cuix Image menu: Plan Cable Tray Hardware > Tray Exp Guide
- **Related**: [`TRAYDROP`](#traydrop) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon)

### TRAYEP

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge.

- **Source**: `Support\QKEY.lsp` line 286
- **Prompts / options**: `Select Point for insertion:`; `Rotation:`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `trayepg_hd`, `c:medblockinsert`)
- **Menu**: med.cuix Image menu: Plan Cable Tray Hardware; med.cuix Image menu: Plan Cable Tray Hardware > Tray Exp Plate
- **Related**: [`TRAYDROP`](#traydrop) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon)

### TRAYFITTEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 310
- **Prompts / options**: none of its own (calls `entsel`, `medconverttrayelbowto3d`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### TRAYFIX

Rebuilds a tray outline from its centerline.

- **Source**: `Support\MEDCableTray.lsp` line 1033
- **Prompts / options**: `Select Tray to fix:`
- **Menu**: med.cuix Menu: Misc. Tools; med.cuix Menu: Misc. Tools > Tray Fix; MEDRibbon.cuix Ribbon: Cable Tray > Tray Fix; med.cuix Toolbar: Cable Tray (+1 more)
- **Related**: [`TRAY`](#tray)

### TRAYHANG

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge.

- **Source**: `Support\QKEY.lsp` line 1055
- **Prompts / options**: `Select Point for insertion:`; `Rotation:`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `trayepg_hd`, `c:medblockinsert`)
- **Menu**: med.cuix Image menu: Plan Cable Tray Hardware; med.cuix Image menu: Plan Cable Tray Hardware > Tray Trapeze
- **Related**: [`TRAYDROP`](#traydrop) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon)

### TRAYHD

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge.

- **Source**: `Support\QKEY.lsp` line 295
- **Prompts / options**: `Select Point for insertion:`; `Rotation:`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `trayepg_hd`, `c:medblockinsert`)
- **Menu**: med.cuix Image menu: Plan Cable Tray Hardware; med.cuix Image menu: Plan Cable Tray Hardware > Tray Hold Down
- **Related**: [`TRAYDROP`](#traydrop) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon)

### TRAYHINGE

Tray hardware detail insert: expansion plate / expansion guide / hold-down / trapeze hanger / hinge.

- **Source**: `Support\QKEY.lsp` line 1314
- **Prompts / options**: `Select Point for insertion:`; `Rotation:`; `Block Rotation <0>:`; `Block Size is Invalid:` (via `trayepg_hd`, `c:medblockinsert`)
- **Menu**: none found (type it)
- **Related**: [`TRAYDROP`](#traydrop) [`TRAYBLIND`](#trayblind) [`TRAYCON`](#traycon)

### TRAYLRRETEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 846
- **Prompts / options**: none of its own (calls `entsel`, `medconverttraylrreducerto3d`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### TRAYOFF

Plan horizontal tray offset at 30/45/60/90 degrees.

- **Source**: `Support\MEDCableTray.lsp` line 1064
- **Prompts / options**: `Select First Entity:`; `Distance of Offset:`; `Offset with 30 / 45 / 60 / 90 degree angle:` [30 45 60 90]
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Horizontal Offset; MEDRibbon.cuix Ribbon: Cable Tray Tools > Horizontal Offset; med.cuix Toolbar: Cable Tray (+3 more)
- **Related**: [`PTRAYOFF`](#ptrayoff) [`VTRAYOFF`](#vtrayoff)
- Image: TODO

### TRAYRE

Straight tray reducer (asks reduce-to size).

- **Source**: `Support\MEDCableTray.lsp` line 789
- **Prompts / options**: `Select insertion point:`; `Angle to reduce to:`; `Angle of generation:`; `Size may not be larger than current size.`; `Size to Reduce to:`
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > Str RE; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Fittings > Str RE; med.cuix Toolbar: Tray Fittings (+3 more)
- **Related**: [`TRAYREL`](#trayrel) [`TRAYRER`](#trayrer) [`TRAYTEERE`](#trayteere)

### TRAYREL

Left-hand tray reducer.

- **Source**: `Support\medtray.lsp` line 2
- **Prompts / options**: `Select insertion point:`; `Angle of generation:`; `Size may not be larger than current size.`; `Size to Reduce to:`; `Select first point:`; `Select second point:` (via `traylrre`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > Lft RE; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Fittings > Lft RE; med.cuix Toolbar: Tray Fittings (+3 more)
- **Related**: [`TRAYRE`](#trayre) [`TRAYRER`](#trayrer)

### TRAYRER

Right-hand tray reducer.

- **Source**: `Support\medtray.lsp` line 6
- **Prompts / options**: `Select insertion point:`; `Angle of generation:`; `Size may not be larger than current size.`; `Size to Reduce to:`; `Select first point:`; `Select second point:` (via `traylrre`, `be`, `get_con_tag`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > Rgt RE; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Fittings > Rgt RE; med.cuix Toolbar: Tray Fittings (+3 more)
- **Related**: [`TRAYRE`](#trayre) [`TRAYREL`](#trayrel)

### TRAYRETEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 820
- **Prompts / options**: none of its own (calls `entsel`, `medconverttrayreducerto3d`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### TRAYSIZE

DCL for tray size, depth, type and radius.

- **Source**: `Support\medtray.lsp` line 22
- **Prompts / options**: `To Point:` (via `c:tray`)
- **Menu**: none found (type it)
- **Related**: [`TRAY`](#tray) [`MEDSETTINGS`](#medsettings)
- Image: TODO

### TRAYTEE

Horizontal tray tee.

- **Source**: `Support\MEDCableTray.lsp` line 532
- **Prompts / options**: `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:`; `PT4` (via `be`, `get_con_tag`, `tray_brk_rot`)
- **Menu**: med.cuix Menu: Plan Fittings; med.cuix Menu: Plan Fittings > Tee; MEDRibbon.cuix Ribbon: Cable Tray Fittings > Fittings > Tee; med.cuix Toolbar: Tray Fittings (+3 more)
- **Related**: [`TRAYCROSS`](#traycross) [`TRAYTEERE`](#trayteere)
- Image: TODO

### TRAYTEERE

Reducing tray tee.

- **Source**: `Support\MEDCableTray.lsp` line 1594
- **Prompts / options**: `Angle of generation:`; `Size may not be larger than current size.`; `Size to Reduce to:`
- **Menu**: none found (type it)
- **Related**: [`TRAYTEE`](#traytee) [`TRAYRE`](#trayre)

### TRAYTEETEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 647
- **Prompts / options**: none of its own (calls `entsel`, `medconverttrayteeto3d`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### TRAYTEST

Developer test for the 3D tray builders (MED3DTrayFunctions.lsp). Not a user command.

- **Source**: `Support\MED3DTrayFunctions.lsp` line 21
- **Prompts / options**: none of its own (calls `entsel`, `medconverttrayto3d`)
- **Menu**: none found (type it)
- **Related**: [`MAKE3DTRAY`](#make3dtray)

### TRAYUP

Tray turning up / down in plan (vertical fitting symbol + elevation).

- **Source**: `Support\MEDCableTray.lsp` line 1905
- **Prompts / options**: `Select Tray item` (via `trayupdown`)
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > TrayUp; MEDRibbon.cuix Ribbon: Cable Tray Tools > TrayUp; med.cuix Toolbar: Cable Tray (+3 more)
- **Related**: [`TRAYV90`](#trayv90) [`CHANUP`](#chanup) [`CHANDN`](#chandn)

### TRAYV90

Plan vertical 90 degree tray elbow (inside/outside).

- **Source**: `Support\MEDCableTray.lsp` line 1225
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:` [Inside Outside]
- **Menu**: med.cuix Menu: Cable Tray; med.cuix Menu: Cable Tray > Plan Vert 90; med.cuix Toolbar: Tray Elbows; med.cuix Toolbar: Tray Elbows > 90 Degree Vertical Elbow
- **Related**: [`TRAYUP`](#trayup) [`TRAYDN`](#traydn) [`VTRAY90`](#vtray90)
- Image: TODO

### TRY

Detail insert from that MEDType group (lighting, ground, power, instrument, tray, comm, j-box, misc).

- **Source**: `Support\meddetl.lsp` line 201
- **Prompts / options**: `Select Entity to Add Detail to:` (via `opt_eq_ins`)
- **Menu**: med.cuix Menu: Details; med.cuix Menu: Details > Tray; med.cuix Toolbar: Details; med.cuix Toolbar: Details > Tray Details
- **Related**: [`DETAIL`](#detail)

### TSTRIP

Terminal strip generator; can chain into CTEDIT for numbering.

- **Source**: `Support\medwire.lsp` line 2
- **Prompts / options**: `Left point of terminals:`; `Angle to generate`; `Number of terminals to generate:`; `Would You like to execute CTEDIT om the terminal Text <Y>/N:` [Yes No]
- **Menu**: med.cuix Menu: Terminals; med.cuix Menu: Terminals > Genrate Terminal Strip
- **Related**: [`CTEDIT`](#ctedit)
- Image: TODO

### TTAG

Tray tag on the centerline with leader.

- **Source**: `Support\QKEY.lsp` line 1565
- **Prompts / options**: `Select Tray to tag:`; `Invalid selection of Tray`
- **Menu**: MEDRibbon.cuix Ribbon: Tagging > Tray Tag; med.cuix Toolbar: Tagging; med.cuix Toolbar: Tagging > Tray Tag
- **Related**: [`TTAGS`](#ttags) [`TELEV`](#telev)
- Image: TODO

### TTAGS

Tray tag variant (T1 style).

- **Source**: `Support\QKEY.lsp` line 1789
- **Prompts / options**: `Select first point:`; `Select second point:` (via `be`)
- **Menu**: none found (type it)
- **Related**: [`TTAG`](#ttag)

### UIL

Turns back on layers switched off by IL (_LAYLIST).

- **Source**: `Support\medutil.lsp` line 675
- **Prompts / options**: none of its own (runs `LAYER`)
- **Menu**: none found (type it)
- **Related**: [`IL`](#il)

### UNISOLATE

Restores entities hidden by ISOLATE.

- **Source**: `Support\MEDCommands.lsp` line 373
- **Prompts / options**: none of its own (runs `LAYER`, `REGEN`)
- **Menu**: med.cuix Menu: MED Main; med.cuix Menu: MED Main > Unisolate Equip
- **Related**: [`ISOLATE`](#isolate)

### UNJ

Inserts a UNJ / UNJC fitting at a point, aligned to a reference entity.

- **Source**: `Support\MEDCommands.lsp` line 523
- **Prompts / options**: `Type of fitting UNJ or UNJC:`; `Insertion point:`; `Select reference entity:`; `Invalid size set conduit size to 1/2 or 3/4` [UNJ UNJC]
- **Menu**: med.cuix Menu: Lighting; med.cuix Menu: Lighting > UNJ/UNJY
- **Related**: [`MEDBLOCKINSERT`](#medblockinsert)

### UPCASE

Converts selected text to upper case.

- **Source**: `Support\medtext.lsp` line 231
- **Prompts / options**: `Select text to be converted to UPPERCASE:`; `Thats it!!`
- **Menu**: none found (type it)
- **Related**: [`CT`](#ct)

### UT

Underlines selected text.

- **Source**: `Support\medtext.lsp` line 635
- **Prompts / options**: `Select text entities to be underlined.`
- **Menu**: none found (type it)
- **Related**: [`CT`](#ct)

### VA

Restore view ALL / named view.

- **Source**: `Support\QKEY.lsp` line 35
- **Prompts / options**: none of its own (calls )
- **Menu**: none found (type it)

### VR

Restore view ALL / named view.

- **Source**: `Support\QKEY.lsp` line 37
- **Prompts / options**: none of its own (calls )
- **Menu**: none found (type it)

### VTRAY

Side-view (vertical) tray run.

- **Source**: `Support\medtray.lsp` line 98
- **Prompts / options**: `To Point:` (via `c:tray`)
- **Menu**: med.cuix Image menu: Tray Side View and Fittings; med.cuix Image menu: Tray Side View and Fittings > Vertical Cable Tray
- **Related**: [`VTRAYOFF`](#vtrayoff) [`VTRAY90`](#vtray90)

### VTRAY30

Side-view tray elbow of that angle (inside/outside).

- **Source**: `Support\medtray.lsp` line 201
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [Inside Outside] [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Image menu: Tray Side View and Fittings; med.cuix Image menu: Tray Side View and Fittings > Vertical 30 deg
- **Related**: [`VTRAY`](#vtray)

### VTRAY45

Side-view tray elbow of that angle (inside/outside).

- **Source**: `Support\medtray.lsp` line 185
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [Inside Outside] [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Image menu: Tray Side View and Fittings; med.cuix Image menu: Tray Side View and Fittings > Vertical 45 deg
- **Related**: [`VTRAY`](#vtray)

### VTRAY60

Side-view tray elbow of that angle (inside/outside).

- **Source**: `Support\medtray.lsp` line 169
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:`; `Positive or Negative degrees <+>/-:`; `Select first point:`; `Select second point:`; `Tag <NONE>:` [Inside Outside] [+ -] (via `trayang`, `be`, `get_con_tag`)
- **Menu**: med.cuix Image menu: Tray Side View and Fittings; med.cuix Image menu: Tray Side View and Fittings > Vertical 60 deg
- **Related**: [`VTRAY`](#vtray)

### VTRAY90

Side-view tray elbow of that angle (inside/outside).

- **Source**: `Support\MEDCableTray.lsp` line 283
- **Prompts / options**: `Inside or <Outside>:`; `Angle of generation:`; `Select first point:`; `Select second point:`; `Tag <NONE>:`; `Select point on line for rotation:` [Inside Outside] (via `medmtray90`, `be`, `get_con_tag`)
- **Menu**: med.cuix Image menu: Tray Side View and Fittings; med.cuix Image menu: Tray Side View and Fittings > Plan Vertical Fit; med.cuix Image menu: Tray Side View and Fittings > Vertical 90 deg
- **Related**: [`VTRAY`](#vtray)

### VTRAYOFF

Side-view tray offset.

- **Source**: `Support\medtray.lsp` line 712
- **Prompts / options**: `Select First Entity:`; `Distance of Offset:`; `Offset with 30 / 45 / 60 / 90 degree angle:`; `To Point:`; `Tag <NONE>:`; `Angle of generation:` [30 45 60 90] [+ -] [Up Down] (via `c:trayoff`, `c:tray`, `get_con_tag`)
- **Menu**: none found (type it)
- **Related**: [`VTRAY`](#vtray) [`TRAYOFF`](#trayoff)

### WBL

Defines a block from a selection (BLOCK with redefine).

- **Source**: `Support\QKEY.lsp` line 503
- **Prompts / options**: `Block name:`; `Insertion Point:`
- **Menu**: none found (type it)
- **Related**: [`BN`](#bn)

### WIRES

Wire markers (hot/neutral/ground dashes) on conduit.

- **Source**: `Support\QKEY.lsp` line 824
- **Prompts / options**: `Select point for tags:`; `Select Rotation for tags:`; `H=Hot N=Neutral Space=Spacer G=Ground S=Switchleg`
- **Menu**: med.cuix Menu: Tagging; med.cuix Menu: Tagging > Wire Markers; MEDRibbon.cuix Ribbon: Tagging > Wire Markers; med.cuix Toolbar: Tagging (+3 more)
- **Related**: [`CTAG`](#ctag)
- Image: TODO

### XT

Converts selected text to another style (spacing adjust if heights differ).

- **Source**: `Support\medtext.lsp` line 159
- **Prompts / options**: `Select text entities to be converted:`; `Style name to convert to:`; `Style name not defined. Please define it`; `Text style height is 0.0`; `Adjust group for spacing Y/N:<N>`; `Base point` [Yes No]
- **Menu**: MEDRibbon.cuix Ribbon: Text Styles > Change Text Styles; med.cuix Toolbar: Text Styles; med.cuix Toolbar: Text Styles > Change Text Styles
- **Related**: [`LOADTXT`](#loadtxt)

### ZD

Zoom window / dynamic / previous / vmax / extents.

- **Source**: `Support\QKEY.lsp` line 27
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)

### ZE

Zoom window / dynamic / previous / vmax / extents.

- **Source**: `Support\QKEY.lsp` line 33
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)

### ZP

Zoom window / dynamic / previous / vmax / extents.

- **Source**: `Support\QKEY.lsp` line 29
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)

### ZV

Zoom window / dynamic / previous / vmax / extents.

- **Source**: `Support\QKEY.lsp` line 31
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)

### ZW

Zoom window / dynamic / previous / vmax / extents.

- **Source**: `Support\QKEY.lsp` line 25
- **Prompts / options**: none of its own (runs `ZOOM`)
- **Menu**: none found (type it)


## Menu macros that start no MED command

These macros are in `med.cuix` / `MEDRibbon.cuix` (and `med.mnu`) but no LISP or .NET command of that name exists in the repo. Reported, not changed.

| Macro command | Where | Note |
| --- | --- | --- |
| `ADDATRIB` | med.cuix Menu: Text & Attributes; med.cuix Menu: Text & Attributes > Add Attribute | Only the helper `(addatrib ...)` exists; the command is `ATADD`. |
| `INST` | med.cuix Menu: Details; med.cuix Menu: Details > Instrumentation | Details > Instrumentation. `INS` exists; `INST` does not. TODO: confirm with Clint. |
| `MOTOR` | med.cuix Toolbar: Lisp Tools; med.cuix Toolbar: Lisp Tools > Parametric Motor | Only the helper `(motor size vert)` exists; the command is `PLANMOTOR`. |
| `T0` | MEDRibbon.cuix Ribbon: Text Styles > 0.09375 Text; med.cuix Toolbar: Text Styles | Macro runs `(c:loadtxt)` then `T0`; no C:T0 is defined (T1-T3 / B1-B3 are, in MEDCommands.lsp). TODO: confirm with Clint. |
| `VCHAN90` | med.cuix Image menu: Plan Cable Channel and Fittings; med.cuix Image menu: Plan Cable Channel and Fittings > Plan Vertical Fit | Image menu "Plan Vertical Fit"; the command is `CHANV90`. |

`FILLET` and `BROWSER` in macros are AutoCAD commands.

