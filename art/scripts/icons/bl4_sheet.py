from PIL import Image, ImageDraw, ImageFont
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
opts = [('D1 · Glass payload window', 'bl4/rocket-window.png', 'pointed steel nose'),
        ('D2 · Steel cage nose', 'bl4/rocket-cage.png', 'larva wedged in a cage'),
        ('E · Burst nose', 'bl2/rocket-burst.png', 'as before'),
        ('F · Bio-rocket', 'bl2/rocket-bio.png', 'as before')]
W, RH = 380, 330
sheet = Image.new('RGB', (W * 2, RH * 2 + 10), (34, 31, 26)); d = ImageDraw.Draw(sheet)
for i, (name, f, note) in enumerate(opts):
    x, y = (i % 2) * W, (i // 2) * RH + 10
    d.text((x + 14, y), name, fill=(240, 200, 120), font=font)
    d.text((x + 14, y + 26), note, fill=(180, 175, 168), font=small)
    img = Image.open(f).convert('RGBA')
    for sz, dx, dy in ((240, 14, 54), (64, 274, 54), (32, 274, 138)):
        pad = 6
        d.rectangle([x + dx, y + dy, x + dx + sz + 2 * pad, y + dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
        im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, y + dy + pad), im)
sheet.save('/home/claude/preview/rocket-options-2.png')
