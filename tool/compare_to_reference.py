"""Compare each rendered frame against its reference mockup.

A single similarity number would be misleading here: the references are
painted illustrations, so any pixel diff is dominated by brush texture that
code was never going to reproduce. Instead this reports four complementary
measures, so the art difference and the layout difference can be told apart.
"""
import os
import json

import cv2
import numpy as np

REF_DIR = 'docs/reference'
OUT_DIR = 'build/compare'
RENDER_DIR = 'build/frames'

PAIRS = [
    ('screen_01.png', 'frame_01_landing.png', 'Landing / The World'),
    ('screen_02.png', 'frame_02_workshop.png', 'The Workshop'),
    ('screen_03.png', 'frame_03_journey.png', 'The Journey Map'),
    ('screen_04.png', 'frame_04_fyers_arrival.png', 'FYERS — arrival'),
    ('screen_05.png', 'frame_05_problem.png', 'FYERS — the problem'),
    ('screen_06.png', 'frame_06_investigation.png', 'FYERS — investigation'),
    ('screen_07.png', 'frame_07_solution.png', 'FYERS — the solution'),
    ('screen_08.png', 'frame_08_deepdive.png', 'FYERS — deep dive'),
    ('screen_09.png', 'frame_09_result.png', 'FYERS — the result'),
    ('screen_10.png', 'frame_10_transition.png', 'FYERS — transition'),
    ('screen_11.png', 'frame_11_personal.png', 'Personal Side'),
    ('screen_12.png', 'frame_12_contact.png', 'Final / Contact'),
]

W, H = 960, 574


def load(path):
    img = cv2.imread(path, cv2.IMREAD_COLOR)
    if img is None:
        raise FileNotFoundError(path)
    return cv2.resize(img, (W, H), interpolation=cv2.INTER_AREA)


def ssim(a, b):
    """Global structural similarity on luminance."""
    a = a.astype(np.float64)
    b = b.astype(np.float64)
    k = (11, 11)
    mu_a = cv2.GaussianBlur(a, k, 1.5)
    mu_b = cv2.GaussianBlur(b, k, 1.5)
    sa = cv2.GaussianBlur(a * a, k, 1.5) - mu_a ** 2
    sb = cv2.GaussianBlur(b * b, k, 1.5) - mu_b ** 2
    sab = cv2.GaussianBlur(a * b, k, 1.5) - mu_a * mu_b
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    num = (2 * mu_a * mu_b + c1) * (2 * sab + c2)
    den = (mu_a ** 2 + mu_b ** 2 + c1) * (sa + sb + c2)
    return float(np.mean(num / den))


def layout_corr(ga, gb, cols=24, rows=12):
    """Where does 'content' sit?

    Local contrast energy per grid cell, correlated between the two images.
    Insensitive to hue and brush texture, sensitive to whether a panel, a
    block of text or a figure occupies the same region.
    """
    def energy(g):
        lap = np.abs(cv2.Laplacian(g.astype(np.float32), cv2.CV_32F, ksize=3))
        cell_h, cell_w = g.shape[0] // rows, g.shape[1] // cols
        out = np.zeros((rows, cols), np.float32)
        for r in range(rows):
            for c in range(cols):
                blk = lap[r * cell_h:(r + 1) * cell_h, c * cell_w:(c + 1) * cell_w]
                out[r, c] = blk.mean()
        # Normalise so overall busyness does not dominate.
        return (out - out.mean()) / (out.std() + 1e-6)

    ea, eb = energy(ga).ravel(), energy(gb).ravel()
    return float(np.corrcoef(ea, eb)[0, 1])


def horizon_profile_corr(ga, gb):
    """Row-mean luminance profile.

    Catches whether the major horizontal bands — sky, mountains, water,
    ground, desk — sit at the same heights.
    """
    pa = ga.mean(axis=1).astype(np.float64)
    pb = gb.mean(axis=1).astype(np.float64)
    pa = (pa - pa.mean()) / (pa.std() + 1e-6)
    pb = (pb - pb.mean()) / (pb.std() + 1e-6)
    return float(np.corrcoef(pa, pb)[0, 1])


def palette_distance(a, b):
    """Mean CIELAB distance between the two images' colour distributions."""
    la = cv2.cvtColor(a, cv2.COLOR_BGR2LAB).reshape(-1, 3).astype(np.float32)
    lb = cv2.cvtColor(b, cv2.COLOR_BGR2LAB).reshape(-1, 3).astype(np.float32)
    return float(np.linalg.norm(la.mean(axis=0) - lb.mean(axis=0)))


def edge_iou(ga, gb):
    """Do structural lines land in the same places?"""
    ea = cv2.dilate(cv2.Canny(ga, 60, 160), np.ones((5, 5), np.uint8)) > 0
    eb = cv2.dilate(cv2.Canny(gb, 60, 160), np.ones((5, 5), np.uint8)) > 0
    union = np.logical_or(ea, eb).sum()
    if union == 0:
        return 0.0
    return float(np.logical_and(ea, eb).sum() / union)


def label(img, text):
    out = img.copy()
    cv2.rectangle(out, (0, 0), (W, 26), (30, 30, 30), -1)
    cv2.putText(out, text, (10, 18), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                (240, 240, 240), 1, cv2.LINE_AA)
    return out


os.makedirs(OUT_DIR, exist_ok=True)
rows_out = []

for ref_name, render_name, title in PAIRS:
    ref = load(os.path.join(REF_DIR, ref_name))
    ren = load(os.path.join(RENDER_DIR, render_name))
    gref = cv2.cvtColor(ref, cv2.COLOR_BGR2GRAY)
    gren = cv2.cvtColor(ren, cv2.COLOR_BGR2GRAY)

    m = {
        'frame': ref_name.replace('screen_', '').replace('.png', ''),
        'title': title,
        'layout': layout_corr(gref, gren),
        'bands': horizon_profile_corr(gref, gren),
        'edges': edge_iou(gref, gren),
        'ssim': ssim(gref, gren),
        'lab': palette_distance(ref, ren),
    }
    rows_out.append(m)

    # Side by side, plus a red/green difference map.
    diff = cv2.absdiff(gref, gren)
    heat = cv2.applyColorMap(diff, cv2.COLORMAP_INFERNO)
    top = np.hstack([label(ref, 'REFERENCE  ' + title),
                     label(ren, 'RENDERED   ' + title)])
    bottom = np.hstack([label(heat, 'DIFFERENCE (bright = diverges)'),
                        label(cv2.addWeighted(ref, 0.5, ren, 0.5, 0), 'OVERLAY 50/50')])
    cv2.imwrite(os.path.join(OUT_DIR, f'compare_{m["frame"]}.png'),
                np.vstack([top, bottom]))

print(json.dumps(rows_out, indent=1))

hdr = f"{'#':<3}{'frame':<24}{'layout':>8}{'bands':>8}{'edges':>8}{'ssim':>8}{'dLab':>8}"
print()
print(hdr)
print('-' * len(hdr))
for m in rows_out:
    print(f"{m['frame']:<3}{m['title'][:23]:<24}"
          f"{m['layout']:>8.2f}{m['bands']:>8.2f}{m['edges']:>8.2f}"
          f"{m['ssim']:>8.2f}{m['lab']:>8.1f}")
print('-' * len(hdr))
avg = lambda k: sum(m[k] for m in rows_out) / len(rows_out)
print(f"{'':<3}{'MEAN':<24}{avg('layout'):>8.2f}{avg('bands'):>8.2f}"
      f"{avg('edges'):>8.2f}{avg('ssim'):>8.2f}{avg('lab'):>8.1f}")
