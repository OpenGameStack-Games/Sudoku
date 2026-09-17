class_name TestBoardUI
extends TestBase

func test_cell_instantiation() -> void:
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
	
	cell.set_highlight_state("peer")
	assert_eq(cell.color, CellUI.COLOR_PEER, "Should be peer color")
	
	cell.set_highlight_state("match")
	assert_eq(cell.color, CellUI.COLOR_MATCH, "Should be match color")
	
	cell.set_highlight_state("conflict")
	assert_eq(cell.color, CellUI.COLOR_CONFLICT, "Should be conflict color")
	
	cell.set_highlight_state("normal")
	assert_eq(cell.color, CellUI.COLOR_NORMAL, "Should be normal color")
	
	cell.queue_free()

func test_board_integration() -> void:
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
	board_ui._on_cell_selected(0, 0)
	
	# Check highlights
	# (0,0) should be selected
	assert_eq(first_cell.color, CellUI.COLOR_SELECTED, "Selected cell should be highlighted selected")
	
	# (0,1) should be peer
	var second_cell = board_ui.cells[1]
	assert_eq(second_cell.color, CellUI.COLOR_PEER, "Peer cell should be highlighted peer")
	
	# Deselect
	board_ui._on_cell_selected(0, 0)
	assert_eq(first_cell.color, CellUI.COLOR_NORMAL, "Deselected cell should be normal")
	
	# Match test: (0,0) has '1', if we select (8,8) which is empty, but say we put '1' there... wait.
	# If we select (0,0), it has digit 1. Other cells with digit 1 should be MATCH.
	logic_board.set_cell_value(80, 1) # This creates a conflict but let's test MATCH logic. Wait, if conflict, conflict color overrides MATCH.
	# Let's set a conflicting 1 at (1,0) which is index 9.
	logic_board.set_cell_value(9, 1) # row 1, col 0. index = 9
	board_ui._on_cell_selected(0, 0)
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
