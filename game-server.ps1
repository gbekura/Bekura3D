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
$port = 8830

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
  $listener.Start()
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
Write-Host "  In the page: choose the NETWORK mode (third button), the same room"
Write-Host "  number on every laptop, and ONE of them picks host (first button)."
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
        if ($rm) { $reg[$rm] = @{ body = $body; ts = [DateTime]::UtcNow } }
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

    if ($path -eq '/' -or $path -eq '/index.html' -or $path -like '*game*.html' -or
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
    $rel = [System.Uri]::UnescapeDataString($path.TrimStart('/'))
    $file = Join-Path $root $rel
    if ($rel -and (Test-Path -LiteralPath $file -PathType Leaf) -and
        $file.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
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
