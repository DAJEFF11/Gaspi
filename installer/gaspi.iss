#define MyAppName "Gaspi"
#define MyAppVersion "0.1.0"
#define MyAppExeName "gaspi.exe"
[Setup]
AppId={{C16C20C7-43B5-46C5-A4B4-658359305B6E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=DAJEFF11
AppPublisherURL=https://github.com/DAJEFF11/Gaspi
AppSupportURL=https://github.com/DAJEFF11/Gaspi/issues
DefaultDirName={localappdata}\Programs\Gaspi
DefaultGroupName=Gaspi
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=Gaspi-Setup-windows-x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; Flags: unchecked
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Gaspi"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Gaspi"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir Gaspi"; Flags: nowait postinstall skipifsilent
