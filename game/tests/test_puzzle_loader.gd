extends TestBase

func test_puzzle_loading_and_validation() -> void:
	var path: String = "res://data/puzzles.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "puzzles.json should exist and be readable")
	
	if file == null:
		return

	var json_text: String = file.get_as_text()
	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	assert_eq(err, OK, "puzzles.json should be valid JSON")
	
	var data: Variant = json.data
	assert_true(data is Dictionary, "puzzles.json root should be a Dictionary")
	if not (data is Dictionary):
		return
	var data_dict: Dictionary = data as Dictionary
	
	var expected_targets: Dictionary = {
		"very_easy": 50,
		"easy": 40,
		"medium": 30,
		"hard": 25,
		"very_hard": 22
	}
	
	for difficulty: String in expected_targets.keys():
		assert_true(data_dict.has(difficulty), "JSON should contain key: " + difficulty)
		var puzzles: Variant = data_dict[difficulty]
		assert_true(puzzles is Array, difficulty + " should be an Array")
		if not (puzzles is Array):
			continue
		var puzzles_arr: Array = puzzles as Array
		assert_true(puzzles_arr.size() >= 5, difficulty + " should have at least 5 puzzles")
		
		for p: Variant in puzzles_arr:
			assert_true(p is String, "Puzzle should be a string")
			if not (p is String):
				continue
			var p_str: String = p as String
			assert_eq(p_str.length(), 81, "Puzzle should be exactly 81 characters")
			
			var is_valid_chars: bool = true
			var has_symmetry: bool = true
			var clue_count: int = 0
			for i: int in range(81):
				var c: String = p_str.substr(i, 1)
				if c < "0" or c > "9":
					is_valid_chars = false
				
				if c != "0":
					clue_count += 1
				
				# Check 180 degree symmetry for clues
				var r: int = i / 9
				var col: int = i % 9
				var sym_r: int = 8 - r
				var sym_c: int = 8 - col
				var sym_i: int = sym_r * 9 + sym_c
				var sym_char: String = p_str.substr(sym_i, 1)
				
				if c != "0" and sym_char == "0":
					has_symmetry = false
				if c == "0" and sym_char != "0":
					has_symmetry = false
					
			assert_true(is_valid_chars, "Puzzle should only contain digits 0-9")
			if expected_targets[difficulty] >= 30:
				assert_true(has_symmetry, "Puzzle clues should have 180-degree rotational symmetry")
			assert_true(clue_count <= expected_targets[difficulty] + 5, "Puzzle clue count should be near " + str(expected_targets[difficulty]))
			assert_true(_is_valid_sudoku_board(p_str), "Puzzle must follow standard Sudoku uniqueness rules for rows, columns, and 3x3 boxes")

func _is_valid_sudoku_board(board_str: String) -> bool:
	if board_str.length() != 81:
		return false
		
	for i in range(9):
		var row_seen: Dictionary = {}
		var col_seen: Dictionary = {}
		for j in range(9):
			var r_char: String = board_str.substr(i * 9 + j, 1)
			if r_char != "0":
				if row_seen.has(r_char): return false
				row_seen[r_char] = true
				
			var c_char: String = board_str.substr(j * 9 + i, 1)
			if c_char != "0":
				if col_seen.has(c_char): return false
				col_seen[c_char] = true
				
	for box_r in range(3):
		for box_c in range(3):
			var box_seen: Dictionary = {}
			for i in range(3):
				for j in range(3):
					var r: int = box_r * 3 + i
					var c: int = box_c * 3 + j
					var char_val: String = board_str.substr(r * 9 + c, 1)
					if char_val != "0":
						if box_seen.has(char_val): return false
						box_seen[char_val] = true
	return true
