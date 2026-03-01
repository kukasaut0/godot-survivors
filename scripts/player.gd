extends CharacterBody2D

signal died
signal level_up(current_level: int)

var speed: float = 300.0

var max_health: float = 100.0
var health: float = 100.0
var _health_per_level: float = 20.0
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100

var projectiles_container: Node = null
var weapons: Array[WeaponBase] = []

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

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = dir.normalized() * speed if dir.length() > 0 else Vector2.ZERO
	move_and_slide()

func take_damage(amount: float) -> void:
	health = clampf(health - amount, 0.0, max_health)
	if health <= 0.0:
		died.emit()
		set_physics_process(false)

func collect_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()

func _level_up() -> void:
	level += 1
	xp_to_next = level * 100
	max_health += _health_per_level
	health = minf(health + _health_per_level, max_health)
	level_up.emit(level)
