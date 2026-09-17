class_name SudokuCell
extends RefCounted

signal cell_changed
signal candidates_changed
signal conflict_changed

var value: int = 0:
	set(v):
		if is_clue:
			return
		if value != v:
			value = v
			cell_changed.emit()

var is_clue: bool = false
var is_conflicting: bool = false:
	set(v):
		if is_conflicting != v:
			is_conflicting = v
			conflict_changed.emit()

var user_candidates: Array[int] = []
var user_deleted_candidates: Array[int] = []
var active_candidates: Array[int] = []

func has_candidate(num: int) -> bool:
	return active_candidates.has(num)

func toggle_candidate(num: int) -> void:
	if has_candidate(num):
		user_candidates.erase(num)
		if not user_deleted_candidates.has(num):
			user_deleted_candidates.append(num)
	else:
		user_deleted_candidates.erase(num)
		if not user_candidates.has(num):
			user_candidates.append(num)
			user_candidates.sort()

func clear_candidates() -> void:
	user_candidates.clear()
	user_deleted_candidates.clear()
	active_candidates.clear()
	candidates_changed.emit()

func remove_candidate_due_to_placement(num: int) -> void:
	if user_candidates.has(num):
		user_candidates.erase(num)
	if not user_deleted_candidates.has(num):
		user_deleted_candidates.append(num)

func update_active_candidates(auto_enabled: bool, math_valid: Array[int]) -> void:
	var new_active: Array[int] = []
	if auto_enabled:
		for c in math_valid:
			if not user_deleted_candidates.has(c):
				new_active.append(c)
		for c in user_candidates:
			if not new_active.has(c):
				new_active.append(c)
	else:
		new_active = user_candidates.duplicate()
	
	new_active.sort()
	
	var changed: bool = false
	if active_candidates.size() != new_active.size():
		changed = true
	else:
		for i in range(active_candidates.size()):
			if active_candidates[i] != new_active[i]:
				changed = true
				break
				
	if changed:
		active_candidates = new_active
		candidates_changed.emit()
