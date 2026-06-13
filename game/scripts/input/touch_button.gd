class_name TouchButton
extends Control
## Virtual on-screen button that fires an InputAction on press and releases it
## on release. Rendered as a translucent circle with a text label. Touch-only;
## does not respond to mouse events so it doesn't interfere with desktop play.

var action: String = ""
var label_text: String = ""
var base_color: Color = Color(1, 1, 1, 0.4)

var _pressed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size / 2.0
	var col := base_color if not _pressed else base_color.lightened(0.25)

	# Shrink button slightly when pressed for visual feedback
	var radius := (size.x / 2.0) * (0.9 if _pressed else 1.0)

	# Translucent background circle
	var bg_col := Color(col.r, col.g, col.b, col.a * 0.25 if not _pressed else col.a * 0.5)
	draw_circle(center, radius, bg_col)

	# Clean border outline
	var border_width := 3.0 if not _pressed else 4.0
	draw_arc(center, radius - border_width / 2.0, 0.0, TAU, 32, col, border_width, true)

	# Centered text label
	if label_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 20
		var label_size := font.get_string_size(
			label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size
		)
		# Align vertical center by offsetting by approximately half of font ascent/height
		var text_pos := center + Vector2(-label_size.x / 2.0, label_size.y * 0.3)
		draw_string(
			font, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE
		)


func _input(event: InputEvent) -> void:
	if not visible or action == "":
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var local := touch.position - global_position
		var center := size / 2.0
		var in_circle := local.distance_to(center) <= size.x / 2.0
		if touch.pressed and in_circle:
			_pressed = true
			Input.action_press(action)
			queue_redraw()
		elif not touch.pressed and _pressed:
			_pressed = false
			Input.action_release(action)
			queue_redraw()
