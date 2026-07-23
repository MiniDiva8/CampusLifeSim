param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot "..\..\游戏场景图片"),
    [string]$DestinationRoot = (Join-Path $PSScriptRoot "..\assets\backgrounds")
)

$ErrorActionPreference = "Stop"

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

function Copy-OriginalPhoto([string]$InputPath, [string]$OutputPath) {
    $outputDirectory = Split-Path -Parent $OutputPath
    [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    Copy-Item -LiteralPath $InputPath -Destination $OutputPath -Force

    $sourceHash = (Get-FileHash -LiteralPath $InputPath -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) {
        throw "Original photo verification failed: $InputPath"
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
        Copy-OriginalPhoto $_.FullName $outputPath
        $imported += 1
    }
}

$stressSource = Join-Path $sourcePath "4da1d68dda097bc790fe525e223bb096.jpg"
if (-not (Test-Path -LiteralPath $stressSource -PathType Leaf)) {
    throw "Missing stress effect source: $stressSource"
}
$stressDestination = Join-Path $destinationPath "effects\stress_overload.jpg"
Copy-OriginalPhoto $stressSource $stressDestination
$imported += 1

$totalBytes = (Get-ChildItem -LiteralPath $destinationPath -Recurse -File -Filter "*.jpg" | Measure-Object Length -Sum).Sum
Write-Output ("Copied and SHA-256 verified {0} original backgrounds to {1} ({2:N2} MiB)." -f $imported, $destinationPath, ($totalBytes / 1MB))
