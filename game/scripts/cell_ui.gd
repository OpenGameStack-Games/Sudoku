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

func _ready() -> void:
	color = COLOR_NORMAL
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_selected.emit(row, col)

func set_value(val: int, is_clue: bool) -> void:
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
		var cand_label: Label = $CandidatesGrid.get_node("Candidate" + str(i)) as Label
		if candidates.has(i):
			cand_label.visible = true
			if i == match_digit:
				cand_label.add_theme_font_size_override("font_size", 24) # Enlarged
				cand_label.modulate = Color(1, 0.8, 0.2)
			else:
				cand_label.add_theme_font_size_override("font_size", 16)
				cand_label.modulate = Color.WHITE
		else:
			cand_label.visible = false

func set_highlight_state(state: String) -> void:
	match state:
		"normal":
			color = COLOR_NORMAL
		"selected":
			color = COLOR_SELECTED
		"peer":
			color = COLOR_PEER
		"match":
			color = COLOR_MATCH
		"conflict":
			color = COLOR_CONFLICT
