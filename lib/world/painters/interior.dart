import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'landscape.dart';
import 'paint_kit.dart';

/// Interior scenery for frames 02 (the workshop) and 05–08 (the night desk).
///
/// Everything is drawn in normalised scene coordinates so the same props can
/// be re-lit and re-staged per frame.
abstract final class Interior {
  // ------------------------------------------------------------------ room

  /// Timber wall with visible planks and a warm falloff from the key light.
  static ScenePaint wall({
    required int seed,
    Color base = const Color(0xFF6B4E32),
    Color dark = const Color(0xFF3E2C1B),
    int planks = 9,
    bool vertical = false,
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final rect = Offset.zero & size;
      Kit.gradientRect(canvas, rect, [
        Color.lerp(base, Colors.white, 0.06)!,
        base,
        dark,
      ]);

      final seam = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      for (var i = 1; i < planks; i++) {
        final t = i / planks;
        seam.color = dark.withValues(alpha: 0.35 + n.at(seed + i) * 0.2);
        if (vertical) {
          canvas.drawLine(
            Offset(size.width * t, 0),
            Offset(size.width * t, size.height),
            seam,
          );
        } else {
          canvas.drawLine(
            Offset(0, size.height * t),
            Offset(size.width, size.height * t),
            seam,
          );
        }
        // Grain within each plank.
        for (var g = 0; g < 3; g++) {
          final gy = size.height * (t + (g + 1) / (planks * 4));
          final path = Path()..moveTo(0, gy);
          for (var x = 0.0; x < size.width; x += 18) {
            path.lineTo(x, gy + (n.value2(x * 0.02, i * 3.0 + g) - 0.5) * 4);
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = dark.withValues(alpha: 0.14),
          );
        }
      }

      // Light falls off from the key direction.
      final key = Offset(
        size.width * ctx.palette.sunPosition.dx,
        size.height * ctx.palette.sunPosition.dy,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(
              ctx.palette.sunPosition.dx * 2 - 1,
              ctx.palette.sunPosition.dy * 2 - 1,
            ),
            radius: 0.9,
            colors: [
              ctx.palette.sunColor.withValues(alpha: 0.22),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.42),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(rect),
      );
      Kit.grain(canvas, rect, n, seed * 3, opacity: 0.03);
      key.dx;
    };
  }

  /// A window with a painted view and a cross of mullions.
  ///
  /// [view] paints whatever is outside, clipped to the opening.
  static ScenePaint window({
    required Rect Function(Size size) bounds,
    required List<ScenePaint> view,
    int columns = 2,
    int rows = 2,
    Color frame = const Color(0xFF5A4028),
    double glare = 0.18,
  }) {
    return (canvas, size, ctx) {
      final rect = bounds(size);
      final radius = Radius.circular(rect.width * 0.01);

      // Outer casing.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(rect.width * 0.035), radius),
        Paint()..color = frame,
      );

      // The view beyond, painted into the opening's own coordinate space.
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));
      canvas.translate(rect.left, rect.top);
      for (final p in view) {
        p(canvas, rect.size, ctx);
      }
      canvas.restore();

      // Glass sheen.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: glare),
              Colors.transparent,
              Colors.white.withValues(alpha: glare * 0.4),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );

      // Mullions.
      final bar = Paint()..color = frame;
      final t = rect.width * 0.012;
      for (var c = 1; c < columns; c++) {
        final x = rect.left + rect.width * c / columns;
        canvas.drawRect(Rect.fromLTWH(x - t / 2, rect.top, t, rect.height), bar);
      }
      for (var r = 1; r < rows; r++) {
        final y = rect.top + rect.height * r / rows;
        canvas.drawRect(Rect.fromLTWH(rect.left, y - t / 2, rect.width, t), bar);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = t * 1.2
          ..color = frame,
      );
    };
  }

  /// Warm light spilling from a window or lamp into the room.
  static ScenePaint lightShaft({
    required Offset Function(Size size) from,
    required double width,
    required double angle,
    Color? color,
    double opacity = 0.16,
    double flicker = 0,
  }) {
    return (canvas, size, ctx) {
      final origin = from(size);
      final len = size.height * 1.6;
      final tint = color ?? ctx.palette.sunColor;
      final wobble = flicker == 0
          ? 1.0
          : 1.0 + math.sin(ctx.time * flicker) * 0.06;

      final path = Path()
        ..moveTo(origin.dx - width / 2, origin.dy)
        ..lineTo(origin.dx + width / 2, origin.dy)
        ..lineTo(
          origin.dx + width * 1.5 + math.cos(angle) * len,
          origin.dy + math.sin(angle) * len,
        )
        ..lineTo(
          origin.dx - width * 1.2 + math.cos(angle) * len,
          origin.dy + math.sin(angle) * len,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tint.withValues(alpha: opacity * wobble),
              tint.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, origin.dy, size.width, len))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    };
  }

  // ------------------------------------------------------------------ desk

  /// A wooden desk surface running across the lower part of the frame.
  static ScenePaint desk({
    required int seed,
    double top = 0.74,
    Color base = const Color(0xFF7A5333),
    Color dark = const Color(0xFF412916),
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final rect = Rect.fromLTRB(0, size.height * top, size.width, size.height);
      // Front edge catches the key light.
      Kit.gradientRect(canvas, rect, [
        Color.lerp(base, ctx.palette.sunColor, 0.22)!,
        base,
        Color.lerp(base, Colors.black, 0.5)!,
      ], stops: const [0.0, 0.18, 1.0]);

      canvas.save();
      canvas.clipRect(rect);
      for (var i = 0; i < 12; i++) {
        final y = rect.top + rect.height * n.at(seed * 5 + i);
        final path = Path()..moveTo(0, y);
        for (var x = 0.0; x < size.width; x += 22) {
          path.lineTo(x, y + (n.value2(x * 0.012, i * 2.0) - 0.5) * 6);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.black.withValues(alpha: 0.1),
        );
      }
      canvas.restore();
      dark.a;
    };
  }

  /// An open laptop, three-quarter view, screen glowing.
  static void laptop(
    Canvas canvas,
    Rect bounds,
    ScenePaintContext ctx, {
    Color shell = const Color(0xFF9AA3AC),
    Color screen = const Color(0xFF16324A),
    bool glow = true,
  }) {
    final lidH = bounds.height * 0.74;
    final lid = Rect.fromLTWH(bounds.left, bounds.top, bounds.width, lidH);

    // Screen glow spilling onto the desk.
    if (glow) {
      Kit.glow(
        canvas,
        lid.center.translate(0, lid.height * 0.4),
        bounds.width * 0.9,
        const Color(0xFF7FC4FF),
        intensity: 0.22,
      );
    }

    // Lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(3)),
      Paint()..color = shell,
    );
    final panel = lid.deflate(lid.width * 0.025);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(screen, Colors.white, 0.18)!,
            screen,
            Color.lerp(screen, Colors.black, 0.25)!,
          ],
        ).createShader(panel),
    );

    // Lines of code on the screen.
    final line = Paint()..strokeWidth = 1.4..strokeCap = StrokeCap.round;
    final rows = (panel.height / 5).floor().clamp(3, 16);
    for (var i = 0; i < rows; i++) {
      final y = panel.top + 4 + i * (panel.height - 8) / rows;
      final w = panel.width * ctx.noise.range(i * 13 + 5, 0.18, 0.78);
      line.color = [
        const Color(0xFF7FC4FF),
        const Color(0xFF9DE8B4),
        const Color(0xFFE8C97F),
        const Color(0xFFCBA9F5),
      ][i % 4]
          .withValues(alpha: 0.72);
      canvas.drawLine(
        Offset(panel.left + 4 + panel.width * 0.05 * (i % 3), y),
        Offset(panel.left + 4 + w, y),
        line,
      );
    }

    // Base and keyboard.
    final base = Rect.fromLTWH(
      bounds.left - bounds.width * 0.06,
      bounds.top + lidH,
      bounds.width * 1.12,
      bounds.height * 0.26,
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.left, base.bottom)
        ..lineTo(base.left + base.width * 0.06, base.top)
        ..lineTo(base.right - base.width * 0.06, base.top)
        ..lineTo(base.right, base.bottom)
        ..close(),
      Paint()..color = Color.lerp(shell, Colors.white, 0.12)!,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        base.left + base.width * 0.12,
        base.top + base.height * 0.25,
        base.width * 0.76,
        base.height * 0.4,
      ),
      Paint()..color = Color.lerp(shell, Colors.black, 0.32)!,
    );
  }

  /// A desktop monitor showing a code editor — frames 07 and 08.
  static void monitor(
    Canvas canvas,
    Rect bounds,
    ScenePaintContext ctx, {
    Color bezel = const Color(0xFF23262B),
  }) {
    Kit.glow(canvas, bounds.center, bounds.width * 0.8,
        const Color(0xFF6FB6FF), intensity: 0.2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(4)),
      Paint()..color = bezel,
    );
    final panel = bounds.deflate(bounds.width * 0.018);
    canvas.drawRect(panel, Paint()..color = const Color(0xFF0E1726));

    // Editor gutter.
    canvas.drawRect(
      Rect.fromLTWH(panel.left, panel.top, panel.width * 0.07, panel.height),
      Paint()..color = const Color(0xFF152134),
    );

    final line = Paint()..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final rows = (panel.height / 6).floor().clamp(4, 26);
    for (var i = 0; i < rows; i++) {
      final y = panel.top + 5 + i * (panel.height - 10) / rows;
      final indent = ctx.noise.range(i * 7 + 3, 0.0, 0.16);
      final w = panel.width * ctx.noise.range(i * 11 + 9, 0.2, 0.82);
      line.color = [
        const Color(0xFF7FC4FF),
        const Color(0xFF9DE8B4),
        const Color(0xFFE8C97F),
        const Color(0xFFCBA9F5),
        const Color(0xFF8FA3B8),
      ][i % 5]
          .withValues(alpha: 0.8);
      canvas.drawLine(
        Offset(panel.left + panel.width * (0.1 + indent), y),
        Offset(panel.left + panel.width * (0.1 + indent) + w * 0.7, y),
        line,
      );
    }

    // Stand.
    canvas.drawRect(
      Rect.fromLTWH(
        bounds.center.dx - bounds.width * 0.05,
        bounds.bottom,
        bounds.width * 0.1,
        bounds.height * 0.14,
      ),
      Paint()..color = bezel,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bounds.center.dx - bounds.width * 0.18,
          bounds.bottom + bounds.height * 0.13,
          bounds.width * 0.36,
          bounds.height * 0.035,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = bezel,
    );
  }

  /// A whiteboard or pinned note sheet with handwritten lines.
  static void board(
    Canvas canvas,
    Rect bounds,
    List<String> lines,
    ScenePaintContext ctx, {
    Color surface = const Color(0xFFF2F0E6),
    Color inkColor = const Color(0xFF3A4A5A),
    TextStyle? style,
    String? title,
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.translate(2, 4), const Radius.circular(3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3)),
      Paint()..color = surface,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF7A6A52),
    );

    final textStyle = style ??
        TextStyle(fontFamily: 'Caveat', fontSize: bounds.height * 0.11, color: inkColor);
    var y = bounds.top + bounds.height * 0.1;
    if (title != null) {
      Kit.text(canvas, title, Offset(bounds.left + bounds.width * 0.08, y),
          textStyle.copyWith(fontWeight: FontWeight.w700));
      y += textStyle.fontSize! * 1.5;
    }
    for (final line in lines) {
      Kit.text(canvas, '• $line', Offset(bounds.left + bounds.width * 0.08, y),
          textStyle);
      y += textStyle.fontSize! * 1.35;
    }

    canvas.restore();
    ctx.noise.at(2);
  }

  /// A potted plant — the workshop is full of them.
  static void plant(
    Canvas canvas,
    Offset base,
    double height,
    ScenePaintContext ctx,
    int seed, {
    Color pot = const Color(0xFFB4714A),
    Color leaf = const Color(0xFF4E7A52),
  }) {
    final n = ctx.noise;
    final potH = height * 0.32;
    final potW = height * 0.36;

    // Leaves fan out from the rim.
    for (var i = 0; i < 11; i++) {
      final a = -math.pi / 2 + n.range(seed * 31 + i, -1.15, 1.15);
      final len = height * n.range(seed * 17 + i, 0.5, 0.86);
      final tip = base + Offset(math.cos(a) * len, math.sin(a) * len - potH * 0.6);
      final mid = base +
          Offset(math.cos(a) * len * 0.5 - math.sin(a) * len * 0.18,
              math.sin(a) * len * 0.5 - potH * 0.6);
      final shade = Color.lerp(leaf, Colors.black, n.range(seed * 7 + i, 0, 0.3))!;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - potH * 0.6)
          ..quadraticBezierTo(mid.dx - len * 0.1, mid.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(mid.dx + len * 0.1, mid.dy, base.dx, base.dy - potH * 0.6)
          ..close(),
        Paint()..color = shade,
      );
    }

    // Pot.
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - potW / 2, base.dy - potH)
        ..lineTo(base.dx + potW / 2, base.dy - potH)
        ..lineTo(base.dx + potW * 0.38, base.dy)
        ..lineTo(base.dx - potW * 0.38, base.dy)
        ..close(),
      Paint()..color = pot,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx - potW * 0.54, base.dy - potH - height * 0.04,
          potW * 1.08, height * 0.055),
      Paint()..color = Color.lerp(pot, Colors.white, 0.12)!,
    );
  }

  /// A stack of books, spines out.
  static void books(
    Canvas canvas,
    Offset base,
    double width,
    int count,
    ScenePaintContext ctx,
    int seed,
  ) {
    final n = ctx.noise;
    const palette = [
      Color(0xFF8C4A3C),
      Color(0xFF3E5C76),
      Color(0xFF6B7F4E),
      Color(0xFFB07A3C),
      Color(0xFF574166),
    ];
    var y = base.dy;
    for (var i = 0; i < count; i++) {
      final h = width * n.range(seed * 13 + i, 0.16, 0.26);
      final w = width * n.range(seed * 29 + i, 0.82, 1.0);
      final rect = Rect.fromLTWH(base.dx - w / 2, y - h, w, h);
      canvas.drawRect(
        rect,
        Paint()..color = palette[(n.at(seed * 5 + i) * palette.length).floor() % palette.length],
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, h * 0.18),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
      y -= h + 1;
    }
  }

  /// A mug, optionally with text printed on it.
  static void mug(
    Canvas canvas,
    Offset base,
    double height,
    ScenePaintContext ctx, {
    Color color = const Color(0xFF2A2724),
    List<String> label = const [],
  }) {
    final w = height * 0.82;
    final body = Rect.fromLTWH(base.dx - w / 2, base.dy - height, w, height);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        body,
        bottomLeft: Radius.circular(w * 0.18),
        bottomRight: Radius.circular(w * 0.18),
      ),
      Paint()..color = color,
    );
    // Handle.
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(body.right + w * 0.04, body.center.dy),
        radius: w * 0.26,
      ),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..color = color,
    );
    // Rim.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(body.center.dx, body.top), width: w, height: w * 0.26),
      Paint()..color = Color.lerp(color, Colors.white, 0.22)!,
    );

    if (label.isNotEmpty) {
      var y = body.top + height * 0.22;
      for (final line in label) {
        Kit.text(
          canvas,
          line,
          Offset(body.left, y),
          TextStyle(
            fontFamily: 'Caveat',
            fontSize: height * 0.15,
            color: const Color(0xFFE8DCC8),
          ),
          maxWidth: w,
          align: TextAlign.center,
        );
        y += height * 0.17;
      }
    }
    ctx.noise.at(3);
  }

  /// A desk lamp casting a cone of warm light — frame 05.
  static void deskLamp(
    Canvas canvas,
    Offset head,
    double scale,
    ScenePaintContext ctx, {
    Color shade = const Color(0xFF2E3136),
  }) {
    final shadeW = 54.0 * scale;
    final shadeH = 30.0 * scale;

    // Cone of light below the bulb.
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - shadeW * 0.42, head.dy + shadeH * 0.5)
        ..lineTo(head.dx + shadeW * 0.42, head.dy + shadeH * 0.5)
        ..lineTo(head.dx + shadeW * 2.6, head.dy + shadeH * 11)
        ..lineTo(head.dx - shadeW * 2.6, head.dy + shadeH * 11)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            T.lampGlow.withValues(alpha: 0.3),
            T.lampGlow.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
          head.dx - shadeW * 2.6,
          head.dy,
          shadeW * 5.2,
          shadeH * 11,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Shade.
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - shadeW * 0.22, head.dy - shadeH * 0.5)
        ..lineTo(head.dx + shadeW * 0.22, head.dy - shadeH * 0.5)
        ..lineTo(head.dx + shadeW * 0.5, head.dy + shadeH * 0.5)
        ..lineTo(head.dx - shadeW * 0.5, head.dy + shadeH * 0.5)
        ..close(),
      Paint()..color = shade,
    );
    // Bulb.
    Kit.glow(canvas, head.translate(0, shadeH * 0.5), shadeW * 1.1, T.lampGlow,
        intensity: 0.8);
    canvas.drawCircle(
      head.translate(0, shadeH * 0.42),
      shadeW * 0.14,
      Paint()..color = const Color(0xFFFFF0C8),
    );
    // Arm.
    canvas.drawLine(
      head.translate(0, -shadeH * 0.5),
      head.translate(shadeW * 0.5, -shadeH * 3.2),
      Paint()
        ..color = shade
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    ctx.noise.at(4);
  }

  /// A framed picture or poster on the wall.
  static void frame(
    Canvas canvas,
    Rect bounds, {
    Color frameColor = const Color(0xFF4A3520),
    required void Function(Canvas canvas, Rect inner) content,
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    canvas.drawRect(
      bounds.translate(2, 4),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRect(bounds, Paint()..color = frameColor);
    final inner = bounds.deflate(bounds.shortestSide * 0.06);
    canvas.save();
    canvas.clipRect(inner);
    content(canvas, inner);
    canvas.restore();
    canvas.restore();
  }

  /// Papers and sketches scattered on a surface.
  static void papers(
    Canvas canvas,
    Rect area,
    int count,
    ScenePaintContext ctx,
    int seed, {
    Color color = const Color(0xFFF3ECDC),
  }) {
    final n = ctx.noise;
    for (var i = 0; i < count; i++) {
      final w = area.width * n.range(seed * 13 + i, 0.2, 0.36);
      final h = w * n.range(seed * 29 + i, 0.6, 0.85);
      final x = area.left + n.at(seed * 7 + i) * (area.width - w);
      final y = area.top + n.at(seed * 11 + i) * (area.height - h);
      final rect = Rect.fromLTWH(x, y, w, h);

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(n.range(seed * 23 + i, -0.25, 0.25));
      canvas.translate(-rect.center.dx, -rect.center.dy);

      canvas.drawRect(
        rect.translate(1, 3),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRect(rect, Paint()..color = color);
      // Ruled marks so they read as written-on.
      final rule = Paint()
        ..strokeWidth = 1
        ..color = const Color(0xFF9AA3AE).withValues(alpha: 0.6);
      final rows = (h / 6).floor().clamp(2, 8);
      for (var r = 0; r < rows; r++) {
        final ry = rect.top + h * (r + 1) / (rows + 1);
        canvas.drawLine(
          Offset(rect.left + w * 0.12, ry),
          Offset(rect.left + w * n.range(seed * 31 + i * 7 + r, 0.4, 0.88), ry),
          rule,
        );
      }
      canvas.restore();
    }
  }

  /// A polaroid-style photo with a painted scene inside — frame 11.
  static void polaroid(
    Canvas canvas,
    Rect bounds,
    ScenePaintContext ctx, {
    required void Function(Canvas canvas, Rect inner) content,
    String? caption,
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    canvas.drawRect(
      bounds.translate(2, 5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFFBF7EE));

    final pad = bounds.width * 0.055;
    final inner = Rect.fromLTWH(
      bounds.left + pad,
      bounds.top + pad,
      bounds.width - pad * 2,
      bounds.height - pad * 2 - bounds.height * 0.16,
    );
    canvas.save();
    canvas.clipRect(inner);
    content(canvas, inner);
    canvas.restore();

    if (caption != null) {
      Kit.text(
        canvas,
        caption,
        Offset(bounds.left + pad, inner.bottom + pad * 0.6),
        TextStyle(
          fontFamily: 'Caveat',
          fontSize: bounds.height * 0.1,
          color: const Color(0xFF5A4A3A),
        ),
        maxWidth: inner.width,
        align: TextAlign.center,
      );
    }
    canvas.restore();
    ctx.noise.at(5);
  }
}
