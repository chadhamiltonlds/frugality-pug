"""Draws the Frugality Pug app icon (pug head next to a money bag) as a 1024x1024 PNG.
Run: python3 Assets/make_icon.py App/Assets.xcassets/AppIcon.appiconset/icon.png
Needs Pillow. No transparency (App Store requirement); iOS rounds the corners itself.
"""
import math, sys
from PIL import Image, ImageDraw, ImageFont

SIZE, S = 1024, 3  # draw at 3x, downsample for smooth edges
W = SIZE * S

def p(v):
    return v * S

def ellipse_poly(cx, cy, rx, ry, angle=0, n=120):
    a = math.radians(angle)
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = rx * math.cos(t), ry * math.sin(t)
        pts.append((p(cx + x * math.cos(a) - y * math.sin(a)), p(cy + x * math.sin(a) + y * math.cos(a))))
    return pts

# Background: warm peach gradient (Priority Pusher palette)
bg = Image.new("RGB", (W, W))
bgd = ImageDraw.Draw(bg)
top, bottom = (249, 211, 160), (255, 240, 220)
for y in range(W):
    t = y / (W - 1)
    bgd.line([(0, y), (W, y)], fill=tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))

# Artwork is drawn on a transparent layer, then centered and scaled to fit.
img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

INK = (43, 30, 26)
LW = p(12)

def shape(pts, fill, outline=True):
    if outline:
        d.polygon(pts, fill=fill, outline=INK, width=LW)
    else:
        d.polygon(pts, fill=fill)

def blob(cx, cy, rx, ry, fill, angle=0, outline=True):
    shape(ellipse_poly(cx, cy, rx, ry, angle), fill, outline)

# --- Money bag (behind the pug's right side) ---
GREEN, GREEN_DARK = (79, 163, 107), (56, 128, 80)
blob(745, 735, 185, 200, GREEN)                         # body
shape([(p(655), p(560)), (p(835), p(560)), (p(805), p(470)), (p(685), p(470))], GREEN)  # neck
blob(745, 462, 105, 34, GREEN_DARK)                     # ruffled top
# tie
shape([(p(648), p(548)), (p(842), p(548)), (p(838), p(592)), (p(652), p(592))], (229, 72, 77))
shape([(p(745), p(570)), (p(690), p(520)), (p(690), p(620))], (229, 72, 77))
shape([(p(745), p(570)), (p(800), p(520)), (p(800), p(620))], (229, 72, 77))
# dollar sign
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", p(250))
except OSError:
    font = ImageFont.load_default()
d.text((p(745), p(755)), "$", font=font, fill=(255, 244, 228), anchor="mm")

# --- Pug head ---
EAR = (92, 76, 70)
FAWN = (226, 185, 127)
WRINKLE = (196, 150, 92)
MUZZLE = (84, 68, 62)
blob(100, 470, 75, 140, EAR, angle=25)                  # left ear (drooping)
blob(620, 470, 75, 140, EAR, angle=-25)                 # right ear (drooping)
blob(360, 565, 285, 255, FAWN)                          # head
for dx, w in ((-70, 120), (0, 140), (70, 120)):         # forehead wrinkles
    d.arc([p(360 + dx - w // 2), p(345), p(360 + dx + w // 2), p(420)], 200, 340, fill=WRINKLE, width=p(11))
blob(360, 668, 150, 112, MUZZLE)                        # muzzle
blob(222, 628, 42, 28, (244, 166, 160), outline=False)  # blush
blob(498, 628, 42, 28, (244, 166, 160), outline=False)
blob(360, 622, 52, 34, (30, 22, 20))                    # nose
d.ellipse([p(338), p(610), p(364), p(624)], fill=(120, 108, 104))
d.line([(p(360), p(650)), (p(360), p(690))], fill=(30, 22, 20), width=p(10))
d.arc([p(318), p(668), p(362), p(712)], 20, 160, fill=(30, 22, 20), width=p(10))
d.arc([p(358), p(668), p(402), p(712)], 20, 160, fill=(30, 22, 20), width=p(10))
for ex in (262, 458):                                   # eyes
    blob(ex, 525, 40, 48, (30, 22, 20))
    d.ellipse([p(ex - 4), p(500), p(ex + 20), p(524)], fill=(255, 255, 255))
    d.ellipse([p(ex - 18), p(538), p(ex - 6), p(550)], fill=(255, 255, 255))

box = img.getbbox()
art = img.crop(box)
scale = (W * 0.80) / max(art.size)
art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
bg.paste(art, ((W - art.width) // 2, (W - art.height) // 2), art)
out = bg.resize((SIZE, SIZE), Image.LANCZOS)
out.save(sys.argv[1] if len(sys.argv) > 1 else "icon.png")
