class_name SudokuBoard
extends RefCounted

signal board_updated
signal conflict_found(index: int)
signal conflict_cleared(index: int)
signal game_won
signal digit_exhausted(digit: int)

var cells: Array[SudokuCell] = []
var undo_manager: UndoManager = null
var auto_candidates_enabled: bool = false
var is_game_won: bool = false

func _init() -> void:
	for i in range(81):
		var cell: SudokuCell = SudokuCell.new()
		cell.cell_changed.connect(_on_cell_changed.bind(i))
		cells.append(cell)

func load_puzzle(puzzle_string: String) -> void:
	is_game_won = false
	for i in range(81):
		var char_val: String = puzzle_string.substr(i, 1)
		var val: int = char_val.to_int()
		var cell: SudokuCell = cells[i]
		
		# Bypass the setter limitations during initialization
		cell.is_clue = false
		cell.value = val
		cell.is_clue = (val != 0)
		cell.is_conflicting = false
		cell.user_candidates.clear()
		cell.user_deleted_candidates.clear()
		cell.active_candidates.clear()
		
	_evaluate_conflicts()
	_update_all_candidates()
	_check_exhaustion_all()
	_check_win_condition()
	board_updated.emit()

func set_auto_candidates(enabled: bool) -> void:
	if auto_candidates_enabled != enabled:
		auto_candidates_enabled = enabled
		_update_all_candidates()
		board_updated.emit()

func toggle_candidate(index: int, digit: int) -> void:
	if index < 0 or index >= 81 or digit < 1 or digit > 9:
		return
	var cell: SudokuCell = cells[index]
	if cell.value != 0:
		return
	var was_added: bool = not cell.has_candidate(digit)
	if undo_manager:
		undo_manager.record_toggle_action(index, digit, was_added)
	
	cell.toggle_candidate(digit)
	cell.update_active_candidates(auto_candidates_enabled, _get_math_valid_candidates(index))
	board_updated.emit()

func set_cell_value(index: int, value: int) -> void:
	if index < 0 or index >= 81:
		return
	var cell: SudokuCell = cells[index]
	if cell.is_clue or cell.value == value:
		return
		
	var old_val: int = cell.value
	
	var cleared_peer_candidates: Dictionary = {}
	if value != 0:
		var peers: Array[int] = _get_peers(index)
		for p in peers:
			if cells[p].user_candidates.has(value):
				cleared_peer_candidates[p] = [value]
				
	if undo_manager:
		undo_manager.record_value_action(
		index, old_val, value, 
		cell.user_candidates.duplicate(),
		cell.user_deleted_candidates.duplicate(),
		cleared_peer_candidates
	)
	
	cell.value = value
	
	if value != 0:
		cell.clear_candidates()
		_clear_peer_candidates(index, value)
		
	_evaluate_conflicts()
	_update_all_candidates()
	
	if old_val != 0:
		_check_exhaustion(old_val)
	if value != 0:
		_check_exhaustion(value)
		
	_check_win_condition()
	board_updated.emit()

func _on_cell_changed(index: int) -> void:
	# Handled internally via set_cell_value for player actions.
	pass

func _evaluate_conflicts() -> void:
	var value_counts: Dictionary = {} # cell_index -> Array of conflicting cell indices
	
	for i in range(81):
		cells[i].is_conflicting = false
		if cells[i].value == 0:
			continue
			
		var r: int = i / 9
		var c: int = i % 9
		var val: int = cells[i].value
		
		# Check peers
		for p in _get_peers(i):
			if cells[p].value == val:
				cells[i].is_conflicting = true
				cells[p].is_conflicting = true
				
func _clear_peer_candidates(index: int, val: int) -> void:
	var peers: Array[int] = _get_peers(index)
	for p in peers:
		cells[p].remove_candidate_due_to_placement(val)

func _update_all_candidates() -> void:
	for i in range(81):
		if cells[i].value == 0:
			var math_valid: Array[int] = _get_math_valid_candidates(i)
			cells[i].update_active_candidates(auto_candidates_enabled, math_valid)
		else:
			cells[i].active_candidates.clear()

func _get_math_valid_candidates(index: int) -> Array[int]:
	var valid: Array[int] = []
	var peers: Array[int] = _get_peers(index)
	var peer_vals: Dictionary = {}
	for p in peers:
		if cells[p].value != 0:
			peer_vals[cells[p].value] = true
			
	for digit in range(1, 10):
		if not peer_vals.has(digit):
			valid.append(digit)
	return valid

func _get_peers(index: int) -> Array[int]:
	var peers: Array[int] = []
	var r: int = index / 9
	var c: int = index % 9
	var block_r: int = r / 3
	var block_c: int = c / 3
	
	for i in range(9):
		# Row
		var row_idx: int = r * 9 + i
		if row_idx != index and not peers.has(row_idx):
			peers.append(row_idx)
		# Col
		var col_idx: int = i * 9 + c
		if col_idx != index and not peers.has(col_idx):
			peers.append(col_idx)
			
	for br in range(3):
		for bc in range(3):
			var b_idx: int = (block_r * 3 + br) * 9 + (block_c * 3 + bc)
			if b_idx != index and not peers.has(b_idx):
				peers.append(b_idx)
				
	return peers

func _check_exhaustion_all() -> void:
	for digit in range(1, 10):
		_check_exhaustion(digit)

func _check_exhaustion(digit: int) -> void:
	if digit == 0:
		return
	var count: int = 0
	for i in range(81):
		if cells[i].value == digit:
			count += 1
	if count >= 9:
		digit_exhausted.emit(digit)

func _check_win_condition() -> void:
	var all_filled: bool = true
	var no_conflicts: bool = true
	
	for i in range(81):
		if cells[i].value == 0:
			all_filled = false
			break
		if cells[i].is_conflicting:
			no_conflicts = false
			break
			
	var newly_won: bool = (all_filled and no_conflicts)
	if newly_won and not is_game_won:
		is_game_won = true
		game_won.emit()
	elif not newly_won and is_game_won:
		is_game_won = false


func _undo_value_action(index: int, old_val: int, new_val: int, old_user_candidates: Array[int], old_user_deleted_candidates: Array[int], cleared_peer_candidates: Dictionary) -> void:
	var cell: SudokuCell = cells[index]
	
	# Revert value
	cell.value = old_val
	
	# Restore cell's own candidates
	cell.user_candidates = old_user_candidates.duplicate()
	cell.user_deleted_candidates = old_user_deleted_candidates.duplicate()
	
	# Restore peer candidates that were auto-cleared
	if new_val != 0:
		for p in cleared_peer_candidates.keys():
			for digit in cleared_peer_candidates[p]:
				var peer_cell: SudokuCell = cells[p]
				if not peer_cell.user_candidates.has(digit):
					peer_cell.user_candidates.append(digit)
					peer_cell.user_candidates.sort()
				if peer_cell.user_deleted_candidates.has(digit):
					peer_cell.user_deleted_candidates.erase(digit)
	
	_evaluate_conflicts()
	_update_all_candidates()
	
	if old_val != 0:
		_check_exhaustion(old_val)
	if new_val != 0:
		_check_exhaustion(new_val)
		
	_check_win_condition()
	board_updated.emit()

func _undo_toggle_action(index: int, digit: int, was_added: bool) -> void:
	var cell: SudokuCell = cells[index]
	
	if was_added:
		if cell.user_candidates.has(digit):
			cell.user_candidates.erase(digit)
		if not cell.user_deleted_candidates.has(digit):
			cell.user_deleted_candidates.append(digit)
	else:
		if cell.user_deleted_candidates.has(digit):
			cell.user_deleted_candidates.erase(digit)
		if not cell.user_candidates.has(digit):
			cell.user_candidates.append(digit)
			cell.user_candidates.sort()
			
	cell.update_active_candidates(auto_candidates_enabled, _get_math_valid_candidates(index))
	board_updated.emit()
