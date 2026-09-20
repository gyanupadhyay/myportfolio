import '../models/chapter.dart';

/// SMVDU — Shri Mata Vaishno Devi University, Aug 2019 to Aug 2023.
///
/// The short opening chapter. Traceable to `docs/resume.pdf`.
const smvduChapter = Chapter(
  id: 'smvdu',
  title: 'SMVDU',
  subtitle: 'The Beginning',
  period: 'Chapter 1',
  credibility: Credibility.professional,
  nextChapterId: 'partyhunt',
  nextChapterLabel: 'PartyHunt',
  accentColor: 0xFF6E8C6A,
  summary: 'B.Tech in Computer Science at Shri Mata Vaishno Devi University, '
      'Jammu & Kashmir — where the fundamentals, and the habit of helping '
      'other people learn them, started.',
  beats: [
    StoryBeat(
      id: 'arrival',
      layout: BeatLayout.opening,
      eyebrow: 'CHAPTER 1  ·  AUG 2019 — AUG 2023',
      title: 'SMVDU',
      body: 'Shri Mata Vaishno Devi University, Jammu & Kashmir. Four years '
          'of Computer Science, a cricket league, and a coding contest that '
          'mattered more than it should have.',
      signLines: ['B.Tech', 'Computer Science'],
    ),
    StoryBeat(
      id: 'investigation',
      layout: BeatLayout.investigation,
      title: 'The Groundwork',
      body: 'The coursework that everything afterwards was built on — and a '
          'grade that was never the interesting part of the story.',
      panelTitle: 'Coursework',
      metrics: [
        Metric(label: 'Computer Architecture', value: 'core'),
        Metric(label: 'Artificial Intelligence', value: 'core'),
        Metric(label: 'Computer Networks', value: 'core'),
        Metric(label: 'Data Structures and Algorithms', value: 'core'),
        Metric(label: 'CGPA', value: '7.25/10', emphasis: true),
      ],
      boardLines: ['Learn it', 'Then teach it'],
    ),
    StoryBeat(
      id: 'result',
      layout: BeatLayout.outcome,
      title: 'Top 10',
      body: 'A top-10 finish in the Code Club Coding Contest, Man of the '
          'Match in the SMVDU House Cricket League, and a habit of running '
          'events to guide other students.',
      checklist: [
        'Top 10 — Code Club Coding Contest',
        'Man of the Match — SMVDU House Cricket League',
        'Top contributor at college',
        'Events and activities to guide students',
      ],
      accent: 'The habit started\nhere: build it,\nthen explain it.',
    ),
    StoryBeat(
      id: 'transition',
      layout: BeatLayout.transition,
      title: 'Continuing the Journey',
      body: 'Out of the valley, toward the first product…',
      accent: 'Next: the first\nreal product.',
    ),
  ],
);
