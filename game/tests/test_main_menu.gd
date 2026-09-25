class_name TestMainMenu
extends TestBase

func test_scenes_and_assets_exist() -> void:
	assert_true(FileAccess.file_exists("res://scenes/main_menu.tscn"), "main_menu.tscn file should exist on disk")
	assert_true(FileAccess.file_exists("res://scenes/main.tscn"), "main.tscn entry point should exist on disk")
	assert_true(FileAccess.file_exists("res://assets/icons/mascot_icon.jpg"), "mascot_icon.jpg should exist on disk")
	assert_true(FileAccess.file_exists("res://data/puzzles.json"), "puzzles.json should exist on disk")

func test_menu_initialization_no_saves() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	# Mock SaveManager returning false for all saves
	var save_mgr: Node = Node.new()
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Node
func has_save(diff: String) -> bool: return false
"""
	script.reload()
	save_mgr.set_script(script)
	menu.save_manager_node = save_mgr
	
	menu._ready()
	
	var mascot_rect: TextureRect = menu.get_node("MarginContainer/VBoxContainer/MascotRect") as TextureRect
	assert_true(mascot_rect != null, "MascotRect node should exist")
	assert_true(mascot_rect.texture != null, "MascotRect should have a texture assigned")
	
	var very_easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/VeryEasyButton") as Button
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var very_hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/VeryHardButton") as Button
	var stats_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/StatsButton") as Button
	
	assert_eq(very_easy_btn.text, "Very Easy", "Button text should be 'Very Easy' when no save exists")
	assert_eq(easy_btn.text, "Easy", "Button text should be 'Easy' when no save exists")
	assert_eq(medium_btn.text, "Medium", "Button text should be 'Medium' when no save exists")
	assert_eq(hard_btn.text, "Hard", "Button text should be 'Hard' when no save exists")
	assert_eq(very_hard_btn.text, "Very Hard", "Button text should be 'Very Hard' when no save exists")
	assert_eq(stats_btn.text, "Statistics", "Stats button should read 'Statistics'")
	
	save_mgr.free()
	menu.free()

func test_menu_initialization_with_save() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	# Mock SaveManager with easy and hard saves
	var save_mgr: Node = Node.new()
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Node
func has_save(diff: String) -> bool: return diff == "easy" or diff == "hard"
"""
	script.reload()
	save_mgr.set_script(script)
	menu.save_manager_node = save_mgr
	
	menu._ready()
	
	var very_easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/VeryEasyButton") as Button
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var very_hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/VeryHardButton") as Button
	
	assert_eq(very_easy_btn.text, "Very Easy", "Button text should be 'Very Easy' when no very easy save exists")
	assert_eq(easy_btn.text, "Resume Easy", "Button text should be 'Resume Easy' when easy save exists")
	assert_eq(medium_btn.text, "Medium", "Button text should remain 'Medium' when no medium save exists")
	assert_eq(hard_btn.text, "Resume Hard", "Button text should be 'Resume Hard' when hard save exists")
	assert_eq(very_hard_btn.text, "Very Hard", "Button text should be 'Very Hard' when no very hard save exists")
	
	save_mgr.free()
	menu.free()

func test_difficulty_selection_routes_fresh_game() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	var save_mgr: Node = Node.new()
	var save_script: GDScript = GDScript.new()
	save_script.source_code = """
extends Node
var marked_diff: String = ""
var marked_puzzle: String = ""
func has_save(diff: String) -> bool: return false
func mark_active_game(d: String, p: String) -> void:
	marked_diff = d
	marked_puzzle = p
"""
	save_script.reload()
	save_mgr.set_script(save_script)
	menu.save_manager_node = save_mgr
	
	var game_mgr: Node = Node.new()
	var game_script: GDScript = GDScript.new()
	game_script.source_code = """
extends Node
var started_puzzle: String = ""
func start_game(p: String) -> void:
	started_puzzle = p
"""
	game_script.reload()
	game_mgr.set_script(game_script)
	menu.game_manager_node = game_mgr
	
	var stats_mgr: Node = Node.new()
	var stats_script: GDScript = GDScript.new()
	stats_script.source_code = """
extends Node
var started_diff: String = ""
func record_game_started(d: String) -> void:
	started_diff = d
"""
	stats_script.reload()
	stats_mgr.set_script(stats_script)
	menu.stats_manager_node = stats_mgr
	
	var time_mgr: Node = Node.new()
	var time_script: GDScript = GDScript.new()
	time_script.source_code = """
extends Node
var reset_called: bool = false
var start_seconds: int = -1
func reset() -> void:
	reset_called = true
func start(secs: int) -> void:
	start_seconds = secs
"""
	time_script.reload()
	time_mgr.set_script(time_script)
	menu.time_manager_node = time_mgr
	
	var action_mgr: Node = Node.new()
	var action_script: GDScript = GDScript.new()
	action_script.source_code = """
extends Node
var clear_called: bool = false
func clear_history() -> void:
	clear_called = true
"""
	action_script.reload()
	action_mgr.set_script(action_script)
	menu.action_manager_node = action_mgr
	
	menu._ready()
	
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	easy_btn.pressed.emit()
	
	assert_eq(save_mgr.get("marked_diff"), "easy", "SaveManager should record active difficulty easy")
	assert_true(str(save_mgr.get("marked_puzzle")).length() == 81, "SaveManager should receive valid 81-character puzzle string")
	assert_true(str(game_mgr.get("started_puzzle")).length() == 81, "GameManager should start valid 81-character puzzle")
	assert_eq(stats_mgr.get("started_diff"), "easy", "StatsManager should record new game started for easy")
	assert_true(time_mgr.get("reset_called"), "TimeManager should be reset on new game")
	assert_eq(time_mgr.get("start_seconds"), 0, "TimeManager should start at 0 seconds on new game")
	assert_true(action_mgr.get("clear_called"), "ActionManager should clear history on new game")
	
	action_mgr.free()
	time_mgr.free()
	stats_mgr.free()
	game_mgr.free()
	save_mgr.free()
	menu.free()

func test_difficulty_selection_routes_resumed_game() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	var save_mgr: Node = Node.new()
	var save_script: GDScript = GDScript.new()
	save_script.source_code = """
extends Node
var marked_diff: String = ""
var marked_puzzle: String = ""
func has_save(diff: String) -> bool: return diff == "medium"
func load_game(diff: String) -> Dictionary:
	return {
		"puzzle_string": "123456789012345678901234567890123456789012345678901234567890123456789012345678901",
		"elapsed_seconds": 45
	}
func mark_active_game(d: String, p: String) -> void:
	marked_diff = d
	marked_puzzle = p
"""
	save_script.reload()
	save_mgr.set_script(save_script)
	menu.save_manager_node = save_mgr
	
	var game_mgr: Node = Node.new()
	var game_script: GDScript = GDScript.new()
	game_script.source_code = """
extends Node
var started_puzzle: String = ""
func start_game(p: String) -> void:
	started_puzzle = p
"""
	game_script.reload()
	game_mgr.set_script(game_script)
	menu.game_manager_node = game_mgr
	
	var stats_mgr: Node = Node.new()
	var stats_script: GDScript = GDScript.new()
	stats_script.source_code = """
extends Node
var started_diff: String = ""
func record_game_started(d: String) -> void:
	started_diff = d
"""
	stats_script.reload()
	stats_mgr.set_script(stats_script)
	menu.stats_manager_node = stats_mgr
	
	var time_mgr: Node = Node.new()
	var time_script: GDScript = GDScript.new()
	time_script.source_code = """
extends Node
var reset_called: bool = false
var start_seconds: int = -1
func reset() -> void:
	reset_called = true
func start(secs: int) -> void:
	start_seconds = secs
"""
	time_script.reload()
	time_mgr.set_script(time_script)
	menu.time_manager_node = time_mgr
	
	var action_mgr: Node = Node.new()
	var action_script: GDScript = GDScript.new()
	action_script.source_code = """
extends Node
var load_called: bool = false
func load_history_state(u: Array, r: Array = []) -> void:
	load_called = true
"""
	action_script.reload()
	action_mgr.set_script(action_script)
	menu.action_manager_node = action_mgr
	
	menu._ready()
	
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	medium_btn.pressed.emit()
	
	assert_eq(save_mgr.get("marked_diff"), "medium", "SaveManager should record resumed difficulty medium")
	assert_eq(save_mgr.get("marked_puzzle"), "123456789012345678901234567890123456789012345678901234567890123456789012345678901", "SaveManager should receive saved puzzle")
	assert_eq(game_mgr.get("started_puzzle"), "123456789012345678901234567890123456789012345678901234567890123456789012345678901", "GameManager should start saved puzzle")
	assert_eq(stats_mgr.get("started_diff"), "", "StatsManager should not record a new game started when resuming")
	assert_false(time_mgr.get("reset_called"), "TimeManager should NOT be reset on resumed game")
	assert_eq(time_mgr.get("start_seconds"), 45, "TimeManager should start at the saved elapsed seconds")
	assert_true(action_mgr.get("load_called"), "ActionManager should load history on resumed game")
	
	action_mgr.free()
	time_mgr.free()
	stats_mgr.free()
	game_mgr.free()
	save_mgr.free()
	menu.free()

func test_main_scene_entry_point() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	assert_true(main_scene != null, "main.tscn should load successfully")
	var main_node: Node = main_scene.instantiate()
	assert_true(main_node != null, "main.tscn should instantiate")
	var menu_child: Control = main_node.get_node_or_null("MainMenu") as Control
	assert_true(menu_child != null, "main.tscn should instance MainMenu as a child node")
	main_node.free()

func test_credits_menu_layout() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	var credits_btn: Button = menu.get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/CreditsButton") as Button
	assert_true(credits_btn != null, "CreditsButton should exist in the VBox")
	assert_eq(credits_btn.text, "Credits", "CreditsButton text should be 'Credits'")
	
	var credits_modal: Control = menu.get_node_or_null("CreditsModal") as Control
	assert_true(credits_modal != null, "CreditsModal should exist")
	assert_false(credits_modal.visible, "CreditsModal should be hidden by default")
	
	var title_lbl: Label = credits_modal.get_node_or_null("MarginContainer/Panel/VBox/ModalTitle") as Label
	assert_true(title_lbl != null, "CreditsModal title label should exist")
	assert_eq(title_lbl.text, "CREDITS", "CreditsModal title should be 'CREDITS'")
	
	var close_btn: Button = credits_modal.get_node_or_null("MarginContainer/Panel/VBox/CloseButton") as Button
	assert_true(close_btn != null, "CreditsModal CloseButton should exist")
	assert_eq(close_btn.text, "Got It!", "CloseButton text should be 'Got It!'")
	
	menu.free()

func test_stats_button_routing() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	menu._ready()
	
	var stats_btn: Button = menu.get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/StatsButton") as Button
	assert_true(stats_btn != null, "Stats button should exist")
	assert_true(stats_btn.pressed.is_connected(menu._on_stats_pressed), "Stats button should be connected to _on_stats_pressed")
	
	# Verify that calling the handler doesn't crash even if not in the tree.
	menu._on_stats_pressed()
	
	menu.free()

func test_difficulty_selection_routes_resumed_game_with_board_state() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	var call_order: Array = []
	
	var save_mgr: Node = Node.new()
	var save_script: GDScript = GDScript.new()
	save_script.source_code = """
extends Node
var call_order_ref: Array = []
var marked_diff: String = ""
var marked_puzzle: String = ""
func has_save(diff: String) -> bool: return diff == "medium"
func load_game(diff: String) -> Dictionary:
	return {
		"puzzle_string": "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
		"elapsed_seconds": 45,
		"auto_candidates": true,
		"board_state": [
			{"index": 2, "value": 4, "candidates": [1, 2], "deleted_candidates": [8]}
		]
	}
func mark_active_game(d: String, p: String) -> void:
	marked_diff = d
	marked_puzzle = p
	call_order_ref.append("mark_active_game")
"""
	save_script.reload()
	save_mgr.set_script(save_script)
	save_mgr.set("call_order_ref", call_order)
	menu.save_manager_node = save_mgr
	
	var game_board: SudokuBoard = SudokuBoard.new()
	var game_mgr: Node = Node.new()
	var game_script: GDScript = GDScript.new()
	game_script.source_code = """
extends Node
var board: SudokuBoard
var call_order_ref: Array = []
func start_game(p: String) -> void:
	board.load_puzzle(p)
	call_order_ref.append("start_game")
"""
	game_script.reload()
	game_mgr.set_script(game_script)
	game_mgr.set("board", game_board)
	game_mgr.set("call_order_ref", call_order)
	menu.game_manager_node = game_mgr
	
	menu._ready()
	
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	medium_btn.pressed.emit()
	
	assert_eq(game_board.cells[2].value, 4, "Cell 2 value should be restored to 4")
	assert_true(game_board.auto_candidates_enabled, "Auto candidates should be enabled from save data")
	assert_eq(call_order.size(), 2, "Should have called start_game and mark_active_game")
	assert_eq(call_order[0], "start_game", "start_game should be called first")
	assert_eq(call_order[1], "mark_active_game", "mark_active_game should be called after restoration")
	
	game_mgr.free()
	save_mgr.free()
	menu.free()

func test_main_menu_separator() -> void:
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	var menu: Control = menu_scene.instantiate() as Control
	
	var buttons_vbox: VBoxContainer = menu.get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox") as VBoxContainer
	assert_true(buttons_vbox != null, "ButtonsVBox should exist")
	
	var sep: HSeparator = buttons_vbox.get_node_or_null("HSeparator") as HSeparator
	assert_true(sep != null, "HSeparator should exist in ButtonsVBox")
	
	var very_hard_btn: Button = buttons_vbox.get_node_or_null("VeryHardButton") as Button
	var stats_btn: Button = buttons_vbox.get_node_or_null("StatsButton") as Button
	
	assert_true(very_hard_btn != null, "VeryHardButton should exist")
	assert_true(stats_btn != null, "StatsButton should exist")
	
	var v_index: int = very_hard_btn.get_index()
	var s_index: int = sep.get_index()
	var st_index: int = stats_btn.get_index()
	
	assert_eq(s_index, v_index + 1, "HSeparator should be positioned immediately after VeryHardButton")
	assert_eq(st_index, s_index + 1, "StatsButton should be positioned immediately after HSeparator")
	
	menu.free()
