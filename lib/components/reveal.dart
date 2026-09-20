import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme/tokens.dart';

/// Fade-and-rise entrance used by every text block and panel in the frames.
///
/// Children of a [RevealGroup] stagger automatically, so a scene reads in the
/// order it was composed rather than appearing all at once.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = T.dSlow,
    this.offset = const Offset(0, 18),
    this.curve = T.eOut,
    this.enabled = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting displacement in design pixels.
  final Offset offset;
  final Curve curve;
  final bool enabled;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) _controller.forward();
  }

  @override
  void didUpdateWidget(Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _start();
    if (!widget.enabled && oldWidget.enabled) _controller.reverse();
  }

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
        final t = widget.curve.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(widget.offset.dx * (1 - t), widget.offset.dy * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps a column of [Reveal]s and hands each one an increasing delay.
class RevealGroup extends StatelessWidget {
  const RevealGroup({
    super.key,
    required this.children,
    this.start = Duration.zero,
    this.step = T.dStagger,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing = 0,
    this.enabled = true,
  });

  final List<Widget> children;
  final Duration start;
  final Duration step;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final wrapped = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && spacing > 0) wrapped.add(SizedBox(height: spacing));
      wrapped.add(
        Reveal(
          delay: start + step * i,
          enabled: enabled,
          child: children[i],
        ),
      );
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: wrapped,
    );
  }
}

/// A looping vertical bob — the scroll hint in frame 01.
class Bob extends StatefulWidget {
  const Bob({
    super.key,
    required this.child,
    this.distance = 6,
    this.period = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final double distance;
  final Duration period;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);

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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, Curves.easeInOut.transform(_controller.value) * widget.distance),
        child: child,
      ),
      child: widget.child,
    );
  }
}
