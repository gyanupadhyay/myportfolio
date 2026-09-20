import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lighting.dart';

/// Which way the visitor has turned the world's key light.
enum DayNight {
  day,
  night;

  DayNight get other => this == day ? night : day;

  /// The lighting a scene composed as [composed] should actually render in.
  ///
  /// Only the open-world daylight scenes follow the toggle. The observatory's
  /// night sky, the sunset farewell and the lamp-lit rooms are written for
  /// their light — painted stars over a blue sky is not a theme, it is a bug —
  /// so they keep what the frame composed.
  SceneLighting apply(SceneLighting composed) =>
      composed == SceneLighting.day && this == DayNight.night
          ? SceneLighting.night
          : composed;

  /// Whether turning the key light changes anything in a scene composed as
  /// [composed].
  ///
  /// Read off [apply] rather than restated, so a scene that starts or stops
  /// following the toggle cannot leave the control describing itself wrongly.
  static bool changes(SceneLighting composed) =>
      day.apply(composed) != night.apply(composed);
}

/// The visitor's day/night choice, shared by every scene.
///
/// This is deliberately a plain [ChangeNotifier] rather than scene state: the
/// choice has to survive a route change, or walking from the valley into a
/// chapter would quietly put the sun back up.
class DayNightController extends ChangeNotifier {
  DayNightController({DayNight initial = DayNight.day}) : _mode = initial;

  static const _storageKey = 'gyan.portfolio.daynight';

  DayNight _mode;

  DayNight get mode => _mode;

  bool get isNight => _mode == DayNight.night;

  void toggle() => setMode(_mode.other);

  void setMode(DayNight value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
    _persist();
  }

  /// Restores the choice from browser storage. Failures are non-fatal — a
  /// visitor with blocked storage simply arrives in daylight.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == null) return;
      final found =
          DayNight.values.where((m) => m.name == stored).firstOrNull;
      if (found != null) setMode(found);
    } catch (_) {
      // Private windows and blocked site data land here; ignore.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _mode.name);
    } catch (_) {
      // See [load].
    }
  }
}

/// Publishes the day/night choice to the whole tree.
///
/// [WorldStage] reads it to resolve the lighting every scene renders in, and
/// the nav toggle reads it to know which way it is pointing. Scenes themselves
/// stay unaware: they declare the light they were composed in and nothing else.
class DayNightScope extends InheritedNotifier<DayNightController> {
  const DayNightScope({
    super.key,
    required DayNightController controller,
    required super.child,
  }) : super(notifier: controller);

  static DayNightController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DayNightScope>()?.notifier;

  /// The mode in force here, or [DayNight.day] where no scope is mounted —
  /// which is what a widget test of a single scene gets.
  static DayNight modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? DayNight.day;

  /// Resolves a scene's composed lighting against the visitor's choice.
  static SceneLighting resolve(BuildContext context, SceneLighting composed) =>
      modeOf(context).apply(composed);

  /// The palette a scene will render in, read from *above* its [WorldStage].
  ///
  /// A scene building its own `WorldStage` sits above the [Lighting] that
  /// stage installs, so `Lighting.paletteOf` would hand it the default rather
  /// than the resolved one. Scenes that colour copy against the painted world
  /// ask here instead.
  static LightingPalette paletteFor(
    BuildContext context,
    SceneLighting composed,
  ) =>
      LightingPalette.of(resolve(context, composed));
}
