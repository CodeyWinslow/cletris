[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$limitPerFile = 1MB
$treeBudget = 25MB

& "$PSScriptRoot\test.ps1"

$tracked = @(git -C $root ls-files)
$forbiddenPath = '(^|/)(\.godot|\.import|build|drive-builds|logs|\.cache)(/|$)'
$forbiddenExtension = '\.(apk|aab|keystore|jks|zip|png|jpe?g|webp|gif|mp3|ogg|wav|ttf|otf|psd|aseprite)$'
$total = [int64]0

foreach ($relative in $tracked) {
    if ($relative -match $forbiddenPath) { throw "Tracked generated or delivery path is forbidden: $relative" }
    if ($relative -match $forbiddenExtension) { throw "Tracked binary/content artifact is forbidden: $relative" }
    $item = Get-Item -LiteralPath (Join-Path $root $relative)
    if ($item.Length -gt $limitPerFile) { throw "Tracked file exceeds 1 MiB: $relative ($($item.Length) bytes)" }
    $total += $item.Length
}
if ($total -gt $treeBudget) { throw "Tracked tree exceeds 25 MiB: $total bytes" }

if (Test-Path (Join-Path $root '.gitattributes')) {
    if ((Get-Content -Raw (Join-Path $root '.gitattributes')) -match '(?i)lfs') { throw 'Git LFS configuration is forbidden.' }
}

& git -C $root diff --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace verification failed.' }

Write-Output "PASS: $($tracked.Count) tracked files, $total bytes (budget $treeBudget), no tracked file above 1 MiB."
