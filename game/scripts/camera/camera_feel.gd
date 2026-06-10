class_name CameraFeel
extends RefCounted
## Pure camera-feel math (FOV kick, smoothing) for OrbitCamera.
##
## Static functions only, no scene access — same testable-core pattern as
## PlayerMotion (docs/ARCHITECTURE.md). Covered by
## tests/unit/test_camera_feel.gd.


## How far into "sprinting" the current speed is, 0..1. Used to blend the
## FOV kick in proportionally instead of snapping on a key press.
static func sprint_blend(speed: float, walk_speed: float, sprint_speed: float) -> float:
	if sprint_speed <= walk_speed:
		return 0.0
	return clampf((speed - walk_speed) / (sprint_speed - walk_speed), 0.0, 1.0)


## Target field of view for a sprint blend amount.
static func fov_for_blend(base_fov: float, kick: float, blend: float) -> float:
	return base_fov + kick * blend


## Frame-rate-independent exponential approach: composing two half-steps
## gives exactly one full step, so feel doesn't change with FPS.
static func exp_smoothed(current: float, target: float, smoothing: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-smoothing * delta))
