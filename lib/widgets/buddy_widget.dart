import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Visual states the AI buddy can be in. Kept separate from narration/quiz
/// state types so this widget stays fully reusable outside this screen.
enum BuddyMood { idle, listening, happy }

/// A cute, reusable AI buddy illustration that reacts to what's happening
/// in the story flow: calmly bobbing when idle, perking up while narrating,
/// and bouncing with joy on a correct answer.
class BuddyWidget extends StatelessWidget {
  const BuddyWidget({
    super.key,
    required this.mood,
    this.size = 200,
  });

  final BuddyMood mood;
  final double size;

  String get _asset {
    switch (mood) {
      case BuddyMood.listening:
        return 'assets/images/buddy_listening.svg';
      case BuddyMood.happy:
        return 'assets/images/buddy_happy.svg';
      case BuddyMood.idle:
        return 'assets/images/buddy_idle.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      _asset,
      width: size,
      height: size,
    );

    // Each mood gets a distinct, premium-feeling micro-animation.
    switch (mood) {
      case BuddyMood.idle:
        return svg
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -8, duration: 1400.ms, curve: Curves.easeInOut);
      case BuddyMood.listening:
        return svg
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms, curve: Curves.easeInOut);
      case BuddyMood.happy:
        return svg
            .animate()
            .scaleXY(
              begin: 0.7,
              end: 1.0,
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .shake(hz: 3, duration: 500.ms, offset: const Offset(4, 0));
    }
  }
}
