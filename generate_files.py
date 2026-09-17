import os
import json

def write_file(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

# 1. gameplay_screen.tscn
gameplay_tscn = """[gd_scene load_steps=5 format=3 uid="uid://gameplay_screen"]

[ext_resource type="Script" path="res://scripts/gameplay_screen.gd" id="1_gps"]
[ext_resource type="PackedScene" path="res://scenes/board.tscn" id="2_brd"]
[ext_resource type="PackedScene" path="res://scenes/input_controls.tscn" id="3_inp"]
[ext_resource type="PackedScene" path="res://scenes/pause_overlay.tscn" id="4_pau"]

[node name="GameplayScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_gps")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.07, 0.07, 0.07, 1.0)

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 16

[node name="Header" type="MarginContainer" parent="VBoxContainer"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 32
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="HBoxContainer" type="HBoxContainer" parent="VBoxContainer/Header"]
layout_mode = 2

[node name="BackButton" type="Button" parent="VBoxContainer/Header/HBoxContainer"]
custom_minimum_size = Vector2(80, 60)
layout_mode = 2
text = "< Back"

[node name="DifficultyLabel" type="Label" parent="VBoxContainer/Header/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
text = "Medium"
horizontal_alignment = 1

[node name="TimerLabel" type="Label" parent="VBoxContainer/Header/HBoxContainer"]
custom_minimum_size = Vector2(100, 0)
layout_mode = 2
text = "00:00"
horizontal_alignment = 2

[node name="PauseButton" type="Button" parent="VBoxContainer/Header/HBoxContainer"]
custom_minimum_size = Vector2(80, 60)
layout_mode = 2
text = "Pause"

[node name="MenuButton" type="MenuButton" parent="VBoxContainer/Header/HBoxContainer"]
custom_minimum_size = Vector2(60, 60)
layout_mode = 2
text = "..."
item_count = 2
popup/item_0/text = "Reset Puzzle"
popup/item_0/id = 0
popup/item_1/text = "New Game"
popup/item_1/id = 1

[node name="BoardContainer" type="CenterContainer" parent="VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="Board" parent="VBoxContainer/BoardContainer" instance=ExtResource("2_brd")]
layout_mode = 2

[node name="InputControls" parent="VBoxContainer" instance=ExtResource("3_inp")]
layout_mode = 2

[node name="PauseOverlay" parent="." instance=ExtResource("4_pau")]
visible = false
layout_mode = 1
"""

# 2. gameplay_screen.gd
gameplay_gd = """extends Control

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
	var root = Engine.get_main_loop().root
	save_manager_node = root.get_node_or_null("SaveManager")
	game_manager_node = root.get_node_or_null("GameManager")
	time_manager_node = root.get_node_or_null("TimeManager")
	
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
		save_manager_node.call("force_save")
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
"""

# 3. pause_overlay.tscn
pause_tscn = """[gd_scene load_steps=3 format=3 uid="uid://pause_overlay"]

[ext_resource type="Script" path="res://scripts/pause_overlay.gd" id="1_pau"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_bg"]
bg_color = Color(0.1, 0.1, 0.1, 0.95)

[node name="PauseOverlay" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_pau")

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_bg")

[node name="CenterContainer" type="CenterContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="Panel/CenterContainer"]
layout_mode = 2
theme_override_constants/separation = 32

[node name="Label" type="Label" parent="Panel/CenterContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 48
text = "PAUSED"
horizontal_alignment = 1

[node name="ResumeButton" type="Button" parent="Panel/CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(200, 80)
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "Resume"
"""

# 4. pause_overlay.gd
pause_gd = """extends Control

signal resume_requested

@onready var resume_button: Button = $Panel/CenterContainer/VBoxContainer/ResumeButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)

func _on_resume_pressed() -> void:
	resume_requested.emit()
"""

# 5. test_gameplay_screen.gd
test_gd = """extends "res://tests/test_base.gd"

var screen
var time_manager_node
var save_manager_node
var game_manager_node

func _ready():
	# For Godot 4 testing, we need to handle _ready explicitly for tests
	pass

func _setup_nodes():
	time_manager_node = Node.new()
	time_manager_node.name = "TimeManager"
	var tm_script = load("res://autoloads/time_manager.gd")
	time_manager_node.set_script(tm_script)
	Engine.get_main_loop().root.add_child(time_manager_node)
	
	save_manager_node = Node.new()
	save_manager_node.name = "SaveManager"
	var sm_script = load("res://autoloads/save_manager.gd")
	save_manager_node.set_script(sm_script)
	Engine.get_main_loop().root.add_child(save_manager_node)
	
	game_manager_node = Node.new()
	game_manager_node.name = "GameManager"
	var gm_script = load("res://autoloads/game_manager.gd")
	game_manager_node.set_script(gm_script)
	Engine.get_main_loop().root.add_child(game_manager_node)
	
	var scene = load("res://scenes/gameplay_screen.tscn")
	screen = scene.instantiate()
	Engine.get_main_loop().root.add_child(screen)

func _teardown_nodes():
	if screen:
		screen.free()
	if time_manager_node:
		time_manager_node.free()
	if save_manager_node:
		save_manager_node.free()
	if game_manager_node:
		game_manager_node.free()

func test_header_initialization():
	_setup_nodes()
	save_manager_node.current_difficulty = "medium"
	# simulate ready
	screen._ready()
	
	assert_eq(screen.difficulty_label.text, "Medium")
	_teardown_nodes()

func test_pause_button_toggles_board_and_timer():
	_setup_nodes()
	screen._ready()
	
	time_manager_node.start()
	assert_false(screen.pause_overlay.visible)
	
	# Press Pause
	screen.pause_button.pressed.emit()
	assert_true(screen.pause_overlay.visible)
	assert_false(screen.board_node.visible)
	assert_true(time_manager_node._manual_pause)
	
	# Press Resume
	screen.pause_overlay.resume_requested.emit()
	assert_false(screen.pause_overlay.visible)
	assert_true(screen.board_node.visible)
	assert_false(time_manager_node._manual_pause)
	
	_teardown_nodes()

func test_reset_puzzle():
	_setup_nodes()
	screen._ready()
	
	save_manager_node.current_puzzle_string = "123" + "0".repeat(78)
	
	# Trigger Reset via MenuButton popup
	screen._on_menu_item_pressed(0)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0)
	_teardown_nodes()

func test_new_game():
	_setup_nodes()
	screen._ready()
	
	save_manager_node.current_difficulty = "easy"
	
	screen._on_menu_item_pressed(1)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0)
	_teardown_nodes()
"""

write_file("game/scenes/gameplay_screen.tscn", gameplay_tscn)
write_file("game/scripts/gameplay_screen.gd", gameplay_gd)
write_file("game/scenes/pause_overlay.tscn", pause_tscn)
write_file("game/scripts/pause_overlay.gd", pause_gd)
write_file("game/tests/test_gameplay_screen.gd", test_gd)
print("Files generated.")
