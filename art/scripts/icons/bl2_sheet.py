from PIL import Image, ImageDraw, ImageFont
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
rows = [('Stasis ward', [('A · Cryo canister', 'ward-canister'), ('B · Frozen pod', 'ward-pod'), ('C · Hex containment cell', 'ward-hex')]),
        ('Larva rocket', [('D · Glass nose', 'rocket-glass'), ('E · Burst nose', 'rocket-burst'), ('F · Bio-rocket', 'rocket-bio')])]
W, RH = 380, 340
sheet = Image.new('RGB', (W * 3, RH * 2 + 20), (34, 31, 26)); d = ImageDraw.Draw(sheet)
for r, (group, opts) in enumerate(rows):
    for c, (name, f) in enumerate(opts):
        x, y = c * W, r * RH + 10
        d.text((x + 14, y), name, fill=(240, 200, 120), font=font)
        d.text((x + 14, y + 26), group, fill=(180, 175, 168), font=small)
        img = Image.open(f'bl2/{f}.png').convert('RGBA')
        for sz, dx, dy in ((240, 14, 56), (64, 274, 56), (32, 274, 140)):
            pad = 6
            d.rectangle([x + dx, y + dy, x + dx + sz + 2 * pad, y + dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
            im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, y + dy + pad), im)
sheet.save('/home/claude/preview/ward-rocket-options.png')
