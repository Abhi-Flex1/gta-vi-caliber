class_name VeniceBeach
extends Node3D
## Root script for the coastal district scene. The shared DistrictLoader picks
## a spawn by "road vertex nearest the world origin", which for a district
## 20 km west of downtown lands on its inland edge — so once the district is
## built, re-anchor the player and spawn markers to the shoreline where the
## coastal postcard actually is.

## Local-metre point just behind the sand line (projection origin is shared
## by every district; Venice's shore runs near x = -21250).
@export var beach_spawn: Vector3 = Vector3(-21050.0, 1.5, 6900.0)


func _ready() -> void:
	var district := find_child("District", false, false)
	if district != null and district.has_signal("district_built"):
		district.district_built.connect(_on_district_built)


func _on_district_built(_buildings: int, _roads: int) -> void:
	for marker in get_tree().get_nodes_in_group("spawn_points"):
		if marker is Node3D:
			(marker as Node3D).global_position = beach_spawn
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node3D:
			(player as Node3D).global_position = beach_spawn + Vector3(0, 0.5, 0)
