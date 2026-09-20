import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../data/journey.dart';
import '../../world/painters/interior.dart';
import '../../world/painters/landscape.dart';
import '../../components/panels.dart';
import '../../world/painters/paint_kit.dart';
import '../../world/plate.dart';
import '../../world/plates.g.dart';
import '../../world/stage.dart';

/// Frame 11 — Personal Side.
///
/// A desk of scattered polaroids, journals, a guitar, a world map and an open
/// notebook. Each artifact is a hotspot, on the same pattern as the workshop.
class HumanScene extends StatelessWidget {
  const HumanScene({super.key, required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    // On a plate the painting carries the note, the polaroids and the
    // notebook; only the back link and the way onward stay live.
    final plate = platesOn(context);
    return WorldStage(
      lighting: SceneLighting.interior,
      ui: SceneUi(
        leading: _Back(onTap: () => onNavigate('/map')),
        // The light and the ambience, reachable from here rather than only
        // from the two screens that show a nav.
        extras: [
          At(right: T.s24, top: T.s24, child: AmbientToggles(composed: SceneLighting.interior)),
        ],
        trailing: Reveal(
          delay: const Duration(milliseconds: 900),
          child: PillButton(
            label: 'Still curious?',
            onPressed: () => onNavigate('/sunset'),
          ),
        ),
        // The reference sets this copy on a paper sheet, not loose on wood.
        copy: plate ? const [] : [CopySlot(
          left: 175,
          top: 140,
          width: 545,
          scrim: false,
          child: Reveal(
            delay: const Duration(milliseconds: 180),
            child: ParchmentPanel(
              seed: 23,
              rotation: -0.006,
              padding: const EdgeInsets.fromLTRB(55, 55, 45, 55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HandwrittenAccent(
                    text: 'Beyond Code',
                    style: Type.handTitle,
                    color: Color(0xFF2E2216),
                    rotation: -0.012,
                    shadow: false,
                  ),
                  const SizedBox(height: T.s24),
                  for (final line in personalLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        line,
                        style: Type.bodyLg.copyWith(
                          color: const Color(0xFF3E3022),
                          fontSize: 29,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )],
      ),
      children: plate
          ? [
              ScenePlate(
                art: plateHuman,
                lighting: SceneLighting.interior,
              ),
            ]
          : [
        // A warm table top seen from above.
        SceneLayer(seed: 401, repaintOnTime: false, paint: [_tableTop]),
        SceneLayer(seed: 403, repaintOnTime: false, paint: [_artifacts]),
        SceneLayer(
          seed: 405,
          paint: [
            Interior.lightShaft(
              from: (size) => Offset(size.width * 0.2, -size.height * 0.1),
              width: 340,
              angle: 1.25,
              opacity: 0.14,
            ),
          ],
        ),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),

        // ------------------------------- hotspots over the painted artifacts
        // Pinned in fractions of the art box, not pixels off the 1440x861
        // reference, so they stay on their prop when the box is re-proportioned.
        WorldAt(
          left: 0.4722,
          top: 0.0697,
          width: 0.1146,
          height: 0.4355,
          child: _Artifact(
            label: 'Cricket — a photo from the field',
            tooltip: 'Cricket',
          ),
        ),
        WorldAt(
          left: 0.6007,
          top: 0.0639,
          width: 0.125,
          height: 0.4471,
          child: _Artifact(
            label: 'Travel — a photo from the mountains',
            tooltip: 'Travel',
          ),
        ),
        WorldAt(
          left: 0.7326,
          top: 0.0755,
          width: 0.1181,
          height: 0.4471,
          child: _Artifact(
            label: 'Books — what I am reading',
            tooltip: 'Books',
          ),
        ),
        WorldAt(
          left: 0.8611,
          top: 0.1161,
          width: 0.1042,
          height: 0.4297,
          child: _Artifact(
            label: 'Music — the guitar in the corner',
            tooltip: 'Music',
          ),
        ),
        WorldAt(
          left: 0.5104,
          top: 0.5691,
          width: 0.184,
          height: 0.4297,
          child: _Artifact(
            label: 'Notebook — Better, Build, Explore, Repeat',
            tooltip: 'The list I keep coming back to',
          ),
        ),
        WorldAt(
          left: 0.7014,
          top: 0.5807,
          width: 0.2222,
          height: 0.4065,
          child: _Artifact(
            label: 'World map — places I have been',
            tooltip: 'Travel map',
          ),
        ),
      ],
    );
  }

  static void _tableTop(Canvas canvas, Size size, ScenePaintContext ctx) {
    final rect = Offset.zero & size;
    final n = ctx.noise;
    Kit.gradientRect(canvas, rect, const [
      Color(0xFF8A6238),
      Color(0xFF6E4B29),
      Color(0xFF4A301A),
    ]);
    // Board seams running across the table.
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF3A2413).withValues(alpha: 0.4),
      );
      for (var g = 0; g < 4; g++) {
        final gy = y + (g + 1) * 6.0;
        final path = Path()..moveTo(0, gy);
        for (var x = 0.0; x < size.width; x += 20) {
          path.lineTo(x, gy + (n.value2(x * 0.014, i * 3.0 + g) - 0.5) * 5);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFF3A2413).withValues(alpha: 0.16),
        );
      }
    }
    Kit.brushwork(canvas, rect, n, 411, angle: 0.1, strokes: 50, opacity: 0.03);
  }

  static void _artifacts(Canvas canvas, Size size, ScenePaintContext ctx) {
    final n = ctx.noise;

    // Cricket polaroid.
    Interior.polaroid(
      canvas,
      Rect.fromLTWH(size.width * 0.472, size.height * 0.070,
          size.width * 0.115, size.height * 0.435),
      ctx,
      rotation: -0.03,
      caption: 'match day',
      content: (canvas, inner) {
        Kit.gradientRect(canvas, inner,
            const [Color(0xFF9FC6E0), Color(0xFF7FB06A)]);
        // A batsman: simple figure with a bat.
        final base = Offset(inner.center.dx, inner.bottom - inner.height * 0.14);
        canvas.drawRect(
          Rect.fromLTWH(base.dx - inner.width * 0.06, base.dy - inner.height * 0.34,
              inner.width * 0.12, inner.height * 0.34),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          base.translate(0, -inner.height * 0.4),
          inner.width * 0.055,
          Paint()..color = const Color(0xFFD9A97E),
        );
        canvas.drawLine(
          base.translate(inner.width * 0.06, -inner.height * 0.28),
          base.translate(inner.width * 0.22, inner.height * 0.02),
          Paint()
            ..color = const Color(0xFFC08A4A)
            ..strokeWidth = inner.width * 0.05
            ..strokeCap = StrokeCap.round,
        );
      },
    );

    // Travel polaroid.
    Interior.polaroid(
      canvas,
      Rect.fromLTWH(size.width * 0.601, size.height * 0.064,
          size.width * 0.125, size.height * 0.447),
      ctx,
      rotation: 0.02,
      caption: 'up there',
      content: (canvas, inner) {
        Kit.gradientRect(canvas, inner,
            const [Color(0xFF8FBEDE), Color(0xFFDCEAF2)]);
        final peak = Path()
          ..moveTo(inner.left, inner.bottom)
          ..lineTo(inner.left + inner.width * 0.34, inner.top + inner.height * 0.22)
          ..lineTo(inner.left + inner.width * 0.6, inner.bottom)
          ..close();
        canvas.drawPath(peak, Paint()..color = const Color(0xFF6E7FA8));
        canvas.drawPath(
          Path()
            ..moveTo(inner.left + inner.width * 0.42, inner.bottom)
            ..lineTo(inner.left + inner.width * 0.78, inner.top + inner.height * 0.34)
            ..lineTo(inner.right, inner.bottom)
            ..close(),
          Paint()..color = const Color(0xFF8B9BC4),
        );
      },
    );

    // A stack of books, seen from above-ish.
    Interior.books(
        canvas, Offset(size.width * 0.793, size.height * 0.50), 150, 5, ctx, 421);

    // Guitar, leaning in from the right.
    _guitar(canvas, Offset(size.width * 0.885, size.height * 0.10),
        size.height * 0.46, ctx);

    // Journals with decorated covers.
    for (var i = 0; i < 2; i++) {
      final r = Rect.fromLTWH(
        size.width * (0.128 + i * 0.145),
        size.height * (0.565 + i * 0.035),
        size.width * 0.175,
        size.height * 0.42,
      );
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(i == 0 ? -0.07 : 0.05);
      canvas.translate(-r.center.dx, -r.center.dy);
      canvas.drawRect(
        r.translate(2, 5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRect(
          r, Paint()..color = i == 0 ? const Color(0xFF3E5C76) : const Color(0xFF7A5E3A));
      // Cover ornament.
      for (var k = 0; k < 6; k++) {
        canvas.drawCircle(
          Offset(r.left + n.at(431 + i * 9 + k) * r.width,
              r.top + n.at(451 + i * 9 + k) * r.height),
          r.width * 0.06,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFE8D9B8).withValues(alpha: 0.6),
        );
      }
      canvas.restore();
    }

    // The open notebook: Better / Build / Explore / Repeat.
    final book = Rect.fromLTWH(size.width * 0.510, size.height * 0.569,
        size.width * 0.184, size.height * 0.430);
    canvas.save();
    canvas.translate(book.center.dx, book.center.dy);
    canvas.rotate(-0.03);
    canvas.translate(-book.center.dx, -book.center.dy);
    canvas.drawRect(
      book.translate(2, 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRect(book, Paint()..color = const Color(0xFFF7F1E2));
    // Ruled lines.
    for (var i = 1; i < 9; i++) {
      final y = book.top + book.height * i / 9;
      canvas.drawLine(
        Offset(book.left + 10, y),
        Offset(book.right - 10, y),
        Paint()
          ..strokeWidth = 1
          ..color = const Color(0xFFBFC9D4).withValues(alpha: 0.7),
      );
    }
    var ny = book.top + book.height * 0.12;
    for (final line in personalNotebook) {
      Kit.text(
        canvas,
        '⤷ $line',
        Offset(book.left + book.width * 0.12, ny),
        const TextStyle(fontFamily: 'Caveat', fontSize: 34, color: Color(0xFF34455A)),
      );
      ny += book.height * 0.20;
    }
    canvas.restore();

    // A world map, unrolled bottom right.
    final map = Rect.fromLTWH(size.width * 0.701, size.height * 0.581,
        size.width * 0.222, size.height * 0.406);
    canvas.save();
    canvas.translate(map.center.dx, map.center.dy);
    canvas.rotate(0.04);
    canvas.translate(-map.center.dx, -map.center.dy);
    canvas.drawRect(
      map.translate(2, 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRect(map, Paint()..color = const Color(0xFFE9DFC4));
    for (var i = 0; i < 10; i++) {
      canvas.drawPath(
        Kit.blob(
          Offset(map.left + n.at(461 + i) * map.width,
              map.top + n.at(481 + i) * map.height),
          map.width * n.range(491 + i, 0.06, 0.16),
          n,
          501 + i,
          points: 11,
          wobble: 0.42,
        ),
        Paint()..color = const Color(0xFF8AA678),
      );
    }
    // Route dashes between a few pins.
    final pins = [
      for (var i = 0; i < 5; i++)
        Offset(map.left + n.at(511 + i) * map.width,
            map.top + n.at(531 + i) * map.height),
    ];
    for (var i = 0; i < pins.length - 1; i++) {
      final a = pins[i];
      final b = pins[i + 1];
      final steps = 10;
      for (var k = 0; k < steps; k += 2) {
        canvas.drawLine(
          Offset.lerp(a, b, k / steps)!,
          Offset.lerp(a, b, (k + 1) / steps)!,
          Paint()
            ..strokeWidth = 1.4
            ..color = const Color(0xFFC0503C).withValues(alpha: 0.7),
        );
      }
    }
    for (final pin in pins) {
      canvas.drawCircle(pin, 3, Paint()..color = const Color(0xFFC0503C));
    }
    canvas.restore();

    // A mug and pen to fill the corner.
    Interior.mug(
        canvas, Offset(size.width * 0.345, size.height * 0.96), 56, ctx);
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.93),
      Offset(size.width * 0.655, size.height * 0.885),
      Paint()
        ..color = const Color(0xFF2E3138)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _guitar(
      Canvas canvas, Offset top, double height, ScenePaintContext ctx) {
    canvas.save();
    canvas.translate(top.dx, top.dy);
    canvas.rotate(0.22);

    final neckW = height * 0.075;
    // Neck.
    canvas.drawRect(
      Rect.fromLTWH(-neckW / 2, 0, neckW, height * 0.52),
      Paint()..color = const Color(0xFF5A3A22),
    );
    // Head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-neckW * 0.75, -height * 0.1, neckW * 1.5, height * 0.11),
        Radius.circular(neckW * 0.3),
      ),
      Paint()..color = const Color(0xFF3E2716),
    );
    // Body: two overlapping ovals.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, height * 0.66),
        width: height * 0.34,
        height: height * 0.3,
      ),
      Paint()..color = const Color(0xFFC98A4A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, height * 0.86),
        width: height * 0.42,
        height: height * 0.36,
      ),
      Paint()..color = const Color(0xFFC98A4A),
    );
    // Sound hole.
    canvas.drawCircle(
      Offset(0, height * 0.74),
      height * 0.06,
      Paint()..color = const Color(0xFF2A1A0E),
    );
    // Strings.
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(i * neckW * 0.16, 0),
        Offset(i * neckW * 0.3, height * 0.86),
        Paint()
          ..strokeWidth = 0.9
          ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.65),
      );
    }
    canvas.restore();
    ctx.noise.at(math.max(1, 1));
  }
}

/// One of the painted objects on the desk.
///
/// These lift and glow under the pointer because the desk should feel alive,
/// but there is nothing behind them to open. So they are scenery: no button
/// role, no click cursor, no place in the tab order. Announcing them as
/// buttons and doing nothing was worse than leaving them quiet — a screen
/// reader counted six controls that could not be activated, and the cursor
/// promised a page that does not exist.
class _Artifact extends StatefulWidget {
  const _Artifact({required this.label, required this.tooltip});

  final String label;
  final String tooltip;

  @override
  State<_Artifact> createState() => _ArtifactState();
}

class _ArtifactState extends State<_Artifact> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.label,
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 380),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: _lift(context, _hovered),
        ),
      ),
    );
  }

  Widget _lift(BuildContext context, bool active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        curve: T.eOut,
        transform: Matrix4.translationValues(0, active ? -6 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.rSm),
          border: Border.all(
            color: active ? T.lampGlow.withValues(alpha: 0.8) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: T.lampGlow.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      );
}

class _Back extends StatelessWidget {
  const _Back({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: 'Back to the journey map',
      tooltip: 'Back to the map',
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: active ? 0.5 : 0.3),
          borderRadius: BorderRadius.circular(T.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 14, color: Colors.white),
            const SizedBox(width: T.s6),
            Text('The map', style: Type.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
