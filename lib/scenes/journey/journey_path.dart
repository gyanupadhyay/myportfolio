import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/chapter.dart';

/// Builds the trail that links the journey nodes.
///
/// Control points come from the nodes themselves, so the path stays
/// registered to the map at any viewport size.
Path buildJourneyPath(List<JourneyNode> nodes, Size size) {
  final points = [
    for (final n in nodes) Offset(size.width * n.position.x, size.height * n.position.y),
  ];
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);

  // Catmull-Rom through the nodes, converted to cubics, so the trail curves
  // through each stop rather than kinking at it.
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = i == 0 ? points[0] : points[i - 1];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

    final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
    final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

/// The glowing dotted trail with a travelling pulse.
class JourneyTrailPainter extends CustomPainter {
  JourneyTrailPainter({
    required this.nodes,
    required this.time,
    required this.glow,
    required this.reduced,
    this.progress = 1.0,
  });

  final List<JourneyNode> nodes;
  final double time;
  final Color glow;
  final bool reduced;

  /// How much of the trail has been drawn in, 0–1.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildJourneyPath(nodes, size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final total = metric.length;
    final drawn = total * progress.clamp(0.0, 1.0);

    // Soft halo under the whole trail.
    canvas.drawPath(
      metric.extractPath(0, drawn),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = glow.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // A dark underlay keeps the white dashes legible over pale terrain.
    canvas.drawPath(
      metric.extractPath(0, drawn),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1E3A2E).withValues(alpha: 0.28),
    );

    // Dashes marching along the route.
    const dash = 12.0;
    const gap = 9.0;
    final phase = reduced ? 0.0 : (time * 16) % (dash + gap);
    final dot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    var d = -phase;
    while (d < drawn) {
      final start = d.clamp(0.0, drawn);
      final end = (d + dash).clamp(0.0, drawn);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), dot);
      }
      d += dash + gap;
    }

    if (reduced) return;

    // A brighter pulse running the length of the trail.
    final head = (time * 0.12) % 1.0 * drawn;
    for (var i = 0; i < 5; i++) {
      final p = head - i * 14;
      if (p < 0 || p > drawn) continue;
      final tan = metric.getTangentForOffset(p);
      if (tan == null) continue;
      canvas.drawCircle(
        tan.position,
        4.5 - i * 0.7,
        Paint()
          ..color = glow.withValues(alpha: 0.65 - i * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(JourneyTrailPainter old) =>
      old.time != time || old.progress != progress;
}

/// The painted map terrain of frame 03: a valley cut by a river, forests,
/// bridges and a castle on the far ridge.
class JourneyMapPainter extends CustomPainter {
  JourneyMapPainter({required this.time, required this.seedBase});

  final double time;
  final int seedBase;

  @override
  void paint(Canvas canvas, Size size) {
    // Terrain is composed by the scene's layer stack; this painter only adds
    // the map-specific features that sit on top of it.
    final river = Path()
      ..moveTo(size.width * 0.02, size.height * 0.92)
      ..cubicTo(
        size.width * 0.22, size.height * 0.80,
        size.width * 0.30, size.height * 0.66,
        size.width * 0.46, size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.62, size.height * 0.58,
        size.width * 0.70, size.height * 0.48,
        size.width * 0.84, size.height * 0.44,
      );

    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.045
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF5B9BC4), Color(0xFF8FC6E0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.018
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.25),
    );

    // Stone bridges where the trail crosses the water.
    for (final at in [0.22, 0.56]) {
      final metric = river.computeMetrics().first;
      final tan = metric.getTangentForOffset(metric.length * at);
      if (tan == null) continue;
      canvas.save();
      canvas.translate(tan.position.dx, tan.position.dy);
      canvas.rotate(math.atan2(tan.vector.dy, tan.vector.dx) + math.pi / 2);
      final w = size.height * 0.10;
      final h = size.height * 0.032;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(h * 0.3),
        ),
        Paint()..color = const Color(0xFFCFC2A8),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(-w * 0.3 + i * w * 0.3, h * 0.52),
          h * 0.22,
          Paint()..color = const Color(0xFF9E8F76),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(JourneyMapPainter old) => false;
}

/// How far along the trail each node sits, in path units.
///
/// The trail is a single contour through the nodes, so a node's distance is
/// found by sampling for the closest point rather than assuming even spacing —
/// the curve between two close stops is shorter than between two far ones.
List<double> journeyNodeDistances(List<JourneyNode> nodes, Size size) {
  final path = buildJourneyPath(nodes, size);
  final metrics = path.computeMetrics().toList();
  if (metrics.isEmpty) return List<double>.filled(nodes.length, 0);
  final metric = metrics.first;
  final total = metric.length;

  const samples = 400;
  final out = <double>[];
  for (final node in nodes) {
    final target = Offset(size.width * node.position.x, size.height * node.position.y);
    var best = 0.0;
    var bestDistance = double.infinity;
    for (var i = 0; i <= samples; i++) {
      final d = total * i / samples;
      final tan = metric.getTangentForOffset(d);
      if (tan == null) continue;
      final gap = (tan.position - target).distanceSquared;
      if (gap < bestDistance) {
        bestDistance = gap;
        best = d;
      }
    }
    out.add(best);
  }
  return out;
}

/// The point and heading at [distance] along the trail.
({Offset position, double dx})? journeyPointAt(
  List<JourneyNode> nodes,
  Size size,
  double distance,
) {
  final metrics = buildJourneyPath(nodes, size).computeMetrics().toList();
  if (metrics.isEmpty) return null;
  final metric = metrics.first;
  final tan = metric.getTangentForOffset(distance.clamp(0.0, metric.length));
  if (tan == null) return null;
  return (position: tan.position, dx: tan.vector.dx);
}
