extends WeaponBase
class_name NovaBolt

var damage: float = 40.0
var bolt_count: int = 8
var fire_interval: float = 0.35
var _timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Rapid bolts in all directions (8 bolts, 40 dmg, 0.35s)",
	"Count: 12 bolts, Damage: 56",
	"Count: 16 bolts, Interval: 0.22s",
	"Max: 24 bolts, 80 dmg, 0.14s",
]

func _on_setup() -> void:
	weapon_name = "Nova Bolt"
	weapon_description = "Fires a rapid barrage of bolts in all directions."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			bolt_count = 12
			damage = 56.0
		3:
			bolt_count = 16
			fire_interval = 0.22
		4:
			bolt_count = 24
			damage = 80.0
			fire_interval = 0.14

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = fire_interval
		_fire_burst()

func _fire_burst() -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	for i in bolt_count:
		var angle: float = (TAU / float(bolt_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
