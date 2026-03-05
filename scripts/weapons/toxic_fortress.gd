extends WeaponBase
class_name ToxicFortress

var damage_per_tick: float = 44.0
var zone_radius: float = 120.0
var zone_duration: float = 10.0
var drop_cooldown: float = 1.5
var max_zones: int = 6
var tick_interval: float = 0.4
var _drop_timer: float = 0.0
var _zones: Array = []  # Array of {pos: Vector2, timer: float, tick_timer: float}

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Massive persistent damage zones (40 dmg, 120 radius, 10s, 6 zones)",
	"Damage: 55, Max zones: 7",
	"Radius: 150, Cooldown: 1.2s, Damage: 75",
	"Max: 100 dmg, 190 radius, 0.8s CD, 0.25s tick, 9 zones",
]

func _on_setup() -> void:
	weapon_name = "Toxic Fortress"
	weapon_description = "Drops massive long-lasting damage zones that melt enemies."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2:
			damage_per_tick = 60.5
			max_zones = 7
		3:
			zone_radius = 150.0
			drop_cooldown = 1.2
			damage_per_tick = 82.5
		4:
			damage_per_tick = 110.0
			zone_radius = 190.0
			drop_cooldown = 0.8
			tick_interval = 0.25
			max_zones = 9

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _physics_process(delta: float) -> void:
	for i in range(_zones.size() - 1, -1, -1):
		_zones[i].timer -= delta
		_zones[i].tick_timer -= delta
		if _zones[i].timer <= 0.0:
			_zones.remove_at(i)
		elif _zones[i].tick_timer <= 0.0:
			_zones[i].tick_timer = tick_interval
			_damage_enemies_in_zone(_zones[i].pos)

	_drop_timer -= delta
	if _drop_timer <= 0.0:
		_drop_timer = drop_cooldown
		if _zones.size() >= max_zones:
			_zones.remove_at(0)
		_zones.append({
			"pos": _player.global_position,
			"timer": zone_duration,
			"tick_timer": 0.0,
		})

	queue_redraw()

func _damage_enemies_in_zone(zone_pos: Vector2) -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var rad_sq := zone_radius * zone_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if zone_pos.distance_squared_to((e as Node2D).global_position) <= rad_sq:
			e.take_damage(damage_per_tick * dmg_mult)

func _draw() -> void:
	for zone in _zones:
		var local_pos: Vector2 = to_local(zone.pos)
		var alpha: float = clampf(zone.timer / zone_duration, 0.1, 0.6)
		draw_circle(local_pos, zone_radius, Color(0.1, 0.6, 0.1, alpha * 0.35))
		draw_arc(local_pos, zone_radius, 0.0, TAU, 48, Color(0.2, 0.9, 0.2, alpha), 2.0)
