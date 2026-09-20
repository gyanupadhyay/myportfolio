"""Screenshot the built web app in real headless Chrome.

`flutter test` renders goldens in the headless Skia tester, which cannot see
browser-only problems: web font loading, icon fallbacks, and how a scene
actually fits the viewport. This serves `build/web` and drives Chrome over the
same routes so those renders can be compared against `docs/reference`.

    flutter build web --release
    python tool/chrome_shots.py            # -> build/chrome/*.png
"""
import functools
import http.server
import os
import shutil
import socketserver
import subprocess
import sys
import threading

# Only used to tell a real frame from a flat one. The screenshot run is still
# worth having without it, so this is a soft dependency rather than a hard one.
try:
    import cv2
except ImportError:
    cv2 = None

# A route that fails to come up leaves a flat white frame, and PNG squeezes
# that to almost nothing: the blanks measure 5.6 KB where the thinnest real
# frame measures 390. Anything in between is a frame worth looking at.
BLANK_KB = 60

# How many times to re-take a blank shot before calling it a real failure.
#
# A single shot comes out blank perhaps a quarter of the time. Retrying clears
# most of that, but not all: the failures cluster rather than falling
# independently — a run started while the machine is still busy with a build
# can lose the same route six times running, where an idle machine takes every
# shot first or second try. So this reduces the noise; it does not remove it.
# A run that still cannot draw a route says so and fails, which is the point:
# the white PNG it used to leave behind looked exactly like a pass.
ATTEMPTS = 6

ROOT = 'build/web'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'build/chrome'
PORT = 8123
CHROME = os.environ.get(
    'CHROME_EXECUTABLE',
    r'C:/Program Files/Google/Chrome/Application/chrome.exe',
)

# The shape the frames were composed at. Override to check another viewport.
VIEWPORT = os.environ.get('SHOT_VIEWPORT', '1440,861')

# The frames that have a reference mockup, by the route that shows them.
ROUTES = [
    ('chrome_01_landing', '/'),
    ('chrome_02_workshop', '/workshop'),
    ('chrome_03_journey', '/map'),
    ('chrome_04_fyers_arrival', '/chapter/fyers/arrival'),
    ('chrome_05_problem', '/chapter/fyers/problem'),
    ('chrome_06_investigation', '/chapter/fyers/investigation'),
    ('chrome_07_solution', '/chapter/fyers/solution'),
    ('chrome_08_deepdive', '/chapter/fyers/deepdive'),
    ('chrome_09_result', '/chapter/fyers/result'),
    ('chrome_10_transition', '/chapter/fyers/transition'),
    ('chrome_11_personal', '/human'),
    ('chrome_12_contact', '/sunset'),
]


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


class QuietServer(socketserver.TCPServer):
    allow_reuse_address = True

    def handle_error(self, request, client_address):
        # Chrome drops its pending requests when it exits after the shot, and
        # the resulting reset connections are not news. Left to the default
        # this prints a traceback per abort, which buries the run's output.
        # It belongs on the server: the exception escapes the handler.
        pass


def shoot(dest, route, profile, size=None):
    """One screenshot of [route], into [dest].

    A throwaway profile per shot: the app remembers story progress, and a warm
    profile would let one route's state leak into the next. [size] is the
    viewport, `width,height`, for checking a scene at a shape other than the
    one the frames were composed at.
    """
    shutil.rmtree(profile, ignore_errors=True)
    return subprocess.run(
        [
            CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
            '--no-first-run', '--no-default-browser-check',
            f'--user-data-dir={profile}',
            f'--window-size={size or VIEWPORT}',
            '--force-device-scale-factor=1',
            # CanvasKit boots, the plate decodes and the entrance animations
            # settle inside this budget; virtual time keeps it deterministic.
            '--virtual-time-budget=30000',
            # Without these the shot can land before a decoded plate has been
            # composited, and the scene comes out blank.
            '--run-all-compositor-stages-before-draw',
            '--disable-new-content-rendering-timeout',
            f'--screenshot={dest}',
            f'http://127.0.0.1:{PORT}/#{route}',
        ],
        capture_output=True, text=True, timeout=180,
    )


def blankness(path):
    """Why [path] is not a picture of a scene, or None if it is one.

    Checked because the app draws into a canvas: a route that throws, or never
    resolves its deferred import, still produces a screenshot — a white one —
    and a run that only fails on a *missing* file calls that a pass. Both this
    project's blank routes sat unnoticed behind exactly that.
    """
    if not os.path.exists(path):
        return 'no file'
    size = os.path.getsize(path)
    if size == 0:
        return 'empty file'
    if size < BLANK_KB * 1024:
        return f'{size / 1024:.1f} KB, nothing drawn'
    if cv2 is not None:
        img = cv2.imread(path)
        # A frame can be large and still be wrong: a flat fill of any colour,
        # or chrome drawn over a world that never arrived.
        if img is not None and img.std() < 6:
            return 'a flat frame, nothing drawn'
    return None


def main():
    if not os.path.isdir(ROOT):
        sys.exit('build/web is missing - run: flutter build web --release')
    # Chrome resolves --screenshot and --user-data-dir against its own working
    # directory, so both have to be absolute.
    out = os.path.abspath(OUT)
    os.makedirs(out, exist_ok=True)

    server = QuietServer(
        ('127.0.0.1', PORT), functools.partial(Quiet, directory=ROOT))
    threading.Thread(target=server.serve_forever, daemon=True).start()

    profile = os.path.join(out, '_chrome_profile')
    failed = []
    for name, route in ROUTES:
        dest = os.path.join(out, f'{name}.png')
        # Retried, because the capture itself is racy rather than the routes:
        # the scenes animate continuously, so the virtual-time budget can
        # expire between CanvasKit frames and catch the surface before it is
        # composited. Which route loses that race moves from run to run, and a
        # longer budget does not help — only taking the shot again does.
        for attempt in range(ATTEMPTS):
            result = shoot(dest, route, profile)
            blank = blankness(dest)
            if blank is None:
                break
        size = os.path.getsize(dest) if os.path.exists(dest) else 0
        retried = '' if attempt == 0 else f'  ({attempt + 1} attempts)'
        note = retried if blank is None else f'  <-- {blank}, gave up'
        print(f'{name:26} {route:32} {size / 1024:8.1f} KB{note}')
        if blank is not None:
            failed.append(f'{name} ({blank})')
            if result.stderr.strip():
                print('  ', result.stderr.strip()[-400:])

    shutil.rmtree(profile, ignore_errors=True)
    server.shutdown()
    if cv2 is None:
        print('note: cv2 not installed - checked file size only, not flatness')
    if failed:
        sys.exit('nothing rendered for:'
                 + ''.join(f'{chr(10)}  {f}' for f in failed))


if __name__ == '__main__':
    main()
