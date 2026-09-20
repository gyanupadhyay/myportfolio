// What a wheel turn does.
//
// A chapter binds the wheel to its beats, and a beat whose copy is taller
// than the viewport also has a scrollable band under the pointer. Both used
// to fire on the same turn: the copy scrolled *and* the beat changed, so the
// end of a long panel could not be read with a mouse — there is no scrollbar,
// and the arrow keys move between beats too. The band gets first claim now,
// and only a turn it cannot use reaches the beats.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportfolio/data/chapters/bosswallah.dart';
import 'package:myportfolio/data/chapters/fyers.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/scenes/chapter/chapter_scene.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.path;
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')
          ..addFont(icons.readAsBytes().then(
                (b) => ByteData.view(Uint8List.fromList(b).buffer),
              )))
        .load();
  }
  for (final family in ['Caveat', 'Nunito', 'JetBrainsMono']) {
    final dir = Directory('assets/fonts');
    if (!dir.existsSync()) continue;
    final loader = FontLoader(family);
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.contains(family)) continue;
      loader.addFont(file.readAsBytes().then(
            (b) => ByteData.view(Uint8List.fromList(b).buffer),
          ));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  Future<void> pumpAt(WidgetTester tester, Size size, Widget scene) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(type: MaterialType.transparency, child: scene),
      ),
    );
    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// One notch of a real mouse wheel over [where].
  Future<void> wheel(WidgetTester tester, Offset where, double dy) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(where));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Which beat is on screen, read off the scene rather than off its copy —
  /// a beat backed by a painted plate has no live text to look for.
  String beatOf(WidgetTester tester) =>
      tester.widget<BeatScene>(find.byType(BeatScene)).beat.id;

  ScrollPosition bandOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('a turn the copy band can use scrolls it and keeps the beat',
      (tester) async {
    await pumpAt(
      tester,
      const Size(1440, 861),
      ChapterScene(
        chapter: bosswallahChapter,
        onNavigate: (_) {},
        initialBeat: 3,
      ),
    );

    final band = bandOf(tester);
    expect(
      band.maxScrollExtent,
      greaterThan(0),
      reason: 'this beat no longer overflows its band — pick one that does, '
          'or there is nothing here to arbitrate',
    );
    expect(band.pixels, 0);

    // Over the copy, where the band is.
    await wheel(tester, const Offset(288, 430), 200);

    expect(beatOf(tester), 'solution',
        reason: 'the wheel left the beat instead of scrolling the copy under '
            'the pointer');
    expect(bandOf(tester).pixels, greaterThan(0),
        reason: 'the copy band did not scroll');
  });

  testWidgets('once the copy is read out, the next turn moves on',
      (tester) async {
    await pumpAt(
      tester,
      const Size(1440, 861),
      ChapterScene(
        chapter: bosswallahChapter,
        onNavigate: (_) {},
        initialBeat: 3,
      ),
    );

    // The band catches the wheel across the whole scene, not only over the
    // column it fills, so the first turn is always its. The second one finds
    // it at the end of its copy and carries the story on instead.
    await wheel(tester, const Offset(288, 430), 200);
    expect(beatOf(tester), 'solution');
    expect(bandOf(tester).pixels, bandOf(tester).maxScrollExtent);

    await wheel(tester, const Offset(288, 430), 200);
    expect(beatOf(tester), 'deepdive');
  });

  testWidgets('the landing answers the scroll it invites', (tester) async {
    var went = '';
    await pumpAt(
      tester,
      const Size(1440, 861),
      ArrivalScene(onNavigate: (route) => went = route),
    );

    await wheel(tester, const Offset(720, 500), 200);
    expect(went, '/workshop',
        reason: '"Scroll to explore" has to explore something');
  });

  testWidgets('a nudge upward on the landing goes nowhere', (tester) async {
    var went = '';
    await pumpAt(
      tester,
      const Size(1440, 861),
      ArrivalScene(onNavigate: (route) => went = route),
    );

    await wheel(tester, const Offset(720, 500), -200);
    expect(went, '');
  });

  testWidgets('a beat with nothing to scroll still advances', (tester) async {
    await pumpAt(
      tester,
      const Size(1440, 861),
      ChapterScene(chapter: fyersChapter, onNavigate: (_) {}, initialBeat: 0),
    );

    expect(bandOf(tester).maxScrollExtent, 0);
    await wheel(tester, const Offset(288, 430), 200);
    expect(beatOf(tester), 'problem');
  });
}
