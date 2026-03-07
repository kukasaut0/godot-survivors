extends WeaponBase
class_name ThunderStrike

var damage: float = 150.0
var target_count: int = 1
var strike_interval: float = 3.0
var _timer: float = 0.0
var _lightning_targets: Array[Vector2] = []

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Zaps the nearest enemy (dmg 150, 3s)",
	"Damage 200",
	"Targets: 2",
	"Interval: 2.5s",
	"Damage 250, Targets: 3",
	"Damage 280, Interval: 2s",
	"Targets: 4, Damage 310, Interval: 1.5s",
	"Max: 5 targets, dmg 350, 1s",
]

func _on_setup() -> void:
	weapon_name = "Thunder Strike"
	weapon_description = "Periodically zaps the nearest enemies."

func _on_upgrade() -> void:
	match level:
		2:
			damage = 200.0
		3:
			target_count = 2
		4:
			strike_interval = 2.5
		5:
			damage = 250.0
			target_count = 3
		6:
			damage = 280.0
			strike_interval = 2.0
		7:
			target_count = 4
			damage = 310.0
			strike_interval = 1.5
		8:
			target_count = 5
			damage = 350.0
			strike_interval = 1.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	for pos in _lightning_targets:
		draw_line(Vector2.ZERO, pos, Color(0.7, 0.85, 1.0, 0.9), 2.0)
		draw_circle(pos, 6.0, Color(1.0, 1.0, 1.0, 0.9))

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
		var da := _player.global_position.distance_squared_to(a.global_position)
		var db := _player.global_position.distance_squared_to(b.global_position)
		return da < db)
	_lightning_targets.clear()
	for i in mini(target_count, candidates.size()):
		candidates[i].take_damage_from(damage * dmg_mult, "thunder_strike")
		_lightning_targets.append(to_local(candidates[i].global_position))
	if not _lightning_targets.is_empty():
		queue_redraw()
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			_lightning_targets.clear()
			queue_redraw())
