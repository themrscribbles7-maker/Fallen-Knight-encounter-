extends Node2D
## Fallen Knight Encounter
## Godot 4.7.x-compatible runtime scene.
##
## The scene intentionally keeps image assets as individual PNG files.
## At runtime, numbered files are assembled into AnimatedSprite2D/SpriteFrames.
##
## Supported filename patterns:
##   Parralexs Idle 1.png
##   Parralexs Idle 2.png
##   ...
##   Knight Idle 1.png
##   Knight Idle 2.png
##   ...
##
## Files can be anywhere below res://.

const VIEW_SIZE := Vector2(1280.0, 720.0)
const IDLE_FPS := 17.0

var parralexs_sprite: AnimatedSprite2D
var knight_sprite: AnimatedSprite2D

func _ready() -> void:
	_create_background()

	parralexs_sprite = _create_character(
		"Parralexs Idle",
		Vector2(330.0, 430.0),
		false
	)

	knight_sprite = _create_character(
		"Knight Idle",
		Vector2(950.0, 430.0),
		false
	)

func _create_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.position = Vector2.ZERO
	background.size = VIEW_SIZE
	background.color = Color(0.035, 0.035, 0.05, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -100
	add_child(background)

func _create_character(
	prefix: String,
	character_position: Vector2,
	flip_horizontal: bool
) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = prefix.replace(" ", "_")
	sprite.position = character_position
	sprite.centered = true
	sprite.flip_h = flip_horizontal

	var frames := _build_sprite_frames(prefix)

	if frames.has_animation("idle"):
		sprite.sprite_frames = frames
		sprite.animation = &"idle"
		sprite.autoplay = "idle"
		sprite.speed_scale = 1.0
		sprite.play(&"idle")
	else:
		sprite.sprite_frames = frames
		sprite.animation = &"idle"

	add_child(sprite)
	return sprite

func _build_sprite_frames(prefix: String) -> SpriteFrames:
	var frames := SpriteFrames.new()

	if frames.has_animation("default"):
		frames.remove_animation("default")

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", IDLE_FPS)
	frames.set_animation_loop(&"idle", true)

	var files := _find_numbered_pngs("res://", prefix)

	for file_path in files:
		var texture := load(file_path) as Texture2D
		if texture != null:
			frames.add_frame(&"idle", texture)

	return frames

func _find_numbered_pngs(root_path: String, prefix: String) -> Array[String]:
	var results: Array[Dictionary] = []
	_scan_directory(root_path, prefix, results)

	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["number"]) < int(b["number"])
	)

	var paths: Array[String] = []
	for item in results:
		paths.append(String(item["path"]))

	return paths

func _scan_directory(
	directory_path: String,
	prefix: String,
	results: Array[Dictionary]
) -> void:
	var directory := DirAccess.open(directory_path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()

	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = directory.get_next()
			continue

		var full_path := directory_path.path_join(entry_name)

		if directory.current_is_dir():
			_scan_directory(full_path, prefix, results)
		elif entry_name.to_lower().ends_with(".png"):
			var stem := entry_name.get_basename()

			if stem.begins_with(prefix):
				var suffix := stem.substr(prefix.length()).strip_edges()

				if suffix.is_valid_int():
					results.append({
						"path": full_path,
						"number": int(suffix)
					})

		entry_name = directory.get_next()

	directory.list_dir_end()
