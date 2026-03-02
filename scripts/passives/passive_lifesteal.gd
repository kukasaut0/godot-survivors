extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Vampiric Fang"
	weapon_description = "Heal a percentage of damage dealt."

func _on_upgrade() -> void:
	_player.lifesteal += 0.01

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+1%% life steal (level %d → %d)" % [level, level + 1]
