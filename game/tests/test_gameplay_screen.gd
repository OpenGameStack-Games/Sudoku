extends "res://tests/test_base.gd"

class MockTimeManager extends Node:
	signal time_updated(secs, fmt)
	var _manual_pause = false
	var _elapsed_seconds = 0
	func start(): pass
	func pause(): _manual_pause = true
	func resume(): _manual_pause = false
	func reset(): _elapsed_seconds = 0
	func get_elapsed_seconds(): return _elapsed_seconds
	func get_formatted_time(): return "00:00"

class MockSaveManager extends Node:
	var current_difficulty = ""
	var current_puzzle_string = ""
	func mark_active_game(diff, puzzle):
		current_difficulty = diff
		current_puzzle_string = puzzle
	func flush_save(): pass
	
class MockGameManager extends Node:
	var board
	func _ready():
		board = load("res://scripts/sudoku_board.gd").new()
	func start_game(puzzle):
		if board: board.load_puzzle(puzzle)

var screen
var time_manager_node
var save_manager_node
var game_manager_node

func _setup_nodes():
	time_manager_node = MockTimeManager.new()
	save_manager_node = MockSaveManager.new()
	game_manager_node = MockGameManager.new()
	
	game_manager_node._ready()
	
	var scene = load("res://scenes/gameplay_screen.tscn")
	screen = scene.instantiate()
	
	screen.time_manager_node = time_manager_node
	screen.save_manager_node = save_manager_node
	screen.game_manager_node = game_manager_node

func _teardown_nodes():
	if screen:
		screen.free()
	if time_manager_node:
		time_manager_node.free()
	if save_manager_node:
		save_manager_node.free()
	if game_manager_node:
		# game_manager_node.board is RefCounted
		game_manager_node.free()

func test_header_initialization():
	_setup_nodes()
	save_manager_node.current_difficulty = "medium"
	screen._ready()
	
	assert_eq(screen.difficulty_label.text, "Medium")
	_teardown_nodes()

func test_pause_button_toggles_board_and_timer():
	_setup_nodes()
	screen._ready()
	
	time_manager_node.start()
	assert_false(screen.pause_overlay.visible)
	
	screen.pause_button.pressed.emit()
	assert_true(screen.pause_overlay.visible)
	assert_false(screen.board_node.visible)
	assert_true(time_manager_node._manual_pause)
	
	screen.pause_overlay.resume_requested.emit()
	assert_false(screen.pause_overlay.visible)
	assert_true(screen.board_node.visible)
	assert_false(time_manager_node._manual_pause)
	
	_teardown_nodes()

func test_reset_puzzle():
	_setup_nodes()
	screen._ready()
	
	save_manager_node.current_puzzle_string = "123" + "0".repeat(78)
	
	screen._on_menu_item_pressed(0)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0)
	_teardown_nodes()

func test_new_game():
	_setup_nodes()
	screen._ready()
	
	save_manager_node.current_difficulty = "easy"
	
	screen._on_menu_item_pressed(1)
	
	assert_eq(time_manager_node.get_elapsed_seconds(), 0)
	_teardown_nodes()
