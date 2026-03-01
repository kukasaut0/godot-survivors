extends Area2D

var xp_value: int = 10
var collect_radius: float = 60.0
var _player: Node2D = null

func setup(value: int, player_ref: Node2D) -> void:
	xp_value = value
	_player = player_ref

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= collect_radius:
		_player.collect_xp(xp_value)
		queue_free()
