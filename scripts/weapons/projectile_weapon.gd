extends WeaponBase
class_name ProjectileWeapon

var damage: float = 28.08
var shoot_cooldown: float = 0.504
var projectile_count: int = 1
var projectile_range: float = 300.0
var _shoot_timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Base shot (damage 28, cooldown 0.50s)",
	"Faster: Cooldown ×0.8",
	"Spread: 2 bolts",
	"Power: Damage ×1.3",
	"Faster: Cooldown ×0.75",
	"Spread: 3 bolts",
	"Power: Damage ×1.4",
	"Max Power: Cooldown ×0.7, 4 bolts",
]

func _on_setup() -> void:
	_projectile_scene = load("res://scenes/projectile.tscn")
	weapon_name = "Magic Bolt"
	weapon_description = "Fires bolts at the nearest enemy."

func _on_upgrade() -> void:
	match level:
		2:
			shoot_cooldown *= 0.8
			projectile_range = 360.0
		3:
			projectile_count = 2
			projectile_range = 420.0
		4:
			damage *= 1.3
			projectile_range = 500.0
		5:
			shoot_cooldown *= 0.75
			projectile_range = 580.0
		6:
			projectile_count = 3
			projectile_range = 660.0
		7:
			damage *= 1.4
			projectile_range = 750.0
		8:
			shoot_cooldown *= 0.7
			projectile_count = 4
			projectile_range = 850.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _physics_process(delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var targets := _find_nearest_enemies(projectile_count)
		if targets.size() > 0:
			_shoot_timer = shoot_cooldown
			_fire_at(targets)

func _find_nearest_enemies(count: int) -> Array:
	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	enemies.sort_custom(func(a, b):
		return _player.global_position.distance_squared_to(a.global_position) \
			 < _player.global_position.distance_squared_to(b.global_position))
	return enemies.slice(0, count)

func _fire_at(targets: Array) -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	for target in targets:
		var dir: Vector2 = ((target as Node2D).global_position - _player.global_position).normalized()
		_spawn_projectile(dir)

func _spawn_projectile(direction: Vector2) -> void:
	var proj: Area2D = _projectile_scene.instantiate()
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	proj.damage = damage * dmg_mult
	proj.direction = direction
	proj.max_range = projectile_range
	proj.global_position = _player.global_position
	_projectiles_container.add_child(proj)
