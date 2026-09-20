import '../models/chapter.dart';

/// FYERS — Mar 2024 to Aug 2025, Software Engineer 2.
///
/// Every claim is traceable to a bullet in `docs/resume.pdf`. Where the résumé
/// gives no figure, this chapter does not invent one.
const fyersChapter = Chapter(
  id: 'fyers',
  title: 'FYERS',
  subtitle: 'Investing Made Simple',
  period: 'Chapter 3',
  credibility: Credibility.professional,
  nextChapterId: 'bosswallah',
  nextChapterLabel: 'BossWallah',
  accentColor: 0xFF6E93B8,
  summary: 'Led the complex Portfolio module, improved app startup by 700 ms, '
      'and replaced paid release tooling with Shorebird OTA channels and '
      'custom GitHub Actions.',
  beats: [
    StoryBeat(
      id: 'arrival',
      layout: BeatLayout.opening,
      eyebrow: 'CHAPTER 3  ·  MAR 2024 — AUG 2025',
      title: 'FYERS',
      body: 'The Portfolio module is where an investor finds out how they are '
          'actually doing. It was the most complex surface in the app, and it '
          'had a date.',
      signLines: ['Investing', 'Made Simple'],
    ),
    StoryBeat(
      id: 'problem',
      layout: BeatLayout.problem,
      title: 'The Challenge',
      body: 'The app startup was slow.\n'
          'Users were waiting before they could even see their portfolio.',
      progressLabel: 'Launching…',
      progressResult: 'slow',
      accent: 'Every millisecond here\nis someone waiting.',
    ),
    StoryBeat(
      id: 'investigation',
      layout: BeatLayout.investigation,
      title: 'What the module had to carry',
      body: 'Portfolio was not one screen. It was the hardest thing in the '
          'app to get right, delivered against a fixed timeline with three '
          'other disciplines in the room.',
      panelTitle: 'Delivering Portfolio',
      metrics: [
        Metric(label: 'Complex Portfolio module', value: 'owned'),
        Metric(label: 'Product collaboration', value: 'yes'),
        Metric(label: 'QA collaboration', value: 'yes'),
        Metric(label: 'Design collaboration', value: 'yes'),
        Metric(label: 'Defined timeline', value: 'met', emphasis: true),
      ],
      boardLines: ['Ship the module', 'Then make it fast'],
    ),
    StoryBeat(
      id: 'solution',
      layout: BeatLayout.decision,
      title: 'What changed?',
      body: 'Three threads ran at once: making the app start faster, making '
          'releases cheaper and safer, and continuing to ship product.',
      tabs: {
        'Performance': [
          'Improved app startup time by 700 ms',
          'Significantly better overall performance',
          'A faster first view of the portfolio',
        ],
        'Release engineering': [
          'Shorebird CI/CD workflows for release and patch channels',
          'Seamless over-the-air (OTA) updates for mobile users',
          'Custom GitHub Actions workflows written in-house',
          'Replaced paid tooling like Codemagic, reducing company expenses',
        ],
        'Product': [
          'Date and time added to the trend chart',
          'Quick View enhanced for better user onboarding',
          'Push notifications built on Firebase to improve engagement',
          'Meta and CleverTap SDKs for user-journey tracking and real-time '
              'behavioural analytics',
        ],
      },
      accent: 'Build\nMeasure\nImprove\nRepeat',
    ),
    StoryBeat(
      id: 'deepdive',
      layout: BeatLayout.architecture,
      title: 'Under the Hood',
      body: 'Where the startup time goes, and where it can be won back.',
      flow: [
        FlowStep('App Launch',
            detail: 'The entry point does the minimum needed to render a '
                'first frame.'),
        FlowStep('Initialization',
            detail: 'Work that does not block the first screen is moved off '
                'the critical path.'),
        FlowStep('Dependencies',
            detail: 'Heavy dependencies resolve when they are first needed, '
                'not at launch.'),
        FlowStep('First Screen',
            detail: 'Portfolio renders as soon as its own data is ready.'),
      ],
      techniques: [
        'Deferred work',
        'Lazy initialization',
        'Shorebird patch channel',
        'GitHub Actions CI/CD',
        'OTA updates',
      ],
      accent: 'Small improvements\nmake a big\ndifference.',
    ),
    StoryBeat(
      id: 'result',
      layout: BeatLayout.outcome,
      title: '700 ms',
      body: 'App startup improved by 700 ms, the Portfolio module shipped '
          'within its timeline, and releases moved onto tooling the company '
          'no longer had to pay for.',
      comparison: Comparison(
        before: 1.0,
        after: 0.72,
        beforeLabel: 'Before',
        afterLabel: 'After',
        beforeValue: 'startup',
        afterValue: '−700ms',
      ),
      checklist: [
        'Startup improved by 700 ms',
        'Portfolio delivered on timeline',
        'OTA updates via Shorebird channels',
        'Paid release tooling replaced',
      ],
      accent: 'Faster apps\nHappier users\nThat’s the goal.',
    ),
    StoryBeat(
      id: 'transition',
      layout: BeatLayout.transition,
      title: 'Continuing the Journey',
      body: 'On to bigger challenges…',
      accent: 'On to bigger challenges…\nThe story continues.',
    ),
  ],
);
