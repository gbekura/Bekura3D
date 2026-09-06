# Bekura3D protocol shim.
#
# Registered by setup.cmd as:
#   HKCU\Software\Classes\bekura3d\shell\open\command
#   powershell -NoProfile -ExecutionPolicy Bypass -File "<root>\bekura3d-update.ps1"
#
# There is deliberately no %1 in that command and no param block here.
#
# Any web page can navigate to bekura3d://anything, so nothing from the URL may
# reach a shell. Windows is documented to APPEND the target when the registered
# command line contains no %1, so assume it does: with -File and no param block
# the appended text is an unbound positional argument that lands in $args and is
# read nowhere. Point this at a .cmd instead, or switch -File to -Command, and
# that same text reaches cmd.exe's batch argument parser -- which is the
# BatBadBut class, CVE-2024-24576. Do not do either.

$ErrorActionPreference = 'Stop'
$target = Join-Path $PSScriptRoot 'update.cmd'
if (-not (Test-Path -LiteralPath $target)) { exit 1 }
Start-Process -FilePath $target -WorkingDirectory $PSScriptRoot