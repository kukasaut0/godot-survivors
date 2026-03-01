extends Node
class_name PassiveItem

signal upgraded(item: PassiveItem)

var weapon_name: String = ""
var weapon_description: String = ""
var level: int = 0
var max_level: int = 5
var _player: Node = null

func setup_passive(player: Node) -> void:
	_player = player
	_on_setup()

func upgrade() -> void:
	level += 1
	_on_upgrade()
	upgraded.emit(self)

func _on_setup() -> void:
	pass

func _on_upgrade() -> void:
	pass

func get_next_upgrade_description() -> String:
	return ""

func is_acquired() -> bool:
	return level > 0

func is_maxed() -> bool:
	return level >= max_level

func can_upgrade() -> bool:
	return not is_maxed()
