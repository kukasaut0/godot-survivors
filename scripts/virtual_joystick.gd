extends Control

const OUTER_RADIUS: float = 72.0
const KNOB_RADIUS: float = 28.0
const OUTER_COLOR: Color = Color(1, 1, 1, 0.18)
const KNOB_COLOR: Color = Color(1, 1, 1, 0.45)

var direction: Vector2 = Vector2.ZERO

var _active: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Must process input even when game is paused (level-up UI) so touch release is never missed
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			# Only activate if touch is on the left half of the screen
			if touch.position.x < get_viewport_rect().size.x * 0.5:
				_touch_index = touch.index
				_center = touch.position
				_knob_offset = Vector2.ZERO
				_active = true
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_active = false
			direction = Vector2.ZERO
			_knob_offset = Vector2.ZERO
			queue_redraw()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_knob_offset = (drag.position - _center).limit_length(OUTER_RADIUS)
			direction = _knob_offset / OUTER_RADIUS if _knob_offset.length() > 8.0 else Vector2.ZERO
			queue_redraw()
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _active:
		return
	# Outer ring
	draw_circle(_center, OUTER_RADIUS, OUTER_COLOR)
	draw_arc(_center, OUTER_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0)
	# Knob
	draw_circle(_center + _knob_offset, KNOB_RADIUS, KNOB_COLOR)
