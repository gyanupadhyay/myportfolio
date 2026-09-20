import 'package:flutter/material.dart';

import 'tokens.dart';

/// Type ramps measured against the reference frames.
///
/// `hand` is the Caveat script used for the free-floating accents in almost
/// every frame; `display`/`body` are Nunito; `mono` is JetBrains Mono for the
/// metric values in frame 06.
abstract final class Type {
  static const _hand = 'Caveat';
  static const _sans = 'Nunito';
  static const _mono = 'JetBrainsMono';

  // ------------------------------------------------------------ handwritten

  /// Frame 01 hero: "Good things are built by curious people."
  static const handHero = TextStyle(
    fontFamily: _hand,
    fontSize: 52.0,
    height: 1.18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  /// Frame 03/12 headline: "A journey of building…", "Still curious?"
  static const handTitle = TextStyle(
    fontFamily: _hand,
    fontSize: 63.0,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// Frame 05/06/07/08 section heads: "The Challenge", "What changed?"
  static const handSection = TextStyle(
    fontFamily: _hand,
    fontSize: 53.0,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  /// Frames 06/08/09/10 scene notes: "Small improvements make a big
  /// difference.", "Too much / Too early / Let's fix this"
  static const handNote = TextStyle(
    fontFamily: _hand,
    fontSize: 37.0,
    height: 1.32,
    fontWeight: FontWeight.w400,
  );

  static const handSmall = TextStyle(
    fontFamily: _hand,
    fontSize: 28.0,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------- display

  /// Frame 09: the "700 ms" result figure.
  static const displayXl = TextStyle(
    fontFamily: _sans,
    fontSize: 96.0,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  /// Frame 04: the "FYERS" chapter title.
  static const displayLg = TextStyle(
    fontFamily: _sans,
    fontSize: 73.0,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static const displayMd = TextStyle(
    fontFamily: _sans,
    fontSize: 46.0,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // ------------------------------------------------------------------- body

  /// Frame 01: "I'm Gyan Upadhyay"
  static const titleSm = TextStyle(
    fontFamily: _sans,
    fontSize: 31.0,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );

  static const bodyLg = TextStyle(
    fontFamily: _sans,
    fontSize: 27.0,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 24.0,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  static const bodySm = TextStyle(
    fontFamily: _sans,
    fontSize: 21.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 23.0,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const labelSm = TextStyle(
    fontFamily: _sans,
    fontSize: 20.0,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Frame 04: "Chapter 2" eyebrow.
  static const eyebrow = TextStyle(
    fontFamily: _sans,
    fontSize: 21.0,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
  );

  // ------------------------------------------------------------------- mono

  /// Frame 06: the 320ms / 480ms / 620ms timeline values.
  static const monoValue = TextStyle(
    fontFamily: _mono,
    fontSize: 23.0,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  static const monoTotal = TextStyle(
    fontFamily: _mono,
    fontSize: 27.0,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// Frame 07: the code on the monitor.
  static const monoCode = TextStyle(
    fontFamily: _mono,
    fontSize: 10.0,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
}

/// Applied once at the [MaterialApp] level so any stray widget inherits
/// sensible defaults instead of Roboto.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: T.skyLow,
    colorScheme: ColorScheme.fromSeed(
      seedColor: T.mountainMid,
      surface: T.parchment,
    ),
  );

  // Material buttons default to `adaptiveClickable`: a hand on the web, an
  // arrow on every other platform. This is a website whichever engine happens
  // to be drawing it, so every button points the same way.
  const clickable = WidgetStateProperty<MouseCursor>.fromMap(
    <WidgetStatesConstraint, MouseCursor>{
      WidgetState.disabled: SystemMouseCursors.basic,
      WidgetState.any: SystemMouseCursors.click,
    },
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Nunito', displayColor: T.ink, bodyColor: T.ink),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textButtonTheme:
        const TextButtonThemeData(style: ButtonStyle(mouseCursor: clickable)),
    iconButtonTheme:
        const IconButtonThemeData(style: ButtonStyle(mouseCursor: clickable)),
    filledButtonTheme:
        const FilledButtonThemeData(style: ButtonStyle(mouseCursor: clickable)),
    elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(mouseCursor: clickable)),
    outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(mouseCursor: clickable)),
  );
}
