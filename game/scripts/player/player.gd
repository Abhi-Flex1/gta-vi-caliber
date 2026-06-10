class_name Player
extends CharacterBody3D
## Third-person player controller: walk, sprint, jump.
##
## Movement math is delegated to PlayerMotion (pure, unit-tested). The camera
## is owned by the CameraRig child (OrbitCamera); we only read its yaw so
## input is camera-relative.

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var acceleration: float = 30.0
@export var deceleration: float = 45.0
@export_range(0.0, 1.0) var air_control: float = 0.35
@export var jump_velocity: float = 4.8
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var climb_speed: float = 3.0

var _time_since_grounded: float = 0.0
var _time_since_jump_pressed: float = 1.0
var _jump_spent: bool = false

@onready var _camera_rig: OrbitCamera = $CameraRig


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := PlayerMotion.direction_from_input(input_dir, _camera_rig.global_rotation.y)

	if _is_on_ladder() and (input_dir.y < 0.0 or not is_on_floor()):
		velocity = PlayerMotion.climb_velocity(input_dir, direction, climb_speed)
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	if PlayerMotion.should_jump(
		_time_since_grounded, coyote_time, _time_since_jump_pressed, jump_buffer_time, _jump_spent
	):
		velocity.y = jump_velocity
		_jump_spent = true
		_time_since_jump_pressed = jump_buffer_time + 1.0

	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := PlayerMotion.horizontal_velocity(direction, speed)
	var rate := PlayerMotion.acceleration_rate(
		not input_dir.is_zero_approx(), is_on_floor(), acceleration, deceleration, air_control
	)
	velocity = PlayerMotion.accelerated(velocity, target, rate, delta)
	move_and_slide()


func _is_on_ladder() -> bool:
	for ladder in get_tree().get_nodes_in_group("ladders"):
		var area := ladder as Area3D
		if area != null and area.overlaps_body(self):
			return true
	return false


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_time_since_grounded = 0.0
		_jump_spent = false
	else:
		_time_since_grounded += delta
	if Input.is_action_just_pressed("jump"):
		_time_since_jump_pressed = 0.0
	else:
		_time_since_jump_pressed += delta


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
