import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/chapters/bosswallah.dart';
import '../data/chapters/fyers.dart';
import '../data/chapters/partyhunt.dart';
import '../data/chapters/smvdu.dart';
import '../components/controls.dart';
import '../data/models/chapter.dart';
import '../scenes/arrival/arrival_scene.dart';
import '../scenes/chapter/chapter_scene.dart' deferred as chapter_scene;
import '../scenes/human/human_scene.dart' deferred as human;
import '../scenes/journey/journey_scene.dart' deferred as journey;
import '../scenes/observatory/observatory_scene.dart' deferred as observatory;
import '../scenes/sunset/sunset_scene.dart' deferred as sunset;
import '../scenes/workshop/workshop_scene.dart' deferred as workshop;
import '../story/story_progress.dart';
import 'ambience.dart';
import 'ambience_player.dart';
import 'deferred_scene.dart';
import 'motion.dart';
import 'secret_layer.dart';
import 'theme/day_night.dart';
import 'theme/lighting.dart';
import 'theme/typography.dart';
import 'viewport_badge.dart';

/// Every chapter the journey can open, keyed by its route id.
const chapters = <String, Chapter>{
  'smvdu': smvduChapter,
  'partyhunt': partyhuntChapter,
  'fyers': fyersChapter,
  'bosswallah': bosswallahChapter,
};

/// Where the contact actions in frame 12 point. Taken from the résumé.
const contactLinks = {
  'email': 'mailto:gyanupadhyay19@gmail.com',
  'linkedin': 'https://www.linkedin.com/in/gyan-upadhyay-b8837b18a/',
  'github': 'https://github.com/gyanupadhyay',
  'resume': 'assets/resume.pdf',
};

/// Scenes cross-fade and push in slightly — the camera moves, the page does
/// not cut.
CustomTransitionPage<void> _cameraMove(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 620),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      if (Motion.of(context)) {
        return FadeTransition(opacity: curved, child: child);
      }
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.06, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

GoRouter buildRouter(StoryProgress progress) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _cameraMove(state, ArrivalScene(onNavigate: context.go)),
      ),
      GoRoute(
        path: '/workshop',
        pageBuilder: (context, state) {
          progress.visit('workshop');
          return _cameraMove(
            state,
            DeferredScene(
              load: workshop.loadLibrary,
              lighting: SceneLighting.interior,
              label: 'the workshop',
              builder: (context) =>
                  workshop.WorkshopScene(onNavigate: context.go),
            ),
          );
        },
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _cameraMove(
          state,
          DeferredScene(
            load: journey.loadLibrary,
            lighting: SceneLighting.day,
            label: 'the journey map',
            builder: (context) => ListenableBuilder(
              listenable: progress,
              builder: (context, _) => journey.JourneyScene(
                onNavigate: context.go,
                visited: progress.visited,
              ),
            ),
          ),
        ),
      ),
      // Chapters are deep-linkable down to an individual beat.
      GoRoute(
        path: '/chapter/:id',
        pageBuilder: (context, state) => _cameraMove(
          state,
          _chapterFor(context, state.pathParameters['id']!, null, progress),
        ),
        routes: [
          GoRoute(
            path: ':beat',
            pageBuilder: (context, state) => _cameraMove(
              state,
              _chapterFor(
                context,
                state.pathParameters['id']!,
                state.pathParameters['beat'],
                progress,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/observatory',
        pageBuilder: (context, state) {
          progress.visit('observatory');
          return _cameraMove(
            state,
            DeferredScene(
              load: observatory.loadLibrary,
              lighting: SceneLighting.night,
              label: 'the observatory',
              builder: (context) => observatory.ObservatoryScene(
                onNavigate: context.go,
                onOpenLink: openExternal,
                initialId: state.uri.queryParameters['id'],
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/human',
        pageBuilder: (context, state) {
          progress.visit('human');
          return _cameraMove(
            state,
            DeferredScene(
              load: human.loadLibrary,
              lighting: SceneLighting.interior,
              label: 'the personal side',
              builder: (context) => human.HumanScene(onNavigate: context.go),
            ),
          );
        },
      ),
      GoRoute(
        path: '/sunset',
        pageBuilder: (context, state) => _cameraMove(
          state,
          DeferredScene(
            load: sunset.loadLibrary,
            lighting: SceneLighting.sunset,
            label: 'the sunset',
            builder: (context) => sunset.SunsetScene(
              onNavigate: context.go,
              onContact: openContact,
            ),
          ),
        ),
      ),
      // The map's "What's Next?" node points here.
      GoRoute(path: '/next', redirect: (context, state) => '/observatory'),
    ],
    errorBuilder: (context, state) => _NotFound(onHome: () => context.go('/')),
  );
}

/// Resolves a chapter id (and optional beat id) to its scene.
Widget _chapterFor(
  BuildContext context,
  String id,
  String? beatId,
  StoryProgress progress,
) {
  final chapter = chapters[id];
  if (chapter == null) {
    return _NotFound(
      onHome: () => context.go('/map'),
      message: 'That chapter is still being written.',
      homeLabel: 'The journey map',
    );
  }
  progress.visit(id);
  final found = beatId == null
      ? 0
      : chapter.beats.indexWhere((b) => b.id == beatId);
  final index = found < 0 ? 0 : found;
  return DeferredScene(
    load: chapter_scene.loadLibrary,
    // Chapters open on their establishing shot, which is daylight.
    lighting: SceneLighting.day,
    label: chapter.title,
    builder: (context) => chapter_scene.ChapterScene(
      chapter: chapter,
      onNavigate: context.go,
      initialBeat: index,
    ),
  );
}

Future<void> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openContact(String target) =>
    openExternal(contactLinks[target] ?? target);

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key});

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  final _progress = StoryProgress();
  final _ambience = Ambience(player: LoopingAmbiencePlayer());
  final _dayNight = DayNightController();
  late final _router = buildRouter(_progress);

  @override
  void initState() {
    super.initState();
    _progress.load();
    _dayNight.load();
  }

  @override
  void dispose() {
    _dayNight.dispose();
    _ambience.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gyan Upadhyay — The Interactive Engineering Story',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      // Pages here are raw scenes, not Scaffolds, so nothing would otherwise
      // provide a Material ancestor — and every Text would render with the
      // yellow debug underline.
      builder: (context, child) => Material(
        type: MaterialType.transparency,
        child: Motion.resolve(
          child: DayNightScope(
            controller: _dayNight,
            child: AmbienceScope(
              ambience: _ambience,
              child: SecretLayer(
                progress: _progress,
                forceOpen: Uri.base.queryParameters.containsKey('dev'),
                child: ViewportBadge(child: child ?? const SizedBox()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onHome, this.message, this.homeLabel});

  final VoidCallback onHome;
  final String? message;
  final String? homeLabel;

  @override
  Widget build(BuildContext context) {
    // A dead end is still part of the world, so it is dressed as one: the
    // night sky, the name, what was being looked for, and a way on. It used
    // to be one grey sentence and a link that looked like text.
    final palette = LightingPalette.of(SceneLighting.night);
    return ColoredBox(
      color: palette.skyMid,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gyan Upadhyay',
                style: Type.labelSm.copyWith(
                  color: palette.onPanelMuted,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message ?? 'There is nothing here yet.',
                textAlign: TextAlign.center,
                style: Type.displayMd.copyWith(
                  color: palette.onPanel,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              // The address, so a mistyped or stale link is obvious.
              Text(
                Uri.base.fragment.isEmpty ? '/' : Uri.base.fragment,
                textAlign: TextAlign.center,
                style: Type.monoValue.copyWith(
                  color: palette.onPanelMuted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              PillButton(
                label: homeLabel ?? 'Back to the world',
                onPressed: onHome,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                textStyle: Type.labelSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
