extends Node

# Core battle flow controller for the boss encounter.
# Handles the normal state, enemy-turn state, battle box opening,
# Soul movement, and simple projectile collision.

var battle_scene: Node2D
var parralexs_actor: AnimatedSprite2D
var knight_actor: AnimatedSprite2D
var battle_box: Node2D
var soul: Node2D
var ui_root: PanelContainer

var phase: String = "normal"
var phase_timer: float = 0.0
var open_delay: float = 0.8
var attack_delay: float = 1.1
var projectiles: Array[Node2D] = []
var attack_started: bool = false

func configure(scene: Node2D, parralexs: AnimatedSprite2D, knight: AnimatedSprite2D, ui: PanelContainer, box: Node2D, soul_node: Node2D) -> void:
	battle_scene = scene
	parralexs_actor = parralexs
	knight_actor = knight
	ui_root = ui
	battle_box = box
	soul = soul_node
	if ui_root:
		ui_root.visible = true

func begin_normal_battle() -> void:
	phase = "normal"
	phase_timer = 0.0
	attack_started = false
	_clear_projectiles()
	_set_battle_box_visible(false)
	_set_soul_visible(false)
	if ui_root:
		ui_root.visible = true

func begin_enemy_turn() -> void:
	phase = "opening"
	phase_timer = 0.0
	attack_started = false
	_clear_projectiles()
	_set_battle_box_visible(true)
	_set_soul_visible(true)
	if soul:
		soul.position = Vector2(620, 300)
	if knight_actor:
		_knight_opening_animation()
	if ui_root:
		ui_root.visible = false

func end_enemy_turn() -> void:
	phase = "normal"
	phase_timer = 0.0
	attack_started = false
	_clear_projectiles()
	_set_battle_box_visible(false)
	_set_soul_visible(false)
	if ui_root:
		ui_root.visible = true

func _process(delta: float) -> void:
	if phase == "normal":
		if Input.is_action_just_pressed("ui_accept"):
			begin_enemy_turn()
		return
	if phase == "opening":
		phase_timer += delta
		if phase_timer >= open_delay:
			phase = "enemy_turn"
			phase_timer = 0.0
			_start_attack_pattern()
		return
	if phase == "enemy_turn":
		phase_timer += delta
		_move_soul(delta)
		_check_projectile_collisions()
		if phase_timer >= attack_delay:
			phase = "normal"
			end_enemy_turn()
		return

func _knight_opening_animation() -> void:
	if knight_actor and knight_actor.sprite_frames and knight_actor.sprite_frames.has_animation("Knight_Open_Battle_Box"):
		knight_actor.animation = "Knight_Open_Battle_Box"
		knight_actor.play("Knight_Open_Battle_Box")

func _start_attack_pattern() -> void:
	# Basic enemy-turn projectile pattern.
	_create_spin_blade(Vector2(620, 260), Vector2(1.2, 0.75))
	attack_started = true

func _create_spin_blade(position: Vector2, velocity: Vector2) -> void:
	var scene := load("res://scenes/SpinBlade.tscn") as PackedScene
	var projectile: Node2D
	if scene:
		projectile = scene.instantiate()
	else:
		projectile = Node2D.new()
		var sprite := ColorRect.new()
		sprite.size = Vector2(18, 18)
		sprite.color = Color("f7d77b")
		projectile.add_child(sprite)
	projectile.position = position
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(velocity * 180.0)
	if projectile.has_method("set_bounds"):
		projectile.set_bounds(Rect2(Vector2(500, 180), Vector2(280, 200)))
	battle_scene.add_child(projectile)
	projectiles.append(projectile)

func _check_projectile_collisions() -> void:
	if not soul:
		return
	for projectile in projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.global_position.distance_to(soul.global_position) < 24.0:
			projectile.queue_free()
			projectiles.erase(projectile)
			return

func _move_soul(delta: float) -> void:
	if not soul:
		return
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if input_vector.length() > 0.0:
		input_vector = input_vector.normalized()
	var speed := 220.0
	var next_position := soul.position + input_vector * speed * delta
	var box_rect := Rect2(Vector2(500, 180), Vector2(280, 200))
	next_position.x = clamp(next_position.x, box_rect.position.x + 12, box_rect.position.x + box_rect.size.x - 12)
	next_position.y = clamp(next_position.y, box_rect.position.y + 12, box_rect.position.y + box_rect.size.y - 12)
	soul.position = next_position

func _clear_projectiles() -> void:
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	projectiles.clear()

func _set_battle_box_visible(visible: bool) -> void:
	if not battle_box:
		return
	battle_box.visible = visible
	for child in battle_box.get_children():
		if child is CanvasItem:
			child.visible = visible

func _set_soul_visible(visible: bool) -> void:
	if soul:
		soul.visible = visible
