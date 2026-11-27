from PIL import Image, ImageDraw, ImageFont
import importlib.util, sys
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
cols = [('Brown (current)', 'bl/larva-biter.png'), ('Orange', 'bl/larva-biter-orange.png'), ('Red', 'bl/larva-biter-red.png')]
W = 360
sheet = Image.new('RGB', (W * 3, 360), (34, 31, 26)); d = ImageDraw.Draw(sheet)
for i, (name, f) in enumerate(cols):
    x = i * W
    d.text((x + 14, 10), name, fill=(240, 200, 120), font=font)
    img = Image.open(f).convert('RGBA')
    for sz, dx, dy in ((220, 14, 48), (64, 250, 48), (32, 250, 130)):
        pad = 6
        d.rectangle([x + dx, dy, x + dx + sz + 2 * pad, dy + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
        im = m.finish(img, sz); sheet.paste(im, (x + dx + pad, dy + pad), im)
sheet.save('/home/claude/preview/biter-larva-colours.png')
