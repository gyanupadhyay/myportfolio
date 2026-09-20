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

ROOT = 'build/web'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'build/chrome'
PORT = 8123
CHROME = os.environ.get(
    'CHROME_EXECUTABLE',
    r'C:/Program Files/Google/Chrome/Application/chrome.exe',
)

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


def main():
    if not os.path.isdir(ROOT):
        sys.exit('build/web is missing - run: flutter build web --release')
    # Chrome resolves --screenshot and --user-data-dir against its own working
    # directory, so both have to be absolute.
    out = os.path.abspath(OUT)
    os.makedirs(out, exist_ok=True)

    socketserver.TCPServer.allow_reuse_address = True
    server = socketserver.TCPServer(
        ('127.0.0.1', PORT), functools.partial(Quiet, directory=ROOT))
    threading.Thread(target=server.serve_forever, daemon=True).start()

    # A throwaway profile per shot: the app remembers story progress, and a
    # warm profile would let one route's state leak into the next.
    profile = os.path.join(out, '_chrome_profile')
    failed = []
    for name, route in ROUTES:
        dest = os.path.join(out, f'{name}.png')
        shutil.rmtree(profile, ignore_errors=True)
        result = subprocess.run(
            [
                CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                '--no-first-run', '--no-default-browser-check',
                f'--user-data-dir={profile}',
                '--window-size=1440,861', '--force-device-scale-factor=1',
                # CanvasKit boots and the entrance animations settle well
                # inside this budget; virtual time keeps it deterministic.
                '--virtual-time-budget=20000',
                f'--screenshot={dest}',
                f'http://127.0.0.1:{PORT}/#{route}',
            ],
            capture_output=True, text=True, timeout=180,
        )
        size = os.path.getsize(dest) if os.path.exists(dest) else 0
        print(f'{name:26} {route:32} {size / 1024:8.1f} KB')
        if size == 0:
            failed.append(name)
            print('  ', result.stderr.strip()[-400:])

    shutil.rmtree(profile, ignore_errors=True)
    server.shutdown()
    if failed:
        sys.exit(f'no screenshot for: {", ".join(failed)}')


if __name__ == '__main__':
    main()
