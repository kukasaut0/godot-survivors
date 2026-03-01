extends RefCounted
class_name EvolutionOffer

var weapon_name: String = ""
var level: int = 0
var max_level: int = 1
var _evolved_id: String = ""
var _parent_a: WeaponBase = null
var _parent_b: WeaponBase = null
var _player: Node = null

func init(name: String, evolved_id: String, parent_a: WeaponBase, parent_b: WeaponBase, player: Node) -> EvolutionOffer:
	weapon_name = name
	_evolved_id = evolved_id
	_parent_a = parent_a
	_parent_b = parent_b
	_player = player
	return self

func is_acquired() -> bool:
	return false

func can_upgrade() -> bool:
	return true

func get_next_upgrade_description() -> String:
	return "EVOLUTION: Replaces %s + %s with ultimate form!" % [_parent_a.weapon_name, _parent_b.weapon_name]

func upgrade() -> void:
	_player.weapons.erase(_parent_a)
	_parent_a.queue_free()
	_player.weapons.erase(_parent_b)
	_parent_b.queue_free()
	var evolved: WeaponBase = WeaponRegistry.create_weapon(_evolved_id)
	if evolved == null:
		return
	_player.add_weapon(evolved)
	evolved.upgrade()
