extends PassiveItem

func _on_setup() -> void:
	weapon_name = "Watch Shard"
	weapon_description = "Reduces all weapon cooldowns."

func _on_upgrade() -> void:
	var old_mult: float = _player.cooldown_multiplier
	var new_mult: float = maxf(old_mult - 0.08, 0.4)
	if new_mult == old_mult:
		return
	var ratio: float = new_mult / old_mult
	_player.cooldown_multiplier = new_mult
	for w in _player.weapons:
		if "shoot_cooldown" in w:
			w.shoot_cooldown = maxf(w.shoot_cooldown * ratio, 0.15)
		elif "tick_interval" in w:
			w.tick_interval = maxf(w.tick_interval * ratio, 0.1)
		elif "strike_interval" in w:
			w.strike_interval = maxf(w.strike_interval * ratio, 0.5)
		elif "fire_interval" in w:
			w.fire_interval = maxf(w.fire_interval * ratio, 0.5)

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return "-8%% weapon cooldowns (level %d → %d)" % [level, level + 1]
