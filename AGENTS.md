# Cletris agent guide

This is a GDScript-only Godot project. Keep game rules deterministic and independent of rendering, input, wall-clock time, and Godot scene state.

- Use Godot `4.6.stable` and its matching export templates only.
- Add no traditional art, audio, fonts, textures, sprites, imports, or binary game content. The game draws everything procedurally at runtime.
- Do not use Git LFS, GitHub Actions, or commit generated output.
- Implement feature requests on a dedicated feature branch. Validate the branch, push it, and open a pull request for review; do not commit feature work directly to `main`.
- Before committing, run `scripts/test.ps1` and `scripts/verify.ps1`.
- For Linux/cloud contributors, use the matching `scripts/test.sh` and `scripts/verify.sh` paths or the repository Docker image. The exact portable toolchain contract is `environment/toolchain.env`; prefer `CLETRIS_*` variables over machine-wide Android variables.
- Keep generated Godot editor settings and templates in the project toolchain cache via the bootstrap `-Configure` / `--configure` command. Do not modify shared Godot settings to make this repository build.
- Android debug output belongs only at `build/android/Cletris-debug.apk` and remains ignored.
- `scripts/publish_phone_build.ps1` is the only supported phone-delivery route. It requires `CLETRIS_PHONE_BUILDS_DIR`; do not configure Google Drive or handle its credentials.
