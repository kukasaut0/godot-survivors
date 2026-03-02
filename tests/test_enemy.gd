extends "res://tests/test_case.gd"
## Tests for Enemy stat application and combat (scripts/enemy.gd)

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const _EnemyData   = preload("res://scripts/data/enemy_data.gd")

func _make_data(base_speed: float = 80.0, hp: float = 30.0, dmg: float = 10.0):
	var d = _EnemyData.new()
	d.base_speed = base_speed
	d.speed_time_scale = 1.0
	d.health = hp
	d.damage = dmg
	d.xp_value = 10
	d.contact_dist = 30.0
	d.modulate_color = Color.WHITE
	d.sprite_scale = Vector2(0.4, 0.4)
	d.collision_scale = Vector2(1.0, 1.0)
	return d

func _make_enemy():
	var enemy = ENEMY_SCENE.instantiate()
	enemy.set_physics_process(false)
	_root.add_child(enemy)
	return enemy

# --- apply_enemy_data speed formula ---

func test_speed_at_time_zero_equals_base_speed() -> void:
	var e = _make_enemy()
	var d = _make_data(80.0)
	d.speed_time_scale = 2.0
	e.apply_enemy_data(d, 0.0)
	assert_approx_eq(e.speed, 80.0, 0.001, "speed = base_speed + 0 * scale")
	e.queue_free()

func test_speed_increases_with_time() -> void:
	var e = _make_enemy()
	var d = _make_data(80.0)
	d.speed_time_scale = 2.0
	e.apply_enemy_data(d, 10.0)
	# speed = 80 + 10 * 2 = 100
	assert_approx_eq(e.speed, 100.0, 0.001)
	e.queue_free()

func test_speed_scale_of_zero_keeps_base_speed() -> void:
	var e = _make_enemy()
	var d = _make_data(60.0)
	d.speed_time_scale = 0.0
	e.apply_enemy_data(d, 999.0)
	assert_approx_eq(e.speed, 60.0, 0.001, "zero scale should not increase speed over time")
	e.queue_free()

func test_apply_data_sets_health() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 50.0), 0.0)
	assert_approx_eq(e.health, 50.0)
	e.queue_free()

func test_apply_data_sets_damage() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 30.0, 15.0), 0.0)
	assert_approx_eq(e.damage, 15.0)
	e.queue_free()

func test_apply_data_sets_xp_value() -> void:
	var e = _make_enemy()
	var d = _make_data()
	d.xp_value = 25
	e.apply_enemy_data(d, 0.0)
	assert_eq(e.xp_value, 25)
	e.queue_free()

func test_apply_data_sets_contact_dist() -> void:
	var e = _make_enemy()
	var d = _make_data()
	d.contact_dist = 45.0
	e.apply_enemy_data(d, 0.0)
	assert_approx_eq(e.contact_dist, 45.0)
	e.queue_free()

# --- make_elite multipliers ---

func test_make_elite_triples_health() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 30.0), 0.0)
	e.make_elite()
	assert_approx_eq(e.health, 90.0, 0.001, "elite health = 30 * 3")
	e.queue_free()

func test_make_elite_multiplies_speed_by_1_5() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0), 0.0)
	e.make_elite()
	assert_approx_eq(e.speed, 120.0, 0.001, "elite speed = 80 * 1.5")
	e.queue_free()

func test_make_elite_multiplies_damage_by_1_5() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 30.0, 10.0), 0.0)
	e.make_elite()
	assert_approx_eq(e.damage, 15.0, 0.001, "elite damage = 10 * 1.5")
	e.queue_free()

func test_make_elite_triples_xp_value() -> void:
	var e = _make_enemy()
	var d = _make_data()
	d.xp_value = 10
	e.apply_enemy_data(d, 0.0)
	e.make_elite()
	assert_eq(e.xp_value, 30, "elite xp_value = 10 * 3")
	e.queue_free()

# --- take_damage ---

func test_take_damage_reduces_health() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 100.0), 0.0)
	e.take_damage(30.0)
	assert_approx_eq(e.health, 70.0)
	e.queue_free()

func test_take_damage_emits_signal_with_amount() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 100.0), 0.0)
	var received := [0.0]  # array so lambda can capture by reference
	e.damage_taken.connect(func(amt): received[0] = amt)
	e.take_damage(30.0)
	assert_approx_eq(received[0], 30.0, 0.001)
	e.queue_free()

func test_take_damage_signal_clamped_to_remaining_health() -> void:
	# damage_taken emits min(amount, health) — the actual HP lost
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 30.0), 0.0)
	var received := [0.0]  # array so lambda can capture by reference
	e.damage_taken.connect(func(amt): received[0] = amt)
	e.take_damage(100.0)  # more than health
	assert_approx_eq(received[0], 30.0, 0.001, "signal should emit actual damage, capped at health")
	# enemy is queue_freed internally after lethal hit

func test_death_emits_died_at_signal() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 30.0), 0.0)
	var died := [false]  # array so lambda can capture by reference
	e.died_at.connect(func(_pos, _xp): died[0] = true)
	e.take_damage(30.0)
	assert_true(died[0], "died_at signal should fire when health reaches zero")

func test_death_signal_passes_xp_value() -> void:
	var e = _make_enemy()
	var d = _make_data(80.0, 30.0)
	d.xp_value = 15
	e.apply_enemy_data(d, 0.0)
	var got_xp := [0]  # array so lambda can capture by reference
	e.died_at.connect(func(_pos, xp): got_xp[0] = xp)
	e.take_damage(30.0)
	assert_eq(got_xp[0], 15, "died_at signal should pass the correct xp_value")

func test_no_death_signal_on_non_lethal_hit() -> void:
	var e = _make_enemy()
	e.apply_enemy_data(_make_data(80.0, 100.0), 0.0)
	var died := [false]  # array so lambda can capture by reference
	e.died_at.connect(func(_pos, _xp): died[0] = true)
	e.take_damage(50.0)
	assert_false(died[0], "died_at must not fire for non-lethal hits")
	e.queue_free()
