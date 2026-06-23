import 'package:flutter_test/flutter_test.dart';
import 'package:peblo_story_buddy/models/quiz_model.dart';

void main() {
  group('QuizModel.fromJson', () {
    test('parses a standard 4-option quiz', () {
      final quiz = QuizModel.fromJson({
        "question": "What colour was Pip the Robot's lost gear?",
        "options": ["Red", "Green", "Blue", "Yellow"],
        "answer": "Blue",
      });

      expect(quiz.options.length, 4);
      expect(quiz.isCorrect("Blue"), isTrue);
      expect(quiz.isCorrect("Red"), isFalse);
    });

    test('parses a 3-option quiz without any code changes', () {
      final quiz = QuizModel.fromJson({
        "question": "How many gears does Pip have?",
        "options": ["One", "Two", "Three"],
        "answer": "Two",
      });

      expect(quiz.options.length, 3);
      expect(quiz.isCorrect("Two"), isTrue);
    });

    test('parses a 5-option quiz without any code changes', () {
      final quiz = QuizModel.fromJson({
        "question": "Where did Pip lose his gear?",
        "options": [
          "The Whispering Woods",
          "The Crystal Cave",
          "Sunny Meadow",
          "The Old Workshop",
          "Riverbend Bridge",
        ],
        "answer": "The Whispering Woods",
      });

      expect(quiz.options.length, 5);
      expect(quiz.isCorrect("The Whispering Woods"), isTrue);
    });

    test('throws FormatException when answer is not among options', () {
      expect(
        () => QuizModel.fromJson({
          "question": "Bad data?",
          "options": ["A", "B"],
          "answer": "C",
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when options array is empty', () {
      expect(
        () => QuizModel.fromJson({
          "question": "Bad data?",
          "options": [],
          "answer": "C",
        }),
        throwsFormatException,
      );
    });
  });
}
