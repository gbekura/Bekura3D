@echo off
REM ---------------------------------------------------------------------------
REM  Bekura3D install, for a shared laptop. Run this ONCE per machine.
REM
REM  Puts bekura3d.html in Program Files and a shortcut on the Desktop that every
REM  account sees. A student then double-clicks one icon instead of walking into
REM  a trainer's Users\<name>\Documents\GitHub folder to find a file.
REM
REM  This needs administrator rights and will ask for them. It has to: the
REM  Public Desktop and Program Files are the two places Windows shares between
REM  accounts, and both are closed to a standard user by design. That is the
REM  whole reason an all-users install cannot be done quietly the way setup.cmd
REM  is. If you would rather not elevate, setup.cmd still does a per-user setup
REM  with no admin at all.
REM
REM  Re-run this after every update: it overwrites the shared copy. uninstall.cmd
REM  undoes it.
REM ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0bekura3d.html" (
  echo.
  echo   bekura3d.html is not next to this file. Run install.cmd from the
  echo   Bekura3D folder.
  echo.
  pause
  exit /b 1
)

REM  Already elevated? net session only succeeds for an administrator.
net session >nul 2>&1
if not errorlevel 1 goto elevated

echo.
echo   Bekura3D install
echo   ================
echo   Asking Windows for administrator rights. A prompt will appear.
echo   Nothing has been changed yet.
echo.
REM  The path travels in an environment variable, not in the command line: a
REM  clone folder containing a quote or an ampersand would otherwise break out of
REM  the -Command string. No arguments are passed across the elevation either --
REM  Start-Process would hand them to a fresh cmd.exe, and a batch file's
REM  argument parser is the BatBadBut hazard (CVE-2024-24576).
set "B3DSELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:B3DSELF -Verb RunAs"
exit /b

:elevated
echo.
echo   Bekura3D install
echo   ================
echo   From: %~dp0
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bekura3d-install.ps1"
if errorlevel 1 (
  echo.
  echo   Install failed. Nothing was left half-done: the copy is one file and
  echo   the shortcuts are written after it.
)
echo.
echo   Saved work is not affected. It lives in the browser's own storage, per
echo   Windows account, and moving which folder the page is opened from does
echo   not touch it.
echo.
pause
endlocal
