extends RefCounted
class_name PassiveEvolutionOffer

var weapon_name: String = ""
var level: int = 0
var max_level: int = 1
var _evolved_id: String = ""
var _parent_weapon: WeaponBase = null
var _parent_passive: PassiveItem = null
var _player: Node = null

func init(name: String, evolved_id: String, weapon: WeaponBase, passive: PassiveItem, player: Node) -> PassiveEvolutionOffer:
	weapon_name = name
	_evolved_id = evolved_id
	_parent_weapon = weapon
	_parent_passive = passive
	_player = player
	return self

func is_acquired() -> bool:
	return false

func can_upgrade() -> bool:
	return true

func get_next_upgrade_description() -> String:
	return "EVOLUTION: Fuses %s + %s into ultimate form!" % [_parent_weapon.weapon_name, _parent_passive.weapon_name]

func upgrade() -> void:
	_player.weapons.erase(_parent_weapon)
	_parent_weapon.queue_free()
	_player.passives.erase(_parent_passive)
	_parent_passive.queue_free()
	var evolved: WeaponBase = WeaponRegistry.create_weapon(_evolved_id)
	if evolved == null:
		return
	_player.add_weapon(evolved)
	evolved.upgrade()
