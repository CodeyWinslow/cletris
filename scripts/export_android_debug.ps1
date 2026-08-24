[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root 'build\android\Cletris-debug.apk'
$godot = (Get-Command godot -ErrorAction Stop).Source

if (-not $env:ANDROID_SDK_ROOT -and $env:ANDROID_HOME) {
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}
if (-not $env:ANDROID_SDK_ROOT) { throw 'ANDROID_HOME or ANDROID_SDK_ROOT is required for Android export.' }

& "$PSScriptRoot\verify.ps1"
if ($LASTEXITCODE -ne 0) { throw 'Verification failed; Android export was not attempted.' }

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
$arguments = @('--headless', '--path', $root, '--export-debug', '"Android Debug"', ('"' + $output + '"'))
$process = Start-Process -FilePath $godot -ArgumentList $arguments -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Godot Android debug export failed with exit code $($process.ExitCode)." }
if (-not (Test-Path -LiteralPath $output)) { throw "Godot completed without creating expected APK: $output" }
Write-Output "APK exported: $output"
