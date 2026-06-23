/// Simulates content that would normally be served by Peblo's backend.
///
/// In production, [storyText] and the raw quiz JSON would come from an API
/// call (see `quiz_provider.dart` for where that swap would happen — the
/// rest of the app already treats this data as "data from the network" and
/// doesn't care where it originates).
class QuizData {
  QuizData._();

  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny "
      "blue gear in the Whispering Woods. Pip searched high and low, under "
      "mossy rocks and inside hollow logs, determined to find it before "
      "sundown.";

  /// The raw JSON payload exactly as Peblo's backend would send it.
  /// Swap this for a different question/option count to prove the renderer
  /// is genuinely data-driven — no UI code changes are needed.
  static const Map<String, dynamic> quizJson = {
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue",
  };

  /// Example of a *different* payload (5 options) to demonstrate the
  /// renderer scales without modification. Not wired up by default —
  /// swap [quizJson] for this in `quiz_provider.dart` to test it live.
  static const Map<String, dynamic> alternateQuizJsonFiveOptions = {
    "question": "Where did Pip lose his gear?",
    "options": [
      "The Whispering Woods",
      "The Crystal Cave",
      "Sunny Meadow",
      "The Old Workshop",
      "Riverbend Bridge",
    ],
    "answer": "The Whispering Woods",
  };
}
