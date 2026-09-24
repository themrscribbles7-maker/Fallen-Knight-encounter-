extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity := Vector2(180.0, 120.0)
var bounds := Rect2(470.0, 180.0, 340.0, 230.0)

func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 17.0)
	frames.set_animation_loop("spin", true)
	var files: Array[Dictionary] = []
	_scan("res://", files)
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["number"]) < int(b["number"])
	)
	for item in files:
		var texture := load(String(item["path"])) as Texture2D
		if texture != null:
			frames.add_frame("spin", texture)
	if frames.get_frame_count("spin") > 0:
		sprite.sprite_frames = frames
		sprite.play("spin")
	else:
		var fallback := ColorRect.new()
		fallback.position = Vector2(-11.0, -11.0)
		fallback.size = Vector2(22.0, 22.0)
		fallback.color = Color("f7d77b")
		add_child(fallback)

func _process(delta: float) -> void:
	position += velocity * delta
	if position.x <= bounds.position.x or position.x >= bounds.end.x:
		velocity.x *= -1.0
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	if position.y <= bounds.position.y or position.y >= bounds.end.y:
		velocity.y *= -1.0
		position.y = clampf(position.y, bounds.position.y, bounds.end.y)
	if sprite != null:
		sprite.rotation += delta * 8.0

func set_velocity(value: Vector2) -> void:
	velocity = value

func set_bounds(value: Rect2) -> void:
	bounds = value

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
			elif entry.to_lower().begins_with("spin blade") and entry.to_lower().ends_with(".png"):
				var number_text := entry.get_basename().substr(10).strip_edges()
				if number_text.is_valid_int():
					files.append({"path": path, "number": int(number_text)})
			entry = directory.get_next()
	directory.list_dir_end()
