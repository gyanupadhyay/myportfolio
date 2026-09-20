import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/app/app.dart';
import 'package:myportfolio/data/experiments.dart';
import 'package:myportfolio/data/journey.dart';
import 'package:myportfolio/data/models/chapter.dart';

void main() {
  group('chapter content', () {
    test('every chapter has an opening and a transition', () {
      for (final chapter in chapters.values) {
        expect(chapter.beats.first.layout, BeatLayout.opening,
            reason: '${chapter.id} should open with an establishing beat');
        expect(chapter.beats.last.layout, BeatLayout.transition,
            reason: '${chapter.id} should end by pointing onward');
      }
    });

    test('beat ids are unique within a chapter', () {
      for (final chapter in chapters.values) {
        final ids = chapter.beats.map((b) => b.id).toList();
        expect(ids.toSet().length, ids.length, reason: chapter.id);
      }
    });

    test('beat labels line up with beat count', () {
      for (final chapter in chapters.values) {
        expect(chapter.beatLabels.length, chapter.beatCount);
      }
    });

    test('each layout has the payload it renders', () {
      for (final chapter in chapters.values) {
        for (final beat in chapter.beats) {
          final where = '${chapter.id}/${beat.id}';
          switch (beat.layout) {
            case BeatLayout.investigation:
              expect(beat.metrics, isNotEmpty, reason: where);
            case BeatLayout.decision:
              expect(beat.tabs.isNotEmpty || beat.checklist.isNotEmpty, isTrue,
                  reason: where);
            case BeatLayout.architecture:
              expect(beat.flow, isNotEmpty, reason: where);
              expect(beat.techniques, isNotEmpty, reason: where);
            case BeatLayout.outcome:
              expect(beat.checklist, isNotEmpty, reason: where);
            case BeatLayout.problem:
              expect(beat.progressResult, isNotNull, reason: where);
            case BeatLayout.opening:
            case BeatLayout.transition:
              expect(beat.title, isNotEmpty, reason: where);
          }
        }
      }
    });

    test('nextChapterId resolves to a real chapter or the observatory', () {
      for (final chapter in chapters.values) {
        final next = chapter.nextChapterId;
        if (next == null || next == 'next') continue;
        expect(chapters.containsKey(next), isTrue,
            reason: '${chapter.id} points at missing chapter $next');
      }
    });
  });

  group('journey map', () {
    test('every node with a chapterId resolves', () {
      for (final node in journeyNodes) {
        final id = node.chapterId;
        if (id == null || id == 'next') continue;
        expect(chapters.containsKey(id), isTrue, reason: node.id);
      }
    });

    test('nodes sit inside the canvas and run left to right', () {
      var lastX = -1.0;
      for (final node in journeyNodes) {
        expect(node.position.x, inInclusiveRange(0.0, 1.0));
        expect(node.position.y, inInclusiveRange(0.0, 1.0));
        expect(node.position.x, greaterThan(lastX),
            reason: 'journey should progress rightward');
        lastX = node.position.x;
      }
    });
  });

  group('observatory', () {
    test('every experiment has steps and details', () {
      for (final e in experiments) {
        expect(e.steps, isNotEmpty, reason: e.id);
        expect(e.details, isNotEmpty, reason: e.id);
      }
    });

    test('credibility is stated explicitly, never defaulted silently', () {
      // The PRD's honesty rule: production work and personal projects must be
      // distinguishable, so both kinds should actually be present.
      final kinds = experiments.map((e) => e.credibility).toSet();
      expect(kinds, contains(Credibility.professional));
      expect(kinds, contains(Credibility.personalProject));
    });

    test('experiment ids are unique', () {
      final ids = experiments.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('contact links', () {
    test('all four actions are wired', () {
      expect(contactLinks.keys,
          containsAll(['email', 'linkedin', 'github', 'resume']));
    });

    test('links are absolute or a bundled asset', () {
      for (final entry in contactLinks.entries) {
        final v = entry.value;
        final ok = v.startsWith('https://') ||
            v.startsWith('mailto:') ||
            v.startsWith('assets/');
        expect(ok, isTrue, reason: '${entry.key} = $v');
      }
    });
  });
}
