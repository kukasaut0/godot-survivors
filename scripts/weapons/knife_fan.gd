extends WeaponBase
class_name KnifeFan

var damage: float = 25.0
var projectile_count: int = 4
var fire_interval: float = 2.0
var _timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Fires 4 knives in all directions (dmg 25, 2.0s)",
	"Damage 30, Count: 6 knives",
	"Damage 36, Count: 8 knives",
	"Interval: 1.6s",
	"Damage 44, Count: 10 knives",
	"Count: 12, Interval: 1.3s",
	"Damage 52",
	"Max: 16 knives, Interval: 1.1s",
]

func _on_setup() -> void:
	weapon_name = "Knife Fan"
	weapon_description = "Periodically fires knives in all directions."
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			damage = 30.0
			projectile_count = 6
		3:
			damage = 36.0
			projectile_count = 8
		4:
			fire_interval = 1.6
		5:
			damage = 44.0
			projectile_count = 10
		6:
			projectile_count = 12
			fire_interval = 1.3
		7:
			damage = 52.0
		8:
			projectile_count = 16
			fire_interval = 1.1

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
	for i in projectile_count:
		var angle: float = (TAU / float(projectile_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.weapon_id = "knife_fan"
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
