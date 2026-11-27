"""Species-tinted larva rockets, built the way the mod will build them: one neutral base icon plus
three tinted layers (rear band, front band, larva). Pure species use one colour on both bands;
hybrids put parent A on the rear band and parent B on the front band."""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

SPECIES = {  # one hue per family, spread around the wheel so each stays readable at 32 px
    'Biter': (1.00, 0.52, 0.10),
    'Spitter': (0.45, 0.85, 0.20),
    'Worm': (0.62, 0.38, 0.95),
    'Pentapod': (0.20, 0.80, 0.85),
    'Hatchling': (0.95, 0.15, 0.12),
}
HYBRIDS = [('Skitterpod', 'Biter', 'Pentapod'), ('Spitworm', 'Spitter', 'Worm'), ('Lavapod', 'Pentapod', 'Hatchling')]

L = {k: Image.open(f'bl5/rocket-{k}.png').convert('RGBA') for k in ('base', 'band_rear', 'band_front', 'larva')}


def tint(img, col):
    a = np.array(img).astype(np.float32)
    a[..., :3] *= np.array(col)[None, None] * 1.25  # masks are pale grey; lift so the tint reads at full strength
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def rocket(rear, front, larva_col):
    out = L['base'].copy()
    for key, col in (('larva', larva_col), ('band_rear', rear), ('band_front', front)):
        out.alpha_composite(tint(L[key], col))
    return out


def mix(a, b):
    return tuple((x + y) / 2 for x, y in zip(a, b))


if __name__ == '__main__':
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 18)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    items = [(n, rocket(c, c, c), 'species') for n, c in SPECIES.items()]
    items += [(f'{h} ({a} × {b})', rocket(SPECIES[a], SPECIES[b], mix(SPECIES[a], SPECIES[b])), 'hybrid') for h, a, b in HYBRIDS]
    CW, RH = 270, 210
    sheet = Image.new('RGB', (CW * 4, 40 + RH * 2), (34, 31, 26)); d = ImageDraw.Draw(sheet)
    d.text((14, 10), 'Larva rocket: band and larva tinted per species. Hybrids: rear band = parent A, front band = parent B.', fill=(220, 215, 205), font=small)
    for i, (name, img, kind) in enumerate(items):
        x, y = 10 + (i % 4) * CW, 40 + (i // 4) * RH
        d.text((x + 4, y), name, fill=(240, 200, 120) if kind == 'species' else (150, 200, 240), font=small)
        for sz, dx, dy in ((128, 0, 24), (64, 144, 24), (32, 144, 102)):
            pad = 4
            d.rectangle([x + dx, y + dy, x + dx + sz + 2 * pad, y + dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
            im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, y + dy + pad), im)
    sheet.save('/home/claude/preview/rocket-species-tints.png')
