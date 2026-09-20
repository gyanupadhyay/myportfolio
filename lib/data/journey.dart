import 'models/chapter.dart';

/// Frame 03 — the five stops, positioned on the painted map.
///
/// Positions are normalised to the design canvas so the trail and the nodes
/// stay registered to the terrain at any viewport size.
const journeyNodes = <JourneyNode>[
  JourneyNode(
    id: 'smvdu',
    title: 'SMVDU',
    caption: 'The Beginning',
    position: (x: 0.099, y: 0.697),
    chapterId: 'smvdu',
  ),
  JourneyNode(
    id: 'partyhunt',
    title: 'PartyHunt',
    caption: 'First Product',
    position: (x: 0.308, y: 0.674),
    chapterId: 'partyhunt',
  ),
  JourneyNode(
    id: 'fyers',
    title: 'FYERS',
    caption: 'Scaling Impact',
    position: (x: 0.512, y: 0.627),
    chapterId: 'fyers',
  ),
  JourneyNode(
    id: 'bosswallah',
    title: 'BossWallah',
    caption: 'Bigger Challenges',
    position: (x: 0.710, y: 0.528),
    chapterId: 'bosswallah',
  ),
  JourneyNode(
    id: 'next',
    title: "What's Next?",
    caption: 'Projects & Beyond',
    position: (x: 0.899, y: 0.490),
    chapterId: 'next',
  ),
];

/// The top bar's destinations, in order.
///
/// One list, used by every scene that shows the bar, because the bar used to
/// be written out per scene: both copies offered "Journal" and "Projects" and
/// sent them to the same chapter, "Journal" was not a place this site has,
/// and the contact scene — the one thing a visitor might actually be looking
/// for — could not be reached from the bar at all.
const navItems = <({String label, String route})>[
  (label: 'Home', route: '/'),
  (label: 'Map', route: '/map'),
  (label: 'Projects', route: '/chapter/fyers'),
  (label: 'Ideas', route: '/observatory'),
  (label: 'About', route: '/human'),
  (label: 'Contact', route: '/sunset'),
];

/// The labels, for [navItems]-driven bars.
List<String> get navLabels => [for (final item in navItems) item.label];

/// Where a bar label goes. Unknown labels fall back to the world.
String navRouteFor(String label) => navItems
    .firstWhere((item) => item.label == label, orElse: () => navItems.first)
    .route;

/// Frame 02 — the Explore menu.
const workshopMenu = <({String label, String route})>[
  (label: 'My Journey', route: '/map'),
  (label: 'Projects', route: '/chapter/fyers'),
  (label: 'Engineering', route: '/chapter/fyers/deepdive'),
  (label: 'AI Experiments', route: '/observatory'),
  (label: 'About Me', route: '/human'),
];

/// Frame 02 — the whiteboard.
const workshopBoard = <String>[
  'Ideas',
  'Code',
  'Products',
  'A Better Tomorrow',
];

/// Frame 11 — the personal side.
const personalLines = <String>[
  'Cricket.  Music.  Books.  Travel.',
  'Volunteering, and wandering different',
  'parts of the world.',
];

const personalNotebook = <String>['Better', 'Build', 'Explore', 'Repeat'];
