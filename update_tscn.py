import os

path = r"c:\Users\kevin\OGS_Projects\Sudoku\.worktrees\issue-95\game\scenes\statistics_screen.tscn"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace(
    '[node name="ScrollContainer" type="ScrollContainer" parent="MarginContainer/VBoxContainer"]\nlayout_mode = 2\nsize_flags_vertical = 3\nhorizontal_scroll_mode = 0\nvertical_scroll_mode = 1\n\n[node name="CardsContainer" type="VBoxContainer" parent="MarginContainer/VBoxContainer/ScrollContainer"]',
    '[node name="CardsContainer" type="VBoxContainer" parent="MarginContainer/VBoxContainer"]'
)

text = text.replace(
    'parent="MarginContainer/VBoxContainer/ScrollContainer/CardsContainer',
    'parent="MarginContainer/VBoxContainer/CardsContainer'
)

with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(text)
