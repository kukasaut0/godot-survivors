extends Resource
class_name CharacterData

@export var id: String = "default"
@export var display_name: String = "Survivor"
@export var speed: float = 300.0
@export var max_health: float = 100.0
@export var health_per_level: float = 20.0
@export var modulate_color: Color = Color(0.3, 0.7, 1, 1)
@export var sprite_scale: Vector2 = Vector2(0.5, 0.5)
@export var starting_weapons: Array[WeaponEntry] = []
