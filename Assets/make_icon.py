"""Draws the Frugality Pug app icon (1024x1024 PNG).

The pug is NOT redrawn: its shapes are lifted directly from Priority Pusher's icon
(Assets/source/priority-pusher-icon.png, 256x256). Each color region (face, ears/muzzle,
outline, blush, eye shine) is separated, scaled up smoothly, and re-filled with the exact
Priority Pusher colors. Priority Pusher's card is replaced by a gold coin engraved with
a pug-head outline traced from the same pug.

Run: python3 Assets/make_icon.py App/Assets.xcassets/AppIcon.appiconset/icon.png
Needs Pillow, numpy, scipy. No transparency (App Store requirement).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "source", "priority-pusher-icon.png")

SIZE = 1024
SS = 2                       # supersample factor
W = SIZE * SS

# Priority Pusher colors (sampled from its icon)
BG_TOP, BG_BOTTOM = (251, 217, 167), (248, 200, 141)
INK = (26, 20, 20)
FAWN = (245, 210, 167)
GRAY = (112, 100, 97)
BLUSH = (252, 171, 154)
SHINE = (255, 255, 255)

# Coin
GOLD = (247, 201, 72)
GOLD_RING = (233, 178, 46)
GOLD_ENGRAVE = (196, 132, 20)

# Layout, in source (256px) coordinates
CARD_EDGE_Y = 118            # Priority Pusher's card top edge; the pug sits on it
PUG_CENTER_X = 128
SRC_TOP = 42                 # top of the pug's ears
COIN_TOP_Y = 112             # coin rim at the center (just under the muzzle)
COIN_R = 69                  # chosen so the rim passes under both paws
SCALE = 4.25                 # source px -> output px
OUT_TOP = 70                 # output y of SRC_TOP


# --- Source analysis ---------------------------------------------------------
src = np.asarray(Image.open(SOURCE).convert("RGB")).astype(float)
lum = 0.299 * src[..., 0] + 0.587 * src[..., 1] + 0.114 * src[..., 2]


def dist(color):
    return np.sqrt(((src - np.array(color, dtype=float)) ** 2).sum(axis=2))


walls = lum < 75
labels, _ = ndimage.label(~walls)
bg_label = labels[0, 0]
card_label = labels[200, 128]

head_fill = np.zeros(walls.shape, bool)
paw_fill = np.zeros(walls.shape, bool)
for index, box in enumerate(ndimage.find_objects(labels), start=1):
    if index in (bg_label, card_label) or box is None:
        continue
    top, bottom = box[0].start, box[0].stop
    if top >= CARD_EDGE_Y + 3:           # card contents (chips, check circles)
        continue
    component = labels == index
    if top >= CARD_EDGE_Y - 8 and bottom > CARD_EDGE_Y:   # paws hang over the card edge
        paw_fill |= component
    else:
        head_fill |= component


def region(fill, grow):
    return ndimage.binary_fill_holes(ndimage.binary_dilation(fill, iterations=grow))


head_region = region(head_fill, 2)
paw_region = region(paw_fill, 2)
gray_like = dist(GRAY) < 25
ink_alpha = np.clip((160 - lum) / 125, 0, 1) * ~gray_like

# The muzzle has no outline in Priority Pusher: inside it, keep only true black (nose, mouth),
# not the darker anti-aliasing at its soft edge.
muzzle_zone = ndimage.binary_dilation((dist(GRAY) < 20) & (np.mgrid[0:256, 0:256][0] > 85), iterations=2)
ink_alpha = np.where(muzzle_zone, (lum < 60).astype(float), ink_alpha)

# Eyes: the two solid black blobs in the eye band. Their 1px lashes can't survive scaling,
# so they are cut from the ink mask here and redrawn as strokes in the same spots.
yy, xx = np.mgrid[0:256, 0:256]
eye_labels, eye_count = ndimage.label((lum < 60) & (yy > 65) & (yy < 92))
EYES = []
for index in range(1, eye_count + 1):
    blob = eye_labels == index
    rows_, cols_ = np.where(blob)
    height, width = np.ptp(rows_) + 1, np.ptp(cols_) + 1
    round_enough = 0.7 <= width / height <= 1.4
    if 20 <= blob.sum() <= 200 and round_enough and abs(cols_.mean() - PUG_CENTER_X) < 45:
        cy_, cx_ = ndimage.center_of_mass(blob)
        EYES.append((cx_, cy_, float(np.sqrt(blob.sum() / np.pi))))
for ex, ey, er in EYES:
    lash_band = (np.abs(xx - ex) < er * 1.9) & (yy < ey - er * 0.75) & (yy > ey - er * 2.6)
    ink_alpha[lash_band] = 0

layers_head = [
    (FAWN, head_region.astype(float)),
    (GRAY, ndimage.binary_opening((dist(GRAY) < 20) & head_region).astype(float)),
    (BLUSH, ((dist(BLUSH) < 22) & head_region).astype(float)),
    (INK, ink_alpha * ndimage.binary_dilation(head_region, iterations=1)),
    (SHINE, ndimage.binary_dilation((lum > 238) & head_region).astype(float)),
]
INK_THRESHOLD = 0.3
layers_paws = [
    (FAWN, paw_region.astype(float)),
    (INK, ink_alpha * ndimage.binary_dilation(paw_region, iterations=1)),
]


# --- Rendering helpers --------------------------------------------------------
def to_output(mask, scale=SCALE, src_anchor=(PUG_CENTER_X, SRC_TOP), out_anchor=(SIZE / 2, OUT_TOP), threshold=0.5):
    """Scale a source-space mask into supersampled output space with smooth edges.

    The mask is softened at source resolution first (removes pixel stair-steps and stray
    anti-aliasing specks), scaled up, then cut at `threshold` for a crisp, curved edge.
    """
    soft = ndimage.gaussian_filter(mask.astype(float), sigma=0.75)
    image = Image.fromarray(np.clip(soft * 255, 0, 255).astype(np.uint8), "L")
    k = 1 / (scale * SS)
    a, c = k, src_anchor[0] - out_anchor[0] * SS * k
    e, f = k, src_anchor[1] - out_anchor[1] * SS * k
    big = image.transform((W, W), Image.AFFINE, (a, 0, c, 0, e, f), resample=Image.BICUBIC)
    big = big.filter(ImageFilter.GaussianBlur(scale * SS * 0.25))
    return big.point(lambda v: 255 if v >= threshold * 255 else 0)


def paint(canvas, color, mask_image):
    canvas.paste(Image.new("RGB", canvas.size, color), (0, 0), mask_image)


def out_xy(x, y):
    """Source coordinates -> supersampled output coordinates."""
    return ((SIZE / 2 + (x - PUG_CENTER_X) * SCALE) * SS, (OUT_TOP + (y - SRC_TOP) * SCALE) * SS)


# --- Compose -----------------------------------------------------------------
canvas = Image.new("RGB", (W, W))
draw = ImageDraw.Draw(canvas)
for y in range(W):
    t = y / (W - 1)
    draw.line([(0, y), (W, y)], fill=tuple(round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)))

for color, mask in layers_head:
    paint(canvas, color, to_output(mask, threshold=INK_THRESHOLD if color == INK else 0.5))

# Lashes: three short strokes fanning up from each eye, as in Priority Pusher
for ex, ey, er in EYES:
    for angle in (-125, -90, -55):
        a = np.radians(angle)
        x0, y0 = out_xy(ex + er * 0.95 * np.cos(a), ey + er * 0.95 * np.sin(a))
        x1, y1 = out_xy(ex + er * 1.6 * np.cos(a), ey + er * 1.6 * np.sin(a))
        width = 1.35 * SCALE * SS
        draw.line([(x0, y0), (x1, y1)], fill=INK, width=round(width))
        for px, py in ((x0, y0), (x1, y1)):
            draw.ellipse([px - width / 2, py - width / 2, px + width / 2, py + width / 2], fill=INK)

# Coin, in front of the pug's chin
cx, cy = out_xy(PUG_CENTER_X, COIN_TOP_Y + COIN_R)
r = COIN_R * SCALE * SS
line = 3 * SCALE * SS                     # same weight as Priority Pusher's outlines
draw.ellipse([cx - r - line / 2, cy - r - line / 2, cx + r + line / 2, cy + r + line / 2], fill=INK)
draw.ellipse([cx - r + line / 2, cy - r + line / 2, cx + r - line / 2, cy + r - line / 2], fill=GOLD)
ring = r * 0.84
draw.ellipse([cx - ring, cy - ring, cx + ring, cy + ring], outline=GOLD_RING, width=round(line * 0.55))

# Engraving: the same pug's head, as even-width dark-gold lines (outline, ear folds, muzzle)
# with filled eyes and nose, centered on the coin.
silhouette = head_region.copy()
silhouette[CARD_EDGE_Y - 1:, :] = False   # the card hid the chin; close it with a rounded jaw
silhouette |= (((xx - PUG_CENTER_X) / 46.0) ** 2 + ((yy - (CARD_EDGE_Y - 14)) / 16.0) ** 2) <= 1
silhouette = ndimage.binary_fill_holes(silhouette)
cols = np.where(silhouette.any(axis=0))[0]
rows = np.where(silhouette.any(axis=1))[0]
engrave_scale = float((r / SS * 1.05) / (cols.max() - cols.min() + 1))
engrave_src = (float(cols.min() + cols.max()) / 2, float(rows.min() + rows.max()) / 2)
engrave_out = (float(cx / SS), float(cy / SS + r / SS * 0.08))
stroke = 5.5 * SS                          # engraved line width (output px x SS)


def engrave_mask(mask):
    return to_output(mask.astype(float), scale=engrave_scale, src_anchor=engrave_src, out_anchor=engrave_out)


def outline_of(mask_image):
    """Inner outline of a filled mask, `stroke` wide (erosion approximated by blur + high cut)."""
    eroded = mask_image.filter(ImageFilter.GaussianBlur(stroke * 0.6)).point(lambda v: 255 if v >= 250 else 0)
    return Image.fromarray(np.where((np.asarray(mask_image) > 0) & (np.asarray(eroded) == 0), 255, 0).astype(np.uint8), "L")


ears = ndimage.binary_opening((dist(GRAY) < 20) & head_region & (yy < 85))
nose = (lum < 60) & muzzle_zone & (yy < 98)
muzzle = ndimage.binary_opening((dist(GRAY) < 20) & head_region & (yy > 85))
muzzle = ndimage.binary_fill_holes(ndimage.binary_closing(muzzle | nose, iterations=2))
for shape in (silhouette, ears, muzzle):
    paint(canvas, GOLD_ENGRAVE, outline_of(engrave_mask(shape)))
paint(canvas, GOLD_ENGRAVE, engrave_mask(ndimage.binary_dilation(nose)))
for ex, ey, er in EYES:
    eye = ((xx - ex) ** 2 + (yy - ey) ** 2) <= er ** 2
    paint(canvas, GOLD_ENGRAVE, engrave_mask(eye))

for color, mask in layers_paws:
    paint(canvas, color, to_output(mask, threshold=INK_THRESHOLD if color == INK else 0.5))

out = canvas.resize((SIZE, SIZE), Image.LANCZOS)
out.save(sys.argv[1] if len(sys.argv) > 1 else "icon.png")
