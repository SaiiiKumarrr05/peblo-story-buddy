import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Celebratory card shown after a correct answer. Confetti itself is
/// rendered at the screen level (it needs to overlay the whole viewport),
/// but this card supplies the message, icon, and "Play Again" affordance.
class SuccessCard extends StatelessWidget {
  const SuccessCard({
    super.key,
    required this.onPlayAgain,
  });

  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.successGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft(color: AppColors.success),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ).animate().scaleXY(
                begin: 0,
                end: 1,
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Text(
            'Great Job! 🎉',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "You found the answer! Pip is so happy.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.replay_rounded, color: Colors.white),
              label: const Text(
                'Play Again',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 2),
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
