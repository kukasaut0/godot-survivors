extends WeaponBase
class_name CycloneDash

var orbit_damage: float = 40.0
var orbit_radius: float = 150.0
var orbit_speed: float = 5.0
var blade_count: int = 5
var dash_cooldown: float = 3.0
var boost_speed: float = 800.0
var boost_duration: float = 0.35

var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}
var _dash_timer: float = 0.0
var _boost_time: float = 0.0
var _last_dir: Vector2 = Vector2.DOWN
var _is_dashing: bool = false

const HIT_COOLDOWN: float = 0.2

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Orbital blades + dash (combined Boomerang + Jump)",
	"Power: 56 dmg, 6 blades, faster orbit",
	"Range: 200 radius, dash 900 speed",
	"Max: 70 dmg, 7 blades, 250 radius, 2s cooldown",
]

func _on_setup() -> void:
	weapon_name = "Cyclone Dash"
	weapon_description = "Orbiting blades that triple in power while dashing."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		1:
			orbit_damage = 40.0
			orbit_radius = 150.0
			orbit_speed = 5.0
			blade_count = 5
			dash_cooldown = 3.0
			boost_speed = 800.0
		2:
			orbit_damage = 56.0
			blade_count = 6
			orbit_speed = 6.0
		3:
			orbit_radius = 200.0
			boost_speed = 900.0
		4:
			orbit_damage = 70.0
			blade_count = 7
			orbit_radius = 250.0
			dash_cooldown = 2.0
	queue_redraw()

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	if level == 0:
		return

	_dash_timer -= delta
	_boost_time -= delta

	# Track movement direction
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if dir.length() > 0:
		_last_dir = dir.normalized()

	# Dash input
	if Input.is_action_just_pressed("jump") and _dash_timer <= 0.0:
		_dash_timer = dash_cooldown
		_boost_time = boost_duration
		_is_dashing = true
		if _player:
			_player.boost_velocity = _last_dir * boost_speed

	# Update dash state
	if _boost_time > 0.0 and _player:
		_player.boost_velocity = _last_dir * boost_speed
	elif _is_dashing:
		_is_dashing = false
		if _player:
			_player.boost_velocity = Vector2.ZERO

	# Orbit
	_angle += orbit_speed * delta

	# Clear expired hit cooldowns
	var expired: Array = []
	for key in _hit_cooldowns:
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			expired.append(key)
	for key in expired:
		_hit_cooldowns.erase(key)

	# During dash: triple radius, double damage
	var current_radius := orbit_radius * (3.0 if _is_dashing else 1.0)
	var current_damage := orbit_damage * (2.0 if _is_dashing else 1.0)

	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var blade_pos: Vector2 = _player.global_position + Vector2(cos(blade_angle), sin(blade_angle)) * current_radius
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var eid := e.get_instance_id()
			if _hit_cooldowns.has(eid):
				continue
			if blade_pos.distance_squared_to(e.global_position) < 1225.0:  # ~35px radius
				e.take_damage(current_damage * dmg_mult)
				_hit_cooldowns[eid] = HIT_COOLDOWN

	queue_redraw()

func _draw() -> void:
	if level == 0:
		return
	var current_radius := orbit_radius * (3.0 if _is_dashing else 1.0)
	var color := Color(0.3, 1, 1, 0.9) if _is_dashing else Color(0.6, 0.8, 1, 0.9)
	for i in blade_count:
		var blade_angle: float = _angle + (TAU / float(blade_count)) * float(i)
		var local_pos: Vector2 = Vector2(cos(blade_angle), sin(blade_angle)) * current_radius
		draw_circle(local_pos, 10.0, color)
		draw_circle(local_pos, 6.0, Color(1, 1, 1, 0.9))
	# Draw orbit ring
	var ring_alpha := 0.3 if not _is_dashing else 0.5
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, ring_alpha), 1.5)
