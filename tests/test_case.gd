## Base class for all test suites.
## Run with: godot --headless --script tests/run_tests.gd
class_name TestCase
extends RefCounted

var _passes: int = 0
var _failures: int = 0
var _current_test: String = ""
var _root: Node = null  # set by run_tests.gd before calling run_all()

# --- Assertions ---

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual == expected:
		_passes += 1
		return
	_failures += 1
	var loc := "[%s::%s]" % [get_script().resource_path.get_file().get_basename(), _current_test]
	var note := " — %s" % msg if msg else ""
	push_error("%s expected <%s> but got <%s>%s" % [loc, str(expected), str(actual), note])

func assert_true(val: bool, msg: String = "") -> void:
	assert_eq(val, true, msg)

func assert_false(val: bool, msg: String = "") -> void:
	assert_eq(val, false, msg)

func assert_null(val: Variant, msg: String = "") -> void:
	if val == null:
		_passes += 1
		return
	_failures += 1
	var loc := "[%s::%s]" % [get_script().resource_path.get_file().get_basename(), _current_test]
	push_error("%s expected null but got <%s>%s" % [loc, str(val), " — %s" % msg if msg else ""])

func assert_not_null(val: Variant, msg: String = "") -> void:
	if val != null:
		_passes += 1
		return
	_failures += 1
	var loc := "[%s::%s]" % [get_script().resource_path.get_file().get_basename(), _current_test]
	push_error("%s expected non-null%s" % [loc, " — %s" % msg if msg else ""])

func assert_approx_eq(actual: float, expected: float, tol: float = 0.001, msg: String = "") -> void:
	if absf(actual - expected) <= tol:
		_passes += 1
		return
	_failures += 1
	var loc := "[%s::%s]" % [get_script().resource_path.get_file().get_basename(), _current_test]
	push_error("%s expected ~%f (±%f) but got %f%s" % [loc, expected, tol, actual, " — %s" % msg if msg else ""])

# --- Runner ---

func run_all() -> Dictionary:
	var suite_name: String = get_script().resource_path.get_file().get_basename()
	for method: Dictionary in get_method_list():
		if method["name"].begins_with("test_"):
			_current_test = method["name"]
			call(_current_test)
	return {"name": suite_name, "pass": _passes, "fail": _failures}
