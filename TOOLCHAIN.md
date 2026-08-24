# Toolchain

Cletris is pinned to **Godot `4.6.stable`** (`4.6.stable.official.89cea1439`) with the matching **Godot 4.6 stable export templates** installed in the Godot user template directory.

Required local tools:

- Git 2.35 or newer
- JDK 17
- Android SDK Platform 35, Build-Tools 35.0.1, Command-line Tools, and Platform-Tools
- Godot 4.6 stable with Android export templates

The project uses the Android package identifier `com.codeywinslow.cletris`. Debug exports use the local Android debug keystore supplied by the Android toolchain; no keystore is stored in this repository.

In Godot Editor Settings, configure both the Java SDK path and Android SDK path. These settings are what Godot uses to validate and export Android builds; do not assume a `PATH` entry or `ANDROID_HOME` selects the desired Build-Tools version. On this PC, the working SDK root is `C:\Android\Sdk` (Build-Tools 35.0.1).

Set `CLETRIS_PHONE_BUILDS_DIR` to a Drive-synced destination only when publishing a debug build to a phone. Start a new PowerShell or Codex session after changing it so the publishing process inherits the value.
