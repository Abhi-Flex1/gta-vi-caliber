extends RefCounted
## Unit tests for OceanWaves — Gerstner sea math. Flat-water identities, the
## amplitude bound, time-periodicity and unit normals are what keep boats afloat
## and the mesh from looping.

var _one := [
	{"dir": Vector2(1, 0), "amplitude": 0.5, "wavelength": 10.0, "steepness": 0.5, "speed": 2.0}
]


func test_flat_water_has_no_displacement() -> bool:
	return OceanWaves.displacement(3.0, 4.0, 1.0, []) == Vector3.ZERO


func test_flat_water_normal_is_up() -> bool:
	return OceanWaves.normal(3.0, 4.0, 1.0, []).is_equal_approx(Vector3.UP)


func test_height_within_amplitude_bound() -> bool:
	var waves := OceanWaves.default_waves()
	var bound := OceanWaves.max_height(waves)
	var x := -30.0
	while x < 30.0:
		if absf(OceanWaves.surface_height(x, x * 0.5, 2.0, waves)) > bound + 0.001:
			return false
		x += 1.3
	return true


func test_single_wave_is_time_periodic() -> bool:
	# Period T = wavelength / speed = 10 / 2 = 5 s.
	var a := OceanWaves.surface_height(2.0, 0.0, 1.0, _one)
	var b := OceanWaves.surface_height(2.0, 0.0, 6.0, _one)
	return absf(a - b) < 0.001


func test_normals_are_unit_length() -> bool:
	var waves := OceanWaves.default_waves()
	for s in 8:
		var n := OceanWaves.normal(float(s) * 2.0, float(s), 1.5, waves)
		if absf(n.length() - 1.0) > 0.001:
			return false
	return true


func test_zero_steepness_has_no_horizontal_shift() -> bool:
	var flat_chop := [
		{"dir": Vector2(1, 0), "amplitude": 0.5, "wavelength": 10.0, "steepness": 0.0, "speed": 2.0}
	]
	# Sample away from a zero crossing so the vertical bob is non-zero.
	var d := OceanWaves.displacement(2.5, 0.0, 0.0, flat_chop)
	return absf(d.x) < 0.001 and absf(d.z) < 0.001 and absf(d.y) > 0.01


func test_surface_actually_moves_over_time() -> bool:
	var waves := OceanWaves.default_waves()
	var a := OceanWaves.surface_height(5.0, 5.0, 0.0, waves)
	var b := OceanWaves.surface_height(5.0, 5.0, 0.7, waves)
	return absf(a - b) > 0.0001
