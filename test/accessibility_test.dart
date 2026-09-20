import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/app/theme/lighting.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/scenes/journey/journey_scene.dart';

/// Relative luminance, per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) {
    final s = v;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Flattens a translucent panel over the sky it sits on, so the ratio is the
/// one a visitor actually sees rather than the one the token claims.
Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void main() {
  // The palette's world-copy contrast is measured *with* the halo behind the
  // ink — 5.8:1 and up. Without it the same pair falls to 3.9:1 on a day sky,
  // and the landing's bio shipped exactly that way: a scene can opt out of
  // the halo and the palette test will never notice.
  group('world copy carries its halo', () {
    Future<void> check(WidgetTester tester, Widget scene, String name) async {
      await tester.binding.setSurfaceSize(const Size(1440, 861));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Material(type: MaterialType.transparency, child: scene),
      ));
      await tester.pump(const Duration(seconds: 2));

      final palette = LightingPalette.of(SceneLighting.day);
      final onWorld = {palette.onWorld, palette.onWorldMuted};
      var checked = 0;
      for (final element in find.byType(Text).evaluate()) {
        final text = element.widget as Text;
        final colour = text.style?.color;
        if (colour == null || !onWorld.contains(colour)) continue;
        checked++;
        expect(text.style?.shadows, isNotEmpty,
            reason: '$name: "${text.data}" sits on the art with no halo');
      }
      expect(checked, greaterThan(0), reason: '$name: found no world copy');
    }

    testWidgets('the landing', (tester) async {
      await check(tester, ArrivalScene(onNavigate: (_) {}), 'landing');
    });

    testWidgets('the map', (tester) async {
      await check(tester, JourneyScene(onNavigate: (_) {}), 'map');
    });
  });

  group('contrast', () {
    test('body text on every panel clears WCAG AA (4.5:1)', () {
      for (final lighting in SceneLighting.values) {
        final p = LightingPalette.of(lighting);
        // A panel is translucent; composite it over the scene's mid sky.
        final panel = _over(p.panel, p.skyMid);
        final ratio = contrast(p.onPanel, panel);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '$lighting: onPanel on panel is '
                '${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('muted panel text clears WCAG AA large (3:1)', () {
      for (final lighting in SceneLighting.values) {
        final p = LightingPalette.of(lighting);
        final panel = _over(p.panel, p.skyMid);
        final ratio = contrast(p.onPanelMuted, panel);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '$lighting: onPanelMuted is '
                '${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('world copy stays legible on both sides of the day/night toggle', () {
      // The landing headline and the map's note have no panel under them,
      // only sky and hillside — which is exactly how a day/night toggle
      // breaks a scene: the ink stays dark and the valley behind it goes
      // navy. Only the two states the toggle can produce are checked; the
      // dusk and sunset frames compose their copy against a specific band of
      // their own gradient rather than the whole of it.
      for (final lighting in [SceneLighting.day, SceneLighting.night]) {
        final p = LightingPalette.of(lighting);
        for (final (name, colour) in [
          ('onWorld', p.onWorld),
          ('onWorldMuted', p.onWorldMuted),
        ]) {
          for (final (where, sky) in [
            ('skyTop', p.skyTop),
            ('skyMid', p.skyMid),
            ('skyBottom', p.skyBottom),
          ]) {
            // Copy on the world is never on bare sky: worldTextShadow is a
            // halo painted behind it. Compositing that is the same treatment
            // the translucent panels already get, and it is what a visitor
            // actually sees.
            final ratio = contrast(colour, _over(p.worldTextShadow, sky));
            expect(ratio, greaterThanOrEqualTo(3.0),
                reason: '$lighting: $name on $where is '
                    '${ratio.toStringAsFixed(2)}:1');
          }
        }
      }
    });

    test('accent and glow are distinguishable from their panel', () {
      for (final lighting in SceneLighting.values) {
        final p = LightingPalette.of(lighting);
        final panel = _over(p.panel, p.skyMid);
        expect(contrast(p.accent, panel), greaterThanOrEqualTo(3.0),
            reason: '$lighting accent');
      }
    });
  });

  group('lighting palettes', () {
    test('every state defines a distinct sky', () {
      final skies = <int>{};
      for (final lighting in SceneLighting.values) {
        final p = LightingPalette.of(lighting);
        skies.add(Object.hash(p.skyTop, p.skyMid, p.skyBottom));
      }
      expect(skies.length, SceneLighting.values.length);
    });

    test('sun position stays inside the frame', () {
      for (final lighting in SceneLighting.values) {
        final p = LightingPalette.of(lighting);
        expect(p.sunPosition.dx, inInclusiveRange(0.0, 1.0));
        expect(p.sunPosition.dy, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
