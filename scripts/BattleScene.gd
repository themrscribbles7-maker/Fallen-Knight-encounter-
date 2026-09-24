extends Node2D
## Initial battle presentation. Builds the two idle animations directly from the
## numbered PNGs already present in the project; no artwork is duplicated.

const FPS := 17.0
const SCREEN_SIZE := Vector2(1280, 720)
const ASSET_ROOT := "res://"

var knight: AnimatedSprite2D
var parralexs: AnimatedSprite2D
var status_label: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101018"))
	_build_background()
	parralexs = _make_actor("Parralexs", Vector2(310, 300), Color("8c78b5"))
	knight = _make_actor("Knight", Vector2(970, 300), Color("9b343f"))
	status_label = Label.new()
	status_label.text = "FALLEN KNIGHT ENCOUNTER"
	status_label.position = Vector2(40, 32)
	status_label.add_theme_font_size_override("font_size", 28)
	add_child(status_label)

func _build_background() -> void:
	# Use the supplied Background image when it can be found. The color is only
	# a non-art fallback so the scene remains runnable before import completes.
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

func _make_actor(actor_name: String, position: Vector2, fallback_color: Color) -> AnimatedSprite2D:
	var actor := AnimatedSprite2D.new()
	actor.name = actor_name
	actor.position = position
	actor.sprite_frames = _make_idle_frames(actor_name)
	if actor.sprite_frames and actor.sprite_frames.has_animation("idle"):
		actor.animation = "idle"
		actor.autoplay = "idle"
		actor.play()
	else:
		# No replacement artwork is generated. This marker makes a missing asset
		# obvious while still allowing the scene to open in the editor.
		var marker := Polygon2D.new()
		marker.polygon = PackedVector2Array([Vector2(-40, -60), Vector2(40, -60), Vector2(40, 60), Vector2(-40, 60)])
		marker.color = fallback_color
		actor.add_child(marker)
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
	var match := RegEx.new()
	match.compile("(\\d+)$")
	var result := match.search(text)
	return int(result.get_string(1)) if result else -1

func _cover_scale(texture_size: Vector2, target_size: Vector2) -> Vector2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE
	var scale := max(target_size.x / texture_size.x, target_size.y / texture_size.y)
	return Vector2(scale, scale)
