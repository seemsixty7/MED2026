#!/usr/bin/env python3
"""Assemble MED2026.bundle (Autodesk App Store / Autoloader) from this repo.

Usage: python3 tools/appstore/build_bundle.py <MED-DotNet.dll> <outdir> [--ribbon] [--version V] [--dwg DIR] [--dwg3d DIR]
Repo Support/ files are copied, never modified. ACAD.LSP and the classic
installer/profile helpers are NOT shipped (no profile/registry/TRUSTEDPATHS edits).
"""
import os, re, shutil, subprocess, sys, zipfile
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SUP = os.path.join(REPO, "Support")

PRODUCT_CODE = "{336DD2C1-557E-4525-AC13-D89591C864F1}"   # change per store release if Autodesk asks
UPGRADE_CODE = "{37E6EE93-0C49-489E-A956-4B37F3701583}"   # keep constant forever
RT = 'OS="Win64" Platform="AutoCAD*" SeriesMin="R23.1" SeriesMax="R24.3"'

SKIP = {"acad.lsp", "acad.pgp", "med2026-profilesetup.lsp", "csharpadd.lsp",
        "meddatabasesettings.example.dat", "manifest.csv", "readme.txt",
        "med-dotnet.dll", "medribbon.cuix", "med.cuix", "med.dll",
        # DLLs ship once, in Contents\Win64 (duplicates in Support were redundant)
        "system.data.sqlite.dll", "sqlite.interop.dll", "med3dlib.dll"}

def version():
    for i,a in enumerate(sys.argv):
        if a == "--version": return sys.argv[i+1]
    for l in open(os.path.join(SUP, "MED.version.txt")):
        if l.startswith("version="): return l.split("=", 1)[1].strip()

def patch_cuix(src, dst):
    """Add About MED2026 / Privacy Policy to the MED Main pulldown."""
    macros = '''    <MenuMacro UID="ID_MED_AppStore_About">
      <Macro type="Any">
        <Revision MajorVersion="23" MinorVersion="1" UserVersion="1" />
        <Name xlate="true" UID="XLS_MEDAS_ABOUT">About MED2026</Name>
        <Command>^C^C_MEDABOUT </Command>
        <HelpString xlate="true" UID="XLS_MEDAS_ABOUTH">Version, user-file location and privacy policy</HelpString>
      </Macro>
    </MenuMacro>
    <MenuMacro UID="ID_MED_AppStore_Privacy">
      <Macro type="Any">
        <Revision MajorVersion="23" MinorVersion="1" UserVersion="1" />
        <Name xlate="true" UID="XLS_MEDAS_PRIV">Privacy Policy</Name>
        <Command>^C^C_MEDPRIVACY </Command>
        <HelpString xlate="true" UID="XLS_MEDAS_PRIVH">Opens https://mooredesign.net/privacy/</HelpString>
      </Macro>
    </MenuMacro>
'''
    items = '''    <PopMenuItem IsSeparator="true" hasDiesel="false" UID="PMIU_MEDAS_SEP">
      <ModifiedRev MajorVersion="23" MinorVersion="1" UserVersion="1" />
    </PopMenuItem>
    <PopMenuItem IsSeparator="false" hasDiesel="false" UID="PMIU_MEDAS_ABOUT">
      <ModifiedRev MajorVersion="23" MinorVersion="1" UserVersion="1" />
      <NameRef UID="XLS_MEDAS_ABOUT" xlate="true">About MED2026</NameRef>
      <MenuItem>
        <MacroRef MenuMacroID="ID_MED_AppStore_About" />
      </MenuItem>
    </PopMenuItem>
    <PopMenuItem IsSeparator="false" hasDiesel="false" UID="PMIU_MEDAS_PRIV">
      <ModifiedRev MajorVersion="23" MinorVersion="1" UserVersion="1" />
      <NameRef UID="XLS_MEDAS_PRIV" xlate="true">Privacy Policy</NameRef>
      <MenuItem>
        <MacroRef MenuMacroID="ID_MED_AppStore_Privacy" />
      </MenuItem>
    </PopMenuItem>
'''
    zin = zipfile.ZipFile(src)
    zout = zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED)
    for info in zin.infolist():
        data = zin.read(info.filename)
        name = info.filename.replace("\\", "/").lower()
        if name.endswith("menugroup.cui"):
            s = data.decode("utf-8-sig")
            nl = "\r\n" if "\r\n" in s else "\n"
            k = s.index('<MacroGroup Name="MEDMacros">') + len('<MacroGroup Name="MEDMacros">')
            s = s[:k] + nl + macros.replace("\n", nl).rstrip() + s[k:]
            assert "ID_MED_AppStore_About" in s
            data = s.encode("utf-8")
        elif name.endswith("popmenuroot.cui"):
            s = data.decode("utf-8-sig")
            i = s.index("<Alias>POP1MEDMAIN</Alias>")
            j = s.index("</PopMenu>", i)
            nl = "\r\n" if "\r\n" in s else "\n"
            s = s[:j] + items.replace("\n", nl).lstrip() + "  " + s[j:]
            data = s.encode("utf-8")
        zout.writestr(info, data)
    zout.close()

def main():
    dll, out = sys.argv[1], sys.argv[2]
    ribbon = "--ribbon" in sys.argv
    ver = version()
    b = os.path.join(out, "MED2026.bundle")
    if os.path.exists(b): shutil.rmtree(b)
    c = os.path.join(b, "Contents")
    for d in ("Win64", "Support", "Data", "Dwg", "Resources"):
        os.makedirs(os.path.join(c, d))
    # .NET + SQLite natives
    shutil.copy2(dll, os.path.join(c, "Win64", "MED-DotNet.dll"))
    shutil.copy2(os.path.join(SUP, "System.Data.SQLite.dll"), os.path.join(c, "Win64"))
    shutil.copy2(os.path.join(SUP, "SQLite.Interop.dll"), os.path.join(c, "Win64"))
    # Support (LISP, DCL, slides, shapes, dat/spc seeds)
    for f in sorted(os.listdir(SUP)):
        p = os.path.join(SUP, f)
        if os.path.isfile(p) and f.lower() not in SKIP:
            shutil.copy2(p, os.path.join(c, "Support", f))
    open(os.path.join(c, "Support", "MED.version.txt"), "w", newline="\r\n").write(
        "version=%s\nbuild_date=%s\ngit=%s\nchannel=appstore\n" % (ver, __import__("datetime").date.today().isoformat(),
        subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()))
    open(os.path.join(c, "Support", "MEDBundle.flag"), "w").write("MED2026 App Store bundle " + ver + "\n")
    open(os.path.join(c, "Support", "MED2026-Bundle.lsp"), "w", newline="\r\n").write(
        ';; MED2026 App Store bundle loader (replaces ACAD.LSP; per document).\n'
        ';; MED-DotNet.dll is loaded by the Autoloader; first-run setup seeds %APPDATA%\\MooreDesign\\MED2026.\n'
        '(vl-load-com)\n'
        '(if (not (member (type processsqlstatementNET) \'(EXRXSUBR SUBR USUBR EXSUBR)))\n'
        '  (princ "\\nMED2026: MED-DotNet.dll is not loaded yet; database commands will retry NETLOAD.")\n'
        ')\n'
        '(prompt "\\nLoading MED User defined Quick Keys")\n'
        '(load "qkey.lsp")\n'
        '(prompt "\\nLoading MED2026")\n'
        '(load "MEDCore.lsp")\n'
        '(princ)\n')
    patch_cuix(os.path.join(SUP, "med.cuix"), os.path.join(c, "Support", "med.cuix"))
    if ribbon:
        shutil.copy2(os.path.join(SUP, "MEDRibbon.cuix"), os.path.join(c, "Support"))
    shutil.copy2(os.path.join(REPO, "Data", "MED.db"), os.path.join(c, "Data", "MED.db"))
    def opt(k):
        return sys.argv[sys.argv.index(k) + 1] if k in sys.argv else None
    if opt("--dwg"):
        shutil.rmtree(os.path.join(c, "Dwg")); shutil.copytree(opt("--dwg"), os.path.join(c, "Dwg"))
    else:
        open(os.path.join(c, "Dwg", "README.txt"), "w").write(
            "MED block library (Dwg) goes here (gitignored; pass --dwg <dir>).\n")
    if opt("--dwg3d"):  # MED3DLIB looks in Contents\Dwg3D (dll dir\..\Dwg3D)
        shutil.copytree(opt("--dwg3d"), os.path.join(c, "Dwg3D"))
    subprocess.check_call([sys.executable, os.path.join(HERE, "make_icons.py"), os.path.join(c, "Resources")])
    shutil.copy2(os.path.join(REPO, "LICENSE"), os.path.join(c, "Resources", "LICENSE.txt"))
    # HelpFile must be a LOCAL file: AutoCAD's AppLoader balloon does FileInfo(HelpFile), and a URL
    # throws NotSupportedException inside acad (fatal e0434352 on startup, seen in 1013a).
    open(os.path.join(c, "Resources", "MED2026-Help.html"), "w", newline="\r\n").write(
        '<!doctype html><html><head><meta charset="utf-8"><title>MED2026 Help</title>'
        '<meta http-equiv="refresh" content="0; url=https://mooredesign.net/"></head>'
        '<body><p>MED2026 by Moore Design. Help: <a href="https://mooredesign.net/">mooredesign.net</a>. '
        'Privacy: <a href="https://mooredesign.net/privacy/">mooredesign.net/privacy</a>.</p></body></html>\n')

    ribbon_xml = ('''    <ComponentEntry AppName="MED2026Ribbon" Version="%s" ModuleName="./Contents/Support/MEDRibbon.cuix" AppDescription="MED ribbon (partial menu)" AppType="CuiX" />\n''' % ver) if ribbon else ""
    xml = f'''<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0"
  AutodeskProduct="AutoCAD"
  ProductType="Application"
  Name="MED2026"
  Description="MED2026 - electrical design tools for AutoCAD: conduit, cable tray, wiring, BOM and 3D model."
  AppVersion="{ver.split('.')[0]}.{ver.split('.')[1]}.{re.sub('[^0-9]','',ver.split('.')[2])}"
  FriendlyVersion="{ver}"
  Author="Moore Design"
  Icon="./Contents/Resources/MED2026-icon-200.png"
  HelpFile="./Contents/Resources/MED2026-Help.html"
  OnlineDocumentation="https://mooredesign.net/"
  ProductCode="{PRODUCT_CODE}"
  UpgradeCode="{UPGRADE_CODE}"
  SupportedLocales="Enu">
  <CompanyDetails Name="Moore Design" Url="https://mooredesign.net/" Email="" />
  <RuntimeRequirements {RT} SupportPath="./Contents/Support" />
  <Components Description="AutoCAD 2020-2024 (.NET Framework 4.7.2)">
    <RuntimeRequirements {RT} SupportPath="./Contents/Support" />
    <ComponentEntry AppName="MED2026DotNet" Version="{ver}" ModuleName="./Contents/Win64/MED-DotNet.dll" AppDescription="MED .NET core, palettes, SQLite data" AppType=".Net" LoadOnAutoCADStartup="True" />
    <ComponentEntry AppName="MED2026Lisp" Version="{ver}" ModuleName="./Contents/Support/MED2026-Bundle.lsp" AppDescription="MED LISP loader (MEDCore)" AppType="Lisp" LoadOnAutoCADStartup="True" PerDocument="True" />
    <ComponentEntry AppName="MED2026Menu" Version="{ver}" ModuleName="./Contents/Support/med.cuix" AppDescription="MED pulldown menus (partial menu)" AppType="CuiX" />
{ribbon_xml}  </Components>
</ApplicationPackage>
'''
    open(os.path.join(b, "PackageContents.xml"), "w", newline="\r\n").write(xml)
    z = os.path.join(out, f"MED2026.bundle-{ver}-appstore.zip")
    if os.path.exists(z): os.remove(z)
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(b):
            for f in files:
                p = os.path.join(root, f)
                zf.write(p, os.path.relpath(p, out))
    print(z)

if __name__ == "__main__":
    main()
