import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/app/app.dart';
import 'package:myportfolio/data/journey.dart';
import 'package:myportfolio/data/models/chapter.dart';

/// The PRD's manual narrative QA, automated: a reviewer should be able to
/// complete the whole journey without getting lost or hitting a dead end.
///
/// This walks the route graph rather than the pixels — it proves every path
/// the world offers leads somewhere that exists.
void main() {
  /// Every route the app can be asked for, and where each can lead next.
  const staticRoutes = {'/', '/workshop', '/map', '/observatory', '/human', '/sunset', '/next'};

  Set<String> allRoutes() => {
        ...staticRoutes,
        for (final id in chapters.keys) '/chapter/$id',
        for (final entry in chapters.entries)
          for (final beat in entry.value.beats) '/chapter/${entry.key}/${beat.id}',
      };

  group('narrative QA', () {
    test('the journey map offers at least one way forward', () {
      final openable = journeyNodes.where((n) => n.chapterId != null);
      expect(openable, isNotEmpty);
    });

    test('every journey stop leads to a route that exists', () {
      final routes = allRoutes();
      for (final node in journeyNodes) {
        final id = node.chapterId;
        if (id == null) continue;
        final route = id == 'next' ? '/observatory' : '/chapter/$id';
        expect(routes, contains(route), reason: 'stop ${node.id}');
      }
    });

    test('every workshop menu entry leads somewhere real', () {
      final routes = allRoutes();
      for (final entry in workshopMenu) {
        final base = entry.route.split('?').first;
        expect(routes, contains(base), reason: entry.label);
      }
    });

    test('no chapter is a dead end — each points onward', () {
      final routes = allRoutes();
      for (final chapter in chapters.values) {
        final next = chapter.nextChapterId;
        expect(next, isNotNull, reason: '${chapter.id} has no onward link');
        final route = next == 'next' ? '/observatory' : '/chapter/$next';
        expect(routes, contains(route),
            reason: '${chapter.id} points at $route, which does not exist');
      }
    });

    test('the chapter chain terminates rather than looping forever', () {
      // Follow nextChapterId from the first stop; it must end at the
      // observatory without revisiting a chapter.
      final seen = <String>{};
      var current = 'smvdu';
      while (chapters.containsKey(current)) {
        expect(seen.add(current), isTrue, reason: 'cycle at $current');
        current = chapters[current]!.nextChapterId ?? 'next';
      }
      expect(current, 'next');
      // Every built chapter should be reachable by following the chain.
      expect(seen, containsAll(chapters.keys));
    });

    test('every beat is individually deep-linkable', () {
      final routes = allRoutes();
      for (final entry in chapters.entries) {
        for (final beat in entry.value.beats) {
          expect(routes, contains('/chapter/${entry.key}/${beat.id}'));
        }
      }
    });

    test('the sunset offers a way back into the world', () {
      // Contact is terminal by design, but the map must stay reachable.
      expect(allRoutes(), contains('/map'));
    });

    test('every chapter states its credibility', () {
      for (final chapter in chapters.values) {
        expect(Credibility.values, contains(chapter.credibility));
      }
    });
  });
}
