import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/quiz_data.dart';
import '../models/quiz_model.dart';

enum QuizStatus { idle, loading, ready, error }

enum AnswerStatus { unanswered, wrong, correct }

class QuizState {
  final QuizStatus status;
  final QuizModel? quiz;
  final AnswerStatus answerStatus;
  final String? selectedOption;
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.idle,
    this.quiz,
    this.answerStatus = AnswerStatus.unanswered,
    this.selectedOption,
    this.errorMessage,
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizModel? quiz,
    AnswerStatus? answerStatus,
    String? selectedOption,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      answerStatus: answerStatus ?? this.answerStatus,
      selectedOption: selectedOption,
      errorMessage: errorMessage,
    );
  }
}

/// Loads the quiz JSON (simulating a backend fetch) and tracks the child's
/// answer attempts.
///
/// Crucially, this notifier never assumes how many options exist — it just
/// parses whatever [QuizData.quizJson] provides into a [QuizModel] and hands
/// that model to the UI. Swap the JSON for a 3- or 5-option payload and
/// nothing here needs to change.
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

  Future<void> loadQuiz() async {
    state = state.copyWith(status: QuizStatus.loading);

    try {
      // Simulates network latency a real backend call would have.
      await Future.delayed(const Duration(milliseconds: 300));
      final quiz = QuizModel.fromJson(QuizData.quizJson);
      state = QuizState(status: QuizStatus.ready, quiz: quiz);
    } catch (e) {
      state = QuizState(
        status: QuizStatus.error,
        errorMessage: "Oops! Our quiz got shy. Let's try again.",
      );
    }
  }

  void selectOption(String option) {
    final quiz = state.quiz;
    if (quiz == null || state.answerStatus == AnswerStatus.correct) return;

    final isCorrect = quiz.isCorrect(option);
    state = state.copyWith(
      selectedOption: option,
      answerStatus: isCorrect ? AnswerStatus.correct : AnswerStatus.wrong,
    );
  }

  /// Lets the child try again after a wrong answer without losing the quiz.
  void clearWrongAnswer() {
    if (state.answerStatus == AnswerStatus.wrong) {
      state = state.copyWith(
        answerStatus: AnswerStatus.unanswered,
        selectedOption: null,
      );
    }
  }

  void reset() {
    state = const QuizState();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});
