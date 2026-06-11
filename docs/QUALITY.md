# Quality ledger — state vs the trailer bar

Dated, honest assessments of where the build stands against the VISION.md
bar (trailer-fidelity coastal open world). Updated by whoever runs a
playtest/capture pass; newest entry first. Captures referenced live in
`/tmp/gta6_playtest/` locally — judge from a fresh run, not memory.

## 2026-06-10 — first full-loop assessment

Verified playable end-to-end by automated headed playtest
(`game/tests/playtest_capture.gd`): walk → enter car → drive 20 m/s with
rising engine note → exit → district load → 5 km floating-origin shift with
0.00 m drift. 439 unit tests green; native WorldCore module loading.

| Dimension | State | Bar | Verdict |
| --- | --- | --- | --- |
| Locomotion/feel | Coyote time, jump buffer, analog gait, camera probe | Fluid traversal | **Near** (no anims for jump/land yet) |
| Vehicles | Torque-curve powertrain, traction circle, weight transfer, damage, audio | Convincing handling | **Near** (greybox bodies) |
| Character | Procedural humanoid v2: tapered limbs, hair, palette variety | Trailer humans | **Far** (no faces, no real anim set) |
| City geometry | 199 real-footprint towers, 901 road ribbons | Dense believable city | **Mid** (no sidewalks/props/foliage) |
| Materials | Untextured slabs; façade shader in flight | Worn stucco/concrete/glass | **Far → Mid** once façades land |
| Lighting/time | ToD cycle in flight: dusk + lit-window night shots already read | Golden hour money shots | **Mid** |
| Water | Gerstner ocean v1: turquoise shallows, sun glitter, sandbars | Postcard coast | **Mid** (no foam/SSR — v2) |
| Life | ~20 wandering pedestrians, police pursuit, wanted stars | Crowded streets, traffic | **Far** (no vehicles traffic, thin density) |
| Audio | Procedural engine/tire/impact/footsteps | Full soundscape | **Mid** (no ambience/music/radio) |
| Play | Weapons loop, health/armor, wanted, missions WIP | "It's a game" | **Mid** |

**Highest-leverage gaps, in order** (each maps to a roadmap box):
1. **Traffic + parked cars** (M4 road graph) — empty streets break the
   fantasy harder than any material does.
2. **Street furniture + foliage pass** — palms, signs, awnings; the OSM data
   has road classes to seed placement. (M4 blockout box.)
3. **Coastal district** — the bar is a *coast*: the ocean v1 + a shoreline
   district together produce the postcard shot. (M4 blockout box.)
4. **Character animation set** — run/idle/jump on the procedural rig (M1).
5. **GI/volumetrics pass at golden hour** (M6 lighting) — cheap to try with
   SDFGI now that ToD exists; do after materials so bounce has color to work
   with.

**Process note:** all three sun/clock systems being built in parallel
(SkyController in sandbox, DaylightMath/TimeOfDay in the district, DayNight
on feat/osm-worldgen) need consolidation into one — see ROADMAP M4 box;
don't add a fourth.
