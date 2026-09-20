import 'models/chapter.dart';

/// One inspectable system in the Engineering Observatory.
///
/// The PRD's honesty rule applies per item: each carries its own
/// [Credibility], so production work and personal projects stay
/// distinguishable at a glance.
class Experiment {
  const Experiment({
    required this.id,
    required this.title,
    required this.tagline,
    required this.credibility,
    required this.context,
    required this.steps,
    required this.details,
    this.link,
    this.stack = const [],
  });

  final String id;
  final String title;
  final String tagline;
  final Credibility credibility;

  /// Where this was built and why.
  final String context;

  /// The path through the system, rendered as a flow the visitor can follow.
  final List<FlowStep> steps;

  /// The deeper layer, opened on demand.
  final List<String> details;

  final String? link;
  final List<String> stack;
}

/// Systems worth opening up, drawn from `docs/resume.pdf`.
///
/// Two are production work from the career chapters; two are the personal
/// projects the résumé lists. Nothing here claims experience the résumé does
/// not support.
const experiments = <Experiment>[
  Experiment(
    id: 'release-pipeline',
    title: 'Release pipeline',
    tagline: 'OTA updates on channels the company stopped paying for',
    credibility: Credibility.professional,
    context: 'Built at FYERS. Shorebird CI/CD workflows gave release and '
        'patch channels for over-the-air updates, and custom GitHub Actions '
        'workflows replaced paid tooling like Codemagic.',
    steps: [
      FlowStep('Commit',
          detail: 'A change lands on a branch that CI is watching.'),
      FlowStep('GitHub Actions',
          detail: 'Custom in-house workflows build and verify it, in place '
              'of a paid service.'),
      FlowStep('Channel',
          detail: 'The build goes to a release channel, or a patch channel '
              'for something already in users’ hands.'),
      FlowStep('Over the air',
          detail: 'Shorebird delivers the patch without waiting on a store '
              'review cycle.'),
    ],
    details: [
      'Shorebird CI/CD workflows for release and patch channels',
      'Seamless over-the-air (OTA) updates for mobile users',
      'Custom GitHub Actions workflows written in-house',
      'Replaced paid tooling like Codemagic, reducing company expenses',
    ],
    stack: ['Shorebird', 'GitHub Actions', 'Flutter', 'CI/CD'],
  ),
  Experiment(
    id: 'flutter-migration',
    title: 'Flutter 3.24 → 3.35.0',
    tagline: 'Replacing the foundations of a live app without stopping it',
    credibility: Credibility.professional,
    context: 'Done single-handedly at BossWallah on an application that was '
        'already shipping, resolving breaking changes, dependency conflicts '
        'and deprecated APIs as they surfaced.',
    steps: [
      FlowStep('Audit',
          detail: 'Catalogue breaking changes, conflicts and deprecated APIs '
              'before changing the version.'),
      FlowStep('Resolve',
          detail: 'Untangle dependency conflicts so the tree can move '
              'forward at all.'),
      FlowStep('Refactor',
          detail: 'Replace outdated components and enforce updated Flutter '
              'best practices.'),
      FlowStep('Verify',
          detail: 'Keep the app installable at every step, not just at the '
              'end.'),
    ],
    details: [
      'Entire Flutter application migrated single-handedly',
      'Breaking changes, dependency conflicts and deprecated APIs resolved',
      'Outdated components refactored during the migration',
      'Updated Flutter best practices enforced across the codebase',
      'Codebase stability and maintainability improved as a result',
    ],
    stack: ['Flutter 3.35.0', 'Dart', 'Dependency resolution'],
  ),
  Experiment(
    id: 'todo-app',
    title: 'Todo App',
    tagline: 'A small app used as a place to get state management right',
    credibility: Credibility.personalProject,
    context: 'A personal Flutter project: tasks with a bin, favourites and '
        'theming, built on Bloc so the state transitions were explicit '
        'rather than scattered through widgets.',
    steps: [
      FlowStep('Add · delete',
          detail: 'The basic task lifecycle, as Bloc events rather than '
              'direct widget mutation.'),
      FlowStep('Done · favourite',
          detail: 'Toggles that each move the task through a defined state.'),
      FlowStep('Bin · restore',
          detail: 'Deletion is reversible: restore a task, or clear the bin '
              'folder outright.'),
      FlowStep('Theme',
          detail: 'Dark and light, switched at runtime.'),
    ],
    details: [
      'Add task and delete task',
      'Done / undone and favourite / unfavourite',
      'Restore task and clear bin folder',
      'Dark and light theme switching',
      'Bloc used for state management',
      'Drawer, popup menu, expansion panel and bottom navigation bar',
    ],
    stack: ['Flutter', 'Bloc', 'Dart'],
  ),
  Experiment(
    id: 'ecommerce-app',
    title: 'Flutter E-Commerce App',
    tagline: 'A shop front with its logic kept out of the widget tree',
    credibility: Credibility.personalProject,
    context: 'A personal Flutter project covering the user interface, the '
        'state and logic behind every feature, and a Firebase backend for '
        'data.',
    steps: [
      FlowStep('Interface',
          detail: 'The shopping UI built in Flutter.'),
      FlowStep('Bloc',
          detail: 'Every feature’s state and logic handled through the '
              'Bloc library.'),
      FlowStep('Firebase',
          detail: 'Data and backend managed with Firebase.'),
    ],
    details: [
      'User interface of the e-commerce app developed in Flutter',
      'Bloc library handling state management and feature logic',
      'Data and backend managed using Firebase',
    ],
    stack: ['Flutter', 'Bloc', 'Firebase'],
  ),
];
