extends WeaponBase
class_name KnifeFan

var damage: float = 10.0
var projectile_count: int = 4
var fire_interval: float = 2.5
var _timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Fires 4 knives in all directions (dmg 10, 2.5s)",
	"Damage: 15",
	"Count: 8 knives",
	"Interval: 2s",
	"Damage: 20",
	"Count: 12 knives",
	"Interval: 1.5s",
	"Max: 16 knives, dmg 30",
]

func _on_setup() -> void:
	weapon_name = "Knife Fan"
	weapon_description = "Periodically fires knives in all directions."
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		1:
			damage = 10.0
			projectile_count = 4
			fire_interval = 2.5
		2:
			damage = 15.0
		3:
			projectile_count = 8
		4:
			fire_interval = 2.0
		5:
			damage = 20.0
		6:
			projectile_count = 12
		7:
			fire_interval = 1.5
		8:
			projectile_count = 16
			damage = 30.0

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	if level == 0:
		return
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
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
