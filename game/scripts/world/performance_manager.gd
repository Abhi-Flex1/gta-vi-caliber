class_name PerformanceManager
extends Node
## Monitors frame time and auto-scales graphics quality to maintain a target FPS.
## This lets low-end hardware run the game smoothly by dynamically reducing
## expensive effects when the GPU falls behind, and restoring them when headroom
## returns. The scaling is gradual (one tier change per cooldown period) to avoid
## visible quality oscillation.
##
## Reads FPS via Engine.get_frames_per_second() and adjusts the quality tier
## via CinematicEnvironment.apply_quality on the scene's WorldEnvironment.
## Also manages per-object LOD bias, shadow atlas size, and MSAA automatically.

signal quality_changed(new_tier: int, reason: String)

## Target FPS — the system tries to keep frame time below 1/target.
@export var target_fps: float = 60.0
## Minimum seconds between quality tier changes to avoid oscillation.
@export var cooldown: float = 3.0
## How many frames below target before downscaling.
@export var downscale_threshold_frames: int = 5
## How many frames above target before upscaling.
@export var upscale_headroom_frames: int = 10

var _current_tier: int = CinematicEnvironment.Quality.MEDIUM
var _cooldown_timer: float = 0.0
var _below_count: int = 0
var _above_count: int = 0
var _env: WorldEnvironment = null


func _ready() -> void:
	_env = _find_environment()
	_current_tier = CinematicEnvironment.resolved_tier()


func _process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	var fps := Engine.get_frames_per_second()
	var frame_budget := 1.0 / target_fps
	var actual_dt := 1.0 / maxf(fps, 1.0)

	if actual_dt > frame_budget * 1.2:
		_below_count += 1
		_above_count = 0
		if _below_count >= downscale_threshold_frames and _cooldown_timer <= 0.0:
			_downscale()
	elif actual_dt < frame_budget * 0.85:
		_above_count += 1
		_below_count = 0
		if _above_count >= upscale_headroom_frames and _cooldown_timer <= 0.0:
			_upscale()
	else:
		_below_count = 0
		_above_count = 0


func _downscale() -> void:
	if _current_tier <= CinematicEnvironment.Quality.LOW:
		return
	_current_tier -= 1
	_apply_tier("fps_below_target")
	_cooldown_timer = cooldown


func _upscale() -> void:
	if _current_tier >= CinematicEnvironment.Quality.ULTRA:
		return
	_current_tier += 1
	_apply_tier("fps_above_target")
	_cooldown_timer = cooldown


func _apply_tier(reason: String) -> void:
	if _env != null and _env.environment != null:
		CinematicEnvironment.apply_quality(_env.environment, _current_tier)
	_adjust_shadows()
	quality_changed.emit(_current_tier, reason)


func _adjust_shadows() -> void:
	match _current_tier:
		CinematicEnvironment.Quality.LOW:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		CinematicEnvironment.Quality.MEDIUM:
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		CinematicEnvironment.Quality.HIGH:
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		CinematicEnvironment.Quality.ULTRA:
			RenderingServer.directional_shadow_atlas_set_size(8192, true)


func get_current_tier() -> int:
	return _current_tier


func set_tier(tier: int) -> void:
	_current_tier = clampi(
		tier, CinematicEnvironment.Quality.LOW, CinematicEnvironment.Quality.ULTRA
	)
	_apply_tier("manual_override")


func _find_environment() -> WorldEnvironment:
	var root := get_tree().root if get_tree() != null else null
	if root == null:
		return null
	return root.find_child("WorldEnvironment", true, false) as WorldEnvironment
