import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/motion.dart';
import '../../app/theme/day_night.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/data_views.dart';
import '../../components/panels.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../data/models/chapter.dart';
import '../../world/painters/character.dart';
import '../../world/painters/interior.dart';
import '../../world/painters/landscape.dart';
import '../../world/painters/paint_kit.dart';
import '../../world/stage.dart';

/// Renders any [Chapter] as a sequence of staged beats.
///
/// Every chapter shares these seven layouts, so adding BossWallah, PartyHunt
/// or SMVDU is a data file rather than a new set of scenes. Scroll, click or
/// arrow keys advance; every beat is deep-linkable.
class ChapterScene extends StatefulWidget {
  const ChapterScene({
    super.key,
    required this.chapter,
    required this.onNavigate,
    this.initialBeat = 0,
  });

  final Chapter chapter;
  final void Function(String route) onNavigate;
  final int initialBeat;

  @override
  State<ChapterScene> createState() => _ChapterSceneState();
}

class _ChapterSceneState extends State<ChapterScene> {
  late int _beat = widget.initialBeat.clamp(0, widget.chapter.beatCount - 1);
  final _focus = FocusNode();
  bool _wheelLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didUpdateWidget(ChapterScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.id != widget.chapter.id) {
      _beat = widget.initialBeat.clamp(0, widget.chapter.beatCount - 1);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _go(int next) {
    if (next < 0) {
      widget.onNavigate('/map');
      return;
    }
    if (next >= widget.chapter.beatCount) {
      final onward = widget.chapter.nextChapterId;
      widget.onNavigate(
        onward == null || onward == 'next'
            ? '/observatory'
            : '/chapter/$onward',
      );
      return;
    }
    setState(() => _beat = next);
  }

  /// One wheel gesture advances one beat, then locks briefly so a single
  /// trackpad flick does not skip three scenes.
  void _onWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _wheelLocked) return;
    if (event.scrollDelta.dy.abs() < 6) return;
    _wheelLocked = true;
    _go(_beat + (event.scrollDelta.dy > 0 ? 1 : -1));
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      _wheelLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowRight:
          case LogicalKeyboardKey.arrowDown:
          case LogicalKeyboardKey.pageDown:
            _go(_beat + 1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowLeft:
          case LogicalKeyboardKey.arrowUp:
          case LogicalKeyboardKey.pageUp:
            _go(_beat - 1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.escape:
            widget.onNavigate('/map');
            return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerSignal: _onWheel,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 620),
                ),
                switchInCurve: T.eOut,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: ValueKey('${chapter.id}:$_beat'),
                  child: BeatScene(
                    chapter: chapter,
                    beat: chapter.beats[_beat],
                    onAdvance: () => _go(_beat + 1),
                  ),
                ),
              ),
            ),

            // The chapter chrome lives outside the stage, so it is measured in
            // real pixels and has to be inset by hand: display cutouts, and a
            // tighter gutter where a 66px margin would eat a phone's width.
            _ChapterChrome(
              beat: _beat,
              beatCount: chapter.beatCount,
              beatLabels: chapter.beatLabels,
              title: chapter.title,
              credibility: chapter.credibility,
              onBack: () => widget.onNavigate('/map'),
              onSelect: (i) => setState(() => _beat = i),
              onStep: _go,
            ),
          ],
        ),
      ),
    );
  }
}

/// Back badge, beat dots and the step arrows, laid out against the real
/// viewport rather than design space.
class _ChapterChrome extends StatelessWidget {
  const _ChapterChrome({
    required this.beat,
    required this.beatCount,
    required this.beatLabels,
    required this.title,
    required this.credibility,
    required this.onBack,
    required this.onSelect,
    required this.onStep,
  });

  final int beat;
  final int beatCount;
  final List<String> beatLabels;
  final String title;
  final Credibility credibility;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onStep;

  /// Chrome is painted on top of the world, not inside it, so it carries its
  /// own transparent [Material]. Without one every `Text` here renders with
  /// Flutter's yellow debug underline.
  Widget _material(Widget child) =>
      Material(type: MaterialType.transparency, child: child);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final form = T.formFor(media.size.width);
    final pad = media.padding;
    final inset = form.pick(phone: 14.0, tablet: 26.0, desktop: T.s40);
    final bottom = form.pick(phone: 12.0, tablet: 18.0, desktop: 22.0);

    final arrows = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.arrow_back,
          label: 'Previous beat',
          onTap: () => onStep(beat - 1),
        ),
        const SizedBox(width: T.s8),
        _ArrowButton(
          icon: Icons.arrow_forward,
          label: 'Next beat',
          onTap: () => onStep(beat + 1),
        ),
      ],
    );

    final dots = BeatIndicator(
      count: beatCount,
      index: beat,
      labels: beatLabels,
      onSelect: onSelect,
    );

    final badge = _ChapterBadge(
      title: title,
      credibility: credibility,
      onBack: onBack,
    );

    // On a phone the dots and the arrows cannot both own the bottom edge, so
    // they share one bar instead of overlapping in the middle.
    if (form.isPhone) {
      return Positioned(
        left: inset + pad.left,
        right: inset + pad.right,
        top: inset + pad.top,
        bottom: bottom + pad.bottom,
        child: _material(
          Column(
            children: [
              // The badge's row is ~369 units wide and a narrow phone leaves it
              // 362, so it scales down instead of clipping its own title.
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: badge,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Seven dots plus two arrows run a few pixels wider than a
                  // narrow phone; let the dots shrink rather than overflow.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: dots,
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  arrows,
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: inset + pad.left,
      right: inset + pad.right,
      top: T.s24 + pad.top,
      bottom: bottom + pad.bottom,
      child: _material(
        Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: badge),
            Align(alignment: Alignment.bottomCenter, child: dots),
            Align(alignment: Alignment.bottomRight, child: arrows),
          ],
        ),
      ),
    );
  }
}

/// Stages one beat according to its [BeatLayout].
class BeatScene extends StatelessWidget {
  const BeatScene({
    super.key,
    required this.chapter,
    required this.beat,
    required this.onAdvance,
  });

  final Chapter chapter;
  final StoryBeat beat;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) => switch (beat.layout) {
    BeatLayout.opening => _Opening(
      chapter: chapter,
      beat: beat,
      onEnter: onAdvance,
    ),
    BeatLayout.problem => _Problem(beat: beat),
    BeatLayout.investigation => _Investigation(beat: beat),
    BeatLayout.decision => _Decision(beat: beat),
    BeatLayout.architecture => _Architecture(beat: beat),
    BeatLayout.outcome => _Outcome(beat: beat),
    BeatLayout.transition => _Transition(
      chapter: chapter,
      beat: beat,
      onNext: onAdvance,
    ),
  };
}

// ---------------------------------------------------------------------------
// Opening — the establishing shot (frame 04)
// ---------------------------------------------------------------------------

class _Opening extends StatelessWidget {
  const _Opening({
    required this.chapter,
    required this.beat,
    required this.onEnter,
  });

  final Chapter chapter;
  final StoryBeat beat;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final glass = Color(chapter.accentColor ?? 0xFF6E93B8);

    return WorldStage(
      lighting: SceneLighting.day,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 75,
            top: 150,
            width: 620,
            child: RevealGroup(
              start: const Duration(milliseconds: 180),
              children: [
                if (beat.eyebrow != null)
                  Text(
                    beat.eyebrow!,
                    style: Type.eyebrow.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: const [
                        Shadow(color: Color(0x99000000), blurRadius: 8),
                      ],
                    ),
                  ),
                const SizedBox(height: T.s8),
                Text(
                  chapter.title,
                  style: Type.displayLg.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 14),
                    ],
                  ),
                ),
                const SizedBox(height: T.s6),
                Text(
                  chapter.subtitle,
                  style: Type.bodyLg.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: T.s20),
                if (beat.body != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      beat.body!,
                      style: Type.bodyLg.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: const [
                          Shadow(color: Color(0xAA000000), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: T.s24),
                PillButton(label: 'Enter the Story', onPressed: onEnter),
              ],
            ),
          ),
        ],

        accents: [
          if (beat.signLines.isNotEmpty)
            At(
              right: 64,
              bottom: 96,
              child: Reveal(
                delay: const Duration(milliseconds: 620),
                child: WoodenSign(
                  lines: beat.signLines,
                  width: 300,
                  height: 118,
                  rotation: -0.02,
                  seed: 9,
                  textStyle: Type.handSmall.copyWith(fontSize: 28),
                ),
              ),
            ),
        ],
      ),
      children: [
        SceneLayer(seed: 11, paint: [Landscape.sky]),
        ParallaxLayer(
          depth: 0.1,
          child: SceneLayer(
            seed: 221,
            paint: [
              Landscape.clouds(seed: 221, band: 0.12, count: 4, scale: 0.5),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.3,
          child: SceneLayer(
            seed: 231,
            repaintOnTime: false,
            paint: [
              Cityscape.officeTower(
                seed: 233,
                bounds: (size) => Rect.fromLTWH(
                  size.width * 0.50,
                  size.height * 0.08,
                  size.width * 0.30,
                  size.height * 0.74,
                ),
                sign: chapter.title.toUpperCase(),
                glass: glass,
              ),
              Cityscape.officeTower(
                seed: 241,
                bounds: (size) => Rect.fromLTWH(
                  size.width * 0.82,
                  size.height * 0.24,
                  size.width * 0.16,
                  size.height * 0.58,
                ),
                glass: Color.lerp(glass, Colors.black, 0.22)!,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.6,
          child: SceneLayer(seed: 251, repaintOnTime: false, paint: [_plaza]),
        ),
        ParallaxLayer(
          depth: 1.0,
          child: SceneLayer(
            seed: 261,
            repaintOnTime: false,
            paint: [
              Landscape.foliageFrame(seed: 261, right: false, scale: 0.9),
            ],
          ),
        ),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _plaza(Canvas canvas, Size size, ScenePaintContext ctx) {
    final n = ctx.noise;
    final ground = Rect.fromLTRB(
      0,
      size.height * 0.78,
      size.width,
      size.height,
    );
    Kit.gradientRect(canvas, ground, const [
      Color(0xFF9A9384),
      Color(0xFF7D7668),
    ]);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, 6),
      Paint()..color = const Color(0xFFB8B2A2),
    );
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.06 + i * 0.105);
      Kit.broadleaf(
        canvas,
        Offset(x, size.height * (0.80 + n.range(i * 7, 0.0, 0.04))),
        size.height * n.range(i * 13, 0.16, 0.24),
        const Color(0xFF3E6B44),
        n,
        i * 5,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Problem — night desk with a live progress bar (frame 05)
// ---------------------------------------------------------------------------

class _Problem extends StatelessWidget {
  const _Problem({required this.beat});

  final StoryBeat beat;

  @override
  Widget build(BuildContext context) {
    return WorldStage(
      lighting: SceneLighting.night,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 75,
            top: 110,
            width: 660,
            child: RevealGroup(
              start: const Duration(milliseconds: 160),
              children: [
                HandwrittenAccent(
                  text: beat.title,
                  style: Type.handSection,
                  color: Colors.white,
                  rotation: -0.012,
                ),
                const SizedBox(height: T.s16),
                if (beat.body != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      beat.body!,
                      style: Type.bodyLg.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Color(0xAA000000), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CopySlot(
            left: 75,
            top: 330,
            width: 620,
            child: Reveal(
              delay: const Duration(milliseconds: 520),
              child: GlassPanel(
                padding: const EdgeInsets.fromLTRB(T.s24, T.s20, T.s24, T.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LaunchProgress(
                      label: beat.progressLabel ?? 'Working…',
                      result: beat.progressResult ?? '',
                      width: 280,
                    ),
                    if (beat.accent != null) ...[
                      const SizedBox(height: T.s16),
                      Text(
                        beat.accent!,
                        style: Type.handSmall.copyWith(
                          fontSize: 30,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      children: [
        SceneLayer(
          seed: 301,
          repaintOnTime: false,
          paint: [
            Interior.wall(
              seed: 301,
              base: const Color(0xFF3A2E22),
              dark: const Color(0xFF1A150F),
              planks: 10,
            ),
          ],
        ),
        SceneLayer(seed: 303, repaintOnTime: false, paint: [_nightRoom]),
        SceneLayer(
          seed: 305,
          paint: [
            Interior.lightShaft(
              from: (size) => Offset(size.width * 0.63, size.height * 0.22),
              width: 120,
              angle: 1.35,
              color: T.lampGlow,
              opacity: 0.2,
              flicker: 1.6,
            ),
          ],
        ),
        SceneLayer(seed: 307, paint: [_deskAndFigure]),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _nightRoom(Canvas canvas, Size size, ScenePaintContext ctx) {
    final win = Rect.fromLTWH(
      size.width * 0.40,
      size.height * 0.08,
      size.width * 0.19,
      size.height * 0.40,
    );
    canvas.drawRect(win, Paint()..color = const Color(0xFF0E1826));
    for (var i = 0; i < 26; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          win.left + ctx.noise.at(i * 3) * win.width,
          win.top + ctx.noise.at(i * 7 + 1) * win.height,
          3,
          4,
        ),
        Paint()..color = T.lampGlow.withValues(alpha: 0.4),
      );
    }
    canvas.drawRect(
      win,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFF2A2018),
    );
    Interior.papers(
      canvas,
      Rect.fromLTWH(
        size.width * 0.80,
        size.height * 0.08,
        size.width * 0.18,
        size.height * 0.34,
      ),
      5,
      ctx,
      311,
      color: const Color(0xFFCFC4AE),
    );
    Interior.plant(
      canvas,
      Offset(size.width * 0.03, size.height * 0.98),
      190,
      ctx,
      313,
      leaf: const Color(0xFF2E4A34),
    );
  }

  static void _deskAndFigure(Canvas canvas, Size size, ScenePaintContext ctx) {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.80, size.width, size.height),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3E2E20), Color(0xFF1C140E)],
            ).createShader(
              Rect.fromLTRB(0, size.height * 0.80, size.width, size.height),
            ),
    );
    Interior.deskLamp(
      canvas,
      Offset(size.width * 0.635, size.height * 0.20),
      1.2,
      ctx,
    );
    Character.paint(
      canvas,
      Offset(size.width * 0.82, size.height * 0.88),
      size.height * 0.56,
      Pose.deskProfile,
      CharacterPalette.night,
      ctx,
      breathe: ctx.time * 0.9,
    );
    Interior.laptop(
      canvas,
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.62,
        size.width * 0.12,
        size.height * 0.2,
      ),
      ctx,
      shell: const Color(0xFF5A6068),
    );
    Interior.mug(
      canvas,
      Offset(size.width * 0.535, size.height * 0.84),
      30,
      ctx,
    );
  }
}

// ---------------------------------------------------------------------------
// Investigation — measured rows and a whiteboard (frame 06)
// ---------------------------------------------------------------------------

class _Investigation extends StatelessWidget {
  const _Investigation({required this.beat});

  final StoryBeat beat;

  @override
  Widget build(BuildContext context) {
    return WorldStage(
      lighting: SceneLighting.night,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 75,
            top: 100,
            width: 660,
            child: RevealGroup(
              start: const Duration(milliseconds: 160),
              children: [
                HandwrittenAccent(
                  text: beat.title,
                  style: Type.handSection,
                  color: Colors.white,
                  rotation: -0.01,
                ),
                const SizedBox(height: T.s12),
                if (beat.body != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      beat.body!,
                      style: Type.bodyLg.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Color(0xAA000000), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CopySlot(
            left: 75,
            top: 330,
            width: 640,
            child: Reveal(
              delay: const Duration(milliseconds: 420),
              child: GlassPanel(
                padding: const EdgeInsets.fromLTRB(T.s20, T.s16, T.s20, T.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (beat.panelTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: T.s4,
                          bottom: T.s12,
                        ),
                        child: Text(
                          beat.panelTitle!,
                          style: Type.label.copyWith(color: Colors.white),
                        ),
                      ),
                    RevealGroup(
                      start: const Duration(milliseconds: 620),
                      step: const Duration(milliseconds: 150),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: T.s4,
                      children: [
                        for (final m in beat.metrics)
                          MetricRow(
                            label: m.label,
                            value: m.value,
                            emphasis: m.emphasis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      children: [
        SceneLayer(
          seed: 321,
          repaintOnTime: false,
          paint: [
            Interior.wall(
              seed: 321,
              base: const Color(0xFF2A3346),
              dark: const Color(0xFF141A26),
              planks: 8,
            ),
          ],
        ),
        SceneLayer(
          seed: 323,
          repaintOnTime: false,
          paint: [_RoomPainter(beat.boardLines).paint],
        ),
        SceneLayer(seed: 325, paint: [_figure]),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _figure(Canvas canvas, Size size, ScenePaintContext ctx) {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.84, size.width, size.height),
      Paint()..color = const Color(0xFF1A2130),
    );
    Interior.laptop(
      canvas,
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.60,
        size.width * 0.13,
        size.height * 0.22,
      ),
      ctx,
      shell: const Color(0xFF4A5058),
    );
    Character.cat(
      canvas,
      Offset(size.width * 0.79, size.height * 0.845),
      64,
      ctx,
      facing: -1,
      tailPhase: ctx.time * 1.4,
      body: const Color(0xFF3A3A42),
      shade: const Color(0xFF2A2A30),
    );
    Character.paint(
      canvas,
      Offset(size.width * 0.95, size.height * 1.02),
      size.height * 0.46,
      Pose.deskBackQuarter,
      CharacterPalette.night,
      ctx,
      breathe: ctx.time * 0.8,
    );
  }
}

/// The night room behind the investigation panel, including the whiteboard.
class _RoomPainter {
  const _RoomPainter(this.boardLines);

  final List<String> boardLines;

  void paint(Canvas canvas, Size size, ScenePaintContext ctx) {
    final win = Rect.fromLTWH(
      size.width * 0.52,
      size.height * 0.06,
      size.width * 0.22,
      size.height * 0.46,
    );
    canvas.drawRect(win, Paint()..color = const Color(0xFF16233A));
    canvas.save();
    canvas.clipRect(win);
    canvas.translate(win.left, win.top);
    Cityscape.skyline(
      seed: 331,
      baseline: 0.92,
      height: 0.5,
      distance: 0.3,
      count: 14,
    )(canvas, win.size, ctx);
    canvas.restore();
    canvas.drawRect(
      win,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF1E2636),
    );

    if (boardLines.isNotEmpty) {
      final board = Rect.fromLTWH(
        size.width * 0.775,
        size.height * 0.055,
        size.width * 0.205,
        size.height * 0.26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(board, const Radius.circular(3)),
        Paint()..color = const Color(0xFFEDEAE0),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(board, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF6B6255),
      );
      var y = board.top + board.height * 0.14;
      for (final line in boardLines) {
        Kit.text(
          canvas,
          line,
          Offset(board.left + board.width * 0.09, y),
          const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 30,
            color: Color(0xFF2E3A48),
          ),
        );
        y += board.height * 0.26;
      }
    }

    Interior.plant(
      canvas,
      Offset(size.width * 0.755, size.height * 0.52),
      76,
      ctx,
      333,
      leaf: const Color(0xFF3A5E42),
    );
  }
}

// ---------------------------------------------------------------------------
// Decision — parchment note with tabs (frame 07)
// ---------------------------------------------------------------------------

class _Decision extends StatefulWidget {
  const _Decision({required this.beat});

  final StoryBeat beat;

  @override
  State<_Decision> createState() => _DecisionState();
}

class _DecisionState extends State<_Decision> {
  int _tab = 0;

  List<String> get _tabNames => widget.beat.tabs.keys.toList();

  List<String> get _items => widget.beat.tabs.isEmpty
      ? widget.beat.checklist
      : widget.beat.tabs[_tabNames[_tab]]!;

  @override
  Widget build(BuildContext context) {
    final beat = widget.beat;

    return WorldStage(
      lighting: SceneLighting.night,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 65,
            top: 95,
            width: 550,
            child: Reveal(
              delay: const Duration(milliseconds: 160),
              child: ParchmentPanel(
                seed: 17,
                rotation: -0.012,
                padding: const EdgeInsets.fromLTRB(T.s24, T.s20, T.s24, T.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HandwrittenAccent(
                      text: beat.title,
                      style: Type.handSection,
                      color: T.ink,
                      rotation: 0,
                      shadow: false,
                    ),
                    const SizedBox(height: T.s12),
                    if (beat.body != null)
                      Text(
                        beat.body!,
                        style: Type.body.copyWith(color: T.inkMuted),
                      ),
                    const SizedBox(height: T.s20),
                    // Switching tabs re-runs the stagger, so the list reads as
                    // a fresh answer rather than a swapped label.
                    AnimatedSwitcher(
                      duration: motionDuration(context, T.dBase),
                      child: CheckList(
                        key: ValueKey(_tab),
                        items: _items,
                        start: Duration.zero,
                        spacing: T.s12,
                        style: Type.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        accents: [
          if (_tabNames.length > 1)
            At(
              right: 56,
              bottom: 64,
              child: Reveal(
                delay: const Duration(milliseconds: 560),
                child: SegmentedTabs(
                  tabs: _tabNames,
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
            ),
        ],
        // The tabs switch the panel above them, so unlike the handwritten
        // accents they cannot simply be dropped on a phone.
        compactExtras: [
          if (_tabNames.length > 1)
            Positioned(
              left: T.s24,
              right: T.s24,
              bottom: 120,
              child: Reveal(
                delay: const Duration(milliseconds: 560),
                child: Center(
                  child: SegmentedTabs(
                    tabs: _tabNames,
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              ),
            ),
        ],
      ),
      children: [
        SceneLayer(
          seed: 341,
          repaintOnTime: false,
          paint: [
            Interior.wall(
              seed: 341,
              base: const Color(0xFF3A3021),
              dark: const Color(0xFF191309),
              planks: 9,
            ),
          ],
        ),
        SceneLayer(seed: 343, repaintOnTime: false, paint: [_room]),
        SceneLayer(seed: 345, paint: [_desk]),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _room(Canvas canvas, Size size, ScenePaintContext ctx) {
    final win = Rect.fromLTWH(
      size.width * 0.47,
      size.height * 0.04,
      size.width * 0.30,
      size.height * 0.50,
    );
    canvas.drawRect(win, Paint()..color = const Color(0xFF15243A));
    canvas.save();
    canvas.clipRect(win);
    canvas.translate(win.left, win.top);
    Landscape.mountains(
      seed: 7,
      top: 0.4,
      bottom: 1.0,
      roughness: 4.0,
      distance: 0.55,
    )(canvas, win.size, ctx);
    Cityscape.skyline(
      seed: 347,
      baseline: 0.96,
      height: 0.4,
      distance: 0.34,
      count: 12,
    )(canvas, win.size, ctx);
    canvas.restore();
    final bar = Paint()..color = const Color(0xFF2C2114);
    canvas.drawRect(
      Rect.fromLTWH(win.center.dx - 3, win.top, 6, win.height),
      bar,
    );
    canvas.drawRect(
      win,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = const Color(0xFF2C2114),
    );
    Interior.plant(
      canvas,
      Offset(size.width * 0.415, size.height * 0.70),
      96,
      ctx,
      349,
      leaf: const Color(0xFF3E6B44),
    );
  }

  static void _desk(Canvas canvas, Size size, ScenePaintContext ctx) {
    Interior.desk(seed: 351, top: 0.70, base: const Color(0xFF6A4728))(
      canvas,
      size,
      ctx,
    );
    Interior.monitor(
      canvas,
      Rect.fromLTWH(
        size.width * 0.545,
        size.height * 0.34,
        size.width * 0.235,
        size.height * 0.33,
      ),
      ctx,
    );
    Interior.mug(
      canvas,
      Offset(size.width * 0.415, size.height * 0.815),
      62,
      ctx,
      label: const ['Build', 'Measure', 'Improve', 'Repeat'],
    );
    Interior.books(
      canvas,
      Offset(size.width * 0.505, size.height * 0.705),
      44,
      3,
      ctx,
      353,
    );
    Character.paint(
      canvas,
      Offset(size.width * 0.94, size.height * 1.02),
      size.height * 0.48,
      Pose.deskBackQuarter,
      CharacterPalette.night,
      ctx,
      breathe: ctx.time * 0.85,
    );
  }
}

// ---------------------------------------------------------------------------
// Architecture — blueprint wall with the flow (frame 08)
// ---------------------------------------------------------------------------

class _Architecture extends StatelessWidget {
  const _Architecture({required this.beat});

  final StoryBeat beat;

  @override
  Widget build(BuildContext context) {
    return WorldStage(
      lighting: SceneLighting.night,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 80,
            top: 140,
            width: 700,
            child: RevealGroup(
              start: const Duration(milliseconds: 140),
              children: [
                HandwrittenAccent(
                  text: beat.title,
                  style: Type.handSection,
                  color: Colors.white,
                  rotation: -0.01,
                ),
                const SizedBox(height: T.s8),
                if (beat.body != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      beat.body!,
                      style: Type.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CopySlot(
            left: 70,
            top: 335,
            width: 890,
            child: Reveal(
              delay: const Duration(milliseconds: 360),
              child: Builder(
                builder: (context) {
                  final compact = WorldStage.of(context).form.isPhone;
                  final flow = FlowDiagram(
                    nodes: [
                      for (final n in beat.flow)
                        FlowNode(n.label, detail: n.detail),
                    ],
                    // Résumé-derived step names are longer than "App Launch";
                    // the default 132 wraps them mid-word.
                    nodeWidth: 240,
                  );
                  final techniques = Container(
                    padding: const EdgeInsets.all(T.s20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(T.rSm),
                      border: Border.all(color: T.glassBorder),
                    ),
                    child: TechniqueList(items: beat.techniques),
                  );
                  // 890 units of diagram-arrow-list cannot sit in a row on a
                  // 600-unit box, so the arrow turns to point downward and the
                  // two halves stack.
                  final arrow = Icon(
                    compact ? Icons.arrow_downward : Icons.arrow_forward,
                    size: 40,
                    color: T.metricBlue.withValues(alpha: 0.95),
                  );
                  return GlassPanel(
                    padding: compact
                        ? const EdgeInsets.all(T.s20)
                        : const EdgeInsets.fromLTRB(40, T.s24, 40, T.s24),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              flow,
                              const SizedBox(height: T.s16),
                              arrow,
                              const SizedBox(height: T.s16),
                              techniques,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              flow,
                              const SizedBox(width: 58),
                              arrow,
                              const SizedBox(width: 54),
                              // Takes the width that is left rather than its
                              // intrinsic size, so a narrower panel wraps the
                              // labels instead of overflowing the row.
                              Expanded(child: techniques),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        ],
        accents: [
          if (beat.accent != null)
            At(
              right: 230,
              top: 440,
              width: 275,
              child: Reveal(
                delay: const Duration(milliseconds: 820),
                child: HandwrittenAccent(
                  text: beat.accent!,
                  style: Type.handNote.copyWith(fontSize: 44),
                  color: const Color(0xFFF0E2C0),
                  rotation: -0.26,
                ),
              ),
            ),
        ],
      ),
      children: [
        SceneLayer(seed: 361, repaintOnTime: false, paint: [_blueprint]),
        SceneLayer(seed: 363, paint: [_figure]),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _blueprint(Canvas canvas, Size size, ScenePaintContext ctx) {
    final rect = Offset.zero & size;
    Kit.gradientRect(canvas, rect, const [
      Color(0xFF0B1A2E),
      Color(0xFF10233C),
      Color(0xFF0A1424),
    ]);
    final grid = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF3E6FA0).withValues(alpha: 0.12);
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final n = ctx.noise;
    final schematic = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF5B9BD4).withValues(alpha: 0.16);
    for (var i = 0; i < 14; i++) {
      final w = size.width * n.range(i * 11 + 3, 0.05, 0.12);
      final h = w * n.range(i * 7 + 5, 0.3, 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * n.at(i * 13),
            size.height * n.at(i * 17 + 1),
            w,
            h,
          ),
          const Radius.circular(3),
        ),
        schematic,
      );
    }
    Kit.glow(
      canvas,
      Offset(size.width * 0.3, size.height * 0.4),
      size.height * 0.7,
      const Color(0xFF2E6BA8),
      intensity: 0.2,
    );
  }

  static void _figure(Canvas canvas, Size size, ScenePaintContext ctx) {
    Character.paint(
      canvas,
      Offset(size.width * 1.02, size.height * 1.02),
      size.height * 0.98,
      Pose.deskBackQuarter,
      CharacterPalette.night,
      ctx,
      breathe: ctx.time * 0.8,
    );
  }
}

// ---------------------------------------------------------------------------
// Outcome — the result on a cream panel (frame 09)
// ---------------------------------------------------------------------------

class _Outcome extends StatelessWidget {
  const _Outcome({required this.beat});

  final StoryBeat beat;

  @override
  Widget build(BuildContext context) {
    final bars = beat.comparison;

    return WorldStage(
      lighting: SceneLighting.sunset,
      ui: SceneUi(
        copy: [
          CopySlot(
            left: 45,
            top: 145,
            width: 790,
            child: Reveal(
              delay: const Duration(milliseconds: 160),
              child: ParchmentPanel(
                seed: 29,
                rotation: -0.004,
                padding: const EdgeInsets.fromLTRB(45, 40, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      beat.title,
                      style: Type.displayXl.copyWith(
                        fontSize: 64,
                        color: T.ink,
                      ),
                    ),
                    const SizedBox(height: T.s16),
                    if (beat.body != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Text(
                          beat.body!,
                          style: Type.bodyLg.copyWith(
                            color: T.inkMuted,
                            height: 1.45,
                          ),
                        ),
                      ),
                    const SizedBox(height: T.s24),
                    // Bars beside a checklist need ~700 units; on a phone they
                    // stack instead of squeezing the list to a word a line.
                    Builder(
                      builder: (context) {
                        final compact = WorldStage.of(context).form.isPhone;
                        return Flex(
                          direction: compact ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: compact
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bars != null) ...[
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  T.s24,
                                  T.s20,
                                  T.s24,
                                  T.s16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3F4A52),
                                  borderRadius: BorderRadius.circular(T.rMd),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ComparisonBars(
                                  before: bars.before,
                                  after: bars.after,
                                  beforeLabel: bars.beforeLabel,
                                  afterLabel: bars.afterLabel,
                                  beforeValue: bars.beforeValue,
                                  afterValue: bars.afterValue,
                                  height: 210,
                                  barWidth: 66,
                                ),
                              ),
                              const SizedBox(width: T.s32, height: T.s24),
                            ],
                            Flexible(
                              child: CheckList(
                                items: beat.checklist,
                                color: T.success,
                                textColor: T.ink,
                                style: Type.bodyLg,
                                spacing: T.s20,
                                tickSize: 42,
                                start: const Duration(milliseconds: 700),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        accents: [
          if (beat.accent != null)
            At(
              right: 96,
              top: 100,
              width: 300,
              child: Reveal(
                delay: const Duration(milliseconds: 820),
                child: HandwrittenAccent(
                  text: beat.accent!,
                  style: Type.handNote.copyWith(fontSize: 44),
                  color: const Color(0xFF3A2A22),
                  shadow: false,
                ),
              ),
            ),
        ],
      ),
      children: [
        SceneLayer(seed: 11, paint: [Landscape.sky, Landscape.sunDisc]),
        ParallaxLayer(
          depth: 0.1,
          child: SceneLayer(
            seed: 371,
            paint: [
              Landscape.clouds(seed: 371, band: 0.14, count: 5, scale: 0.6),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.2,
          child: SceneLayer(
            seed: 7,
            repaintOnTime: false,
            paint: [
              Landscape.mountains(
                seed: 7,
                top: 0.26,
                bottom: 0.56,
                roughness: 5.0,
                distance: 0.5,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.34,
          child: SceneLayer(
            seed: 373,
            repaintOnTime: false,
            paint: [
              Cityscape.skyline(
                seed: 373,
                baseline: 0.62,
                height: 0.22,
                distance: 0.3,
                count: 30,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.45,
          child: SceneLayer(
            seed: 375,
            paint: [Landscape.lake(seed: 375, top: 0.60, bottom: 0.84)],
          ),
        ),
        ParallaxLayer(
          depth: 0.7,
          child: SceneLayer(
            seed: 377,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 377,
                top: 0.78,
                bottom: 1.06,
                distance: 0.06,
                amplitude: 0.3,
                treeCount: 26,
                treeScale: 0.6,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.9,
          child: SceneLayer(seed: 379, paint: [_benchAndFigure]),
        ),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _benchAndFigure(Canvas canvas, Size size, ScenePaintContext ctx) {
    final base = Offset(size.width * 0.79, size.height * 0.965);
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 150, base.dy - 6, 300, 12),
      Paint()..color = const Color(0xFF4A3A2A),
    );
    for (final dx in [-120.0, 120.0]) {
      canvas.drawRect(
        Rect.fromLTWH(base.dx + dx, base.dy + 6, 12, 54),
        Paint()..color = const Color(0xFF3A2C20),
      );
    }
    Character.paint(
      canvas,
      base,
      size.height * 0.52,
      Pose.seatedBack,
      CharacterPalette.sunset,
      ctx,
      backpack: false,
      breathe: ctx.time * 0.95,
    );
    Character.cat(
      canvas,
      base.translate(118, 0),
      62,
      ctx,
      facing: -1,
      tailPhase: ctx.time * 1.5,
    );
    Character.cat(
      canvas,
      base.translate(-126, 0),
      56,
      ctx,
      facing: 1,
      tailPhase: ctx.time * 1.2,
      body: const Color(0xFF6E5A46),
      shade: const Color(0xFF4E3E30),
    );
  }
}

// ---------------------------------------------------------------------------
// Transition — the road onward (frame 10)
// ---------------------------------------------------------------------------

class _Transition extends StatelessWidget {
  const _Transition({
    required this.chapter,
    required this.beat,
    required this.onNext,
  });

  final Chapter chapter;
  final StoryBeat beat;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return WorldStage(
      lighting: SceneLighting.day,
      ui: SceneUi(
        accents: [
          if (beat.accent != null)
            At(
              right: 195,
              top: 120,
              width: 470,
              child: Reveal(
                delay: const Duration(milliseconds: 220),
                child: HandwrittenAccent(
                  text: beat.accent!,
                  style: Type.handNote.copyWith(fontSize: 40),
                  // Written on the hillside, not on a panel — it has to
                  // follow whatever light the scene resolved to.
                  color: DayNightScope.paletteFor(
                    context,
                    SceneLighting.day,
                  ).onWorld,
                  shadow: false,
                  align: TextAlign.right,
                ),
              ),
            ),
          if (chapter.nextChapterLabel != null)
            At(
              right: 0,
              top: 385,
              child: Reveal(
                delay: const Duration(milliseconds: 560),
                offset: const Offset(20, 0),
                child: Hotspot(
                  label: 'Next chapter — ${chapter.nextChapterLabel}',
                  tooltip: 'Continue to ${chapter.nextChapterLabel}',
                  onActivate: onNext,
                  builder: (context, active) => WoodenSign(
                    lines: [chapter.nextChapterLabel!],
                    eyebrow: 'Next Chapter',
                    width: 340,
                    height: 205,
                    seed: 11,
                    active: active,
                    eyebrowStyle: Type.label.copyWith(fontSize: 30),
                    textStyle: Type.displayMd.copyWith(fontSize: 44),
                  ),
                ),
              ),
            ),
        ],
        // The 340-unit plank is the only way on from here, and it hangs off the
        // right edge, so a phone gets it as a button instead of losing it.
        compactExtras: [
          if (chapter.nextChapterLabel != null)
            Positioned(
              left: T.s24,
              right: T.s24,
              bottom: 120,
              child: Reveal(
                delay: const Duration(milliseconds: 560),
                child: CompactDestination(
                  label: 'Next chapter — ${chapter.nextChapterLabel}',
                  onTap: onNext,
                ),
              ),
            ),
        ],
      ),
      children: [
        SceneLayer(seed: 11, paint: [Landscape.sky]),
        ParallaxLayer(
          depth: 0.1,
          child: SceneLayer(
            seed: 381,
            paint: [
              Landscape.clouds(seed: 381, band: 0.10, count: 5, scale: 0.6),
              Landscape.clouds(
                seed: 383,
                band: 0.2,
                count: 3,
                scale: 0.42,
                opacity: 0.85,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.2,
          child: SceneLayer(
            seed: 7,
            repaintOnTime: false,
            paint: [
              Landscape.mountains(
                seed: 7,
                top: 0.16,
                bottom: 0.54,
                roughness: 5.5,
                distance: 0.44,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.3,
          child: SceneLayer(
            seed: 385,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 385,
                top: 0.30,
                bottom: 0.62,
                distance: 0.3,
                amplitude: 0.4,
                trees: false,
                color: const Color(0xFF6E8C6A),
                shape: (t) =>
                    0.22 - math.exp(-math.pow(t - 0.56, 2) * 30) * 0.4,
              ),
              Landscape.castle(
                seed: 387,
                anchor: (size) =>
                    Offset(size.width * 0.556, size.height * 0.44),
                scale: 1.25,
                distance: 0.28,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.45,
          child: SceneLayer(
            seed: 389,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 389,
                top: 0.46,
                bottom: 0.86,
                distance: 0.16,
                amplitude: 0.42,
                treeCount: 36,
                treeScale: 0.6,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.8,
          child: SceneLayer(
            seed: 393,
            repaintOnTime: false,
            paint: [Landscape.ground(seed: 393, top: 0.82, amplitude: 0.2)],
          ),
        ),
        // The road sits on top of the near ground, not under it.
        ParallaxLayer(
          depth: 0.6,
          child: SceneLayer(
            seed: 391,
            repaintOnTime: false,
            paint: [
              Landscape.road(
                seed: 391,
                horizon: 0.50,
                horizonX: 0.558,
                nearX: 0.60,
                width: 0.22,
                bend: 0.15,
              ),
            ],
          ),
        ),
        ParallaxLayer(
          depth: 0.3,
          child: SceneLayer(
            seed: 395,
            paint: [Landscape.birds(seed: 395, band: 0.18)],
          ),
        ),
        ParallaxLayer(
          depth: 0.95,
          child: SceneLayer(seed: 397, paint: [_wandererAndCat]),
        ),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  static void _wandererAndCat(Canvas canvas, Size size, ScenePaintContext ctx) {
    final base = Offset(size.width * 0.268, size.height * 1.0);
    Character.paint(
      canvas,
      base,
      size.height * 0.74,
      Pose.standingBack,
      CharacterPalette.day,
      ctx,
      breathe: ctx.time * 1.0,
    );
    Character.cat(
      canvas,
      Offset(size.width * 0.405, size.height * 0.94),
      120,
      ctx,
      tailPhase: ctx.time * 1.7,
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

class _ChapterBadge extends StatelessWidget {
  const _ChapterBadge({
    required this.title,
    required this.credibility,
    required this.onBack,
  });

  final String title;
  final Credibility credibility;
  final VoidCallback onBack;

  /// Fill and border for the kind badge, so a degree is never tinted like a
  /// job.
  (Color, Color) get _tint => switch (credibility) {
        Credibility.professional => (T.success, T.successGlow),
        Credibility.education => (T.lampGlow, T.lampGlow),
        Credibility.personalProject => (T.metricBlue, T.metricBlue),
        Credibility.exploration => (T.lampGlow, T.lampGlow),
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hotspot(
          label: 'Back to the journey map',
          tooltip: 'Back to the map',
          onActivate: onBack,
          builder: (context, active) => AnimatedContainer(
            duration: motionDuration(context, T.dFast),
            padding: const EdgeInsets.symmetric(
              horizontal: T.s12,
              vertical: T.s6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: active ? 0.5 : 0.32),
              borderRadius: BorderRadius.circular(T.rPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 14, color: Colors.white),
                const SizedBox(width: T.s6),
                Text(title, style: Type.labelSm.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: T.s8),
        // The PRD's honesty rule, rendered rather than implied.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: T.s8, vertical: 3),
          decoration: BoxDecoration(
            color: _tint.$1.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(T.rPill),
            border: Border.all(color: _tint.$2.withValues(alpha: 0.7)),
          ),
          child: Text(
            credibility.label,
            style: Type.labelSm.copyWith(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: label,
      tooltip: label,
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: active ? 0.55 : 0.32),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.8 : 0.35),
          ),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
