# Development

Open the project in Godot 4.6 stable or run the scripts from PowerShell.

```powershell
./scripts/bootstrap.ps1
./scripts/test.ps1
./scripts/verify.ps1
./scripts/export_android_debug.ps1
./scripts/publish_phone_build.ps1
```

`bootstrap.ps1` validates the local toolchain and does not install software. `test.ps1` runs deterministic rules tests. `verify.ps1` also checks ignore policy, rejects tracked files larger than 1 MiB, and enforces a 25 MiB tracked-tree budget.

Godot 4.6 requires `textures/vram_compression/import_etc2_astc=true` for Android export, even though Cletris has no texture assets. Keep that project setting enabled. The scripts start Godot through a waiting process wrapper because direct PowerShell invocation on Windows may not reliably wait for Godot to finish.

The export script writes only `build/android/Cletris-debug.apk`. The publish script copies that file to the required `CLETRIS_PHONE_BUILDS_DIR` location as `Cletris-debug.apk` and writes `Cletris-build-info.txt` beside it. It fails without a configured, accessible destination and never configures Google Drive itself.
