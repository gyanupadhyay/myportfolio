# Build Plan — The Interactive Engineering Story

Flutter Web portfolio. Phase-wise delivery plan derived from the PRD
(*The Interactive Engineering Story*) and the **12 reference frames** in
[docs/reference/](reference/).

**Current repo state:** empty scaffold. Folders exist (`lib/world`, `lib/scenes`,
`lib/story`, `lib/data`, `lib/components`, `lib/animations`, `assets/fonts`,
`web/`) but there is no `pubspec.yaml` and no Dart source yet. Flutter 3.47.4 /
Dart 3.13.3 is installed.

---

## 0. What the 12 frames actually are

They are not 12 unrelated screens. They are **one complete journey**, and it is
exactly the PRD's R1 scope. Building all 12 gets you a shippable portfolio.

| # | Frame | Role | Phase |
|---|---|---|---|
| 01 | Landing / The World | Chapter 0 — Arrival | 3 |
| 02 | The Workshop / Entry Point | Chapter 1 — Workshop | 3 |
| 03 | The Journey Map | Navigation spine | 4 |
| 04 | Entering a Chapter — FYERS | FYERS beat 1 — opening scene | 5 |
| 05 | The Problem | FYERS beat 2 — the challenge | 5 |
| 06 | The Investigation | FYERS beat 3 — profiling | 5 |
| 07 | The Solution | FYERS beat 4 — the decision | 5 |
| 08 | Technical Deep Dive | FYERS beat 5 — architecture | 5 |
| 09 | The Result | FYERS beat 6 — 700 ms outcome | 5 |
| 10 | Continuing the Journey | FYERS beat 7 — transition out | 5 |
| 11 | Personal Side | Chapter 6 — Human Layer | 6 |
| 12 | Final / Contact | Final Chapter — Sunset | 6 |

Frames 04–10 map one-to-one onto the PRD's deep-story template — opening,
problem, pressure, investigation, decision, technical depth, outcome,
reflection, transition. The mockups already solved the narrative structure;
this plan is about building it.

**Note:** the dark pill in each frame's top-left (`4. Entering a Chapter —
FYERS`) is a mockup annotation, not UI. Do not build it. Replace it with the
subtle beat indicator described in Phase 2.

---

## 1. The art-pipeline decision (read this first)

The frames are painted illustrations. How they reach the screen drives
Phases 3–6.

| Option | What it means | Fidelity | Cost |
|---|---|---|---|
| **A — Flat backgrounds** | Ship each frame's art as one WebP/AVIF, build all UI on top in code | Pixel-exact, immediately | Low. Flat, limited parallax |
| **B — Layered art (recommended)** | Split each scene into 4–6 depth layers (sky / clouds / far / mid / foreground), each a transparent WebP; all UI, character, panels, charts, glow in code | Pixel-exact *and* spatial | Medium. One art-prep pass per scene |
| **C — Fully procedural** | Every mountain, desk and plank drawn with `CustomPainter` | Will **not** match — reads as vector art | Very high |

**Recommendation: B.** Everything these frames show as *interface* — nav bar,
headline, CTA pills, signpost planks, Explore menu, journey-map nodes, glass
panels, the startup timeline, the checklists, the flow diagram, the before/after
bar chart, the contact buttons — is built in code and is exactly reproducible.
The *painting* stays a painting, because that is what makes it look like the
mockup.

Phase 3 ships with Option A as an interim so scenes are on screen in week one,
then upgrades in place to B without touching any UI code.

If you want C anyway, say so — the plan roughly triples in Phases 3–6 and the
visual target becomes "stylised vector world", not these frames.

---

## 2. What the frames share (build once, use twelve times)

Reading all 12 together, a small component vocabulary repeats. This is the
highest-leverage observation in the plan: **build these in Phase 2 and every
later phase is assembly, not invention.**

| Component | Appears in | Notes |
|---|---|---|
| `GlassPanel` — dark translucent, ~16 px radius, 1 px light border | 05, 06, 08, 09 | Two tints: night-blue and neutral |
| `ParchmentPanel` — aged paper, torn edge, soft shadow | 07, 11 | `CustomPainter` edge + noise texture |
| `HandwrittenAccent` — script text placed freely in the scene | 01, 03, 05, 06, 07, 08, 09, 10, 11, 12 | Rotated a few degrees, staggered per-line reveal |
| `PillButton` — dark rounded CTA with trailing arrow | 01, 04 | "Begin the Journey →", "Enter the Story →" |
| `CheckRow` — green circular tick + label | 07, 09 | Staggered check-in animation |
| `MetricRow` — icon + label + right-aligned mono number | 06 | Blue values, red total |
| `FlowDiagram` — stacked nodes joined by arrows | 08 | App Launch → Initialization → Core Services → First Screen |
| `ComparisonBars` — before/after vertical bars | 09 | 3.2 s grey vs 2.5 s green, grow on enter |
| `WoodenSign` — plank with routed text | 01, 04, 10 | Signpost, "Better Tools / Brighter Investors", "Next Chapter · BossWallah" |
| `SegmentedTabs` — light pill tab bar | 07 | Approach · Implementation · Learnings |
| `IconActionRow` — labelled icon buttons | 12 | Email · LinkedIn · GitHub · Resume |
| `BeatIndicator` | all | Replaces the mockup annotation chip |

**Lighting arc.** The frames deliberately change time of day: 01–04 bright day,
05–08 night, 09 sunset, 10 day, 11 warm interior, 12 sunset. Model this as a
`SceneLighting` token (`dawn / day / dusk / night / interior`) on every scene
so panel tint, text colour and glow derive from it automatically instead of
being hand-tuned twelve times.

---

## Phase 1 — Foundation (3–4 days)

**Goal:** an app that boots, routes by URL, and has a scene + camera system the
later phases plug into.

- `pubspec.yaml` — `go_router`, `flutter_riverpod`, `flutter_svg`, local fonts
  in `assets/fonts`, `rive` (deferred to Phase 7).
- `lib/main.dart`, `lib/app/app.dart` — `MaterialApp.router`.
- `lib/app/router.dart` — `/`, `/workshop`, `/map`, `/chapter/:id/:beat`.
  Deep-linkable to an individual beat; browser back works.
- `lib/world/scene.dart` — `Scene`: `id`, `lighting`, `build`, `onEnter`,
  `onExit`, `preload()`.
- `lib/world/camera/camera_controller.dart` — normalised camera (`offset`,
  `zoom`, `focus`) driven by scroll/pointer, with `animateTo` for transitions.
  Scroll moves the camera; it does not move a `ListView`.
- `lib/world/rendering/parallax_layer.dart` — layer + depth factor, reads the
  camera, applies the transform.
- `lib/story/beat_controller.dart` — advances beats within a chapter, handles
  scroll/keyboard/click, and is what frames 04–10 run on.
- `lib/app/motion.dart` — central `reducedMotion` flag wired to
  `MediaQuery.disableAnimations`; **every** animation reads it.

**Exit:** `flutter run -d chrome` shows a placeholder scene; scrolling pans the
camera; Tab cycles hotspots with a visible ring; `flutter analyze` clean.

---

## Phase 2 — Design system and shared components (4–5 days)

Build the §2 table. This phase looks like overhead and is the reason Phases 3–6
stay short.

- `lib/app/theme/tokens.dart` — colour, spacing, radius, duration, elevation.
- `lib/app/theme/lighting.dart` — the `SceneLighting` enum and the derived
  palette per lighting state.
- `lib/app/theme/typography.dart` — handwritten / display / body / mono ramps.
- `lib/components/` — one file per row of the §2 table, each with a widget test
  and a golden.
- A `/dev/components` gallery route rendering every component in every lighting
  state. This is how you catch night-mode contrast bugs before they reach a
  scene.

**Exit:** the gallery renders all components in all five lighting states;
goldens committed; contrast checked against WCAG AA for every text-on-panel
combination.

---

## Phase 3 — Frames 01–02: Landing and Workshop (5–6 days)

**Frame 01 — Landing / The World** (`lib/scenes/arrival/`)

- `top_nav.dart` — transparent bar: `Home · Journal · Map · Projects · About`
  right-of-centre, then sun (theme), globe/sound and profile icons. Collapses
  to a hamburger below 900 px.
- `hero_copy.dart` — handwritten *"Good things are built by curious people."*
  (2 lines), then **I'm Gyan Upadhyay**, the two-line subtitle, then the
  `PillButton` **"Begin the Journey →"**. Staggered fade-up, 120 ms apart.
- `signpost.dart` — four planks (*Projects, Experience, Ideas, Life*), each
  rotated, each a `WoodenSign` + focusable hotspot routing to its chapter.
  Hover nudges and highlights.
- `wanderer.dart` — backpack character, centre-bottom, back to camera.
- `scroll_hint.dart` — "↓ Scroll to explore", slow bob, fades after first
  scroll.
- Parallax: sky → clouds → far mountains → lake/town → foreground foliage.

**Frame 02 — The Workshop** (`lib/scenes/workshop/`), reached by a camera
push-in from the landing scene, not a page swap.

- `explore_menu.dart` — right panel: "Explore" header pill, then bulleted rows
  *My Journey, Projects, Engineering, AI Experiments, About Me*. Hover slides
  the row; arrow keys navigate; Enter opens.
- Hotspots over the art, each focusable with a tooltip: **laptop** → projects;
  **whiteboard** (Ideas / Code / Products / A Better Tomorrow) → philosophy
  note; **world-map poster** → human layer; **notebook and sketches** →
  engineering notes; **framed photos** → about; **the cat** → easter egg
  (Phase 9). The cat recurs in frames 06, 09, 10 and 12 — treat it as a
  character, not a prop.
- Warm light shaft from the window: animated gradient overlay, off under
  reduced motion.

**Exit:** side by side with the reference PNGs at 1440×900 both layouts match;
they hold at 1920, 1280, 834 and 390; every hotspot keyboard-reachable with a
screen-reader label; LCP < 2.5 s deployed.

---

## Phase 4 — Frame 03: The Journey Map (4 days)

`lib/scenes/journey/`

- `journey_path.dart` — `CustomPainter` glowing dotted trail: animated dash
  phase, soft outer glow, travelling pulse. Normalised control points in data,
  so it re-fits on resize.
- `journey_node.dart` — the five cards in map space, not screen space:
  **SMVDU** (The Beginning) · **PartyHunt** (First Product) · **FYERS**
  (Scaling Impact — active, raised, green glow ring) · **BossWallah** (Bigger
  Challenges) · **What's Next?** (AI & Beyond). States: active / visited /
  locked.
- Handwritten headline top-left; hint bottom-left *"Click on a place to explore
  a chapter"*; seated character bottom-right.
- `lib/story/story_progress.dart` — visited chapters, persisted to
  `localStorage`. This drives the "visited" node state.

**Exit:** nodes and path stay registered to the art at every viewport width;
clicking a node camera-flies into that chapter; `story_progress` unit-tested.

---

## Phase 5 — Frames 04–10: the FYERS chapter (7–8 days)

The PRD's reference implementation, and the seven frames specify it completely.
All narrative text lives in `lib/data/chapters/fyers.dart` — **never inside
widgets.**

Models first (`lib/data/models/`): `Chapter`, `StoryBeat`, `Metric`,
`ArchitectureNode`, `Credibility`.

| Frame | Beat | Built from |
|---|---|---|
| 04 | **Opening** — "Chapter 2 · FYERS · Investing Made Simple", intro paragraph, `PillButton` "Enter the Story →", `WoodenSign` "Better Tools, Brighter Investors" | day lighting |
| 05 | **The problem** — "The Challenge"; `GlassPanel` with a live **Launching…** progress bar resolving to **3.2 s**, caption *"That 3.2 seconds felt like forever."* The bar animates in real time — this is the beat, not decoration | night |
| 06 | **The investigation** — "Where was the time going?"; `MetricRow` Startup Timeline: App Initialization 320 ms · Dependency Injection 480 ms · Core Services 620 ms · First Screen Render 780 ms · **Total 3.2 s** (red). Rows reveal sequentially. Whiteboard: *"Too much / Too early / Let's fix this"* | night |
| 07 | **The decision** — "What changed?" on a `ParchmentPanel`; `CheckRow` list: Lazy initialization · Optimized dependencies · Deferred non-critical tasks · Better state management. `SegmentedTabs`: **Approach · Implementation · Learnings** — this is the PRD's progressive-depth control; the casual visitor stops at Approach | night |
| 08 | **Technical depth** — "Under the Hood"; `FlowDiagram` App Launch → Initialization → Core Services → First Screen, assembling node by node, arrowing into Deferred Modules · Lazy Loading · Isolates · Optimized Packages · Minimal Blocking Tasks. Handwritten *"Small improvements make a big difference."* | night |
| 09 | **The outcome** — huge **700 ms**; `ComparisonBars` 3.2 s → 2.5 s; `CheckRow` Faster startup · Smoother UX · Higher retention · Positive feedback. Handwritten *"Faster apps / Happier users / That's the goal."* | sunset |
| 10 | **Transition** — wide road toward the castle; handwritten *"On to bigger challenges… The story continues."*; `WoodenSign` **Next Chapter · BossWallah** routing onward | day |

The night → sunset → day lighting run across 05–10 is the emotional arc. Do not
flatten it.

**Additional FYERS content the PRD requires but the frames do not show** —
Shorebird CI/CD with release/patch channels and OTA, the custom GitHub Actions
that replaced Codemagic, trend-chart date/time handling, Quick View onboarding,
FCM, analytics SDKs. Surface these under frame 07's **Implementation** tab and
frame 08's expandable diagram nodes rather than adding new frames.

**Exit:** a reader who knows nothing finishes the chapter and can state the
problem, the decision and the outcome. Every number traceable to the résumé.
Goldens for frames 05, 06, 08 and 09.

---

## Phase 6 — Frames 11–12: Human Layer and Sunset (3 days)

- **Frame 11 — Personal Side** (`lib/scenes/human/`) — "Beyond Code";
  *Cricket. Travel. Music. Books. / Good conversations. New places. / Same
  curiosity.* Scattered polaroids, journals, guitar, world map and a notebook
  reading **Better · Build · Explore · Repeat**. Each artifact is a hotspot on
  the Phase 3 pattern; polaroids tilt and lift on hover.
- **Frame 12 — Final / Contact** (`lib/scenes/sunset/`) — handwritten
  **"Still curious?"**, *"Let's build something meaningful."*, `IconActionRow`
  **Email · LinkedIn · GitHub · Resume**, handwritten *"Same sky / Bigger
  dreams / See you soon."* Contact lives inside the scene, per the PRD — no
  modal, no footer.

**→ R1 ships here.** All 12 frames, one complete journey, contact included.
Roughly **5–6 weeks** from an empty repo.

---

## Phase 7 — Motion and character (3 days)

- Rive or sprite-sheet idle and walk cycles for the wanderer; he walks between
  map nodes instead of teleporting. The cat gets an idle loop too.
- Per-scene ambience: birds, water shimmer, leaf drift, lamp flicker in the
  night beats.
- Camera easing tuned per transition type (push-in, pan, fly-to).
- Optional ambient audio, **off by default**, visible toggle.
- All of it gates on `reducedMotion`.

---

## Phase 8 — Remaining chapters (5–6 days)

Reuse the Phase 5 framework — only data files are new. Frame 10 already points
at BossWallah, so that is the natural next build.

- `lib/data/chapters/bosswallah.dart` — the Flutter 3.24 → 3.35.0 migration as
  a bridge crossing: breaking changes, dependency conflicts, deprecated APIs;
  then attribution/campaign integrations, finance workflows, timezone-aware
  scheduling. Each capability appears *because it solved a problem* — the PRD's
  narrative rule.
- `lib/data/chapters/partyhunt.dart` — Create Party and Create Brand as
  enterable rooms; scalable architecture and coding standards as the answer to
  growing complexity; Firebase Analytics / Crashlytics / FCM as the operational
  layer; code reviews and the **30 % defect reduction**.
- `lib/data/chapters/smvdu.dart` — short opening chapter.

---

## Phase 9 — Observatory and secret layer (4 days)

- **Observatory** (`lib/scenes/observatory/`) — RAG, Agents, Knowledge Graphs,
  Text-to-SQL as inspectable experiments; a request traceable through
  retrieval → reasoning → tool steps, reusing `FlowDiagram`.
  **The honesty rule is enforced in the model:** `Chapter.credibility ∈
  {professional, personalProject, exploration}` renders as a visible badge.
  Not optional, not a footnote.
- **Secret layer** — developer mode (Konami or `?dev`), the cat easter egg,
  sound toggle, night mode across all scenes.

---

## Phase 10 — Performance, accessibility, QA (4 days)

- **Performance:** deferred-load each chapter (`deferred as`), AVIF/WebP with
  size variants, `flutter build web --wasm` evaluated against CanvasKit, target
  initial payload < 2 MB and 60 fps in-scene. Low-power fallback: static
  backgrounds that keep the full narrative.
- **Accessibility:** full keyboard path through all 12 frames; semantic labels
  on every hotspot; contrast audit on text over painted art (frames 01, 10 and
  12 will need a scrim under copy); visible focus rings; reduced motion
  verified frame by frame. Frames 05–08 are light text on dark art — check
  those first.
- **Tests:** unit (story progress, beat controller, camera math), widget
  (chapter enter/exit, tabs, responsive breakpoints), golden (all 12 frames),
  and a manual narrative QA pass — a reviewer completes the journey without a
  dead end.
- **Deploy:** GitHub Actions → GitHub Pages or Firebase Hosting, goldens gating
  the deploy.

---

## Release mapping

| Release | Phases | Contents |
|---|---|---|
| **R1 — The First Story** | 1–6 | All 12 frames: Landing, Workshop, Map, FYERS end to end, Personal, Contact |
| R2 — The Journey | 7–8 | Character motion, BossWallah, PartyHunt, SMVDU |
| R3 — The Observatory | 9 (part) | AI exploration, diagrams |
| R4 — The Secret Layer | 9 (rest) | Dev mode, easter eggs, sound, night mode |
| R5 — The Living Portfolio | later | Grounded "Ask Gyan", live GitHub data |

---

## Design tokens to extract in Phase 2

Sampled from the frames — confirm with a colour picker against the PNGs:

- **Day:** sky `#8FBEDE` → `#C9E2F0`, mountain haze `#6E7FA8`, forest `#4E7A52`
- **Night:** panel `#16243Acc`, panel border `#FFFFFF1F`, body `#DDE6F2`,
  metric value `#5AA9F0`, alert total `#FF6B6B`
- **Sunset:** sky `#F5A65B` → `#7B5EA7`, water glint `#FFD9A0`
- **Parchment / card** `#F6EEDC`, ink `#3A2B1F`, muted ink `#6B5B4C`
- **Accents:** CTA pill `#2A2724` on cream; success tick and active-node glow
  `#3FBF8F` / `#6FE3A0`
- **Wood:** `#8B6239`, plank shadow `#00000033`
- **Fonts:** a handwritten face for accents (Caveat / Patrick Hand), a warm
  humanist sans for body (Nunito / Inter), a mono for metrics (JetBrains Mono).
  Self-host in `assets/fonts` — do not fetch from Google Fonts at runtime, it
  costs you LCP.

---

## Open decisions

1. **Art pipeline** — confirm Option B (layered) over A (flat) or C
   (procedural).
2. **Layer source** — do you have layered sources for these 12 frames, or
   should Phase 3 slice the flat PNGs into depth layers?
3. **Beat navigation** — do frames 04–10 advance on scroll, on click, or both?
   Scroll-driven with click fallback is assumed.
4. **Character** — Rive (Phase 7) or sprite sheet? Rive is smoother, ~200 KB
   runtime.
5. **State management** — Riverpod assumed; say if you prefer bloc or provider.

---

## Status — what is built

Verified by `flutter analyze` (clean), `flutter test` (**136 tests**) and
`flutter build web --release`.

| Phase | State |
|---|---|
| 1 — Foundation | **Done.** Router, scene system, camera/parallax, reduced-motion gate |
| 2 — Design system | **Done.** Tokens, lighting arc, type ramp measured against the references, shared components |
| 3 — Frames 01–02 | **Done.** Landing and Workshop |
| 4 — Frame 03 | **Done.** Journey map, five stops on an animated trail |
| 5 — Frames 04–10 | **Done.** Seven beats, rendered by a generic `ChapterScene` |
| 6 — Frames 11–12 | **Done.** Personal side and contact |
| 7 — Motion & character | **Done.** Procedural walk cycle; the wanderer walks the trail between stops; ambience controller with a working toggle (see *Audio* below) |
| 8 — Remaining chapters | **Done.** SMVDU, PartyHunt, FYERS, BossWallah — all four from `docs/resume.pdf` |
| 9 — Observatory + secret layer | **Done.** Four inspectable systems with per-item credibility badges; developer mode via Konami or `?dev` |
| 10 — Perf, a11y, QA | **Done.** Deferred per-scene loading, WCAG contrast gate, narrative route-graph QA, responsive suite, CI workflow |

### Content is résumé-derived

All four chapters and the Observatory are written from `docs/resume.pdf`
(the Flutter résumé). Where the résumé gives no figure, nothing is invented.

- **SMVDU** — B.Tech CS, coursework, Code Club top 10, House Cricket League
- **PartyHunt** — Create Party and Create Brand, Firebase trio, 30% defect reduction
- **FYERS** — Portfolio module, 700 ms startup, Shorebird OTA channels, custom GitHub Actions replacing Codemagic, trend-chart date/time, Quick View, Firebase push, Meta + CleverTap
- **BossWallah** — Flutter 3.24 → 3.35.0 migration, Adjust SDK attribution, Finance module, timezone-aware scheduling

### Audio

The ambience is **synthesised, not sampled** — `tool/generate_ambience.py`
writes five seamless OGG Vorbis loops into `assets/audio`, one per lighting
state. Nothing is taken from a recording, so there is no licence question on a
site you will send to employers, and regenerating is deterministic.

Each loop is two layers: a **bed** (wind, birds, crickets, room tone) and a
**score**. The score is one piece of music — a slow waltz in F major, 75 bpm,
twelve bars — re-orchestrated per lighting state rather than rewritten:

| Loop | Scoring |
|---|---|
| `valley-day` | Piano waltz, strings, wooden flute on the melody |
| `valley-dusk` | The same theme in D minor; piano down to the bass note, cello under it |
| `valley-sunset` | Strings two bars at a time, single piano notes left to ring |
| `room-night` | Music box and a quiet string pad, with a lot of silence |
| `room-interior` | Marimba — wood, because everything in that room is |

The instruments are synthesised from their physics rather than sampled: the
piano's partials are stretched by string stiffness and its highs decay faster
than its lows, the marimba's overtones sit near the fourth and ninth harmonics,
the music box is deliberately out of tune with itself above the fundamental.
Melodies are written in the same octave as the harmony, then lifted an octave
clear of it, and every note is nudged off the grid and off its printed dynamic
by a fixed amount, so the result is played rather than triggered.

Loops are seamless by construction rather than by cross-fading: noise layers
are built in the frequency domain (so they are inherently periodic), drones use
whole numbers of cycles per loop, and every note and one-shot event is placed
with wraparound — a piano note struck in the last bar rings on across the seam
into the first. The generator prints a seam measurement: the wrap compared to
the largest ordinary step in the few milliseconds *around* it, since the seam
can land inside a mallet strike where every step is large. All five come in
under 1.0, so the wrap is indistinguishable from its own neighbourhood.

101–175 KB per loop, 679 KB for all five. Ambience is off by default and only
the current scene's loop is ever fetched, and only once a visitor switches it
on, so it costs nothing on first load. `LoopingAmbiencePlayer` holds two decks
and cross-fades between them on an equal-power curve — with a melody playing,
cutting one loop off to start another is the thing that would make it sound
like a website. A blocked autoplay policy degrades to silence, not an error.

To change the music, edit the chord progressions and note lists at the bottom
of the generator and re-run it; to change the instruments, edit the voice
functions above them.

### Known gaps

- Reference frames 02, 03, 08 and 11 score lowest on layout correlation.
  Those are the most prop-dense paintings; the gap there is art, not layout.
- Frame 04's colour is well off its reference (`dLab` ~46).
- Deferred loading moved ~160 KB out of the initial bundle. The remainder is
  the Flutter runtime, which `deferred as` cannot split — the honest win is
  about 6%, not a halving.
- The mockups show a 3.2 s → 2.5 s startup and a per-stage timeline. Neither
  is on the résumé, so the chapter shows the 700 ms delta instead.
- No Rive character; the walk cycle is procedural.
- The ambience is synthesised, so both the instruments and the weather are
  models rather than recordings — close enough to read as piano, flute and
  marimba, not close enough to pass for them. Real recordings would need a
  licence that permits redistribution.
