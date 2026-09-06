# Two Desktop shortcuts: the app, and the update.
#
# Pure ASCII on purpose -- PowerShell 5.1 reads a BOM-less file as ANSI, so a
# Georgian literal here would mangle. The Georgian shortcut name is built from
# codepoints instead.
#
# The app shortcut targets bekura3d.html, never a named browser. file://
# localStorage is per browser: point it at chrome.exe and the day the default
# differs, every student's saved work is silently gone.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$desk = [Environment]::GetFolderPath('Desktop')
$sh   = New-Object -ComObject WScript.Shell

# "?????????"
$upd = -join ([int[]](0x10D2,0x10D0,0x10DC,0x10D0,0x10EE,0x10DA,0x10D4,0x10D1,0x10D0) |
              ForEach-Object { [char]$_ })

$app = $sh.CreateShortcut((Join-Path $desk 'Bekura3D.lnk'))
$app.TargetPath       = Join-Path $root 'bekura3d.html'
$app.WorkingDirectory = $root
$app.Description      = 'Bekura3D'
$app.Save()

$u = $sh.CreateShortcut((Join-Path $desk ($upd + '.lnk')))
$u.TargetPath       = Join-Path $root 'update.cmd'
$u.WorkingDirectory = $root
$u.Description      = 'Bekura3D update'
$u.Save()

Write-Host "  Desktop: Bekura3D  and  $upd"