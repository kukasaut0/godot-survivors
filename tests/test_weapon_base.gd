extends "res://tests/test_case.gd"
## Tests for WeaponBase level/upgrade logic (scripts/weapons/weapon_base.gd)

const _WeaponBase = preload("res://scripts/weapons/weapon_base.gd")

func test_initial_level_is_zero() -> void:
	var w = _WeaponBase.new()
	assert_eq(w.level, 0)
	w.free()

func test_not_acquired_at_start() -> void:
	var w = _WeaponBase.new()
	assert_false(w.is_acquired())
	w.free()

func test_not_maxed_at_start() -> void:
	var w = _WeaponBase.new()
	assert_false(w.is_maxed())
	w.free()

func test_can_upgrade_at_start() -> void:
	var w = _WeaponBase.new()
	assert_true(w.can_upgrade())
	w.free()

func test_upgrade_increments_level() -> void:
	var w = _WeaponBase.new()
	w.upgrade()
	assert_eq(w.level, 1)
	w.upgrade()
	assert_eq(w.level, 2)
	w.free()

func test_acquired_after_first_upgrade() -> void:
	var w = _WeaponBase.new()
	w.upgrade()
	assert_true(w.is_acquired())
	w.free()

func test_default_max_level_is_eight() -> void:
	var w = _WeaponBase.new()
	assert_eq(w.max_level, 8)
	w.free()

func test_maxed_at_max_level() -> void:
	var w = _WeaponBase.new()
	for i in w.max_level:
		w.upgrade()
	assert_true(w.is_maxed())
	assert_eq(w.level, 8)
	w.free()

func test_not_maxed_one_below_max_level() -> void:
	var w = _WeaponBase.new()
	for i in w.max_level - 1:
		w.upgrade()
	assert_false(w.is_maxed())
	assert_true(w.can_upgrade())
	w.free()

func test_cannot_upgrade_when_maxed() -> void:
	var w = _WeaponBase.new()
	w.level = w.max_level
	assert_false(w.can_upgrade())
	w.free()

func test_upgrade_emits_signal() -> void:
	var w = _WeaponBase.new()
	var received := [null]  # array so lambda can capture by reference
	w.upgraded.connect(func(weapon): received[0] = weapon)
	w.upgrade()
	assert_eq(received[0], w, "upgraded signal should pass the weapon instance")
	w.free()

func test_custom_max_level() -> void:
	var w = _WeaponBase.new()
	w.max_level = 3
	w.upgrade()
	w.upgrade()
	assert_false(w.is_maxed())
	w.upgrade()
	assert_true(w.is_maxed())
	w.free()

func test_is_acquired_false_at_level_zero() -> void:
	var w = _WeaponBase.new()
	w.level = 0
	assert_false(w.is_acquired())
	w.free()

func test_is_acquired_true_at_level_one() -> void:
	var w = _WeaponBase.new()
	w.level = 1
	assert_true(w.is_acquired())
	w.free()
