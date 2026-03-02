extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Iron Shield"
	weapon_description = "Reduces incoming damage by a flat amount."

func _on_upgrade() -> void:
	_player.armor += 3.0

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "+3 armor (level %d → %d)" % [level, level + 1]
