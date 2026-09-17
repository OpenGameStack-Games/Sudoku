class_name TestVictoryScreen
extends TestBase

class MockTimeManager extends Node:
	signal time_updated(secs: int, fmt: String)
	var _elapsed_seconds: int = 150
	var _paused: bool = false
	func get_elapsed_seconds() -> int:
		return _elapsed_seconds
	func pause() -> void:
		_paused = true
	func get_formatted_time() -> String:
		return "02:30"
	func start(time: int = 0) -> void:
		pass
	func reset() -> void:
		pass

class MockSaveManager extends Node:
	var current_difficulty: String = "hard"
	var cleared_difficulty: String = ""
	var current_puzzle_string: String = ""
	func clear_save(diff: String) -> void:
		cleared_difficulty = diff
	func flush_save() -> void:
		pass
	func mark_active_game(diff: String, puz: String) -> void:
		pass

class MockStatsManager extends Node:
	var recorded_difficulty: String = ""
	var recorded_time: int = 0
	func record_game_won(diff: String, elapsed: int) -> void:
		recorded_difficulty = diff
		recorded_time = elapsed

class MockGameManager extends Node:
	signal game_won
	var board: Object = null
	func start_game(puz: String) -> void:
		pass

var screen: GameplayScreen
var time_manager_node: MockTimeManager
var save_manager_node: MockSaveManager
var stats_manager_node: MockStatsManager
var game_manager_node: MockGameManager

func _setup_nodes() -> void:
	time_manager_node = MockTimeManager.new()
	save_manager_node = MockSaveManager.new()
	stats_manager_node = MockStatsManager.new()
	stats_manager_node.name = "StatsManager"
	game_manager_node = MockGameManager.new()
	
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		if not tree.root.has_node("StatsManager"):
			tree.root.add_child(stats_manager_node)
	
	var scene: PackedScene = load("res://scenes/gameplay_screen.tscn") as PackedScene
	screen = scene.instantiate() as GameplayScreen
	
	screen.time_manager_node = time_manager_node
	screen.save_manager_node = save_manager_node
	screen.game_manager_node = game_manager_node
	screen.stats_manager_node = stats_manager_node
	
	screen._ready()

func _teardown_nodes() -> void:
	if screen:
		screen.free()
	if time_manager_node:
		time_manager_node.free()
	if save_manager_node:
		save_manager_node.free()
	if game_manager_node:
		game_manager_node.free()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("StatsManager"):
		var node = tree.root.get_node("StatsManager")
		tree.root.remove_child(node)
		node.free()
	elif stats_manager_node and not stats_manager_node.is_queued_for_deletion():
		stats_manager_node.free()

func test_victory_overlay_exists() -> void:
	assert_true(FileAccess.file_exists("res://scenes/victory_overlay.tscn"), "victory_overlay.tscn should exist")

func test_game_won_triggers_victory_logic() -> void:
	_setup_nodes()
	
	assert_false(screen.victory_overlay.visible, "Victory overlay should be hidden initially")
	
	# Simulate win
	game_manager_node.game_won.emit()
	
	assert_true(time_manager_node._paused, "TimeManager should be paused")
	assert_eq(stats_manager_node.recorded_difficulty, "hard", "StatsManager should record win for correct difficulty")
	assert_eq(stats_manager_node.recorded_time, 150, "StatsManager should record correct time")
	assert_eq(save_manager_node.cleared_difficulty, "hard", "SaveManager should clear save for correct difficulty")
	
	assert_true(screen.victory_overlay.visible, "Victory overlay should become visible")
	
	var time_label: Label = screen.victory_overlay.time_label
	assert_eq(time_label.text, "Completion Time: 02:30", "Overlay should display formatted completion time")
	
	_teardown_nodes()

func test_victory_buttons_routing() -> void:
	_setup_nodes()
	game_manager_node.game_won.emit()
	
	var overlay = screen.victory_overlay
	assert_true(overlay.panel.visible, "Panel should be visible")
	assert_false(overlay.restore_btn.visible, "Restore button should be hidden")
	
	# Test Admire Button
	overlay.admire_btn.pressed.emit()
	assert_false(overlay.panel.visible, "Panel should hide when admiring")
	assert_true(overlay.restore_btn.visible, "Restore button should show when admiring")
	
	# Test Restore Button
	overlay.restore_btn.pressed.emit()
	assert_true(overlay.panel.visible, "Panel should restore")
	assert_false(overlay.restore_btn.visible, "Restore button should hide")
	
	# Play again routes through new game logic
	overlay.play_again_btn.pressed.emit()
	assert_false(overlay.visible, "Overlay should hide on play again")
	
	_teardown_nodes()
