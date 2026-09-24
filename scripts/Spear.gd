extends Node2D
## Reusable Spear projectile for the dissection attack.
## The numbered Spear PNGs are assembled into one looping animation.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2(470.0, 180.0, 340.0, 230.0)
var lifetime: float = 5.0

func _ready() -> void:
	var frames: SpriteFrames = _build_spear_frames()

	if frames.get_frame_count("spear") > 0:
		sprite.sprite_frames = frames
		sprite.animation = "spear"
		sprite.play("spear")
	else:
		_create_fallback_visual()

func _process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	if sprite != null and velocity.length_squared() > 0.0:
		sprite.rotation = velocity.angle() + PI / 2.0

func set_velocity(value: Vector2) -> void:
	velocity = value

func set_bounds(value: Rect2) -> void:
	bounds = value

func set_lifetime(value: float) -> void:
	lifetime = value

func _build_spear_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("spear")
	frames.set_animation_speed("spear", 17.0)
	frames.set_animation_loop("spear", true)

	var matches: Array[Dictionary] = []
	for path in _find_png_files("res://"):
		var filename := path.get_file().get_basename().to_lower()
		if not filename.begins_with("spear"):
			continue

		var frame_number := _trailing_number(filename)
		if frame_number >= 0:
			matches.append({"number": frame_number, "path": path})

	matches.sort_custom(_sort_frame_numbers)

	for match_data in matches:
		var texture := load(match_data["path"]) as Texture2D
		if texture != null:
			frames.add_frame("spear", texture)

	return frames

func _sort_frame_numbers(first: Dictionary, second: Dictionary) -> bool:
	return int(first["number"]) < int(second["number"])

func _find_png_files(directory: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(directory)

	if dir == null:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not file_name.begins_with("."):
			var path := directory.path_join(file_name)

			if dir.current_is_dir():
				files.append_array(_find_png_files(path))
			elif file_name.to_lower().ends_with(".png"):
				files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()
	return files

func _trailing_number(text: String) -> int:
	var regex := RegEx.new()
	regex.compile("(\\d+)$")
	var result := regex.search(text)

	if result == null:
		return -1

	return int(result.get_string(1))

func _create_fallback_visual() -> void:
	var fallback := ColorRect.new()
	fallback.size = Vector2(14.0, 34.0)
	fallback.position = Vector2(-7.0, -17.0)
	fallback.color = Color("b0d4ff")
	add_child(fallback)
