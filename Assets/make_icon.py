"""Builds the Frugality Pug app icon (1024x1024 PNG) from vector art.

The pug is Platypug's fawn pug, the same art as Priority Pusher's icon, used unchanged
from Assets/source/pug-fawn.svg. Only parts the coin would hide (tail, legs, arms, belly)
and the game's blink lids are left out. The pug peeks over a gold coin, paws on the rim;
the coin is engraved with the same pug's head (its own line art, recolored in gold).

Everything is composed as one SVG and rendered once at full size, so edges stay crisp.

Run: python3 Assets/make_icon.py App/Assets.xcassets/AppIcon.appiconset/icon.png \
       --logo=App/Assets.xcassets/Logo.imageset/logo.png \
       --head=App/Assets.xcassets/PugHead.imageset/pug-head.png [--svg]
(--logo writes a small copy of the icon for the About sheet; --head writes the pug's head alone,
on a transparent background, for the home screen's top-right corner.)
Needs: pip install cairosvg pillow
"""
import io
import math
import os
import re
import sys

import cairosvg
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "source", "pug-fawn.svg")
SIZE = 1024

# Background sampled from Priority Pusher's icon; pug colors come from the SVG itself.
BG_CENTER, BG_MID, BG_EDGE = "#FDE3B8", "#F9CE96", "#F5B676"
INK = "#000"
FAWN = "#f5d2a7"
GOLD = "#F7C948"
GOLD_RING = "#E5AD2E"
GOLD_SHADE = "#EDB93A"        # ear tone in the engraving
GOLD_ENGRAVE = "#B9790F"
OUTLINE = 2.49                # the pug's own outline weight (SVG units)

# Layout in the pug's SVG units
PUG_CENTER_X = 68.3           # midway between the ear tips
PUG_TOP = 3.0                 # top of the ears
COIN_TOP = 84.0               # coin rim at center: just under the muzzle
COIN_R = 82.0                 # big enough that the rim is nearly flat under the paws
PAW_X = (44.0, 92.7)          # under each eye
MARGIN = 64                   # px around the artwork

# --- Source art --------------------------------------------------------------
raw = open(SOURCE).read()
body = re.search(r"<svg[^>]*>(.*)</svg>", raw, re.S).group(1)


def take_group(markup, cls):
    match = re.search(r'<g class="' + cls + r'">(.*?)</g>', markup, re.S)
    return match.group(1), markup.replace(match.group(0), "")


foot, body = take_group(body, "pug-leg leg-l")    # reused as the paw shape
_, body = take_group(body, "pug-leg leg-r")
_, body = take_group(body, "pug-tail")
body = re.sub(r'<ellipse class="crit-lid".*?</ellipse>', "", body, flags=re.S)
for hidden in ("M44.8,87.58", "M90.76,87.58", "M39.68,106.1", "M95.29,104.51", "M66.8,126.36", "M66.8,123.87"):
    body = re.sub(r'<path d="' + re.escape(hidden) + r'.*?</path>', "", body, flags=re.S)  # arms, belly

FOOT_CENTER = (46.1, 130.8)   # center of the left foot in the source


def recolor(markup, mapping):
    for old, new in mapping.items():
        markup = markup.replace(old, new)
    return markup


# --- Geometry ----------------------------------------------------------------
coin_cx, coin_cy = PUG_CENTER_X, COIN_TOP + COIN_R
art_top, art_bottom = PUG_TOP, coin_cy + COIN_R + OUTLINE
scale = (SIZE - 2 * MARGIN) / (art_bottom - art_top)
tx = SIZE / 2 - PUG_CENTER_X * scale
ty = MARGIN - art_top * scale


def rim_y(x):
    return coin_cy - math.sqrt(COIN_R ** 2 - (x - coin_cx) ** 2)


# --- Pieces ------------------------------------------------------------------
pug = f'<g fill="{INK}">{body}</g>'

coin = (
    f'<circle cx="{coin_cx}" cy="{coin_cy}" r="{COIN_R}" fill="{GOLD}" stroke="{INK}" stroke-width="{OUTLINE}"/>'
    f'<circle cx="{coin_cx}" cy="{coin_cy}" r="{COIN_R * 0.86}" fill="none" stroke="{GOLD_RING}" stroke-width="{OUTLINE * 0.75}"/>'
)

# Engraving: the head's own line art in dark gold, fills in coin gold, clipped to the head,
# with a jaw line where the head meets the (hidden) body.
JAW = "M29.66,83.06 Q68.3,104 108.31,83.45"
engrave_art = recolor(body, {
    f'fill="{FAWN}"': f'fill="{GOLD}"',
    'fill="#706461"': f'fill="{GOLD_SHADE}"',
    'stroke="#4f4f4f"': f'stroke="{GOLD_ENGRAVE}"',
    'stroke="#000"': f'stroke="{GOLD_ENGRAVE}"',
    'fill="#fff"': f'fill="{GOLD}"',
    'fill="#fcab9a"': f'fill="{GOLD}"',
})
engrave_scale = 0.6
engrave_cx, engrave_cy = coin_cx, coin_cy + 6           # center of the visible coin face
head_mid_y = 52.0
engraving = (
    '<defs><clipPath id="head"><path d="M-20,-20 H160 V83.45 L108.31,83.45 Q68.3,104 29.66,83.06 L-20,83.06 Z"/></clipPath></defs>'
    f'<g transform="translate({engrave_cx} {engrave_cy}) scale({engrave_scale}) translate({-PUG_CENTER_X} {-head_mid_y})">'
    f'<g clip-path="url(#head)" fill="{GOLD_ENGRAVE}">{engrave_art}</g>'
    f'<path d="{JAW}" fill="none" stroke="{GOLD_ENGRAVE}" stroke-width="{OUTLINE}" stroke-linecap="round"/>'
    '</g>'
)

# Paws: the pug's foot shape, resting on the rim, with two toe marks like Priority Pusher's.
paws = ""
for x in PAW_X:
    y = rim_y(x) + 3.0
    toes = "".join(
        f'<line x1="{FOOT_CENTER[0] + dx}" y1="{FOOT_CENTER[1] + 1.2}" x2="{FOOT_CENTER[0] + dx}" y2="{FOOT_CENTER[1] + 4.6}" '
        f'stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
        for dx in (-2.4, 2.4)
    )
    paws += (f'<g transform="translate({x - FOOT_CENTER[0]} {y - FOOT_CENTER[1]})" fill="{INK}">'
             f'{foot}{toes}</g>')

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">
<defs><radialGradient id="bg" cx="50%" cy="35%" r="80%">
  <stop offset="0" stop-color="{BG_CENTER}"/><stop offset="0.55" stop-color="{BG_MID}"/><stop offset="1" stop-color="{BG_EDGE}"/>
</radialGradient></defs>
<rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>
<g transform="translate({tx} {ty}) scale({scale})">
{pug}
{coin}
{engraving}
{paws}
</g>
</svg>'''

png = cairosvg.svg2png(bytestring=svg.encode(), output_width=SIZE, output_height=SIZE)
out = Image.open(io.BytesIO(png)).convert("RGB")      # no alpha channel for the App Store
target = next((a for a in sys.argv[1:] if not a.startswith("--")), "icon.png")
out.save(target)
for arg in sys.argv[1:]:
    if arg.startswith("--logo="):
        out.resize((256, 256), Image.LANCZOS).save(arg.split("=", 1)[1])
    if arg.startswith("--head="):
        # The pug's head alone: everything above the jaw, closed off with a jaw line.
        head_svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -3 145 102" width="435" height="306">'
            '<defs><clipPath id="head"><path d="M-20,-20 H160 V83.45 L108.31,83.45 Q68.3,104 29.66,83.06 L-20,83.06 Z"/></clipPath></defs>'
            f'<g clip-path="url(#head)" fill="{INK}">{body}</g>'
            f'<path d="{JAW}" fill="none" stroke="{INK}" stroke-width="{OUTLINE}" stroke-linecap="round"/>'
            '</svg>'
        )
        cairosvg.svg2png(bytestring=head_svg.encode(), write_to=arg.split("=", 1)[1])
if "--svg" in sys.argv:
    open(os.path.splitext(target)[0] + ".svg", "w").write(svg)
