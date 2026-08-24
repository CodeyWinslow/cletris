# Cloud contribution contract

Cloud contributors must start from a clean checkout and use the repository Docker image unless the host is already provisioned with the exact values in [`environment/toolchain.env`](../environment/toolchain.env).

Required acceptance checks are:

1. `bash scripts/bootstrap.sh` reports the pinned Godot, JDK, and Android packages.
2. `bash scripts/test.sh` passes deterministic rules tests.
3. `bash scripts/verify.sh` passes source-tree, size, and Git LFS policy checks.
4. If an Android export is required, `bash scripts/export_android_debug.sh` produces only ignored `build/android/Cletris-debug.apk`.

Do not configure Google Drive, upload APKs, add credentials, install system-wide SDKs, or run the Windows phone publishing script in cloud automation. The cloud image is a contributor environment, not a delivery system.

Before opening a change for review, keep `.godot`, caches, export output, and any local environment file untracked. The same source, test, and verification commands are used on Windows and Linux.
