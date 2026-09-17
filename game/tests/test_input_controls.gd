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
		var cell_ui = cell_scene.instantiate() as CellUI
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
		for cell in board_ui.cells:
			if is_instance_valid(cell): cell.free()
		board_ui.free()
	if scene_tree_mock:
		scene_tree_mock.free()

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
	assert_eq(controls.numpad_btns[0].modulate, Color(0.4, 0.4, 0.4))
	
	# Remove one instance
	board.set_cell_value(8, 0)
	
	# Check de-exhaustion
	assert_false(controls.numpad_btns[0].disabled)
	assert_eq(controls.numpad_btns[0].modulate, Color(1.0, 1.0, 1.0))
	
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

func test_undo_signal() -> void:
	before_each()
	
	board.set_cell_value(0, 3)
	assert_eq(board.cells[0].value, 3)
	
	controls._on_undo_pressed()
	
	assert_eq(board.cells[0].value, 0)
	
	after_each()

func test_auto_candidate_toggle() -> void:
	before_each()
	
	assert_false(board.auto_candidates_enabled)
	
	controls._on_auto_candidate_toggled(true)
	
	assert_true(board.auto_candidates_enabled)
	
	after_each()
