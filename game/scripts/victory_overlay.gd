class_name VictoryOverlay
extends Control

signal play_again_requested
signal main_menu_requested
signal statistics_requested

var time_label: Label = null
var play_again_btn: Button = null
var main_menu_btn: Button = null
var stats_btn: Button = null
var admire_btn: Button = null
var restore_btn: Button = null
var panel: PanelContainer = null
var mascot_rect: TextureRect = null

func _ready() -> void:
	panel = get_node_or_null("PanelContainer") as PanelContainer
	mascot_rect = get_node_or_null("PanelContainer/VBoxContainer/MascotRect") as TextureRect
	time_label = get_node_or_null("PanelContainer/VBoxContainer/TimeLabel") as Label
	play_again_btn = get_node_or_null("PanelContainer/VBoxContainer/PlayAgainButton") as Button
	main_menu_btn = get_node_or_null("PanelContainer/VBoxContainer/MainMenuButton") as Button
	stats_btn = get_node_or_null("PanelContainer/VBoxContainer/StatsButton") as Button
	admire_btn = get_node_or_null("PanelContainer/VBoxContainer/AdmireButton") as Button
	restore_btn = get_node_or_null("RestoreButton") as Button
	
	if play_again_btn and not play_again_btn.pressed.is_connected(_on_play_again_pressed):
		play_again_btn.pressed.connect(_on_play_again_pressed)
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_main_menu_pressed):
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if stats_btn and not stats_btn.pressed.is_connected(_on_stats_pressed):
		stats_btn.pressed.connect(_on_stats_pressed)
	if admire_btn and not admire_btn.pressed.is_connected(_on_admire_pressed):
		admire_btn.pressed.connect(_on_admire_pressed)
	if restore_btn and not restore_btn.pressed.is_connected(_on_restore_pressed):
		restore_btn.pressed.connect(_on_restore_pressed)

func _on_play_again_pressed() -> void:
	play_again_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()

func _on_stats_pressed() -> void:
	statistics_requested.emit()

func show_victory(elapsed_seconds: int) -> void:
	show()
	if panel:
		panel.show()
	if restore_btn:
		restore_btn.hide()
	
	if time_label:
		var m: int = elapsed_seconds / 60
		var s: int = elapsed_seconds % 60
		time_label.text = "Completion Time: %02d:%02d" % [m, s]

func _on_admire_pressed() -> void:
	if panel:
		panel.hide()
	if restore_btn:
		restore_btn.show()

func _on_restore_pressed() -> void:
	if panel:
		panel.show()
	if restore_btn:
		restore_btn.hide()
