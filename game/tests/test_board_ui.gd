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
		var label = cell.get_node("CandidatesCenter/CandidatesGrid/Slot" + str(i) + "/Candidate" + str(i)) as Label
		assert_true(label != null, "Candidate label %d should exist" % i)
		assert_eq(label.text, str(i), "Label text should match index")
	cell.queue_free()

func test_cell_value_label_layout() -> void:
	var cell_scene = load("res://scenes/cell.tscn")
	var cell = cell_scene.instantiate() as CellUI
	var value_label = cell.get_node("ValueLabel") as Label
	assert_eq(value_label.layout_mode, 1, "ValueLabel layout_mode should be 1 (Anchors)")
	assert_eq(value_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "ValueLabel horizontal_alignment should be center")
	assert_eq(value_label.vertical_alignment, VERTICAL_ALIGNMENT_CENTER, "ValueLabel vertical_alignment should be center")
	assert_eq(value_label.anchor_right, 1.0, "ValueLabel anchor_right should be 1.0")
	assert_eq(value_label.anchor_bottom, 1.0, "ValueLabel anchor_bottom should be 1.0")
	assert_eq(value_label.grow_horizontal, Control.GROW_DIRECTION_BOTH, "ValueLabel grow_horizontal should be both (2)")
	assert_eq(value_label.grow_vertical, Control.GROW_DIRECTION_BOTH, "ValueLabel grow_vertical should be both (2)")
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
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color("#a0a0a0"), "Normal state should use gray text for non-clues")
	
	cell.is_clue = true
	cell.set_highlight_state("normal")
	assert_eq(cell.get_node("ValueLabel").get_theme_color("font_color"), Color.WHITE, "Normal state should use white text for clues")
	
	cell.queue_free()

func test_cell_font_size() -> void:
	var cell_scene = load("res://scenes/cell.tscn")
	var cell = cell_scene.instantiate() as CellUI
	cell._ready()
	
	cell.set_value(5, true)
	assert_eq(cell.get_node("ValueLabel").get_theme_font_size("font_size"), 75, "Clue numbers should have 2x font size (75)")
	
	cell.set_value(5, false)
	assert_eq(cell.get_node("ValueLabel").get_theme_font_size("font_size"), 67, "Non-clue numbers should have 2x font size (67)")
	
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
	
	# All candidate labels must remain visible to preserve fixed 3x3 GridContainer slots
	for i in range(1, 10):
		var label = cell.get_node("CandidatesCenter/CandidatesGrid/Slot" + str(i) + "/Candidate" + str(i)) as Label
		assert_true(label.visible, "Candidate %d label must be visible to preserve grid layout" % i)
		assert_eq(label.text, "", "Candidate %d label text should be empty initially" % i)
	
	var candidates: Array[int] = [1, 5, 9]
	cell.set_candidates(candidates, 5) # 5 is the match digit
	
	for i in range(1, 10):
		var label = cell.get_node("CandidatesCenter/CandidatesGrid/Slot" + str(i) + "/Candidate" + str(i)) as Label
		assert_true(label.visible, "Candidate %d must stay visible in grid layout" % i)
		if i in [1, 5, 9]:
			assert_eq(label.text, str(i), "Candidate %d should display its digit" % i)
		else:
			assert_eq(label.text, "", "Inactive candidate %d should display empty string" % i)
	
	var label1 = cell.get_node("CandidatesCenter/CandidatesGrid/Slot1/Candidate1") as Label
	var label5 = cell.get_node("CandidatesCenter/CandidatesGrid/Slot5/Candidate5") as Label
	assert_ne(label5.get_theme_font_size("font_size"), label1.get_theme_font_size("font_size"), "Matched candidate should have different font size")
	
	# Clear candidates
	var empty_candidates: Array[int] = []
	cell.set_candidates(empty_candidates)
	for i in range(1, 10):
		var label = cell.get_node("CandidatesCenter/CandidatesGrid/Slot" + str(i) + "/Candidate" + str(i)) as Label
		assert_true(label.visible, "Candidate %d must remain visible when cleared" % i)
		assert_eq(label.text, "", "Candidate %d text must be empty when cleared" % i)
	
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
	assert_eq(macro_grid.get("theme_override_constants/h_separation"), 6, "Thick borders separating 3x3 blocks should be 6")
	assert_eq(macro_grid.get("theme_override_constants/v_separation"), 6, "Thick borders separating 3x3 blocks should be 6")
	
	for macro_r in range(3):
		for macro_c in range(3):
			var micro_grid = macro_grid.get_node("MicroGrid_%d_%d" % [macro_r, macro_c]) as GridContainer
			assert_true(micro_grid != null, "MicroGrid should exist")
			assert_eq(micro_grid.get("theme_override_constants/h_separation"), 2, "Thin borders within 3x3 blocks should be 2")
			assert_eq(micro_grid.get("theme_override_constants/v_separation"), 2, "Thin borders within 3x3 blocks should be 2")

	var bg = board_ui.get_node("Background") as ColorRect
	assert_true(bg != null, "Background ColorRect should exist")
	assert_eq(bg.color, Color.WHITE, "Background must be pure white to create white grid lines")

	board_ui.queue_free()

func test_numpad_digit_highlight() -> void:
	var board_scene = load("res://scenes/board.tscn")
	var board_ui = board_scene.instantiate() as BoardUI
	board_ui._ready()
	
	var logic_board = SudokuBoard.new()
	logic_board.load_puzzle("0".repeat(81))
	board_ui.bind_to_board(logic_board)
	
	logic_board.set_cell_value(10, 5)
	logic_board.toggle_candidate(11, 5)
	board_ui.deselect_cell()
	
	board_ui.set_numpad_digit(5)
	assert_eq(board_ui.cells[10].color, CellUI.COLOR_MATCH, "Cell with 5 should highlight when numpad 5 is selected")
	
	var cand_label = board_ui.cells[11].get_node("CandidatesCenter/CandidatesGrid/Slot5/Candidate5") as Label
	assert_eq(cand_label.get_theme_font_size("font_size"), 27, "Matched candidate should be enlarged")
	if cand_label.has_theme_font("note_font_bold", "Label"):
		assert_true(cand_label.has_theme_font_override("font"), "Matched candidate should have font override")
		
	board_ui.set_numpad_digit(-1)
	assert_eq(board_ui.cells[10].color, CellUI.COLOR_NORMAL, "Cell 10 should return to normal when numpad digit cleared")
	assert_false(cand_label.has_theme_font_override("font"), "Candidate font override should be cleared")
	
	board_ui.set_numpad_digit(5)
	board_ui._on_cell_selected(0, 0)
	assert_eq(board_ui.cells[10].color, CellUI.COLOR_PEER, "Selected empty cell should override numpad digit highlight")
	
	board_ui.queue_free()
