# MED2026 App Store bundle (from 0925a)

Build (Linux box or Windows with .NET 8 SDK):

    dotnet build tools/appstore/MED-DotNet.AppStore.csproj -c Release
    python3 tools/appstore/build_bundle.py tools/appstore/bin/Release/net472/MED-DotNet.dll <outdir> [--ribbon]

Output: `<outdir>/MED2026.bundle` + `MED2026.bundle-<ver>-appstore.zip`.

- AutoCAD 2020-2024 only (R23.1-R24.3, net472). 2025+ needs a .NET 8 build.
- AutoCAD API refs come from the AutoCAD.NET 23.1.0 NuGet package (compile only).
- First run: MED-DotNet seeds `%APPDATA%\MooreDesign\MED2026` (Support: Project.dat, MEDDataBaseSettings.dat, med.spc, MOTOR.DAT, medblck.dat, setup.add, QKEY.lsp; Data: MED.db). Never overwrites. No registry/profile/TRUSTEDPATHS edits.
- LISP uses the per-user copies only when `MEDBundle.flag` is on the path (bundle installs), so Setup.exe installs behave as before.
- Not shipped: ACAD.LSP (replaced by MED2026-Bundle.lsp), ACAD.PGP, MED2026-ProfileSetup.lsp, CSharpAdd.lsp, MEDRegistrations.db, Navisworks plugin.
- MEDRibbon.cuix is left out by default because 0925a unloads the ribbon; pass `--ribbon` to include it.
- Contents/Dwg is empty: the block library is not in git; copy C:\MED2026\Dwg in before packaging.
- New commands: MEDABOUT, MEDPRIVACY (also on the MED Main pulldown in the bundle's med.cuix).
