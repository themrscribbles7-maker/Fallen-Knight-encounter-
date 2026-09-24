extends Node2D

# Keeps the projectile animated and moving while the battle manager handles the
# attack timing and collision states.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocity: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
var damage: float = 10.0
var active: bool = true
var flip_x_state: bool = false

func _ready() -> void:
	var frames := _build_frames()
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
		sprite.position = Vector2.ZERO

func _process(delta: float) -> void:
	if not active:
		return
	position += velocity * delta * 60.0
	if position.x < bounds.position.x or position.x > bounds.position.x + bounds.size.x:
		velocity.x *= -1.0
		position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	if position.y < bounds.position.y or position.y > bounds.position.y + bounds.size.y:
		velocity.y *= -1.0
		position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
	if sprite:
		sprite.rotation += 0.2
	if velocity.length() > 0.0:
		velocity = velocity.normalized() * min(velocity.length() + 0.08, 420.0)

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_loop("spin", true)
	frames.set_animation_speed("spin", 17.0)
	var textures: Array[Texture2D] = []
	for path in _all_png_paths("res://"):
		var base := path.get_file().get_basename().to_lower()
		if base.begins_with("spin blade"):
			var num := _trailing_number(base)
			if num >= 0:
				textures.append(load(path) as Texture2D)
	texturessort custom not supported? 
	