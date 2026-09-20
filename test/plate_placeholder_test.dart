// What a plate scene shows before its painting has decoded.
//
// The widget tester never decodes an image, which makes it the right place to
// check this: what it renders *is* the frame a visitor gets while a third of a
// megabyte is still in flight. Before the placeholder that frame was white,
// with the live UI floating on nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportfolio/app/theme/day_night.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/world/plate.dart';
import 'package:myportfolio/world/plates.g.dart';

/// The gradients painted inside the scene's plate.
List<LinearGradient> _gradientsIn(WidgetTester tester) {
  final plate = find.byType(ScenePlate);
  expect(plate, findsOneWidget, reason: 'the scene is not on a plate');
  return find
      .descendant(of: plate, matching: find.byType(DecoratedBox))
      .evaluate()
      .map((e) => (e.widget as DecoratedBox).decoration)
      .whereType<BoxDecoration>()
      .map((d) => d.gradient)
      .whereType<LinearGradient>()
      .toList();
}

Future<void> _pumpLanding(WidgetTester tester, {DayNight? mode}) async {
  const size = Size(1440, 861);
  await tester.binding.setSurfaceSize(size);
  // The view too, not just the surface: `platesOn` reads MediaQuery, which
  // follows the view — left at its default the scene is a tablet and hangs no
  // plate at all.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  Widget scene = ArrivalScene(onNavigate: (_) {});
  if (mode != null) {
    final controller = DayNightController(initial: mode);
    addTearDown(controller.dispose);
    scene = DayNightScope(controller: controller, child: scene);
  }

  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(type: MaterialType.transparency, child: scene),
  ));
  // Long enough for every staggered entrance to fire: a pending timer trips
  // the binding's leak check and hides the result.
  for (var i = 0; i < 32; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a plate scene opens on its own sky and ground', (tester) async {
    await _pumpLanding(tester);

    final gradients = _gradientsIn(tester);
    expect(
      gradients.any((g) =>
          g.colors.first == plateLanding.sky &&
          g.colors.last == plateLanding.ground),
      isTrue,
      reason: 'the plate paints no placeholder, so the scene opens on white',
    );
  });

  testWidgets('the placeholder is dark when night is already chosen',
      (tester) async {
    await _pumpLanding(tester, mode: DayNight.night);

    final gradients = _gradientsIn(tester);
    final sky = gradients
        .map((g) => g.colors.first)
        .where((c) => c != plateLanding.sky)
        .toList();
    expect(sky, isNotEmpty,
        reason: 'the daylit sky is painted in front of a moonlit plate');
    // Sampled from the daylit bake, so it has to be taken down to arrive in
    // the same light as the painting behind it.
    for (final colour in sky) {
      expect(colour.computeLuminance(),
          lessThan(plateLanding.sky.computeLuminance()));
    }
  });

  test('every plate declares a placeholder that is not the default white', () {
    for (final (name, art) in [
      ('landing', plateLanding),
      ('workshop', plateWorkshop),
      ('journey', plateJourney),
      ('sunset', plateSunset),
      ('human', plateHuman),
    ]) {
      for (final (band, colour) in [('sky', art.sky), ('ground', art.ground)]) {
        expect(colour.a, 1.0, reason: '$name $band is translucent');
        expect(colour.computeLuminance(), lessThan(0.9),
            reason: '$name $band is white, which is what this replaces');
      }
    }
  });
}
