# Toolchain

The authoritative version contract is [`environment/toolchain.env`](environment/toolchain.env). Every local and container toolchain must match it exactly:

- Godot `4.6.stable` (`4.6.stable.official.89cea1439`) and matching `4.6.stable` export templates
- JDK `17.0.20+8` (Java 17)
- Android command-line tools `22.0`, Platform `android-35`, Build-Tools `35.0.1`, NDK `28.1.13356709`, and CMake `3.10.2.4988404`

Godot export templates and editor configuration are required for Android export but are never committed. The Android debug keystore remains toolchain-provided; no keystore is stored in this repository.

## Project-scoped configuration

Set these values in the current shell or a local shell profile, never in tracked files:

- `CLETRIS_GODOT_BIN`: exact Godot executable
- `CLETRIS_JAVA_HOME`: exact JDK 17 home
- `CLETRIS_ANDROID_SDK_ROOT`: SDK root with the packages above
- `CLETRIS_TOOLCHAIN_CACHE`: optional external directory for isolated Godot settings and export templates

`ANDROID_SDK_ROOT` and `ANDROID_HOME` are compatibility fallbacks for the Windows scripts. They are not the preferred authority and the doctor reports their use. A `PATH` entry alone is never sufficient: Godot needs the SDK and JDK paths configured in its editor settings.

Run `scripts/bootstrap.ps1 -Configure` on Windows or `bash scripts/bootstrap.sh --configure` on Linux once after confirming the doctor. It copies already-installed matching templates into the external cache and writes an isolated Godot editor configuration there. It does not change user-wide Godot settings, system PATH, SDK installation, or shell profiles.

On Windows, use the default cache or a directory beneath `%APPDATA%` for `CLETRIS_TOOLCHAIN_CACHE`. Godot's Windows editor-path resolver can reinterpret arbitrary cache roots. Linux caches may live anywhere writable.

[`environment/local.env.example`](environment/local.env.example) provides shell-specific examples. Never commit a populated `environment/local.env`.

`CLETRIS_PHONE_BUILDS_DIR` is unrelated to building. It is local Windows-only delivery configuration and is consumed solely by `scripts/publish_phone_build.ps1`.
