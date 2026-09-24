extends Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var velocity := Vector2.ZERO
var bounds := Rect2(470, 180, 340, 230)
var lifetime := 5.0
func _ready() -> void:
	var f := SpriteFrames.new(); f.add_animation("spear"); f.set_animation_speed("spear", 17); f.set_animation_loop("spear", true)
	for path in _pngs("res://"):
		if path.get_file().get_basename().to_lower().begins_with("spear"): f.add_frame("spear", load(path))
	if f.get_frame_count("spear") > 0: sprite.sprite_frames = f; sprite.play("spear")
	else:
		var c := ColorRect.new(); c.size = Vector2(14, 34); c.color = Color("b0d4ff"); add_child(c)
func _process(delta: float) -> void:
	position += velocity * delta; lifetime -= delta
	if lifetime <= 0: queue_free()
	if sprite: sprite.rotation = velocity.angle() + PI / 2
func set_velocity(v: Vector2) -> void: velocity = v
func set_bounds(r: Rect2) -> void: bounds = r
func _pngs(dir: String) -> Array[String]:
	var out: Array[String] = []; var d := DirAccess.open(dir); if not d: return out; d.list_dir_begin(); var n := d.get_next()
	while n != "":
		if not n.begins_with("."): out.append_array(_pngs(dir.path_join(n)) if d.current_is_dir() else ([dir.path_join(n)] if n.to_lower().ends_with(".png") else []))
		n = d.get_next()
	d.list_dir_end(); return out
