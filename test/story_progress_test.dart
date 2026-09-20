import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/story/story_progress.dart';

void main() {
  group('StoryProgress', () {
    test('starts empty', () {
      expect(StoryProgress().visited, isEmpty);
    });

    test('records a first visit and reports repeats', () {
      final progress = StoryProgress();
      expect(progress.visit('fyers'), isTrue);
      expect(progress.visit('fyers'), isFalse);
      expect(progress.count, 1);
      expect(progress.hasVisited('fyers'), isTrue);
      expect(progress.hasVisited('bosswallah'), isFalse);
    });

    test('notifies listeners only on change', () {
      final progress = StoryProgress();
      var notifications = 0;
      progress.addListener(() => notifications++);
      progress
        ..visit('fyers')
        ..visit('fyers')
        ..visit('human');
      expect(notifications, 2);
    });

    test('reset clears progress and notifies once', () {
      final progress = StoryProgress(initial: {'fyers'});
      var notifications = 0;
      progress.addListener(() => notifications++);
      progress
        ..reset()
        ..reset();
      expect(progress.visited, isEmpty);
      expect(notifications, 1);
    });

    test('exposes an unmodifiable view', () {
      final progress = StoryProgress(initial: {'fyers'});
      expect(() => progress.visited.add('x'), throwsUnsupportedError);
    });
  });
}
