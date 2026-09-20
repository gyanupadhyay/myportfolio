import 'package:flutter/widgets.dart';

import 'theme/lighting.dart';

/// Ambient sound, off by default.
///
/// The PRD asks for optional ambience with a visible toggle, and browsers
/// refuse to start audio before a gesture anyway — so silence is both the
/// polite default and the only one that works.
///
/// This owns the *decision* of what should be playing. Actual playback is
/// delegated to an [AmbiencePlayer], so the scenes and the toggle can be built
/// and tested without an audio backend, and without shipping audio files whose
/// licensing has not been settled.
class Ambience extends ChangeNotifier {
  Ambience({AmbiencePlayer? player}) : _player = player ?? const SilentPlayer();

  final AmbiencePlayer _player;

  bool _enabled = false;
  SceneLighting? _scene;

  bool get enabled => _enabled;

  /// The loop that should be audible right now, or null when muted.
  String? get track => _enabled && _scene != null ? trackFor(_scene!) : null;

  /// Which loop belongs to a lighting state. Interiors get room tone, the
  /// night desk gets something quieter than the open valley.
  static String trackFor(SceneLighting lighting) => switch (lighting) {
        SceneLighting.day => 'valley-day',
        SceneLighting.dusk => 'valley-dusk',
        SceneLighting.night => 'room-night',
        SceneLighting.sunset => 'valley-sunset',
        SceneLighting.interior => 'room-interior',
      };

  void toggle() => setEnabled(!_enabled);

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _sync();
    notifyListeners();
  }

  /// Called by a scene as it becomes visible.
  void enterScene(SceneLighting lighting) {
    if (_scene == lighting) return;
    _scene = lighting;
    _sync();
    notifyListeners();
  }

  void _sync() {
    final next = track;
    if (next == null) {
      _player.stop();
    } else {
      _player.play(next);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Plays a named ambience loop. Implement this against an audio package when
/// the loops exist; until then [SilentPlayer] keeps the rest honest.
abstract interface class AmbiencePlayer {
  void play(String track);
  void stop();

  /// Releases whatever the implementation is holding. The controller is owned
  /// by the app shell, so without this the audio backend outlives it.
  void dispose();
}

/// Does nothing, and says so. The toggle still works, the state is still
/// correct, and nothing pretends to be playing.
class SilentPlayer implements AmbiencePlayer {
  const SilentPlayer();

  @override
  void play(String track) {
    assert(() {
      debugPrint('[ambience] would play "$track" (no audio assets bundled)');
      return true;
    }());
  }

  @override
  void stop() {}

  @override
  void dispose() {}
}

/// Records what was asked of it — used by the tests.
class RecordingPlayer implements AmbiencePlayer {
  final List<String> played = [];
  int stops = 0;
  bool disposed = false;

  @override
  void play(String track) => played.add(track);

  @override
  void stop() => stops++;

  @override
  void dispose() => disposed = true;
}

/// Makes the ambience controller available to scenes and to the nav toggle.
class AmbienceScope extends InheritedNotifier<Ambience> {
  const AmbienceScope({
    super.key,
    required Ambience ambience,
    required super.child,
  }) : super(notifier: ambience);

  static Ambience? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmbienceScope>()?.notifier;
}
