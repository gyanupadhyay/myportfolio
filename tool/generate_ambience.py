"""Generate the ambience loops.

The whole world in this app is drawn from code, so its ambience is written the
same way. That also settles the licensing question: nothing here is sampled
from a recording, so the loops can ship with the site.

Every loop is seamless by construction rather than by cross-fading:
  * tonal layers use only frequencies with a whole number of cycles in the
    loop, so the waveform meets itself exactly at the wrap;
  * noise layers are generated in the frequency domain from a real spectrum,
    which makes them inherently periodic over the loop length;
  * one-shot events (a bird, a page) are placed with wraparound, so an event
    near the end continues across the seam.

Run:  python tool/generate_ambience.py
Out:  assets/audio/<name>.ogg
"""
from __future__ import annotations

import os

import numpy as np
import soundfile as sf

RATE = 22050          # plenty for wind and room tone, half the size of 44.1k
SECONDS = 12.0
OUT_DIR = os.path.join('assets', 'audio')

N = int(RATE * SECONDS)
T = np.arange(N) / RATE
RNG_ROOT = 20260920   # fixed, so regenerating gives byte-identical files


def rng(tag: str) -> np.random.Generator:
    """A generator seeded per layer, so layers are independent but stable."""
    return np.random.default_rng(RNG_ROOT + (abs(hash(tag)) % 100_000))


def periodic_noise(tag: str, lo: float, hi: float, slope: float = 0.0):
    """Band-limited noise that loops exactly.

    Built by giving each FFT bin a random phase and a magnitude envelope, then
    transforming back — the result is periodic over exactly N samples.
    [slope] tilts the spectrum: 0 is white, -1 pink, -2 brown.
    """
    g = rng(tag)
    freqs = np.fft.rfftfreq(N, 1 / RATE)
    mag = np.zeros_like(freqs)

    band = (freqs >= lo) & (freqs <= hi)
    mag[band] = 1.0
    # Tilt, guarding the DC bin.
    with np.errstate(divide='ignore'):
        tilt = np.where(freqs > 0, freqs, 1.0) ** slope
    mag *= tilt

    # Soften the band edges so the noise does not sound filtered.
    edge = np.clip((freqs - lo) / max(lo * 0.5, 1.0), 0, 1)
    edge *= np.clip((hi - freqs) / max(hi * 0.25, 1.0), 0, 1)
    mag *= edge

    phase = g.uniform(0, 2 * np.pi, len(freqs))
    spectrum = mag * np.exp(1j * phase)
    spectrum[0] = 0
    out = np.fft.irfft(spectrum, n=N)
    peak = np.max(np.abs(out))
    return out / peak if peak > 0 else out


def loop_sine(cycles: int, phase: float = 0.0):
    """A sine with a whole number of cycles per loop, so it wraps cleanly."""
    return np.sin(2 * np.pi * cycles * T / SECONDS + phase)


def breathe(cycles: int, depth: float, phase: float = 0.0):
    """A slow gain envelope — wind gusting, a room settling."""
    return 1.0 - depth + depth * (0.5 + 0.5 * loop_sine(cycles, phase))


def place(buffer: np.ndarray, sample: np.ndarray, at: int, gain: float):
    """Adds [sample] at [at], wrapping past the end so the seam is clean."""
    end = at + len(sample)
    if end <= N:
        buffer[at:end] += sample * gain
    else:
        split = N - at
        buffer[at:] += sample[:split] * gain
        buffer[: end - N] += sample[split:] * gain


def chirp(duration: float, f0: float, f1: float, warble: float = 0.0):
    """A short bird-like note: a glide, with optional flutter."""
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    sweep = f0 + (f1 - f0) * (t / max(t[-1], 1e-6))
    if warble:
        sweep += warble * np.sin(2 * np.pi * 26 * t)
    tone = np.sin(2 * np.pi * np.cumsum(sweep) / RATE)
    # A soft attack and a longer decay keeps it from clicking.
    env = np.exp(-t * 9.0) * np.clip(t / 0.012, 0, 1)
    return tone * env


def water(tag: str):
    """Lapping water: low noise, amplitude-modulated at an irrational-ish rate
    built from two loop-safe components so it never sounds metronomic."""
    body = periodic_noise(tag + ':body', 120, 2400, slope=-1.2)
    swell = breathe(7, 0.55) * breathe(11, 0.35, phase=1.1)
    return body * swell


def normalise(x: np.ndarray, peak: float):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def soft_clip(x: np.ndarray):
    """Rounds off any stray peak without audible distortion."""
    return np.tanh(x * 1.2) / np.tanh(1.2)


# ---------------------------------------------------------------- the loops

def valley_day():
    """Open air: wind through the valley, a few birds, distant brightness."""
    wind = periodic_noise('day:wind', 180, 5200, slope=-1.1) * breathe(3, 0.45)
    wind += periodic_noise('day:gust', 90, 1400, slope=-1.4) * breathe(5, 0.6, 0.8) * 0.5
    bed = wind * 0.5

    birds = np.zeros(N)
    g = rng('day:birds')
    for i in range(14):
        at = int(g.uniform(0, N))
        f0 = g.uniform(1900, 3400)
        note = chirp(g.uniform(0.09, 0.20), f0, f0 * g.uniform(1.15, 1.7),
                     warble=g.uniform(0, 90))
        place(birds, note, at, g.uniform(0.05, 0.13))

    return soft_clip(normalise(bed + birds, 0.72))


def valley_dusk():
    """The light going: wind softer, fewer birds, a low warmth underneath."""
    wind = periodic_noise('dusk:wind', 140, 3600, slope=-1.3) * breathe(2, 0.5)
    bed = wind * 0.45

    birds = np.zeros(N)
    g = rng('dusk:birds')
    for i in range(5):
        at = int(g.uniform(0, N))
        f0 = g.uniform(1500, 2400)
        place(birds, chirp(g.uniform(0.12, 0.24), f0, f0 * 1.2), at,
              g.uniform(0.03, 0.07))

    crickets = periodic_noise('dusk:crickets', 3800, 5200, slope=0.0)
    # 24 cycles over the loop is a whole number, so the pulse wraps cleanly.
    crickets *= (0.5 + 0.5 * np.tanh(np.sin(2 * np.pi * 24 * T) * 4)) * 0.04

    return soft_clip(normalise(bed + birds + crickets, 0.6))


def valley_sunset():
    """Wide and still: low wind over water, no birds."""
    wind = periodic_noise('sunset:wind', 110, 2600, slope=-1.4) * breathe(2, 0.4)
    lap = water('sunset:water') * 0.42
    return soft_clip(normalise(wind * 0.4 + lap, 0.62))


def room_night():
    """A desk at night: room tone, the faint hum of a machine, nothing else."""
    tone = periodic_noise('night:tone', 40, 900, slope=-1.8) * breathe(2, 0.18)
    # A quiet mains-ish hum, locked to the loop so it does not beat at the seam.
    hum = (loop_sine(600) * 0.5 + loop_sine(1200) * 0.18) * 0.012
    return soft_clip(normalise(tone * 0.5 + hum, 0.42))


def room_interior():
    """The workshop: warmer room tone, the occasional settle of the building."""
    tone = periodic_noise('interior:tone', 60, 1500, slope=-1.6) * breathe(3, 0.22)

    creaks = np.zeros(N)
    g = rng('interior:creak')
    for i in range(4):
        at = int(g.uniform(0, N))
        f0 = g.uniform(70, 150)
        place(creaks, chirp(g.uniform(0.3, 0.7), f0, f0 * 0.8), at,
              g.uniform(0.02, 0.05))

    return soft_clip(normalise(tone * 0.52 + creaks, 0.5))


LOOPS = {
    'valley-day': valley_day,
    'valley-dusk': valley_dusk,
    'valley-sunset': valley_sunset,
    'room-night': room_night,
    'room-interior': room_interior,
}


def write_ogg(path: str, samples: np.ndarray):
    """Vorbis: about a twentieth the size of PCM, and the browser decodes it
    natively. Ambience is opt-in, so these are only fetched if it is enabled."""
    sf.write(path, np.clip(samples, -1.0, 1.0), RATE, format='OGG',
             subtype='VORBIS')


def seam_ratio(samples: np.ndarray) -> float:
    """How the wrap compares to an ordinary sample-to-sample step.

    Comparing the first and last sample outright is misleading: they are one
    step apart, so even a perfect loop shows a difference. What matters is
    whether the wrap is a *discontinuity* — a step far larger than the signal's
    typical one. Anything near 1.0 is inaudible.
    """
    steps = np.abs(np.diff(samples))
    typical = float(np.percentile(steps, 99))
    wrap = float(abs(samples[0] - samples[-1]))
    return wrap / typical if typical > 0 else 0.0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'{"loop":<16}{"secs":>6}{"KB":>8}{"peak":>7}{"seam x step":>13}')
    print('-' * 50)
    total = 0.0
    for name, build in LOOPS.items():
        samples = build()
        path = os.path.join(OUT_DIR, f'{name}.ogg')
        write_ogg(path, samples)
        size = os.path.getsize(path) / 1024
        total += size
        print(f'{name:<16}{SECONDS:>6.0f}{size:>8.0f}'
              f'{np.max(np.abs(samples)):>7.2f}{seam_ratio(samples):>13.2f}')
    print('-' * 50)
    print(f'{"total":<16}{"":>6}{total:>8.0f}')


if __name__ == '__main__':
    main()
