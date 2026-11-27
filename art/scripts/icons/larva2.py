import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from render3d import Scene, ball, noise, N, xx, yy

SPECIES = {
    'biter':   dict(flesh=(196, 146, 100), chitin=(104, 56, 34), dark=(58, 30, 18), egg=(226, 196, 132), vein=(170, 70, 40), liquid=(150, 80, 40)),
    'spitter': dict(flesh=(176, 184, 104), chitin=(74, 96, 34), dark=(38, 52, 18), egg=(204, 214, 140), vein=(110, 140, 40), liquid=(96, 130, 40)),
}


def arc_points(n, cx, cy, R, a0, a1):
    t = np.linspace(a0, a1, n)
    return [(cx + R * np.cos(a), cy + R * np.sin(a)) for a in t]


def grub(s, c, cx=0.5, cy=0.52, R=0.25, size=1.0, a0=2.6, a1=-0.2, spikes=False, head_kind='grub', legs=False):
    """C-shaped segmented grub: tail at a0, head at a1 (radians on a circle)."""
    pts = arc_points(9, cx, cy, R * size, a0, a1)
    radii = np.interp(np.arange(9), [0, 3, 6, 8], [0.055, 0.095, 0.1, 0.085]) * size
    rng = np.random.default_rng(7)
    radii = radii * (1 + rng.uniform(-0.08, 0.08, 9))
    pts = [(x + rng.uniform(-0.006, 0.006), y + rng.uniform(-0.006, 0.006)) for x, y in pts]
    for i, ((x, y), r) in enumerate(zip(pts, radii)):
        if i == 8:
            break
        s.add(ball(x, y, r), c['flesh'], gloss=0.55)
        # chitin plate on the outer (back) side of each segment
        ang = a0 + (a1 - a0) * i / 8
        ox, oy = np.cos(ang) * r * 0.45, np.sin(ang) * r * 0.45
        s.add(ball(x + ox, y + oy, r * 0.78, z0=r * 0.12), c['chitin'], gloss=0.8)
        if spikes and 1 <= i <= 7:
            sx, sy = x + np.cos(ang) * r * 1.0, y + np.sin(ang) * r * 1.0
            s.add(ball(sx, sy, r * 0.34, z0=r * 0.55), c['dark'], gloss=0.9)
            s.add(ball(x + np.cos(ang) * r * 1.3, y + np.sin(ang) * r * 1.3, r * 0.18, z0=r * 0.6), c['dark'], gloss=0.9)
        if legs and 2 <= i <= 6:
            lx, ly = x - np.cos(ang) * r * 0.95, y - np.sin(ang) * r * 0.95
            s.add(ball(lx, ly, r * 0.22, z0=-r * 0.1), c['dark'], gloss=0.6)
    hx, hy = pts[8]
    hr = radii[8]
    s.add(ball(hx, hy, hr * 1.05), c['chitin'], gloss=0.9)
    ang = a1 - 0.9  # head faces along the curve
    fx, fy = np.cos(ang), np.sin(ang)
    if head_kind == 'biter':
        for k in (-0.5, 0, 0.5):
            px, py = np.cos(ang + k), np.sin(ang + k)
            s.add(ball(hx + px * hr * 1.0, hy + py * hr * 1.0, hr * 0.26, z0=hr * 0.25), c['dark'], gloss=0.9)
            s.add(ball(hx + px * hr * 1.45, hy + py * hr * 1.45, hr * 0.2, z0=hr * 0.2), c['dark'], gloss=0.9)
            s.add(ball(hx + px * hr * 1.85, hy + py * hr * 1.85, hr * 0.13, z0=hr * 0.15), c['dark'], gloss=0.9)
    else:
        for k in (-0.45, 0.45):
            px, py = np.cos(ang + k), np.sin(ang + k)
            s.add(ball(hx + px * hr * 0.95, hy + py * hr * 0.95, hr * 0.24, z0=hr * 0.2), c['dark'], gloss=0.9)
    # mottling and darker seams between plates
    s.paint((noise(3, 6) > 0.53) * (s.h > 0), c['chitin'], 0.3)
    s.paint((noise(9, 2) > 0.56) * (s.h > 0), c['dark'], 0.35)
    return s


def opt_grub(c):
    s = grub(Scene(), c, cx=0.45, cy=0.5, R=0.23, size=1.25)
    return s.render()


def opt_biter_larva(c):
    s = grub(Scene(), c, cx=0.45, cy=0.5, R=0.23, size=1.25, spikes=True, head_kind='biter', legs=True)
    return s.render()


def opt_egg(c):
    inner = grub(Scene(), c, cx=0.44, cy=0.53, R=0.15, size=0.8, a0=2.3, a1=-0.6, spikes=False).render()
    shell = Scene()
    shell.add(ball(0.5, 0.52, 0.3, 0.37), c['egg'], gloss=0.9)
    veins = (np.abs(noise(11, 7) - 0.5) < 0.006) & (shell.h > 0)
    shell.paint(veins.astype(np.float32), c['dark'], 0.9)
    shell.paint(((noise(5, 14) > 0.56) & (shell.h > 0)).astype(np.float32), c['vein'], 0.18)
    sh = shell.render(rim=c['egg'], seed=12, grime=0.7)
    # membrane: translucent in the middle, opaque toward the edge
    h = np.clip(shell.h, 0, None) / 0.3
    trans = np.clip(0.12 + 0.88 * (1 - h) ** 2.2, 0, 1)
    a = np.array(sh)[..., 3].astype(np.float32) / 255 * trans
    arr = np.array(sh).astype(np.float32)
    arr[..., 3] = a * 255
    out = Image.new('RGBA', (N, N))
    base = Image.new('RGBA', (N, N))
    base.paste(Image.fromarray(np.dstack([arr[..., :3], np.array(sh)[..., 3:4].astype(np.float32) * 0.55]).astype(np.uint8)), (0, 0))
    out.alpha_composite(base)
    tinted = Image.fromarray((np.array(inner).astype(np.float32) * [0.85, 0.8, 0.7, 1]).astype(np.uint8))
    out.alpha_composite(tinted)
    out.alpha_composite(Image.fromarray(arr.astype(np.uint8)))
    return out


def opt_capsule(c):
    s = Scene()
    # vanilla capsule silhouette: round canister seen from above, metal rim, glass dome
    s.add(ball(0.5, 0.56, 0.36, 0.3), (88, 86, 82), gloss=0.6)
    s.add(ball(0.5, 0.53, 0.3, 0.25, z0=0.02), (60, 58, 55), gloss=0.4)
    rim = ((np.hypot((xx - 0.5) / 0.36, (yy - 0.56) / 0.3) > 0.88) & (s.h > 0)).astype(np.float32)
    s.paint(rim, (140, 136, 128), 0.8)
    for k in range(6):  # bolts around the rim
        a = k / 6 * 2 * np.pi + 0.3
        s.add(ball(0.5 + np.cos(a) * 0.325, 0.56 + np.sin(a) * 0.27, 0.022, z0=0.035), (170, 165, 150), gloss=0.9)
    rust = np.clip((noise(21, 6) - 0.52) * 7, 0, 1) * (s.h > 0)
    s.paint(rust, (112, 62, 32), 0.75)
    base = s.render(rim=(200, 200, 200), rim_k=0.2, seed=20, grime=0.6)
    inner = grub(Scene(), c, cx=0.45, cy=0.53, R=0.15, size=0.75, a0=2.5, a1=-0.4).render()
    liquid = Scene()
    liquid.add(ball(0.5, 0.53, 0.27, 0.22, z0=0.05), c['liquid'], gloss=0.2)
    liq = liquid.render(rim=c['liquid'], seed=30, grime=0.5)
    out = Image.new('RGBA', (N, N))
    out.alpha_composite(base)
    l = np.array(liq).astype(np.float32); l[..., 3] *= 0.75
    out.alpha_composite(Image.fromarray(l.astype(np.uint8)))
    out.alpha_composite(inner)
    glass = Scene()
    glass.add(ball(0.5, 0.53, 0.27, 0.22, z0=0.05), (220, 235, 230), gloss=1.0)
    g = np.array(glass.render(rim=(255, 255, 255), rim_k=0.6)).astype(np.float32)
    lum = g[..., :3].mean(axis=2)
    smudge = np.clip((noise(31, 8) - 0.45) * 3, 0, 1)
    g[..., 3] = np.where(g[..., 3] > 0, np.clip((lum - 195) / 60, 0, 1) * 130 * (1 - 0.7 * smudge) + 10 + smudge * 55, 0)
    g[..., :3] = g[..., :3] * (1 - smudge[..., None] * 0.55) + np.array([70, 62, 48]) * smudge[..., None] * 0.55
    out.alpha_composite(Image.fromarray(g.astype(np.uint8)))
    return out


def finish(img, size):
    """Centre and fill the frame like vanilla icons, add a soft contact shadow, downsample."""
    bb = img.getbbox(); obj = img.crop(bb)
    k = N * 0.84 / max(obj.size); obj = obj.resize((int(obj.width * k), int(obj.height * k)), Image.LANCZOS)
    img = Image.new('RGBA', (N, N)); img.alpha_composite(obj, ((N - obj.width) // 2, (N - obj.height) // 2))
    a = img.split()[3].filter(ImageFilter.GaussianBlur(N / 90))
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0)); sh.putalpha(a.point(lambda v: int(v * 0.45)))
    out = Image.new('RGBA', img.size); out.alpha_composite(sh, (int(N * 0.012), int(N * 0.02))); out.alpha_composite(img)
    small = out.resize((size, size), Image.LANCZOS)
    if size <= 64:
        small = small.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    return small


OPTS = [('E', 'E · Segmented grub', opt_grub), ('F', 'F · Biter larva', opt_biter_larva),
        ('G', 'G · Larva in an egg sac', opt_egg), ('H', 'H · Larva capsule', opt_capsule)]

if __name__ == '__main__':
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    RH = 230
    sheet = Image.new('RGB', (1000, 40 + RH * len(OPTS)), (34, 31, 26)); d = ImageDraw.Draw(sheet)
    d.text((300, 10), 'Biter', fill=(230, 225, 218), font=font); d.text((680, 10), 'Spitter', fill=(230, 225, 218), font=font)

    def slot(img, sz, x, y):
        pad = 6; d.rectangle([x, y, x + sz + 2 * pad, y + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
        sheet.paste(img, (x + pad, y + pad), img)
    for i, (k, name, fn) in enumerate(OPTS):
        y = 40 + i * RH
        d.text((14, y + 10), name, fill=(240, 200, 120), font=font)
        d.text((14, y + 40), 'big preview · 64 px icon ·\n32 px in an inventory slot', fill=(180, 175, 168), font=small)
        for j, sp in enumerate(['biter', 'spitter']):
            img = fn(SPECIES[sp])
            img.save(f'larva-{k}-{sp}-512.png')
            x = 230 + j * 380
            slot(finish(img, 160), 160, x, y + 40); slot(finish(img, 64), 64, x + 190, y + 40); slot(finish(img, 32), 32, x + 280, y + 40)
    sheet.save('/home/claude/preview/larva-icon-options-2.png')


def chosen_sheet():
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    rows = [('Larva (plain)', opt_biter_larva), ('Egg', opt_egg), ('Loaded larva (payload icon goes in the corner)', opt_capsule)]
    RH = 300
    sheet = Image.new('RGB', (1100, 40 + RH * 3), (34, 31, 26)); d = ImageDraw.Draw(sheet)
    d.text((320, 10), 'Biter', fill=(230, 225, 218), font=font); d.text((760, 10), 'Spitter', fill=(230, 225, 218), font=font)
    for i, (name, fn) in enumerate(rows):
        y = 40 + i * RH
        d.text((14, y + 10), name, fill=(240, 200, 120), font=font)
        d.text((14, y + 40), 'big preview · 64 px ·\n32 px in a slot', fill=(180, 175, 168), font=small)
        for j, sp in enumerate(['biter', 'spitter']):
            img = fn(SPECIES[sp])
            x = 230 + j * 440
            for sz, dx in ((220, 0), (64, 250), (32, 340)):
                pad = 6
                d.rectangle([x + dx, y + 40, x + dx + sz + 2 * pad, y + 40 + sz + 2 * pad], fill=(49, 48, 49), outline=(20, 20, 20))
                im = finish(img, sz); sheet.paste(im, (x + dx + pad, y + 40 + pad), im)
                if sz == 64:
                    im.save(f'final-{fn.__name__}-{sp}-64.png')
    sheet.save('/home/claude/preview/larva-icons-chosen.png')


if __name__ == '__main__':
    chosen_sheet()
