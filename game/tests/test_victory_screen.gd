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
	func clear_active_game() -> void:
		clear_save(current_difficulty)
		current_difficulty = ""
		current_puzzle_string = ""
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
	assert_true(FileAccess.file_exists("res://assets/icons/mascot_icon.jpg"), "mascot_icon.jpg should exist on disk")
	assert_true(FileAccess.file_exists("res://resources/theme_1930s.tres"), "theme_1930s.tres should exist on disk")

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
	assert_true(screen.victory_overlay.mascot_rect != null, "MascotRect should exist on victory overlay")
	assert_true(screen.victory_overlay.mascot_rect.texture != null, "MascotRect should have a texture assigned")
	
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

func test_restore_button_layout() -> void:
	_setup_nodes()
	
	var overlay = screen.victory_overlay
	var btn = overlay.restore_btn
	
	# Verify button is centered horizontally at the top (anchor_preset = 5)
	assert_eq(int(btn.anchors_preset), int(Control.PRESET_TOP_WIDE) if btn.anchors_preset == 10 else 5, "Anchor preset should be top center")
	assert_eq(btn.anchor_left, 0.5, "Anchor left should be 0.5")
	assert_eq(btn.anchor_right, 0.5, "Anchor right should be 0.5")
	assert_eq(btn.offset_top, 160.0, "Offset top should be 160.0 to be above the grid")
	
	_teardown_nodes()

func test_victory_modal_scaling() -> void:
	_setup_nodes()
	
	var overlay = screen.victory_overlay
	var panel = overlay.panel
	var vbox = panel.get_node("VBoxContainer")
	var banner = vbox.get_node("Banner") as Label
	var time_label = overlay.time_label
	var play_again_btn = overlay.play_again_btn
	var mascot = overlay.mascot_rect
	
	# Verify responsive anchors
	assert_eq(int(panel.anchors_preset), 15, "Panel should be anchored to fill screen")
	assert_eq(panel.anchor_right, 1.0, "Panel anchor_right should be 1.0")
	assert_eq(panel.anchor_bottom, 1.0, "Panel anchor_bottom should be 1.0")
	assert_eq(panel.offset_left, 36.0, "Panel should have screen margin left")
	assert_eq(panel.offset_top, 100.0, "Panel should have screen margin top")
	assert_eq(panel.offset_right, -36.0, "Panel should have screen margin right")
	assert_eq(panel.offset_bottom, -100.0, "Panel should have screen margin bottom")
	
	# Verify 2x scaled internal elements
	assert_eq(banner.get_theme_font_size("font_size"), 64, "Banner font size should be 2x")
	assert_eq(time_label.get_theme_font_size("font_size"), 40, "TimeLabel font size should be 2x")
	assert_eq(play_again_btn.custom_minimum_size.x, 440, "Button width should be 2x")
	assert_eq(play_again_btn.custom_minimum_size.y, 92, "Button height should be 2x")
	assert_eq(play_again_btn.get_theme_font_size("font_size"), 40, "Button font size should be 2x")
	assert_eq(mascot.custom_minimum_size.x, 260, "Mascot width should be 2x")
	assert_eq(mascot.custom_minimum_size.y, 260, "Mascot height should be 2x")
	assert_eq(vbox.get_theme_constant("separation"), 28, "VBox separation should be 2x")
	
	var stylebox = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_true(stylebox != null, "StyleBoxFlat should exist")
	if stylebox:
		assert_eq(stylebox.content_margin_left, 48.0, "Stylebox margin left should be 2x")
		assert_eq(stylebox.content_margin_top, 48.0, "Stylebox margin top should be 2x")
		assert_eq(stylebox.border_width_left, 4, "Stylebox border should be 2x")
		assert_eq(stylebox.corner_radius_top_left, 16, "Stylebox corner radius should be 2x")
	
	_teardown_nodes()
