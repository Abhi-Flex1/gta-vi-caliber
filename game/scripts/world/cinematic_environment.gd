class_name CinematicEnvironment
extends RefCounted
## Builds a premium, cinematic Environment any scene can adopt for trailer-grade
## lighting: real-time global illumination (SDFGI) for bounced light, screen-space
## AO + indirect light + reflections (so glass curtain-walls mirror the sky and
## the street), volumetric fog for atmosphere, ACES tonemapping, tasteful bloom,
## and a subtle contrast/saturation grade.
##
## `build()` returns a fully-configured resource for offline/hero renders.
## `enhance(env, with_gi)` upgrades a scene's *existing* Environment in place —
## keeping its own day/night sky — which is what live world scenes use so the
## SkyController/DayNight horizon tinting keeps working. Pure + unit-tested in
## tests/unit/test_cinematic_environment.gd.


## Apply the premium grade/AO/reflections/bloom/fog to an existing Environment,
## preserving its sky and background. `with_gi` adds SDFGI (expensive — reserve
## for static hero scenes, not the streamed world where it flickers as districts
## page in). Returns the same env for chaining.
static func enhance(env: Environment, with_gi: bool = false) -> Environment:
	if env == null:
		env = Environment.new()

	# Sky-sourced ambient gives image-based lighting: metallic glass reflects the
	# sky even before SSR contributes on-screen bounces.
	if env.background_mode == Environment.BG_CLEAR_COLOR:
		env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# Filmic/ACES tonemapping keeps highlights from clipping to flat white.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.tonemap_exposure = 1.0

	# Contact AO between buildings/ground + indirect colour bleed.
	env.ssao_enabled = true
	env.ssao_radius = 3.0
	env.ssao_intensity = 2.2
	env.ssao_power = 1.5
	env.ssil_enabled = true

	# Screen-space reflections: the headline glass-curtain-wall realism cue —
	# towers mirror the street and neighbouring buildings.
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2

	# Bloom for emissive windows/streetlights at night and bright sky highlights.
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 1.1

	# Aerial-perspective depth fog down the avenues (cheap; volumetric below adds
	# god-ray-able density). Kept light so it reads as distance, not soup.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.74, 0.79, 0.86)
	env.fog_density = 0.0008
	env.fog_sky_affect = 0.2
	env.fog_aerial_perspective = 0.5
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.002
	env.volumetric_fog_albedo = Color(0.82, 0.86, 0.92)

	# A gentle cinematic grade — a touch more contrast and saturation.
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.14
	env.adjustment_brightness = 1.01

	# Real-time GI: bounced light, ambient occlusion and colour bleed.
	env.sdfgi_enabled = with_gi
	if with_gi:
		env.sdfgi_bounce_feedback = 0.5

	return env


static func build() -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = _premium_sky()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	return enhance(env, true)


## A tuned daytime ProceduralSkyMaterial: deep blue zenith, warm hazy horizon,
## a soft sun disk. Live world scenes override the horizon tint per time-of-day.
static func _premium_sky() -> ProceduralSkyMaterial:
	var m := ProceduralSkyMaterial.new()
	m.sky_top_color = Color(0.16, 0.33, 0.62)
	m.sky_horizon_color = Color(0.78, 0.80, 0.81)
	m.sky_curve = 0.12
	m.sky_energy_multiplier = 1.1
	m.ground_horizon_color = Color(0.74, 0.74, 0.72)
	m.ground_bottom_color = Color(0.42, 0.42, 0.40)
	m.sun_angle_max = 12.0
	m.sun_curve = 0.08
	return m
