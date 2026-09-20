import os

def generate_board():
    out = []
    out.append('[gd_scene load_steps=3 format=3 uid="uid://cyboard"]')
    out.append('')
    out.append('[ext_resource type="Script" path="res://scripts/board_ui.gd" id="1_bd1"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/cell.tscn" id="2_cel"]')
    out.append('')
    out.append('[node name="Board" type="AspectRatioContainer"]')
    out.append('anchors_preset = 15')
    out.append('anchor_right = 1.0')
    out.append('anchor_bottom = 1.0')
    out.append('grow_horizontal = 2')
    out.append('grow_vertical = 2')
    out.append('script = ExtResource("1_bd1")')
    out.append('')
    out.append('[node name="Background" type="ColorRect" parent="."]')
    out.append('layout_mode = 2')
    # White background creates white grid lines
    out.append('color = Color(1, 1, 1, 1)')
    out.append('')
    out.append('[node name="MarginContainer" type="MarginContainer" parent="."]')
    out.append('layout_mode = 2')
    out.append('theme_override_constants/margin_left = 4')
    out.append('theme_override_constants/margin_top = 4')
    out.append('theme_override_constants/margin_right = 4')
    out.append('theme_override_constants/margin_bottom = 4')
    out.append('')
    out.append('[node name="MacroGrid" type="GridContainer" parent="MarginContainer"]')
    out.append('layout_mode = 2')
    out.append('theme_override_constants/h_separation = 6')
    out.append('theme_override_constants/v_separation = 6')
    out.append('columns = 3')
    out.append('')

    for macro_r in range(3):
        for macro_c in range(3):
            out.append(f'[node name="MicroGrid_{macro_r}_{macro_c}" type="GridContainer" parent="MarginContainer/MacroGrid"]')
            out.append('layout_mode = 2')
            out.append('size_flags_horizontal = 3')
            out.append('size_flags_vertical = 3')
            out.append('theme_override_constants/h_separation = 2')
            out.append('theme_override_constants/v_separation = 2')
            out.append('columns = 3')
            out.append('')
            
            for micro_r in range(3):
                for micro_c in range(3):
                    row = macro_r * 3 + micro_r
                    col = macro_c * 3 + micro_c
                    out.append(f'[node name="Cell_{row}_{col}" parent="MarginContainer/MacroGrid/MicroGrid_{macro_r}_{macro_c}" instance=ExtResource("2_cel")]')
                    out.append('layout_mode = 2')
                    out.append('size_flags_horizontal = 3')
                    out.append('size_flags_vertical = 3')
                    out.append('')

    return "\n".join(out).strip() + "\n"

if __name__ == "__main__":
    out_path = "game/scenes/board.tscn"
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(generate_board())
    print(f"Generated {out_path}")
