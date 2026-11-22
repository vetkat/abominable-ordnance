import math

import factorio_layout as L


def test_directions_turn_clockwise_from_north():
    yaws, err = L.direction_yaws(4)
    assert err is None
    # Clockwise seen from above is a negative turn about Blender's Z.
    assert yaws == [0.0, -math.pi / 2, -math.pi, -3 * math.pi / 2]


def test_direction_count_must_be_positive():
    assert L.direction_yaws(0) == (None, "direction_count must be 1 or more")


def test_frame_size_is_64_px_a_tile_plus_headroom():
    assert L.frame_size(3, 3, 64) == ((192, 256), None)


def test_frame_size_rejects_an_empty_footprint():
    assert L.frame_size(0, 2, 0) == (None, "the footprint needs at least 1x1 tile")


def test_cells_run_frames_then_directions_in_rows():
    plan, err = L.sheet_plan(frame_size=(100, 50), frame_count=3,
                             direction_count=2, line_length=4)
    assert err is None
    # Factorio order: direction 0 frames 0..2, then direction 1 frames 0..2.
    assert plan["cells"][:4] == [
        {"direction": 0, "frame": 0, "file": 0, "x": 0, "y": 0},
        {"direction": 0, "frame": 1, "file": 0, "x": 100, "y": 0},
        {"direction": 0, "frame": 2, "file": 0, "x": 200, "y": 0},
        {"direction": 1, "frame": 0, "file": 0, "x": 300, "y": 0},
    ]
    assert plan["cells"][4] == {"direction": 1, "frame": 1, "file": 0, "x": 0, "y": 50}
    assert plan["files"] == [(400, 100)]


def test_tall_sheets_split_into_files_under_the_limit():
    plan, err = L.sheet_plan(frame_size=(400, 300), frame_count=16,
                             direction_count=16, line_length=8, max_px=8192)
    assert err is None
    # 32 rows of 300 px. 27 rows fit in 8192 px, so 2 files.
    assert plan["lines_per_file"] == 27
    assert len(plan["files"]) == 2
    assert plan["files"][1] == (3200, 5 * 300)
    last = plan["cells"][-1]
    assert (last["file"], last["y"]) == (1, 4 * 300)


def test_a_frame_wider_than_the_limit_is_an_error():
    plan, err = L.sheet_plan(frame_size=(9000, 10), frame_count=1,
                             direction_count=1, line_length=1)
    assert plan is None and "8192" in err


def test_line_length_must_be_positive():
    assert L.sheet_plan((10, 10), 1, 1, 0)[1] == "line_length must be 1 or more"


def test_camera_squares_the_ground_tiles():
    cam = L.camera(frame_size=(192, 256), pitch_deg=45)
    # The view fits the width: 192 px at 64 px a tile is 3 tiles.
    assert cam["sensor_fit"] == "HORIZONTAL"
    assert math.isclose(cam["ortho_scale"], 3.0)
    assert math.isclose(cam["rotation_x"], math.radians(90 - 45))
    # The camera shortens ground depth by sin(pitch). The aspect stretches it back.
    assert math.isclose(cam["pixel_aspect_y"] / cam["pixel_aspect_x"],
                        math.sin(math.radians(45)))


def test_headroom_lifts_the_view_and_sets_the_shift():
    flat = L.camera((192, 192), 45)
    tall = L.camera((192, 256), 45, headroom_px=64)
    # The sprite centre sits 32 px above the entity centre.
    assert tall["shift_px"] == (0, -32) and flat["shift_px"] == (0, 0)
    # 32 px on screen is 0.5 tile of ground depth, foreshortened by sin(45).
    lift = math.dist(tall["location"], flat["location"])
    assert math.isclose(lift, 0.5 * math.sin(math.radians(45)))


def test_sidecar_matches_the_vanilla_format():
    lua = L.sidecar_lua(width=192, height=256, shift_px=(0, -32),
                        line_length=8, file_count=2, lines_per_file=27)
    assert lua == (
        "return\n{\n"
        "  width = 192,\n"
        "  height = 256,\n"
        "  shift = util.by_pixel(0.0, -16.0),\n"
        "  line_length = 8,\n"
        "  filenames = {\n    \"-1.png\",\n    \"-2.png\",\n  },\n"
        "  lines_per_file = 27,\n"
        "}\n"
    )


def test_single_file_sidecar_has_no_filenames():
    lua = L.sidecar_lua(64, 64, (0, 0), 1, 1, 1)
    assert "filenames" not in lua and "lines_per_file" not in lua


def test_icon_mipmaps_sit_left_to_right():
    assert L.icon_mipmaps(64, 4) == [(64, 0), (32, 64), (16, 96), (8, 112)]


def test_scene_frames_spread_evenly_over_the_timeline():
    assert L.scene_frames(1, 48, 4) == ([1, 13, 25, 37], None)
    assert L.scene_frames(1, 1, 1) == ([1], None)


def test_scene_frames_needs_a_frame_for_each_sample():
    assert L.scene_frames(1, 2, 3) == (None, "the timeline has 2 frames, fewer than 3")


def test_cell_path_names_layer_direction_and_frame():
    assert L.cell_path("shadow", 3, 12) == "cells/shadow/d03_f012.png"


def test_vanilla_shadow_angle_matches_the_centrifuge_offset():
    # The centrifuge shadow sits about 73 px east and 7 px south.
    assert math.isclose(math.tan(math.radians(L.VANILLA_SHADOW_ANGLE_DEG)), 7 / 73)


def test_sun_at_zero_angle_throws_shadows_due_east():
    x, y, z = L.sun_direction(0, 45)
    assert math.isclose(x, math.sqrt(0.5))
    assert math.isclose(y, 0, abs_tol=1e-12)
    assert math.isclose(z, -math.sqrt(0.5))


def test_positive_shadow_angle_turns_shadows_south():
    _, y, _ = L.sun_direction(30, 45)
    assert y < 0


def test_sun_direction_is_a_unit_vector():
    v = L.sun_direction(L.VANILLA_SHADOW_ANGLE_DEG, 30)
    assert math.isclose(math.hypot(*v), 1)


def test_lower_sun_travels_flatter():
    assert L.sun_direction(0, 20)[2] > L.sun_direction(0, 60)[2]
