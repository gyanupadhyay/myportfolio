import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'ambience.dart';

/// Plays the generated ambience loops.
///
/// The loops live in `assets/audio` and are produced by
/// `tool/generate_ambience.py` — synthesised rather than sampled, so they can
/// ship with the site without a licence question. Each one is seamless, so it
/// is simply set to loop rather than cross-faded with itself.
///
/// Between *scenes* the fade does matter. The loops carry a melody, and
/// cutting one tune off mid-phrase to start another is the single thing that
/// makes background music sound like a website. So this holds two decks and
/// cross-fades between them: the outgoing scene's music is still dying away as
/// the next one comes up, the way a film cue overlaps a change of shot.
///
/// Nothing is fetched until ambience is switched on: the asset is only
/// requested on the first [play].
class LoopingAmbiencePlayer implements AmbiencePlayer {
  LoopingAmbiencePlayer({AudioPlayer Function()? createPlayer})
      : _decks = List.generate(2, (_) => (createPlayer ?? AudioPlayer.new)());

  /// Ambience sits under the world, never on top of it. Music carries further
  /// than wind does, so this is lower than a pure texture bed would need.
  static const _volume = 0.3;

  /// Long enough to read as one cue giving way to another rather than a cut,
  /// short enough to keep up with the camera.
  static const _fade = Duration(milliseconds: 1500);
  static const _steps = 30;

  /// Two decks: one carrying the current track, one either idle or still
  /// fading out.
  final List<AudioPlayer> _decks;

  int _live = 0;

  String? _current;

  /// Bumped by every [play] and [stop]. A fade in flight checks this on each
  /// step and abandons the moment a newer one starts, so clicking quickly
  /// through scenes cannot leave two tracks stuck against each other.
  int _generation = 0;

  AudioPlayer get _front => _decks[_live];

  @override
  Future<void> play(String track) async {
    if (_current == track) return;
    _current = track;
    final generation = ++_generation;

    final outgoing = _front;
    _live = 1 - _live;
    final incoming = _front;

    try {
      await incoming.setReleaseMode(ReleaseMode.loop);
      await incoming.setVolume(0);
      await incoming.play(AssetSource('audio/$track.ogg'));
      await _fadeTo(generation, {incoming: _volume, outgoing: 0});
      if (generation == _generation) await outgoing.stop();
    } catch (error, stack) {
      // A blocked autoplay policy or a missing decoder should never take the
      // world down with it — the visitor just gets silence.
      if (generation == _generation) _current = null;
      assert(() {
        debugPrint('[ambience] could not play "$track": $error\n$stack');
        return true;
      }());
    }
  }

  @override
  Future<void> stop() async {
    _current = null;
    final generation = ++_generation;
    try {
      // Both decks, because one of them may still be fading out from a scene
      // change the visitor muted halfway through.
      await _fadeTo(generation, {for (final deck in _decks) deck: 0});
      if (generation != _generation) return;
      await Future.wait([for (final deck in _decks) deck.stop()]);
    } catch (_) {
      // Already stopped, or the audio context is gone.
    }
  }

  @override
  Future<void> dispose() async {
    _current = null;
    _generation++;
    await Future.wait([for (final deck in _decks) deck.dispose()]);
  }

  /// Walks each deck from where it is now to its target, in step.
  ///
  /// The curve is equal-power rather than linear: the two loops are unrelated
  /// pieces of music, so their levels have to add up in energy, not in
  /// amplitude. Fading both linearly would leave an audible dip in the middle
  /// of every scene change.
  Future<void> _fadeTo(int generation, Map<AudioPlayer, double> targets) async {
    final start = {for (final deck in targets.keys) deck: deck.volume};
    for (var step = 1; step <= _steps; step++) {
      if (generation != _generation) return;
      final progress = step / _steps;
      await Future.wait([
        for (final target in targets.entries)
          if (start[target.key] != target.value)
            target.key.setVolume(_ease(
              start[target.key]!,
              target.value,
              progress,
            )),
      ]);
      await Future<void>.delayed(_fade ~/ _steps);
    }
  }

  /// Equal-power interpolation: a rise follows a sine, a fall follows a
  /// cosine, so a pair of them holds a constant total loudness throughout.
  static double _ease(double from, double to, double progress) {
    final shaped = to > from
        ? math.sin(progress * math.pi / 2)
        : 1 - math.cos(progress * math.pi / 2);
    return from + (to - from) * shaped;
  }
}
