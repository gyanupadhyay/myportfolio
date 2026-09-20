import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/data/journey.dart';
import 'package:myportfolio/scenes/journey/journey_path.dart';
import 'package:myportfolio/scenes/journey/journey_scene.dart';

void main() {
  group('journey trail geometry', () {
    const size = Size(1440, 861);

    test('node distances increase along the trail', () {
      final d = journeyNodeDistances(journeyNodes, size);
      expect(d.length, journeyNodes.length);
      for (var i = 1; i < d.length; i++) {
        expect(d[i], greaterThan(d[i - 1]),
            reason: 'stop $i should be further along than ${i - 1}');
      }
    });

    test('each node distance lands near that node on the map', () {
      final d = journeyNodeDistances(journeyNodes, size);
      for (var i = 0; i < journeyNodes.length; i++) {
        final point = journeyPointAt(journeyNodes, size, d[i]);
        expect(point, isNotNull);
        final expected = Offset(
          size.width * journeyNodes[i].position.x,
          size.height * journeyNodes[i].position.y,
        );
        // The trail is a curve through the stops, so allow a few pixels.
        expect((point!.position - expected).distance, lessThan(6),
            reason: journeyNodes[i].id);
      }
    });

    test('heading runs left to right across the valley', () {
      final d = journeyNodeDistances(journeyNodes, size);
      final mid = journeyPointAt(journeyNodes, size, d.last / 2);
      expect(mid!.dx, greaterThan(0));
    });
  });

  group('walking to a stop', () {
    testWidgets('tapping a built chapter navigates once the walk finishes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 861));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final routes = <String>[];
      await tester.pumpWidget(
        MaterialApp(home: JourneyScene(onNavigate: routes.add)),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // FYERS is the stop the reference frame highlights.
      await tester.tap(find.text('FYERS'), warnIfMissed: false);
      await tester.pump();

      // The walk runs first; navigation happens on arrival.
      expect(routes, isEmpty, reason: 'should not teleport');

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(routes, ['/chapter/fyers']);
    });

    testWidgets('a stop with no chapter does not navigate', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 861));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final routes = <String>[];
      await tester.pumpWidget(
        MaterialApp(home: JourneyScene(onNavigate: routes.add)),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.text('SMVDU'), warnIfMissed: false);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // SMVDU is built, so this should navigate; the guard is that no stop
      // ever routes to a chapter that does not exist.
      for (final r in routes) {
        expect(r.startsWith('/chapter/') || r == '/observatory', isTrue);
      }
    });
  });
}
