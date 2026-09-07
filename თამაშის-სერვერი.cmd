@echo off
REM ---------------------------------------------------------------------------
REM  Bekura3D game server. The trainer runs this; the class joins from their
REM  browsers. No install, no internet, and no admin for the common case.
REM
REM  It prints the address to write on the board. Everyone opens it, picks the
REM  network mode and the same room number, and one of them picks host.
REM
REM  ASCII on purpose, like every other .cmd here: cmd.exe draws Georgian as
REM  empty boxes under the default console font. The game page itself is
REM  Georgian; this window is not.
REM
REM  Close the window to stop it. Nothing is written to disk.
REM ---------------------------------------------------------------------------
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0game-server.ps1"
echo.
pause
endlocal
