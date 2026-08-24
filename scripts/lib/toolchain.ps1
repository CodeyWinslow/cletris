Set-StrictMode -Version Latest

function Get-CletrisRepositoryRoot {
    return (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

function Get-CletrisToolchainManifest {
    $manifestPath = Join-Path (Get-CletrisRepositoryRoot) 'environment\toolchain.env'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Toolchain manifest is missing: $manifestPath" }
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $manifestPath) {
        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith('#')) {
            $pair = $trimmed.Split('=', 2)
            if ($pair.Count -ne 2) { throw "Invalid toolchain manifest line: $line" }
            $values[$pair[0]] = $pair[1]
        }
    }
    return $values
}

function Get-CletrisCacheRoot {
    if ($env:CLETRIS_TOOLCHAIN_CACHE) { return $env:CLETRIS_TOOLCHAIN_CACHE }
    # Godot resolves its Windows editor paths from APPDATA. Keep the isolated
    # configuration beneath it so absolute paths are not reinterpreted as relative.
    if ($env:APPDATA) { return (Join-Path $env:APPDATA 'CDevToolchain') }
    return (Join-Path (Get-CletrisRepositoryRoot) '.cletris')
}

function Get-CletrisGodot {
    if ($env:CLETRIS_GODOT_BIN) {
        if (-not (Test-Path -LiteralPath $env:CLETRIS_GODOT_BIN -PathType Leaf)) { throw "CLETRIS_GODOT_BIN does not exist: $env:CLETRIS_GODOT_BIN" }
        return $env:CLETRIS_GODOT_BIN
    }
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if (-not $command) { throw 'Godot was not found. Set CLETRIS_GODOT_BIN to the Godot 4.6 executable.' }
    return $command.Source
}

function Get-CletrisJava {
    if ($env:CLETRIS_JAVA_HOME) {
        $candidate = Join-Path $env:CLETRIS_JAVA_HOME 'bin\java.exe'
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "CLETRIS_JAVA_HOME has no bin\\java.exe: $env:CLETRIS_JAVA_HOME" }
        return $candidate
    }
    $command = Get-Command java -ErrorAction SilentlyContinue
    if (-not $command) { throw 'Java was not found. Set CLETRIS_JAVA_HOME to the pinned JDK 17 installation.' }
    return $command.Source
}

function Get-CletrisAndroidSdk {
    if ($env:CLETRIS_ANDROID_SDK_ROOT) { return $env:CLETRIS_ANDROID_SDK_ROOT }
    if ($env:ANDROID_SDK_ROOT) {
        Write-Warning 'Using legacy ANDROID_SDK_ROOT fallback. Set CLETRIS_ANDROID_SDK_ROOT for a reproducible project toolchain.'
        return $env:ANDROID_SDK_ROOT
    }
    if ($env:ANDROID_HOME) {
        Write-Warning 'Using legacy ANDROID_HOME fallback. Set CLETRIS_ANDROID_SDK_ROOT for a reproducible project toolchain.'
        return $env:ANDROID_HOME
    }
    throw 'Android SDK was not configured. Set CLETRIS_ANDROID_SDK_ROOT to the SDK containing the pinned packages.'
}

function Test-CletrisAndroidSdk([string]$SdkRoot, [hashtable]$Manifest) {
    $required = @(
        'platform-tools\adb.exe',
        ("build-tools\\{0}\\aapt.exe" -f $Manifest['ANDROID_BUILD_TOOLS']),
        ("platforms\\{0}\\android.jar" -f $Manifest['ANDROID_PLATFORM']),
        'cmdline-tools\latest\bin\sdkmanager.bat',
        ("ndk\\{0}\\source.properties" -f $Manifest['ANDROID_NDK']),
        ("cmake\\{0}\\bin\\cmake.exe" -f $Manifest['ANDROID_CMAKE'])
    )
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $SdkRoot $relative) -PathType Leaf)) { throw "Android SDK is missing required file: $relative under $SdkRoot" }
    }
}

function Assert-CletrisToolchain([switch]$RequireAndroid) {
    $manifest = Get-CletrisToolchainManifest
    $godot = Get-CletrisGodot
    $godotVersion = ((& $godot --version 2>&1 | Select-Object -First 1).ToString()).Trim()
    if ($godotVersion -ne $manifest['GODOT_BUILD']) { throw "Godot must be $($manifest['GODOT_BUILD']); found $godotVersion at $godot" }
    $java = Get-CletrisJava
    $javaVersion = (& $java -version 2>&1 | Select-Object -First 1)
    if ($javaVersion -notmatch 'version "17\.') { throw "JDK 17 is required; found $javaVersion" }
    $result = @{ Root = Get-CletrisRepositoryRoot; Manifest = $manifest; Godot = $godot; Java = $java; JavaVersion = $javaVersion }
    if ($RequireAndroid) {
        $sdk = Get-CletrisAndroidSdk
        if (-not (Test-Path -LiteralPath $sdk -PathType Container)) { throw "Android SDK directory does not exist: $sdk" }
        Test-CletrisAndroidSdk $sdk $manifest
        $result['AndroidSdk'] = $sdk
    }
    return $result
}

function Enable-CletrisGodotIsolation([hashtable]$Toolchain) {
    $cache = Get-CletrisCacheRoot
    # Nested project scripts inherit the redirected APPDATA value. Persist the
    # resolved cache in this process so they do not derive a nested cache path.
    if (-not $env:CLETRIS_TOOLCHAIN_CACHE) { $env:CLETRIS_TOOLCHAIN_CACHE = $cache }
    $configRoot = Join-Path $cache 'godot-config'
    $dataRoot = Join-Path $cache 'godot-data'
    New-Item -ItemType Directory -Force -Path $configRoot, $dataRoot | Out-Null
    $env:APPDATA = $configRoot
    $settingsDirectory = Join-Path $configRoot 'Godot'
    New-Item -ItemType Directory -Force -Path $settingsDirectory | Out-Null
    if ($Toolchain.ContainsKey('AndroidSdk')) {
        $javaHome = Split-Path -Parent (Split-Path -Parent $Toolchain['Java'])
        $settings = @(
            '[gd_resource type="EditorSettings" format=3]'
            ''
            '[resource]'
            ("export/android/java_sdk_path = `"{0}`"" -f $javaHome.Replace('\', '\\'))
            ("export/android/android_sdk_path = `"{0}`"" -f $Toolchain['AndroidSdk'].Replace('\', '\\'))
        )
        Set-Content -LiteralPath (Join-Path $settingsDirectory 'editor_settings-4.tres') -Value $settings -Encoding utf8
    }
    return @{ Cache = $cache; Config = $configRoot; Data = $dataRoot }
}

function Initialize-CletrisExportTemplates([hashtable]$Toolchain) {
    $cache = Get-CletrisCacheRoot
    $destination = Join-Path $cache ("godot-config\\Godot\\export_templates\\{0}" -f $Toolchain['Manifest']['GODOT_TEMPLATES_VERSION'])
    if (Test-Path -LiteralPath $destination -PathType Container) { return $destination }
    $source = Join-Path $env:APPDATA ("Godot\\export_templates\\{0}" -f $Toolchain['Manifest']['GODOT_TEMPLATES_VERSION'])
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Matching Godot export templates are unavailable. Install $($Toolchain['Manifest']['GODOT_TEMPLATES_VERSION']) templates, then run scripts/bootstrap.ps1 -Configure."
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Recurse
    return $destination
}

function Initialize-CletrisExportTemplates([hashtable]$Toolchain) {
    $cache = Get-CletrisCacheRoot
    $destination = Join-Path $cache ("godot-config\\Godot\\export_templates\\{0}" -f $Toolchain['Manifest']['GODOT_TEMPLATES_VERSION'])
    if (Test-Path -LiteralPath $destination -PathType Container) { return $destination }
    $source = Join-Path $env:APPDATA ("Godot\\export_templates\\{0}" -f $Toolchain['Manifest']['GODOT_TEMPLATES_VERSION'])
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw "Matching Godot export templates are unavailable. Install $($Toolchain['Manifest']['GODOT_TEMPLATES_VERSION']) templates, then run scripts/bootstrap.ps1 -Configure."
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Recurse
    return $destination
}
