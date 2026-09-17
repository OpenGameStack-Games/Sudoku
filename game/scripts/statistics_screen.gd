extends Control

var stats_manager_node: Node

func _ready() -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if not stats_manager_node:
			stats_manager_node = tree.root.get_node_or_null("StatsManager")
	
	var back_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/Header/BackButton") as Button
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	
	_populate_stats()

func _populate_stats() -> void:
	if not stats_manager_node:
		push_warning("StatisticsScreen: StatsManager not found.")
		return
		
	_populate_difficulty("easy")
	_populate_difficulty("medium")
	_populate_difficulty("hard")

func _populate_difficulty(diff: String) -> void:
	var capitalized_diff: String = diff.capitalize()
	var card_path: String = "MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/%sCard" % capitalized_diff
	var card_node: Control = get_node_or_null(card_path) as Control
	
	if not card_node:
		return
		
	var stats: Dictionary = stats_manager_node.call("get_stats", diff)
	
	var started_label: Label = card_node.get_node_or_null("VBox/GridContainer/StartedValue") as Label
	if started_label:
		started_label.text = str(stats.get("games_started", 0))
		
	var won_label: Label = card_node.get_node_or_null("VBox/GridContainer/WonValue") as Label
	if won_label:
		won_label.text = str(stats.get("games_won", 0))
		
	var best_label: Label = card_node.get_node_or_null("VBox/GridContainer/BestTimeValue") as Label
	if best_label:
		best_label.text = stats_manager_node.call("format_time", stats.get("best_time_seconds", 0))
		
	var avg_label: Label = card_node.get_node_or_null("VBox/GridContainer/AverageTimeValue") as Label
	if avg_label:
		avg_label.text = stats_manager_node.call("format_time", int(stats.get("average_time_seconds", 0.0)))

func _on_back_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
