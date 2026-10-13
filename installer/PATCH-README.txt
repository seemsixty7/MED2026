MED2026 Patch installer - 2026.0.1013a (WORK IN PROGRESS)
=========================================================

IMPORTANT: MED 3D models are approximations, not copies of manufacturer
specifications; users must verify all dimensions.

This build is a work-in-progress pre-release. Test it before rolling it out
to production seats.

This patch updates an existing MED2026 install: the classic Setup install
(C:\MED2026) and/or the Autodesk App Store bundle
(C:\ProgramData\Autodesk\ApplicationPlugins\MED2026.bundle). It asks for
administrator rights (the App Store bundle lives in ProgramData). If neither
install is found it says so and exits.

What it updates
---------------
- Everything in Support\ (MED-DotNet.dll, MED.dll / MEDRibbon.dll, all LISP,
  med.cuix and MEDRibbon.cuix, med.mnu / mns / mnl / mnr / dcl, toolbar icons,
  slide libraries, ...), EXCEPT the files listed under "What it does NOT touch"
- App Store bundle: the bundle's program files (Contents\Support, Win64, Dwg,
  Dwg3D, Data\seed, Resources, PackageContents.xml); never its Data\MED.db
- Your editable files (med.spc, ACAD.PGP, QKEY.lsp, MOTOR.DAT, medblck.dat,
  setup.add) in C:\MED2026\Support and, for the App Store bundle, in
  %APPDATA%\MooreDesign\MED2026\Support: installed ONLY IF MISSING. If yours
  differs from the new version, yours is kept and the new one is saved beside
  it as <name>.new. The finish page and patch-updates.log list them so you can
  merge by hand.
- Support\MED.version.txt (written as channel=patch)
- Data\seed\*.csv (conduit OD, cable OD, conduit body dimensions, fitting body
  keys). MED-DotNet fills blank values in your existing database at load - it
  never replaces MED.db or overwrites values.
- Dwg\: adds the blocks the 1005a menu fixes need (LTGPNL, SPRNUT, UNISIDE,
  GLOBE, GLOBE30, EVCXA, EVCXB, EVCXPNDA, EVCXPNDB, VMVSTANE, EYS29B) only if
  they are missing. Existing blocks are never replaced.
- Navisworks MEDProperties plugin under your per-user AppData
  (Manage 2024 / Simulate 2024 Plugins\MEDPropertiesPlugin\)

What it does NOT touch
----------------------
- AutoCAD profile / registry
- Your copies of med.spc, ACAD.PGP, QKEY.lsp, MOTOR.DAT, medblck.dat, setup.add
  (see .new above), MEDDataBaseSettings.dat, Project.dat, MED.registration.json
- Any MED.db (C:\MED2026\Data, %APPDATA%\MooreDesign\MED2026\Data, or the
  bundle's starter copy) and Data\MEDRegistrations.db. Database changes come
  only from MED's update path at load (backup first) and MEDDBUPDATE.
- Any other block in Dwg\

Safety guards
-------------
- Existing install required: the classic update runs when the chosen folder
  contains Support\MED-DotNet.dll or Support\MED.version.txt; the App Store
  update runs when MED2026.bundle\PackageContents.xml exists in ProgramData.
  With neither, the wizard stops with "No MED2026 installation found" -
  run the full MED2026-Setup first, or browse to your MED2026 folder.
  The patch never creates a Support folder. Navisworks-only still works
  without a MED install. Silent runs (/SILENT, /VERYSILENT) exit instead.
- Downgrade warning: if Support\MED.version.txt shows a NEWER version than
  this patch, you are asked before Support files are downgraded (default No;
  silent runs abort). Same version re-runs proceed as a repair.

After install
-------------
Restart AutoCAD and Navisworks so they reload the DLL / plugin and menus.
If the MED menus or the MED ribbon tabs look old, run CUILOAD and reload
med.cuix (MEDRibbon.cuix loads with it).

If C:\MED2026 is not writable
-----------------------------
The patch cannot update Support there without admin. Either:
  - Run the full MED2026-Setup as administrator, or
  - Point this wizard at a user-writable MED folder, or
  - Continue for Navisworks-only (AppData plugin always writable).

See docs\updates.md for full vs patch and version tracking.
