import 'package:flutter/material.dart';

import 'tokens.dart';

/// The lighting arc across the 12 frames:
/// 01–04 day → 05–08 night → 09 sunset → 10 day → 11 interior → 12 sunset.
///
/// Every scene declares one of these and panels, text and glow derive from it
/// rather than being hand-tuned per frame.
enum SceneLighting { day, dusk, night, sunset, interior }

/// Resolved colours for a given [SceneLighting].
@immutable
class LightingPalette {
  const LightingPalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.haze,
    required this.panel,
    required this.panelBorder,
    required this.onPanel,
    required this.onPanelMuted,
    required this.onWorld,
    required this.onWorldMuted,
    required this.worldTextShadow,
    required this.accent,
    required this.glow,
    required this.sunPosition,
    required this.sunColor,
    required this.ambient,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;

  /// Atmospheric haze mixed into distant geometry.
  final Color haze;

  final Color panel;
  final Color panelBorder;
  final Color onPanel;
  final Color onPanelMuted;

  /// Copy laid straight onto the painted world with no panel behind it — the
  /// landing headline, the map's handwritten note. Daylight scenes take ink on
  /// a bright valley; every darker light needs the opposite, or the sentence
  /// disappears into the hillside.
  final Color onWorld;
  final Color onWorldMuted;

  /// The wash behind [onWorld] that lifts it off busy art: a light halo under
  /// dark ink, a dark one under light.
  final Color worldTextShadow;

  final Color accent;
  final Color glow;

  /// Normalised position of the key light within the scene (0–1 each axis).
  final Offset sunPosition;
  final Color sunColor;

  /// Overlay tint applied to the whole scene to unify the palette.
  final Color ambient;

  static const day = LightingPalette(
    skyTop: T.skyHigh,
    skyMid: T.skyMid,
    skyBottom: T.skyLow,
    haze: Color(0xFFBFD6E8),
    panel: Color(0xCC0F1B2E),
    panelBorder: T.glassBorder,
    onPanel: Colors.white,
    onPanelMuted: T.onDarkMuted,
    onWorld: Color(0xFF1F2E3D),
    onWorldMuted: Color(0xFF2E3E4E),
    worldTextShadow: Color(0x66FFFFFF),
    accent: T.metricBlue,
    glow: T.successGlow,
    sunPosition: Offset(0.74, 0.16),
    sunColor: Color(0xFFFFF4D6),
    ambient: Color(0x00000000),
  );

  static const dusk = LightingPalette(
    skyTop: Color(0xFF3E4E7E),
    skyMid: Color(0xFF7D6E9C),
    skyBottom: Color(0xFFD99B6E),
    haze: Color(0xFFB08FA0),
    panel: Color(0xD91A1B30),
    panelBorder: T.glassBorder,
    onPanel: Colors.white,
    onPanelMuted: T.onDarkMuted,
    onWorld: Color(0xFFF6F1EA),
    onWorldMuted: Color(0xFFDCD2C6),
    worldTextShadow: Color(0x99000000),
    accent: T.metricBlue,
    glow: T.lampGlow,
    sunPosition: Offset(0.2, 0.62),
    sunColor: Color(0xFFFFCE94),
    ambient: Color(0x14FF9E5E),
  );

  static const night = LightingPalette(
    skyTop: T.nightDeep,
    skyMid: T.nightSky,
    skyBottom: Color(0xFF243550),
    haze: Color(0xFF2B3B57),
    panel: T.glassNight,
    panelBorder: T.glassBorder,
    onPanel: T.onDark,
    onPanelMuted: T.onDarkMuted,
    onWorld: Color(0xFFE9EFF7),
    onWorldMuted: Color(0xFFB7C5D8),
    worldTextShadow: Color(0xAA000000),
    accent: T.metricBlue,
    glow: T.lampGlow,
    sunPosition: Offset(0.62, 0.22),
    sunColor: T.lampGlow,
    ambient: Color(0x1A0A1830),
  );

  static const sunset = LightingPalette(
    skyTop: T.sunsetHigh,
    skyMid: T.sunsetMid,
    skyBottom: T.sunsetLow,
    haze: Color(0xFFE0A788),
    panel: Color(0xCC241C2E),
    panelBorder: Color(0x33FFD9A0),
    onPanel: Colors.white,
    onPanelMuted: Color(0xFFE8D6C4),
    // Near-white on a bright orange sky measured 2.33:1. The reference frame
    // sets this copy in dark ink with a light halo, which also reads better.
    onWorld: Color(0xFF2E2A33),
    onWorldMuted: Color(0xFF453E48),
    worldTextShadow: Color(0x99FFFFFF),
    accent: T.sunDisc,
    glow: T.sunDisc,
    sunPosition: Offset(0.58, 0.44),
    sunColor: T.sunDisc,
    ambient: Color(0x1FFF9A4D),
  );

  static const interior = LightingPalette(
    skyTop: Color(0xFF2A2115),
    skyMid: Color(0xFF3E3020),
    skyBottom: Color(0xFF55412A),
    haze: Color(0xFF6B543A),
    panel: Color(0xE6221A11),
    panelBorder: Color(0x33FFD9A0),
    onPanel: Color(0xFFF3E6D2),
    onPanelMuted: Color(0xFFC3AE92),
    onWorld: Color(0xFFF3E6D2),
    onWorldMuted: Color(0xFFC3AE92),
    worldTextShadow: Color(0xAA000000),
    accent: T.lampGlow,
    glow: T.lampGlow,
    sunPosition: Offset(0.44, 0.3),
    sunColor: Color(0xFFFFE0A8),
    ambient: Color(0x1AFFB25E),
  );

  static LightingPalette of(SceneLighting lighting) => switch (lighting) {
        SceneLighting.day => day,
        SceneLighting.dusk => dusk,
        SceneLighting.night => night,
        SceneLighting.sunset => sunset,
        SceneLighting.interior => interior,
      };
}

/// Makes the active scene's palette available to every descendant so
/// components never need it passed down explicitly.
class Lighting extends InheritedWidget {
  const Lighting({
    super.key,
    required this.lighting,
    required super.child,
  });

  final SceneLighting lighting;

  LightingPalette get palette => LightingPalette.of(lighting);

  static LightingPalette paletteOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<Lighting>();
    return widget?.palette ?? LightingPalette.day;
  }

  static SceneLighting modeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<Lighting>();
    return widget?.lighting ?? SceneLighting.day;
  }

  @override
  bool updateShouldNotify(Lighting oldWidget) =>
      oldWidget.lighting != lighting;
}
