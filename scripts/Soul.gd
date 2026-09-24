extends Node2D

@onready var body: Polygon2D = $Body

func _ready() -> void:
	if body != null:
		body.color = Color("f0445a")

func set_size(value: Vector2) -> void:
	if body == null:
		return
	body.polygon = PackedVector2Array([
		Vector2(-value.x * 0.5, -value.y * 0.5),
		Vector2(value.x * 0.5, -value.y * 0.5),
		Vector2(value.x * 0.5, value.y * 0.5),
		Vector2(-value.x * 0.5, value.y * 0.5)
	])
