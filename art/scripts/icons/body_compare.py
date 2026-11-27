"""Rocket body colour × band width, each with all five species, at the sizes the player sees."""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
from tint_preview import SPECIES, tint

LARVA = Image.open('bl5/rocket-larva.png').convert('RGBA')


def rocket(body, w, col):
    out = Image.open(f'bl6/base-{body}-{w}.png').convert('RGBA')
    out.alpha_composite(tint(LARVA, col))
    for k in ('band_rear', 'band_front'):
        out.alpha_composite(tint(Image.open(f'bl6/{k}-{w}.png').convert('RGBA'), col))
    return out


font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 17)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 13)
rows = [(b, w) for b in ('red', 'grey', 'olive', 'khaki') for w in ('0.12', '0.24')]
names = {'red': 'Red (current)', 'grey': 'Gunmetal grey', 'olive': 'Olive drab', 'khaki': 'Khaki'}
RH, CW = 96, 126
sheet = Image.new('RGB', (200 + CW * 5, 40 + RH * len(rows)), (34, 31, 26)); d = ImageDraw.Draw(sheet)
for i, sp in enumerate(SPECIES):
    d.text((200 + i * CW + 6, 12), sp, fill=(220, 215, 205), font=small)
for r, (b, w) in enumerate(rows):
    y = 40 + r * RH
    d.text((10, y + 18), names[b], fill=(240, 200, 120), font=font)
    d.text((10, y + 42), 'wide bands' if w == '0.24' else 'narrow bands', fill=(180, 175, 168), font=small)
    for i, col in enumerate(SPECIES.values()):
        img = rocket(b, w, col)
        x = 200 + i * CW
        for sz, dx, dy in ((64, 0, 6), (32, 74, 6)):
            pad = 4
            d.rectangle([x + dx, y + dy, x + dx + sz + 2 * pad, y + dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
            im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, y + dy + pad), im)
sheet.save('/home/claude/preview/rocket-body-compare.png')
