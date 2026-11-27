from PIL import Image, ImageDraw, ImageFont, ImageFilter

N = 640


def finish(img, size):
    """Centre and fill the frame like vanilla icons, add a soft contact shadow, downsample."""
    bb = img.getbbox(); obj = img.crop(bb)
    k = N * 0.86 / max(obj.size); obj = obj.resize((int(obj.width * k), int(obj.height * k)), Image.LANCZOS)
    img = Image.new('RGBA', (N, N)); img.alpha_composite(obj, ((N - obj.width) // 2, (N - obj.height) // 2))
    a = img.split()[3].filter(ImageFilter.GaussianBlur(N / 90))
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0)); sh.putalpha(a.point(lambda v: int(v * 0.4)))
    out = Image.new('RGBA', img.size); out.alpha_composite(sh, (int(N * 0.012), int(N * 0.02))); out.alpha_composite(img)
    small = out.resize((size, size), Image.LANCZOS)
    if size <= 64:
        small = small.filter(ImageFilter.UnsharpMask(radius=1, percent=70, threshold=2))
    return small


font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
rows = [('Larva (plain)', 'larva'), ('Egg', 'egg'), ('Loaded larva', 'capsule')]
RH = 300
sheet = Image.new('RGB', (1100, 40 + RH * 3), (34, 31, 26)); d = ImageDraw.Draw(sheet)
d.text((320, 10), 'Biter', fill=(230, 225, 218), font=font); d.text((760, 10), 'Spitter', fill=(230, 225, 218), font=font)
for i, (name, key) in enumerate(rows):
    y = 40 + i * RH
    d.text((14, y + 10), name, fill=(240, 200, 120), font=font)
    d.text((14, y + 40), 'big preview · 64 px ·\n32 px in a slot', fill=(180, 175, 168), font=small)
    for j, sp in enumerate(['biter', 'spitter']):
        img = Image.open(f'bl/{key}-{sp}.png').convert('RGBA')
        x = 230 + j * 440
        for sz, dx in ((220, 0), (64, 250), (32, 340)):
            pad = 6
            d.rectangle([x + dx, y + 40, x + dx + sz + 2 * pad, y + 40 + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
            im = finish(img, sz); sheet.paste(im, (x + dx + pad, y + 40 + pad), im)
            if sz == 64:
                im.save(f'bl/{key}-{sp}-64.png')
sheet.save('/home/claude/preview/larva-icons-blender.png')
