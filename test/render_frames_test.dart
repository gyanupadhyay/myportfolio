@Tags(['render'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myportfolio/app/theme/day_night.dart';
import 'package:myportfolio/scenes/arrival/arrival_scene.dart';
import 'package:myportfolio/data/chapters/bosswallah.dart';
import 'package:myportfolio/data/chapters/fyers.dart';
import 'package:myportfolio/data/chapters/partyhunt.dart';
import 'package:myportfolio/data/chapters/smvdu.dart';
import 'package:myportfolio/scenes/chapter/chapter_scene.dart';
import 'package:myportfolio/scenes/observatory/observatory_scene.dart';
import 'package:myportfolio/scenes/human/human_scene.dart';
import 'package:myportfolio/scenes/journey/journey_scene.dart';
import 'package:myportfolio/scenes/sunset/sunset_scene.dart';
import 'package:myportfolio/scenes/workshop/workshop_scene.dart';

/// Renders each frame to `build/frames/*.png` so the result can be compared
/// side by side with `docs/reference/*.png`.
///
/// Run with: flutter test test/render_frames_test.dart --update-goldens
Future<void> _loadFonts() async {
  // Material icons are not bundled into the test binary; load them from the
  // SDK cache so icon glyphs render instead of tofu boxes.
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
  setUpAll(() async {
    await _loadFonts();
  });

  /// Pumps [scene] at design size and writes it to `build/frames/<name>.png`.
  Future<void> renderFrame(
    WidgetTester tester,
    String name,
    Widget scene,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 861));
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: const Key('frame'), child: scene),
      ),
    );
    // Step the clock rather than jumping it: a single large pump only starts
    // the tickers, leaving entrance animations part-way through.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await expectLater(
      find.byKey(const Key('frame')),
      matchesGoldenFile('../build/frames/$name.png'),
    );
  }

  /// The same scene with the day/night toggle flipped, so the night valley can
  /// be eyeballed next to the composed frames rather than trusted.
  Future<void> renderNight(
    WidgetTester tester,
    String name,
    Widget scene,
  ) async {
    final controller = DayNightController(initial: DayNight.night);
    addTearDown(controller.dispose);
    await renderFrame(
      tester,
      name,
      DayNightScope(controller: controller, child: scene),
    );
  }

  testWidgets('frame 01 — landing', (tester) async {
    await renderFrame(tester, 'frame_01_landing',
        ArrivalScene(onNavigate: (_) {}));
  });

  testWidgets('frame 02 — workshop', (tester) async {
    await renderFrame(tester, 'frame_02_workshop',
        WorkshopScene(onNavigate: (_) {}));
  });

  testWidgets('frame 03 — journey map', (tester) async {
    await renderFrame(tester, 'frame_03_journey',
        JourneyScene(onNavigate: (_) {}));
  });

  // Frames 04–10 are the seven beats of the FYERS chapter.
  const fyersFrames = [
    'frame_04_fyers_arrival',
    'frame_05_problem',
    'frame_06_investigation',
    'frame_07_solution',
    'frame_08_deepdive',
    'frame_09_result',
    'frame_10_transition',
  ];
  for (var i = 0; i < fyersFrames.length; i++) {
    testWidgets(fyersFrames[i], (tester) async {
      await renderFrame(
        tester,
        fyersFrames[i],
        ChapterScene(
          chapter: fyersChapter,
          onNavigate: (_) {},
          initialBeat: i,
        ),
      );
    });
  }

  testWidgets('frame 11 — personal side', (tester) async {
    await renderFrame(tester, 'frame_11_personal',
        HumanScene(onNavigate: (_) {}));
  });

  testWidgets('frame 12 — final / contact', (tester) async {
    await renderFrame(tester, 'frame_12_contact',
        SunsetScene(onNavigate: (_) {}, onContact: (_) {}));
  });

  testWidgets('frame 13 — observatory', (tester) async {
    await renderFrame(
      tester,
      'frame_13_observatory',
      ObservatoryScene(onNavigate: (_) {}, onOpenLink: (_) {}),
    );
  });

  // The other three chapters run through the same generic renderer, so one
  // beat of each is enough to catch a layout that cannot hold their content.
  testWidgets('chapter — SMVDU opening', (tester) async {
    await renderFrame(tester, 'chapter_smvdu_opening',
        ChapterScene(chapter: smvduChapter, onNavigate: (_) {}));
  });

  testWidgets('chapter — PartyHunt outcome', (tester) async {
    await renderFrame(
      tester,
      'chapter_partyhunt_outcome',
      ChapterScene(
        chapter: partyhuntChapter,
        onNavigate: (_) {},
        initialBeat: partyhuntChapter.beats.indexWhere((b) => b.id == 'result'),
      ),
    );
  });

  testWidgets('chapter — Boss Works AI deep dive', (tester) async {
    await renderFrame(
      tester,
      'chapter_bosswallah_deepdive',
      ChapterScene(
        chapter: bosswallahChapter,
        onNavigate: (_) {},
        initialBeat:
            bosswallahChapter.beats.indexWhere((b) => b.id == 'deepdive'),
      ),
    );
  });

  testWidgets('night — landing', (tester) async {
    await renderNight(tester, 'night_01_landing',
        ArrivalScene(onNavigate: (_) {}));
  });

  testWidgets('night — journey map', (tester) async {
    await renderNight(tester, 'night_03_journey',
        JourneyScene(onNavigate: (_) {}));
  });
}
