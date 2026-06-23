import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';

/// Renders a quiz entirely from a [QuizModel] — the question text and
/// however many options it contains. There is no assumption anywhere in
/// this widget about option count: `ListView.builder` (via `Column` +
/// `map`, which is equivalent for short, non-scrolling lists) iterates
/// over whatever `quiz.options` provides. Feed it 3, 4, or 5 options and
/// the layout adapts without a single code change.
class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.quiz,
    required this.answerStatus,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  final QuizModel quiz;
  final AnswerStatus answerStatus;
  final String? selectedOption;
  final void Function(String option) onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final isWrong = answerStatus == AnswerStatus.wrong;

    Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft(),
        border: isWrong
            ? Border.all(color: AppColors.error.withOpacity(0.4), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.secondaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quick Quiz!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quiz.question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          // Data-driven option list — works for any length of quiz.options.
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quiz.options.length,
            itemBuilder: (context, index) {
              final option = quiz.options[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionTile(
                  option: option,
                  isSelected: selectedOption == option,
                  answerStatus: answerStatus,
                  isCorrectOption: option == quiz.answer,
                  onTap: () => onOptionSelected(option),
                ),
              );
            },
          ),
          if (isWrong)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Not quite — give it another try! 💪',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );

    if (isWrong) {
      // Shake feedback on a wrong answer, as specified. (Haptic feedback
      // is triggered once, on the state *transition*, by the screen that
      // owns this card — see home_screen.dart's ref.listen block. Firing
      // it here in build() would re-trigger it on every rebuild while the
      // answer stays "wrong", not just the moment it becomes wrong.)
      card = card
          .animate()
          .shake(hz: 4, duration: 450.ms, offset: const Offset(6, 0));
    }

    return card.animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.08,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.answerStatus,
    required this.isCorrectOption,
    required this.onTap,
  });

  final String option;
  final bool isSelected;
  final AnswerStatus answerStatus;
  final bool isCorrectOption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = answerStatus == AnswerStatus.correct;

    // Determine visual state for this specific tile.
    Color borderColor = AppColors.background;
    Color bgColor = AppColors.background;
    Color textColor = AppColors.textPrimary;
    Widget? trailing;

    if (isSelected && answerStatus == AnswerStatus.wrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withOpacity(0.08);
      trailing = const Icon(Icons.close_rounded, color: AppColors.error);
    } else if (isSelected && answerStatus == AnswerStatus.correct) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      trailing = const Icon(Icons.check_circle_rounded, color: AppColors.success);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
