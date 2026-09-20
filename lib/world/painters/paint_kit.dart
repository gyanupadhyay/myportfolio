import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Deterministic value noise + fractal brownian motion.
///
/// Every piece of scenery in this app is generated from a seed rather than
/// random-at-runtime, so a scene paints identically on every frame and golden
/// tests stay stable.
class Noise {
  const Noise(this.seed);

  final int seed;

  double _hash(int x) {
    var h = x * 374761393 + seed * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7fffffff) / 0x7fffffff;
  }

  double _hash2(int x, int y) => _hash(x * 73856093 ^ y * 19349663);

  static double _smooth(double t) => t * t * (3 - 2 * t);

  /// 1D value noise in 0–1.
  double value(double x) {
    final i = x.floor();
    final f = _smooth(x - i);
    return _hash(i) * (1 - f) + _hash(i + 1) * f;
  }

  /// 2D value noise in 0–1.
  double value2(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = _smooth(x - ix);
    final fy = _smooth(y - iy);
    final a = _hash2(ix, iy);
    final b = _hash2(ix + 1, iy);
    final c = _hash2(ix, iy + 1);
    final d = _hash2(ix + 1, iy + 1);
    final top = a * (1 - fx) + b * fx;
    final bottom = c * (1 - fx) + d * fx;
    return top * (1 - fy) + bottom * fy;
  }

  /// Layered noise. [octaves] controls detail, [gain] how fast it decays.
  double fbm(double x, {int octaves = 4, double gain = 0.5, double lacunarity = 2.0}) {
    var sum = 0.0;
    var amp = 1.0;
    var freq = 1.0;
    var norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += value(x * freq) * amp;
      norm += amp;
      amp *= gain;
      freq *= lacunarity;
    }
    return sum / norm;
  }

  double fbm2(double x, double y, {int octaves = 4, double gain = 0.5}) {
    var sum = 0.0;
    var amp = 1.0;
    var freq = 1.0;
    var norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += value2(x * freq, y * freq) * amp;
      norm += amp;
      amp *= gain;
      freq *= 2.0;
    }
    return sum / norm;
  }

  /// Ridged noise — sharp peaks, good for mountain silhouettes.
  double ridge(double x, {int octaves = 4}) {
    var sum = 0.0;
    var amp = 1.0;
    var freq = 1.0;
    var norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      final n = 1.0 - (value(x * freq) * 2 - 1).abs();
      sum += n * n * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2.0;
    }
    return sum / norm;
  }

  /// A stable pseudo-random in 0–1 for index [i].
  double at(int i) => _hash(i);

  /// A stable pseudo-random in [min]–[max] for index [i].
  double range(int i, double min, double max) => min + _hash(i) * (max - min);
}

/// Shared drawing helpers used by the scene painters.
abstract final class Kit {
  /// Vertical gradient fill over [rect].
  static void gradientRect(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    List<double>? stops,
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          stops: stops,
          begin: begin,
          end: end,
        ).createShader(rect),
    );
  }

  /// Soft radial glow — the sun, lamps, the green node halo.
  static void glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double intensity = 1.0,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: color.a * intensity),
            color.withValues(alpha: color.a * intensity * 0.35),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// Builds a closed silhouette from a top profile function.
  ///
  /// [profile] receives x in 0–1 and returns the surface height as a fraction
  /// of [rect].height measured from the top of the rect.
  static Path profilePath(
    Rect rect,
    double Function(double t) profile, {
    int samples = 140,
  }) {
    final path = Path()..moveTo(rect.left, rect.bottom);
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = rect.left + rect.width * t;
      final y = rect.top + rect.height * profile(t);
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path
      ..lineTo(rect.right, rect.bottom)
      ..close();
    return path;
  }

  /// A rounded, slightly irregular blob — cloud puffs, tree canopies, bushes.
  static Path blob(
    Offset center,
    double radius,
    Noise noise,
    int seed, {
    int points = 10,
    double wobble = 0.22,
  }) {
    final path = Path();
    final pts = <Offset>[];
    for (var i = 0; i < points; i++) {
      final a = i / points * math.pi * 2;
      final r = radius * (1 + (noise.at(seed * 97 + i) - 0.5) * 2 * wobble);
      pts.add(center + Offset(math.cos(a) * r, math.sin(a) * r));
    }
    path.moveTo(
      (pts[0].dx + pts[pts.length - 1].dx) / 2,
      (pts[0].dy + pts[pts.length - 1].dy) / 2,
    );
    for (var i = 0; i < pts.length; i++) {
      final cur = pts[i];
      final next = pts[(i + 1) % pts.length];
      path.quadraticBezierTo(
        cur.dx,
        cur.dy,
        (cur.dx + next.dx) / 2,
        (cur.dy + next.dy) / 2,
      );
    }
    path.close();
    return path;
  }

  /// Stylised cumulus: overlapping puffs with a lit crown and a soft,
  /// slightly flattened base — the shape these clouds read as in frame 01.
  static void cloud(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Noise noise,
    int seed, {
    Color top = const Color(0xFFFFFFFF),
    Color bottom = const Color(0xFFD5E2EE),
    double opacity = 1.0,
  }) {
    final puffs = 5 + (noise.at(seed) * 4).floor();
    final path = Path();

    for (var i = 0; i < puffs; i++) {
      final t = i / (puffs - 1);
      // Tallest through the middle of the cluster, tapering to the ends.
      final lift = math.sin(t * math.pi);
      final px = center.dx + (t - 0.5) * width;
      final py = center.dy - lift * height * 0.34;
      final pr = height * (0.3 + lift * 0.42) * noise.range(seed * 31 + i, 0.82, 1.18);
      // Circles, slightly squashed — cleaner than a wobbled blob at this size.
      path.addOval(Rect.fromCenter(
        center: Offset(px, py),
        width: pr * 2.2,
        height: pr * 1.75,
      ));
    }

    // A rounded shelf so the cluster sits on a base instead of floating.
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - width * 0.42,
        center.dy - height * 0.06,
        center.dx + width * 0.42,
        center.dy + height * 0.14,
      ),
      Radius.circular(height * 0.14),
    ));

    final bounds = Rect.fromCenter(
      center: center.translate(0, -height * 0.1),
      width: width * 1.3,
      height: height * 2.0,
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            top.withValues(alpha: top.a * opacity),
            Color.lerp(top, bottom, 0.5)!.withValues(alpha: opacity),
            bottom.withValues(alpha: bottom.a * opacity),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );
  }

  /// Conifer silhouette — the dominant tree in frames 01, 03, 10.
  static void conifer(
    Canvas canvas,
    Offset base,
    double height,
    Color color, {
    double widthFactor = 0.42,
    int tiers = 4,
  }) {
    final w = height * widthFactor;
    final paint = Paint()..color = color;
    // Trunk.
    canvas.drawRect(
      Rect.fromLTWH(base.dx - w * 0.06, base.dy - height * 0.18, w * 0.12, height * 0.18),
      Paint()..color = Color.lerp(color, const Color(0xFF3A2A1C), 0.45)!,
    );
    for (var i = 0; i < tiers; i++) {
      final t = i / tiers;
      final tierBase = base.dy - height * (0.12 + t * 0.7);
      final tierW = w * (1 - t * 0.55);
      final tierH = height * 0.34;
      final path = Path()
        ..moveTo(base.dx, tierBase - tierH)
        ..lineTo(base.dx - tierW / 2, tierBase)
        ..lineTo(base.dx + tierW / 2, tierBase)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  /// Rounded broadleaf tree.
  static void broadleaf(
    Canvas canvas,
    Offset base,
    double height,
    Color color,
    Noise noise,
    int seed,
  ) {
    final trunkH = height * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(base.dx - height * 0.035, base.dy - trunkH, height * 0.07, trunkH),
      Paint()..color = Color.lerp(color, const Color(0xFF3A2A1C), 0.5)!,
    );
    final canopy = Offset(base.dx, base.dy - height * 0.62);
    canvas.drawPath(
      blob(canopy, height * 0.36, noise, seed, points: 12, wobble: 0.2),
      Paint()..color = color,
    );
    canvas.drawPath(
      blob(canopy.translate(-height * 0.08, -height * 0.08), height * 0.22, noise, seed + 7,
          points: 10, wobble: 0.2),
      Paint()..color = Color.lerp(color, Colors.white, 0.12)!,
    );
  }

  /// A band of trees along a ridge — used for forest edges.
  static void treeLine(
    Canvas canvas,
    Rect rect,
    double Function(double t) profile,
    Color color,
    Noise noise,
    int seed, {
    int count = 30,
    double scale = 1.0,
  }) {
    for (var i = 0; i < count; i++) {
      final t = (i + noise.range(seed + i, 0.15, 0.85)) / count;
      if (t > 1) continue;
      final x = rect.left + rect.width * t;
      final y = rect.top + rect.height * profile(t);
      final h = rect.height * noise.range(seed * 3 + i, 0.16, 0.3) * scale;
      final shade = Color.lerp(color, Colors.black, noise.range(seed * 5 + i, 0, 0.18))!;
      if (noise.at(seed * 11 + i) > 0.35) {
        conifer(canvas, Offset(x, y + h * 0.1), h, shade);
      } else {
        broadleaf(canvas, Offset(x, y + h * 0.1), h * 0.8, shade, noise, seed * 17 + i);
      }
    }
  }

  /// Horizontal shimmer bands over water.
  static void waterShimmer(
    Canvas canvas,
    Rect rect,
    Noise noise,
    int seed,
    double phase, {
    Color color = Colors.white,
  }) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rows = 16;
    for (var r = 0; r < rows; r++) {
      final t = r / rows;
      final y = rect.top + rect.height * t;
      // Shimmer concentrates near the far shore and fades toward the viewer.
      final strength = (1 - t) * 0.5 + 0.1;
      final count = 3 + (noise.at(seed + r) * 4).floor();
      for (var i = 0; i < count; i++) {
        final base = noise.range(seed * 29 + r * 13 + i, 0.0, 1.0);
        final drift = (base + phase * (0.06 + t * 0.08)) % 1.0;
        final w = rect.width * noise.range(seed * 7 + r * 5 + i, 0.02, 0.09) * (0.5 + t);
        final x = rect.left + rect.width * drift;
        paint.color = color.withValues(alpha: 0.14 * strength);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, rect.height * 0.012 + 0.6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  /// Wood plank with grain and a routed bevel — signposts, desks, shelves.
  static void plank(
    Canvas canvas,
    RRect rrect,
    Noise noise,
    int seed, {
    Color base = const Color(0xFF8B6239),
    Color dark = const Color(0xFF5E4024),
    Color light = const Color(0xFFA97C4C),
  }) {
    canvas.save();
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rrect.outerRect),
    );
    canvas.clipRRect(rrect);
    // Grain.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final lines = (rrect.height / 4).clamp(3, 14).floor();
    for (var i = 0; i < lines; i++) {
      final y = rrect.top + rrect.height * (i + 0.5) / lines;
      final path = Path()..moveTo(rrect.left, y);
      for (var x = 0.0; x <= rrect.width; x += 6) {
        final n = noise.value2(x * 0.05 + seed, i * 1.7 + seed);
        path.lineTo(rrect.left + x, y + (n - 0.5) * 3.2);
      }
      grain.color = dark.withValues(alpha: 0.18 + noise.at(seed + i) * 0.14);
      canvas.drawPath(path, grain);
    }
    canvas.restore();
    // Bevel highlight.
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = light.withValues(alpha: 0.35),
    );
  }

  /// Paper texture with a torn edge — the parchment panels in frames 07, 11.
  static Path tornRect(Rect rect, Noise noise, int seed, {double depth = 5}) {
    final path = Path();
    const step = 12.0;
    path.moveTo(rect.left, rect.top);
    for (var x = rect.left; x < rect.right; x += step) {
      final n = noise.value2(x * 0.03, seed.toDouble());
      path.lineTo(x, rect.top + (n - 0.5) * depth);
    }
    path.lineTo(rect.right, rect.top);
    for (var y = rect.top; y < rect.bottom; y += step) {
      final n = noise.value2(y * 0.03, seed + 11.0);
      path.lineTo(rect.right + (n - 0.5) * depth, y);
    }
    path.lineTo(rect.right, rect.bottom);
    for (var x = rect.right; x > rect.left; x -= step) {
      final n = noise.value2(x * 0.03, seed + 23.0);
      path.lineTo(x, rect.bottom + (n - 0.5) * depth);
    }
    path.lineTo(rect.left, rect.bottom);
    for (var y = rect.bottom; y > rect.top; y -= step) {
      final n = noise.value2(y * 0.03, seed + 37.0);
      path.lineTo(rect.left + (n - 0.5) * depth, y);
    }
    path.close();
    return path;
  }

  /// Breaks a ruler-smooth silhouette with fine noise so edges read as
  /// painted rather than plotted. Wrap any profile function with this.
  static double Function(double t) paintedEdge(
    double Function(double t) profile,
    Noise noise,
    int seed, {
    double amount = 0.012,
    double frequency = 34,
  }) {
    return (t) =>
        profile(t) +
        (noise.value(t * frequency + seed * 1.7) - 0.5) * amount +
        (noise.value(t * frequency * 3.1 + seed * 0.9) - 0.5) * amount * 0.45;
  }

  /// Translucent colour washes laid over a shape, the way a glaze builds up
  /// depth in gouache. Cheap: two or three large soft-edged strokes.
  static void glaze(
    Canvas canvas,
    Rect rect,
    Noise noise,
    int seed,
    List<Color> washes, {
    double opacity = 0.14,
  }) {
    for (var i = 0; i < washes.length; i++) {
      final cx = rect.left + rect.width * noise.range(seed * 17 + i, 0.15, 0.85);
      final cy = rect.top + rect.height * noise.range(seed * 29 + i, 0.1, 0.9);
      final r = rect.longestSide * noise.range(seed * 41 + i, 0.3, 0.62);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = washes[i].withValues(alpha: opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55),
      );
    }
  }

  /// Directional brush texture — faint elongated strokes following the light.
  static void brushwork(
    Canvas canvas,
    Rect rect,
    Noise noise,
    int seed, {
    double angle = -0.4,
    int strokes = 48,
    double opacity = 0.05,
    Color color = Colors.white,
  }) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < strokes; i++) {
      final x = rect.left + noise.at(seed * 13 + i) * rect.width;
      final y = rect.top + noise.at(seed * 31 + i) * rect.height;
      final len = rect.shortestSide * noise.range(seed * 7 + i, 0.06, 0.22);
      paint
        ..strokeWidth = noise.range(seed * 11 + i, 1.5, 5.0)
        ..color = color.withValues(alpha: opacity * noise.range(seed * 5 + i, 0.4, 1.0));
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        paint,
      );
    }
  }

  /// Fine grain overlay that keeps large flat fills from looking like vector
  /// art. Cheap: a handful of translucent dots per call.
  static void grain(Canvas canvas, Rect rect, Noise noise, int seed, {double opacity = 0.03}) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
    final count = (rect.width * rect.height / 900).clamp(0, 900).floor();
    for (var i = 0; i < count; i++) {
      final x = rect.left + noise.at(seed * 3 + i * 2) * rect.width;
      final y = rect.top + noise.at(seed * 5 + i * 2 + 1) * rect.height;
      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  /// Draws text into a canvas at [offset] with optional rotation.
  static void text(
    Canvas canvas,
    String value,
    Offset offset,
    TextStyle style, {
    double maxWidth = double.infinity,
    TextAlign align = TextAlign.left,
    double rotation = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    if (rotation == 0) {
      painter.paint(canvas, offset);
      return;
    }
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Blurs whatever [draw] paints — used for depth-of-field on far layers.
  static void blurred(Canvas canvas, Rect bounds, double sigma, VoidCallback draw) {
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
    draw();
    canvas.restore();
  }

  /// Atmospheric perspective: fades distant geometry toward the haze colour.
  static Color haze(Color color, Color hazeColor, double amount) =>
      Color.lerp(color, hazeColor, amount.clamp(0.0, 1.0))!;
}
