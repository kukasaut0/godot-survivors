extends Area2D

const COLLECT_RADIUS: float = 60.0
const HEAL_AMOUNT: float = 20.0

var _player: Node = null

func setup(player_ref: Node) -> void:
	_player = player_ref
	$Sprite2D.modulate = Color(1, 0.2, 0.4, 1)
	$Sprite2D.scale = Vector2(0.12, 0.12)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_squared_to(_player.global_position) <= COLLECT_RADIUS * COLLECT_RADIUS:
		_player.health = minf(_player.health + HEAL_AMOUNT, _player.max_health)
		queue_free()
