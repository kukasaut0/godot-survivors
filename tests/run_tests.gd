## Headless test runner.
## Usage: godot --headless --script tests/run_tests.gd
extends SceneTree

# Load TestCase first so its class_name is registered before suite scripts are parsed
const _TC = preload("res://tests/test_case.gd")

const SUITES = [
	preload("res://tests/test_weapon_base.gd"),
	preload("res://tests/test_weapon_registry.gd"),
	preload("res://tests/test_player.gd"),
	preload("res://tests/test_enemy.gd"),
]

func _initialize() -> void:
	# Defer one frame so get_root() is fully wired into the SceneTree
	# (nodes added to root in _initialize() have data.tree == null)
	call_deferred("_run_tests")

func _run_tests() -> void:
	var total_pass := 0
	var total_fail := 0

	for suite_script in SUITES:
		var suite = suite_script.new()
		suite._root = get_root()
		var result: Dictionary = suite.run_all()
		var status := "OK  " if result.fail == 0 else "FAIL"
		print("[%s] %-30s %d passed, %d failed" % [status, result.name, result.pass, result.fail])
		total_pass += result.pass
		total_fail += result.fail

	print("\n=== %d passed, %d failed ===" % [total_pass, total_fail])
	quit(1 if total_fail > 0 else 0)
