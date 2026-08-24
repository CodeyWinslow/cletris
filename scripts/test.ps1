[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = (Get-Command godot -ErrorAction Stop).Source

$process = Start-Process -FilePath $godot -ArgumentList @('--headless', '--path', $root, '--script', 'res://tests/test_rules.gd', '--quit-after', '3') -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Godot rules tests failed with exit code $($process.ExitCode)." }
