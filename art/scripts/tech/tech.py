from PIL import Image, ImageFilter, ImageDraw, ImageFont
import numpy as np
S = 1024  # work size; tech icons ship at 256

def trim(im):
    return im.crop(im.getbbox())

def fit(im, box):
    k = min(box / im.width, box / im.height)
    return im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)

def shadowed(im, blur=14, off=(10, 16), alpha=0.5):
    pad = blur * 3
    c = Image.new('RGBA', (im.width + pad * 2, im.height + pad * 2))
    a = im.split()[3].point(lambda v: int(v * alpha))
    sh = Image.new('RGBA', im.size, (0, 0, 0, 255)); sh.putalpha(a)
    c.alpha_composite(sh, (pad + off[0], pad + off[1]))
    c = c.filter(ImageFilter.GaussianBlur(blur))
    c.alpha_composite(im, (pad, pad))
    return c

def compose(main, extra=None, main_box=0.92, extra_box=0.46, extra_pos='br'):
    out = Image.new('RGBA', (S, S))
    m = shadowed(fit(trim(main), int(S * main_box)))
    out.alpha_composite(m, ((S - m.width) // 2, (S - m.height) // 2))
    if extra is not None:
        e = shadowed(fit(trim(extra), int(S * extra_box)), blur=10, alpha=0.7)
        x = S - e.width + 10 if extra_pos == 'br' else -10
        out.alpha_composite(e, (x, S - e.height + 10))
    return out

def frame0(path, fw, fh, k=0, cols=8):
    im = Image.open(path).convert('RGBA')
    return im.crop(((k % cols) * fw, (k // cols) * fh, (k % cols) * fw + fw, (k // cols) * fh + fh))

POD = frame0('/home/claude/simonbrodtmann/mod-framework/mf-buildings-graphics-1/graphics/pathogen-lab/pathogen-lab-animation.png', 500, 500)
CH = Image.open('/home/claude/panglia/simulation_chamber/simulation_chamber_base.png').convert('RGBA')
CH.alpha_composite(Image.open('/home/claude/panglia/simulation_chamber/layer4.png').convert('RGBA'))
LAU = frame0('/home/claude/hlrt-clean/rocket-turret_attack.png', 512, 512, k=6)
ROCKET = Image.open('/home/claude/icons/bl4/rocket-window.png').convert('RGBA')
WARD = Image.open('/home/claude/icons/bl3/canister-std.png').convert('RGBA')
EGG = Image.open('/home/claude/icons/bl/egg-biter.png').convert('RGBA')
LARVA = Image.open('/home/claude/icons/bl/larva-biter.png').convert('RGBA')
CAPS = Image.open('/home/claude/icons/bl/capsule-biter.png').convert('RGBA')

TECHS = [
    ('Monster husbandry', [('Breeding pod', compose(POD)), ('Pod + egg', compose(POD, EGG, main_box=0.86))]),
    ('Ordnance loading', [('Loading chamber', compose(CH)), ('Chamber + loaded larva', compose(CH, CAPS, main_box=0.86))]),
    ('Larva rockets', [('Larva rocket', compose(ROCKET, main_box=0.98)), ('Launcher + rocket', compose(LAU, ROCKET, main_box=0.86, extra_box=0.62))]),
    ('Stasis ward', [('Stasis ward', compose(WARD, main_box=0.86)), ('Ward + larva', compose(WARD, LARVA, main_box=0.8))]),
]

if __name__ == '__main__':
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
    CW, RH = 560, 330
    sheet = Image.new('RGB', (CW * 2 + 20, 20 + RH * 4), (34, 31, 26)); d = ImageDraw.Draw(sheet)
    for r, (tech, opts) in enumerate(TECHS):
        for c, (name, img) in enumerate(opts):
            x, y = 10 + c * CW, 10 + r * RH
            d.text((x + 10, y + 4), f'{tech} · {"AB"[c]}', fill=(240, 200, 120), font=font)
            d.text((x + 10, y + 30), name, fill=(180, 175, 168), font=small)
            # tech slot look: dark rounded tile behind the icon, as in the research screen
            for sz, dx, dy in ((256, 10, 56), (128, 290, 56), (64, 290, 200)):
                d.rounded_rectangle([x + dx, y + dy, x + dx + sz + 8, y + dy + sz + 8], radius=6, fill=(60, 58, 56), outline=(20, 20, 20))
                im = img.resize((sz, sz), Image.LANCZOS)
                sheet.paste(im, (x + dx + 4, y + dy + 4), im)
            img.resize((256, 256), Image.LANCZOS).save(f'tech-{tech.lower().replace(" ", "-")}-{"ab"[c]}.png')
    sheet.save('/home/claude/preview/tech-icon-options.png')
