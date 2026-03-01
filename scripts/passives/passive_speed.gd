extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Boots"
	weapon_description = "Increases movement speed."

func _on_upgrade() -> void:
	_player.speed += 30.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+30 movement speed (level %d → %d)" % [level, level + 1]
