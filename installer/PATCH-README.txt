MED2026 Patch installer - 2026.0.1005a (WORK IN PROGRESS)
=========================================================

IMPORTANT: MED 3D models are approximations, not copies of manufacturer
specifications; users must verify all dimensions.

This build is a work-in-progress pre-release. Test it before rolling it out
to production seats.

This patch updates an existing MED2026 install without requiring administrator
rights when the install folder is writable by your account.

What it updates
---------------
- Everything in Support\ (MED-DotNet.dll, MED.dll / MEDRibbon.dll, all LISP,
  med.cuix and MEDRibbon.cuix, med.mnu / mns / mnl / mnr / dcl, toolbar icons,
  slide libraries, MOTOR.DAT, medblck.dat, ...), EXCEPT the site files listed
  under "What it does NOT touch"
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
- Support\med.spc, Support\ACAD.PGP, MEDDataBaseSettings.dat, Project.dat,
  MED.registration.json
- Data\MED.db (file) and Data\MEDRegistrations.db
- Any other block in Dwg\

Safety guards
-------------
- Existing install required: the Support update only runs when the chosen
  folder already contains Support\MED-DotNet.dll or Support\MED.version.txt.
  Otherwise the wizard stops with "No MED2026 installation found at ..." -
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
