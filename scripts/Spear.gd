extends Node2D
## Spear projectile that bounces inside the battle box instead of disappearing.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity := Vector2.ZERO
var bounds := Rect2(470.0, 180.0, 340.0, 230.0)
var spawn_position := Vector2.ZERO

func _ready() -> void:
	spawn_position = position
	var frames := _build_frames()
	if frames.get_frame_count("spear") > 0:
		sprite.sprite_frames = frames
		sprite.play("spear")
	else:
		var fallback := ColorRect.new()
		fallback.position = Vector2(-7.0, -17.0)
		fallback.size = Vector2(14.0, 34.0)
		fallback.color = Color("b0d4ff")
		add_child(fallback)

func _process(delta: float) -> void:
	position += velocity * delta
	if position.x <= bounds.position.x or position.x >= bounds.end.x:
		velocity.x *= -1.0
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	if position.y <= bounds.position.y or position.y >= bounds.end.y:
		velocity.y *= -1.0
		position.y = clampf(position.y, bounds.position.y, bounds.end.y)
	if sprite != null and velocity.length_squared() > 0.0:
		sprite.rotation = velocity.angle() + PI / 2.0

func set_velocity(value: Vector2) -> void:
	velocity = value

func set_bounds(value: Rect2) -> void:
	bounds = value

func reset_position() -> void:
	position = spawn_position

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("spear")
	frames.set_animation_speed("spear", 17.0)
	frames.set_animation_loop("spear", true)
	var files: Array[Dictionary] = []
	_scan("res://", files)
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["number"]) < int(b["number"])
	)
	for item in files:
		var texture := load(String(item["path"])) as Texture2D
		if texture != null:
			frames.add_frame("spear", texture)
	return frames

func _scan(directory_path: String, files: Array[Dictionary]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var path := directory_path.path_join(entry)
			if directory.current_is_dir():
				_scan(path, files)
			elif entry.to_lower().begins_with("spear") and entry.to_lower().ends_with(".png"):
				var number_text := entry.get_basename().substr(5).strip_edges()
				if number_text.is_valid_int():
					files.append({"path": path, "number": int(number_text)})
			entry = directory.get_next()
	 directory.list_dir_end()
