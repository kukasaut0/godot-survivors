extends PassiveItem

var regen_per_second: float = 0.0

func _on_setup() -> void:
	weapon_name = "Vital Stone"
	weapon_description = "Regenerates health over time."

func _on_upgrade() -> void:
	regen_per_second += 1.5

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+1.5 HP/s regeneration (level %d → %d)" % [level, level + 1]

func _process(delta: float) -> void:
	if _player == null or regen_per_second <= 0.0:
		return
	_player.health = minf(_player.health + regen_per_second * delta, _player.max_health)
