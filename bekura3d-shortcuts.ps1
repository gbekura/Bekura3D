# Two Desktop shortcuts: the app, and the update.
#
# Pure ASCII on purpose -- PowerShell 5.1 reads a BOM-less file as ANSI, so a
# Georgian literal here would mangle. The Georgian shortcut name is built from
# codepoints instead.
#
# That is only half of it. WScript.Shell is COM, and CreateShortcut takes the
# .lnk PATH through the system ANSI codepage, which on a Georgian laptop set to
# a Latin locale (1252 here) cannot hold Georgian: the path arrives as
# "?????????.lnk", "?" is illegal in a Windows filename, and Save() dies with
# FileNotFoundException. NTFS itself stores the name perfectly well. So the
# shortcut is written to an ASCII path and then renamed with Move-Item, which
# is .NET and Unicode all the way down.
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

$tmp   = Join-Path $desk 'bekura3d-update-tmp.lnk'
$final = Join-Path $desk ($upd + '.lnk')
$u = $sh.CreateShortcut($tmp)
$u.TargetPath       = Join-Path $root 'update.cmd'
$u.WorkingDirectory = $root
$u.Description      = 'Bekura3D update'
$u.Save()
if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Force }
Move-Item -LiteralPath $tmp -Destination $final -Force

Write-Host "  Desktop: Bekura3D  and  $upd"