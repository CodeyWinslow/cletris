# Architecture

`scripts/core/cletris_rules.gd` is the pure deterministic rules layer. It owns board state, piece source state, collision, rotation validation, locking, line clearing, score calculation, and game-over decisions. It is a `RefCounted` object with no nodes, drawing, input events, timers, files, or wall-clock reads.

`scripts/main.gd` is the Godot adapter. It reads touch/keyboard input, advances gravity with frame time, and procedurally draws the board and controls. It delegates every game-state decision to `CletrisRules`.

`tests/test_rules.gd` drives the rules object headlessly. It contains deterministic checks for seeded sequences, collision, rotation, locking/clearing, scoring, and game over.

```
Input + frame time -> Main (presentation) -> CletrisRules (deterministic state)
                                      -> procedural CanvasItem drawing
Headless tests -----------------------> CletrisRules
```
