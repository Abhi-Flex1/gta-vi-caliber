extends RefCounted
## Unit tests for TouchStick radial deadzone and conditioning (pure, no tree).
## Exercises StickInput.radial_deadzone via the TouchStick's public interface.


func test_deadzone_returns_zero_inside() -> bool:
	var raw := Vector2(0.05, 0.03)
	var result := StickInput.radial_deadzone(raw, 0.15)
	return result.length_squared() < 0.0001


func test_deadzone_returns_nonzero_outside() -> bool:
	var raw := Vector2(0.8, 0.0)
	var result := StickInput.radial_deadzone(raw, 0.15)
	return result.length() > 0.1


func test_deadzone_preserves_direction() -> bool:
	var raw := Vector2(0.0, 1.0)
	var result := StickInput.radial_deadzone(raw, 0.15)
	return absf(result.x) < 0.0001 and result.y > 0.0


func test_response_exponent_shapes_magnitude() -> bool:
	var v := Vector2(0.5, 0.0)
	var linear := StickInput.apply_response(v, 1.0)
	var curved := StickInput.apply_response(v, 2.0)
	return curved.length() < linear.length()


func test_conditioned_output_unit_length() -> bool:
	var raw := Vector2(0.9, 0.3)
	var result := StickInput.conditioned(raw, 0.15, 1.0)
	return result.length() <= 1.001


func test_look_delta_frame_rate_independent() -> bool:
	var raw := Vector2(1.0, 0.0)
	var d1 := StickInput.look_delta(raw, 0.15, 1.0, 2.0, 0.016)
	var d2 := StickInput.look_delta(raw, 0.15, 1.0, 2.0, 0.033)
	return absf(d1.x / 0.016 - d2.x / 0.033) < 0.01


func test_movement_uses_keyboard_when_stronger() -> bool:
	var keys := Vector2(1.0, 0.0)
	var stick := Vector2(0.3, 0.0)
	var result := StickInput.movement(keys, stick, 0.15, 1.0)
	return result.length() >= 0.9


func test_movement_uses_stick_when_stronger() -> bool:
	var keys := Vector2(0.1, 0.0)
	var stick := Vector2(0.9, 0.0)
	var result := StickInput.movement(keys, stick, 0.15, 1.0)
	return result.length() > 0.5
