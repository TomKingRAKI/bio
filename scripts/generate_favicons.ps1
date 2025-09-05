param(
  [string]$Source = "awatar.jpg"
)

Add-Type -AssemblyName System.Drawing | Out-Null

if (!(Test-Path $Source)) {
  Write-Error "Nie znaleziono pliku: $Source"; exit 1
}

$img = [System.Drawing.Image]::FromFile($Source)
$w = $img.Width; $h = $img.Height
$min = [Math]::Min($w,$h)
$cropX = [int](($w - $min) / 2)
$cropY = [int](($h - $min) / 2)
$cropRect = New-Object System.Drawing.Rectangle($cropX,$cropY,$min,$min)

# Kwadratowa baza ARGB
$square = New-Object System.Drawing.Bitmap($min,$min,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g0 = [System.Drawing.Graphics]::FromImage($square)
$g0.SmoothingMode = 'HighQuality'
$g0.InterpolationMode = 'HighQualityBicubic'
$g0.PixelOffsetMode = 'HighQuality'
$g0.DrawImage($img, (New-Object System.Drawing.Rectangle(0,0,$min,$min)), $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
$g0.Dispose()
$img.Dispose()

function Save-CirclePng([System.Drawing.Bitmap]$srcSquare, [int]$size, [string]$path) {
  $dest = New-Object System.Drawing.Bitmap($size,$size,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dest)
  $g.SmoothingMode = 'HighQuality'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  $ellipse = New-Object System.Drawing.Drawing2D.GraphicsPath
  $ellipse.AddEllipse(0,0,$size,$size)
  $g.SetClip($ellipse)
  $g.DrawImage($srcSquare, 0,0, $size, $size)
  $g.ResetClip()
  $g.Dispose()
  $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/png' }
  $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::ColorDepth, 32)
  $dest.Save($path, $enc, $ep)
  $dest.Dispose()
}

Save-CirclePng $square 180 "apple-touch-icon.png"
Save-CirclePng $square 48  "favicon-48x48.png"
Save-CirclePng $square 32  "favicon-32x32.png"
Save-CirclePng $square 16  "favicon-16x16.png"

# favicon.ico z 32x32 (zachowuje przezroczystość)
$icoBmp = New-Object System.Drawing.Bitmap "favicon-32x32.png"
$icon = [System.Drawing.Icon]::FromHandle($icoBmp.GetHicon())
$fs = [System.IO.File]::Open("favicon.ico", [System.IO.FileMode]::Create)
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$icoBmp.Dispose()
$square.Dispose()

Write-Output "Wygenerowano: favicon-16x16.png, favicon-32x32.png, favicon-48x48.png, apple-touch-icon.png, favicon.ico"

