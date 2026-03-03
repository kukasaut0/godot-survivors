extends Node

var selected_character_data: CharacterData = null
var selected_level_data: LevelData = null

const SAVE_PATH := "user://unlocks.cfg"
var _config := ConfigFile.new()

const UPGRADE_IDS: Array[String] = ["vital_core", "quick_feet", "power_core", "accelerator", "scholar", "lucky", "armor", "revival"]
const UPGRADE_MAX_TIER: int = 5
const UPGRADE_COSTS: Dictionary = {
	"vital_core":  [70, 140, 280, 560, 1120],
	"quick_feet":  [70, 140, 280, 560, 1120],
	"power_core":  [105, 210, 420, 840, 1680],
	"accelerator": [105, 210, 420, 840, 1680],
	"scholar":     [70, 140, 280, 560, 1120],
	"lucky":       [70, 140, 280, 560, 1120],
	"armor":       [105, 210, 420, 840, 1680],
	"revival":     [140, 280, 560, 1120, 2100],
}
const UPGRADE_NAMES: Dictionary = {
	"vital_core":  "Vital Core",
	"quick_feet":  "Quick Feet",
	"power_core":  "Power Core",
	"accelerator": "Accelerator",
	"scholar":     "Scholar",
	"lucky":       "Lucky Charm",
	"armor":       "Iron Skin",
	"revival":     "Second Wind",
}
const UPGRADE_DESCS: Dictionary = {
	"vital_core":  "+10% Max HP per tier",
	"quick_feet":  "+5% Speed per tier",
	"power_core":  "+5% Damage per tier",
	"accelerator": "-5% Cooldowns per tier",
	"scholar":     "+10% XP Gain per tier",
	"lucky":       "+3% Health Drop Chance per tier",
	"armor":       "-5% Damage Taken per tier",
	"revival":     "Revive once per run (30-75% HP)",
}

func _ready() -> void:
	_config.load(SAVE_PATH)

func get_unlock(key: String, default: bool = false) -> bool:
	return _config.get_value("unlocks", key, default)

func set_unlock(key: String, value: bool) -> void:
	_config.set_value("unlocks", key, value)
	_config.save(SAVE_PATH)

func get_souls() -> int:
	return _config.get_value("meta", "souls", 0)

func add_souls(amount: int) -> void:
	_config.set_value("meta", "souls", get_souls() + amount)
	_config.save(SAVE_PATH)

func spend_souls(amount: int) -> bool:
	var current := get_souls()
	if current < amount:
		return false
	_config.set_value("meta", "souls", current - amount)
	_config.save(SAVE_PATH)
	return true

func get_upgrade_level(id: String) -> int:
	return _config.get_value("meta", "upg_" + id, 0)

func set_upgrade_level(id: String, tier: int) -> void:
	_config.set_value("meta", "upg_" + id, tier)
	_config.save(SAVE_PATH)

func get_upgrade_cost(id: String) -> int:
	var tier := get_upgrade_level(id)
	if tier >= UPGRADE_MAX_TIER:
		return -1
	return UPGRADE_COSTS[id][tier]
