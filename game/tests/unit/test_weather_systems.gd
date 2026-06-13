extends RefCounted
## Unit tests for WeatherState and WeatherEffects (pure, no scene tree).


func test_clear_start() -> bool:
	var state := WeatherState.new()
	return state.cloudiness == 0.0 and state.rain == 0.0 and state.wetness == 0.0


func test_front_targets_range() -> bool:
	for i in range(0, 100):
		var pos := float(i) / 100.0
		var targets := WeatherState.front_targets(pos)
		if targets["cloud"] < 0.0 or targets["cloud"] > 1.0:
			return false
		if targets["rain"] < 0.0 or targets["rain"] > 1.0:
			return false
	return true


func test_wetness_increases_in_rain() -> bool:
	var state := WeatherState.new()
	state.step(1.0, 1.0, 1.0)
	return state.wetness > 0.0


func test_wetness_decreases_when_dry() -> bool:
	var state := WeatherState.new()
	state.wetness = 0.5
	state.step(1.0, 0.0, 0.0)
	return state.wetness < 0.5


func test_label_rain() -> bool:
	var state := WeatherState.new()
	state.rain = 0.5
	return state.label() == "rain"


func test_label_clear() -> bool:
	var state := WeatherState.new()
	return state.label() == "clear"


func test_sun_dim_factor_at_noon() -> bool:
	var factor := WeatherState.sun_dim_factor(0.0)
	return absf(factor - 1.0) < 0.01


func test_sun_dim_factor_in_storm() -> bool:
	var factor := WeatherState.sun_dim_factor(1.0)
	return factor < 0.5


func test_grip_multiplier_dry() -> bool:
	return absf(WeatherEffects.grip_multiplier(0.0) - 1.0) < 0.01


func test_grip_multiplier_wet() -> bool:
	return WeatherEffects.grip_multiplier(1.0) < 1.0


func test_brake_distance_dry() -> bool:
	return absf(WeatherEffects.brake_distance_multiplier(0.0) - 1.0) < 0.01


func test_brake_distance_wet() -> bool:
	return WeatherEffects.brake_distance_multiplier(1.0) > 1.0


func test_visibility_clear() -> bool:
	return absf(WeatherEffects.visibility_range(100.0, 0.0) - 100.0) < 0.1


func test_visibility_foggy() -> bool:
	return WeatherEffects.visibility_range(100.0, 1.0) < 100.0


func test_traffic_speed_dry() -> bool:
	return absf(WeatherEffects.traffic_speed_multiplier(0.0) - 1.0) < 0.01


func test_traffic_speed_wet() -> bool:
	return WeatherEffects.traffic_speed_multiplier(1.0) < 1.0


func test_hydroplane_no_water() -> bool:
	return absf(WeatherEffects.hydroplane_risk(0.0, 30.0, 20.0)) < 0.01


func test_hydroplane_fast_wet() -> bool:
	return WeatherEffects.hydroplane_risk(1.0, 40.0, 20.0) > 0.0


func test_headlights_recommended_night() -> bool:
	return WeatherEffects.headlights_recommended(0.0, 0.8) == true


func test_headlights_not_recommended_day() -> bool:
	return WeatherEffects.headlights_recommended(0.0, 0.0) == false
