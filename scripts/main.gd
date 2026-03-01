extends Node2D

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")
var health_pickup_scene: PackedScene = preload("res://scenes/health_pickup.tscn")

@export var character_data: CharacterData
@export var level_data: LevelData

@onready var player: CharacterBody2D = $Player
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var projectiles_container: Node2D = $ProjectilesContainer
@onready var gems_container: Node2D = $GemsContainer
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var weapon_select_ui = $WeaponSelectUI
@onready var pause_menu = $PauseMenu

var time_elapsed: float = 0.0
var spawn_timer: float = 0.0
var is_game_over: bool = false
var max_enemies: int = 500
var total_kills: int = 0
var total_damage_dealt: float = 0.0

var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0

var _boss_spawn_times: Array[float] = [300.0, 600.0, 900.0]
var _boss_data: EnemyData = null

func _ready() -> void:
	if GameState.selected_character_data != null:
		character_data = GameState.selected_character_data
	if character_data == null:
		character_data = load("res://data/characters/default.tres")
	if level_data == null:
		level_data = load("res://data/levels/default.tres")
	_boss_data = load("res://data/enemies/boss.tres")
	player.projectiles_container = projectiles_container
	player._main_node = self
	player.apply_character_data(character_data)
	player.died.connect(_on_player_died)
	player.level_up.connect(_on_level_up)
	weapon_select_ui.item_chosen.connect(_on_item_chosen)
	_setup_weapons()
	_init_passive_pool()

func _setup_weapons() -> void:
	for entry in character_data.starting_weapons:
		var weapon := WeaponRegistry.create_weapon(entry.weapon_id)
		if weapon == null:
			continue
		player.add_weapon(weapon)
		for i in entry.starting_level:
			weapon.upgrade()

func _init_passive_pool() -> void:
	var passive_scripts: Array = [
		load("res://scripts/passives/passive_speed.gd"),
		load("res://scripts/passives/passive_damage.gd"),
		load("res://scripts/passives/passive_health.gd"),
		load("res://scripts/passives/passive_xp.gd"),
		load("res://scripts/passives/passive_cooldown.gd"),
		load("res://scripts/passives/passive_magnet.gd"),
	]
	for scr in passive_scripts:
		var item: PassiveItem = scr.new()
		player.add_passive(item)

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_elapsed += delta

	# Screen shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		camera.global_position = player.global_position + Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity))
	else:
		camera.global_position = player.global_position

	# Boss spawns
	for i in range(_boss_spawn_times.size() - 1, -1, -1):
		if time_elapsed >= _boss_spawn_times[i]:
			_boss_spawn_times.remove_at(i)
			_spawn_boss()

	# Regular spawns
	spawn_timer -= delta
	var spawn_interval := maxf(
		level_data.initial_spawn_interval - (time_elapsed / 30.0) * level_data.interval_decay_per_30s,
		level_data.min_spawn_interval
	)
	if spawn_timer <= 0.0:
		var count := level_data.spawn_count_base + int(time_elapsed / 30.0) * level_data.spawn_count_per_30s
		for i in count:
			if enemies_container.get_child_count() < max_enemies:
				_spawn_enemy()
		spawn_timer = spawn_interval

	hud.update_hud(player, time_elapsed, total_kills)

func trigger_screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration

func _spawn_enemy() -> void:
	var angle := randf() * TAU
	var dist := randf_range(level_data.spawn_distance_min, level_data.spawn_distance_max)
	var enemy := enemy_scene.instantiate() as Enemy
	enemies_container.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	enemy.setup(player)
	enemy.apply_enemy_data(_pick_enemy_data(), time_elapsed)
	if randf() < 0.10:
		enemy.make_elite()
	enemy.died_at.connect(_on_enemy_died_at)
	enemy.damage_taken.connect(func(amount: float) -> void: total_damage_dealt += amount)

func _spawn_boss() -> void:
	if _boss_data == null:
		return
	hud.show_boss_warning()
	var angle := randf() * TAU
	var dist := randf_range(level_data.spawn_distance_min, level_data.spawn_distance_max)
	var enemy := enemy_scene.instantiate() as Enemy
	enemies_container.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	enemy.setup(player)
	enemy.apply_enemy_data(_boss_data, time_elapsed)
	enemy.died_at.connect(_on_enemy_died_at)
	enemy.damage_taken.connect(func(amount: float) -> void: total_damage_dealt += amount)

func _pick_enemy_data() -> EnemyData:
	for i in range(level_data.waves.size() - 1, -1, -1):
		var wave: EnemySpawnWave = level_data.waves[i]
		if time_elapsed >= wave.start_time and time_elapsed < wave.end_time:
			return _weighted_pick(wave.spawn_entries)
	return load("res://data/enemies/normal.tres")

func _weighted_pick(entries: Array) -> EnemyData:
	var total := 0.0
	for e in entries:
		total += e.weight
	var r := randf() * total
	for e in entries:
		r -= e.weight
		if r <= 0.0:
			return e.enemy_data
	return entries[-1].enemy_data

func _on_enemy_died_at(pos: Vector2, xp_value: int) -> void:
	total_kills += 1
	var gem: Area2D = xp_gem_scene.instantiate()
	gems_container.add_child(gem)
	gem.global_position = pos
	gem.setup(xp_value, player)
	if randf() < 0.05:
		var pickup: Area2D = health_pickup_scene.instantiate()
		gems_container.add_child(pickup)
		pickup.global_position = pos
		pickup.setup(player)

func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	_check_persistent_unlocks()
	var names: Array = player.weapons.map(func(w) -> String: return w.weapon_name)
	hud.show_game_over(time_elapsed, player.level, total_kills, total_damage_dealt, names)

func _check_persistent_unlocks() -> void:
	if time_elapsed >= 300.0:
		GameState.set_unlock("char_speeder_hero", true)
		GameState.set_unlock("char_tank_hero", true)

func _on_level_up(_lvl: int) -> void:
	var options: Array = []
	for w in player.weapons:
		if w.can_upgrade():
			options.append(w)
	for p in player.passives:
		if p.can_upgrade():
			options.append(p)
	var evolutions := _check_evolutions()
	options.append_array(evolutions)
	if options.is_empty():
		return
	options.shuffle()
	options = options.slice(0, mini(3, options.size()))
	get_tree().paused = true
	weapon_select_ui.show_options(options)

func _check_evolutions() -> Array:
	var result: Array = []
	var weapon_map: Dictionary = {}
	for w in player.weapons:
		weapon_map[w.get_script()] = w
	# VoidOrb: magic_bolt (ProjectileWeapon) + holy_onion (AuraWeapon)
	var has_pb := weapon_map.has(ProjectileWeapon)
	var has_aw := weapon_map.has(AuraWeapon)
	if has_pb and has_aw:
		var pb: WeaponBase = weapon_map[ProjectileWeapon]
		var aw: WeaponBase = weapon_map[AuraWeapon]
		if pb.is_maxed() and aw.is_maxed():
			var already_evolved: bool = player.weapons.any(func(w) -> bool: return w is VoidOrb)
			if not already_evolved:
				result.append(EvolutionOffer.new().init("Void Orb", "void_orb", pb, aw, player))
	# StormTempest: thunder_strike (ThunderStrike) + knife_fan (KnifeFan)
	var has_ts := weapon_map.has(ThunderStrike)
	var has_kf := weapon_map.has(KnifeFan)
	if has_ts and has_kf:
		var ts: WeaponBase = weapon_map[ThunderStrike]
		var kf: WeaponBase = weapon_map[KnifeFan]
		if ts.is_maxed() and kf.is_maxed():
			var already_evolved: bool = player.weapons.any(func(w) -> bool: return w is StormTempest)
			if not already_evolved:
				result.append(EvolutionOffer.new().init("Storm Tempest", "storm_tempest", ts, kf, player))
	return result

func _on_item_chosen(item) -> void:
	item.upgrade()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_game_over:
			return
		if weapon_select_ui.visible:
			return
		if get_tree().paused:
			pause_menu.hide_menu()
			get_tree().paused = false
		else:
			get_tree().paused = true
			pause_menu.show_menu()
