extends Control

var save_manager_node: Node
var game_manager_node: Node
var stats_manager_node: Node
var time_manager_node: Node
var action_manager_node: Node

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
		if not time_manager_node:
			time_manager_node = tree.root.get_node_or_null("TimeManager")
		if not action_manager_node:
			action_manager_node = tree.root.get_node_or_null("ActionManager")
			
	var very_easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/VeryEasyButton") as Button
	var easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var very_hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/VeryHardButton") as Button
	var stats_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/StatsButton") as Button
	
	if very_easy_btn:
		very_easy_btn.pressed.connect(_on_difficulty_pressed.bind("very_easy"))
	if easy_btn:
		easy_btn.pressed.connect(_on_difficulty_pressed.bind("easy"))
	if medium_btn:
		medium_btn.pressed.connect(_on_difficulty_pressed.bind("medium"))
	if hard_btn:
		hard_btn.pressed.connect(_on_difficulty_pressed.bind("hard"))
	if very_hard_btn:
		very_hard_btn.pressed.connect(_on_difficulty_pressed.bind("very_hard"))
	if stats_btn:
		stats_btn.pressed.connect(_on_stats_pressed)
		
	var credits_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/CreditsButton") as Button
	if credits_btn:
		credits_btn.pressed.connect(_on_credits_pressed)
		
	var credits_modal: Control = get_node_or_null("CreditsModal") as Control
	if credits_modal:
		var close_btn: Button = credits_modal.get_node_or_null("MarginContainer/Panel/VBox/CloseButton") as Button
		if close_btn:
			close_btn.pressed.connect(func() -> void: credits_modal.visible = false)
		
		var ogs: Node = credits_modal.find_child("OGSBlock", true, false)
		if ogs:
			var btn: Button = ogs.find_child("WebIconBtn", true, false) as Button
			if btn:
				btn.pressed.connect(func() -> void: OS.shell_open("https://opengamestack.org/"))
				
		var audrain: Node = credits_modal.find_child("AudrainBlock", true, false)
		if audrain:
			var btn: Button = audrain.find_child("WebIconBtn", true, false) as Button
			if btn:
				btn.pressed.connect(func() -> void: OS.shell_open("https://audrain.games/"))
				
		var github: Node = credits_modal.find_child("GitHubBlock", true, false)
		if github:
			var btn: Button = github.find_child("WebIconBtn", true, false) as Button
			if btn:
				btn.pressed.connect(func() -> void: OS.shell_open("https://github.com/OpenGameStack-Games/Sudoku"))
		
	_refresh_buttons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_refresh_buttons()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_refresh_buttons()

func _refresh_buttons() -> void:
	var very_easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/VeryEasyButton") as Button
	var easy_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/EasyButton") as Button
	var medium_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/MediumButton") as Button
	var hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/HardButton") as Button
	var very_hard_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/ButtonsVBox/VeryHardButton") as Button
	
	if very_easy_btn:
		_update_difficulty_button(very_easy_btn, "very_easy", "Very Easy")
	if easy_btn:
		_update_difficulty_button(easy_btn, "easy", "Easy")
	if medium_btn:
		_update_difficulty_button(medium_btn, "medium", "Medium")
	if hard_btn:
		_update_difficulty_button(hard_btn, "hard", "Hard")
	if very_hard_btn:
		_update_difficulty_button(very_hard_btn, "very_hard", "Very Hard")

func _update_difficulty_button(btn: Button, diff: String, base_text: String) -> void:
	if save_manager_node and save_manager_node.has_save(diff):
		btn.text = "Resume " + base_text
	else:
		btn.text = base_text

func _on_difficulty_pressed(diff: String) -> void:
	if save_manager_node and save_manager_node.has_save(diff):
		var save_data: Dictionary = save_manager_node.load_game(diff)
		if save_data.has("puzzle_string"):
			if game_manager_node:
				game_manager_node.start_game(save_data["puzzle_string"])
				if save_data.has("board_state"):
					game_manager_node.board.restore_board_state(save_data["board_state"])
				if save_data.has("auto_candidates"):
					game_manager_node.board.set_auto_candidates(bool(save_data["auto_candidates"]))
			
			save_manager_node.mark_active_game(diff, save_data["puzzle_string"])
			
			if action_manager_node:
				var undo_stack: Array = save_data.get("undo_stack", []) as Array
				var redo_stack: Array = save_data.get("redo_stack", []) as Array
				action_manager_node.load_history_state(undo_stack, redo_stack)
			
			if time_manager_node:
				time_manager_node.start(int(save_data.get("elapsed_seconds", 0)))
	else:
		var puzzle_string: String = _get_random_puzzle(diff)
		if save_manager_node:
			save_manager_node.mark_active_game(diff, puzzle_string)
		if action_manager_node:
			action_manager_node.clear_history()
		if game_manager_node:
			game_manager_node.start_game(puzzle_string)
		if time_manager_node:
			time_manager_node.reset()
			time_manager_node.start(0)
		if stats_manager_node:
			stats_manager_node.record_game_started(diff)
			
	# Navigate to gameplay screen.
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/gameplay_screen.tscn")

func _on_stats_pressed() -> void:
	# Navigate to statistics screen.
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/statistics_screen.tscn")

func _on_credits_pressed() -> void:
	var credits_modal: Control = get_node_or_null("CreditsModal") as Control
	if credits_modal:
		credits_modal.visible = true

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

