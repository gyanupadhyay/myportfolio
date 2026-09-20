import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/app/theme/day_night.dart';
import 'package:myportfolio/app/theme/lighting.dart';
import 'package:myportfolio/components/scene_ui.dart';
import 'package:myportfolio/world/stage.dart';

void main() {
  group('DayNight', () {
    test('daylight leaves every scene as composed', () {
      for (final lighting in SceneLighting.values) {
        expect(DayNight.day.apply(lighting), lighting);
      }
    });

    test('night falls on the open-world daylight scenes', () {
      expect(DayNight.night.apply(SceneLighting.day), SceneLighting.night);
    });

    test('scenes written for their own light keep it', () {
      // Painted stars over a blue sky, or a sunset farewell at noon, would be
      // a bug rather than a theme.
      for (final lighting in [
        SceneLighting.dusk,
        SceneLighting.night,
        SceneLighting.sunset,
        SceneLighting.interior,
      ]) {
        expect(DayNight.night.apply(lighting), lighting);
      }
    });

    test('is reversible — toggling back restores the composed light', () {
      for (final lighting in SceneLighting.values) {
        final there = DayNight.day.other.apply(lighting);
        expect(DayNight.night.other.apply(lighting), lighting,
            reason: '$lighting went to $there and did not come back');
      }
    });
  });

  group('DayNightController', () {
    test('starts in daylight and flips on toggle', () {
      final c = DayNightController();
      expect(c.mode, DayNight.day);
      expect(c.isNight, isFalse);

      c.toggle();
      expect(c.isNight, isTrue);
      c.toggle();
      expect(c.isNight, isFalse);
    });

    test('notifies only on a real change', () {
      final c = DayNightController();
      var notifications = 0;
      c.addListener(() => notifications++);

      c.setMode(DayNight.day);
      expect(notifications, 0);
      c.setMode(DayNight.night);
      expect(notifications, 1);
    });
  });

  group('the toggle in the world', () {
    /// A stage whose palette we can read back, under a real controller.
    Widget host(DayNightController controller, SceneLighting composed) {
      return MaterialApp(
        home: DayNightScope(
          controller: controller,
          child: WorldStage(
            lighting: composed,
            ui: TopNav(
              items: const ['Home'],
              current: 'Home',
              onSelect: (_) {},
            ),
            children: const [],
          ),
        ),
      );
    }

    testWidgets('tapping it turns the valley to night and back',
        (tester) async {
      final controller = DayNightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller, SceneLighting.day));
      await tester.pump(const Duration(milliseconds: 100));

      SceneLighting rendered() =>
          WorldStage.of(tester.element(find.byType(TopNav))).lighting;

      expect(rendered(), SceneLighting.day);

      await tester.tap(find.byTooltip('Switch to night'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.isNight, isTrue);
      expect(rendered(), SceneLighting.night);

      await tester.tap(find.byTooltip('Switch to daylight'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(rendered(), SceneLighting.day);
    });

    testWidgets('the control is enabled even with no callback wired',
        (tester) async {
      final controller = DayNightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller, SceneLighting.day));
      await tester.pump(const Duration(milliseconds: 100));

      final button = tester.widget<IconButton>(
        find.descendant(
          of: find.byTooltip('Switch to night'),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
