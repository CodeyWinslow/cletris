# Linux contributor image

Build the pinned Linux development image from the repository root:

```bash
bash docker/build.sh
```

The wrapper supplies every Docker build argument from `environment/toolchain.env`; do not call `docker build` directly. On Windows, use `./docker/build.ps1`.

Run deterministic tests without installing Godot, Java, or Android tools on the cloud worker:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace cletris-dev:4.6 bash scripts/test.sh
docker run --rm -v "$PWD:/workspace" -w /workspace cletris-dev:4.6 bash scripts/verify.sh
```

An Android debug export is also supported. It writes only the ignored repository path:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace cletris-dev:4.6 bash scripts/export_android_debug.sh
```

The image contains no phone-delivery configuration. Do not mount or configure Google Drive in a cloud worker, and do not run the Windows-only publish script there.
