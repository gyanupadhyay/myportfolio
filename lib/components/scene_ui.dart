import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/ambience.dart';
import '../app/motion.dart';
import '../app/theme/day_night.dart';
import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import '../app/theme/typography.dart';
import '../world/painters/paint_kit.dart';
import '../world/stage.dart';
import 'reveal.dart';

/// Free-floating script text — the accent that appears in ten of the twelve
/// frames. Slightly rotated and softly shadowed so it sits *in* the scene
/// rather than on top of it.
class HandwrittenAccent extends StatelessWidget {
  const HandwrittenAccent({
    super.key,
    required this.text,
    this.style,
    this.color,
    this.rotation = -0.02,
    this.align = TextAlign.left,
    this.shadow = true,
    this.maxWidth,
  });

  final String text;
  final TextStyle? style;
  final Color? color;
  final double rotation;
  final TextAlign align;
  final bool shadow;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    final resolved = (style ?? Type.handNote).copyWith(
      color: color ?? palette.onPanel,
      shadows: shadow
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    // Scenery, never a control. Its box is far wider than its glyphs, so
    // without this it swallows clicks on whatever it floats over — on the
    // journey map it covered the FYERS stop.
    return IgnorePointer(
      child: Transform.rotate(
        angle: rotation,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: Text(text, style: resolved, textAlign: align),
        ),
      ),
    );
  }
}

/// A routed wooden plank with text. Frame 01's signpost, frame 04's
/// "Better Tools / Brighter Investors", frame 10's "Next Chapter · BossWallah".
class WoodenSign extends StatelessWidget {
  const WoodenSign({
    super.key,
    required this.lines,
    this.width = 180,
    this.height = 44,
    this.rotation = 0,
    this.arrow = SignArrow.none,
    this.seed = 4,
    this.active = false,
    this.textStyle,
    this.eyebrow,
    this.eyebrowStyle,
  });

  final List<String> lines;
  final double width;
  final double height;
  final double rotation;
  final SignArrow arrow;
  final int seed;
  final bool active;
  final TextStyle? textStyle;

  /// Small line above the main text — frame 10's "Next Chapter".
  final String? eyebrow;
  final TextStyle? eyebrowStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: motionDuration(context, T.dFast),
      transform: Matrix4.translationValues(active ? 4 : 0, active ? -2 : 0, 0),
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SignPainter(seed: seed, arrow: arrow, active: active),
            child: Padding(
              padding: EdgeInsets.only(
                left: arrow == SignArrow.left ? height * 0.5 : T.s12,
                right: arrow == SignArrow.right ? height * 0.5 : T.s12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      style: (eyebrowStyle ?? Type.labelSm).copyWith(
                        color: const Color(0xFFE8D4B8),
                      ),
                    ),
                  for (final line in lines)
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: (textStyle ?? Type.label).copyWith(
                        color: const Color(0xFFF4E6CE),
                        shadows: [
                          const Shadow(
                            color: Color(0xAA2A1B10),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SignArrow { none, left, right }

class _SignPainter extends CustomPainter {
  _SignPainter({required this.seed, required this.arrow, required this.active});

  final int seed;
  final SignArrow arrow;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final noise = Noise(seed);
    final rect = Offset.zero & size;

    // Drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(2, 5), const Radius.circular(4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    if (arrow == SignArrow.none) {
      Kit.plank(
        canvas,
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        noise,
        seed,
      );
    } else {
      // A pointed plank: clip the wood fill to an arrow silhouette.
      final tip = size.height * 0.42;
      final path = arrow == SignArrow.right
          ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width - tip, 0)
            ..lineTo(size.width, size.height / 2)
            ..lineTo(size.width - tip, size.height)
            ..lineTo(0, size.height)
            ..close())
          : (Path()
            ..moveTo(size.width, 0)
            ..lineTo(tip, 0)
            ..lineTo(0, size.height / 2)
            ..lineTo(tip, size.height)
            ..lineTo(size.width, size.height)
            ..close());

      canvas.save();
      canvas.clipPath(path);
      Kit.plank(
        canvas,
        RRect.fromRectAndRadius(rect.inflate(2), Radius.zero),
        noise,
        seed,
      );
      canvas.restore();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = T.woodDark.withValues(alpha: 0.55),
      );
    }

    // Nail heads.
    final nail = Paint()..color = const Color(0xFF3B2A1C);
    for (final dx in [size.width * 0.08, size.width * 0.92]) {
      canvas.drawCircle(Offset(dx, size.height * 0.22), 1.8, nail);
      canvas.drawCircle(Offset(dx, size.height * 0.78), 1.8, nail);
    }

    if (active) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = T.lampGlow.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_SignPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.arrow != arrow;
}

/// The transparent top bar from frames 01–03.
///
/// Five labels plus the icon cluster need roughly 700 design units; a phone's
/// UI box is 600 wide. Rather than overflow, the labels fold into a menu the
/// bar toggles open beneath itself.
class TopNav extends StatefulWidget {
  const TopNav({
    super.key,
    required this.items,
    required this.onSelect,
    required this.current,
    this.onToggleTheme,
    this.onToggleSound,
    this.soundOn = false,
    this.iconsOnly = false,
  });

  /// Frames 02 and 03 show only the icon cluster, not the nav items.
  final bool iconsOnly;

  final List<String> items;
  final ValueChanged<String> onSelect;
  final String current;
  /// Only used when no [DayNightScope] is mounted above the bar.
  final VoidCallback? onToggleTheme;
  final VoidCallback? onToggleSound;
  final bool soundOn;

  @override
  State<TopNav> createState() => _TopNavState();
}

class _TopNavState extends State<TopNav> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    final form = stage.form;
    final onNav = Colors.white;
    final gutter = stage.gutter;
    final collapse = form.isPhone && !widget.iconsOnly;

    final icons = [
      // The day/night controller is the source of truth when one is in scope;
      // the explicit prop stays for scenes built without it.
      Builder(builder: (context) {
        final dayNight = DayNightScope.maybeOf(context);
        final night = dayNight?.isNight ?? false;
        return _NavIcon(
          // Show where the toggle goes, not where it is.
          icon: night ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
          label: night ? 'Switch to daylight' : 'Switch to night',
          color: onNav,
          onTap: dayNight == null ? widget.onToggleTheme : dayNight.toggle,
        );
      }),
      // The ambience controller is the source of truth when one is in scope;
      // the explicit props stay for scenes built without it.
      Builder(builder: (context) {
        final ambience = AmbienceScope.maybeOf(context);
        final on = ambience?.enabled ?? widget.soundOn;
        return _NavIcon(
          icon: on ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          label: on ? 'Mute ambience' : 'Play ambience',
          color: onNav,
          onTap: ambience == null ? widget.onToggleSound : ambience.toggle,
        );
      }),
      _NavIcon(
        icon: Icons.person_outline,
        label: 'About Gyan',
        color: onNav,
        onTap: () => widget.onSelect('About'),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            gutter.left,
            form.pick(phone: T.s12, tablet: T.s20, desktop: T.s32),
            gutter.right,
            form.pick(phone: T.s8, tablet: T.s16, desktop: T.s32),
          ),
          child: Row(
            children: [
              const Spacer(),
              if (!widget.iconsOnly && !collapse)
                for (final item in widget.items)
                  _NavItem(
                    label: item,
                    selected: item == widget.current,
                    color: onNav,
                    onTap: () => widget.onSelect(item),
                  ),
              if (!collapse) SizedBox(width: form.pick(phone: 0.0, desktop: T.s24)),
              ...icons,
              if (collapse)
                _NavIcon(
                  icon: _open ? Icons.close : Icons.menu,
                  label: _open ? 'Close menu' : 'Open menu',
                  color: onNav,
                  onTap: () => setState(() => _open = !_open),
                ),
            ],
          ),
        ),
        if (collapse && _open)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter.left),
            child: _NavSheet(
              items: widget.items,
              current: widget.current,
              onSelect: (item) {
                setState(() => _open = false);
                widget.onSelect(item);
              },
            ),
          ),
      ],
    );
  }
}

/// The folded-out nav on a phone.
class _NavSheet extends StatelessWidget {
  const _NavSheet({
    required this.items,
    required this.current,
    required this.onSelect,
  });

  final List<String> items;
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return Material(
      color: palette.panel.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(T.rSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            InkWell(
              onTap: () => onSelect(item),
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: T.s16,
                  vertical: T.s12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: Type.label.copyWith(
                          color: Colors.white,
                          fontWeight: item == current
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item == current)
                      Icon(Icons.circle, size: 8, color: palette.glow),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused || widget.selected;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onTap();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: Type.label.copyWith(
                    color: widget.color.withValues(alpha: active ? 1 : 0.86),
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: motionDuration(context, T.dFast),
                  height: 1.5,
                  width: active ? 18 : 0,
                  color: widget.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: color,
        splashRadius: 18,
        tooltip: null,
        // Material's default is `adaptiveClickable`: a hand on the web, an
        // arrow everywhere else. The pointer should say the same thing
        // wherever this is running.
        mouseCursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      ),
    );
  }
}

/// "↓ Scroll to explore" — frame 01.
class ScrollHint extends StatelessWidget {
  const ScrollHint({super.key, this.label = 'Scroll to explore', this.visible = true});

  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: motionDuration(context, T.dSlow),
      opacity: visible ? 1 : 0,
      child: Bob(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 8)],
            ),
            Text(
              label,
              style: Type.labelSm.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the mockups' annotation chip: shows which beat of a chapter the
/// visitor is on, and lets them jump.
class BeatIndicator extends StatelessWidget {
  const BeatIndicator({
    super.key,
    required this.count,
    required this.index,
    required this.onSelect,
    this.labels = const [],
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: i < labels.length ? labels[i] : 'Beat ${i + 1}',
            child: Tooltip(
              message: i < labels.length ? labels[i] : 'Beat ${i + 1}',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  // An 8px dot is far too small to aim at; the padding is part
                  // of the target rather than dead space around it.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 10,
                    ),
                    child: AnimatedContainer(
                      duration: motionDuration(context, T.dFast),
                      width: i == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(T.rPill),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A soft pulsing halo — the active journey node in frame 03.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.radius = 26,
    this.period = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final Color color;
  final double radius;
  final Duration period;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.of(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + t * 0.35),
                blurRadius: widget.radius * (0.7 + t * 0.6),
                spreadRadius: widget.radius * 0.1 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
