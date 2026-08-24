[CmdletBinding()]
param(
    [switch]$Configure
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\toolchain.ps1"

$toolchain = Assert-CletrisToolchain -RequireAndroid
$git = Get-Command git -ErrorAction Stop
Write-Output "Repository: $($toolchain['Root'])"
& $git.Source --version
Write-Output $toolchain['JavaVersion']
Write-Output "Godot: $(& $toolchain['Godot'] --version 2>&1 | Select-Object -First 1)"
Write-Output "Android SDK: $($toolchain['AndroidSdk'])"
Write-Output "Godot isolation cache: $(Get-CletrisCacheRoot)"

if ($Configure) {
    $templates = Initialize-CletrisExportTemplates $toolchain
    $isolation = Enable-CletrisGodotIsolation $toolchain
    Write-Output "Configured isolated Godot settings: $($isolation['Config'])"
    Write-Output "Copied matching export templates: $templates"
} else {
    Write-Output 'Doctor completed. No software, user environment variable, or shared Godot setting was modified.'
    Write-Output 'Run scripts/bootstrap.ps1 -Configure once to create isolated Godot settings and copy already-installed matching templates.'
}
