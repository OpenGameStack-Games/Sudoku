class_name UndoManager
extends Node

signal history_changed
signal undo_performed
signal redo_performed

var _history: Array[Dictionary] = []
var _redo_history: Array[Dictionary] = []

func record_value_action(index: int, old_value: int, new_value: int, old_user_candidates: Array, old_user_deleted_candidates: Array, cleared_peer_candidates: Dictionary) -> void:
	var typed_user: Array[int] = []
	typed_user.assign(old_user_candidates)
	var typed_deleted: Array[int] = []
	typed_deleted.assign(old_user_deleted_candidates)
	
	_history.append({
		"type": "value",
		"index": index,
		"old_value": old_value,
		"new_value": new_value,
		"old_user_candidates": typed_user,
		"old_user_deleted_candidates": typed_deleted,
		"cleared_peer_candidates": cleared_peer_candidates
	})
	_redo_history.clear()
	history_changed.emit()

func record_toggle_action(index: int, digit: int, was_added: bool) -> void:
	_history.append({
		"type": "toggle",
		"index": index,
		"digit": digit,
		"was_added": was_added
	})
	_redo_history.clear()
	history_changed.emit()

func has_undo() -> bool:
	return _history.size() > 0

func has_redo() -> bool:
	return _redo_history.size() > 0

func undo_last_action(board: SudokuBoard) -> void:
	if _history.is_empty():
		return
	
	var action: Dictionary = _history.pop_back()
	_redo_history.append(action)
	
	if action["type"] == "value":
		board._undo_value_action(action["index"], action["old_value"], action["new_value"], action["old_user_candidates"], action["old_user_deleted_candidates"], action["cleared_peer_candidates"])
	elif action["type"] == "toggle":
		board._undo_toggle_action(action["index"], action["digit"], action["was_added"])
		
	history_changed.emit()
	undo_performed.emit()

func redo_last_action(board: SudokuBoard) -> void:
	if _redo_history.is_empty():
		return
	
	var action: Dictionary = _redo_history.pop_back()
	_history.append(action)
	
	if action["type"] == "value":
		board._redo_value_action(action["index"], action["old_value"], action["new_value"], action["cleared_peer_candidates"])
	elif action["type"] == "toggle":
		board._redo_toggle_action(action["index"], action["digit"], action["was_added"])
		
	history_changed.emit()
	redo_performed.emit()

func clear_history() -> void:
	_history.clear()
	_redo_history.clear()
	history_changed.emit()

func get_history_state() -> Array:
	return _history.duplicate(true)

func get_redo_history_state() -> Array:
	return _redo_history.duplicate(true)

func load_history_state(state: Array, redo_state: Array = []) -> void:
	var typed_state: Array[Dictionary] = []
	for item in state:
		if typeof(item) == TYPE_DICTIONARY:
			typed_state.append(item as Dictionary)
	_history = typed_state
	
	var typed_redo: Array[Dictionary] = []
	for item in redo_state:
		if typeof(item) == TYPE_DICTIONARY:
			typed_redo.append(item as Dictionary)
	_redo_history = typed_redo
	
	history_changed.emit()


