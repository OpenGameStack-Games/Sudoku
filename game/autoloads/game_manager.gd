extends Node

signal game_started
signal game_won

var board: SudokuBoard

func _ready() -> void:
	board = SudokuBoard.new()
	board.game_won.connect(_on_game_won)

func start_game(puzzle_string: String) -> void:
	board.load_puzzle(puzzle_string)
	game_started.emit()

func _on_game_won() -> void:
	game_won.emit()
