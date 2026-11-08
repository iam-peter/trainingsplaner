; Windows installer (Inno Setup 6 or 7), built by the nightly workflow
; (saved as UTF-8 with BOM, so the compiler reads the umlauts correctly):
;
;   iscc /O<output dir> /DAppVersion=0.2.0 /DAppFiles=<deployed app folder> trainingsplaner.iss
;
; It installs into the fixed program folder, without administrator rights
; for the current user (%LOCALAPPDATA%\Programs\Trainingsplaner) or, chosen
; in a dialog, for all users (Program Files). It asks for a Start menu
; entry and a desktop shortcut (both on) and registers an uninstaller in
; Windows' list of apps.
;
; The training data lives elsewhere, in %APPDATA%\Trainingsplaner (the
; database) and the registry (HKCU\Software\Trainingsplaner, settings).
; Updates never touch it; the uninstaller asks whether to delete it too
; (default: no). Silently it keeps it, unless given /REMOVEDATA=1.
;
; The program updates itself by running this installer with
; /SILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS; it keeps the
; earlier choices of shortcuts and starts again afterwards. /NOLAUNCH=1
; keeps it from starting (for tests).

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
; Always the same, known place: no folder to choose
DefaultDirName={autopf}\Trainingsplaner
DisableDirPage=yes
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
Name: "startmenuicon"; Description: "Eintrag im Startmenü"; GroupDescription: "{cm:AdditionalIcons}"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

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
Name: "{autoprograms}\Trainingsplaner"; Filename: "{app}\trainingsplaner.exe"; Tasks: startmenuicon
Name: "{autodesktop}\Trainingsplaner"; Filename: "{app}\trainingsplaner.exe"; Tasks: desktopicon

[Run]
; Also after a silent update, so the program comes back by itself
Filename: "{app}\trainingsplaner.exe"; Description: "{cm:LaunchProgram,Trainingsplaner}"; Flags: nowait postinstall; Check: ShouldLaunch

[UninstallDelete]
; Leftovers that are not data: the QML cache and a downloaded update
Type: filesandordirs; Name: "{localappdata}\Trainingsplaner\Trainingsplaner\cache"
Type: dirifempty; Name: "{localappdata}\Trainingsplaner\Trainingsplaner"
Type: dirifempty; Name: "{localappdata}\Trainingsplaner"
Type: filesandordirs; Name: "{%TEMP}\trainingsplaner-update"

[Code]
function ShouldLaunch: Boolean;
begin
  Result := ExpandConstant('{param:NOLAUNCH|0}') = '0';
end;

// Asks after the program files are gone; "Nein" is the default, so
// pressing Enter keeps the data
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  RemoveData: Boolean;
begin
  if CurUninstallStep <> usPostUninstall then
    exit;
  if UninstallSilent then
    RemoveData := ExpandConstant('{param:REMOVEDATA|0}') = '1'
  else
    RemoveData := MsgBox('Sollen auch alle Daten des Trainingsplaners gelöscht werden?' + #13#10 + #13#10 +
      'Das sind alle Sportler, Trainingspläne, Wettkämpfe und Einstellungen in' + #13#10 +
      ExpandConstant('{userappdata}\Trainingsplaner') + #13#10 + #13#10 +
      'Das kann nicht rückgängig gemacht werden. Wer die Daten behalten möchte, wählt „Nein“; ' +
      'bei einer späteren Installation sind sie dann wieder da.',
      mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES;
  if RemoveData then begin
    DelTree(ExpandConstant('{userappdata}\Trainingsplaner'), True, True, True);
    RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, 'Software\Trainingsplaner');
  end;
end;
