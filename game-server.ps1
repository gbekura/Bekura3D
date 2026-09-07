# Bekura3D game server. Started by the Georgian-named .cmd next to it.
#
# The whole multiplayer story for a classroom with no internet and nothing
# installed: PowerShell has an HTTP listener built in, so the trainer's own
# laptop is the server and the students' browsers are the clients. No Node, no
# Python, no install, no admin.
#
# It serves the game page and keeps one append-only message log per room in
# memory. Clients poll for what they have not seen. Short polling rather than
# sockets on purpose -- these games move once per turn, and a socket server in
# PowerShell is a great deal of code for no gain here.
#
# Nothing is written to disk and nothing survives the window closing. A room is
# a lobby, not a save file; the students' work lives in the planner.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
# 8830 unless the environment says otherwise. A second one on another port is
# occasionally useful for trying something without disturbing a running lesson.
$port = 8830
if ($env:BEKURA3D_PORT -match '^\d+$') { $port = [int]$env:BEKURA3D_PORT }

# The page to serve: the built one-file bundle, or the source if nobody has run
# build-game.sh here. The bundle's name is Georgian and this file is ASCII --
# PowerShell 5.1 reads a BOM-less script as ANSI, so a Georgian literal here
# would mangle, Test-Path would miss, and the server would quietly serve the
# unbuilt source instead. Built from codepoints, as bekura3d-shortcuts.ps1 does.
$bundle = -join ([int[]](0x10D7,0x10D0,0x10DB,0x10D0,0x10E8,0x10D8) |
                 ForEach-Object { [char]$_ })
$page = Join-Path $root ($bundle + '.html')
if (-not (Test-Path -LiteralPath $page)) { $page = Join-Path $root 'game.html' }
if (-not (Test-Path -LiteralPath $page)) {
  Write-Host "  No game page here. Run this from the Bekura3D folder."
  exit 1
}

# What "/" hands out. The planner is the app the class actually plays now -- all
# five games and the lobby live in it -- so the bare address a trainer writes on
# the board has to land there. It used to land on the standalone page, whose only
# remaining game is the sun duel, so a child who joined a planner host arrived in
# a different program and nothing worked.
$homePage = Join-Path $root 'bekura3d.html'
if (-not (Test-Path -LiteralPath $homePage)) { $homePage = $page }

$rooms = @{}      # room id -> append-only message log
$reg   = @{}      # room id -> the host's own announcement, plus when it last spoke

# Minimal JSON string escaping. Host names are typed by children and will contain
# quotes, backslashes and Georgian sooner or later; the Georgian is fine as UTF-8
# but the punctuation would otherwise break the reply out of its own string.
function Esc([string]$s) {
  if ($null -eq $s) { return '' }
  $s = $s -replace '\\', '\\\\'
  $s = $s -replace '"', '\"'
  $s = $s -replace "`r", '\r'
  $s = $s -replace "`n", '\n'
  $s = $s -replace "`t", '\t'
  return $s
}

# Is one already running? Double-clicking the shortcut twice, or leaving last
# lesson's window open behind another program, otherwise ends in a raw
# HttpListenerException and a stack trace -- which is not a thing to hand a
# trainer in the middle of a class. Checked before asking for administrator
# rights, so nobody is shown a Windows prompt for a server they already have.
function Test-PortBusy([int]$p) {
  try {
    $c = New-Object System.Net.Sockets.TcpClient
    $ok = $c.BeginConnect('127.0.0.1', $p, $null, $null).AsyncWaitHandle.WaitOne(400)
    $c.Close()
    return $ok
  } catch { return $false }
}
if (Test-PortBusy $port) {
  # Busy is not the same as "ours". Ask whoever is there who they are before
  # telling a trainer to go and find a window that may not exist.
  $mine = $false
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:$port/whoami" -UseBasicParsing -TimeoutSec 3
    $mine = ($r.Content -like '*"wild"*')
  } catch {}
  Write-Host ""
  Write-Host "  Bekura3D game server"
  Write-Host "  ===================="
  if ($mine) {
    Write-Host "  It is ALREADY RUNNING on this laptop -- there is another window"
    Write-Host "  open somewhere with it in. You do not need a second one."
    Write-Host ""
    Write-Host "  Use it as it is:   http://localhost:$port/"
    Write-Host "  Or close that window first, then start this again."
  } else {
    Write-Host "  Port $port on this laptop is taken by some other program, so the"
    Write-Host "  game server cannot open it."
    Write-Host ""
    Write-Host "  Close whatever is using it and start this again. To find out what"
    Write-Host "  that is, from a console:"
    Write-Host "      netstat -ano | findstr :$port"
  }
  Write-Host ""
  exit 1
}

# Reserving http://+:8830/ is an administrator's job on Windows. Without it this
# listens to itself and nothing else, which looks exactly like a working server
# right up until the moment a second laptop tries to reach it -- so ask for the
# rights once, up front, instead of starting a server that cannot do its job.
# Exit code 7 tells the .cmd that a new elevated window has the console now.
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $env:BEKURA3D_NOELEVATE) {
  try {
    # The path must carry its own quotes: Start-Process joins the array and hands
    # ShellExecute one string, so an installed copy under "C:\Program Files\..."
    # arrived as two broken arguments and BOTH windows vanished with no server.
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
      '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
      ('"' + $PSCommandPath + '"')) | Out-Null
    exit 7
  } catch {
    # They said no. Carry on -- the listener below falls back to localhost and
    # the banner explains what that means.
  }
}

$listener = New-Object System.Net.HttpListener
# + rather than localhost: the whole point is that other laptops can reach it.
# Windows normally wants an admin to reserve a wildcard prefix, so fall back to
# localhost and say so rather than dying with an unexplained access error.
$wild = $true
try {
  $listener.Prefixes.Add("http://+:$port/")
  $listener.Start()
} catch {
  $wild = $false
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$port/")
  # And if even that will not open, say what to do rather than throwing the
  # exception at whoever is standing in front of the class.
  try {
    $listener.Start()
  } catch {
    Write-Host ""
    Write-Host "  Bekura3D game server"
    Write-Host "  ===================="
    Write-Host "  Could not open port $port on this laptop."
    Write-Host ""
    Write-Host "  Almost always this means something else already has it -- most"
    Write-Host "  likely another copy of this server in a window you have forgotten."
    Write-Host "  Close it and start this again."
    Write-Host ""
    Write-Host "  Windows said:"
    Write-Host ("      " + $_.Exception.Message)
    Write-Host ""
    exit 1
  }
}

$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
         Select-Object -ExpandProperty IPAddress)

# ASCII only from here down. This is a console window, and cmd.exe under the
# default font draws Georgian as boxes or worse -- the first run of this script
# printed the two menu names as a line of mojibake. The game page is Georgian;
# this window talks to the trainer, in the same English every other .cmd here uses.
Write-Host ""
Write-Host "  Bekura3D game server"
Write-Host "  ===================="
if ($wild -and $ips.Count) {
  Write-Host "  Write ONE of these on the board for the class to open:"
  foreach ($ip in $ips) { Write-Host "      http://${ip}:$port/" }
} elseif ($wild) {
  Write-Host "  Running, but this laptop has no network address other than itself."
  Write-Host "      http://localhost:$port/"
} else {
  Write-Host "  Windows would not let this listen for the whole network, so for now"
  Write-Host "  only THIS laptop can reach it:"
  Write-Host "      http://localhost:$port/"
  Write-Host ""
  Write-Host "  For a real room, either right-click the .cmd and Run as administrator,"
  Write-Host "  or grant it once and for all from an admin console:"
  Write-Host "      netsh http add urlacl url=http://+:$port/ user=Everyone"
}
Write-Host ""
Write-Host "  In Bekura3D on every laptop:  FILE > GAME"
Write-Host "    - one of you picks a game, then OPEN A ROOM, and types a name"
Write-Host "    - everyone else picks JOIN SOMEONE and taps that name in the list"
Write-Host "  If a laptop asks for an address, give it the one above."
Write-Host "  Windows may ask once to allow this through the firewall -- say yes for"
Write-Host "  a private network."
Write-Host ""
Write-Host "  Close this window to stop the server. Nothing is written to disk."
Write-Host ""

while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  try {
    $req = $ctx.Request
    $res = $ctx.Response
    $res.Headers.Add('Cache-Control', 'no-store')
    # The planner is opened two ways: from this server, and by double-clicking a
    # copy sitting on a Desktop. The second kind has no origin of its own, so it
    # has to be allowed to ask across one. Only GET and plain-bodied POST are
    # ever sent, which needs no preflight -- this one header is the whole of it.
    $res.Headers.Add('Access-Control-Allow-Origin', '*')
    $path = $req.Url.AbsolutePath

    # Who am I, and can anyone else actually reach me? The page asks this the
    # moment somebody opens a room, so it can show the class the address to type
    # instead of making a trainer read it off a console window in English.
    if ($path -eq '/whoami') {
      $parts = @()
      foreach ($ip in $ips) { $parts += ('"' + (Esc $ip) + '"') }
      $res.ContentType = 'application/json; charset=utf-8'
      $body = '{"port":' + $port + ',"wild":' + $(if ($wild) { 'true' } else { 'false' }) +
              ',"addr":[' + ($parts -join ',') + ']}'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    # The open-room list. A host announces itself here and keeps saying so; a
    # joiner reads it to see who is waiting and which game they are running. The
    # announcement body is stored and handed back verbatim rather than rebuilt,
    # so a Georgian name never passes through a second encoder.
    if ($path -eq '/rooms') {
      if ($req.HttpMethod -eq 'POST') {
        # UTF-8 unconditionally, NOT $req.ContentEncoding: a request without a
        # charset on its Content-Type makes HttpListener fall back to the system
        # ANSI codepage, which cannot hold Georgian and turned every name into
        # a row of question marks.
        $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
        $body = $sr.ReadToEnd(); $sr.Close()
        $rm = $req.QueryString['room']
        # close=1 takes a room off the list at once. A room with both its players
        # in it is not an open room, and waiting twenty-five seconds for the
        # heartbeat to lapse means a class full of children tapping a name that
        # will never answer them.
        if ($rm -and $req.QueryString['close']) { $reg.Remove($rm) }
        elseif ($rm) { $reg[$rm] = @{ body = $body; ts = [DateTime]::UtcNow } }
        $out = '{"ok":1}'
      } else {
        # A host that has stopped saying it is there is gone: a laptop that was
        # closed mid-game would otherwise sit in the list all afternoon.
        $now = [DateTime]::UtcNow
        $parts = @()
        foreach ($k in @($reg.Keys)) {
          if (($now - $reg[$k].ts).TotalSeconds -gt 25) { $reg.Remove($k); continue }
          $parts += '{"room":"' + (Esc $k) + '","info":' + $reg[$k].body + '}'
        }
        $out = '{"rooms":[' + ($parts -join ',') + ']}'
      }
      $res.ContentType = 'application/json; charset=utf-8'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($out)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    if ($path -like '/r/*') {
      # A room. POST appends a message, GET returns everything after ?since=N.
      $room = [System.Uri]::UnescapeDataString($path.Substring(3))
      if (-not $rooms.ContainsKey($room)) { $rooms[$room] = New-Object System.Collections.ArrayList }
      $log = $rooms[$room]

      if ($req.HttpMethod -eq 'POST') {
        # UTF-8 unconditionally, NOT $req.ContentEncoding: a request without a
        # charset on its Content-Type makes HttpListener fall back to the system
        # ANSI codepage, which cannot hold Georgian and turned every name into
        # a row of question marks.
        $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
        $body = $sr.ReadToEnd(); $sr.Close()
        [void]$log.Add($body)
        $out = '{"ok":1}'
      } else {
        $since = 0
        if ($req.QueryString['since']) { [int]::TryParse($req.QueryString['since'], [ref]$since) | Out-Null }
        if ($since -lt 0) { $since = 0 }
        if ($since -gt $log.Count) { $since = $log.Count }
        $slice = @()
        if ($since -lt $log.Count) { $slice = $log.GetRange($since, $log.Count - $since) }
        # The stored bodies are already JSON, so they are spliced in as text
        # rather than re-encoded -- ConvertTo-Json would escape them into strings.
        $out = '{"n":' + $log.Count + ',"msgs":[' + ($slice -join ',') + ']}'
      }
      $res.ContentType = 'application/json; charset=utf-8'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($out)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    # The bare address goes to the planner; the standalone page keeps its own name.
    if ($path -eq '/' -or $path -eq '/index.html') {
      $bytes = [System.IO.File]::ReadAllBytes($homePage)
      $res.ContentType = 'text/html; charset=utf-8'
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }
    if ($path -like '*game*.html' -or
        $path -like '*%E1%83%97%E1%83%90%E1%83%9B%E1%83%90%E1%83%A8%E1%83%98*') {
      $bytes = [System.IO.File]::ReadAllBytes($page)
      $res.ContentType = 'text/html; charset=utf-8'
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    # Anything else that really is a file next to us -- three.min.js when the
    # unbuilt source is being served.
    # Only the handful of things a page legitimately asks for, and only from this
    # folder. This is a classroom network, and the folder is a git checkout: the
    # old guard compared the UNRESOLVED path against $root, so ".." was answered
    # by http.sys's canonicalisation rather than by anything here, and .git was
    # served to anyone who asked for it.
    $rel = [System.Uri]::UnescapeDataString($path.TrimStart('/'))
    $file = Join-Path $root $rel
    $full = $null
    try { $full = [System.IO.Path]::GetFullPath($file) } catch { $full = $null }
    $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
    $okName = ($rel -notmatch '(^|[\\/])\.') -and ($rel -notmatch '\.\.')
    if ($rel -and $okName -and $full -and
        $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $full -PathType Leaf) -and
        ($full -match '\.(html|js|css|json|png|jpg|jpeg|svg|woff2?|ttf|otf)$')) {
      $file = $full
      $bytes = [System.IO.File]::ReadAllBytes($file)
      # bekura3d.html is served from here too, so a class can open the planner
      # itself off the trainer's laptop and play across the room with nothing to
      # configure. Without the charset the Georgian comes out as mojibake.
      if ($file -like '*.html') { $res.ContentType = 'text/html; charset=utf-8' }
      elseif ($file -like '*.js')   { $res.ContentType = 'application/javascript; charset=utf-8' }
      elseif ($file -like '*.jpg') { $res.ContentType = 'image/jpeg' }
      elseif ($file -like '*.json'){ $res.ContentType = 'application/json; charset=utf-8' }
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    $res.StatusCode = 404
    $res.Close()
  } catch {
    try { $ctx.Response.StatusCode = 500; $ctx.Response.Close() } catch {}
  }
}
$listener.Stop()
