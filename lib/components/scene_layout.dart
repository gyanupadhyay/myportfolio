import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import '../app/theme/typography.dart';
import '../world/stage.dart';

/// The first copy slot's band: it scrolls when the block is taller than the
/// viewport, and stays out of the way when it is not.
///
/// A viewport fills its band whether or not the copy does, and an opaque one
/// would eat every click on the art behind the empty half of it — the journey
/// map's stops sit under exactly that. A translucent one lets those clicks
/// through and still takes a drag anywhere in the band, but it also drops the
/// wheel, which a parent only sees when the child claims the pointer. So the
/// wheel is picked up here instead, through the resolver: over the copy the
/// scroll view registers first and this handler is dropped, and over the empty
/// part of the band nothing else claims it, so the page still moves.
class _ScrollBand extends StatefulWidget {
  const _ScrollBand({
    required this.alignment,
    required this.padding,
    required this.child,
  });

  final Alignment alignment;
  final EdgeInsets padding;
  final Widget child;

  @override
  State<_ScrollBand> createState() => _ScrollBandState();
}

class _ScrollBandState extends State<_ScrollBand> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wheel(PointerEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final position = _controller.position;
    final target = (position.pixels + event.scrollDelta.dy)
        .clamp(0.0, position.maxScrollExtent);
    if (target != position.pixels) position.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(event, _wheel);
        }
      },
      child: Align(
        alignment: widget.alignment,
        child: SingleChildScrollView(
          controller: _controller,
          hitTestBehavior: HitTestBehavior.translucent,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Where a scene's main copy sits, and how it behaves when the viewport is too
/// narrow to hold it where the reference frame put it.
///
/// On desktop the anchors are used verbatim, so the composed frames reproduce
/// exactly. On a phone the block is lifted out of its absolute position and
/// reflowed into the readable band between the top bar and the bottom bar,
/// scrolling if it does not fit.
@immutable
class CopySlot {
  const CopySlot({
    required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.phoneAlignment = Alignment.center,
    this.scrim = true,
  });

  final Widget child;

  /// Anchors in UI design units, as composed for the reference frame.
  final double? left, top, right, bottom, width;

  /// Where the block settles inside the phone band when it is shorter than it.
  final Alignment phoneAlignment;

  /// Whether to lay a readability wash behind the block on a phone, where copy
  /// sits directly over the busiest part of the art.
  final bool scrim;
}

/// The responsive chrome for a scene, laid out in UI design space.
///
/// Pass this to `WorldStage.ui`. Slots are positioned against the real screen
/// edges at every size; only [accents] — decoration that has nowhere to go on a
/// small screen — is dropped on a phone.
class SceneUi extends StatelessWidget {
  const SceneUi({
    super.key,
    this.topBar,
    this.leading,
    this.copy = const [],
    this.accents = const [],
    this.extras = const [],
    this.trailing,
    this.footer,
    this.compactExtras = const [],
  });

  /// Full-bleed bar pinned to the top — the nav.
  final Widget? topBar;

  /// Top-left affordance, usually a back control.
  final Widget? leading;

  /// The scene's main text blocks, in reading order. Placed at their composed
  /// coordinates where there is room, and stacked into one scrolling column on
  /// a phone.
  final List<CopySlot> copy;

  /// Decorative pieces positioned with [At]. Hidden on a phone, where there is
  /// no room for anything that is not load-bearing.
  final List<Widget> accents;

  /// Positioned widgets kept at every size. Anchor these to an edge, not to a
  /// point in the middle of the composition.
  final List<Widget> extras;

  /// Shown on phone only — usually the list that stands in for hotspots
  /// scattered across art a phone cannot show all of. A tablet keeps the
  /// composed layout, so it gets [accents] instead.
  final List<Widget> compactExtras;

  /// Primary action, bottom-right (bottom-centre and full width on a phone).
  final Widget? trailing;

  /// Centred hint along the bottom edge. Dropped on a phone when [trailing]
  /// also wants that space.
  final Widget? footer;

  /// Height the top bar occupies, so the copy band can clear it.
  static double topBarHeight(StageForm form) =>
      form.pick(phone: 86.0, tablet: 104.0, desktop: 120.0);

  /// Height reserved along the bottom for [trailing] and [footer].
  double _bottomBandHeight(StageForm form) {
    if (!form.isPhone) return 0;
    var h = 0.0;
    if (trailing != null) h += 96;
    if (footer != null) h += 58;
    return h == 0 ? 0 : h + 20;
  }

  @override
  Widget build(BuildContext context) {
    final stage = WorldStage.of(context);
    final form = stage.form;
    final gutter = stage.gutter;

    return form.isPhone
        ? _buildPhone(context, stage, gutter)
        : _buildRoomy(context, stage, gutter);
  }

  // --------------------------------------------------------------- desktop

  Widget _buildRoomy(BuildContext context, StageState stage, EdgeInsets gutter) {
    final box = stage.uiSize;
    final reference = T.uiReference(stage.form);
    // A portrait tablet gets a box far taller than the frame was composed for.
    // Absolute `top` anchors would strand the copy in the upper fifth, so the
    // block is centred in the leftover height instead.
    final centreCopy = box.height > reference.height * 1.15;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Only the first slot is re-flowed: the rest are anchored relative to
        // it in the composition, so moving them independently would break it.
        for (final (i, slot) in copy.indexed)
          if (i == 0)
            _scrollingBand(slot, stage, gutter, centreCopy: centreCopy)
          else
            Positioned(
              left: slot.left,
              top: slot.top,
              right: slot.right,
              bottom: slot.bottom,
              width: slot.width,
              child: slot.child,
            ),

        ...accents,
        ...extras,

        if (topBar case final bar?)
          Positioned(left: 0, right: 0, top: stage.safeInsets.top, child: bar),

        if (leading case final lead?)
          Positioned(left: gutter.left, top: gutter.top, child: lead),

        if (footer case final foot?)
          Positioned(
            left: gutter.left,
            right: gutter.right,
            bottom: gutter.bottom * 0.5,
            child: Center(child: foot),
          ),

        if (trailing case final trail?)
          Positioned(
            right: gutter.right,
            bottom: gutter.bottom * 0.7,
            child: trail,
          ),
      ],
    );
  }

  /// How far the band reaches past the block, so a panel's drop shadow — 28
  /// units of blur, thrown 10 down — is not shaved off by the scroll
  /// viewport's clip. The child is padded to match, so the copy still lands
  /// exactly where it was composed. The top is tightest: every unit of it is
  /// a unit of scrolled copy left showing above the composition.
  static const _bleed = EdgeInsets.fromLTRB(40, 32, 40, 48);

  /// The first copy slot, as a band that scrolls when the block is taller than
  /// the viewport.
  ///
  /// A laptop screen is shorter than the 861-unit frame these scenes were
  /// composed at, so the tail of a long block — the observatory's system card —
  /// used to sit under the fold with no way to reach it. The band runs to the
  /// bottom edge rather than the bottom gutter, because composed blocks lean
  /// into that margin and cutting there would hide copy that used to show.
  Widget _scrollingBand(
    CopySlot slot,
    StageState stage,
    EdgeInsets gutter, {
    required bool centreCopy,
  }) {
    final left = slot.left ?? (slot.right != null ? null : gutter.left);
    final right = left == null ? slot.right : null;
    final top = centreCopy
        ? gutter.top + SceneUi.topBarHeight(stage.form)
        : slot.top;

    return Positioned(
      left: left == null ? null : left - _bleed.left,
      right: right == null ? null : right - _bleed.right,
      width: slot.width == null ? null : slot.width! + _bleed.horizontal,
      top: top == null ? null : top - _bleed.top,
      bottom: centreCopy ? gutter.bottom : 0,
      child: _ScrollBand(
        alignment: centreCopy ? Alignment.centerLeft : Alignment.topLeft,
        padding: _bleed.copyWith(bottom: 0),
        child: slot.child,
      ),
    );
  }

  // ----------------------------------------------------------------- phone

  Widget _buildPhone(BuildContext context, StageState stage, EdgeInsets gutter) {
    final palette = Lighting.paletteOf(context);
    final bandTop = stage.safeInsets.top + SceneUi.topBarHeight(stage.form);
    final bandBottom = gutter.bottom + _bottomBandHeight(stage.form);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (copy.isNotEmpty) ...[
          if (copy.any((s) => s.scrim))
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.panel.withValues(alpha: 0.58),
                        palette.panel.withValues(alpha: 0.86),
                        palette.panel.withValues(alpha: 0.58),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: gutter.left,
            right: gutter.right,
            top: bandTop,
            bottom: bandBottom,
            child: Align(
              alignment: copy.first.phoneAlignment,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: T.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, slot) in copy.indexed) ...[
                      if (i > 0) const SizedBox(height: T.s24),
                      slot.child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],

        ...extras,
        ...compactExtras,

        if (topBar case final bar?)
          Positioned(left: 0, right: 0, top: stage.safeInsets.top, child: bar),

        if (leading case final lead?)
          Positioned(
            left: gutter.left,
            top: stage.safeInsets.top + T.s8,
            child: lead,
          ),

        // The action spans the gutter on a phone rather than hugging a corner.
        if (trailing != null || footer != null)
          Positioned(
            left: gutter.left,
            right: gutter.right,
            bottom: gutter.bottom * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing case final trail?)
                  SizedBox(width: double.infinity, child: Center(child: trail)),
                if (trailing != null && footer != null)
                  const SizedBox(height: T.s8),
                if (footer case final foot?) Center(child: foot),
              ],
            ),
          ),
      ],
    );
  }
}

/// A full-width destination button — what a signpost plank, a prop hotspot or
/// a map pin turns into once the art they sit on is off-screen.
class CompactDestination extends StatelessWidget {
  const CompactDestination({
    super.key,
    required this.label,
    required this.onTap,
    this.detail,
    this.icon = Icons.chevron_right,
    this.enabled = true,
  });

  final String label;
  final String? detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: palette.panel.withValues(alpha: enabled ? 0.92 : 0.5),
        borderRadius: BorderRadius.circular(T.rSm),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(T.rSm),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: T.s16,
              vertical: T.s12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(color: palette.panelBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Type.label.copyWith(
                          color: palette.onPanel
                              .withValues(alpha: enabled ? 1 : 0.6),
                        ),
                      ),
                      if (detail case final d?)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            d,
                            style: Type.labelSm.copyWith(
                              color: palette.onPanelMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  size: 24,
                  color: palette.onPanelMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A stack of [CompactDestination]s, anchored above the bottom band.
class CompactDestinationList extends StatelessWidget {
  const CompactDestinationList({
    super.key,
    required this.children,
    this.title,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title case final t?)
          Padding(
            padding: const EdgeInsets.only(bottom: T.s8),
            child: Text(
              t,
              style: Type.labelSm.copyWith(color: palette.onPanelMuted),
            ),
          ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: T.s8),
          children[i],
        ],
      ],
    );
  }
}
