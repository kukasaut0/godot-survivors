extends WeaponBase
class_name Boomerang

var damage: float = 12.0
var orbit_radius: float = 100.0
var orbit_speed: float = 3.0
var blade_count: int = 1
var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}

const HIT_COOLDOWN: float = 0.3

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Orbiting blade damages enemies (1 blade, 15 dmg, 100 radius)",
	"Blades: 2",
	"Damage: 22, Radius: 120",
	"Speed: 4 rad/s",
	"Blades: 3, Damage: 30",
	"Radius: 150",
	"Blades: 4, Speed: 4.5 rad/s",
	"Max: 5 blades, 45 dmg, 180 radius, 5 rad/s",
]

func _on_setup() -> void:
	weapon_name = "Boomerang"
	weapon_description = "Blades orbit around you, hitting nearby enemies."

func _on_upgrade() -> void:
	match level:
		2:
			blade_count = 2
		3:
			damage = 17.6
			orbit_radius = 120.0
		4:
			orbit_speed = 4.0
		5:
			blade_count = 3
			damage = 24.0
		6:
			orbit_radius = 150.0
		7:
			blade_count = 4
			orbit_speed = 4.5
		8:
			blade_count = 5
			damage = 36.0
			orbit_radius = 180.0
			orbit_speed = 5.0
	queue_redraw()

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

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
			if blade_pos.distance_squared_to(e.global_position) < 900.0:  # ~30px radius
				e.take_damage(damage * dmg_mult)
				_hit_cooldowns[eid] = HIT_COOLDOWN

	queue_redraw()

func _draw() -> void:
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var local_pos: Vector2 = Vector2(cos(blade_angle), sin(blade_angle)) * orbit_radius
		draw_circle(local_pos, 8.0, Color(0.8, 0.8, 0.2, 0.9))
		draw_circle(local_pos, 5.0, Color(1, 1, 0.5, 1))
