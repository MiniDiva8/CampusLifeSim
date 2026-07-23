param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot "..\..\游戏场景图片"),
    [string]$DestinationRoot = (Join-Path $PSScriptRoot "..\assets\backgrounds"),
    [int]$MaximumDimension = 1920,
    [int]$JpegQuality = 88
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$sourcePath = (Resolve-Path -LiteralPath $SourceRoot).Path
$destinationPath = [System.IO.Path]::GetFullPath($DestinationRoot)

$categoryMap = [ordered]@{
    "游戏菜单界面图片" = "menu"
    "宿舍" = "locations\dorm"
    "图书馆" = "locations\library"
    "教学楼" = "locations\teaching"
    "实验室" = "locations\lab"
    "食堂" = "locations\canteen"
    "操场" = "locations\field"
    "道路照片\白天" = "roads\day"
    "道路照片\夜晚" = "roads\night"
}

function Get-ExifOrientation([System.Drawing.Image]$Image) {
    if ($Image.PropertyIdList -contains 274) {
        return [int]$Image.GetPropertyItem(274).Value[0]
    }
    return 1
}

function Apply-ExifOrientation([System.Drawing.Image]$Image, [int]$Orientation) {
    switch ($Orientation) {
        2 { $Image.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
        3 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        4 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
        5 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
        6 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        7 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
        8 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
}

function Save-OptimizedJpeg([string]$InputPath, [string]$OutputPath) {
    $sourceImage = [System.Drawing.Image]::FromFile($InputPath)
    try {
        $orientation = Get-ExifOrientation $sourceImage
        Apply-ExifOrientation $sourceImage $orientation

        $scale = [Math]::Min(1.0, $MaximumDimension / [double][Math]::Max($sourceImage.Width, $sourceImage.Height))
        $width = [Math]::Max(1, [int][Math]::Round($sourceImage.Width * $scale))
        $height = [Math]::Max(1, [int][Math]::Round($sourceImage.Height * $scale))
        $bitmap = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Black)
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($sourceImage, 0, 0, $width, $height)
            }
            finally {
                $graphics.Dispose()
            }

            $outputDirectory = Split-Path -Parent $OutputPath
            [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
            $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                Where-Object { $_.MimeType -eq "image/jpeg" } |
                Select-Object -First 1
            $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
            try {
                $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
                    [System.Drawing.Imaging.Encoder]::Quality,
                    [long]$JpegQuality
                )
                $bitmap.Save($OutputPath, $jpegCodec, $encoderParameters)
            }
            finally {
                $encoderParameters.Dispose()
            }
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $sourceImage.Dispose()
    }
}

$imported = 0
foreach ($entry in $categoryMap.GetEnumerator()) {
    $categorySource = Join-Path $sourcePath $entry.Key
    if (-not (Test-Path -LiteralPath $categorySource -PathType Container)) {
        throw "Missing source category: $categorySource"
    }
    $categoryDestination = Join-Path $destinationPath $entry.Value
    Get-ChildItem -LiteralPath $categorySource -Recurse -File -Filter "*.jpg" | ForEach-Object {
        $relativePath = $_.FullName.Substring($categorySource.Length).TrimStart('\')
        $outputPath = Join-Path $categoryDestination $relativePath
        Save-OptimizedJpeg $_.FullName $outputPath
        $imported += 1
    }
}

$totalBytes = (Get-ChildItem -LiteralPath $destinationPath -Recurse -File | Measure-Object Length -Sum).Sum
Write-Output ("Imported {0} backgrounds to {1} ({2:N2} MB)." -f $imported, $destinationPath, ($totalBytes / 1MB))
