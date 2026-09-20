import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/ambience.dart';
import '../app/motion.dart';
import '../app/theme/day_night.dart';
import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import 'painters/landscape.dart';
import 'painters/paint_kit.dart';

/// The design space the reference frames were composed in.
///
/// 1440x861 is the mockups' 1.672 aspect ratio; art and UI geometry are
/// measured against `docs/reference` in exactly this space.
///
/// It is the *reference*, not a fixed canvas. [WorldStage] re-proportions the
/// art box to the viewport's aspect ratio (painters are written in fractions,
/// so the composition simply re-flows) and fits a per-form UI box on top. At
/// exactly 1440x861 both boxes are this size and the frames reproduce pixel
/// for pixel; at any other shape nothing is cropped off the edges.
const Size kDesignSize = Size(1440, 861);

/// Ambient state shared by every layer of the active scene.
@immutable
class StageState {
  const StageState({
    required this.time,
    required this.pointer,
    required this.reduced,
    required this.lighting,
    required this.composed,
    required this.size,
    required this.form,
    required this.viewport,
    required this.uiSize,
    required this.uiScale,
    required this.safeInsets,
  });

  /// Seconds since the stage mounted; frozen at 0 under reduced motion.
  final double time;

  /// Pointer position in design space, normalised to −1…1 from centre.
  /// Drives parallax without the visitor having to scroll.
  final Offset pointer;

  final bool reduced;

  /// The light this scene is actually rendering in, after the visitor's
  /// day/night choice has been applied.
  final SceneLighting lighting;

  /// The light the scene was *composed* in, before that choice.
  ///
  /// Kept alongside [lighting] because the two are not recoverable from each
  /// other: a scene written for the night and a daylight scene the visitor
  /// turned down both resolve to `night`, and only the second one is
  /// something the toggle did.
  final SceneLighting composed;

  /// The art box, in world design units. Its aspect ratio tracks the viewport
  /// so scenes are not cropped; position art against it in fractions, or with
  /// [WorldAt], never with absolute numbers.
  final Size size;

  /// Which layout this viewport gets.
  final StageForm form;

  /// The real viewport, in logical pixels.
  final Size viewport;

  /// The UI box, in UI design units. Covers the viewport exactly, so `left: 0`
  /// in the `ui` slot is the real left edge of the screen.
  final Size uiSize;

  /// UI design units → logical pixels.
  final double uiScale;

  /// Display cutouts and system bars, converted into UI design units.
  final EdgeInsets safeInsets;

  LightingPalette get palette => LightingPalette.of(lighting);

  /// Page gutter for this form, already widened past any display cutout.
  EdgeInsets get gutter {
    final g = T.gutter(form);
    return EdgeInsets.fromLTRB(
      g + safeInsets.left,
      g + safeInsets.top,
      g + safeInsets.right,
      g + safeInsets.bottom,
    );
  }
}

class _StageScope extends InheritedWidget {
  const _StageScope({required this.state, required super.child});

  final StageState state;

  @override
  bool updateShouldNotify(_StageScope oldWidget) => oldWidget.state != state;
}

/// Hosts one scene: runs the clock, tracks the pointer, sizes the two design
/// spaces against the viewport and publishes [StageState] to its descendants.
///
/// There are two layers and they scale differently, which is the whole point:
///
///  * [children] is the **world** — painted art and anything pinned to it. It
///    lives in a box whose aspect ratio follows the viewport, so the painters
///    re-compose instead of being cropped. Pin to it with [WorldAt], which
///    takes fractions, not pixels.
///  * [ui] is the **chrome** — nav, copy, buttons. It lives in a per-form box
///    ([T.uiReference]) stretched to cover the viewport exactly, so `left: 0`
///    is the real screen edge and text stays legible on a phone.
class WorldStage extends StatefulWidget {
  const WorldStage({
    super.key,
    required this.lighting,
    required this.children,
    this.ui,
    this.designSize = kDesignSize,
    this.fit = BoxFit.cover,
    this.reproportionArt = true,
  });

  final SceneLighting lighting;

  /// The light this scene was *composed* in. What it actually renders in is
  /// this run through the visitor's day/night choice — see [DayNightScope].
  SceneLighting lightingIn(BuildContext context) =>
      DayNightScope.resolve(context, lighting);

  /// Layers, painted back to front. Use [SceneLayer] and [ParallaxLayer].
  final List<Widget> children;

  /// The responsive overlay, laid out in UI design space. Use `SceneUi`.
  final Widget? ui;

  /// The art box's reference size. Its *area* is preserved when the box is
  /// re-proportioned to the viewport; only its aspect ratio changes.
  final Size designSize;
  final BoxFit fit;

  /// Whether the art box may follow the viewport's aspect ratio. Off for the
  /// rare layer that really does assume 1440x861.
  final bool reproportionArt;

  /// The art box for [viewport]: same height as the reference, width stretched
  /// to the viewport's aspect ratio within [T.worldAspectMin]/[T.worldAspectMax].
  static Size artBoxFor(Size viewport, Size reference) {
    if (viewport.isEmpty) return reference;
    final aspect = (viewport.width / viewport.height)
        .clamp(T.worldAspectMin, T.worldAspectMax);
    return Size(reference.height * aspect, reference.height);
  }

  static StageState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StageScope>();
    assert(scope != null, 'No WorldStage above this widget.');
    return scope!.state;
  }

  @override
  State<WorldStage> createState() => _WorldStageState();
}

class _WorldStageState extends State<WorldStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;
  Offset _pointer = Offset.zero;
  Offset _pointerTarget = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final reduced = Motion.of(context);
    // Ease the pointer so parallax glides instead of snapping.
    final eased = Offset(
      _pointer.dx + (_pointerTarget.dx - _pointer.dx) * 0.08,
      _pointer.dy + (_pointerTarget.dy - _pointer.dy) * 0.08,
    );
    final nextTime = reduced ? 0.0 : elapsed.inMicroseconds / 1e6;
    if (nextTime == _time && (eased - _pointer).distance < 0.0005) return;
    setState(() {
      _time = nextTime;
      _pointer = reduced ? Offset.zero : eased;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Report the scene's lighting so ambience can follow the world. This runs
    // again when the day/night choice changes, so the loop follows the toggle.
    AmbienceScope.maybeOf(context)?.enterScene(widget.lightingIn(context));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.of(context);
    final media = MediaQuery.of(context);
    final lighting = widget.lightingIn(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : media.size.height,
        );
        final form = T.formFor(viewport.width);

        // ------------------------------------------------------------ world
        // The art box follows the viewport's shape, so `cover` has almost
        // nothing left to crop and the painters re-compose instead.
        final artBox = widget.reproportionArt
            ? WorldStage.artBoxFor(viewport, widget.designSize)
            : widget.designSize;
        final worldScale = switch (widget.fit) {
          BoxFit.contain => _min(
              viewport.width / artBox.width,
              viewport.height / artBox.height,
            ),
          _ => _max(
              viewport.width / artBox.width,
              viewport.height / artBox.height,
            ),
        };

        // --------------------------------------------------------------- ui
        // Contain a per-form reference box, then grow the box back out to
        // cover the viewport exactly. Nothing is ever cropped off the chrome.
        final uiRef = T.uiReference(form);
        final uiScale = _min(
          viewport.width / uiRef.width,
          viewport.height / uiRef.height,
        );
        final uiBox = uiScale <= 0
            ? uiRef
            : Size(viewport.width / uiScale, viewport.height / uiScale);

        final padding = media.padding;
        final safeInsets = uiScale <= 0
            ? EdgeInsets.zero
            : EdgeInsets.fromLTRB(
                padding.left / uiScale,
                padding.top / uiScale,
                padding.right / uiScale,
                padding.bottom / uiScale,
              );

        final state = StageState(
          time: _time,
          pointer: _pointer,
          reduced: reduced,
          lighting: lighting,
          composed: widget.lighting,
          size: artBox,
          form: form,
          viewport: viewport,
          uiSize: uiBox,
          uiScale: uiScale,
          safeInsets: safeInsets,
        );

        return MouseRegion(
          onHover: (event) {
            if (reduced) return;
            final local = event.localPosition;
            _pointerTarget = Offset(
              ((local.dx / viewport.width) * 2 - 1).clamp(-1.0, 1.0),
              ((local.dy / viewport.height) * 2 - 1).clamp(-1.0, 1.0),
            );
          },
          onExit: (_) => _pointerTarget = Offset.zero,
          child: Lighting(
            lighting: lighting,
            // Scenes are painted, not Material surfaces, but text still needs
            // a Material ancestor to avoid the debug underline.
            child: _StageScope(
              state: state,
              child: Material(
                type: MaterialType.transparency,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ScaledBox(
                        size: artBox,
                        scale: worldScale,
                        alignment: Alignment.center,
                        // Art is illustration: a bumped system font size must
                        // not reflow a painted frame.
                        clampTextScale: true,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final child in widget.children)
                              // Bare painted layers fill the stage; `At`,
                              // `WorldAt` and `ParallaxLayer` position
                              // themselves.
                              if (child is SceneLayer)
                                Positioned.fill(child: child)
                              else
                                child,
                          ],
                        ),
                      ),
                      if (widget.ui case final ui?)
                        _ScaledBox(
                          size: uiBox,
                          scale: uiScale,
                          alignment: Alignment.topLeft,
                          child: ui,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;

/// A fixed-size design box scaled into the viewport.
class _ScaledBox extends StatelessWidget {
  const _ScaledBox({
    required this.size,
    required this.scale,
    required this.alignment,
    required this.child,
    this.clampTextScale = false,
  });

  final Size size;
  final double scale;
  final Alignment alignment;
  final Widget child;
  final bool clampTextScale;

  @override
  Widget build(BuildContext context) {
    Widget box = SizedBox(width: size.width, height: size.height, child: child);
    if (clampTextScale) {
      box = MediaQuery.withNoTextScaling(child: box);
    }
    return FittedBox(
      fit: BoxFit.none,
      alignment: alignment,
      clipBehavior: Clip.none,
      child: Transform.scale(scale: scale, alignment: alignment, child: box),
    );
  }
}

/// Positions a widget against the art box in fractions of its width and
/// height, so it stays pinned to the painting at any viewport shape.
///
/// This is what absolutely-positioned hotspots must use: the art box is
/// re-proportioned per viewport, so pixel coordinates measured on the 1440x861
/// reference drift off their prop as soon as the window is not that shape.
class WorldAt extends StatelessWidget {
  const WorldAt({
    super.key,
    required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
  });

  /// All values are fractions of the art box: 0 is its left/top edge, 1 the
  /// right/bottom.
  final double? left, top, right, bottom, width, height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = WorldStage.of(context).size;
    return Positioned(
      left: left == null ? null : left! * box.width,
      top: top == null ? null : top! * box.height,
      right: right == null ? null : right! * box.width,
      bottom: bottom == null ? null : bottom! * box.height,
      width: width == null ? null : width! * box.width,
      height: height == null ? null : height! * box.height,
      child: child,
    );
  }
}

/// A full-bleed painted layer inside a [WorldStage].
class SceneLayer extends StatelessWidget {
  const SceneLayer({
    super.key,
    required this.paint,
    this.seed = 1,
    this.repaintOnTime = true,
  });

  /// One or more paint functions, drawn in order.
  final List<ScenePaint> paint;

  final int seed;

  /// Set false for layers with no animation — they then repaint only on
  /// resize, which keeps the frame budget for the layers that do move.
  final bool repaintOnTime;

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _LayerPainter(
          paints: paint,
          ctx: ScenePaintContext(
            palette: stage.palette,
            noise: Noise(seed),
            time: repaintOnTime ? stage.time : 0,
          ),
          timeKey: repaintOnTime ? stage.time : 0,
        ),
        size: Size.infinite,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LayerPainter extends CustomPainter {
  _LayerPainter({
    required this.paints,
    required this.ctx,
    required this.timeKey,
  });

  final List<ScenePaint> paints;
  final ScenePaintContext ctx;
  final double timeKey;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in paints) {
      p(canvas, size, ctx);
    }
  }

  @override
  bool shouldRepaint(_LayerPainter oldDelegate) =>
      oldDelegate.timeKey != timeKey || oldDelegate.ctx.palette != ctx.palette;
}

/// Offsets its child by a fraction of the pointer travel, creating depth.
///
/// [depth] 0 is the far background (barely moves), 1 is the foreground.
class ParallaxLayer extends StatelessWidget {
  const ParallaxLayer({
    super.key,
    required this.depth,
    required this.child,
    this.maxShift = 26,
    this.verticalFactor = 0.45,
  });

  final double depth;
  final Widget child;

  /// Pixels of travel in design space at `depth == 1`.
  final double maxShift;

  /// Vertical parallax is subtler than horizontal.
  final double verticalFactor;

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    final shift = Offset(
      -stage.pointer.dx * maxShift * depth,
      -stage.pointer.dy * maxShift * depth * verticalFactor,
    );
    return Positioned.fill(
      child: Transform.translate(offset: shift, child: child),
    );
  }
}

/// Positions a widget in design-space coordinates.
class At extends StatelessWidget {
  const At({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  final double? left, top, right, bottom, width, height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    width: width,
    height: height,
    child: child,
  );
}
