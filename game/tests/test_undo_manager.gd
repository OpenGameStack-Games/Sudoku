class_name TestUndoManager
extends "res://tests/test_base.gd"

func test_safe_behavior_empty_stack() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	
	# Attempt to undo on empty stack should not crash
	assert_false(um.has_undo())
	um.undo_last_action(board)
	assert_false(um.has_undo())
	
func test_sequential_undo_final_answers() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	
	board.set_cell_value(0, 5)
	board.set_cell_value(1, 3)
	
	assert_eq(board.cells[0].value, 5)
	assert_eq(board.cells[1].value, 3)
	assert_true(um.has_undo())
	
	# Undo last
	um.undo_last_action(board)
	assert_eq(board.cells[1].value, 0)
	assert_eq(board.cells[0].value, 5)
	
	# Undo again
	um.undo_last_action(board)
	assert_eq(board.cells[0].value, 0)
	assert_false(um.has_undo())

func test_sequential_undo_candidate_notes() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	board.set_auto_candidates(false)
	
	board.toggle_candidate(0, 1)
	board.toggle_candidate(0, 2)
	assert_true(board.cells[0].has_candidate(1))
	assert_true(board.cells[0].has_candidate(2))
	
	um.undo_last_action(board)
	assert_true(board.cells[0].has_candidate(1))
	assert_false(board.cells[0].has_candidate(2))
	
	um.undo_last_action(board)
	assert_false(board.cells[0].has_candidate(1))
	
func test_compound_action_auto_cleared_candidates() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	
	# Add some candidate notes to peer cell (1 in the same row as 0)
	board.toggle_candidate(1, 5)
	board.toggle_candidate(1, 7)
	
	# Ensure the candidates are present
	assert_true(board.cells[1].has_candidate(5))
	assert_true(board.cells[1].has_candidate(7))
	
	# Set cell 0 to 5, which should auto-clear candidate 5 from cell 1
	board.set_cell_value(0, 5)
	
	assert_false(board.cells[1].has_candidate(5))
	assert_true(board.cells[1].has_candidate(7))
	
	# Undo the value placement
	um.undo_last_action(board)
	
	# The value should be gone
	assert_eq(board.cells[0].value, 0)
	
	# The auto-cleared candidate 5 should be restored
	assert_true(board.cells[1].has_candidate(5))
	assert_true(board.cells[1].has_candidate(7))
	
func test_recalculation_of_conflicts_and_exhaustion() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	
	# Place two 5s in the same row to create a conflict
	board.set_cell_value(0, 5)
	board.set_cell_value(1, 5)
	
	assert_true(board.cells[0].is_conflicting)
	assert_true(board.cells[1].is_conflicting)
	
	# Undo the second 5
	um.undo_last_action(board)
	
	# Conflicts should be cleared
	assert_false(board.cells[0].is_conflicting)
	assert_false(board.cells[1].is_conflicting)

func test_autoload_asset_path() -> void:
	assert_true(FileAccess.file_exists("res://scripts/undo_manager.gd"), "undo_manager.gd should exist.")

func test_history_serialization() -> void:
	var um = UndoManager.new()
	um.record_value_action(0, 0, 5, [1, 2], [3], {1: [5]})
	um.record_toggle_action(2, 4, true)
	assert_true(um.has_undo())
	
	var state = um.get_history_state()
	assert_eq(state.size(), 2)
	
	var restored_um = UndoManager.new()
	restored_um.load_history_state(state)
	assert_true(restored_um.has_undo())
	assert_eq(restored_um.get_history_state().size(), 2)

func test_redo_action() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	
	board.set_cell_value(0, 5)
	assert_eq(board.cells[0].value, 5)
	assert_false(um.has_redo())
	
	um.undo_last_action(board)
	assert_eq(board.cells[0].value, 0)
	assert_true(um.has_redo())
	
	um.redo_last_action(board)
	assert_eq(board.cells[0].value, 5)
	assert_false(um.has_redo())
	assert_true(um.has_undo())

func test_redo_stack_cleared_on_new_move() -> void:
	var board = SudokuBoard.new()
	var um = UndoManager.new()
	board.undo_manager = um
	board.load_puzzle("000000000000000000000000000000000000000000000000000000000000000000000000000000000")
	
	board.set_cell_value(0, 5)
	um.undo_last_action(board)
	assert_true(um.has_redo())
	
	# New move should clear the redo stack
	board.set_cell_value(1, 3)
	assert_false(um.has_redo())

