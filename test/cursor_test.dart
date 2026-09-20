import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myportfolio/app/theme/day_night.dart';
import 'package:myportfolio/app/theme/lighting.dart';
import 'package:myportfolio/components/controls.dart';
import 'package:myportfolio/components/scene_layout.dart';
import 'package:myportfolio/components/scene_ui.dart';
import 'package:myportfolio/world/stage.dart';

/// Anything a visitor can click has to turn the pointer into a hand.
///
/// Material's own buttons will not do this for you: their default cursor is
/// `WidgetStateMouseCursor.adaptiveClickable`, which is a hand on the web and
/// a plain arrow on every other platform. These assertions read the cursor the
/// mouse tracker actually settles on, so they fail on a control that only
/// looks clickable.
void main() {
  /// Everything clickable in the app is one of these shared controls, so
  /// covering them here covers every scene that composes them.
  Widget host(Widget child) => MaterialApp(
        // The app provides this, so the harness must too — without it the
        // day/night toggle has no handler and renders disabled.
        home: DayNightScope(
          controller: DayNightController(),
          child: WorldStage(
            lighting: SceneLighting.day,
            ui: Center(child: child),
            children: const [],
          ),
        ),
      );

  Future<MouseCursor?> cursorOver(WidgetTester tester, Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(target.first));
    // The stage runs a ticker for parallax, so it never settles; pump a couple
    // of frames instead and let the hover land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
  }

  void clickable(String name, Widget Function() build, Finder Function() at) {
    testWidgets('$name shows the hand cursor', (tester) async {
      await tester.pumpWidget(host(build()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(await cursorOver(tester, at()), SystemMouseCursors.click,
          reason: name);
    });
  }

  clickable(
    'PillButton',
    () => PillButton(label: 'Begin the Journey', onPressed: () {}),
    () => find.byType(PillButton),
  );

  clickable(
    'a segmented tab',
    () => SegmentedTabs(
      tabs: const ['Approach', 'Implementation'],
      index: 0,
      onChanged: (_) {},
    ),
    () => find.text('Implementation'),
  );

  clickable(
    'a contact icon action',
    () => IconActionRow(
      actions: [IconAction(icon: Icons.mail, label: 'Email', onTap: () {})],
    ),
    () => find.text('Email'),
  );

  clickable(
    'a world hotspot',
    () => Hotspot(
      label: 'The laptop',
      onActivate: () {},
      builder: (context, active) => const SizedBox(width: 60, height: 60),
    ),
    () => find.byType(Hotspot),
  );

  clickable(
    'a compact destination',
    () => CompactDestination(label: 'Projects', onTap: () {}),
    () => find.text('Projects'),
  );

  clickable(
    'a nav item',
    () => TopNav(items: const ['Map'], current: 'Home', onSelect: (_) {}),
    () => find.text('Map'),
  );

  clickable(
    'the day/night toggle',
    () => TopNav(items: const ['Map'], current: 'Home', onSelect: (_) {}),
    () => find.byTooltip('Switch to night'),
  );

  clickable(
    'a beat indicator dot',
    () => BeatIndicator(count: 3, index: 0, onSelect: (_) {}),
    () => find.byTooltip('Beat 2'),
  );
}
