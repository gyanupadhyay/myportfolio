"""Generate the ambience loops.

The whole world in this app is drawn from code, so its ambience is written the
same way. That also settles the licensing question: nothing here is sampled
from a recording, so the loops can ship with the site.

Each loop is two things at once:

  * a **bed** — wind, birds, room tone, the sound of the place;
  * a **score** — a slow waltz for piano, strings and a wooden flute.

The score is what makes it feel like the films rather than like a weather
report. It is one piece of music in F major across all five loops: the same
tempo, the same harmonic family, the same instruments thinning out or filling
in with the light. Walking from the valley into the workshop is a change of
scoring, not a change of soundtrack.

Every loop is seamless by construction rather than by cross-fading:
  * noise layers are generated in the frequency domain from a real spectrum,
    which makes them inherently periodic over the loop length;
  * tonal drones use only frequencies with a whole number of cycles in the
    loop, so the waveform meets itself exactly at the wrap;
  * every note and every one-shot event is placed with wraparound, so a piano
    note struck in the last bar rings on across the seam into the first.

Run:  python tool/generate_ambience.py
Out:  assets/audio/<name>.ogg
"""
from __future__ import annotations

import math
import os
import zlib

import numpy as np
import soundfile as sf

RATE = 22050          # plenty for wind, room tone and a soft piano
OUT_DIR = os.path.join('assets', 'audio')

# The music. A waltz, slow enough to sit behind reading: 75 bpm in 3/4, twelve
# bars, which lands the loop at 28.8 s — long enough for a phrase to breathe
# and come back round without the visitor noticing where it started.
BEAT = 0.8
BEATS_PER_BAR = 3
BARS = 12
SECONDS = BARS * BEATS_PER_BAR * BEAT

N = int(RATE * SECONDS)
T = np.arange(N) / RATE
# Fixed, so regenerating gives identical *audio*. Not identical files: libogg
# stamps each stream with a random serial number, so the bytes differ even when
# every sample matches.
RNG_ROOT = 20260920


def rng(tag: str) -> np.random.Generator:
    """A generator seeded per layer, so layers are independent but stable.

    Seeded from a CRC rather than hash(): Python salts string hashes per
    process, which would make "deterministic" true only within a single run.
    """
    return np.random.default_rng(RNG_ROOT + zlib.crc32(tag.encode()))


# ------------------------------------------------------------------ texture

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


def birdsong(tag: str, count: int, lo: float, hi: float, gain: float,
             warble: float = 90.0):
    """A handful of calls scattered across the loop."""
    out = np.zeros(N)
    g = rng(tag)
    for _ in range(count):
        f0 = g.uniform(lo, hi)
        note = chirp(g.uniform(0.09, 0.20), f0, f0 * g.uniform(1.15, 1.7),
                     warble=g.uniform(0, warble))
        place(out, note, int(g.uniform(0, N)), g.uniform(0.5, 1.3) * gain)
    return out


# -------------------------------------------------------------------- notes

_STEP = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def freq(name: str) -> float:
    """Scientific pitch to hertz: 'Bb3', 'F#5', 'C4' (middle C)."""
    semitone = _STEP[name[0]]
    i = 1
    while name[i] in '#b':
        semitone += 1 if name[i] == '#' else -1
        i += 1
    midi = 12 * (int(name[i:]) + 1) + semitone
    return 440.0 * 2 ** ((midi - 69) / 12)


def _fade_out(n: int, seconds: float):
    """A cosine fade over the tail of a note, so truncating never clicks."""
    env = np.ones(n)
    k = min(n, int(RATE * seconds))
    if k > 1:
        env[n - k:] = 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, k))
    return env


def keys(f0: float, hold: float):
    """A felt piano: struck, slightly inharmonic, dying away slowly.

    Partials are stretched by the stiffness of a real string, high ones decay
    faster than low ones, and a breath of noise under the attack stands in for
    the hammer. That last detail is most of what separates a piano from an
    organ.
    """
    n = int(RATE * (hold + 2.6))
    t = np.arange(n) / RATE
    out = np.zeros(n)
    base = 0.9 + 0.9 * (f0 / 440.0)
    for k in range(1, 15):
        f = f0 * k * math.sqrt(1 + 0.0006 * k * k)
        if f > 0.45 * RATE:
            break
        amp = 1.0 / k ** 1.7
        out += amp * np.sin(2 * np.pi * f * t + 0.7 * k) \
            * np.exp(-t * base * (1 + 0.45 * (k - 1)))
    out *= np.clip(t / 0.006, 0, 1)
    hammer = np.random.default_rng(int(f0 * 10)).normal(0, 1, n)
    out += hammer * np.exp(-t * 90) * 0.035
    return out * _fade_out(n, 0.05) * 0.62


def music_box(f0: float, hold: float):
    """A wound music box: a tine, not a string — bright, short, and a little
    out of tune with itself in the upper partials."""
    n = int(RATE * 2.4)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for ratio, amp, decay in ((1.0, 1.0, 3.6), (2.0, 0.42, 5.2),
                              (3.02, 0.2, 8.0), (4.97, 0.09, 12.0),
                              (8.1, 0.04, 17.0)):
        f = f0 * ratio
        if f > 0.45 * RATE:
            continue
        out += amp * np.sin(2 * np.pi * f * t + ratio) * np.exp(-t * decay)
    out *= np.clip(t / 0.004, 0, 1)
    return out * _fade_out(n, 0.05) * 0.55


def marimba(f0: float, hold: float):
    """Struck wood. The bar's overtones sit near the fourth and ninth
    harmonics, which is why a marimba reads as warm rather than bell-like."""
    n = int(RATE * 1.6)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for ratio, amp, decay in ((1.0, 1.0, 4.6), (3.93, 0.3, 9.5),
                              (9.2, 0.08, 16.0)):
        f = f0 * ratio
        if f > 0.45 * RATE:
            continue
        out += amp * np.sin(2 * np.pi * f * t + ratio) * np.exp(-t * decay)
    mallet = np.random.default_rng(int(f0 * 3)).normal(0, 1, n)
    out += mallet * np.exp(-t * 130) * 0.03
    out *= np.clip(t / 0.005, 0, 1)
    return out * _fade_out(n, 0.04) * 0.6


def flute(f0: float, hold: float):
    """A wooden flute for the melody — mostly fundamental, an octave above it,
    a little air, and vibrato that arrives only after the note has settled."""
    n = int(RATE * (hold + 0.22))
    t = np.arange(n) / RATE
    vibrato = 1 + 0.005 * np.sin(2 * np.pi * 5.1 * t) \
        * np.clip((t - 0.2) / 0.5, 0, 1)
    phase = 2 * np.pi * f0 * np.cumsum(vibrato) / RATE
    out = np.sin(phase) + 0.17 * np.sin(2 * phase) + 0.05 * np.sin(3 * phase)

    air = np.random.default_rng(int(f0 * 7)).normal(0, 1, n)
    air = np.convolve(air, [1.0, -1.0], mode='same')      # tilt it up, crudely
    out += air * 0.022

    env = np.clip(t / 0.075, 0, 1) ** 1.3
    env *= 1 + 0.04 * np.sin(2 * np.pi * 0.7 * t)
    return out * env * _fade_out(n, 0.2) * 0.42


def strings(f0: float, hold: float):
    """A small string section: three players, none quite in tune with the
    others, bowed in rather than struck. Higher partials are rolled off, which
    is the difference between a bow and a buzz."""
    n = int(RATE * (hold + 1.5))
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for detune in (-0.0045, 0.0, 0.0045):
        f = f0 * (1 + detune)
        for k in range(1, 13):
            fk = f * k
            if fk > 0.45 * RATE:
                break
            amp = (1.0 / k) / (1 + (fk / 1500.0) ** 2)
            out += amp * np.sin(2 * np.pi * fk * t + 1.3 * k + 220 * detune)
    out *= np.clip(t / 0.55, 0, 1) ** 1.4
    out *= 1 + 0.07 * np.sin(2 * np.pi * 0.23 * t)
    return out * _fade_out(n, 1.35) * 0.22


# ---------------------------------------------------------------- the score

# Voicings sit in one octave so the harmony never jumps register between bars.
CHORDS = {
    'F':    ('F3', 'A3', 'C4'),
    'FM9':  ('F3', 'A3', 'C4', 'G4'),
    'Am':   ('A3', 'C4', 'E4'),
    'Bb':   ('Bb3', 'D4', 'F4'),
    'BbM7': ('Bb3', 'D4', 'F4', 'A4'),
    'C':    ('C4', 'E4', 'G4'),
    'Csus': ('C4', 'F4', 'G4'),
    'Dm':   ('D3', 'F3', 'A3'),
    'Dm7':  ('D3', 'F3', 'A3', 'C4'),
    'Gm':   ('G3', 'Bb3', 'D4'),
    'Gm7':  ('G3', 'Bb3', 'D4', 'F4'),
}

# Where each root sits in the bass. Kept inside a ninth so the left hand walks
# rather than leaps.
BASS = {'F': 'F2', 'G': 'G2', 'A': 'A2', 'Bb': 'Bb2', 'C': 'C3', 'D': 'D3'}


def bass_of(chord: str) -> str:
    root = chord[:2] if len(chord) > 1 and chord[1] == 'b' else chord[:1]
    return BASS[root]


def at(bar: float, beat: float) -> int:
    """Sample index of a position in the score."""
    return int(((bar * BEATS_PER_BAR + beat) * BEAT) * RATE) % N


def _human(tag: str, index: int):
    """A player is not a sequencer: nudge each note off the grid and off the
    printed dynamic, by the same amount every time the tool is run."""
    g = np.random.default_rng(RNG_ROOT + zlib.crc32(tag.encode()) + index * 977)
    return int(g.uniform(-0.012, 0.012) * RATE), float(g.uniform(0.86, 1.14))


def perform(buf, voice, score, gain: float, tag: str, octave: int = 0):
    """Plays a melody: (bar, beat, note, beats), with each note's own tail left
    to ring past its written length.

    Melodies are written in the same octave as the harmony so the two can be
    read against each other, then lifted clear with [octave]. A tune competing
    for register with its own accompaniment is the fastest way to lose it.
    """
    for i, (bar, beat, name, beats) in enumerate(score):
        shift, dynamic = _human(tag, i)
        place(buf, voice(freq(name) * 2 ** octave, beats * BEAT),
              (at(bar, beat) + shift) % N, gain * dynamic)


def waltz(buf, progression, gain: float, voice=keys, tag: str = 'waltz'):
    """The left hand: root on one, the chord on two and three, each chord
    rolled slightly so it sounds played rather than triggered."""
    for bar, chord in enumerate(progression):
        shift, dynamic = _human(tag, bar)
        place(buf, voice(freq(bass_of(chord)), BEAT), (at(bar, 0) + shift) % N,
              gain * dynamic)
        for beat in (1, 2):
            for v, tone in enumerate(CHORDS[chord]):
                roll, dyn = _human(tag + ':chord', bar * 8 + beat * 4 + v)
                place(buf, voice(freq(tone), BEAT * 0.9),
                      (at(bar, beat) + roll + int(v * 0.007 * RATE)) % N,
                      gain * 0.42 * dyn)


def pad(buf, progression, gain: float, bars_per_chord: int = 1):
    """Strings holding the harmony under everything else. Releases run past the
    bar line and over the seam, so the chords overlap the way a section does."""
    for bar in range(0, BARS, bars_per_chord):
        chord = progression[bar]
        hold = BEAT * BEATS_PER_BAR * bars_per_chord
        for tone in CHORDS[chord]:
            place(buf, strings(freq(tone), hold), at(bar, 0), gain)


def cello(buf, progression, gain: float, bars_per_chord: int = 1):
    """One long bowed root per chord, an octave under the pad."""
    for bar in range(0, BARS, bars_per_chord):
        hold = BEAT * BEATS_PER_BAR * bars_per_chord
        place(buf, strings(freq(bass_of(progression[bar])), hold),
              at(bar, 0), gain)


def normalise(x: np.ndarray, peak: float):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def soft_clip(x: np.ndarray):
    """Rounds off any stray peak without audible distortion."""
    return np.tanh(x * 1.2) / np.tanh(1.2)


# ---------------------------------------------------------------- the loops

DAY_CHORDS = ['F', 'Am', 'Bb', 'C', 'Dm', 'Bb', 'F', 'C',
              'Bb', 'F', 'Gm7', 'C']

# Twelve bars that rise to F5 in the middle and come home through a suspension,
# so the last bar leans on the first rather than stopping at it.
DAY_MELODY = [
    (0, 0, 'F4', 1), (0, 1, 'A4', 1), (0, 2, 'C5', 1),
    (1, 0, 'D5', 2), (1, 2, 'C5', 1),
    (2, 0, 'A4', 1.5), (2, 1.5, 'Bb4', 0.5), (2, 2, 'C5', 1),
    (3, 0, 'G4', 3),
    (4, 0, 'A4', 1), (4, 1, 'D5', 1), (4, 2, 'E5', 1),
    (5, 0, 'F5', 2), (5, 2, 'D5', 1),
    (6, 0, 'C5', 2), (6, 2, 'A4', 1),
    (7, 0, 'Bb4', 1.5), (7, 1.5, 'A4', 0.5), (7, 2, 'G4', 1),
    (8, 0, 'F4', 1), (8, 1, 'Bb4', 1), (8, 2, 'D5', 1),
    (9, 0, 'C5', 2), (9, 2, 'A4', 1),
    (10, 0, 'Bb4', 1), (10, 1, 'A4', 1), (10, 2, 'C5', 1),
    (11, 0, 'G4', 1), (11, 1, 'E4', 1),            # bar 12 beat 3 is a breath
]


def valley_day():
    """Open air in the morning: wind, birds, and the theme played straight —
    piano waltz, strings, flute on top."""
    wind = periodic_noise('day:wind', 180, 5200, slope=-1.1) * breathe(3, 0.45)
    wind += periodic_noise('day:gust', 90, 1400, slope=-1.4) \
        * breathe(5, 0.6, 0.8) * 0.5
    bed = wind * 0.42 + birdsong('day:birds', 14, 1900, 3400, 0.10)

    music = np.zeros(N)
    pad(music, DAY_CHORDS, 0.28)
    waltz(music, DAY_CHORDS, 0.30)
    perform(music, flute, DAY_MELODY, 0.36, 'day:melody', octave=1)

    return soft_clip(normalise(bed * 0.42 + music, 0.74))


DUSK_CHORDS = ['Dm', 'Dm', 'Bb', 'F', 'Gm', 'C', 'F', 'Dm',
               'Bb', 'F', 'Gm7', 'C']

# The same room, half the notes. Long tones, and a final F held over the C so
# the phrase is still leaning when it comes round to D minor again.
DUSK_MELODY = [
    (0, 0, 'A4', 3),
    (1, 0, 'F4', 2), (1, 2, 'G4', 1),
    (2, 0, 'A4', 3),
    (3, 0, 'C5', 2), (3, 2, 'A4', 1),
    (4, 0, 'Bb4', 3),
    (5, 0, 'G4', 2), (5, 2, 'E4', 1),
    (6, 0, 'F4', 3),
    (8, 0, 'D5', 2), (8, 2, 'C5', 1),               # bar 8 is silence
    (9, 0, 'A4', 3),
    (10, 0, 'Bb4', 1), (10, 1, 'A4', 1), (10, 2, 'G4', 1),
    (11, 0, 'F4', 2),
]


def valley_dusk():
    """The light going: the theme turned to its relative minor, the piano
    reduced to the bass note, crickets starting up underneath."""
    wind = periodic_noise('dusk:wind', 140, 3600, slope=-1.3) * breathe(2, 0.5)
    bed = wind * 0.42 + birdsong('dusk:birds', 5, 1500, 2400, 0.05, warble=0)

    crickets = periodic_noise('dusk:crickets', 3800, 5200, slope=0.0)
    # 24 cycles over the loop is a whole number, so the pulse wraps cleanly.
    crickets *= (0.5 + 0.5 * np.tanh(np.sin(2 * np.pi * 24 * T) * 4)) * 0.05
    bed += crickets

    music = np.zeros(N)
    pad(music, DUSK_CHORDS, 0.26)
    cello(music, DUSK_CHORDS, 0.22, bars_per_chord=2)
    for bar, chord in enumerate(DUSK_CHORDS):
        place(music, keys(freq(CHORDS[chord][0]), BEAT), at(bar, 0), 0.20)
    perform(music, flute, DUSK_MELODY, 0.32, 'dusk:melody', octave=1)

    return soft_clip(normalise(bed * 0.45 + music, 0.66))


SUNSET_CHORDS = ['BbM7', 'BbM7', 'F', 'F', 'Gm7', 'Gm7', 'Csus', 'Csus',
                 'Dm7', 'Dm7', 'Bb', 'C']

# Almost nothing: single notes high up, one every two bars, left to ring.
SUNSET_MELODY = [
    (0, 2, 'F5', 1), (2, 2, 'C5', 1), (4, 2, 'D5', 1), (6, 2, 'G4', 1),
    (8, 2, 'A4', 1), (10, 0, 'F4', 1), (11, 1, 'E4', 1),
]


def valley_sunset():
    """Wide and still: strings two bars at a time, water underneath, and a
    piano that plays one note and then listens."""
    wind = periodic_noise('sunset:wind', 110, 2600, slope=-1.4) * breathe(2, 0.4)
    bed = wind * 0.38 + water('sunset:water') * 0.42

    music = np.zeros(N)
    pad(music, SUNSET_CHORDS, 0.26, bars_per_chord=2)
    cello(music, SUNSET_CHORDS, 0.22, bars_per_chord=2)
    perform(music, keys, SUNSET_MELODY, 0.50, 'sunset:keys', octave=1)

    return soft_clip(normalise(bed * 0.46 + music, 0.64))


NIGHT_CHORDS = ['Dm', 'Dm', 'Bb', 'Bb', 'F', 'F', 'Gm', 'Gm',
                'Dm', 'Dm', 'Csus', 'C']

# A music box someone wound half way. Four short figures and a lot of room.
NIGHT_MELODY = [
    (0, 0, 'D5', 1), (0, 1, 'A4', 1), (0, 2, 'F4', 1),
    (2, 0, 'D5', 1), (2, 1, 'Bb4', 1),
    (4, 0, 'C5', 1), (4, 2, 'A4', 1),
    (6, 0, 'Bb4', 1), (6, 1, 'G4', 1), (6, 2, 'D5', 1),
    (9, 0, 'A4', 1), (9, 2, 'F4', 1),
    (11, 0, 'E4', 1),
]


def room_night():
    """A desk at night: room tone, the hum of a machine, and a music box far
    enough away that it might be in another room."""
    tone = periodic_noise('night:tone', 40, 900, slope=-1.8) * breathe(2, 0.18)
    # A quiet mains-ish hum, locked to the loop so it does not beat at the seam.
    hum = (loop_sine(600) * 0.5 + loop_sine(1200) * 0.18) * 0.012
    bed = tone * 0.5 + hum

    music = np.zeros(N)
    pad(music, NIGHT_CHORDS, 0.20, bars_per_chord=2)
    perform(music, music_box, NIGHT_MELODY, 0.32, 'night:box', octave=1)

    return soft_clip(normalise(bed * 0.5 + music, 0.5))


INTERIOR_CHORDS = ['F', 'Dm', 'Gm7', 'C', 'F', 'Dm', 'Bb', 'C',
                   'Am', 'Dm', 'Gm7', 'C']

# Indoors and busy with something: the melody keeps moving, mostly one note
# per beat, the way you hum while your hands are working.
INTERIOR_MELODY = [
    (0, 0, 'C5', 1), (0, 1, 'A4', 1), (0, 2, 'F4', 1),
    (1, 0, 'D5', 1), (1, 1, 'A4', 2),
    (2, 0, 'Bb4', 1), (2, 1, 'D5', 1), (2, 2, 'G4', 1),
    (3, 0, 'C5', 3),
    (4, 0, 'A4', 1), (4, 1, 'C5', 1), (4, 2, 'F5', 1),
    (5, 0, 'E5', 1), (5, 1, 'D5', 2),
    (6, 0, 'D5', 1), (6, 1, 'Bb4', 1), (6, 2, 'F4', 1),
    (7, 0, 'G4', 2), (7, 2, 'E4', 1),
    (8, 0, 'A4', 1), (8, 1, 'E5', 1), (8, 2, 'C5', 1),
    (9, 0, 'D5', 2), (9, 2, 'A4', 1),
    (10, 0, 'Bb4', 1), (10, 1, 'G4', 1), (10, 2, 'D5', 1),
    (11, 0, 'G4', 1), (11, 1, 'E4', 2),
]


def room_interior():
    """The workshop: warm room tone, the building settling, and the theme on
    marimba — wood, because everything in this room is."""
    tone = periodic_noise('interior:tone', 60, 1500, slope=-1.6) * breathe(3, 0.22)

    creaks = np.zeros(N)
    g = rng('interior:creak')
    for _ in range(4):
        f0 = g.uniform(70, 150)
        place(creaks, chirp(g.uniform(0.3, 0.7), f0, f0 * 0.8),
              int(g.uniform(0, N)), g.uniform(0.02, 0.05))
    bed = tone * 0.52 + creaks

    music = np.zeros(N)
    pad(music, INTERIOR_CHORDS, 0.18)
    waltz(music, INTERIOR_CHORDS, 0.22, voice=marimba, tag='interior:waltz')
    perform(music, marimba, INTERIOR_MELODY, 0.40, 'interior:melody', octave=1)

    return soft_clip(normalise(bed * 0.5 + music, 0.62))


LOOPS = {
    'valley-day': valley_day,
    'valley-dusk': valley_dusk,
    'valley-sunset': valley_sunset,
    'room-night': room_night,
    'room-interior': room_interior,
}

# libsndfile's Vorbis scale: 0 is best quality, 1 is smallest. These loops are
# soft and mostly tonal, which Vorbis encodes well; this keeps each inside the
# budget the asset test enforces without audible artefacts.
COMPRESSION = 0.55


def write_ogg(path: str, samples: np.ndarray):
    """Vorbis: a fraction the size of PCM, and the browser decodes it
    natively. Ambience is opt-in, so these are only fetched if it is enabled."""
    sf.write(path, np.clip(samples, -1.0, 1.0), RATE, format='OGG',
             subtype='VORBIS', compression_level=COMPRESSION)


def seam_ratio(samples: np.ndarray, window: int = 256) -> float:
    """How the wrap compares to the steps on either side of it.

    Comparing the first and last sample outright is misleading: they are one
    step apart, so even a perfect loop shows a difference. Comparing against
    the *whole* loop's typical step is misleading too — the seam can land
    inside a mallet strike, where every step is large and a big one means
    nothing.

    So this measures locally: the wrap against the largest ordinary step in the
    few milliseconds around it. At or below 1.0 the wrap is indistinguishable
    from its own neighbourhood, which is what "no click" actually means.
    """
    neighbourhood = np.concatenate([samples[-window:], samples[:window]])
    steps = np.abs(np.diff(neighbourhood))
    # Drop the wrap itself — it is the thing being measured, not a reference.
    local = np.delete(steps, window - 1)
    wrap = float(abs(samples[0] - samples[-1]))
    return wrap / float(local.max()) if local.max() > 0 else 0.0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'{"loop":<16}{"secs":>6}{"KB":>8}{"peak":>7}{"rms":>7}'
          f'{"seam x step":>13}')
    print('-' * 57)
    total = 0.0
    for name, build in LOOPS.items():
        samples = build()
        path = os.path.join(OUT_DIR, f'{name}.ogg')
        write_ogg(path, samples)
        size = os.path.getsize(path) / 1024
        total += size
        print(f'{name:<16}{SECONDS:>6.1f}{size:>8.0f}'
              f'{np.max(np.abs(samples)):>7.2f}'
              f'{float(np.sqrt(np.mean(samples ** 2))):>7.2f}'
              f'{seam_ratio(samples):>13.2f}')
    print('-' * 57)
    print(f'{"total":<16}{"":>6}{total:>8.0f}')


if __name__ == '__main__':
    main()
