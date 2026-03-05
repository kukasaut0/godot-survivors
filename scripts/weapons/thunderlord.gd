extends WeaponBase
class_name Thunderlord

var damage: float = 110.0
var aoe_damage: float = 66.0
var aoe_radius: float = 80.0
var target_count: int = 8
var strike_interval: float = 1.8
var _timer: float = 0.0
var _lightning_targets: Array[Vector2] = []

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Lightning strikes each target with an AoE explosion (8 targets, 100+60 dmg, 1.8s)",
	"Targets: 10, Damage: 150+90",
	"Targets: 12, Damage: 200+120, Interval: 1.4s",
	"Max: 16 targets, 280+180 dmg, 1.0s",
]

func _on_setup() -> void:
	weapon_name = "Thunderlord"
	weapon_description = "Strikes multiple enemies with lightning, each causing an AoE explosion."
	max_level = 4

func _on_upgrade() -> void:
	match level:
		2:
			target_count = 10
			damage = 165.0
			aoe_damage = 99.0
		3:
			target_count = 12
			damage = 220.0
			aoe_damage = 132.0
			strike_interval = 1.4
		4:
			target_count = 16
			damage = 308.0
			aoe_damage = 198.0
			aoe_radius = 110.0
			strike_interval = 1.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	for pos in _lightning_targets:
		draw_line(Vector2.ZERO, pos, Color(1.0, 0.85, 0.1, 0.95), 3.0)
		draw_circle(pos, 10.0, Color(1.0, 1.0, 0.4, 0.95))
		draw_circle(pos, aoe_radius, Color(1.0, 0.7, 0.0, 0.15))

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = strike_interval
		_strike()

func _strike() -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	var candidates: Array[Enemy] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and is_instance_valid(enemy):
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return _player.global_position.distance_squared_to(a.global_position) < \
			_player.global_position.distance_squared_to(b.global_position))
	_lightning_targets.clear()
	var hit_positions: Array[Vector2] = []
	for i in mini(target_count, candidates.size()):
		var target := candidates[i]
		target.take_damage(damage * dmg_mult)
		_lightning_targets.append(to_local(target.global_position))
		hit_positions.append(target.global_position)
	# AoE explosion at each hit position
	var rad_sq := aoe_radius * aoe_radius
	for hit_pos in hit_positions:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			if hit_pos.distance_squared_to((e as Node2D).global_position) <= rad_sq:
				e.take_damage(aoe_damage * dmg_mult)
	if not _lightning_targets.is_empty():
		queue_redraw()
		get_tree().create_timer(0.15).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			_lightning_targets.clear()
			queue_redraw())
