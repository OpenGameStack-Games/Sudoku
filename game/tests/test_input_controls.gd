extends "res://tests/test_base.gd"

var controls: InputControls
var board: SudokuBoard
var board_ui: BoardUI
var undo_manager: UndoManager
var scene_tree_mock: SceneTree

func before_each() -> void:
	board = SudokuBoard.new()
	undo_manager = UndoManager.new()
	board.undo_manager = undo_manager
	
	board_ui = BoardUI.new()
	var cell_scene: PackedScene = load("res://scenes/cell.tscn")
	board_ui.cells = []
	for i in range(81):
		var cell_ui: CellUI = cell_scene.instantiate() as CellUI
		cell_ui.row = i / 9
		cell_ui.col = i % 9
		board_ui.cells.append(cell_ui)
		board_ui.add_child(cell_ui)
		
	board_ui.bind_to_board(board)
	
	var controls_scene: PackedScene = load("res://scenes/input_controls.tscn")
	controls = controls_scene.instantiate() as InputControls
	
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		main_loop.root.add_child(board_ui)
		main_loop.root.add_child(controls)
	else:
		scene_tree_mock = SceneTree.new()
		# Headless environments may not have a normal SceneTree. If this executes, we skip add_child to root.
	
	controls._ready()
	controls.bind_to_board(board, board_ui)

func after_each() -> void:
	if controls:
		controls.free()
	if board_ui:
		for cell: CellUI in board_ui.cells:
			if is_instance_valid(cell): cell.free()
		board_ui.free()
	if scene_tree_mock:
		scene_tree_mock.free()

func test_scene_and_theme_resources() -> void:
	before_each()
	
	assert_true(FileAccess.file_exists("res://scenes/input_controls.tscn"), "input_controls.tscn should exist on disk")
	assert_true(controls.theme != null, "InputControls should have a valid theme loaded")
	
	after_each()

func test_layout_and_styling() -> void:
	before_each()
	
	assert_true(controls is MarginContainer, "InputControls root should be MarginContainer")
	assert_eq(controls.get_theme_constant("margin_left"), 56, "Left margin should be 56")
	assert_eq(controls.get_theme_constant("margin_right"), 56, "Right margin should be 56")
	assert_eq(controls.get_theme_constant("margin_bottom"), 48, "Bottom margin should be 48")
	
	assert_true(controls.numpad_btns.size() == 10, "Should have 10 numpad buttons (1-9 and X)")
	for btn: Button in controls.numpad_btns:
		assert_eq(btn.custom_minimum_size.y, 64.0, "Numpad buttons should have 64px minimum height")
		
	var normal_style: StyleBox = controls.auto_candidate_btn.get_theme_stylebox("normal")
	assert_true(normal_style is StyleBoxEmpty, "Auto candidate button should have StyleBoxEmpty normal style")
	assert_eq(controls.auto_candidate_btn.get_theme_font_size("font_size"), 32, "Auto candidate button should have font size 32")
	
	after_each()

func test_mode_switching() -> void:
	before_each()
	
	assert_false(controls.is_candidate_mode)
	
	controls._on_mode_candidate_pressed()
	assert_true(controls.is_candidate_mode)
	assert_eq(controls.mode_candidate_btn.modulate, Color(1.0, 1.0, 1.0))
	assert_eq(controls.mode_normal_btn.modulate, Color(0.5, 0.5, 0.5))
	
	controls._on_mode_normal_pressed()
	assert_false(controls.is_candidate_mode)
	assert_eq(controls.mode_candidate_btn.modulate, Color(0.5, 0.5, 0.5))
	assert_eq(controls.mode_normal_btn.modulate, Color(1.0, 1.0, 1.0))
	
	after_each()

func test_numpad_exhaustion() -> void:
	before_each()
	
	# Initially not exhausted
	assert_false(controls.numpad_btns[0].disabled)
	assert_eq(controls.numpad_btns[0].modulate, Color(1.0, 1.0, 1.0))
	
	# Add 9 instances of digit 1
	for i in range(9):
		board.set_cell_value(i, 1)
		
	# Check exhaustion
	assert_true(controls.numpad_btns[0].disabled)
	assert_eq(controls.numpad_btns[0].modulate, ThemeConstants.COLOR_NUMPAD_EXHAUSTED)
	
	# Remove one instance
	board.set_cell_value(8, 0)
	
	# Check de-exhaustion
	assert_false(controls.numpad_btns[0].disabled)
	assert_eq(controls.numpad_btns[0].modulate, Color(1.0, 1.0, 1.0))
	
	after_each()

func test_exhaustion_resets_selected_digit() -> void:
	before_each()
	
	controls._on_numpad_pressed(2)
	assert_eq(controls.selected_digit, 2)
	
	for i in range(9):
		board.set_cell_value(i, 2)
		
	assert_eq(controls.selected_digit, -1, "Exhausting a digit should reset selected_digit")
	assert_true(controls.numpad_btns[1].disabled)
	
	after_each()

func test_cell_first_input() -> void:
	before_each()
	
	board_ui.selected_row = 0
	board_ui.selected_col = 0
	
	controls._on_numpad_pressed(5)
	
	assert_eq(board.cells[0].value, 5)
	assert_eq(controls.selected_digit, -1) # Number shouldn't be selected in cell-first
	
	after_each()

func test_number_first_input() -> void:
	before_each()
	
	# Select number first
	controls._on_numpad_pressed(7)
	assert_eq(controls.selected_digit, 7)
	
	# Tap cell
	controls._on_cell_selected(1, 1)
	
	assert_eq(board.cells[10].value, 7)
	
	after_each()

func test_candidate_mode_input() -> void:
	before_each()
	
	controls._on_mode_candidate_pressed()
	board_ui.selected_row = 0
	board_ui.selected_col = 2
	
	controls._on_numpad_pressed(4)
	assert_true(board.cells[2].has_candidate(4))
	
	# Toggling again removes it
	controls._on_numpad_pressed(4)
	assert_false(board.cells[2].has_candidate(4))
	
	after_each()

func test_erase_button() -> void:
	before_each()
	
	board.set_cell_value(0, 8)
	board_ui.selected_row = 0
	board_ui.selected_col = 0
	
	# Erase value
	controls._on_numpad_pressed(0)
	assert_eq(board.cells[0].value, 0)
	
	# Erase candidates
	board.toggle_candidate(0, 3)
	board.toggle_candidate(0, 6)
	assert_true(board.cells[0].has_candidate(3), "Candidate 3 should be set")
	
	controls._on_numpad_pressed(0)
	assert_false(board.cells[0].has_candidate(3), "Candidate 3 should be erased")
	assert_false(board.cells[0].has_candidate(6), "Candidate 6 should be erased")
	
	after_each()

func test_clue_protection() -> void:
	before_each()
	
	board.cells[0].value = 9
	board.cells[0].is_clue = true
	board_ui.selected_row = 0
	board_ui.selected_col = 0
	
	# Attempt to overwrite clue with 4
	controls._on_numpad_pressed(4)
	assert_eq(board.cells[0].value, 9)
	
	# Attempt to erase clue
	controls._on_numpad_pressed(0)
	assert_eq(board.cells[0].value, 9)
	
	after_each()

func test_keyboard_input_routing() -> void:
	before_each()
	
	board_ui.selected_row = 0
	board_ui.selected_col = 0
	
	# Key 6
	var key_ev: InputEventKey = InputEventKey.new()
	key_ev.pressed = true
	key_ev.echo = false
	key_ev.keycode = KEY_6
	controls._unhandled_input(key_ev)
	assert_eq(board.cells[0].value, 6)
	
	# Key C -> candidate mode
	key_ev.keycode = KEY_C
	controls._unhandled_input(key_ev)
	assert_true(controls.is_candidate_mode)
	
	# Key N -> normal mode
	key_ev.keycode = KEY_N
	controls._unhandled_input(key_ev)
	assert_false(controls.is_candidate_mode)
	
	# Key X -> erase
	key_ev.keycode = KEY_X
	controls._unhandled_input(key_ev)
	assert_eq(board.cells[0].value, 0)
	
	after_each()

func test_undo_signal() -> void:
	before_each()
	
	assert_true(controls.undo_btn.disabled, "Undo button should be disabled initially")
	
	board.set_cell_value(0, 3)
	assert_eq(board.cells[0].value, 3)
	assert_false(controls.undo_btn.disabled, "Undo button should be enabled after move")
	
	controls._on_undo_pressed()
	
	assert_eq(board.cells[0].value, 0)
	assert_true(controls.undo_btn.disabled, "Undo button should be disabled after undoing")
	
	after_each()

func test_auto_candidate_toggle() -> void:
	before_each()
	
	assert_false(board.auto_candidates_enabled)
	
	controls._on_auto_candidate_toggled(true)
	
	assert_true(board.auto_candidates_enabled)
	
	after_each()
