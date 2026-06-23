import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A playful loading indicator — three bouncing dots — used while TTS is
/// preparing audio or the quiz JSON is "loading". Avoids the default
/// circular progress spinner, which feels clinical rather than playful.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.label = 'Getting ready...',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final colors = [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
            ];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                    delay: (i * 150).ms,
                  )
                  .moveY(begin: 0, end: -12, duration: 450.ms, curve: Curves.easeInOut),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
