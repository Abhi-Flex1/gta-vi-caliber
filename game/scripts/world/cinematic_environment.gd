class_name CinematicEnvironment
extends RefCounted
## Builds a premium, cinematic Environment any scene can adopt for trailer-grade
## lighting: real-time global illumination (SDFGI) for bounced light and colour
## bleed, screen-space AO + indirect light, volumetric fog for atmosphere, ACES
## tonemapping, tasteful bloom, and a subtle contrast/saturation grade.
##
## Returned as a configured resource so any world scene (or the district loader)
## can do `world_environment.environment = CinematicEnvironment.build()`. Pure —
## the configuration is asserted in tests/unit/test_cinematic_environment.gd.


static func build() -> Environment:
	var env := Environment.new()

	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0

	# Filmic/ACES tonemapping keeps highlights from clipping to flat white.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0

	# Real-time GI: bounced light, ambient occlusion and colour bleed.
	env.sdfgi_enabled = true
	env.sdfgi_bounce_feedback = 0.5
	env.ssao_enabled = true
	env.ssil_enabled = true

	# Bloom for emissive windows/streetlights at night.
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15

	# Volumetric fog for depth and atmosphere down the avenues.
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.82, 0.86, 0.92)

	# A gentle cinematic grade — a touch more contrast and saturation.
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	env.adjustment_brightness = 1.0

	return env
