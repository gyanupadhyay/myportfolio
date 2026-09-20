import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../story/story_progress.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';

/// Phase 8 of the plan — the secret layer.
///
/// Developer mode is opened with the Konami sequence or `?dev` on any URL. It
/// exposes what the world is actually doing: which chapters have been
/// visited, the reduced-motion state, the design canvas, and a reset.
class SecretLayer extends StatefulWidget {
  const SecretLayer({
    super.key,
    required this.child,
    required this.progress,
    this.forceOpen = false,
  });

  final Widget child;
  final StoryProgress progress;

  /// Set by `?dev` in the URL.
  final bool forceOpen;

  @override
  State<SecretLayer> createState() => _SecretLayerState();
}

class _SecretLayerState extends State<SecretLayer> {
  static const _konami = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];

  final _typed = <LogicalKeyboardKey>[];
  late bool _open = widget.forceOpen;

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    // Chapters use the arrows for navigation, so the sequence is watched
    // passively rather than intercepted.
    _typed.add(event.logicalKey);
    if (_typed.length > _konami.length) {
      _typed.removeAt(0);
    }
    if (_typed.length == _konami.length) {
      for (var i = 0; i < _konami.length; i++) {
        if (_typed[i] != _konami[i]) return;
      }
      _typed.clear();
      setState(() => _open = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          widget.child,
          if (_open)
            Positioned(
              right: 16,
              top: 16,
              child: _DevPanel(
                progress: widget.progress,
                onClose: () => setState(() => _open = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _DevPanel extends StatelessWidget {
  const _DevPanel({required this.progress, required this.onClose});

  final StoryProgress progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduced = media.disableAnimations;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xEE0B1220),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x556FE3A0)),
        ),
        child: ListenableBuilder(
          listenable: progress,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'developer mode',
                      style: Type.labelSm.copyWith(
                        color: const Color(0xFF6FE3A0),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    mouseCursor: SystemMouseCursors.click,
                    child: const Icon(Icons.close, size: 14, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _row('canvas', '${T.designWidth.toInt()} × ${T.designHeight.toInt()}'),
              _row('viewport',
                  '${media.size.width.toInt()} × ${media.size.height.toInt()}'),
              _row('dpr', media.devicePixelRatio.toStringAsFixed(2)),
              _row('reduced motion', reduced ? 'on' : 'off'),
              _row('visited', '${progress.count}'),
              const SizedBox(height: 6),
              Text(
                progress.visited.isEmpty ? '—' : progress.visited.join(', '),
                style: Type.labelSm.copyWith(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: progress.reset,
                mouseCursor: SystemMouseCursors.click,
                child: Text(
                  'reset progress',
                  style: Type.labelSm.copyWith(
                    color: const Color(0xFFFF9E9E),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _row(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                key,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}
