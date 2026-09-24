; MED2026 non-admin patch installer
; Updates Support (MED-DotNet + changed LISP + MED.version.txt) and optional
; Navisworks MEDProperties plugin under per-user AppData.
; Does NOT rewrite AutoCAD profiles, MEDDataBaseSettings.dat, Project.dat, or MED.db.
; PrivilegesRequired=lowest ? may fail to write C:\MED2026 if that folder is admin-owned.
; Opt-in registration: reuse Support\MED.registration.json when present (skip wizard page).
; Guards: Support update requires an existing MED install ({app}\Support\MED-DotNet.dll or
;   MED.version.txt); warns (default No) before downgrading a newer installed version.

#define MyAppName "MED2026"
#define MyAppVersion "2026.0.0924h"
#define MyAppPublisher "Dewitt Clinton Moore"
#define MyOutputBase "MED2026-Patch-0924h"
#define MedBuildDate "2026-09-24"
#define MedGitHash "b286023"
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

function StripTrailingBackslash(const S: String): String;
begin
  Result := Trim(S);
  while (Length(Result) > 3) and (Result[Length(Result)] = '\') do
    Result := Copy(Result, 1, Length(Result) - 1);
end;

{ A valid MED install is a folder containing Support\MED-DotNet.dll or Support\MED.version.txt. }
function IsValidMedInstall(const Dir: String): Boolean;
var
  D: String;
begin
  Result := False;
  D := StripTrailingBackslash(Dir);
  if D = '' then
    exit;
  Result := FileExists(D + '\Support\MED-DotNet.dll') or
            FileExists(D + '\Support\MED.version.txt');
end;

function GetDefaultMedDir(Param: String): String;
var
  EnvDir, SdDir: String;
begin
  EnvDir := StripTrailingBackslash(GetEnvMed());
  if (EnvDir <> '') and IsValidMedInstall(EnvDir) then
  begin
    Result := EnvDir;
    exit;
  end;
  SdDir := ExpandConstant('{sd}\MED2026');
  { Suggest <sd>\MED2026 even when missing; the wizard blocks Support updates
    unless the chosen folder is a real MED install. Never fall back to Documents. }
  Result := SdDir;
end;

{ Version compare for strings like 2026.0.0924h.
  Split on '.', compare leading digits numerically, then trailing letter suffix
  alphabetically (case-insensitive). Returns -1 (A<B), 0 (equal), 1 (A>B),
  or 2 if either string cannot be parsed. }
function MedSplitPart(const Part: String; var Num: Integer; var Suffix: String): Boolean;
var
  I: Integer;
  Digits: String;
begin
  Result := False;
  Num := 0;
  Suffix := '';
  I := 1;
  Digits := '';
  while (I <= Length(Part)) and (Part[I] >= '0') and (Part[I] <= '9') do
  begin
    Digits := Digits + Part[I];
    I := I + 1;
  end;
  if Digits = '' then
    exit;
  Suffix := LowerCase(Copy(Part, I, Length(Part) - I + 1));
  { Suffix must be letters only }
  for I := 1 to Length(Suffix) do
    if (Suffix[I] < 'a') or (Suffix[I] > 'z') then
      exit;
  Num := StrToIntDef(Digits, -1);
  if Num < 0 then
    exit;
  Result := True;
end;

function MedNextPart(var S: String): String;
var
  P: Integer;
begin
  P := Pos('.', S);
  if P = 0 then
  begin
    Result := S;
    S := '';
  end
  else
  begin
    Result := Copy(S, 1, P - 1);
    S := Copy(S, P + 1, Length(S) - P);
  end;
end;

function MedCompareVersions(const A, B: String): Integer;
var
  RestA, RestB, PA, PB, SufA, SufB: String;
  NA, NB: Integer;
begin
  RestA := Trim(A);
  RestB := Trim(B);
  if (RestA = '') or (RestB = '') then
  begin
    Result := 2;
    exit;
  end;
  Result := 0;
  while ((RestA <> '') or (RestB <> '')) and (Result = 0) do
  begin
    if RestA <> '' then PA := MedNextPart(RestA) else PA := '0';
    if RestB <> '' then PB := MedNextPart(RestB) else PB := '0';
    if (not MedSplitPart(PA, NA, SufA)) or (not MedSplitPart(PB, NB, SufB)) then
    begin
      Result := 2;
      exit;
    end;
    if NA < NB then Result := -1
    else if NA > NB then Result := 1
    else if CompareStr(SufA, SufB) < 0 then Result := -1
    else if CompareStr(SufA, SufB) > 0 then Result := 1;
  end;
end;

{ Reads version= from Dir\Support\MED.version.txt; '' when missing/unreadable. }
function ReadInstalledMedVersion(const Dir: String): String;
var
  Lines: TArrayOfString;
  I: Integer;
  L: String;
begin
  Result := '';
  if not LoadStringsFromFile(StripTrailingBackslash(Dir) + '\Support\MED.version.txt', Lines) then
    exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    L := Trim(Lines[I]);
    if CompareText(Copy(L, 1, 8), 'version=') = 0 then
    begin
      Result := Trim(Copy(L, 9, Length(L) - 8));
      exit;
    end;
  end;
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
  { Never create Support here: a missing Support folder means no MED install. }
  if not DirExists(SupportDir) then
    exit;
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

{ Guard (a): Support update requires an existing MED install at the chosen app dir. }
function MedCheckInstallPresent: Boolean;
var
  AppDir: String;
begin
  Result := True;
  if not WizardIsComponentSelected('support') then
    exit;
  AppDir := ExpandConstant('{app}');
  if IsValidMedInstall(AppDir) then
    exit;
  Log('MED patch: no MED2026 install at ' + AppDir +
      ' (missing Support\MED-DotNet.dll and Support\MED.version.txt); blocking Support update.');
  SuppressibleMsgBox(
    'No MED2026 installation found at' + #13#10 + AppDir + #13#10#13#10 +
    'Run the full MED2026-Setup first, or browse to your MED2026 folder.' + #13#10#13#10 +
    '(To install only the Navisworks plugin, choose "Navisworks plugin only".)',
    mbError, MB_OK, IDOK);
  Result := False;
end;

{ Guard (b): warn (default No) before installing over a newer installed version. }
function MedCheckNotDowngrade: Boolean;
var
  AppDir, Installed: String;
  Cmp: Integer;
begin
  Result := True;
  if not WizardIsComponentSelected('support') then
    exit;
  AppDir := ExpandConstant('{app}');
  Installed := ReadInstalledMedVersion(AppDir);
  if Installed = '' then
  begin
    Log('MED patch: installed version unknown; no downgrade check.');
    exit;
  end;
  Cmp := MedCompareVersions(Installed, '{#MyAppVersion}');
  Log('MED patch: installed=' + Installed + ' patch={#MyAppVersion} cmp=' + IntToStr(Cmp));
  if Cmp <> 1 then
    exit;
  if SuppressibleMsgBox(
    'Installed MED is ' + Installed + ', this patch is {#MyAppVersion} (older).' + #13#10#13#10 +
    'Installing will downgrade Support files. Continue?',
    mbConfirmation, MB_YESNO or MB_DEFBUTTON2, IDNO) = IDYES then
  begin
    Log('MED patch: user accepted downgrade from ' + Installed + '.');
    exit;
  end;
  Log('MED patch: downgrade declined (installed ' + Installed + ' is newer); blocking.');
  Result := False;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  SupportDir: String;
begin
  Result := True;
  { Checked after Select Components (which follows Select Dir) so both the
    folder and the component choice are final; Navis-only needs no MED install.
    Also runs on /SILENT and /VERYSILENT: returning False there exits Setup. }
  if CurPageID = wpSelectComponents then
  begin
    SupportWritableKnown := False;
    if not MedCheckInstallPresent then
    begin
      Result := False;
      exit;
    end;
    if not MedCheckNotDowngrade then
    begin
      Result := False;
      exit;
    end;
    SupportDir := ExpandConstant('{app}\Support');
    if WizardIsComponentSelected('support') and (not MedSupportWritable) then
    begin
      SuppressibleMsgBox(
        'Cannot write to:' + #13#10 + SupportDir + #13#10#13#10 +
        'This folder is not writable without administrator rights (typical for C:\MED2026).' + #13#10#13#10 +
        'Options:' + #13#10 +
        '  1) Run the full MED2026-Setup as administrator, or' + #13#10 +
        '  2) Choose a user-writable MED install folder, or' + #13#10 +
        '  3) Continue - Navisworks AppData plugin can still install;' + #13#10 +
        '     Support files will be skipped.' + #13#10,
        mbError, MB_OK, IDOK);
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

function NeedRestart(): Boolean;
begin
  { MED never requires reboot; ignore machine-wide PendingFileRenameOperations. }
  Result := False;
end;
