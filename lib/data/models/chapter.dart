import 'package:flutter/foundation.dart';

/// The PRD's honesty rule, enforced in the model rather than left to prose.
/// Every chapter and experiment carries one, and it renders as a visible badge.
enum Credibility {
  professional('Professional experience'),
  personalProject('Personal project'),
  exploration('Exploration / learning');

  const Credibility(this.label);

  final String label;
}

/// The seven staged layouts a beat can use.
///
/// These are the PRD's deep-story template turned into renderable forms, so a
/// new chapter is a data file rather than a new set of widgets.
enum BeatLayout {
  /// Exterior establishing shot: eyebrow, title, subtitle, body, CTA, sign.
  opening,

  /// Night desk with a glass panel — the concrete problem.
  problem,

  /// Night desk with a measured list and a whiteboard.
  investigation,

  /// Parchment note with a checklist and depth tabs.
  decision,

  /// Blueprint wall with a flow diagram and technique list.
  architecture,

  /// Sunset with the measurable result on a paper panel.
  outcome,

  /// Daylight road toward the next chapter.
  transition,
}

/// One box in a beat's flow diagram.
@immutable
class FlowStep {
  const FlowStep(this.label, {this.detail});

  final String label;

  /// Shown when the node is expanded — the PRD's "go deeper" layer.
  final String? detail;
}

/// A measured outcome. Only ever populated from work the résumé supports.
@immutable
class Metric {
  const Metric({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;
}

/// Before/after figures for an [BeatLayout.outcome] beat.
@immutable
class Comparison {
  const Comparison({
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    required this.beforeValue,
    required this.afterValue,
  });

  final double before;
  final double after;
  final String beforeLabel;
  final String afterLabel;
  final String beforeValue;
  final String afterValue;
}

/// One beat of a chapter — a single frame of the story.
@immutable
class StoryBeat {
  const StoryBeat({
    required this.id,
    required this.layout,
    required this.title,
    this.eyebrow,
    this.body,
    this.accent,
    this.metrics = const [],
    this.checklist = const [],
    this.tabs = const {},
    this.flow = const [],
    this.techniques = const [],
    this.boardLines = const [],
    this.comparison,
    this.progressLabel,
    this.progressResult,
    this.signLines = const [],
    this.panelTitle,
  });

  final String id;
  final BeatLayout layout;

  /// The handwritten or display heading for the beat.
  final String title;

  /// Small label above the title.
  final String? eyebrow;

  /// The prose paragraph.
  final String? body;

  /// The free-floating handwritten note in the scene.
  final String? accent;

  /// [BeatLayout.investigation]: the measured rows.
  final List<Metric> metrics;

  /// [BeatLayout.decision] / [BeatLayout.outcome]: the ticked list. When
  /// [tabs] is set this is the first tab's contents.
  final List<String> checklist;

  /// [BeatLayout.decision]: progressive depth — tab label to its items.
  final Map<String, List<String>> tabs;

  /// [BeatLayout.architecture]: the chained boxes.
  final List<FlowStep> flow;

  /// [BeatLayout.architecture]: the techniques beside the flow.
  final List<String> techniques;

  /// [BeatLayout.investigation]: the whiteboard scrawl.
  final List<String> boardLines;

  /// [BeatLayout.outcome]: the before/after bars.
  final Comparison? comparison;

  /// [BeatLayout.problem]: the live progress bar.
  final String? progressLabel;
  final String? progressResult;

  /// [BeatLayout.opening] / [BeatLayout.transition]: the wooden sign.
  final List<String> signLines;

  /// [BeatLayout.investigation]: heading above the metric rows.
  final String? panelTitle;
}

/// A stop on the journey, rendered as a sequence of [StoryBeat]s.
@immutable
class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.period,
    required this.credibility,
    required this.beats,
    this.summary,
    this.nextChapterId,
    this.nextChapterLabel,
    this.accentColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final String period;
  final Credibility credibility;
  final List<StoryBeat> beats;
  final String? summary;
  final String? nextChapterId;
  final String? nextChapterLabel;

  /// Tints the chapter's establishing shot so the chapters do not all look
  /// like the same building.
  final int? accentColor;

  int get beatCount => beats.length;

  /// Short labels for the beat indicator.
  List<String> get beatLabels => [
        for (final b in beats) _labelFor(b.layout),
      ];

  static String _labelFor(BeatLayout layout) => switch (layout) {
        BeatLayout.opening => 'Arrival',
        BeatLayout.problem => 'The problem',
        BeatLayout.investigation => 'The investigation',
        BeatLayout.decision => 'The decision',
        BeatLayout.architecture => 'Technical depth',
        BeatLayout.outcome => 'The outcome',
        BeatLayout.transition => 'Continuing on',
      };
}

/// A stop on the journey map in frame 03.
@immutable
class JourneyNode {
  const JourneyNode({
    required this.id,
    required this.title,
    required this.caption,
    required this.position,
    this.chapterId,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String caption;

  /// Normalised position on the map, 0–1 in each axis.
  final ({double x, double y}) position;

  /// Null means the chapter is not built yet; the node renders as "coming".
  final String? chapterId;

  final bool enabled;
}
