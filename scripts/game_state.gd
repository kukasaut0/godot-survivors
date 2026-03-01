extends Node

var selected_character_data: CharacterData = null

const SAVE_PATH := "user://unlocks.cfg"
var _config := ConfigFile.new()

func _ready() -> void:
	_config.load(SAVE_PATH)

func get_unlock(key: String, default: bool = false) -> bool:
	return _config.get_value("unlocks", key, default)

func set_unlock(key: String, value: bool) -> void:
	_config.set_value("unlocks", key, value)
	_config.save(SAVE_PATH)
