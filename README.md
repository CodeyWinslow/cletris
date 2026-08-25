# Cletris

Cletris is an original, Android-first falling-block puzzle game built in Godot. It is designed for portrait phones and touch-first play, with procedural visuals and a deterministic GDScript rules layer kept separate from rendering and input.

The playable prototype includes all seven pieces, seeded piece sequences, movement, rotation, collision, locking, line clears, scoring, game-over handling, restart, a ghost landing preview, gesture controls, pause/resume, and a small main menu with Play and Credits. The project intentionally contains no traditional art, audio, font, texture, sprite, import, or binary game assets.

## Contributing

Use the pinned Godot, Java, and Android toolchain in [TOOLCHAIN.md](TOOLCHAIN.md). The standard workflow is to implement each feature on a branch, run the deterministic tests and repository verification, push the branch, and submit a pull request before merging to `main`. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for Windows, Linux, and cloud setup details.

The project’s phone-driven development workflow was evaluated in a 24-hour experiment. [Read the experiment report](docs/EXPERIMENT_24H_REPORT.md) for the system design, replication steps, findings, and recommendations.
