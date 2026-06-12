extends SceneTree
## Capacity benchmark for the native crowd sim: how many agents can be stepped
## (SpatialHash rebuild + per-agent CrowdSteering) within a single 60 FPS frame
## budget (16 ms)? Answers the GTA-density question. Density is held ~constant
## across sizes (field scales with sqrt(n)) so it's a fair scaling test. Skips
## cleanly when the native modules are absent.
##
## Run: godot --headless --path game --script res://tests/crowd_capacity_probe.gd

const RADIUS := 4.0
const SIZES := [500, 1000, 2000, 4000]
const BUDGET_MS := 16.0  # 60 FPS frame budget
const REPS := 5


func _initialize() -> void:
	var ok := _run()
	print("crowd_capacity_probe: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _run() -> bool:
	if not (ClassDB.class_exists("SpatialHash") and ClassDB.class_exists("CrowdSteering")):
		print("  native crowd modules absent — skipping (OK)")
		return true

	var hash: Object = ClassDB.instantiate("SpatialHash")
	hash.set("cell_size", RADIUS)
	var steer: Object = ClassDB.instantiate("CrowdSteering")
	steer.set("neighbor_radius", RADIUS)

	var capacity := 0
	for n in SIZES:
		var ms := _step_ms(n, hash, steer)
		var under := ms < BUDGET_MS
		if under:
			capacity = n
		print("  N=%d: %.2f ms/step %s" % [n, ms, "(<16ms)" if under else "(over budget)"])

	print("  capacity ~%d agents within the 16 ms (60 FPS) budget" % capacity)
	# GTA-density bar: at least ~1000 simulated agents per frame at 60 FPS.
	return capacity >= 1000


## Average wall-clock milliseconds for one full crowd step over `n` agents.
func _step_ms(n: int, hash: Object, steer: Object) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var span := sqrt(float(n)) * RADIUS  # ~constant density as n grows
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	pos.resize(n)
	vel.resize(n)
	for i in n:
		pos[i] = Vector2(rng.randf_range(-span, span), rng.randf_range(-span, span))
		vel[i] = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))

	var t0 := Time.get_ticks_usec()
	for _r in REPS:
		hash.call("clear")
		for i in n:
			hash.call("insert", i, pos[i])
		for i in n:
			var ids: PackedInt32Array = hash.call("query_radius", pos[i], RADIUS)
			var npos := PackedVector2Array()
			var nvel := PackedVector2Array()
			for id in ids:
				if id == i:
					continue
				npos.append(pos[id])
				nvel.append(vel[id])
			steer.call("steer", pos[i], vel[i], npos, nvel)
	var total_us := Time.get_ticks_usec() - t0
	return float(total_us) / float(REPS) / 1000.0
