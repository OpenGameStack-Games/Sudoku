class_name TestMainMenu
extends TestBase

func test_scene_exists() -> void:
	assert_true(FileAccess.file_exists("res://scenes/main_menu.tscn"), "main_menu.tscn file should exist on disk")

func test_menu_initialization_no_saves() -> void:
	var menu_scene = load("res://scenes/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	
	# Mock SaveManager
	var save_mgr = Node.new()
	var script = GDScript.new()
	script.source_code = """
extends Node
func has_save(diff: String) -> bool: return false
"""
	script.reload()
	save_mgr.set_script(script)
	
	# Inject mock
	menu.save_manager_node = save_mgr
	
	menu._ready()
	
	var easy_btn = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	assert_eq(easy_btn.text, "Easy", "Button text should just be 'Easy' when no save exists")
	
	save_mgr.queue_free()
	menu.queue_free()

func test_menu_initialization_with_save() -> void:
	var menu_scene = load("res://scenes/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	
	# Mock SaveManager
	var save_mgr = Node.new()
	var script = GDScript.new()
	script.source_code = """
extends Node
func has_save(diff: String) -> bool: return diff == "easy"
func load_game(diff: String) -> Dictionary: return {"puzzle_string": "123"}
func mark_active_game(d: String, p: String) -> void: pass
"""
	script.reload()
	save_mgr.set_script(script)
	
	menu.save_manager_node = save_mgr
	
	menu._ready()
	
	var easy_btn = menu.get_node("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	assert_eq(easy_btn.text, "Resume Easy", "Button text should be 'Resume Easy' when save exists")
	
	save_mgr.queue_free()
	menu.queue_free()

func test_difficulty_selection_signal() -> void:
	var menu_scene = load("res://scenes/main_menu.tscn")
	var menu = menu_scene.instantiate() as Control
	
	var save_mgr = Node.new()
	var script = GDScript.new()
	script.source_code = """
extends Node
func has_save(diff: String) -> bool: return false
func mark_active_game(d: String, p: String) -> void: pass
"""
	script.reload()
	save_mgr.set_script(script)
	menu.save_manager_node = save_mgr
	
	menu._ready()
	
	# Call it manually
	menu._on_difficulty_pressed("easy")
	
	save_mgr.queue_free()
	menu.queue_free()
