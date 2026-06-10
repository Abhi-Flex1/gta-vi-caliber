extends RefCounted
## Unit tests for VehicleMotion (runner contract: test_* methods return true).


func test_full_throttle_at_standstill_gives_max_force() -> bool:
	return absf(VehicleMotion.engine_force(1.0, 2600.0, 0.0, 38.0) - 2600.0) < 0.0001


func test_force_tapers_to_zero_at_top_speed() -> bool:
	return absf(VehicleMotion.engine_force(1.0, 2600.0, 38.0, 38.0)) < 0.0001


func test_force_is_half_at_half_top_speed() -> bool:
	return absf(VehicleMotion.engine_force(1.0, 2600.0, 19.0, 38.0) - 1300.0) < 0.0001


func test_reverse_throttle_gives_negative_force() -> bool:
	return VehicleMotion.engine_force(-1.0, 2600.0, 0.0, 38.0) < 0.0


func test_throttle_is_clamped() -> bool:
	return absf(VehicleMotion.engine_force(5.0, 2600.0, 0.0, 38.0) - 2600.0) < 0.0001


func test_degenerate_top_speed_gives_no_force() -> bool:
	return VehicleMotion.engine_force(1.0, 2600.0, 10.0, 0.0) == 0.0


func test_steer_limit_is_full_lock_when_parked() -> bool:
	return absf(VehicleMotion.steer_limit(0.0, 0.55, 12.0) - 0.55) < 0.0001


func test_steer_limit_halves_at_falloff_speed() -> bool:
	return absf(VehicleMotion.steer_limit(12.0, 0.55, 12.0) - 0.275) < 0.0001


func test_steer_target_scales_input() -> bool:
	return absf(VehicleMotion.steer_target(0.5, 0.0, 0.55, 12.0) - 0.275) < 0.0001


func test_steer_target_clamps_input() -> bool:
	return absf(VehicleMotion.steer_target(3.0, 0.0, 0.55, 12.0) - 0.55) < 0.0001
