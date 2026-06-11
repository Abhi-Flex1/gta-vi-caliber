extends RefCounted
## Unit tests for CinematicEnvironment — the premium lighting preset has the
## headline features (GI, bloom, volumetrics, filmic tonemap, sky) switched on.


func test_builds_an_environment() -> bool:
	return CinematicEnvironment.build() is Environment


func test_global_illumination_and_ao_on() -> bool:
	var e := CinematicEnvironment.build()
	return e.sdfgi_enabled and e.ssao_enabled and e.ssil_enabled


func test_bloom_and_volumetric_fog_on() -> bool:
	var e := CinematicEnvironment.build()
	return e.glow_enabled and e.volumetric_fog_enabled


func test_filmic_tonemap_and_grade() -> bool:
	var e := CinematicEnvironment.build()
	return e.tonemap_mode == Environment.TONE_MAPPER_ACES and e.adjustment_enabled


func test_has_a_sky() -> bool:
	return CinematicEnvironment.build().sky != null
