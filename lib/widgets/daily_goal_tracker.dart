import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DailyGoalTracker extends StatelessWidget {
  final int itemsCompleted;
  final int dailyGoal;
  final VoidCallback? onSetGoal;

  const DailyGoalTracker({
    super.key,
    required this.itemsCompleted,
    required this.dailyGoal,
    this.onSetGoal,
  });

  double get progressPercentage {
    if (dailyGoal == 0) return 0.0;
    return (itemsCompleted / dailyGoal).clamp(0.0, 1.0);
  }

  bool get isGoalAchieved => itemsCompleted >= dailyGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = progressPercentage;

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
                Text(
                  'Daily Goal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onSetGoal != null)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: onSetGoal,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 12.0,
              percent: progress,
              center: Text(
                '$itemsCompleted/$dailyGoal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: isGoalAchieved
                  ? Colors.green
                  : progress > 0.75
                      ? theme.colorScheme.primary
                      : Colors.orange,
              backgroundColor: theme.dividerColor,
            ),
            const SizedBox(height: 16),
            if (isGoalAchieved)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎉 Goal Achieved!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
