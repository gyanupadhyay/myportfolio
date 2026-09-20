// The night side of the painted plates.
//
// `render_frames_test.dart` skips itself when plates are on — the widget
// tester does not decode images — so nothing there covers what the day/night
// toggle does to a painting or to the copy laid over it. These are the two
// contracts that matter, and both are checkable without decoding anything.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportfolio/app/theme/day_night.dart';
import 'package:myportfolio/app/theme/lighting.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/world/plate.dart';

/// WCAG relative-contrast between two opaque colours.
double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  final (hi, lo) = x > y ? (x, y) : (y, x);
  return (hi + 0.05) / (lo + 0.05);
}

/// One channel of [plateGrade] applied to an 8-bit colour.
double _channel(List<double> m, int row, Color c) =>
    (m[row * 5] * c.r + m[row * 5 + 1] * c.g + m[row * 5 + 2] * c.b) * 255 +
    m[row * 5 + 4];

Color _graded(List<double> m, Color c) => Color.fromARGB(
      255,
      _channel(m, 0, c).clamp(0, 255).round(),
      _channel(m, 1, c).clamp(0, 255).round(),
      _channel(m, 2, c).clamp(0, 255).round(),
    );

void main() {
  group('copy over a plate scrim', () {
    // The landing sets its headline in `onWorld` over a `PlateScrim`, and both
    // follow the light in force. Pinning the veil to one colour while the ink
    // moved put near-white text on near-white cream at night; this is the
    // guard against that pairing coming apart again.
    for (final lighting in SceneLighting.values) {
      test('${lighting.name} keeps its ink legible on its own scrim', () {
        final p = LightingPalette.of(lighting);
        expect(
          _contrast(p.onWorld, p.worldScrim),
          greaterThanOrEqualTo(4.5),
          reason: '${lighting.name}: body ink on the scrim it sits on',
        );
        expect(
          _contrast(p.onWorldMuted, p.worldScrim),
          greaterThanOrEqualTo(4.5),
          reason: '${lighting.name}: muted ink on the scrim it sits on',
        );
      });
    }
  });

  group('moonlight grade', () {
    // Sampled off the daylight plates: sky, cloud, sunlit paint, foliage.
    const samples = <String, Color>{
      'sky': Color(0xFF87B4E1),
      'cloud': Color(0xFFFFFFFF),
      'sun glow': Color(0xFFFFF4D6),
      'grass': Color(0xFF789650),
      'paper': Color(0xFFF5EBD2),
      'shadow': Color(0xFF1F2E3D),
    };

    test('takes light out of every colour it touches', () {
      final m = plateGrade(1);
      samples.forEach((name, c) {
        expect(
          _graded(m, c).computeLuminance(),
          lessThan(c.computeLuminance()),
          reason: '$name should be darker at night, not merely bluer',
        );
      });
    });

    // Dimmer alone is too weak a claim to be worth asserting — the matrix this
    // replaced also lowered luminance. What it did not do was turn the lights
    // down far enough: white paint came out at 0.305, brighter than a sunlit
    // midtone, so the brightest things in the picture still read as daylight.
    test('turns the brightest paint down to moonlight', () {
      final m = plateGrade(1);
      samples.forEach((name, c) {
        expect(
          _graded(m, c).computeLuminance(),
          lessThanOrEqualTo(0.18),
          reason: '$name is still lit like day',
        );
      });
    });

    // The other half of that failure: cutting red and green while leaving blue
    // at 0.72 dyed the picture instead of darkening it — sky came out with
    // blue at 3.2x red, which is a cyanotype, not night.
    test('cools the picture without dyeing it', () {
      final m = plateGrade(1);
      samples.forEach((name, c) {
        final n = _graded(m, c);
        final channels = [n.r, n.g, n.b];
        expect(
          channels.reduce((a, b) => a > b ? a : b),
          lessThanOrEqualTo(channels.reduce((a, b) => a < b ? a : b) * 3),
          reason: '$name is dyed rather than graded',
        );
        expect(n.b, greaterThanOrEqualTo(n.r), reason: '$name should be cool');
      });
    });

    test('t == 0 is the daylight no-op', () {
      final m = plateGrade(0);
      for (final c in samples.values) {
        expect(_graded(m, c), equals(c));
      }
    });
  });

  group('the landing at night', () {
    // Plates are desktop-only, so the scene has to be pumped wide enough to
    // get one at all.
    Future<void> pumpLanding(WidgetTester tester, DayNight mode) async {
      const size = Size(1440, 861);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final dayNight = DayNightController(initial: mode);
      addTearDown(dayNight.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DayNightScope(
            controller: dayNight,
            child: ArrivalScene(onNavigate: (_) {}),
          ),
        ),
      );
      // Past every staggered Reveal and the full dusk crossfade.
      for (var i = 0; i < 32; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Set<String> platesShown(WidgetTester tester) => tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName)
        .where((a) => a.startsWith('assets/art/'))
        .toSet();

    Color scrimColour(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PlateScrim),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient =
          (box.decoration as BoxDecoration).gradient! as LinearGradient;
      return gradient.colors.first;
    }

    testWidgets('hangs the moonlit bake, not the daylit one',
        skip: !kPaintedPlates, (tester) async {
      await pumpLanding(tester, DayNight.night);
      expect(platesShown(tester), contains('assets/art/landing_night.webp'));
    });

    testWidgets('never fetches the night bake in daylight',
        skip: !kPaintedPlates, (tester) async {
      await pumpLanding(tester, DayNight.day);
      expect(platesShown(tester), contains('assets/art/landing.webp'));
      expect(
        platesShown(tester),
        isNot(contains('assets/art/landing_night.webp')),
        reason: 'a visitor who never asks for night should never pay for it',
      );
    });

    testWidgets('veils the copy in the light actually in force',
        skip: !kPaintedPlates, (tester) async {
      await pumpLanding(tester, DayNight.night);
      final veil = scrimColour(tester);
      expect(
        veil.withValues(alpha: 1),
        equals(LightingPalette.night.worldScrim),
        reason: 'the scrim must follow the ink, or the headline vanishes',
      );
      // The guard that matters, stated the way the visitor meets it.
      expect(
        _contrast(LightingPalette.night.onWorld, veil.withValues(alpha: 1)),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('the toggle', () {
    // What the nav control promises depends on this: five of the twelve
    // routes are written for their own hour and keep it either way, and the
    // control says so rather than appearing to do nothing.
    test('acts only on the scenes written for daylight', () {
      expect(DayNight.changes(SceneLighting.day), isTrue);
      for (final composed in SceneLighting.values) {
        if (composed == SceneLighting.day) continue;
        expect(
          DayNight.changes(composed),
          isFalse,
          reason: '${composed.name} is written for its own hour',
        );
      }
    });
  });
}
