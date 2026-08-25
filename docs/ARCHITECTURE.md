# Architecture

`scripts/core/cletris_rules.gd` is the pure deterministic rules layer. It owns board state, piece source state, the queued next piece, collision, rotation validation, locking, line clearing, score calculation, and game-over decisions. It is a `RefCounted` object with no nodes, drawing, input events, timers, files, or wall-clock reads.

`scripts/main.gd` is the Godot adapter and app shell. It owns the main-menu, game, credits, and presentation-scoped pause states; routes menu/game input; advances gravity with frame time only while playing; and procedurally draws the board, ghost landing projection, next-piece preview, menu controls, pause controls, and overlays. Returning to the main menu discards the current `CletrisRules` instance. It delegates every game-state decision during play to `CletrisRules`.

`tests/test_rules.gd` drives the rules object headlessly. It contains deterministic checks for seeded sequences, the next-piece queue, collision, rotation, locking/clearing, scoring, and game over.

```
Input + frame time -> Main (presentation) -> CletrisRules (deterministic state)
                                      -> procedural CanvasItem drawing
Headless tests -----------------------> CletrisRules
```
