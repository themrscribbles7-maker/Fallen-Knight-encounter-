extends Node2D

# Core boss battle flow: normal state, battle-box opening, Soul movement,
# and the reusable spin blade + dissection spear phases.

const FPS := 17.0
const SCREEN_SIZE := Vector2(1280, 720)
const ASSET_ROOT := "res://"

var battle_scene: Node2D
var parralexs_actor: AnimatedSprite2D
var knight_actor: AnimatedSprite2D
var battle_box: Node2D
var soul: Node2D
var ui_root: PanelContainer

var phase: String = "normal"
var phase_timer: float = 0.0
var open_delay: float = 0.8
var spin_attack_delay: float = 1.8
var dissection_delay: float = 3.3
var projectiles: Array[Node2D] = []
var lane_markers: Array[ColorRect] = []

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
	_clear_projectiles()
	_hide_split_markers()
	_set_battle_box_visible(false)
	_set_soul_visible(false)
	if ui_root:
		ui_root.visible = true

func begin_enemy_turn() -> void:
	phase = "opening"
	phase_timer = 0.0
	_clear_projectiles()
	_hide_split_markers()
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
	_clear_projectiles()
	_hide_split_markers()
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
		if phase_timer >= spin_attack_delay:
			begin_dissection_phase()
		return

	if phase == "dissection":
		phase_timer += delta
		_move_soul(delta)
		_check_projectile_collisions()
		if phase_timer >= dissection_delay:
			end_enemy_turn()
		return

func _knight_opening_animation() -> void:
	if knight_actor and knight_actor.sprite_frames and knight_actor.sprite_frames.has_animation("Knight_Open_Battle_Box"):
		knight_actor.animation = "Knight_Open_Battle_Box"
		knight_actor.play("Knight_Open_Battle_Box")

func _start_attack_pattern() -> void:
	var blade := _create_spin_blade(Vector2(620, 260), Vector2(1.2, 0.75))
	if blade and blade.has_signal("rebound"):
		blade.rebound.connect(_on_spin_blade_rebound)
	if blade and blade.has_signal("hit_player"):
		blade.hit_player.connect(_on_spin_blade_hit_player)

func begin_dissection_phase() -> void:
	phase = "dissection"
	phase_timer = 0.0
	_clear_projectiles()
	_show_split_markers()
	_spawn_spear_wave()

func _show_split_markers() -> void:
	if not battle_box:
		return
	for existing in lane_markers:
		if is_instance_valid(existing):
			existing.queue_free()
	lane_markers.clear()
	var split_positions := [
		Vector2(500, 180),
		Vector2(720, 180),
		Vector2(500, 340),
		Vector2(720, 340),
	]
	for i in range(split_positions.size()):
		var marker := ColorRect.new()
		marker.size = Vector2(100, 60)
		marker.position = split_positions[i]
		marker.color = Color(1.0, 1.0, 1.0, 0.08)
		battle_box.add_child(marker)
		lane_markers.append(marker)

func _hide_split_markers() -> void:
	for existing in lane_markers:
		if is_instance_valid(existing):
			existing.queue_free()
	lane_markers.clear()

func _spawn_spear_wave() -> void:
	var spawn_points := [
		Vector2(520, 150),
		Vector2(710, 150),
		Vector2(520, 390),
		Vector2(710, 390),
	]
	var target_points := [
		Vector2(620, 300),
		Vector2(620, 300),
		Vector2(620, 300),
		Vector2(620, 300),
	]
	for i in range(spawn_points.size()):
		var spear := _create_spear(spawn_points[i], target_points[i])
		if spear:
			projectiles.append(spear)

func _create_spin_blade(position: Vector2, velocity: Vector2) -> Node2D:
	var scene := load("res://scenes/SpinBlade.tscn") as PackedScene
	var projectile: Node2D
	if scene:
		projectile = scene.instantiate()
	else:
		projectile = Node2D.new()
		var fallback := ColorRect.new()
		fallback.size = Vector2(18, 18)
		fallback.color = Color("f7d77b")
		projectile.add_child(fallback)

	projectile.position = position
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(velocity * 180.0)
	if projectile.has_method("set_bounds"):
		projectile.set_bounds(Rect2(Vector2(500, 180), Vector2(280, 200)))

	battle_scene.add_child(projectile)
	return projectile

func _create_spear(position: Vector2, target: Vector2) -> Node2D:
	var scene := load("res://scenes/Spear.tscn") as PackedScene
	var projectile: Node2D
	if scene:
		projectile = scene.instantiate()
	else:
		projectile = Node2D.new()
		var fallback := ColorRect.new()
		fallback.size = Vector2(16, 36)
		fallback.color = Color("b0d4ff")
		projectile.add_child(fallback)
	projectile.position = position
	var direction := (target - position).normalized()
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction * 240.0)
	if projectile.has_method("set_bounds"):
		projectile.set_bounds(Rect2(Vector2(500, 180), Vector2(280, 200)))
	if projectile.has_method("set_lifetime"):
		projectile.set_lifetime(2.4)
	battle_scene.add_child(projectile)
	return projectile

func _on_spin_blade_rebound() -> void:
	if knight_actor and knight_actor.sprite_frames and knight_actor.sprite_frames.has_animation("Knight_Rebound"):
		knight_actor.animation = "Knight_Rebound"
		knight_actor.play("Knight_Rebound")

func _on_spin_blade_hit_player() -> void:
	if soul:
		soul.modulate = Color(1.0, 0.7, 0.7, 1.0)
	phase = "normal"
	end_enemy_turn()

func _check_projectile_collisions() -> void:
	if not soul:
		return
	for projectile in projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.global_position.distance_to(soul.global_position) < 22.0:
			projectile.active = false
			projectile.queue_free()
			projectiles.erase(projectile)
			_on_spin_blade_hit_player()
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
	next_position.x = clamp(next_position.x, box_rect.position.x + 12.0, box_rect.position.x + box_rect.size.x - 12.0)
	next_position.y = clamp(next_position.y, box_rect.position.y + 12.0, box_rect.position.y + box_rect.size.y - 12.0)
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
