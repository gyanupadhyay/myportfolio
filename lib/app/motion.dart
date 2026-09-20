import 'package:flutter/material.dart';

/// Central reduced-motion gate.
///
/// Every animation in the app asks this before moving. When the visitor has
/// asked their OS for reduced motion the world still renders in full — it just
/// stops drifting, shimmering and flickering, per the PRD's fallback rule.
class Motion extends InheritedWidget {
  const Motion({super.key, required this.reduced, required super.child});

  final bool reduced;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Motion>()?.reduced ?? false;

  /// Wraps [child] and resolves the flag from platform settings, allowing an
  /// explicit [override] for testing and for the in-app toggle.
  static Widget resolve({required Widget child, bool? override}) {
    return Builder(
      builder: (context) {
        final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        return Motion(reduced: override ?? disabled, child: child);
      },
    );
  }

  @override
  bool updateShouldNotify(Motion oldWidget) => oldWidget.reduced != reduced;
}

/// Convenience: returns [duration], or [Duration.zero] under reduced motion.
Duration motionDuration(BuildContext context, Duration duration) =>
    Motion.of(context) ? Duration.zero : duration;
