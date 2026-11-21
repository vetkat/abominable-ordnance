"""Composite vanilla biter, spitter and spawner frames with their runtime tint masks.

Usage: python3 -I composite_monsters.py <factorio-data-dir> <out-dir>

Each layer is frame 0 of its sheet, placed by its sidecar shift.
Tints work as in the game: premultiplied colour times the tint, then
drawn over the layers below. Worms are left out: their masks are
very dark, and this maths does not give the colours their icons show.
"""
import functools
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# -I leaves the script's folder off sys.path. Put it back for sidecar.py.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import sidecar  # noqa: E402

# Values from base/prototypes/entity/enemy-constants.lua.
BITERS = {
    "small": (0.5, (0.60, 0.58, 0.51, 1), (0.62, 0.55, 0.2, 0.7)),
    "medium": (0.7, (0.49, 0.46, 0.51, 1), (0.6, 0.36, 0.36, 0.7)),
    "big": (1.0, (0.37, 0.40, 0.72, 1), (0.15, 0.55, 0.5, 0.7)),
    "behemoth": (1.2, (0.2, 0.25, 0.2, 1), (0.45, 0.82, 0.1, 0.7)),
}
SPITTERS = {
    "small": (0.5, (0.8, 0.45, 0, 1), (0.55, 0.6, 0.4, 0.8)),
    "medium": (0.7, (0.7, 0.2, 0.3, 1), (0.6, 0.5, 0.5, 0.8)),
    "big": (1.0, (0.1, 0.4, 0.6, 1), (0.45, 0.45, 0.45, 0.8)),
    "behemoth": (1.2, (0.3, 0.2, 0.06, 1), (0.45, 0.7, 0.12, 0.75)),
}
SPAWNERS = {
    "biter-spawner": (0.92, 0.54, 0, 0.5),
    "spitter-spawner": (0.99, 0.09, 0.09, 1),
}


@functools.cache
def layer(entity: Path, stem: str):
    """Frame 0 of a sheet as premultiplied float RGBA, and its pixel shift.

    Each size tints the same layers, so the cache decodes each sheet once.
    Callers must not change the array.
    """
    frame = sidecar.parse((entity / f"{stem}.lua").read_text())
    png = entity / f"{stem}.png"
    if not png.exists():
        png = entity / f"{stem}-1.png"
    crop = Image.open(png).crop((0, 0, frame["width"], frame["height"]))
    px = np.asarray(crop.convert("RGBA"), dtype=np.float32) / 255
    px[..., :3] *= px[..., 3:]  # px is new here, so premultiply in place.
    sx, sy = frame["shift"]
    # Layers share one scale, so 2 x by_pixel is the shift in file pixels.
    return px, (2 * sx, 2 * sy)


def composite(entity: Path, base: str, masks: list) -> Image.Image:
    layers = [layer(entity, base)] + [
        (px * np.asarray(tint, dtype=np.float32), shift)
        for stem, tint in masks
        for px, shift in [layer(entity, stem)]
    ]
    # Canvas big enough for every layer, centred on the entity position.
    half_w = max(abs(s[0]) + p.shape[1] / 2 for p, s in layers)
    half_h = max(abs(s[1]) + p.shape[0] / 2 for p, s in layers)
    cw, ch = int(np.ceil(2 * half_w)), int(np.ceil(2 * half_h))
    out = np.zeros((ch, cw, 4), dtype=np.float32)
    for px, (sx, sy) in layers:
        h, w = px.shape[:2]
        x0 = int(round(cw / 2 + sx - w / 2))
        y0 = int(round(ch / 2 + sy - h / 2))
        dst = out[y0:y0 + h, x0:x0 + w]
        dst[:] = px + dst * (1 - px[..., 3:])
    alpha = out[..., 3:]
    rgb = np.where(alpha > 0, out[..., :3] / np.maximum(alpha, 1e-6), 0)
    rgba = np.clip(np.concatenate([rgb, alpha], axis=-1), 0, 1)
    img = Image.fromarray((rgba * 255).astype(np.uint8))
    return img.crop(img.getbbox())


def lineup(images: list, scales: list) -> Image.Image:
    """Side by side at relative in-game size, on the ground line."""
    sized = [im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))))
             for im, s in zip(images, scales)]
    gap = 24
    w = sum(im.width for im in sized) + gap * (len(sized) + 1)
    h = max(im.height for im in sized) + 2 * gap
    sheet = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = gap
    for im in sized:
        sheet.alpha_composite(im, (x, h - gap - im.height))
        x += im.width + gap
    return sheet


def main(data: Path, out: Path) -> None:
    ent = data / "base/graphics/entity"
    out.mkdir(parents=True, exist_ok=True)
    for species, sizes in {"biter": BITERS, "spitter": SPITTERS}.items():
        for anim in (f"{species}-run", f"{species}-attack"):
            images, scales = [], []
            for size, (scale, tint1, tint2) in sizes.items():
                img = composite(ent / species, anim,
                                [(f"{anim}-mask1", tint1), (f"{anim}-mask2", tint2)])
                img.save(out / f"{size}-{species}--{anim}.png")
                images.append(img)
                scales.append(scale)
            lineup(images, scales).save(out / f"lineup--{species}--{anim}.png")
    for name, tint in SPAWNERS.items():
        composite(ent / "spawner", "spawner-idle",
                  [("spawner-idle-mask", tint)]).save(out / f"{name}--spawner-idle.png")
    print(f"wrote {len(list(out.glob('*.png')))} images to {out}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
