extends WeaponBase
class_name StormTempest

var thunder_damage: float = 84.5
var thunder_targets: int = 6
var thunder_interval: float = 0.8
var knife_damage: float = 26.4
var knife_count: int = 20
var knife_interval: float = 1.0

var _thunder_timer: float = 0.0
var _knife_timer: float = 0.0
var _projectile_scene: PackedScene = null
var _lightning_targets: Array[Vector2] = []

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Storm zaps + knife fan (combined Thunder Strike + Knife Fan)",
	"Power: Thunder dmg 90, Knife dmg 30",
	"Count: 8 thunder targets, 22 knives",
	"Max: Thunder dmg 120, Knife dmg 42, 0.75s/1.0s intervals",
]

func _on_setup() -> void:
	weapon_name = "Storm Tempest"
	weapon_description = "Unleashes lightning storms and knife cyclones."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			thunder_damage = 90.0
			knife_damage = 30.0
		3:
			thunder_targets = 8
			knife_count = 22
		4:
			thunder_damage = 120.0
			knife_damage = 42.0
			thunder_interval = 0.75
			knife_interval = 1.0
	queue_redraw()

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	for pos in _lightning_targets:
		draw_line(Vector2.ZERO, pos, Color(1.0, 0.9, 0.3, 0.9), 2.5)
		draw_circle(pos, 7.0, Color(1.0, 1.0, 0.5, 0.9))

func _physics_process(delta: float) -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	_thunder_timer -= delta
	if _thunder_timer <= 0.0:
		_thunder_timer = thunder_interval
		_strike_thunder(dmg_mult)
	_knife_timer -= delta
	if _knife_timer <= 0.0:
		_knife_timer = knife_interval
		_fire_knives(dmg_mult)

func _strike_thunder(dmg_mult: float) -> void:
	var candidates: Array[Enemy] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and is_instance_valid(enemy):
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return _player.global_position.distance_squared_to(a.global_position) < \
			_player.global_position.distance_squared_to(b.global_position))
	_lightning_targets.clear()
	for i in mini(thunder_targets, candidates.size()):
		candidates[i].take_damage(thunder_damage * dmg_mult)
		_lightning_targets.append(to_local(candidates[i].global_position))
	if not _lightning_targets.is_empty():
		queue_redraw()
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			_lightning_targets.clear()
			queue_redraw())

func _fire_knives(dmg_mult: float) -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	for i in knife_count:
		var angle: float = (TAU / float(knife_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = knife_damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)
