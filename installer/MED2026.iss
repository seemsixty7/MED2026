; MED2026 Inno Setup wrapper
; Unpacks the OpenSource tree under {app}, then runs installer\Install-MED2026.ps1
; SourceDir is the parent of installer (repo root).
; Layout must be {app}\Support, {app}\Data, {app}\installer, {app}\Dwgs
; so the ps1 RepoRoot (parent of installer) is {app}.

#define MyAppName "MED2026"
#define MyAppVersion "2026.0"
#define MyAppPublisher "Dewitt Clinton Moore"

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
OutputBaseFilename=MED2026-Setup
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

; C:\MED2026 needs elevation on modern Windows; lowest cannot create it.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Support keepers. Live shop settings and backups stay out of the package.
Source: "Support\*"; DestDir: "{app}\Support"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "MEDDataBaseSettings.dat,Project.dat,*.bak,med.cuix.bak-*,MEDRibbon.cuix.bak-*"
Source: "Data\MED.db"; DestDir: "{app}\Data"; Flags: ignoreversion
Source: "Data\README.txt"; DestDir: "{app}\Data"; Flags: ignoreversion
Source: "Samples\*"; DestDir: "{app}\Dwgs"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist
Source: "installer\Install-MED2026.ps1"; DestDir: "{app}\installer"; Flags: ignoreversion
Source: "installer\MED2026-ProfileSetup.lsp"; DestDir: "{app}\installer"; Flags: ignoreversion

[Run]
; Do not add a second desktop icon here; the ps1 already creates "MED2026 AutoCAD.lnk".
Filename: "powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -File ""{app}\installer\Install-MED2026.ps1"" -InstallDir ""{app}"" -Provider SQLite"; \
    StatusMsg: "Configuring MED2026 (SQLite, profile, shortcut)..."; \
    Flags: waituntilterminated