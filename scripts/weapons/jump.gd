extends WeaponBase
class_name Jump

var boost_speed: float = 500.0
var boost_duration: float = 0.3
var dash_cooldown: float = 4.0
var _dash_timer: float = 0.0
var _boost_time: float = 0.0
var _last_dir: Vector2 = Vector2.DOWN

const UPGRADE_DESCRIPTIONS: Array[String] = [
	"Dash burst forward (speed 500, 4s cooldown)",
	"Speed ↑ (700)",
	"Cooldown ↓ (3.5s)",
	"Speed ↑ (900)",
	"Cooldown ↓ (3.0s)",
	"Speed ↑ (1100)",
	"Cooldown ↓ (2.5s)",
	"Speed ↑ 1300, Cooldown ↓ 2.0s (MAX)",
]

func _on_setup() -> void:
	weapon_name = "Jump"
	weapon_description = "Burst forward in your movement direction."

func _on_upgrade() -> void:
	match level:
		1:
			boost_speed = 500.0
			dash_cooldown = 4.0
		2:
			boost_speed = 700.0
		3:
			dash_cooldown = 3.5
		4:
			boost_speed = 900.0
		5:
			dash_cooldown = 3.0
		6:
			boost_speed = 1100.0
		7:
			dash_cooldown = 2.5
		8:
			boost_speed = 1300.0
			dash_cooldown = 2.0

func get_next_upgrade_description() -> String:
	var next := level + 1
	if next > max_level:
		return "(maxed)"
	return UPGRADE_DESCRIPTIONS[next - 1]

func _physics_process(delta: float) -> void:
	if level == 0:
		return

	_dash_timer -= delta
	_boost_time -= delta

	# Track current movement direction
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if dir.length() > 0:
		_last_dir = dir.normalized()

	# Check for jump input
	if Input.is_action_just_pressed("jump"):
		if _dash_timer <= 0.0:
			_dash_timer = dash_cooldown
			_boost_time = boost_duration
			_perform_boost(_last_dir)

	# Apply boost velocity if active
	if _boost_time > 0.0 and _player:
		_player.boost_velocity = _last_dir * boost_speed
	else:
		_player.boost_velocity = Vector2.ZERO

func _perform_boost(direction: Vector2) -> void:
	if _player == null:
		return

	# Visual feedback: briefly flash
	var original_modulate := (_player as Node2D).modulate
	(_player as Node2D).modulate = original_modulate.lightened(0.3)
	await get_tree().create_timer(0.1).timeout
	(_player as Node2D).modulate = original_modulate
