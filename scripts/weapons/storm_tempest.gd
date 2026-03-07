extends WeaponBase
class_name StormTempest

var thunder_damage: float = 130.0
var thunder_targets: int = 9
var thunder_interval: float = 0.65
var knife_damage: float = 42.0
var knife_count: int = 22
var knife_interval: float = 0.85

var _thunder_timer: float = 0.0
var _knife_timer: float = 0.0
var _projectile_scene: PackedScene = null
var _lightning_targets: Array[Vector2] = []

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: Storm zaps + knife fan (9 targets, 130 thunder dmg, 0.65s / 22 knives, 42 dmg, 0.85s)",
	"Thunder dmg 160, Knife dmg 52",
	"Thunder targets: 11, Knives: 26, Thunder interval: 0.60s",
	"Max: Thunder dmg 195, Knife dmg 64, intervals 0.55s/0.75s, 13 targets, 28 knives",
]

func _on_setup() -> void:
	weapon_name = "Storm Tempest"
	weapon_description = "Unleashes lightning storms and knife cyclones."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			thunder_damage = 160.0
			knife_damage = 52.0
		3:
			thunder_targets = 11
			knife_count = 26
			thunder_interval = 0.60
		4:
			thunder_damage = 195.0
			knife_damage = 64.0
			thunder_targets = 13
			knife_count = 28
			thunder_interval = 0.55
			knife_interval = 0.75
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
