class_name OrbitCamera
extends Node3D
## Mouse-look camera rig: this node yaws, the SpringArm child pitches.
##
## The SpringArm keeps the camera from clipping through world geometry
## (its collision mask excludes the player's layer).

const PITCH_MIN: float = -1.2
const PITCH_MAX: float = 0.5

@export var sensitivity: float = 0.003
## Over-the-shoulder framing: the arm pivot sits slightly right of the spine.
@export var shoulder_offset: Vector3 = Vector3(0.55, 0.0, 0.0)
@export var base_fov: float = 75.0
## Extra FOV blended in at full sprint speed for a sense of acceleration.
@export var sprint_fov_kick: float = 9.0
@export var fov_smoothing: float = 8.0
## Speeds (horizontal m/s) mapping to 0% and 100% of the FOV kick — keep in
## sync with Player.walk_speed / Player.sprint_speed.
@export var fov_walk_speed: float = 5.0
@export var fov_sprint_speed: float = 8.5

@onready var _arm: SpringArm3D = $SpringArm
@onready var _camera: Camera3D = $SpringArm/Camera


func _ready() -> void:
	_arm.position = shoulder_offset
	_camera.fov = base_fov


## Re-activate this rig's camera (e.g. after stepping out of a vehicle).
func make_current() -> void:
	_camera.current = true


func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody3D
	if body == null:
		return
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var blend := CameraFeel.sprint_blend(speed, fov_walk_speed, fov_sprint_speed)
	var target := CameraFeel.fov_for_blend(base_fov, sprint_fov_kick, blend)
	_camera.fov = CameraFeel.exp_smoothed(_camera.fov, target, fov_smoothing, delta)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	rotation.y -= motion.relative.x * sensitivity
	_arm.rotation.x = clampf(
		_arm.rotation.x - motion.relative.y * sensitivity, PITCH_MIN, PITCH_MAX
	)
