"""Export a curated Factorio sprite reference set for art direction.

Usage: python3 -I export_sprites.py <factorio-data-dir> <out-dir>
"""
import re
import sys
from pathlib import Path

from PIL import Image

# -I leaves the script's folder off sys.path. Put it back for sidecar.py.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import sidecar  # noqa: E402

# Mod role -> vanilla entity folders it borrows or relates to.
ENTITIES = {
    "incubator (centrifuge)": ["base/graphics/entity/centrifuge"],
    "chamber (assembler 3)": ["base/graphics/entity/assembling-machine-3"],
    "pod (biochamber, chemical plant)": [
        "space-age/graphics/entity/biochamber",
        "base/graphics/entity/chemical-plant",
    ],
    "larva launcher (artillery turret)": ["base/graphics/entity/artillery-turret", "base/graphics/entity/artillery-wagon"],
    "larva shell (artillery shell)": ["base/graphics/entity/artillery-projectile"],
    "cryo ward context (cryogenic plant)": ["space-age/graphics/entity/cryogenic-plant"],
    "monsters nauvis": [
        "base/graphics/entity/biter",
        "base/graphics/entity/spitter",
        "base/graphics/entity/worm",
        "base/graphics/entity/spawner",
    ],
    "monsters gleba and captive": [
        "space-age/graphics/entity/captive-spawner",
        "space-age/graphics/entity/gleba-spawner",
        "space-age/graphics/entity/wriggler",
        "space-age/graphics/entity/stomper",
        "space-age/graphics/entity/strafer",
    ],
}

ICONS = {
    "base/graphics/icons": [
        "centrifuge", "assembling-machine-3", "chemical-plant",
        "artillery-turret", "artillery-shell", "artillery-targeting-remote",
        "plastic-bar", "coal", "poison-capsule", "rocket", "explosive-rocket",
        "fluid/sulfuric-acid", "biter-spawner", "spitter-spawner",
    ] + [f"{s}-{k}" for s in ("small", "medium", "big", "behemoth")
         for k in ("biter", "spitter", "worm")],
    "space-age/graphics/icons": [
        "biochamber", "cryogenic-plant", "captive-biter-spawner", "biter-egg",
        "pentapod-egg", "gleba-spawner",
    ] + [f"{s}-{k}" for s in ("small", "medium", "big")
         for k in ("wriggler", "stomper", "strafer")],
}

# Helper layers that only make sense composited in game.
SKIP = re.compile(
    r"mask|shadow|light|glow|reflection|integration|frozen|explosion|death|"
    r"decay|die|puddle|corpse|remnant|map-visualization|emission|foam|liquid|"
    r"water|smoke|fluid|effect-map|artillery-wagon-base|minimap"
)

PREVIEW_MAX = 1600


def frame_of(png: Path):
    """The sheet's sidecar values, from x.lua or, for x-1.png, x.lua."""
    for stem in (png.stem, re.sub(r"-\d+$", "", png.stem)):
        lua = png.with_name(stem + ".lua")
        if lua.exists() and (found := sidecar.parse(lua.read_text())):
            return found
    return None


def export_entity(src: Path, dst: Path) -> int:
    count = 0
    for png in sorted(src.rglob("*.png")):
        if SKIP.search(png.stem):
            continue
        frame = frame_of(png)
        # A split sheet (x-1.png, x-2.png ...) exports only its first file.
        part = re.search(r"-(\d+)$", png.stem)
        if frame and part and part.group(1) != "1":
            continue
        img = Image.open(png)
        rel = png.relative_to(src).with_suffix("")
        name = re.sub(r"-1$", "", "--".join(rel.parts))
        if frame:
            img.crop((0, 0, frame["width"], frame["height"])).convert("RGBA").save(
                dst / f"{name}--frame.png")
        if not frame or img.width > frame["width"] or img.height > frame["height"]:
            # img is not used after this, so shrinking it in place is safe.
            img = img.convert("RGBA")
            img.thumbnail((PREVIEW_MAX, PREVIEW_MAX))
            img.save(dst / f"{name}--sheet.png")
        count += 1
    return count


def icon_frame(png: Path) -> Image.Image:
    """Icons are mipmap strips. The largest square sits at the left."""
    img = Image.open(png)
    return img.crop((0, 0, img.height, img.height)).convert("RGBA")


def main(data: Path, out: Path) -> None:
    for role, folders in ENTITIES.items():
        for folder in folders:
            src = data / folder
            if not src.is_dir():
                print(f"missing: {folder}")
                continue
            dst = out / "entities" / role / src.name
            dst.mkdir(parents=True, exist_ok=True)
            print(f"{role}: {src.name}: {export_entity(src, dst)} layers")
    icons = out / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    for folder, names in ICONS.items():
        for name in names:
            png = data / folder / f"{name}.png"
            if png.exists():
                icon_frame(png).save(icons / f"{Path(name).name}.png")
            else:
                print(f"missing icon: {folder}/{name}")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
