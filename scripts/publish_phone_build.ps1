[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\toolchain.ps1"
$root = Get-CletrisRepositoryRoot
$apk = Join-Path $root 'build\android\Cletris-debug.apk'
$destinationDirectory = [Environment]::GetEnvironmentVariable('CLETRIS_PHONE_BUILDS_DIR', 'Process')

if ([string]::IsNullOrWhiteSpace($destinationDirectory)) {
    throw 'CLETRIS_PHONE_BUILDS_DIR is required. Set it to an accessible Drive-synced folder; no fallback destination is used.'
}
if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
    throw "CLETRIS_PHONE_BUILDS_DIR is inaccessible or not a directory: $destinationDirectory. No files were written."
}
if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) {
    throw "Expected debug APK is missing: $apk. Run scripts/export_android_debug.ps1 first."
}

$targetApk = Join-Path $destinationDirectory 'Cletris-debug.apk'
$targetInfo = Join-Path $destinationDirectory 'Cletris-build-info.txt'
$commit = (git -C $root rev-parse HEAD).Trim()
$toolchain = Assert-CletrisToolchain
$godotVersion = ((& $toolchain['Godot'] --version 2>&1 | Select-Object -First 1).ToString()).Trim()
$utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

Copy-Item -LiteralPath $apk -Destination $targetApk -Force
@(
    "Git commit: $commit"
    "UTC build time: $utc"
    "Godot version: $godotVersion"
) | Set-Content -LiteralPath $targetInfo -Encoding utf8

Write-Output "Published APK: $targetApk"
Write-Output "Published build info: $targetInfo"
