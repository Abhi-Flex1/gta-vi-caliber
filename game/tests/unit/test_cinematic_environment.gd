extends RefCounted
## Unit tests for CinematicEnvironment — the premium lighting preset has the
## headline features (GI, screen-space reflections, bloom, volumetrics, filmic
## tonemap, sky) switched on, and enhance() upgrades an env in place.


func test_builds_an_environment() -> bool:
	return CinematicEnvironment.build() is Environment


func test_global_illumination_and_ao_on() -> bool:
	var e := CinematicEnvironment.build()
	return e.sdfgi_enabled and e.ssao_enabled and e.ssil_enabled


func test_screen_space_reflections_on() -> bool:
	# Glass curtain-walls need SSR to mirror the street/sky.
	return CinematicEnvironment.build().ssr_enabled


func test_bloom_and_volumetric_fog_on() -> bool:
	var e := CinematicEnvironment.build()
	return e.glow_enabled and e.volumetric_fog_enabled


func test_filmic_tonemap_and_grade() -> bool:
	var e := CinematicEnvironment.build()
	return e.tonemap_mode == Environment.TONE_MAPPER_ACES and e.adjustment_enabled


func test_has_a_sky() -> bool:
	return CinematicEnvironment.build().sky != null


func test_enhance_upgrades_in_place_without_forcing_gi() -> bool:
	# enhance() defaults to no SDFGI (streamed world) but still adds SSR + AO so
	# the live scene keeps its own sky while gaining the reflections/grade.
	var base := Environment.new()
	var e := CinematicEnvironment.enhance(base)
	return e == base and e.ssr_enabled and e.ssao_enabled and not e.sdfgi_enabled
