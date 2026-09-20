"""Turn the painted reference frames into scene plates.

The references in `docs/reference` are paintings with the mockup's UI painted
into them. A plate is the same painting with the parts the app has to own
wiped out — the frame numbering, and any chrome that has to reflect state
(the nav, the day/night chips). Everything else stays painted: the app hangs
the plate behind the scene and puts hotspots on the objects that should react.

    python tool/make_plates.py          # -> assets/art/*.webp

Wiping is a large median rather than an inpaint: median dissolves lettering
while keeping the local colour and texture, where inpaint smears a hole across
detailed art. A solid shape too big for the median to dissolve — the landing's
CTA pill — is replaced by cloning clean paint from elsewhere in the frame
first.
"""
import os

import cv2
import numpy as np

REF = 'docs/reference'
OUT = 'assets/art'
# Measured on the two busiest plates: from 82 down to 74 costs about 1.2 dB of
# PSNR against the lossless render and saves 23% of the bytes, and at 1:1 on
# the most detail-dense part of the landing the two encodes are not tellable
# apart. Below 74 the curve flattens — another 5% for the same again.
QUALITY = 74

# The references are crops, and no two share an aspect ratio — 1.68 for the
# landing, 2.64 for the sunset — while a browser window is usually near 1.67.
# Filling the viewport with a 2.64 strip would crop away a third of its width,
# taking the contact buttons with it. So every plate is padded to one aspect
# first, by continuing its own sky and ground outwards. The app then fills the
# viewport with the padded plate and only ever crops into that margin.
TARGET_ASPECT = 1.55

# (x0, y0, x1, y1) in each reference's own pixels.
#
# 'night' — also bake a moonlit variant of this plate (see [night]). Only the
#            daylight frames need one; a frame already painted at night or
#            indoors keeps the light it was composed in.
# 'lit'   — rects of painted handwriting inside a 'night' plate, repainted as
#            light strokes so dark ink does not die against the graded sky.
# 'wipe'  — painted UI the app replaces with live widgets.
# 'clone'  — (rect, (dx, dy)): fill rect with paint copied from that offset,
#            before the wipe, for shapes a median cannot dissolve.
# 'extend' — rect: rebuild the strip from the clean rows just below it. Right
#            for a banner lying on sky or on a scrim, where the paint under it
#            is a smooth vertical gradient; a clone would drag the frame's
#            headline up into it.
PLATES = {
    # The landing carries the app's real copy — headline, name, bio, CTA — so
    # all of it comes out and Flutter draws it back over a scrim. Every other
    # frame keeps its painted copy and gains hotspots instead.
    'landing': {
        'src': 'screen_01.png',
        'night': True,
        'clone': [((55, 676, 450, 804), (0, -300))],
        'wipe': [
            (15, 0, 330, 72),        # frame numbering
            (640, 28, 1275, 95),     # nav row
            (1375, 25, 1615, 98),    # day/night, ambience, secret chips
            (55, 225, 505, 475),     # "Good things are built by…"
            (60, 470, 240, 520),     # gold rule
            (55, 496, 415, 585),     # name
            (60, 568, 552, 675),     # bio
            (60, 680, 445, 800),     # CTA pill
            (785, 862, 955, 948),    # scroll hint
        ],
    },
    # The numbering sits on a dark banner — a low-frequency shape a median
    # keeps. Those strips are cloned from clean paint first, then wiped, so
    # the banner goes with the lettering.
    'workshop': {
        'src': 'screen_02.png',
        'clone': [((0, 0, 700, 125), (700, 0))],
        'wipe': [(0, 0, 700, 125)],
    },
    'journey': {
        'src': 'screen_03.png',
        'night': True,
        'lit': [(45, 128, 295, 373)],
        'extend': [(0, 0, 500, 112), (1480, 0, 1672, 122)],
        'wipe': [(0, 0, 500, 112), (1480, 0, 1672, 122)],
    },
    'fyers_arrival': {
        'src': 'screen_04.png',
        'night': True,
        'extend': [(0, 0, 520, 128)],
        'wipe': [(0, 0, 520, 128)],
    },
    'fyers_problem': {
        'src': 'screen_05.png',
        'extend': [(0, 0, 420, 108)],
        'wipe': [(0, 0, 420, 108)],
    },
    'fyers_result': {
        'src': 'screen_09.png',
        'extend': [(0, 0, 480, 128)],
        'wipe': [(0, 0, 480, 128)],
    },
    'fyers_transition': {
        'src': 'screen_10.png',
        'night': True,
        'lit': [(1295, 63, 1800, 183)],
        'extend': [(0, 0, 600, 118)],
        'wipe': [(0, 0, 600, 118)],
    },
    # Leaves and wood, not sky: extending would streak, so this one clones
    # clean wall from further along the same band.
    'human': {
        'src': 'screen_11.png',
        'clone': [((115, 22, 460, 88), (420, 0))],
        'wipe': [(115, 22, 460, 88)],
    },
    'sunset': {
        'src': 'screen_12.png',
        'extend': [(0, 0, 400, 108)],
        'wipe': [(0, 0, 400, 108)],
    },
}


def clone(img, rect, offset):
    x0, y0, x1, y1 = rect
    dx, dy = offset
    patch = img[y0 + dy:y1 + dy, x0 + dx:x1 + dx].copy()
    feather = cv2.GaussianBlur(np.ones((y1 - y0, x1 - x0), np.float32), (0, 0), 20)
    feather = feather[..., None]
    img[y0:y1, x0:x1] = (img[y0:y1, x0:x1] * (1 - feather)
                         + patch * feather).astype(np.uint8)
    return img


def extend(img, rect):
    """Rebuild a strip from the clean rows immediately below it."""
    x0, y0, x1, y1 = rect
    source = img[y1:y1 + 8, x0:x1].astype(np.float32).mean(axis=0)
    band = np.repeat(source[None, :, :], y1 - y0, axis=0)
    band = cv2.GaussianBlur(band, (0, 0), 6)
    # Feather the right and bottom joins so the rebuilt strip does not end on
    # a visible edge.
    feather = np.ones((y1 - y0, x1 - x0), np.float32)
    feather[:, -70:] *= np.linspace(1, 0, 70)[None, :]
    feather[-40:, :] *= np.linspace(1, 0, 40)[:, None]
    feather = feather[..., None]
    img[y0:y1, x0:x1] = (img[y0:y1, x0:x1] * (1 - feather)
                         + band * feather).astype(np.uint8)
    return img


def wipe(img, rects):
    h, w = img.shape[:2]
    mask = np.zeros((h, w), np.float32)
    for x0, y0, x1, y1 in rects:
        cv2.rectangle(mask, (x0, y0), (x1, y1), 1.0, -1)
    mask = cv2.GaussianBlur(mask, (0, 0), 14)
    soft = cv2.medianBlur(img, 51)
    soft = cv2.medianBlur(soft, 41)
    soft = cv2.GaussianBlur(soft, (0, 0), 11)
    mask = np.dstack([mask] * 3)
    return (img * (1 - mask) + soft * mask).astype(np.uint8)


def base_colours(img):
    """The plate's top and bottom bands, averaged, as Dart colour literals.

    A plate is a third of a megabyte and decodes after the first frame, so a
    scene that hangs one opens on white and then snaps to a painting. These
    two colours are painted immediately instead, as a gradient: the sky the
    plate starts in and the ground it ends in, which is a plausible-enough
    version of the frame to arrive on.
    """
    h = img.shape[0]
    bands = (img[:int(h * 0.18)], img[int(h * 0.82):])
    return tuple(
        '0xFF{:02X}{:02X}{:02X}'.format(
            *(int(round(c)) for c in band.reshape(-1, 3).mean(axis=0)[::-1]))
        for band in bands
    )


def pad(img, aspect=TARGET_ASPECT):
    """Grow a plate to [aspect] by continuing its top and bottom edges.

    The continuation starts as the edge itself — per column, so the sky keeps
    its sun and the ground its colour — and then smears sideways and darkens
    with distance. Extending a detailed edge unchanged combs it into vertical
    streaks; letting it wash out turns the margin into a vignette, which is
    what a viewport wider than the painting should look like.

    How far it washes out matters more than it sounds. The margin is not a
    sliver: the sunset is a 2.46 crop padded to 1.55, so nearly 500 rows of a
    1315-row plate are this band, and at the aspect a browser window actually
    has, 200 of them are on screen above the painting. Fading only part way
    left them bright enough to read as paint — a smeared strip of sky with
    combing still in it, along the top of the best screen in the site. Taken
    down further they read as what they are: the dark inside of a frame the
    painting sits in.
    """
    h, w = img.shape[:2]
    target = int(round(w / aspect))
    if target <= h:
        return img, 0
    extra = target - h
    top, bottom = extra * 45 // 100, extra - extra * 45 // 100

    def band(edge, rows, fade_to):
        if rows <= 0:
            return np.zeros((0, w, 3), np.float32)
        base = np.repeat(edge[None, :, :], rows, axis=0)
        near = cv2.GaussianBlur(base, (0, 0), sigmaX=8, sigmaY=1)
        far = cv2.GaussianBlur(base, (0, 0), sigmaX=110, sigmaY=1)
        t = np.linspace(0, 1, rows)[:, None, None]
        # Into the wide blur quickly — a slow ease keeps the edge's own
        # columns legible for a couple of hundred rows, and reads as combing —
        # then fade the light out of it.
        out = near * (1 - t ** 0.32) + far * t ** 0.32
        return np.clip(out * (1 - (1 - fade_to) * t ** 0.7), 0, 255)

    top_band = band(img[:10].astype(np.float32).mean(axis=0), top, 0.22)[::-1]
    bottom_band = band(img[-10:].astype(np.float32).mean(axis=0), bottom, 0.16)
    out = np.vstack([top_band, img.astype(np.float32), bottom_band])
    # Soften the two joins so the painting does not end on a hard line.
    for y in (top, top + h):
        lo, hi = max(0, y - 36), min(target, y + 36)
        out[lo:hi] = cv2.GaussianBlur(out[lo:hi], (0, 0), 7)
    return out.astype(np.uint8), top


# The grade the app used to run at paint time, now baked. Desaturates ~70%
# toward luminance, then darkens with a cool bias — a colourist's night rather
# than a blue channel left switched on. Kept in step with `_moonlight` in
# lib/world/plate.dart, which still grades any plate with no baked variant.
MOONLIGHT = np.array([
    [0.173, 0.140, 0.026, 0],
    [0.080, 0.271, 0.029, 2],
    [0.118, 0.231, 0.211, 8],
], np.float32)


def grade(img):
    b, g, r = cv2.split(img.astype(np.float32))
    return np.clip(cv2.merge([
        MOONLIGHT[2, 0] * r + MOONLIGHT[2, 1] * g + MOONLIGHT[2, 2] * b + MOONLIGHT[2, 3],
        MOONLIGHT[1, 0] * r + MOONLIGHT[1, 1] * g + MOONLIGHT[1, 2] * b + MOONLIGHT[1, 3],
        MOONLIGHT[0, 0] * r + MOONLIGHT[0, 1] * g + MOONLIGHT[0, 2] * b + MOONLIGHT[0, 3],
    ]), 0, 255)


def sky_mask(img):
    """The open sky: the run of sky-like paint that reaches the top of frame.

    Per column rather than by colour alone, so snow on a peak and the lake do
    not count as sky — only what the stars can actually sit in.
    """
    b, g, r = cv2.split(img.astype(np.float32))
    v = img.max(axis=2).astype(np.float32)
    like = ((v > 105) & (b >= r - 12)).astype(np.uint8)
    h, w = like.shape
    keep = np.zeros_like(like)
    run = np.ones(w, bool)
    for y in range(h):
        run &= like[y] > 0
        if not run.any():
            break
        keep[y] = run
    # Feathered wide: the mask's edge against a tree canopy is a straight
    # vertical line, and a sharp one leaves a visible seam in the sky.
    return np.clip(cv2.GaussianBlur(keep.astype(np.float32), (0, 0), 34), 0, 1) * 0.92


def night(img, seed=7):
    """A moonlit variant of a daylit plate.

    A colour matrix alone cannot do this: the sky is painted bright and hazy
    and stays that way however it is graded, and no matrix can put stars into
    a daytime sky. So the grade is only the first step — the sky band is
    replaced with a night gradient that keeps the cloud modelling, stars are
    scattered through the clear parts of it, and the frame is vignetted.
    """
    h, w = img.shape[:2]
    out = grade(img)
    m = sky_mask(img)[..., None]

    t = np.linspace(0, 1, h)[:, None, None]
    sky = np.array([54, 20, 10], np.float32) + np.array([58, 40, 26], np.float32) * t

    # The clouds survive as the graded sky's detail above its own blur, so the
    # replacement keeps the painting's shapes instead of flattening them.
    blur = cv2.GaussianBlur(out, (0, 0), 55)
    detail = np.clip((out - blur) * 1.25, -60, 60)
    out = out * (1 - m) + np.clip(sky + detail, 0, 255) * m

    # Stars: thickest at the top of the sky, and never on a cloud.
    rng = np.random.default_rng(seed)
    clear = np.clip(1 - np.abs(detail).mean(axis=2) / 26, 0, 1)
    stars = np.zeros((h, w), np.float32)
    ys = rng.integers(0, h, int(w * h / 900))
    xs = rng.integers(0, w, int(w * h / 900))
    for y, x in zip(ys, xs):
        p = m[y, x, 0] * clear[y, x] * (1 - y / h) ** 1.6
        if rng.random() < p * 1.9:
            stars[y, x] = 120 + rng.random() * 135
    stars = cv2.GaussianBlur(stars, (0, 0), 0.8)
    out = np.clip(out + stars[..., None] * np.array([1.0, 0.96, 0.86], np.float32), 0, 255)

    # A cool vignette, so the eye still lands where the copy goes.
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((xx / w - 0.5) * 1.05) ** 2 + ((yy / h - 0.5) * 1.15) ** 2)
    vig = np.clip(1 - np.clip(d - 0.42, 0, 1) * 0.85, 0.42, 1)[..., None]
    return np.clip(out * vig, 0, 255).astype(np.uint8)


def relight(day, out, rects, strength=0.78):
    """Repaint a frame's own handwriting as light strokes.

    The daylight frames set their notes in dark ink on a bright sky. Graded,
    that ink is dark-on-dark and gone. Lifting the strokes out against their
    local ground and adding them back pale is what the palette already does
    for live copy — `onWorld` flips with the light — applied to paint.
    """
    for x0, y0, x1, y1 in rects:
        patch = day[y0:y1, x0:x1].astype(np.float32)
        ground = cv2.GaussianBlur(patch, (0, 0), 26)
        ink = np.clip(ground - patch, 0, 255).min(axis=2)
        ink = np.clip((ink - 14) * 1.35, 0, 255)
        tint = np.array([0.98, 0.93, 0.86], np.float32)
        out[y0:y1, x0:x1] = np.clip(
            out[y0:y1, x0:x1].astype(np.float32) + ink[..., None] * tint * strength,
            0, 255).astype(np.uint8)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    made = []
    for name, spec in PLATES.items():
        img = cv2.imread(os.path.join(REF, spec['src']))
        if img is None:
            raise FileNotFoundError(spec['src'])
        for rect, offset in spec.get('clone', []):
            img = clone(img, rect, offset)
        for rect in spec.get('extend', []):
            img = extend(img, rect)
        img = wipe(img, spec['wipe'])
        img, top = pad(img)

        dest = os.path.join(OUT, f'{name}.webp')
        cv2.imwrite(dest, img, [cv2.IMWRITE_WEBP_QUALITY, QUALITY])
        size = os.path.getsize(dest)
        total += size

        # The night variant is baked from the padded plate, so both files
        # share one geometry and the hotspots traced off the day plate land
        # in the same place on either.
        has_night = spec.get('night', False)
        if has_night:
            lit = [(x0, y0 + top, x1, y1 + top) for x0, y0, x1, y1 in spec.get('lit', [])]
            dark = relight(img, night(img), lit)
            dark_dest = os.path.join(OUT, f'{name}_night.webp')
            cv2.imwrite(dark_dest, dark, [cv2.IMWRITE_WEBP_QUALITY, QUALITY])
            night_size = os.path.getsize(dark_dest)
            total += night_size

        h, w = img.shape[:2]
        sky, ground = base_colours(img)
        made.append((name, w, h, top, has_night, sky, ground))
        night_note = f' + {night_size / 1024:.1f} KB night' if has_night else ''
        print(f'{name:18} {w:>5}x{h:<5} pad top {top:>4}  {size / 1024:8.1f} KB{night_note}')
    print(f'{"total":18} {"":22} {total / 1024:8.1f} KB')
    write_dart(made)


def write_dart(made):
    """Emit the plate geometry the scenes position their hotspots against.

    Padding moves the painting down inside its file, so a hotspot traced off
    the reference would drift. Generating the numbers keeps the two in step.
    """
    lines = [
        '// GENERATED by tool/make_plates.py — do not edit by hand.',
        '//',
        '// Run `python tool/make_plates.py` after changing a reference frame.',
        '',
        "import 'package:flutter/foundation.dart';",
        "import 'package:flutter/painting.dart';",
        '',
        '/// A painted plate: the file, its padded size, and where the original',
        '/// painting sits inside that padding. Hotspots are written in the',
        "/// painting's own coordinates and shifted by [origin].",
        '@immutable',
        'class PlateArt {',
        '  const PlateArt(this.asset, this.size, this.origin, this.sky,',
        '      this.ground, {this.night});',
        '',
        '  final String asset;',
        '  final Size size;',
        '  final Offset origin;',
        '',
        "  /// The average of the plate's top and bottom bands, painted as a",
        '  /// gradient until the file has decoded. Without it the scene opens',
        '  /// on white and then snaps to a painting.',
        '  final Color sky;',
        '  final Color ground;',
        '',
        '  /// The moonlit bake of the same painting, where one exists.',
        '  ///',
        '  /// Only the daylight plates have one, and only they need it: a frame',
        '  /// already painted at night keeps the light it was composed in. A',
        '  /// plate without one is graded at paint time instead.',
        '  final String? night;',
        '}',
        '',
    ]
    for name, w, h, top, has_night, sky, ground in made:
        ident = ''.join(p.capitalize() for p in name.split('_'))
        dark = (f", night: 'assets/art/{name}_night.webp'"
                if has_night else '')
        lines.append(
            f"const plate{ident} = PlateArt('assets/art/{name}.webp',")
        lines.append(f'    Size({w}, {h}), Offset(0, {top}),')
        lines.append(f'    Color({sky}), Color({ground}){dark});')
    with open('lib/world/plates.g.dart', 'w', encoding='utf-8') as f:
        f.write(chr(10).join(lines) + chr(10))
    print('wrote lib/world/plates.g.dart')


if __name__ == '__main__':
    main()
