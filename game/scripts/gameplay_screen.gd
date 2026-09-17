class_name GameplayScreen
extends Control

var background: ColorRect = null
var back_button: Button = null
var difficulty_label: Label = null
var timer_label: Label = null
var pause_button: Button = null
var menu_button: MenuButton = null
var board_node: BoardUI = null
var input_controls: InputControls = null
var pause_overlay: PauseOverlay = null
var victory_overlay: Control = null

var save_manager_node: Node = null
var game_manager_node: Node = null
var time_manager_node: Node = null
var stats_manager_node: Node = null

func _init_nodes() -> void:
	if not background:
		background = get_node_or_null("Background") as ColorRect
	if not back_button:
		back_button = get_node_or_null("VBoxContainer/Header/HBoxContainer/BackButton") as Button
	if not difficulty_label:
		difficulty_label = get_node_or_null("VBoxContainer/Header/HBoxContainer/DifficultyLabel") as Label
	if not timer_label:
		timer_label = get_node_or_null("VBoxContainer/Header/HBoxContainer/TimerLabel") as Label
	if not pause_button:
		pause_button = get_node_or_null("VBoxContainer/Header/HBoxContainer/PauseButton") as Button
	if not menu_button:
		menu_button = get_node_or_null("VBoxContainer/Header/HBoxContainer/MenuButton") as MenuButton
	if not board_node:
		board_node = get_node_or_null("VBoxContainer/BoardContainer/Board") as BoardUI
	if not input_controls:
		input_controls = get_node_or_null("VBoxContainer/InputControls") as InputControls
	if not pause_overlay:
		pause_overlay = get_node_or_null("PauseOverlay") as PauseOverlay
	if not victory_overlay:
		victory_overlay = get_node_or_null("VictoryOverlay")

func _ready() -> void:
	_init_nodes()
	
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if not save_manager_node and tree.root:
			save_manager_node = tree.root.get_node_or_null("SaveManager")
		if not game_manager_node and tree.root:
			game_manager_node = tree.root.get_node_or_null("GameManager")
		if not time_manager_node and tree.root:
			time_manager_node = tree.root.get_node_or_null("TimeManager")
		if not stats_manager_node and tree.root:
			stats_manager_node = tree.root.get_node_or_null("StatsManager")
	
	if board_node and board_node.cells.is_empty() and board_node.has_method("_ready"):
		board_node._ready()
	if input_controls and input_controls.numpad_btns.is_empty() and input_controls.has_method("_ready"):
		input_controls._ready()
	if pause_overlay and pause_overlay.has_method("_ready"):
		pause_overlay._ready()
	if victory_overlay and victory_overlay.has_method("_ready"):
		victory_overlay._ready()
		
	if game_manager_node and game_manager_node.get("board"):
		if board_node and board_node.has_method("bind_to_board"):
			board_node.bind_to_board(game_manager_node.board)
		if input_controls and input_controls.has_method("bind_to_board") and board_node:
			input_controls.bind_to_board(game_manager_node.board, board_node)
			
	if game_manager_node and not game_manager_node.game_won.is_connected(_on_game_won):
		game_manager_node.game_won.connect(_on_game_won)
		
	if victory_overlay:
		if not victory_overlay.play_again_requested.is_connected(_on_play_again_requested):
			victory_overlay.play_again_requested.connect(_on_play_again_requested)
		if not victory_overlay.main_menu_requested.is_connected(_on_main_menu_requested):
			victory_overlay.main_menu_requested.connect(_on_main_menu_requested)
		if not victory_overlay.statistics_requested.is_connected(_on_statistics_requested):
			victory_overlay.statistics_requested.connect(_on_statistics_requested)
			
	if time_manager_node:
		if not time_manager_node.time_updated.is_connected(_on_time_updated):
			time_manager_node.time_updated.connect(_on_time_updated)
		if timer_label:
			timer_label.text = time_manager_node.get_formatted_time()
		if not time_manager_node.get("_active"):
			var initial_seconds: int = 0
			if save_manager_node and save_manager_node.has_method("load_game"):
				var diff: String = save_manager_node.current_difficulty
				if diff != "" and save_manager_node.has_save(diff):
					var save_data: Dictionary = save_manager_node.load_game(diff)
					initial_seconds = int(save_data.get("elapsed_seconds", 0))
			time_manager_node.start(initial_seconds)
		
	if save_manager_node and difficulty_label:
		var diff: String = save_manager_node.current_difficulty
		if diff != "":
			difficulty_label.text = diff.capitalize()
			
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if pause_button and not pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.connect(_on_pause_pressed)
	
	if menu_button:
		var popup: PopupMenu = menu_button.get_popup()
		if popup and not popup.id_pressed.is_connected(_on_menu_item_pressed):
			popup.id_pressed.connect(_on_menu_item_pressed)
	
	if pause_overlay and not pause_overlay.resume_requested.is_connected(_on_resume_requested):
		pause_overlay.resume_requested.connect(_on_resume_requested)
	if background and not background.gui_input.is_connected(_on_background_gui_input):
		background.gui_input.connect(_on_background_gui_input)

func _on_time_updated(seconds: int, formatted_str: String) -> void:
	if timer_label:
		timer_label.text = formatted_str

func _on_back_pressed() -> void:
	if save_manager_node and save_manager_node.has_method("flush_save"):
		save_manager_node.flush_save()
	if time_manager_node:
		time_manager_node.pause()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_pause_pressed() -> void:
	if time_manager_node:
		time_manager_node.pause()
	if board_node:
		board_node.hide()
	if pause_overlay:
		pause_overlay.show()

func _on_resume_requested() -> void:
	if time_manager_node:
		time_manager_node.resume()
	if board_node:
		board_node.show()
	if pause_overlay:
		pause_overlay.hide()

func _on_menu_item_pressed(id: int) -> void:
	if id == 0:
		# Reset Puzzle
		if save_manager_node and game_manager_node and game_manager_node.get("board"):
			var puzzle: String = save_manager_node.current_puzzle_string
			if puzzle != "":
				game_manager_node.board.load_puzzle(puzzle)
			if game_manager_node.board.undo_manager:
				game_manager_node.board.undo_manager.clear_history()
		if time_manager_node:
			time_manager_node.reset()
			time_manager_node.start(0)
		if save_manager_node and save_manager_node.has_method("flush_save"):
			save_manager_node.flush_save()
	elif id == 1:
		# New Game
		if save_manager_node and game_manager_node:
			var diff: String = save_manager_node.current_difficulty
			var current_puz: String = save_manager_node.current_puzzle_string
			var puzzle: String = _get_random_puzzle(diff, current_puz)
			save_manager_node.mark_active_game(diff, puzzle)
			game_manager_node.start_game(puzzle)
			if game_manager_node.board and game_manager_node.board.undo_manager:
				game_manager_node.board.undo_manager.clear_history()
		if time_manager_node:
			time_manager_node.reset()
			time_manager_node.start(0)
		if save_manager_node and save_manager_node.has_method("flush_save"):
			save_manager_node.flush_save()

func _get_random_puzzle(diff: String, exclude_puzzle: String = "") -> String:
	if not FileAccess.file_exists("res://data/puzzles.json"):
		return ""
	var file: FileAccess = FileAccess.open("res://data/puzzles.json", FileAccess.READ)
	if not file:
		return ""
	var content: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(content) == OK:
		var data: Variant = parser.data
		if data is Dictionary and (data as Dictionary).has(diff):
			var arr: Array = (data as Dictionary)[diff] as Array
			if arr.size() > 0:
				if arr.size() > 1 and exclude_puzzle != "":
					var filtered: Array = arr.filter(func(p: Variant) -> bool: return str(p) != exclude_puzzle)
					if filtered.size() > 0:
						return filtered[randi() % filtered.size()] as String
				return arr[randi() % arr.size()] as String
	return ""

func _on_game_won() -> void:
	if time_manager_node:
		time_manager_node.pause()
	var elapsed: int = time_manager_node.get_elapsed_seconds() if time_manager_node else 0
	var diff: String = save_manager_node.current_difficulty if save_manager_node else "medium"
	
	if not stats_manager_node:
		var main_loop: MainLoop = Engine.get_main_loop()
		if main_loop and main_loop is SceneTree and (main_loop as SceneTree).root:
			stats_manager_node = (main_loop as SceneTree).root.get_node_or_null("StatsManager")
		
	if stats_manager_node and stats_manager_node.has_method("record_game_won"):
		stats_manager_node.record_game_won(diff, elapsed)
		
	if save_manager_node:
		if save_manager_node.has_method("clear_active_game"):
			save_manager_node.clear_active_game()
		elif save_manager_node.has_method("clear_save"):
			save_manager_node.clear_save(diff)
		
	if victory_overlay and victory_overlay.has_method("show_victory"):
		victory_overlay.show_victory(elapsed)
		
func _on_play_again_requested() -> void:
	if victory_overlay:
		victory_overlay.hide()
	_on_menu_item_pressed(1) # Re-uses New Game logic

func _on_main_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_statistics_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/statistics_screen.tscn")

func _on_background_gui_input(event: InputEvent) -> void:
	var is_mouse_press: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	var is_touch_press: bool = event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	if is_mouse_press or is_touch_press:
		if board_node and board_node.has_method("deselect_cell"):
			board_node.deselect_cell()
