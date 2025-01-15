extends Node3D

var settings := {
    "mouse_sensitivity": 0.3,
    "move_speed": 4.0
}

var yaw := 0.0
var pitch := 0.0

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    load_settings()

func _unhandled_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * settings.mouse_sensitivity * 0.01
        pitch -= event.relative.y * settings.mouse_sensitivity * 0.01
        pitch = clamp(pitch, -1.2, 1.2)
        $Camera3D.rotation.x = pitch
        $Camera3D.rotation.y = yaw

    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_S:
                save_settings()
            KEY_R:
                yaw = 0.0
                pitch = 0.0
                $Camera3D.rotation = Vector3.ZERO
                $Camera3D.position = Vector3(0, 1.6, 6)

func _process(delta):
    var dir := Vector3.ZERO
    if Input.is_action_pressed("ui_up"): dir.z -= 1
    if Input.is_action_pressed("ui_down"): dir.z += 1
    if Input.is_action_pressed("ui_left"): dir.x -= 1
    if Input.is_action_pressed("ui_right"): dir.x += 1
    dir = dir.normalized()
    var forward := -$Camera3D.global_transform.basis.z
    var right := $Camera3D.global_transform.basis.x
    var move := (forward * dir.z + right * dir.x) * settings.move_speed * delta
    $Camera3D.global_translate(move)

func save_settings():
    var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(settings))
        f.close()

func load_settings():
    if FileAccess.file_exists("user://settings.json"):
        var f := FileAccess.open("user://settings.json", FileAccess.READ)
        if f:
            var txt := f.get_as_text()
            var parsed := JSON.parse_string(txt)
            if typeof(parsed) == TYPE_DICTIONARY:
                settings = parsed
            f.close()