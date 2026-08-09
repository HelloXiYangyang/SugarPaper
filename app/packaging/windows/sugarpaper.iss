; Copyright (C) 2026 HelloXiYangyang
; SPDX-License-Identifier: AGPL-3.0-or-later

; 糖纸 · SugarPaper —— Windows 安装包（Inno Setup 6）
; 用法：ISCC.exe /DMyAppVersion=0.32.0 sugarpaper.iss

#define MyAppName "糖纸 · SugarPaper"
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef MyArch
  #define MyArch "x64"
#endif
#define MyAppPublisher "HelloXiYangyang"
#define MyAppExeName "SugarPaper.exe"
#define MyAppId "{{8F6E4C9D-2B7A-4E5F-9C1D-3A4B5C6D7E8F}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\SugarPaper
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\build\windows\dist\v{#MyAppVersion}
OutputBaseFilename=SugarPaper-v{#MyAppVersion}-windows-{#MyArch}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
#if MyArch == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
