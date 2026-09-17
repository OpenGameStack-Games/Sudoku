class_name TimeManagerAutoLoad
extends Node
## Manages the gameplay timer, application focus lifecycle, and screen wake lock.

signal time_updated(seconds: int, formatted_str: String)

var _active: bool = false
var _manual_pause: bool = false
var _is_focused: bool = true
var _elapsed_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if _active and not _manual_pause and _is_focused:
		var old_seconds: int = int(_elapsed_seconds)
		_elapsed_seconds += delta
		var new_seconds: int = int(_elapsed_seconds)
		if new_seconds > old_seconds:
			time_updated.emit(new_seconds, get_formatted_time())

func start(initial_seconds: int = 0) -> void:
	_elapsed_seconds = float(initial_seconds)
	_active = true
	_manual_pause = false
	_update_wake_lock()
	time_updated.emit(int(_elapsed_seconds), get_formatted_time())

func pause() -> void:
	_manual_pause = true
	_update_wake_lock()

func resume() -> void:
	if _active:
		_manual_pause = false
		_update_wake_lock()

func reset() -> void:
	_active = false
	_manual_pause = false
	_elapsed_seconds = 0.0
	_update_wake_lock()

func get_elapsed_seconds() -> int:
	return int(_elapsed_seconds)

func get_formatted_time() -> String:
	var secs: int = get_elapsed_seconds()
	var h: int = secs / 3600
	var m: int = (secs % 3600) / 60
	var s: int = secs % 60
	if h > 0:
		return "%02d:%02d:%02d" % [h, m, s]
	else:
		return "%02d:%02d" % [m, s]

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_is_focused = false
			_update_wake_lock()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_is_focused = true
			_update_wake_lock()

func _update_wake_lock() -> void:
	if _active and not _manual_pause and _is_focused:
		DisplayServer.screen_set_keep_on(true)
	else:
		DisplayServer.screen_set_keep_on(false)
