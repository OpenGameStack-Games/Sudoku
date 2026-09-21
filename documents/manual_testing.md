# Manual Testing Guide

This document outlines the strict manual testing procedures required before any release candidate can be deployed.

## Test 1.0: Launch & Boot
- **Step 1:** Open the app.
- **Expected:** The app boots to `main.tscn`, loading `main_menu.tscn` displaying the 1930s monochrome mascot artwork and difficulty buttons without crashing.
- **Automated Verification:** Verified in headless CI via `game/tests/test_main_menu.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming root scene loading and `MainMenu` child instantiation.

## Test 2.0: System UI & Platform Integration
- **Step 1:** Launch the app on an Android device (or simulator).
- **Expected (Non-Immersive):** The Android status bar (top) and navigation bar (bottom) must remain visible. The game must NOT force the device into immersive fullscreen mode (`screen/immersive_mode=false`).
- **Expected (Orientation):** The app must lock to Portrait mode (`window/handheld/orientation=1`). Rotating the device must NOT rotate the game into Landscape mode.
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming non-immersive mode, portrait orientation, canvas_items expand stretch, and touch emulation settings.


## Test 3.0: Dynamic UI Scaling
- **Step 1:** Launch the app on devices or simulators with varying aspect ratios and screen sizes (e.g., a tall, narrow phone and a wider tablet).
- **Expected:** All UI elements (buttons, the Sudoku grid, text, and Statistics cards) dynamically adjust their anchors and margins relative to one another. There should be no overlapping text, UI clipping off the edge of the screen, or awkwardly empty spaces that break the intended layout. Specifically on the Statistics screen, enlarged stat cards and typography (32pt stats, 48pt difficulty headings, 64pt title) should remain cleanly readable inside the ScrollContainer across phone and tablet aspect ratios.

## Test 4.0: Visual Theme and Assets
- **Step 1:** Navigate through the Main Menu, Statistics screen, and Gameplay screen.
- **Expected:** The entire app conforms to a 1930s monochrome cartoon aesthetic.
- **Expected (Colors):** The global palette must be **white-on-black**. The background MUST be Dark Gray (`#121212`, `ThemeConstants.COLOR_BG_DARK_GRAY`) per Material Design guidelines, rather than pure black. Fonts and lines must be white (`ThemeConstants.COLOR_UI_FOREGROUND`). Color is ONLY used for critical game moves, and the colors are flat and not overly bright.
- **Expected (Assets & Theme):** The mascot icon is visible and themed correctly. Buttons and panels apply 1930s rounded styling from `game/resources/theme_1930s.tres`.
- **Expected (Monochrome Symbols):** Buttons utilizing Unicode symbols (Undo, Pause, Resume) MUST render as flat monochrome white shapes on a dark gray background. They must NOT render as blue or colored emojis on any OS (including Windows and Android).
- **Automated Verification:** Verified in headless CI via `game/tests/test_theme_constants.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming ThemeConstants color palette definitions, distinct values, and successful loading and panel/font styling of `game/resources/theme_1930s.tres`.

## Test 5.0: Main Menu & Navigation
- **Step 1 (Default State):** Boot the game to the Main Menu with no existing saves.
- **Expected:** The 1930s monochrome mascot character (`mascot_icon.jpg`) is prominently centered in the upper half. The screen contains four clear buttons reading: "Easy", "Medium", "Hard", and "Statistics".
- **Step 2 (Resume State Indication):** If an active save exists for a difficulty tier (e.g., Easy), verify that the corresponding button dynamically updates to read `"Resume Easy"`. Unsaved difficulties remain `"Medium"` and `"Hard"`.
- **Step 3 (Resume Navigation):** Tap a "Resume [Difficulty]" button.
- **Expected:** The app transitions to the Gameplay screen (`res://scenes/gameplay_screen.tscn`), restoring the active saved puzzle for that difficulty without incrementing `games_started` in `StatsManager`, and actively unpausing the timer to continue counting from the saved elapsed seconds.
- **Step 4 (Fresh Game Navigation):** From the Main Menu, tap a non-resumed difficulty button (e.g., "Medium").
- **Expected:** The app starts a fresh game by selecting a random puzzle string from `game/data/puzzles.json`, marks it as the active save, unconditionally resets and starts `TimeManager` at 0 (unpaused), increments `games_started` in `StatsManager`, and opens `res://scenes/gameplay_screen.tscn`.
- **Step 5 (Statistics Navigation):** Tap the "Statistics" button.
- **Expected:** The app transitions to the Statistics screen (`res://scenes/statistics_screen.tscn`).
- **Step 6 (Statistics Screen UI, Typography Scaling & Back Navigation):**
  - Verify the header displays the prominent "STATISTICS" title (font size 64) and a "<" back button.
  - Verify three independent cards ("Easy", "Medium", and "Hard") displaying "Games Started", "Games Won", "Best Time", and "Average Time".
  - **Visual Real Estate & Readability Verification:** Verify that the statistics cards and typography are enlarged to comfortably fill the vertical screen real estate without feeling cramped or leaving excessive blank space. Difficulty headers should be large (48pt) and stat labels/values should be prominent (32pt) with generous inner card padding (40px) and vertical separation (30px).
  - Verify the 1930s monochrome styling with Dark Gray `#121212` background, crisp white borders, and balanced monochrome typography.
  - Tap the "<" button.
  - **Expected:** The app returns cleanly to the Main Menu.
- **Automated Verification:** Verified in headless CI via `game/tests/test_main_menu.gd` and `game/tests/test_statistics_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming scene asset existence, dynamic button text adaptation for saves vs fresh states, button signal routing, statistics screen data binding from mock StatsManager, formatting of empty vs recorded metrics, enlarged styling/padding assertions, and Back button signal wiring.

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
- **Automated Verification:** Verified in headless CI via `game/tests/test_stats_manager.gd` and `game/tests/test_statistics_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming metric tracking (starts, wins, best times, averages), JSON serialization/deserialization to `user://stats.json`, time formatting across `easy`, `medium`, and `hard` difficulties, and accurate visual binding to the Statistics screen labels.

## Test 6.0: Gameplay Screen Layout & Navigation
- **Step 1:** On the Gameplay screen, observe the Header row.
- **Expected:** Top-left is a `<` button. Center-left is the capitalized Difficulty label ("Easy", "Medium", or "Hard"). Center-right is the active Timer label. Top-right contains the Pause button and the triple-dot menu ("..."). The header maintains at least 32px top margin to remain clear of the non-immersive Android status bar.
- **Step 2:** Observe the Grid and controls.
- **Expected:** A 9x9 grid exists centered within an aspect ratio container. Below it are mode toggle buttons ("Normal" and "Candidate"), an "Undo" button spaced to the right, a 1-9 & Erase numpad, and an Auto Candidate switch.
- **Step 3:** Enter a move on the board (e.g. place a number into an empty cell), then tap the `<` button.
- **Expected:** Navigates back to the Main Menu. The Main Menu button for that difficulty now reflects `"Resume [Difficulty]"`. Tapping Resume restores the exact board state and elapsed time, confirming the `<` button successfully flushed game state to `SaveManager`.
- **Automated Verification:** Verified in headless CI via `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting header initialization, difficulty label capitalization, timer label binding, back button save flushing, and scene asset presence.

## Test 6.1: Sudoku Board Grid Lines & Visual Separation
- **Step 1:** Enter an active game on the Gameplay screen and inspect the 9x9 Sudoku board.
- **Step 2 (Grid Lines & Aesthetics):** Verify that the board exhibits crisp, pure white grid lines separating dark cells (`#222222`), conforming to the 1930s monochrome aesthetic.
- **Step 3 (Border Widths & Consistency):**
  - Verify that the outer perimeter of the 9x9 board is bounded by a uniform 4px thick white border (`MarginContainer` margin = 4).
  - Verify that the major division lines separating the nine 3x3 macro blocks are uniformly thick (6px separation), clearly and unmistakably delineating each 3x3 block.
  - Verify that the minor inner lines separating individual cells within each 3x3 block are uniformly thin (2px separation) yet sharp and clearly visible.
- **Step 4 (Dynamic Scaling Verification):**
  - Scale the game window dynamically (e.g., resizing the window or testing on smaller resolutions) and verify that all 81 cells maintain solidly rendered borders without any dropping out or becoming sub-pixel invisible.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` (`test_grid_lines_consistency()`), asserting the presence of `MarginContainer` with 4px margins, `MacroGrid` with 6px `h_separation` and `v_separation`, each `MicroGrid` with 2px `h_separation` and `v_separation`, and `Background` ColorRect set to pure white `Color(1, 1, 1, 1)`.

## Test 7.0: Gameplay Timer
- **Step 1:** Enter a game. Observe the timer counting up from 00:00 (or saved elapsed time).
- **Step 2 (Resume Timer Continuation):** Start an Easy game and let the timer count for several seconds (e.g., 8 seconds). Tap `<` or Pause to exit back to the Main Menu. From the Main Menu, tap "Resume Easy".
- **Expected:** The game loads and the timer immediately unpauses and continues counting up from 8 seconds (`00:08`, `00:09`, `00:10`...). The timer is NOT frozen.
- **Step 3 (Fresh Game Reset Verification):** From the resumed Easy game, tap `<` to return to the Main Menu. Tap a different difficulty without an active save (e.g., "Medium" or "Hard").
- **Expected:** The new game starts with the timer reset to `00:00` and ticking normally (`00:01`, `00:02`...). The timer is NOT frozen, and does NOT retain or bleed the previous session's elapsed time.
- **Step 4:** Background the app, switch to another application, or return to the Main Menu, wait 5 seconds, and return to the game.
- **Expected:** The timer must pause while unfocused and resume counting exactly where it left off upon returning.
- **Step 5:** Allow gameplay timer to pass 59 seconds and verify it transitions smoothly from `00:59` to `01:00`. If playing an extended session, verify it transitions to `HH:MM:SS` format past 3600 seconds.
- **Automated Verification:** Verified in headless CI via `game/tests/test_game_timer.gd` and `game/tests/test_main_menu.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming initial seconds loading, time formatting (`MM:SS` and `HH:MM:SS`), second-by-second incrementing, manual pause/resume, focus lifecycle state handling, and unconditional reset on new game routing.

## Test 8.0: Grid Input (Bi-Directional & Keyboard Shortcuts)
- **Step 1 (Cell-First Input & Visual Distinction):** Tap an empty cell, then tap a number 1-9 on the numpad.
- **Expected:** The number is entered into the cell. Verify that the entered digit is rendered in a dimmer gray (`#a0a0a0`) and smaller font size (28pt) compared to the initial clue digits which remain bold, larger (32pt), and pure white (`Color.WHITE`), clearly differentiating player inputs while maintaining the 1930s monochrome aesthetic.
- **Step 2 (Number-First Input):** Tap a number on the numpad (it highlights in soft green `Color(0.8, 1.0, 0.8)`), then tap several empty cells.
- **Expected:** The number is entered into every cell tapped. Tapping the numpad button again deselects it.
- **Step 3 (Mode Toggles):** Tap the "Candidate" button (or press `C` on a keyboard). Tap an empty cell and input digit '3'.
- **Expected:** '3' is placed into the cell's candidate micro-grid. Tap "Normal" (or press `N`) to switch back to normal answer input mode.
- **Step 4 (Erase Button):** Select a cell containing a number or candidate notes, then tap the 'X' numpad button (or press `X`, `0`, `Backspace`, or `Delete` on keyboard).
- **Expected:** Final answer is cleared, or candidate notes are deleted. Clue cells remain unaffected.
- **Step 5 (Keyboard Shortcuts):** With a cell selected, press keys `1`-`9` (or numpad keys `KP_1`-`KP_9`).
- **Expected:** Corresponding digit is placed into the selected cell. Press `U` or `Ctrl+Z` to verify undo action.
- **Step 6 (Auto-Clear Candidates):** Enter candidate '5' into several cells in a row. Then enter a final answer '5' in that row.
- **Expected:** All candidate '5's in that row automatically disappear.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting cell-first and number-first input, candidate toggling, erase behavior, clue protection, keyboard shortcuts, undo emissions, candidate micro-grid synchronization, and font color differentiation (#a0a0a0 for user inputs vs white for clues).

## Test 9.0: Undo System
- **Step 1 (Initial Disabled State):** Upon starting a fresh puzzle or resetting an active puzzle, observe the "Undo" button on the controls row.
- **Expected:** The "Undo" button is disabled (`disabled = true`) because the undo stack is empty.
- **Step 2 (Dynamic Enable on Move):** Place a digit or toggle a candidate note onto the grid.
- **Expected:** As soon as the action is performed, the "Undo" button immediately becomes enabled (`disabled = false`).
- **Step 3 (Reverting and Re-disabling):** Tap the "Undo" button to revert the single action.
- **Expected:** The action is undone, restoring the previous board or note state. Because the undo stack is now empty, the "Undo" button immediately becomes disabled (`disabled = true`) again.
- **Step 4 (Sequential Input Undo):** Make several inputs (Normal and Candidate mode) on the grid. Tap the "Undo" button repeatedly.
- **Expected:** The board accurately steps backward through an unlimited history of inputs, including candidate notes.
- **Step 5 (Auto-Cleared Candidate Restoration):** In an empty row, add candidate '5' to Cell B. In Cell A of the same row, place final answer '5'. Confirm that candidate '5' in Cell B is automatically cleared.
- **Step 6:** Tap "Undo" to revert the placement of final answer '5' in Cell A.
- **Expected:** Cell A's value reverts to empty, and candidate note '5' in Cell B is seamlessly restored.
- **Step 7 (Conflict Highlighting Recalculation):** Place an identical digit in the same row, column, or block to trigger red conflict highlighting. Tap "Undo".
- **Expected:** The conflict highlight immediately clears for the remaining cells.
- **Step 8 (Numpad Exhaustion Recalculation):** Place the 9th instance of a digit so its numpad button grays out. Tap "Undo".
- **Expected:** The numpad button re-enables and returns to its active visual state.
- **Step 9 (Empty Stack Safety):** Tap "Undo" repeatedly until no further actions remain in history.
- **Expected:** The app handles the empty stack gracefully with no crashes or unexpected state changes, and the button remains disabled.
- **Automated Verification:** Verified in headless CI via `game/tests/test_undo_manager.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming empty stack safety, sequential final answer undo, sequential candidate note undo, compound action peer candidate restoration, conflict/exhaustion recalculation, dynamic undo button disabled/enabled state synchronization (`test_undo_signal`), and state serialization.

## Test 10.0: Puzzle Menus (Reset & New Game)
- **Step 1:** Enter a game, make several final answer inputs, toggle several candidate notes, and observe the elapsed timer (e.g. at 01:25).
- **Step 2:** Tap the triple-dot menu ("...") on the top-right header and select "Reset Puzzle".
- **Expected:** All user-entered numbers and candidate notes are wiped clean, restoring the grid back to its initial clue configuration. The undo history is cleared (Undo button disabled), the active timer restarts at `00:00`, and `SaveManager` persists the reset puzzle state to disk.
- **Step 3:** Enter several moves again, then tap the triple-dot menu and select "New Game".
- **Expected:** The board discards the current puzzle, retrieves a brand new distinct puzzle string for the same difficulty tier from `puzzles.json`, repopulates the initial clues, wipes undo history, restarts the timer at `00:00`, and overwrites the previous save file in `SaveManager`.
- **Automated Verification:** Verified in headless CI via `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting Reset Puzzle reverts user inputs while zeroing the timer and flushing save data, and New Game loads distinct puzzle strings while resetting timer and save state.

## Test 11.0: Auto Candidate Mode
- **Step 1:** While playing a puzzle, locate the "Auto Candidate Mode" toggle below the numpad.
- **Expected (Flat Styling):** The toggle button appears as a clean, flat text checkbox without standard heavy button outlines or borders (`StyleBoxEmpty`).
- **Step 2:** Toggle it ON.
- **Expected:** All empty cells automatically populate with correct, calculated candidates.
- **Step 3:** Manually delete one of the auto-candidates using the 'X' button.
- **Expected:** The candidate is deleted and stays deleted (the auto-calculator respects user edits).
- **Step 4:** Toggle it OFF.
- **Expected:** All auto-generated candidates disappear from the board.
- **Automated Verification:** Verified in headless CI via `game/tests/test_sudoku_board.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), verifying auto-candidate toggle signals, valid candidate generation, user deletion preservation, flat stylebox overrides, and dynamic UI synchronization.

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
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` and `game/tests/test_sudoku_board.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming that conflicting answer entries trigger flat red conflict highlights on `CellUI` components without throwing exceptions or ending the game.

## Test 15.0: Win State & Victory Screen
- **Step 1:** Successfully enter the final correct number filling the entire grid with 0 conflicts.
- **Expected:** The game detects the win state. The timer halts immediately and elapsed time is captured.
- **Expected (Visual & Theme):** The Victory Screen overlay appears centered over the board with 1930s monochrome card styling (2px white borders on `#121212` background, 8px rounded corners), displaying the "VICTORY!" banner, the 1930s rubber-hose mascot artwork (`mascot_icon.jpg`), and formatted completion time (`Completion Time: MM:SS`).
- **Expected (Managers):** `StatsManager` increments `games_won`, updates best time, and recalculates average time. `SaveManager` removes the in-progress save file for this difficulty (`clear_save` / `clear_active_game`).
- **Step 2:** Tap "Admire Puzzle".
- **Expected:** The victory dialog card hides, revealing the completed Sudoku board clearly. A floating "Restore Dialog" button appears at the top right of the screen.
- **Step 3:** Tap "Restore Dialog".
- **Expected:** The victory dialog card reappears in full, and the "Restore Dialog" button hides.
- **Step 4:** Tap "Statistics".
- **Expected:** Transitions to the Statistics Screen, where the newly recorded win and updated best/average times are visibly displayed for the current difficulty tier.
- **Step 5:** Return to an active game, trigger win state, and tap "Play Again".
- **Expected:** The victory overlay dismisses, the timer resets to `00:00`, and a fresh puzzle of the same difficulty starts immediately.
- **Step 6:** Tap "<" to return to the Main Menu.
- **Expected:** The Main Menu difficulty button displays its default text (e.g. "Medium", not "Resume Medium"), confirming the completed puzzle was purged from active save tracking.
- **Automated Verification:** Verified in headless CI via `game/tests/test_victory_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting overlay activation on win signal, accurate parameter passing to `StatsManager.record_game_won` and `SaveManager.clear_save`, asset presence (`victory_overlay.tscn`, `mascot_icon.jpg`, `theme_1930s.tres`), and button routing (Play Again, Main Menu, Statistics, Admire Puzzle, Restore Dialog).

## Test 16.0: Concurrent Save Persistence & Menus
- **Step 1:** Start an Easy game. Input several numbers and candidate notes into empty cells. Perform an undo action. Let the timer run for 10 seconds. Switch apps or background the application (triggering focus loss auto-flush), then return to the Main Menu.
- **Step 2:** Start a Medium game. Input different numbers and candidate notes. Let the timer run for 20 seconds. Pause the game, then return to the Main Menu.
- **Step 3:** Start a Hard game. Input numbers and notes. Let the timer run for 30 seconds. Return to the Main Menu.
- **Expected:** The application maintains up to 3 separate active saves concurrently in `user://saves/` (`save_easy.json`, `save_medium.json`, and `save_hard.json`). The Main Menu visibly updates difficulty button labels dynamically to `"Resume Easy"`, `"Resume Medium"`, and `"Resume Hard"` when active saves exist.
- **Step 4:** Tap the "Resume Easy" button on the Main Menu.
- **Expected:** The game automatically resumes the Easy puzzle, restoring the exact board layout, user-entered numbers, candidate notes, deleted candidate notes, elapsed timer (10 seconds), and undo history stack (tapping "Undo" reverts earlier moves).
- **Step 5:** Force-close the app entirely or kill the process. Reopen the app. Verify "Resume Medium" is still displayed, and tap "Resume Medium".
- **Expected:** The Medium puzzle state (board layout, candidate notes, 20-second timer, and undo stack) is fully restored from `user://saves/save_medium.json`.
- **Step 6 (Save Overwrite):** On Easy difficulty, open the menu and start a "New Game". Make a move.
- **Expected:** The previous Easy save is cleanly overwritten with the new puzzle state, resetting the timer and undo stack.
- **Step 7 (Save Clearing):** Complete a puzzle or select "Reset Puzzle".
- **Expected:** The active save file for that difficulty is deleted (`clear_save`), and returning to the Main Menu reflects that the button reverts from `"Resume [Difficulty]"` back to its default label (`"Easy"`).
- **Automated Verification:** Verified in headless CI via `game/tests/test_save_manager.gd` and `game/tests/test_main_menu.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming concurrent saving and loading across Easy/Medium/Hard, save overwriting, complex state restoration (board, notes, undo history, elapsed seconds), save deletion, and menu label synchronization.

## Test 17.0: Selection & Number Matching Highlighting
- **Step 1:** Tap an empty or filled cell on the grid.
- **Expected (Cell & Peer Highlights):** The selected cell turns flat orange (`ThemeConstants.COLOR_SELECTION`). The rest of the cells in that same row, column, and 3x3 block turn a very light translucent orange (`ThemeConstants.COLOR_PEER_HIGHLIGHT`).
- **Expected (Text Contrast Inversion):** Any existing numbers or candidate notes inside the selected cell and all highlighted peer cells (row, column, and 3x3 block) dynamically switch from white to dark text (`#121212`) so they contrast sharply and legibly against the bright orange backgrounds.
- **Step 2:** Tap the exact same cell again.
- **Expected:** The cell (and the row/col/block highlights) deselects completely, and text colors revert to standard white (`Color.WHITE`).
- **Step 3:** Tap an empty cell, then tap anywhere outside the board.
- **Expected:** The cell deselects completely, and text colors revert to standard white.
- **Step 4:** Ensure the board has some Candidate notes entered in various cells (e.g., several '3's).
- **Step 5:** Tap a cell that contains a large, final answer '3'.
- **Expected (Large Match & Contrast):** All other cells containing a large '3' highlight in a darker orange/brownish color (`ThemeConstants.COLOR_NUMBER_MATCH`), and their numbers render in dark text (`#121212`).
- **Expected (Candidate Match):** All small candidate '3's across the entire board immediately become bold or enlarge (`note_font_bold`), distinguishing them from the other candidate numbers.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` and `game/tests/test_theme_constants.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), validating cell selection/deselection state transitions, peer highlights (`CellUI.COLOR_PEER`), number match highlights (`CellUI.COLOR_MATCH`), font color overrides (`#121212` for selected/peer/match, `Color.WHITE` for normal/conflict), and matching candidate font enlargement.

## Test 18.0: Pause Functionality & Button Styling
- **Step 1:** During an active game session, inspect the "Pause" button in the gameplay header row.
- **Expected (Pause Button Styling):** The "Pause" button displays a crisp 2px solid white border, rounded corners, and a `#121212` background conforming to the 1930s monochrome aesthetic (`res://resources/theme_1930s.tres`), distinguishing it clearly as an interactive element. Ensure the button renders the monochrome ASCII emoji `⏸︎` correctly without clipping or falling back to a missing glyph box on the target device.
- **Step 2:** Tap the "Pause" button.
- **Expected:** The timer stops immediately. The Sudoku board completely hides behind an opaque/obscuring overlay (`#121212` background at 95% opacity) displaying the 1930s monochrome mascot graphic (`mascot_icon.jpg`) scaled significantly larger (320x320) without pushing UI elements off-screen, a large "PAUSED" title, and a styled "Resume" button to prevent cheating. The screen wake lock is released (`DisplayServer.screen_set_keep_on(false)`), allowing the device to follow standard display sleep timeouts.
- **Step 3:** Inspect the "Resume" button on the pause overlay.
- **Expected (Resume Button Styling):** The "Resume" button displays a crisp 2px solid white border, rounded corners, and a `#121212` background conforming to `theme_1930s.tres`. Ensure the button renders the monochrome ASCII emoji `▶︎` correctly without clipping or falling back to a missing glyph box on the target device.
- **Step 4:** Tap the "Resume" button on the pause overlay.
- **Expected:** The pause overlay disappears, the Sudoku board reappears with all clues, entries, and candidate notes intact, the timer resumes counting from the exact second it stopped, and the screen wake lock is restored (`DisplayServer.screen_set_keep_on(true)`).
- **Automated Verification:** Verified in headless CI via `game/tests/test_game_timer.gd` and `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming timer halts during manual pause, the board hides while the pause overlay shows, theme resource assignment with 2px white borders and #121212 background (`test_button_themes_applied`), and resuming cleanly reverses both states.

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
- **Expected:** The number '5' button on the numpad visually **grays out** (it does not disappear; uses dimmed gray `ThemeConstants.COLOR_NUMPAD_EXHAUSTED` / `Color(0.4, 0.4, 0.4)`) and is disabled to indicate that nine 5s have been placed.
- **Step 2:** Tap 'Undo' or use the 'X' button to delete one of the 5s.
- **Expected:** The number '5' button on the numpad lights back up to its normal active state (`Color(1.0, 1.0, 1.0)`) and is re-enabled.
- **Step 3 (Cheat Prevention):** Intentionally place 9 instances of the number '5' on the board in completely wrong, conflicting cells.
- **Expected:** The number '5' button on the numpad MUST still gray out (ignoring whether the placements are actually correct).
- **Step 4 (Number-First Deselection):** Select digit '5' in number-first mode. Place the 9th instance of '5'.
- **Expected:** The '5' button grays out and is automatically deselected (`selected_digit` reset to -1).
- **Automated Verification:** Verified in headless CI via `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), verifying button disablement, dimmed modulation, restoration on count drop, cheat prevention, and auto-deselection.

## Test 21.0: Input Controls Layout & Sizing
- **Step 1:** Launch the game and enter an active puzzle on the Gameplay screen.
- **Step 2 (Container Margins & Alignment):** Observe the left, right, and bottom margins of the `InputControls` area below the 9x9 board.
- **Expected:** The controls section exhibits explicit 56px padding on the left and right (`MarginContainer`) to precisely align with the 9x9 board boundaries, and 48px bottom padding.
- **Step 3 (Vertical Spacing & Centering):** Observe the Mode/Undo row ("Normal", "Candidate", "Undo").
- **Expected:** The row is visually centered. "Normal", "Candidate", and "Undo" buttons possess enlarged touch target dimensions. A clear vertical spacer (16px) provides distinct separation between the mode controls and the digit keypad.
- **Step 4 (Numpad Button Sizing & Font):** Observe the 10 numpad buttons (1-9 and X).
- **Expected:** Buttons maintain an explicit minimum height of 64px and feature a larger 36px font size for improved legibility on mobile viewports.
- **Step 5 (Auto Candidate Centering & Styling):** Inspect the "Auto Candidate Mode" toggle below the numpad.
- **Expected:** The toggle lacks the standard 2px white button outline, presenting a sleek, flat checkbox/text-toggle aesthetic (`StyleBoxEmpty`), and remains visually centered below the numpad.
- **Automated Verification:** Verified in headless CI via `game/tests/test_input_controls.gd` (`test_layout_and_styling()`), asserting `MarginContainer` margin constants (56px/48px), 64px button minimum vertical heights, and `StyleBoxEmpty` theme override styleboxes on the toggle button.

## Test 22.0: Positional Candidate Notes (3x3 Micro-Grid Layout)
- **Step 1:** Start a new game and switch to Candidate mode (tap "Candidate" button or press `C`).
- **Step 2 (Isolated Note Positioning):** Select an empty cell. Input a single candidate note: digit '5'.
- **Expected:** Digit '5' appears precisely in the dead center slot (row 2, column 2) of the cell's 3x3 micro-grid. It does NOT reflow or shift to the top-left slot.
- **Step 3 (Multiple Disjoint Candidates):** Into the same cell, add candidate notes '1' and '9'.
- **Expected:**
  - '1' appears in the top-left slot (row 1, column 1).
  - '5' remains anchored in the exact center slot (row 2, column 2).
  - '9' appears in the bottom-right slot (row 3, column 3).
  - All other slots (2, 3, 4, 6, 7, 8) remain empty and transparent without reflowing or altering the grid geometry.
- **Step 4 (Candidate Note Toggling):** Tap digit '5' again to toggle it off.
- **Expected:** Digit '5' disappears from the center slot. Digits '1' and '9' maintain their exact rigid positions in the top-left and bottom-right corners without jumping or shifting.
- **Step 5 (Full 1-9 Grid Alignment):** In an empty cell, toggle all candidate digits 1 through 9.
- **Expected:** Digits 1-9 form a perfectly aligned 3x3 numpad-style grid (1, 2, 3 on top row; 4, 5, 6 on middle row; 7, 8, 9 on bottom row) with clean font sizing (16pt regular, scaling to 24pt bold on number matching) matching the 1930s monochrome aesthetic. The 20x20 minimum size lock prevents the bottom row (7, 8, 9) from touching the cell boundary, and highlighting an active number (e.g., '5') does not shift or push the bottom row out of view.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` (`test_candidates()`), verifying that all 9 candidate labels maintain permanent visibility (`visible = true`) in the `CandidatesGrid` layout container and dynamically toggle their `text` property between the digit and `""`.

 
 # #   T e s t   2 4 . 0 :   D y n a m i c   S c a l i n g   o f   S t a t i s t i c s   S c r e e n 
 
 -   * * S t e p   1 : * *   N a v i g a t e   t o   t h e   S t a t i s t i c s   s c r e e n   f r o m   t h e   M a i n   M e n u . 
 
 -   * * S t e p   2 : * *   R e s i z e   t h e   g a m e   w i n d o w   v e r t i c a l l y   ( s i m u l a t i n g   v a r i o u s   m o b i l e   a s p e c t   r a t i o s   a n d   s i z e s ) . 
 
 -   * * E x p e c t e d : * *   A l l   t h r e e   d i f f i c u l t y   c a r d s   ( E a s y ,   M e d i u m ,   H a r d )   r e m a i n   f u l l y   v i s i b l e   o n   a   s i n g l e   s c r e e n   w i t h o u t   r e q u i r i n g   s c r o l l i n g .   T h e   t e x t   f o n t   s i z e s   a n d   p a d d i n g   s c a l e   p r o p o r t i o n a l l y   t o   f i t   t h e   a v a i l a b l e   v e r t i c a l   s c r e e n   r e a l   e s t a t e   p e r f e c t l y . 
 
 -   * * A u t o m a t e d   V e r i f i c a t i o n : * *   T h e   ` i s _ i n s i d e _ t r e e ( ) `   g a t e   c h e c k s   e n s u r e   t h e   d y n a m i c   s c a l e   l o g i c   r u n s   s a f e l y   w i t h o u t   c r a s h i n g   i n   h e a d l e s s   t e s t s ,   m a i n t a i n i n g   a   1 0 0 %   p a s s   r a t e . 
 
 # #   T e s t   2 3 . 0 :   I s o l a t e   I n p u t   C o n t r o l s   B e t w e e n   D i f f i c u l t i e s 
 
 -   * * S t e p   1 : * *   S t a r t   a   n e w   ' E a s y '   g a m e .   T o g g l e   t h e   ' C a n d i d a t e '   i n p u t   m o d e   o n   a n d   c h e c k   t h e   ' A u t o   C a n d i d a t e   M o d e '   t o g g l e   o n . 
 
 -   * * S t e p   2 : * *   P a u s e   t h e   g a m e   a n d   r e t u r n   t o   t h e   M a i n   M e n u . 
 
 -   * * S t e p   3 : * *   S t a r t   a   n e w   ' M e d i u m '   g a m e . 
 
 -   * * E x p e c t e d : * *   T h e   ' M e d i u m '   g a m e   s t a r t s   f r e s h   w i t h   ' N o r m a l '   i n p u t   m o d e   a n d   ' A u t o   C a n d i d a t e   M o d e '   O F F .   T h e   t o g g l e s   f r o m   t h e   E a s y   g a m e   d i d   n o t   b l e e d   o v e r . 
 
 -   * * S t e p   4 : * *   P a u s e   t h e   ' M e d i u m '   g a m e   a n d   r e t u r n   t o   t h e   M a i n   M e n u . 
 
 -   * * S t e p   5 : * *   T a p   ' R e s u m e   E a s y ' . 
 
 -   * * E x p e c t e d : * *   T h e   ' E a s y '   g a m e   r e s t o r e s   w i t h   ' C a n d i d a t e '   i n p u t   m o d e   a n d   ' A u t o   C a n d i d a t e   M o d e '   O N   e x a c t l y   a s   t h e y   w e r e   l e f t . 
 
 -   * * A u t o m a t e d   V e r i f i c a t i o n : * *   V e r i f i e d   i n   h e a d l e s s   C I   v i a   ` g a m e / t e s t s / t e s t _ s a v e _ m a n a g e r . g d `   ( ` t e s t _ s t a t e _ i s o l a t i o n _ b e t w e e n _ d i f f i c u l t i e s ( ) ` ) ,   e n s u r i n g   i n d e p e n d e n t   t o g g l e s   a r e   s t o r e d   a n d   r e s t o r e d   c o r r e c t l y   a c r o s s   d i f f i c u l t i e s . 
 
 