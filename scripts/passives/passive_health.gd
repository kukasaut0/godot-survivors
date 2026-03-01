extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Heart Vessel"
	weapon_description = "Increases maximum health."

func _on_upgrade() -> void:
	_player.max_health += 30.0
	_player.health += 30.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+30 max health (level %d → %d)" % [level, level + 1]
