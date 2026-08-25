# Cletris 24-Hour Mobile-Driven Development Experiment

## Executive summary

This experiment tested whether a Godot game could be developed from a phone as the primary command and review surface, while a dedicated Windows workstation ran Codex and performed the builds. The phone supplied feature requests and conversation prompts. The workstation inspected the repository, implemented changes, ran deterministic checks, exported Android debug APKs, and published the current APK to a Google Drive-synced folder. GitHub was the durable source repository and the GitHub mobile app was the review and approval surface. The phone then downloaded the APK from Google Drive and manually playtested it.

The workflow was viable for a solo developer working in small, bounded increments. The strongest parts were the pull-request gate, deterministic rules tests, and a narrow build-delivery script. The weakest parts were the lack of automated device testing, dependence on a correctly prepared workstation, and the latency and ambiguity introduced by Drive synchronization and manual installation. The result is a practical remote-development loop, not a replacement for local device debugging.

## Experiment shape

The workflow had four deliberately separate boundaries:

1. **Mobile command surface.** The phone was used to describe product work, ask for status, approve completed work, and review the resulting pull request.
2. **Persistent workstation.** A Windows machine kept the checkout, Godot, Java, Android SDK, export templates, isolated editor cache, and Codex session. It was the only build host.
3. **GitHub review boundary.** Feature work was committed on a branch, pushed, and proposed through a pull request. The GitHub mobile app provided review and approval. Merged `main` remained the source of truth.
4. **Drive delivery boundary.** A successful Android debug export was copied by `publish_phone_build.ps1` to the configured `CLETRIS_PHONE_BUILDS_DIR`. Google Drive itself was not configured by the project or by Codex; its desktop sync was the transport to the phone.

## What was built and exercised

The repository was bootstrapped around a pinned, portable Godot contract and a pure deterministic rules layer. The current contract is Godot `4.6.stable.official.89cea1439`, matching `4.6.stable` export templates, Java `17.0.20+8`, Android platform `android-35`, build tools `35.0.1`, NDK `28.1.13356709`, CMake `3.10.2.4988404`, and Android command-line tools `22.0`. The project uses GDScript only and draws its presentation procedurally, with no committed art, audio, font, texture, import, or binary game assets.

The playable slices exercised during the experiment included:

- a board with all seven tetrominoes, deterministic seeded piece generation, movement, rotation, collision, locking, line clears, scoring, game-over detection, and restart;
- touch gestures: tap-to-rotate with left/right screen-side direction, horizontal dragging, swipe-down hard drop, and press-and-hold accelerated falling;
- a next-piece preview and ghost landing projection;
- pause/resume, a pause overlay, and a route back to the main menu that abandons the active game;
- a procedural main menu with Play and Credits actions;
- deterministic tests for collision, rotation validity, locking and clearing, scoring, game over, and seeded sequences;
- scripts that test, verify repository limits, export the ignored APK, and publish only the current test build plus build metadata.

The feature history shows the intended vertical-slice rhythm: gesture controls, pause, feature-workflow documentation, ghost piece, and app shell were each developed as reviewable changes and merged through pull requests (`#3` through `#6`, alongside the earlier bootstrap and next-preview work).

## Replication steps

### 1. Prepare the persistent workstation

Clone the GitHub repository on the build workstation and install or otherwise provide the exact versions listed in [`TOOLCHAIN.md`](../TOOLCHAIN.md) and [`environment/toolchain.env`](../environment/toolchain.env). Do not install software or change system-wide settings merely because the project can use them; confirm the versions first.

On Windows, a project-scoped PowerShell session can be prepared as follows (adapt paths to the workstation):

```powershell
Set-Location 'D:\Projects\GameDev\Godot\cletris'
$env:CLETRIS_GODOT_BIN = 'D:\Godot\Engine4_6\godot.exe'
$env:CLETRIS_JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:CLETRIS_ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:CLETRIS_TOOLCHAIN_CACHE = "$env:APPDATA\CDevToolchain"
./scripts/bootstrap.ps1
./scripts/bootstrap.ps1 -Configure
```

The first command is a doctor; the configure form prepares an isolated Godot editor cache and matching templates without changing shared Godot settings, PATH, Android SDK installation, or shell profiles. For phone delivery, set the local-only destination separately:

```powershell
$env:CLETRIS_PHONE_BUILDS_DIR = 'G:\My Drive\Cletris Builds'
```

This variable is a delivery destination, not a toolchain input. Never put credentials in the repository and never ask the project scripts to configure Google Drive. A Linux/cloud contributor can use the matching `scripts/bootstrap.sh`, `scripts/test.sh`, and `scripts/verify.sh` paths or the repository Docker image; that environment has no phone-publishing route.

### 2. Implement a feature

Keep `main` current and create a dedicated branch for each bounded request:

```powershell
git switch main
git pull --ff-only origin main
git switch -c codex/<short-feature-name>
```

Keep rules deterministic and independent of rendering, input, wall-clock time, and Godot scene state. Add or update deterministic tests with the feature. Run the project checks before committing:

```powershell
./scripts/test.ps1
./scripts/verify.ps1
```

The verify script enforces the tracked-file size and total tracked-tree budgets and catches generated or forbidden content. Exported output belongs only at the ignored path `build/android/Cletris-debug.apk`.

### 3. Review and merge

Commit only source, tests, configuration, scripts, and documentation. Push the branch and open a pull request:

```powershell
git add <changed-files>
git commit -m "Describe the feature"
git push -u origin codex/<short-feature-name>
```

Review the diff and validation results in the GitHub mobile app. If changes are requested, update the same branch and PR. Merge only after approval. Then update local `main` before producing a phone build:

```powershell
git switch main
git pull --ff-only origin main
./scripts/test.ps1
./scripts/verify.ps1
```

### 4. Export, publish, and test on the phone

Export the debug APK and publish it through the one supported route:

```powershell
./scripts/export_android_debug.ps1
./scripts/publish_phone_build.ps1
```

Publishing fails clearly, and writes nowhere, when `CLETRIS_PHONE_BUILDS_DIR` is missing or inaccessible. When configured, it replaces only `Cletris-debug.apk` in that destination and writes `Cletris-build-info.txt` beside it with the Git commit, UTC build time, and Godot version. Wait for the desktop Drive client to synchronize, download the APK in the Google Drive app, install it, and manually exercise the requested behavior. Manual phone testing is intentionally not represented as automated validation.

## Important characteristics

- **GitHub is the durable source of truth.** The workstation checkout and the Drive copy are disposable working state; merged source and review history live in GitHub.
- **The PR is a safety boundary.** It separates “implemented on a remote machine” from “accepted into the playable mainline” and gives a phone-sized review workflow a useful checkpoint.
- **Determinism reduces remote iteration cost.** Rules tests cover most correctness without requiring the phone, while the phone concentrates on touch feel, layout, lifecycle, and rendering.
- **Procedural presentation is transportable.** Avoiding imported assets kept commits small, made cloud checkouts straightforward, and removed an entire class of missing-file and binary-review failures.
- **The toolchain is explicit but host-dependent.** Exact versions and scripts make setup repeatable, but Android SDK/JDK/Godot installation and permissions still have to exist on the workstation or container.
- **Drive is intentionally a narrow delivery channel.** The project knows only a destination directory and build metadata; it does not know about accounts, credentials, or upload APIs.

## Findings and analysis

### What worked well

The phone was sufficient for high-level direction and acceptance decisions. Requests such as gesture input, pause, ghost projection, and an app shell could be expressed clearly without a desktop editor. Each feature stayed small enough for Codex to implement, test, and explain in one iteration. The feature-branch/PR sequence also preserved user control: implementation happened remotely, but acceptance happened in the GitHub mobile app before `main` was rebuilt.

The deterministic rules/presentation split paid off. Collision, rotation, lock, clear, score, game-over, and seeded-sequence regressions were testable headlessly. That made the APK a delivery artifact for interaction testing rather than the only place correctness could be established. The build-info file added useful provenance when several APKs existed in the Drive folder.

### Friction and failure modes

There was no automated device loop. Gesture feel, screen-size layout, Android lifecycle behavior, installation permissions, and the final rendered result still required the physical phone. A successful export therefore did not prove a successful play session.

Environment scope mattered. User/process variables, Godot editor settings, Android SDK roots, and the isolated cache had to be made visible to the process that invoked Godot. The Windows Godot path resolver also made cache placement non-obvious; keeping the cache under the normal Windows application-data area avoided the nested-cache failure discovered during real export. These are setup concerns worth checking before feature work begins.

Android export output was verbose and included non-fatal warnings (for example, a missing project icon). Separating fatal exit status from warning text prevented wasted debugging time. The absence of the GitHub CLI was not a blocker because the GitHub connector could create the PR, but it is another host capability that should be documented rather than assumed. Finally, Drive synchronization added a variable delay between “published” and “available on the phone.”

### Overall assessment

For a solo developer or small team, this is a practical remote development loop when requests are bounded, the workstation is persistent, and manual phone testing is acceptable. It improves the economics of intermittent mobile input: the phone can direct and approve work without carrying the editor or SDK. It is less suitable for diagnosing subtle touch behavior, Android lifecycle bugs, performance regressions, or device-specific rendering without an additional local/remote device-debugging path.

## Recommendations for the next iteration

1. Keep the branch/PR gate and the deterministic test suite as non-negotiable workflow contracts.
2. Add a short manual phone checklist to each feature PR for gestures, pause/menu transitions, orientation, and restart behavior.
3. Consider adding APK size and a checksum to `Cletris-build-info.txt` so a phone tester can confirm which file arrived through Drive.
4. Measure export time and Drive propagation time separately; they are different sources of feedback latency.
5. Keep the Linux Docker/native setup aligned with the same `environment/toolchain.env` contract so cloud contributors can reproduce source-level work without touching the Windows delivery path.
6. Preserve the rule that only the publisher writes to the configured phone-build folder and that no build artifact, credential, keystore, cache, or Drive file enters Git.
