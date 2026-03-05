extends Area2D

var speed: float = 400.0
var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0
var max_range: float = -1.0  # -1 = unlimited
var _timer: float = 0.0
var _distance: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	position += move
	_timer += delta
	if max_range > 0.0:
		_distance += move.length()
		if _distance >= max_range:
			queue_free()
			return
	if _timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
