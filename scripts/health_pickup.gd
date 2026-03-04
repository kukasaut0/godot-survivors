extends Area2D

const HEAL_AMOUNT: float = 20.0
const MAGNET_ACCELERATION: float = 700.0
const MAX_MAGNET_SPEED: float = 1000.0

var _player: Node2D = null
var _current_speed: float = 0.0

func setup(player_ref: Node2D) -> void:
	_player = player_ref
	$Sprite2D.modulate = Color(1, 0.2, 0.4, 1)
	$Sprite2D.scale = Vector2(0.12, 0.12)

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var collect_radius: float = _player.xp_collect_radius if "xp_collect_radius" in _player else 60.0
	var magnet_radius: float = _player.xp_magnet_radius if "xp_magnet_radius" in _player else 200.0
	var dist_sq := global_position.distance_squared_to(_player.global_position)
	if dist_sq <= collect_radius * collect_radius:
		_player.health = minf(_player.health + HEAL_AMOUNT, _player.max_health)
		queue_free()
	elif dist_sq <= magnet_radius * magnet_radius:
		_current_speed = minf(_current_speed + MAGNET_ACCELERATION * delta, MAX_MAGNET_SPEED)
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * _current_speed * delta
	else:
		_current_speed = 0.0
