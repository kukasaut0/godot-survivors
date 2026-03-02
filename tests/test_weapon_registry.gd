extends "res://tests/test_case.gd"
## Tests for WeaponRegistry factory (scripts/data/weapon_registry.gd)
## WeaponRegistry is an autoload not available in --script mode, so we instantiate it directly.

const _RegistryScript  = preload("res://scripts/data/weapon_registry.gd")
const _ProjWeapon      = preload("res://scripts/weapons/projectile_weapon.gd")
const _AuraWeapon      = preload("res://scripts/weapons/aura_weapon.gd")
const _ThunderStrike   = preload("res://scripts/weapons/thunder_strike.gd")
const _KnifeFan        = preload("res://scripts/weapons/knife_fan.gd")
const _Jump            = preload("res://scripts/weapons/jump.gd")
const _VoidOrb         = preload("res://scripts/weapons/void_orb.gd")
const _StormTempest    = preload("res://scripts/weapons/storm_tempest.gd")
const _Boomerang       = preload("res://scripts/weapons/boomerang.gd")
const _SpikeStrip      = preload("res://scripts/weapons/spike_strip.gd")
const _CycloneDash     = preload("res://scripts/weapons/cyclone_dash.gd")

var _registry  # lazily initialized

func _reg():
	if not _registry:
		_registry = _RegistryScript.new()
	return _registry

func test_magic_bolt_returns_projectile_weapon() -> void:
	var w = _reg().create_weapon("magic_bolt")
	assert_not_null(w)
	assert_eq(w.get_script(), _ProjWeapon, "magic_bolt should be ProjectileWeapon")
	w.free()

func test_holy_onion_returns_aura_weapon() -> void:
	var w = _reg().create_weapon("holy_onion")
	assert_not_null(w)
	assert_eq(w.get_script(), _AuraWeapon, "holy_onion should be AuraWeapon")
	w.free()

func test_thunder_strike_returns_thunder_strike() -> void:
	var w = _reg().create_weapon("thunder_strike")
	assert_not_null(w)
	assert_eq(w.get_script(), _ThunderStrike, "thunder_strike should be ThunderStrike")
	w.free()

func test_knife_fan_returns_knife_fan() -> void:
	var w = _reg().create_weapon("knife_fan")
	assert_not_null(w)
	assert_eq(w.get_script(), _KnifeFan, "knife_fan should be KnifeFan")
	w.free()

func test_jump_returns_jump() -> void:
	var w = _reg().create_weapon("jump")
	assert_not_null(w)
	assert_eq(w.get_script(), _Jump, "jump should be Jump")
	w.free()

func test_void_orb_returns_void_orb() -> void:
	var w = _reg().create_weapon("void_orb")
	assert_not_null(w)
	assert_eq(w.get_script(), _VoidOrb, "void_orb should be VoidOrb")
	w.free()

func test_storm_tempest_returns_storm_tempest() -> void:
	var w = _reg().create_weapon("storm_tempest")
	assert_not_null(w)
	assert_eq(w.get_script(), _StormTempest, "storm_tempest should be StormTempest")
	w.free()

func test_boomerang_returns_boomerang() -> void:
	var w = _reg().create_weapon("boomerang")
	assert_not_null(w)
	assert_eq(w.get_script(), _Boomerang, "boomerang should be Boomerang")
	w.free()

func test_spike_strip_returns_spike_strip() -> void:
	var w = _reg().create_weapon("spike_strip")
	assert_not_null(w)
	assert_eq(w.get_script(), _SpikeStrip, "spike_strip should be SpikeStrip")
	w.free()

func test_cyclone_dash_returns_cyclone_dash() -> void:
	var w = _reg().create_weapon("cyclone_dash")
	assert_not_null(w)
	assert_eq(w.get_script(), _CycloneDash, "cyclone_dash should be CycloneDash")
	w.free()

func test_unknown_id_returns_null() -> void:
	var w = _reg().create_weapon("does_not_exist")
	assert_null(w, "unknown weapon_id should return null")

func test_empty_id_returns_null() -> void:
	var w = _reg().create_weapon("")
	assert_null(w, "empty weapon_id should return null")

func test_all_known_ids_return_node() -> void:
	# WeaponBase extends Node2D, so all weapons should be Nodes
	var ids := ["magic_bolt", "holy_onion", "thunder_strike", "knife_fan", "jump", "void_orb", "storm_tempest", "boomerang", "spike_strip", "cyclone_dash"]
	for id in ids:
		var w = _reg().create_weapon(id)
		assert_true(w is Node, "%s should be a Node (WeaponBase extends Node2D)" % id)
		w.free()

func test_each_call_returns_new_instance() -> void:
	var a = _reg().create_weapon("magic_bolt")
	var b = _reg().create_weapon("magic_bolt")
	assert_true(a != b, "each create_weapon call should return a distinct instance")
	a.free()
	b.free()
