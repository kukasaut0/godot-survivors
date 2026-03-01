extends Node2D

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")

@export var character_data: CharacterData
@export var level_data: LevelData

@onready var player: CharacterBody2D = $Player
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var projectiles_container: Node2D = $ProjectilesContainer
@onready var gems_container: Node2D = $GemsContainer
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var weapon_select_ui = $WeaponSelectUI

var time_elapsed: float = 0.0
var spawn_timer: float = 0.0
var is_game_over: bool = false

func _ready() -> void:
	if character_data == null:
		character_data = load("res://data/characters/default.tres")
	if level_data == null:
		level_data = load("res://data/levels/default.tres")
	player.projectiles_container = projectiles_container
	player.apply_character_data(character_data)
	player.died.connect(_on_player_died)
	player.level_up.connect(_on_level_up)
	weapon_select_ui.weapon_chosen.connect(_on_weapon_chosen)
	_setup_weapons()

func _setup_weapons() -> void:
	for entry in character_data.starting_weapons:
		var weapon := WeaponRegistry.create_weapon(entry.weapon_id)
		if weapon == null:
			continue
		player.add_weapon(weapon)
		for i in entry.starting_level:
			weapon.upgrade()

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_elapsed += delta
	camera.global_position = player.global_position
	spawn_timer -= delta
	var spawn_interval := maxf(
		level_data.initial_spawn_interval - (time_elapsed / 30.0) * level_data.interval_decay_per_30s,
		level_data.min_spawn_interval
	)
	if spawn_timer <= 0.0:
		var count := level_data.spawn_count_base + int(time_elapsed / 30.0) * level_data.spawn_count_per_30s
		for i in count:
			_spawn_enemy()
		spawn_timer = spawn_interval
	hud.update_hud(player, time_elapsed)

func _spawn_enemy() -> void:
	var angle := randf() * TAU
	var dist := randf_range(level_data.spawn_distance_min, level_data.spawn_distance_max)
	var enemy := enemy_scene.instantiate() as Enemy
	enemies_container.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	enemy.setup(player)
	enemy.apply_enemy_data(_pick_enemy_data(), time_elapsed)
	enemy.died_at.connect(_on_enemy_died_at)

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
	var gem: Area2D = xp_gem_scene.instantiate()
	gems_container.add_child(gem)
	gem.global_position = pos
	gem.setup(xp_value, player)

func _on_player_died() -> void:
	is_game_over = true
	hud.show_game_over(time_elapsed, player.level)

func _on_level_up(_lvl: int) -> void:
	var options: Array[WeaponBase] = []
	for w in player.weapons:
		if w.can_upgrade():
			options.append(w)
	if options.is_empty():
		return
	get_tree().paused = true
	weapon_select_ui.show_options(options)

func _on_weapon_chosen(weapon: WeaponBase) -> void:
	weapon.upgrade()
	get_tree().paused = false
