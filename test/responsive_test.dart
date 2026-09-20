import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportfolio/components/panels.dart';
import 'package:myportfolio/data/chapters/fyers.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/scenes/chapter/chapter_scene.dart';
import 'package:myportfolio/scenes/human/human_scene.dart';
import 'package:myportfolio/scenes/journey/journey_scene.dart';
import 'package:myportfolio/scenes/observatory/observatory_scene.dart';
import 'package:myportfolio/scenes/sunset/sunset_scene.dart';
import 'package:myportfolio/scenes/workshop/workshop_scene.dart';

/// Every scene, at every shape a real visitor arrives in.
///
/// The failure this guards against is the one the app shipped with: a fixed
/// 1440x861 canvas scaled with `BoxFit.cover`, which cropped 72% of the frame
/// on a phone. A scene passes when it neither overflows nor puts its controls
/// outside the viewport.
const _viewports = <String, Size>{
  'phone portrait': Size(390, 844),
  'phone landscape': Size(844, 390),
  'tablet portrait': Size(820, 1180),
  'desktop': Size(1440, 861),
  'ultrawide': Size(2560, 1080),
};

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.path;
  final iconFont = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconFont.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(iconFont.readAsBytes().then(
            (b) => ByteData.view(Uint8List.fromList(b).buffer),
          ));
    await loader.load();
  }
  for (final family in ['Caveat', 'Nunito', 'JetBrainsMono']) {
    final loader = FontLoader(family);
    final dir = Directory('assets/fonts');
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.contains(family.replaceAll(' ', ''))) continue;
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  /// Pumps [scene] at [size] and fails on any layout exception.
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
    // Long enough for every staggered Reveal to fire; a pending entrance timer
    // trips the binding's leak check and masks the layout result.
    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  Widget sceneFor(String name) => switch (name) {
        'arrival' => ArrivalScene(onNavigate: (_) {}),
        'workshop' => WorkshopScene(onNavigate: (_) {}),
        'journey' => JourneyScene(onNavigate: (_) {}),
        'human' => HumanScene(onNavigate: (_) {}),
        'sunset' => SunsetScene(onNavigate: (_) {}, onContact: (_) {}),
        _ => ObservatoryScene(onNavigate: (_) {}, onOpenLink: (_) {}),
      };

  const sceneNames = [
    'arrival',
    'workshop',
    'journey',
    'human',
    'sunset',
    'observatory',
  ];

  for (final entry in _viewports.entries) {
    group(entry.key, () {
      for (final name in sceneNames) {
        testWidgets('$name lays out without overflow', (tester) async {
          await pumpAt(tester, entry.value, sceneFor(name));
        });
      }

      for (var beat = 0; beat < fyersChapter.beatCount; beat++) {
        testWidgets('chapter beat $beat lays out without overflow',
            (tester) async {
          await pumpAt(
            tester,
            entry.value,
            ChapterScene(
              chapter: fyersChapter,
              onNavigate: (_) {},
              initialBeat: beat,
            ),
          );
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // The regression that started this: controls cropped off the side.
  // -------------------------------------------------------------------------

  /// Every pixel of [finder] must fall inside the viewport.
  void expectOnScreen(WidgetTester tester, Finder finder, Size viewport) {
    expect(finder, findsWidgets, reason: 'nothing to check');
    final r = tester.getRect(finder.first);
    expect(r.left, greaterThanOrEqualTo(-0.5), reason: 'clipped at the left');
    expect(r.top, greaterThanOrEqualTo(-0.5), reason: 'clipped at the top');
    expect(r.right, lessThanOrEqualTo(viewport.width + 0.5),
        reason: 'clipped at the right');
    expect(r.bottom, lessThanOrEqualTo(viewport.height + 0.5),
        reason: 'clipped at the bottom');
  }

  for (final entry in _viewports.entries) {
    testWidgets('${entry.key}: the landing CTA is fully on screen',
        (tester) async {
      await pumpAt(tester, entry.value, sceneFor('arrival'));
      expectOnScreen(tester, find.text('Begin the Journey'), entry.value);
    });

    testWidgets('${entry.key}: every contact action is reachable',
        (tester) async {
      await pumpAt(tester, entry.value, sceneFor('sunset'));
      for (final label in ['Email', 'LinkedIn', 'GitHub', 'Resume']) {
        expectOnScreen(tester, find.text(label), entry.value);
      }
    });
  }

  testWidgets('phone: the signpost routes survive as a list', (tester) async {
    const size = Size(390, 844);
    await pumpAt(tester, size, sceneFor('arrival'));
    // The planks hang off the right edge and are dropped on a phone, so the
    // four destinations have to show up somewhere else.
    for (final label in ['Projects', 'Experience', 'Ideas', 'Life']) {
      expect(find.text(label), findsWidgets, reason: '$label is unreachable');
    }
  });

  testWidgets('phone: the journey stops survive as a list', (tester) async {
    const size = Size(390, 844);
    await pumpAt(tester, size, sceneFor('journey'));
    expect(find.text('The stops'), findsOneWidget);
  });

  // The observatory's system card is taller than the frame it was composed
  // for, and its tail used to be unreachable: the card was pinned to 430 units
  // with the diagram scrolling inside it. The copy band scrolls now.
  for (final size in const [Size(1440, 861), Size(1366, 700)]) {
    testWidgets('laptop ${size.height.round()}: the end of the system card can '
        'be scrolled into view', (tester) async {
      await pumpAt(tester, size, sceneFor('observatory'));

      // The last step of the release pipeline, below the fold on arrival.
      final tail = find.text('Over the air');
      expect(tester.getRect(tail).bottom, greaterThan(size.height),
          reason: 'nothing to scroll to — rewrite this test');

      await tester.drag(find.byType(GlassPanel).first, const Offset(0, -400));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expectOnScreen(tester, tail, size);
    });
  }

  testWidgets('phone: the chapter can still be advanced', (tester) async {
    const size = Size(390, 844);
    await pumpAt(
      tester,
      size,
      ChapterScene(chapter: fyersChapter, onNavigate: (_) {}, initialBeat: 0),
    );
    expectOnScreen(tester, find.bySemanticsLabel('Next beat'), size);
  });
}
