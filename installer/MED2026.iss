; MED2026 Inno Setup wrapper
; Unpacks under {app}, then runs installer\Install-MED2026.ps1 hidden as the
; logged-in user (HKCU AutoCAD profile + desktop icon). Users never run a .ps1.
; Layout: {app}\Support, {app}\Data, {app}\Dwg, {app}\installer
; Optional: Navisworks MEDProperties plugin to per-user AppData (no Autodesk API DLLs).

#define MyAppName "MED2026"
#define MyAppVersion "2026.0.0924"
#define MyAppPublisher "Dewitt Clinton Moore"
#define MyOutputBase "MED2026-Setup-0924a"

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

[Files]
; Core Support pack ? do not ship live .dat settings; Create if missing in [Code]
Source: "Support\*"; DestDir: "{app}\Support"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core; Excludes: "MEDDataBaseSettings.dat,Project.dat,*.bak,med.cuix.bak-*,MEDRibbon.cuix.bak-*,acad.rx,MEDMain.odcl,TODO-MEDMainDialogs-CSharpUI.txt,MEDMainDialogs-RedoWithCSharp.lsp,TESTICONONEINCHa.bmp,MEDDataBaseSettings.example.dat"
Source: "Data\MED.db"; DestDir: "{app}\Data"; Flags: ignoreversion; Components: core
Source: "Data\README.txt"; DestDir: "{app}\Data"; Flags: ignoreversion; Components: core
; Real block library. Not Samples, not a Dwgs folder. Skip leftover Csch1.
Source: "Dwg\*"; DestDir: "{app}\Dwg"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core; Excludes: "Csch1.dwg,csch1.dwg,CSCH1.dwg"
Source: "installer\Install-MED2026.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion; Components: core
Source: "installer\MED2026-ProfileSetup.lsp"; DestDir: "{app}\installer"; Flags: ignoreversion; Components: core
Source: "installer\MED2026-ProfileSetup.lsp"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: core
Source: "installer\MED2026-FirstRun.scr"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: core

; Stage Navis plugin under {app}; Install-MED2026.ps1 (runasoriginaluser) copies to
; the logged-in user's AppData so elevated Setup does not write the wrong profile.
; No Autodesk.* API DLLs. Traditional layout: folder name = DLL base name.
Source: "installer\staging\Navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll"; DestDir: "{app}\installer\navis\MEDPropertiesPlugin"; Flags: ignoreversion; Components: navis

[Icons]
; Public desktop so the icon is visible even if UAC ran Setup elevated.
; Filename is filled in by [Code] once acad.exe is found.
Name: "{commondesktop}\MED2026 AutoCAD"; Filename: "{code:GetAcadExe}"; Parameters: "/p MED2026 /b ""{app}\Support\MED2026-FirstRun.scr"""; WorkingDir: "{app}"; Comment: "AutoCAD with MED2026 profile"; Check: AcadFound; Components: core

[Run]
; Must be the logged-in user so the AutoCAD profile lands in THEIR HKCU.
; Hidden: nobody has to know this is PowerShell.
Filename: "powershell.exe"; \
    Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\installer\Install-MED2026.ps1"" -InstallDir ""{app}"" -Provider SQLite"; \
    StatusMsg: "Creating the MED2026 AutoCAD profile and desktop shortcut..."; \
    Flags: waituntilterminated runasoriginaluser runhidden; Components: core

[Code]
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
    'build_date=2026-09-24' + #13#10 +
    'git=81b1915' + #13#10 +
    'channel=' + Channel + #13#10;
  SaveStringToFile(P, Contents, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    WriteSqliteSettings;
    WriteProjectDat;
    WriteVersionFile('full');
  end;
end;
