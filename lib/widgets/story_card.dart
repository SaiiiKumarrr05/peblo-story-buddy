import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/tts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';

/// Displays the story text and the primary "Read Me a Story" call to
/// action, fully reflecting the current [TtsState]: idle, loading,
/// speaking, completed, or error (with retry).
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.storyText,
    required this.ttsState,
    required this.onReadPressed,
  });

  final String storyText;
  final TtsState ttsState;
  final VoidCallback onReadPressed;

  @override
  Widget build(BuildContext context) {
    final isBusy = ttsState.isBusy;
    final isError = ttsState.status == NarrationStatus.error;
    final isSpeaking = ttsState.status == NarrationStatus.speaking;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft(),
        border: isSpeaking
            ? Border.all(color: AppColors.primary.withOpacity(0.35), width: 2)
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Story Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            storyText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          if (isError) _buildError(context),
          if (!isError) _buildActionArea(context, isBusy, isSpeaking),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, bool isBusy, bool isSpeaking) {
    if (isBusy) {
      return Center(
        child: LoadingWidget(
          label: isSpeaking ? 'Reading aloud...' : 'Getting the story ready...',
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onReadPressed,
        icon: const Icon(Icons.volume_up_rounded),
        label: const Text('Read Me A Story'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(58),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildError(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.sentiment_dissatisfied_rounded,
                  color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ttsState.errorMessage ?? "Oops! Let's try that again.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onReadPressed,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            minimumSize: const Size.fromHeight(58),
          ),
        ),
      ],
    ).animate().shake(hz: 3, duration: 400.ms);
  }
}
