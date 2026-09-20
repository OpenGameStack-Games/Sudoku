## UI controller for the Statistics Screen.
## Displays historical gameplay metrics (games started, won, best time, average time)
## for Easy, Medium, and Hard difficulty levels.
extends Control

var stats_manager_node: Node

func _ready() -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		if not stats_manager_node:
			stats_manager_node = tree.root.get_node_or_null("StatsManager")
	
	var back_btn: Button = get_node_or_null("MarginContainer/VBoxContainer/Header/BackButton") as Button
	if back_btn and not back_btn.pressed.is_connected(_on_back_pressed):
		back_btn.pressed.connect(_on_back_pressed)
	
	_populate_stats()
	_scale_ui()

func _populate_stats() -> void:
	if not stats_manager_node:
		push_warning("StatisticsScreen: StatsManager not found.")
		return
		
	_populate_difficulty("easy")
	_populate_difficulty("medium")
	_populate_difficulty("hard")

func _populate_difficulty(diff: String) -> void:
	var capitalized_diff: String = diff.capitalize()
	# Support either path
	var card_path: String = "MarginContainer/VBoxContainer/CardsContainer/%sCard" % capitalized_diff
	var card_node: Control = get_node_or_null(card_path) as Control
	
	if not card_node:
		card_path = "MarginContainer/VBoxContainer/ScrollContainer/CardsContainer/%sCard" % capitalized_diff
		card_node = get_node_or_null(card_path) as Control
		
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_scale_ui()

func _scale_ui() -> void:
	if not is_inside_tree():
		return
	var viewport_height = get_viewport_rect().size.y
	# Base height is 1280. If it gets smaller, scale fonts down.
	var scale_factor = min(1.0, viewport_height / 1280.0)
	
	var cards_container = get_node_or_null("MarginContainer/VBoxContainer/CardsContainer")
	if not cards_container:
		cards_container = get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/CardsContainer")
		
	if not cards_container:
		return
		
	for card in cards_container.get_children():
		var diff_label = card.get_node_or_null("VBox/DifficultyLabel") as Label
		if diff_label:
			diff_label.add_theme_font_size_override("font_size", int(48 * scale_factor))
			
		var grid = card.get_node_or_null("VBox/GridContainer")
		if grid:
			for child in grid.get_children():
				if child is Label:
					child.add_theme_font_size_override("font_size", int(32 * scale_factor))
					
		# Also scale margins dynamically!
		if card is PanelContainer:
			var style = card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			style.content_margin_top = 40.0 * scale_factor
			style.content_margin_bottom = 40.0 * scale_factor
			style.content_margin_left = 40.0 * scale_factor
			style.content_margin_right = 40.0 * scale_factor
			card.add_theme_stylebox_override("panel", style)

func _on_back_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
