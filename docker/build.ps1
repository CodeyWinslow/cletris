[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\scripts\lib\toolchain.ps1"
$manifest = Get-CletrisToolchainManifest
$arguments = @(
    'build', '--tag', $(if ($env:CLETRIS_DOCKER_TAG) { $env:CLETRIS_DOCKER_TAG } else { 'cletris-dev:4.6' })
)
foreach ($key in @(
    'JDK_DOCKER_IMAGE', 'GODOT_RELEASE_TAG', 'GODOT_BUILD', 'GODOT_TEMPLATES_VERSION',
    'GODOT_LINUX_ARCHIVE', 'GODOT_TEMPLATES_ARCHIVE', 'ANDROID_COMMAND_LINE_TOOLS',
    'ANDROID_COMMAND_LINE_TOOLS_LINUX_URL', 'ANDROID_COMMAND_LINE_TOOLS_LINUX_SHA1',
    'ANDROID_PLATFORM', 'ANDROID_BUILD_TOOLS', 'ANDROID_NDK', 'ANDROID_CMAKE'
)) {
    $arguments += '--build-arg'
    $arguments += "$key=$($manifest[$key])"
}
$arguments += (Get-CletrisRepositoryRoot)
& docker @arguments
if ($LASTEXITCODE -ne 0) { throw "Docker image build failed with exit code $LASTEXITCODE." }
