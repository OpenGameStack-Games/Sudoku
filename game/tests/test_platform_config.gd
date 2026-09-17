extends "res://tests/test_base.gd"

func test_android_export_presets() -> void:
	var file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert_true(file != null, "export_presets.cfg should exist.")
	
	var content := file.get_as_text()
	
	assert_true("screen/immersive_mode=false" in content, "Immersive mode should be disabled (false).")
	
	var has_json_filter: bool = false
	var lines := content.split("\n")
	for line in lines:
		if line.begins_with("include_filter="):
			if "*.json" in line:
				has_json_filter = true
	
	assert_true(has_json_filter, "include_filter should contain '*.json'.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon.png"), "icon.png should exist.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon_foreground.png"), "icon_foreground.png should exist.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon_background.png"), "icon_background.png should exist.")

func test_project_settings() -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	assert_true(file != null, "project.godot should exist.")
	
	var content := file.get_as_text()
	assert_true("window/handheld/orientation=1" in content, "Portrait orientation should be set.")
	assert_true("window/stretch/mode=\"canvas_items\"" in content, "Stretch mode should be canvas_items.")
	assert_true("window/stretch/aspect=\"expand\"" in content, "Stretch aspect should be expand.")
	assert_true("emulate_touch_from_mouse=true" in content, "Emulate touch from mouse should be enabled.")

