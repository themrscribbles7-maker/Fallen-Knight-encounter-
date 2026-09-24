extends Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var velocity := Vector2(180, 120)
var bounds := Rect2(470, 180, 340, 230)
func _ready() -> void:
	var f := SpriteFrames.new(); f.add_animation("spin"); f.set_animation_speed("spin", 17); f.set_animation_loop("spin", true)
	for path in _pngs("res://"):
		if path.get_file().get_basename().to_lower().begins_with("spin blade"):
			f.add_frame("spin", load(path))
	if f.get_frame_count("spin") > 0: sprite.sprite_frames = f; sprite.play("spin")
	else:
		var c := ColorRect.new(); c.size = Vector2(22,22); c.color = Color("f7d77b"); add_child(c)
func _process(delta: float) -> void:
	position += velocity * delta
	if position.x <= bounds.position.x or position.x >= bounds.end.x: velocity.x *= -1
	if position.y <= bounds.position.y or position.y >= bounds.end.y: velocity.y *= -1
	if sprite: sprite.rotation += delta * 8
func set_velocity(v: Vector2) -> void: velocity = v
func set_bounds(r: Rect2) -> void: bounds = r
func _pngs(dir: String) -> Array[String]:
	var out: Array[String] = []; var d := DirAccess.open(dir); if not d: return out; d.list_dir_begin(); var n := d.get_next()
	while n != "":
		if not n.begins_with("."): out.append_array(_pngs(dir.path_join(n)) if d.current_is_dir() else ([dir.path_join(n)] if n.to_lower().ends_with(".png") else []))
		n = d.get_next()
	d.list_dir_end(); return out
