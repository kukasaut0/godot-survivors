extends Resource
class_name LevelData

@export var id: String = "default"
@export var display_name: String = "The Fields"
@export var initial_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3
@export var interval_decay_per_30s: float = 0.1
@export var spawn_count_base: int = 1
@export var spawn_count_per_30s: int = 1
@export var max_spawn_count: int = 5
@export var spawn_distance_min: float = 400.0
@export var spawn_distance_max: float = 600.0
@export var waves: Array[EnemySpawnWave] = []
@export var win_time: float = 900.0
@export var boss_spawn_times: Array[float] = [300.0, 600.0, 900.0]
@export var boss_data_path: String = "res://data/enemies/boss.tres"
@export var elite_chance: float = 0.10
@export var health_drop_chance: float = 0.05
@export var background_color: Color = Color(0.05, 0.08, 0.05, 1)
@export var soul_multiplier: float = 1.0
@export var max_weapons: int = 4
