import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/spaced_repetition_service.dart';
import 'package:sumquiz/services/firestore_service.dart';
import 'package:sumquiz/services/progress_service.dart';
import 'package:sumquiz/widgets/activity_chart.dart';
import 'package:sumquiz/widgets/daily_goal_tracker.dart';
import 'package:sumquiz/widgets/goal_setting_dialog.dart';
import 'package:sumquiz/services/user_service.dart';

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
      final srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      final firestoreService = FirestoreService();
      final progressService = ProgressService();

      final srsStatsFuture = srsService.getStatistics(userId);
      final firestoreStatsFuture = firestoreService.streamAllItems(userId).first;
      final accuracyFuture = progressService.getAverageAccuracy(userId);
      final timeSpentFuture = progressService.getTotalTimeSpent(userId);

      final results = await Future.wait([srsStatsFuture, firestoreStatsFuture, accuracyFuture, timeSpentFuture]);
      final srsStats = results[0] as Map<String, dynamic>;
      final firestoreStats = results[1] as Map<String, List<dynamic>>;
      final averageAccuracy = results[2] as double;
      final totalTimeSpent = results[3] as int;

      final result = {
        ...srsStats,
        'summariesCount': firestoreStats['summaries']?.length ?? 0,
        'quizzesCount': firestoreStats['quizzes']?.length ?? 0,
        'flashcardsCount': firestoreStats['flashcards']?.length ?? 0,
        'averageAccuracy': averageAccuracy,
        'totalTimeSpent': totalTimeSpent,
      };
      developer.log('Stats loaded successfully: $result', name: 'ProgressScreen');
      return result;
    } catch (e, s) {
      developer.log('Error loading stats', name: 'ProgressScreen', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text('Please log in to view your progress.', style: theme.textTheme.bodyLarge)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Your Progress', style: theme.textTheme.headlineSmall),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(user.uid, snapshot.error!);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(user.uid);
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _loadStats(user.uid);
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMomentumAndStreak(user),
                  const SizedBox(height: 24),
                  DailyGoalTracker(
                    itemsCompleted: user.itemsCompletedToday,
                    dailyGoal: user.dailyGoal,
                    onSetGoal: () => _setDailyGoal(user),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Overall Stats', Icons.pie_chart_outline_rounded),
                  const SizedBox(height: 16),
                  _buildOverallStats(stats),
                  const SizedBox(height: 24),
                   _buildSectionTitle(context, 'Recent Activity', Icons.trending_up_rounded),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: ActivityChart(activityData: stats['upcomingReviews'] as List<MapEntry<DateTime, int>>? ?? [])),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Review Priority', Icons.star_border_rounded),
                  const SizedBox(height: 16),
                  _buildReviewBanner(stats['dueForReviewCount'] as int? ?? 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _setDailyGoal(UserModel user) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => GoalSettingDialog(currentGoal: user.dailyGoal),
    );

    if (newGoal != null && newGoal > 0) {
      try {
        await userService.updateDailyGoal(user.uid, newGoal);
        setState(() {
          _statsFuture = _loadStats(user.uid);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update goal: $e')),
        );
      }
    }
  }
  
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _buildErrorState(String userId, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text('Something went wrong.', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Could not load your progress. Please try again later.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _statsFuture = _loadStats(userId)),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String userId) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 80, color: theme.iconTheme.color),
          const SizedBox(height: 16),
          Text('No Progress Data Yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Complete some quizzes or flashcard reviews to see your progress here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _statsFuture = _loadStats(userId)),
            child: const Text('Refresh'),
          )
        ],
      ),
    );
  }

  Widget _buildMomentumAndStreak(UserModel user) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Momentum', user.currentMomentum.toStringAsFixed(0), Icons.local_fire_department_rounded, Colors.orangeAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Streak', '${user.missionCompletionStreak} days', Icons.whatshot_rounded, Colors.redAccent)),
      ],
    );
  }

  Widget _buildOverallStats(Map<String, dynamic> stats) {
    final avgAccuracy = (stats['averageAccuracy'] as double? ?? 0.0).toStringAsFixed(1);
    final timeSpent = _formatTimeSpent(stats['totalTimeSpent'] as int? ?? 0);
    final summaries = (stats['summariesCount'] as int? ?? 0).toString();
    final quizzes = (stats['quizzesCount'] as int? ?? 0).toString();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Avg. Accuracy', '$avgAccuracy%', Icons.check_circle_outline_rounded, Colors.greenAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Time Spent', timeSpent, Icons.timer_rounded, Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Summaries', summaries, Icons.article_rounded, Colors.purpleAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Quizzes', quizzes, Icons.quiz_rounded, Colors.tealAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
        ],
      ),
    );
  }
  
  String _formatTimeSpent(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildReviewBanner(int dueCount) {
    final theme = Theme.of(context);
    if (dueCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withAlpha((255 * 0.15).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_rtl_rounded, color: theme.colorScheme.secondary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dueCount items due', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                const SizedBox(height: 4),
                Text('Review them now to strengthen your memory.', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.secondary),
        ],
      ),
    );
  }
}
