# Manual Testing Guide

This document outlines the strict manual testing procedures required before any release candidate can be deployed.

## Test 1.0: Launch & Boot
- **Step 1:** Open the app.
- **Expected:** The app boots to the main menu without crashing.

## Test 2.0: System UI & Platform Integration
- **Step 1:** Launch the app on an Android device (or simulator).
- **Expected (Non-Immersive):** The Android status bar (top) and navigation bar (bottom) must remain visible. The game must NOT force the device into immersive fullscreen mode (`screen/immersive_mode=false`).
- **Expected (Orientation):** The app must lock to Portrait mode (`window/handheld/orientation=1`). Rotating the device must NOT rotate the game into Landscape mode.
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming non-immersive mode, portrait orientation, canvas_items expand stretch, and touch emulation settings.


## Test 3.0: Dynamic UI Scaling
- **Step 1:** Launch the app on devices or simulators with varying aspect ratios and screen sizes (e.g., a tall, narrow phone and a wider tablet).
- **Expected:** All UI elements (buttons, the Sudoku grid, text) dynamically adjust their anchors and margins relative to one another. There should be no overlapping text, UI clipping off the edge of the screen, or awkwardly empty spaces that break the intended layout.

## Test 4.0: Visual Theme and Assets
- **Step 1:** Navigate through the Main Menu, Statistics screen, and Gameplay screen.
- **Expected:** The entire app conforms to a 1930s monochrome cartoon aesthetic.
- **Expected (Colors):** The global palette must be **white-on-black**. The background MUST be Dark Gray (`#121212`, `ThemeConstants.COLOR_BG_DARK_GRAY`) per Material Design guidelines, rather than pure black. Fonts and lines must be white (`ThemeConstants.COLOR_UI_FOREGROUND`). Color is ONLY used for critical game moves, and the colors are flat and not overly bright.
- **Expected (Assets & Theme):** The mascot icon is visible and themed correctly. Buttons and panels apply 1930s rounded styling from `game/resources/theme_1930s.tres`.
- **Automated Verification:** Verified in headless CI via `game/tests/test_theme_constants.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming ThemeConstants color palette definitions, distinct values, and successful loading and panel/font styling of `game/resources/theme_1930s.tres`.

## Test 5.0: Main Menu & Navigation
- **Step 1:** Boot the game to the Main Menu.
- **Expected:** The mascot icon is prominently displayed. The screen contains four clear buttons: "Easy", "Medium", "Hard", and "Statistics".
- **Step 2:** Tap the "Statistics" button.
- **Expected:** The Statistics screen correctly displays "Games Started", "Games Won", "Best Time", and "Average Time" broken down independently by difficulty (Easy, Medium, Hard).
- **Step 3:** From the Main Menu, tap "Easy", "Medium", or "Hard".
- **Expected:** The app transitions to the Gameplay screen with a Sudoku board generated at the selected difficulty.

## Test 5.1: Player Statistics Tracking & Persistence
- **Step 1:** Launch the game and inspect the initial statistics on the Statistics screen (or clear `user://stats.json`).
- **Expected:** Initial statistics show 0 for Games Started and Games Won, and `"--:--"` for Best Time and Average Time across all difficulties.
- **Step 2:** Start an Easy game. Exit to the Main Menu and open the Statistics screen.
- **Expected:** Easy "Games Started" increments to 1. "Games Won" remains 0.
- **Step 3:** Complete an Easy game with a winning board in 180 seconds.
- **Expected:** Easy "Games Won" increments to 1. "Best Time" displays "03:00". "Average Time" displays "03:00".
- **Step 4:** Complete a second Easy game in 120 seconds.
- **Expected:** Easy "Games Won" increments to 2. "Best Time" updates to "02:00". "Average Time" updates to "02:30" (150 seconds).
- **Step 5:** Complete a third Easy game in 240 seconds.
- **Expected:** Easy "Games Won" increments to 3. "Best Time" remains "02:00" (does not regress). "Average Time" updates to "03:00" (180 seconds).
- **Step 6:** Force close or restart the application, then navigate to the Statistics screen.
- **Expected:** All statistics remain accurately persisted from `user://stats.json`.
- **Automated Verification:** Verified in headless CI via `game/tests/test_stats_manager.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming metric tracking (starts, wins, best times, averages), JSON serialization/deserialization to `user://stats.json`, and time formatting across `easy`, `medium`, and `hard` difficulties.

## Test 6.0: Gameplay Screen Layout & Navigation
- **Step 1:** On the Gameplay screen, observe the Header row.
- **Expected:** Top-left is a Back arrow. Center-left is the Difficulty. Center-right is the Timer. Top-right is a three-dot menu.
- **Step 2:** Observe the Grid and controls.
- **Expected:** A 9x9 grid exists. Below it are two adjacent "Normal" and "Candidate" buttons, and an "Undo" button spaced to the right. Below that is a numpad containing 1-9 and an 'X' button.
- **Step 3:** Tap the Back arrow.
- **Expected:** Navigates back to the Main Menu.

## Test 7.0: Gameplay Timer
- **Step 1:** Enter a game. Observe the timer counting up from 00:00 (or saved elapsed time).
- **Step 2:** Background the app, switch to another application, or return to the Main Menu, wait 5 seconds, and return to the game.
- **Expected:** The timer must pause while unfocused and resume counting exactly where it left off upon returning.
- **Step 3:** Allow gameplay timer to pass 59 seconds and verify it transitions smoothly from `00:59` to `01:00`. If playing an extended session, verify it transitions to `HH:MM:SS` format past 3600 seconds.
- **Automated Verification:** Verified in headless CI via `game/tests/test_game_timer.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming initial seconds loading, time formatting (`MM:SS` and `HH:MM:SS`), second-by-second incrementing, manual pause/resume, and focus lifecycle state handling.

## Test 8.0: Grid Input (Bi-Directional)
- **Step 1 (Cell-First):** Tap an empty cell, then tap a number on the numpad.
- **Expected:** The number is entered into the cell.
- **Step 2 (Number-First):** Tap a number on the numpad, then tap several empty cells.
- **Expected:** The number is entered into every cell tapped.
- **Step 3 (Auto-Clear Candidates):** Enter candidate '5' into several cells in a row. Then enter a final answer '5' in that row.
- **Expected:** All candidate '5's in that row automatically disappear.

## Test 9.0: Undo System
- **Step 1:** Make several inputs (Normal and Candidate mode) on the grid.
- **Step 2:** Tap the "Undo" button repeatedly.
- **Expected:** The board accurately steps backward through an unlimited history of inputs, including candidate notes.
- **Step 3 (Auto-Cleared Candidate Restoration):** In an empty row, add candidate '5' to Cell B. In Cell A of the same row, place final answer '5'. Confirm that candidate '5' in Cell B is automatically cleared.
- **Step 4:** Tap "Undo" to revert the placement of final answer '5' in Cell A.
- **Expected:** Cell A's value reverts to empty, and candidate note '5' in Cell B is seamlessly restored.
- **Step 5 (Conflict Highlighting Recalculation):** Place an identical digit in the same row, column, or block to trigger red conflict highlighting. Tap "Undo".
- **Expected:** The conflict highlight immediately clears for the remaining cells.
- **Step 6 (Numpad Exhaustion Recalculation):** Place the 9th instance of a digit so its numpad button grays out. Tap "Undo".
- **Expected:** The numpad button re-enables and returns to its active visual state.
- **Step 7 (Empty Stack Safety):** Tap "Undo" repeatedly until no further actions remain in history.
- **Expected:** The app handles the empty stack gracefully with no crashes or unexpected state changes.
- **Automated Verification:** Verified in headless CI via `game/tests/test_undo_manager.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming empty stack safety, sequential final answer undo, sequential candidate note undo, compound action peer candidate restoration, conflict/exhaustion recalculation, and state serialization.

## Test 10.0: Puzzle Menus (Reset & New Game)
- **Step 1:** Tap the triple-dot menu. Select "Reset Puzzle".
- **Expected:** All inputs wipe, and the timer resets to 00:00.
- **Step 2:** Tap the triple-dot menu. Select "New Game".
- **Expected:** The board generates a brand new puzzle and the timer resets to 00:00.

## Test 11.0: Auto Candidate Mode
- **Step 1:** While playing a puzzle, locate the "Auto Candidate Mode" toggle below the numpad.
- **Step 2:** Toggle it ON.
- **Expected:** All empty cells automatically populate with correct, calculated candidates.
- **Step 3:** Manually delete one of the auto-candidates using the 'X' button.
- **Expected:** The candidate is deleted and stays deleted (the auto-calculator respects user edits).
- **Step 4:** Toggle it OFF.
- **Expected:** All auto-generated candidates disappear from the board.

## Test 12.0: Puzzle Database Load & Symmetry
- **Step 1:** Tap "Easy", "Medium", and "Hard" sequentially from the main menu, exiting back to the menu between each.
- **Expected:** The game successfully loads a puzzle string from `puzzles.json` for each difficulty without hanging or crashing. The initial clues populated on the board must exactly match the non-zero digits of the loaded string.
- **Step 2:** Observe the initial clues on the board.
- **Expected:** The layout of the clues MUST be rotationally symmetrical (180 degrees).
- **Automated Verification:** Verified in headless CI via `game/tests/test_puzzle_loader.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), which validates file existence, JSON validity, array sizes (>= 10), string lengths (81 characters), valid digits ('0'-'9'), and 180-degree rotational symmetry for all clues across `easy`, `medium`, and `hard`.

## Test 13.0: Android Build Export & Launcher Icons
- **Step 1:** Build the Android `.apk`/`.aab` or install/run the game natively on an Android device via Godot export.
- **Step 2:** Boot the game and start any new puzzle.
- **Expected (JSON Packaging):** The puzzle loads perfectly. If the screen is blank or the app crashes here, the `*.json` file was likely stripped during the build process and the `export_presets.cfg` include filter (`include_filter="*.txt, *.json"`) must be verified.
- **Step 3:** Inspect the app icon on the Android launcher, home screen, and app drawer.
- **Expected (Launcher Icons):** The app displays the custom mascot icon (`icon.png` / `icon_foreground.png` / `icon_background.png`) rather than the default Godot engine icon.
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), validating that `export_presets.cfg` includes `*.json` in the include filter and that all launcher icon assets exist on disk.


## Test 14.0: Error Highlighting (No Strikes)
- **Step 1:** Input a final answer number into a cell that already exists in that cell's row, column, or 3x3 block.
- **Expected:** The game does NOT end. Instead, both the newly inputted final answer and the conflicting final answer(s) turn flat red (`ThemeConstants.COLOR_CONFLICT_ERROR`).
- **Step 2:** Input a *candidate* note that conflicts with a final answer in the same row.
- **Expected:** The candidate note does NOT turn red (error highlighting only applies to final answers).
- **Step 3:** Delete the newly inputted conflicting final answer.
- **Expected:** The red highlight disappears.

## Test 15.0: Win State & Victory Screen
- **Step 1:** Successfully fill the entire grid with the correct solution.
- **Expected:** The game detects the win state. The timer immediately stops.
- **Expected:** A Victory Screen overlay appears showing the final time. It contains "Play Again", "Main Menu", "Statistics", and "Admire Puzzle" buttons.
- **Step 2:** Tap "Admire Puzzle".
- **Expected:** The overlay disappears, allowing the player to view the completed board.
- **Step 3:** Tap the Back arrow.
- **Expected:** Navigates to the Main Menu and clears the completed puzzle from the active save state.

## Test 16.0: Concurrent Save Persistence & Menus
- **Step 1:** Start an Easy game. Input several numbers and candidate notes into empty cells. Perform an undo action. Let the timer run for 10 seconds. Switch apps or background the application (triggering focus loss auto-flush), then return to the Main Menu.
- **Step 2:** Start a Medium game. Input different numbers and candidate notes. Let the timer run for 20 seconds. Pause the game, then return to the Main Menu.
- **Step 3:** Start a Hard game. Input numbers and notes. Let the timer run for 30 seconds. Return to the Main Menu.
- **Expected:** The application maintains up to 3 separate active saves concurrently in `user://saves/` (`save_easy.json`, `save_medium.json`, and `save_hard.json`). The Main Menu visibly indicates active in-progress games for each difficulty.
- **Step 4:** Tap the "Easy" button on the Main Menu.
- **Expected:** The game automatically resumes the Easy puzzle, restoring the exact board layout, user-entered numbers, candidate notes, deleted candidate notes, elapsed timer (10 seconds), and undo history stack (tapping "Undo" reverts earlier moves).
- **Step 5:** Force-close the app entirely or kill the process. Reopen the app and tap "Medium".
- **Expected:** The Medium puzzle state (board layout, candidate notes, 20-second timer, and undo stack) is fully restored from `user://saves/save_medium.json`.
- **Step 6 (Save Overwrite):** On Easy difficulty, open the menu and start a "New Game". Make a move.
- **Expected:** The previous Easy save is cleanly overwritten with the new puzzle state, resetting the timer and undo stack.
- **Step 7 (Save Clearing):** Complete a puzzle or select "Reset Puzzle".
- **Expected:** The active save file for that difficulty is deleted (`clear_save`), and returning to the Main Menu reflects that no active save exists for that difficulty.
- **Automated Verification:** Verified in headless CI via `game/tests/test_save_manager.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming concurrent saving and loading across Easy/Medium/Hard, save overwriting, complex state restoration (board, notes, undo history, elapsed seconds), save deletion, and graceful recovery from corrupted save files.

## Test 17.0: Selection & Number Matching Highlighting
- **Step 1:** Tap an empty cell on the grid.
- **Expected:** The selected cell turns flat orange (`ThemeConstants.COLOR_SELECTION`). The rest of the cells in that same row, column, and 3x3 block turn a very light translucent orange (`ThemeConstants.COLOR_PEER_HIGHLIGHT`).
- **Step 2:** Tap the exact same cell again.
- **Expected:** The cell (and the row/col/block highlights) deselects completely.
- **Step 3:** Tap an empty cell, then tap anywhere outside the board.
- **Expected:** The cell deselects completely.
- **Step 4:** Ensure the board has some Candidate notes entered in various cells (e.g., several '3's).
- **Step 5:** Tap a cell that contains a large, final answer '3'.
- **Expected (Large Match):** All other cells containing a large '3' highlight in a darker orange/brownish color (`ThemeConstants.COLOR_NUMBER_MATCH`).
- **Expected (Candidate Match):** All small candidate '3's across the entire board immediately become bold or enlarge (`note_font_bold`), distinguishing them from the other candidate numbers.
- **Automated Verification:** Verified in headless CI via `game/tests/test_theme_constants.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming ThemeConstants color palette definitions and font variation styles.

## Test 18.0: Pause Functionality
- **Step 1:** Tap the Pause button on the header row.
- **Expected:** The timer stops, the Sudoku board completely hides or blurs to prevent cheating, and the screen wake lock is released (`DisplayServer.screen_set_keep_on(false)`), allowing the device to follow standard display sleep timeouts.
- **Step 2:** Tap Resume/Unpause.
- **Expected:** The board reappears, the timer continues, and the screen wake lock is restored (`DisplayServer.screen_set_keep_on(true)`).
- **Automated Verification:** Verified in headless CI via `game/tests/test_game_timer.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming timer halts during manual pause and resumes upon unpause.

## Test 19.0: Screen Wake Lock
- **Step 1:** Leave the app open on the active, unpaused gameplay screen without touching it for longer than the device's system sleep timeout (e.g., 2-5 minutes).
- **Expected:** The screen stays awake and does not dim, sleep, or lock.
- **Step 2:** From gameplay, pause the game or navigate to the Main Menu. Leave the device idle without interaction.
- **Expected:** The device screen dims and goes to sleep according to system display timeout settings, confirming wake lock is released when not in active gameplay.
- **Step 3:** Switch to another app or minimize the game.
- **Expected:** Wake lock remains released, respecting system power management and battery life.
- **Automated Verification:** Verified in headless CI via `game/tests/test_game_timer.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), verifying wake lock state updates across pause, resume, and focus loss notifications (bypassed in headless environments).

## Test 20.0: Numpad Exhaustion State
- **Step 1:** Play a puzzle and fill the ninth instance of a specific number (e.g., '5') onto the board.
- **Expected:** The number '5' button on the numpad visually **grays out** (it does not disappear; uses dimmed gray `ThemeConstants.COLOR_NUMPAD_EXHAUSTED`) to indicate that nine 5s have been placed.
- **Step 2:** Tap 'Undo' or use the 'X' button to delete one of the 5s.
- **Expected:** The number '5' button on the numpad lights back up to its normal active state.
- **Step 3 (Cheat Prevention):** Intentionally place 9 instances of the number '5' on the board in completely wrong, conflicting cells.
- **Expected:** The number '5' button on the numpad MUST still gray out (ignoring whether the placements are actually correct).
