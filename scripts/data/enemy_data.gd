extends Resource
class_name EnemyData

@export var id: String = "normal"
@export var base_speed: float = 80.0
@export var speed_time_scale: float = 0.5
@export var health: float = 30.0
@export var damage: float = 10.0
@export var xp_value: int = 10
@export var contact_dist: float = 30.0
@export var modulate_color: Color = Color(1, 0.5, 0.2)
@export var sprite_scale: Vector2 = Vector2(0.4, 0.4)
@export var collision_scale: Vector2 = Vector2(1.0, 1.0)
@export var phase_through: bool = false
@export var charges: bool = false
@export var charge_interval: float = 3.0
@export var charge_speed_mult: float = 3.0
@export var charge_duration: float = 0.5
