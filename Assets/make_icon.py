"""Draws the Frugality Pug app icon as a 1024x1024 PNG.

The pug matches the Priority Pusher icon: same colors, thick outlines, floppy ears,
lashed eyes, blush, gray muzzle, round paws. Here it hugs a money bag instead of peeking over a card.

Run: python3 Assets/make_icon.py App/Assets.xcassets/AppIcon.appiconset/icon.png
Needs Pillow. No transparency (App Store requirement); iOS rounds the corners itself.
"""
import math
import sys

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
S = 2                      # supersample factor
W = SIZE * S

# Priority Pusher palette (sampled from its icon)
BG_TOP, BG_BOTTOM = (251, 217, 167), (248, 200, 141)
INK = (26, 20, 20)
FACE = (245, 210, 167)
EAR = (112, 100, 97)
BLUSH = (252, 171, 154)
WHITE = (255, 255, 255)

# Money bag
SACK = (126, 200, 150)
SACK_SHADE = (98, 176, 126)
SACK_LIGHT = (176, 228, 192)
RIBBON = (229, 72, 77)
GOLD = (247, 201, 72)
GOLD_DARK = (201, 138, 18)

OUTLINE = 15               # outline width in 1024-space

img = Image.new("RGB", (W, W))
d = ImageDraw.Draw(img)


def s(v):
    return round(v * S)


def pts(points):
    return [(s(x), s(y)) for x, y in points]


def ellipse_points(cx, cy, rx, ry, angle=0.0, n=160, power=2.0):
    """Ellipse (power=2) or rounded-square superellipse (power>2), optionally rotated (degrees)."""
    a = math.radians(angle)
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, sn = math.cos(t), math.sin(t)
        x = rx * math.copysign(abs(c) ** (2 / power), c)
        y = ry * math.copysign(abs(sn) ** (2 / power), sn)
        out.append((cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a)))
    return out


def shape(points, fill, outline=True):
    """Filled polygon with a smooth, uniform outline outside its edge."""
    p = pts(points)
    if outline:
        d.line(p + [p[0], p[1]], fill=INK, width=s(OUTLINE * 2), joint="curve")
        for x, y in p[:: max(1, len(p) // 40)]:
            r = s(OUTLINE)
            d.ellipse([x - r, y - r, x + r, y + r], fill=INK)
    d.polygon(p, fill=fill)


def blob(cx, cy, rx, ry, fill, angle=0.0, outline=True, power=2.0):
    shape(ellipse_points(cx, cy, rx, ry, angle, power=power), fill, outline)


def stroke(points, width=10, fill=INK):
    d.line(pts(points), fill=fill, width=s(width), joint="curve")
    for x, y in (points[0], points[-1]):
        r = s(width / 2)
        d.ellipse([s(x) - r, s(y) - r, s(x) + r, s(y) + r], fill=fill)


def arc_points(cx, cy, r, start, end, n=30):
    return [(cx + r * math.cos(math.radians(start + (end - start) * i / n)),
             cy + r * math.sin(math.radians(start + (end - start) * i / n))) for i in range(n + 1)]


# --- Background -------------------------------------------------------------
for y in range(W):
    t = y / (W - 1)
    d.line([(0, y), (W, y)], fill=tuple(round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)))

# --- Layout -----------------------------------------------------------------
# Like Priority Pusher's pug peeking over a card: here the pug hugs a money bag,
# chin above its ruffle, paws on its shoulders. Draw order: pug head, bag, paws.
HX, HY, HW = 512, 310, 540   # head center and width
u = HW / 570                 # scale from the reference drawing
BX, BY, R = 512, 790, 200    # bag body center and radius


def draw_head():
    shape(ellipse_points(HX, HY, 272 * u, 242 * u, power=2.5), FACE)
    # one floppy ear per side, over the head's top corners, flopping outward
    blob(HX - 240 * u, HY - 112 * u, 82 * u, 128 * u, EAR, angle=38)
    blob(HX + 240 * u, HY - 112 * u, 82 * u, 128 * u, EAR, angle=-38)

    # muzzle, blush
    blob(HX, HY + 95 * u, 140 * u, 62 * u, EAR, outline=False)
    blob(HX - 182 * u, HY + 72 * u, 46 * u, 30 * u, BLUSH, outline=False)
    blob(HX + 182 * u, HY + 72 * u, 46 * u, 30 * u, BLUSH, outline=False)

    # eyes with highlight and lashes
    for ex in (HX - 118 * u, HX + 118 * u):
        ey = HY + 18 * u
        blob(ex, ey, 36 * u, 38 * u, INK, outline=False)
        blob(ex - 9 * u, ey - 11 * u, 12 * u, 12 * u, WHITE, outline=False)
        for ang in (-120, -90, -60):
            a = math.radians(ang)
            stroke([(ex + 36 * u * math.cos(a), ey + 38 * u * math.sin(a)),
                    (ex + 58 * u * math.cos(a), ey + 60 * u * math.sin(a))], width=7)

    # nose and "w" mouth
    shape([(HX - 26 * u, HY + 68 * u), (HX + 26 * u, HY + 68 * u), (HX, HY + 94 * u)], INK, outline=False)
    blob(HX, HY + 72 * u, 26 * u, 10 * u, INK, outline=False)
    stroke([(HX, HY + 90 * u), (HX, HY + 108 * u)], width=8)
    stroke(arc_points(HX - 20 * u, HY + 102 * u, 20 * u, 20, 160), width=8)
    stroke(arc_points(HX + 20 * u, HY + 102 * u, 20 * u, 20, 160), width=8)


def quad(p0, p1, p2, n=24):
    """Points along a quadratic Bezier curve (excluding the start point)."""
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
            for t in (i / n for i in range(1, n + 1))]


def sack_outline():
    """Classic money bag silhouette: round body, pinched neck, ruffled top."""
    body = [(BX + R * math.cos(math.radians(a)), BY + 0.95 * R * math.sin(math.radians(a)))
            for a in range(-55, 236, 3)]                        # upper right -> bottom -> upper left
    left_shoulder = body[-1]
    pts_ = list(body)
    pinch_l = (BX - 0.24 * R, BY - 1.06 * R)
    flare_l = (BX - 0.52 * R, BY - 1.32 * R)
    pts_ += quad(left_shoulder, (BX - 0.30 * R, BY - 0.86 * R), pinch_l)
    pts_ += quad(pinch_l, (BX - 0.22 * R, BY - 1.22 * R), flare_l)
    # three rounded ruffle bumps across the top
    xs = [BX - 0.52 * R, BX - 0.17 * R, BX + 0.17 * R, BX + 0.52 * R]
    for x0, x1 in zip(xs, xs[1:]):
        pts_ += quad((x0, BY - 1.32 * R), ((x0 + x1) / 2, BY - 1.62 * R), (x1, BY - 1.32 * R))
    pinch_r = (BX + 0.24 * R, BY - 1.06 * R)
    right_shoulder = body[0]
    pts_ += quad((BX + 0.52 * R, BY - 1.32 * R), (BX + 0.22 * R, BY - 1.22 * R), pinch_r)
    pts_ += quad(pinch_r, (BX + 0.30 * R, BY - 0.86 * R), right_shoulder)
    return pts_


def draw_bag():
    shape(sack_outline(), SACK)
    blob(BX + 40, BY + 85, 118, 70, SACK_SHADE, angle=-10, outline=False)   # soft shadow
    blob(BX - 125, BY - 40, 30, 62, SACK_LIGHT, angle=18, outline=False)    # shine

    # ribbon around the neck with a bow
    NY = BY - 1.08 * R
    shape([(BX - 0.40 * R, NY - 16), (BX + 0.40 * R, NY - 16), (BX + 0.38 * R, NY + 18), (BX - 0.38 * R, NY + 18)], RIBBON)
    blob(BX - 48, NY, 42, 25, RIBBON, angle=-20)
    blob(BX + 48, NY, 42, 25, RIBBON, angle=20)
    blob(BX, NY + 2, 20, 20, RIBBON)

    # gold coin with $ on the front
    CX, CY = BX, BY + 25
    blob(CX, CY, 100, 100, GOLD)
    d.ellipse([s(CX - 75), s(CY - 75), s(CX + 75), s(CY + 75)], outline=GOLD_DARK, width=s(7))
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", s(130))
    except OSError:
        font = ImageFont.load_default()
    d.text((s(CX), s(CY + 4)), "$", font=font, fill=GOLD_DARK, anchor="mm")

    # coin stacks at the base
    for x, n in ((BX + 290, 3), (BX - 285, 2)):
        for i in range(n):
            blob(x, BY + 165 - 33 * i, 62, 24, GOLD)


def draw_paws():
    # resting on the bag's shoulders
    for px in (BX - 0.66 * R, BX + 0.66 * R):
        py = BY - 0.80 * R
        blob(px, py, 58 * u, 50 * u, FACE)
        for dx in (-18, 0, 18):
            stroke([(px + dx * u, py + 24 * u), (px + dx * u, py + 42 * u)], width=7)


draw_head()
draw_bag()
draw_paws()

out = img.resize((SIZE, SIZE), Image.LANCZOS)
out.save(sys.argv[1] if len(sys.argv) > 1 else "icon.png")
