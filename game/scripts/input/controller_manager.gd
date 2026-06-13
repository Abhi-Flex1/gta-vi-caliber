class_name ControllerManager
extends Node
## Centralises gamepad detection, vibration, and input-mapping toggling so
## other systems (player, camera, HUD) don't need to poll for controllers.
##
## Listens for joypad connection/disconnection events, manages the active
## device ID, and drives vibration via Input.start_joy_vibration. Also provides
## the "controller_aware" group contract (set_controller_enabled) so the
## settings panel can toggle gamepad support globally.

signal controller_connected(device_id: int)
signal controller_disconnected(device_id: int)

var _active_device: int = -1
var _enabled: bool = true
var _vibration_map: Dictionary = {}


func _ready() -> void:
	add_to_group("controller_aware")
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	# Check if a controller is already connected.
	for device_id in Input.get_connected_joypads():
		_active_device = device_id
		break


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		_active_device = device
		controller_connected.emit(device)
	elif device == _active_device:
		_active_device = -1
		controller_disconnected.emit(device)


func is_controller_connected() -> bool:
	return _active_device >= 0


func get_active_device() -> int:
	return _active_device


func set_controller_enabled(value: bool) -> void:
	_enabled = value


func is_enabled() -> bool:
	return _enabled


func vibrate(device: int, weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	if not _enabled or device < 0:
		return
	Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)


func vibrate_active(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	vibrate(_active_device, weak_magnitude, strong_magnitude, duration)


func get_joystick_axis(device: int, axis: JoyAxis) -> float:
	if not _enabled or device < 0:
		return 0.0
	return Input.get_joy_axis(device, axis)
