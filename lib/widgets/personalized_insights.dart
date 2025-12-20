import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class PersonalizedInsights extends StatelessWidget {
  final double averageAccuracy;
  final int totalTimeSpent;
  final int streakDays;
  final int itemsCompletedToday;
  final int dailyGoal;

  const PersonalizedInsights({
    super.key,
    required this.averageAccuracy,
    required this.totalTimeSpent,
    required this.streakDays,
    required this.itemsCompletedToday,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserModel?>(context);
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

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
                Text('Personalized Insights',
                    style: theme.textTheme.headlineSmall),
                if (user != null)
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _exportInsights(context, user),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        insight['icon'] as IconData,
                        color: insight['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight['text'] as String,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _exportInsights(BuildContext context, UserModel user) {
    if (user.isPro) {
      // Implement export functionality for Pro users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Export functionality would be implemented here for Pro users')),
      );
    } else {
      // Show upgrade prompt for FREE users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Export is only available for Pro users. Upgrade to unlock this feature.')),
      );
    }
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];

    // Accuracy-based insights
    if (averageAccuracy < 70) {
      insights.add({
        'icon': Icons.trending_down,
        'color': Colors.orange,
        'text':
            'Your average accuracy is ${averageAccuracy.toStringAsFixed(1)}%. Consider reviewing flashcards more frequently to improve retention.'
      });
    } else if (averageAccuracy >= 90) {
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.green,
        'text':
            'Great job! Your average accuracy of ${averageAccuracy.toStringAsFixed(1)}% shows strong mastery of the material.'
      });
    }

    // Time-based insights
    if (totalTimeSpent > 0 && totalTimeSpent < 3600) {
      // Less than 1 hour
      insights.add({
        'icon': Icons.access_time,
        'color': Colors.blue,
        'text':
            'You\'ve spent ${_formatTime(totalTimeSpent)} learning. Consistent daily practice leads to better retention!'
      });
    } else if (totalTimeSpent >= 3600) {
      // 1 hour or more
      insights.add({
        'icon': Icons.hourglass_full,
        'color': Colors.green,
        'text':
            'Impressive dedication! You\'ve spent ${_formatTime(totalTimeSpent)} learning. Keep up the great work!'
      });
    }

    // Streak-based insights
    if (streakDays >= 7) {
      insights.add({
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'text':
            '🔥 $streakDays-day streak! Your consistency is paying off. Maintaining streaks builds lasting habits.'
      });
    }

    // Goal-based insights
    if (itemsCompletedToday >= dailyGoal) {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'text':
            '🎯 Daily goal achieved! You\'ve completed $itemsCompletedToday/$dailyGoal items today.'
      });
    } else if (dailyGoal > 0) {
      final remaining = dailyGoal - itemsCompletedToday;
      insights.add({
        'icon': Icons.arrow_forward,
        'color': Colors.blue,
        'text':
            '💪 $remaining more items to reach your daily goal of $dailyGoal.'
      });
    }

    return insights;
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      return '${minutes}m';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '${hours}h ${minutes}m';
    }
  }
}
