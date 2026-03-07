extends WeaponBase
class_name SacredMantle

var damage: float = 75.0
var radius: float = 380.0
var tick_interval: float = 0.35
var heal_per_tick: float = 7.0
var _tick_timer: float = 0.0

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Healing aura damages enemies and restores HP (380 radius, 75 dmg, +7 HP/tick, 0.35s)",
	"Radius: 440, Damage: 100, Heal: 12/tick, Tick: 0.32s",
	"Radius: 520, Damage: 130, Heal: 18/tick, Tick: 0.28s",
	"Max: 620 radius, 170 dmg, heal 28/tick, 0.24s tick",
]

func _on_setup() -> void:
	weapon_name = "Sacred Mantle"
	weapon_description = "A holy aura that damages enemies and heals you over time."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2:
			radius = 440.0
			damage = 100.0
			heal_per_tick = 12.0
			tick_interval = 0.32
		3:
			radius = 520.0
			damage = 130.0
			heal_per_tick = 18.0
			tick_interval = 0.28
		4:
			radius = 620.0
			damage = 170.0
			heal_per_tick = 28.0
			tick_interval = 0.24
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
