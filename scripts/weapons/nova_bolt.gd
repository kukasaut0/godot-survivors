extends WeaponBase
class_name NovaBolt

var damage: float = 70.0
var bolt_count: int = 6
var fire_interval: float = 0.40
var _timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Rapid bolts in all directions (6 bolts, 70 dmg, 0.40s)",
	"Count: 8 bolts, Damage: 90, Interval: 0.36s",
	"Count: 10 bolts, Damage: 110, Interval: 0.32s",
	"Max: 12 bolts, 135 dmg, 0.28s",
]

func _on_setup() -> void:
	weapon_name = "Nova Bolt"
	weapon_description = "Fires a rapid barrage of bolts in all directions."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			bolt_count = 8
			damage = 90.0
			fire_interval = 0.36
		3:
			bolt_count = 10
			damage = 110.0
			fire_interval = 0.32
		4:
			bolt_count = 12
			damage = 135.0
			fire_interval = 0.28

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
	for i in bolt_count:
		var angle: float = (TAU / float(bolt_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
