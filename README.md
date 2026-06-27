# Peblo Story Buddy 🤖📖

An AI-narrated story and interactive quiz experience for kids, built for the **Peblo Flutter Developer Internship Challenge**.

A child taps **"Read Me A Story"**, listens to a short narrated story, and then answers a quiz question rendered entirely from a JSON payload — exactly as if it had been served by Peblo's backend. Wrong answers shake and invite another try; the correct answer triggers confetti, a happy buddy, and a success screen.

---

## 1. Project Overview

The app is a single, focused screen with four moments, matching the brief's wireframe:

1. **Buddy + header** — a small robot character (Pip) that reacts to what's happening.
2. **Story card** — the narration text and the "Read Me A Story" button, with loading / speaking / error states.
3. **Quiz card** — appears the instant narration finishes, rendered from a JSON object with no assumptions about option count.
4. **Success card** — confetti, a happy buddy, and a "Play Again" reset.

The visual language deliberately avoids a "generic Flutter template" or dark UI — bright gradients, rounded 28px cards, soft shadows, and Poppins typography throughout, in line with apps like Khan Academy Kids or Lingokids.

## 2. Why Flutter

Flutter was the natural choice for this brief for three reasons:

- **Single codebase, two platforms.** Peblo's stated audience is mostly Android, but a children's product benefits from also reaching iOS without maintaining two native codebases.
- **Animation control.** `flutter_animate` and a custom `Transform`/`AnimatedContainer` toolkit make it straightforward to hit the "shake, confetti, bounce, fade" requirements at 60fps without hand-rolling `AnimationController`s for every widget.
- **Native TTS access.** `flutter_tts` wraps `AVSpeechSynthesizer` on iOS and Android's `TextToSpeech` engine behind one API, which satisfies the brief's "acceptable: native TTS engine" requirement without needing a paid cloud API for the core flow.

## 3. Architecture

```
lib/
├── main.dart              # Entry point: ProviderScope + orientation lock
├── app.dart                # MaterialApp + theme wiring
│
├── models/
│   └── quiz_model.dart      # QuizModel + strict fromJson() parsing/validation
│
├── providers/
│   ├── quiz_provider.dart   # Quiz fetch + answer state machine (Riverpod)
│   └── tts_provider.dart    # Narration state machine (Riverpod)
│
├── services/
│   └── tts_service.dart     # Thin wrapper around the flutter_tts plugin
│
├── screens/
│   └── home_screen.dart     # Composes everything; owns ConfettiController
│
├── widgets/
│   ├── buddy_widget.dart    # Reusable AI buddy (idle / listening / happy)
│   ├── story_card.dart      # Narration trigger + states
│   ├── quiz_card.dart       # Data-driven quiz renderer
│   ├── success_card.dart    # Celebration card
│   └── loading_widget.dart  # Shared "getting ready" indicator
│
├── data/
│   └── quiz_data.dart       # Story text + quiz JSON (stand-in for a backend call)
│
└── theme/
    └── app_theme.dart       # Single source of truth for colors, radii, shadows, type
```

The layering is intentionally strict:

- **Widgets** never read JSON or talk to plugins — they take typed data and callbacks.
- **Providers** own all state transitions and are the only thing screens listen to.
- **Services** are the only place that touches a third-party plugin (`flutter_tts`), so a future swap to a cloud TTS API (ElevenLabs, etc.) only touches one file.

## 4. State Management — Riverpod

Two `StateNotifierProvider`s drive the whole screen:

- **`ttsProvider`** → `NarrationStatus { idle, loading, speaking, completed, error }`. This maps directly onto the brief's required flow: *tap → loading → speaking → audio complete*.
- **`quizProvider`** → `QuizStatus { idle, loading, ready, error }` plus an `AnswerStatus { unanswered, wrong, correct }` for the in-progress answer.

`HomeScreen` uses `ref.listen` (not `ref.watch`) for the two cross-cutting side effects that aren't really "build" concerns:

```dart
// Narration → quiz handoff
ref.listen<TtsState>(ttsProvider, (previous, next) {
  final justCompleted = previous?.status != NarrationStatus.completed &&
      next.status == NarrationStatus.completed;
  if (justCompleted && quizState.status == QuizStatus.idle) {
    ref.read(quizProvider.notifier).loadQuiz();
  }
});

// Correct answer → confetti
ref.listen<QuizState>(quizProvider, (previous, next) {
  final justCorrect = previous?.answerStatus != AnswerStatus.correct &&
      next.answerStatus == AnswerStatus.correct;
  if (justCorrect) _confettiController.play();
});
```

**Why `ref.listen` instead of triggering side effects from inside the TTS completion callback directly:** it keeps the "what happens when narration finishes" decision in the screen/composition layer, not buried inside the TTS service. The service only reports *that* narration finished — it has no opinion about quizzes existing at all. This is what lets `TtsService` and `BuddyWidget` be dropped into a completely different screen (e.g. a future "Story Library" feature) with zero changes.

### Handling the audio-end → quiz-appear transition

This was the trickiest piece of state-machine design in the brief. The risk is double-firing: if both the `Future` returned by `_tts.speak()` *and* the `setCompletionHandler` callback fire "success," the quiz could try to load twice, or the buddy could flicker between moods. The fix, in `TtsService.speak()`, is a `settled` flag shared by closures so completion/error is reported **exactly once**, regardless of which of the plugin's several callback paths fires first (see the in-code comment in `tts_service.dart` for the full reasoning).

## 5. Data-Driven Quiz Design

`QuizCard` never assumes a number of options. It receives a `QuizModel` (parsed once, validated once, in `QuizModel.fromJson`) and iterates `quiz.options` with `ListView.builder`:

```dart
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: quiz.options.length,
  itemBuilder: (context, index) {
    final option = quiz.options[index];
    return _OptionTile(option: option, ...);
  },
),
```

To prove this, `quiz_data.dart` includes a second example payload (`alternateQuizJsonFiveOptions`) with 5 options and different question text. Swapping `QuizData.quizJson` for it in `quiz_provider.dart` is the *only* change needed to render a totally different quiz — no widget, no layout file, nothing in `quiz_card.dart` changes. `test/quiz_model_test.dart` asserts this directly for 3, 4, and 5-option payloads, plus malformed-JSON edge cases (empty options array, answer not present in options).

`QuizModel.fromJson` also **validates** the payload (answer must be one of the options, question/options/answer must be non-empty) and throws a `FormatException` with a clear message rather than letting a malformed backend response crash the UI — `quizProvider` catches this and surfaces the existing error/retry card.

## 6. TTS Integration

`TtsService` wraps `flutter_tts` and exposes a single `speak()` method with named callbacks (`onStart`, `onComplete`, `onError`) instead of leaking the plugin's handler-registration API into the rest of the app.

State surfaced to the UI:

| State | UI |
|---|---|
| `idle` | "Read Me A Story" button |
| `loading` | Bouncing-dots loader, button replaced |
| `speaking` | Same loader (different label), buddy switches to "listening" mood, story card gets a highlighted border |
| `completed` | Quiz card fades in |
| `error` | Child-friendly message ("Oops! Let's try that again.") + Retry button |

Speech is configured for a child audience specifically: `setSpeechRate(0.42)` (slower than the 0.5 default) and `setPitch(1.05)` (slightly brighter) so narration is easy to follow without sounding artificial.

## 7. Error Handling

Three failure points are handled explicitly, all surfacing the same friendly copy rather than a stack trace:

1. **TTS engine init failure** (no engine installed / platform channel error) — caught in `TtsService.initialize()`, surfaced via `TtsException`.
2. **Mid-speech failure** (engine killed, interrupted by another app's audio focus, etc.) — caught via `setErrorHandler` in `TtsService.speak()`.
3. **Quiz "fetch" failure** (malformed JSON from `QuizModel.fromJson`) — caught in `QuizNotifier.loadQuiz()`.

Every failure path ends in the same UX pattern: a friendly sentence + a single, obvious **Retry** button. Nothing hangs, and nothing surfaces a raw exception message to a child.

## 8. Performance Optimization (mid-range Android target)

Concrete choices made with a ~3GB RAM Android device in mind:

- **Const constructors everywhere it's valid** (`analysis_options.yaml` enforces `prefer_const_constructors` as a lint, not just a guideline) — avoids rebuilding widget subtrees that never change.
- **`ListView.builder`** for quiz options instead of `Column(children: options.map(...))` — avoids building widgets for content that, while currently short, should scale the same way regardless of option count.
- **SVG over raster/Lottie for the buddy.** The brief listed `lottie` as optional; three small hand-authored SVGs (~1–2KB each) for idle/listening/happy moods cost far less memory and CPU than decoding a Lottie JSON animation on every mood change, while still giving each state a distinct animated treatment via `flutter_animate` transforms (move/scale/shake) applied *to* the SVG rather than *inside* it.
- **`ref.listen` instead of rebuilding on every provider change just to check "did we just become correct."** Using `watch` plus an `if` inside `build()` would re-run that comparison on every rebuild for unrelated reasons; `listen` only fires on actual state transitions.
- **Animations are transform/opacity-based** (`Transform`, `Opacity` via `flutter_animate`'s fade/scale/shake effects), which the Flutter engine can composite on the GPU without re-laying-out or repainting the subtree — this is what keeps shake/confetti smooth at 60fps on weaker GPUs.
- **No `setState` calls anywhere in the widget tree.** All state changes flow through Riverpod, and `ConsumerWidget`/`ConsumerStatefulWidget` only rebuild the parts of the tree that actually `watch` a given provider — `BuddyWidget`, `StoryCard`, and `QuizCard` are all separate widgets specifically so a quiz-state change doesn't force the buddy or story text to rebuild.

### What I'd profile next (and how)
With a physical mid-range Android device, the next concrete step would be:
1. Run the app in profile mode (`flutter run --profile`) and open the **Flutter DevTools Performance** tab.
2. Trigger the full flow (narrate → quiz → wrong answer → correct answer) while recording.
3. Look specifically at the frame chart during the **shake** and **confetti** moments, since those are the two steady streams of rebuilds — confirm no frame exceeds the 16.6ms (60fps) budget, and that the "Highlight widgets repainted on every frame" overlay shows only the confetti canvas and the shaking card, not the whole screen.
4. If a frame-timing screenshot were attached to this submission, it would be inserted here — this README is written ahead of running that specific test pass on physical hardware, so this section documents the *plan and method*, not a result.

## 9. Caching Strategy

The brief's caching question is most relevant if remote TTS audio is involved. Two layers, current and future:

- **Today (on-device TTS):** there is nothing to cache — `flutter_tts` synthesizes speech locally and there's no network round-trip or audio file to persist.
- **If swapped to a remote TTS API (e.g. ElevenLabs), the approach would be:**
  - Key the cache by a hash of `(text, voiceId, speed)` so identical story text never re-fetches audio.
  - Store the resulting audio bytes in the app's cache directory (`path_provider`'s `getTemporaryDirectory()`), not memory, so repeated app opens don't re-download the same story.
  - Evict by total cache size (e.g. cap at ~20MB of cached story audio) rather than by age, since a child re-reading their 5 favorite stories should never have to re-fetch any of them.
  - The swap point in code would be entirely inside `TtsService` — `speak()`'s public signature wouldn't need to change, only its internal implementation (check cache → play if hit → fetch, cache, then play if miss).

## 10. AI Usage Disclosure

AI assistance (this Claude session) was used to:
- Scaffold the full file/folder structure from the brief's spec.
- Write the initial draft of every Dart file.
- **Verify package APIs against current documentation** rather than relying purely on training-data recall — for example, confirming the exact `flutter_tts` handler signatures, the `confetti` package's `ConfettiWidget` constructor parameters, and the `flutter_animate` `ShakeEffect` parameters via live web searches mid-build, specifically because animation/plugin APIs are exactly the kind of detail that goes stale.

**A suggestion I rejected:** my first draft of `TtsService.speak()` set `onComplete` from both `setCompletionHandler` *and* by checking the return value of the awaited `_tts.speak()` call once it resolved. After re-reading how `awaitSpeakCompletion(true)` actually works, I realized this double-fires completion — the awaited call and the handler both resolve at the same moment, on the same successful path, which would call `onComplete` twice. I reworked it to a single `settled` boolean shared by `completeOnce`/`errorOnce` closures so exactly one outcome is ever reported per call to `speak()`, regardless of which of the plugin's callback paths fires first.

**A platform quirk I worked around:** `awaitSpeakCompletion(true)` has documented Android crash reports in the `flutter_tts` issue tracker on certain device/OS combinations. Since this app explicitly targets mid-range Android hardware, I wrapped that single call in its own try/catch in `TtsService.initialize()` so a failure there degrades gracefully (narration still works, it just relies purely on the handler callbacks rather than the awaited Future) instead of taking down story narration entirely on an affected device.

**What I'd still want to validate on real hardware:** the exact `flutter_animate` `ShakeEffect` parameter set (specifically whether a `rotation` parameter exists alongside `offset`) wasn't fully confirmed by the documentation excerpts available during this session. Rather than ship an unverified parameter name that could fail to compile, every `.shake()` call in this codebase intentionally sticks to the parameters I could directly confirm (`hz`, `duration`, `offset`) — a deliberately conservative choice over a flashier one I couldn't verify.

## 11. How to Run

```bash
flutter pub get
flutter run
```

Requires Flutter's latest stable channel (Dart SDK ≥ 3.4). No environment variables, API keys, or backend are needed — the story and quiz content in `lib/data/quiz_data.dart` stand in for what would be a network call in production.

To see the data-driven renderer handle a different quiz shape, open `lib/providers/quiz_provider.dart` and swap:

```dart
final quiz = QuizModel.fromJson(QuizData.quizJson);
```

for:

```dart
final quiz = QuizModel.fromJson(QuizData.alternateQuizJsonFiveOptions);
```

— no other file needs to change.

Run the unit tests with:

```bash
flutter test
```

