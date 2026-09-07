# Bekura3D machine-wide install.
#
# Called by install.cmd, which has already elevated. Puts one file where every
# account on the laptop can read it and one shortcut where every account can see
# it, so a student never has to walk into somebody else's user folder.
#
# Pure ASCII on purpose -- PowerShell 5.1 reads a BOM-less file as ANSI, so a
# Georgian literal here would mangle. Every path this writes is ASCII too, which
# is the other half of that problem: WScript.Shell is COM and takes the .lnk path
# through the system ANSI codepage, so a Georgian shortcut name has to be created
# under an ASCII name and renamed afterwards (see bekura3d-shortcuts.ps1). The
# names here are "Bekura3D", so that does not arise.
#
# Only bekura3d.html is copied. It is one self-contained file by design -- the
# 3D engine, the fonts and all three town maps are inlined -- so there is no
# install tree to keep consistent, and refreshing the shared copy after a pull is
# a single overwrite. Re-running this script IS the refresh.

$ErrorActionPreference = 'Stop'

$src = $PSScriptRoot
$app = Join-Path $src 'bekura3d.html'
if (-not (Test-Path -LiteralPath $app)) {
  Write-Host "  bekura3d.html is not next to this script. Run install.cmd from the Bekura3D folder."
  exit 1
}

# ProgramW6432 is the 64-bit Program Files even when a 32-bit PowerShell is what
# ended up running us; ProgramFiles alone would silently become the (x86) one.
$pf = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$dest = Join-Path $pf 'Bekura3D'

if (-not (Test-Path -LiteralPath $dest)) {
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

Copy-Item -LiteralPath $app -Destination (Join-Path $dest 'bekura3d.html') -Force
Write-Host "  Installed: $dest\bekura3d.html"

# The trainer's seed data, if this clone has any. Gitignored, so most do not.
$seed = Join-Path $src 'bekura3d-data.js'
if (Test-Path -LiteralPath $seed) {
  Copy-Item -LiteralPath $seed -Destination (Join-Path $dest 'bekura3d-data.js') -Force
  Write-Host "  Installed: $dest\bekura3d-data.js"
}

# The games, if this clone has them built. Installed under an ASCII name on
# purpose: WScript.Shell THROWS outright when a shortcut's TargetPath contains
# Georgian -- "Value does not fall within the expected range" -- so a .lnk can
# never point at the Georgian bundle name. The shortcut's own name is still
# Georgian; only the file it points at is not.
$gameSrc = Join-Path $src ((-join ([int[]](0x10D7,0x10D0,0x10DB,0x10D0,0x10E8,0x10D8) |
                                   ForEach-Object { [char]$_ })) + '.html')
$gameDst = Join-Path $dest 'games.html'
$haveGame = Test-Path -LiteralPath $gameSrc
if ($haveGame) {
  Copy-Item -LiteralPath $gameSrc -Destination $gameDst -Force
  Write-Host "  Installed: $gameDst"
}

# The shortcut targets the .html, never a named browser. file:// localStorage is
# per browser: point this at chrome.exe and the day the default differs, every
# student's saved work is silently gone.
$sh = New-Object -ComObject WScript.Shell

# A Georgian shortcut NAME is fine, but only if the .lnk is created under an
# ASCII path and renamed afterwards: CreateShortcut takes the path through the
# system ANSI codepage, which on a Latin-locale laptop turns Georgian into
# "?????" and then fails, because "?" is illegal in a filename. Move-Item is
# .NET and Unicode all the way down.
function New-B3DShortcut($path, $target, $desc) {
  $parent = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  $tmp = Join-Path $parent ('b3d-tmp-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.lnk')
  $s = $sh.CreateShortcut($tmp)
  $s.TargetPath       = $target
  $s.WorkingDirectory = $dest
  $s.Description      = $desc
  $s.Save()
  if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
  Move-Item -LiteralPath $tmp -Destination $path -Force
  Write-Host "  Shortcut:  $path"
}

$app = Join-Path $dest 'bekura3d.html'
$games = -join ([int[]](0x10D7,0x10D0,0x10DB,0x10D0,0x10E8,0x10D4,0x10D1,0x10D8) |
                ForEach-Object { [char]$_ })          # "თამაშები"

# Public Desktop is merged into every account's desktop by Windows, so one
# shortcut here appears for all of them, including accounts made later.
$pubDesk = Join-Path $env:PUBLIC 'Desktop'
$startMenu = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
New-B3DShortcut (Join-Path $pubDesk 'Bekura3D.lnk') $app 'Bekura3D'
New-B3DShortcut (Join-Path $startMenu 'Bekura3D.lnk') $app 'Bekura3D'
if ($haveGame) {
  New-B3DShortcut (Join-Path $pubDesk ($games + '.lnk')) $gameDst 'Bekura3D games'
  New-B3DShortcut (Join-Path $startMenu ($games + '.lnk')) $gameDst 'Bekura3D games'
} else {
  Write-Host "  (no games bundle in this copy - run build-game.sh, or pull a build that has one)"
}

Write-Host ""
Write-Host "  Every account on this laptop can now open Bekura3D from the Desktop."
