import 'package:flutter/material.dart';

/// Which layout a viewport gets.
///
/// Decided on the real viewport width in logical pixels — never on design
/// space, which is a fiction the stage maintains on top of it.
enum StageForm { phone, tablet, desktop }

extension StageFormX on StageForm {
  bool get isPhone => this == StageForm.phone;
  bool get isTablet => this == StageForm.tablet;
  bool get isDesktop => this == StageForm.desktop;

  /// Phone or tablet: the forms that get the reflowed UI instead of the
  /// absolutely-positioned one the frames were composed in.
  bool get isCompact => this != StageForm.desktop;

  /// Picks the value for this form. [tablet] falls back to [desktop] because
  /// most slots only really differ between "reflowed" and "as composed".
  V pick<V>({required V phone, V? tablet, required V desktop}) => switch (this) {
        StageForm.phone => phone,
        StageForm.tablet => tablet ?? desktop,
        StageForm.desktop => desktop,
      };
}

/// Design tokens sampled from the 12 reference frames in `docs/reference/`.
///
/// Nothing in the app hardcodes a colour; scenes pull from [SceneLighting]
/// (see `lighting.dart`) and components pull from here.
abstract final class T {
  // ---------------------------------------------------------------- palette

  // Day sky / landscape (frames 01, 02, 03, 04, 10)
  static const skyHigh = Color(0xFF5E9FD4);
  static const skyMid = Color(0xFF8FBEDE);
  static const skyLow = Color(0xFFC9E2F0);
  static const mountainFar = Color(0xFF8B9BC4);
  static const mountainMid = Color(0xFF6E7FA8);
  static const mountainNear = Color(0xFF4F6285);
  static const mountainSnow = Color(0xFFF2F5FA);
  static const forestFar = Color(0xFF6A9464);
  static const forestMid = Color(0xFF4E7A52);
  static const forestNear = Color(0xFF35603F);
  static const waterHigh = Color(0xFF6FA8CC);
  static const waterLow = Color(0xFF3E7B9E);

  // Night interior (frames 05, 06, 07, 08)
  static const nightSky = Color(0xFF17253C);
  static const nightDeep = Color(0xFF0C1524);
  static const nightRoom = Color(0xFF1B2436);
  static const nightWarm = Color(0xFF3A3020);
  static const lampGlow = Color(0xFFFFC978);

  // Sunset (frames 09, 12)
  static const sunsetHigh = Color(0xFF6B5E9E);
  static const sunsetMid = Color(0xFFE88B54);
  static const sunsetLow = Color(0xFFF7C77E);
  static const sunDisc = Color(0xFFFFE9B0);

  // Surfaces
  static const parchment = Color(0xFFF6EEDC);
  static const parchmentEdge = Color(0xFFE3D6BB);
  static const glassNight = Color(0xE616243A);
  static const glassDay = Color(0xCC12203A);
  static const glassBorder = Color(0x2EFFFFFF);

  // Ink
  static const ink = Color(0xFF3A2B1F);
  static const inkMuted = Color(0xFF6B5B4C);
  static const onDark = Color(0xFFDDE6F2);
  static const onDarkMuted = Color(0xFFA9B8CC);

  // Accents
  static const ctaPill = Color(0xFF2A2724);
  static const success = Color(0xFF3FBF8F);
  static const successGlow = Color(0xFF6FE3A0);
  static const metricBlue = Color(0xFF5AA9F0);
  static const alert = Color(0xFFFF6B6B);
  static const progressPink = Color(0xFFE879B9);
  static const wood = Color(0xFF8B6239);
  static const woodDark = Color(0xFF5E4024);
  static const woodLight = Color(0xFFA97C4C);

  // ---------------------------------------------------------------- spacing

  // Spacing is expressed in design-space pixels on the 1440x861 canvas, which
  // is ~1.66x the density of a conventional 1440px web layout. The names keep
  // their original ratios so call sites did not have to change.
  static const s2 = 3.0;
  static const s4 = 7.0;
  static const s6 = 10.0;
  static const s8 = 13.0;
  static const s12 = 20.0;
  static const s16 = 27.0;
  static const s20 = 33.0;
  static const s24 = 40.0;
  static const s32 = 53.0;
  static const s40 = 66.0;
  static const s48 = 80.0;
  static const s64 = 106.0;
  static const s80 = 133.0;

  // ----------------------------------------------------------------- radius

  static const rSm = 13.0;
  static const rMd = 23.0;
  static const rLg = 33.0;
  static const rPill = 999.0;

  // --------------------------------------------------------------- duration

  static const dFast = Duration(milliseconds: 180);
  static const dBase = Duration(milliseconds: 320);
  static const dSlow = Duration(milliseconds: 620);
  static const dCamera = Duration(milliseconds: 1100);
  static const dStagger = Duration(milliseconds: 110);

  static const eOut = Curves.easeOutCubic;
  static const eInOut = Curves.easeInOutCubic;
  static const eCamera = Curves.easeInOutCubicEmphasized;

  // ------------------------------------------------------------- breakpoint

  /// The frames were composed at this size — the reference mockups' 1.672
  /// aspect ratio. All scene geometry is expressed here and scaled to the
  /// viewport by [WorldStage].
  static const designWidth = 1440.0;
  static const designHeight = 861.0;

  static const bpPhone = 600.0;
  static const bpTablet = 900.0;
  static const bpDesktop = 1280.0;

  /// The form a viewport of [width] logical pixels gets.
  static StageForm formFor(double width) => width < bpPhone
      ? StageForm.phone
      : width < bpDesktop
          ? StageForm.tablet
          : StageForm.desktop;

  /// The box each form's UI is authored against.
  ///
  /// The stage fits this into the viewport (contain, never crop) and hands the
  /// scene the resulting box, so UI always reaches the real screen edges. The
  /// narrower the reference, the larger everything renders — which is what
  /// keeps 24pt design-space body text legible on a 390px phone.
  static Size uiReference(StageForm form) => switch (form) {
        StageForm.phone => const Size(600, 900),
        StageForm.tablet => const Size(1024, 860),
        StageForm.desktop => const Size(designWidth, designHeight),
      };

  /// Page gutter, in the form's UI design units.
  static double gutter(StageForm form) => switch (form) {
        StageForm.phone => 26,
        StageForm.tablet => 46,
        StageForm.desktop => s40,
      };

  /// The art box is re-proportioned to the viewport so scenes are never
  /// cropped; these clamp how far that may go before the composition suffers.
  static const worldAspectMin = 0.62;
  static const worldAspectMax = 2.40;
}
