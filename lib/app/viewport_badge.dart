import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme/tokens.dart';

/// A corner readout of the live viewport and the layout it resolves to.
///
/// This exists to answer one question directly: when you resize the window or
/// change the browser's zoom, does the app actually see a different viewport?
/// If the numbers move, the responsive layout is working and any problem is in
/// the design. If they do not move, the app is not being told about the change.
///
/// Debug builds only — [kDebugMode] compiles it out of a release build, so it
/// cannot reach the published site. Add `?badge=off` to hide it.
class ViewportBadge extends StatelessWidget {
  const ViewportBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || Uri.base.queryParameters['badge'] == 'off') return child;

    final media = MediaQuery.of(context);
    final size = media.size;
    final form = T.formFor(size.width);

    return Stack(
      children: [
        child,
        Positioned(
          right: 8,
          bottom: 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE6101820),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  '${size.width.round()} x ${size.height.round()}  ·  '
                  '${form.name}  ·  dpr ${media.devicePixelRatio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: Color(0xFFCFE3FF),
                    fontFamily: 'JetBrainsMono',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
