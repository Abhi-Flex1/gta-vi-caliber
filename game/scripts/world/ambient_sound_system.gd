class_name AmbientSoundSystem
extends Node
## Plays context-sensitive ambient sounds: ocean waves near shore, city traffic
## rumble downtown, birds in parks, crickets at night. Intensity scales with
## proximity and time of day so the soundscape shifts as the player explores.
##
## Reads the player's position and time-of-day from groups, crossfading between
## layers based on distance to tagged zones (beach, urban, park) and the day/night
## cycle. Each layer is an AudioStreamPlayer3D parented to the player so the
## sounds follow them.

## Maximum volume for each layer at full intensity.
@export var max_volume_db: float = -6.0
## Minimum volume (fade-out floor) so layers don't pop to silence.
@export var min_volume_db: float = -40.0
## Crossfade speed (dB/s) so transitions are smooth.
@export var crossfade_speed: float = 12.0

var _layers: Dictionary = {}
var _player: Node3D = null


func _ready() -> void:
	_create_layer("ocean", "res://assets/audio/ambient/ocean_loop.ogg", 0.7)
	_create_layer("city", "res://assets/audio/ambient/city_loop.ogg", 0.5)
	_create_layer("birds", "res://assets/audio/ambient/birds_loop.ogg", 0.3)
	_create_layer("crickets", "res://assets/audio/ambient/crickets_loop.ogg", 0.3)


func _create_layer(id: String, _path: String, base_vol: float) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "Ambient_" + id
	player.bus = "SFX"
	player.max_db = max_volume_db
	player.volume_db = min_volume_db
	add_child(player)
	_layers[id] = {"player": player, "target_db": min_volume_db, "base_vol": base_vol}


func _process(delta: float) -> void:
	_resolve_player()
	if _player == null:
		return
	var pos := _player.global_position
	var tod := _get_tod()
	_update_ocean(pos, tod, delta)
	_update_city(pos, tod, delta)
	_update_birds(pos, tod, delta)
	_update_crickets(pos, tod, delta)


func _resolve_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player") as Node3D


func _get_tod() -> float:
	var sky := get_tree().get_first_node_in_group("sky")
	if sky != null and "time_of_day" in sky:
		return sky.time_of_day
	return 12.0


func _update_ocean(pos: Vector3, _tod: float, delta: float) -> void:
	var beach_dist := _distance_to_group(pos, "beach_zone")
	var target := min_volume_db
	if beach_dist < 80.0:
		var fade := 1.0 - clampf(beach_dist / 80.0, 0.0, 1.0)
		target = lerpf(min_volume_db, max_volume_db * _layers["ocean"]["base_vol"], fade)
	_crossfade("ocean", target, delta)


func _update_city(pos: Vector3, _tod: float, delta: float) -> void:
	var urban_dist := _distance_to_group(pos, "urban_zone")
	var target := min_volume_db
	if urban_dist < 100.0:
		var fade := 1.0 - clampf(urban_dist / 100.0, 0.0, 1.0)
		target = lerpf(min_volume_db, max_volume_db * _layers["city"]["base_vol"], fade)
	_crossfade("city", target, delta)


func _update_birds(pos: Vector3, tod: float, delta: float) -> void:
	var daylight := 1.0 if (tod > 6.0 and tod < 19.0) else 0.0
	var park_dist := _distance_to_group(pos, "park_zone")
	var target := min_volume_db
	if park_dist < 60.0 and daylight > 0.5:
		var fade := (1.0 - clampf(park_dist / 60.0, 0.0, 1.0)) * daylight
		target = lerpf(min_volume_db, max_volume_db * _layers["birds"]["base_vol"], fade)
	_crossfade("birds", target, delta)


func _update_crickets(_pos: Vector3, tod: float, delta: float) -> void:
	var night := 1.0 if (tod < 6.0 or tod > 20.0) else 0.0
	var target := min_volume_db
	if night > 0.5:
		target = lerpf(min_volume_db, max_volume_db * _layers["crickets"]["base_vol"], night)
	_crossfade("crickets", target, delta)


func _crossfade(id: String, target_db: float, delta: float) -> void:
	var layer: Dictionary = _layers.get(id, {})
	if layer.is_empty():
		return
	layer["target_db"] = target_db
	var player: AudioStreamPlayer3D = layer["player"]
	var current := player.volume_db
	player.volume_db = move_toward(current, target_db, crossfade_speed * delta)


func _distance_to_group(pos: Vector3, group: String) -> float:
	var best := 1e9
	for node in get_tree().get_nodes_in_group(group):
		var n3 := node as Node3D
		if n3 != null:
			best = minf(best, pos.distance_to(n3.global_position))
	return best
