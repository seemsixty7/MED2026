# UserGuide.docx: changes from the 2012 user guide

Draft of `docs/UserGuide.docx` (MED2026 User's Guide and Tutorial), written 1 Oct 2026 for Clint's review. Not committed.

## Source

- The original is `Dropbox\MEDDocs\MED 2012 Full Docs.doc` (21 Mar 2013). The copy under `MEDArchive\MED\2006-08-07-MED2005Release\...\disk1\Docs\MED Full Docs.doc` is corrupt (scrambled, no Word header), and there is no `MED Full Docs.doc` in the MEDArchive root. The older Upstream/Backups copies (2000) have the same text.
- `Dropbox\MEDDocs\UserGuide.docx` (2013) is an empty Word manual template with only an Introduction. Its intro text was reused. That file was not changed.
- Commands, prompts and menus were checked against `Support\*.lsp`, `src\MED-DotNet` (C# commands, MED3DLIB), `Support\ACAD.PGP`, `med.cuix` (through `docs\command-reference.md` / `doc-audit.csv`) and the existing md docs (medsettings, medchg, medrecords, medtype, medshowbom, database, 3d.md, 3d-guide.md).

## Shape of the new guide

- 91 pages (LibreOffice rendering; Word may differ by a page or two), 8 chapters, 138 headings (H1 8, H2 37, H3 57, H4 35, H5 1).
- Title page, table of contents (a real Word TOC field, levels 1-2, page numbers filled in; right-click > Update Field after editing), page-number footer.
- Word heading styles Heading 1-5; numbered task steps ("To draw a conduit run: 1. ..."); prompts in Courier on a grey background; tips/notes with a left bar.
- 207 pictures reused from the 2012 guide (drawings, toolbar buttons, DDMEDLIST and DETAGUPD dialogs, which are still DCL) plus 3 MED2026 screenshots from `docs\images` (medproperties, medshowbom, medrecords).
- 13 screenshot placeholders, shown as bold `[Screenshot: ...]` lines.
- 24 `[VERIFY: ...]` items, shown in bold red on a yellow highlight.

Chapters: 1 General Information, 2 Plan Drawings (Conduit, Cable Tray, Cables, Equipment, Material Data), 3 Details, 4 Wiring Diagrams, 5 3D Modeling (new), 6 3D Block Library (new), 7 Utilities, Appendix A Command Reference (new).

## Added

- **What's new in MED2026** (General Information).
- **Installing and Starting MED**: replaces "Start MED in Training Mode".
- **MED Settings palette** (MEDSETTINGS): replaces the MEDSET dialog pictures; covers every field, including the new Size/Depth/Radius/Tangent/Flange values.
- **MED Properties palette** (MEDCHG) with *VARIES* and Edit records...; MEDCHG-CLASSIC noted.
- **Cable palette** (MEDCABLE / CABLEPALETTE / CABLESET), RUN3DCABLE tip.
- **TTAG TraySystem prompt**, DEFINE tip, CN/CF centerline layer commands, the full list of tray hardware commands.
- **Material Data**: Where MED keeps its data (SQLite `Data\MED.db` / SQL Server), MEDTYPE grid steps (Ctrl+S, CSV export/import), Browsing the BOM with **MEDSHOWBOM**, **MEDRECORDS**, MEDDBBACKUP / MEDDBRESTORE, Other MED data tools (MEDFIND, MEDCOPY, MEDSTRIP, CHGTAG, ISOLATE).
- **Chapter 5, 3D Modeling**: commands table, preparing the plan, MEDMAKE3D step by step (Dwg / Layer), reading the summary, running again (ESOLID warning), conduit bodies (names, Key2 body keys, forms, not-modelled list), flags and mirrored fittings (MED_3DFLAG, "MIRRORED FITTING - re-insert, do not mirror"), MAKE3DTRAY / MAKE3DCONDUIT / MAKE3DCABLE / M3D / C3D, MEDCBINS step by step, MEDCBTEST / MEDCBALL / MEDCBGRID / MEDCBDATA / MEDCBVER / MED3DVER, data changes and `_PRE_` blocks / PURGE, Navisworks (.medprops.json, MEDPropertiesPlugin).
- **Chapter 6, 3D Block Library** (MED3DLIB): opening and docking, the palette at a glance, finding (search, category filter including (Uncategorized) / (Missing files) / (No preview)), List / Tiles / Grid views, inserting (double-click / Enter / Insert / drag, point + rotation, MED3DLIBINSERT), Open DWG, editing Description / Category / Note (panel and Grid), Excel export / import with the (clear) rule and automatic backup, Rescan (Shift = rebuild all previews), Folder..., category table (22 categories, 385 blocks, from Dwg3DCatalog.db).
- **Appendix A**: pointer to docs\command-reference.md, 3d-guide.md, lisp-reference.md, and a table of removed commands and dead menu items with what to use instead.

## Removed (2012 sections and items not carried over)

- **Start MED in Training Mode** (MED 1.53 training icon). Replaced by Installing and Starting MED.
- **Using Access to View or Modify Data**: Access/.dbf no longer used.
- **MEDPACK**: not needed with SQLite.
- **Browsing the BOM with SHOW**: SHOW no longer exists. The section is rewritten for MEDSHOWBOM.
- **Index**: replaced by the table of contents.
- MEDTYPE Add New Record dialog walkthrough (DCL dialogs, images 149-151): replaced by MEDTYPE grid steps.
- MEDSET dialog pictures (images 22, 42, 49, 51, 174), MED Change dialog pictures (38, 39, 123), Setup dialog picture (3), main toolbar strip (7), cable tray toolbar strip (59), side-view tray button (68), Osnap dialog (136), BOM output (148), training icon (2). Replaced by MED2026 screenshots or `[Screenshot: ...]` placeholders.
- Cable Tray toolbar **Side View Tray** button (no longer on the toolbar; type VTRAY).
- Main toolbar **DD** button (gone from the toolbar; DD itself is in Utilities).
- Utilities: **BLK20** (no longer in MED).
- Dead menu items left out of the task text (listed only in Appendix A): SHOW, BOMSS, ADDATRIB, MOTOR, INST, T0, VCHAN90.

## Updated

- All "MEDSET dialog" references now point to the MED Settings palette; all "MEDCHANGE dialog" steps use the MED Properties palette.
- Every prompt in the tutorials was re-checked against the LISP source: CONDUIT, CABLE (`Cable Relate Tag`), TRAY (`Startpoint of ...`, `To Point:`, `CableTray Tag number`), conduit up/down (`Length of Conduit traveling Up<10'>:`), CHGSIZE (`Change COnduit or Fitting <CO>:`, decimal size), TRAYV90, TRAYDN, TRAYOFF / PTRAYOFF / VTRAYOFF, TRAYRE (`Size to Reduce to:`), SECT, DETAG (and the Enter fallback prompts), MEDSTRIP, MEDLIST (`Select Entity to list:`), MEDFIND, MEDCOPY, LISP.
- Plan Drawings / Details / Wiring Diagrams intros: MEDPLAN / MEDDETAIL / MEDWIRING still exist (med.mnl) but are marked [VERIFY] for med.cuix.
- Details toolbar: Instrument Details button calls the dead INST; the guide tells you to type INS.
- Material Data: entity data table now includes Flange; MEDType field table updated (Group = Cable Type, Key2 = conduit body key, User1 tray section length, User3 cable OD); extraction steps rewritten for MEDProject.
- Detail Conduit: CONFIX, MEDDETCON layer, HUBS.
- Wiring diagrams: tutorial kept; the Oneline tutorial drawing is not shipped, so it starts in a new drawing; Typical Starters menu marked [VERIFY].
- Utilities tables re-checked: every command except BLK20 is still defined. IL text: LAT does not exist, now says use AutoCAD's LAYTHW. ACAD.PGP table matches `Support\ACAD.PGP`, plus the 3 extra aliases (3DLINE, RR, SERIAL).
- Tutorial drawings (Conduit2, Conduit3, TRAY START, CABLE START, Oneline) are not in the repo; the tutorials start from a new drawing.

## Open [VERIFY] items (24)

| # | Chapter | Section | Item |
| --- | --- | --- | --- |
| 1 | General Information | How to use this guide | compare the toolbar pictures with med.cuix |
| 2 | General Information | Installing and Starting MED | exact way to show MED toolbars with MENUBAR=1 in the MED2026 profile |
| 3 | General Information | Drawing Setup | 2012 SETUP prompted for the FILEINFO block itself; the MED2026 SETUP code only inserts the title block |
| 4 | Plan Drawings | (intro) | MEDPLAN / MEDDETAIL / MEDWIRING menu switching with med.cuix in AutoCAD 2020-2024 |
| 5 | Plan Drawings | Conduit | tag insertion prompt text |
| 6 | Plan Drawings | Conduit | ship the tutorial drawings or drop the references |
| 7 | Plan Drawings | Cable Tray | leader prompt text in MED2026 |
| 8 | Plan Drawings | Cable Tray | 2012 also prompted for a direction; check the MED2026 prompt sequence |
| 9 | Plan Drawings | Cable Tray | VTRAYOFF has no toolbar button in med.cuix; type it |
| 10 | Plan Drawings | Cable Tray | TRAYFIX on tray fittings |
| 11 | Plan Drawings | Cables | the three symbol buttons are all named 'Ground Cable Up' in med.cuix; confirm which is up solid / up open / down |
| 12 | Plan Drawings | Material Data | remove or remap these buttons in med.cuix |
| 13 | Details | (intro) | MEDDETAIL menu switching with med.cuix |
| 14 | Details | Detail Conduit | toolbar picture |
| 15 | Wiring Diagrams | (intro) | MEDWIRING menu switching with med.cuix |
| 16 | Wiring Diagrams | The Oneline Toolbar | menu name and item in med.cuix |
| 17 | Wiring Diagrams | The Oneline Toolbar | image menu still current |
| 18 | 3D Modeling | The 3D commands | add MEDMAKE3D and MED3DLIB to med.cuix? |
| 19 | 3D Modeling | Single-purpose 3D commands | 3DS option in current AutoCAD |
| 20 | 3D Modeling | Conduit body test and data commands | MEDCBGrid.lsp is not installed with MED |
| 21 | 3D Modeling | Using the model in Navisworks | how the Navisworks plug-in is installed for end users |
| 22 | 3D Block Library | Opening the library | the MED2026 installer ships the Dwg3D folder and Dwg3DCatalog.db |
| 23 | 3D Block Library | Inserting a block | drag-and-drop now inserts at the drop point (fixed; was opening the DWG via FileDrop); check prompts and scale |
| 24 | Appendix A: Command Reference | Removed commands and menu items | remove or remap the dead menu items above in med.cuix |

## Screenshots still needed (13)

- Drawing Setup dialog (scale type including Metric, scale list, Title Block, File..., Use PaperSpace)
- MED2026 Main Tool Bar (Home Page, MED Docs, flyouts, Drawing Setup, Revision Triangle, linetype flyouts, Double Line, Triple Line)
- MED Settings palette (General, Conduit and Tray sections, Scale list)
- MED2026 Cable Tray toolbar
- Cable palette (Cable Type list, Cable list, Route Cable button)
- MED Properties palette showing a cable record (Tag, Related Tag, Size/Count, Code, Distance, Measure)
- MEDTYPE catalog grid with the Type filter set to Equipment
- MEDMAKE3D result: tray, conduit and conduit bodies in an isometric view
- Conduit run with LB and T conduit bodies after MEDMAKE3D
- MED3DLIB palette in List view, docked on the right
- MED3DLIB palette in Tiles view
- MED3DLIB palette in Grid view
- Dwg3DCatalog_BulkEdit.xlsx Blocks sheet with category drop-down

Also re-shoot the reused 2012 toolbar pictures if the med.cuix icons look different.

- 2026-10-01: DDMEDLIST removed from MED. Conduit and tray "Identifying ... with MEDLIST and ..." sections now use MEDLIST / MEDPROPERTIES (MED Properties palette, MEDRECORDS grid); the Dynamic MEDList dialog picture and caption were deleted; MED Data Tools flyout text lists MED 3D Library instead of MED List; Appendix A removed-commands table has a DDMEDLIST row.

- 2026-10-01: Toolbar icon pictures swapped for Clint's new icons (`Dropbox\Development\MED\Icons`, 340 16x15 BMPs named `Med_<image name>.bmp` after the med.cuix SmallImage names). 97 distinct button/flyout pictures in the guide (113 uses) were matched to a new icon by med.cuix button name plus a pixel comparison (flyout pictures show the first button of the target toolbar). 49 pictures (59 uses) were replaced; the other 48 were already pixel-identical to the new icon and were left alone. Most changes are the darker conduit/cable/tray background shades (navy, green, purple); real artwork changes are MED Data Strip (MEDSTRIP), grey detail pixels in RGS, Union and the cap fitting, and a few edge pixels on SETUP, DD, 2LINE, Conduit Down, Draw Conduit, TRAYFIX, Tray Down and HOA. The new icon was pasted (as PNG) into the old 23x22 button frame at the same offset, keeping the flyout triangle, so the size and position on the page are the same. Toolbar strip screenshots (Conduit, Tray Size/Depth/Radius, Cables, Details, Detail Conduit, One Lines, Elementary), dialogs and drawings were not touched. Picture 40 (cap fitting) was matched to CON_REPLUG (Recessed Plug) by eye; CON_SQPLUG looks almost the same. The Text Styles flyout picture uses LSP_T937THIN, but med.cuix names those buttons LSP_T0-T3 / LSP_B1-B3, which are not in the Icons folder. No icon images in docs\*.md (those are screenshots). Backup: `Downloads\UserGuide.docx.bak-20261001-135310`; old/new sheet: `Downloads\guide_icon_swap.png`.

## 2 Oct 2026: Appendix A rebuilt, table of contents and index

Backup before this change: `Downloads\UserGuide.docx.bak-20261002-141935`. Not committed.

- **Appendix A** now lists every command MED defines on `feature/3dpath`: 275 commands, 254 LISP (`defun c:` in `Support\*.lsp`, `med.mnl`, `med.spc` LOADTXT and the two `tests\autocad` files) and 21 .NET (`[CommandMethod]` in `src\MED-DotNet`, including MED3DLIB / MED3DLIBINSERT / MED3DLIBTEST). DDMEDLIST is gone (it shows up only in the "Removed commands" table). No commands exist only in `SupportAdds` (it has no .lsp files). The list matches `docs\command-reference.md` exactly.
  - **Commands by category** (new, at the front of the appendix): 13 categories, each with a short description and a table of its commands. Setup and Configuration 15, Conduit and Conduit Fittings 16, Cable Tray and Channel 48, Cables and Wiring 6, One-Lines and Elementary Diagrams 4, Details and Equipment 11, Lists, Reports and MED Data 34, Tagging and Balloons 34, Text and Attributes 36, Layers, Editing and View Utilities 41, 3D Modeling and Conduit Bodies 17, 3D Block Library 2, Developer and Test 11.
  - **Commands A to Z** (new): Command | Description | Category | Source. Descriptions come from `docs\command-reference.md`. Source shows the defining file, "(not loaded by MEDCore)" for MED3DCON.lsp and the test files, and the second file for commands defined twice (LOADTXT, SECT, ESOLID; MC is defined twice in QKEY.lsp).
  - New [VERIFY] note: BLDSTL creates one command per text style when it runs (for example T937THIN); should the Text Styles menu call these, or T1 / T2 / T3?
  - The intro paragraph was rewritten; the docs bullets and "Removed commands and menu items" are unchanged.
- **Table of contents**: the TOC field now covers Heading 1-3 (was 1-2) with clickable entries (`TOC \o "1-3" \h \z \u`). Every chapter and section already used the Heading 1-5 styles; nothing needed restyling. The "To ...:" bold lines are procedure intros, not headings, and were left alone.
- **Index** (new, last chapter, two columns): `INDEX \c "2" \h "A"` with 758 XE entries for 332 terms: all 275 commands (at their Appendix A row and where the body describes them, once per section) and 57 topics (conduit, cable tray, fittings, conduit bodies, cables, layers, xdata, drawing setup, MED Settings / Properties palettes, 3D modeling, 3D Block Library, Navisworks, BOM, catalog, database and more), marked in headings plus the first mention in each chapter.
- The TOC and index are filled in with LibreOffice page numbers. `updateFields` is set in settings.xml, so Word asks to update fields when the guide opens; say Yes and Word renumbers to its own layout.
- Length: 110 pages in LibreOffice (was 91): Appendix A is about 13 pages, the index about 5, and the TOC 4 (was 2).

## 5 Oct 2026: scale section rewritten around the MED Settings palette

- Drawing Setup > Setup: replaced the "If you need to change the scale of a drawing, run SETUP again..." paragraph and the following MED Settings Tip with a new Heading 4 **Changing the Drawing Scale**: short intro, "To set the drawing scale:" steps (MEDSETTINGS / MEDSET, MED Main > MED Settings, MED Data Tools toolbar or ribbon panel; General > Scale; applies on pick), a figure of the palette with the Scale list open (cropped from Clint's screenshot, 2.4" wide, Caption style), a note on the Full Size / Arch / Eng / Metric grouping and that the number in parentheses is the scale factor, and a Tip keeping the XT advice (now with LOADTXT first).
- Checked against `src\MED-DotNet\MED-DotNet\MedSettingsPalette.cs`, `MedSettingsControl.cs`, `MedScaleChoice.cs`, `MedLisp.cs` (ApplyDrawingScale sets `_SC`, `_PLOTSCALE`, `DIMSCALE`, `USERR1` only), `Support\medsetup.lsp` + `setup.add` (SETUP also inserts the title block, sets LTSCALE/LUNITS/grid/snap and runs LOADTXT), `Support\medtext.lsp` (XT, LOADTXT), `Support\med.mnu` and `MEDRibbon.cuix` (menu, toolbar and ribbon buttons).
- XE entries added in the section: Scale, MED Settings palette, MEDSETTINGS, MEDSET, XT, Text styles, LOADTXT. `updateFields` set again in settings.xml (it had been cleared by a Word save), so Word asks to update the TOC and index on open.
- Clint's own edits since 2 Oct were kept (worked from the 5 Oct 9:54 AM file). Backup: `Downloads\UserGuide.docx.bak-20261005-095940`.

## 5 Oct 2026: Clint's review edits (screenshots, tray notes, 3D disclaimer, MED Data Tools)

Backup before this change: `Downloads\UserGuide.docx.bak-20261005-110747`. Not committed. Worked from the current file, so Clint's own edits are kept. Page numbers below are LibreOffice pages.

- **Main Tool Bar** (p. 10): the `[Screenshot: MED2026 Main Tool Bar ...]` placeholder is replaced by Clint's toolbar strip, captioned "The MED Main Tool Bar." The Text Styles flyout line now says it starts text at the standard MED sizes (T1-T3, and B1-B3 on the bold layer). The MED Data Tools flyout line now lists the same buttons as the toolbar.
- **MEDCHG / MED Properties** (p. 17): new figure of the palette beside a selected conduit run, captioned "The MED Properties palette with a conduit selected." The earlier multi-select palette picture moved below the *VARIES* paragraph with a new caption.
- **MED Data Tools toolbar** (Material Data > Other MED data tools, p. 59-60): new toolbar figure plus a left-to-right list of all 13 buttons and their commands (MEDCHG, MEDRECORDS, MED3DLIB, MEDCHG-CLASSIC, MEDSET, BOM, BOMSS, Browse BOM = MEDSHOWBOM, DETAGUPD, MEDFIND, MEDCOPY, MEDSTRIP, CHGSIZE). BOM SS is described as running BOM on a selection set you pick instead of the whole drawing, and Browse BOM as running MEDSHOWBOM (Clint approved these fixes). The old note about dead SHOW / BOMSS buttons (p. 58) is rewritten without [VERIFY]. In Appendix A > Removed commands, the BOMSS row is removed and the SHOW row now reads "SHOW (2012 browse dialog)". BOMSS isn't in Commands A to Z yet; add it once the command is in the code.
- **MEDRECORDS icon** (p. 22): the old MEDLIST-style "!" icon next to "The MED Records button (MEDRECORDS)" is removed. The line is now plain text pointing to Editing multiple records.
- **TRAYOFF** (p. 35): the [VERIFY] note about a direction prompt is removed. Step 5 now says the plan offset doesn't ask for a direction, and that PTRAYOFF is the command that prompts Up/Down.
- **VTRAYOFF** (p. 39): the 2012 button picture, its caption and the [VERIFY] are removed. A new note says VTRAYOFF has no button (type it) and is kept for older side-view drawings, since the 3D model mostly replaces side views. The Appendix A row says the same.
- **TRAYFIX** (p. 43): the note now says TRAYFIX redraws the outlines of both tray and tray fittings (2012 handled tray only). The [VERIFY] is removed, and the Appendix A row is updated to match.
- **3D disclaimer**: a boxed Important note (same blue left bar as the Notes, plus a light blue box) appears at the end of the Introduction (p. 6), at the start of 3D Modeling (p. 78) and at the start of 3D Block Library (p. 84). It reads: "3D models are approximations for layout and coordination only and are not reproductions of manufacturer specifications. Verify all dimensions against manufacturer data." There's a new index entry, "Disclaimer, 3D models", plus "MED Data Tools toolbar".
- **3D Library drag insert** (p. 85): the [VERIFY] is removed. Dragging a block from the list or preview inserts it at the drop point and then asks for rotation. Open DWG is the only way to open a block's DWG from the palette. The code fix is in progress on feature/3dpath.
- **T1-T3 / B1-B3** (Appendix A, p. 94-95): the BLDSTL note no longer has its [VERIFY]. It now explains that T1/T2/T3 start DTEXT in the default MED styles at body, medium and large sizes, and B1/B2/B3 do the same on the MED_TEXT-BOLD layer. They aren't text styles, and the per-style commands BLDSTL makes (for example T937THIN) are separate. The A-Z rows for T1-T3 and B1-B3 are reworded to match (checked against MED_TXT_STYLE_MAP in MEDVariables.lsp and med_text in MEDCommands.lsp).
- The TOC and index page numbers are refreshed from LibreOffice, and `updateFields` is still set, so Word will ask to update fields on open. LibreOffice length is 109 pages, unchanged. 17 [VERIFY] markers remain, down from 23, not counting the two that explain the marker.
