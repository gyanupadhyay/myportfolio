import '../models/chapter.dart';

/// PARTYHUNT — Feb 2023 to Feb 2024, Software Engineer, North Goa.
///
/// Traceable to `docs/resume.pdf`.
const partyhuntChapter = Chapter(
  id: 'partyhunt',
  title: 'PartyHunt',
  subtitle: 'Building From the Ground Up',
  period: 'Chapter 2',
  credibility: Credibility.professional,
  nextChapterId: 'fyers',
  nextChapterLabel: 'FYERS',
  accentColor: 0xFFB85A78,
  summary: 'Led Create Party and Create Brand end to end, established '
      'scalable architecture and coding standards, and contributed to a 30% '
      'reduction in code defects through code review.',
  beats: [
    StoryBeat(
      id: 'arrival',
      layout: BeatLayout.opening,
      eyebrow: 'CHAPTER 2  ·  FEB 2023 — FEB 2024',
      title: 'PartyHunt',
      body: 'The first product. Two of the most critical features in the app '
          'to own end to end, and a codebase that had to be made ready for '
          'the developers who would come next.',
      signLines: ['Own it', 'End to end'],
    ),
    StoryBeat(
      id: 'problem',
      layout: BeatLayout.problem,
      title: 'The Critical Path',
      body: 'Create Party and Create Brand were the two features the product '
          'depended on.\n'
          'If they were wrong, nothing downstream mattered.',
      progressLabel: 'Creating…',
      progressResult: 'core',
      accent: 'The features everything\nelse hangs off.',
    ),
    StoryBeat(
      id: 'investigation',
      layout: BeatLayout.investigation,
      title: 'What slows a growing team?',
      body: 'Not the features themselves — the absence of an agreed way '
          'to build them, and the defects that only surface after release.',
      panelTitle: 'What needed to exist',
      metrics: [
        Metric(label: 'Scalable architecture', value: 'none yet'),
        Metric(label: 'Coding standards', value: 'none yet'),
        Metric(label: 'Crash visibility', value: 'none yet'),
        Metric(label: 'Behaviour tracking', value: 'none yet'),
        Metric(label: 'Consistency across the team', value: 'goal',
            emphasis: true),
      ],
      boardLines: ['Agree it', 'Review it', 'Then it exists'],
    ),
    StoryBeat(
      id: 'solution',
      layout: BeatLayout.decision,
      title: 'Structure as the answer',
      body: 'The architecture was introduced through the features being '
          'built — Create Party and Create Brand became the reference '
          'other work followed.',
      tabs: {
        'Approach': [
          'Scalable architecture, established rather than inherited',
          'Coding standards that kept the team consistent',
          'Onboarding made easier for new developers',
          'Code review as the place standards actually land',
        ],
        'Implementation': [
          'Led Create Party end to end — a critical app feature',
          'Led Create Brand on the same architectural pattern',
          'Firebase Analytics for user behaviour tracking',
          'Crashlytics for real-time crash reporting',
          'Firebase Cloud Messaging for push notifications',
        ],
        'Learnings': [
          'A reference implementation teaches faster than a document',
          'Standards not enforced in review do not exist',
          'Crash reporting changes what you find out, and when',
          'Consistency is what makes a team’s output predictable',
        ],
      },
      accent: 'Build the thing.\nBuild how you\nbuild things.',
    ),
    StoryBeat(
      id: 'deepdive',
      layout: BeatLayout.architecture,
      title: 'The Operational Layer',
      body: 'What a shipped feature needed behind it to stay trustworthy.',
      flow: [
        FlowStep('Create Party',
            detail: 'One of the two most critical features, delivered end to '
                'end.'),
        FlowStep('Create Brand',
            detail: 'The same architecture applied again, proving it '
                'generalised.'),
        FlowStep('Standards',
            detail: 'Consistency across the team, and easier onboarding for '
                'new developers.'),
        FlowStep('Operations',
            detail: 'Analytics, crash reporting and messaging, so problems '
                'surfaced before users reported them.'),
      ],
      techniques: [
        'Firebase Analytics',
        'Crashlytics',
        'Firebase Cloud Messaging',
        'Scalable architecture',
        'Coding standards',
      ],
      accent: 'You cannot fix\nwhat you cannot\nsee.',
    ),
    StoryBeat(
      id: 'result',
      layout: BeatLayout.outcome,
      title: '30%',
      body: 'Active participation in code reviews and constructive feedback '
          'contributed to a 30% reduction in code defects, and improved '
          'overall code quality across the team.',
      comparison: Comparison(
        before: 100,
        after: 70,
        beforeLabel: 'Before',
        afterLabel: 'After',
        beforeValue: 'defects',
        afterValue: '−30%',
      ),
      checklist: [
        '30% reduction in code defects',
        'Improved overall code quality',
        'Consistency across the team',
        'Easier onboarding for new developers',
      ],
      accent: 'Fewer defects.\nCalmer releases.',
    ),
    StoryBeat(
      id: 'transition',
      layout: BeatLayout.transition,
      title: 'Continuing the Journey',
      body: 'The road continues forward…',
      accent: 'Next: a bigger\nproduct, and a\nharder module.',
    ),
  ],
);
