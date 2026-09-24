extends Node2D

# Reusable spin blade projectile used for the Fallen Knight's enemy-turn attack.
# The projectile itself handles movement and wall rebounds. The battle manager
# handles the attack flow and collision timing.

signal rebound
signal hit_player

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity: Vector2 = Vector2(1.2, 0.75).normalized() * 180.0
var bounds: Rect2 = Rect2(Vector2(500, 180), Vector2(280, 200))
var active: bool = true
var max_speed: float = 420.0
var rebound_count: int = 0

func _ready() -> void:
	if sprite == null:
		var fallback := ColorRect.new()
		fallback.size = Vector2(18, 18)
		fallback.color = Color(1.0, 0.9, 0.45, 1.0)
		add_child(fallback)
		return
	var frames := _build_animation_frames()
	if frames:
		sprite.sprite_frames = frames
		sprite.animation = "spin"
		sprite.autoplay = "spin"
		sprite.play("spin")
	else:
		sprite.modulate = Color(1.0, 0.8, 0.5, 1.0)
		var rect := ColorRect.new()
		rect.size = Vector2(18, 18)
		rect.color = Color(1.0, 0.9, 0.45, 1.0)
		sprite.add_child(rect)

func _process(delta: float) -> void:
	if not active:
		return

	position += velocity * delta

	var min_x := bounds.position.x
	var max_x := bounds.position.x + bounds.size.x
	var min_y := bounds.position.y
	var max_y := bounds.position.y + bounds.size.y
	var hit_wall := false

	if position.x <= min_x:
		position.x = min_x
		velocity.x = abs(velocity.x)
		hit_wall = true
	elif position.x >= max_x:
		position.x = max_x
		velocity.x = -abs(velocity.x)
		hit_wall = true

	if position.y <= min_y:
		position.y = min_y
		velocity.y = abs(velocity.y)
		hit_wall = true
	elif position.y >= max_y:
		position.y = max_y
		velocity.y = -abs(velocity.y)
		hit_wall = true

	if sprite:
		sprite.rotation += 0.18

	if hit_wall:
		rebound_count += 1
		var speed := velocity.length()
		if speed > 0.0:
			velocity = velocity.normalized() * min(speed + 32.0, max_speed)
		emit_signal("rebound")

func set_velocity(value: Vector2) -> void:
	velocity = value

func set_bounds(value: Rect2) -> void:
	bounds = value

func _build_animation_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_loop("spin", true)
	frames.set_animation_speed("spin", 17.0)

	var matches: Array[Dictionary] = []
	for path in _all_png_paths("res://"):
		var base := path.get_file().get_basename().to_lower()
		if not base.begins_with("spin blade"):
			continue
		var number := _trailing_number(base)
		if number >= 0:
			matches.append({"number": number, "path": path})

	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["number"] < b["number"]
	)

	for item in matches:
		var texture := load(item["path"]) as Texture2D
		if texture:
			frames.add_frame("spin", texture)

	if frames.get_frame_count("spin") > 0:
		return frames
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
