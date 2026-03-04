extends Node2D

const GRID_SIZE: float = 80.0

var _camera: Camera2D = null
var _line_color: Color = Color(1, 1, 1, 0.07)

func setup(camera: Camera2D, bg_color: Color) -> void:
	_camera = camera
	# Grid lines are a slightly brightened version of the background color
	_line_color = Color(
		minf(bg_color.r * 2.5 + 0.06, 1.0),
		minf(bg_color.g * 2.5 + 0.06, 1.0),
		minf(bg_color.b * 2.5 + 0.06, 1.0),
		0.35
	)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _camera == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	var zoom := _camera.zoom.x
	var half_w := vp_size.x / (2.0 * zoom) + GRID_SIZE
	var half_h := vp_size.y / (2.0 * zoom) + GRID_SIZE
	var cam_pos := _camera.global_position

	var left: float = floor((cam_pos.x - half_w) / GRID_SIZE) * GRID_SIZE
	var right: float = cam_pos.x + half_w
	var top: float = floor((cam_pos.y - half_h) / GRID_SIZE) * GRID_SIZE
	var bottom: float = cam_pos.y + half_h

	var x: float = left
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), _line_color, 1.0)
		x += GRID_SIZE

	var y: float = top
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), _line_color, 1.0)
		y += GRID_SIZE
