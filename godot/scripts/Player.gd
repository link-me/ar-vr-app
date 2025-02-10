extends CharacterBody3D

# Управление в стиле Snake3D: постоянное движение вперёд и поворот по вводу
@export var move_speed: float = 6.0
@export var turn_speed: float = 3.0
@export var auto_forward: bool = true
@export var head_height: float = 0.0
@export var camera_distance: float = 4.0
@export var camera_height: float = 2.0
@export var camera_lerp: float = 6.0
@export var camera_look_offset: Vector3 = Vector3(0.0, 0.5, 0.0)

var yaw: float = 0.0

func _setup_input_map() -> void:
    # Создаём действия для WASD, если их нет
    var actions := {
        "move_left": [KEY_A],
        "move_right": [KEY_D],
        "move_forward": [KEY_W],
        "move_back": [KEY_S]
    }
    for name in actions.keys():
        if not InputMap.has_action(name):
            InputMap.add_action(name)
        # Добавляем события клавиш
        for key in actions[name]:
            var ev := InputEventKey.new()
            ev.keycode = key
            InputMap.action_add_event(name, ev)

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    _setup_input_map()
    print("[Player] Ready. Snake3D movement. speed=", move_speed)

    # Голова змеи: составная модель (череп + морда + глаза), вместо капсулы
    if not has_node("HeadMesh"):
        var head := Node3D.new()
        head.name = "HeadMesh"
        add_child(head)
        # Дополнительно опускаем локально голову, чтобы визуально совпадала с телом
        # Опускаем голову ниже уровня тела, убираем лишний подъём
        head.position = Vector3(0.0, -0.18, 0.0)

        var body_mat := StandardMaterial3D.new()
        body_mat.albedo_color = Color(0.2, 0.8, 0.3, 1.0)
        body_mat.emission_enabled = true
        body_mat.emission = Color(0.06, 0.24, 0.09, 1.0)
        body_mat.emission_energy_multiplier = 0.6
        body_mat.roughness = 0.55

        var eye_mat := StandardMaterial3D.new()
        eye_mat.albedo_color = Color(0.05, 0.05, 0.05, 1.0)
        eye_mat.roughness = 0.4

        # Череп: слегка вытянутый шар
        var skull := MeshInstance3D.new()
        skull.name = "Skull"
        skull.mesh = SphereMesh.new()
        skull.scale = Vector3(0.6, 0.55, 0.9)
        skull.material_override = body_mat
        head.add_child(skull)

        # Морда: конус (через CylinderMesh с top_radius=0), ориентированный вперёд по -Z
        var snout := MeshInstance3D.new()
        snout.name = "Snout"
        var cone: CylinderMesh = CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = 0.18
        cone.height = 0.55
        snout.mesh = cone
        snout.rotation_degrees.x = 90.0
        # Чуть ближе к черепу, чтобы уменьшить зазор визуально
        snout.position = Vector3(0.0, 0.0, -0.38)
        snout.material_override = body_mat
        head.add_child(snout)

        # Глаза: два маленьких шара по бокам
        for side in [-1, 1]:
            var eye := MeshInstance3D.new()
            eye.name = "LeftEye" if side < 0 else "RightEye"
            var es := SphereMesh.new()
            es.radius = 0.06
            eye.mesh = es
            eye.material_override = eye_mat
            eye.position = Vector3(0.16 * float(side), 0.16, -0.18)
            head.add_child(eye)

    # Камера третьего лица: создаём при отсутствии
    if not has_node("Camera3D"):
        var cam := Camera3D.new()
        cam.name = "Camera3D"
        cam.fov = 70.0
        cam.near = 0.1
        cam.far = 400.0
        cam.current = true
        add_child(cam)

func _physics_process(delta: float) -> void:
    # Поворот по вводу: влево/вправо (ui_* или move_*)
    var turn := Input.get_axis("ui_left", "ui_right")
    if turn == 0.0:
        turn = Input.get_axis("move_left", "move_right")
    yaw += turn * turn_speed * delta
    rotation.y = yaw

    # Движение вперёд по направлению -Z
    var dir: Vector3 = -global_transform.basis.z
    dir.y = 0.0
    dir = dir.normalized()

    var go_forward := auto_forward or Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_forward")
    if go_forward:
        velocity = dir * move_speed
    else:
        velocity = Vector3.ZERO

    # Фикс высоты головы
    global_position.y = head_height
    move_and_slide()

    # Камера: плавное следование сзади и сверху
    if has_node("Camera3D"):
        var desired := global_position - (-global_transform.basis.z).normalized() * camera_distance + Vector3(0.0, camera_height, 0.0)
        $Camera3D.global_position = $Camera3D.global_position.lerp(desired, camera_lerp * delta)
        $Camera3D.look_at(global_position + camera_look_offset, Vector3.UP)