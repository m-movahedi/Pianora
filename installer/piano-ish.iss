#define MyAppName "Piano-ish"
#define MyAppExeName "Piano-ish.exe"

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0+1"
#endif

#ifndef MyVersionInfoVersion
  #define MyVersionInfoVersion "1.0.0.1"
#endif

#ifndef MyPackageVersion
  #define MyPackageVersion "1.0.0-build1"
#endif

[Setup]
; Never change AppId: it is how a newer installer finds and upgrades Piano-ish.
AppId={{7E5C12CA-3348-49D3-BA31-39D4907106EC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=Mohammad Movahedi
AppPublisherURL=https://www.m-movahedi.com
AppSupportURL=https://www.m-movahedi.com
AppUpdatesURL=https://www.m-movahedi.com
DefaultDirName={localappdata}\Programs\Piano-ish
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=output
OutputBaseFilename=Piano-ish-Setup-{#MyPackageVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=yes
UsePreviousAppDir=yes
UsePreviousTasks=yes
SetupLogging=yes
VersionInfoVersion={#MyVersionInfoVersion}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyVersionInfoVersion}
VersionInfoDescription={#MyAppName} installer
VersionInfoCompany=Mohammad Movahedi

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
