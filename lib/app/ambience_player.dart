import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'ambience.dart';

/// Plays the generated ambience loops.
///
/// The loops live in `assets/audio` and are produced by
/// `tool/generate_ambience.py` — synthesised rather than sampled, so they can
/// ship with the site without a licence question. Each is seamless, so it is
/// simply set to loop rather than cross-faded.
///
/// Nothing is fetched until ambience is switched on: the asset is only
/// requested on the first [play].
class LoopingAmbiencePlayer implements AmbiencePlayer {
  LoopingAmbiencePlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _player
      ..setReleaseMode(ReleaseMode.loop)
      // Ambience sits under the world, never on top of it.
      ..setVolume(_volume);
  }

  static const _volume = 0.35;

  /// Long enough that a scene change does not cut abruptly, short enough that
  /// it keeps up with the camera.
  static const _fade = Duration(milliseconds: 700);

  final AudioPlayer _player;

  String? _current;

  @override
  Future<void> play(String track) async {
    if (_current == track) return;
    _current = track;
    try {
      await _player.stop();
      await _player.setVolume(0);
      await _player.play(AssetSource('audio/$track.ogg'));
      await _rampTo(_volume);
    } catch (error, stack) {
      // A blocked autoplay policy or a missing decoder should never take the
      // world down with it — the visitor just gets silence.
      _current = null;
      assert(() {
        debugPrint('[ambience] could not play "$track": $error\n$stack');
        return true;
      }());
    }
  }

  @override
  Future<void> stop() async {
    _current = null;
    try {
      await _rampTo(0);
      await _player.stop();
    } catch (_) {
      // Already stopped, or the context is gone.
    }
  }

  /// Steps the volume rather than jumping it, so switching scenes or muting
  /// does not click.
  Future<void> _rampTo(double target) async {
    const steps = 12;
    final start = _player.volume;
    for (var i = 1; i <= steps; i++) {
      await _player.setVolume(start + (target - start) * i / steps);
      await Future<void>.delayed(_fade ~/ steps);
    }
  }

  Future<void> dispose() => _player.dispose();
}
