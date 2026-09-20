"""Put the reference and the render side by side in design space with a
coordinate grid, so UI positions can be read off directly rather than guessed.
"""
import os
import sys
import cv2
import numpy as np

DW, DH = 1440, 861
REF_DIR = 'docs/reference'
RENDER_DIR = 'build/frames'
OUT = 'build/compare'

pairs = {
    '01': ('screen_01.png', 'frame_01_landing.png'),
    '02': ('screen_02.png', 'frame_02_workshop.png'),
    '03': ('screen_03.png', 'frame_03_journey.png'),
    '04': ('screen_04.png', 'frame_04_fyers_arrival.png'),
    '05': ('screen_05.png', 'frame_05_problem.png'),
    '06': ('screen_06.png', 'frame_06_investigation.png'),
    '07': ('screen_07.png', 'frame_07_solution.png'),
    '08': ('screen_08.png', 'frame_08_deepdive.png'),
    '09': ('screen_09.png', 'frame_09_result.png'),
    '10': ('screen_10.png', 'frame_10_transition.png'),
    '11': ('screen_11.png', 'frame_11_personal.png'),
    '12': ('screen_12.png', 'frame_12_contact.png'),
}


def gridded(path, title):
    img = cv2.imread(path, cv2.IMREAD_COLOR)
    h0, w0 = img.shape[:2]
    img = cv2.resize(img, (DW, DH), interpolation=cv2.INTER_AREA)
    for x in range(0, DW + 1, 120):
        cv2.line(img, (x, 0), (x, DH), (0, 255, 255), 1)
        cv2.putText(img, str(x), (x + 3, 14), cv2.FONT_HERSHEY_SIMPLEX, 0.38,
                    (0, 255, 255), 1, cv2.LINE_AA)
    for y in range(0, DH + 1, 60):
        cv2.line(img, (0, y), (DW, y), (0, 255, 255), 1)
        cv2.putText(img, str(y), (3, y - 3), cv2.FONT_HERSHEY_SIMPLEX, 0.38,
                    (0, 255, 255), 1, cv2.LINE_AA)
    bar = np.zeros((28, DW, 3), np.uint8)
    cv2.putText(bar, f'{title}   (source {w0}x{h0})', (8, 20),
                cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1, cv2.LINE_AA)
    return np.vstack([bar, img])


os.makedirs(OUT, exist_ok=True)
which = sys.argv[1:] or list(pairs)
for key in which:
    ref_name, ren_name = pairs[key]
    a = gridded(os.path.join(REF_DIR, ref_name), f'REFERENCE {ref_name}')
    b = gridded(os.path.join(RENDER_DIR, ren_name), f'RENDERED  {ren_name}')
    cv2.imwrite(os.path.join(OUT, f'grid_{key}.png'), np.vstack([a, b]))
    print('wrote', os.path.join(OUT, f'grid_{key}.png'))
