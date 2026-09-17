extends Control

@onready var background: ColorRect = $Background
@onready var back_button: Button = $VBoxContainer/Header/HBoxContainer/BackButton
@onready var difficulty_label: Label = $VBoxContainer/Header/HBoxContainer/DifficultyLabel
@onready var timer_label: Label = $VBoxContainer/Header/HBoxContainer/TimerLabel
@onready var pause_button: Button = $VBoxContainer/Header/HBoxContainer/PauseButton
@onready var menu_button: MenuButton = $VBoxContainer/Header/HBoxContainer/MenuButton
@onready var board_node = $VBoxContainer/BoardContainer/Board
@onready var pause_overlay = $PauseOverlay

var save_manager_node: Node
var game_manager_node: Node
var time_manager_node: Node

func _ready() -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if not save_manager_node:
			save_manager_node = tree.root.get_node_or_null("SaveManager")
		if not game_manager_node:
			game_manager_node = tree.root.get_node_or_null("GameManager")
		if not time_manager_node:
			time_manager_node = tree.root.get_node_or_null("TimeManager")
	
	if time_manager_node:
		time_manager_node.time_updated.connect(_on_time_updated)
		timer_label.text = time_manager_node.get_formatted_time()
		
	if save_manager_node:
		var diff = save_manager_node.current_difficulty
		if diff != "":
			difficulty_label.text = diff.capitalize()
			
	back_button.pressed.connect(_on_back_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	
	var popup = menu_button.get_popup()
	popup.id_pressed.connect(_on_menu_item_pressed)
	
	pause_overlay.resume_requested.connect(_on_resume_requested)
	background.gui_input.connect(_on_background_gui_input)

func _on_time_updated(seconds: int, formatted_str: String) -> void:
	timer_label.text = formatted_str

func _on_back_pressed() -> void:
	if save_manager_node and game_manager_node and game_manager_node.board:
		save_manager_node.call("flush_save")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_pause_pressed() -> void:
	if time_manager_node:
		time_manager_node.pause()
	board_node.hide()
	pause_overlay.show()

func _on_resume_requested() -> void:
	if time_manager_node:
		time_manager_node.resume()
	board_node.show()
	pause_overlay.hide()

func _on_menu_item_pressed(id: int) -> void:
	if id == 0:
		# Reset Puzzle
		if game_manager_node and game_manager_node.board:
			var puzzle = save_manager_node.current_puzzle_string
			if puzzle != "":
				game_manager_node.board.load_puzzle(puzzle)
		if time_manager_node:
			time_manager_node.reset()
			time_manager_node.start()
	elif id == 1:
		# New Game
		if save_manager_node and game_manager_node:
			var diff = save_manager_node.current_difficulty
			var puzzle = _get_random_puzzle(diff)
			save_manager_node.mark_active_game(diff, puzzle)
			game_manager_node.start_game(puzzle)
		if time_manager_node:
			time_manager_node.reset()
			time_manager_node.start()

func _get_random_puzzle(diff: String) -> String:
	if not FileAccess.file_exists("res://data/puzzles.json"):
		return ""
	var file = FileAccess.open("res://data/puzzles.json", FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	var parser = JSON.new()
	if parser.parse(content) == OK:
		var data = parser.data
		if data is Dictionary and data.has(diff):
			var arr = data[diff]
			if arr is Array and arr.size() > 0:
				return arr[randi() % arr.size()]
	return ""

func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if board_node and board_node.has_method("deselect_cell"):
			board_node.deselect_cell()
