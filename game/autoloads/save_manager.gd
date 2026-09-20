## Manages persistence of game states across multiple difficulties.
## Handles automatic background saving on state transitions.
extends Node

const SAVE_DIR: String = "user://saves"

var current_difficulty: String = ""
var current_puzzle_string: String = ""

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## Sets the currently active game to enable auto-flushing.
func mark_active_game(difficulty: String, puzzle_string: String) -> void:
	current_difficulty = difficulty
	current_puzzle_string = puzzle_string
	_connect_signals()

## Clears the currently tracked active game (e.g. on win or manual reset) and its save.
func clear_active_game() -> void:
	if current_difficulty != "":
		clear_save(current_difficulty)
	current_difficulty = ""
	current_puzzle_string = ""

func _connect_signals() -> void:
	var game_manager_node = get_node_or_null("/root/GameManager")
	var action_manager_node = get_node_or_null("/root/ActionManager")
	
	if game_manager_node and game_manager_node.board and not game_manager_node.board.board_updated.is_connected(flush_save):
		game_manager_node.board.board_updated.connect(flush_save)
	if action_manager_node and not action_manager_node.history_changed.is_connected(flush_save):
		action_manager_node.history_changed.connect(flush_save)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		flush_save()

## Automatically collects current state from all managers and flushes it to disk.
func flush_save() -> void:
	if current_difficulty == "" or current_puzzle_string == "":
		return
	
	var game_manager_node = get_node_or_null("/root/GameManager")
	var action_manager_node = get_node_or_null("/root/ActionManager")
	var time_manager_node = get_node_or_null("/root/TimeManager")
	
	var board_state: Array = []
	if game_manager_node and game_manager_node.board:
		for i in range(81):
			var cell = game_manager_node.board.cells[i]
			board_state.append({
				"index": i,
				"value": cell.value,
				"candidates": cell.user_candidates.duplicate(),
				"deleted_candidates": cell.user_deleted_candidates.duplicate()
			})
			
	var undo_stack: Array = []
	if action_manager_node:
		undo_stack = action_manager_node.get_history_state()
		
	var elapsed: int = 0
	if time_manager_node:
		elapsed = time_manager_node.get_elapsed_seconds()
		
	var input_mode: bool = false
	var auto_candidates: bool = false
	if game_manager_node and game_manager_node.board:
		auto_candidates = game_manager_node.board.auto_candidates_enabled
		
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if tree.current_scene and tree.current_scene.has_method("_on_pause_pressed"): # check if it's gameplay screen
			var input_controls: Node = tree.current_scene.get_node_or_null("VBoxContainer/InputControls")
			if input_controls and input_controls.get("is_candidate_mode") != null:
				input_mode = input_controls.is_candidate_mode
		
	var save_data := {
		"difficulty": current_difficulty,
		"puzzle_string": current_puzzle_string,
		"board_state": board_state,
		"undo_stack": undo_stack,
		"elapsed_seconds": elapsed,
		"auto_candidates": auto_candidates,
		"input_mode": input_mode
	}
	
	save_game(current_difficulty, save_data)

func _get_save_path(difficulty: String) -> String:
	return SAVE_DIR + "/save_" + difficulty + ".json"

## Checks if an in-progress save exists for a given difficulty.
func has_save(difficulty: String) -> bool:
	var path: String = _get_save_path(difficulty)
	return FileAccess.file_exists(path)

## Persists state as JSON.
func save_game(difficulty: String, save_data: Dictionary) -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		
	var path: String = _get_save_path(difficulty)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for writing: " + path)
		return false
		
	var json_string := JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	print_debug("SaveManager: Saved game for difficulty %s" % difficulty)
	return true

## Restores saved state. Returns empty dictionary if missing or corrupted.
func load_game(difficulty: String) -> Dictionary:
	var path: String = _get_save_path(difficulty)
	if not FileAccess.file_exists(path):
		return {}
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("SaveManager: Failed to open save file for reading: " + path)
		return {}
		
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_warning("SaveManager: Corrupted save file detected, returning empty state for %s." % difficulty)
		return {}
		
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("SaveManager: Save file does not contain a dictionary, returning empty state for %s." % difficulty)
		return {}
		
	print_debug("SaveManager: Loaded game for difficulty %s" % difficulty)
	return data as Dictionary

## Removes save file when a game is won or abandoned.
func clear_save(difficulty: String) -> void:
	var path: String = _get_save_path(difficulty)
	if FileAccess.file_exists(path):
		var dir := DirAccess.open(SAVE_DIR)
		if dir:
			var err := dir.remove("save_" + difficulty + ".json")
			if err != OK:
				push_warning("SaveManager: Failed to remove save file for %s." % difficulty)
			else:
				print_debug("SaveManager: Cleared save for difficulty %s" % difficulty)
