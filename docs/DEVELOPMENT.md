# Development

Cletris has a deterministic GDScript rules layer and a procedural Godot presentation. Use Godot `4.6.stable` only; see [TOOLCHAIN.md](../TOOLCHAIN.md) for every exact version.

## Windows local workflow

In a PowerShell session, set the project-scoped values shown in [`environment/local.env.example`](../environment/local.env.example), then run:

```powershell
./scripts/bootstrap.ps1
./scripts/bootstrap.ps1 -Configure # one-time isolated Godot configuration
./scripts/test.ps1
./scripts/verify.ps1
./scripts/export_android_debug.ps1
```

The doctor only inspects software. `-Configure` creates an external cache and copies your already-installed matching templates into it; it does not install or reconfigure Android, Java, PATH, or shared Godot settings. On Windows, keep `CLETRIS_TOOLCHAIN_CACHE` beneath `%APPDATA%` (the default does this). The scripts start Godot through a waiting process wrapper because direct PowerShell invocation on Windows does not reliably wait for every Godot process.

`scripts/export_android_debug.ps1` writes only `build/android/Cletris-debug.apk`. If a local phone test is wanted, run `scripts/publish_phone_build.ps1` afterward. It requires an accessible `CLETRIS_PHONE_BUILDS_DIR`, replaces only `Cletris-debug.apk` there, and writes build metadata beside it. It never configures Google Drive. Manual phone testing remains manual.

## Linux and cloud workflow

The recommended cloud environment is the pinned repository [`Dockerfile`](../Dockerfile). Build and run it using [docker/README.md](../docker/README.md). The container sets project-scoped paths, has no credentials, and has no phone publishing route.

For a native Linux environment, set the same `CLETRIS_*` variables, run `bash scripts/bootstrap.sh`, then `bash scripts/bootstrap.sh --configure`. Use `bash scripts/test.sh`, `bash scripts/verify.sh`, and `bash scripts/export_android_debug.sh` thereafter.

## Editor behavior

The repository commits project settings and the Android export preset, but not Godot's mutable editor state. The bootstrap configuration places the generated editor settings and templates under `CLETRIS_TOOLCHAIN_CACHE` (or the platform cache default), so Windows and Linux agents do not overwrite each other's user profile. `.editorconfig` provides neutral whitespace rules for editors; do not commit editor workspace settings.

Godot 4.6 requires `textures/vram_compression/import_etc2_astc=true` for Android export, even though Cletris has no texture assets. Keep that project setting enabled.
