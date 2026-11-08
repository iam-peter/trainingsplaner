; Windows installer (Inno Setup 6 or 7), built by the nightly workflow:
;
;   iscc /O<output dir> /DAppVersion=0.2.0 /DAppFiles=<deployed app folder> trainingsplaner.iss
;
; It installs for the current user without administrator rights (a
; dialog offers an installation for all users), adds Start menu entries
; and an uninstaller. The training data lives in the user's AppData
; folder and is neither touched by updates nor by uninstalling.
;
; The program updates itself by running this installer with
; /SILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS; it starts
; again afterwards. /NOLAUNCH=1 keeps it from starting (for tests).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef AppFiles
  #define AppFiles "..\..\Trainingsplaner"
#endif

[Setup]
; Never change the AppId: it is how Windows and later versions recognise
; an existing installation
AppId={{177267CF-CE6F-4A78-A6F7-A6DAFE213FB9}
AppName=Trainingsplaner
AppVersion={#AppVersion}
AppVerName=Trainingsplaner {#AppVersion}
AppPublisher=Trainingsplaner
AppPublisherURL=https://iam-peter.github.io/trainingsplaner/
AppSupportURL=https://github.com/iam-peter/trainingsplaner/issues
AppUpdatesURL=https://github.com/iam-peter/trainingsplaner/releases
AppCopyright=MIT-Lizenz
VersionInfoVersion={#AppVersion}
VersionInfoDescription=Trainingsplaner Setup
DefaultDirName={autopf}\Trainingsplaner
DefaultGroupName=Trainingsplaner
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputBaseFilename=trainingsplaner-windows-x64-setup
SetupIconFile=..\..\logo\trainingsplaner.ico
UninstallDisplayIcon={app}\trainingsplaner.exe
UninstallDisplayName=Trainingsplaner
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
; Close a running Trainingsplaner before replacing its files
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Qt's folders from the previous version, so no outdated plugin or QML
; module stays behind. The DLLs next to the program are overwritten.
Type: filesandordirs; Name: "{app}\qml"
Type: filesandordirs; Name: "{app}\generic"
Type: filesandordirs; Name: "{app}\iconengines"
Type: filesandordirs; Name: "{app}\imageformats"
Type: filesandordirs; Name: "{app}\networkinformation"
Type: filesandordirs; Name: "{app}\platforms"
Type: filesandordirs; Name: "{app}\printsupport"
Type: filesandordirs; Name: "{app}\qmltooling"
Type: filesandordirs; Name: "{app}\sqldrivers"
Type: filesandordirs; Name: "{app}\styles"
Type: filesandordirs; Name: "{app}\tls"
Type: filesandordirs; Name: "{app}\translations"

[Files]
Source: "{#AppFiles}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Trainingsplaner"; Filename: "{app}\trainingsplaner.exe"
Name: "{autodesktop}\Trainingsplaner"; Filename: "{app}\trainingsplaner.exe"; Tasks: desktopicon

[Run]
; Also after a silent update, so the program comes back by itself
Filename: "{app}\trainingsplaner.exe"; Description: "{cm:LaunchProgram,Trainingsplaner}"; Flags: nowait postinstall; Check: ShouldLaunch

[Code]
function ShouldLaunch: Boolean;
begin
  Result := ExpandConstant('{param:NOLAUNCH|0}') = '0';
end;
