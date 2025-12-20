import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/firestore_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/personalized_insights.dart';
import '../../widgets/activity_chart.dart';
import '../../widgets/achievements_tracker.dart';
import '../../widgets/daily_goal_tracker.dart';
import '../../widgets/goal_setting_dialog.dart';
import '../../services/user_service.dart';
import '../../widgets/pro_gate.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null) {
      _statsFuture = _loadStats(user.uid);
    }
  }

  Future<Map<String, dynamic>> _loadStats(String userId) async {
    try {
      final dbService = LocalDatabaseService();
      await dbService.init(); // Ensure initialized
      final srsService =
          SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      final firestoreService = FirestoreService();
      final progressService = ProgressService();

      // Fetch all data in parallel
      final srsStatsFuture = srsService.getStatistics(userId);
      final firestoreStatsFuture =
          firestoreService.streamAllItems(userId).first;
      final accuracyFuture = progressService.getAverageAccuracy(userId);
      final timeSpentFuture = progressService.getTotalTimeSpent(userId);

      final results = await Future.wait([
        srsStatsFuture,
        firestoreStatsFuture,
        accuracyFuture,
        timeSpentFuture
      ]);
      final srsStats = results[0];
      final firestoreStats = results[1] as Map<String, List<dynamic>>;
      final averageAccuracy = results[2] as double;
      final totalTimeSpent = results[3] as int;

      final summariesCount = firestoreStats['summaries']?.length ?? 0;
      final quizzesCount = firestoreStats['quizzes']?.length ?? 0;
      final flashcardsCount = firestoreStats['flashcards']?.length ?? 0;

      final Map<String, dynamic> result = {
        ...srsStats as Map<String, dynamic>,
        'summariesCount': summariesCount,
        'quizzesCount': quizzesCount,
        'flashcardsCount': flashcardsCount,
        'averageAccuracy': averageAccuracy,
        'totalTimeSpent': totalTimeSpent,
      };
      developer.log('Stats loaded successfully: $result',
          name: 'ProgressScreen');
      return result;
    } catch (e, s) {
      developer.log('Error loading stats',
          name: 'ProgressScreen', error: e, stackTrace: s);
      // Rethrow the error to be caught by the FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Center(
          child: Text('Please log in to view your progress.',
              style: theme.textTheme.bodyMedium));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Progress', style: theme.textTheme.headlineMedium),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSurface)));
          }
          if (snapshot.hasError) {
            developer.log('FutureBuilder error',
                name: 'ProgressScreen',
                error: snapshot.error,
                stackTrace: snapshot.stackTrace);
            return _buildErrorState(user.uid, snapshot.error!, theme);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(user.uid, theme);
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _loadStats(user.uid);
              });
            },
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMissionEngineHero(user, theme),
                    const SizedBox(height: 32),
                    DailyGoalTracker(
                      itemsCompleted: user.itemsCompletedToday,
                      dailyGoal: user.dailyGoal,
                      onSetGoal: () async {
                        final userService =
                            Provider.of<UserService>(context, listen: false);
                        final newGoal = await showDialog<int>(
                          context: context,
                          builder: (BuildContext context) {
                            return GoalSettingDialog(
                                currentGoal: user.dailyGoal);
                          },
                        );

                        if (newGoal != null && newGoal > 0) {
                          try {
                            await userService.updateDailyGoal(
                                user.uid, newGoal);
                            // Refresh the data
                            setState(() {
                              _statsFuture = _loadStats(user.uid);
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to update goal: $e')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildTopMetrics(stats, theme),
                    const SizedBox(height: 32),
                    _buildReviewBanner(
                        stats['dueForReviewCount'] as int? ?? 0, theme),
                    const SizedBox(height: 32),
                    ActivityChart(
                      activityData: stats['upcomingReviews']
                              as List<MapEntry<DateTime, int>>? ??
                          [],
                      title: 'Weekly Activity',
                    ),
                    const SizedBox(height: 32),
                    AchievementsTracker(
                      streakDays: user.missionCompletionStreak,
                      totalItemsCompleted: stats['summariesCount'] as int? ??
                          0 + stats['quizzesCount'] as int? ??
                          0 + stats['flashcardsCount'] as int? ??
                          0,
                      quizzesTaken: stats['quizzesCount'] as int? ?? 0,
                      flashcardsReviewed: stats['flashcardsCount'] as int? ?? 0,
                    ),
                    const SizedBox(height: 32),
                    PersonalizedInsights(
                      averageAccuracy:
                          stats['averageAccuracy'] as double? ?? 0.0,
                      totalTimeSpent: stats['totalTimeSpent'] as int? ?? 0,
                      streakDays: user.missionCompletionStreak,
                      itemsCompletedToday: user.itemsCompletedToday,
                      dailyGoal: user.dailyGoal,
                    ),
                  ],
                ),
              ),
            )),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String userId, Object error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Something went wrong.', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Could not load your progress. Please try again later.',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Details: ${error.toString()}',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _statsFuture = _loadStats(userId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMissionEngineHero(UserModel user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Momentum Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Text('Momentum', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.currentMomentum.toStringAsFixed(0),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Decays 5% daily',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                ),
              ],
            ),
          ),
          // Streak Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.whatshot,
                        color: Colors.deepOrange, size: 28),
                    const SizedBox(width: 8),
                    Text('Streak', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.missionCompletionStreak}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.missionCompletionStreak == 1 ? 'day' : 'days',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetrics(Map<String, dynamic> stats, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Metrics', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricChip(theme, 'Summaries',
                  (stats['summariesCount'] ?? 0).toString()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricChip(
                  theme, 'Quizzes', (stats['quizzesCount'] ?? 0).toString()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricChip(theme, 'Flashcards',
                  (stats['flashcardsCount'] ?? 0).toString()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricChip(theme, 'Avg. Accuracy',
                  '${(stats['averageAccuracy'] ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.check_circle_outline),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricChip(theme, 'Time Spent',
                  _formatTimeSpent(stats['totalTimeSpent'] ?? 0),
                  icon: Icons.access_time),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMetricChip(ThemeData theme, String label, String value,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
          ],
          Text(value,
              style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  String _formatTimeSpent(int seconds) {
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

  Widget _buildReviewBanner(int dueCount, ThemeData theme) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: NetworkImage(
              'https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Freview_banner.png?alt=media&token=8f3955e8-1269-482d-9793-1fe2a27b134b'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor.withAlpha(178),
              Colors.transparent
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dueCount items',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: theme.colorScheme.onSurface)),
                Text('Due for review today',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String userId, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined,
              size: 80, color: theme.iconTheme.color),
          const SizedBox(height: 16),
          Text('No Progress Data Yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Complete some quizzes or flashcard reviews to see your progress here.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _statsFuture = _loadStats(userId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Refresh'),
          )
        ],
      ),
    );
  }
}
