extends WeaponBase
class_name AuraWeapon

var damage: float = 5.0
var radius: float = 120.0
var tick_interval: float = 0.5
var _tick_timer: float = 0.0

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Aura damages nearby enemies (dmg 5, radius 120, tick 0.5s)",
	"Range: Radius 160",
	"Power: Damage 8",
	"Speed: Tick 0.35s",
	"Range: Radius 200",
	"Power: Damage 14",
	"Speed: Tick 0.25s",
	"Max Power: Radius 260, Damage 20",
]

func _on_setup() -> void:
	weapon_name = "Holy Onion"
	weapon_description = "Pulses damage to nearby enemies."

func _on_upgrade() -> void:
	match level:
		1:
			damage = 5.0
			radius = 120.0
			tick_interval = 0.5
		2:
			radius = 160.0
		3:
			damage = 8.0
		4:
			tick_interval = 0.35
		5:
			radius = 200.0
		6:
			damage = 14.0
		7:
			tick_interval = 0.25
		8:
			radius = 260.0
			damage = 20.0
	queue_redraw()

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _draw() -> void:
	if level == 0:
		return
	draw_circle(Vector2.ZERO, radius, Color(0.3, 1, 0.3, 0.07))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.3, 1, 0.3, 0.5), 2.0)

func _physics_process(delta: float) -> void:
	if level == 0:
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_pulse()

func _pulse() -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if _player.global_position.distance_squared_to(e.global_position) <= radius * radius:
			e.take_damage(damage * dmg_mult)
