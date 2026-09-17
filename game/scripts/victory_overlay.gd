class_name VictoryOverlay
extends Control

signal play_again_requested
signal main_menu_requested
signal statistics_requested

var time_label: Label
var play_again_btn: Button
var main_menu_btn: Button
var stats_btn: Button
var admire_btn: Button
var restore_btn: Button
var panel: PanelContainer

func _ready() -> void:
	panel = get_node_or_null("PanelContainer") as PanelContainer
	time_label = get_node_or_null("PanelContainer/VBoxContainer/TimeLabel") as Label
	play_again_btn = get_node_or_null("PanelContainer/VBoxContainer/PlayAgainButton") as Button
	main_menu_btn = get_node_or_null("PanelContainer/VBoxContainer/MainMenuButton") as Button
	stats_btn = get_node_or_null("PanelContainer/VBoxContainer/StatsButton") as Button
	admire_btn = get_node_or_null("PanelContainer/VBoxContainer/AdmireButton") as Button
	restore_btn = get_node_or_null("RestoreButton") as Button
	
	if play_again_btn: play_again_btn.pressed.connect(func() -> void: play_again_requested.emit())
	if main_menu_btn: main_menu_btn.pressed.connect(func() -> void: main_menu_requested.emit())
	if stats_btn: stats_btn.pressed.connect(func() -> void: statistics_requested.emit())
	if admire_btn: admire_btn.pressed.connect(_on_admire_pressed)
	if restore_btn: restore_btn.pressed.connect(_on_restore_pressed)

func show_victory(elapsed_seconds: int) -> void:
	show()
	if panel:
		panel.show()
	if restore_btn:
		restore_btn.hide()
	
	if time_label:
		var m := elapsed_seconds / 60
		var s := elapsed_seconds % 60
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
