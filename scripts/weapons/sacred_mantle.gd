extends WeaponBase
class_name SacredMantle

var damage: float = 20.0
var radius: float = 350.0
var tick_interval: float = 0.4
var heal_per_tick: float = 8.0
var _tick_timer: float = 0.0

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Healing aura damages enemies and restores HP (350 radius, 20 dmg, +8 HP/tick)",
	"Radius: 420, Damage: 28, Heal: 12/tick",
	"Radius: 500, Damage: 38, Heal: 16/tick",
	"Max: 600 radius, 54 dmg, heal 24/tick, 0.3s tick",
]

func _on_setup() -> void:
	weapon_name = "Sacred Mantle"
	weapon_description = "A holy aura that damages enemies and heals you over time."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2:
			radius = 420.0
			damage = 28.0
			heal_per_tick = 12.0
		3:
			radius = 500.0
			damage = 38.0
			heal_per_tick = 16.0
		4:
			radius = 600.0
			damage = 54.0
			heal_per_tick = 24.0
			tick_interval = 0.3
	queue_redraw()

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.2, 0.06))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.9, 0.3, 0.6), 2.5)

func _physics_process(delta: float) -> void:
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_pulse()

func _pulse() -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if _player.global_position.distance_squared_to(e.global_position) <= radius * radius:
			e.take_damage(damage * dmg_mult)
			hit_any = true
	if hit_any and "health" in _player and "max_health" in _player:
		_player.health = minf(_player.health + heal_per_tick, _player.max_health)
