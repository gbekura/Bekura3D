@echo off
REM ---------------------------------------------------------------------------
REM  Undoes install.cmd: removes the shared copy and both shortcuts. Needs the
REM  same administrator rights, and asks for them the same way.
REM
REM  It does NOT touch anybody's saved work. That lives in each Windows account's
REM  own browser storage, not in the installed folder, so a student's plan
REM  survives an uninstall and is still there after a reinstall.
REM ---------------------------------------------------------------------------
setlocal

net session >nul 2>&1
if not errorlevel 1 goto elevated

echo.
echo   Asking Windows for administrator rights. A prompt will appear.
echo.
REM  via the environment, not the command line: see the note in install.cmd
set "B3DSELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:B3DSELF -Verb RunAs"
exit /b

:elevated
echo.
echo   Bekura3D uninstall
echo   ==================
echo.

set "DEST=%ProgramW6432%\Bekura3D"
if not defined ProgramW6432 set "DEST=%ProgramFiles%\Bekura3D"

if exist "%DEST%" (
  rmdir /s /q "%DEST%"
  echo   Removed: %DEST%
) else (
  echo   Not installed: %DEST%
)

if exist "%PUBLIC%\Desktop\Bekura3D.lnk" (
  del /q "%PUBLIC%\Desktop\Bekura3D.lnk"
  echo   Removed: Desktop shortcut
)
if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Bekura3D.lnk" (
  del /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Bekura3D.lnk"
  echo   Removed: Start Menu shortcut
)

echo.
echo   Saved work is untouched: it is in each account's browser storage, not here.
echo.
pause
endlocal
