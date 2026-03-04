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
var _hud_timer: float = 0.0

var _boss_spawn_times: Array[float] = []
var _boss_data: EnemyData = null

# Weapon discovery pool
const MAX_WEAPONS := 4
const ALL_WEAPON_IDS: Array[String] = ["magic_bolt", "holy_onion", "thunder_strike", "knife_fan", "boomerang", "spike_strip"]
var _weapon_pool: Array[String] = []
var _pending_new_weapons: Array = []
var _pending_weapon_ids: Dictionary = {}  # WeaponBase → weapon_id string

# Combo system
var _combo_count: int = 0
var _combo_timer: float = 0.0
const COMBO_WINDOW: float = 2.0

# Surge system
var _surge_times: Array[float] = []
var _surge_active: float = 0.0
const SURGE_DURATION: float = 10.0
const SURGE_INTERVAL: float = 180.0

# Health drop chance (modified by meta upgrades)
var _health_drop_chance: float = 0.01
var _elite_chance: float = 0.10

func _ready() -> void:
	if GameState.selected_character_data != null:
		character_data = GameState.selected_character_data
	if GameState.selected_level_data != null:
		level_data = GameState.selected_level_data
	if character_data == null:
		character_data = load("res://data/characters/default.tres")
	if level_data == null:
		level_data = load("res://data/levels/default.tres")

	# Load stage-specific data
	_boss_spawn_times = level_data.boss_spawn_times.duplicate()
	_boss_data = load(level_data.boss_data_path) as EnemyData
	_elite_chance = level_data.elite_chance
	_health_drop_chance = level_data.health_drop_chance
	RenderingServer.set_default_clear_color(level_data.background_color)

	# Build surge times
	var t := SURGE_INTERVAL
	while t < level_data.win_time - 30.0:
		_surge_times.append(t)
		t += SURGE_INTERVAL

	player.projectiles_container = projectiles_container
	player._main_node = self
	player.apply_character_data(character_data)
	_apply_meta_upgrades()
	player.died.connect(_on_player_died)
	player.level_up.connect(_on_level_up)
	weapon_select_ui.item_chosen.connect(_on_item_chosen)
	pause_menu.cash_out_requested.connect(_on_cash_out)
	_setup_weapons()
	_init_passive_pool()
	_build_weapon_pool()

func _setup_weapons() -> void:
	for entry in character_data.starting_weapons:
		if entry.starting_level < 1:
			continue
		var weapon := WeaponRegistry.create_weapon(entry.weapon_id)
		if weapon == null:
			continue
		player.add_weapon(weapon)
		for i in entry.starting_level - 1:
			weapon.upgrade()

func _init_passive_pool() -> void:
	var passive_scripts: Array = [
		load("res://scripts/passives/passive_speed.gd"),
		load("res://scripts/passives/passive_damage.gd"),
		load("res://scripts/passives/passive_health.gd"),
		load("res://scripts/passives/passive_xp.gd"),
		load("res://scripts/passives/passive_cooldown.gd"),
		load("res://scripts/passives/passive_magnet.gd"),
		load("res://scripts/passives/passive_armor.gd"),
		load("res://scripts/passives/passive_lifesteal.gd"),
	]
	for scr in passive_scripts:
		var item: PassiveItem = scr.new()
		player.add_passive(item)

func _build_weapon_pool() -> void:
	var owned_ids: Array[String] = []
	for entry in character_data.starting_weapons:
		if entry.starting_level >= 1:
			owned_ids.append(entry.weapon_id)
	_weapon_pool.clear()
	for wid in ALL_WEAPON_IDS:
		if wid not in owned_ids:
			_weapon_pool.append(wid)

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_elapsed += delta

	if time_elapsed >= level_data.win_time:
		_on_run_complete()
		return

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

	# Surge events
	for i in range(_surge_times.size() - 1, -1, -1):
		if time_elapsed >= _surge_times[i]:
			_surge_times.remove_at(i)
			_surge_active = SURGE_DURATION
			hud.show_surge_warning()

	if _surge_active > 0.0:
		_surge_active -= delta

	# Combo timer
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
			hud.hide_combo()

	# Non-linear spawn scaling
	var spawn_interval := _compute_spawn_interval()
	if _surge_active > 0.0:
		spawn_interval /= 3.0

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var count := mini(level_data.spawn_count_base + int(time_elapsed / 30.0) * level_data.spawn_count_per_30s, level_data.max_spawn_count)
		if _surge_active > 0.0:
			count = mini(count * 2, level_data.max_spawn_count * 2)
		for i in count:
			if enemies_container.get_child_count() < max_enemies:
				_spawn_enemy()
		spawn_timer = spawn_interval

	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.1
		hud.update_hud(player, time_elapsed, total_kills, total_damage_dealt, level_data.display_name)

func _compute_spawn_interval() -> float:
	# Piecewise non-linear spawn scaling
	var base := level_data.initial_spawn_interval
	var result: float
	if time_elapsed < 120.0:
		# Gentle ramp (learning phase)
		result = base - (time_elapsed / 120.0) * (base * 0.2)
	elif time_elapsed < 480.0:
		# Steady increase (core gameplay)
		var progress := (time_elapsed - 120.0) / 360.0
		result = base * 0.8 - progress * (base * 0.4)
	else:
		# Aggressive ramp (endgame)
		var progress := minf((time_elapsed - 480.0) / 420.0, 1.0)
		result = base * 0.4 - progress * (base * 0.25)
	return maxf(result, level_data.min_spawn_interval)

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
	enemy.apply_enemy_data(_pick_enemy_data(), time_elapsed, player.level)
	if randf() < _elite_chance:
		enemy.make_elite()
	enemy.died_at.connect(_on_enemy_died_at)
	enemy.damage_taken.connect(func(amount: float) -> void:
		total_damage_dealt += amount
		player.on_damage_dealt(amount))

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
	enemy.damage_taken.connect(func(amount: float) -> void:
		total_damage_dealt += amount
		player.on_damage_dealt(amount))

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

	# Combo system
	_combo_count += 1
	_combo_timer = COMBO_WINDOW
	var xp_bonus: float = 1.0
	if _combo_count >= 50:
		xp_bonus = 1.10
		hud.show_combo(_combo_count, "ULTRA!")
	elif _combo_count >= 25:
		xp_bonus = 1.08
		hud.show_combo(_combo_count, "MEGA!")
	elif _combo_count >= 10:
		xp_bonus = 1.05
		hud.show_combo(_combo_count, "COMBO x%d!" % _combo_count)

	var gem: Area2D = xp_gem_scene.instantiate()
	gems_container.add_child(gem)
	gem.global_position = pos
	gem.setup(int(xp_value * xp_bonus), player)
	if randf() < _health_drop_chance:
		var pickup: Area2D = health_pickup_scene.instantiate()
		gems_container.add_child(pickup)
		pickup.global_position = pos
		pickup.setup(player)

func _apply_meta_upgrades() -> void:
	var vital_tier := GameState.get_upgrade_level("vital_core")
	var speed_tier := GameState.get_upgrade_level("quick_feet")
	var dmg_tier := GameState.get_upgrade_level("power_core")
	var cd_tier := GameState.get_upgrade_level("accelerator")
	var xp_tier := GameState.get_upgrade_level("scholar")
	var lucky_tier := GameState.get_upgrade_level("lucky")
	var armor_tier := GameState.get_upgrade_level("armor")
	var revival_tier := GameState.get_upgrade_level("revival")
	if vital_tier > 0:
		player.max_health *= (1.0 + 0.10 * vital_tier)
		player.health = player.max_health
	if speed_tier > 0:
		player.speed *= (1.0 + 0.05 * speed_tier)
	if dmg_tier > 0:
		player.damage_multiplier *= (1.0 + 0.05 * dmg_tier)
	if cd_tier > 0:
		player.cooldown_multiplier = maxf(player.cooldown_multiplier * (1.0 - 0.05 * cd_tier), 0.15)
	if xp_tier > 0:
		player.xp_multiplier *= (1.0 + 0.10 * xp_tier)
	if lucky_tier > 0:
		_health_drop_chance += 0.03 * lucky_tier
	if armor_tier > 0:
		player.damage_reduction = 0.05 * armor_tier
	if revival_tier > 0:
		var percents := [0.3, 0.4, 0.5, 0.6, 0.75]
		player.revival_hp_percent = percents[mini(revival_tier - 1, percents.size() - 1)]

func _on_cash_out() -> void:
	_check_persistent_unlocks()
	var souls_earned := int((int(time_elapsed / 60.0) * 10 + total_kills) * level_data.soul_multiplier)
	GameState.add_souls(souls_earned)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_run_complete() -> void:
	is_game_over = true
	get_tree().paused = true
	_check_persistent_unlocks()
	# Mark stage clear
	match level_data.id:
		"default":
			GameState.set_unlock("stage_fields_clear", true)
		"crypt":
			GameState.set_unlock("stage_crypt_clear", true)
		"abyss":
			GameState.set_unlock("stage_abyss_clear", true)
	var souls_earned := int((int(time_elapsed / 60.0) * 10 + total_kills) * level_data.soul_multiplier)
	GameState.add_souls(souls_earned)
	hud.show_victory(time_elapsed, player, total_kills, total_damage_dealt, souls_earned)

func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	_check_persistent_unlocks()
	var souls_earned := int((int(time_elapsed / 60.0) * 10 + total_kills) * level_data.soul_multiplier)
	GameState.add_souls(souls_earned)
	hud.show_game_over(time_elapsed, player, total_kills, total_damage_dealt, souls_earned)

func _check_persistent_unlocks() -> void:
	# Speedster: Kill 500 enemies in a single run
	if total_kills >= 500:
		GameState.set_unlock("char_speeder_hero", true)
	# Tank: Survive 10 minutes
	if time_elapsed >= 600.0:
		GameState.set_unlock("char_tank_hero", true)
	# Mage: Reach level 20
	if player.level >= 20:
		GameState.set_unlock("char_mage", true)

func _on_level_up(_lvl: int) -> void:
	# --- Owned upgradeable weapons + evolutions (shuffled) ---
	var owned_upgradeable: Array = []
	for w in player.weapons:
		if w.can_upgrade():
			owned_upgradeable.append(w)
	owned_upgradeable.append_array(_check_evolutions())
	owned_upgradeable.append_array(_check_passive_evolutions())
	owned_upgradeable.shuffle()

	# --- New weapons from pool (up to 2) ---
	var new_slots: int = MAX_WEAPONS - player.weapons.size() - _pending_new_weapons.size()
	_weapon_pool.shuffle()
	var new_weapons: Array = []
	var pool_i := 0
	while new_weapons.size() < 2 and new_slots > 0 and pool_i < _weapon_pool.size():
		var wid: String = _weapon_pool[pool_i]
		var w := WeaponRegistry.create_weapon(wid)
		if w != null:
			w.setup(player, projectiles_container)
			_pending_new_weapons.append(w)
			_pending_weapon_ids[w] = wid
			new_weapons.append(w)
			new_slots -= 1
		pool_i += 1
	# Remove IDs from pool now; unchosen ones are returned in _on_item_chosen
	for w in _pending_new_weapons:
		_weapon_pool.erase(_pending_weapon_ids[w])

	# --- Weapon slot 1: 60% existing upgrade, 40% new from pool ---
	var weapon_options: Array = []
	var slot1_is_existing := not owned_upgradeable.is_empty() and randf() < 0.6
	if slot1_is_existing:
		weapon_options.append(owned_upgradeable.pop_back())
	elif not new_weapons.is_empty():
		weapon_options.append(new_weapons.pop_back())
	elif not owned_upgradeable.is_empty():
		weapon_options.append(owned_upgradeable.pop_back())

	# --- Weapon slot 2: random, equal chance between owned and new ---
	var slot2_pool: Array = owned_upgradeable + new_weapons
	slot2_pool.shuffle()
	for w in slot2_pool:
		if w not in weapon_options:
			weapon_options.append(w)
			break

	# --- 2 passive slots ---
	var passive_candidates: Array = []
	for p in player.passives:
		if p.can_upgrade():
			passive_candidates.append(p)
	passive_candidates.shuffle()
	var passive_options: Array = passive_candidates.slice(0, mini(2, passive_candidates.size()))

	var options: Array = weapon_options + passive_options
	if options.is_empty():
		return
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

func _check_passive_evolutions() -> Array:
	var result: Array = []
	var weapon_map: Dictionary = {}
	for w in player.weapons:
		weapon_map[w.get_script()] = w
	# Build map of maxed passives by name
	var passive_map: Dictionary = {}
	for p in player.passives:
		if p.is_maxed():
			passive_map[p.weapon_name] = p

	# Nova Bolt: magic_bolt (ProjectileWeapon) + Watch Shard
	if weapon_map.has(ProjectileWeapon) and passive_map.has("Watch Shard"):
		var w: WeaponBase = weapon_map[ProjectileWeapon]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is NovaBolt):
			result.append(PassiveEvolutionOffer.new().init("Nova Bolt", "nova_bolt", w, passive_map["Watch Shard"], player))

	# Sacred Mantle: holy_onion (AuraWeapon) + Heart Vessel
	if weapon_map.has(AuraWeapon) and passive_map.has("Heart Vessel"):
		var w: WeaponBase = weapon_map[AuraWeapon]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is SacredMantle):
			result.append(PassiveEvolutionOffer.new().init("Sacred Mantle", "sacred_mantle", w, passive_map["Heart Vessel"], player))

	# Thunderlord: thunder_strike (ThunderStrike) + Power Shard
	if weapon_map.has(ThunderStrike) and passive_map.has("Power Shard"):
		var w: WeaponBase = weapon_map[ThunderStrike]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is Thunderlord):
			result.append(PassiveEvolutionOffer.new().init("Thunderlord", "thunderlord", w, passive_map["Power Shard"], player))

	# Cyclone Blades: knife_fan (KnifeFan) + Boots
	if weapon_map.has(KnifeFan) and passive_map.has("Boots"):
		var w: WeaponBase = weapon_map[KnifeFan]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is CycloneBlades):
			result.append(PassiveEvolutionOffer.new().init("Cyclone Blades", "cyclone_blades", w, passive_map["Boots"], player))

	# Graviton Ring: boomerang (Boomerang) + Magnet
	if weapon_map.has(Boomerang) and passive_map.has("Magnet"):
		var w: WeaponBase = weapon_map[Boomerang]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is GravitonRing):
			result.append(PassiveEvolutionOffer.new().init("Graviton Ring", "graviton_ring", w, passive_map["Magnet"], player))

	# Toxic Fortress: spike_strip (SpikeStrip) + Iron Shield
	if weapon_map.has(SpikeStrip) and passive_map.has("Iron Shield"):
		var w: WeaponBase = weapon_map[SpikeStrip]
		if w.is_maxed() and not player.weapons.any(func(x) -> bool: return x is ToxicFortress):
			result.append(PassiveEvolutionOffer.new().init("Toxic Fortress", "toxic_fortress", w, passive_map["Iron Shield"], player))

	return result

func _on_item_chosen(item) -> void:
	var is_new_weapon: bool = item is WeaponBase and item not in player.weapons
	if is_new_weapon:
		player.add_weapon(item)
		_pending_new_weapons.erase(item)
		_pending_weapon_ids.erase(item)
	for w in _pending_new_weapons:
		if _pending_weapon_ids.has(w):
			_weapon_pool.append(_pending_weapon_ids[w])
			_pending_weapon_ids.erase(w)
		w.queue_free()
	_pending_new_weapons.clear()
	if not is_new_weapon:
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
