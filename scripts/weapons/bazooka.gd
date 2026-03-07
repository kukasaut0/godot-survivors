extends WeaponBase
class_name Bazooka

var damage: float = 145.0
var explosion_radius: float = 110.0
var fire_interval: float = 2.9
var rocket_speed: float = 380.0
var projectile_count: int = 1

var _fire_timer: float = 0.0
var _rockets: Array = []    # {pos: Vector2, dir: Vector2, dist_left: float}
var _explosions: Array = [] # {pos: Vector2, timer: float}

const ROCKET_HIT_RADIUS: float = 28.0
const EXPLOSION_FLASH_TIME: float = 0.35

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Fires explosive rockets — AoE dmg (145 dmg, 110 radius, 2.9s)",
	"Damage: 190",
	"Interval: 2.3s, Radius: 130",
	"Count: 2 rockets",
	"Damage: 245",
	"Radius: 160, Interval: 2.0s",
	"Count: 3 rockets",
	"Max: 330 dmg, 195 radius, 1.5s",
]

func _on_setup() -> void:
	weapon_name = "Bazooka"
	weapon_description = "Fires explosive rockets that deal collateral AoE damage."

func _on_upgrade() -> void:
	match level:
		2: damage = 190.0
		3: fire_interval = 2.3; explosion_radius = 130.0
		4: projectile_count = 2
		5: damage = 245.0
		6: explosion_radius = 160.0; fire_interval = 2.0
		7: projectile_count = 3
		8: damage = 330.0; explosion_radius = 195.0; fire_interval = 1.5

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		var targets := _get_nearest_enemies(projectile_count)
		if not targets.is_empty():
			_fire_timer = fire_interval
			for t in targets:
				var tpos: Vector2 = (t as Node2D).global_position
				var dir: Vector2 = (tpos - _player.global_position).normalized()
				var dist: float = _player.global_position.distance_to(tpos) + 30.0
				_rockets.append({"pos": _player.global_position, "dir": dir, "dist_left": dist})

	for i in range(_rockets.size() - 1, -1, -1):
		var r: Dictionary = _rockets[i]
		var step: float = rocket_speed * delta
		r.pos += r.dir * step
		r.dist_left -= step
		var hit: bool = r.dist_left <= 0.0
		if not hit:
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and r.pos.distance_squared_to((e as Node2D).global_position) < ROCKET_HIT_RADIUS * ROCKET_HIT_RADIUS:
					hit = true
					break
		if hit:
			_explode(r.pos)
			_rockets.remove_at(i)

	for i in range(_explosions.size() - 1, -1, -1):
		_explosions[i].timer -= delta
		if _explosions[i].timer <= 0.0:
			_explosions.remove_at(i)

	queue_redraw()

func _explode(pos: Vector2) -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var rad_sq: float = explosion_radius * explosion_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if pos.distance_squared_to((e as Node2D).global_position) <= rad_sq:
			e.take_damage_from(damage * dmg_mult, "bazooka")
	_explosions.append({"pos": pos, "timer": EXPLOSION_FLASH_TIME})
	queue_redraw()

func _get_nearest_enemies(count: int) -> Array:
	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	enemies.sort_custom(func(a, b):
		return _player.global_position.distance_squared_to((a as Node2D).global_position) \
			 < _player.global_position.distance_squared_to((b as Node2D).global_position))
	return enemies.slice(0, count)

func _draw() -> void:
	for r in _rockets:
		var local: Vector2 = to_local(r.pos)
		draw_circle(local, 8.0, Color(1, 0.4, 0.1, 1))
		draw_circle(local, 5.0, Color(1, 0.85, 0.2, 1))
	for ex in _explosions:
		var local: Vector2 = to_local(ex.pos)
		var t: float = ex.timer / EXPLOSION_FLASH_TIME
		draw_circle(local, explosion_radius, Color(1, 0.5, 0.1, t * 0.35))
		draw_arc(local, explosion_radius, 0.0, TAU, 32, Color(1, 0.75, 0.2, t), 2.5)
		draw_circle(local, explosion_radius * 0.4, Color(1, 0.9, 0.5, t * 0.6))
