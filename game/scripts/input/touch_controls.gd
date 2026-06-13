class_name TouchControls
extends CanvasLayer
## On-screen touch controls for mobile devices: virtual dual-stick joysticks,
## action buttons (jump, sprint, interact, shoot, aim), and a weapon wheel toggle.
## Automatically shows/hides based on device type and user settings toggle.
##
## The left stick drives movement (mapped to move_left/right/forward/back actions),
## the right stick drives camera look (emitting raw stick deltas for OrbitCamera),
## and the action buttons fire their mapped InputActions so existing gameplay code
## doesn't need to know about touch at all.

signal camera_look_delta(delta: Vector2)

enum InputMode { TOUCH, KBM, GAMEPAD }

const BASE_HEIGHT: float = 720.0
const STICK_SIZE_BASE: float = 180.0
const BUTTON_SIZE_BASE: float = 60.0

const LEFT_STICK_CENTER_BASE := Vector2(140, -140)
const RIGHT_STICK_CENTER_BASE := Vector2(-360, -140)

const BUTTON_CENTERS_BASE := {
	"jump": Vector2(-75, -140),
	"sprint": Vector2(-60, -225),
	"interact": Vector2(-145, -225),
	"fire": Vector2(-130, -310),
	"aim": Vector2(-215, -310),
	"reload": Vector2(-300, -310),
	"weapon_wheel": Vector2(-230, -225)
}

## Whether touch controls are globally enabled (persisted via settings).
var enabled: bool = false
var current_mode: InputMode = InputMode.TOUCH

var _left_stick: TouchStick = null
var _right_stick: TouchStick = null
var _buttons: Dictionary = {}


func _ready() -> void:
	add_to_group("touch_controls")
	layer = 100
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_resize_ui()
	_update_visibility()


func set_enabled(value: bool) -> void:
	enabled = value
	_update_visibility()


func _update_visibility() -> void:
	visible = enabled and (current_mode == InputMode.TOUCH)


func _on_viewport_size_changed() -> void:
	_resize_ui()


func _resize_ui() -> void:
	var viewport_size: Vector2 = get_viewport().size
	var scale_factor := float(viewport_size.y) / BASE_HEIGHT
	scale_factor = clampf(scale_factor, 0.4, 2.0)

	var stick_size_scaled := STICK_SIZE_BASE * scale_factor
	if _left_stick != null:
		var left_stick_center := LEFT_STICK_CENTER_BASE * scale_factor
		_update_control_layout(_left_stick, 0.0, 1.0, left_stick_center, stick_size_scaled)

	if _right_stick != null:
		var right_stick_center := RIGHT_STICK_CENTER_BASE * scale_factor
		_update_control_layout(_right_stick, 1.0, 1.0, right_stick_center, stick_size_scaled)

	var button_size_scaled := BUTTON_SIZE_BASE * scale_factor
	for action in _buttons:
		var btn = _buttons[action]
		var base_center = BUTTON_CENTERS_BASE.get(action, Vector2.ZERO)
		var center_scaled = base_center * scale_factor
		_update_control_layout(btn, 1.0, 1.0, center_scaled, button_size_scaled)


func _update_control_layout(
	node: Control, anchor_x: float, anchor_y: float, center_offset: Vector2, size_val: float
) -> void:
	var sz := Vector2(size_val, size_val)
	node.custom_minimum_size = sz
	node.size = sz

	node.anchor_left = anchor_x
	node.anchor_right = anchor_x
	node.anchor_top = anchor_y
	node.anchor_bottom = anchor_y

	var half_sz := size_val / 2.0
	node.offset_left = center_offset.x - half_sz
	node.offset_top = center_offset.y - half_sz
	node.offset_right = center_offset.x + half_sz
	node.offset_bottom = center_offset.y + half_sz

	if node is TouchStick:
		node.radius = size_val / 2.4
		node._base_pos = sz / 2.0
		node.queue_redraw()
	elif node is TouchButton:
		node.queue_redraw()


func _build_ui() -> void:
	_left_stick = TouchStick.new()
	_left_stick.name = "LeftStick"
	add_child(_left_stick)

	_right_stick = TouchStick.new()
	_right_stick.name = "RightStick"
	_right_stick.modulate = Color(0.4, 0.6, 1.0, 0.5)
	add_child(_right_stick)

	_add_button("jump", "A", Color(0.2, 0.7, 0.3, 0.6))
	_add_button("sprint", "B", Color(0.8, 0.4, 0.1, 0.6))
	_add_button("interact", "X", Color(0.2, 0.5, 0.9, 0.6))
	_add_button("fire", "Y", Color(0.9, 0.2, 0.2, 0.6))
	_add_button("aim", "LT", Color(0.6, 0.2, 0.8, 0.6))
	_add_button("reload", "R", Color(0.5, 0.5, 0.5, 0.6))
	_add_button("weapon_wheel", "W", Color(0.3, 0.3, 0.6, 0.6))


func _add_button(action: String, label: String, color: Color) -> void:
	var btn := TouchButton.new()
	btn.action = action
	btn.label_text = label
	btn.base_color = color
	add_child(btn)
	_buttons[action] = btn


func _physics_process(_delta: float) -> void:
	if not visible:
		return
	_send_move_input()
	_send_look_input()


func _send_move_input() -> void:
	if _left_stick == null:
		return
	var raw := _left_stick.output
	if raw.length_squared() < 0.01:
		return
	_synthetic_action("move_right", raw.x)
	_synthetic_action("move_left", -raw.x)
	_synthetic_action("move_forward", -raw.y)
	_synthetic_action("move_back", raw.y)


func _send_look_input() -> void:
	if _right_stick == null:
		return
	var raw := _right_stick.output
	if raw.length_squared() < 0.01:
		return
	camera_look_delta.emit(raw)


## Synthesize an InputEvent action so existing gameplay code reads touch as if
## a real gamepad button were pressed. Uses the engine Input singleton so
## Input.is_action_pressed/strength both work.
func _synthetic_action(action: String, value: float) -> void:
	var strength := absf(value)
	if strength > 0.1:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if current_mode != InputMode.TOUCH:
			current_mode = InputMode.TOUCH
			_update_visibility()
		return

	if event is InputEventJoypadButton:
		if current_mode != InputMode.GAMEPAD:
			current_mode = InputMode.GAMEPAD
			_update_visibility()
		return
	if event is InputEventJoypadMotion:
		if absf(event.axis_value) > 0.15:
			if current_mode != InputMode.GAMEPAD:
				current_mode = InputMode.GAMEPAD
				_update_visibility()
			return

	if event is InputEventKey and event.pressed:
		if current_mode != InputMode.KBM:
			current_mode = InputMode.KBM
			_update_visibility()
		if current_mode != InputMode.KBM:
			current_mode = InputMode.KBM
			_update_visibility()
		return
