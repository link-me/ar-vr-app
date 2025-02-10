extends Node3D

@export var food_count: int = 6
@export var spike_count: int = 16
@export var spawn_min: Vector2 = Vector2(-18.5, -18.5)
@export var spawn_max: Vector2 = Vector2(18.5, 18.5)
@export var segment_spacing: float = 0.7
@export var segment_follow_rate: float = 12.0
@export var segment_look_rate: float = 10.0
@export var initial_segments: int = 3
@export var slither_amp: float = 0.35
@export var slither_freq: float = 3.0
@export var slither_phase_step: float = 0.65
@export var path_point_min_step: float = 0.08
@export var path_max_points: int = 2000

var foods: Array = []
var spikes: Array = []
var segments: Array = []
var player: CharacterBody3D
var is_game_over: bool = false
var ui_layer: CanvasLayer
var ui_panel: Control
var console_layer: CanvasLayer
var console_panel: Panel
var console_input: LineEdit
var console_log: RichTextLabel
var cubes_enabled: bool = false
var matrix_cubes: Array = []
var _slither_time: float = 0.0
var path_points: Array[Vector3] = []

func _ready():
    player = get_parent().get_node("Player")
    _spawn_foods()
    _spawn_spikes()
    _build_ui()
    _build_console()
    _setup_input_actions()
    _spawn_initial_segments()
    if player:
        _seed_path_buffer(initial_segments)
    # Получаем ввод даже в паузе (нужно для рестарта), но продолжаем
    # обрабатывать физику в обычном режиме игры
    process_mode = Node.PROCESS_MODE_ALWAYS
	# Гарантируем действие restart (только E), если вдруг отсутствует
	if not InputMap.has_action("restart"):
		InputMap.add_action("restart")
		var ev_e: InputEventKey = InputEventKey.new()
		ev_e.physical_keycode = 69
		ev_e.keycode = 69
		InputMap.action_add_event("restart", ev_e)
    # На старте отключаем неигровые матричные кубы (можно включить командой)
    _collect_matrix_cubes()
    _set_cubes_enabled(false)
	print("[Game] Spawned foods=", foods.size(), ", spikes=", spikes.size())

func _physics_process(delta: float):
    # Во время паузы (game over) не двигаем хвост
    if is_game_over:
        return
    if not player:
        return
	# Обновляем буфер пути головы
	_push_head_point(player.global_position)
	# Ровное буферное следование хвоста: выбор точек на пути головы на заданной дистанции
	for i in range(segments.size()):
		var sample: Dictionary = _sample_path_at_distance(segment_spacing * float(i + 1))
		var target_pos: Vector3 = sample["pos"]
		var tan_vec: Vector3 = sample["tan"]
		target_pos.y = player.global_position.y
		var seg: Node3D = segments[i]
		# Сглаживание позиции — постепенно притягиваемся к целевой точке
		var alpha_pos: float = clamp(segment_follow_rate * delta, 0.0, 1.0)
		seg.global_position = seg.global_position.lerp(target_pos, alpha_pos)
		# Сглаживание ориентации — интерполяция угла поворота по оси Y
		if tan_vec.length() > 0.001:
			var target_yaw: float = atan2(tan_vec.x, tan_vec.z)
			var yaw_alpha: float = clamp(segment_look_rate * delta, 0.0, 1.0)
			var r: Vector3 = seg.rotation
			r.y = lerp_angle(r.y, target_yaw, yaw_alpha)
			seg.rotation = r

func _spawn_foods():
	for i in range(food_count):
		var f: Food = Food.new()
		if f != null:
			add_child(f)
			f.setup(self)
			f.randomize_position(spawn_min, spawn_max)
			foods.append(f)

func _spawn_spikes():
	for i in range(spike_count):
		var s: Spikes = Spikes.new()
		if s != null:
			add_child(s)
			s.setup(self)
			s.randomize_position(spawn_min, spawn_max)
			spikes.append(s)
			print("[Game] Spike at ", s.global_position)

func on_food_eaten(food: Node):
	add_segment()
	if player:
		print("[Game] Еда съедена — сегментов: ", segments.size(), " (персонаж увеличился)")
	if food and food.has_method("randomize_position"):
		food.randomize_position(spawn_min, spawn_max)

func game_over():
	if is_game_over:
		return
	is_game_over = true
	print("[Game] GAME OVER")
	get_tree().paused = true
	if ui_panel:
		ui_panel.visible = true

func add_segment() -> void:
	var seg = Segment.new()
	if seg != null:
		add_child(seg)
		seg.setup(self)
		seg.global_position = player.global_position
		# Коротко прикрепляем сегмент к игроку, чтобы он визуально не оставался позади
		if seg.has_method("set_attach_time"):
			seg.set_attach_time(0.6)
		segments.append(seg)
		_update_segment_thickness()

func _spawn_initial_segments() -> void:
	if not player:
		return
	for i in range(max(0, initial_segments)):
		add_segment()
		var seg: Node3D = segments.back()
		if seg:
			# Небольшое смещение по оси Z, чтобы хвост был видим при старте
			seg.global_position = player.global_position - player.global_transform.basis.z.normalized() * segment_spacing * float(i + 1)
			seg.global_position.y = player.global_position.y
	_update_segment_thickness()
func restart_game() -> void:
	print("[Game] Restart")
	# Возобновляем игру
	get_tree().paused = false
	is_game_over = false
	if ui_panel:
		ui_panel.visible = false
	# Сбрасываем игрока
    if player:
        player.velocity = Vector3.ZERO
        player.scale = Vector3.ONE
        # Опускаем игрока на уровень пола, чтобы голова и тело совпадали по высоте
        player.global_position = Vector3(0.0, 0.0, 0.0)
        player.rotation = Vector3.ZERO
	# Сбрасываем буфер пути
	path_points.clear()
	# Удаляем сегменты
	for seg in segments:
		if seg:
			seg.queue_free()
	segments.clear()
	# Перерандомим объекты
	for f in foods:
		if f and f.has_method("randomize_position"):
			f.randomize_position(spawn_min, spawn_max)
	for s in spikes:
		if s and s.has_method("randomize_position"):
			s.randomize_position(spawn_min, spawn_max)
	# Перезаполняем хвост и буфер пути
	_spawn_initial_segments()
	if player:
		_seed_path_buffer(initial_segments)
	_update_segment_thickness()

func _build_ui() -> void:
    if ui_layer:
        return
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	ui_panel = Control.new()
	# Size flags не используются: якоря уже растягивают панель на весь экран
	ui_panel.visible = false
	ui_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui_layer.add_child(ui_panel)

	var vb = VBoxContainer.new()
	vb.anchor_left = 0.0
	vb.anchor_right = 1.0
	vb.anchor_top = 0.0
	vb.anchor_bottom = 1.0
	# Size flags не используются: VBoxContainer заполняет панель благодаря якорям
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui_panel.add_child(vb)

	var label = Label.new()
	label.text = "GAME OVER — Press E to Restart"
	label.horizontal_alignment = 1
	label.vertical_alignment = 1
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	vb.add_child(label)

	var btn = Button.new()
	btn.text = "Restart"
	btn.custom_minimum_size = Vector2(200, 48)
	btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn.connect("pressed", Callable(self, "_on_restart_pressed"))
	vb.add_child(btn)

func _on_restart_pressed() -> void:
	restart_game()

func _input(event) -> void:
    # Обрабатываем нажатие рестарта даже если UI перехватывает события
    if is_game_over and event is InputEventKey and event.pressed:
        if event.is_action_pressed("restart") or event.keycode == KEY_E:
            print("[Input] Action 'restart' pressed (via _input) → restarting")
            restart_game()
    # Тоггл консоли по клавише ` (QUOTELEFT)
    if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
        _toggle_console()

func _unhandled_input(_event) -> void:
	# Логируем нажатия в состоянии game over (только E) и сам триггер действия
	if is_game_over:
		if _event is InputEventKey and _event.pressed:
			var key_str = OS.get_keycode_string(_event.keycode)
			if _event.keycode == 69:
				print("[Input] Key pressed: ", key_str)
		if Input.is_action_just_pressed("restart"):
			print("[Input] Action 'restart' just_pressed → restarting")
			restart_game()

func _setup_input_actions() -> void:
    # Действие для вызова консоли
    if not InputMap.has_action("toggle_console"):
        InputMap.add_action("toggle_console")
        var ev: InputEventKey = InputEventKey.new()
        ev.keycode = KEY_QUOTELEFT
        InputMap.action_add_event("toggle_console", ev)

func _build_console() -> void:
    console_layer = CanvasLayer.new()
    add_child(console_layer)
    console_layer.process_mode = Node.PROCESS_MODE_ALWAYS

    console_panel = Panel.new()
    console_panel.visible = false
    console_panel.anchor_left = 0.0
    console_panel.anchor_right = 1.0
    console_panel.anchor_top = 0.6
    console_panel.anchor_bottom = 1.0
    console_panel.offset_left = 0.0
    console_panel.offset_right = 0.0
    console_panel.offset_top = 0.0
    console_panel.offset_bottom = 0.0
    console_layer.add_child(console_panel)

    var vb := VBoxContainer.new()
    vb.anchor_left = 0.0
    vb.anchor_right = 1.0
    vb.anchor_top = 0.0
    vb.anchor_bottom = 1.0
    vb.offset_left = 8.0
    vb.offset_right = -8.0
    vb.offset_top = 8.0
    vb.offset_bottom = -8.0
    console_panel.add_child(vb)

    var sc := ScrollContainer.new()
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vb.add_child(sc)

    console_log = RichTextLabel.new()
    console_log.scroll_active = true
    console_log.fit_content = false
    console_log.autowrap = true
    console_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    console_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    console_log.append_text("Console ready. Нажмите ` для скрытия/показа.\n")
    sc.add_child(console_log)

    console_input = LineEdit.new()
    console_input.placeholder_text = "Введите команду и нажмите Enter (help — список)"
    console_input.caret_blink = true
    console_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vb.add_child(console_input)
    console_input.connect("text_submitted", Callable(self, "_on_console_submit"))

func _set_console_visible(show: bool) -> void:
    if console_panel == null:
        return
    console_panel.visible = show
    if show:
        console_input.grab_focus()
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_console_height(p: float) -> void:
    if console_panel == null:
        return
    var pct := clamp(p, 0.3, 0.95)
    console_panel.anchor_top = 1.0 - pct

func _toggle_console() -> void:
    if console_panel == null:
        return
    _set_console_visible(not console_panel.visible)

func _on_console_submit(text: String) -> void:
    var cmd := text.strip_edges()
    console_input.text = ""
    if cmd == "":
        return
    _log_console("> " + cmd)
    _execute_command(cmd)

func _log_console(line: String) -> void:
    if console_log:
        console_log.append_text(line + "\n")
        if console_log.has_method("get_line_count") and console_log.has_method("scroll_to_line"):
            console_log.scroll_to_line(console_log.get_line_count())

func _execute_command(cmd: String) -> void:
    var parts := cmd.split(" ", false, 0)
    var name := parts[0].to_lower()
    var args := parts.slice(1, parts.size())
    match name:
        "help":
            _log_console(_commands_help())
        "clear":
            if console_log:
                console_log.clear()
            _log_console("<console cleared>")
        "restart":
            restart_game()
            _log_console("restart")
        "speed":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.move_speed = v
                _log_console("move_speed=" + str(v))
        "turn":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.turn_speed = v
                _log_console("turn_speed=" + str(v))
        "auto_forward":
            if player and args.size() >= 1:
                var s := args[0].to_lower()
                var on := (s == "on" or s == "1" or s == "true")
                player.auto_forward = on
                _log_console("auto_forward=" + ("on" if on else "off"))
        "camera_distance":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.camera_distance = v
                _log_console("camera_distance=" + str(v))
        "camera_height":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.camera_height = v
                _log_console("camera_height=" + str(v))
        "camera_lerp":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.camera_lerp = v
                _log_console("camera_lerp=" + str(v))
        "head_height":
            if player and args.size() >= 1:
                var v := args[0].to_float()
                player.head_height = v
                _log_console("head_height=" + str(v))
        "segments_add":
            if args.size() >= 1:
                var n := int(args[0])
                for i in range(max(0, n)):
                    add_segment()
                _log_console("segments=" + str(segments.size()))
        "segments_clear":
            for seg in segments:
                if seg:
                    seg.queue_free()
            segments.clear()
            _log_console("segments cleared")
        "cubes":
            if args.size() >= 1:
                var s := args[0].to_lower()
                var on := (s == "on" or s == "1" or s == "true")
                _set_cubes_enabled(on)
                _log_console("cubes=" + ("on" if on else "off"))
        "console":
            if args.size() >= 1:
                var s := args[0].to_lower()
                var on := (s == "on" or s == "1" or s == "true")
                _set_console_visible(on)
                _log_console("console=" + ("on" if on else "off"))
        "console_height":
            if args.size() >= 1:
                var p := clamp(args[0].to_float(), 0.3, 0.95)
                _set_console_height(p)
                _log_console("console_height=" + str(p))
        _:
            _log_console("Unknown command: " + name)

func _commands_help() -> String:
    var lines := [
        "Commands:",
        "  help — список команд",
        "  clear — очистить консоль",
        "  restart — рестарт игры",
        "  speed <float> — скорость движения вперёд",
        "  turn <float> — скорость поворота",
        "  auto_forward <on|off> — авто-движение",
        "  camera_distance <float> — дистанция камеры",
        "  camera_height <float> — высота камеры",
        "  camera_lerp <float> — сглаживание камеры",
        "  head_height <float> — уровень головы/тела (Y)",
        "  segments_add <int> — добавить сегменты хвоста",
        "  segments_clear — удалить все сегменты",
        "  cubes <on|off> — включить/выключить матричные кубы",
        "  console <on|off> — показать/скрыть консоль",
        "  console_height <0.3..0.95> — высота консоли (доля экрана)",
        "",
        "Подсказка: клавиша ` (тильда) — быстрое скрытие/показ."
    ]
    return "\n".join(lines)

func _collect_matrix_cubes() -> void:
    matrix_cubes.clear()
    var root := get_tree().root
    var stack: Array = [root]
    while stack.size() > 0:
        var n: Node = stack.pop_back()
        for c in n.get_children():
            stack.append(c)
            if c is Node:
                var sc = c.get_script()
                if sc and sc is Script and String(sc.resource_path).find("MatrixCube.gd") != -1:
                    matrix_cubes.append(c)

func _set_cubes_enabled(enabled: bool) -> void:
    cubes_enabled = enabled
    if matrix_cubes.size() == 0:
        _collect_matrix_cubes()
    for n in matrix_cubes:
        if n and n is Node3D:
            (n as Node3D).visible = enabled

# ----- Буфер пути головы и выбор точек хвоста -----
func _push_head_point(pos: Vector3) -> void:
	if path_points.size() == 0:
		path_points.append(pos)
		return
	var last: Vector3 = path_points.back()
	if (pos - last).length() >= path_point_min_step:
		path_points.append(pos)
		if path_points.size() > path_max_points:
			path_points.remove_at(0)

func _seed_path_buffer(count: int) -> void:
	path_points.clear()
	var dir: Vector3 = -player.global_transform.basis.z.normalized()
	var step: float = path_point_min_step
	var total_len: float = segment_spacing * float(count + 5)
	var steps: int = int(ceil(total_len / step))
	var base: Vector3 = player.global_position
	for i in range(steps):
		var p: Vector3 = base + dir * float(i) * step
		path_points.append(p)

func _sample_path_at_distance(d: float) -> Dictionary:
	var n: int = path_points.size()
	if n < 2 or d <= 0.0:
		var dir_fallback: Vector3 = -player.global_transform.basis.z.normalized()
		return {"pos": player.global_position + dir_fallback * d, "tan": dir_fallback}
	var remain: float = d
	var i: int = n - 1
	while i > 0:
		var p1: Vector3 = path_points[i]
		var p0: Vector3 = path_points[i - 1]
		var seg_len: float = (p1 - p0).length()
		if seg_len >= remain:
			var t: float = remain / seg_len
			var pos: Vector3 = p1.lerp(p0, t)
			var tan: Vector3 = (p1 - p0).normalized()
			return {"pos": pos, "tan": tan}
		remain -= seg_len
		i -= 1
	var dir_tail: Vector3 = -player.global_transform.basis.z.normalized()
	var pos_tail: Vector3 = path_points[0] - dir_tail * remain
	return {"pos": pos_tail, "tan": dir_tail}

func _update_segment_thickness() -> void:
	# Градиент толщины хвоста: ближе к голове — толще, к концу — тоньше
	var total: int = segments.size()
	if total <= 0:
		return
	for i in range(total):
		var seg: Node3D = segments[i]
		var t: float = float(i) / float(total)
		# 0: рядом с головой -> 0.30; конец хвоста -> 0.20
		var thick: float = lerp(0.20, 0.30, 1.0 - t)
		if seg and seg.has_method("set_radii"):
			seg.set_radii(thick * 0.92, thick)