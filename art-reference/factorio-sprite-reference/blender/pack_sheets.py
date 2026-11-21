"""Pack the frames that render_factorio.py wrote into Factorio sheets.

Usage: python3 -I pack_sheets.py <render-out-dir> <mod-graphics-dir>

It writes <name>.png (or <name>-1.png, -2.png ...) with a <name>.lua
sidecar for each layer, and a draft <name>-icon.png with 4 mipmaps. The data
stage loads a sheet with util.sprite_load("__mod__/graphics/.../<name>",
{frame_count = ..., direction_count = ..., scale = 0.5}).
"""
import json
import sys
from pathlib import Path

from PIL import Image

# -I leaves the script's folder off sys.path. Put it back.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import factorio_layout as L  # noqa: E402

ICON_SIZE, ICON_MIPMAPS = 64, 4


def layer_name(name, layer):
    return name if layer == "main" else f"{name}-{layer}"


def pack(plan, load_cell):
    """Sheets and sidecars for every layer, as {file name: Image or str}.

    load_cell(layer, direction, frame) gives one rendered frame.
    """
    size, err = L.frame_size(*plan["tiles"], plan["headroom_px"])
    if err:
        return None, err
    sheet, err = L.sheet_plan(size, plan["frame_count"], plan["direction_count"],
                              plan["line_length"])
    if err:
        return None, err
    shift = L.camera(size, plan["pitch_deg"], plan["headroom_px"])["shift_px"]
    files = {}
    for layer in plan["layers"]:
        base = layer_name(plan["name"], layer)
        # These sheets are new here, so filling them in place is safe.
        sheets = [Image.new("RGBA", wh, (0, 0, 0, 0)) for wh in sheet["files"]]
        for cell in sheet["cells"]:
            sheets[cell["file"]].paste(
                load_cell(layer, cell["direction"], cell["frame"]), (cell["x"], cell["y"]))
        if len(sheets) == 1:
            files[f"{base}.png"] = sheets[0]
        else:
            files.update({f"{base}-{i + 1}.png": s for i, s in enumerate(sheets)})
        files[f"{base}.lua"] = L.sidecar_lua(
            size[0], size[1], shift, plan["line_length"], len(sheets),
            sheet["lines_per_file"])
    return files, None


def square_icon(frame):
    """The picture in a frame, cropped and centred on a square."""
    box = frame.getbbox()
    if box is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    pic = frame.crop(box)
    side = max(pic.size)
    out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    out.paste(pic, ((side - pic.width) // 2, (side - pic.height) // 2))
    return out


def icon_strip(icon, size, levels):
    """A Factorio icon: the picture at each mipmap size, side by side."""
    mips = L.icon_mipmaps(size, levels)
    strip = Image.new("RGBA", (sum(s for s, _ in mips), size), (0, 0, 0, 0))
    for s, x in mips:
        strip.paste(icon.resize((s, s), Image.LANCZOS), (x, 0))
    return strip


def main(render_dir, out_dir):
    plan = json.loads((render_dir / "plan.json").read_text())

    def load_cell(layer, direction, frame):
        return Image.open(render_dir / L.cell_path(layer, direction, frame))

    files, err = pack(plan, load_cell)
    if err:
        sys.exit(f"pack_sheets: {err}")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, content in files.items():
        if isinstance(content, str):
            (out_dir / name).write_text(content)
        else:
            content.save(out_dir / name)
    # A first draft of the icon: the model as it faces north. Paint over it.
    icon = square_icon(load_cell("main", 0, 0).convert("RGBA"))
    icon_strip(icon, ICON_SIZE, ICON_MIPMAPS).save(out_dir / f"{plan['name']}-icon.png")
    print(f"wrote {len(files)} files to {out_dir}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
