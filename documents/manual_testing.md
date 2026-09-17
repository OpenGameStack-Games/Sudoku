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
- **Expected (Colors):** The global palette must be **white-on-black**. The background MUST be Dark Gray (#121212) per Material Design guidelines, rather than pure black. Fonts and lines must be white. Color is ONLY used for critical game moves, and the colors are flat and not overly bright.
- **Expected (Assets):** The mascot icon is visible and themed correctly.

## Test 5.0: Main Menu & Navigation
- **Step 1:** Boot the game to the Main Menu.
- **Expected:** The mascot icon is prominently displayed. The screen contains four clear buttons: "Easy", "Medium", "Hard", and "Statistics".
- **Step 2:** Tap the "Statistics" button.
- **Expected:** The Statistics screen correctly displays "Games Started", "Games Won", "Best Time", and "Average Time" broken down independently by difficulty (Easy, Medium, Hard).
- **Step 3:** From the Main Menu, tap "Easy", "Medium", or "Hard".
- **Expected:** The app transitions to the Gameplay screen with a Sudoku board generated at the selected difficulty.

## Test 6.0: Gameplay Screen Layout & Navigation
- **Step 1:** On the Gameplay screen, observe the Header row.
- **Expected:** Top-left is a Back arrow. Center-left is the Difficulty. Center-right is the Timer. Top-right is a three-dot menu.
- **Step 2:** Observe the Grid and controls.
- **Expected:** A 9x9 grid exists. Below it are two adjacent "Normal" and "Candidate" buttons, and an "Undo" button spaced to the right. Below that is a numpad containing 1-9 and an 'X' button.
- **Step 3:** Tap the Back arrow.
- **Expected:** Navigates back to the Main Menu.

## Test 7.0: Gameplay Timer
- **Step 1:** Enter a game. Observe the timer counting up.
- **Step 2:** Background the app or return to the Main Menu, wait 5 seconds, and return to the game.
- **Expected:** The timer must pause while unfocused and resume exactly where it left off upon returning.

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
- **Expected:** The game does NOT end. Instead, both the newly inputted final answer and the conflicting final answer(s) turn red.
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
- **Step 1:** Start an Easy game. Input some numbers. Let the timer run for 10 seconds. Return to the Main Menu.
- **Step 2:** Start a Medium game. Input different numbers. Let the timer run for 20 seconds. Return to the Main Menu.
- **Expected:** The Main Menu must visibly indicate that there is an active "Easy" and "Medium" game in progress.
- **Step 3:** Tap the "Easy" button on the main menu.
- **Expected:** The game automatically resumes the Easy board layout, specific numbers, and the 10-second timer.
- **Step 4:** Force-close the app entirely, reopen it, and tap "Medium".
- **Expected:** The Medium board layout and 20-second timer are perfectly restored.

## Test 17.0: Selection & Number Matching Highlighting
- **Step 1:** Tap an empty cell on the grid.
- **Expected:** The selected cell turns flat orange. The rest of the cells in that same row, column, and 3x3 block turn a very light orange.
- **Step 2:** Tap the exact same cell again.
- **Expected:** The cell (and the row/col/block highlights) deselects completely.
- **Step 3:** Tap an empty cell, then tap anywhere outside the board.
- **Expected:** The cell deselects completely.
- **Step 4:** Ensure the board has some Candidate notes entered in various cells (e.g., several '3's).
- **Step 5:** Tap a cell that contains a large, final answer '3'.
- **Expected (Large Match):** All other cells containing a large '3' highlight in a darker orange/brownish color.
- **Expected (Candidate Match):** All small candidate '3's across the entire board immediately become bold or enlarge, distinguishing them from the other candidate numbers.

## Test 18.0: Pause Functionality
- **Step 1:** Tap the Pause button on the header row.
- **Expected:** The timer stops, and the Sudoku board completely hides or blurs to prevent cheating.
- **Step 2:** Tap Resume/Unpause.
- **Expected:** The board reappears and the timer continues.

## Test 19.0: Screen Wake Lock
- **Step 1:** Leave the app open on the active gameplay screen without touching it for longer than the device's system sleep timer (e.g., 5 minutes).
- **Expected:** The screen stays awake and does not dim or lock.

## Test 20.0: Numpad Exhaustion State
- **Step 1:** Play a puzzle and fill the ninth instance of a specific number (e.g., '5') onto the board.
- **Expected:** The number '5' button on the numpad visually **grays out** (it does not disappear) to indicate that nine 5s have been placed.
- **Step 2:** Tap 'Undo' or use the 'X' button to delete one of the 5s.
- **Expected:** The number '5' button on the numpad lights back up to its normal active state.
- **Step 3 (Cheat Prevention):** Intentionally place 9 instances of the number '5' on the board in completely wrong, conflicting cells.
- **Expected:** The number '5' button on the numpad MUST still gray out (ignoring whether the placements are actually correct).
