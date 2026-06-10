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
## How close (m) a vehicle must be for the interact key to enter it.
@export var enter_vehicle_range: float = 3.5

var _time_since_grounded: float = 0.0
var _time_since_jump_pressed: float = 1.0
var _jump_spent: bool = false
var _vehicle: Node3D = null

@onready var _camera_rig: OrbitCamera = $CameraRig
@onready var _rig: CharacterAnimator = $Rig


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()
	elif event.is_action_pressed("interact"):
		_toggle_vehicle()


func _physics_process(delta: float) -> void:
	if _vehicle != null:
		global_position = _vehicle.global_position
		return

	_update_jump_timers(delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := PlayerMotion.direction_from_input(input_dir, _camera_rig.global_rotation.y)

	if _is_on_ladder() and (input_dir.y < 0.0 or not is_on_floor()):
		velocity = PlayerMotion.climb_velocity(input_dir, direction, climb_speed)
		move_and_slide()
		_drive_rig(delta, true)
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
	_drive_rig(delta, false)


## Feed the procedural animator this frame's motion. Called after move_and_slide
## so velocity reflects collisions; the planar component drives swing and facing.
func _drive_rig(delta: float, is_climbing: bool) -> void:
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	_rig.animate(planar, is_on_floor(), velocity.y, is_climbing, delta)


func _is_on_ladder() -> bool:
	for ladder in get_tree().get_nodes_in_group("ladders"):
		var area := ladder as Area3D
		if area != null and area.overlaps_body(self):
			return true
	return false


func _toggle_vehicle() -> void:
	if _vehicle != null:
		_exit_vehicle()
		return
	var vehicle := _nearest_vehicle()
	if vehicle != null and not vehicle.has_driver():
		_enter_vehicle(vehicle)


func _enter_vehicle(vehicle: Node3D) -> void:
	_vehicle = vehicle
	velocity = Vector3.ZERO
	visible = false
	collision_layer = 0
	collision_mask = 0
	vehicle.enter(self)


func _exit_vehicle() -> void:
	global_position = _vehicle.exit()
	_vehicle = null
	velocity = Vector3.ZERO
	visible = true
	collision_layer = 2
	collision_mask = 1
	_camera_rig.make_current()


## Vehicles are any Node3D in group "vehicles" implementing the
## enter(driver)/exit()/has_driver() contract (Car, Bike, Boat, ...).
func _nearest_vehicle() -> Node3D:
	var best: Node3D = null
	var best_distance := enter_vehicle_range
	for vehicle in get_tree().get_nodes_in_group("vehicles"):
		var body := vehicle as Node3D
		if body == null or not body.has_method("enter"):
			continue
		var distance := global_position.distance_to(body.global_position)
		if distance <= best_distance:
			best = body
			best_distance = distance
	return best


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
