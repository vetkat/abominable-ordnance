"""Render a Blender model as Factorio frames. This is the Blender shell.

Run it inside Blender, on a .blend that holds one model at the origin,
facing north (+Y), at 1 Blender unit a tile:

  blender -b model.blend -P render_factorio.py -- \
      --name incubator --tiles 3x3 --headroom 64 \
      --frames 16 --directions 1 --line-length 8 --out render/incubator

Then pack the frames into sheets, sidecars and an icon:

  python3 -I pack_sheets.py render/incubator <mod>/graphics/entity/incubator

The script changes the scene in memory only. Do not save the .blend after.
The model animates over the scene's frame range. A turret or a creature
needs --directions 8, 16 or more. The shadow layer comes from a shadow
catcher on the ground, so the model must stand on z = 0.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import factorio_layout as L  # noqa: E402


def parse(argv):
    p = argparse.ArgumentParser(prog="render_factorio.py")
    p.add_argument("--name", required=True)
    p.add_argument("--tiles", default="3x3", help="footprint, as WxH tiles")
    p.add_argument("--headroom", type=int, default=64,
                   help="px above the footprint for tall parts")
    p.add_argument("--frames", type=int, default=1)
    p.add_argument("--directions", type=int, default=1)
    p.add_argument("--line-length", type=int, default=8)
    p.add_argument("--pitch", type=float, default=45.0,
                   help="camera degrees above the horizon")
    p.add_argument("--shadow-angle", type=float, default=L.VANILLA_SHADOW_ANGLE_DEG,
                   help="degrees south of east that shadows fall")
    p.add_argument("--sun-elevation", type=float, default=45.0,
                   help="sun degrees above the horizon; lower gives longer shadows")
    p.add_argument("--samples", type=int, default=64)
    p.add_argument("--out", required=True)
    args = p.parse_args(argv[argv.index("--") + 1:] if "--" in argv else [])
    args.tiles = [int(v) for v in args.tiles.lower().split("x")]
    return args


def fail(err):
    sys.exit(f"render_factorio: {err}")


def models(scene):
    return [o for o in scene.objects
            if o.parent is None and o.type not in {"CAMERA", "LIGHT"}]


def add_object(scene, name, data):
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    return obj


def setup(scene, size, cam, samples, sun_direction):
    """Camera, sun, render settings, a pivot and a shadow catcher."""
    r = scene.render
    r.engine = "CYCLES"
    scene.cycles.samples = samples
    r.film_transparent = True
    r.resolution_x, r.resolution_y = size
    r.resolution_percentage = 100
    r.pixel_aspect_x, r.pixel_aspect_y = cam["pixel_aspect_x"], cam["pixel_aspect_y"]
    r.image_settings.file_format = "PNG"
    r.image_settings.color_mode = "RGBA"
    r.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"

    cam_data = bpy.data.cameras.new("factorio-camera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = cam["ortho_scale"]
    cam_data.sensor_fit = cam["sensor_fit"]
    cam_data.clip_end = 2 * L.CAMERA_DISTANCE
    camera = add_object(scene, "factorio-camera", cam_data)
    camera.location = cam["location"]
    camera.rotation_euler = (cam["rotation_x"], 0.0, 0.0)
    scene.camera = camera

    if not any(o.type == "LIGHT" for o in scene.objects):
        sun_data = bpy.data.lights.new("factorio-sun", "SUN")
        sun_data.energy = 4.0
        sun = add_object(scene, "factorio-sun", sun_data)
        sun.rotation_euler = Vector(sun_direction).to_track_quat("-Z", "Y").to_euler()

    model = models(scene)
    pivot = add_object(scene, "factorio-pivot", None)
    for obj in model:
        obj.parent = pivot

    size_m = 4 * L.CAMERA_DISTANCE
    ground = bpy.data.meshes.new("factorio-ground")
    ground.from_pydata([(-size_m, -size_m, 0), (size_m, -size_m, 0),
                        (size_m, size_m, 0), (-size_m, size_m, 0)], [], [(0, 1, 2, 3)])
    catcher = add_object(scene, "factorio-ground", ground)
    catcher.is_shadow_catcher = True
    return pivot, catcher


def show_layer(layer, pivot, catcher):
    """main: the model alone. shadow: only its shadow on the ground."""
    catcher.hide_render = layer == "main"
    for obj in pivot.children_recursive:
        obj.visible_camera = layer == "main"


def main():
    args = parse(sys.argv)
    scene = bpy.context.scene
    def check(result):
        value, err = result
        if err:
            fail(err)
        return value

    size = check(L.frame_size(*args.tiles, args.headroom))
    yaws = check(L.direction_yaws(args.directions))
    frames = check(L.scene_frames(scene.frame_start, scene.frame_end, args.frames))
    # Check the sheet layout now, so a bad one fails before a long render.
    check(L.sheet_plan(size, args.frames, args.directions, args.line_length))

    cam = L.camera(size, args.pitch, args.headroom)
    sun = L.sun_direction(args.shadow_angle, args.sun_elevation)
    pivot, catcher = setup(scene, size, cam, args.samples, sun)
    out = Path(args.out).resolve()
    layers = ["main", "shadow"]
    for layer in layers:
        show_layer(layer, pivot, catcher)
        for d, yaw in enumerate(yaws):
            pivot.rotation_euler = (0.0, 0.0, yaw)
            for f, scene_frame in enumerate(frames):
                scene.frame_set(scene_frame)
                scene.render.filepath = str(out / L.cell_path(layer, d, f))
                bpy.ops.render.render(write_still=True)

    (out / "plan.json").write_text(json.dumps({
        "name": args.name, "tiles": args.tiles, "headroom_px": args.headroom,
        "pitch_deg": args.pitch, "frame_count": args.frames,
        "direction_count": args.directions, "line_length": args.line_length,
        "layers": layers,
    }, indent=2))
    print(f"render_factorio: rendered {len(layers) * len(yaws) * len(frames)} frames to {out}")


main()
