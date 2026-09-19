class_name TestBoardUI
extends TestBase

func test_cell_instantiation() -> void:
	assert_true(FileAccess.file_exists("res://scenes/cell.tscn"), "cell.tscn file should exist on disk")
	var cell_scene = load("res://scenes/cell.tscn")
	assert_true(cell_scene != null, "Cell scene should load")
	var cell = cell_scene.instantiate() as CellUI
	assert_true(cell != null, "Cell should be CellUI")
	
	# Test candidates are 1..9
	for i in range(1, 10):
		var label = cell.get_node("CandidatesGrid/Candidate" + str(i)) as Label
		assert_true(label != null, "Candidate label %d should exist" % i)
		assert_eq(label.text, str(i), "Label text should match index")
	cell.queue_free()

func test_cell_states() -> void:
	var cell_scene = load("res://scenes/cell.tscn")
	var cell = cell_scene.instantiate() as CellUI
	
	# Wait for ready or manual call
	cell._ready()
	
	cell.set_highlight_state("selected")
	assert_eq(cell.color, CellUI.COLOR_SELECTED, "Should be selected color")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color("#121212"), "Selected state should use dark text")
	
	cell.set_highlight_state("peer")
	assert_eq(cell.color, CellUI.COLOR_PEER, "Should be peer color")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color("#121212"), "Peer state should use dark text")
	
	cell.set_highlight_state("match")
	assert_eq(cell.color, CellUI.COLOR_MATCH, "Should be match color")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color("#121212"), "Match state should use dark text")
	
	cell.set_highlight_state("conflict")
	assert_eq(cell.color, CellUI.COLOR_CONFLICT, "Should be conflict color")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color.WHITE, "Conflict state should use white text")
	
	cell.set_highlight_state("normal")
	assert_eq(cell.color, CellUI.COLOR_NORMAL, "Should be normal color")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color.WHITE, "Normal state should use white text")
	
	cell.queue_free()

func test_board_integration() -> void:
	assert_true(FileAccess.file_exists("res://scenes/board.tscn"), "board.tscn file should exist on disk")
	var board_scene = load("res://scenes/board.tscn")
	assert_true(board_scene != null, "Board scene should load")
	var board_ui = board_scene.instantiate() as BoardUI
	assert_true(board_ui != null, "Board should be BoardUI")
	
	# _ready is needed to gather cells
	board_ui._ready()
	assert_eq(board_ui.cells.size(), 81, "Should have 81 cells")
	
	var logic_board = SudokuBoard.new()
	logic_board.load_puzzle("123456789" + "0".repeat(72))
	
	board_ui.bind_to_board(logic_board)
	
	# Check value was propagated
	var first_cell = board_ui.cells[0]
	assert_eq(first_cell.get_node("ValueLabel").text, "1", "First cell should have value 1")
	
	# Simulate selection
	var selected_emitted: Array = []
	var deselected_emitted: Array = []
	board_ui.cell_selected.connect(func(r: int, c: int): selected_emitted.append([r, c]))
	board_ui.cell_deselected.connect(func(): deselected_emitted.append(true))
	
	board_ui._on_cell_selected(0, 0)
	assert_eq(selected_emitted.size(), 1, "cell_selected should be emitted")
	assert_eq(selected_emitted[0][0], 0, "Selected row should be 0")
	assert_eq(selected_emitted[0][1], 0, "Selected col should be 0")
	
	# Check highlights
	# (0,0) should be selected
	assert_eq(first_cell.color, CellUI.COLOR_SELECTED, "Selected cell should be highlighted selected")
	
	# (0,1) should be peer
	var second_cell = board_ui.cells[1]
	assert_eq(second_cell.color, CellUI.COLOR_PEER, "Peer cell should be highlighted peer")
	
	# Deselect
	board_ui._on_cell_selected(0, 0)
	assert_eq(deselected_emitted.size(), 1, "cell_deselected should be emitted")
	assert_eq(first_cell.color, CellUI.COLOR_NORMAL, "Deselected cell should be normal")
	
	# Test explicit deselect_cell method
	board_ui._on_cell_selected(0, 0)
	assert_eq(board_ui.selected_row, 0)
	board_ui.deselect_cell()
	assert_eq(board_ui.selected_row, -1)
	assert_eq(first_cell.color, CellUI.COLOR_NORMAL)
	
	# Match test: select (0,0) which contains digit 1.
	board_ui._on_cell_selected(0, 0)
	# Cell 80 (8,8) contains 1, is not in the same peer row/col/block, so it should be MATCH highlight
	logic_board.set_cell_value(80, 1)
	assert_eq(board_ui.cells[80].color, CellUI.COLOR_MATCH, "Non-peer cell with matching digit should have match highlight")
	assert_eq(board_ui.cells[80].get_node("ValueLabel").text, "1", "Cell 80 value should be updated via board_updated signal")

	# Conflict test: setting a 1 at index 9 (row 1, col 0) causes conflict in col 0
	logic_board.set_cell_value(9, 1)
	assert_eq(board_ui.cells[9].color, CellUI.COLOR_CONFLICT, "Should be conflict because of Sudoku rules!")
	
	board_ui.queue_free()

func test_candidates() -> void:
	var cell_scene = load("res://scenes/cell.tscn")
	var cell = cell_scene.instantiate() as CellUI
	cell._ready()
	
	var candidates: Array[int] = [1, 5, 9]
	cell.set_candidates(candidates, 5) # 5 is the match digit
	
	var label1 = cell.get_node("CandidatesGrid/Candidate1") as Label
	var label5 = cell.get_node("CandidatesGrid/Candidate5") as Label
	var label9 = cell.get_node("CandidatesGrid/Candidate9") as Label
	var label2 = cell.get_node("CandidatesGrid/Candidate2") as Label
	
	assert_true(label1.visible, "1 should be visible")
	assert_true(label5.visible, "5 should be visible")
	assert_true(label9.visible, "9 should be visible")
	assert_false(label2.visible, "2 should not be visible")
	
	assert_ne(label5.get_theme_font_size("font_size"), label1.get_theme_font_size("font_size"), "Matched candidate should have different font size")
	
	cell.queue_free()

func test_grid_lines_consistency() -> void:
	var board_scene = load("res://scenes/board.tscn")
	var board_ui = board_scene.instantiate() as BoardUI
	
	var margin_container = board_ui.get_node("MarginContainer") as MarginContainer
	assert_true(margin_container != null, "MarginContainer should exist for outer border")
	assert_eq(margin_container.get("theme_override_constants/margin_left"), 4, "Outer border margin_left should be 4")
	assert_eq(margin_container.get("theme_override_constants/margin_right"), 4, "Outer border margin_right should be 4")
	assert_eq(margin_container.get("theme_override_constants/margin_top"), 4, "Outer border margin_top should be 4")
	assert_eq(margin_container.get("theme_override_constants/margin_bottom"), 4, "Outer border margin_bottom should be 4")

	var macro_grid = margin_container.get_node("MacroGrid") as GridContainer
	assert_true(macro_grid != null, "MacroGrid should exist inside MarginContainer")
	assert_eq(macro_grid.get("theme_override_constants/h_separation"), 4, "Thick borders separating 3x3 blocks should be 4")
	assert_eq(macro_grid.get("theme_override_constants/v_separation"), 4, "Thick borders separating 3x3 blocks should be 4")
	
	for macro_r in range(3):
		for macro_c in range(3):
			var micro_grid = macro_grid.get_node("MicroGrid_%d_%d" % [macro_r, macro_c]) as GridContainer
			assert_true(micro_grid != null, "MicroGrid should exist")
			assert_eq(micro_grid.get("theme_override_constants/h_separation"), 1, "Thin borders within 3x3 blocks should be 1")
			assert_eq(micro_grid.get("theme_override_constants/v_separation"), 1, "Thin borders within 3x3 blocks should be 1")

	var bg = board_ui.get_node("Background") as ColorRect
	assert_true(bg != null, "Background ColorRect should exist")
	assert_eq(bg.color, Color.WHITE, "Background must be pure white to create white grid lines")

	board_ui.queue_free()
