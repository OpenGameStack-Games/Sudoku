class_name TestGameplayScreen
extends TestBase

class MockTimeManager extends Node:
	signal time_updated(secs: int, fmt: String)
	var _active: bool = false
	var _manual_pause: bool = false
	var _elapsed_seconds: int = 0
	func start(initial_seconds: int = 0) -> void:
		_active = true
		_elapsed_seconds = initial_seconds
	func pause() -> void:
		_manual_pause = true
	func resume() -> void:
		_manual_pause = false
	func reset() -> void:
		_elapsed_seconds = 0
		_active = false
	func get_elapsed_seconds() -> int:
		return _elapsed_seconds
	func get_formatted_time() -> String:
		var m: int = _elapsed_seconds / 60
		var s: int = _elapsed_seconds % 60
		return "%02d:%02d" % [m, s]

class MockSaveManager extends Node:
	var current_difficulty: String = ""
	var current_puzzle_string: String = ""
	var flush_called: bool = false
	func mark_active_game(diff: String, puzzle: String) -> void:
		current_difficulty = diff
		current_puzzle_string = puzzle
	func has_save(diff: String) -> bool:
		return false
	func load_game(diff: String) -> Dictionary:
		return {}
	func clear_active_game() -> void:
		current_difficulty = ""
		current_puzzle_string = ""
	func flush_save() -> void:
		flush_called = true

class MockGameManager extends Node:
	signal game_won
	var board: SudokuBoard
	func _ready() -> void:
		board = SudokuBoard.new()
		board.undo_manager = UndoManager.new()
	func start_game(puzzle: String) -> void:
		if board:
			board.load_puzzle(puzzle)

var screen: GameplayScreen
var time_manager_node: MockTimeManager
var save_manager_node: MockSaveManager
var game_manager_node: MockGameManager

func _setup_nodes(diff: String = "medium") -> void:
	time_manager_node = MockTimeManager.new()
	save_manager_node = MockSaveManager.new()
	save_manager_node.current_difficulty = diff
	
	game_manager_node = MockGameManager.new()
	game_manager_node._ready()
	
	var scene: PackedScene = load("res://scenes/gameplay_screen.tscn") as PackedScene
	screen = scene.instantiate() as GameplayScreen
	
	screen.time_manager_node = time_manager_node
	screen.save_manager_node = save_manager_node
	screen.game_manager_node = game_manager_node

	screen._ready()

func _teardown_nodes() -> void:
	if screen:
		screen.free()
	if time_manager_node:
		time_manager_node.free()
	if save_manager_node:
		save_manager_node.free()
	if game_manager_node:
		if game_manager_node.board and game_manager_node.board.undo_manager:
			game_manager_node.board.undo_manager.free()
		game_manager_node.free()

func test_scenes_and_assets_exist() -> void:
	assert_true(FileAccess.file_exists("res://scenes/gameplay_screen.tscn"), "gameplay_screen.tscn should exist on disk")
	assert_true(FileAccess.file_exists("res://scenes/pause_overlay.tscn"), "pause_overlay.tscn should exist on disk")
	assert_true(FileAccess.file_exists("res://assets/icons/mascot_icon.jpg"), "mascot_icon.jpg should exist on disk")
	assert_true(FileAccess.file_exists("res://data/puzzles.json"), "puzzles.json should exist on disk")

func test_header_initialization() -> void:
	_setup_nodes("medium")
	
	assert_eq(screen.difficulty_label.text, "Medium", "Difficulty label should display capitalized difficulty")
	assert_eq(screen.timer_label.text, "00:00", "Timer label should initialize to 00:00")
	
	var header_margin: MarginContainer = screen.get_node("VBoxContainer/Header") as MarginContainer
	assert_eq(header_margin.get_theme_constant("margin_top"), 48, "Header top margin should be scaled to 48")
	
	var header_hbox: HBoxContainer = screen.get_node("VBoxContainer/Header/HBoxContainer") as HBoxContainer
	assert_eq(header_hbox.get_theme_constant("separation"), 32, "Header items should have 32 separation")
	assert_eq(header_hbox.alignment, BoxContainer.ALIGNMENT_CENTER, "Header items should be centrally aligned")
	
	_teardown_nodes()

func test_pause_button_toggles_board_and_timer() -> void:
	_setup_nodes("medium")
	
	time_manager_node.start(10)
	assert_false(screen.pause_overlay.visible, "Pause overlay should initially be hidden")
	assert_true(screen.board_node.visible, "Board should initially be visible")
	
	# Press Pause
	screen.pause_button.pressed.emit()
	assert_true(screen.pause_overlay.visible, "Pause overlay should be visible when paused")
	assert_false(screen.board_node.visible, "Board should be hidden when paused")
	assert_true(time_manager_node._manual_pause, "Timer should be paused")
	
	# Press Resume
	screen.pause_overlay.resume_requested.emit()
	assert_false(screen.pause_overlay.visible, "Pause overlay should be hidden after resume")
	assert_true(screen.board_node.visible, "Board should be visible after resume")
	assert_false(time_manager_node._manual_pause, "Timer should resume")
	
	_teardown_nodes()

func test_reset_puzzle() -> void:
	_setup_nodes("medium")
	
	var initial_clues: String = "100" + "0".repeat(78)
	save_manager_node.current_puzzle_string = initial_clues
	game_manager_node.board.load_puzzle(initial_clues)
	
	# Enter player move
	game_manager_node.board.set_cell_value(1, 5)
	assert_eq(game_manager_node.board.cells[1].value, 5, "Cell 1 should have user value 5")
	
	time_manager_node.start(45)
	assert_eq(time_manager_node.get_elapsed_seconds(), 45)
	
	# Trigger Reset via MenuButton popup
	save_manager_node.flush_called = false
	screen._on_menu_item_pressed(0)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0, "Timer should be reset to 0")
	assert_eq(game_manager_node.board.cells[1].value, 0, "User input should be reset to initial empty clue")
	assert_true(save_manager_node.flush_called, "SaveManager should be flushed after reset")
	
	_teardown_nodes()

func test_new_game() -> void:
	_setup_nodes("easy")
	
	var old_puzzle: String = "1".repeat(81)
	save_manager_node.current_puzzle_string = old_puzzle
	time_manager_node.start(120)
	
	save_manager_node.flush_called = false
	screen._on_menu_item_pressed(1)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0, "Timer should be reset to 0 on new game")
	assert_true(save_manager_node.current_puzzle_string != old_puzzle, "New game should load a fresh puzzle string")
	assert_eq(save_manager_node.current_puzzle_string.length(), 81, "New puzzle string should have length 81")
	assert_true(save_manager_node.flush_called, "SaveManager should be flushed on new game")
	
	_teardown_nodes()

func test_deselection_on_background_touch() -> void:
	_setup_nodes("medium")
	
	# Simulate cell selection on board
	screen.board_node._on_cell_selected(0, 0)
	assert_eq(screen.board_node.selected_row, 0, "Cell (0,0) should be selected")
	assert_eq(screen.board_node.selected_col, 0, "Cell (0,0) should be selected")
	
	# Simulate background mouse click
	var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	screen._on_background_gui_input(mouse_event)
	
	assert_eq(screen.board_node.selected_row, -1, "Cell should be deselected after background click")
	assert_eq(screen.board_node.selected_col, -1, "Cell should be deselected after background click")
	
	_teardown_nodes()

func test_button_themes_applied() -> void:
	_setup_nodes("medium")
	
	assert_true(screen.pause_button.theme != null, "Pause button should have a theme applied")
	assert_true(screen.pause_overlay.resume_button.theme != null, "Resume button should have a theme applied")
	
	var pause_style: StyleBoxFlat = screen.pause_button.theme.get_stylebox("normal", "Button") as StyleBoxFlat
	assert_true(pause_style != null, "Pause button theme should define a normal Button style")
	assert_eq(pause_style.border_color, Color.WHITE, "Pause button border should be white")
	assert_eq(pause_style.bg_color.to_html(false), Color("#121212").to_html(false), "Pause button background should be #121212")
	assert_eq(pause_style.border_width_left, 2, "Pause button border width left should be 2")
	assert_eq(pause_style.border_width_top, 2, "Pause button border width top should be 2")
	assert_eq(pause_style.border_width_right, 2, "Pause button border width right should be 2")
	assert_eq(pause_style.border_width_bottom, 2, "Pause button border width bottom should be 2")
	
	var resume_style: StyleBoxFlat = screen.pause_overlay.resume_button.theme.get_stylebox("normal", "Button") as StyleBoxFlat
	assert_true(resume_style != null, "Resume button theme should define a normal Button style")
	assert_eq(resume_style.border_color, Color.WHITE, "Resume button border should be white")
	assert_eq(resume_style.bg_color.to_html(false), Color("#121212").to_html(false), "Resume button background should be #121212")
	assert_eq(resume_style.border_width_left, 2, "Resume button border width left should be 2")
	assert_eq(resume_style.border_width_top, 2, "Resume button border width top should be 2")
	assert_eq(resume_style.border_width_right, 2, "Resume button border width right should be 2")
	assert_eq(resume_style.border_width_bottom, 2, "Resume button border width bottom should be 2")
	
	assert_eq(screen.pause_button.get_node("Label").text, "||", "Pause button text should be ||")
	assert_eq(screen.pause_overlay.resume_button.text, "▶︎", "Resume button text should be ▶︎")
	
	_teardown_nodes()

func test_menu_button_scale_and_font_size() -> void:
	_setup_nodes("medium")
	
	assert_eq(screen.menu_button.custom_minimum_size.x, 80, "MenuButton custom_minimum_size width should be 80")
	assert_eq(screen.menu_button.custom_minimum_size.y, 80, "MenuButton custom_minimum_size height should be 80")
	
	var label = screen.menu_button.get_node("Label")
	assert_true(label != null, "MenuButton should have a Label child")
	assert_eq(label.get_theme_font_size("font_size"), 64, "MenuButton Label font size should be 64")
	assert_eq(label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "MenuButton Label should be centered horizontally")
	assert_eq(label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER, "MenuButton Label should be centered vertically")
	
	var popup: PopupMenu = screen.menu_button.get_popup()
	assert_true(popup != null, "PopupMenu should exist")
	assert_eq(popup.get_theme_font_size("font_size"), 48, "PopupMenu font size should be 48")
	
	_teardown_nodes()

func test_pause_overlay_mascot_size() -> void:
	_setup_nodes("medium")
	
	var mascot_rect: TextureRect = screen.pause_overlay.get_node_or_null("Panel/CenterContainer/VBoxContainer/MascotRect") as TextureRect
	assert_true(mascot_rect != null, "MascotRect should exist on pause overlay")
	assert_eq(mascot_rect.custom_minimum_size.x, 320, "MascotRect custom_minimum_size width should be 320")
	assert_eq(mascot_rect.custom_minimum_size.y, 320, "MascotRect custom_minimum_size height should be 320")
	
	_teardown_nodes()

func test_play_again() -> void:
	_setup_nodes("medium")
	
	var old_puzzle: String = "1".repeat(81)
	save_manager_node.current_puzzle_string = old_puzzle
	time_manager_node.start(120)
	
	# Simulate winning the game
	save_manager_node.current_difficulty = "medium"
	screen._on_game_won()
	
	# After _on_game_won(), active game should be cleared
	assert_eq(save_manager_node.current_difficulty, "", "Active game should be cleared after win")
	assert_eq(save_manager_node.current_puzzle_string, "", "Active game puzzle should be cleared after win")
	
	# Verify that Play Again loads a new game with the correct difficulty instead of a blank string
	save_manager_node.flush_called = false
	screen._on_play_again_requested()
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0, "Timer should be reset to 0 on Play Again")
	assert_true(save_manager_node.current_puzzle_string != old_puzzle, "Play Again should load a fresh puzzle string")
	assert_eq(save_manager_node.current_puzzle_string.length(), 81, "New puzzle string should have length 81")
	assert_eq(save_manager_node.current_difficulty, "medium", "New game should inherit previous difficulty")
	assert_true(save_manager_node.flush_called, "SaveManager should be flushed on new game")
	
	_teardown_nodes()
