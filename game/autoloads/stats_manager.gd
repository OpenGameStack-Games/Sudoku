class_name StatsManagerAutoLoad
extends Node

## Manages player statistics across different difficulties.
## Handles recording wins, time tracking, and persistence to disk.

const STATS_FILE_PATH: String = "user://stats.json"

var _stats: Dictionary = {}

func _ready() -> void:
	_init_default_stats()
	_load_stats()

func _init_default_stats() -> void:
	_stats = {
		"very_easy": _create_empty_stat(),
		"easy": _create_empty_stat(),
		"medium": _create_empty_stat(),
		"hard": _create_empty_stat(),
		"very_hard": _create_empty_stat()
	}

func _create_empty_stat() -> Dictionary:
	return {
		"games_started": 0,
		"games_won": 0,
		"best_time_seconds": 0,
		"total_time_seconds": 0,
		"average_time_seconds": 0.0
	}

func _load_stats() -> void:
	if not FileAccess.file_exists(STATS_FILE_PATH):
		return
	
	var file := FileAccess.open(STATS_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("StatsManager: Failed to open stats file for reading.")
		return
	
	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		push_warning("StatsManager: Invalid JSON in stats file, using defaults.")
		return
		
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("StatsManager: Stats file root is not a dictionary, using defaults.")
		return
		
	var dict_data: Dictionary = data
	for diff in _stats.keys():
		if dict_data.has(diff) and typeof(dict_data[diff]) == TYPE_DICTIONARY:
			var loaded_stat: Dictionary = dict_data[diff]
			var my_stat: Dictionary = _stats[diff]
			for key in my_stat.keys():
				if loaded_stat.has(key):
					if typeof(my_stat[key]) == TYPE_FLOAT:
						my_stat[key] = float(loaded_stat[key])
					elif typeof(my_stat[key]) == TYPE_INT:
						my_stat[key] = int(loaded_stat[key])
					else:
						my_stat[key] = loaded_stat[key]

func _save_stats() -> void:
	var file := FileAccess.open(STATS_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("StatsManager: Failed to open stats file for writing.")
		return
	
	var json_string := JSON.stringify(_stats)
	file.store_string(json_string)

func record_game_started(difficulty: String) -> void:
	if not _stats.has(difficulty):
		push_warning("StatsManager: Unknown difficulty '%s'" % difficulty)
		return
		
	_stats[difficulty]["games_started"] += 1
	_save_stats()

func record_game_won(difficulty: String, elapsed_seconds: int) -> void:
	if not _stats.has(difficulty):
		push_warning("StatsManager: Unknown difficulty '%s'" % difficulty)
		return
		
	var diff_stats: Dictionary = _stats[difficulty]
	diff_stats["games_won"] += 1
	diff_stats["total_time_seconds"] += elapsed_seconds
	
	if diff_stats["best_time_seconds"] == 0 or elapsed_seconds < diff_stats["best_time_seconds"]:
		diff_stats["best_time_seconds"] = elapsed_seconds
		
	diff_stats["average_time_seconds"] = float(diff_stats["total_time_seconds"]) / float(diff_stats["games_won"])
	
	_save_stats()

func format_time(seconds: int) -> String:
	if seconds <= 0:
		return "--:--"
		
	var m := seconds / 60
	var s := seconds % 60
	return "%02d:%02d" % [m, s]

# Helper to inspect stats during tests
func get_stats(difficulty: String) -> Dictionary:
	if _stats.has(difficulty):
		return _stats[difficulty].duplicate()
	return {}
