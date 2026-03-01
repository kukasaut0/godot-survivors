extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Scholar Tome"
	weapon_description = "Increases XP gained."

func _on_upgrade() -> void:
	_player.xp_multiplier += 0.2

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+20%% XP gain (level %d → %d)" % [level, level + 1]
