import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'achievement_badge.dart';
import '../models/user_model.dart';

class AchievementsTracker extends StatelessWidget {
  final int streakDays;
  final int totalItemsCompleted;
  final int quizzesTaken;
  final int flashcardsReviewed;

  const AchievementsTracker({
    super.key,
    required this.streakDays,
    required this.totalItemsCompleted,
    required this.quizzesTaken,
    required this.flashcardsReviewed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserModel?>(context);

    // Define achievements based on user stats
    final achievements = [
      {
        'title': 'First Steps',
        'description': 'Complete your first item',
        'icon': Icons.rocket_launch,
        'earned': totalItemsCompleted >= 1,
      },
      {
        'title': 'Consistency King',
        'description': 'Maintain a 7-day streak',
        'icon': Icons.local_fire_department,
        'earned': streakDays >= 7,
      },
      {
        'title': 'Knowledge Seeker',
        'description': 'Complete 50 items',
        'icon': Icons.school,
        'earned': totalItemsCompleted >= 50,
      },
      {
        'title': 'Quiz Master',
        'description': 'Take 10 quizzes',
        'icon': Icons.quiz,
        'earned': quizzesTaken >= 10,
      },
      {
        'title': 'Flashcard Fanatic',
        'description': 'Review 100 flashcards',
        'icon': Icons.flip_camera_android,
        'earned': flashcardsReviewed >= 100,
      },
      {
        'title': 'Marathon Learner',
        'description': 'Complete 200 items',
        'icon': Icons.emoji_events,
        'earned': totalItemsCompleted >= 200,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Achievements', style: theme.textTheme.headlineSmall),
                if (user != null && !user.isPro)
                  const Icon(Icons.lock_outline, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${achievements.where((a) => a['earned'] == true).length}/${achievements.length} unlocked',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (user != null && !user.isPro)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Full rewards available with Pro',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ...achievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AchievementBadge(
                    title: achievement['title'] as String,
                    description: achievement['description'] as String,
                    icon: achievement['icon'] as IconData,
                    isEarned: achievement['earned'] as bool,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
