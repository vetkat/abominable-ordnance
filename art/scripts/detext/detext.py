import cv2, numpy as np
from PIL import Image

def mask_text(rgba, bh_thresh=34, bright=48):
    """Dark, thin strokes (black-hat) sitting on the light pod surface."""
    rgb = rgba[..., :3]; a = rgba[..., 3]
    g = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    bh = cv2.morphologyEx(g, cv2.MORPH_BLACKHAT, k)
    local = cv2.medianBlur(cv2.morphologyEx(g, cv2.MORPH_CLOSE, k), 15)
    # pods are a warm light grey; keep only that surface
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    m = (bh > bh_thresh) & (local > bright) & (a > 200)
    m = m.astype(np.uint8) * 255
    # letters are small blobs; drop long thin seams
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, 8)
    keep = np.zeros_like(m)
    for i in range(1, n):
        x, y, w, h, area = st[i]
        if area < 5 or max(w, h) > 26 or (max(w, h) > 14 and min(w, h) < 3):
            continue
        keep[lab == i] = 255
    return cv2.dilate(keep, np.ones((3, 3), np.uint8), 1)

def clean(rgba):
    m = mask_text(rgba)
    bgr = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2BGR)
    out = cv2.inpaint(bgr, m, 4, cv2.INPAINT_TELEA)
    res = rgba.copy(); res[..., :3] = cv2.cvtColor(out, cv2.COLOR_BGR2RGB)
    return res, m

if __name__ == '__main__':
    E = '/home/claude/hlrt/hl-Rocket-turret_0.1.2/graphics/entity/'
    a = np.array(Image.open(E + 'rocket-turret_attack.png').convert('RGBA'))
    tiles = []
    for k in (0, 10, 24, 40):
        fr = a[(k // 8) * 512:(k // 8) * 512 + 512, (k % 8) * 512:(k % 8) * 512 + 512]
        c, m = clean(fr)
        mm = np.dstack([m, m, m, np.full_like(m, 255)])
        tiles.append(np.hstack([fr, c, mm]))
    Image.fromarray(np.vstack(tiles)).resize((768, 1024)).save('/home/claude/preview/detext-test.png')
