class_name TestStatisticsScreen
extends "res://tests/test_base.gd"

var scene: Control
var mock_stats_manager: Node

func test_scene_and_script_assets_exist() -> void:
	assert_true(FileAccess.file_exists("res://scenes/statistics_screen.tscn"), "statistics_screen.tscn should exist on disk")
	assert_true(FileAccess.file_exists("res://scripts/statistics_screen.gd"), "statistics_screen.gd should exist on disk")

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
		"very_easy": {
			"games_started": 2, "games_won": 2, "best_time_seconds": 60, "total_time_seconds": 120, "average_time_seconds": 60.0
		},
		"easy": {
			"games_started": 5, "games_won": 3, "best_time_seconds": 125, "total_time_seconds": 450, "average_time_seconds": 150.0
		},
		"medium": {
			"games_started": 10, "games_won": 0, "best_time_seconds": 0, "total_time_seconds": 0, "average_time_seconds": 0.0
		},
		"very_hard": {
			"games_started": 1, "games_won": 0, "best_time_seconds": 0, "total_time_seconds": 0, "average_time_seconds": 0.0
		}
	})
	
	scene._ready()
	
	var very_easy_started = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/VeryEasyCard/VBox/GridContainer/StartedValue")
	assert_eq(very_easy_started.text, "2", "Very Easy games started should match")
	
	var easy_started = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/GridContainer/StartedValue")
	var easy_won = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/GridContainer/WonValue")
	var easy_best = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/GridContainer/BestTimeValue")
	var easy_avg = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/GridContainer/AverageTimeValue")
	
	assert_eq(easy_started.text, "5", "Easy games started should match")
	assert_eq(easy_won.text, "3", "Easy games won should match")
	assert_eq(easy_best.text, "02:05", "Easy best time should be formatted")
	assert_eq(easy_avg.text, "02:30", "Easy average time should be formatted")
	
	var medium_started = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/MediumCard/VBox/GridContainer/StartedValue")
	var medium_won = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/MediumCard/VBox/GridContainer/WonValue")
	var medium_best = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/MediumCard/VBox/GridContainer/BestTimeValue")
	var medium_avg = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/MediumCard/VBox/GridContainer/AverageTimeValue")
	
	assert_eq(medium_started.text, "10", "Medium games started should match")
	assert_eq(medium_won.text, "0", "Medium games won should match")
	assert_eq(medium_best.text, "--:--", "Medium best time should display empty state")
	assert_eq(medium_avg.text, "--:--", "Medium average time should display empty state")
	
	var hard_started = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/HardCard/VBox/GridContainer/StartedValue")
	assert_eq(hard_started.text, "0", "Hard games started should default to 0")

	var very_hard_started = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/VeryHardCard/VBox/GridContainer/StartedValue")
	assert_eq(very_hard_started.text, "1", "Very Hard games started should match")
	
	_teardown_scene()

func test_back_button_exists_and_connected() -> void:
	_setup_scene()
	scene._ready()
	
	var back_btn = scene.get_node("MarginContainer/VBoxContainer/Header/BackButton")
	assert_true(back_btn != null, "BackButton should exist")
	var is_conn = back_btn.pressed.is_connected(scene._on_back_pressed)
	assert_true(is_conn, "BackButton should be connected to _on_back_pressed")
	
	_teardown_scene()

func test_statistics_screen_styling_applied() -> void:
	_setup_scene()
	scene._ready()
	
	var title_lbl: Label = scene.get_node("MarginContainer/VBoxContainer/Header/Title") as Label
	assert_eq(title_lbl.get_theme_font_size("font_size"), 64, "Title font size should be 64")
	
	var easy_card: PanelContainer = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard") as PanelContainer
	var style: StyleBoxFlat = easy_card.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.content_margin_left, 20.0, "Card left margin should be 20.0")
	assert_eq(style.content_margin_top, 10.0, "Card top margin should be 10.0")
	
	var diff_lbl: Label = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/DifficultyLabel") as Label
	assert_eq(diff_lbl.get_theme_font_size("font_size"), 36, "DifficultyLabel font size should be 36")
	
	var started_val: Label = scene.get_node("MarginContainer/VBoxContainer/CardsContainer/EasyCard/VBox/GridContainer/StartedValue") as Label
	assert_eq(started_val.get_theme_font_size("font_size"), 24, "Grid Labels should have font size 24")
	
	_teardown_scene()

func test_no_scroll_container_properties() -> void:
	_setup_scene()
	scene._ready()
	
	var scroll_container = scene.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer")
	assert_true(scroll_container == null, "ScrollContainer should no longer exist to prevent scrollbars")
		
	var cards_container = scene.get_node_or_null("MarginContainer/VBoxContainer/CardsContainer")
	assert_true(cards_container != null, "CardsContainer should exist directly inside VBoxContainer")
	assert_eq(cards_container.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "Should expand horizontally")
	
	_teardown_scene()
