extends WeaponBase
class_name ProjectileWeapon

var damage: float = 15.0
var shoot_cooldown: float = 0.8
var projectile_count: int = 1
var _shoot_timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Base shot (damage 15, cooldown 0.8s)",
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
		1:
			damage = 15.0
			shoot_cooldown = 0.8
			projectile_count = 1
		2:
			shoot_cooldown *= 0.8
		3:
			projectile_count = 2
		4:
			damage *= 1.3
		5:
			shoot_cooldown *= 0.75
		6:
			projectile_count = 3
		7:
			damage *= 1.4
		8:
			shoot_cooldown *= 0.7
			projectile_count = 4

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	if level == 0:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var nearest := _find_nearest_enemy()
		if nearest:
			_shoot_timer = shoot_cooldown
			_fire_at(nearest)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := _player.global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func _fire_at(target: Node2D) -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	var base_dir := (target.global_position - _player.global_position).normalized()
	if projectile_count == 1:
		_spawn_projectile(base_dir)
	else:
		var spread := deg_to_rad(20.0)
		for i in projectile_count:
			var t := float(i) / float(projectile_count - 1)
			var angle: float = lerp(-spread, spread, t)
			_spawn_projectile(base_dir.rotated(angle))

func _spawn_projectile(direction: Vector2) -> void:
	var proj: Area2D = _projectile_scene.instantiate()
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	proj.damage = damage * dmg_mult
	proj.direction = direction
	proj.global_position = _player.global_position
	_projectiles_container.add_child(proj)
