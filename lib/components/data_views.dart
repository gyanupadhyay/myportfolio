import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import '../app/theme/typography.dart';
import 'reveal.dart';

/// Green tick + label. Frames 07 and 09.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    this.color = T.success,
    this.textColor,
    this.style,
    this.tickSize = 30,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final TextStyle? style;

  /// Diameter of the tick. Frame 09's reference uses ~42px.
  final double tickSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tickSize,
          height: tickSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.check, size: tickSize * 0.62, color: Colors.white),
        ),
        const SizedBox(width: T.s12),
        Flexible(
          child: Text(
            label,
            style: (style ?? Type.bodyLg).copyWith(color: textColor ?? T.ink),
          ),
        ),
      ],
    );
  }
}

/// A staggered list of [CheckRow]s.
class CheckList extends StatelessWidget {
  const CheckList({
    super.key,
    required this.items,
    this.color = T.success,
    this.textColor,
    this.spacing = T.s12,
    this.style,
    this.start = const Duration(milliseconds: 220),
    this.tickSize = 30,
  });

  final List<String> items;
  final Color color;
  final Color? textColor;
  final double spacing;
  final TextStyle? style;
  final Duration start;
  final double tickSize;

  @override
  Widget build(BuildContext context) {
    return RevealGroup(
      start: start,
      spacing: spacing,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          CheckRow(
            label: item,
            color: color,
            textColor: textColor,
            style: style,
            tickSize: tickSize,
          ),
      ],
    );
  }
}

/// One line of the Startup Timeline in frame 06: icon, label, mono value.
class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.insert_drive_file_outlined,
    this.emphasis = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;

  /// The "Total" row — brighter, larger, alert-coloured.
  final bool emphasis;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
      decoration: BoxDecoration(
        color: emphasis ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(
          color: emphasis ? palette.panelBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            emphasis ? Icons.circle : icon,
            size: emphasis ? 7 : 13,
            color: emphasis ? (valueColor ?? T.alert) : palette.onPanelMuted,
          ),
          const SizedBox(width: T.s8),
          Expanded(
            child: Text(
              label,
              style: Type.body.copyWith(
                color: palette.onPanel,
                fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: (emphasis ? Type.monoTotal : Type.monoValue).copyWith(
              color: valueColor ?? (emphasis ? T.alert : T.metricBlue),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Launching…" bar in frame 05. Fills in real time, then settles on the
/// measured figure — the beat *is* the wait.
class LaunchProgress extends StatefulWidget {
  const LaunchProgress({
    super.key,
    required this.label,
    required this.result,
    this.duration = const Duration(milliseconds: 3200),
    this.barColor = T.progressPink,
    this.trackColor = const Color(0x33FFFFFF),
    this.width = 250,
  });

  final String label;
  final String result;
  final Duration duration;
  final Color barColor;
  final Color trackColor;
  final double width;

  @override
  State<LaunchProgress> createState() => _LaunchProgressState();
}

class _LaunchProgressState extends State<LaunchProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    final reduced = Motion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: Type.body.copyWith(color: palette.onPanel)),
        const SizedBox(height: T.s12),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Stall in the middle the way a slow cold start actually feels.
            final raw = reduced ? 1.0 : _controller.value;
            final t = raw < 0.45
                ? raw * 1.5
                : raw < 0.75
                    ? 0.675 + (raw - 0.45) * 0.25
                    : 0.75 + (raw - 0.75) * 1.0;
            return Row(
              children: [
                SizedBox(
                  width: widget.width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(T.rPill),
                    child: Stack(
                      children: [
                        Container(height: 12, color: widget.trackColor),
                        FractionallySizedBox(
                          widthFactor: t.clamp(0.0, 1.0),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.barColor,
                                  Color.lerp(widget.barColor, Colors.white, 0.3)!,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: T.s16),
                Opacity(
                  opacity: reduced ? 1.0 : Curves.easeIn.transform(raw.clamp(0.0, 1.0)),
                  child: Text(
                    widget.result,
                    style: Type.displayMd.copyWith(
                      color: palette.onPanel,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Vertical before/after bars — frame 09's 3.2 s → 2.5 s.
class ComparisonBars extends StatefulWidget {
  const ComparisonBars({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    this.beforeValue = '',
    this.afterValue = '',
    this.height = 110,
    this.barWidth = 46,
  });

  /// Raw magnitudes; the taller bar fills [height].
  final double before;
  final double after;
  final String beforeLabel;
  final String afterLabel;
  final String beforeValue;
  final String afterValue;
  final double height;
  final double barWidth;

  @override
  State<ComparisonBars> createState() => _ComparisonBarsState();
}

class _ComparisonBarsState extends State<ComparisonBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: T.dSlow);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    final peak = widget.before > widget.after ? widget.before : widget.after;
    final reduced = Motion.of(context);

    Widget bar(double value, String label, String caption, Color color, int index) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduced
              ? 1.0
              : Curves.easeOutCubic.transform(
                  (_controller.value * 1.4 - index * 0.18).clamp(0.0, 1.0),
                );
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                caption,
                style: Type.labelSm.copyWith(color: palette.onPanel),
              ),
              const SizedBox(height: T.s6),
              Container(
                width: widget.barWidth,
                height: widget.height * (value / peak) * t,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: T.s6),
              Text(label, style: Type.labelSm.copyWith(color: palette.onPanelMuted)),
            ],
          );
        },
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bar(widget.before, widget.beforeLabel, widget.beforeValue,
            const Color(0xFF9AA3AE), 0),
        const SizedBox(width: T.s24),
        bar(widget.after, widget.afterLabel, widget.afterValue, T.successGlow, 1),
      ],
    );
  }
}

/// One box in the startup flow of frame 08.
class FlowNode {
  const FlowNode(this.label, {this.detail});

  final String label;

  /// Shown when the node is expanded — the PRD's "go deeper" layer.
  final String? detail;
}

/// Vertical chain of boxes joined by arrows — frame 08's
/// App Launch → Initialization → Core Services → First Screen.
class FlowDiagram extends StatefulWidget {
  const FlowDiagram({
    super.key,
    required this.nodes,
    this.nodeWidth = 132,
    this.onSelect,
  });

  final List<FlowNode> nodes;
  final double nodeWidth;
  final ValueChanged<int>? onSelect;

  @override
  State<FlowDiagram> createState() => _FlowDiagramState();
}

class _FlowDiagramState extends State<FlowDiagram> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    final children = <Widget>[];

    for (var i = 0; i < widget.nodes.length; i++) {
      final node = widget.nodes[i];
      final expanded = _expanded == i;
      // A node without detail still reports its index, so it is clickable
      // whenever a listener is attached — the cursor has to say the same.
      final interactive = node.detail != null || widget.onSelect != null;

      children.add(
        Reveal(
          delay: T.dStagger * i,
          child: Semantics(
            button: interactive,
            label: node.label,
            child: GestureDetector(
              onTap: () {
                setState(() => _expanded = expanded ? null : i);
                widget.onSelect?.call(i);
              },
              child: MouseRegion(
                cursor: interactive
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: AnimatedContainer(
                  duration: motionDuration(context, T.dFast),
                  width: widget.nodeWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: T.s12,
                    vertical: T.s8,
                  ),
                  decoration: BoxDecoration(
                    color: expanded
                        ? palette.accent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(T.rSm),
                    border: Border.all(
                      color: expanded ? palette.accent : palette.panelBorder,
                      width: expanded ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        node.label,
                        textAlign: TextAlign.center,
                        style: Type.label.copyWith(color: palette.onPanel),
                      ),
                      if (expanded && node.detail != null) ...[
                        const SizedBox(height: T.s6),
                        Text(
                          node.detail!,
                          textAlign: TextAlign.center,
                          style: Type.bodySm.copyWith(color: palette.onPanelMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (i < widget.nodes.length - 1) {
        children.add(
          Reveal(
            delay: T.dStagger * i + const Duration(milliseconds: 60),
            child: Icon(
              Icons.arrow_downward,
              size: 16,
              color: palette.accent.withValues(alpha: 0.8),
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: T.s6),
          children[i],
        ],
      ],
    );
  }
}

/// The right-hand list in frame 08 — technique chips beside the flow.
class TechniqueList extends StatelessWidget {
  const TechniqueList({super.key, required this.items, this.icon = Icons.settings});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return RevealGroup(
      start: const Duration(milliseconds: 380),
      spacing: T.s8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: palette.onPanelMuted),
              const SizedBox(width: T.s8),
              Flexible(
                child: Text(item,
                    style: Type.body.copyWith(color: palette.onPanel)),
              ),
            ],
          ),
      ],
    );
  }
}
