; Inno Setup script for the Centauri desktop installer.
; CI builds it with: ISCC.exe /DAppVersion=<version> centauri.iss

#define AppName "Centauri"
#define AppPublisher "Centauri"
#define AppExeName "centauri.exe"

; The version is passed by CI; the fallback keeps local builds working.
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define BuildDir "..\..\build\windows\x64\runner\Release"
#define OutputDir "..\..\build\windows\installer"

[Setup]
AppId={{B7A4E2F1-3C5D-4A89-9F6B-1D2E3C4A5B60}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=Centauri-Setup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
