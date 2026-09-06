@echo off
REM ---------------------------------------------------------------------------
REM  Bekura3D setup. Run once per laptop, per Windows user. No admin, no UAC.
REM  remove.cmd undoes the registry half; the shortcuts are deleted by hand.
REM
REM    1. two Desktop shortcuts: the app, and the update
REM    2. optional: the bekura3d:// scheme, so the update button inside the
REM       app can start the updater instead of only naming the file
REM ---------------------------------------------------------------------------
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

if not exist "%ROOT%\update.cmd" (
  echo   update.cmd is not next to this file. Run it from the Bekura3D folder.
  goto end
)

echo.
echo   Bekura3D setup
echo   ==============
echo   User:   %USERNAME%
echo   Folder: %ROOT%
echo.
echo   Creating Desktop shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\bekura3d-shortcuts.ps1"
echo.

set "ANS="
set /p ANS=  Also let the update button inside the app start the updater? [y/N] 
if /i not "%ANS%"=="y" (
  echo.
  echo   Skipped. The Desktop shortcuts work on their own.
  goto end
)

REM  The registered command runs the PowerShell shim with -File and NO "%%1".
REM  Any web page can navigate to bekura3d://anything. Windows appends the URL
REM  when the command line has no %%1, so the shim takes no parameters and the
REM  appended text binds to nothing. Never point this at a .cmd, and never use
REM  -Command: either one hands that text to a shell.
echo.
echo   Registering bekura3d:// for this user...
reg add "HKCU\Software\Classes\bekura3d" /ve /t REG_SZ /d "URL:Bekura3D" /f >nul
reg add "HKCU\Software\Classes\bekura3d" /v "URL Protocol" /t REG_SZ /d "" /f >nul
reg add "HKCU\Software\Classes\bekura3d\shell\open\command" /ve /t REG_SZ /d "powershell -NoProfile -ExecutionPolicy Bypass -File \"%ROOT%\bekura3d-update.ps1\"" /f >nul

echo   Registered:
reg query "HKCU\Software\Classes\bekura3d\shell\open\command" /ve
echo.
echo   TEST IT NOW, before the workshop, in the browser that opens
echo   bekura3d.html when you double-click it:
echo.
echo     1. open bekura3d.html, press the i button, then the update button.
echo        A permission dialog should appear, then a console window.
echo     2. in the address bar type:  bekura3d://update"^&calc^&"
echo        Calculator must NOT open. If it does, run remove.cmd and use the
echo        Desktop shortcut instead.
echo.
echo   The browser asks permission every time. That is normal for a local file.

:end
echo.
pause
endlocal