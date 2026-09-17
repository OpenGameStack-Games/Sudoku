class_name TestStatsManager
extends "res://tests/test_base.gd"

var stats_manager: StatsManagerAutoLoad

func _setup_manager() -> StatsManagerAutoLoad:
	if FileAccess.file_exists("user://stats.json"):
		var dir = DirAccess.open("user://")
		dir.remove("stats.json")
	var sm = StatsManagerAutoLoad.new()
	sm._ready()
	return sm

func _teardown_manager(sm: StatsManagerAutoLoad) -> void:
	if is_instance_valid(sm):
		sm.free()
	if FileAccess.file_exists("user://stats.json"):
		var dir = DirAccess.open("user://")
		dir.remove("stats.json")

func test_initial_state() -> void:
	var sm = _setup_manager()
	var easy_stats = sm.get_stats("easy")
	assert_eq(easy_stats["games_started"], 0)
	assert_eq(easy_stats["games_won"], 0)
	assert_eq(easy_stats["best_time_seconds"], 0)
	assert_eq(easy_stats["total_time_seconds"], 0)
	assert_eq(easy_stats["average_time_seconds"], 0.0)
	_teardown_manager(sm)

func test_record_game_started() -> void:
	var sm = _setup_manager()
	sm.record_game_started("easy")
	var easy_stats = sm.get_stats("easy")
	assert_eq(easy_stats["games_started"], 1)
	
	# Should not affect other difficulties
	var medium_stats = sm.get_stats("medium")
	assert_eq(medium_stats["games_started"], 0)
	_teardown_manager(sm)

func test_record_game_won_and_best_time() -> void:
	var sm = _setup_manager()
	sm.record_game_started("medium")
	
	# First win, sets best time
	sm.record_game_won("medium", 300)
	var stats = sm.get_stats("medium")
	assert_eq(stats["games_won"], 1)
	assert_eq(stats["best_time_seconds"], 300)
	assert_eq(stats["total_time_seconds"], 300)
	assert_eq(stats["average_time_seconds"], 300.0)
	
	# Slower win, does not update best time
	sm.record_game_won("medium", 400)
	stats = sm.get_stats("medium")
	assert_eq(stats["games_won"], 2)
	assert_eq(stats["best_time_seconds"], 300)
	assert_eq(stats["total_time_seconds"], 700)
	assert_eq(stats["average_time_seconds"], 350.0)
	
	# Faster win, updates best time
	sm.record_game_won("medium", 200)
	stats = sm.get_stats("medium")
	assert_eq(stats["games_won"], 3)
	assert_eq(stats["best_time_seconds"], 200)
	assert_eq(stats["total_time_seconds"], 900)
	assert_eq(stats["average_time_seconds"], 300.0)
	_teardown_manager(sm)

func test_format_time() -> void:
	var sm = _setup_manager()
	assert_eq(sm.format_time(0), "--:--")
	assert_eq(sm.format_time(-1), "--:--")
	assert_eq(sm.format_time(59), "00:59")
	assert_eq(sm.format_time(60), "01:00")
	assert_eq(sm.format_time(61), "01:01")
	assert_eq(sm.format_time(600), "10:00")
	assert_eq(sm.format_time(3599), "59:59")
	assert_eq(sm.format_time(3600), "60:00")
	_teardown_manager(sm)

func test_serialization_and_deserialization() -> void:
	var sm = _setup_manager()
	sm.record_game_started("hard")
	sm.record_game_won("hard", 125)
	
	var new_manager = StatsManagerAutoLoad.new()
	new_manager._ready()
	
	var hard_stats = new_manager.get_stats("hard")
	assert_eq(hard_stats["games_started"], 1)
	assert_eq(hard_stats["games_won"], 1)
	assert_eq(hard_stats["best_time_seconds"], 125)
	
	new_manager.free()
	_teardown_manager(sm)
