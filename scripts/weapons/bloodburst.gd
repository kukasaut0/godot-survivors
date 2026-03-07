extends WeaponBase
class_name Bloodburst

var damage: float = 350.0
var explosion_radius: float = 230.0
var fire_interval: float = 1.1
var rocket_speed: float = 440.0
var projectile_count: int = 3
var lifesteal_pct: float = 0.15

var _fire_timer: float = 0.0
var _rockets: Array = []
var _explosions: Array = []

const ROCKET_HIT_RADIUS: float = 28.0
const EXPLOSION_FLASH_TIME: float = 0.4

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: 3 life-draining rockets (350 dmg, 230 radius, 1.1s, 15% lifesteal)",
	"Damage: 440, Interval: 1.0s, Radius: 250",
	"Damage: 540, Interval: 0.9s, Count: 4, Radius: 270",
	"Max: 660 dmg, 310 radius, 0.75s, Count: 5",
]

func _on_setup() -> void:
	weapon_name = "Bloodburst"
	weapon_description = "Explosive rockets that drain life from every enemy hit."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2: damage = 440.0; fire_interval = 1.0; explosion_radius = 250.0
		3: damage = 540.0; fire_interval = 0.9; projectile_count = 4; explosion_radius = 270.0
		4: damage = 660.0; explosion_radius = 310.0; fire_interval = 0.75; projectile_count = 5

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
	var total_heal: float = 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if pos.distance_squared_to((e as Node2D).global_position) <= rad_sq:
			var dmg: float = damage * dmg_mult
			e.take_damage(dmg)
			total_heal += dmg * lifesteal_pct
	if total_heal > 0.0:
		_player.health = minf(_player.health + total_heal, _player.max_health)
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
		draw_circle(local, 10.0, Color(0.8, 0.1, 0.1, 1))
		draw_circle(local, 6.0, Color(1, 0.4, 0.6, 1))
	for ex in _explosions:
		var local: Vector2 = to_local(ex.pos)
		var t: float = ex.timer / EXPLOSION_FLASH_TIME
		draw_circle(local, explosion_radius, Color(0.9, 0.1, 0.2, t * 0.4))
		draw_arc(local, explosion_radius, 0.0, TAU, 32, Color(1, 0.3, 0.5, t), 3.0)
		draw_circle(local, explosion_radius * 0.45, Color(1, 0.6, 0.7, t * 0.7))
