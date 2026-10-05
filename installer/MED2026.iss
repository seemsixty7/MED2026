; MED2026 Inno Setup wrapper
; Unpacks under {app}, then runs installer\Install-MED2026.ps1 as the
; logged-in user (HKCU AutoCAD profile + desktop icon). Visible like Core so
; profile failures stay on screen. Users never run a .ps1.
; Layout: {app}\Support, {app}\Data, {app}\Dwg, {app}\installer
; Optional: Navisworks MEDProperties plugin to per-user AppData (no Autodesk API DLLs).
; Optional opt-in install registration -> MooreDesign Netlify (not InstallHer).

#define MyAppName "MED2026"
#define MyAppVersion "2026.0.1005a"
#define MyAppPublisher "Dewitt Clinton Moore"
#define MyOutputBase "MED2026-Setup-1005a"
#define MedBuildDate "2026-10-05"
#define MedGitHash "eca633b"
; Optional 3D block library (Dwg3D folder + Dwg3DCatalog.db for the MED3DLIB palette).
; Off by default: compile with /DMedWithDwg3D to include it. Dwg3D\ is gitignored, so it is
; taken from the working tree. /DMedDwg3DCatalog="<path>" points at a catalog copy to ship
; (e.g. one with source_path cleared); default is Dwg3D\Dwg3DCatalog.db.
#ifndef MedDwg3DCatalog
  #define MedDwg3DCatalog "Dwg3D\Dwg3DCatalog.db"
#endif
#define MedRegisterUrl "https://mooredesign.net/.netlify/functions/med-register"

[Setup]
AppId={{8E2F6A1B-4C9D-4E07-9B53-7A1C0D2E4F68}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={sd}\MED2026
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer\Output
OutputBaseFilename={#MyOutputBase}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=LICENSE
; Release status + 3D model disclaimer page (shown after the license).
InfoBeforeFile=installer\MED2026-INFO.txt
SourceDir=..
UninstallDisplayName={#MyAppName}
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Compact (no Navisworks plugin)"
Name: "custom"; Description: "Custom"; Flags: iscustom

[Components]
Name: "core"; Description: "MED2026 core (Support, Data, Dwg)"; Types: full compact custom; Flags: fixed
Name: "navis"; Description: "Navisworks MEDProperties plugin (per-user AppData)"; Types: full custom
#ifdef MedWithDwg3D
Name: "lib3d"; Description: "MED 3D block library (Dwg3D, MED3DLIB palette)"; Types: full compact custom
#endif

[Files]
; Core Support pack ? do not ship live .dat settings; Create if missing in [Code]
Source: "Support\*"; DestDir: "{app}\Support"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core; Excludes: "MEDDataBaseSettings.dat,Project.dat,*.bak,*.bak-*,*.bak*,med.cuix.bak-*,MEDRibbon.cuix.bak-*,acad.rx,MEDMain.odcl,TODO-MEDMainDialogs-CSharpUI.txt,MEDMainDialogs-RedoWithCSharp.lsp,TESTICONONEINCHa.bmp,MEDDataBaseSettings.example.dat,MED.registration.json"
; Ship catalog MED.db only. NEVER ship Data\MEDRegistrations.db (desktop roster for Jane/Clint).
Source: "Data\MED.db"; DestDir: "{app}\Data"; Flags: ignoreversion; Components: core
Source: "Data\README.txt"; DestDir: "{app}\Data"; Flags: ignoreversion; Components: core
; OD seed data (conduit OD table + cable OD for MEDType.USER3). MED-DotNet applies blanks-only at load.
Source: "Data\seed\*.csv"; DestDir: "{app}\Data\seed"; Flags: ignoreversion; Components: core
; Real block library. Not Samples, not a Dwgs folder. Skip leftover Csch1.
Source: "Dwg\*"; DestDir: "{app}\Dwg"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core; Excludes: "Csch1.dwg,csch1.dwg,CSCH1.dwg"
#ifdef MedWithDwg3D
; 3D block library beside Support ({app}\Dwg3D is where MED3DLIB looks first). Keep a user-edited catalog.
Source: "Dwg3D\*.dwg"; DestDir: "{app}\Dwg3D"; Flags: ignoreversion; Components: lib3d
Source: "{#MedDwg3DCatalog}"; DestDir: "{app}\Dwg3D"; DestName: "Dwg3DCatalog.db"; Flags: onlyifdoesntexist uninsneveruninstall; Components: lib3d
#endif
Source: "installer\Install-MED2026.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion; Components: core
Source: "installer\RestoreMEDProfile.cmd"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "installer\Register-MEDInstall.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion; Components: core
Source: "installer\Register-MEDInstall.ps1"; Flags: dontcopy
Source: "installer\MED2026-ProfileSetup.lsp"; DestDir: "{app}\installer"; Flags: ignoreversion; Components: core
Source: "installer\MED2026-ProfileSetup.lsp"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: core
Source: "installer\MED2026-FirstRun.scr"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: core

; Stage Navis plugin under {app}; Install-MED2026.ps1 (runasoriginaluser) copies to
; the logged-in user's AppData so elevated Setup does not write the wrong profile.
; No Autodesk.* API DLLs. Traditional layout: folder name = DLL base name.
Source: "installer\staging\Navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll"; DestDir: "{app}\installer\navis\MEDPropertiesPlugin"; Flags: ignoreversion; Components: navis

; Desktop shortcut is created by Install-MED2026.ps1 (user desktop + optional
; public) with /p MED2026 /b FirstRun.scr ??? one source of truth (matches Core).
[Run]
; Visible so profile clone errors stay on screen (matches Core2026; no runhidden).
; Must be the logged-in user so HKCU AutoCAD profiles are theirs.
Filename: "powershell.exe"; \
    Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\installer\Install-MED2026.ps1"" -InstallDir ""{app}"" -Provider SQLite -SkipCopy"; \
    StatusMsg: "Configuring AutoCAD profile for MED2026..."; \
    Flags: waituntilterminated runasoriginaluser; Components: core
[Code]
#include "MED-Registration.issinc"

function AcadYearPaths(Year: string): string;
begin
  Result := ExpandConstant('{pf}') + '\Autodesk\AutoCAD ' + Year + '\acad.exe';
end;

function GetAcadExe(Param: string): string;
begin
  if FileExists(AcadYearPaths('2024')) then
    Result := AcadYearPaths('2024')
  else if FileExists(AcadYearPaths('2022')) then
    Result := AcadYearPaths('2022')
  else if FileExists(AcadYearPaths('2020')) then
    Result := AcadYearPaths('2020')
  else
    Result := AcadYearPaths('2024');
end;

function AcadFound: Boolean;
begin
  Result := FileExists(AcadYearPaths('2024')) or FileExists(AcadYearPaths('2022')) or FileExists(AcadYearPaths('2020'));
end;

function NavisManage2024Found: Boolean;
begin
  Result := FileExists(ExpandConstant('{pf}') + '\Autodesk\Navisworks Manage 2024\Roamer.exe');
end;

function NavisSimulate2024Found: Boolean;
begin
  Result := FileExists(ExpandConstant('{pf}') + '\Autodesk\Navisworks Simulate 2024\Roamer.exe');
end;

procedure WriteSqliteSettings;
var
  P, Contents: String;
begin
  P := ExpandConstant('{app}\Support\MEDDataBaseSettings.dat');
  if not FileExists(P) then
  begin
    Contents := 'Provider=SQLite' + #13#10 +
      'ConnectString=Data Source=' + ExpandConstant('{app}\Data\MED.db') + #13#10;
    SaveStringToFile(P, Contents, False);
  end;
end;

procedure WriteProjectDat;
var
  P, S, Contents: String;
begin
  P := ExpandConstant('{app}\Support\Project.dat');
  if not FileExists(P) then
  begin
    S := ExpandConstant('{app}\Support');
    Contents := 'MED.db' + #13#10 + S + #13#10 + S + #13#10 + S + #13#10 +
      ExpandConstant('{app}\Dwg') + #13#10;
    SaveStringToFile(P, Contents, False);
  end;
end;

procedure WriteVersionFile(Channel: String);
var
  P, Contents: String;
begin
  P := ExpandConstant('{app}\Support\MED.version.txt');
  Contents :=
    'version={#MyAppVersion}' + #13#10 +
    'build_date={#MedBuildDate}' + #13#10 +
    'git={#MedGitHash}' + #13#10 +
    'channel=' + Channel + #13#10;
  SaveStringToFile(P, Contents, False);
end;

procedure InitializeWizard;
begin
  MedCreateRegistrationPage;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if (MedRegPage <> nil) and (PageID = MedRegPage.ID) then
  begin
    { Re-check after dir is known }
    if MedLoadExistingOptIn then
    begin
      MedRegSkipPage := True;
      Result := True;
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (MedRegPage <> nil) and (CurPageID = MedRegPage.ID) then
    Result := MedRegPageNextCheck;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    WriteSqliteSettings;
    WriteProjectDat;
    WriteVersionFile('full');
    MedHandleRegistrationPostInstall('full');
  end;
end;

function NeedRestart(): Boolean;
begin
  { MED never requires reboot; ignore machine-wide PendingFileRenameOperations. }
  Result := False;
end;
