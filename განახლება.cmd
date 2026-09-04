@echo off
REM ---------------------------------------------------------------------------
REM  Bekura3D update. Double-click this file.
REM
REM  The console speaks English on purpose. cmd.exe draws Georgian as empty
REM  boxes under the default console font, and a wall of boxes on a failed pull
REM  is worse than no message at all. The app's განახლება panel is in Georgian.
REM
REM  A pull is the whole update: the repository ships bekura3d.html already
REM  built, because students double-click it. There is nothing to compile here.
REM ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

echo.
echo   Bekura3D update
echo   ===============
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo   Git is not installed, or is not on PATH.
  echo   Get it from https://git-scm.com/download/win, then run this again.
  goto end
)

if not exist ".git" (
  echo   This folder is not a git clone, so there is nothing to pull.
  echo   Make one somewhere else and use that copy:
  echo.
  echo       git clone https://github.com/gbekura/Bekura3D.git
  goto end
)

REM build.sh rewrites bekura3d.html, so anyone who has run it locally has a
REM modified working tree and the pull would refuse. That file is a build
REM artefact, not anybody's work: saved models live in localStorage and in
REM bekura3d-data.js, which git ignores. Restore it, and only it.
git diff --quiet -- bekura3d.html
if errorlevel 1 (
  echo   Your bekura3d.html differs from the last release, which happens after
  echo   running build.sh here. Restoring it so the pull can go through.
  git checkout -- bekura3d.html
  echo.
)

REM Anything else modified is a real edit and stops the script rather than
REM being merged over.
for /f %%d in ('git status --porcelain --untracked-files^=no ^| find /c /v ""') do set DIRTY=%%d
if not "%DIRTY%"=="0" (
  echo   There are local changes in this folder:
  echo.
  git status --short --untracked-files=no
  echo.
  echo   Nothing has been touched. Commit or undo those first, then run this again.
  goto end
)

echo   Checking for a new version...
git pull --ff-only
if errorlevel 1 (
  echo.
  echo   The pull failed and nothing has changed.
  echo   Usually that means there is no internet, or the history has diverged.
  goto end
)

echo.
echo   Done. Close bekura3d.html and open it again.
echo   The version shown under the განახლება button should have changed.
echo   Your saved work is untouched.

:end
echo.
pause
endlocal
