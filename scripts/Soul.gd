extends Node2D

# Simple player soul object. The battle manager controls movement and visibility.
# This allows the soul to be a reusable scene while keeping gameplay logic clean.

@onready var body: ColorRect = $Body

func _ready() -> void:
	if body:
		body.size = Vector2(18, 18)
		body.color = Color(1.0, 1.0, 1.0, 1.0)
	visible = false

func set_size(value: Vector2) -> void:
	if body:
		body.size = value
