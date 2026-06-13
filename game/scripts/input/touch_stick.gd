class_name TouchStick
extends Control
## Virtual analog stick rendered as two concentric circles. Tracks finger drag
## within a bounding area and emits a clamped [-1, 1] × [-1, 1] output vector
## that consumers (TouchControls) read each frame. Radial deadzone prevents
## drift; the outer ring is a visual guide, not a hard boundary.

@export var radius: float = 80.0
@export var deadzone: float = 0.12
@export var ring_color: Color = Color(1, 1, 1, 0.25)
@export var knob_color: Color = Color(1, 1, 1, 0.55)

## Output vector in [-1,1]² — consumed by the parent TouchControls each frame.
var output: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _base_pos: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.4, radius * 2.4)
	size = custom_minimum_size
	_base_pos = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var center := _base_pos

	# Translucent background circle
	var bg_color := Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * 0.25)
	draw_circle(center, radius, bg_color)

	# Clean outline ring
	draw_arc(center, radius, 0.0, TAU, 64, ring_color, 4.0, true)

	# Inner deadzone visual guide
	var deadzone_color := Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * 0.1)
	draw_circle(center, radius * deadzone, deadzone_color)

	# Draw Knob
	var knob_pos := center + _knob_offset
	var knob_radius := radius * 0.35

	# Translucent knob fill
	var knob_fill := Color(knob_color.r, knob_color.g, knob_color.b, knob_color.a * 0.4)
	draw_circle(knob_pos, knob_radius, knob_fill)

	# Knob outline
	draw_arc(knob_pos, knob_radius, 0.0, TAU, 32, knob_color, 3.0, true)

	# Knob center dot
	draw_circle(knob_pos, knob_radius * 0.25, knob_color)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _in_bounds(touch.position):
			_touch_index = touch.index
			_update_offset(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_offset(drag.position)


func _in_bounds(pos: Vector2) -> bool:
	var local := pos - global_position
	return local.distance_to(_base_pos) <= radius * 1.4


func _update_offset(screen_pos: Vector2) -> void:
	var local := screen_pos - global_position - _base_pos
	var clamped := local.limit_length(radius)
	_knob_offset = clamped
	var raw := clamped / radius
	output = StickInput.radial_deadzone(raw, deadzone)
	queue_redraw()


func _reset() -> void:
	_touch_index = -1
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	queue_redraw()
