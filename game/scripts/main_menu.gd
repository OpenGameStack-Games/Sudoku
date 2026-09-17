extends Control

var save_manager_node: Node
var game_manager_node: Node
var stats_manager_node: Node

func _ready() -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if not save_manager_node:
			save_manager_node = tree.root.get_node_or_null("SaveManager")
		if not game_manager_node:
			game_manager_node = tree.root.get_node_or_null("GameManager")
		if not stats_manager_node:
			stats_manager_node = tree.root.get_node_or_null("StatsManager")
			
	var easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var stats_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/StatsButton") as Button
	
	if easy_btn:
		easy_btn.pressed.connect(_on_difficulty_pressed.bind("easy"))
	if medium_btn:
		medium_btn.pressed.connect(_on_difficulty_pressed.bind("medium"))
	if hard_btn:
		hard_btn.pressed.connect(_on_difficulty_pressed.bind("hard"))
	if stats_btn:
		stats_btn.pressed.connect(_on_stats_pressed)
		
	_refresh_buttons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_refresh_buttons()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_refresh_buttons()

func _refresh_buttons() -> void:
	var easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	
	if easy_btn:
		_update_difficulty_button(easy_btn, "easy", "Easy")
	if medium_btn:
		_update_difficulty_button(medium_btn, "medium", "Medium")
	if hard_btn:
		_update_difficulty_button(hard_btn, "hard", "Hard")

func _update_difficulty_button(btn: Button, diff: String, base_text: String) -> void:
	if save_manager_node and save_manager_node.has_save(diff):
		btn.text = "Resume " + base_text
	else:
		btn.text = base_text

func _on_difficulty_pressed(diff: String) -> void:
	if save_manager_node and save_manager_node.has_save(diff):
		var save_data: Dictionary = save_manager_node.load_game(diff)
		if save_data.has("puzzle_string"):
			save_manager_node.mark_active_game(diff, save_data["puzzle_string"])
			if game_manager_node:
				game_manager_node.start_game(save_data["puzzle_string"])
	else:
		var puzzle_string: String = _get_random_puzzle(diff)
		if save_manager_node:
			save_manager_node.mark_active_game(diff, puzzle_string)
		if game_manager_node:
			game_manager_node.start_game(puzzle_string)
		if stats_manager_node:
			stats_manager_node.record_game_started(diff)
			
	# Navigate to gameplay screen.
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/board.tscn")

func _on_stats_pressed() -> void:
	# Navigate to statistics screen if it exists.
	if FileAccess.file_exists("res://scenes/statistics_screen.tscn") and is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/statistics_screen.tscn")

func _get_random_puzzle(diff: String) -> String:
	if not FileAccess.file_exists("res://data/puzzles.json"):
		return ""
		
	var file: FileAccess = FileAccess.open("res://data/puzzles.json", FileAccess.READ)
	if not file:
		return ""
		
	var content: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var err: Error = json.parse(content)
	if err == OK:
		var data: Variant = json.get_data()
		if typeof(data) == TYPE_DICTIONARY and (data as Dictionary).has(diff) and typeof((data as Dictionary)[diff]) == TYPE_ARRAY:
			var puzzles: Array = (data as Dictionary)[diff] as Array
			if puzzles.size() > 0:
				return puzzles[randi() % puzzles.size()] as String
	return ""

