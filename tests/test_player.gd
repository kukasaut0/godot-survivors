extends "res://tests/test_case.gd"
## Tests for Player health and XP/level-up logic (scripts/player.gd)

const PLAYER_SCENE = preload("res://scenes/player.tscn")

func _make_player():
	var player = PLAYER_SCENE.instantiate()
	player.set_physics_process(false)
	_root.add_child(player)
	return player

# --- Initial state ---

func test_initial_health() -> void:
	var p = _make_player()
	assert_approx_eq(p.health, 100.0)
	p.queue_free()

func test_initial_max_health() -> void:
	var p = _make_player()
	assert_approx_eq(p.max_health, 100.0)
	p.queue_free()

func test_initial_level() -> void:
	var p = _make_player()
	assert_eq(p.level, 1)
	p.queue_free()

func test_initial_xp_is_zero() -> void:
	var p = _make_player()
	assert_eq(p.xp, 0)
	p.queue_free()

func test_initial_xp_to_next() -> void:
	var p = _make_player()
	assert_eq(p.xp_to_next, 100)
	p.queue_free()

# --- Health / take_damage ---

func test_take_damage_reduces_health() -> void:
	var p = _make_player()
	p.take_damage(30.0)
	assert_approx_eq(p.health, 70.0)
	p.queue_free()

func test_take_damage_clamped_at_zero() -> void:
	var p = _make_player()
	p.take_damage(999.0)
	assert_approx_eq(p.health, 0.0, 0.001, "health must not go below zero")
	p.queue_free()

func test_take_damage_clamped_at_max_health() -> void:
	var p = _make_player()
	# Negative damage (would be healing); clamp keeps health <= max
	p.take_damage(-50.0)
	assert_approx_eq(p.health, 100.0, 0.001, "health must not exceed max_health")
	p.queue_free()

func test_multiple_damage_instances_accumulate() -> void:
	var p = _make_player()
	p.take_damage(20.0)
	p.take_damage(20.0)
	assert_approx_eq(p.health, 60.0)
	p.queue_free()

func test_died_signal_on_lethal_damage() -> void:
	var p = _make_player()
	var died := [false]  # array so lambda can capture by reference
	p.died.connect(func(): died[0] = true)
	p.take_damage(100.0)
	assert_true(died[0], "died signal should fire on lethal damage")
	p.queue_free()

func test_died_signal_not_on_non_lethal_damage() -> void:
	var p = _make_player()
	var died := [false]
	p.died.connect(func(): died[0] = true)
	p.take_damage(50.0)
	assert_false(died[0], "died signal must not fire for non-lethal damage")
	p.queue_free()

# --- XP collection ---

func test_collect_xp_accumulates() -> void:
	var p = _make_player()
	p.collect_xp(30)
	p.collect_xp(20)
	assert_eq(p.xp, 50)
	p.queue_free()

func test_collect_xp_no_level_up_below_threshold() -> void:
	var p = _make_player()
	p.collect_xp(99)
	assert_eq(p.level, 1, "no level-up below threshold")
	assert_eq(p.xp, 99)
	p.queue_free()

func test_collect_xp_applies_multiplier() -> void:
	var p = _make_player()
	p.xp_multiplier = 2.0
	p.collect_xp(25)
	# int(ceil(25 * 2.0)) = 50
	assert_eq(p.xp, 50)
	p.queue_free()

func test_collect_xp_applies_ceil_to_fractional_multiplier() -> void:
	var p = _make_player()
	p.xp_multiplier = 1.5
	p.collect_xp(3)
	# int(ceil(3 * 1.5)) = int(ceil(4.5)) = 5
	assert_eq(p.xp, 5)
	p.queue_free()

func test_collect_xp_multiplier_one_is_identity() -> void:
	var p = _make_player()
	p.xp_multiplier = 1.0
	p.collect_xp(42)
	assert_eq(p.xp, 42)
	p.queue_free()

# --- Level-up ---

func test_level_up_at_threshold() -> void:
	var p = _make_player()
	p.collect_xp(100)
	assert_eq(p.level, 2)
	p.queue_free()

func test_level_up_signal_emitted() -> void:
	var p = _make_player()
	var leveled_to := [0]  # array so lambda can capture by reference
	p.level_up.connect(func(lvl): leveled_to[0] = lvl)
	p.collect_xp(100)
	assert_eq(leveled_to[0], 2, "level_up signal should pass the new level")
	p.queue_free()

func test_level_up_xp_to_next_scales_linearly() -> void:
	var p = _make_player()
	assert_eq(p.xp_to_next, 100)
	p.collect_xp(100)
	# level = 2, xp_to_next = 2 * 100 = 200
	assert_eq(p.xp_to_next, 200)
	p.queue_free()

func test_level_up_increases_max_health() -> void:
	var p = _make_player()
	var old_max: float = p.max_health
	p.collect_xp(100)
	assert_approx_eq(p.max_health, old_max + 20.0, 0.001, "max_health should increase by 20 per level")
	p.queue_free()

func test_level_up_heals_player_by_health_per_level() -> void:
	var p = _make_player()
	p.take_damage(50.0)   # health = 50
	p.collect_xp(100)     # level-up: max_health=120, health = min(50+20, 120) = 70
	assert_approx_eq(p.health, 70.0, 0.001)
	p.queue_free()

func test_level_up_does_not_overheal_beyond_new_max() -> void:
	var p = _make_player()
	# Health is full (100). After level-up max_health=120, health = min(120, 120) = 120
	p.collect_xp(100)
	assert_approx_eq(p.health, p.max_health, 0.001, "health should equal new max_health")
	p.queue_free()

func test_xp_carries_over_after_level_up() -> void:
	var p = _make_player()
	p.collect_xp(110)  # 110 >= 100 → level up, carry over 10
	assert_eq(p.xp, 10, "excess XP should carry over to next level")
	p.queue_free()

func test_single_collect_triggers_one_level_up() -> void:
	# 200 XP at level 1 (threshold 100): levels to 2 once, xp = 100
	var p = _make_player()
	p.collect_xp(200)
	assert_eq(p.level, 2, "single collect_xp only triggers one level-up")
	assert_eq(p.xp, 100)
	p.queue_free()
