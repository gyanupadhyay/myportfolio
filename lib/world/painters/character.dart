import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'landscape.dart';

/// The wanderer's poses across the 12 frames.
enum Pose {
  /// Frames 01, 10 — standing, back to camera, backpack on.
  standingBack,

  /// Frames 03, 09, 12 — seated on a rock, back to camera.
  seatedBack,

  /// Frame 05 — at the desk in profile, chin on hand.
  deskProfile,

  /// Frames 06, 07, 08 — three-quarter back of head at the monitor.
  deskBackQuarter,
}

/// Palette for the character. Kept separate from scene lighting so the same
/// figure can be re-lit per frame.
@immutable
class CharacterPalette {
  const CharacterPalette({
    required this.hair,
    required this.hairLight,
    required this.skin,
    required this.skinShade,
    required this.shirt,
    required this.shirtShade,
    required this.pants,
    required this.pack,
    required this.packStrap,
  });

  final Color hair;
  final Color hairLight;
  final Color skin;
  final Color skinShade;
  final Color shirt;
  final Color shirtShade;
  final Color pants;
  final Color pack;
  final Color packStrap;

  static const day = CharacterPalette(
    hair: Color(0xFF241A16),
    hairLight: Color(0xFF4A362C),
    skin: Color(0xFFE8B98F),
    skinShade: Color(0xFFC8946A),
    shirt: Color(0xFF6E7F93),
    shirtShade: Color(0xFF4E5C6E),
    pants: Color(0xFF3B4250),
    pack: Color(0xFF4A4038),
    packStrap: Color(0xFF322B25),
  );

  static const night = CharacterPalette(
    hair: Color(0xFF16141A),
    hairLight: Color(0xFF3A3340),
    skin: Color(0xFFBE8F6C),
    skinShade: Color(0xFF8E6A4E),
    shirt: Color(0xFF2A3142),
    shirtShade: Color(0xFF1C2130),
    pants: Color(0xFF20242F),
    pack: Color(0xFF2E2A26),
    packStrap: Color(0xFF1E1B18),
  );

  static const sunset = CharacterPalette(
    hair: Color(0xFF1C1418),
    hairLight: Color(0xFF52382E),
    skin: Color(0xFFD9A077),
    skinShade: Color(0xFFA9714E),
    shirt: Color(0xFF3A3340),
    shirtShade: Color(0xFF261F2A),
    pants: Color(0xFF241F28),
    pack: Color(0xFF3A322A),
    packStrap: Color(0xFF241F1A),
  );
}

abstract final class Character {
  /// Paints the wanderer. [anchor] is the ground point under the figure and
  /// [height] the full figure height in pixels.
  static void paint(
    Canvas canvas,
    Offset anchor,
    double height,
    Pose pose,
    CharacterPalette c,
    ScenePaintContext ctx, {
    bool backpack = true,
    double breathe = 0,
    double walk = 0,
    double facing = 1,
  }) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    // A slow idle breath lifts the torso a hair; a stride adds a second,
    // faster bob at twice the step frequency.
    final lift = math.sin(breathe) * height * 0.006 +
        (walk == 0 ? 0 : -math.sin(walk * 2).abs() * height * 0.012);
    canvas.translate(0, lift);

    switch (pose) {
      case Pose.standingBack:
        _standingBack(canvas, height, c, ctx, backpack, walk, facing);
      case Pose.seatedBack:
        _seatedBack(canvas, height, c, ctx, backpack);
      case Pose.deskProfile:
        _deskProfile(canvas, height, c, ctx);
      case Pose.deskBackQuarter:
        _deskBackQuarter(canvas, height, c, ctx);
    }
    canvas.restore();
  }

  // Shared: a rounded mass of hair with a few tapering points. It has to read
  // as a silhouette first — long even spikes become a sunburst at large sizes.
  static void _hair(
    Canvas canvas,
    Offset head,
    double r,
    CharacterPalette c,
    ScenePaintContext ctx, {
    double spread = 1.0,
    int seedBase = 5,
    double back = 0.0,
  }) {
    final n = ctx.noise;
    final paint = Paint()..color = c.hair;

    Rect cap() => Rect.fromCenter(
          center: head.translate(back * r * 0.2, -r * 0.12),
          width: r * 2.16,
          height: r * 2.0,
        );

    // The bulk: a slightly oversized cap sitting over the skull.
    canvas.drawOval(cap(), paint);

    // A handful of short points around the crown.
    const count = 9;
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1);
      final a = math.pi * (1.02 - t * 1.04) * spread;
      final len = r * n.range(seedBase * 31 + i, 0.08, 0.26);
      final baseA = a + n.range(seedBase * 17 + i, -0.08, 0.08);
      final origin = head.translate(0, -r * 0.12);
      final tip = origin +
          Offset(math.cos(baseA) * (r * 1.1 + len),
              -math.sin(baseA) * (r * 1.05 + len));
      final l = origin +
          Offset(math.cos(baseA + 0.3) * r * 1.1,
              -math.sin(baseA + 0.3) * r * 1.05);
      final rr = origin +
          Offset(math.cos(baseA - 0.3) * r * 1.1,
              -math.sin(baseA - 0.3) * r * 1.05);
      canvas.drawPath(
        Path()
          ..moveTo(l.dx, l.dy)
          ..quadraticBezierTo(
              (l.dx + tip.dx) / 2, (l.dy + tip.dy) / 2, tip.dx, tip.dy)
          ..quadraticBezierTo(
              (rr.dx + tip.dx) / 2, (rr.dy + tip.dy) / 2, rr.dx, rr.dy)
          ..close(),
        paint,
      );
    }

    // Rim light from the key direction.
    final lightA = (ctx.palette.sunPosition.dx - 0.5) * 2;
    canvas.save();
    canvas.clipPath(Path()..addOval(cap()));
    canvas.drawCircle(
      head.translate(lightA * r * 0.6, -r * 0.6),
      r * 0.8,
      Paint()
        ..color = c.hairLight.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );
    canvas.restore();
  }

  static void _backpack(Canvas canvas, Rect torso, CharacterPalette c) {
    final packRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: torso.center.translate(0, torso.height * 0.02),
        width: torso.width * 0.86,
        height: torso.height * 0.78,
      ),
      Radius.circular(torso.width * 0.22),
    );
    canvas.drawRRect(packRect, Paint()..color = c.pack);
    // Lid seam.
    canvas.drawLine(
      Offset(packRect.left + packRect.width * 0.1, packRect.top + packRect.height * 0.34),
      Offset(packRect.right - packRect.width * 0.1, packRect.top + packRect.height * 0.34),
      Paint()
        ..color = c.packStrap
        ..strokeWidth = torso.width * 0.05,
    );
    // Straps over the shoulders.
    final strap = Paint()
      ..color = c.packStrap
      ..strokeWidth = torso.width * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(torso.left + torso.width * 0.2, torso.top),
      Offset(torso.left + torso.width * 0.12, torso.top + torso.height * 0.5),
      strap,
    );
    canvas.drawLine(
      Offset(torso.right - torso.width * 0.2, torso.top),
      Offset(torso.right - torso.width * 0.12, torso.top + torso.height * 0.5),
      strap,
    );
  }

  // ------------------------------------------------------------- standing

  /// Standing, seen from behind. [walk] drives a stride: 0 is at rest, and
  /// the phase advances one full step cycle every 2*pi.
  static void _standingBack(
    Canvas canvas,
    double h,
    CharacterPalette c,
    ScenePaintContext ctx,
    bool backpack, [
    double walk = 0,
    double facing = 1,
  ]) {
    final w = h * 0.26;
    final walking = walk != 0;
    // One leg swings forward while the other trails; the arms counter-swing.
    final swing = walking ? math.sin(walk) : 0.0;
    final lean = walking ? facing * h * 0.006 : 0.0;

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 1.7, height: h * 0.03),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.014),
    );

    // Legs — short and tapered; the figure reads as a teenager, not a stick.
    // From behind, a stride reads as the feet parting and the leading shoe
    // lifting, rather than as a side-on scissor.
    final legPaint = Paint()..color = c.pants;
    final shoe = Paint()..color = Color.lerp(c.pants, Colors.black, 0.45)!;
    for (final leg in [-1.0, 1.0]) {
      final phase = leg * swing;
      final dx = (leg < 0 ? -0.27 : 0.03) + phase * 0.10;
      // A leg swinging forward is foreshortened and its foot comes up.
      final shorten = phase.clamp(0.0, 1.0) * h * 0.03;
      canvas.drawPath(
        Path()
          ..moveTo(w * dx, -h * 0.38)
          ..lineTo(w * (dx + 0.24), -h * 0.38)
          ..lineTo(w * (dx + 0.2), -shorten)
          ..lineTo(w * (dx + 0.02), -shorten)
          ..close(),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * (dx - 0.01),
            -h * 0.022 - shorten,
            w * 0.26,
            h * 0.026,
          ),
          Radius.circular(h * 0.012),
        ),
        shoe,
      );
    }

    // Torso — wider at the shoulders, narrowing to the waist. It leans a
    // little into the direction of travel while walking.
    final torso = Rect.fromLTWH(-w / 2 + lean, -h * 0.72, w, h * 0.34);
    canvas.drawPath(
      Path()
        ..moveTo(torso.left + w * 0.02, torso.top + h * 0.02)
        ..quadraticBezierTo(torso.center.dx, torso.top - h * 0.012,
            torso.right - w * 0.02, torso.top + h * 0.02)
        ..quadraticBezierTo(torso.right + w * 0.04, torso.center.dy,
            torso.right - w * 0.08, torso.bottom)
        ..lineTo(torso.left + w * 0.08, torso.bottom)
        ..quadraticBezierTo(torso.left - w * 0.04, torso.center.dy,
            torso.left + w * 0.02, torso.top + h * 0.02)
        ..close(),
      Paint()..color = c.shirt,
    );
    // Shade the side away from the key light.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(torso.center.dx, torso.top - h * 0.03,
        torso.width, torso.height + h * 0.03));
    canvas.drawRect(
      torso.inflate(h * 0.03),
      Paint()..color = c.shirtShade.withValues(alpha: 0.4),
    );
    canvas.restore();

    // Arms hang just clear of the body, elbows slightly bent.
    final sleeve = Paint()
      ..color = c.shirt
      ..strokeWidth = w * 0.19
      ..strokeCap = StrokeCap.round;
    final forearm = Paint()
      ..color = c.skin
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      // Arms swing opposite to the leg on the same side.
      final arm = -side * swing;
      final shoulder =
          Offset(lean + side * w * 0.44, torso.top + h * 0.045);
      final elbow = Offset(
        lean + side * w * 0.54 + arm * w * 0.06,
        torso.top + h * 0.17,
      );
      final hand = Offset(
        lean + side * w * 0.47 + arm * w * 0.16,
        torso.bottom + h * 0.055 - arm.clamp(0.0, 1.0) * h * 0.02,
      );
      canvas.drawLine(shoulder, elbow, sleeve);
      canvas.drawLine(elbow, hand, forearm);
    }

    if (backpack) _backpack(canvas, torso, c);

    // Neck + head.
    canvas.drawRect(
      Rect.fromLTWH(lean - w * 0.1, -h * 0.775, w * 0.2, h * 0.06),
      Paint()..color = c.skinShade,
    );
    _hair(canvas, Offset(lean, -h * 0.845), h * 0.078, c, ctx, seedBase: 5);
  }

  // --------------------------------------------------------------- seated

  static void _seatedBack(
    Canvas canvas,
    double h,
    CharacterPalette c,
    ScenePaintContext ctx,
    bool backpack,
  ) {
    final w = h * 0.30;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.1, 0), width: w * 1.9, height: h * 0.04),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.014),
    );

    // Knees drawn up: thigh runs forward, shin drops to the ground.
    final thigh = Paint()
      ..color = c.pants
      ..strokeWidth = w * 0.3
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final hip = Offset(side * w * 0.2, -h * 0.16);
      final knee = Offset(side * w * 0.52, -h * 0.30);
      final foot = Offset(side * w * 0.6, -h * 0.02);
      canvas.drawLine(hip, knee, thigh);
      canvas.drawLine(
        knee,
        foot,
        Paint()
          ..color = Color.lerp(c.pants, Colors.black, 0.18)!
          ..strokeWidth = w * 0.24
          ..strokeCap = StrokeCap.round,
      );
    }

    // Seat / hips.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -h * 0.17), width: w * 1.02, height: h * 0.16),
        Radius.circular(w * 0.22),
      ),
      Paint()..color = Color.lerp(c.pants, Colors.black, 0.1)!,
    );

    // Torso, leaning back a touch.
    final torso = Rect.fromLTWH(-w / 2, -h * 0.60, w, h * 0.44);
    canvas.save();
    canvas.translate(torso.center.dx, torso.bottom);
    canvas.rotate(-0.04);
    canvas.translate(-torso.center.dx, -torso.bottom);

    canvas.drawPath(
      Path()
        ..moveTo(torso.left + w * 0.08, torso.top + h * 0.02)
        ..quadraticBezierTo(torso.center.dx, torso.top - h * 0.015,
            torso.right - w * 0.08, torso.top + h * 0.02)
        ..quadraticBezierTo(
            torso.right + w * 0.02, torso.center.dy, torso.right, torso.bottom)
        ..lineTo(torso.left, torso.bottom)
        ..quadraticBezierTo(
            torso.left - w * 0.02, torso.center.dy, torso.left + w * 0.08,
            torso.top + h * 0.02)
        ..close(),
      Paint()..color = c.shirt,
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
        torso.center.dx, torso.top - h * 0.04, torso.width, torso.height + h * 0.04));
    canvas.drawRRect(
      RRect.fromRectAndRadius(torso.inflate(h * 0.02), Radius.circular(w * 0.2)),
      Paint()..color = c.shirtShade.withValues(alpha: 0.42),
    );
    canvas.restore();

    if (backpack) _backpack(canvas, torso, c);

    // Arms resting forward onto the knees.
    final sleeve = Paint()
      ..color = c.shirt
      ..strokeWidth = w * 0.19
      ..strokeCap = StrokeCap.round;
    final forearm = Paint()
      ..color = c.skin
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(side * w * 0.45, torso.top + h * 0.06);
      final elbow = Offset(side * w * 0.56, torso.top + h * 0.26);
      final hand = Offset(side * w * 0.5, torso.bottom + h * 0.04);
      canvas.drawLine(shoulder, elbow, sleeve);
      canvas.drawLine(elbow, hand, forearm);
    }

    // Neck + head.
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.1, -h * 0.655, w * 0.2, h * 0.07),
      Paint()..color = c.skinShade,
    );
    _hair(canvas, Offset(0, -h * 0.715), h * 0.075, c, ctx, seedBase: 9);
    canvas.restore();
  }

  // ----------------------------------------------------------- desk poses

  /// Frame 05 — profile, elbow on the desk, chin resting on the hand.
  ///
  /// The anchor is where the body meets the desk line; the figure faces left.
  static void _deskProfile(
    Canvas canvas,
    double h,
    CharacterPalette c,
    ScenePaintContext ctx,
  ) {
    final shoulder = Offset(0, -h * 0.40);
    final head = Offset(-h * 0.10, -h * 0.575);
    final headR = h * 0.088;
    final elbow = Offset(-h * 0.19, -h * 0.02);
    final hand = Offset(-h * 0.125, -h * 0.47);

    // Torso in profile, leaning very slightly forward.
    canvas.drawPath(
      Path()
        ..moveTo(h * 0.13, 0)
        ..lineTo(h * 0.10, -h * 0.30)
        ..quadraticBezierTo(h * 0.085, -h * 0.40, h * 0.02, -h * 0.425)
        ..lineTo(-h * 0.055, -h * 0.42)
        ..quadraticBezierTo(-h * 0.105, -h * 0.34, -h * 0.10, -h * 0.2)
        ..lineTo(-h * 0.10, 0)
        ..close(),
      Paint()..color = c.shirt,
    );
    // Shading down the far side of the back.
    canvas.drawPath(
      Path()
        ..moveTo(h * 0.13, 0)
        ..lineTo(h * 0.10, -h * 0.30)
        ..quadraticBezierTo(h * 0.085, -h * 0.40, h * 0.02, -h * 0.425)
        ..lineTo(0, -h * 0.42)
        ..lineTo(h * 0.04, 0)
        ..close(),
      Paint()..color = c.shirtShade.withValues(alpha: 0.5),
    );

    // Upper arm: shoulder down to the elbow planted on the desk.
    canvas.drawLine(
      shoulder,
      elbow,
      Paint()
        ..color = c.shirt
        ..strokeWidth = h * 0.075
        ..strokeCap = StrokeCap.round,
    );
    // Forearm: elbow up to the hand under the chin.
    canvas.drawLine(
      elbow,
      hand,
      Paint()
        ..color = c.skin
        ..strokeWidth = h * 0.058
        ..strokeCap = StrokeCap.round,
    );

    // Neck.
    canvas.drawLine(
      Offset(-h * 0.03, -h * 0.40),
      Offset(-h * 0.055, -h * 0.49),
      Paint()
        ..color = c.skinShade
        ..strokeWidth = h * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Head in profile: rounded skull with a brow and a slight nose.
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + headR * 0.3, head.dy - headR * 0.95)
        ..quadraticBezierTo(head.dx + headR * 1.15, head.dy - headR * 0.3,
            head.dx + headR * 0.95, head.dy + headR * 0.6)
        ..quadraticBezierTo(head.dx + headR * 0.7, head.dy + headR * 1.15,
            head.dx - headR * 0.1, head.dy + headR * 1.0)
        ..quadraticBezierTo(head.dx - headR * 0.95, head.dy + headR * 0.8,
            head.dx - headR * 1.0, head.dy + headR * 0.1)
        ..lineTo(head.dx - headR * 1.12, head.dy - headR * 0.06)
        ..lineTo(head.dx - headR * 0.92, head.dy - headR * 0.3)
        ..quadraticBezierTo(head.dx - headR * 0.75, head.dy - headR * 1.05,
            head.dx + headR * 0.3, head.dy - headR * 0.95)
        ..close(),
      Paint()..color = c.skin,
    );

    // Eye, on the screen.
    canvas.drawOval(
      Rect.fromCenter(
        center: head.translate(-headR * 0.55, -headR * 0.12),
        width: headR * 0.3,
        height: headR * 0.2,
      ),
      Paint()..color = const Color(0xFF1A1418),
    );

    // The hand cupping the jaw sits over the face edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: hand.translate(-headR * 0.05, headR * 0.1),
          width: headR * 0.72,
          height: headR * 0.92,
        ),
        Radius.circular(headR * 0.3),
      ),
      Paint()..color = c.skinShade,
    );

    _hair(canvas, head, headR, c, ctx, spread: 1.05, seedBase: 13, back: 0.45);
  }

  /// Frames 06, 07, 08 — seen from behind and slightly to the side, filling
  /// the corner of the frame.
  static void _deskBackQuarter(
    Canvas canvas,
    double h,
    CharacterPalette c,
    ScenePaintContext ctx,
  ) {
    final headR = h * 0.13;
    final head = Offset(0, -h * 0.62);

    // Neck, drawn first so the shoulders overlap its base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-h * 0.055, -h * 0.54, h * 0.11, h * 0.18),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = c.skinShade,
    );

    // Shoulders: a low, wide curve rather than a hill.
    canvas.drawPath(
      Path()
        ..moveTo(-h * 0.46, 0)
        ..cubicTo(-h * 0.42, -h * 0.30, -h * 0.24, -h * 0.40, -h * 0.02, -h * 0.40)
        ..cubicTo(h * 0.22, -h * 0.40, h * 0.38, -h * 0.29, h * 0.42, 0)
        ..close(),
      Paint()..color = c.shirt,
    );
    canvas.drawPath(
      Path()
        ..moveTo(h * 0.06, -h * 0.395)
        ..cubicTo(h * 0.24, -h * 0.38, h * 0.38, -h * 0.29, h * 0.42, 0)
        ..lineTo(h * 0.06, 0)
        ..close(),
      Paint()..color = c.shirtShade.withValues(alpha: 0.5),
    );

    // An ear edge catching the screen light.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-headR * 0.92, head.dy + headR * 0.25),
        width: headR * 0.34,
        height: headR * 0.5,
      ),
      Paint()..color = c.skin,
    );

    _hair(canvas, head, headR, c, ctx, spread: 1.0, seedBase: 21);
  }

  // ------------------------------------------------------------------ cat

  /// The tabby that recurs in frames 02, 06, 09, 10 and 12.
  /// [facing] is 1 for right, -1 for left.
  static void cat(
    Canvas canvas,
    Offset anchor,
    double height,
    ScenePaintContext ctx, {
    double facing = 1,
    bool curled = false,
    double tailPhase = 0,
    Color body = const Color(0xFFD9A05B),
    Color shade = const Color(0xFFB07A3C),
  }) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(facing, 1);

    final h = height;
    final paint = Paint()..color = body;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 0), width: h * 1.1, height: h * 0.12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.05),
    );

    if (curled) {
      // Sleeping: a comma of fur.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -h * 0.28), width: h * 1.25, height: h * 0.56),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-h * 0.36, -h * 0.34), width: h * 0.52, height: h * 0.46),
        paint,
      );
      // Tail wrapped around.
      canvas.drawPath(
        Path()
          ..moveTo(h * 0.55, -h * 0.2)
          ..quadraticBezierTo(h * 0.8, -h * 0.05, h * 0.2, -h * 0.06),
        Paint()
          ..color = shade
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.16
          ..strokeCap = StrokeCap.round,
      );
      // Ears.
      for (final dx in [-0.5, -0.22]) {
        canvas.drawPath(
          Path()
            ..moveTo(h * dx, -h * 0.5)
            ..lineTo(h * (dx + 0.06), -h * 0.66)
            ..lineTo(h * (dx + 0.14), -h * 0.5)
            ..close(),
          paint,
        );
      }
      canvas.restore();
      return;
    }

    // Sitting: haunches, chest, head, upright tail.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-h * 0.16, -h * 0.26), width: h * 0.72, height: h * 0.52),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(h * 0.06, -h * 0.08)
        ..quadraticBezierTo(h * 0.24, -h * 0.42, h * 0.16, -h * 0.6)
        ..lineTo(-h * 0.06, -h * 0.56)
        ..quadraticBezierTo(-h * 0.1, -h * 0.2, -h * 0.12, -h * 0.05)
        ..close(),
      paint,
    );
    // Tail with a slow flick.
    final flick = math.sin(tailPhase) * h * 0.08;
    canvas.drawPath(
      Path()
        ..moveTo(-h * 0.42, -h * 0.08)
        ..quadraticBezierTo(-h * 0.74 + flick, -h * 0.3, -h * 0.58 + flick, -h * 0.66),
      Paint()
        ..color = shade
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.13
        ..strokeCap = StrokeCap.round,
    );
    // Head.
    final head = Offset(h * 0.12, -h * 0.72);
    canvas.drawCircle(head, h * 0.2, paint);
    for (final dx in [-0.16, 0.14]) {
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + h * dx, head.dy - h * 0.1)
          ..lineTo(head.dx + h * (dx + (dx < 0 ? -0.02 : 0.02)), head.dy - h * 0.3)
          ..lineTo(head.dx + h * (dx + (dx < 0 ? 0.13 : 0.1)), head.dy - h * 0.13)
          ..close(),
        paint,
      );
    }
    // Eyes catching the light.
    final eye = Paint()..color = const Color(0xFF2A2018);
    canvas.drawOval(
      Rect.fromCenter(center: head.translate(h * 0.03, -h * 0.02), width: h * 0.05, height: h * 0.07),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(center: head.translate(h * 0.17, -h * 0.02), width: h * 0.05, height: h * 0.07),
      eye,
    );

    canvas.restore();
    ctx.noise.at(1);
  }
}
