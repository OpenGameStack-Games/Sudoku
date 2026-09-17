Resolves #1

### Problem & Context
The game required an out-of-band Python script to generate a pre-baked `puzzles.json` file. These puzzles need to have guaranteed unique solutions, strict 180-degree rotational symmetry, and be split into `easy`, `medium`, and `hard` difficulties (10 per tier for MVP).

### Key Changes & Technical Scope
- `tools/generate_puzzles.py`: Added Python script that generates valid 9x9 Sudoku puzzles. It uses backtracking to guarantee unique solutions and strictly enforces 180-degree clue symmetry. It categorizes puzzles into `easy` (50 clues), `medium` (40 clues), and `hard` (30 clues).
- `game/data/puzzles.json`: Exported 10 distinct symmetric puzzles per difficulty tier.
- `game/tests/test_puzzle_loader.gd`: Added automated tests verifying JSON structure, 81-character length, valid digit characters, and 180-degree rotational symmetry for all clues.

### Automated Test Results
- `Test Results: 133 Passed, 0 Failed`

### Handoff for PR Reviewer & Documentation Agent
- `documents/requirements.md`: No new specs added, but MVP requirements for offline generation and symmetry are now complete.
- `documents/manual_testing.md`: Manual Test 12.0 is validated through automated tests (`test_puzzle_loader.gd`); consider documenting this test coverage.
- `README.md`: No changes needed as this is a backend tooling/data issue.
