class_name Car
extends VehicleBody3D
## Greybox drivable car. Idle until a driver enters (Player calls enter()),
## then reads move input as throttle/steer. Control math is delegated to
## VehicleMotion (pure, unit-tested).

@export var max_engine_force: float = 2600.0
@export var max_brake: float = 55.0
@export var max_steer: float = 0.55
@export var top_speed: float = 38.0
## Speed (m/s) at which available steering lock is halved.
@export var steer_falloff_speed: float = 12.0
## How fast the wheels track the steering target (rad/s).
@export var steer_speed: float = 3.5
@export var max_health: float = 100.0
## Velocity change (m/s) in a single physics tick that starts counting as a
## crash — normal driving, braking, and landings stay below this.
@export var impact_threshold: float = 6.0
@export var impact_damage_scale: float = 4.0
## Engine output fraction left when barely alive (limp-home floor).
@export var limp_floor: float = 0.25

var health: float = 100.0

var _driver: Node3D = null
var _prev_velocity: Vector3 = Vector3.ZERO

@onready var _camera: Camera3D = $CameraPivot/SpringArm/Camera
@onready var _exit_point: Marker3D = $ExitPoint


func has_driver() -> bool:
	return _driver != null


func enter(driver: Node3D) -> void:
	_driver = driver
	_camera.current = true


## Releases the driver and returns a safe world position to step out at.
func exit() -> Vector3:
	_driver = null
	_camera.current = false
	return _exit_point.global_position


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	_track_impacts()
	if _driver == null:
		engine_force = 0.0
		brake = max_brake * 0.05
		steering = move_toward(steering, 0.0, steer_speed * delta)
		return

	var throttle := Input.get_axis("move_back", "move_forward")
	var steer_input := Input.get_axis("move_right", "move_left")
	var speed := linear_velocity.length()
	var force := VehicleMotion.engine_force(throttle, max_engine_force, speed, top_speed)
	engine_force = force * VehicleDamage.engine_multiplier(health, max_health, limp_floor)
	var target := VehicleMotion.steer_target(steer_input, speed, max_steer, steer_falloff_speed)
	steering = move_toward(steering, target, steer_speed * delta)
	brake = max_brake if Input.is_action_pressed("jump") else 0.0


func _track_impacts() -> void:
	var velocity_change := (linear_velocity - _prev_velocity).length()
	_prev_velocity = linear_velocity
	var damage := VehicleDamage.impact_damage(
		velocity_change, impact_threshold, impact_damage_scale
	)
	if damage > 0.0:
		health = VehicleDamage.health_after(health, damage)
