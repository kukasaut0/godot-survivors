extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Magnet"
	weapon_description = "Increases XP gem collection radius."

func _on_upgrade() -> void:
	_player.xp_collect_radius += 30.0
	_player.xp_magnet_radius += 100.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+30 collect radius, +100 magnet radius (level %d → %d)" % [level, level + 1]
