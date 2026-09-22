class_name BoardUI
extends AspectRatioContainer

signal cell_selected(row: int, col: int)
signal cell_deselected

var cells: Array[CellUI] = []
var board: SudokuBoard = null

var selected_row: int = -1
var selected_col: int = -1
var numpad_digit: int = -1

func _ready() -> void:
	_gather_cells()
	_update_highlights()

func _gather_cells() -> void:
	cells.clear()
	var macro = $MarginContainer/MacroGrid
	if not macro:
		return
	
	# Cells are distributed in 3x3 micro grids within the 3x3 macro grid
	# So we need to map them back to 0-80 index correctly, or just by row/col.
	for r in range(9):
		for c in range(9):
			cells.append(null)
			
	for macro_r in range(3):
		for macro_c in range(3):
			var micro = macro.get_node("MicroGrid_%d_%d" % [macro_r, macro_c])
			for micro_r in range(3):
				for micro_c in range(3):
					var row = macro_r * 3 + micro_r
					var col = macro_c * 3 + micro_c
					var cell_node = micro.get_node("Cell_%d_%d" % [row, col]) as CellUI
					cell_node.row = row
					cell_node.col = col
					cell_node.cell_selected.connect(_on_cell_selected)
					var index = row * 9 + col
					cells[index] = cell_node

func bind_to_board(b: SudokuBoard) -> void:
	board = b
	board.board_updated.connect(_on_board_updated)
	_on_board_updated()

func _on_board_updated() -> void:
	if not board:
		return
	var match_digit = 0
	if selected_row != -1 and selected_col != -1:
		var sel_idx = selected_row * 9 + selected_col
		var sel_cell = board.cells[sel_idx]
		if sel_cell.value != 0:
			match_digit = sel_cell.value
	elif numpad_digit > 0:
		match_digit = numpad_digit
			
	for i in range(81):
		var b_cell = board.cells[i]
		var u_cell = cells[i]
		u_cell.set_value(b_cell.value, b_cell.is_clue)
		u_cell.set_candidates(b_cell.active_candidates, match_digit)
		
	_update_highlights()

func _on_conflict_changed() -> void:
	_update_highlights()

func set_numpad_digit(digit: int) -> void:
	numpad_digit = digit
	_on_board_updated()

func deselect_cell() -> void:
	if selected_row != -1 or selected_col != -1:
		selected_row = -1
		selected_col = -1
		cell_deselected.emit()
		_on_board_updated()

func _on_cell_selected(row: int, col: int) -> void:
	if selected_row == row and selected_col == col:
		deselect_cell()
		return
	else:
		selected_row = row
		selected_col = col
		cell_selected.emit(row, col)
		
	_on_board_updated()

func _update_highlights() -> void:
	if not board:
		return
		
	var match_digit = 0
	if selected_row != -1 and selected_col != -1:
		var sel_idx = selected_row * 9 + selected_col
		var sel_cell = board.cells[sel_idx]
		if sel_cell.value != 0:
			match_digit = sel_cell.value
	elif numpad_digit > 0:
		match_digit = numpad_digit
			
	for r in range(9):
		for c in range(9):
			var idx = r * 9 + c
			var u_cell = cells[idx]
			var b_cell = board.cells[idx]
			
			if b_cell.is_conflicting:
				u_cell.set_highlight_state("conflict")
				continue
				
			if selected_row == r and selected_col == c:
				u_cell.set_highlight_state("selected")
			elif selected_row != -1 and selected_col != -1 and (r == selected_row or c == selected_col or (r/3 == selected_row/3 and c/3 == selected_col/3)):
				u_cell.set_highlight_state("peer")
			elif match_digit != 0 and b_cell.value == match_digit:
				u_cell.set_highlight_state("match")
			else:
				u_cell.set_highlight_state("normal")
