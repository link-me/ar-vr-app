extends Area3D
class_name Segment

var game: Node
var _spawn_grace_time: float = 0.6
var _attach_time: float = 0.0
var _cyl: CylinderMesh

func setup(g: Node) -> void:
    game = g

func _ready():
    monitoring = true

    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.25
    shape.height = 0.9
    col.shape = shape
    add_child(col)

    var mesh := MeshInstance3D.new()
    _cyl = CylinderMesh.new()
    _cyl.top_radius = 0.25
    _cyl.bottom_radius = 0.25
    _cyl.height = 0.9
    mesh.mesh = _cyl
    mesh.rotation_degrees.x = 90.0 # ориентируем цилиндр вдоль оси Z
    mesh.scale = Vector3(1.0, 1.0, 1.0)

    var mat := StandardMaterial3D.new()
    # Пытаемся загрузить текстуру чешуи змеи (CC0). Если не найдена — используем зелёный цвет.
    var tex: Texture2D = null
    var paths := [
        "res://assets/textures/snake/snake_body.jpg",
        "res://assets/textures/snake/snake_body.png"
    ]
    for p in paths:
        if ResourceLoader.exists(p):
            var r = load(p)
            if r is Texture2D:
                tex = r
                break
    if tex:
        mat.albedo_texture = tex
        mat.uv1_scale = Vector3(1.5, 1.0, 1.0)
        mat.roughness = 0.6
        mat.metallic = 0.0
        mat.emission_enabled = false
    else:
        # Процедурная «чешуя», если внешняя текстура недоступна
        var proc := _make_scale_texture(256)
        if proc:
            mat.albedo_texture = proc
            mat.uv1_scale = Vector3(1.2, 1.2, 1.0)
            mat.roughness = 0.65
            mat.metallic = 0.0
            mat.emission_enabled = false
        else:
            mat.albedo_color = Color(0.2, 0.8, 0.3, 1.0)
            mat.emission_enabled = true
            mat.emission = Color(0.2, 0.8, 0.3, 1.0)
            mat.emission_energy_multiplier = 1.5

    mesh.material_override = mat
    add_child(mesh)

    connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
    # Короткий grace-период после спауна сегмента, чтобы избежать
    # мгновенного game over при поедании еды (сегмент появляется на игроке).
    if _spawn_grace_time > 0.0:
        _spawn_grace_time = max(0.0, _spawn_grace_time - delta)
    # Временное прикрепление к голове: пока таймер активен, сегмент следует
    # за позицией игрока, чтобы визуально "прилипнуть" к капсуле.
    if _attach_time > 0.0 and game:
        _attach_time = max(0.0, _attach_time - delta)
        var player_node = game.get_parent().get_node("Player")
        if player_node:
            global_position = player_node.global_position

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody3D and body.name == "Player":
        # Игнорируем столкновение в течение grace-периода после создания
        if _spawn_grace_time > 0.0:
            return
        if game and game.has_method("game_over"):
            game.game_over()
func set_attach_time(seconds: float) -> void:
    _attach_time = max(0.0, seconds)
    # На время прикрепления продлеваем grace-период коллизии с игроком
    _spawn_grace_time = max(_spawn_grace_time, seconds)
func set_radii(top_radius: float, bottom_radius: float) -> void:
    # Позволяет игре настраивать толщину сегмента для плавного градиента хвоста
    if _cyl:
        _cyl.top_radius = max(0.05, top_radius)
        _cyl.bottom_radius = max(0.05, bottom_radius)

func _make_scale_texture(size: int) -> Texture2D:
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    for y in range(size):
        for x in range(size):
            var u: float = float(x) / float(size)
            var v: float = float(y) / float(size)
            # Количество «чешуек» по U/V
            var cols: float = 8.0
            var rows: float = 6.0
            var uu: float = u * cols
            var vv: float = v * rows
            # Сдвиг ряда для шахматного расположения
            var vv_off: float = vv + float(int(floor(uu)) % 2) * 0.5
            # Вычисляем ромбовидную маску
            var fu: float = float(abs((uu - floor(uu)) - 0.5))
            var fv: float = float(abs((vv_off - floor(vv_off)) - 0.5))
            var d: float = fu + fv
            var base: Color = Color(0.12, 0.55, 0.2, 1.0)
            var edge: Color = Color(0.08, 0.45, 0.16, 1.0)
            var c: Color
            if d < 0.35:
                c = edge
            else:
                c = base
            img.set_pixel(x, y, c)
    var tex := ImageTexture.create_from_image(img)
    return tex