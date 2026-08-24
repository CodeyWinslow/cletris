[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\toolchain.ps1"
$toolchain = Assert-CletrisToolchain
$root = $toolchain['Root']
$godot = $toolchain['Godot']
Enable-CletrisGodotIsolation $toolchain | Out-Null

$process = Start-Process -FilePath $godot -ArgumentList @('--headless', '--path', $root, '--script', 'res://tests/test_rules.gd', '--quit-after', '3') -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Godot rules tests failed with exit code $($process.ExitCode)." }
