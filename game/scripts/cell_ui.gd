class_name CellUI
extends ColorRect

signal cell_selected(row: int, col: int)
signal cell_deselected

const COLOR_NORMAL = Color("222222")
const COLOR_SELECTED = Color("ffa500") # Flat Orange
const COLOR_PEER = Color("ffdb99") # Light Orange
const COLOR_MATCH = Color("cc8400") # Darker Orange
const COLOR_CONFLICT = Color("ff0000") # Flat Red

var row: int = 0
var col: int = 0
var is_clue: bool = false


func _ready() -> void:
	color = COLOR_NORMAL
	gui_input.connect(_on_gui_input)
	for i in range(1, 10):
		var cand_label: Label = $CandidatesCenter/CandidatesGrid.get_node("Candidate" + str(i)) as Label
		cand_label.text = ""

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_selected.emit(row, col)

func set_value(val: int, clue: bool) -> void:
	self.is_clue = clue
	if val == 0:
		$ValueLabel.text = ""
	else:
		$ValueLabel.text = str(val)
	
	if is_clue:
		$ValueLabel.add_theme_font_size_override("font_size", 32)
	else:
		$ValueLabel.add_theme_font_size_override("font_size", 28)

func set_candidates(candidates: Array[int], match_digit: int = 0) -> void:
	for i in range(1, 10):
		var cand_label: Label = $CandidatesCenter/CandidatesGrid.get_node("Candidate" + str(i)) as Label
		if candidates.has(i):
			cand_label.text = str(i)
			if i == match_digit:
				cand_label.add_theme_font_size_override("font_size", 24) # Enlarged
				cand_label.modulate = Color(1, 0.8, 0.2)
			else:
				cand_label.add_theme_font_size_override("font_size", 16)
				cand_label.modulate = Color.WHITE
		else:
			cand_label.text = ""

func set_highlight_state(state: String) -> void:
	var text_color := Color.WHITE
	match state:
		"normal":
			color = COLOR_NORMAL
			text_color = Color.WHITE if is_clue else Color("#a0a0a0")
		"selected":
			color = COLOR_SELECTED
			text_color = Color("#121212")
		"peer":
			color = COLOR_PEER
			text_color = Color("#121212")
		"match":
			color = COLOR_MATCH
			text_color = Color("#121212")
		"conflict":
			color = COLOR_CONFLICT
			text_color = Color.WHITE
	
	$ValueLabel.add_theme_color_override("font_color", text_color)
	for i in range(1, 10):
		var cand_label: Label = $CandidatesCenter/CandidatesGrid.get_node("Candidate" + str(i)) as Label
		cand_label.add_theme_color_override("font_color", text_color)
