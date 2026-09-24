; MED2026 non-admin patch installer
; Updates Support (MED-DotNet + changed LISP + MED.version.txt) and optional
; Navisworks MEDProperties plugin under per-user AppData.
; Does NOT rewrite AutoCAD profiles, MEDDataBaseSettings.dat, Project.dat, or MED.db.
; PrivilegesRequired=lowest ? may fail to write C:\MED2026 if that folder is admin-owned.
; Opt-in registration: reuse Support\MED.registration.json when present (skip wizard page).

#define MyAppName "MED2026"
#define MyAppVersion "2026.0.0924b"
#define MyAppPublisher "Dewitt Clinton Moore"
#define MyOutputBase "MED2026-Patch-0924b"
#define MedBuildDate "2026-09-24"
#define MedGitHash "a5a57d2"
#define MedRegisterUrl "https://mooredesign.net/.netlify/functions/med-register"

[Setup]
AppId={{8E2F6A1B-4C9D-4E07-9B53-7A1C0D2E4F68}
AppName={#MyAppName} Patch
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} Patch {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={code:GetDefaultMedDir}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer\Output
OutputBaseFilename={#MyOutputBase}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SourceDir=..
UninstallDisplayName={#MyAppName}
SetupLogging=yes
DirExistsWarning=no
UsePreviousAppDir=yes
DisableDirPage=no
InfoBeforeFile=installer\PATCH-README.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Support update + Navisworks plugin"
Name: "supportonly"; Description: "Support files only"
Name: "navisonly"; Description: "Navisworks plugin only"
Name: "custom"; Description: "Custom"; Flags: iscustom

[Components]
Name: "support"; Description: "Update MED Support (DLL + LISP + version file)"; Types: full supportonly custom
Name: "navis"; Description: "Navisworks MEDProperties plugin (per-user AppData)"; Types: full navisonly custom

[Files]
; Overwrite key Support files into {app}\Support when writable.
Source: "Support\MED-DotNet.dll"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: support; Check: MedSupportWritable
Source: "Support\MEDCore.lsp"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: support; Check: MedSupportWritable
Source: "Support\MEDFunctions.lsp"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: support; Check: MedSupportWritable
Source: "Support\MED3DTrayFunctions.lsp"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: support; Check: MedSupportWritable
Source: "Support\MED.version.txt"; DestDir: "{app}\Support"; Flags: ignoreversion; Components: support; Check: MedSupportWritable
Source: "installer\Register-MEDInstall.ps1"; Flags: dontcopy

; Always try Navis per-user AppData (writable without admin).
Source: "installer\staging\Navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll"; DestDir: "{userappdata}\Autodesk\Navisworks Manage 2024\Plugins\MEDPropertiesPlugin"; Flags: ignoreversion; Components: navis; Check: NavisManage2024Found
Source: "installer\staging\Navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll"; DestDir: "{userappdata}\Autodesk\Navisworks Simulate 2024\Plugins\MEDPropertiesPlugin"; Flags: ignoreversion; Components: navis; Check: NavisSimulate2024Found

[Code]
var
  SupportWritableCached: Boolean;
  SupportWritableKnown: Boolean;
  WarnedUnwritable: Boolean;

#include "MED-Registration.issinc"

function GetEnvMed: String;
begin
  Result := GetEnv('MED2026');
end;

function GetDefaultMedDir(Param: String): String;
var
  EnvDir, SdDir: String;
begin
  EnvDir := GetEnvMed();
  if (EnvDir <> '') and DirExists(EnvDir) then
  begin
    Result := EnvDir;
    exit;
  end;
  SdDir := ExpandConstant('{sd}\MED2026');
  if DirExists(SdDir) then
  begin
    Result := SdDir;
    exit;
  end;
  { Prefer a user-writable fallback suggestion if C:\MED2026 is missing }
  Result := ExpandConstant('{userdocs}\MED2026');
end;

function NavisManage2024Found: Boolean;
begin
  Result := FileExists(ExpandConstant('{pf}') + '\Autodesk\Navisworks Manage 2024\Roamer.exe');
end;

function NavisSimulate2024Found: Boolean;
begin
  Result := FileExists(ExpandConstant('{pf}') + '\Autodesk\Navisworks Simulate 2024\Roamer.exe');
end;

function ProbeSupportWritable(SupportDir: String): Boolean;
var
  TestFile: String;
begin
  Result := False;
  if not DirExists(SupportDir) then
  begin
    { Try create ? may fail without admin on C:\MED2026 }
    if not ForceDirectories(SupportDir) then
      exit;
  end;
  TestFile := SupportDir + '\.med_patch_write_test';
  if SaveStringToFile(TestFile, 'ok', False) then
  begin
    DeleteFile(TestFile);
    Result := True;
  end;
end;

function MedSupportWritable: Boolean;
var
  SupportDir: String;
begin
  if SupportWritableKnown then
  begin
    Result := SupportWritableCached;
    exit;
  end;
  SupportDir := ExpandConstant('{app}\Support');
  SupportWritableCached := ProbeSupportWritable(SupportDir);
  SupportWritableKnown := True;
  Result := SupportWritableCached;
end;

procedure WriteVersionFilePatch;
var
  P, Contents: String;
begin
  if not MedSupportWritable then
    exit;
  P := ExpandConstant('{app}\Support\MED.version.txt');
  Contents :=
    'version={#MyAppVersion}' + #13#10 +
    'build_date={#MedBuildDate}' + #13#10 +
    'git={#MedGitHash}' + #13#10 +
    'channel=patch' + #13#10;
  SaveStringToFile(P, Contents, False);
end;

procedure InitializeWizard;
begin
  WarnedUnwritable := False;
  SupportWritableKnown := False;
  MedCreateRegistrationPage;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if (MedRegPage <> nil) and (PageID = MedRegPage.ID) then
  begin
    if MedLoadExistingOptIn then
    begin
      MedRegSkipPage := True;
      Result := True;
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  SupportDir: String;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    SupportWritableKnown := False;
    SupportDir := ExpandConstant('{app}\Support');
    if WizardIsComponentSelected('support') and (not MedSupportWritable) then
    begin
      MsgBox(
        'Cannot write to:' + #13#10 + SupportDir + #13#10#13#10 +
        'This folder is not writable without administrator rights (typical for C:\MED2026).' + #13#10#13#10 +
        'Options:' + #13#10 +
        '  1) Run the full MED2026-Setup as administrator, or' + #13#10 +
        '  2) Choose a user-writable MED install folder, or' + #13#10 +
        '  3) Continue ? Navisworks AppData plugin can still install;' + #13#10 +
        '     Support files will be skipped.' + #13#10,
        mbError, MB_OK);
      WarnedUnwritable := True;
      { Allow continue so Navis-only still works }
      Result := True;
    end;
  end
  else if (MedRegPage <> nil) and (CurPageID = MedRegPage.ID) then
    Result := MedRegPageNextCheck;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsComponentSelected('support') and MedSupportWritable then
      WriteVersionFilePatch;
    { Registration update even if only navis selected, when Support is writable enough for JSON }
    if MedSupportWritable or MedRegHaveExisting then
      MedHandleRegistrationPostInstall('patch');
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    if WarnedUnwritable and (not MedSupportWritable) then
      WizardForm.FinishedLabel.Caption :=
        WizardForm.FinishedLabel.Caption + #13#10#13#10 +
        'NOTE: Support files were NOT updated (install folder not writable). ' +
        'Navisworks plugin may still have been installed under your AppData. ' +
        'Run full Setup as admin or copy Support files manually.';
  end;
end;