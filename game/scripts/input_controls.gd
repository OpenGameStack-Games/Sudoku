class_name InputControls
extends VBoxContainer

signal mode_changed(is_candidate_mode: bool)
signal auto_candidate_toggled(enabled: bool)
signal undo_requested

var board: SudokuBoard = null
var board_ui: BoardUI = null

var selected_digit: int = -1
var is_candidate_mode: bool = false

@onready var mode_normal_btn: Button = $ModeRow/NormalBtn
@onready var mode_candidate_btn: Button = $ModeRow/CandidateBtn
@onready var undo_btn: Button = $ModeRow/UndoBtn

@onready var auto_candidate_btn: CheckButton = $AutoRow/AutoCandidateBtn

var numpad_btns: Array[Button] = []

func _ready() -> void:
	for i in range(1, 10):
		var btn: Button = get_node("NumpadRow/Btn%d" % i) as Button
		numpad_btns.append(btn)
		btn.pressed.connect(_on_numpad_pressed.bind(i))
		
	var erase_btn: Button = $NumpadRow/BtnX as Button
	numpad_btns.append(erase_btn)
	erase_btn.pressed.connect(_on_numpad_pressed.bind(0))
	
	mode_normal_btn.pressed.connect(_on_mode_normal_pressed)
	mode_candidate_btn.pressed.connect(_on_mode_candidate_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	auto_candidate_btn.toggled.connect(_on_auto_candidate_toggled)
	
	_update_mode_buttons()

func bind_to_board(b: SudokuBoard, ui: BoardUI) -> void:
	board = b
	board_ui = ui
	
	board.board_updated.connect(_on_board_updated)
	if board.undo_manager:
		board.undo_manager.history_changed.connect(_on_history_changed)
	
	board_ui.cell_selected.connect(_on_cell_selected)
	
	_on_board_updated()
	_on_history_changed()
	
	# Sync auto candidate mode
	auto_candidate_btn.button_pressed = board.auto_candidates_enabled

func _on_board_updated() -> void:
	_update_numpad_exhaustion()

func _on_history_changed() -> void:
	if not board or not board.undo_manager:
		undo_btn.disabled = true
		return
	undo_btn.disabled = not board.undo_manager.has_undo()

func _update_numpad_exhaustion() -> void:
	if not board:
		return
		
	var counts: Dictionary = {}
	for i in range(1, 10):
		counts[i] = 0
		
	for i in range(81):
		var val: int = board.cells[i].value
		if val != 0:
			counts[val] += 1
			
	for i in range(1, 10):
		var btn: Button = numpad_btns[i - 1]
		if counts[i] >= 9:
			btn.modulate = ThemeConstants.COLOR_NUMPAD_EXHAUSTED
			btn.disabled = true
			if selected_digit == i:
				selected_digit = -1
		else:
			btn.disabled = false
			if selected_digit == i:
				btn.modulate = Color(0.8, 1.0, 0.8)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0)
				
	if numpad_btns.size() > 9:
		var erase_btn: Button = numpad_btns[9]
		if selected_digit == 0:
			erase_btn.modulate = Color(0.8, 1.0, 0.8)
		else:
			erase_btn.modulate = Color(1.0, 1.0, 1.0)

func _on_mode_normal_pressed() -> void:
	is_candidate_mode = false
	_update_mode_buttons()
	mode_changed.emit(false)

func _on_mode_candidate_pressed() -> void:
	is_candidate_mode = true
	_update_mode_buttons()
	mode_changed.emit(true)

func _update_mode_buttons() -> void:
	if is_candidate_mode:
		mode_normal_btn.modulate = Color(0.5, 0.5, 0.5)
		mode_candidate_btn.modulate = Color(1.0, 1.0, 1.0)
	else:
		mode_normal_btn.modulate = Color(1.0, 1.0, 1.0)
		mode_candidate_btn.modulate = Color(0.5, 0.5, 0.5)

func _update_numpad_selection() -> void:
	_update_numpad_exhaustion()

func _on_numpad_pressed(digit: int) -> void:
	# Cell-first mode
	if board_ui and board_ui.selected_row != -1:
		_apply_digit_to_cell(board_ui.selected_row, board_ui.selected_col, digit)
		return
		
	# Number-first mode
	if selected_digit == digit:
		selected_digit = -1
	else:
		selected_digit = digit
		
	_update_numpad_selection()

func _on_cell_selected(row: int, col: int) -> void:
	if selected_digit != -1:
		_apply_digit_to_cell(row, col, selected_digit)
		# After applying in number-first mode, deselect the cell visually in BoardUI
		# (But wait, we can't easily deselect without calling _on_cell_selected on the cell)
		# This is handled if player re-taps, but usually it's fine.
		if board_ui:
			board_ui.selected_row = -1
			board_ui.selected_col = -1
			board_ui._on_board_updated()

func _apply_digit_to_cell(row: int, col: int, digit: int) -> void:
	if not board: return
	var index: int = row * 9 + col
	if board.cells[index].is_clue:
		return
	if digit == 0:
		if board.cells[index].value != 0:
			board.set_cell_value(index, 0)
		else:
			board.cells[index].clear_candidates()
			board.board_updated.emit()
	else:
		if is_candidate_mode:
			board.toggle_candidate(index, digit)
		else:
			board.set_cell_value(index, digit)

func _on_undo_pressed() -> void:
	if board and board.undo_manager:
		board.undo_manager.undo_last_action(board)
	undo_requested.emit()

func _on_auto_candidate_toggled(toggled_on: bool) -> void:
	if board:
		board.set_auto_candidates(toggled_on)
	auto_candidate_toggled.emit(toggled_on)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var handled: bool = false
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_on_numpad_pressed(event.keycode - KEY_0)
			handled = true
		elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
			_on_numpad_pressed(event.keycode - KEY_KP_0)
			handled = true
		elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE or event.keycode == KEY_0 or event.keycode == KEY_KP_0 or event.keycode == KEY_X:
			_on_numpad_pressed(0)
			handled = true
		elif event.keycode == KEY_C:
			_on_mode_candidate_pressed()
			handled = true
		elif event.keycode == KEY_N:
			_on_mode_normal_pressed()
			handled = true
		elif event.keycode == KEY_U or (event.keycode == KEY_Z and event.is_command_or_control_pressed()):
			_on_undo_pressed()
			handled = true
			
		if handled:
			var vp: Viewport = get_viewport()
			if vp:
				vp.set_input_as_handled()
