import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import '../world/painters/paint_kit.dart';

/// The dark translucent card used in frames 05, 06, 08 and 09.
///
/// Blur is real (`BackdropFilter`) so the painted scene shows through the way
/// it does in the reference frames.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(T.s20),
    this.radius = T.rMd,
    this.blur = 14,
    this.tint,
    this.borderColor,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? borderColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? palette.panel,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? palette.panelBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Aged paper with a torn edge — frames 07 and 11.
class ParchmentPanel extends StatelessWidget {
  const ParchmentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(T.s24),
    this.seed = 3,
    this.width,
    this.rotation = 0,
  });

  final Widget child;
  final EdgeInsets padding;
  final int seed;
  final double? width;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        painter: _ParchmentPainter(seed),
        child: Container(
          width: width,
          padding: padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: T.ink),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  _ParchmentPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final noise = Noise(seed);
    final rect = Offset.zero & size;
    final path = Kit.tornRect(rect.deflate(3), noise, seed, depth: 6);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFBF5E7),
            T.parchment,
            T.parchmentEdge,
          ],
        ).createShader(rect),
    );

    // Fibre speckle so the paper does not read as flat cream.
    canvas.save();
    canvas.clipPath(path);
    Kit.grain(canvas, rect, noise, seed * 7, opacity: 0.035);
    // A soft fold shadow down one third.
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.33, 0, 2, size.height),
      Paint()
        ..color = const Color(0xFFBCA87F).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ParchmentPainter oldDelegate) => oldDelegate.seed != seed;
}

/// A soft scrim placed under copy that sits directly on painted art, so text
/// keeps its contrast ratio without a hard-edged box.
class TextScrim extends StatelessWidget {
  const TextScrim({
    super.key,
    required this.child,
    this.strength = 0.42,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
  });

  final Widget child;
  final double strength;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            Colors.black.withValues(alpha: strength),
            Colors.black.withValues(alpha: strength * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
