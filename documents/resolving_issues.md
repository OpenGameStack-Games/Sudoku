# Issue Resolution Workflow & Standards

This document establishes the official standards, Git worktree workflow, and coding guidelines for anyone resolving issues in the **Sudoku** repositoryâ€”whether human contributor or autonomous agent.

---

## 0. Operational Rules
* **PowerShell Chaining:** When executing shell commands, NEVER use `&&` to chain commands together (it requires PowerShell 7+). Instead, use `;` or execute commands sequentially in separate tool calls.
* **File Generation Encoding:** Generating text files via PowerShell pipes (e.g., `>` or `Set-Content`) or .NET APIs often creates UTF-16 LE encoding errors or adds a UTF-8 BOM (Byte Order Mark). Godot will completely fail to parse `.tscn` files that contain a BOM (`Parse Error: Expected '['`). ALWAYS use the `write_to_file` and `replace_file_content` agent tools to generate/edit text or script files to ensure proper UTF-8 encoding without BOMs.
* **Documentation Redundancy:** Before requesting the PR Reviewer to document a feature or testing steps, always verify if the documentation already exists in `documents/requirements.md` or `documents/manual_testing.md`. Do not duplicate existing specification notes.

## 1. Role Overview & Core Boundaries

The **Issue Resolver** is responsible for taking an open issue from conception to an unmerged, thoroughly tested, and documented Pull Request.

### Primary Responsibilities
1. **Triage & Select:** Identify the next unblocked issue based on issue number and dependencies.
2. **Worktree Isolation:** Create and work within an isolated Git worktree under `.worktrees/`.
3. **Implement:** Write clean, modular, and statically typed GDScript code meeting all acceptance criteria.
4. **Test:** Run the automated test suite and add new automated tests in `game/tests/` verifying the change.
5. **Detailed Pull Request:** Push the feature branch and submit a highly detailed PR against `main`.

### Explicit Boundaries (What the Issue Resolver Does NOT Do)
* **DO NOT merge into `main`:** The Issue Resolver must never merge the PR or push directly to `main`.
* **DO NOT update project documentation:** Updating `documents/requirements.md`, `documents/manual_testing.md`, or `README.md` is handled by the **PR Reviewer & Documentation Agent**. The resolver provides the necessary handoff details in the PR body so the reviewing agent can update documentation accurately.

---

## 2. Issue Discovery & Triage Protocol

When tasked with resolving an issue, follow this triage procedure:

### 1. Inspect Open Issues
List open issues via the GitHub CLI:
```powershell
gh issue list --state open
```

> [!WARNING]
> **NEVER run a bare `gh issue view <id>` command.** The repository's token configuration will trigger a `read:project` scope error for the bare command. You must ALWAYS use the `--json` flag to avoid this error.

Inspect the issue details using JSON output:
```powershell
gh issue view <issue_number> --json title,body,state,labels,assignees
```

### 2. Dependency Checking (`Depends on #X`)
* Read the issue description carefully.
* If the issue header contains **`Depends on #<number>`**, check the status of the dependency:
  ```powershell
  gh issue view <dependency_number> --json state
  ```
* If the dependency issue is still `OPEN`, **do not begin work on this issue**. Move to the next unblocked issue or report the blocker.
* Only begin work if all dependencies are `CLOSED` and their pull requests merged into `main`.

### 3. Issue Selection Strategy
Unless instructed to work on a specific issue:
1. Select the lowest-numbered open issue that has no open dependencies.
2. If multiple issues are ready, prioritize bugs and foundational features (`core`, `autoloads`) before downstream UI enhancements.

---

## 3. Git Worktree & Branching Workflow

All work must occur inside an isolated worktree to keep the primary working tree clean.

### 1. Ensure `main` is Synchronized
```powershell
git checkout main
git pull origin main
```

### 2. Create the Worktree
Create a new feature branch and isolated worktree inside `.worktrees/`:
```powershell
git worktree add .worktrees/issue-<number> -b feature/issue-<number>-<short-description>
```
*Example:*
```powershell
git worktree add .worktrees/issue-21 -b feature/issue-21-absent-color-red
```

### 3. Commit Guidelines
* Follow [Conventional Commits](https://www.conventionalcommits.org/):
  * `feat: <description>` for new features
  * `fix: <description>` for bug fixes
  * `test: <description>` for test additions
  * `refactor: <description>` for code restructuring
* Keep commits atomic, well-described, and focused on the issue.

---

## 4. Coding & Architecture Standards

### Godot 4.x & GDScript Standards
1. **Project Configuration (`project.godot`):**
   * Emulating touch from mouse must use the correct Godot 4 path: `input_devices/pointing/emulate_touch_from_mouse=true`.
2. **Asset Generation & Metadata:**
   * Using Python (e.g., `Pillow` or standard libraries) to generate or manipulate assets like PNG icons is completely acceptable and encouraged.
   * For complex non-scene Godot resources (like `Theme` `.tres` files), avoid manual raw text manipulation. Instead, write a temporary Godot CLI script (e.g. `godot --headless -s generate.gd`) utilizing `ResourceSaver`. However, for minor tweaks to `.tscn` (scene) files (like attaching a theme or modifying a property), standard string/text replacement is preferred, as saving a `PackedScene` via `ResourceSaver` can destructively strip child nodes if their `owner` is not perfectly reassigned.
   * However, for heavily nested, repetitive UI scenes (like an 81-cell board `.tscn`), using a Python string-generation script to directly construct the `.tscn` file is endorsed. If a script doesn't exist, proactively write and execute a temporary Python generator script rather than attempting huge, error-prone manual text replacements. This approach avoids GDScript `PackedScene` hierarchy/owner initialization quirks.
   * **CRITICAL**: Godot 4 generates `.uid` metadata files alongside `.gd` scripts, scenes, and assets. Always stage and commit these `.uid` files alongside your changes.
3. **Static Typing Everywhere:**
   * Always annotate variable types and function returns. This applies equally to production scripts AND unit test files (`tests/*.gd`).
   * Dynamic node lookups (`get_node()`, `get_node_or_null()`) MUST include explicit type annotations and type casting (e.g., `var node: TargetType = get_node_or_null(...) as TargetType`).
     ```gdscript
     var current_row: int = 0
     var secret_word: String = ""
     func evaluate_guess(guess: String) -> Array[int]:
     ```
2. **Naming Conventions:**
   * **Classes & Nodes:** `PascalCase` (e.g., `GameBoard`, `KeyboardKey`)
   * **Variables & Functions:** `snake_case` (e.g., `current_guess`, `_on_tile_pressed()`)
   * **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_ATTEMPTS = 6`, `COLOR_BG_ABSENT`)
   * **Signals:** `snake_case` in past tense or action oriented (e.g., `letter_submitted`, `row_completed`)
3. **Commenting & Documentation:**
   * Do not write redundant comments stating the obvious.
   * Document the *intent*, *assumptions*, or mathematical/algorithmic logic.
   * Every autoload and major script must contain a header docstring explaining its domain responsibility.

4. **UI Design & Styling:**
   * Any custom container or card components created in `.tscn` scenes MUST include explicit `StyleBoxFlat` definitions (e.g. 2px white borders, 8px rounded corners, `#121212` backgrounds, and content margins) or bind directly to `game/resources/theme_1930s.tres` to guarantee the 1930s monochrome aesthetic is fully implemented. Do not submit bare unstyled panels.
   * For highly dynamic element styling based on game state (e.g. text color inverting when a cell is highlighted), prefer using GDScript runtime overrides (like `add_theme_color_override`) inside the component's script rather than attempting to create duplicate/complex static `.tscn` resources.
   * When using `GridContainer`, remember that Godot natively ignores invisible children (`visible = false`), causing remaining nodes to reflow. If you need fixed slot positions (like a numpad layout), you must keep the nodes visible and manage their empty state via text clearing (`text = ""`) or modulate/opacity.
   * When constructing compound screens (e.g., `GameplayScreen` that instances `BoardUI` and `InputControls`), the root screen script is responsible for explicitly wiring its child components to the underlying domain models (e.g., `child.board = GameManager.board`). Verify that methods invoked on child nodes actually exist on those component scripts before calling them.
5. **Post-Game State Management:**
   * When handling win conditions or game resets, ALWAYS invoke `SaveManager.clear_active_game()` rather than a bare `SaveManager.clear_save()`. This ensures memory states (like current difficulty and puzzle string) are fully wiped, preventing focus-loss events from inadvertently auto-flushing a completed game back to disk.

---

## 5. Logging Standards

Avoid raw `print()` statements in production code. Use categorized, engine-native logging:
* `print_debug(...)`: Diagnostic info and state transitions (e.g., `print_debug("GameManager: Started game in mode %s" % mode_name)`).
* `push_warning(...)`: Non-fatal issues or recoverable conditions (e.g., `push_warning("SaveManager: Corrupted save file detected, resetting.")`).
* `push_error(...)`: Critical logic failures or invariant violations.

---

## 6. Automated Testing Standards

Every feature or bug fix touching game logic or autoloads must be backed by automated tests.

### Agentic Visual QA (MCP Bridge)
If your issue involves UI layout, coloring, or visual polish, you MUST visually verify your changes before submitting the PR.
1. Run the game in the background (`godot --path game`).
2. This will automatically spin up the `McpInteractionServer` AutoLoad.
3. Use your MCP tools (or raw TCP payloads to port 9090) to capture a screenshot (`{"command":"screenshot"}`) and inspect the SceneTree.
4. Visually verify that your changes adhere to the 1930s style guidelines, look good, and don't break existing layouts.

### Test Architecture
* Tests are located in `game/tests/`.
* Test scripts inherit from `res://tests/test_base.gd`.
* Every test method starts with `test_`.
* Assertions use `assert_true()`, `assert_false()`, `assert_eq()`, and `assert_ne()`.
* **CRITICAL**: When modifying UI layout or styling, do not assume unit tests are unnecessary. Write lightweight structural assertions directly validating the theme overrides or layout constants (e.g. `assert_eq(node.get_theme_constant("margin_left"), 16)` or `assert_eq(node.custom_minimum_size.y, 64)`).
* **CRITICAL**: When adding an Autoload, configuring an asset path in `project.godot`/`export_presets.cfg`, or generating standalone resources (like `.tres` files), you MUST add a unit test that asserts `FileAccess.file_exists(...)` for that exact path to ensure the asset actually exists and wasn't skipped or renamed.
* **CRITICAL**: GDScript lambdas capture primitives by VALUE, not by reference. When using inline lambdas to verify signal emissions, you must capture variables via an `Array` wrapper (e.g., `var count: Array[int] = [0]`) or an object property, otherwise the outer scope will not reflect updates made inside the lambda.
* **CRITICAL**: The `test_runner.gd` does not initialize `project.godot` autoloads natively. To ensure testability, avoid hardcoded singleton identifier calls (e.g., `StatsManager.do_something()`) inside `RefCounted`, core logic classes, or even other autoloads. Instead, use dependency injection, or look up peer singletons dynamically using `Engine.get_main_loop().root.get_node_or_null("StatsManager")` (or simply `/root/SingletonName`). If the class uses global identifiers directly, test suite compilation will fail with "Identifier not found". When verifying or fixing Autoload behavior, always grep `project.godot` to confirm their exact exact registration names and paths.
* **CRITICAL**: When testing `Control` nodes headlessly, `_ready()` is NOT invoked organically unless nodes enter the active scene tree. For simple scripts without deep dependencies, you may manually invoke `mock_node._ready()`. However, for compound UI components, you should build a proper mock `SceneTree` structure (e.g. `Engine.get_main_loop().root.add_child(mock_node)`) in your test setup to ensure `_ready()` fires organically across all nested children, then `remove_child` and `free` them in teardown.

### Running Automated Tests
> [!NOTE]
> The custom `test_runner.gd` does NOT currently support automatic `before_each()` or `after_each()` hooks. If your tests require state isolation (e.g. wiping a `user://` save file), you must manually call your setup and teardown methods inside every single `test_*` function. Additionally, because the runner exits without cycling idle frames, always use `.free()` instead of `.queue_free()` when cleaning up mock Nodes to prevent ObjectDB memory leaks.

> [!WARNING]
> Testing `DisplayServer` state methods (like `screen_is_kept_on()`) will FAIL when running tests via the headless runner. You must bypass these assertions using `if DisplayServer.get_name() != "headless":`.

Run the headless Godot test suite. First, **CRITICALLY**, force an editor import pass to cache any newly added binary files or `class_name` definitions:
```powershell
godot --headless --editor --quit --path game
godot --headless --path game -s res://tests/test_runner.gd
```
*(Note: This requires the Godot executable directory to be in your system's PATH, and the executable to be named `godot` or `godot.exe`/`godot.bat`).*

### Verification Gate
* **Zero Failures:** All existing and newly created tests must pass (`Test Results: X Passed, 0 Failed`, exit code 0).
* If any test fails, resolve the regression before pushing.

---

## 7. Submitting the Pull Request

Once the fix is implemented and verified:

### 1. Push Feature Branch
```powershell
git push -u origin feature/issue-<number>-<short-description>
```

### 2. Create the Pull Request
Submit the PR targeting `main` using GitHub CLI. The PR body must follow the **Highly Detailed Pull Request Standard** (pre-populated automatically from `.github/pull_request_template.md`) so that the PR Reviewer & Documentation Agent has all the required context.

```powershell
# Write the PR body to a temporary markdown file using the write_to_file tool, then use:
gh pr create --title "<type>: <concise description> (Resolves #<number>)" --body-file pr_body.md --base main
```

### Required PR Body Structure
Every PR submitted by an Issue Resolver must include:
1. **Closes / Resolves Link:** `Resolves #<number>`
2. **Problem & Context:** Summary of the issue being addressed and root cause.
3. **Key Changes & Technical Scope:** Detailed breakdown of modified, added, or deleted files with architectural rationale.
4. **Automated Test Results:** Test execution output confirming pass count and new test methods introduced.
5. **Handoff for PR Reviewer & Documentation Agent:**
   * Specific recommendations on which sections of `documents/requirements.md` need updates.
   * Recommended manual test cases for `documents/manual_testing.md`.
   * Any `README.md` updates if player-facing UI/mechanics changed.

### 3. Stop and Stand Down
After opening the PR:
* **Do not merge the pull request.**
* **Do not delete the worktree yet** (it can be kept until the PR is merged by the reviewer agent, or cleaned up once the PR branch is confirmed safely on remote).
* Report the PR URL and summary back to the user.


