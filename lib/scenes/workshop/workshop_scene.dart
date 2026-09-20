import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme/lighting.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../components/controls.dart';
import '../../components/reveal.dart';
import '../../components/scene_layout.dart';
import '../../components/scene_ui.dart';
import '../../data/journey.dart';
import '../../world/painters/character.dart';
import '../../world/painters/interior.dart';
import '../../world/painters/landscape.dart';
import '../../world/painters/paint_kit.dart';
import '../../world/plate.dart';
import '../../world/plates.g.dart';
import '../../world/stage.dart';

/// Frame 02 — The Workshop / Entry Point.
///
/// A lit cabin: window onto the valley, desk with a laptop, whiteboard of
/// intentions, plants, books, the sleeping cat — and the Explore menu.
class WorkshopScene extends StatelessWidget {
  const WorkshopScene({super.key, required this.onNavigate});

  final void Function(String route) onNavigate;

  /// The painted Explore rows, traced off `assets/art/workshop.webp`. Same
  /// order as [workshopMenu].
  static const _menuHotspots = <Rect>[
    Rect.fromLTRB(1250, 516, 1595, 587),
    Rect.fromLTRB(1250, 587, 1595, 657),
    Rect.fromLTRB(1250, 657, 1595, 722),
    Rect.fromLTRB(1250, 722, 1595, 790),
    Rect.fromLTRB(1250, 790, 1595, 860),
  ];

  @override
  Widget build(BuildContext context) {
    // On a plate the painting carries the room, the board and the Explore
    // card; the scene puts targets on the painted rows.
    final plate = platesOn(context);
    return WorldStage(
      lighting: SceneLighting.interior,
      ui: SceneUi(
        leading: Reveal(child: _BackToWorld(onTap: () => onNavigate('/'))),
        // The light and the ambience, reachable from here rather than only
        // from the two screens that show a nav.
        extras: [
          At(right: T.s24, top: T.s24, child: AmbientToggles(composed: SceneLighting.interior)),
        ],
        // On a phone the props the hotspots cover are mostly off-frame, so
        // the Explore menu is the only way through — it gets the full width
        // rather than a 300-unit column hugging the right edge.
        accents: [
          if (!plate) At(
            right: 55,
            top: 440,
            width: 300,
            child: Reveal(
              delay: const Duration(milliseconds: 320),
              offset: const Offset(22, 0),
              child: _ExploreMenu(onNavigate: onNavigate),
            ),
          ),
        ],
        compactBelow: [
          Reveal(
            delay: const Duration(milliseconds: 320),
            // The same five destinations the painted card and the drawn
            // menu offer, so the way through the workshop does not change
            // with the viewport. Listing the journey stops here instead
            // sent "What's Next?" to /chapter/next, which is not a chapter.
            child: CompactDestinationList(
              title: 'Explore',
              children: [
                for (final item in workshopMenu)
                  CompactDestination(
                    label: item.label,
                    onTap: () => onNavigate(item.route),
                  ),
              ],
            ),
          ),
        ],
      ),
      children: plate
          ? [
              ScenePlate(
                art: plateWorkshop,
                lighting: SceneLighting.interior,
                children: [
                  for (var i = 0; i < workshopMenu.length; i++)
                    PlateHotspot(
                      rect: _menuHotspots[i],
                      label: workshopMenu[i].label,
                      onTap: () => onNavigate(workshopMenu[i].route),
                    ),
                ],
              ),
            ]
          : [
        // ------------------------------------------------------------ room
        SceneLayer(
          seed: 101,
          repaintOnTime: false,
          paint: [
            Interior.wall(seed: 101, planks: 11),
          ],
        ),

        // The window, and the valley beyond it.
        ParallaxLayer(
          depth: 0.1,
          child: SceneLayer(
            seed: 103,
            paint: [
              Interior.window(
                bounds: (size) => Rect.fromLTWH(
                  size.width * 0.271,
                  size.height * 0.168,
                  size.width * 0.389,
                  size.height * 0.406,
                ),
                columns: 3,
                rows: 2,
                view: [
                  _daylightSky,
                  Landscape.clouds(seed: 21, band: 0.22, count: 3, scale: 0.5),
                  Landscape.mountains(
                    seed: 7,
                    top: 0.18,
                    bottom: 0.78,
                    roughness: 4.5,
                    distance: 0.34,
                  ),
                  Landscape.hills(
                    seed: 37,
                    top: 0.56,
                    bottom: 0.95,
                    distance: 0.2,
                    amplitude: 0.3,
                    trees: false,
                    color: const Color(0xFF7E9A6E),
                  ),
                  Landscape.town(
                    seed: 29,
                    distance: 0.32,
                    count: 70,
                    bounds: (size) => Rect.fromLTWH(
                      size.width * 0.04,
                      size.height * 0.60,
                      size.width * 0.94,
                      size.height * 0.13,
                    ),
                  ),
                  Landscape.hills(
                    seed: 17,
                    top: 0.74,
                    bottom: 1.1,
                    distance: 0.06,
                    amplitude: 0.3,
                    treeCount: 22,
                    treeScale: 0.7,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Daylight pouring in across the room.
        SceneLayer(
          seed: 104,
          paint: [
            Interior.lightShaft(
              from: (size) => Offset(size.width * 0.5, size.height * 0.12),
              width: 300,
              angle: 1.15,
              opacity: 0.2,
            ),
          ],
        ),

        // ----------------------------------------------------------- props
        SceneLayer(seed: 105, repaintOnTime: false, paint: [_wallProps]),
        SceneLayer(
          seed: 107,
          repaintOnTime: false,
          paint: [Interior.desk(seed: 107, top: 0.743)],
        ),
        SceneLayer(seed: 109, paint: [_deskProps]),

        SceneLayer(seed: 91, repaintOnTime: false, paint: [Landscape.ambient]),

        // -------------------------------------------------------- hotspots
        // Invisible targets over the painted props: the world is clickable
        // and, just as importantly, tab-navigable.
        //
        // These sit *on* the painting, so they are pinned in fractions of the
        // art box rather than in pixels off the 1440x861 reference — the box
        // is re-proportioned per viewport and pixel anchors would slide off
        // their prop.
        WorldAt(
          left: 0.0139,
          top: 0.1974,
          width: 0.1493,
          height: 0.2671,
          child: _PropHotspot(
            label: 'Whiteboard — Ideas, Code, Products, A Better Tomorrow',
            tooltip: 'What I care about building',
            onTap: () => onNavigate('/human'),
          ),
        ),
        WorldAt(
          left: 0.1979,
          top: 0.5749,
          width: 0.1819,
          height: 0.2323,
          child: _PropHotspot(
            label: 'Laptop — open the projects',
            tooltip: 'Projects',
            onTap: () => onNavigate('/chapter/fyers'),
          ),
        ),
        WorldAt(
          right: 0.1806,
          top: 0.2671,
          width: 0.1215,
          height: 0.2323,
          child: _PropHotspot(
            label: 'World map — travel and the personal side',
            tooltip: 'Where I have been',
            onTap: () => onNavigate('/human'),
          ),
        ),
        // The cat is the one prop with nothing behind it, and the tooltip is
        // the whole joke — so it stays scenery rather than a button that a
        // screen reader offers and a cursor promises.
        WorldAt(
          left: 0.5972,
          top: 0.7201,
          width: 0.0972,
          height: 0.1161,
          child: Semantics(
            image: true,
            label: 'The cat, asleep on the desk',
            child: const Tooltip(
              message: 'Shhh.',
              waitDuration: Duration(milliseconds: 380),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  static void _daylightSky(Canvas canvas, Size size, ScenePaintContext ctx) {
    // The window looks onto daylight even though the room is warm-lit, so the
    // view uses the day palette rather than the scene's interior one.
    Kit.gradientRect(canvas, Offset.zero & size, const [
      Color(0xFF5E9FD4),
      Color(0xFF8FBEDE),
      Color(0xFFC9E2F0),
    ]);
  }

  /// Whiteboard, map poster and framed photos.
  static void _wallProps(Canvas canvas, Size size, ScenePaintContext ctx) {
    // Whiteboard, upper left.
    Interior.board(
      canvas,
      Rect.fromLTWH(size.width * 0.014, size.height * 0.197, size.width * 0.146,
          size.height * 0.267),
      workshopBoard,
      ctx,
      title: null,
      rotation: -0.012,
      style: const TextStyle(
        fontFamily: 'Caveat',
        fontSize: 31,
        color: Color(0xFF3A4A5A),
      ),
    );

    // Shelf with books and a plant, left wall.
    final shelfY = size.height * 0.60;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.05, shelfY, size.width * 0.18, 8),
      Paint()..color = const Color(0xFF53381F),
    );
    Interior.books(canvas, Offset(size.width * 0.085, shelfY), 42, 4, ctx, 21);
    Interior.books(canvas, Offset(size.width * 0.135, shelfY), 38, 3, ctx, 27);
    Interior.plant(canvas, Offset(size.width * 0.195, shelfY), 62, ctx, 31);

    // World map poster, right wall.
    Interior.frame(
      canvas,
      Rect.fromLTWH(size.width * 0.701, size.height * 0.267, size.width * 0.118,
          size.height * 0.232),
      rotation: 0.008,
      content: (canvas, inner) {
        canvas.drawRect(inner, Paint()..color = const Color(0xFFE8DFC8));
        // Loose landmasses — enough to read as a world map.
        final n = ctx.noise;
        final land = Paint()..color = const Color(0xFF8AA678);
        for (var i = 0; i < 9; i++) {
          final c = Offset(
            inner.left + n.at(41 + i) * inner.width,
            inner.top + n.at(71 + i) * inner.height,
          );
          canvas.drawPath(
            Kit.blob(c, inner.width * n.range(91 + i, 0.06, 0.15), n, 13 + i,
                points: 11, wobble: 0.4),
            land,
          );
        }
        // Route pins.
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(
              inner.left + n.at(131 + i) * inner.width,
              inner.top + n.at(151 + i) * inner.height,
            ),
            2.2,
            Paint()..color = const Color(0xFFC0503C),
          );
        }
      },
    );

    // Two small framed photos below the map.
    for (var i = 0; i < 2; i++) {
      Interior.frame(
        canvas,
        Rect.fromLTWH(size.width * (0.695 + i * 0.072), size.height * 0.17,
            size.width * 0.058, size.height * 0.095),
        rotation: i == 0 ? -0.03 : 0.025,
        content: (canvas, inner) {
          canvas.drawRect(
            inner,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9FC6E0), Color(0xFF6B9A64)],
              ).createShader(inner),
          );
          Kit.conifer(
            canvas,
            Offset(inner.center.dx, inner.bottom),
            inner.height * 0.7,
            const Color(0xFF2F4A33),
          );
        },
      );
    }

    // Hanging plant, top right corner.
    Interior.plant(canvas, Offset(size.width * 0.955, size.height * 0.30), 92, ctx, 37);
    // Floor plant, left.
    Interior.plant(canvas, Offset(size.width * 0.035, size.height * 0.98), 190, ctx, 43);
  }

  /// Laptop, notebook, mug, papers and the cat.
  static void _deskProps(Canvas canvas, Size size, ScenePaintContext ctx) {
    Interior.papers(
      canvas,
      Rect.fromLTWH(size.width * 0.15, size.height * 0.755, size.width * 0.17,
          size.height * 0.16),
      3,
      ctx,
      53,
    );

    Interior.laptop(
      canvas,
      Rect.fromLTWH(size.width * 0.20, size.height * 0.575, size.width * 0.165,
          size.height * 0.225),
      ctx,
    );

    Interior.books(canvas, Offset(size.width * 0.135, size.height * 0.755), 58, 4, ctx, 59);
    Interior.mug(canvas, Offset(size.width * 0.375, size.height * 0.775), 50, ctx);

    Interior.papers(
      canvas,
      Rect.fromLTWH(size.width * 0.49, size.height * 0.745, size.width * 0.135,
          size.height * 0.14),
      3,
      ctx,
      61,
    );

    // The cat, asleep by the window.
    Character.cat(
      canvas,
      Offset(size.width * 0.625, size.height * 0.79),
      70,
      ctx,
      curled: true,
      facing: -1,
    );

    Interior.plant(canvas, Offset(size.width * 0.175, size.height * 0.74), 62, ctx, 67);
    Interior.plant(canvas, Offset(size.width * 0.545, size.height * 0.74), 70, ctx, 71);
    Interior.books(canvas, Offset(size.width * 0.575, size.height * 0.74), 50, 3, ctx, 73);
  }
}

/// A transparent, focusable target over a painted prop.
class _PropHotspot extends StatelessWidget {
  const _PropHotspot({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: label,
      tooltip: tooltip,
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.rSm),
          color: active
              ? T.lampGlow.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: active ? T.lampGlow.withValues(alpha: 0.7) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: T.lampGlow.withValues(alpha: 0.28),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// The right-hand Explore panel from frame 02.
class _ExploreMenu extends StatefulWidget {
  const _ExploreMenu({required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  State<_ExploreMenu> createState() => _ExploreMenuState();
}

class _ExploreMenuState extends State<_ExploreMenu> {
  int _hovered = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Explore" header pill.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: T.s24, vertical: T.s12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EDE2).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(T.rPill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Explore',
            textAlign: TextAlign.center,
            style: Type.displayMd.copyWith(fontSize: 34, color: T.ink),
          ),
        ),
        const SizedBox(height: T.s16),
        for (var i = 0; i < workshopMenu.length; i++)
          _MenuRow(
            label: workshopMenu[i].label,
            hovered: _hovered == i,
            onHover: (v) => setState(() => _hovered = v ? i : -1),
            onTap: () => widget.onNavigate(workshopMenu[i].route),
          ),
      ],
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.label,
    required this.hovered,
    required this.onHover,
    required this.onTap,
  });

  final String label;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.hovered || _focused;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: widget.onHover,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onTap();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: motionDuration(context, T.dFast),
            curve: T.eOut,
            margin: const EdgeInsets.only(bottom: 2),
            padding: EdgeInsets.only(
              left: active ? T.s20 : T.s12,
              top: 17,
              bottom: 17,
              right: T.s12,
            ),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(
                color: _focused ? T.lampGlow : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: motionDuration(context, T.dFast),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? T.lampGlow
                        : const Color(0xFFE8DCC8).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: T.s12),
                Text(
                  widget.label,
                  style: Type.bodyLg.copyWith(
                    color: active ? Colors.white : const Color(0xFFEDE2D0),
                    shadows: const [Shadow(color: Color(0xAA1A1208), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "back out to the valley" affordance.
class _BackToWorld extends StatelessWidget {
  const _BackToWorld({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hotspot(
      label: 'Back to the valley',
      tooltip: 'Back to the valley',
      onActivate: onTap,
      builder: (context, active) => AnimatedContainer(
        duration: motionDuration(context, T.dFast),
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: active ? 0.45 : 0.28),
          borderRadius: BorderRadius.circular(T.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 14, color: Colors.white),
            const SizedBox(width: T.s6),
            Text('The valley', style: Type.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
