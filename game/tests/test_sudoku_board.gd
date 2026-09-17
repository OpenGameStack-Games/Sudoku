extends TestBase

var board: SudokuBoard

func test_autoload_exists() -> void:
	assert_true(FileAccess.file_exists("res://autoloads/game_manager.gd"), "game_manager.gd should exist")

func test_clue_loading() -> void:
	board = SudokuBoard.new()
	var puzzle: String = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
	board.load_puzzle(puzzle)
	
	assert_eq(board.cells[0].value, 5, "Cell 0 should be 5")
	assert_true(board.cells[0].is_clue, "Cell 0 should be a clue")
	assert_eq(board.cells[2].value, 0, "Cell 2 should be empty")
	assert_false(board.cells[2].is_clue, "Cell 2 should not be a clue")

func test_conflict_detection() -> void:
	board = SudokuBoard.new()
	var puzzle: String = "000000000".repeat(9) # empty board
	board.load_puzzle(puzzle)
	
	# Row conflict
	board.set_cell_value(0, 5) # (0,0)
	board.set_cell_value(8, 5) # (0,8)
	assert_true(board.cells[0].is_conflicting, "Cell 0 should conflict")
	assert_true(board.cells[8].is_conflicting, "Cell 8 should conflict")
	
	board.set_cell_value(8, 0) # Clear
	assert_false(board.cells[0].is_conflicting, "Cell 0 conflict cleared")
	
	# Col conflict
	board.set_cell_value(9, 5) # (1,0)
	assert_true(board.cells[0].is_conflicting, "Cell 0 should conflict again")
	assert_true(board.cells[9].is_conflicting, "Cell 9 should conflict")
	
	board.set_cell_value(9, 0)
	
	# Block conflict
	board.set_cell_value(10, 5) # (1,1)
	assert_true(board.cells[0].is_conflicting, "Cell 0 should conflict block")
	assert_true(board.cells[10].is_conflicting, "Cell 10 should conflict")

func test_auto_clearing_candidates() -> void:
	board = SudokuBoard.new()
	var puzzle: String = "000000000".repeat(9)
	board.load_puzzle(puzzle)
	
	board.toggle_candidate(1, 5)
	assert_true(board.cells[1].has_candidate(5), "Cell 1 should have candidate 5")
	
	# Place 5 in same row (0,0)
	board.set_cell_value(0, 5)
	assert_false(board.cells[1].has_candidate(5), "Cell 1 candidate 5 should be cleared")

func test_auto_candidate_calculation_and_preservation() -> void:
	board = SudokuBoard.new()
	var puzzle: String = "000000000".repeat(9)
	board.load_puzzle(puzzle)
	
	board.set_auto_candidates(true)
	assert_true(board.cells[0].has_candidate(5), "Cell 0 should auto-have 5")
	
	# Manually remove it
	board.toggle_candidate(0, 5)
	assert_false(board.cells[0].has_candidate(5), "Cell 0 should not have 5 after manual deletion")
	
	# Update board to trigger recalc
	board.set_cell_value(1, 1)
	assert_false(board.cells[0].has_candidate(5), "Cell 0 should STILL not have 5")
	assert_true(board.cells[0].has_candidate(6), "Cell 0 should auto-have 6")
	
	# Turn off auto
	board.set_auto_candidates(false)
	assert_false(board.cells[0].has_candidate(6), "Cell 0 auto candidate hidden")

func test_numpad_exhaustion() -> void:
	board = SudokuBoard.new()
	var puzzle: String = "000000000".repeat(9)
	board.load_puzzle(puzzle)
	
	var counts: Array[int] = [0]
	board.digit_exhausted.connect(func(d: int):
		counts[0] += 1
	)
	
	for i in range(8):
		board.set_cell_value(i, 7) # Place 7
	assert_eq(counts[0], 0, "Not exhausted yet")
	
	board.set_cell_value(8, 7) # Place 9th 7
	assert_eq(counts[0], 1, "Digit 7 exhausted")

func test_win_detection() -> void:
	board = SudokuBoard.new()
	# Valid completed puzzle
	var puzzle: String = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
	board.load_puzzle(puzzle)
	assert_true(board.is_game_won, "Game should be won immediately if puzzle is complete and valid")
	
	# Introduce conflict
	board.cells[0].is_clue = false
	board.set_cell_value(0, 3)
	assert_false(board.is_game_won, "Game should not be won with conflict")
