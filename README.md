# The Interactive Engineering Story

**Live: https://gyanupadhyay.github.io/myportfolio/**

Gyan Upadhyay's portfolio, built as a Flutter Web app. Instead of a resume
page with sections, it's a single continuous journey: you arrive in a drawn
world, walk a map of four career chapters, and read each one as a sequence of
story beats.

Each scene exists twice. On a wide viewport it is a **painted plate** — the
reference artwork itself, hung behind the scene, with the live UI and a set of
hotspots over the objects in the painting. Everywhere else it is the **drawn
world**: the same composition painted on canvas from code, which re-flows to
any shape a plate cannot. A scene with no plate yet uses the drawn world at
every size, so the two can coexist while the art is finished.

The music is written the same way as the drawn world: `tool/generate_ambience.py`
synthesises a scored waltz for piano, strings and flute, one arrangement per
lighting state. Nothing is sampled, so the licensing question stays settled.

## The journey

| Route | Scene | Lighting |
|---|---|---|
| `/` | Arrival — the world | day |
| `/workshop` | The workshop, the entry point | interior |
| `/map` | The journey map, the navigation spine | day |
| `/chapter/:id` | A chapter, opening on its establishing shot | day |
| `/chapter/:id/:beat` | A single beat, deep-linkable | day |
| `/observatory` | Experiments and side work | night |
| `/human` | The personal side | interior |
| `/sunset` | Closing scene and contact | sunset |
| `/next` | Redirects to `/observatory` | — |

The four chapters, in the order the map walks them:

| Id | Chapter | Beats |
|---|---|---|
| `smvdu` | SMVDU — The Beginning | 4 |
| `partyhunt` | PartyHunt — Building From the Ground Up | 7 |
| `fyers` | FYERS — Investing Made Simple | 7 |
| `bosswallah` | BossWallah — Working Inside a Moving Product | 7 |

## How it's put together

    lib/
      app/          shell: router, theme, ambience, motion, secret layer
        theme/      design tokens, typography, day/night lighting
      components/   scene layout, panels, data views, controls, reveal
      data/         chapter model and the portfolio content itself
      scenes/       the seven scenes
      story/        visit tracking, persisted across sessions
      world/        stage and the canvas painters

A few decisions worth knowing before you read the code:

- **Scenes are deferred.** Every scene past arrival is a `deferred as` import
  behind `DeferredScene`, so the initial load carries only the first screen.
- **Lighting is a property of the route**, not of the widget tree. Each route
  declares a `SceneLighting` (`day`, `dusk`, `night`, `sunset`, `interior`)
  and the palette, the ambience track and the painters all follow from it.
- **Transitions are a camera move**, not a page cut — a cross-fade with a
  slight push in, which collapses to a plain fade under reduced motion.
- **Story progress is a plain `ChangeNotifier`** kept out of the widget tree,
  so scene rendering stays stateless and the logic is unit-testable. It
  persists to `shared_preferences`, and it's what turns a map node from
  unvisited into visited.
- **Ambience is off by default.** Browsers won't start audio before a gesture
  anyway, so silence is both the polite default and the only one that works.
  `Ambience` decides what *should* play; `AmbiencePlayer` does the playing, so
  everything can be tested without an audio backend.
- **The score follows the light, not the route.** One piece of music in F
  major is re-orchestrated per lighting state, so walking from the valley into
  the workshop is a change of scoring rather than a change of soundtrack.
  `LoopingAmbiencePlayer` holds two decks and cross-fades between them, which
  is what keeps a scene change from cutting a melody off mid-phrase.

### The secret layer

The Konami code — ↑ ↑ ↓ ↓ ← → ← → B A — or `?dev` appended to any URL opens
developer mode: visited chapters, the reduced-motion state, the design canvas,
and a reset.

`?badge=on` is the other one. It shows the corner readout of the live viewport,
the layout it resolves to, the device pixel ratio and the text scale — in a
release build, because "what does the app think it is being shown in?" is a
question you need answered against the deployed build in the browser that is
actually misbehaving. A debug build shows it by default; `?badge=off` hides it.

## Running it

    flutter pub get
    flutter run -d chrome

    flutter analyze --fatal-infos
    flutter test --exclude-tags render
    flutter build web --release

Requires Flutter with Dart SDK `^3.13.3`.

## Tests

Thirteen suites under [test/](test/) cover story progress, chapter content,
the day/night cycle, responsive layout, accessibility semantics, the journey
walk, narrative QA, and what a wheel turn does —
[test/wheel_test.dart](test/wheel_test.dart), which holds the line between
scrolling a beat's copy and leaving the beat, and keeps the landing's
"Scroll to explore" answering for itself.

[test/render_frames_test.dart](test/render_frames_test.dart) is different: it
renders scenes to `build/frames` for visual comparison against the twelve
reference mockups in [docs/reference/](docs/reference/). Goldens don't
reproduce across machines, so it's tagged `render` and CI skips it with
`--exclude-tags render`. Its failure output lands in `test/failures/` and is
gitignored.

It also skips itself whenever painted plates are on, which is the default: a
plate is an image, the widget tester does not decode one, and the frames would
come out blank. So a plain `flutter test` reports eighteen skips. To render the
drawn world instead:

    flutter test test/render_frames_test.dart --dart-define=PLATES=false

The goldens live in `build/frames`, which is gitignored, so they are a local
render set rather than a committed gate: they catch drift between runs, and
`--update-goldens` refreshes them after a deliberate scene change.

Nothing renders the *painted* scenes in the test suite, by the same limitation.
They are covered from two other directions: `tool/chrome_shots.py` drives a
real browser over every route, and
[test/night_mode_test.dart](test/night_mode_test.dart) asserts which plate a
scene hangs and that the copy over it stays legible in either light.

## Tooling

[tool/](tool/) holds the Python helpers used while building the scenes — they
are authoring aids, not part of the app, and need `opencv-python` and `numpy`:

- `generate_ambience.py` — synthesises the five seamless ambience loops into
  `assets/audio/`. Each is a bed (wind, birds, room tone) under a score
  (waltz, strings, melody), written as chord progressions and note lists at the
  bottom of the file. Loops are seamless by construction rather than by
  cross-fading. Needs `soundfile` as well as `numpy`.
- `make_plates.py` — turns the reference frames in `docs/reference/` into the
  scene plates in `assets/art/`. It wipes the chrome the app has to own (the
  frame numbering, the nav, the state chips), pads each frame out to one
  aspect ratio by continuing its own sky and ground — the references are crops
  ranging from 1.68 to 2.64, and filling a browser window with a 2.64 strip
  would crop the contact buttons off the sides — and writes the geometry the
  scenes trace their hotspots against to `lib/world/plates.g.dart`. It also
  bakes a moonlit variant of each daylight plate, because a colour matrix
  cannot take the sun out of a painted sky or put stars into it: the sky band
  is replaced with a night gradient that keeps the cloud modelling, and any
  handwriting the frame carries is repainted as light strokes so dark ink does
  not die against it. Frames already painted at night or indoors keep the light
  they were composed in. Re-run it after changing a reference frame.
- `chrome_shots.py` — serves `build/web` and drives real headless Chrome over
  the twelve routes into `build/chrome/`. `flutter test` renders goldens in the
  headless Skia tester, which cannot see browser-only problems: web font
  loading, icon fallbacks, and how a scene actually fits the viewport. Needs a
  release build first, and honours `CHROME_EXECUTABLE`. The scenes animate
  continuously, so the virtual-time budget can expire between CanvasKit frames
  and catch the surface before it is composited — about one shot in four comes
  out blank, and which route loses that race moves from run to run. Shots are
  retried until they carry a picture, and a route that never renders fails the
  run rather than leaving a white PNG that looks like a pass. Retrying clears
  most of the noise but not all of it — the failures cluster when the machine
  is busy, so run it on an idle one.
- `compare_to_reference.py` — scores each render against its reference on four
  measures, so art differences and layout differences can be told apart.
- `grid_overlay.py` — puts reference and render side by side in design space
  (1440×861) with a coordinate grid, so UI positions can be read off directly.

[docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) is the phase-wise plan the twelve
reference frames were built against.

## CI and deployment

[.github/workflows/deploy.yml](.github/workflows/deploy.yml) analyzes, tests
and builds the web release on every push, then publishes `main`/`master` to
GitHub Pages with the repository name as the base href.

The site is live at **https://gyanupadhyay.github.io/myportfolio/**.

Pages is configured with source *GitHub Actions*, so the artifact the `verify`
job uploads is what gets published — there is no `gh-pages` branch. The
`deploy` job only runs on `main`/`master`; pull requests build and test but do
not publish.

## Contact

Email, LinkedIn, GitHub and the resume are wired into the sunset scene; see
`contactLinks` in [lib/app/app.dart](lib/app/app.dart).
