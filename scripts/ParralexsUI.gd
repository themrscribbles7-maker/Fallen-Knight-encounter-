[gd_scene load_steps=2 format=3]

[ext_resource type="res://scripts/ParralexsUI.gd" type="Script" id="1"]

[node name="ParralexsUI" type="PanelContainer"]
custom_minimum_size = Vector2(420, 190)
script = ExtResource("1")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 18
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 18

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2
alignment = 1

[node name="Choice1" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "FIGHT"

[node name="Choice2" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "ACT"

[node name="Choice3" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "ITEM"

[node name="Choice4" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "MERCY"
