import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/day_night.dart';
import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import 'plates.g.dart';
import 'stage.dart';

/// Painted scene plates.
///
/// The reference frames are paintings. Vector painters can echo their
/// composition but not their brushwork, so a scene can hang the painting
/// itself behind it instead: [ScenePlate] fills the stage with the plate, and
/// the live UI — nav, copy, buttons — carries on sitting on top of it.
///
/// Objects *inside* the painting stay interactive through [PlateHotspot],
/// which contributes the target and the hover response the flat image cannot.
///
/// On by default. The drawn world is still there for the scenes that have no
/// plate yet, for narrow viewports, and for a build that asks for it:
///
///     flutter run -d chrome --dart-define=PLATES=false
const bool kPaintedPlates = bool.fromEnvironment('PLATES', defaultValue: true);

/// Whether this viewport gets the painting.
///
/// Only the wide forms: a plate carries its copy at a fixed size and in a
/// fixed place, which a phone cannot re-flow. Narrow viewports keep the
/// painted-by-code world and the live, responsive UI over it.
bool platesOn(BuildContext context) =>
    kPaintedPlates && T.formFor(MediaQuery.sizeOf(context).width).isDesktop;

/// Moonlight for a plate painted in daylight.
///
/// Built the way a colourist would grade it rather than by pushing one
/// channel: desaturate ~70% toward luminance, then darken with a cool bias
/// and lift the blacks a little, which is what the eye reads as night.
///
/// Weighting blue instead — the obvious shortcut — leaves the picture
/// *brighter* in blue than the daylight original and turns every cloud into
/// glowing periwinkle. It looks like a filter laid over a sunlit painting,
/// because that is what it is. Preserving relative luminance keeps the
/// modelling in the art and simply turns the lights down.
const List<double> _moonlight = <double>[
  0.173, 0.140, 0.026, 0, 0,
  0.080, 0.271, 0.029, 0, 2,
  0.118, 0.231, 0.211, 0, 8,
  0, 0, 0, 1, 0,
];

/// The no-op grade, for the day end of the fade.
const List<double> _daylight = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

/// The grade [t] of the way from daylight to [_moonlight].
///
/// Public so a test can assert the thing the eye is meant to see — that the
/// grade actually takes light *out* of every colour it touches.
@visibleForTesting
List<double> plateGrade(double t) => <double>[
      for (var i = 0; i < 20; i++)
        _daylight[i] + (_moonlight[i] - _daylight[i]) * t,
    ];

/// How long the sun takes to go down when the visitor asks it to.
const _dusk = Duration(milliseconds: 900);

/// A painting hung behind a scene, with [children] pinned to it.
///
/// [children] are positioned in the plate's own pixel space ([imageSize]), so
/// a hotspot traced off the artwork keeps its place at every viewport size.
class ScenePlate extends StatelessWidget {
  const ScenePlate({
    super.key,
    required this.art,
    required this.lighting,
    this.children = const [],
    this.drift = 9,
    this.parallax = 16,
  });

  /// The file and its geometry, from `plates.g.dart`.
  final PlateArt art;

  /// The light the plate was painted in. If the visitor has asked for night
  /// and the painting is a daylit one, it is swapped for that plate's moonlit
  /// bake, or graded where no bake exists.
  final SceneLighting lighting;

  /// Hotspots and any other art-pinned widgets.
  final List<Widget> children;

  /// Pixels of slow ambient travel, so a still painting still breathes.
  final double drift;

  /// Pixels the plate follows the pointer, for a little depth.
  final double parallax;

  Widget _imageOf(String asset) => Image.asset(
        asset,
        width: art.size.width,
        height: art.size.height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      );

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    // Graded only when the toggle actually moved this scene into the dark:
    // a frame painted at night or indoors is already in its own light.
    final resolved = DayNightScope.resolve(context, lighting);
    final night = resolved == SceneLighting.night &&
        lighting != SceneLighting.night;
    final move = stage.reduced
        ? Offset.zero
        : Offset(
              math.sin(stage.time * 0.09),
              math.sin(stage.time * 0.13) * 0.6,
            ) *
            drift;
    final follow = Offset(
      -stage.pointer.dx * parallax,
      -stage.pointer.dy * parallax * 0.45,
    );

    final painting = Stack(
      children: [
        // Faded rather than switched: the toggle is a light going down, and a
        // painting that snaps to night reads as a different picture.
        //
        // Where the plate has a moonlit bake the fade is between two
        // paintings, which is the only way the sun comes out of the sky and
        // the stars come into it. Where it does not, the grade still runs at
        // paint time — the fallback that keeps every plate honest while the
        // rest of the art is made.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: night ? 1 : 0),
          duration: stage.reduced ? Duration.zero : _dusk,
          curve: Curves.easeInOut,
          child: _imageOf(art.asset),
          builder: (context, t, child) {
            if (t == 0) return child!;
            final dark = art.night;
            // Built only once the sun starts going down, so a visitor who
            // never asks for night never fetches the second painting.
            if (dark != null) {
              return Stack(
                children: [
                  child!,
                  Opacity(opacity: t, child: _imageOf(dark)),
                ],
              );
            }
            return ColorFiltered(
              colorFilter: ColorFilter.matrix(plateGrade(t)),
              child: child,
            );
          },
        ),
        // Hotspots are written in the painting's own coordinates; the padding
        // the plate was grown by shifts them down.
        Positioned.fill(
          child: Transform.translate(
            offset: art.origin,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        ),
      ],
    );

    return Positioned.fill(
      child: ClipRect(
        // The plate is already padded to a safe aspect by tool/make_plates.py,
        // so filling the viewport only ever crops into that margin.
        child: Transform.translate(
          offset: move + follow,
          child: Transform.scale(
            scale: 1 + (drift + parallax) * 2 / art.size.width,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox.fromSize(size: art.size, child: painting),
            ),
          ),
        ),
      ),
    );
  }
}

/// A clickable region of the painting.
///
/// The art already draws the object; this contributes what a painting cannot —
/// a target, a hover glow that says the object is live, a name for screen
/// readers, and a place in the tab order. [rect] is in the plate's pixel
/// space.
///
/// Keyboard reach is not a nicety here: plates are the *only* thing a desktop
/// visitor gets, so a mouse-only hotspot makes the workshop's Explore menu,
/// the landing signpost, the map's five stops and — worst — the sunset's
/// contact buttons unreachable without a pointer.
class PlateHotspot extends StatefulWidget {
  const PlateHotspot({
    super.key,
    required this.rect,
    required this.label,
    required this.onTap,
  });

  final Rect rect;
  final String label;
  final VoidCallback onTap;

  @override
  State<PlateHotspot> createState() => _PlateHotspotState();
}

class _PlateHotspotState extends State<PlateHotspot> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // Hover fades a warm glow up over the painted object. Focus has to say
    // the same thing to someone who cannot see a cursor, so it draws a ring
    // as well: a glow alone is easy to lose against the art it sits on.
    final lit = _hovered || _focused;
    return Positioned.fromRect(
      rect: widget.rect,
      child: Semantics(
        button: true,
        label: widget.label,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onTap();
              return null;
            }),
          },
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              opacity: lit ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: _focused
                      ? Border.all(color: const Color(0xFFFFE9B0), width: 2)
                      : null,
                  gradient: const RadialGradient(
                    radius: 0.85,
                    colors: [Color(0x59FFE9B0), Color(0x00FFE9B0)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The veil the painted frames carry under their copy.
///
/// Every reference frame warms or darkens the area its text sits on; without
/// it, body copy lands straight on the painting and loses its contrast.
class PlateScrim extends StatelessWidget {
  const PlateScrim({
    super.key,
    this.color,
    this.extent = 0.46,
    this.strength = 0.9,
  });

  /// The veil's colour. Left unset it follows the light in force — warm under
  /// the daylight's dark ink, dark under the pale ink every other light uses.
  ///
  /// It has to be read rather than fixed: the copy over it takes its colour
  /// from the same palette, so a veil pinned to cream puts the night's
  /// near-white headline on a near-white ground.
  final Color? color;

  /// How far across the frame it reaches.
  final double extent;

  /// Its opacity where it is thickest.
  final double strength;

  @override
  Widget build(BuildContext context) {
    final veil = color ?? Lighting.paletteOf(context).worldScrim;
    return Positioned.fill(
      child: IgnorePointer(
        // Crossfaded on the same clock as the plate's own grade, so the veil
        // and the painting under it go down together.
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: veil),
          duration: WorldStage.of(context).reduced ? Duration.zero : _dusk,
          curve: Curves.easeInOut,
          builder: (context, tinted, _) {
            final c = tinted ?? veil;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, extent * 0.55, extent],
                  colors: [
                    c.withValues(alpha: strength),
                    c.withValues(alpha: strength * 0.62),
                    c.withValues(alpha: 0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
