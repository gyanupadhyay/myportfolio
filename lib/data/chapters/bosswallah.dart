import '../models/chapter.dart';

/// BossWallah — Dec 2025 to present, Software Engineer.
///
/// The PRD's narrative rule for this chapter: no bullet list of capabilities.
/// Each one appears because it solved a product or engineering problem.
/// Traceable to `docs/resume.pdf`.
const bosswallahChapter = Chapter(
  id: 'bosswallah',
  title: 'BossWallah',
  subtitle: 'Working Inside a Moving Product',
  period: 'Chapter 4',
  credibility: Credibility.professional,
  nextChapterId: 'next',
  nextChapterLabel: "What's Next?",
  accentColor: 0xFF7A6E9C,
  summary: 'Single-handedly migrated a live Flutter app from 3.24 to 3.35.0, '
      'then built attribution, finance and timezone-aware scheduling on the '
      'modernised codebase.',
  beats: [
    StoryBeat(
      id: 'arrival',
      layout: BeatLayout.opening,
      eyebrow: 'CHAPTER 4  ·  DEC 2025 — PRESENT',
      title: 'BossWallah',
      body: 'A product that was already live, already shipping, and already '
          'carrying years of decisions. Nothing could stop while the '
          'foundations were replaced underneath it.',
      signLines: ['Keep shipping', 'Keep it standing'],
    ),
    StoryBeat(
      id: 'problem',
      layout: BeatLayout.problem,
      title: 'The Bridge',
      body: 'The app was pinned to Flutter 3.24 while the ecosystem moved on.\n'
          'Every package we wanted next had already left us behind.',
      progressLabel: 'Resolving dependencies…',
      progressResult: 'conflict',
      accent: 'Standing still\nwas the risk.',
    ),
    StoryBeat(
      id: 'investigation',
      layout: BeatLayout.investigation,
      title: 'What was actually blocking us?',
      body: 'Before touching the version, every obstacle was catalogued — '
          'breaking changes, transitive conflicts, and APIs that had been '
          'deprecated for two releases.',
      panelTitle: 'Migration survey',
      metrics: [
        Metric(label: 'Breaking framework changes', value: 'audit'),
        Metric(label: 'Dependency conflicts', value: 'resolve'),
        Metric(label: 'Deprecated APIs in use', value: 'replace'),
        Metric(label: 'Outdated components', value: 'refactor'),
        Metric(label: 'Flutter 3.24 → 3.35.0', value: 'go', emphasis: true),
      ],
      boardLines: ['One at a time', 'Keep it green', 'Ship on Friday'],
    ),
    StoryBeat(
      id: 'solution',
      layout: BeatLayout.decision,
      title: 'Clearing the path',
      body: 'The migration was not one change. It was a sequence of small '
          'reversible ones, each verified against a working build — and once '
          'the ground was stable, the product work that needed it.',
      tabs: {
        'Migration': [
          'Single-handedly migrated the entire Flutter application',
          'Resolved breaking changes, dependency conflicts and deprecated APIs',
          'Refactored outdated components during the migration',
          'Enforced updated Flutter best practices across the codebase',
        ],
        'Product': [
          'Adjust SDK integration for accurate attribution tracking',
          'Campaign performance analysis and user-acquisition insights '
              'across platforms',
          'Finance module: expense tracking, financial dashboard and core '
              'finance workflows',
          'Timezone-aware dates, times and scheduling for users in different '
              'regions',
        ],
        'Learnings': [
          'A migration is a product risk, not a maintenance task',
          'Timezone bugs are data-model bugs wearing a costume',
          'Deprecated APIs are a countdown you can choose to start early',
          'Stability and maintainability are features the user never sees',
        ],
      },
      accent: 'Modernise\nwithout\nstopping.',
    ),
    StoryBeat(
      id: 'deepdive',
      layout: BeatLayout.architecture,
      title: 'Time, Money and Attribution',
      body: 'Three subsystems that each needed their own correctness.',
      flow: [
        FlowStep('Acquisition',
            detail: 'Adjust SDK identifies where a user actually came from, '
                'across platforms.'),
        FlowStep('Campaign insight',
            detail: 'Attribution feeds campaign performance analysis rather '
                'than guesswork.'),
        FlowStep('Finance',
            detail: 'Expense tracking and a financial dashboard, modelled '
                'explicitly rather than derived from UI state.'),
        FlowStep('Scheduling',
            detail: 'Every timestamp carries a zone, so dates and reminders '
                'are right wherever the user is.'),
      ],
      techniques: [
        'Flutter 3.35.0',
        'Adjust SDK',
        'Finance workflows',
        'Timezone-aware scheduling',
        'Dependency resolution',
      ],
      accent: 'Correctness\nbeats\ncleverness.',
    ),
    StoryBeat(
      id: 'result',
      layout: BeatLayout.outcome,
      title: '3.35.0',
      body: 'The app moved onto a current Flutter, kept shipping throughout, '
          'and gained finance and scheduling features the old toolchain could '
          'not support.',
      comparison: Comparison(
        before: 3.24,
        after: 3.35,
        beforeLabel: 'Before',
        afterLabel: 'After',
        beforeValue: '3.24',
        afterValue: '3.35.0',
      ),
      checklist: [
        'Entire app migrated single-handedly',
        'Stability and maintainability improved',
        'Attribution tracking in place',
        'Finance module and timezone-aware scheduling shipped',
      ],
      accent: 'Moving product.\nMoving foundations.\nBoth kept moving.',
    ),
    StoryBeat(
      id: 'transition',
      layout: BeatLayout.transition,
      title: 'Continuing the Journey',
      body: 'And the work keeps moving…',
      accent: 'Still building.\nStill curious.',
    ),
  ],
);
