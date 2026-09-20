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
/// cannot reach the published site. Add `?badge=off` to hide it, or
/// `?badge=on` to ask a release build for it: the question "what does the app
/// think it is being shown in?" is one you need answered against the build
/// that is actually deployed, in the browser it is actually misbehaving in,
/// and a debug build answers for itself rather than for that one.
class ViewportBadge extends StatelessWidget {
  const ViewportBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final asked = Uri.base.queryParameters['badge'];
    if (asked == 'off' || (!kDebugMode && asked != 'on')) return child;

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
                  '${form.name}  ·  dpr ${media.devicePixelRatio.toStringAsFixed(2)}'
                  '  ·  text x${media.textScaler.scale(10) / 10}',
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
