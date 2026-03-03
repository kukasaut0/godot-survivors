extends Node2D
class_name WeaponBase

signal upgraded(weapon: WeaponBase)

var weapon_name: String = ""
var weapon_description: String = ""
var max_level: int = 8
var level: int = 1

var _player: Node2D = null
var _projectiles_container: Node = null
var _in_player: bool = false

func setup(player: Node2D, proj_container: Node) -> void:
	_player = player
	_projectiles_container = proj_container
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

func is_maxed() -> bool:
	return level >= max_level

func is_acquired() -> bool:
	return _in_player

func can_upgrade() -> bool:
	return not is_maxed()
