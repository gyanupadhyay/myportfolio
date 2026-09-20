import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/data_views.dart';
import '../../components/panels.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../data/experiments.dart';
import '../../data/models/chapter.dart';
import '../../world/painters/landscape.dart';
import '../../world/painters/paint_kit.dart';
import '../../world/stage.dart';

/// The Engineering Observatory.
///
/// Each system is inspectable: the visitor follows a request through its
/// steps and can open the deeper layer. Every item carries its own
/// credibility badge, because on this résumé some of it is production work
/// and some is a personal project.
class ObservatoryScene extends StatefulWidget {
  const ObservatoryScene({
    super.key,
    required this.onNavigate,
    required this.onOpenLink,
    this.initialId,
  });

  final void Function(String route) onNavigate;
  final void Function(String url) onOpenLink;
  final String? initialId;

  @override
  State<ObservatoryScene> createState() => _ObservatorySceneState();
}

class _ObservatorySceneState extends State<ObservatoryScene> {
  late int _selected = () {
    final i = experiments.indexWhere((e) => e.id == widget.initialId);
    return i < 0 ? 0 : i;
  }();

  bool _deep = false;

  @override
  Widget build(BuildContext context) {
    final item = experiments[_selected];

    return WorldStage(
      lighting: SceneLighting.night,
      ui: SceneUi(
        leading: _Back(onTap: () => widget.onNavigate('/map')),
        // The light and the ambience, reachable from here rather than only
        // from the two screens that show a nav.
        extras: [
          At(right: T.s24, top: T.s24, child: AmbientToggles(composed: SceneLighting.night)),
        ],
        trailing: Reveal(
          delay: const Duration(milliseconds: 900),
          child: PillButton(
            label: 'The human layer',
            onPressed: () => widget.onNavigate('/human'),
          ),
        ),
        // Title, picker and card were three absolutely-placed blocks spanning
        // 1290 units. They are one column now, so a narrow viewport reflows
        // them instead of pushing two thirds of the card off-screen.
        copy: [CopySlot(
          left: 75,
          top: 100,
          width: 1290,
          phoneAlignment: Alignment.topCenter,
          child: Builder(
            builder: (context) {
              final compact = WorldStage.of(context).form.isPhone;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RevealGroup(
                    start: const Duration(milliseconds: 160),
                    children: [
                      const HandwrittenAccent(
                        text: 'Engineering Observatory',
                        style: Type.handSection,
                        color: Colors.white,
                        rotation: -0.012,
                      ),
                      const SizedBox(height: T.s12),
                      Text(
                        'Systems I have built — release pipelines, a '
                        'framework migration, and the projects I write for '
                        'myself. Follow a path through one of them.',
                        style: Type.bodyLg.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? T.s20 : 56),
                  Reveal(
                    delay: const Duration(milliseconds: 300),
                    child: Wrap(
                      spacing: T.s12,
                      runSpacing: T.s12,
                      children: [
                        for (var i = 0; i < experiments.length; i++)
                          _ExperimentChip(
                            experiment: experiments[i],
                            selected: i == _selected,
                            onTap: () => setState(() {
                              _selected = i;
                              _deep = false;
                            }),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? T.s20 : T.s24),
                  Reveal(
                    key: ValueKey(item.id),
                    delay: const Duration(milliseconds: 120),
                    child: _SystemPanel(
                      item: item,
                      deep: _deep,
                      compact: compact,
                      onToggleDeep: () => setState(() => _deep = !_deep),
                      onOpenLink: widget.onOpenLink,
                    ),
                  ),
                  // Room to scroll the card's last line clear of the floating
                  // 'human layer' button in the bottom corner.
                  const SizedBox(height: 96),
                ],
              );
            },
          ),
        )],
      ),
      children: [
        SceneLayer(seed: 701, repaintOnTime: false, paint: [_dome]),
        SceneLayer(seed: 703, paint: [_stars]),
        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),
      ],
    );
  }

  /// A dark observatory dome with a slit onto the sky.
  static void _dome(Canvas canvas, Size size, ScenePaintContext ctx) {
    final rect = Offset.zero & size;
    Kit.gradientRect(canvas, rect, const [
      Color(0xFF0A1220),
      Color(0xFF111E33),
      Color(0xFF070D18),
    ]);
    // Ribs of the dome converging toward the top.
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF3E6FA0).withValues(alpha: 0.16);
    final apex = Offset(size.width * 0.5, -size.height * 0.5);
    for (var i = -6; i <= 6; i++) {
      canvas.drawLine(
        Offset(size.width * (0.5 + i * 0.12), size.height),
        apex,
        rib,
      );
    }
    for (var r = 1; r <= 4; r++) {
      canvas.drawArc(
        Rect.fromCircle(center: apex, radius: size.height * (0.55 + r * 0.32)),
        0.25 * math.pi,
        0.5 * math.pi,
        false,
        rib,
      );
    }
    Kit.glow(canvas, Offset(size.width * 0.5, size.height * 0.1),
        size.height * 0.8, const Color(0xFF2E6BA8), intensity: 0.18);
  }

  /// A slow drift of stars through the dome slit.
  static void _stars(Canvas canvas, Size size, ScenePaintContext ctx) {
    final n = ctx.noise;
    for (var i = 0; i < 90; i++) {
      final x = ((n.at(i * 3) + ctx.time * 0.004) % 1.0) * size.width;
      final y = n.at(i * 7 + 1) * size.height * 0.75;
      final twinkle = (math.sin(ctx.time * 1.4 + i) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        0.8 + n.at(i * 11) * 1.4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12 + twinkle * 0.3),
      );
    }
  }
}

class _ExperimentChip extends StatelessWidget {
  const _ExperimentChip({
    required this.experiment,
    required this.selected,
    required this.onTap,
  });

  final Experiment experiment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: '${experiment.title} — ${experiment.tagline}',
      tooltip: experiment.credibility.label,
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        padding: const EdgeInsets.symmetric(horizontal: T.s20, vertical: T.s12),
        decoration: BoxDecoration(
          color: selected
              ? T.metricBlue.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: active ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(T.rPill),
          border: Border.all(
            color: selected ? T.metricBlue : T.glassBorder,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Text(
          experiment.title,
          style: Type.label.copyWith(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StackChip extends StatelessWidget {
  const _StackChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(color: T.glassBorder),
      ),
      child: Text(
        label,
        style: Type.labelSm.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 18,
        ),
      ),
    );
  }
}

/// Renders the PRD's honesty rule per experiment.
class _CredibilityBadge extends StatelessWidget {
  const _CredibilityBadge(this.credibility);

  final Credibility credibility;

  @override
  Widget build(BuildContext context) {
    final color = switch (credibility) {
      Credibility.professional => T.success,
      Credibility.education => T.lampGlow,
      Credibility.personalProject => T.metricBlue,
      Credibility.exploration => T.lampGlow,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(T.rPill),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        credibility.label,
        style: Type.labelSm.copyWith(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

class _DeeperToggle extends StatelessWidget {
  const _DeeperToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: open ? 'Hide implementation detail' : 'Go deeper',
      tooltip: open ? 'Collapse' : 'Go deeper',
      onActivate: onTap,
      builder: (context, active) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedRotation(
            duration: motionDuration(context, T.dFast),
            turns: open ? 0.25 : 0,
            child: Icon(Icons.chevron_right,
                size: 24, color: T.metricBlue.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: T.s6),
          Text(
            open ? 'Less' : 'Go deeper',
            style: Type.label.copyWith(
              color: Colors.white.withValues(alpha: active ? 1 : 0.88),
              decoration: active ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
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

/// The selected system's card.
///
/// It grows with its content at every size: the reference frame pinned it to
/// 430 units and scrolled the flow and the notes inside their own columns,
/// which hid a third of the diagram behind a gesture nobody would guess at.
/// The page band scrolls instead. On a phone the flow diagram and the notes
/// beside it cannot share a row, so they stack.
class _SystemPanel extends StatelessWidget {
  const _SystemPanel({
    required this.item,
    required this.compact,
    required this.deep,
    required this.onToggleDeep,
    required this.onOpenLink,
  });

  final Experiment item;
  final bool compact;
  final bool deep;
  final VoidCallback onToggleDeep;
  final void Function(String url) onOpenLink;

  Widget _flow() => FlowDiagram(
        nodes: [
          for (final s in item.steps) FlowNode(s.label, detail: s.detail),
        ],
        nodeWidth: compact ? 300 : 240,
      );

  Widget _notes() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.stack.isNotEmpty)
            Wrap(
              spacing: T.s8,
              runSpacing: T.s8,
              children: [for (final s in item.stack) _StackChip(s)],
            ),
          const SizedBox(height: T.s16),
          _DeeperToggle(open: deep, onTap: onToggleDeep),
          if (deep) ...[
            const SizedBox(height: T.s16),
            for (final d in item.details)
              Padding(
                padding: const EdgeInsets.only(bottom: T.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: T.metricBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: Text(
                        d,
                        style: Type.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (item.link != null) ...[
            const SizedBox(height: T.s16),
            PillButton(
              label: 'Open on GitHub',
              icon: Icons.open_in_new,
              padding: const EdgeInsets.symmetric(
                horizontal: T.s20,
                vertical: T.s12,
              ),
              onPressed: () => onOpenLink(item.link!),
            ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: Type.displayMd.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: T.s4),
                  Text(
                    item.tagline,
                    style: Type.bodyLg.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            _CredibilityBadge(item.credibility),
          ],
        ),
        const SizedBox(height: T.s16),
        Text(
          item.context,
          style: Type.body.copyWith(color: Colors.white.withValues(alpha: 0.86)),
        ),
        const SizedBox(height: T.s24),
      ],
    );

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(T.s32, T.s24, T.s32, T.s20),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [header, _flow(), const SizedBox(height: T.s24), _notes()],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _flow(),
                    const SizedBox(width: T.s32),
                    Expanded(child: _notes()),
                  ],
                ),
              ],
            ),
    );
  }
}
