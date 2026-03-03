extends CharacterBody2D
class_name Enemy

signal died_at(pos: Vector2, xp_value: int)
signal damage_taken(amount: float)

static var _enemy_count: int = 0

var speed: float = 80.0
var health: float = 30.0
var damage: float = 10.0
var xp_value: int = 10
var contact_dist: float = 30.0
var _player: Node2D = null
var _damage_timer: float = 0.0
var _flash_timer: float = 0.0
var _reposition_threshold_sq: float = 0.0
var _normal_modulate: Color = Color(1, 0.5, 0.2)
var _sep_cache: Vector2 = Vector2.ZERO
var _sep_frame: int = 0
var _knockback_velocity: Vector2 = Vector2.ZERO

# Behavior flags
var _phase_through: bool = false
var _charges: bool = false
var _charge_interval: float = 3.0
var _charge_speed_mult: float = 3.0
var _charge_duration: float = 0.5
var _charge_timer: float = 0.0
var _charge_active: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_recovering: float = 0.0

const KNOCKBACK_DECAY: float = 8.0
const DAMAGE_COOLDOWN: float = 1.0
const SEP_RADIUS: float = 60.0
const SEP_WEIGHT: float = 0.6
const SEP_INTERVAL: int = 8
const SEP_MAX_COUNT: int = 80
const CHARGE_RECOVERY_TIME: float = 1.0
const CHARGE_RECOVERY_SPEED: float = 0.3

func _ready() -> void:
	_enemy_count += 1
	add_to_group("enemies")
	var vp_size := get_viewport().get_visible_rect().size
	var camera := get_viewport().get_camera_2d()
	var zoom_val: float = camera.zoom.x if camera != null else 1.0
	var threshold: float = (vp_size / zoom_val).length() * 1.2
	_reposition_threshold_sq = threshold * threshold
	_sep_frame = randi() % SEP_INTERVAL

func _exit_tree() -> void:
	_enemy_count -= 1

func setup(player_ref: Node2D) -> void:
	_player = player_ref

func apply_enemy_data(data: EnemyData, time_elapsed: float) -> void:
	speed = data.base_speed + time_elapsed * data.speed_time_scale
	health = data.health
	damage = data.damage
	xp_value = data.xp_value
	contact_dist = data.contact_dist
	_phase_through = data.phase_through
	_charges = data.charges
	_charge_interval = data.charge_interval
	_charge_speed_mult = data.charge_speed_mult
	_charge_duration = data.charge_duration
	if _charges:
		_charge_timer = randf_range(1.0, _charge_interval)
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
	if _enemy_count > SEP_MAX_COUNT:
		return Vector2.ZERO
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
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			$Sprite2D.modulate = _normal_modulate
	if _player == null or not is_instance_valid(_player):
		return

	# Separation (skipped for ghosts)
	if not _phase_through:
		_sep_frame = (_sep_frame + 1) % SEP_INTERVAL
		if _sep_frame == 0:
			_sep_cache = _compute_separation()
	else:
		_sep_cache = Vector2.ZERO

	# Decay knockback
	if _knockback_velocity.length_squared() > 1.0:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _knockback_velocity.length() * KNOCKBACK_DECAY * delta)
	else:
		_knockback_velocity = Vector2.ZERO

	# Charge behavior
	if _charges:
		_process_charge(delta)
	else:
		var pursuit_dir := (_player.global_position - global_position).normalized()
		velocity = (pursuit_dir + _sep_cache * SEP_WEIGHT).normalized() * speed
	velocity += _knockback_velocity
	move_and_slide()

	_damage_timer -= delta
	if _damage_timer <= 0.0 and global_position.distance_squared_to(_player.global_position) < contact_dist * contact_dist:
		_player.take_damage(damage * 3.0)
		_damage_timer = DAMAGE_COOLDOWN
	if global_position.distance_squared_to(_player.global_position) > _reposition_threshold_sq:
		_reposition()

func _process_charge(delta: float) -> void:
	if _charge_recovering > 0.0:
		# Recovery phase: move slowly
		_charge_recovering -= delta
		var pursuit_dir := (_player.global_position - global_position).normalized()
		velocity = (pursuit_dir + _sep_cache * SEP_WEIGHT).normalized() * speed * CHARGE_RECOVERY_SPEED
	elif _charge_active > 0.0:
		# Charging phase: fast dash toward locked direction
		_charge_active -= delta
		velocity = _charge_dir * speed * _charge_speed_mult
		if _charge_active <= 0.0:
			_charge_recovering = CHARGE_RECOVERY_TIME
	else:
		# Normal pursuit + charge timer
		_charge_timer -= delta
		var pursuit_dir := (_player.global_position - global_position).normalized()
		velocity = (pursuit_dir + _sep_cache * SEP_WEIGHT).normalized() * speed
		if _charge_timer <= 0.0:
			_charge_timer = _charge_interval
			_charge_active = _charge_duration
			_charge_dir = (_player.global_position - global_position).normalized()
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0)
			_flash_timer = _charge_duration

func _reposition() -> void:
	var opposite_dir: Vector2 = (_player.global_position - global_position).normalized()
	var dist: float = randf_range(400.0, 600.0)
	global_position = _player.global_position + opposite_dir * dist

func apply_knockback(impulse: Vector2) -> void:
	_knockback_velocity = impulse

func take_damage(amount: float) -> void:
	var actual := minf(amount, health)
	damage_taken.emit(actual)
	health -= amount
	$Sprite2D.modulate = Color(1.0, 0.4, 0.4)
	if health <= 0.0:
		died_at.emit(global_position, xp_value)
		queue_free()
	else:
		_flash_timer = 0.1
