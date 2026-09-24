MED2026 Patch installer
=======================

This patch updates an existing MED2026 install without requiring administrator
rights when the install folder is writable by your account.

What it updates
---------------
- Support\MED-DotNet.dll
- Support\MEDCore.lsp, MEDFunctions.lsp, MED3DTrayFunctions.lsp
- Support\MED.version.txt (channel=patch)
- Navisworks MEDProperties plugin under your per-user AppData
  (Manage 2024 / Simulate 2024 Plugins\MEDPropertiesPlugin\)

What it does NOT touch
----------------------
- AutoCAD profile / registry
- MEDDataBaseSettings.dat, Project.dat, MED.db
- Block library (Dwg)

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
Restart AutoCAD and Navisworks so they reload the DLL / plugin.

If C:\MED2026 is not writable
-----------------------------
The patch cannot update Support there without admin. Either:
  - Run the full MED2026-Setup as administrator, or
  - Point this wizard at a user-writable MED folder, or
  - Continue for Navisworks-only (AppData plugin always writable).

See docs\updates.md for full vs patch and version tracking.
