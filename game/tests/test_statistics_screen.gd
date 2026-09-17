extends "res://tests/test_base.gd"

var scene: Control
var mock_stats_manager: Node

func _setup_scene() -> void:
	var packed_scene: PackedScene = load("res://scenes/statistics_screen.tscn") as PackedScene
	scene = packed_scene.instantiate() as Control
	
	mock_stats_manager = Node.new()
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Node
var returned_stats: Dictionary = {}
func get_stats(diff: String) -> Dictionary:
	if returned_stats.has(diff): return returned_stats[diff]
	return {"games_started": 0, "games_won": 0, "best_time_seconds": 0, "total_time_seconds": 0, "average_time_seconds": 0.0}
func format_time(seconds: int) -> String:
	if seconds <= 0: return "--:--"
	var m := seconds / 60
	var s := seconds % 60
	return "%02d:%02d" % [m, s]
"""
	script.reload()
	mock_stats_manager.set_script(script)
	scene.set("stats_manager_node", mock_stats_manager)

func _teardown_scene() -> void:
	if scene:
		if scene.get_parent():
			scene.get_parent().remove_child(scene)
		scene.free()
		scene = null
		
	if mock_stats_manager:
		if mock_stats_manager.get_parent():
			mock_stats_manager.get_parent().remove_child(mock_stats_manager)
		mock_stats_manager.free()
		mock_stats_manager = null

func test_statistics_screen_displays_mock_data() -> void:
	_setup_scene()
	mock_stats_manager.set("returned_stats", {
		"easy": {
			"games_started": 5,
			"games_won": 3,
			"best_time_seconds": 125,
			"total_time_seconds": 450,
			"average_time_seconds": 150.0
		},
		"medium": {
			"games_started": 10,
			"games_won": 0,
			"best_time_seconds": 0,
			"total_time_seconds": 0,
			"average_time_seconds": 0.0
		}
	})
	
	scene._ready()
	
	var easy_started = scene.get_node("MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/EasyCard/VBox/GridContainer/StartedValue")
	var easy_won = scene.get_node("MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/EasyCard/VBox/GridContainer/WonValue")
	var easy_best = scene.get_node("MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/EasyCard/VBox/GridContainer/BestTimeValue")
	
	var medium_best = scene.get_node("MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/MediumCard/VBox/GridContainer/BestTimeValue")
	
	assert_eq(easy_started.text, "5")
	assert_eq(easy_won.text, "3")
	assert_eq(easy_best.text, "02:05")
	
	assert_eq(medium_best.text, "--:--")
	
	_teardown_scene()

func test_back_button_exists_and_connected() -> void:
	_setup_scene()
	scene._ready()
	
	var back_btn = scene.get_node("MarginContainer/VBoxContainer/Header/BackButton")
	assert_true(back_btn != null)
	var is_conn = back_btn.pressed.is_connected(scene._on_back_pressed)
	assert_true(is_conn)
	
	_teardown_scene()
