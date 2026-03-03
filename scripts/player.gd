extends CharacterBody2D

signal died
signal level_up(current_level: int)

var speed: float = 300.0

var max_health: float = 100.0
var health: float = 100.0
var _health_per_level: float = 20.0
var level: int = 1
var xp: int = 0
var xp_to_next: int = 240

var projectiles_container: Node = null
var weapons: Array[WeaponBase] = []
var passives: Array = []
var boost_velocity: Vector2 = Vector2.ZERO

var damage_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var xp_multiplier: float = 1.0
var xp_collect_radius: float = 60.0
var xp_magnet_radius: float = 200.0

var armor: float = 0.0
var damage_reduction: float = 0.0
var lifesteal: float = 0.0
var revival_hp_percent: float = 0.0
var _revival_used: bool = false

var _main_node: Node = null

func apply_character_data(data: CharacterData) -> void:
	speed = data.speed
	max_health = data.max_health
	health = data.max_health
	_health_per_level = data.health_per_level
	$Sprite2D.modulate = data.modulate_color
	$Sprite2D.scale = data.sprite_scale

func add_weapon(w: WeaponBase) -> void:
	weapons.append(w)
	add_child(w)
	w.setup(self, projectiles_container)

func add_passive(item: PassiveItem) -> void:
	passives.append(item)
	add_child(item)
	item.setup_passive(self)

func _physics_process(_delta: float) -> void:
	if boost_velocity.length() > 0:
		velocity = boost_velocity
	else:
		var dir := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		velocity = dir.normalized() * speed if dir.length() > 0 else Vector2.ZERO
	move_and_slide()

func take_damage(amount: float) -> void:
	var reduced := amount * (1.0 - damage_reduction)
	var actual := maxf(reduced - armor, 1.0)
	health = clampf(health - actual, 0.0, max_health)
	if _main_node != null:
		_main_node.trigger_screen_shake(8.0, 0.2)
	if health <= 0.0:
		if not _revival_used and revival_hp_percent > 0.0:
			_revival_used = true
			health = max_health * revival_hp_percent
			if _main_node != null:
				_main_node.trigger_screen_shake(12.0, 0.4)
			return
		died.emit()
		set_physics_process(false)

func on_damage_dealt(amount: float) -> void:
	if lifesteal > 0.0:
		var heal := amount * lifesteal
		health = minf(health + heal, max_health)

func collect_xp(amount: int) -> void:
	xp += int(ceil(float(amount) * xp_multiplier))
	if xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()

func _level_up() -> void:
	level += 1
	xp_to_next = int(240.0 * pow(1.15, level - 1))
	max_health += _health_per_level
	health = minf(health + _health_per_level, max_health)
	level_up.emit(level)
