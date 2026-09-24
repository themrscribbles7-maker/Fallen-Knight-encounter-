extends Node2D

const SIZE := Vector2(1280, 720)
const BOX := Rect2(470.0, 180.0, 340.0, 230.0)
const FPS := 17.0

var knight: AnimatedSprite2D
var player: AnimatedSprite2D
var soul: Node2D
var blade: Node2D
var spears: Array[Node2D] = []
var menu: Array[String] = ["FIGHT", "ACT", "ITEM", "MERCY"]
var selected := 0
var state := "menu"
var timer := 0.0
var player_hp := 100
var knight_hp := 160
var status: Label
var menu_label: Label
var hp_label: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("11111b"))
	_build_background()
	player = _create_actor("Parralexs", Vector2(260, 270), "Parralexs idle")
	knight = _create_actor("Knight", Vector2(1010, 270), "Knight Idle")
	soul = _create_soul()
	add_child(soul)
	status = _create_label("Choose an action. Enter confirms; arrows/WASD move.", Vector2(390, 620), 20)
	menu_label = _create_label("", Vector2(90, 505), 24)
	hp_label = _create_label("", Vector2(90, 445), 20)
	_refresh_menu()

func _process(delta: float) -> void:
	timer += delta

	match state:
		"menu":
			_process_menu()
		"fight":
			if Input.is_action_just_pressed("ui_accept"):
				_finish_fight()
		"enemy":
			_move_soul(delta)
			_check_hits()
			if timer > 7.0:
				_end_enemy_turn()
		"victory", "defeat":
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().reload_current_scene()

	_update_hud()

func _process_menu() -> void:
	if Input.is_action_just_pressed("ui_up"):
		selected = (selected + menu.size() - 1) % menu.size()
		_refresh_menu()
	if Input.is_action_just_pressed("ui_down"):
		selected = (selected + 1) % menu.size()
		_refresh_menu()
	if Input.is_action_just_pressed("ui_accept"):
		_choose()

func _choose() -> void:
	match menu[selected]:
		"FIGHT":
			state = "fight"
			timer = 0.0
			status.text = "Press ENTER to strike!"
			_play_if_available(player, "Parralexs_Attack")
		"ACT":
			status.text = "Parralexs studies the Knight. Its guard weakens."
			knight_hp = max(0, knight_hp - 8)
			_start_enemy_turn()
		"ITEM":
			player_hp = min(100, player_hp + 25)
			status.text = "You used an item. HP restored."
			_start_enemy_turn()
		"MERCY":
			status.text = "You offer mercy. The Knight refuses!"
			_start_enemy_turn()

func _finish_fight() -> void:
	var accuracy := absf(fmod(timer * 0.8, 2.0) - 1.0)
	var damage := 35 if accuracy < 0.25 else 15
	knight_hp = max(0, knight_hp - damage)

	if damage == 35:
		status.text = "Direct hit!"
	else:
		status.text = "A weak hit..."

	if knight_hp == 0:
		state = "victory"
		status.text = "VICTORY! Press ENTER to restart."
	else:
		_start_enemy_turn()

func _start_enemy_turn() -> void:
	state = "enemy"
	timer = 0.0
	soul.visible = true
	soul.position = BOX.get_center()
	_play_if_available(knight, "Knight_Attack")
	blade = _spawn_blade(Vector2(640, 280), Vector2(190, 125))

	for index in range(3):
		var spear_position := Vector2(510.0 + index * 150.0, 190.0)
		spears.append(_spawn_spear(spear_position, BOX.get_center()))

func _end_enemy_turn() -> void:
	for spear in spears:
		if is_instance_valid(spear):
			spear.queue_free()
	spears.clear()

	if is_instance_valid(blade):
		blade.queue_free()
	blade = null

	soul.visible = false

	if player_hp <= 0:
		state = "defeat"
		status.text = "DEFEAT! Press ENTER to restart."
	else:
		state = "menu"
		status.text = "Choose an action."

	_play_if_available(knight, "idle")

func _move_soul(delta: float) -> void:
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_key_pressed(KEY_A):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		movement.y += 1.0

	if movement.length_squared() > 1.0:
		movement = movement.normalized()

	soul.position += movement * 230.0 * delta
	soul.position.x = clampf(soul.position.x, BOX.position.x + 12.0, BOX.end.x - 12.0)
	soul.position.y = clampf(soul.position.y, BOX.position.y + 12.0, BOX.end.y - 12.0)

func _check_hits() -> void:
	if is_instance_valid(blade) and blade.global_position.distance_to(soul.global_position) < 25.0:
		player_hp = max(0, player_hp - 10)
		blade.queue_free()
		blade = null
		status.text = "Hit! Keep moving!"

	for spear in spears:
		if is_instance_valid(spear) and spear.global_position.distance_to(soul.global_position) < 25.0:
			player_hp = max(0, player_hp - 10)
			spear.queue_free()
			status.text = "Hit! Keep moving!"

func _create_actor(actor_name: String, actor_position: Vector2, prefix: String) -> AnimatedSprite2D:
	var actor := AnimatedSprite2D.new()
	actor.name = actor_name
	actor.position = actor_position
	actor.sprite_frames = _build_frames(prefix, true)
	if actor.sprite_frames.get_frame_count("idle") > 0:
		actor.play("idle")
	add_child(actor)
	return actor

func _build_frames(prefix: String, loop: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", FPS)
	frames.set_animation_loop("idle", loop)

	var found: Array[Dictionary] = []
	for path in _find_png_files("res://"):
		var base := path.get_file().get_basename().to_lower()
		if base.begins_with(prefix.to_lower()):
			var frame_number := _trailing_number(base)
			if frame_number >= 0:
				found.append({"number": frame_number, "path": path})

	found.sort_custom(_sort_frame_numbers)
	for item in found:
		var texture := load(item["path"]) as Texture2D
		if texture != null:
			frames.add_frame("idle", texture)
	return frames

func _sort_frame_numbers(first: Dictionary, second: Dictionary) -> bool:
	return int(first["number"]) < int(second["number"])

func _spawn_blade(spawn_position: Vector2, blade_velocity: Vector2) -> Node2D:
	var projectile := preload("res://scenes/SpinBlade.tscn").instantiate() as Node2D
	projectile.position = spawn_position
	projectile.set_velocity(blade_velocity)
	projectile.set_bounds(BOX)
	add_child(projectile)
	return projectile

func _spawn_spear(spawn_position: Vector2, target: Vector2) -> Node2D:
	var projectile := preload("res://scenes/Spear.tscn").instantiate() as Node2D
	projectile.position = spawn_position
	projectile.set_velocity((target - spawn_position).normalized() * 180.0)
	projectile.set_bounds(BOX)
	add_child(projectile)
	return projectile

func _create_soul() -> Node2D:
	var soul_scene := preload("res://scenes/Soul.tscn").instantiate() as Node2D
	soul_scene.position = BOX.get_center()
	soul_scene.visible = false
	return soul_scene

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("242438")
	background.size = SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	var battle_box := ColorRect.new()
	battle_box.position = BOX.position
	battle_box.size = BOX.size
	battle_box.color = Color("101018")
	battle_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(battle_box)

func _create_label(text: String, label_position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func _refresh_menu() -> void:
	var lines: Array[String] = []
	for index in range(menu.size()):
		var prefix := "> " if index == selected else "  "
		lines.append(prefix + menu[index])
	menu_label.text = "\n".join(lines)

func _update_hud() -> void:
	hp_label.text = "PARRALEXS HP: %d / 100    KNIGHT HP: %d / 160" % [player_hp, knight_hp]

func _play_if_available(actor: AnimatedSprite2D, animation_name: String) -> void:
	if actor != null and actor.sprite_frames != null and actor.sprite_frames.has_animation(animation_name):
		actor.play(animation_name)

func _find_png_files(directory: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var path := directory.path_join(file_name)
			if dir.current_is_dir():
				files.append_array(_find_png_files(path))
			elif file_name.to_lower().ends_with(".png"):
				files.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files

func _trailing_number(text: String) -> int:
	var regex := RegEx.new()
	regex.compile("(\\d+)$")
	var result := regex.search(text)
	if result == null:
		return -1
	return int(result.get_string(1))
