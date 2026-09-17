extends Control

signal resume_requested

@onready var resume_button: Button = $Panel/CenterContainer/VBoxContainer/ResumeButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)

func _on_resume_pressed() -> void:
	resume_requested.emit()
