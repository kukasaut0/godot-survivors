extends WeaponBase
class_name Boomerang

var damage: float = 24.0
var orbit_radius: float = 100.0
var orbit_speed: float = 3.5
var blade_count: int = 1
var knockback_force: float = 150.0
var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}

const HIT_COOLDOWN: float = 0.25
const HIT_RADIUS_SQ: float = 1600.0  # 40px

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Orbiting blade with knockback (1 blade, 24 dmg, 100 radius)",
	"Blades: 2",
	"Damage: 36, Radius: 120",
	"Speed: 4 rad/s",
	"Blades: 3, Damage: 48, Knockback +50",
	"Radius: 150",
	"Blades: 4, Speed: 4.5 rad/s",
	"Max: 5 blades, 72 dmg, 180 radius, 5 rad/s",
]

func _on_setup() -> void:
	weapon_name = "Boomerang"
	weapon_description = "Blades orbit around you, hitting nearby enemies."

func _on_upgrade() -> void:
	match level:
		2:
			blade_count = 2
		3:
			damage = 36.0
			orbit_radius = 120.0
		4:
			orbit_speed = 4.0
		5:
			blade_count = 3
			damage = 48.0
			knockback_force = 200.0
		6:
			orbit_radius = 150.0
		7:
			blade_count = 4
			orbit_speed = 4.5
		8:
			blade_count = 5
			damage = 72.0
			orbit_radius = 180.0
			orbit_speed = 5.0
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

	# Check enemy hits for each blade position
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var blade_pos: Vector2 = _player.global_position + Vector2(cos(blade_angle), sin(blade_angle)) * orbit_radius
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var eid := e.get_instance_id()
			if _hit_cooldowns.has(eid):
				continue
			if blade_pos.distance_squared_to(e.global_position) < HIT_RADIUS_SQ:
				e.take_damage(damage * dmg_mult)
				var push_dir: Vector2 = ((e as Node2D).global_position - _player.global_position).normalized()
				e.apply_knockback(push_dir * knockback_force)
				_hit_cooldowns[eid] = HIT_COOLDOWN

	queue_redraw()

func _draw() -> void:
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var local_pos: Vector2 = Vector2(cos(blade_angle), sin(blade_angle)) * orbit_radius
		draw_circle(local_pos, 8.0, Color(0.8, 0.8, 0.2, 0.9))
		draw_circle(local_pos, 5.0, Color(1, 1, 0.5, 1))
