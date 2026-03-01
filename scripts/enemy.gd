extends CharacterBody2D
class_name Enemy

enum Type { NORMAL, SPEEDER, BRUTE }

signal died_at(pos: Vector2, xp_value: int)

var speed: float = 80.0
var health: float = 30.0
var damage: float = 10.0
var xp_value: int = 10
var contact_dist: float = 30.0
var _player: Node2D = null
var _damage_timer: float = 0.0
var _reposition_threshold_sq: float = 0.0
var _normal_modulate: Color = Color(1, 0.5, 0.2)

const DAMAGE_COOLDOWN: float = 1.0

func _ready() -> void:
	add_to_group("enemies")
	var vp_size := get_viewport().get_visible_rect().size
	var threshold: float = vp_size.length() * 2.0
	_reposition_threshold_sq = threshold * threshold

func setup(player_ref: Node2D) -> void:
	_player = player_ref

func setup_type(type: Type, time_elapsed: float) -> void:
	match type:
		Type.SPEEDER:
			speed = 160.0 + time_elapsed * 0.8
			health = 15.0
			damage = 8.0
			xp_value = 5
			_normal_modulate = Color(1.0, 0.9, 0.1)
			$Sprite2D.modulate = _normal_modulate
			$Sprite2D.scale = Vector2(0.25, 0.25)
			$CollisionShape2D.scale = Vector2(0.6, 0.6)
		Type.BRUTE:
			speed = 45.0 + time_elapsed * 0.2
			health = 200.0
			damage = 25.0
			xp_value = 30
			contact_dist = 50.0
			_normal_modulate = Color(0.8, 0.15, 0.15)
			$Sprite2D.modulate = _normal_modulate
			$Sprite2D.scale = Vector2(0.7, 0.7)
			$CollisionShape2D.scale = Vector2(1.75, 1.75)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	velocity = (_player.global_position - global_position).normalized() * speed
	move_and_slide()
	_damage_timer -= delta
	if _damage_timer <= 0.0 and global_position.distance_to(_player.global_position) < contact_dist:
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
	$Sprite2D.modulate = Color(1.0, 0.4, 0.4)
	if health <= 0.0:
		died_at.emit(global_position, xp_value)
		queue_free()
	else:
		get_tree().create_timer(0.1).timeout.connect(
			func() -> void: if is_instance_valid(self): $Sprite2D.modulate = _normal_modulate
		)
