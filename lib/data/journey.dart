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

/// Frame 02 — the Explore menu.
const workshopMenu = <({String label, String route})>[
  (label: 'My Journey', route: '/map'),
  (label: 'Portfolio module', route: '/chapter/fyers'),
  (label: 'Engineering', route: '/chapter/fyers/deepdive'),
  (label: 'Projects', route: '/observatory'),
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
