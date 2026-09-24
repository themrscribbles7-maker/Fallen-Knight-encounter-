extends Node2D

# Core battle layout and character setup.
# This scene hosts the actors, custom UI, battle box, and soul.

const FPS := 17.0
const SCREEN_SIZE := Vector2(1280, 720)
const ASSET_ROOT := "res://"

var battle_manager: Node
var parralexs_actor: AnimatedSprite2D
var knight_actor: AnimatedSprite2D
var battle_box: Node2D
var soul: Node2D
var ui_root: PanelContainer
var status_label: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101018"))
	_build_background()
	_create_layout()
	_setup_battle_manager()
	status_label = Label.new()
	status_label.text = "Fallen Knight Encounter"
	status_label.position = Vector2(40, 30)
	status_label.add_theme_font_size_override("font_size", 22)
	add_child(status_label)

func _create_layout() -> void:
	parralexs_actor = _make_actor("Parralexs", Vector2(280, 300), Color("8d75b5"), true)
	knight_actor = _make_actor("Knight", Vector2(990, 300), Color("a73b45"), false)

	var ui_scene := load("res://scenes/ParralexsUI.tscn") as PackedScene
	if ui_scene:
		ui_root = ui_scene.instantiate()
		ui_root.position = Vector2(150, 470)
		add_child(ui_root)
	else:
		ui_root = PanelContainer.new()
		ui_root.position = Vector2(150, 470)
		ui_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ui_root.add_theme_stylebox_override("panel", _make_panel_style())
		add_child(ui_root)

	var box_scene := load("res://scenes/BattleBox.tscn") as PackedScene
	if box_scene:
		battle_box = box_scene.instantiate()
		battle_box.position = Vector2(480, 170)
		battle_box.visible = false
		add_child(battle_box)
	else:
		battle_box = Node2D.new()
		battle_box.position = Vector2(480, 170)
		battle_box.visible = false
		add_child(battle_box)
		var rect := ColorRect.new()
		rect.size = Vector2(320, 220)
		rect.position = Vector2.ZERO
		rect.color = Color("2e2e38")
		battle_box.add_child(rect)

	var soul_scene := load("res://scenes/Soul.tscn") as PackedScene
	if soul_scene:
		soul = soul_scene.instantiate()
		soul.visible = false
		soul.position = Vector2(620, 300)
		add_child(soul)
	else:
		soul = Node2D.new()
		soul.visible = false
		soul.position = Vector2(620, 300)
		add_child(soul)
		var circle := ColorRect.new()
		circle.size = Vector2(18, 18)
		circle.color = Color("ffffff")
		soul.add_child(circle)

func _setup_battle_manager() -> void:
	battle_manager = load("res://scripts/BattleManager.gd").new()
	battle_manager.set_meta("battle_scene", self)
	add_child(battle_manager)
	battle_manager.configure(self, parralexs_actor, knight_actor, ui_root, battle_box, soul)
	battle_manager.begin_normal_battle()

func _build_background() -> void:
	var background_texture := _find_single_asset(["background"])
	if background_texture:
		var background := Sprite2D.new()
		background.texture = background_texture
		background.position = SCREEN_SIZE / 2.0
		background.centered = true
		background.scale = _cover_scale(background_texture.get_size(), SCREEN_SIZE)
		background.z_index = -10
		add_child(background)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color("181824")
		fallback.position = Vector2.ZERO
		fallback.size = SCREEN_SIZE
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.z_index = -10
		add_child(fallback)

func _make_actor(actor_name: String, position: Vector2, fallback_color: Color, is_player: bool) -> AnimatedSprite2D:
	var actor := AnimatedSprite2D.new()
	actor.name = actor_name
	actor.position = position
	actor.sprite_frames = _make_idle_frames(actor_name)
	if actor.sprite_frames and actor.sprite_frames.has_animation("idle"):
		actor.animation = "idle"
		actor.autoplay = "idle"
		actor.play()
		actor.z_index = 2
	else:
		var marker := Polygon2D.new()
		marker.polygon = PackedVector2Array([Vector2(-40, -60), Vector2(40, -60), Vector2(40, 60), Vector2(-40, 60)])
		marker.color = fallback_color
		actor.add_child(marker)
		actor.z_index = 2
	add_child(actor)
	return actor

func _make_idle_frames(actor_name: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", FPS)
	frames.set_animation_loop("idle", true)
	var textures := _find_numbered_frames(actor_name + " idle")
	for texture in textures:
		frames.add_frame("idle", texture)
	return frames

func _find_numbered_frames(prefix: String) -> Array[Texture2D]:
	var matches: Array[Dictionary] = []
	for path in _all_png_paths(ASSET_ROOT):
		var base := path.get_file().get_basename().to_lower()
		var wanted := prefix.to_lower()
		if not base.begins_with(wanted):
			continue
		var number := _trailing_number(base)
		if number >= 0:
			matches.append({"number": number, "path": path})
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.number < b.number)
	var result: Array[Texture2D] = []
	for item in matches:
		var texture := load(item.path) as Texture2D
		if texture:
			result.append(texture)
	return result

func _find_single_asset(words: Array[String]) -> Texture2D:
	for path in _all_png_paths(ASSET_ROOT):
		var base := path.get_file().get_basename().to_lower()
		var found := true
		for word in words:
			if not base.contains(word.to_lower()):
				found = false
		if found:
			return load(path) as Texture2D
	return null

func _all_png_paths(directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(directory)
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var path := directory.path_join(file_name)
		if dir.current_is_dir():
			result.append_array(_all_png_paths(path))
		elif file_name.to_lower().ends_with(".png"):
			result.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func _trailing_number(text: String) -> int:
	var regex := RegEx.new()
	regex.compile("(\\d+)$")
	var result := regex.search(text)
	return int(result.get_string(1)) if result else -1

func _cover_scale(texture_size: Vector2, target_size: Vector2) -> Vector2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE
	var scale := max(target_size.x / texture_size.x, target_size.y / texture_size.y)
	return Vector2(scale, scale)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20202a")
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color("7c7b8d")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style
