# Composites fetched raster tiles into one texture and writes it as JPEG.
#
# Called by make-satellite.sh. Kept in PowerShell rather than the headless
# Chrome trick make-ground.sh uses, because aerial imagery has to leave as JPEG
# and Chrome only screenshots PNG. System.Drawing is part of Windows, so this
# adds no dependency.
param(
  [string]$TileDir, [int]$N, [double]$OX, [double]$OY,
  [int]$Px, [int]$OutPx, [int]$Quality, [string]$Out, [string]$Ext = "jpg"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$full = New-Object System.Drawing.Bitmap ($Px), ($Px)
$g = [System.Drawing.Graphics]::FromImage($full)
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode   = 'HighQuality'
$g.Clear([System.Drawing.Color]::FromArgb(28, 34, 40))

$missing = 0
for ($i = 0; $i -le $N; $i++) {
  for ($j = 0; $j -le $N; $j++) {
    $f = Join-Path $TileDir "$($i)_$($j).$Ext"
    if (-not (Test-Path $f)) { $missing++; continue }
    try {
      $t = [System.Drawing.Image]::FromFile($f)
      # -OX/-OY shift the mosaic so the town centre lands dead centre, the same
      # way the CSS offset does in make-ground.sh.
      $g.DrawImage($t, [int]($i * 256 - $OX), [int]($j * 256 - $OY), 256, 256)
      $t.Dispose()
    } catch { $missing++ }
  }
}
$g.Dispose()

# Downsample in one step: the extent is fixed by the tile maths, so fewer
# pixels only costs resolution, never alignment with the terrain underneath.
if ($OutPx -ne $Px) {
  $small = New-Object System.Drawing.Bitmap ($OutPx), ($OutPx)
  $g2 = [System.Drawing.Graphics]::FromImage($small)
  $g2.InterpolationMode  = 'HighQualityBicubic'
  $g2.SmoothingMode      = 'HighQuality'
  $g2.PixelOffsetMode    = 'HighQuality'
  $g2.DrawImage($full, 0, 0, $OutPx, $OutPx)
  $g2.Dispose(); $full.Dispose(); $full = $small
}

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
       Where-Object { $_.MimeType -eq 'image/jpeg' }
$ps = New-Object System.Drawing.Imaging.EncoderParameters 1
$ps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
                 [System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)
$full.Save($Out, $enc, $ps)
$full.Dispose()

$kb = [math]::Round((Get-Item $Out).Length / 1KB)
Write-Output "      mosaic $OutPx px  q$Quality  $kb KB  missing=$missing"
