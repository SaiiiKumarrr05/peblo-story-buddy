import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Root widget of Peblo Story Buddy.
///
/// Deliberately tiny: theme and routing live here, everything else is
/// delegated to [HomeScreen] and the providers/widgets it composes.
class PebloStoryBuddyApp extends StatelessWidget {
  const PebloStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo Story Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Intentionally no darkTheme/themeMode override — this app is
      // always bright and light, by design, for its young audience.
      home: const HomeScreen(),
    );
  }
}
