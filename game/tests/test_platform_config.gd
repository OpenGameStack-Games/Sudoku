extends "res://tests/test_base.gd"

func test_android_and_web_export_presets() -> void:
	var file: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert_not_null(file, "export_presets.cfg should exist.")
	if file == null:
		return

	var content: String = file.get_as_text()

	assert_contains(content, "screen/immersive_mode=false", "Immersive mode should be disabled (false) to avoid safe area cutoffs.")
	assert_contains(content, "package/unique_name=\"games.audrain.sudoku\"", "Package unique name should be games.audrain.sudoku.")
	assert_contains(content, "name=\"Web\"", "Web export preset should exist.")
	assert_contains(content, "platform=\"Web\"", "Web export preset platform should be Web.")
	assert_file_exists("res://assets/icons/icon.png", "icon.png should exist.")
	assert_file_exists("res://assets/icons/icon_foreground.png", "icon_foreground.png should exist.")
	assert_file_exists("res://assets/icons/icon_background.png", "icon_background.png should exist.")

	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("res://export_presets.cfg")
	assert_eq(err, OK, "export_presets.cfg should load cleanly as a ConfigFile.")
	if err == OK:
		var android_filter: String = str(cfg.get_value("preset.0", "include_filter", ""))
		var web_filter: String = str(cfg.get_value("preset.1", "include_filter", ""))
		assert_contains(android_filter, "*.ttf", "Android preset include_filter must include '*.ttf'.")
		assert_contains(android_filter, "*.json", "Android preset include_filter must include '*.json'.")
		assert_contains(web_filter, "*.ttf", "Web preset include_filter must include '*.ttf'.")
		assert_contains(web_filter, "*.json", "Web preset include_filter must include '*.json'.")

		var export_version: String = str(cfg.get_value("preset.0.options", "version/name", ""))
		var project_version: String = str(ProjectSettings.get_setting("application/config/version", ""))
		assert_eq(project_version, export_version, "project.godot config/version must match export_presets.cfg version/name.")

func test_project_settings() -> void:
	var file: FileAccess = FileAccess.open("res://project.godot", FileAccess.READ)
	assert_not_null(file, "project.godot should exist.")
	if file == null:
		return

	var content: String = file.get_as_text()
	assert_contains(content, "window/handheld/orientation=1", "Portrait orientation should be set.")
	assert_contains(content, "window/stretch/mode=\"canvas_items\"", "Stretch mode should be canvas_items.")
	assert_contains(content, "window/stretch/aspect=\"expand\"", "Stretch aspect should be expand.")
	assert_contains(content, "emulate_touch_from_mouse=true", "Emulate touch from mouse should be enabled.")
	assert_true(ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 1, "V-Sync mode should be forced enabled (1).")
	assert_contains(content, "renderer/rendering_method=\"gl_compatibility\"", "Renderer should be set to gl_compatibility.")
	assert_contains(content, "renderer/rendering_method.mobile=\"gl_compatibility\"", "Mobile renderer should be set to gl_compatibility.")
	assert_contains(content, "config/icon=\"res://assets/icons/mascot_icon.png\"", "Project icon should be set to mascot_icon.png.")
	assert_contains(content, "boot_splash/image=\"res://assets/icons/mascot_icon.png\"", "Splash screen should be set to mascot_icon.png.")
	assert_file_exists("res://assets/icons/mascot_icon.png", "mascot_icon.png should exist.")
	assert_contains(content, "McpInteractionServer=\"*res://autoloads/mcp_interaction_server.gd\"", "McpInteractionServer should point to res://autoloads/mcp_interaction_server.gd.")
	assert_file_exists("res://autoloads/mcp_interaction_server.gd", "mcp_interaction_server.gd should exist in res://autoloads/.")
	assert_file_exists("res://AGENTS.md", "game/AGENTS.md directory rules file should exist.")

func test_symbol_fallback_fonts() -> void:
	var symbols_path: String = "res://assets/fonts/NotoSansSymbols-Regular.ttf"
	var dejavu_path: String = "res://assets/fonts/DejaVuSans.ttf"
	assert_file_exists(symbols_path, "NotoSansSymbols-Regular.ttf must exist in res://assets/fonts/.")
	assert_file_exists(dejavu_path, "DejaVuSans.ttf must exist in res://assets/fonts/.")

	var symbols_font: FontFile = load(symbols_path) as FontFile
	var dejavu_font: FontFile = load(dejavu_path) as FontFile
	assert_not_null(symbols_font, "NotoSansSymbols-Regular.ttf must load as a valid FontFile.")
	assert_not_null(dejavu_font, "DejaVuSans.ttf must load as a valid FontFile.")

	var theme_path: String = "res://resources/theme_1930s.tres"
	assert_file_exists(theme_path, "theme_1930s.tres must exist.")
	var theme: Theme = load(theme_path) as Theme
	assert_not_null(theme, "theme_1930s.tres must load as a valid Theme.")

	var fonts_to_verify: Array[Font] = []
	if theme != null:
		var btn_font: Font = theme.get_font("font", "Button")
		if btn_font != null:
			assert_false(btn_font is SystemFont, "Button font in theme_1930s.tres must not be a SystemFont.")
			fonts_to_verify.append(btn_font)
		var lbl_font: Font = theme.get_font("font", "Label")
		if lbl_font != null and not fonts_to_verify.has(lbl_font):
			assert_false(lbl_font is SystemFont, "Label font in theme_1930s.tres must not be a SystemFont.")
			fonts_to_verify.append(lbl_font)

	assert_gt(float(fonts_to_verify.size()), 0.0, "theme_1930s.tres must define active font variation(s).")
	var required_symbols: Array[String] = ["☰", "✕", "▸", "▾", "★", "↺", "↻", "⌫", "▶", "→"]
	for active_font in fonts_to_verify:
		assert_gt(float(active_font.fallbacks.size()), 0.0, "Active theme font must have symbol fallback fonts attached for Web/HTML5 builds.")
		for sym in required_symbols:
			assert_true(active_font.has_char(ord(sym)), "Active theme font must support UI symbol '%s' (U+%04X) via bundled fallbacks." % [sym, ord(sym)])
