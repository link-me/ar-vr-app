extends MeshInstance3D

@export var amplitude: Vector3 = Vector3(0.2, 0.3, 0.2)
@export var speed: Vector3 = Vector3(0.8, 1.2, 0.6)
@export var phase: Vector3 = Vector3.ZERO
@export var pulse_amp: float = 1.0
@export var pulse_speed: float = 1.6

var base_pos: Vector3
var base_emission_energy: float = 1.0

func _ready():
	base_pos = global_transform.origin
	# Случайная фаза, чтобы кубы двигались по-разному
	var r := randi() % 1000
	phase = Vector3(float(r % 7), float((r / 7) % 11), float((r / 13) % 17))
	# Дублируем материал, чтобы пульсация была уникальной на каждом кубе
	var mat = material_override
	if mat:
		mat = mat.duplicate()
		material_override = mat
		if mat is StandardMaterial3D:
			mat.emission_enabled = true
			base_emission_energy = mat.emission_energy_multiplier

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var offset := Vector3(
		sin(t * speed.x + phase.x) * amplitude.x,
		sin(t * speed.y + phase.y) * amplitude.y,
		sin(t * speed.z + phase.z) * amplitude.z
	)
	global_position = base_pos + offset
	# Пульсация эмиссии для матричного glow
	var mat2 = material_override
	if mat2 and mat2 is StandardMaterial3D:
		mat2.emission_enabled = true
		mat2.emission_energy_multiplier = base_emission_energy + sin(t * pulse_speed) * pulse_amp
