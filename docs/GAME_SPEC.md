# Cletris game specification

Cletris is an original, portrait, touch-first falling-block puzzle game. It uses its own name and a procedural neon-grid presentation; it does not use Tetris branding, art, or copied presentation.

The playfield is 10 columns by 20 rows. A seeded seven-piece bag supplies the seven standard four-cell geometric piece families. A player can move left or right, rotate in either direction when the rotated shape fits, soft-drop, or hard-drop. A piece locks when it can no longer descend. Completed rows clear together.

Scoring is deterministic: one, two, three, and four cleared rows award 100, 300, 500, and 800 points respectively. The game ends if a newly spawned piece cannot fit. Restarting uses the original seed so a run is reproducible.

Touch controls use gestures across the playfield: tap the left half to rotate counterclockwise or the right half to rotate clockwise; drag left or right to move; swipe down to hard-drop; and tap-and-hold to speed falling. Desktop arrow keys and Space provide development controls.

Manual phone testing remains necessary. Automated tests validate the rules layer only; they do not simulate device touch behavior or installation on a phone.
