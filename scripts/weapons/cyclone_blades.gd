extends WeaponBase
class_name CycloneBlades

var damage: float = 35.0
var knife_count: int = 20
var fire_interval: float = 0.55
var _timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Continuous knife cyclone (20 knives, 35 dmg, 0.55s)",
	"Count: 22 knives, Damage: 46, Interval: 0.50s",
	"Count: 26 knives, Damage: 58, Interval: 0.40s",
	"Max: 30 knives, 72 dmg, 0.32s",
]

func _on_setup() -> void:
	weapon_name = "Cyclone Blades"
	weapon_description = "Unleashes an unending cyclone of blades in all directions."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			knife_count = 22
			damage = 46.0
			fire_interval = 0.50
		3:
			knife_count = 26
			damage = 58.0
			fire_interval = 0.40
		4:
			knife_count = 30
			damage = 72.0
			fire_interval = 0.32

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = fire_interval
		_fire_burst()

func _fire_burst() -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var angle_offset: float = randf() * TAU
	for i in knife_count:
		var angle: float = angle_offset + (TAU / float(knife_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
