extends Resource
class_name LevelData

@export var id: String = "default"
@export var display_name: String = "The Fields"
@export var initial_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3
@export var interval_decay_per_30s: float = 0.1
@export var spawn_count_base: int = 1
@export var spawn_count_per_30s: int = 1
@export var spawn_distance_min: float = 400.0
@export var spawn_distance_max: float = 600.0
@export var waves: Array[EnemySpawnWave] = []
