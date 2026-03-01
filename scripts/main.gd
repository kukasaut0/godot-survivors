extends Node2D

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")

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
	player.projectiles_container = projectiles_container
	player.died.connect(_on_player_died)
	player.level_up.connect(_on_level_up)
	weapon_select_ui.weapon_chosen.connect(_on_weapon_chosen)
	_setup_weapons()

func _setup_weapons() -> void:
	var proj_weapon := ProjectileWeapon.new()
	var aura_weapon := AuraWeapon.new()
	var thunder := ThunderStrike.new()
	var fan := KnifeFan.new()
	player.add_weapon(proj_weapon)
	player.add_weapon(aura_weapon)
	player.add_weapon(thunder)
	player.add_weapon(fan)
	proj_weapon.upgrade()

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_elapsed += delta
	camera.global_position = player.global_position
	spawn_timer -= delta
	var spawn_interval := maxf(1.5 - (time_elapsed / 30.0) * 0.1, 0.3)
	if spawn_timer <= 0.0:
		var count := 1 + int(time_elapsed / 30.0)
		for i in count:
			_spawn_enemy()
		spawn_timer = spawn_interval
	hud.update_hud(player, time_elapsed)

func _spawn_enemy() -> void:
	var angle := randf() * TAU
	var dist := randf_range(400.0, 600.0)
	var enemy := enemy_scene.instantiate() as Enemy
	enemies_container.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	enemy.speed = 80.0 + time_elapsed * 0.5
	enemy.setup(player)
	enemy.setup_type(_pick_enemy_type(), time_elapsed)
	enemy.died_at.connect(_on_enemy_died_at)

func _pick_enemy_type() -> Enemy.Type:
	if time_elapsed < 30.0:
		return Enemy.Type.NORMAL
	var r := randf()
	if time_elapsed < 90.0:
		return Enemy.Type.SPEEDER if r < 0.35 else Enemy.Type.NORMAL
	elif time_elapsed < 180.0:
		if r < 0.45:
			return Enemy.Type.NORMAL
		elif r < 0.80:
			return Enemy.Type.SPEEDER
		return Enemy.Type.BRUTE
	else:
		if r < 0.30:
			return Enemy.Type.NORMAL
		elif r < 0.60:
			return Enemy.Type.SPEEDER
		return Enemy.Type.BRUTE

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
