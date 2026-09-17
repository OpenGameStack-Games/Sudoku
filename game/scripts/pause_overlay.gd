class_name PauseOverlay
extends Control

signal resume_requested

var resume_button: Button = null

func _ready() -> void:
	if not resume_button:
		resume_button = get_node_or_null("Panel/CenterContainer/VBoxContainer/ResumeButton") as Button
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)

func _on_resume_pressed() -> void:
	resume_requested.emit()
