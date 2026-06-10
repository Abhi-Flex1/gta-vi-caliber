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
