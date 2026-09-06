@echo off
REM  Undoes setup.cmd. The Desktop shortcuts are deleted by hand.
setlocal
echo.
echo   Removing the bekura3d:// scheme for %USERNAME%...
reg delete "HKCU\Software\Classes\bekura3d" /f >nul 2>&1
if errorlevel 1 (echo   It was not registered.) else (echo   Removed.)
echo.
pause
endlocal