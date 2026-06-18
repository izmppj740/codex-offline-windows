Unicode true
!include LogicLib.nsh
!include MUI2.nsh
!include nsDialogs.nsh
!include WinMessages.nsh
Name "CODEX 离线安装包"
!ifndef SETUP_OUTFILE
!define SETUP_OUTFILE "codex-offline-windows-x64-0.135.0-setup.exe"
!endif
OutFile "${SETUP_OUTFILE}"
InstallDir "$LOCALAPPDATA\OpenAI"
Caption "CODEX 离线安装包"
UninstallCaption "卸载 CODEX 离线安装包"
Icon "installer-assets\codex.ico"
UninstallIcon "installer-assets\codex.ico"
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show
SetCompress off
AutoCloseWindow false

!define PAYLOAD_ARCHIVE "codex-offline-windows-x64-0.135.0-full.tar.gz"
!define PAYLOAD_DIR "codex-offline-windows-x64-0.135.0"
!define DESKTOP_EXE "desktop-expanded\OpenAI.Codex_26.602.9276.0_x64__2p2nqsd0c76g0\app\Codex.exe"
!define CLI_CMD "cli-native\codex.cmd"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexOfflineFull"
!define AD_URL "https://aiopentool.com/"
!define TUTORIAL_URL "https://aiopentool.com/questions/10010000000000002"
!define VC_REDIST_X64 "vc_redist.x64.exe"
!define CODEX_DESKTOP_SHORTCUT "CODEX 离线桌面版.lnk"
!define CODEX_CLI_SHORTCUT "CODEX 命令行.lnk"
!define SITE_SHORTCUT "AI保姆站.url"
!define SITE_ICON "ai-baomu.ico"

!define MUI_ABORTWARNING
Page custom AdPageCreate AdPageLeave

!define MUI_PAGE_HEADER_TEXT "第二步：选择安装位置"
!define MUI_PAGE_HEADER_SUBTEXT "请选择 CODEX 离线安装包释放到本机的位置"
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_PAGE_HEADER_TEXT "第三步：安装 CODEX"
!define MUI_PAGE_HEADER_SUBTEXT "正在释放 CODEX 桌面版和命令行工具"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "第四步：安装成功"
!define MUI_INSTFILESPAGE_FINISHHEADER_SUBTEXT "CODEX 已经安装完成，请点击下一步查看完成信息"
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "第四步：安装成功"
!define MUI_FINISHPAGE_TEXT "已经安装 CODEX 完成。$\r$\n$\r$\n桌面入口：CODEX 离线桌面版$\r$\n命令行：新开终端后运行 codex --version$\r$\n网站入口：桌面上的 AI保姆站"
!define MUI_FINISHPAGE_LINK "访问我：https://aiopentool.com/"
!define MUI_FINISHPAGE_LINK_LOCATION "${AD_URL}"
!define MUI_FINISHPAGE_BUTTON "完成"
!insertmacro MUI_PAGE_FINISH

!define MUI_PAGE_HEADER_TEXT "卸载第一步：确认卸载"
!define MUI_PAGE_HEADER_SUBTEXT "确认是否从本机移除 CODEX 离线安装包"
!insertmacro MUI_UNPAGE_CONFIRM

!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_PAGE_HEADER_TEXT "卸载第二步：执行卸载"
!define MUI_PAGE_HEADER_SUBTEXT "正在移除 CODEX 离线安装包和快捷方式"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "卸载第三步：卸载完成"
!define MUI_INSTFILESPAGE_FINISHHEADER_SUBTEXT "CODEX 离线安装包已经从本机移除"
!insertmacro MUI_UNPAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "卸载第三步：卸载完成"
!define MUI_FINISHPAGE_TEXT "CODEX 离线安装包已经卸载完成。$\r$\n$\r$\n桌面快捷方式、PATH 和卸载注册表项已清理。"
!define MUI_FINISHPAGE_BUTTON "完成"
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "SimpChinese"

Function OpenAdUrl
  ExecShell "open" "${AD_URL}"
FunctionEnd

Function FindTar
  StrCpy $0 "$WINDIR\Sysnative\tar.exe"
  IfFileExists "$0" findtar_done
  StrCpy $0 "$WINDIR\System32\tar.exe"
  IfFileExists "$0" findtar_done
  StrCpy $0 "tar.exe"
findtar_done:
FunctionEnd

Function IsVcRedistX64Installed
  StrCpy $R0 "0"
  SetRegView 64
  ClearErrors
  ReadRegDWORD $R1 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64" "Installed"
  IfErrors vc_check_done
  StrCmp $R1 1 vc_check_installed vc_check_done
vc_check_installed:
  StrCpy $R0 "1"
vc_check_done:
  SetRegView 32
  Push $R0
FunctionEnd

Function EnsureVcRedistX64
  DetailPrint "检测 Microsoft Visual C++ 2015-2022 x64 运行库"
  Call IsVcRedistX64Installed
  Pop $R0
  StrCmp $R0 "1" vc_runtime_installed

  MessageBox MB_ICONINFORMATION "安装 CODEX 需要 Microsoft Visual C++ 2015-2022 x64 运行库。$\r$\n$\r$\n接下来会打开 Microsoft 运行库安装程序，请按提示完成安装。"
  SetOutPath "$PLUGINSDIR"
  File /oname=${VC_REDIST_X64} "installer-assets\${VC_REDIST_X64}"
  IfSilent vc_runtime_silent vc_runtime_normal
vc_runtime_silent:
  nsExec::ExecToLog '"$PLUGINSDIR\${VC_REDIST_X64}" /install /quiet /norestart'
  Pop $R1
  Goto vc_runtime_check_result
vc_runtime_normal:
  ExecWait '"$PLUGINSDIR\${VC_REDIST_X64}" /install /norestart' $R1
vc_runtime_check_result:
  StrCmp $R1 0 vc_runtime_installed_after
  StrCmp $R1 3010 vc_runtime_installed_after
  StrCmp $R1 1638 vc_runtime_installed_after
  MessageBox MB_ICONSTOP "Microsoft Visual C++ 运行库安装失败或已取消。$\r$\n$\r$\n退出码：$R1"
  Abort
vc_runtime_installed_after:
  DetailPrint "Microsoft Visual C++ 运行库已就绪"
  Return

vc_runtime_installed:
  DetailPrint "Microsoft Visual C++ 2015-2022 x64 运行库已安装"
FunctionEnd

Function AdPageCreate
  !insertmacro MUI_HEADER_TEXT "第一步：安装包说明" "CODEX 离线安装包 / 制作方：aiopentool"

  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  CreateFont $1 "Microsoft YaHei UI" 18 700
  CreateFont $2 "Microsoft YaHei UI" 11 500

  ${NSD_CreateLabel} 0 0u 100% 22u "CODEX 离线安装包"
  Pop $3
  SendMessage $3 ${WM_SETFONT} $1 1

  ${NSD_CreateLabel} 0 28u 100% 16u "制作方：aiopentool"
  Pop $4
  SendMessage $4 ${WM_SETFONT} $2 1

  ${NSD_CreateLabel} 0 52u 100% 18u "AI 小白 快乐营"
  Pop $5
  SendMessage $5 ${WM_SETFONT} $2 1

  ${NSD_CreateLabel} 0 74u 100% 18u "手把手教你制作第一个 APP，改变世界。"
  Pop $6

  ${NSD_CreateLabel} 0 104u 44u 16u "访问我："
  Pop $7

  ${NSD_CreateLink} 44u 104u 180u 16u "${AD_URL}"
  Pop $8
  ${NSD_OnClick} $8 OpenAdUrl

  nsDialogs::Show
FunctionEnd

Function AdPageLeave
FunctionEnd

Section "Install"
  InitPluginsDir
  Call EnsureVcRedistX64

  SetOutPath "$PLUGINSDIR"
  File /oname=codex-full.tar.gz "${PAYLOAD_ARCHIVE}"

  SetOutPath "$INSTDIR"
  Call FindTar
  DetailPrint "Extracting Codex payload to $INSTDIR"
  nsExec::ExecToLog '"$0" -xzf "$PLUGINSDIR\codex-full.tar.gz" -C "$INSTDIR"'
  Pop $1
  ${If} $1 != 0
    MessageBox MB_ICONSTOP "无法释放 CODEX 离线包。tar.exe 退出码：$1"
    Abort
  ${EndIf}

  StrCpy $2 "$INSTDIR\${PAYLOAD_DIR}"
  StrCpy $3 "$2\${DESKTOP_EXE}"
  StrCpy $4 "$2\${CLI_CMD}"

  IfFileExists "$3" desktop_ok
    MessageBox MB_ICONSTOP "释放后没有找到 CODEX 桌面程序：$3"
    Abort
desktop_ok:
  IfFileExists "$4" cli_ok
    MessageBox MB_ICONSTOP "释放后没有找到 CODEX 命令行程序：$4"
    Abort
cli_ok:

  CreateShortcut "$SMPROGRAMS\${CODEX_DESKTOP_SHORTCUT}" "$3" "" "$3" 0
  CreateShortcut "$DESKTOP\${CODEX_DESKTOP_SHORTCUT}" "$3" "" "$3" 0
  CreateShortcut "$SMPROGRAMS\${CODEX_CLI_SHORTCUT}" "$SYSDIR\cmd.exe" '/k ""$4" --version & echo. & echo Use: codex"' "$4" 0
  SetOutPath "$2\assets"
  File /oname=${SITE_ICON} "installer-assets\ai-baomu.ico"
  Delete "$DESKTOP\${SITE_SHORTCUT}"
  WriteINIStr "$DESKTOP\${SITE_SHORTCUT}" "InternetShortcut" "URL" "${AD_URL}"
  WriteINIStr "$DESKTOP\${SITE_SHORTCUT}" "InternetShortcut" "IconFile" "$2\assets\${SITE_ICON}"
  WriteINIStr "$DESKTOP\${SITE_SHORTCUT}" "InternetShortcut" "IconIndex" "0"

  DetailPrint "Adding Codex native CLI to current user PATH"
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$2\add-user-path.ps1"'

  WriteUninstaller "$2\Uninstall.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "CODEX 离线安装包"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "0.135.0 / Desktop 26.602.9276.0"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "aiopentool"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$2"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$2\Uninstall.exe"'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1

  IfSilent done
  MessageBox MB_YESNO|MB_DEFBUTTON2|MB_ICONQUESTION "已经安装 CODEX 完成。$\r$\n$\r$\n有注册教程，是否立刻查看？" IDNO done
  ExecShell "open" "${TUTORIAL_URL}"
done:
SectionEnd

Section "Uninstall"
  ReadRegStr $2 HKCU "${UNINSTALL_KEY}" "InstallLocation"
  ${If} $2 == ""
    StrCpy $2 "$EXEDIR"
  ${EndIf}
  ${IfNot} ${FileExists} "$2\${CLI_CMD}"
    ${If} ${FileExists} "$LOCALAPPDATA\OpenAI\${PAYLOAD_DIR}\${CLI_CMD}"
      StrCpy $2 "$LOCALAPPDATA\OpenAI\${PAYLOAD_DIR}"
    ${EndIf}
  ${EndIf}

  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$2\remove-user-path.ps1"'
  Delete "$SMPROGRAMS\${CODEX_DESKTOP_SHORTCUT}"
  Delete "$DESKTOP\${CODEX_DESKTOP_SHORTCUT}"
  Delete "$SMPROGRAMS\${CODEX_CLI_SHORTCUT}"
  Delete "$DESKTOP\${SITE_SHORTCUT}"
  Delete "$SMPROGRAMS\Codex Offline Expanded.lnk"
  Delete "$DESKTOP\Codex Offline Expanded.lnk"
  Delete "$SMPROGRAMS\Codex CLI Prompt.lnk"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  RMDir /r "$2"
  ${If} ${FileExists} "$2\*.*"
    StrCpy $5 "$TEMP\codex-offline-cleanup.cmd"
    FileOpen $6 "$5" w
    FileWrite $6 '@echo off$\r$\n'
    FileWrite $6 'timeout /t 2 /nobreak >nul 2>nul$\r$\n'
    FileWrite $6 'set "TARGET=$2"$\r$\n'
    FileWrite $6 'set "EMPTY=%TEMP%\codex-empty-%RANDOM%%RANDOM%"$\r$\n'
    FileWrite $6 'mkdir "%EMPTY%" >nul 2>nul$\r$\n'
    FileWrite $6 'robocopy "%EMPTY%" "%TARGET%" /MIR /R:0 /W:0 /NFL /NDL /NP >nul 2>nul$\r$\n'
    FileWrite $6 'rmdir /s /q "%EMPTY%" >nul 2>nul$\r$\n'
    FileWrite $6 'rmdir /s /q "%TARGET%" >nul 2>nul$\r$\n'
    FileWrite $6 'del "%~f0" >nul 2>nul$\r$\n'
    FileClose $6
    Exec '"$SYSDIR\cmd.exe" /c "$5"'
  ${EndIf}
SectionEnd
