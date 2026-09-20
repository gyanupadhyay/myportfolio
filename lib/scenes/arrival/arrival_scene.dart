import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/day_night.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../world/painters/character.dart';
import '../../world/painters/landscape.dart';
import '../../world/stage.dart';

/// Frame 01 — Landing / The World.
///
/// The valley, the signpost, the wanderer and the invitation to begin.
class ArrivalScene extends StatefulWidget {
  const ArrivalScene({super.key, required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  State<ArrivalScene> createState() => _ArrivalSceneState();
}

class _ArrivalSceneState extends State<ArrivalScene> {
  bool _scrolled = false;

  static const _signs = <({String label, String route})>[
    (label: 'Projects', route: '/chapter/fyers'),
    (label: 'Experience', route: '/map'),
    (label: 'Ideas', route: '/observatory'),
    (label: 'Life', route: '/human'),
  ];

  @override
  Widget build(BuildContext context) {
    // This copy sits straight on the valley with no panel behind it, so its
    // ink has to follow the light the visitor chose — dark on a bright
    // morning, pale once the sun is down.
    final palette = DayNightScope.paletteFor(context, SceneLighting.day);
    return Listener(
      onPointerSignal: (_) {
        if (!_scrolled) setState(() => _scrolled = true);
      },
      child: WorldStage(
        lighting: SceneLighting.day,
        ui: SceneUi(
          topBar: TopNav(
            items: const ['Home', 'Journal', 'Map', 'Projects', 'About'],
            current: 'Home',
            onSelect: (item) => widget.onNavigate(switch (item) {
              'Map' => '/map',
              'Projects' => '/chapter/fyers',
              'Journal' => '/chapter/fyers',
              'About' => '/human',
              _ => '/',
            }),
          ),
          copy: [CopySlot(
            left: 75,
            top: 250,
            width: 700,
            phoneAlignment: Alignment.centerLeft,
            child: RevealGroup(
              start: const Duration(milliseconds: 260),
              spacing: 0,
              children: [
                HandwrittenAccent(
                  text: 'Good things\nare built by\ncurious people.',
                  style: Type.handHero,
                  color: palette.onWorld,
                  rotation: -0.018,
                  shadow: false,
                ),
                const SizedBox(height: 38),
                Text(
                  "I'm Gyan Upadhyay",
                  style: Type.titleSm.copyWith(
                    color: palette.onWorld,
                    shadows: [
                      Shadow(color: palette.worldTextShadow, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: T.s8),
                SizedBox(
                  width: 300,
                  child: Text(
                    'A Flutter engineer, product builder,\nand an explorer at heart.',
                    style: Type.body.copyWith(color: palette.onWorldMuted),
                  ),
                ),
                const SizedBox(height: 26),
                // Measured against the reference: a 321x66 pill at (75, 645).
                PillButton(
                  label: 'Begin the Journey',
                  onPressed: () => widget.onNavigate('/workshop'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 34,
                    vertical: 19,
                  ),
                ),
              ],
            ),
          )],
          // The signpost: four planks pointing into the world. It hangs off
          // the right edge of the frame, which is the first thing a narrow
          // viewport loses — so on a phone the same four routes become a list
          // under the copy instead.
          accents: [
            At(
              right: 34,
              top: 200,
              child: Reveal(
                delay: const Duration(milliseconds: 520),
                offset: const Offset(24, 0),
                child: _Signpost(signs: _signs, onSelect: widget.onNavigate),
              ),
            ),
          ],
          compactExtras: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(T.s24, 0, T.s24, T.s64),
                child: Reveal(
                  delay: const Duration(milliseconds: 520),
                  child: CompactDestinationList(
                    title: 'Or go straight there',
                    children: [
                      for (final sign in _signs)
                        CompactDestination(
                          label: sign.label,
                          onTap: () => widget.onNavigate(sign.route),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          footer: ScrollHint(visible: !_scrolled),
        ),
        children: [
          // ---------------------------------------------------------- world
          SceneLayer(seed: 11, paint: [Landscape.sky]),

          ParallaxLayer(
            depth: 0.12,
            child: SceneLayer(
              seed: 21,
              paint: [
                Landscape.clouds(
                    seed: 21, band: 0.10, count: 5, speed: 0.0032, scale: 0.62),
                Landscape.clouds(
                    seed: 33, band: 0.21, count: 4, speed: 0.0048, scale: 0.44,
                    opacity: 0.9),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.22,
            child: SceneLayer(
              seed: 7,
              repaintOnTime: false,
              paint: [
                Landscape.mountains(
                  seed: 7,
                  top: 0.11,
                  bottom: 0.60,
                  roughness: 5.5,
                  distance: 0.42,
                ),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.34,
            child: SceneLayer(
              seed: 13,
              repaintOnTime: false,
              paint: [
                Landscape.mountains(
                  seed: 13,
                  top: 0.26,
                  bottom: 0.64,
                  roughness: 8.0,
                  distance: 0.22,
                  snow: false,
                  tint: T.mountainNear,
                ),
              ],
            ),
          ),

          // The far shore the town is built on.
          ParallaxLayer(
            depth: 0.40,
            child: SceneLayer(
              seed: 37,
              repaintOnTime: false,
              paint: [
                Landscape.hills(
                  seed: 37,
                  top: 0.42,
                  bottom: 0.66,
                  distance: 0.34,
                  amplitude: 0.26,
                  trees: false,
                  color: const Color(0xFF7E9A6E),
                  shape: _farShore,
                ),
              ],
            ),
          ),

          // The lakeside town nestles on that shore.
          ParallaxLayer(
            depth: 0.42,
            child: SceneLayer(
              seed: 29,
              repaintOnTime: false,
              paint: [
                Landscape.town(
                  seed: 29,
                  distance: 0.22,
                  count: 90,
                  bounds: (size) => Rect.fromLTWH(
                    size.width * 0.24,
                    size.height * 0.505,
                    size.width * 0.52,
                    size.height * 0.085,
                  ),
                ),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.5,
            child: SceneLayer(
              seed: 41,
              paint: [
                Landscape.lake(seed: 41, top: 0.52, bottom: 0.80, shore: _waterLine),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.62,
            child: SceneLayer(
              seed: 17,
              repaintOnTime: false,
              paint: [
                Landscape.hills(
                  seed: 17,
                  top: 0.60,
                  bottom: 0.98,
                  distance: 0.10,
                  amplitude: 0.34,
                  shape: _nearBank,
                  treeCount: 44,
                  treeScale: 0.8,
                ),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.8,
            child: SceneLayer(
              seed: 23,
              repaintOnTime: false,
              paint: [
                Landscape.ground(
                  seed: 23,
                  top: 0.78,
                  amplitude: 0.18,
                  shape: _meadow,
                ),
              ],
            ),
          ),

          ParallaxLayer(
            depth: 0.3,
            child: SceneLayer(seed: 55, paint: [Landscape.birds(seed: 55, band: 0.2)]),
          ),

          // ------------------------------------------------------ character
          ParallaxLayer(
            depth: 0.9,
            child: SceneLayer(seed: 61, paint: [_wanderer]),
          ),

          // Foreground foliage frames the valley.
          ParallaxLayer(
            depth: 1.0,
            child: SceneLayer(
              seed: 71,
              repaintOnTime: false,
              paint: [Landscape.foliageFrame(seed: 71, scale: 1.05)],
            ),
          ),

          SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),

        ],
      ),
    );
  }

  /// The far bank drops away through the middle of the frame so the bay
  /// opens up behind the town instead of reading as a stripe.
  static double _farShore(double t) => 0.26 * math.sin(t * math.pi).clamp(0.0, 1.0);

  /// Top edge of the water: hugs the far bank, curving down at the sides.
  static double _waterLine(double t) {
    final centre = math.sin(t * math.pi);
    return 0.34 - 0.2 * centre + 0.05 * math.sin(t * 9.0);
  }

  /// Near banks climb at the left and right edges, enclosing the view.
  static double _nearBank(double t) {
    final edge = math.pow((t - 0.5).abs() * 2, 2.2).toDouble();
    return 0.26 - edge * 0.52;
  }

  /// The meadow the wanderer stands on dips slightly toward the water.
  static double _meadow(double t) => -0.06 * math.sin(t * math.pi);

  static void _wanderer(Canvas canvas, Size size, ScenePaintContext ctx) {
    Character.paint(
      canvas,
      Offset(size.width * 0.41, size.height * 1.0),
      size.height * 0.52,
      Pose.standingBack,
      CharacterPalette.day,
      ctx,
      breathe: ctx.time * 1.1,
    );
  }
}

/// The wooden post with four arrow planks, frame 01's right side.
class _Signpost extends StatelessWidget {
  const _Signpost({required this.signs, required this.onSelect});

  final List<({String label, String route})> signs;
  final void Function(String route) onSelect;

  @override
  Widget build(BuildContext context) {
    const rotations = [-0.035, 0.028, -0.022, 0.034];
    const offsets = [0.0, 22.0, 6.0, 32.0];

    return SizedBox(
      width: 380,
      height: 470,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The post itself.
          Positioned(
            left: 150,
            top: 40,
            child: CustomPaint(
              size: const Size(30, 420),
              painter: _PostPainter(),
            ),
          ),
          for (var i = 0; i < signs.length; i++)
            Positioned(
              left: offsets[i],
              top: 40.0 + i * 62,
              child: Hotspot(
                label: '${signs[i].label} — open this part of the world',
                tooltip: signs[i].label,
                onActivate: () => onSelect(signs[i].route),
                builder: (context, active) => WoodenSign(
                  lines: [signs[i].label],
                  width: 205,
                  height: 62,
                  rotation: rotations[i],
                  arrow: SignArrow.right,
                  seed: 4 + i,
                  active: active,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 6, size.width, size.height),
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          colors: [T.woodLight, T.wood, T.woodDark],
          stops: [0.0, 0.4, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_PostPainter oldDelegate) => false;
}
