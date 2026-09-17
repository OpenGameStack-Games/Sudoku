extends "res://tests/test_base.gd"
## Unit tests for TimeManager autoload

func _setup_manager() -> TimeManagerAutoLoad:
	var tm = TimeManagerAutoLoad.new()
	tm._ready()
	tm._is_focused = true
	return tm

func _teardown_manager(tm: TimeManagerAutoLoad) -> void:
	if is_instance_valid(tm):
		tm.free()

func test_timer_initialization() -> void:
	var tm = _setup_manager()
	tm.start(10)
	assert_eq(tm.get_elapsed_seconds(), 10, "Elapsed seconds should match initial")
	assert_eq(tm.get_formatted_time(), "00:10", "Formatting should be MM:SS for < 60s")
	_teardown_manager(tm)

func test_time_formatting() -> void:
	var tm = _setup_manager()
	tm.start(59)
	assert_eq(tm.get_formatted_time(), "00:59", "59s formatting")
	tm.start(60)
	assert_eq(tm.get_formatted_time(), "01:00", "60s formatting")
	tm.start(3599)
	assert_eq(tm.get_formatted_time(), "59:59", "3599s formatting")
	tm.start(3600)
	assert_eq(tm.get_formatted_time(), "01:00:00", "3600s formatting (1 hr)")
	tm.start(3665)
	assert_eq(tm.get_formatted_time(), "01:01:05", "3665s formatting (1 hr, 1 min, 5s)")
	_teardown_manager(tm)

func test_timer_increment() -> void:
	var tm = _setup_manager()
	tm.start(0)
	tm._process(0.5)
	assert_eq(tm.get_elapsed_seconds(), 0, "Should not reach 1 second yet")
	tm._process(0.6)
	assert_eq(tm.get_elapsed_seconds(), 1, "Should have passed 1 second")
	_teardown_manager(tm)

func test_manual_pause_resume() -> void:
	var tm = _setup_manager()
	tm.start(0)
	if DisplayServer.get_name() != "headless":
		assert_true(DisplayServer.screen_is_kept_on(), "Screen should be kept on during gameplay")
	
	tm.pause()
	if DisplayServer.get_name() != "headless":
		assert_false(DisplayServer.screen_is_kept_on(), "Screen lock should be released when paused")
	tm._process(1.5)
	assert_eq(tm.get_elapsed_seconds(), 0, "Time should not increment while manually paused")
	
	tm.resume()
	if DisplayServer.get_name() != "headless":
		assert_true(DisplayServer.screen_is_kept_on(), "Screen lock should be restored when resumed")
	tm._process(1.5)
	assert_eq(tm.get_elapsed_seconds(), 1, "Time should increment after resuming")
	_teardown_manager(tm)

func test_focus_lifecycle() -> void:
	var tm = _setup_manager()
	tm.start(0)
	if DisplayServer.get_name() != "headless":
		assert_true(DisplayServer.screen_is_kept_on(), "Screen should be on initially")
	
	# Simulate focus loss
	tm._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	if DisplayServer.get_name() != "headless":
		assert_false(DisplayServer.screen_is_kept_on(), "Screen lock released on focus loss")
	tm._process(2.0)
	assert_eq(tm.get_elapsed_seconds(), 0, "Time should not increment while out of focus")
	
	# Simulate focus regain
	tm._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	if DisplayServer.get_name() != "headless":
		assert_true(DisplayServer.screen_is_kept_on(), "Screen lock restored on focus gain")
	tm._process(1.0)
	assert_eq(tm.get_elapsed_seconds(), 1, "Time increments again")
	_teardown_manager(tm)
	
func test_autoload_configured() -> void:
	assert_true(FileAccess.file_exists("res://autoloads/time_manager.gd"), "TimeManager autoload script must exist")
