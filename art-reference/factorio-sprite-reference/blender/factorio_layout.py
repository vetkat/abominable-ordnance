"""Pure layout maths for Factorio sprite renders. No Blender, no I/O.

Every function that can fail returns (value, error): one of them is None.
Units: 1 Blender unit is 1 tile, and high-resolution sprites use 64 px a
tile. Blender +Y is north, as Factorio's screen-up.
"""
import math

PX_PER_TILE = 64
MAX_SHEET_PX = 8192  # Factorio refuses larger textures.
CAMERA_DISTANCE = 50.0


def direction_yaws(direction_count):
    """Model yaw for each Factorio direction, clockwise from north."""
    if direction_count < 1:
        return None, "direction_count must be 1 or more"
    step = 2 * math.pi / direction_count
    return [-i * step for i in range(direction_count)], None


def scene_frames(start, end, count):
    """count timeline frames spread evenly from start, for one loop."""
    length = end - start + 1
    if count < 1 or length < count:
        return None, f"the timeline has {length} frames, fewer than {count}"
    return [start + (i * length) // count for i in range(count)], None


def frame_size(tiles_w, tiles_h, headroom_px):
    """Pixel size of one frame: the footprint plus space above it."""
    if tiles_w < 1 or tiles_h < 1:
        return None, "the footprint needs at least 1x1 tile"
    return (tiles_w * PX_PER_TILE, tiles_h * PX_PER_TILE + headroom_px), None


def sheet_plan(frame_size, frame_count, direction_count, line_length,
               max_px=MAX_SHEET_PX):
    """Where each frame goes, in Factorio's order, split over files.

    Factorio reads direction 0 frames 0..n-1, then direction 1, and so
    on, line_length frames a row. Rows that do not fit in max_px go on to
    the next file, as util.sprite_load expects (lines_per_file).
    """
    w, h = frame_size
    if line_length < 1:
        return None, "line_length must be 1 or more"
    if frame_count < 1 or direction_count < 1:
        return None, "frame_count and direction_count must be 1 or more"
    total = frame_count * direction_count
    columns = min(line_length, total)
    if w * columns > max_px or h > max_px:
        return None, f"a row of {columns} frames does not fit in {max_px} px"
    rows = math.ceil(total / line_length)
    lines_per_file = min(rows, max_px // h)
    cells = []
    for index in range(total):
        row = index // line_length
        cells.append({
            "direction": index // frame_count,
            "frame": index % frame_count,
            "file": row // lines_per_file,
            "x": (index % line_length) * w,
            "y": (row % lines_per_file) * h,
        })
    file_count = math.ceil(rows / lines_per_file)
    files = [(columns * w, min(lines_per_file, rows - f * lines_per_file) * h)
             for f in range(file_count)]
    return {"cells": cells, "files": files, "lines_per_file": lines_per_file}, None


def camera(frame_size, pitch_deg, headroom_px=0):
    """Orthographic camera that draws a ground tile as 64 x 64 px.

    At a pitch of p degrees above the horizon, ground depth shrinks by
    sin(p) on the view plane, so the pixel aspect stretches it back.
    Headroom moves the view up so the extra space sits above the footprint.
    """
    w, _ = frame_size
    pitch = math.radians(pitch_deg)
    # Ground depth on screen: 1 tile is sin(pitch) view-plane units.
    lift = (headroom_px / 2) / PX_PER_TILE * math.sin(pitch)
    tilt = math.pi / 2 - pitch
    # The camera sits south of the origin and looks north and down.
    # Its up vector after the tilt is (0, cos(tilt), sin(tilt)).
    location = (
        0.0,
        -CAMERA_DISTANCE * math.cos(pitch) + lift * math.cos(tilt),
        CAMERA_DISTANCE * math.sin(pitch) + lift * math.sin(tilt),
    )
    return {
        "sensor_fit": "HORIZONTAL",
        "ortho_scale": w / PX_PER_TILE,
        "rotation_x": tilt,
        "location": location,
        # Blender needs aspects of 1 or more: widen x rather than shrink y.
        "pixel_aspect_x": 1 / math.sin(pitch),
        "pixel_aspect_y": 1.0,
        "shift_px": (0, -(headroom_px // 2)),
    }


def sidecar_lua(width, height, shift_px, line_length, file_count, lines_per_file):
    """A .lua sidecar in the vanilla format that util.sprite_load reads.

    util.by_pixel takes half of the high-resolution pixel shift.
    """
    sx, sy = (float(v) / 2 for v in shift_px)
    lines = [
        "return", "{",
        f"  width = {width},",
        f"  height = {height},",
        f"  shift = util.by_pixel({sx}, {sy}),",
        f"  line_length = {line_length},",
    ]
    if file_count > 1:
        lines.append("  filenames = {")
        lines += [f'    "-{i + 1}.png",' for i in range(file_count)]
        lines.append("  },")
        lines.append(f"  lines_per_file = {lines_per_file},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def icon_mipmaps(size, levels):
    """(size, x) of each mipmap in an icon strip, largest on the left."""
    out, x = [], 0
    for level in range(levels):
        s = size >> level
        out.append((s, x))
        x += s
    return out


def cell_path(layer, direction, frame):
    """Where render_factorio.py writes a frame and pack_sheets.py reads it."""
    return f"cells/{layer}/d{direction:02}_f{frame:03}.png"
