import sys
import re

def main():
    tscn_path = r'c:\Users\kevin\OGS_Projects\Sudoku\.worktrees\issue-127\game\scenes\statistics_screen.tscn'
    with open(tscn_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We will just write a new tscn from scratch since it's simple enough, or replace the CardsContainer part.
    # The header and margin container are fine.
    # Let's extract everything up to `[node name="EasyCard" type="PanelContainer" parent="MarginContainer/VBoxContainer/CardsContainer"]`
    
    header_split = content.split('[node name="EasyCard" type="PanelContainer" parent="MarginContainer/VBoxContainer/CardsContainer"]')
    if len(header_split) != 2:
        print("Could not split file")
        return
        
    top_part = header_split[0]
    
    difficulties = [
        ("VeryEasy", "Very Easy"),
        ("Easy", "Easy"),
        ("Medium", "Medium"),
        ("Hard", "Hard"),
        ("VeryHard", "Very Hard")
    ]
    
    cards_str = ""
    for idx, (node_name, title) in enumerate(difficulties):
        cards_str += f"""[node name="{node_name}Card" type="PanelContainer" parent="MarginContainer/VBoxContainer/CardsContainer"]
size_flags_vertical = 3
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_card")

[node name="VBox" type="VBoxContainer" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card"]
layout_mode = 2
theme_override_constants/separation = 10

[node name="DifficultyLabel" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 36
text = "{title}"
horizontal_alignment = 1

[node name="GridContainer" type="GridContainer" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox"]
layout_mode = 2
columns = 4
theme_override_constants/h_separation = 15
theme_override_constants/v_separation = 5

[node name="StartedLabel" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "Started"

[node name="StartedValue" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "0"
horizontal_alignment = 2

[node name="WonLabel" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "Won"

[node name="WonValue" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "0"
horizontal_alignment = 2

[node name="BestTimeLabel" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "Best Time"

[node name="BestTimeValue" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "--:--"
horizontal_alignment = 2

[node name="AverageTimeLabel" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "Avg Time"

[node name="AverageTimeValue" type="Label" parent="MarginContainer/VBoxContainer/CardsContainer/{node_name}Card/VBox/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
text = "--:--"
horizontal_alignment = 2
"""
        if idx < len(difficulties) - 1:
            cards_str += "\n"

    new_content = top_part + cards_str
    
    with open(tscn_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Done")

if __name__ == "__main__":
    main()
