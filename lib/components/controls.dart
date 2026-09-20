import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/theme/lighting.dart';
import '../app/theme/tokens.dart';
import '../app/theme/typography.dart';
import '../world/stage.dart';

/// The dark CTA pill — "Begin the Journey →" (frame 01), "Enter the Story →"
/// (frame 04).
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.background = T.ctaPill,
    this.foreground = const Color(0xFFF7F2E8),
    this.padding = const EdgeInsets.symmetric(horizontal: T.s24, vertical: T.s12),
    this.textStyle,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: motionDuration(context, T.dFast),
            curve: T.eOut,
            transform: Matrix4.translationValues(0, active ? -2 : 0, 0),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(T.rPill),
              border: _focused
                  ? Border.all(color: widget.foreground, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: active ? 0.34 : 0.22),
                  blurRadius: active ? 22 : 14,
                  offset: Offset(0, active ? 8 : 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: (widget.textStyle ?? Type.label).copyWith(color: widget.foreground),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: T.s8),
                  AnimatedSlide(
                    duration: motionDuration(context, T.dFast),
                    offset: Offset(active ? 0.22 : 0, 0),
                    child: Icon(widget.icon, size: 16, color: widget.foreground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Light pill tab bar — "Approach · Implementation · Learnings" (frame 07).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = WorldStage.of(context).form.isPhone;
    final children = [
      for (var i = 0; i < tabs.length; i++)
        _Tab(
          label: tabs[i],
          selected: i == index,
          onTap: () => onChanged(i),
          compact: compact,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE8).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(T.rPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Always a wrap, never a row: three labels do not fit on one
      // phone-width line, and they do not fit beside the panel they switch
      // either — which is where they now sit rather than in the frame's
      // opposite corner. A wrap that fits behaves exactly like a row.
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: children,
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
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
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? T.s12 : T.s16,
              vertical: T.s8,
            ),
            decoration: BoxDecoration(
              color: widget.selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(T.rPill),
              border: Border.all(
                color: _focused ? T.ctaPill : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: Type.label.copyWith(
                color: widget.selected ? T.ink : T.inkMuted,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The contact buttons in frame 12 — Email · LinkedIn · GitHub · Resume.
class IconAction {
  const IconAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class IconActionRow extends StatelessWidget {
  const IconActionRow({super.key, required this.actions, this.spacing = T.s12});

  final List<IconAction> actions;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final form = WorldStage.of(context).form;
    // The reference spacing is generous; on a phone it is the difference
    // between two rows of two and four rows of one.
    final gap = form.pick(
      phone: spacing.clamp(0.0, T.s12),
      tablet: spacing.clamp(0.0, T.s20),
      desktop: spacing,
    );
    final buttons = [for (final a in actions) _IconActionButton(action: a)];

    // The reference keeps all four contacts on one line. Above phone width the
    // row scales down to fit rather than wrapping, which would otherwise leave
    // a single button stranded underneath the other three.
    if (!form.isPhone) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                buttons[i],
              ],
            ],
          ),
        ),
      );
    }

    return Wrap(spacing: gap, runSpacing: gap, children: buttons);
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({required this.action});

  final IconAction action;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = Lighting.paletteOf(context);
    final form = WorldStage.of(context).form;
    final active = _hovered || _focused;
    // Four of these have to fit side by side; on a phone that means the
    // 30pt reference sizing has to come down or they wrap to four rows.
    final glyph = form.pick(phone: 20.0, tablet: 25.0, desktop: 30.0);
    final pad = form.pick(
      phone: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s12),
      tablet: const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s16),
      desktop: const EdgeInsets.symmetric(horizontal: T.s20, vertical: 18),
    );
    return Semantics(
      button: true,
      label: widget.action.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.action.onTap();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: widget.action.onTap,
          child: AnimatedContainer(
            duration: motionDuration(context, T.dFast),
            transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
            padding: pad,
            decoration: BoxDecoration(
              color: Color.lerp(palette.panel, Colors.white, active ? 0.12 : 0.0),
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(
                color: _focused ? palette.onPanel : palette.panelBorder,
                width: _focused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: active ? 20 : 12,
                  offset: Offset(0, active ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.action.icon, size: glyph, color: palette.onPanel),
                SizedBox(width: form.pick(phone: T.s6, desktop: T.s12)),
                Text(
                  widget.action.label,
                  style: Type.label.copyWith(
                      color: palette.onPanel, fontSize: glyph),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Any clickable object inside the painted world — the laptop, the cat, a
/// signpost plank, a journey node. Keyboard-reachable and labelled, which is
/// what keeps the world navigable without a mouse.
class Hotspot extends StatefulWidget {
  const Hotspot({
    super.key,
    required this.label,
    required this.onActivate,
    required this.builder,
    this.tooltip,
    this.cursor = SystemMouseCursors.click,
  });

  final String label;
  final String? tooltip;
  final VoidCallback onActivate;

  /// Receives whether the hotspot is hovered or focused.
  final Widget Function(BuildContext context, bool active) builder;

  final MouseCursor cursor;

  @override
  State<Hotspot> createState() => _HotspotState();
}

class _HotspotState extends State<Hotspot> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    Widget child = widget.builder(context, active);

    if (_focused) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Lighting.paletteOf(context).glow, width: 2),
          borderRadius: BorderRadius.circular(T.rSm),
        ),
        child: child,
      );
    }

    if (widget.tooltip != null) {
      child = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 380),
        child: child,
      );
    }

    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: widget.cursor,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onActivate();
            return null;
          }),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: GestureDetector(onTap: widget.onActivate, child: child),
      ),
    );
  }
}
