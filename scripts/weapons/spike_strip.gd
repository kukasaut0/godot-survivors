extends WeaponBase
class_name SpikeStrip

var damage_per_tick: float = 6.4
var zone_radius: float = 60.0
var zone_duration: float = 4.0
var drop_cooldown: float = 3.0
var max_zones: int = 3
var _drop_timer: float = 0.0
var _zones: Array = []  # Array of {pos: Vector2, timer: float}

const TICK_INTERVAL: float = 0.5

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Drops damage zones at your position (8 dmg, 60 radius, 4s)",
	"Damage: 11, Max zones: 4",
	"Radius: 75, Cooldown: 2.5s",
	"Duration: 5s, Damage: 15",
	"Max zones: 5, Radius: 85",
	"Cooldown: 2s, Damage: 19",
	"Duration: 5.5s, Max zones: 5",
	"Max: 24 dmg, 100 radius, 6s, 1.5s CD, 6 zones",
]

func _on_setup() -> void:
	weapon_name = "Spike Strip"
	weapon_description = "Drops damage zones that hurt enemies walking through."

func _on_upgrade() -> void:
	match level:
		2:
			damage_per_tick = 8.8
			max_zones = 4
		3:
			zone_radius = 75.0
			drop_cooldown = 2.5
		4:
			zone_duration = 5.0
			damage_per_tick = 12.0
		5:
			max_zones = 5
			zone_radius = 85.0
		6:
			drop_cooldown = 2.0
			damage_per_tick = 15.2
		7:
			zone_duration = 5.5
			max_zones = 5
		8:
			damage_per_tick = 19.2
			zone_radius = 100.0
			zone_duration = 6.0
			drop_cooldown = 1.5
			max_zones = 6

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	# Update zones
	for i in range(_zones.size() - 1, -1, -1):
		_zones[i].timer -= delta
		_zones[i].tick_timer -= delta
		if _zones[i].timer <= 0.0:
			_zones.remove_at(i)
		elif _zones[i].tick_timer <= 0.0:
			_zones[i].tick_timer = TICK_INTERVAL
			_damage_enemies_in_zone(_zones[i].pos)

	# Drop new zones
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
		if zone_pos.distance_squared_to(e.global_position) <= rad_sq:
			e.take_damage(damage_per_tick * dmg_mult)

func _draw() -> void:
	for zone in _zones:
		var local_pos: Vector2 = to_local(zone.pos)
		var alpha: float = clampf(zone.timer / zone_duration, 0.1, 0.5)
		draw_circle(local_pos, zone_radius, Color(0.8, 0.2, 0.2, alpha * 0.3))
		draw_arc(local_pos, zone_radius, 0.0, TAU, 32, Color(0.8, 0.3, 0.3, alpha), 1.5)
