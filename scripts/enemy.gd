extends CharacterBody2D
class_name Enemy

signal died_at(pos: Vector2, xp_value: int)
signal damage_taken(amount: float)

var speed: float = 80.0
var health: float = 30.0
var damage: float = 10.0
var xp_value: int = 10
var contact_dist: float = 30.0
var _player: Node2D = null
var _damage_timer: float = 0.0
var _reposition_threshold_sq: float = 0.0
var _normal_modulate: Color = Color(1, 0.5, 0.2)
var _sep_cache: Vector2 = Vector2.ZERO
var _sep_frame: int = 0

const DAMAGE_COOLDOWN: float = 1.0
const SEP_RADIUS: float = 60.0
const SEP_WEIGHT: float = 0.6
const SEP_INTERVAL: int = 3

func _ready() -> void:
	add_to_group("enemies")
	var vp_size := get_viewport().get_visible_rect().size
	var threshold: float = vp_size.length() * 0.8
	_reposition_threshold_sq = threshold * threshold
	_sep_frame = randi() % SEP_INTERVAL

func setup(player_ref: Node2D) -> void:
	_player = player_ref

func apply_enemy_data(data: EnemyData, time_elapsed: float) -> void:
	speed = data.base_speed + time_elapsed * data.speed_time_scale
	health = data.health
	damage = data.damage
	xp_value = data.xp_value
	contact_dist = data.contact_dist
	_apply_visuals(data.modulate_color, data.sprite_scale, data.collision_scale)

func make_elite() -> void:
	health *= 3.0
	speed *= 1.5
	damage *= 1.5
	xp_value *= 3
	_normal_modulate = Color(1.0, 0.85, 0.1, 1.0)
	$Sprite2D.modulate = _normal_modulate
	$Sprite2D.scale *= 1.2
	$CollisionShape2D.scale *= 1.2

func _compute_separation() -> Vector2:
	var sep := Vector2.ZERO
	for neighbor in get_tree().get_nodes_in_group("enemies"):
		if neighbor == self or not is_instance_valid(neighbor):
			continue
		var diff := global_position - (neighbor as Node2D).global_position
		var dist := diff.length()
		if dist < SEP_RADIUS and dist > 0.001:
			sep += diff / dist * (1.0 - dist / SEP_RADIUS)
	return sep

func _apply_visuals(color: Color, sprite_scale: Vector2, collision_scale: Vector2) -> void:
	_normal_modulate = color
	$Sprite2D.modulate = color
	$Sprite2D.scale = sprite_scale
	$CollisionShape2D.scale = collision_scale

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_sep_frame = (_sep_frame + 1) % SEP_INTERVAL
	if _sep_frame == 0:
		_sep_cache = _compute_separation()
	var pursuit_dir := (_player.global_position - global_position).normalized()
	velocity = (pursuit_dir + _sep_cache * SEP_WEIGHT).normalized() * speed
	move_and_slide()
	_damage_timer -= delta
	if _damage_timer <= 0.0 and global_position.distance_squared_to(_player.global_position) < contact_dist * contact_dist:
		_player.take_damage(damage)
		_damage_timer = DAMAGE_COOLDOWN
	if global_position.distance_squared_to(_player.global_position) > _reposition_threshold_sq:
		_reposition()

func _reposition() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(400.0, 600.0)
	global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist

func take_damage(amount: float) -> void:
	var actual := minf(amount, health)
	damage_taken.emit(actual)
	health -= amount
	$Sprite2D.modulate = Color(1.0, 0.4, 0.4)
	if health <= 0.0:
		died_at.emit(global_position, xp_value)
		queue_free()
	else:
		get_tree().create_timer(0.1).timeout.connect(
			func() -> void: if is_instance_valid(self): $Sprite2D.modulate = _normal_modulate
		)
