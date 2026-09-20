import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme/day_night.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../data/journey.dart';
import '../../data/models/chapter.dart';
import '../../world/painters/character.dart';
import '../../world/painters/landscape.dart';
import '../../world/painters/paint_kit.dart';
import '../../world/plate.dart';
import '../../world/plates.g.dart';
import '../../world/stage.dart';
import 'journey_path.dart';

/// Frame 03 — The Journey Map.
///
/// Five stops along a glowing trail across the valley. This is the navigation
/// spine for every career chapter.
class JourneyScene extends StatefulWidget {
  const JourneyScene({
    super.key,
    required this.onNavigate,
    this.visited = const {},
  });

  final void Function(String route) onNavigate;

  /// Node ids the visitor has already opened.
  final Set<String> visited;

  @override
  State<JourneyScene> createState() => _JourneySceneState();
}

class _JourneySceneState extends State<JourneyScene>
    with SingleTickerProviderStateMixin {
  /// Which stop the wanderer is standing at. He starts where the trail does.
  int _at = 0;

  /// The stop he is walking toward, if any.
  int? _target;

  late final AnimationController _walk = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _walk.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final target = _target;
      if (target == null) return;
      setState(() {
        _at = target;
        _target = null;
      });
      _open(journeyNodes[target]);
    });
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  void _open(JourneyNode node) {
    final chapter = node.chapterId;
    if (chapter == null) return;
    widget.onNavigate(chapter == 'next' ? '/observatory' : '/chapter/$chapter');
  }

  /// Walks to [index] and opens it on arrival. Under reduced motion the walk
  /// is skipped entirely rather than played fast.
  void _travelTo(int index) {
    final node = journeyNodes[index];
    if (node.chapterId == null) return;
    if (_target != null) return;

    if (Motion.of(context) || index == _at) {
      setState(() => _at = index);
      _open(node);
      return;
    }

    // Pace the walk by how far it actually is, so a hop to the next stop is
    // not the same length as crossing the whole valley.
    final steps = (index - _at).abs();
    setState(() {
      _target = index;
      _walk.duration = Duration(milliseconds: 420 + steps * 320);
    });
    _walk.forward(from: 0);
  }

  /// The five painted cards, traced off `assets/art/journey.webp` in its own
  /// pixel space. Same order as [journeyNodes].
  static const _cardHotspots = <Rect>[
    Rect.fromLTRB(73, 471, 281, 555),
    Rect.fromLTRB(426, 438, 616, 521),
    Rect.fromLTRB(752, 392, 957, 476),
    Rect.fromLTRB(1097, 312, 1300, 392),
    Rect.fromLTRB(1410, 266, 1614, 347),
  ];

  @override
  Widget build(BuildContext context) {
    // The note is written on the map itself, with no panel behind it, so its
    // ink follows the light the visitor chose.
    final palette = DayNightScope.paletteFor(context, SceneLighting.day);
    // On a plate the painting carries the trail, the five cards and the hint;
    // the scene contributes targets over the painted cards.
    final plate = platesOn(context);
    return WorldStage(
      lighting: SceneLighting.day,
      ui: SceneUi(
        topBar: TopNav(
          items: navLabels,
          current: 'Map',
          iconsOnly: true,
          onSelect: (item) => widget.onNavigate(navRouteFor(item)),
        ),
        copy: plate ? const [] : [CopySlot(
          left: 40,
          top: 165,
          scrim: false,
          phoneAlignment: Alignment.topLeft,
          child: Reveal(
            delay: const Duration(milliseconds: 220),
            child: HandwrittenAccent(
              text: 'A journey\nof building,\nlearning and\ngrowing…',
              style: Type.handTitle,
              color: palette.onWorld,
              rotation: -0.02,
            ),
          ),
        )],
        // Five 200-unit cards cannot be spread across a phone's trail without
        // colliding, so the map hands over to a list of the same stops.
        compactBelow: [
          Reveal(
            delay: const Duration(milliseconds: 700),
            child: CompactDestinationList(
              title: 'The stops',
              children: [
                for (final node in journeyNodes)
                  CompactDestination(
                    label: node.title,
                    detail: node.caption,
                    enabled: node.chapterId != null,
                    onTap: () => _open(node),
                  ),
              ],
            ),
          ),
        ],
        footer: plate ? null : Reveal(
          delay: const Duration(milliseconds: 900),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 22,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: T.s6),
              Text(
                'Click on a place to explore a chapter',
                style: Type.labelSm.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  shadows: const [
                    Shadow(color: Color(0xAA000000), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      children: plate
          ? [
              ScenePlate(
                art: plateJourney,
                lighting: SceneLighting.day,
                children: [
                  for (var i = 0; i < journeyNodes.length; i++)
                    PlateHotspot(
                      rect: _cardHotspots[i],
                      label: '${journeyNodes[i].title} — ${journeyNodes[i].caption}',
                      onTap: () => _open(journeyNodes[i]),
                    ),
                ],
              ),
            ]
          : [
        SceneLayer(seed: 11, paint: [Landscape.sky]),

        ParallaxLayer(
          depth: 0.1,
          child: SceneLayer(
            seed: 121,
            paint: [
              Landscape.clouds(seed: 121, band: 0.09, count: 5, scale: 0.55),
              Landscape.clouds(
                  seed: 133, band: 0.19, count: 4, scale: 0.4, opacity: 0.85),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.2,
          child: SceneLayer(
            seed: 7,
            repaintOnTime: false,
            paint: [
              Landscape.mountains(
                seed: 7,
                top: 0.06,
                bottom: 0.48,
                roughness: 6.0,
                distance: 0.44,
              ),
            ],
          ),
        ),

        // The ridge the castle sits on, top right.
        ParallaxLayer(
          depth: 0.28,
          child: SceneLayer(
            seed: 141,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 141,
                top: 0.20,
                bottom: 0.52,
                distance: 0.3,
                amplitude: 0.5,
                trees: false,
                color: const Color(0xFF6E8C6A),
                shape: (t) => 0.3 - math.pow(t, 3).toDouble() * 0.5,
              ),
              Landscape.castle(
                seed: 151,
                anchor: (size) => Offset(size.width * 0.585, size.height * 0.45),
                scale: 0.95,
                distance: 0.34,
              ),
            ],
          ),
        ),

        // The valley floor the trail runs across.
        ParallaxLayer(
          depth: 0.4,
          child: SceneLayer(
            seed: 161,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 161,
                top: 0.34,
                bottom: 0.78,
                distance: 0.18,
                amplitude: 0.42,
                treeCount: 40,
                treeScale: 0.6,
                shape: (t) => 0.16 - t * 0.28,
              ),
            ],
          ),
        ),

        // River and bridges.
        ParallaxLayer(
          depth: 0.5,
          child: _MapFeatures(),
        ),

        ParallaxLayer(
          depth: 0.62,
          child: SceneLayer(
            seed: 171,
            repaintOnTime: false,
            paint: [
              Landscape.hills(
                seed: 171,
                top: 0.62,
                bottom: 1.02,
                distance: 0.08,
                amplitude: 0.4,
                treeCount: 48,
                treeScale: 0.75,
                shape: (t) => 0.2 - math.pow(1 - t, 2.4).toDouble() * 0.34,
              ),
            ],
          ),
        ),

        ParallaxLayer(
          depth: 0.3,
          child: SceneLayer(seed: 181, paint: [Landscape.birds(seed: 181, band: 0.16)]),
        ),

        // The trail itself, under the node cards.
        ParallaxLayer(depth: 0.55, child: _Trail()),

        // The wanderer: seated on his rock while idle, walking the trail
        // while travelling to a stop.
        ParallaxLayer(
          depth: 0.85,
          child: _target == null
              ? SceneLayer(seed: 191, paint: [_seatedWanderer])
              : _Traveller(
                  progress: _walk,
                  from: _at,
                  to: _target!,
                ),
        ),

        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),

        // The five stops. These sit on the painted trail, so they stay in the
        // world layer and move with it.
        for (var i = 0; i < journeyNodes.length; i++)
          _NodeAt(
            node: journeyNodes[i],
            index: i,
            visited: widget.visited.contains(journeyNodes[i].id),
            onTap: () => _travelTo(i),
          ),
      ],
    );
  }

  static void _seatedWanderer(Canvas canvas, Size size, ScenePaintContext ctx) {
    // A rock for him to sit on.
    final base = Offset(size.width * 0.892, size.height * 0.813);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 78, base.dy + 46)
        ..quadraticBezierTo(base.dx - 60, base.dy - 12, base.dx - 6, base.dy + 2)
        ..quadraticBezierTo(base.dx + 54, base.dy - 6, base.dx + 76, base.dy + 46)
        ..close(),
      Paint()..color = const Color(0xFF6C6152),
    );
    Character.paint(
      canvas,
      base,
      size.height * 0.26,
      Pose.seatedBack,
      CharacterPalette.day,
      ctx,
      breathe: ctx.time * 1.05,
    );
    Character.cat(
      canvas,
      base.translate(66, 44),
      34,
      ctx,
      facing: -1,
      tailPhase: ctx.time * 1.6,
    );
  }
}

class _MapFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: JourneyMapPainter(time: stage.time, seedBase: 201),
        size: Size.infinite,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Trail extends StatefulWidget {
  @override
  State<_Trail> createState() => _TrailState();
}

class _TrailState extends State<_Trail> with SingleTickerProviderStateMixin {
  late final AnimationController _draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _draw.forward();
    });
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    final reduced = Motion.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => CustomPaint(
          painter: JourneyTrailPainter(
            nodes: journeyNodes,
            time: stage.time,
            glow: T.successGlow,
            reduced: reduced,
            progress: reduced ? 1.0 : Curves.easeInOut.transform(_draw.value),
          ),
          size: Size.infinite,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Positions one node card over the map, anchored to its normalised point.
///
/// The marker must land exactly on the trail, so the block is sized such that
/// the marker's centre coincides with the node's point and the card stacks
/// directly above it.
class _NodeAt extends StatelessWidget {
  const _NodeAt({
    required this.node,
    required this.index,
    required this.visited,
    required this.onTap,
  });

  final JourneyNode node;
  final int index;
  final bool visited;
  final VoidCallback onTap;

  static const _cardWidth = 210.0;
  static const _blockHeight = 196.0;
  static const _markerSize = 14.0;

  @override
  Widget build(BuildContext context) {
    // Against the live art box, not the 1440x861 reference: the trail under
    // these markers is painted from the same fractions, so both re-compose
    // together and the pin stays on its stop at any viewport shape.
    final stage = WorldStage.of(context);
    // A phone gets the list in the UI layer instead; drawing both would put
    // five overlapping cards on top of it.
    if (stage.form.isPhone) {
      return const At(width: 0, height: 0, child: SizedBox.shrink());
    }
    final box = stage.size;
    final x = box.width * node.position.x;
    final y = box.height * node.position.y;
    final active = node.chapterId != null;

    return At(
      left: x - _cardWidth / 2,
      top: y - _blockHeight + _markerSize / 2,
      width: _cardWidth,
      height: _blockHeight,
      child: Reveal(
        delay: Duration(milliseconds: 700 + index * 140),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _NodeCard(node: node, active: active, visited: visited, onTap: onTap),
            const SizedBox(height: T.s8),
            if (active)
              const PulseGlow(
                color: T.successGlow,
                radius: 18,
                child: _Marker(active: true),
              )
            else
              _Marker(active: false, visited: visited),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.active, this.visited = false});


  final bool active;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? T.successGlow
            : visited
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.active,
    required this.visited,
    required this.onTap,
  });

  final JourneyNode node;
  final bool active;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: active
          ? '${node.title} — ${node.caption}. Open this chapter.'
          : '${node.title} — ${node.caption}. Chapter coming soon.',
      tooltip: active ? 'Open ${node.title}' : 'Coming soon',
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onActivate: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        curve: T.eOut,
        transform: Matrix4.translationValues(0, hovered ? -5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.96 : 0.86),
          borderRadius: BorderRadius.circular(T.rSm),
          border: Border.all(
            color: active ? T.successGlow : Colors.white.withValues(alpha: 0.9),
            width: active ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hovered ? 0.34 : 0.24),
              blurRadius: hovered ? 22 : 14,
              offset: Offset(0, hovered ? 9 : 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.title,
              textAlign: TextAlign.center,
              style: Type.label.copyWith(
                color: T.ink,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              node.caption,
              textAlign: TextAlign.center,
              style: Type.labelSm.copyWith(
                color: T.inkMuted,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (visited) ...[
              const SizedBox(height: 3),
              Icon(Icons.check_circle, size: 11, color: T.success),
            ],
          ],
        ),
      ),
    );
  }
}

/// The wanderer walking the trail between two stops.
///
/// He is positioned by distance along the same path the trail is drawn from,
/// so he follows the route exactly rather than cutting across the terrain.
class _Traveller extends StatelessWidget {
  const _Traveller({
    required this.progress,
    required this.from,
    required this.to,
  });

  final Animation<double> progress;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => CustomPaint(
          painter: _TravellerPainter(
            t: Curves.easeInOutSine.transform(progress.value),
            from: from,
            to: to,
            time: stage.time,
            palette: stage.palette,
          ),
          size: Size.infinite,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TravellerPainter extends CustomPainter {
  _TravellerPainter({
    required this.t,
    required this.from,
    required this.to,
    required this.time,
    required this.palette,
  });

  final double t;
  final int from;
  final int to;
  final double time;
  final LightingPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final distances = journeyNodeDistances(journeyNodes, size);
    if (from >= distances.length || to >= distances.length) return;

    final travelled = distances[from] + (distances[to] - distances[from]) * t;
    final point = journeyPointAt(journeyNodes, size, travelled);
    if (point == null) return;

    final ctx = ScenePaintContext(
      palette: palette,
      noise: const Noise(191),
      time: time,
    );

    // Stride frequency scales with the distance covered, so a long walk takes
    // more steps rather than the same steps stretched out.
    final span = (distances[to] - distances[from]).abs();
    final strides = (span / 42).clamp(3.0, 26.0);
    final walk = t * strides * math.pi * 2;

    Character.paint(
      canvas,
      point.position,
      size.height * 0.15,
      Pose.standingBack,
      CharacterPalette.day,
      ctx,
      walk: walk,
      facing: point.dx >= 0 ? 1 : -1,
      breathe: time * 1.1,
    );
  }

  @override
  bool shouldRepaint(_TravellerPainter old) =>
      old.t != t || old.time != time || old.from != from || old.to != to;
}
