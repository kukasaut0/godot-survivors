extends WeaponBase
class_name AuraWeapon

var damage: float = 8.4
var radius: float = 120.0
var tick_interval: float = 0.5
var knockback_force: float = 0.0
var _tick_timer: float = 0.0

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Aura damages nearby enemies (dmg 8, radius 120, tick 0.5s)",
	"Damage 13, Radius 150",
	"Damage 18, Tick 0.40s",
	"Damage 24, Knockback",
	"Damage 30, Radius 190",
	"Damage 38, Tick 0.35s",
	"Damage 46",
	"Max Power: Damage 56, Radius 250, Tick 0.28s",
]

func _on_setup() -> void:
	weapon_name = "Holy Onion"
	weapon_description = "Pulses damage to nearby enemies."

func _on_upgrade() -> void:
	match level:
		2:
			damage = 13.0
			radius = 150.0
		3:
			damage = 18.0
			tick_interval = 0.40
		4:
			damage = 24.0
			knockback_force = 140.0
		5:
			damage = 30.0
			radius = 190.0
		6:
			damage = 38.0
			tick_interval = 0.35
		7:
			damage = 46.0
		8:
			damage = 56.0
			radius = 250.0
			tick_interval = 0.28
	queue_redraw()

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.3, 1, 0.3, 0.07))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.3, 1, 0.3, 0.5), 2.0)

func _physics_process(delta: float) -> void:
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
			e.take_damage_from(damage * dmg_mult, "holy_onion")
			if knockback_force > 0.0:
				var push_dir: Vector2 = ((e as Node2D).global_position - _player.global_position).normalized()
				e.apply_knockback(push_dir * knockback_force)
