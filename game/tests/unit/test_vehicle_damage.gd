extends RefCounted
## Unit tests for VehicleDamage (runner contract: test_* methods return true).


func test_gentle_velocity_change_is_free() -> bool:
	return VehicleDamage.impact_damage(3.0, 6.0, 4.0) == 0.0


func test_change_at_threshold_is_free() -> bool:
	return VehicleDamage.impact_damage(6.0, 6.0, 4.0) == 0.0


func test_crash_damage_scales_past_threshold() -> bool:
	return absf(VehicleDamage.impact_damage(10.0, 6.0, 4.0) - 16.0) < 0.0001


func test_health_decreases_by_damage() -> bool:
	return absf(VehicleDamage.health_after(100.0, 16.0) - 84.0) < 0.0001


func test_health_never_goes_negative() -> bool:
	return VehicleDamage.health_after(10.0, 50.0) == 0.0


func test_pristine_engine_runs_at_full_power() -> bool:
	return absf(VehicleDamage.engine_multiplier(100.0, 100.0, 0.25) - 1.0) < 0.0001


func test_half_health_engine_is_degraded() -> bool:
	var multiplier := VehicleDamage.engine_multiplier(50.0, 100.0, 0.25)
	return absf(multiplier - 0.625) < 0.0001


func test_barely_alive_engine_limps_at_floor() -> bool:
	var multiplier := VehicleDamage.engine_multiplier(0.001, 100.0, 0.25)
	return absf(multiplier - 0.25) < 0.001


func test_dead_engine_gives_no_power() -> bool:
	return VehicleDamage.engine_multiplier(0.0, 100.0, 0.25) == 0.0


func test_degenerate_max_health_gives_no_power() -> bool:
	return VehicleDamage.engine_multiplier(50.0, 0.0, 0.25) == 0.0
