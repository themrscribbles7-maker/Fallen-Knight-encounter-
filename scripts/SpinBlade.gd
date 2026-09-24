extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity := Vector2(180, 120)
var bounds := Rect2(470, 180, 340, 230)

func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 17.0)
	frames.set_animation_loop("spin", true)

	for path in _pngs("res://"):
		if path.get_file().get_basename().to_lower().begins_with("spin blade"):
			var texture := load(path) as Texture2D
			if texture:
				frames.add_frame("spin", texture)

	if frames.get_frame_count("spin") > 0:
		sprite.sprite_frames = frames
		sprite.animation = "spin"
		sprite.play("spin")
	else:
		var fallback := ColorRect.new()
		fallback.size = Vector2(22, 22)
		fallback.color = Color("f7d77b")
		add_child(fallback)

func _process(delta: float) -> void:
	position += velocity * delta

	if position.x <= bounds.position.x or position.x >= bounds.end.x:
		velocity.x *= -1.0
		position.x = clamp(position.x, bounds.position.x, bounds.end.x)
	if position.y <= bounds.position.y or position.y >= bounds.end.y:
		velocity.y *= -1.0
		position.y = clamp(position.y, bounds.position.y, bounds.end.y)

	if sprite:
		sprite.rotation += delta * 8.0

func set_velocity(value: Vector2) -> void:
	velocity = value

func set_bounds(value: Rect2) -> void:
	bounds = value

func _pngs(directory: String) -> Array[String]:
	var output: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return output

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var path := directory.path_join(file_name)
			if dir.current_is_dir():
				output.append_array(_pngs(path))
			elif file_name.to_lower().ends_with(".png"):
				output.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return output
