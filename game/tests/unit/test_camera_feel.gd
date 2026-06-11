extends RefCounted
## Unit tests for CameraFeel (runner contract: test_* methods return true).


func test_blend_is_zero_at_walk_speed() -> bool:
	return CameraFeel.sprint_blend(5.0, 5.0, 8.5) == 0.0


func test_blend_is_one_at_sprint_speed() -> bool:
	return CameraFeel.sprint_blend(8.5, 5.0, 8.5) == 1.0


func test_blend_is_clamped_above_sprint_speed() -> bool:
	return CameraFeel.sprint_blend(20.0, 5.0, 8.5) == 1.0


func test_blend_is_clamped_below_walk_speed() -> bool:
	return CameraFeel.sprint_blend(0.0, 5.0, 8.5) == 0.0


func test_blend_is_proportional_between_speeds() -> bool:
	var blend := CameraFeel.sprint_blend(6.75, 5.0, 8.5)
	return absf(blend - 0.5) < 0.0001


func test_blend_handles_degenerate_speed_range() -> bool:
	return CameraFeel.sprint_blend(10.0, 5.0, 5.0) == 0.0


func test_fov_adds_full_kick_at_full_blend() -> bool:
	return absf(CameraFeel.fov_for_blend(75.0, 9.0, 1.0) - 84.0) < 0.0001


func test_fov_is_base_at_zero_blend() -> bool:
	return absf(CameraFeel.fov_for_blend(75.0, 9.0, 0.0) - 75.0) < 0.0001


func test_smoothing_converges_to_target() -> bool:
	var fov := 75.0
	for _i in range(200):
		fov = CameraFeel.exp_smoothed(fov, 84.0, 8.0, 0.016)
	return absf(fov - 84.0) < 0.01


func test_smoothing_is_frame_rate_independent() -> bool:
	# Two half-steps must land exactly where one full step does.
	var one_step := CameraFeel.exp_smoothed(75.0, 84.0, 8.0, 0.032)
	var half := CameraFeel.exp_smoothed(75.0, 84.0, 8.0, 0.016)
	var two_steps := CameraFeel.exp_smoothed(half, 84.0, 8.0, 0.016)
	return absf(one_step - two_steps) < 0.0001


func test_smoothing_never_overshoots() -> bool:
	var fov := CameraFeel.exp_smoothed(75.0, 84.0, 100.0, 1.0)
	return fov <= 84.0


func test_recenter_yaw_forward_is_zero() -> bool:
	# Moving "forward" (-Z) at yaw 0 keeps the camera where it is.
	return absf(CameraFeel.recenter_yaw(0.0, -1.0)) < 0.0001


func test_recenter_yaw_matches_motion_convention() -> bool:
	# The recenter yaw must reproduce the travel direction through PlayerMotion.
	var yaw := CameraFeel.recenter_yaw(1.0, 0.0)
	var dir := PlayerMotion.direction_from_input(Vector2(0, -1), yaw)
	return dir.is_equal_approx(Vector3(1, 0, 0))


func test_recenter_yaw_zero_velocity_safe() -> bool:
	return CameraFeel.recenter_yaw(0.0, 0.0) == 0.0


func test_approach_angle_steps_toward() -> bool:
	return absf(CameraFeel.approach_angle(0.0, 1.0, 0.25) - 0.25) < 0.0001


func test_approach_angle_clamps_to_target() -> bool:
	return absf(CameraFeel.approach_angle(0.0, 0.1, 0.25) - 0.1) < 0.0001


func test_approach_angle_takes_short_arc_over_wrap() -> bool:
	# From 3.0 toward -3.0 the short way is across the ±PI wrap (increasing),
	# not the long -6.0 sweep.
	return CameraFeel.approach_angle(3.0, -3.0, 0.1) > 3.0
