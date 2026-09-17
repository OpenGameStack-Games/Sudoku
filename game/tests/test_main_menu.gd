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
	
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var stats_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/StatsButton") as Button
	
	assert_eq(easy_btn.text, "Easy", "Button text should be 'Easy' when no save exists")
	assert_eq(medium_btn.text, "Medium", "Button text should be 'Medium' when no save exists")
	assert_eq(hard_btn.text, "Hard", "Button text should be 'Hard' when no save exists")
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
	
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	
	assert_eq(easy_btn.text, "Resume Easy", "Button text should be 'Resume Easy' when easy save exists")
	assert_eq(medium_btn.text, "Medium", "Button text should remain 'Medium' when no medium save exists")
	assert_eq(hard_btn.text, "Resume Hard", "Button text should be 'Resume Hard' when hard save exists")
	
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
	
	menu._ready()
	
	var easy_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	easy_btn.pressed.emit()
	
	assert_eq(save_mgr.get("marked_diff"), "easy", "SaveManager should record active difficulty easy")
	assert_true(str(save_mgr.get("marked_puzzle")).length() == 81, "SaveManager should receive valid 81-character puzzle string")
	assert_true(str(game_mgr.get("started_puzzle")).length() == 81, "GameManager should start valid 81-character puzzle")
	assert_eq(stats_mgr.get("started_diff"), "easy", "StatsManager should record new game started for easy")
	
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
	return {"puzzle_string": "123456789012345678901234567890123456789012345678901234567890123456789012345678901"}
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
	
	menu._ready()
	
	var medium_btn: Button = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	medium_btn.pressed.emit()
	
	assert_eq(save_mgr.get("marked_diff"), "medium", "SaveManager should record resumed difficulty medium")
	assert_eq(save_mgr.get("marked_puzzle"), "123456789012345678901234567890123456789012345678901234567890123456789012345678901", "SaveManager should receive saved puzzle")
	assert_eq(game_mgr.get("started_puzzle"), "123456789012345678901234567890123456789012345678901234567890123456789012345678901", "GameManager should start saved puzzle")
	assert_eq(stats_mgr.get("started_diff"), "", "StatsManager should not record a new game started when resuming")
	
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

