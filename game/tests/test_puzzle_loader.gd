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
			assert_true(clue_count <= expected_targets[difficulty], "Puzzle clue count should be <= " + str(expected_targets[difficulty]))
