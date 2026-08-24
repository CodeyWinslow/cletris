[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Require-Command([string]$name) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $command) { throw "Required command '$name' was not found on PATH." }
    return $command.Source
}

$git = Require-Command 'git'
$java = Require-Command 'java'
$godot = Require-Command 'godot'

if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) {
    throw 'ANDROID_HOME or ANDROID_SDK_ROOT must point to an installed Android SDK.'
}
if (-not $env:ANDROID_SDK_ROOT -and $env:ANDROID_HOME) {
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}

Write-Output "Repository: $root"
& $git --version
& $java -version
& $godot --version
Write-Output "Android SDK: $env:ANDROID_SDK_ROOT"
Write-Output 'Bootstrap validation complete. No software was installed or modified.'
