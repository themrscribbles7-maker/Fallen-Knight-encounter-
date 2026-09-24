extends PanelContainer

var choices: Array[Label] = []
var selected_index: int = 0

func _ready() -> void:
	add_theme_stylebox_override("panel", _panel_style())
	var container := get_node_or_null("MarginContainer/VBoxContainer")
	if container == null:
		return
	for child in container.get_children():
		if child is Label:
			choices.append(child as Label)
	_refresh_selection()

func _process(_delta: float) -> void:
	if not visible or choices.is_empty():
		return
	if Input.is_action_just_pressed("ui_up"):
		selected_index = (selected_index + choices.size() - 1) % choices.size()
		_refresh_selection()
	if Input.is_action_just_pressed("ui_down"):
		selected_index = (selected_index + 1) % choices.size()
		_refresh_selection()

func _refresh_selection() -> void:
	for index in range(choices.size()):
		var label := choices[index]
		if index == selected_index:
			label.text = "> " + label.text.trim_prefix("> ")
			label.add_theme_color_override("font_color", Color("f8ed7d"))
		else:
			label.text = "  " + label.text.trim_prefix("> ").trim_prefix("  ")
			label.add_theme_color_override("font_color", Color.WHITE)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1b24")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("d4d0d9")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style
