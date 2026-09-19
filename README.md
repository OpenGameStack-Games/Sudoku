# Sudoku - Godot AI Template

An AI-first Godot 4.7.2 project template featuring built-in CI/CD pipelines, strict documentation standards, and automated agent orchestration.

## Getting Started
1. Click **Use this template** to create a new repository.
2. Ensure you have Godot 4.7.2 installed and add the directory containing the executable to your system's `PATH` environment variable. Make sure the executable is named `godot` (or `godot.exe` / `godot.bat` on Windows) so the command line can find it.
3. Use your AI Agent to build your game!

## OpenGameStack Integration
This project is configured as an **OpenGameStack (OGS)** project. It includes `stack.json` and `ogs_config.json` files which define the exact environment (like Godot 4.7.2) required to run and build this game.

To get started with OGS:
1. Download the [OGS Launcher](https://github.com/OpenGameStack-Launcher/ogs-launcher).
2. Open the OGS Launcher and click **Add Project** to register this repository.
3. The launcher will read `stack.json` and automatically download the correct Godot version and any other required tools for your team.

## Git LFS Requirement
This template is configured to use [Git Large File Storage (LFS)](https://git-lfs.com/) for all binary assets (images, audio, video, 3D models, fonts, etc.). It is assumed that repositories instantiated from this template will have Git LFS installed and enabled locally.

To ensure your assets are tracked correctly:
1. Ensure Git LFS is installed on your machine (`git lfs install`).
2. The provided `.gitattributes` file will automatically handle LFS tracking for standard game asset extensions.
## Core Architecture
- **StatsManager (`game/autoloads/stats_manager.gd`):** Global autoload managing player statistics (games started, games won, best times, and average times) across Easy, Medium, and Hard difficulties, persisted locally in `user://stats.json`.
- **TimeManager (`game/autoloads/time_manager.gd`):** Global autoload managing the gameplay timer, application focus lifecycle, and screen wake lock (`DisplayServer.screen_set_keep_on`). Respects device battery life by automatically pausing elapsed time and releasing the screen wake lock whenever the game is paused, backgrounded, or out of focus.
- **Sudoku Engine (`game/scripts/sudoku_board.gd` & `game/scripts/sudoku_cell.gd`):** Core validation engine managing grid state, clue initialization, candidate notes, and conflict detection (no-strike policy). Supports an Auto Candidate mode that dynamically calculates valid candidates while strictly preserving manual user deletions.
- **Theme & Palette System (`game/scripts/theme_constants.gd` & `game/resources/theme_1930s.tres`):** Centralized 1930s monochrome cartoon aesthetic featuring Dark Gray (`#121212`) Material Design background to prevent OLED smearing, crisp white outlines and rounded borders, and flat highlighting colors for selection, peer highlights, number matches, conflict errors, and exhausted numpad digits. Configures dedicated typography variations for clues, player inputs, and candidate notes.
- **Undo System (`game/scripts/undo_manager.gd`):** Global autoload (`ActionManager`) and board-injectable command stack managing an unlimited undo history for both final answer values and candidate notes. Accurately restores peer candidates auto-cleared upon answer placement, and triggers real-time board recalculation (conflicts, exhaustion, and win state) upon undo.
- **SaveManager (`game/autoloads/save_manager.gd`):** Global autoload managing multi-difficulty save state persistence across Easy, Medium, and Hard slots (`user://saves/save_<difficulty>.json`). Automatically flushes complete game state (puzzle string, cell values, candidate notes, user deleted candidates, undo history stack, and elapsed seconds) upon state transitions (board updates, undo actions, window/app focus loss), with robust fallback and recovery from corrupted save files.
- **Board & Cell UI Components (`game/scenes/board.tscn`, `game/scenes/cell.tscn`, `game/scripts/board_ui.gd`, `game/scripts/cell_ui.gd`):** Interactive visual components implementing the 9x9 Sudoku grid and fixed 3x3 positional candidate micro-grids (numpad layout 1-9 using empty text rather than visibility toggles to prevent reflow) within an `AspectRatioContainer` for dynamic portrait scaling. Features crisp 1930s monochrome grid separation (4px white outer border, 4px white 3x3 block dividers, and 1px white inner cell dividers over dark cells) with clear visual differentiation between starting clues (bold, 32pt, pure white) and player inputs (28pt, dim gray `#a0a0a0`). Seamlessly binds to the core `SudokuBoard` model, handling cell selection toggling, peer highlighting, number matching, matching candidate note font enlargement, dynamic high-contrast text color inversion for highlighted cells, and real-time conflict error states.
- **Main Menu Screen (`game/scenes/main.tscn`, `game/scenes/main_menu.tscn`, `game/scripts/main_menu.gd`):** Application entry point embodying the 1930s rubber-hose aesthetic with a custom monochrome mascot character (`game/assets/icons/mascot_icon.jpg`). Features difficulty selection (Easy, Medium, Hard) that dynamically detects saved games via `SaveManager` to present "Resume" options with seamless timer continuation, manages statistics navigation, and starts new puzzles seeded from `game/data/puzzles.json` with cleanly reset timer states.
- **Statistics Screen (`game/scenes/statistics_screen.tscn`, `game/scripts/statistics_screen.gd`):** Dedicated UI screen styled in 1930s monochrome presentation with enlarged, high-readability difficulty cards and typography displaying player performance metrics (games started, games won, best times, and average times) categorized by Easy, Medium, and Hard difficulties with smooth navigation back to the main menu.
- **Input Controls & Numpad (`game/scenes/input_controls.tscn` & `game/scripts/input_controls.gd`):** Standalone 1930s-styled control panel wrapped in a `MarginContainer` (16px margins), featuring Normal/Candidate mode toggles, dedicated vertical separation, dynamically synchronized Undo button (disabled on empty history, enabled upon moves), 1-9 & Erase (X) numpad with balanced portrait button heights (64px) and cheat-proof digit exhaustion dimming (`ThemeConstants.COLOR_NUMPAD_EXHAUSTED`), flat borderless Auto Candidate checkbox styling (`StyleBoxEmpty`), and full bi-directional (Cell-First and Number-First) input routing.
- **Gameplay Screen & Pause Overlay (`game/scenes/gameplay_screen.tscn`, `game/scripts/gameplay_screen.gd`, `game/scenes/pause_overlay.tscn`, `game/scripts/pause_overlay.gd`):** Top-level gameplay view organizing the responsive navigation header (< Back button with auto-saving, Difficulty label, active Timer, themed Pause button with 2px white outline, and Triple-dot Menu for Reset Puzzle & New Game), 9x9 Board, and Input Controls. Features a full-screen 1930s themed opaque pause overlay with mascot artwork to obscure the board, pause the timer, release the screen wake lock, and present a themed Resume button.
- **Victory Screen Overlay (`game/scenes/victory_overlay.tscn` & `game/scripts/victory_overlay.gd`):** Post-game celebration overlay styled with 1930s monochrome aesthetics (`res://resources/theme_1930s.tres`), featuring the mascot artwork (`game/assets/icons/mascot_icon.jpg`), celebratory banner, and formatted completion time (`MM:SS`). Automatically stops the timer, records victory metrics in `StatsManager`, purges completed save files via `SaveManager`, and provides actions for "Play Again", "Main Menu", "Statistics", and "Admire Puzzle" (with floating "Restore Dialog" support).

## Controls & Accessibility
The game supports intuitive touch/mouse controls as well as full keyboard navigation for desktop testing and accessibility:
- **Bi-directional Workflows:**
  - **Cell-First Mode:** Tap an empty cell on the grid, then tap a numpad digit `1`-`9` or 'X' (Erase).
  - **Number-First Mode:** Tap a numpad digit to activate it (`Color(0.8, 1.0, 0.8)`), then tap multiple grid cells to rapidly place that digit. Tap the digit again to exit number-first mode.
- **Session & Post-Game Controls:**
  - `< Back`: Flushes the active game state to disk and returns to the Main Menu.
  - `Pause`: Halts the timer, conceals the grid behind a 1930s themed mascot overlay, and releases the screen wake lock.
  - `Reset Puzzle`: Restores initial clues, clears player answers and notes, and resets the timer to 00:00.
  - `New Game` / `Play Again`: Fetches a fresh distinct puzzle from `puzzles.json` of the current difficulty tier and restarts the session.
  - `Admire Puzzle`: Temporarily conceals the victory dialog card so the player can view their finished board, with a floating `Restore Dialog` button to bring it back.
  - **Background Tap:** Tapping outside the 9x9 board or controls deselects the current cell.
- **Keyboard Shortcuts:**
  - `1` - `9` / Keypad `1` - `9`: Input digit.
  - `X`, `0`, `Keypad 0`, `Backspace`, `Delete`: Erase digit or candidate notes in selected cell.
  - `C`: Switch to Candidate note mode.
  - `N`: Switch to Normal answer mode.
  - `U` / `Ctrl + Z`: Trigger Undo.
### Puzzle Generator (`tools/generate_puzzles.py`)
An offline Python utility to generate 9x9 Sudoku puzzles with guaranteed unique solutions and 180-degree rotational symmetry:
```powershell
python tools/generate_puzzles.py --count 10 --out game/data/puzzles.json
```
- `--count <N>`: Count of puzzles to generate per difficulty level (default: 10).
- `--out <path>`: Destination path for the exported JSON dataset (default: `game/data/puzzles.json`).

### Board Scene Generator (`tools/generate_board.py`)
An offline Python utility to procedurally generate the complete 81-cell Godot scene file (`game/scenes/board.tscn`) with consistent `MarginContainer` and `GridContainer` separation properties:
```powershell
python tools/generate_board.py
```

## License
This project uses a split license:
- **Source Code:** Licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).
- **Game Assets:** Unless otherwise specified, art, audio, and models in `game/assets/` are licensed under [Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)](LICENSE-ASSETS).

