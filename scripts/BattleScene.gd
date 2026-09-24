extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BATTLE_BOX := Rect2(470.0, 180.0, 340.0, 230.0)
const FPS := 17.0
const MAX_PLAYER_HP := 100
const MAX_KNIGHT_HP := 160

var player: AnimatedSprite2D
var knight: AnimatedSprite2D
var soul: Node2D
var blade: Node2D
var spears: Array[Node2D] = []
var menu_items: Array[String] = ["FIGHT", "ACT", "ITEM", "MERCY"]
var selected_index := 0
var battle_state := "menu"
var state_time := 0.0
var player_hp := MAX_PLAYER_HP
var knight_hp := MAX_KNIGHT_HP
var menu_label: Label
var status_label: Label
var hp_label: Label

func _ready() -> void:
	_build_background()
	player = _create_character("Parralexs", "Parralexs Idle", Vector2(300.0, 300.0), false)
	knight = _create_character("Knight", "Knight Idle", Vector2(980.0, 300.0), true)
	soul = preload("res://scenes/Soul.tscn").instantiate() as Node2D
	soul.position = BATTLE_BOX.get_center()
	soul.visible = false
	add_child(soul)
	status_label = _create_label("Choose an action. Enter confirms.", Vector2(390.0, 620.0), 20)
	menu_label = _create_label("", Vector2(90.0, 500.0), 26)
	hp_label = _create_label("", Vector2(90.0, 440.0), 20)
	_refresh_menu()
	_update_hud()

func _process(delta: float) -> void:
	state_time += delta
	match battle_state:
		"menu":
			_process_menu()
		"fight":
			if Input.is_action_just_pressed("ui_accept"):
				_finish_player_attack()
		"enemy":
			_move_soul(delta)
			_check_projectile_hits()
			if state_time >= 7.0:
				_end_enemy_turn()
		"victory", "defeat":
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().reload_current_scene()
	_update_hud()

func _process_menu() -> void:
	if Input.is_action_just_pressed("ui_up"):
		selected_index = (selected_index + menu_items.size() - 1) % menu_items.size()
		_refresh_menu()
	if Input.is_action_just_pressed("ui_down"):
		selected_index = (selected_index + 1) % menu_items.size()
		_refresh_menu()
	if Input.is_action_just_pressed("ui_accept"):
		_choose_action()

func _choose_action() -> void:
	match menu_items[selected_index]:
		"FIGHT":
			battle_state = "fight"
			state_time = 0.0
			status_label.text = "Press ENTER to attack!"
			_play_animation(player, "Parralexs attack", "Parralexs Idle")
		"ACT":
			knight_hp = max(0, knight_hp - 8)
			status_label.text = "You study the Knight. Its guard weakens."
			_start_enemy_turn()
		"ITEM":
			player_hp = min(MAX_PLAYER_HP, player_hp + 25)
			status_label.text = "You used an item and recovered HP."
			_start_enemy_turn()
		"MERCY":
			status_label.text = "You offer mercy. The Knight refuses!"
			_start_enemy_turn()

func _finish_player_attack() -> void:
	var accuracy := absf(fmod(state_time * 0.8, 2.0) - 1.0)
	var damage := 35 if accuracy < 0.25 else 15
	knight_hp = max(0, knight_hp - damage)
	status_label.text = "Direct hit!" if damage == 35 else "A weak hit..."
	if knight_hp <= 0:
		battle_state = "victory"
		status_label.text = "VICTORY! Press ENTER to restart."
		_play_animation(knight, "Damage knight", "Knight Idle")
	else:
		_start_enemy_turn()

func _start_enemy_turn() -> void:
	battle_state = "enemy"
	state_time = 0.0
	soul.visible = true
	soul.position = BATTLE_BOX.get_center()
	_play_animation(knight, "Knight slash", "Knight Idle")
	blade = _spawn_blade(Vector2(640.0, 280.0), Vector2(190.0, 125.0))
	for index in range(3):
		var spawn_position := Vector2(510.0 + index * 150.0, 195.0)
		spears.append(_spawn_spear(spawn_position, BATTLE_BOX.get_center()))

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
		battle_state = "defeat"
		status_label.text = "DEFEAT! Press ENTER to restart."
	else:
		battle_state = "menu"
		status_label.text = "Choose an action. Enter confirms."
	_play_animation(knight, "Knight Idle", "Knight Idle")

func _move_soul(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	soul.position += direction * 230.0 * delta
	soul.position.x = clampf(soul.position.x, BATTLE_BOX.position.x + 14.0, BATTLE_BOX.end.x - 14.0)
	soul.position.y = clampf(soul.position.y, BATTLE_BOX.position.y + 14.0, BATTLE_BOX.end.y - 14.0)

func _check_projectile_hits() -> void:
	if is_instance_valid(blade) and blade.global_position.distance_to(soul.global_position) < 24.0:
		player_hp = max(0, player_hp - 10)
		status_label.text = "Hit! Keep moving!"
		blade.position = Vector2(-1000.0, -1000.0)
	for spear in spears:
		if is_instance_valid(spear) and spear.global_position.distance_to(soul.global_position) < 24.0:
			player_hp = max(0, player_hp - 10)
			status_label.text = "Hit! Keep moving!"
			spear.reset_position()

func _create_character(character_name: String, prefix: String, character_position: Vector2, flip: bool) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = character_name
	sprite.position = character_position
	sprite.flip_h = flip
	sprite.sprite_frames = _build_frames(prefix)
	if sprite.sprite_frames.get_frame_count("idle") > 0:
		sprite.play("idle")
	add_child(sprite)
	return sprite

func _build_frames(prefix: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", FPS)
	frames.set_animation_loop("idle", true)
	var found: Array[Dictionary] = []
	_scan_pngs("res://", prefix, found)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["number"]) < int(b["number"])
	)
	for item in found:
		var texture := load(String(item["path"])) as Texture2D
		if texture != null:
			frames.add_frame("idle", texture)
	return frames

func _scan_pngs(directory_path: String, prefix: String, found: Array[Dictionary]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path := directory_path.path_join(entry)
			if directory.current_is_dir():
				_scan_pngs(full_path, prefix, found)
			elif entry.to_lower().ends_with(".png"):
				var stem := entry.get_basename()
				if stem.to_lower().begins_with(prefix.to_lower()):
					var suffix := stem.substr(prefix.length()).strip_edges()
					if suffix.is_valid_int():
						found.append({"path": full_path, "number": int(suffix)})
			entry = directory.get_next()
	directory.list_dir_end()

func _play_animation(sprite: AnimatedSprite2D, prefix: String, fallback_prefix: String) -> void:
	var frames := _build_frames(prefix)
	if frames.get_frame_count("idle") == 0:
		frames = _build_frames(fallback_prefix)
	if frames.get_frame_count("idle") > 0:
		sprite.sprite_frames = frames
		sprite.play("idle")

func _spawn_blade(spawn_position: Vector2, velocity_value: Vector2) -> Node2D:
	var projectile := preload("res://scenes/SpinBlade.tscn").instantiate() as Node2D
	projectile.position = spawn_position
	projectile.set_velocity(velocity_value)
	projectile.set_bounds(BATTLE_BOX)
	add_child(projectile)
	return projectile

func _spawn_spear(spawn_position: Vector2, target: Vector2) -> Node2D:
	var projectile := preload("res://scenes/Spear.tscn").instantiate() as Node2D
	projectile.position = spawn_position
	projectile.set_velocity((target - spawn_position).normalized() * 180.0)
	projectile.set_bounds(BATTLE_BOX)
	add_child(projectile)
	return projectile

func _build_background() -> void:
	var background := ColorRect.new()
	background.size = VIEW_SIZE
	background.color = Color("11111b")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)
	var battle_box := ColorRect.new()
	battle_box.position = BATTLE_BOX.position
	battle_box.size = BATTLE_BOX.size
	battle_box.color = Color("101018")
	battle_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(battle_box)

func _create_label(text_value: String, label_position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func _refresh_menu() -> void:
	var lines: Array[String] = []
	for index in range(menu_items.size()):
		var marker := "> " if index == selected_index else "  "
		lines.append(marker + menu_items[index])
	menu_label.text = "\n".join(lines)

func _update_hud() -> void:
	hp_label.text = "PARRALEXS HP: %d / %d    KNIGHT HP: %d / %d" % [player_hp, MAX_PLAYER_HP, knight_hp, MAX_KNIGHT_HP]
