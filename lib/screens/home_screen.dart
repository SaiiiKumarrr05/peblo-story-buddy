import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/quiz_data.dart';
import '../providers/quiz_provider.dart';
import '../providers/tts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/quiz_card.dart';
import '../widgets/story_card.dart';
import '../widgets/success_card.dart';

/// The single screen for Peblo Story Buddy.
///
/// Responsible only for composing widgets and wiring Riverpod state to
/// them — all business logic lives in the providers, and all visual
/// presentation lives in the widgets/ folder. This keeps the screen itself
/// thin and easy to reason about.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleReadStory() async {
    await ref.read(ttsProvider.notifier).narrate(QuizData.storyText);
  }

  void _handlePlayAgain() {
    ref.read(quizProvider.notifier).reset();
    ref.read(ttsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(ttsProvider);
    final quizState = ref.watch(quizProvider);

    // React to narration completing by loading the quiz exactly once,
    // capturing the "Audio Complete → Quiz Appears" transition from the
    // brief's state flow.
    ref.listen<TtsState>(ttsProvider, (previous, next) {
      final justCompleted = previous?.status != NarrationStatus.completed &&
          next.status == NarrationStatus.completed;
      if (justCompleted && quizState.status == QuizStatus.idle) {
        ref.read(quizProvider.notifier).loadQuiz();
      }
    });

    // Fire confetti exactly once when the answer becomes correct, and a
    // single haptic buzz exactly once when it becomes wrong — both as
    // state *transitions*, not on every rebuild where the status happens
    // to already be correct/wrong.
    ref.listen<QuizState>(quizProvider, (previous, next) {
      final justCorrect = previous?.answerStatus != AnswerStatus.correct &&
          next.answerStatus == AnswerStatus.correct;
      if (justCorrect) {
        _confettiController.play();
      }

      final justWrong = previous?.answerStatus != AnswerStatus.wrong &&
          next.answerStatus == AnswerStatus.wrong;
      if (justWrong) {
        HapticFeedback.mediumImpact();
      }
    });

    final buddyMood = _resolveBuddyMood(ttsState, quizState);

    return Scaffold(
      body: Stack(
        children: [
          // Soft brand-colored gradient background — bright, never dark.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFFFFF1DC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                children: [
                  _buildHeader(context, buddyMood),
                  const SizedBox(height: 24),
                  StoryCard(
                    storyText: QuizData.storyText,
                    ttsState: ttsState,
                    onReadPressed: _handleReadStory,
                  ),
                  const SizedBox(height: 20),
                  _buildQuizArea(quizState),
                ],
              ),
            ),
          ),
          // Confetti overlay, centered at the top, falling down across
          // the whole screen.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 18,
              minBlastForce: 8,
              emissionFrequency: 0.06,
              numberOfParticles: 24,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.success,
              ],
            ),
          ),
        ],
      ),
    );
  }

  BuddyMood _resolveBuddyMood(TtsState ttsState, QuizState quizState) {
    if (quizState.answerStatus == AnswerStatus.correct) {
      return BuddyMood.happy;
    }
    if (ttsState.status == NarrationStatus.speaking ||
        ttsState.status == NarrationStatus.loading) {
      return BuddyMood.listening;
    }
    return BuddyMood.idle;
  }

  Widget _buildHeader(BuildContext context, BuddyMood mood) {
    return Column(
      children: [
        BuddyWidget(mood: mood, size: 180),
        const SizedBox(height: 12),
        Text(
          'Peblo Story Buddy',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          "Let's listen and learn!",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuizArea(QuizState quizState) {
    switch (quizState.status) {
      case QuizStatus.idle:
        return const SizedBox.shrink();

      case QuizStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: LoadingWidget(label: 'Preparing your quiz...')),
        );

      case QuizStatus.error:
        return _buildQuizError(quizState);

      case QuizStatus.ready:
        if (quizState.answerStatus == AnswerStatus.correct) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SuccessCard(onPlayAgain: _handlePlayAgain),
          );
        }
        return QuizCard(
          quiz: quizState.quiz!,
          answerStatus: quizState.answerStatus,
          selectedOption: quizState.selectedOption,
          onOptionSelected: (option) {
            ref.read(quizProvider.notifier).selectOption(option);
            // Give the child a moment to see the shake feedback, then
            // unlock the options again so they can retry.
            if (!quizState.quiz!.isCorrect(option)) {
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) {
                  ref.read(quizProvider.notifier).clearWrongAnswer();
                }
              });
            }
          },
        );
    }
  }

  Widget _buildQuizError(QuizState quizState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          Text(
            quizState.errorMessage ?? "Oops! Let's try that again.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => ref.read(quizProvider.notifier).loadQuiz(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ).animate().shake(hz: 3, duration: 400.ms);
  }
}
