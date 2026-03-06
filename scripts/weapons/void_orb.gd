extends WeaponBase
class_name VoidOrb

var bolt_damage: float = 36.0
var bolt_count: int = 5
var bolt_cooldown: float = 0.4
var aura_damage: float = 28.0
var aura_radius: float = 240.0
var aura_tick: float = 0.4

var _bolt_timer: float = 0.0
var _aura_timer: float = 0.0
var _projectile_scene: PackedScene = null

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"EVOLUTION: 5 bolts + void aura (36 dmg, 28 aura, 240 radius)",
	"Power: Bolt dmg 50, Aura dmg 40",
	"Range: Aura radius 300, Bolt count 7",
	"Max Power: Bolt dmg 70, Aura dmg 55, tick 0.3s",
]

func _on_setup() -> void:
	weapon_name = "Void Orb"
	weapon_description = "Fires orbiting bolts and pulses a void aura."
	max_level = 4
	_projectile_scene = load("res://scenes/projectile.tscn")

func _on_upgrade() -> void:
	match level:
		2:
			bolt_damage = 50.0
			aura_damage = 40.0
		3:
			aura_radius = 300.0
			bolt_count = 7
		4:
			bolt_damage = 70.0
			aura_damage = 55.0
			aura_tick = 0.3
	queue_redraw()

func get_next_upgrade_description() -> String:
	if is_maxed():
		return "Maxed out!"
	return UPGRADE_DESCRIPTIONS[_desc_index()]

func _draw() -> void:
	draw_circle(Vector2.ZERO, aura_radius, Color(0.5, 0, 1, 0.07))
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 64, Color(0.5, 0, 1, 0.5), 2.0)

func _physics_process(delta: float) -> void:
	var dmg_mult: float = _player.damage_multiplier if "damage_multiplier" in _player else 1.0
	_bolt_timer -= delta
	if _bolt_timer <= 0.0:
		_bolt_timer = bolt_cooldown
		_fire_bolts(dmg_mult)
	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = aura_tick
		_pulse_aura(dmg_mult)

func _fire_bolts(dmg_mult: float) -> void:
	if _projectile_scene == null or _projectiles_container == null:
		return
	for i in bolt_count:
		var angle: float = (TAU / float(bolt_count)) * float(i)
		var proj: Area2D = _projectile_scene.instantiate()
		proj.damage = bolt_damage * dmg_mult
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.global_position = _player.global_position
		_projectiles_container.add_child(proj)

func _pulse_aura(dmg_mult: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if _player.global_position.distance_squared_to(e.global_position) <= aura_radius * aura_radius:
			e.take_damage(aura_damage * dmg_mult)
