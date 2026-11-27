"""Tiny height-field renderer for Factorio-style item icons.
Shapes are unions of ellipsoid balls; lighting is top-left key light, soft ambient,
glossy specular and a warm rim, like vanilla 2.0 / Space Age organic icons."""
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

N = 512
yy, xx = np.mgrid[0:N, 0:N].astype(np.float32) / N
LIGHT = np.array([-0.55, -0.65, 0.55]); LIGHT /= np.linalg.norm(LIGHT)
HALF = LIGHT + np.array([0, 0, 1.0]); HALF /= np.linalg.norm(HALF)


def ball(cx, cy, r, ry=None, z0=0.0):
    ry = ry or r
    d2 = ((xx - cx) / r) ** 2 + ((yy - cy) / ry) ** 2
    h = np.where(d2 < 1, np.sqrt(np.clip(1 - d2, 0, 1)) * min(r, ry), -1.0) + z0
    return h


class Scene:
    def __init__(self):
        self.h = np.full((N, N), -1.0, np.float32)
        self.col = np.zeros((N, N, 3), np.float32)
        self.gloss = np.zeros((N, N), np.float32)
        self.alpha = np.zeros((N, N), np.float32)
        self.groove = np.zeros((N, N), np.float32)

    def add(self, h, color, gloss=0.5, k=0.012):
        """Smooth union; colour follows whichever surface is on top."""
        top = h > self.h
        near = np.abs(h - self.h) < k
        # grooves where two balls meet (segment seams)
        self.groove = np.maximum(self.groove, np.where(near & (h > 0) & (self.h > 0), 1 - np.abs(h - self.h) / k, 0))
        self.col[top] = np.array(color, np.float32) / 255
        self.gloss[top] = gloss
        self.h = np.maximum(self.h, h)
        self.alpha = np.maximum(self.alpha, (h > -0.5).astype(np.float32))

    def paint(self, mask, color, strength=1.0):
        c = np.array(color, np.float32) / 255
        m = (mask * strength)[..., None]
        self.col = self.col * (1 - m) + c * m

    def render(self, rim=(255, 170, 120), rim_k=0.35, ao=1.0, grime=1.0, seed=1):
        h = np.where(self.h > 0, self.h, 0)
        mask = (self.h > 0).astype(np.float32)
        # surface bumps: fine pits and lumps, so nothing looks moulded
        bump = (noise(seed, 1.2) - 0.5) * 0.004 + (noise(seed + 1, 4) - 0.5) * 0.016
        h = h + bump * mask * grime
        hs = gaussian_filter(h, 1.0)
        gy, gx = np.gradient(hs * N)
        n = np.dstack([-gx, -gy, np.ones_like(gx)])
        n /= np.linalg.norm(n, axis=2, keepdims=True)
        diff = np.clip(n @ LIGHT, 0, 1)
        spec = np.clip(n @ HALF, 0, 1) ** 40 * self.gloss
        occl = np.clip((gaussian_filter(h, 18) - h) * 9, 0, 0.6) * ao
        rimv = (1 - n[..., 2]) ** 2 * rim_k
        groove = gaussian_filter(self.groove, 1.0)
        # colour mottling at three scales, dirt and wet patches
        mott = 1 + ((noise(seed + 2, 3) - 0.5) * 1.2 + (noise(seed + 3, 12) - 0.5) * 2.2) * 0.7 * grime
        col = self.col * mott[..., None]
        dirt = np.clip((noise(seed + 4, 5) - 0.47) * 6, 0, 1) * np.clip(occl * 5 + 0.15, 0, 1) * grime
        col = col * (1 - 0.55 * dirt[..., None]) + np.array([0.16, 0.12, 0.08]) * 0.55 * dirt[..., None]
        specks = (noise(seed + 5, 0.9) > 0.585).astype(np.float32) * grime
        col = col * (1 - 0.25 * specks[..., None])
        wet = np.clip((noise(seed + 6, 9) - 0.40) * 4, 0.35, 1.3)
        spec = np.clip(n @ HALF, 0, 1) ** 40 * self.gloss * wet * (1 - 0.7 * dirt)
        # Factorio's contour: surfaces darken toward their silhouette
        edge = np.clip(1 - gaussian_filter(mask, 3) * 1.25, 0, 1) * mask
        lit = col * (0.34 + 0.78 * diff[..., None]) - occl[..., None] * 0.75
        lit = lit * (1 - 0.6 * edge[..., None])
        lit = lit * (1 - 0.55 * groove[..., None])
        lit += np.array(rim, np.float32)[None, None] / 255 * rimv[..., None] * diff[..., None] * 0.6
        lit += spec[..., None] * 0.9
        # grade: slightly desaturated and warm, like the game's renders
        g = lit.mean(axis=2, keepdims=True)
        lit = g + (lit - g) * (1 - 0.28 * grime)
        lit = lit * np.array([1.0, 0.97, 0.9]) * (1 - 0.06 * grime)
        a = gaussian_filter(self.alpha, 0.7)
        rgba = np.dstack([np.clip(lit, 0, 1), np.clip(a, 0, 1)])
        return Image.fromarray((rgba * 255).astype(np.uint8), 'RGBA')


def noise(seed, scale):
    rng = np.random.default_rng(seed)
    return gaussian_filter(rng.random((N, N)).astype(np.float32), scale)
