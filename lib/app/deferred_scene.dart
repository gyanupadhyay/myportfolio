import 'package:flutter/material.dart';

import 'theme/day_night.dart';
import 'theme/lighting.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';

/// Loads a deferred library before building the scene that lives in it.
///
/// The arrival scene is what the visitor waits for, so only it ships in the
/// initial bundle. Chapters, the observatory, the human layer and the sunset
/// are split out and fetched on first visit — which is also the first time
/// their route is reachable.
///
/// The placeholder is a quiet wash in the scene's own lighting rather than a
/// spinner, so the split is not something the visitor has to look at.
class DeferredScene extends StatefulWidget {
  const DeferredScene({
    super.key,
    required this.load,
    required this.builder,
    required this.lighting,
    this.label,
  });

  /// The generated `loadLibrary()` for the deferred import.
  final Future<void> Function() load;

  /// Built once the library is in memory.
  final WidgetBuilder builder;

  /// Used to tint the placeholder so the transition does not flash.
  final SceneLighting lighting;

  /// Announced to assistive tech while loading.
  final String? label;

  @override
  State<DeferredScene> createState() => _DeferredSceneState();
}

class _DeferredSceneState extends State<DeferredScene> {
  late Future<void> _future = widget.load();

  @override
  void didUpdateWidget(DeferredScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load != widget.load) _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _SceneLoadError(
              lighting: widget.lighting,
              onRetry: () => setState(() => _future = widget.load()),
            );
          }
          return widget.builder(context);
        }
        return _ScenePlaceholder(
          lighting: widget.lighting,
          label: widget.label,
        );
      },
    );
  }
}

class _ScenePlaceholder extends StatelessWidget {
  const _ScenePlaceholder({required this.lighting, this.label});

  final SceneLighting lighting;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette =
        LightingPalette.of(DayNightScope.resolve(context, lighting));
    return Semantics(
      label: label == null ? 'Loading' : 'Loading $label',
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SceneLoadError extends StatelessWidget {
  const _SceneLoadError({required this.lighting, required this.onRetry});

  final SceneLighting lighting;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette =
        LightingPalette.of(DayNightScope.resolve(context, lighting));
    return ColoredBox(
      color: palette.skyMid,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'That part of the world did not load.',
              style: Type.bodyLg.copyWith(color: palette.onPanel),
            ),
            const SizedBox(height: T.s16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: Type.label.copyWith(color: T.successGlow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
