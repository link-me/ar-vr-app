extends Area3D
class_name Spikes

var game: Node

func setup(g: Node) -> void:
    game = g

func _ready():
    monitoring = true
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(0.8, 0.8, 0.8)
    col.shape = shape
    add_child(col)

    var mesh = MeshInstance3D.new()
    # Конусообразная форма через CylinderMesh (совместима в Godot 4)
    var cyl = CylinderMesh.new()
    cyl.height = 1.0
    cyl.bottom_radius = 0.6
    cyl.top_radius = 0.0
    mesh.mesh = cyl
    mesh.scale = Vector3(0.7, 0.7, 0.7)
    var mat = StandardMaterial3D.new()
    # Базовый материал (fallback)
    mat.albedo_color = Color(1.0, 0.05, 0.05, 1)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.1, 0.1, 1)
    mat.emission_energy_multiplier = 2.0
    mat.roughness = 0.6
    mat.metallic = 0.0
    # Попытка загрузить текстуру, если она существует
    var tex_path := "res://assets/textures/spikes.png"
    if ResourceLoader.exists(tex_path):
        var tex: Texture2D = load(tex_path)
        if tex:
            mat.albedo_texture = tex
            mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
            mat.emission_enabled = false
            mat.roughness = 0.8
    mesh.material_override = mat
    add_child(mesh)

    connect("body_entered", Callable(self, "_on_body_entered"))

func randomize_position(min_v: Vector2, max_v: Vector2) -> void:
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var tries := 0
    var min_dist := 1.2
    var pos := global_position
    while tries < 32:
        var x = rng.randf_range(min_v.x, max_v.x)
        var z = rng.randf_range(min_v.y, max_v.y)
        pos = Vector3(x, 0.4, z)
        if _is_far_from_foods(pos, min_dist):
            break
        tries += 1
    global_position = pos

func _is_far_from_foods(pos: Vector3, min_dist: float) -> bool:
    var parent := get_parent()
    if parent:
        for c in parent.get_children():
            if c != self and c is Food:
                var d := pos.distance_to(c.global_position)
                if d < min_dist:
                    return false
    return true

func _process(delta: float) -> void:
    rotate_y(0.4 * delta)

# Убраны процедурные/внешние текстуры для исключения парсер-ошибок

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody3D and body.name == "Player":
        # Лог: игрок наступил на шипы
        print("[Collision] Наступил на ШИПЫ")
        if game and game.has_method("game_over"):
            game.game_over()