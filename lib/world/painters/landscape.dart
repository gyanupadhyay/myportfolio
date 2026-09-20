import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import 'paint_kit.dart';

/// Everything a layer needs to paint itself.
@immutable
class ScenePaintContext {
  const ScenePaintContext({
    required this.palette,
    required this.noise,
    required this.time,
    this.reveal = 1.0,
  });

  final LightingPalette palette;
  final Noise noise;

  /// Seconds since the scene mounted. Drives drift, shimmer and flicker.
  /// Frozen at 0 when the user prefers reduced motion.
  final double time;

  /// Entrance progress 0–1.
  final double reveal;
}

typedef ScenePaint = void Function(Canvas canvas, Size size, ScenePaintContext ctx);

/// The valley world shared by frames 01, 03, 09, 10 and 12.
///
/// Each function paints one depth layer; scenes stack them in
/// [ParallaxLayer]s so they move at different rates.
abstract final class Landscape {
  // ------------------------------------------------------------------- sky

  static void sky(Canvas canvas, Size size, ScenePaintContext ctx) {
    final p = ctx.palette;
    final rect = Offset.zero & size;
    Kit.gradientRect(
      canvas,
      rect,
      [p.skyTop, p.skyMid, p.skyBottom],
      stops: const [0.0, 0.52, 1.0],
    );

    // Key light.
    final sun = Offset(size.width * p.sunPosition.dx, size.height * p.sunPosition.dy);
    Kit.glow(canvas, sun, size.height * 0.55, p.sunColor, intensity: 0.34);
  }

  /// A visible sun disc with a warm corona — frames 09 and 12.
  static void sunDisc(Canvas canvas, Size size, ScenePaintContext ctx) {
    final p = ctx.palette;
    final sun = Offset(size.width * p.sunPosition.dx, size.height * p.sunPosition.dy);
    final r = size.height * 0.055;
    Kit.glow(canvas, sun, r * 9, p.sunColor, intensity: 0.5);
    Kit.glow(canvas, sun, r * 3.2, p.sunColor, intensity: 0.7);
    canvas.drawCircle(sun, r, Paint()..color = p.sunColor);
    canvas.drawCircle(
      sun,
      r * 1.5,
      Paint()
        ..color = p.sunColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  /// Drifting cumulus. [band] places the cluster vertically (0–1).
  static ScenePaint clouds({
    required int seed,
    double band = 0.18,
    double speed = 0.004,
    double scale = 1.0,
    double opacity = 1.0,
    int count = 5,
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      for (var i = 0; i < count; i++) {
        final base = n.range(seed * 41 + i, 0.0, 1.0);
        // Wrap with margin so clouds enter and leave cleanly.
        final x = ((base + ctx.time * speed * n.range(seed * 7 + i, 0.6, 1.4)) % 1.4) - 0.2;
        final y = band + (n.at(seed * 13 + i) - 0.5) * 0.12;
        final w = size.width * n.range(seed * 17 + i, 0.14, 0.26) * scale;
        final h = w * n.range(seed * 19 + i, 0.3, 0.46);
        Kit.cloud(
          canvas,
          Offset(size.width * x, size.height * y),
          w,
          h,
          n,
          seed * 3 + i,
          top: Color.lerp(Colors.white, ctx.palette.sunColor, 0.25)!,
          bottom: Color.lerp(const Color(0xFFD5E2EE), ctx.palette.haze, 0.45)!,
          opacity: opacity * (0.7 + n.at(seed * 23 + i) * 0.3),
        );
      }
    };
  }

  // ------------------------------------------------------------- mountains

  /// Snow-capped far range. [top]/[bottom] are fractions of scene height.
  static ScenePaint mountains({
    required int seed,
    double top = 0.24,
    double bottom = 0.62,
    double roughness = 3.0,
    double distance = 0.55,
    bool snow = true,
    Color? tint,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final n = ctx.noise;
      final rect = Rect.fromLTRB(
        -size.width * 0.05,
        size.height * top,
        size.width * 1.05,
        size.height * bottom,
      );

      final profile = Kit.paintedEdge(
        (t) {
          final r = n.ridge(t * roughness + seed * 0.37, octaves: 5);
          return (1 - r) * 0.72 + 0.06;
        },
        n,
        seed,
        amount: 0.022,
        frequency: 46,
      );

      final body = Kit.profilePath(rect, profile, samples: 300);
      final base = tint ?? T.mountainFar;
      final hazed = Kit.haze(base, p.haze, distance);
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Kit.haze(Color.lerp(hazed, Colors.white, 0.18)!, p.haze, distance * 0.5),
              hazed,
              Kit.haze(Color.lerp(base, Colors.black, 0.2)!, p.haze, distance),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );

      if (snow) {
        // Snow sits on the upper reaches only, so clip the body to a band
        // that follows the ridgeline.
        canvas.save();
        canvas.clipPath(body);
        for (var i = 0; i <= 260; i++) {
          final t = i / 260;
          final h = profile(t);
          if (h > 0.46) continue;
          final x = rect.left + rect.width * t;
          final y = rect.top + rect.height * h;
          final depth = (0.46 - h) / 0.46;
          final snowPath = Path()
            ..moveTo(x, y)
            ..lineTo(x + rect.width / 260, rect.top + rect.height * profile(t + 1 / 260))
            ..lineTo(x + rect.width / 260, y + rect.height * depth * 0.24)
            ..lineTo(x, y + rect.height * depth * 0.21)
            ..close();
          canvas.drawPath(
            snowPath,
            Paint()
              ..color = Kit.haze(T.mountainSnow, p.haze, distance * 0.35)
                  .withValues(alpha: (0.35 + 0.65 * depth).clamp(0.0, 1.0)),
          );
        }
        canvas.restore();
      }

      // Glazed rock so the face is not one flat fill.
      canvas.save();
      canvas.clipPath(body);
      Kit.glaze(canvas, rect, n, seed * 3, [
        Color.lerp(base, Colors.black, 0.35)!,
        Color.lerp(base, p.sunColor, 0.4)!,
        Color.lerp(base, p.haze, 0.5)!,
      ], opacity: 0.16);
      Kit.brushwork(canvas, rect, n, seed * 5,
          angle: -0.9, strokes: 40, opacity: 0.05);
      canvas.restore();

      // Sunlit face on the light side.
      canvas.save();
      canvas.clipPath(body);
      final lightDir = p.sunPosition.dx;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(lightDir * 2 - 1, -1),
            end: Alignment(1 - lightDir * 2, 1),
            colors: [
              p.sunColor.withValues(alpha: 0.16),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
          ).createShader(rect),
      );
      canvas.restore();
    };
  }

  // ------------------------------------------------------------------ hills

  /// Rolling forested hills. Softer profile than [mountains].
  ///
  /// [shape] biases the ridgeline as a fraction of the band height — negative
  /// lifts the land, positive drops it. That is what carves the bay in frame
  /// 01: the banks rise at the edges and the middle falls away to water.
  static ScenePaint hills({
    required int seed,
    double top = 0.52,
    double bottom = 0.78,
    double distance = 0.25,
    Color? color,
    bool trees = true,
    double amplitude = 0.5,
    double Function(double t)? shape,
    int treeCount = 34,
    double treeScale = 0.9,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final n = ctx.noise;
      final rect = Rect.fromLTRB(
        -size.width * 0.05,
        size.height * top,
        size.width * 1.05,
        size.height * bottom,
      );

      final profile = Kit.paintedEdge(
        (t) =>
            0.32 +
            (n.fbm(t * 2.2 + seed * 0.61, octaves: 3) - 0.5) * amplitude +
            (shape?.call(t) ?? 0),
        n,
        seed,
        amount: 0.03,
        frequency: 30,
      );

      final body = Kit.profilePath(rect, profile, samples: 220);
      final base = color ?? T.forestMid;
      final hazed = Kit.haze(base, p.haze, distance);
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(hazed, p.sunColor, 0.1)!,
              hazed,
              Color.lerp(hazed, Colors.black, 0.25)!,
            ],
          ).createShader(rect),
      );

      canvas.save();
      canvas.clipPath(body);
      Kit.glaze(canvas, rect, n, seed * 7, [
        Color.lerp(base, Colors.black, 0.4)!,
        Color.lerp(base, p.sunColor, 0.35)!,
      ], opacity: 0.15);
      canvas.restore();

      if (trees) {
        canvas.save();
        canvas.clipRect(rect.inflate(rect.height));
        Kit.treeLine(
          canvas,
          rect,
          profile,
          Kit.haze(Color.lerp(base, Colors.black, 0.22)!, p.haze, distance * 0.8),
          n,
          seed * 5,
          count: treeCount,
          scale: treeScale,
        );
        canvas.restore();
      }
    };
  }

  // ------------------------------------------------------------------ water

  /// The lake. Reflects the sky and carries an animated shimmer.
  static ScenePaint lake({
    required int seed,
    double top = 0.6,
    double bottom = 0.76,
    double inset = 0.0,
    double Function(double t)? shore,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final rect = Rect.fromLTRB(
        size.width * inset,
        size.height * top,
        size.width * (1 - inset),
        size.height * bottom,
      );

      // The far shore is an irregular edge, not a ruled line.
      final water = shore == null
          ? (Path()..addRect(rect))
          : Kit.profilePath(rect, shore, samples: 160);

      canvas.save();
      canvas.clipPath(water);
      // Water reflects the sky it sits under rather than being fixed blue.
      Kit.gradientRect(canvas, rect, [
        Color.lerp(p.skyBottom, T.waterHigh, 0.35)!,
        Color.lerp(T.waterHigh, p.skyMid, 0.35)!,
        Color.lerp(T.waterLow, p.skyTop, 0.28)!,
      ]);

      // A warm reflection column beneath the sun.
      final sunX = rect.left + rect.width * p.sunPosition.dx;
      canvas.drawRect(
        Rect.fromLTRB(sunX - rect.width * 0.09, rect.top, sunX + rect.width * 0.09, rect.bottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              p.sunColor.withValues(alpha: 0.5),
              p.sunColor.withValues(alpha: 0.05),
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      Kit.waterShimmer(canvas, rect, ctx.noise, seed, ctx.time);
      canvas.restore();

      // A pale rim where the water meets the land.
      if (shore != null) {
        canvas.drawPath(
          water,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Color.lerp(T.waterHigh, Colors.white, 0.55)!
                .withValues(alpha: 0.5),
        );
      }
    };
  }

  // ------------------------------------------------------------------- town

  /// The lakeside town in frame 01 — clustered roofs climbing a slope.
  static ScenePaint town({
    required int seed,
    required Rect Function(Size size) bounds,
    double distance = 0.3,
    int count = 42,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final n = ctx.noise;
      final rect = bounds(size);

      final roofs = <Color>[
        const Color(0xFFC96F52),
        const Color(0xFFB85A46),
        const Color(0xFFD98A63),
        const Color(0xFF9C5340),
      ];

      for (var i = 0; i < count; i++) {
        final tx = n.at(seed * 31 + i);
        final ty = n.at(seed * 53 + i);
        // Buildings get smaller and hazier toward the back of the cluster.
        final depth = ty;
        final w = rect.width * n.range(seed * 11 + i, 0.013, 0.032) * (1.1 - depth * 0.35);
        final h = w * n.range(seed * 17 + i, 0.75, 1.3);
        final x = rect.left + rect.width * tx;
        final y = rect.top + rect.height * (0.25 + ty * 0.7);

        final wallBase = Color.lerp(
          const Color(0xFFF3E4CE),
          const Color(0xFFDCC7AA),
          n.at(seed * 19 + i),
        )!;
        final wall = Kit.haze(wallBase, p.haze, distance + depth * 0.2);
        final roof = Kit.haze(
          roofs[(n.at(seed * 23 + i) * roofs.length).floor() % roofs.length],
          p.haze,
          distance + depth * 0.2,
        );

        // Wall.
        canvas.drawRect(Rect.fromLTWH(x, y - h, w, h), Paint()..color = wall);
        canvas.drawRect(
          Rect.fromLTWH(x + w * 0.62, y - h, w * 0.38, h),
          Paint()..color = Color.lerp(wall, Colors.black, 0.12)!,
        );
        // Roof.
        final roofH = h * 0.36;
        canvas.drawPath(
          Path()
            ..moveTo(x - w * 0.09, y - h)
            ..lineTo(x + w / 2, y - h - roofH)
            ..lineTo(x + w * 1.09, y - h)
            ..close(),
          Paint()..color = roof,
        );
        // A couple of lit windows once it is dark enough to matter.
        if (w > 5 && n.at(seed * 29 + i) > 0.45) {
          final lit = p.sunPosition.dy > 0.4 || ctx.palette == LightingPalette.night;
          canvas.drawRect(
            Rect.fromLTWH(x + w * 0.2, y - h * 0.62, w * 0.22, h * 0.24),
            Paint()
              ..color = lit
                  ? T.lampGlow.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.18),
          );
        }
      }
    };
  }

  /// A hilltop castle — frame 10's destination.
  static ScenePaint castle({
    required int seed,
    required Offset Function(Size size) anchor,
    double scale = 1.0,
    double distance = 0.4,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final n = ctx.noise;
      final base = anchor(size);
      final unit = size.height * 0.06 * scale;

      final stone = Kit.haze(const Color(0xFFE8DCC8), p.haze, distance);
      final stoneDark = Kit.haze(const Color(0xFFC3B49C), p.haze, distance);
      final roof = Kit.haze(const Color(0xFF7A8FB8), p.haze, distance * 0.8);

      void tower(double dx, double heightUnits, double widthUnits) {
        final w = unit * widthUnits;
        final h = unit * heightUnits;
        final x = base.dx + dx * unit;
        final r = Rect.fromLTWH(x - w / 2, base.dy - h, w, h);
        canvas.drawRect(r, Paint()..color = stone);
        canvas.drawRect(
          Rect.fromLTWH(r.right - w * 0.34, r.top, w * 0.34, h),
          Paint()..color = stoneDark,
        );
        // Spire.
        canvas.drawPath(
          Path()
            ..moveTo(x - w * 0.72, r.top)
            ..lineTo(x, r.top - h * 0.55)
            ..lineTo(x + w * 0.72, r.top)
            ..close(),
          Paint()..color = roof,
        );
        // Windows.
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - w * 0.14, r.top + h * (0.25 + i * 0.22), w * 0.28, h * 0.12),
              Radius.circular(w * 0.14),
            ),
            Paint()..color = T.lampGlow.withValues(alpha: 0.5),
          );
        }
      }

      // Curtain wall.
      canvas.drawRect(
        Rect.fromLTWH(base.dx - unit * 3.4, base.dy - unit * 1.6, unit * 6.8, unit * 1.6),
        Paint()..color = stoneDark,
      );
      tower(-2.4, 3.2, 1.0);
      tower(2.4, 3.0, 0.95);
      tower(-0.9, 4.4, 1.15);
      tower(1.1, 5.4, 1.3);
      tower(0.1, 6.6, 1.5);

      // Lit haze around the silhouette so it reads as "the destination".
      Kit.glow(canvas, base.translate(0, -unit * 4), unit * 7, p.sunColor, intensity: 0.18);
      n.at(seed); // keep the seed meaningful for future variation
    };
  }

  // -------------------------------------------------------------- terrain

  /// Near ground the character stands on.
  static ScenePaint ground({
    required int seed,
    double top = 0.74,
    Color? color,
    double amplitude = 0.4,
    double Function(double t)? shape,
  }) {
    return (canvas, size, ctx) {
      final p = ctx.palette;
      final n = ctx.noise;
      final rect = Rect.fromLTRB(
        -size.width * 0.05,
        size.height * top,
        size.width * 1.05,
        size.height * 1.05,
      );

      final profile = Kit.paintedEdge(
        (t) =>
            0.14 +
            (n.fbm(t * 1.8 + seed * 0.29, octaves: 3) - 0.5) * amplitude +
            (shape?.call(t) ?? 0),
        n,
        seed,
        amount: 0.026,
        frequency: 26,
      );

      final base = color ?? T.forestNear;
      canvas.drawPath(
        Kit.profilePath(rect, profile, samples: 200),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(base, p.sunColor, 0.14)!,
              base,
              Color.lerp(base, Colors.black, 0.4)!,
            ],
          ).createShader(rect),
      );

      canvas.save();
      canvas.clipPath(Kit.profilePath(rect, profile, samples: 160));
      Kit.glaze(canvas, rect, n, seed * 11, [
        Color.lerp(base, Colors.black, 0.35)!,
        Color.lerp(base, p.sunColor, 0.3)!,
      ], opacity: 0.16);
      canvas.restore();

      // Scattered grass tufts catch the key light.
      final tuft = Paint()..strokeWidth = 1.4..strokeCap = StrokeCap.round;
      for (var i = 0; i < 120; i++) {
        final t = n.at(seed * 7 + i);
        final x = rect.left + rect.width * t;
        final y = rect.top + rect.height * profile(t) + n.range(seed * 3 + i, 2, 26);
        final h = n.range(seed * 5 + i, 4, 11);
        tuft.color = Color.lerp(base, p.sunColor, 0.3)!.withValues(alpha: 0.4);
        canvas.drawLine(Offset(x, y), Offset(x + n.range(seed * 9 + i, -2, 2), y - h), tuft);
      }
    };
  }

  /// A winding road receding toward the horizon — frame 10.
  ///
  /// The ribbon is built from a curved centre line whose half-width shrinks to
  /// almost nothing at the vanishing point, so it tapers rather than forming a
  /// wedge.
  static ScenePaint road({
    required int seed,
    double horizon = 0.46,
    double horizonX = 0.56,
    double nearX = 0.44,
    double width = 0.30,
    double bend = 0.09,
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final horizonY = size.height * horizon;
      final nearY = size.height * 1.04;

      Offset centre(double t) {
        // Ease so most of the visible length is near the viewer.
        final e = Curves.easeInCubic.transform(t);
        // A sustained S-swing, not a single bulge that vanishes at both ends.
        final swing = math.sin(t * math.pi * 1.35) * (1 - e * 0.35);
        return Offset(
          size.width * (nearX + (horizonX - nearX) * e) +
              swing * size.width * bend,
          nearY + (horizonY - nearY) * e,
        );
      }

      // Half-width narrows with distance but never closes to a point.
      double halfWidth(double t) {
        final e = Curves.easeInCubic.transform(t);
        return size.width * width * 0.5 * (1 - e * 0.93) + 3.0;
      }

      const steps = 60;
      final ribbon = Path();
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final c = centre(t);
        final w = halfWidth(t);
        if (i == 0) {
          ribbon.moveTo(c.dx - w, c.dy);
        } else {
          ribbon.lineTo(c.dx - w, c.dy);
        }
      }
      for (var i = steps; i >= 0; i--) {
        final t = i / steps;
        final c = centre(t);
        ribbon.lineTo(c.dx + halfWidth(t), c.dy);
      }
      ribbon.close();

      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Kit.haze(const Color(0xFFD8CDB4), ctx.palette.haze, 0.5),
              const Color(0xFFCBBFA4),
              const Color(0xFFB3A489),
            ],
          ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height)),
      );

      // Soft verges where the road meets the grass.
      canvas.drawPath(
        ribbon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFF6E6247).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Worn tracks down the middle.
      canvas.save();
      canvas.clipPath(ribbon);
      for (final side in [-0.36, 0.36]) {
        final track = Path();
        for (var i = 0; i <= steps; i++) {
          final t = i / steps;
          final c = centre(t);
          final x = c.dx + halfWidth(t) * side * 2;
          if (i == 0) {
            track.moveTo(x, c.dy);
          } else {
            track.lineTo(x, c.dy);
          }
        }
        canvas.drawPath(
          track,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.02
            ..color = const Color(0xFF9E9076).withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      Kit.grain(canvas, Rect.fromLTRB(0, horizonY, size.width, size.height), n,
          seed * 3, opacity: 0.03);
      canvas.restore();
    };
  }

  // -------------------------------------------------------------- overlays

  /// Foreground foliage framing the corners — the depth cue that makes the
  /// valley feel like it is being looked *into*.
  static ScenePaint foliageFrame({
    required int seed,
    double scale = 1.0,
    bool left = true,
    bool right = true,
    bool bottom = false,
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final dark = Color.lerp(T.forestNear, Colors.black, 0.45)!;

      void cluster(Offset origin, double dirX, int index) {
        for (var i = 0; i < 14; i++) {
          final a = n.range(seed * 13 + index * 40 + i, -0.9, 0.9);
          final len = size.height * n.range(seed * 7 + index * 40 + i, 0.1, 0.26) * scale;
          final leaf = Offset(
            origin.dx + dirX * len * math.cos(a) * 1.3,
            origin.dy - len * math.sin(a).abs() * 1.1,
          );
          canvas.drawPath(
            Kit.blob(leaf, len * 0.42, n, seed * 3 + index * 40 + i, points: 9, wobble: 0.3),
            Paint()
              ..color = Color.lerp(dark, T.forestMid, n.at(seed * 5 + i) * 0.35)!
                  .withValues(alpha: 0.95),
          );
        }
      }

      if (left) cluster(Offset(-size.width * 0.02, size.height * 1.02), 1, 1);
      if (right) cluster(Offset(size.width * 1.02, size.height * 1.02), -1, 2);
      if (bottom) {
        cluster(Offset(size.width * 0.35, size.height * 1.12), 1, 3);
        cluster(Offset(size.width * 0.7, size.height * 1.12), -1, 4);
      }
    };
  }

  /// Birds — three or four strokes drifting across the sky.
  static ScenePaint birds({required int seed, int count = 5, double band = 0.22}) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.32);

      for (var i = 0; i < count; i++) {
        final speed = n.range(seed * 11 + i, 0.012, 0.022);
        final x = ((n.at(seed * 17 + i) + ctx.time * speed) % 1.3) - 0.15;
        final y = band + (n.at(seed * 19 + i) - 0.5) * 0.1;
        // Wings flap on a sine so the flock does not look frozen.
        final flap = math.sin(ctx.time * 3.2 + i * 1.7) * 0.4 + 0.6;
        final s = size.height * n.range(seed * 23 + i, 0.008, 0.015);
        final c = Offset(size.width * x, size.height * y);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - s, c.dy)
            ..quadraticBezierTo(c.dx - s * 0.5, c.dy - s * flap, c.dx, c.dy)
            ..quadraticBezierTo(c.dx + s * 0.5, c.dy - s * flap, c.dx + s, c.dy),
          paint,
        );
      }
    };
  }

  /// Unifying ambient wash + vignette. Always the last layer.
  static void ambient(Canvas canvas, Size size, ScenePaintContext ctx) {
    final rect = Offset.zero & size;
    if (ctx.palette.ambient.a > 0) {
      canvas.drawRect(rect, Paint()..color = ctx.palette.ambient);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.24),
          ],
          stops: const [0.58, 1.0],
        ).createShader(rect),
    );
    Kit.brushwork(canvas, rect, ctx.noise, 77,
        angle: -0.35, strokes: 70, opacity: 0.022);
    Kit.grain(canvas, rect, ctx.noise, 91, opacity: 0.022);
  }
}

/// Built environment for the FYERS chapter: the office in frame 04 and the
/// river city at sunset in frame 09.
abstract final class Cityscape {
  /// A glass office tower, three-quarter view, with a lit sign band.
  static ScenePaint officeTower({
    required int seed,
    required Rect Function(Size size) bounds,
    String? sign,
    Color glass = const Color(0xFF6E93B8),
    Color mullion = const Color(0xFFBFD2E2),
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final p = ctx.palette;
      final rect = bounds(size);

      // Main face.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(glass, p.sunColor, 0.28)!,
              glass,
              Color.lerp(glass, Colors.black, 0.3)!,
            ],
          ).createShader(rect),
      );

      // Receding side face.
      final sideW = rect.width * 0.26;
      canvas.drawPath(
        Path()
          ..moveTo(rect.right, rect.top)
          ..lineTo(rect.right + sideW, rect.top + rect.height * 0.06)
          ..lineTo(rect.right + sideW, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..close(),
        Paint()..color = Color.lerp(glass, Colors.black, 0.42)!,
      );

      // Window grid — the reason it reads as an office rather than a slab.
      final cols = (rect.width / 22).floor().clamp(4, 22);
      final rows = (rect.height / 26).floor().clamp(6, 30);
      for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
          final w = rect.width / cols;
          final h = rect.height / rows;
          final cell = Rect.fromLTWH(
            rect.left + c * w + w * 0.14,
            rect.top + r * h + h * 0.16,
            w * 0.72,
            h * 0.66,
          );
          final lit = n.at(seed * 31 + r * 40 + c);
          canvas.drawRect(
            cell,
            Paint()
              ..color = lit > 0.82
                  ? T.lampGlow.withValues(alpha: 0.5)
                  : Color.lerp(glass, const Color(0xFF16324A), 0.45)!
                      .withValues(alpha: 0.75),
          );
        }
      }

      // Horizontal mullion bands.
      for (var r = 0; r <= rows; r++) {
        final y = rect.top + r * rect.height / rows;
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          Paint()
            ..strokeWidth = 1.2
            ..color = mullion.withValues(alpha: 0.32),
        );
      }

      // Sky reflection sheen down the face.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.transparent,
              Colors.white.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(rect),
      );

      if (sign != null) {
        final band = Rect.fromLTWH(
          rect.left + rect.width * 0.14,
          rect.top + rect.height * 0.055,
          rect.width * 0.72,
          rect.height * 0.062,
        );
        Kit.text(
          canvas,
          sign,
          Offset(band.left, band.top),
          TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: band.height * 0.92,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.95),
            shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)],
          ),
          maxWidth: band.width,
          align: TextAlign.center,
        );
      }
    };
  }

  /// A skyline of simple blocks receding into haze — frame 09.
  static ScenePaint skyline({
    required int seed,
    double baseline = 0.62,
    double height = 0.2,
    double distance = 0.35,
    int count = 26,
    Color? color,
  }) {
    return (canvas, size, ctx) {
      final n = ctx.noise;
      final p = ctx.palette;
      final base = color ?? const Color(0xFF4A4A63);

      for (var i = 0; i < count; i++) {
        final t = i / count;
        final w = size.width * n.range(seed * 13 + i, 0.022, 0.05);
        final h = size.height * height * n.range(seed * 29 + i, 0.3, 1.0);
        final x = size.width * (t + n.range(seed * 7 + i, -0.012, 0.012));
        final y = size.height * baseline;
        final depth = n.at(seed * 11 + i);
        final tone = Kit.haze(
          Color.lerp(base, Colors.black, depth * 0.3)!,
          p.haze,
          distance,
        );
        canvas.drawRect(Rect.fromLTWH(x, y - h, w, h), Paint()..color = tone);

        // Lit windows.
        final cols = (w / 6).floor().clamp(1, 6);
        final rows = (h / 9).floor().clamp(1, 16);
        for (var c = 0; c < cols; c++) {
          for (var r = 0; r < rows; r++) {
            if (n.at(seed * 37 + i * 97 + r * 7 + c) < 0.62) continue;
            canvas.drawRect(
              Rect.fromLTWH(
                x + c * w / cols + w / cols * 0.22,
                y - h + r * h / rows + h / rows * 0.22,
                w / cols * 0.5,
                h / rows * 0.46,
              ),
              Paint()..color = T.lampGlow.withValues(alpha: 0.55),
            );
          }
        }
      }
    };
  }
}
