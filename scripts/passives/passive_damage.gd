extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Power Shard"
	weapon_description = "Increases all damage dealt."

func _on_upgrade() -> void:
	_player.damage_multiplier += 0.1

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+10%% damage multiplier (level %d → %d)" % [level, level + 1]
