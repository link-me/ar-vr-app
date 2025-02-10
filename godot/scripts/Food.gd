extends Area3D
class_name Food

var game: Node

func setup(g: Node) -> void:
    game = g

func _ready():
    monitoring = true
    var col = CollisionShape3D.new()
    var shape = SphereShape3D.new()
    shape.radius = 0.35
    col.shape = shape
    add_child(col)

    var mesh = MeshInstance3D.new()
    # Сферическая форма для еды (похоже на фрукт)
    var sphere := SphereMesh.new()
    sphere.radial_segments = 24
    sphere.rings = 16
    mesh.mesh = sphere
    mesh.scale = Vector3(0.8, 0.8, 0.8)
    var mat = StandardMaterial3D.new()
    # Базовый материал (fallback)
    mat.albedo_color = Color(0.0, 1.0, 0.4, 1)
    mat.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
    mat.emission_enabled = true
    mat.emission = Color(0.0, 1.0, 0.5, 1)
    mat.emission_energy_multiplier = 1.2
    mat.roughness = 0.6
    # Попытка загрузить текстуру, если она существует
    var tex_path := "res://assets/textures/food.png"
    if ResourceLoader.exists(tex_path):
        var tex: Texture2D = load(tex_path)
        if tex:
            mat.albedo_texture = tex
            mat.emission_enabled = false
            mat.roughness = 0.7
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
        pos = Vector3(x, 1.5, z)
        if _is_far_from_spikes(pos, min_dist):
            break
        tries += 1
    global_position = pos

func _is_far_from_spikes(pos: Vector3, min_dist: float) -> bool:
    var parent := get_parent()
    if parent:
        for c in parent.get_children():
            if c != self and c is Spikes:
                var d := pos.distance_to(c.global_position)
                if d < min_dist:
                    return false
    return true

func _process(delta: float) -> void:
    rotate_y(0.8 * delta)

# Убраны процедурные/внешние текстуры для исключения парсер-ошибок

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody3D and body.name == "Player":
        # Лог: игрок взял еду
        print("[Collision] Взял ЕДУ")
        if game and game.has_method("on_food_eaten"):
            game.on_food_eaten(self)