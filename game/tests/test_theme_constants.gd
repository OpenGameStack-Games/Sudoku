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
	assert_true(FileAccess.file_exists("res://resources/theme_1930s.tres"), "Theme resource file should exist on disk.")
	var theme: Theme = ResourceLoader.load("res://resources/theme_1930s.tres") as Theme
	assert_true(theme != null, "Theme resource should load successfully.")
	
	var style: StyleBoxFlat = theme.get_stylebox("panel", "Panel") as StyleBoxFlat
	assert_true(style != null, "Theme should have a panel style.")
	assert_eq(style.bg_color, Color("#121212"), "Panel background color should be #121212")
	assert_true(theme.has_font("clue_font", "Label"), "Theme should have clue_font configured.")
	assert_true(theme.has_font("input_font", "Label"), "Theme should have input_font configured.")
	assert_true(theme.has_font("note_font", "Label"), "Theme should have note_font configured.")
	assert_true(theme.has_font("note_font_bold", "Label"), "Theme should have note_font_bold configured.")
	assert_true(FileAccess.file_exists("res://assets/fonts/NotoSansSymbols-Regular.ttf"), "NotoSansSymbols font file should exist on disk.")
	assert_true(theme.has_font("font", "Button"), "Theme should have font configured for Button.")
	assert_true(theme.has_font("font", "Label"), "Theme should have default font configured for Label.")

func test_button_hover_style_retains_borders() -> void:
	var theme: Theme = ResourceLoader.load("res://resources/theme_1930s.tres") as Theme
	assert_true(theme != null, "Theme resource should load successfully.")
	
	var normal_style: StyleBoxFlat = theme.get_stylebox("normal", "Button") as StyleBoxFlat
	var hover_style: StyleBoxFlat = theme.get_stylebox("hover", "Button") as StyleBoxFlat
	
	assert_true(normal_style != null, "Button normal style should exist.")
	assert_true(hover_style != null, "Button hover style should exist.")
	
	# Verify that the background color of hover is explicitly different from normal
	assert_ne(normal_style.bg_color, hover_style.bg_color, "Hover background should differ from normal.")
	
	# Verify that the border widths are identical
	assert_eq(hover_style.border_width_left, normal_style.border_width_left, "Hover left border width should match normal.")
	assert_eq(hover_style.border_width_right, normal_style.border_width_right, "Hover right border width should match normal.")
	assert_eq(hover_style.border_width_top, normal_style.border_width_top, "Hover top border width should match normal.")
	assert_eq(hover_style.border_width_bottom, normal_style.border_width_bottom, "Hover bottom border width should match normal.")
	
	# Verify the border colors match
	assert_eq(hover_style.border_color, normal_style.border_color, "Hover border color should match normal.")
