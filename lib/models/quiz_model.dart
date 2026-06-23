/// Data model for a single quiz question.
///
/// This is intentionally generic: [options] is a plain list of strings of
/// *any* length, and the renderer (see `quiz_card.dart`) builds its UI from
/// that list with `ListView.builder`. Nothing about the UI assumes a fixed
/// number of options — feeding this model a 3, 4, or 5-option JSON payload
/// requires no code changes anywhere in the app.
class QuizModel {
  final String question;
  final List<String> options;
  final String answer;

  const QuizModel({
    required this.question,
    required this.options,
    required this.answer,
  });

  /// Parses a quiz question from a JSON map shaped like the backend
  /// contract described in the challenge brief:
  /// ```json
  /// {
  ///   "question": "...",
  ///   "options": ["...", "...", "...", "..."],
  ///   "answer": "..."
  /// }
  /// ```
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw const FormatException(
        'Quiz JSON is missing a non-empty "options" array.',
      );
    }

    final question = json['question'];
    final answer = json['answer'];
    if (question is! String || question.isEmpty) {
      throw const FormatException('Quiz JSON is missing a "question" string.');
    }
    if (answer is! String || answer.isEmpty) {
      throw const FormatException('Quiz JSON is missing an "answer" string.');
    }

    final options = rawOptions.map((e) => e.toString()).toList();

    if (!options.contains(answer)) {
      throw const FormatException(
        'Quiz JSON "answer" must match one of the provided "options".',
      );
    }

    return QuizModel(
      question: question,
      options: options,
      answer: answer,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
      };

  bool isCorrect(String selected) => selected == answer;
}
