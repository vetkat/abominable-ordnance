from PIL import Image, ImageDraw, ImageFont
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
pairs = [('1 · Canister', 'canister', 'amber sedative gel', 'blue coolant, frost'),
         ('2 · Specimen jar', 'jar', 'green preservative', 'frozen, copper cooling coil'),
         ('3 · Hex cell', 'hex', 'amber sedation field', 'blue stasis field, frost')]
RH = 230
sheet = Image.new('RGB', (1120, 50 + RH * 3), (34, 31, 26)); d = ImageDraw.Draw(sheet)
d.text((250, 14), 'Stasis ward (early)', fill=(230, 225, 218), font=font); d.text((690, 14), 'Cryo ward (later)', fill=(230, 225, 218), font=font)
for i, (name, key, a, b) in enumerate(pairs):
    y = 50 + i * RH
    d.text((14, y + 10), name, fill=(240, 200, 120), font=font)
    for j, (suffix, note) in enumerate((('std', a), ('cryo', b))):
        x = 230 + j * 440
        img = Image.open(f'bl3/{key}-{suffix}.png').convert('RGBA')
        for sz, dx, dy in ((190, 0, 10), (64, 220, 10), (32, 310, 10)):
            pad = 6
            d.rectangle([x + dx, y + dy, x + dx + sz + 2 * pad, y + dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
            im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, y + dy + pad), im)
        d.text((x + 220, y + 100), note, fill=(180, 175, 168), font=small)
sheet.save('/home/claude/preview/ward-pairs.png')
