class_name Ballistics
extends RefCounted
## Pure hitscan math shared by every weapon.
##
## Static functions only — no scene access, no RNG (the caller passes a random
## sample in, so results are deterministic and testable). Covered by
## tests/unit/test_ballistics.gd.


## Perturb a forward aim direction within a cone. `sample` is a point in the
## unit disk (each component in [-1, 1], length <= 1) supplied by the caller's
## RNG; `right`/`up` are the camera basis. spread is the cone half-angle in
## radians: 0 returns forward unchanged. Result is unit length.
static func spread_direction(
	forward: Vector3, right: Vector3, up: Vector3, sample: Vector2, spread: float
) -> Vector3:
	if spread <= 0.0 or sample.is_zero_approx():
		return forward.normalized()
	var offset: Vector3 = (right * sample.x + up * sample.y) * tan(spread)
	return (forward + offset).normalized()


## Damage after distance falloff: full inside falloff_start, lerps down to
## base_damage * min_fraction by falloff_end, flat beyond. Guards a degenerate
## (end <= start) band by returning the near value.
static func damage_at_range(
	base_damage: float,
	distance: float,
	falloff_start: float,
	falloff_end: float,
	min_fraction: float
) -> float:
	if distance <= falloff_start:
		return base_damage
	if distance >= falloff_end or falloff_end <= falloff_start:
		return base_damage * min_fraction
	var t: float = (distance - falloff_start) / (falloff_end - falloff_start)
	return base_damage * lerpf(1.0, min_fraction, t)


## A point uniformly distributed in the unit disk from two independent [0, 1)
## samples (rejection-free, area-correct). Use to feed spread_direction without
## clumping shots toward the centre. Caller supplies the randoms so tests stay
## deterministic.
static func disk_sample(u_radius: float, u_angle: float) -> Vector2:
	var r: float = sqrt(clampf(u_radius, 0.0, 1.0))
	var a: float = u_angle * TAU
	return Vector2(cos(a), sin(a)) * r
