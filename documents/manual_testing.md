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
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming non-immersive mode, portrait orientation, canvas_items expand stretch, touch emulation, OpenGL compatibility renderer, and V-Sync settings.


## Test 3.0: Dynamic UI Scaling
- **Step 1:** Launch the app on devices or simulators with varying aspect ratios and screen sizes (e.g., a tall, narrow phone and a wider tablet).
- **Expected:** All UI elements (buttons, the Sudoku grid, text, and Statistics cards) dynamically adjust their anchors and margins relative to one another. There should be no overlapping text, UI clipping off the edge of the screen, or awkwardly empty spaces that break the intended layout. Confirm that the enlarged Sudoku grid (~707px board footprint with 75x75px cells) cleanly fills the portrait phone screen width with ~6.5px screen edge margins, maintaining a 1:1 square aspect ratio without vertically crowding or overlapping the header or bottom controls. Specifically on the Statistics screen, the enlarged `<` back button (font size 64) and "STATISTICS" title remain vertically centered and horizontally balanced with the spacer without clipping or overflow, and all five difficulty cards ("Very Easy", "Easy", "Medium", "Hard", and "Very Hard") and their typography scale dynamically to remain cleanly readable on a single page without requiring a scrollbar across phone and tablet aspect ratios.

## Test 4.0: Visual Theme and Assets
- **Step 1:** Navigate through the Main Menu, Statistics screen, and Gameplay screen.
- **Expected:** The entire app conforms to a 1930s monochrome cartoon aesthetic.
- **Expected (Colors):** The global palette must be **white-on-black**. The background MUST be Dark Gray (`#121212`, `ThemeConstants.COLOR_BG_DARK_GRAY`) per Material Design guidelines, rather than pure black. Fonts and lines must be white (`ThemeConstants.COLOR_UI_FOREGROUND`). Color is ONLY used for critical game moves, and the colors are flat and not overly bright.
- **Expected (Assets & Theme):** The mascot icon is visible and themed correctly. Buttons and panels apply 1930s rounded styling from `game/resources/theme_1930s.tres`.
- **Expected (Monochrome Symbols):** Buttons utilizing Unicode symbols (Undo, Pause, Resume) MUST render as flat monochrome white shapes on a dark gray background. They must NOT render as blue or colored emojis on any OS (including Windows and Android).
- **Automated Verification:** Verified in headless CI via `game/tests/test_theme_constants.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming ThemeConstants color palette definitions, distinct values, and successful loading and panel/font styling of `game/resources/theme_1930s.tres`.

## Test 4.1: Cross-Platform & Web Export Unicode Symbol Rendering (Undo, Redo, Resume)
- **Step 1:** Launch the game in a Web Export (HTML5/WebAssembly) build (e.g. running via a local web server or on itch.io) or native desktop/mobile build.
- **Step 2:** Start or resume any puzzle (e.g., Easy) to reach the Gameplay screen.
- **Step 3:** Observe the "Undo" (`↺`) and "Redo" (`↻`) buttons located on the ModeRow controls bar below the board.
- **Expected (Undo & Redo Glyphs):** The Undo button cleanly renders the `↺` anticlockwise open circle arrow glyph rotated 90 degrees counter-clockwise (`-90°` / `-PI/2`, pointing left) and the Redo button cleanly renders the `↻` clockwise open circle arrow glyph rotated 90 degrees clockwise (`+90°` / `PI/2`, pointing right) about centered pivot offsets (`Vector2(40, 40)`). Both render as crisp monochrome white shapes against the button's dark background. They must NOT render as missing glyph boxes (tofu / ``), blank empty spaces, or colored OS emojis.
- **Step 4:** Tap the Pause button (`||`) in the top navigation header to open the Pause Overlay modal.
- **Step 5:** Observe the Resume button.
- **Expected (Resume Glyph):** The Resume button cleanly renders the standard `▶` (U+25B6) triangle glyph as a crisp monochrome white symbol centered inside the button border, without falling back to missing glyph boxes or color emoji triangles.
- **Step 6:** Tap Resume to confirm interaction and verify the game unpauses.
- **Automated Verification:** Verified in headless CI via `game/tests/test_input_controls.gd` (`test_undo_redo_icons()`, asserting label existence, glyph text, centered pivot offsets, and 90-degree rotations), `game/tests/test_gameplay_screen.gd` (`test_button_themes_applied()`, asserting Resume button text is `▶`), and `game/tests/test_theme_constants.gd` (`test_theme_resource_loads()` and `test_font_symbol_coverage()`, asserting `res://assets/fonts/DejaVuSans.ttf` exists and supports `0x21BA`, `0x21BB`, and `0x25B6`, and `theme_1930s.tres` configures default button and label fonts with bundled font fallbacks).

## Test 5.0: Main Menu & Navigation
- **Step 1 (Default State):** Boot the game to the Main Menu with no existing saves.
- **Expected:** The 1930s monochrome mascot character (`mascot_icon.jpg`) is prominently centered in the upper half. The screen contains seven clear buttons reading: "Very Easy", "Easy", "Medium", "Hard", "Very Hard", "Statistics", and "Credits". A crisp, solid horizontal white separator line (`HSeparator`, `#FFFFFF`, 2px thickness) visually delineates the five difficulty buttons from the "Statistics" and "Credits" buttons without clipping or causing vertical overflow.
- **Step 2 (Resume State Indication):** If an active save exists for a difficulty tier (e.g., Easy), verify that the corresponding button dynamically updates to read `"Resume Easy"`. Unsaved difficulties remain `"Very Easy"`, `"Medium"`, `"Hard"`, and `"Very Hard"`.
- **Step 3 (Resume Navigation):** Tap a "Resume [Difficulty]" button.
- **Expected:** The app transitions to the Gameplay screen (`res://scenes/gameplay_screen.tscn`), restoring the active saved puzzle for that difficulty without incrementing `games_started` in `StatsManager`, and actively unpausing the timer to continue counting from the saved elapsed seconds.
- **Step 4 (Fresh Game Navigation):** From the Main Menu, tap a non-resumed difficulty button (e.g., "Medium").
- **Expected:** The app starts a fresh game by selecting a random puzzle string from `game/data/puzzles.json`, marks it as the active save, unconditionally resets and starts `TimeManager` at 0 (unpaused), increments `games_started` in `StatsManager`, and opens `res://scenes/gameplay_screen.tscn`.
- **Step 5 (Statistics Navigation):** Tap the "Statistics" button.
- **Expected:** The app transitions to the Statistics screen (`res://scenes/statistics_screen.tscn`).
- **Step 6 (Statistics Screen UI, Dynamic Sizing & Back Navigation):**
  - Verify the header displays the prominent "STATISTICS" title (font size 64) and an enlarged "<" back button (font size 64, ~3x original size, capped so it does not exceed the title height while remaining vertically centered and aligned with the header spacer).
  - Verify all five independent cards ("Very Easy", "Easy", "Medium", "Hard", and "Very Hard") displaying "Games Started", "Games Won", "Best Time", and "Average Time" arranged in a compact 4-column metrics layout where metric values are left-aligned beside their respective labels rather than bumping flush against the next column's labels.
  - **Single Page & No Scrollbar Verification:** Confirm that all five difficulty cards fit cleanly on a single page without any vertical scrollbar (`ScrollContainer` absent) and without clipping at top, bottom, or sides.
  - **Visual Real Estate & Readability Verification:** Verify that the statistics cards, headers (36pt base), metric labels/values (24pt base), and paddings (20px left/right, 10px top/bottom base) scale responsively to comfortably fill the screen while remaining crisp and legible.
  - Verify the 1930s monochrome styling with Dark Gray `#121212` background, crisp white borders, and balanced monochrome typography.
  - Tap the "<" button.
  - **Expected:** The app returns cleanly to the Main Menu.
- **Automated Verification:** Verified in headless CI via `game/tests/test_main_menu.gd` and `game/tests/test_statistics_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming scene asset existence, horizontal separator existence and positioning between Very Hard and Statistics buttons along with 2px white line theme styling assertions (`test_main_menu_separator`), dynamic button text adaptation for saves vs fresh states, button signal routing, statistics screen data binding across all five difficulty cards, formatting of empty vs recorded metrics, responsive styling assertions, absence of ScrollContainer, enlarged Back button font size (64px), and Back button signal wiring.

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
- **Automated Verification:** Verified in headless CI via `game/tests/test_stats_manager.gd` and `game/tests/test_statistics_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming metric tracking (starts, wins, best times, averages), JSON serialization/deserialization to `user://stats.json`, time formatting across `very_easy`, `easy`, `medium`, `hard`, and `very_hard` difficulties, and accurate visual binding to the Statistics screen labels.

## Test 5.2: Credits Menu & Studio Attributions
- **Step 1:** On the Main Menu, tap the "Credits" button.
- **Expected:** A full-screen `CreditsModal` appears as an overlay on top of the menu. The modal background must be nearly opaque (98% opacity) to ensure the UI elements behind it are adequately obscured and do not interfere with readability. The modal title reads "CREDITS".
- **Step 2:** Scroll through the modal (if necessary) and observe the attribution blocks.
- **Expected:** There are three distinct blocks for Open Game Stack, Audrain Entertainment, and GitHub. Each block features the corresponding studio/service logo and descriptive text.
- **Step 3:** Tap the Web icon button next to the Open Game Stack attribution.
- **Expected:** The system browser opens and navigates to `https://opengamestack.org/`.
- **Step 4:** Tap the Web icon button next to the Audrain Entertainment attribution.
- **Expected:** The system browser opens and navigates to `https://audrain.games/`.
- **Step 5:** Tap the Web icon button next to the GitHub attribution.
- **Expected:** The system browser opens and navigates to the OpenGameStack-Games/Sudoku GitHub repository.
- **Step 6:** Tap the "Got It!" close button at the bottom of the modal.
- **Expected:** The "Got It!" button displays a distinct 2px solid white outline (`theme_1930s.tres`) with rounded corners and a dark background, clearly identifying it as an interactive, tappable button against the dark modal background. Tapping the button dismisses the Credits modal and returns the user to the Main Menu.
- **Automated Verification:** Verified in headless CI via `game/tests/test_main_menu.gd` asserting the `CreditsButton`, `CreditsModal`, and `CloseButton` exist and are configured correctly, with `CloseButton` assigned `theme_1930s.tres`.

## Test 6.0: Gameplay Screen Layout & Navigation
- **Step 1:** On the Gameplay screen, observe the Header row.
- **Expected:** Top-left is a `<` button. Center-left is the capitalized Difficulty label ("Easy", "Medium", or "Hard"). Center-right is the active Timer label. Top-right contains the Pause button and the triple-dot menu ("..."). The header maintains at least a 48px top margin to remain clear of the non-immersive Android status bar. The header elements are properly centered and distributed with 32px separation, and scale nicely without getting misaligned or clipped on extra wide or extra tall aspect ratios. Visually verify that the `<`, `||`, and `...` header button text/icons are perfectly centered both horizontally and vertically inside their button borders, taking font baselines into account. Visually confirm that a horizontal line can pass cleanly through the center of the text inside the Back, Pause, and Menu buttons, as well as the Timer and Difficulty labels. Also verify that the Menu button now has a visible border.
- **Step 2:** Observe the Grid and controls.
- **Expected:** A 9x9 grid exists centered within an aspect ratio container, scaled to an enlarged footprint of ~707px in width (~6.5px side margins from the 720px screen edges) with 75x75px cell minimum dimensions. Below it are mode toggle buttons ("Normal" and "Candidate"), an "Undo" button spaced to the right, a 1-9 & Erase numpad, and an Auto Candidate switch.
- **Step 3:** Enter a move on the board (e.g. place a number into an empty cell), then tap the `<` button.
- **Expected:** Navigates back to the Main Menu. The Main Menu button for that difficulty now reflects `"Resume [Difficulty]"`. Tapping Resume restores the exact board state and elapsed time, confirming the `<` button successfully flushed game state to `SaveManager`.
- **Automated Verification:** Verified in headless CI via `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting header initialization, difficulty label capitalization, timer label binding, back button save flushing, and scene asset presence.

## Test 6.1: Sudoku Board Grid Lines & Visual Separation
- **Step 1:** Enter an active game on the Gameplay screen and inspect the 9x9 Sudoku board.
- **Step 2 (Grid Lines & Aesthetics):** Verify that the board exhibits crisp, pure white grid lines separating dark cells (`#222222`), conforming to the 1930s monochrome aesthetic.
- **Step 3 (Border Widths & Consistency):**
  - Verify that the outer perimeter of the enlarged 9x9 board (~707px total width, 75x75px cells) is bounded by a uniform 4px thick white border (`MarginContainer` margin = 4), leaving ~6.5px of screen margin on each side.
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
- **Expected:** The number is entered into the cell. Verify that the entered digit is rendered in a dimmer gray (`#a0a0a0`) and smaller font size (67pt) compared to the initial clue digits which remain bold, larger (75pt), and pure white (`Color.WHITE`), clearly differentiating player inputs while maintaining the 1930s monochrome aesthetic and occupying most of the 75x75px cell box without clipping borders.
- **Step 2 (Number-First Input):** Tap a number on the numpad (it highlights in flat orange `Color("ffa500")`). Note the board state before placing it anywhere.
- **Expected:** The corresponding number highlights on all existing placed cells, and any matching candidate notes dynamically bold and enlarge (scaling from 19pt to 27pt bold) within their 24x24px slots. Tap several empty cells to enter the number into them. Tapping the numpad button again deselects it and clears the board highlights.
- **Step 3 (Mode Toggles):** Tap the "Candidate" button (or press `C` on a keyboard). Observe the segmented toggle control. Tap an empty cell and input digit '3'.
- **Expected:** The "Candidate" button visually inverts (light background, dark text) to indicate it is active, and the "Normal" button reverts to inactive (dark background, light text). '3' is placed into the cell's candidate micro-grid. Tap "Normal" (or press `N`) to switch back to normal answer input mode and verify color inversion flips back.
- **Step 4 (Erase Button):** Select a cell containing a number or candidate notes, then tap the 'X' numpad button (or press `X`, `0`, `Backspace`, or `Delete` on keyboard).
- **Expected:** Final answer is cleared, or candidate notes are deleted. Clue cells remain unaffected.
- **Step 5 (Keyboard Shortcuts):** With a cell selected, press keys `1`-`9` (or numpad keys `KP_1`-`KP_9`).
- **Expected:** Corresponding digit is placed into the selected cell. Press `U` or `Ctrl+Z` to verify undo action.
- **Step 6 (Auto-Clear Candidates):** Enter candidate '5' into several cells in a row. Then enter a final answer '5' in that row.
- **Expected:** All candidate '5's in that row automatically disappear.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting cell-first and number-first input, candidate toggling, erase behavior, clue protection, keyboard shortcuts, undo emissions, candidate micro-grid synchronization, and font color differentiation (#a0a0a0 for user inputs vs white for clues).

## Test 9.0: Undo & Redo System
- **Step 1 (Initial Disabled State):** Upon starting a fresh puzzle or resetting an active puzzle, observe the "Undo" and "Redo" buttons on the controls row.
- **Expected:** Both buttons are disabled because the history stacks are empty.
- **Step 2 (Dynamic Enable on Move):** Place a digit or toggle a candidate note onto the grid.
- **Expected:** As soon as the action is performed, the "Undo" button immediately becomes enabled. The "Redo" button remains disabled.
- **Step 3 (Reverting and Redo Enable):** Tap the "Undo" button to revert the single action.
- **Expected:** The action is undone. The "Undo" button immediately becomes disabled. The "Redo" button immediately becomes enabled.
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
- **Step 10 (Redo Stack Clear on New Move):** After undoing several moves, verify that the Redo button is enabled. Place a completely new number or candidate note on the board.
- **Expected:** The Redo button immediately becomes disabled because the new action flushes the redo history stack.
- **Step 11 (Auto-Candidate Removal Undo/Redo):**
  1. Turn on Auto-Candidates.
  2. Notice the auto-candidates present.
  3. Place a number that mathematically clears some auto-candidates in the same block/row/column.
  4. Click Undo and verify the auto-candidates reappear.
  5. Click Redo and verify the auto-candidates disappear again.
- **Automated Verification:** Verified in headless CI via `game/tests/test_undo_manager.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming empty stack safety, sequential final answer undo, sequential candidate note undo, compound action peer candidate restoration, auto-candidate note restoration and redo removal, conflict/exhaustion recalculation, dynamic undo/redo button disabled/enabled state synchronization, redo stack flushing on new moves, and state serialization.

## Test 9.1: Undo State Session Isolation
- **Step 1:** Start an Easy game, make a move on the board, then tap `<` to navigate to the Main Menu.
- **Step 2:** Start a Hard game. Observe the "Undo" button.
- **Expected:** The "Undo" button is completely disabled, confirming the undo stack was cleared for the new session.
- **Step 3:** Tap `<` to navigate to the Main Menu, then tap "Resume Easy".
- **Expected:** The Easy game restores and the "Undo" button is enabled. Tap "Undo" and verify your previous move from Step 1 is undone, confirming history states are correctly restored from the save file.

## Test 10.0: Puzzle Menus (Reset & New Game)
- **Step 1:** Enter a game, make several final answer inputs, toggle several candidate notes, and observe the elapsed timer (e.g. at 01:25).
- **Step 2:** Tap the triple-dot menu ("...") on the top-right header and select "Reset Puzzle".
- **Expected:** All user-entered numbers and candidate notes are wiped clean, restoring the grid back to its initial clue configuration. The undo history is cleared (Undo button disabled), the active timer restarts at `00:00`, and `SaveManager` persists the reset puzzle state to disk.
- **Step 3:** Enter several moves again, then tap the triple-dot menu and select "New Game".
- **Expected:** The board discards the current puzzle, retrieves a brand new distinct puzzle string for the same difficulty tier from `puzzles.json`, repopulates the initial clues, wipes undo history, restarts the timer at `00:00`, and overwrites the previous save file in `SaveManager`.
- **Step 4:** Visually ensure the Triple-Dot Menu popup appears legibly across small devices without vertical clipping, scaling adequately to 3x/4x dimensions for touch accessibility.
- **Automated Verification:** Verified in headless CI via `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting Reset Puzzle reverts user inputs while zeroing the timer and flushing save data, and New Game loads distinct puzzle strings while resetting timer and save state.

## Test 11.0: Auto Candidate Mode
- **Step 1:** While playing a puzzle, locate the "Auto Candidate Mode" toggle below the numpad.
- **Expected (Flat Styling & Toggle Switch Dimensions):** The toggle button appears as a clean, flat text checkbox without standard heavy button outlines or borders (`StyleBoxEmpty`). The toggle switch icon is visibly enlarged to approximately twice the default Godot switch size (56x28 custom monochrome icon), proportioned slightly shorter than the 32px font label, vertically centered relative to the "Auto Candidate Mode" text, and clearly readable. Verify that the enlarged control does not push down or displace the numpad row or clip the 48px bottom screen margin across various portrait screen sizes and aspect ratios.
- **Step 2:** Toggle it ON.
- **Expected:** All empty cells automatically populate with correct, calculated candidates. The switch displays its active monochrome icon (solid white pill with black thumb on the right).
- **Step 3:** Manually delete one of the auto-candidates using the 'X' button.
- **Expected:** The candidate is deleted and stays deleted (the auto-calculator respects user edits).
- **Step 4:** Toggle it OFF.
- **Expected:** All auto-generated candidates disappear from the board. The switch displays its inactive monochrome icon (outlined white pill with white thumb on the left).
- **Automated Verification:** Verified in headless CI via `game/tests/test_sudoku_board.gd` and `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), verifying auto-candidate toggle signals, valid candidate generation, user deletion preservation, flat stylebox overrides, 56x28 icon sizing assertions, asset existence on disk, and dynamic UI synchronization.

## Test 11.1: UI Save State Restoration on Resume
- **Step 1:** Start a new game and toggle both "Candidate" mode and "Auto Candidate Mode" to ON.
- **Step 2:** Ensure the toggles reflect their active visual states.
- **Step 3:** Tap the `<` (Back) button to navigate to the Main Menu.
- **Step 4:** Tap the corresponding "Resume [Difficulty]" button to return to the active puzzle.
- **Expected:** The game successfully loads, and both the "Candidate" mode button and the "Auto Candidate Mode" toggle retain their active visual states and active behavior without reverting to the default "Normal" mode/OFF state.
- **Automated Verification:** Verified in headless CI via `game/tests/test_gameplay_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), which explicitly tests save loading of `auto_candidates` and `input_mode` when transitioning with an active `TimeManager`.

## Test 11.2: Candidate Notes and Auto-Candidate Toggle Persistence across Save/Resume
- **Step 1:** Launch the game and start a new puzzle on any difficulty (e.g. Medium).
- **Step 2:** Switch to Candidate mode and enter manual candidate notes (e.g., digits 1 and 2) on an empty cell.
- **Step 3:** Enable Auto Candidate Mode toggle. Confirm that auto-calculated candidates populate across all remaining empty cells. Select another cell and manually delete one of its auto-candidates (e.g., digit 8) using the 'X' button or toggling it off.
- **Step 4:** Tap the `<` (Back) button to navigate back to the Main Menu.
- **Step 5:** On the Main Menu, observe that the button dynamically reflects `"Resume Medium"`. Tap `"Resume Medium"`.
- **Step 6:** Inspect the board and input controls:
  - The Auto-Candidate toggle switch MUST remain ON.
  - The manually deleted candidate (digit 8) on the second cell MUST remain excluded.
  - The manual candidate notes (digits 1 and 2) on the first cell MUST be fully restored.
  - The 3x3 candidate micro-grids MUST be immediately visible and correctly populated without being wiped clean.
- **Step 7:** Toggle Auto-Candidate Mode to OFF. Confirm that all auto-generated candidates disappear while manual notes remain.
- **Step 8:** Tap the `<` (Back) button to return to the Main Menu, then tap `"Resume Medium"` again.
- **Step 9:** Verify that the Auto-Candidate toggle remains OFF, and the manual candidate notes on cell 1 remain intact while auto-candidates stay hidden.
- **Automated Verification:** Verified in headless CI via `game/tests/test_save_manager.gd` (`test_resume_preserves_notes_and_toggle`), `game/tests/test_sudoku_board.gd` (`test_restore_board_state`), and `game/tests/test_main_menu.gd` (`test_difficulty_selection_routes_resumed_game_with_board_state`).

## Test 12.0: Puzzle Database Load & Symmetry
- **Step 1:** Tap "Easy", "Medium", and "Hard" sequentially from the main menu, exiting back to the menu between each.
- **Expected:** The game successfully loads a puzzle string from `puzzles.json` for each difficulty without hanging or crashing. The initial clues populated on the board must exactly match the non-zero digits of the loaded string.
- **Step 2:** Observe the initial clues on the board.
- **Expected:** The layout of the clues MUST be rotationally symmetrical (180 degrees).
- **Automated Verification:** Verified in headless CI via `game/tests/test_puzzle_loader.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), which validates file existence, JSON validity, array sizes (>= 10), string lengths (81 characters), valid digits ('0'-'9'), and 180-degree rotational symmetry for all clues across `easy`, `medium`, and `hard`.

## Test 12.1: Puzzle Rule Validity & Mock Prevention
- **Step 1:** Start a new "Very Hard" game from the Main Menu.
- **Step 2:** Observe the freshly loaded board and its initial clues.
- **Expected:** The board must present a valid, playable Sudoku layout (i.e., not a string of 1s and 0s).
- **Step 3:** Visually inspect the starting clues across several rows, columns, and 3x3 macro blocks.
- **Expected:** The starting clues must adhere to standard Sudoku rules: no duplicate digits may exist within any single row, column, or 3x3 block.
- **Automated Verification:** Verified in headless CI via `game/tests/test_puzzle_loader.gd` (`_is_valid_sudoku_board`), which enforces strict validation to ensure all starting clues are unique within their respective rows, columns, and 3x3 blocks.

## Test 13.0: Android Build Export, Splash Screen & Launcher Icons
- **Step 1:** Build the Android `.apk`/`.aab` or install/run the game natively on an Android device via Godot export.
- **Step 2:** Boot the game and immediately observe the initial launch sequence.
- **Expected (Splash Screen):** The game must present a boot splash screen featuring the 1930s monochrome mascot correctly scaled and centered against a dark background before transitioning to the Main Menu.
- **Expected (JSON Packaging):** The puzzle loads perfectly. If the screen is blank or the app crashes here, the `*.json` file was likely stripped during the build process and the `export_presets.cfg` include filter (`include_filter="*.txt, *.json"`) must be verified.
- **Step 3:** Inspect the app icon on the Android launcher, home screen, and app drawer.
- **Expected (Launcher Icons):** The app must prominently display the custom mascot icon (`mascot_icon.png` configured as the standard icon and adaptive foreground) rather than the default Godot engine icon.
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), validating that `export_presets.cfg` includes `*.json` in the include filter, that `mascot_icon.png` is configured as the boot splash and icon, and that all launcher icon assets exist on disk.

## Test 13.1: CI/CD Build Download & Sideloading
- **Step 1:** Push a new version tag (e.g. `v1.0.0`) to the repository to trigger the GitHub Actions workflows.
- **Step 2 (Android Artifact):** Navigate to the Actions tab or the created Release in GitHub. Download the exported `Sudoku.aab` or `.apk` artifacts.
- **Step 3:** Use `bundletool` or adb to install the downloaded artifact onto a physical Android device or emulator.
- **Expected:** The game installs successfully, boot splash screen is displayed, and puzzle generation functions correctly (validating the include filters were respected by the automated build system).
- **Step 4 (Web Build):** Navigate to the designated itch.io page for the project after the Web build workflow completes.
- **Expected:** The HTML5 game loads properly in the browser, displays the UI correctly, and runs smoothly.


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
- **Expected (Visual & Theme):** The Victory Screen overlay appears full-screen with responsive margins over the board with 1930s monochrome card styling (4px white borders on `#121212` background, 16px rounded corners). It displays a large scaled "VICTORY!" banner, the 1930s rubber-hose mascot artwork (`mascot_icon.jpg`), and formatted completion time (`Completion Time: MM:SS`).
- **Expected (Resolution & Scaling):** Resize the game window or view on varying devices (e.g., tablet vs. tall mobile). The modal should dynamically size without clipping the scaled buttons and banner, ensuring the ~2x UI components remain readable and prominent.
- **Expected (Managers):** `StatsManager` increments `games_won`, updates best time, and recalculates average time. `SaveManager` removes the in-progress save file for this difficulty (`clear_save` / `clear_active_game`).
- **Step 2:** Tap "Admire Puzzle".
- **Expected:** The victory dialog card hides, revealing the completed 9x9 Sudoku board clearly with zero obstruction or overlap. An enlarged (440x92 px, 40pt font) "Victory Window" button appears horizontally centered below the puzzle board, prominently covering the inactive bottom input controls and numpad row.
- **Step 3:** Tap "Victory Window".
- **Expected:** The victory dialog card reappears in full, and the "Victory Window" button hides cleanly.
- **Step 4:** Tap "Statistics".
- **Expected:** Transitions to the Statistics Screen, where the newly recorded win and updated best/average times are visibly displayed for the current difficulty tier.
- **Step 5:** Return to an active game, trigger win state, and tap "Play Again".
- **Expected:** The victory overlay dismisses, the timer resets to `00:00`, and a fresh puzzle of the same difficulty starts immediately.
- **Step 6:** Inspect the new board and toggle Auto-Candidate mode ON.
- **Expected:** The new board has initial clues populated (it is not a blank grid). Auto-Candidate correctly calculates and displays candidates for the new puzzle.
- **Step 7:** Tap "<" to return to the Main Menu.
- **Expected:** The Main Menu difficulty button displays its default text (e.g. "Medium", not "Resume Medium"), confirming the completed puzzle was purged from active save tracking.
- **Automated Verification:** Verified in headless CI via `game/tests/test_victory_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting overlay activation on win signal, accurate parameter passing to `StatsManager.record_game_won` and `SaveManager.clear_save`, asset presence (`victory_overlay.tscn`, `mascot_icon.jpg`, `theme_1930s.tres`), and button routing (Play Again, Main Menu, Statistics, Admire Puzzle, Victory Window restore button).

## Test 16.0: Concurrent Save Persistence & Menus
- **Step 1:** Start an Easy game. Input several numbers and candidate notes into empty cells. Perform an undo action. Let the timer run for 10 seconds. Switch apps or background the application (triggering focus loss auto-flush), then return to the Main Menu.
- **Step 2:** Start a Medium game. Input different numbers and candidate notes. Let the timer run for 20 seconds. Pause the game, then return to the Main Menu.
- **Step 3:** Start a Hard game. Input numbers and notes. Let the timer run for 30 seconds. Return to the Main Menu.
- **Expected:** The application maintains up to 5 separate active saves concurrently in `user://saves/` (`save_very_easy.json`, `save_easy.json`, `save_medium.json`, `save_hard.json`, and `save_very_hard.json`). The Main Menu visibly updates difficulty button labels dynamically to `"Resume Very Easy"`, `"Resume Easy"`, `"Resume Medium"`, `"Resume Hard"`, and `"Resume Very Hard"` when active saves exist.
- **Step 4:** Tap the "Resume Easy" button on the Main Menu.
- **Expected:** The game automatically resumes the Easy puzzle, restoring the exact board layout, user-entered numbers, candidate notes, deleted candidate notes, elapsed timer (10 seconds), and undo history stack (tapping "Undo" reverts earlier moves).
- **Step 5:** Force-close the app entirely or kill the process. Reopen the app. Verify "Resume Medium" is still displayed, and tap "Resume Medium".
- **Expected:** The Medium puzzle state (board layout, candidate notes, 20-second timer, and undo stack) is fully restored from `user://saves/save_medium.json`.
- **Step 6 (Save Overwrite):** On Easy difficulty, open the menu and start a "New Game". Make a move.
- **Expected:** The previous Easy save is cleanly overwritten with the new puzzle state, resetting the timer and undo stack.
- **Step 7 (Save Clearing):** Complete a puzzle or select "Reset Puzzle".
- **Expected:** The active save file for that difficulty is deleted (`clear_save`), and returning to the Main Menu reflects that the button reverts from `"Resume [Difficulty]"` back to its default label (`"Easy"`).
- **Automated Verification:** Verified in headless CI via `game/tests/test_save_manager.gd` and `game/tests/test_main_menu.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming concurrent saving and loading across Very Easy/Easy/Medium/Hard/Very Hard, save overwriting, complex state restoration (board, notes, undo history, elapsed seconds), save deletion, and menu label synchronization.

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
- **Expected (Pause Button Styling):** The "Pause" button displays a crisp 2px solid white border, rounded corners, and a `#121212` background conforming to the 1930s monochrome aesthetic (`res://resources/theme_1930s.tres`), distinguishing it clearly as an interactive element. Ensure the button renders the pure monochrome text symbol `||` correctly on the target device.
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
- **Expected:** The '5' button grays out and is automatically deselected (`selected_digit` reset to -1). The board highlights for 5 should also clear.
- **Automated Verification:** Verified in headless CI via `game/tests/test_input_controls.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), verifying button disablement, dimmed modulation, restoration on count drop, cheat prevention, and auto-deselection.

## Test 21.0: Input Controls Layout & Sizing
- **Step 1:** Launch the game and enter an active puzzle on the Gameplay screen.
- **Step 2 (Container Margins & Alignment):** Observe the left, right, and bottom margins of the `InputControls` area below the 9x9 board.
- **Expected:** The controls section exhibits explicit 56px padding on the left and right (`MarginContainer`) to precisely align with the 9x9 board boundaries, and 48px bottom padding.
- **Step 3 (Vertical Spacing & Centering):** Observe the Mode/Undo row ("Normal", "Candidate", "Undo", "Redo").
- **Expected:** The row is visually centered. "Normal" and "Candidate" buttons are unified into a single segmented control with 0 separation, and the "Undo" and "Redo" buttons are spaced to their right. All buttons possess enlarged touch target dimensions. Visually verify that the "Undo" button icon (↺) points explicitly outward to the left, and the "Redo" button icon (↻) points explicitly outward to the right. A clear vertical spacer (16px) provides distinct separation between the mode controls and the digit keypad.
- **Step 4 (Numpad Button Sizing & Font):** Observe the 10 numpad buttons (1-9 and X).
- **Expected:** Buttons maintain an explicit minimum height of 80px (matching the height of the utility buttons) and feature a proportionally scaled 45px font size for improved touch ergonomics and legibility on mobile viewports.
- **Step 5 (Auto Candidate Centering & Styling):** Inspect the "Auto Candidate Mode" toggle below the numpad, especially on different aspect ratios.
- **Expected:** The toggle lacks the standard 2px white button outline, presenting a sleek, flat checkbox/text-toggle aesthetic (`StyleBoxEmpty`), and remains visually centered below the numpad. The "Auto Candidate Mode" text must be scaled up (explicitly sized to 32) and clearly readable. The layout must dynamically shift upwards such that the Numpad isn't pushed too far up or clipping into the board, while strictly maintaining the 48px bottom margin.
- **Automated Verification:** Verified in headless CI via `game/tests/test_input_controls.gd` (`test_layout_and_styling()`), asserting `MarginContainer` margin constants (56px/48px), 80px button minimum vertical heights, 45px font size, `StyleBoxEmpty` theme override styleboxes, and font size 32 on the toggle button.

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
- **Expected:** Digits 1-9 form a perfectly aligned 3x3 numpad-style grid (1, 2, 3 on top row; 4, 5, 6 on middle row; 7, 8, 9 on bottom row) with clean font sizing (19pt regular, scaling to 27pt bold on number matching) matching the 1930s monochrome aesthetic. The 24x24 minimum size lock on the Control nodes prevents the bottom row (7, 8, 9) from touching the cell boundary. **Crucially**, highlighting an active number (e.g., '5') must NOT cause any vertical layout shifting of the surrounding cells or push the bottom row out of view when the font size dynamically bolds and scales.
- **Automated Verification:** Verified in headless CI via `game/tests/test_board_ui.gd` (`test_candidates()`), verifying that all 9 candidate labels maintain permanent visibility (`visible = true`) in the `CandidatesGrid` layout container and dynamically toggle their `text` property between the digit and `""`.


## Test 24.0: Statistics Screen Dynamic Layout Scaling & 5 Difficulty Cards
- **Step 1:** Navigate to the Statistics screen from the Main Menu.
- **Step 2:** Verify that all five difficulty cards ("Very Easy", "Easy", "Medium", "Hard", and "Very Hard") are rendered simultaneously on the single page without a scrollbar.
- **Step 3 (Column Alignment & Separation Verification):** Inspect the internal 4-column layout of each card. Verify that metric values are left-aligned beside their respective labels rather than right-aligned flush against adjacent column labels (e.g., verifying clear visual separation between the `Started` / `Best Time` values and the `Won` / `Avg Time` labels without collisions).
- **Step 4:** Resize the game window vertically and horizontally (e.g., simulating large 1080p/1440p screens and very small windowed or mobile vertical aspect ratios).
- **Expected:** The entire Statistics screen scales uniformly to fit the available space without requiring a scrollbar or `ScrollContainer`. All five cards and their text (headers, difficulty titles, and metric values) scale down dynamically to prevent clipping, internal metric columns remain distinctly separated and paired, and the Back button (`<`) remains fully visible and clickable across all screen dimensions.
- **Automated Verification:** Verified in headless CI via `game/tests/test_statistics_screen.gd` (`test_no_scroll_container_properties()`, `test_statistics_screen_displays_mock_data()`, and `test_statistics_screen_styling_applied()`), ensuring that the ScrollContainer has been completely removed, the CardsContainer expands horizontally and vertically, all 5 difficulty cards bind data correctly, and metric values default to `HORIZONTAL_ALIGNMENT_LEFT`.

## Test 23.0: Isolate Input Controls Between Difficulties

- **Step 1:** Start a new 'Easy' game. Toggle the 'Candidate' input mode on and check the 'Auto Candidate Mode' toggle on.

- **Step 2:** Pause the game and return to the Main Menu.

- **Step 3:** Start a new 'Medium' game.

- **Expected:** The 'Medium' game starts fresh with 'Normal' input mode and 'Auto Candidate Mode' OFF. The toggles from the Easy game did not bleed over.

- **Step 4:** Pause the 'Medium' game and return to the Main Menu.

- **Step 5:** Tap 'Resume Easy'.

- **Expected:** The 'Easy' game restores with 'Candidate' input mode and 'Auto Candidate Mode' ON exactly as they were left.

- **Automated Verification:** Verified in headless CI via `game/tests/test_save_manager.gd` (`test_state_isolation_between_difficulties()`), ensuring independent toggles are stored and restored correctly across difficulties.


## Test 25.0: Button Hover States
- **Step 1:** Launch the app on a device or platform that supports mouse cursor input (e.g., PC, or Android with a connected mouse).
- **Step 2:** Move the mouse cursor to hover over various interactable UI buttons (e.g., Pause, Resume, Normal/Candidate toggles, Numpad digits, Easy/Medium/Hard menu buttons).
- **Expected:** The background color of the button shifts slightly to indicate the hover state, while the 2px solid white border explicitly remains visible and does not vanish or disappear during the hover.


## Test 26.0: Cell Number Prominence & Alignment
- **Step 1:** Launch the game and enter an active puzzle on the Gameplay screen.
- **Step 2:** Observe the font size of the initial clue numbers and any placed answers.
- **Expected:** Clue numbers and player answers appear very prominent (font sizes 75 and 67 respectively) within the 75x75px cell bounds, creating clear visual hierarchy over the much smaller candidate notes. They must also be perfectly centered vertically and horizontally, without clipping or overlapping the boundaries of the cells.
- **Step 3:** Enter several candidate notes in the same cell as a large main number (this would only happen if forced, but observe candidate size).
- **Expected:** The candidate notes do not visually overwhelm the main numbers, due to the main numbers' scaled prominence.

## Test 27.0: Web Export Statistics Navigation & Clean State
- **Step 1:** Launch an exported Web (HTML5) build (e.g. locally via HTTP server or in an itch.io sandbox) in a fresh browser session (or private browsing window with no cached `user://` storage data).
- **Step 2:** On the Main Menu, click the "Statistics" button.
- **Expected:** The application smoothly transitions to the Statistics screen (`res://scenes/statistics_screen.tscn`) rather than failing or remaining unresponsive. The transition must not be blocked by file access checks that fail on remapped PCK scenes.
- **Step 3:** Inspect the displayed statistics on the clean run.
- **Expected:** All difficulty cards ("Very Easy", "Easy", "Medium", "Hard", "Very Hard") display initial zero/empty state values cleanly without unhandled exceptions (Games Started: 0, Games Won: 0, Best Time: "--:--", Average Time: "--:--").
- **Step 4:** Click the back button (`<`).
- **Expected:** Cleanly returns to the Main Menu.
- **Automated Verification:** Verified in headless CI via `game/tests/test_main_menu.gd` (`test_stats_button_routing()`) and `game/tests/test_statistics_screen.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), confirming signal connection, crash-free execution, and default zero-state rendering.

## Test 28.0: Android Release Workflow & Google Play Production Deployment
- **Step 1:** Create and push a version tag conforming to `v*.*.*` (e.g., `git tag v0.1.7 && git push origin v0.1.7`) on a commit merged into `main`.
- **Step 2:** Open GitHub Actions in the repository and observe the triggered `Android Build & Release` workflow (`.github/workflows/android_release.yml`).
- **Expected (Export & Signing):** The workflow successfully runs headless Godot export, generates `Sudoku.aab`, native debug symbols (`*-native-debug-symbols.zip`), and ProGuard mapping (`mapping.txt`), and cryptographically signs the bundle using `r0adkll/sign-android-release@v1`.
- **Step 3:** Inspect the "Deploy to Google Play" workflow step.
- **Expected (Play Store Upload):** The step runs `r0adkll/upload-google-play@v1`, successfully authenticating using the `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret. It uploads `Sudoku.aab`, mapping file, and native debug symbols directly to the `production` track (`games.audrain.sudoku`) with `status: completed` without error.
- **Step 4:** Inspect the generated GitHub Release for the tagged version.
- **Expected (Release Assets):** The release contains `Sudoku.aab`, native debug symbols zip, and `mapping.txt` attached as downloadable assets.
- **Step 5:** Log in to Google Play Console, select `games.audrain.sudoku`, and navigate to **Release > Production**.
- **Expected (Console Verification):** The new release version code and name are present on the Production track in the "Completed" state, with native debug symbols and deobfuscation files successfully associated, ready for rollout to users without requiring manual bundle upload.
- **Automated Verification:** Verified via headless CI in `game/tests/test_platform_config.gd` (`assert_true("package/unique_name=\"games.audrain.sudoku\"" in content)`) and workflow syntax validation.

## Test 29.0: Device-Specific Rendering & V-Sync (Samsung Galaxy S24 Ultra / Adreno 750)
- **Step 1:** Launch the app on a Samsung Galaxy S24 Ultra (or other Adreno 750 GPU Android device with high-refresh rate display).
- **Step 2:** Interact with the game: navigate the Main Menu, start or resume a puzzle, place answers and candidate notes on the board, and toggle the Pause overlay.
- **Expected:** The application renders smoothly using the OpenGL Compatibility backend (`gl_compatibility`) with V-Sync forced enabled (`vsync_mode=1`). There must be no horizontal screen tearing, stuttering, or Vulkan driver visual artifacts during touch interactions, animations, or screen transitions.
- **Automated Verification:** Verified in headless CI via `game/tests/test_platform_config.gd` (`godot --headless --path game -s res://tests/test_runner.gd`), asserting `renderer/rendering_method="gl_compatibility"`, `renderer/rendering_method.mobile="gl_compatibility"`, and `window/vsync/vsync_mode=1` in `res://project.godot`.


