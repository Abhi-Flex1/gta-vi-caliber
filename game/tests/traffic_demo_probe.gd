extends SceneTree
## Headless end-to-end probe for the native traffic demo: loads traffic_demo.tscn
## and runs the IDM car-following sim for several seconds, asserting the key
## safety property — no car ever overlaps the one ahead (min gap stays positive)
## — plus finite, flowing traffic. Skips cleanly when the native module is absent.
##
## Run: godot --headless --path game --script res://tests/traffic_demo_probe.gd


func _initialize() -> void:
	var ok := _run()
	print("traffic_demo_probe: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _run() -> bool:
	if not ClassDB.class_exists("TrafficModel"):
		print("  native TrafficModel absent — skipping (OK)")
		return true

	var packed := load("res://scenes/world/traffic_demo.tscn")
	if packed == null:
		print("  could not load traffic_demo.tscn")
		return false
	var demo: TrafficDemo = packed.instantiate()
	demo.car_count = 24
	demo._ready()  # deterministic setup (don't depend on tree _ready timing)

	if not demo.native_active():
		print("  FAIL: TrafficModel exists but the demo did not activate it")
		return false

	for _f in 600:  # ~10 s at 60 Hz — long enough for the platoon to settle
		demo.step(1.0 / 60.0)

	var sum_speed := 0.0
	var ok := true
	for i in demo.car_count:
		var v: float = demo.speed[i]
		if not is_finite(v) or v < 0.0:
			print("  FAIL: car %d bad speed %s" % [i, str(v)])
			ok = false
			break
		sum_speed += v
	if not ok:
		return false

	var avg_speed := sum_speed / float(demo.car_count)
	# Safety: no collision ever (min gap across the whole run > 0) AND traffic
	# flows rather than gridlocking. One combined gate keeps return count in lint.
	if demo.min_gap_seen() <= 0.0 or avg_speed < 0.5:
		print(
			(
				"  FAIL: traffic unsafe/gridlocked (min gap %.2f, avg speed %.2f)"
				% [demo.min_gap_seen(), avg_speed]
			)
		)
		return false

	print(
		(
			"  OK: %d cars, no collisions (min gap %.2f m), avg speed %.1f m/s"
			% [demo.car_count, demo.min_gap_seen(), avg_speed]
		)
	)
	return true
