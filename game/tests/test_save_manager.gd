extends "res://tests/test_base.gd"

const SaveManagerClass = preload("res://autoloads/save_manager.gd")
var save_manager: Node

func _setup_manager() -> void:
	save_manager = SaveManagerClass.new()
	save_manager._ready()
	_teardown_manager() # Ensure clean state

func _teardown_manager() -> void:
	if save_manager:
		save_manager.clear_save("easy")
		save_manager.clear_save("medium")
		save_manager.clear_save("hard")

func test_autoload_path() -> void:
	assert_true(FileAccess.file_exists("res://autoloads/save_manager.gd"), "Save manager script should exist at expected path")

func test_concurrent_saving_and_loading() -> void:
	_setup_manager()
	
	var easy_data := {"difficulty": "easy", "elapsed_seconds": 100}
	var medium_data := {"difficulty": "medium", "elapsed_seconds": 200}
	var hard_data := {"difficulty": "hard", "elapsed_seconds": 300}
	
	save_manager.save_game("easy", easy_data)
	save_manager.save_game("medium", medium_data)
	save_manager.save_game("hard", hard_data)
	
	assert_true(save_manager.has_save("easy"), "Should have easy save")
	assert_true(save_manager.has_save("medium"), "Should have medium save")
	assert_true(save_manager.has_save("hard"), "Should have hard save")
	
	var loaded_easy = save_manager.load_game("easy")
	var loaded_medium = save_manager.load_game("medium")
	var loaded_hard = save_manager.load_game("hard")
	
	assert_eq(loaded_easy["elapsed_seconds"], 100, "Easy data should match")
	assert_eq(loaded_medium["elapsed_seconds"], 200, "Medium data should match")
	assert_eq(loaded_hard["elapsed_seconds"], 300, "Hard data should match")
	
	_teardown_manager()

func test_overwriting_save() -> void:
	_setup_manager()
	
	var initial_data := {"puzzle_string": "123", "elapsed_seconds": 50}
	save_manager.save_game("easy", initial_data)
	
	var new_data := {"puzzle_string": "456", "elapsed_seconds": 0}
	save_manager.save_game("easy", new_data)
	
	var loaded = save_manager.load_game("easy")
	assert_eq(loaded["puzzle_string"], "456", "Overwritten data should have new puzzle_string")
	assert_eq(loaded["elapsed_seconds"], 0, "Overwritten data should have new elapsed_seconds")
	
	_teardown_manager()

func test_restoration_of_complex_state() -> void:
	_setup_manager()
	
	var complex_state := {
		"difficulty": "medium",
		"puzzle_string": "123456789",
		"board_state": [
			{"index": 0, "value": 1, "candidates": []},
			{"index": 1, "value": 0, "candidates": [2, 3]}
		],
		"undo_stack": [
			{"action": "set_value", "index": 0, "old": 0, "new": 1}
		],
		"elapsed_seconds": 350
	}
	
	save_manager.save_game("medium", complex_state)
	var loaded = save_manager.load_game("medium")
	
	assert_eq(loaded["difficulty"], "medium", "Difficulty matches")
	assert_eq(loaded["puzzle_string"], "123456789", "Puzzle string matches")
	assert_eq(loaded["elapsed_seconds"], 350, "Elapsed seconds matches")
	
	var board = loaded["board_state"] as Array
	assert_eq(board.size(), 2, "Board state size matches")
	assert_eq(board[1]["candidates"].size(), 2, "Candidates array size matches")
	assert_eq(board[1]["candidates"][0], 2, "Candidates value matches")
	
	var undo = loaded["undo_stack"] as Array
	assert_eq(undo.size(), 1, "Undo stack size matches")
	assert_eq(undo[0]["action"], "set_value", "Undo stack action matches")
	
	_teardown_manager()

func test_clearing_save() -> void:
	_setup_manager()
	
	save_manager.save_game("hard", {"test": true})
	assert_true(save_manager.has_save("hard"), "Save should exist")
	
	save_manager.clear_save("hard")
	assert_false(save_manager.has_save("hard"), "Save should be cleared")
	
	var loaded = save_manager.load_game("hard")
	assert_true(loaded.is_empty(), "Loading cleared save should return empty dict")
	
	_teardown_manager()

func test_graceful_recovery_from_corruption() -> void:
	_setup_manager()
	
	# Manually write bad JSON
	var path: String = save_manager.SAVE_DIR + "/save_easy.json"
	if not DirAccess.dir_exists_absolute(save_manager.SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(save_manager.SAVE_DIR)
		
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ bad json")
	file.close()
	
	var loaded = save_manager.load_game("easy")
	assert_true(loaded.is_empty(), "Loading corrupted save should return empty dict")
	
	_teardown_manager()
