extends "res://tests/test_base.gd"

func test_theme_constants_loaded() -> void:
	assert_true(ThemeConstants != null, "ThemeConstants class should exist.")
	
	# Background color matches Hex #121212
	var expected_bg: Color = Color("#121212")
	assert_eq(ThemeConstants.COLOR_BG_DARK_GRAY, expected_bg, "Background color should be #121212")
	
	# All color constants are loaded and distinct
	var colors: Array[Color] = [
		ThemeConstants.COLOR_BG_DARK_GRAY,
		ThemeConstants.COLOR_UI_FOREGROUND,
		ThemeConstants.COLOR_CONFLICT_ERROR,
		ThemeConstants.COLOR_SELECTION,
		ThemeConstants.COLOR_PEER_HIGHLIGHT,
		ThemeConstants.COLOR_NUMBER_MATCH,
		ThemeConstants.COLOR_NUMPAD_EXHAUSTED
	]
	
	for i in range(colors.size()):
		for j in range(i + 1, colors.size()):
			assert_ne(colors[i], colors[j], "Colors should be distinct: %s vs %s" % [str(colors[i]), str(colors[j])])

func test_theme_resource_loads() -> void:
	var theme: Theme = ResourceLoader.load("res://resources/theme_1930s.tres") as Theme
	assert_true(theme != null, "Theme resource should load successfully.")
	
	var style: StyleBoxFlat = theme.get_stylebox("panel", "Panel") as StyleBoxFlat
	assert_true(style != null, "Theme should have a panel style.")
	assert_eq(style.bg_color, Color("#121212"), "Panel background color should be #121212")
