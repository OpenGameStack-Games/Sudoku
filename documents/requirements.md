# Project Requirements

This document acts as the definitive source of truth for the game's features, logic, UI dimensions, and constraints. When a subagent creates a feature or refactors code, it MUST consult this document to ensure strict adherence to the project's vision.

## 1. Core Mechanics
- **Difficulty Levels:** The game must offer three distinct difficulty levels: Easy, Medium, and Hard.
- **Puzzle Generation & Data Structure:** Puzzles are NOT generated on the fly inside the Godot engine. Instead, the game must read puzzles from a pre-baked `game/data/puzzles.json` file.
  - Puzzles are represented as 81-character strings (where '0' represents an empty cell).
  - The JSON contains top-level keys for each difficulty tier: `"easy"`, `"medium"`, and `"hard"`, each containing an array of 81-character puzzle strings (minimum 10 per difficulty for MVP).
  - When a user selects a difficulty, the game randomly selects a puzzle string from that category.
- **Python Generator Tool:** The repository contains an out-of-band Python script located at `tools/generate_puzzles.py` (outside the Godot project). This script is responsible for generating, grading, and exporting the `puzzles.json` file.
  - **Symmetry Requirement:** The generated puzzles MUST feature traditional 180-degree rotational symmetry (if a clue exists at row `r` col `c`, a clue must exist at row `8-r` col `8-c`).
  - **Difficulty Grading:** Difficulty is categorized by target clue count: Easy (50 clues), Medium (40 clues), and Hard (30 clues).
  - **Command Line Arguments:** Accepts `--count <N>` (number of puzzles per difficulty, default 10) and `--out <path>` (output JSON destination, default `game/data/puzzles.json`).
- **Timer & Pause:** The gameplay screen must track time elapsed starting at 00:00.
  - The timer ONLY runs when the screen has active focus. 
  - It pauses if the app is backgrounded or the player returns to the main menu.
  - **Manual Pause:** There must be a dedicated Pause button. When pressed, the timer stops and the Sudoku board is completely hidden (to prevent cheating) until unpaused.
- **Puzzle State & Menus:** The triple-dot menu must contain two options:
  - **"Reset Puzzle":** Wipes all player inputs, returning the board to its original generated state, and resets the timer back to 00:00.
  - **"New Game":** Abandons the current puzzle and instantly generates a new puzzle of the same difficulty.
- **Input Modes (Bi-directional):** 
  - **Cell-First:** The player taps a cell, then taps a number.
  - **Number-First:** The player taps a number on the numpad, then taps multiple cells to quickly fill them.
  - **Normal Mode:** Inputs the final answer into the selected cell.
  - **Candidate Mode:** Inputs small note/candidate numbers into a cell.
  - **Auto Candidate Mode:** An optional toggle. When ON, it calculates and displays valid candidates. It must respect user edits (if a user manually deletes an auto-candidate, it stays deleted). When OFF, auto-generated candidates are hidden.
  - **Auto-Clearing Candidates:** When a player inputs a final answer, any matching candidate notes in the same row, column, and 3x3 block must be automatically deleted.
- **Numpad Exhaustion State:** When a player places 9 instances of a specific number on the board, that corresponding number button on the numpad must visually **gray out**. (It must NOT disappear or be removed).
  - **Cheat Prevention:** To prevent players from using the numpad as an answer-checker, the button must gray out whenever *any* 9 instances of that number are on the board, regardless of whether they are placed correctly or incorrectly.
- **Candidate Layout:** Each cell must support 9 candidate slots (a 3x3 micro-grid within the cell). Candidates 1-9 are positioned consistently: 1 at top-left, 9 at bottom-right.
- **Undo System:** Players can undo an **unlimited** number of previous actions. The history tracks both final answers and candidate note placements/deletions.
- **Error Handling (No Losing):** There are no "strikes" or game-over states for wrong answers. The player can keep trying indefinitely.
  - **Conflict Highlighting:** If a player inputs a final answer that already exists in the same row, column, or 3x3 block, both the newly inputted number and the conflicting number(s) must be highlighted in **red** (a permitted exception to the monochrome theme).
  - **Note:** Error highlighting applies *only* to final answers, not to candidate notes.
- **Cell Selection & Deselection:** Tapping an empty or filled cell selects it. Tapping the currently selected cell again, or tapping anywhere outside the board, deselects the cell.
- **Win State:** The game is won when the grid is completely and correctly filled. 
  - If the grid is completely filled but contains errors (red cells), nothing happens; the timer keeps running until the player corrects them.
  - When won, the timer stops, statistics are updated, and a Victory Screen overlays the board displaying the final time.
  - **Victory Screen Buttons:** "Play Again", "Main Menu", "Statistics", and "Admire Puzzle" (which hides the victory overlay so the player can view their completed board).

## 2. Visuals and Layout
- **Theme and Aesthetics:** The game must use a 1930s monochrome cartoon/animation style (e.g., Steamboat Willie). The color palette is specifically **white-on-black**. 
  - **Background Color:** The background color must use **Dark Gray (Hex #121212)** instead of pure black (#000000). This aligns with Android Material Design guidelines to prevent "OLED smearing" (motion blur when scrolling), reduce eye strain (halation), and allow for subtle drop shadows to convey UI depth.
- **Font Distinctions:** 
  - **Original Clues:** Must use a bold, slightly larger white font.
  - **Player Inputs:** Must use a standard, thinner white font to distinguish them from original clues. 
- **Color Exceptions (Highlights):** Flat, non-bright colors are permitted ONLY for critical game interactions:
  - **Error Highlight:** Conflicting final answers must be highlighted in a flat **Red**.
  - **Selection (Orange Spectrum):** 
    - The currently selected cell must be highlighted in a **flat Orange**.
    - The row, column, and 3x3 macro-block of the selected cell must be highlighted in a **very light Orange**.
  - **Number Matching:** If a selected cell contains a final answer digit (e.g., '1'):
    - All other cells containing that same final answer digit must be highlighted (e.g., in a darker orange/brownish tint).
    - All matching *candidate notes* (e.g., small '1's) across the entire board must become **bold or increase in size** to stand out from the other tiny notes.
- **Mascot/Icon:** The game must feature a mascot character that acts as the game's primary icon, designed in the 1930s monochrome style.
- **Main Menu Screen:** The main screen must feature:
  - The game's mascot/icon prominently displayed.
  - Three difficulty selection buttons: "Easy", "Medium", and "Hard".
  - **Resume Behavior:** If a game is currently saved/in-progress for a specific difficulty, tapping that difficulty button automatically resumes the in-progress game. (The player can use the 'New Game' or 'Reset' options from within the gameplay menu if they want to abandon it).
  - A "Statistics" button.
- **Statistics Screen:** A dedicated screen to display the player's historical performance. It must track the following metrics independently for Easy, Medium, and Hard difficulties:
  - Games Started
  - Games Won
  - Best Time
  - Average Time
- **Gameplay Screen Layout:** The gameplay screen must be structured vertically from top to bottom as follows:
  - **Header Row:**
    - Top-Left: Back arrow button (returns to Main Menu).
    - Center-Left: Difficulty label text (Easy, Medium, or Hard).
    - Center-Right: Active Timer.
    - Top-Right: Triple-dot menu button and a Pause button.
  - **Sudoku Grid:** A standard 9x9 grid, visually sectioned into 3x3 macro blocks. Each cell contains a 3x3 candidate micro-grid.
  - **Mode & Action Row:**
    - Left side: Two adjacent mode toggle buttons ("Normal" and "Candidate").
    - Right side (spaced apart): "Undo" button.
  - **Numpad Row:**
    - 10 buttons: Digits `1` through `9`, and an `X` button (to delete/clear the selected square's contents).
  - **Auto Candidate Row:**
    - Located below the numpad. Contains a toggle control for "Auto Candidate Mode".
- **Statistics Screen:** A dedicated screen to display the player's historical performance and statistics in Sudoku.
- **Dynamic Scaling & Anchoring:** All screens, objects, and nodes must adjust dynamically relative to one another. The UI must fit seamlessly across a wide range of resolutions, aspect ratios, and physical sizes without clipping or overlapping.
- **Orientation:** The application must be locked to **Portrait mode**.
- **Device Support:** The UI must be optimized for both Android phones and Android tablets.

## 3. Data and Persistence
- **Persistent Save States:** The game must auto-save the player's progress. 
  - The player can have up to **three games in progress simultaneously** (one for each difficulty: 1 Easy, 1 Medium, 1 Hard).
  - The save state must include the current board layout, candidate notes, undo history, and the current elapsed time.
  - If a player starts a *new* game on a difficulty that already has an in-progress save, the old save is overwritten.
- **Persistent Player Statistics:** The game tracks and persists historical performance metrics to `user://stats.json` independently across Easy, Medium, and Hard difficulties via the `StatsManager` autoload:
  - **Metrics Tracked:** `games_started` (integer), `games_won` (integer), `best_time_seconds` (integer, 0 when no wins recorded), `total_time_seconds` (integer), and `average_time_seconds` (float).
  - **Auto-Persistence:** Statistics are automatically loaded from `user://stats.json` on startup (with graceful fallback to clean default structures if the file is missing or contains invalid JSON) and saved immediately upon game start or victory events.
  - **Time Formatting:** Provides `format_time(seconds: int) -> String` producing `"MM:SS"` (or `"--:--"` when no time is recorded).

## 4. Platform Specifics
- **Platform:** Android.
- **Screen Wake Lock:** The game must keep the device screen awake as long as the gameplay screen is active (do not allow the phone to go to sleep while playing).
- **System UI (Non-Immersive):** The game must NOT use immersive mode (`screen/immersive_mode=false` in `game/export_presets.cfg`). The Android status bar (battery, time, signal) at the top and the system navigation bar (back, home buttons) at the bottom must remain visible at all times during gameplay and menus.
- **Export Filters:** The `puzzles.json` file (and any other `.json` data files) MUST be explicitly added to the Godot export preset's `include_filter` (e.g., `*.txt, *.json`). Failure to do so will result in the file being stripped from the final Android `.apk`/`.aab` build.
- **Launcher Icons:** Android launcher icons conforming to Godot export standards are located in `game/assets/icons/`: standard launcher icon `icon.png` (192x192 PNG), and adaptive launcher icons `icon_foreground.png` (432x432 PNG) and `icon_background.png` (432x432 PNG). All icon paths are registered in `game/export_presets.cfg`.
- **Display & Input Configuration:** Project orientation is locked to Portrait (`window/handheld/orientation=1`), stretch mode configured to `canvas_items` with aspect `expand`, and touch emulation enabled (`window/touchscreen/emulate_touch_from_mouse=true`) in `game/project.godot`.
- **Automated Verification:** Automated unit tests in `game/tests/test_platform_config.gd` validate that `export_presets.cfg` disables immersive mode, preserves the `*.json` include filter, ensures icon assets exist, and verifies orientation and stretch project settings.

