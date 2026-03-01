extends Area2D

var xp_value: int = 10
var collect_radius: float = 60.0
var magnet_radius: float = 200.0
var magnet_speed: float = 350.0
var _player: Node2D = null

func setup(value: int, player_ref: Node2D) -> void:
	xp_value = value
	_player = player_ref

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dist_sq := global_position.distance_squared_to(_player.global_position)
	if dist_sq <= collect_radius * collect_radius:
		_player.collect_xp(xp_value)
		queue_free()
	elif dist_sq <= magnet_radius * magnet_radius:
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta
