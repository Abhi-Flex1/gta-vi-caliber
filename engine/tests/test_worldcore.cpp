// Plain-C++ unit tests for engine logic that doesn't need a Godot runtime.
// Build & run: scons tests (see engine/SConstruct), or let CI do it.
// Keep this dependency-free (no test framework) until the suite outgrows it.
#include <cmath>
#include <cstdio>
#include <cstring>

#include "../src/native_bench/bench_kernels.h"
#include "../src/worldcore/impostor_core.h"
#include "../src/worldcore/tile_streamer_core.h"
#include "../src/worldcore/worldcore_version.h"

using worldcore_streaming::TileCoord;

static int failures = 0;

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            ++failures;                                                      \
            std::fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond); \
        }                                                                    \
    } while (0)

static void test_version_is_consistent() {
    char expected[32];
    std::snprintf(expected, sizeof(expected), "%d.%d.%d", WORLDCORE_VERSION_MAJOR,
            WORLDCORE_VERSION_MINOR, WORLDCORE_VERSION_PATCH);
    CHECK(std::strcmp(expected, WORLDCORE_VERSION_STRING) == 0);
    CHECK(std::strlen(WORLDCORE_VERSION_STRING) > 0);
}

static void test_sum_of_squares() {
    CHECK(worldcore_kernels::sum_of_squares(0) == 0);
    CHECK(worldcore_kernels::sum_of_squares(1) == 0); // sums i in [0, n)
    CHECK(worldcore_kernels::sum_of_squares(4) == 0 + 1 + 4 + 9);
    CHECK(worldcore_kernels::sum_of_squares(100) == 328350);
}

static void test_world_to_tile() {
    using worldcore_streaming::world_to_tile;
    CHECK(world_to_tile(0.0, 0.0, 256.0) == (TileCoord{0, 0}));
    CHECK(world_to_tile(257.0, 0.0, 256.0) == (TileCoord{1, 0}));
    CHECK(world_to_tile(-1.0, 0.0, 256.0) == (TileCoord{-1, 0}));
    CHECK(world_to_tile(0.0, 600.0, 256.0) == (TileCoord{0, 2}));
}

static void test_desired_tiles_within_radius_nearest_first() {
    using worldcore_streaming::desired_tiles;
    using worldcore_streaming::tile_center;
    // Stationary camera at the center of tile (0,0) — so that tile is uniquely
    // nearest (dist 0). (A camera on a tile corner would 4-way tie.)
    const double cam_x = 128.0, cam_z = 128.0;
    auto tiles = desired_tiles(cam_x, cam_z, 0.0, 0.0, 256.0, 300.0, 0.5);
    CHECK(!tiles.empty());
    CHECK(tiles.front() == (TileCoord{0, 0})); // closest
    for (const TileCoord &t : tiles) {
        double cx, cz;
        tile_center(t, 256.0, cx, cz);
        const double dx = cx - cam_x, dz = cz - cam_z;
        CHECK(std::sqrt(dx * dx + dz * dz) <= 300.0 + 1e-9);
    }
}

static void test_velocity_prioritizes_tiles_ahead() {
    using worldcore_streaming::desired_tiles;
    // Camera in tile (0,0) moving +x: the tile ahead (1,0) must load before the
    // symmetric tile behind (-1,0).
    auto tiles = desired_tiles(128.0, 128.0, 10.0, 0.0, 256.0, 800.0, 0.8);
    int ahead = -1, behind = -1;
    for (int i = 0; i < static_cast<int>(tiles.size()); ++i) {
        if (tiles[i] == (TileCoord{1, 0})) {
            ahead = i;
        }
        if (tiles[i] == (TileCoord{-1, 0})) {
            behind = i;
        }
    }
    CHECK(ahead >= 0 && behind >= 0);
    CHECK(ahead < behind);
}

static void test_unload_uses_hysteresis() {
    using worldcore_streaming::tiles_to_unload;
    std::vector<TileCoord> resident = {{0, 0}, {5, 0}};
    auto drop = tiles_to_unload(resident, 0.0, 0.0, 256.0, 1000.0);
    // (0,0) center ~181 m away stays; (5,0) center ~1414 m away unloads.
    CHECK(drop.size() == 1);
    CHECK(drop.front() == (TileCoord{5, 0}));
}

static void test_octa_encode_cardinals() {
    using worldcore_impostor::octa_encode;
    double u, v;
    octa_encode(0.0, 1.0, 0.0, u, v); // straight up -> center
    CHECK(std::fabs(u - 0.5) < 1e-9 && std::fabs(v - 0.5) < 1e-9);
    octa_encode(1.0, 0.0, 0.0, u, v); // +x -> right edge, mid height
    CHECK(std::fabs(u - 1.0) < 1e-9 && std::fabs(v - 0.5) < 1e-9);
    octa_encode(0.0, 0.0, 1.0, u, v); // +z -> mid width, top edge
    CHECK(std::fabs(u - 0.5) < 1e-9 && std::fabs(v - 1.0) < 1e-9);
    octa_encode(-1.0, 0.0, 0.0, u, v); // -x -> left edge
    CHECK(std::fabs(u - 0.0) < 1e-9 && std::fabs(v - 0.5) < 1e-9);
}

static void test_atlas_cell_clamps() {
    using worldcore_impostor::atlas_cell;
    int col, row;
    atlas_cell(0.0, 0.0, 8, col, row);
    CHECK(col == 0 && row == 0);
    atlas_cell(0.99, 0.99, 8, col, row);
    CHECK(col == 7 && row == 7);
    atlas_cell(1.0, 1.0, 8, col, row); // edge u=1 must clamp, not index 8
    CHECK(col == 7 && row == 7);
    atlas_cell(0.5, 0.5, 8, col, row);
    CHECK(col == 4 && row == 4);
}

static void test_projected_radius_shrinks_with_distance() {
    using worldcore_impostor::projected_radius_px;
    const double fov = 60.0 * 3.14159265358979323846 / 180.0;
    const double near_px = projected_radius_px(10.0, 50.0, fov, 1080.0);
    const double far_px = projected_radius_px(10.0, 500.0, fov, 1080.0);
    CHECK(near_px > far_px);
    CHECK(far_px > 0.0);
}

static void test_should_impostor_threshold() {
    using worldcore_impostor::should_impostor;
    const double fov = 60.0 * 3.14159265358979323846 / 180.0;
    // 10 m bound, 32 px threshold: close stays a mesh, far becomes an impostor.
    CHECK(!should_impostor(10.0, 50.0, fov, 1080.0, 32.0));
    CHECK(should_impostor(10.0, 500.0, fov, 1080.0, 32.0));
}

int main() {
    test_version_is_consistent();
    test_sum_of_squares();
    test_world_to_tile();
    test_desired_tiles_within_radius_nearest_first();
    test_velocity_prioritizes_tiles_ahead();
    test_unload_uses_hysteresis();
    test_octa_encode_cardinals();
    test_atlas_cell_clamps();
    test_projected_radius_shrinks_with_distance();
    test_should_impostor_threshold();
    if (failures > 0) {
        std::fprintf(stderr, "engine tests: %d failure(s)\n", failures);
        return 1;
    }
    std::printf("engine tests: all passed\n");
    return 0;
}
