@echo off
REM  The Georgian name for install.cmd, the way update.cmd has one too. The work
REM  is in install.cmd, which is ASCII so that the elevation prompt and the
REM  console output carry no Georgian -- cmd.exe draws it as empty boxes under
REM  the default console font.
call "%~dp0install.cmd"
