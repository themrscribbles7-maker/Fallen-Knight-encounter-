extends Node2D

const SIZE := Vector2(1280, 720)
const BOX := Rect2(470, 180, 340, 230)
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
	player = _actor("Parralexs", Vector2(260, 270), "Parralexs idle")
	knight = _actor("Knight", Vector2(1010, 270), "Knight Idle")
	soul = _make_soul()
	add_child(soul)
	status = _label("Choose an action.  Enter confirms; arrows/WASD move.", Vector2(390, 620), 20)
	menu_label = _label("", Vector2(90, 505), 24)
	hp_label = _label("", Vector2(90, 445), 20)
	_refresh_menu()

func _process(delta: float) -> void:
	timer += delta
	if state == "menu":
		if Input.is_action_just_pressed("ui_up"): selected = (selected + 3) % 4; _refresh_menu()
		if Input.is_action_just_pressed("ui_down"): selected = (selected + 1) % 4; _refresh_menu()
		if Input.is_action_just_pressed("ui_accept"): _choose()
	elif state == "fight":
		if Input.is_action_just_pressed("ui_accept"): _finish_fight()
	elif state == "enemy":
		_move_soul(delta)
		_check_hits()
		if timer > 7.0: _end_enemy_turn()
	elif state == "victory" or state == "defeat":
		if Input.is_action_just_pressed("ui_accept"): get_tree().reload_current_scene()
	_update_hud()

func _choose() -> void:
	match menu[selected]:
		"FIGHT":
			state = "fight"; timer = 0.0; status.text = "Press ENTER when the marker is in the center!"
			if player.sprite_frames.has_animation("Parralexs_Attack"): player.play("Parralexs_Attack")
		"ACT":
			status.text = "Parralexs studies the Knight. Its guard weakens."
			knight_hp = max(0, knight_hp - 8); _enemy_turn()
		"ITEM":
			player_hp = min(100, player_hp + 25); status.text = "You used an item. HP restored."; _enemy_turn()
		"MERCY":
			status.text = "You offer mercy. The Knight refuses!"; _enemy_turn()

func _finish_fight() -> void:
	var accuracy := abs(fmod(timer * 0.8, 2.0) - 1.0)
	var damage := 35 if accuracy < 0.25 else 15
	knight_hp = max(0, knight_hp - damage)
	status.text = "Direct hit!" if damage == 35 else "A weak hit..."
	if knight_hp == 0:
		state = "victory"; status.text = "VICTORY! Press ENTER to restart."; return
	_enemy_turn()

func _enemy_turn() -> void:
	state = "enemy"; timer = 0.0; soul.visible = true
	if knight.sprite_frames.has_animation("Knight_Attack"): knight.play("Knight_Attack")
	else: knight.play("idle")
	blade = _spawn_blade(Vector2(640, 280), Vector2(190, 125))
	for i in range(3): spears.append(_spawn_spear(Vector2(510 + i * 150, 190), Vector2(640, 300)))

func _end_enemy_turn() -> void:
	for p in spears: if is_instance_valid(p): p.queue_free()
	spears.clear()
	if is_instance_valid(blade): blade.queue_free()
	blade = null; soul.visible = false
	if player_hp <= 0: state = "defeat"; status.text = "DEFEAT! Press ENTER to restart."
	else: state = "menu"; status.text = "Choose an action."
	if knight.sprite_frames.has_animation("idle"): knight.play("idle")

func _move_soul(delta: float) -> void:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_W): v.y -= 1
	if Input.is_key_pressed(KEY_S): v.y += 1
	soul.position = soul.position + v.normalized() * 230.0 * delta if v.length() > 0 else soul.position
	soul.position.x = clamp(soul.position.x, BOX.position.x + 12, BOX.end.x - 12)
	soul.position.y = clamp(soul.position.y, BOX.position.y + 12, BOX.end.y - 12)

func _check_hits() -> void:
	for p in [blade] + spears:
		if is_instance_valid(p) and p.global_position.distance_to(soul.global_position) < 25:
			player_hp = max(0, player_hp - 10); p.queue_free(); status.text = "Hit! Keep moving!"

func _actor(name: String, pos: Vector2, prefix: String) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new(); a.name = name; a.position = pos; a.sprite_frames = _frames(prefix, true)
	if a.sprite_frames.get_frame_count("idle") > 0: a.play("idle")
	add_child(a); return a

func _frames(prefix: String, loop: bool) -> SpriteFrames:
	var f := SpriteFrames.new(); f.add_animation("idle"); f.set_animation_speed("idle", FPS); f.set_animation_loop("idle", loop)
	var found: Array[Dictionary] = []
	for path in _pngs("res://"):
		var base := path.get_file().get_basename().to_lower()
		if base.begins_with(prefix.to_lower()):
			var n := _number(base)
			if n >= 0: found.append({"n": n, "p": path})
	found.sort_custom(func(a, b): return a.n < b.n)
	for item in found: f.add_frame("idle", load(item.p))
	return f

func _spawn_blade(pos: Vector2, vel: Vector2) -> Node2D:
	var p := preload("res://scenes/SpinBlade.tscn").instantiate(); p.position = pos; p.set_velocity(vel); p.set_bounds(BOX); add_child(p); return p
func _spawn_spear(pos: Vector2, target: Vector2) -> Node2D:
	var p := preload("res://scenes/Spear.tscn").instantiate(); p.position = pos; p.set_velocity((target-pos).normalized()*180); p.set_bounds(BOX); add_child(p); return p
func _make_soul() -> Node2D:
	var s := preload("res://scenes/Soul.tscn").instantiate(); s.position = BOX.get_center(); s.visible = false; return s
func _build_background() -> void:
	var r := ColorRect.new(); r.color = Color("242438"); r.size = SIZE; r.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(r); move_child(r, 0)
	var box := ColorRect.new(); box.position = BOX.position; box.size = BOX.size; box.color = Color("101018"); box.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(box)
func _label(text: String, pos: Vector2, size: int) -> Label:
	var l := Label.new(); l.text = text; l.position = pos; l.add_theme_font_size_override("font_size", size); add_child(l); return l
func _refresh_menu() -> void:
	menu_label.text = "\n".join([("> " if i == selected else "  ") + menu[i] for i in range(4)])
func _update_hud() -> void:
	hp_label.text = "PARRALEXS HP: %d / 100    KNIGHT HP: %d / 160" % [player_hp, knight_hp]
func _pngs(dir: String) -> Array[String]:
	var out: Array[String] = []; var d := DirAccess.open(dir); if not d: return out; d.list_dir_begin(); var n := d.get_next()
	while n != "":
		if not n.begins_with("."): out.append_array(_pngs(dir.path_join(n)) if d.current_is_dir() else ([dir.path_join(n)] if n.to_lower().ends_with(".png") else []))
		n = d.get_next()
	d.list_dir_end(); return out
func _number(s: String) -> int:
	var r := RegEx.new(); r.compile("(\\d+)$"); var m := r.search(s); return int(m.get_string(1)) if m else -1
