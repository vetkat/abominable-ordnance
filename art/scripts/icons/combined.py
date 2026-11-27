"""Preview of the layered icons (base icon + payload or contents in the corner).
The payload icons are STAND-INS drawn here: the real ones are vanilla's explosive rocket,
sulfuric acid and poison capsule icons, which the mod references from __base__ and never ships."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import importlib.util
spec = importlib.util.spec_from_file_location('s', 'bl_sheet_fn.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

R = 256  # stand-ins are drawn big, then shrunk like real icons


def standin(kind):
    """Flat placeholder glyphs, clearly not game art: a coloured disc with a symbol and a dashed rim."""
    im = Image.new('RGBA', (R, R)); d = ImageDraw.Draw(im)
    col = {'explosive': (205, 60, 35), 'acid': (190, 205, 40), 'poison': (80, 165, 60)}[kind]
    d.ellipse([16, 16, R - 16, R - 16], fill=col + (255,), outline=(20, 20, 20, 255), width=10)
    for a in range(0, 360, 30):  # dashed white rim marks it as a stand-in
        d.arc([30, 30, R - 30, R - 30], a, a + 15, fill=(255, 255, 255, 230), width=10)
    c = R // 2
    if kind == 'explosive':
        pts = [(c, 60), (c + 22, c - 18), (c + 70, c - 10), (c + 30, c + 18), (c + 45, c + 70), (c, c + 38),
               (c - 45, c + 70), (c - 30, c + 18), (c - 70, c - 10), (c - 22, c - 18)]
        d.polygon(pts, fill=(255, 220, 90, 255))
    elif kind == 'acid':
        d.polygon([(c, 58), (c + 52, c + 30), (c - 52, c + 30)], fill=(250, 250, 200, 255))
        d.ellipse([c - 54, c - 10, c + 54, c + 72], fill=(250, 250, 200, 255))
    else:
        d.ellipse([c - 55, c - 62, c + 55, c + 40], fill=(235, 240, 225, 255))
        d.rectangle([c - 32, c + 20, c + 32, c + 62], fill=(235, 240, 225, 255))
        d.ellipse([c - 36, c - 30, c - 8, c], fill=col + (255,)); d.ellipse([c + 8, c - 30, c + 36, c], fill=col + (255,))
    return im


def layered(base, overlay, size, scale=0.5):
    """Like Factorio's icons = { base, { icon = overlay, scale = 0.5, shift = {8, 8} } } at 64 px."""
    out = m.finish(base, size).copy()
    o = overlay.resize((int(size * scale), int(size * scale)), Image.LANCZOS)
    out.alpha_composite(o, (size - o.width, size - o.height))
    return out


def load(p):
    return Image.open(p).convert('RGBA')


PAY = [('explosive', 'Explosive rocket'), ('acid', 'Sulfuric acid'), ('poison', 'Poison capsule')]
BASES = {
    ('Loaded larva', 'biter'): load('bl/capsule-biter.png'), ('Loaded larva', 'spitter'): load('bl/capsule-spitter.png'),
    ('Larva rocket', 'biter'): load('bl4/rocket-window.png'), ('Larva rocket', 'spitter'): load('bl4/rocket-window-spitter.png'),
}

if __name__ == '__main__':
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 18)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    W = 1340
    sheet = Image.new('RGB', (W, 760), (34, 31, 26)); d = ImageDraw.Draw(sheet)
    d.rectangle([0, 0, W, 40], fill=(120, 40, 30))
    d.text((14, 10), 'STAND-INS: the payload badges are placeholders. In game they are vanilla icons, referenced from __base__.', fill=(255, 235, 220), font=small)

    def slot(img, sz, x, y):
        pad = 4
        d.rectangle([x, y, x + sz + 2 * pad, y + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
        sheet.paste(img, (x + pad, y + pad), img)

    y = 52
    for item in ('Loaded larva', 'Larva rocket'):
        d.text((14, y), item, fill=(240, 200, 120), font=font)
        for si, sp in enumerate(('biter', 'spitter')):
            for pi, (pk, pname) in enumerate(PAY):
                x = 14 + (si * 3 + pi) * 220
                d.text((x, y + 26), f'{sp}, {pname.lower()}', fill=(180, 175, 168), font=small)
                ov = standin(pk)
                slot(layered(BASES[(item, sp)], ov, 128), 128, x, y + 46)
                slot(layered(BASES[(item, sp)], ov, 64), 64, x + 140, y + 46)
                slot(layered(BASES[(item, sp)], ov, 32), 32, x + 140, y + 122)
        y += 200
    # packed wards: the contents sit in the corner, the same way as the payloads
    d.text((14, y), 'Packed wards', fill=(240, 200, 120), font=font)
    wards = [('Stasis ward', load('bl3/canister-std.png')), ('Cryo ward', load('bl3/canister-cryo.png'))]
    contents = [('egg', load('bl/egg-biter.png')), ('larva', load('bl/larva-biter.png')), ('loaded larva', load('bl/capsule-biter.png'))]
    k = 0
    for wname, wimg in wards:
        for cname, cimg in contents:
            x = 14 + k * 220
            d.text((x, y + 26), f'{wname.lower()}, {cname}', fill=(180, 175, 168), font=small)
            ov = m.finish(cimg, 256)
            slot(layered(wimg, ov, 128), 128, x, y + 46)
            slot(layered(wimg, ov, 64), 64, x + 140, y + 46)
            slot(layered(wimg, ov, 32), 32, x + 140, y + 122)
            k += 1
    sheet.save('/home/claude/preview/combined-icons-preview.png')
