# The Interactive Engineering Story

**Live: https://gyanupadhyay.github.io/myportfolio/**

Gyan Upadhyay's portfolio, built as a Flutter Web app. Instead of a resume
page with sections, it's a single continuous journey: you arrive in a drawn
world, walk a map of four career chapters, and read each one as a sequence of
story beats.

Every backdrop is painted on canvas from code — there are no illustration
assets. The music is written the same way: `tool/generate_ambience.py`
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

The Konami code — ↑ ↑ ↓ ↓ ← → ← → — or `?dev` appended to any URL opens
developer mode: visited chapters, the reduced-motion state, the design canvas,
and a reset.

## Running it

    flutter pub get
    flutter run -d chrome

    flutter analyze --fatal-infos
    flutter test --exclude-tags render
    flutter build web --release

Requires Flutter with Dart SDK `^3.13.3`.

## Tests

Eleven suites under [test/](test/) cover story progress, chapter content,
the day/night cycle, responsive layout, accessibility semantics, the journey
walk and narrative QA.

[test/render_frames_test.dart](test/render_frames_test.dart) is different: it
renders scenes to `build/frames` for visual comparison against the twelve
reference mockups in [docs/reference/](docs/reference/). Goldens don't
reproduce across machines, so it's tagged `render` and CI skips it with
`--exclude-tags render`. Its failure output lands in `test/failures/` and is
gitignored.

## Tooling

[tool/](tool/) holds the Python helpers used while building the scenes — they
are authoring aids, not part of the app, and need `opencv-python` and `numpy`:

- `generate_ambience.py` — synthesises the five seamless ambience loops into
  `assets/audio/`. Each is a bed (wind, birds, room tone) under a score
  (waltz, strings, melody), written as chord progressions and note lists at the
  bottom of the file. Loops are seamless by construction rather than by
  cross-fading. Needs `soundfile` as well as `numpy`.
- `chrome_shots.py` — serves `build/web` and drives real headless Chrome over
  the twelve routes into `build/chrome/`. `flutter test` renders goldens in the
  headless Skia tester, which cannot see browser-only problems: web font
  loading, icon fallbacks, and how a scene actually fits the viewport. Needs a
  release build first, and honours `CHROME_EXECUTABLE`.
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
