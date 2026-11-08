; Windows installer (Inno Setup 6 or 7), built by the nightly workflow
; (saved as UTF-8 with BOM, so the compiler reads the umlauts correctly):
;
;   iscc /O<output dir> /DAppVersion=0.2.0 /DAppFiles=<deployed app folder> trainingsplaner.iss
;
; It installs into the fixed program folder, without administrator rights
; for the current user (%LOCALAPPDATA%\Programs\Trainingsplaner) or, chosen
; in a dialog, for all users (Program Files). Two checkboxes (both
; ticked) add a Start menu entry and a desktop shortcut. It registers an
; uninstaller in Windows' list of apps.
;
; The training data lives elsewhere, in %APPDATA%\Trainingsplaner (the
; database) and the registry (HKCU\Software\Trainingsplaner, settings).
; Updates never touch it; the uninstaller offers a checkbox to delete it
; too (unticked). Silently it keeps it, unless given /REMOVEDATA=1.
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

var
  RemoveData: Boolean;

// A small window with an unticked checkbox; closing it keeps the data
procedure AskAboutData;
var
  Form: TSetupForm;
  Info: TNewStaticText;
  Box: TNewCheckBox;
  Button: TNewButton;
begin
  // The form's size moved into the call with Inno Setup 6.6.0
#if Ver >= EncodeVer(6,6,0)
  Form := CreateCustomForm(440, 160, False, False);
#else
  Form := CreateCustomForm;
  Form.ClientWidth := ScaleX(440);
  Form.ClientHeight := ScaleY(160);
#endif
  try
    Form.Caption := 'Trainingsplaner deinstallieren';
    Form.Position := poScreenCenter;

    Info := TNewStaticText.Create(Form);
    Info.Parent := Form;
    Info.Left := ScaleX(16);
    Info.Top := ScaleY(16);
    Info.Width := Form.ClientWidth - ScaleX(32);
    Info.WordWrap := True;
    Info.Caption := 'Ihre Daten (Sportler, Trainingspläne, Wettkämpfe und Einstellungen) ' +
      'liegen getrennt vom Programm. Normalerweise bleiben sie erhalten, damit eine ' +
      'spätere Installation sie wieder vorfindet.';

    Box := TNewCheckBox.Create(Form);
    Box.Parent := Form;
    Box.Left := ScaleX(16);
    Box.Top := ScaleY(82);
    Box.Width := Form.ClientWidth - ScaleX(32);
    Box.Height := ScaleY(20);
    Box.Caption := 'Auch alle Daten löschen (kann nicht rückgängig gemacht werden)';
    Box.Checked := False;

    Button := TNewButton.Create(Form);
    Button.Parent := Form;
    Button.Width := ScaleX(90);
    Button.Height := ScaleY(25);
    Button.Left := Form.ClientWidth - Button.Width - ScaleX(16);
    Button.Top := Form.ClientHeight - Button.Height - ScaleY(14);
    Button.Caption := 'Weiter';
    Button.ModalResult := mrOk;
    Button.Default := True;

    Form.ActiveControl := Button;
    RemoveData := (Form.ShowModal = mrOk) and Box.Checked;
  finally
    Form.Free;
  end;
end;

// Asked once the user has confirmed uninstalling, deleted after the
// program files are gone. Silently the data stays unless /REMOVEDATA=1.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then begin
    if UninstallSilent then
      RemoveData := ExpandConstant('{param:REMOVEDATA|0}') = '1'
    else
      AskAboutData;
  end;
  if (CurUninstallStep = usPostUninstall) and RemoveData then begin
    DelTree(ExpandConstant('{userappdata}\Trainingsplaner'), True, True, True);
    RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, 'Software\Trainingsplaner');
  end;
end;
