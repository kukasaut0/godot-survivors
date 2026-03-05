extends WeaponBase
class_name GravitonRing

var damage: float = 50.0
var orbit_radius: float = 180.0
var orbit_speed: float = 3.5
var blade_count: int = 4
var pull_force: float = 150.0
var pull_radius: float = 280.0
var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}

const HIT_COOLDOWN: float = 0.2
const HIT_RADIUS_SQ: float = 1600.0  # 40px

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Orbiting blades that pull enemies in (4 blades, 50 dmg, 180 radius)",
	"Blades: 5, Damage: 70, Pull: stronger",
	"Blades: 6, Damage: 95, Radius: 220",
	"Max: 8 blades, 130 dmg, 270 radius, powerful pull",
]

func _on_setup() -> void:
	weapon_name = "Graviton Ring"
	weapon_description = "Orbiting blades that pull enemies toward you before striking."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2:
			blade_count = 5
			damage = 70.0
			pull_force = 220.0
		3:
			blade_count = 6
			damage = 95.0
			orbit_radius = 220.0
			pull_radius = 350.0
			pull_force = 300.0
		4:
			blade_count = 8
			damage = 130.0
			orbit_radius = 270.0
			pull_radius = 440.0
			pull_force = 420.0
			orbit_speed = 4.5
	queue_redraw()

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _physics_process(delta: float) -> void:
	_angle += orbit_speed * delta

	# Clear expired hit cooldowns
	var expired: Array = []
	for key in _hit_cooldowns:
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			expired.append(key)
	for key in expired:
		_hit_cooldowns.erase(key)

	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var pull_rad_sq := pull_radius * pull_radius

	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var enemy_node := e as Node2D
		if enemy_node == null:
			continue
		var to_player: Vector2 = _player.global_position - enemy_node.global_position
		var dist_sq := to_player.length_squared()
		# Pull enemies within pull_radius toward player
		if dist_sq <= pull_rad_sq and dist_sq > 1.0:
			e.apply_knockback(to_player.normalized() * pull_force * delta)

	# Blade hits
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var blade_pos: Vector2 = _player.global_position + Vector2(cos(blade_angle), sin(blade_angle)) * orbit_radius
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var eid := e.get_instance_id()
			if _hit_cooldowns.has(eid):
				continue
			if blade_pos.distance_squared_to((e as Node2D).global_position) < HIT_RADIUS_SQ:
				e.take_damage(damage * dmg_mult)
				_hit_cooldowns[eid] = HIT_COOLDOWN

	queue_redraw()

func _draw() -> void:
	# Draw pull radius
	draw_circle(Vector2.ZERO, pull_radius, Color(0.4, 0.1, 0.9, 0.04))
	draw_arc(Vector2.ZERO, pull_radius, 0.0, TAU, 64, Color(0.5, 0.2, 1.0, 0.25), 1.5)
	# Draw blades
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var local_pos: Vector2 = Vector2(cos(blade_angle), sin(blade_angle)) * orbit_radius
		draw_circle(local_pos, 10.0, Color(0.5, 0.1, 0.9, 0.9))
		draw_circle(local_pos, 6.0, Color(0.8, 0.5, 1.0, 1.0))
