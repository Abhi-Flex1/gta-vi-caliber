class_name LightningSystem
extends Node
## Lightning strikes during storms: random flashes that briefly illuminate the
## scene and produce a distant thunder rumble. Intensity scales with weather
## rain level — no lightning in clear skies, frequent in heavy storms.
##
## Pure timing math with no scene deps beyond the audio it triggers. Attaches
## to the weather controller or any storm-active node.

## Minimum / maximum seconds between flashes at full storm intensity.
@export var min_interval: float = 3.0
@export var max_interval: float = 12.0
## Flash duration (seconds) the OmniLight stays on.
@export var flash_duration: float = 0.08
## Peak light energy of the flash OmniLight (positioned above the player).
@export var flash_energy: float = 8.0
## Flash light range.
@export var flash_range: float = 200.0

var _timer: float = 0.0
var _flash_light: OmniLight3D = null
var _flash_timer: float = 0.0
var _rain_level: float = 0.0


func _ready() -> void:
	_flash_light = OmniLight3D.new()
	_flash_light.name = "LightningFlash"
	_flash_light.light_color = Color(0.9, 0.92, 1.0)
	_flash_light.light_energy = 0.0
	_flash_light.omni_range = flash_range
	_flash_light.omni_attenuation = 0.5
	_flash_light.shadow_enabled = false
	_flash_light.visible = false
	add_child(_flash_light)
	_timer = randf_range(min_interval, max_interval)


func set_rain_level(level: float) -> void:
	_rain_level = clampf(level, 0.0, 1.0)


func _process(delta: float) -> void:
	_tick_flash(delta)
	if _rain_level < 0.3:
		return
	_timer -= delta
	if _timer <= 0.0:
		_trigger_flash()
		var intensity_factor := (_rain_level - 0.3) / 0.7
		_timer = randf_range(lerpf(max_interval, min_interval, intensity_factor), max_interval)


func _trigger_flash() -> void:
	_flash_timer = flash_duration
	_flash_light.light_energy = flash_energy
	_flash_light.visible = true
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player := players[0] as Node3D
		if player != null:
			_flash_light.global_position = player.global_position + Vector3(0, 50, 0)


func _tick_flash(delta: float) -> void:
	if _flash_timer <= 0.0:
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_flash_light.light_energy = 0.0
		_flash_light.visible = false
	else:
		var t := _flash_timer / flash_duration
		_flash_light.light_energy = flash_energy * t
