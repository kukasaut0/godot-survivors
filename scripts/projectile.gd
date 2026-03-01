extends Area2D

var speed: float = 400.0
var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0
var _timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
