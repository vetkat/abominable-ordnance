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


