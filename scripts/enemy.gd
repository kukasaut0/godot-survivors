extends CharacterBody2D

signal died_at(pos: Vector2, xp_value: int)

var speed: float = 80.0
var health: float = 30.0
var damage: float = 10.0
var xp_value: int = 10
var _player: Node2D = null
var _damage_timer: float = 0.0
var _reposition_threshold_sq: float = 0.0

const DAMAGE_COOLDOWN: float = 1.0
const CONTACT_DIST: float = 30.0

func _ready() -> void:
	add_to_group("enemies")
	var vp_size := get_viewport().get_visible_rect().size
	var threshold: float = vp_size.length() * 2.0
	_reposition_threshold_sq = threshold * threshold

func setup(player_ref: Node2D) -> void:
	_player = player_ref

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	velocity = (_player.global_position - global_position).normalized() * speed
	move_and_slide()
	_damage_timer -= delta
	if _damage_timer <= 0.0 and global_position.distance_to(_player.global_position) < CONTACT_DIST:
		_player.take_damage(damage)
		_damage_timer = DAMAGE_COOLDOWN
	if global_position.distance_squared_to(_player.global_position) > _reposition_threshold_sq:
		_reposition()

func _reposition() -> void:
	var away: Vector2 = (global_position - _player.global_position).normalized()
	var angle: float = atan2(-away.y, -away.x) + randf_range(-0.4, 0.4)
	var dist: float = randf_range(400.0, 600.0)
	global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist

func take_damage(amount: float) -> void:
	health -= amount
	modulate = Color(1.0, 0.3, 0.3)
	if health <= 0.0:
		died_at.emit(global_position, xp_value)
		queue_free()
	else:
		get_tree().create_timer(0.1).timeout.connect(
			func(): if is_instance_valid(self): modulate = Color(1, 0.5, 0.2)
		)
