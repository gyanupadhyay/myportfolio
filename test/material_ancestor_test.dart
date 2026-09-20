@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/data/chapters/bosswallah.dart';
import 'package:myportfolio/data/chapters/fyers.dart';
import 'package:myportfolio/data/chapters/partyhunt.dart';
import 'package:myportfolio/data/chapters/smvdu.dart';
import 'package:myportfolio/data/models/chapter.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/scenes/chapter/chapter_scene.dart';
import 'package:myportfolio/scenes/human/human_scene.dart';
import 'package:myportfolio/scenes/journey/journey_scene.dart';
import 'package:myportfolio/scenes/observatory/observatory_scene.dart';
import 'package:myportfolio/scenes/sunset/sunset_scene.dart';
import 'package:myportfolio/scenes/workshop/workshop_scene.dart';

/// Text without a Material ancestor renders with Flutter's yellow debug
/// underline. These scenes are raw widgets rather than Scaffolds, so nothing
/// supplies one automatically — this catches it before it reaches a screen.
List<String> textsWithoutMaterial(WidgetTester tester) {
  final offenders = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    var found = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is Material) {
        found = true;
        return false;
      }
      return true;
    });
    if (!found) {
      final widget = element.widget as Text;
      offenders.add(widget.data ?? widget.textSpan?.toPlainText() ?? '<span>');
    }
  }
  return offenders;
}

void main() {
  Future<void> check(WidgetTester tester, String name, Widget scene) async {
    // setSurfaceSize is physical; without pinning the ratio the default 3.0
    // turns 1440 into a 480-wide phone layout.
    const size = Size(1440, 861);
    await tester.binding.setSurfaceSize(size);
    // physicalSize as well, or MediaQuery reports a different box from the
    // surface and the scene lays out for the wrong form.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(debugShowCheckedModeBanner: false, home: scene),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Overflow at various viewports is responsive_test.dart's job; draining
    // those here keeps this test about one thing.
    while (tester.takeException() != null) {}

    expect(textsWithoutMaterial(tester), isEmpty,
        reason: '$name has Text outside any Material — these render with the '
            'yellow debug underline');
  }

  testWidgets('arrival', (t) => check(t, 'arrival', ArrivalScene(onNavigate: (_) {})));
  testWidgets('workshop', (t) => check(t, 'workshop', WorkshopScene(onNavigate: (_) {})));
  testWidgets('journey map', (t) => check(t, 'journey', JourneyScene(onNavigate: (_) {})));
  testWidgets('human layer', (t) => check(t, 'human', HumanScene(onNavigate: (_) {})));
  testWidgets('sunset', (t) => check(t, 'sunset', SunsetScene(onNavigate: (_) {}, onContact: (_) {})));
  testWidgets('observatory',
      (t) => check(t, 'observatory', ObservatoryScene(onNavigate: (_) {}, onOpenLink: (_) {})));

  const all = <Chapter>[smvduChapter, partyhuntChapter, fyersChapter, bosswallahChapter];
  for (final chapter in all) {
    for (var i = 0; i < chapter.beatCount; i++) {
      testWidgets('${chapter.id} beat ${chapter.beats[i].id}', (t) async {
        await check(t, '${chapter.id}/${chapter.beats[i].id}',
            ChapterScene(chapter: chapter, onNavigate: (_) {}, initialBeat: i));
      });
    }
  }
}
